# Libraries
# -------------------------
LineEndingRegExp = /(?:\n|\r\n)$/

_ = require 'underscore-plus'
{Point, Range, CompositeDisposable, BufferedProcess} = require 'atom'

{
  haveSomeSelection, getVimEofBufferPosition
  moveCursorLeft, moveCursorRight
  highlightRanges, getNewTextRangeFromCheckpoint
  preserveSelectionStartPoints
  isEndsWithNewLineForBufferRow
} = require './utils'
swrap = require './selection-wrapper'
settings = require './settings'
Base = require './base'

# -------------------------
class OperatorError extends Base
  @extend(false)
  constructor: (@message) ->
    @name = 'Operator Error'

# General Operator
# -------------------------
class Operator extends Base
  @extend(false)
  recordable: true
  target: null
  flashTarget: true
  trackChange: false
  requireTarget: true

  setMarkForChange: ({start, end}) ->
    @vimState.mark.set('[', start)
    @vimState.mark.set(']', end)

  needFlash: ->
    @flashTarget and settings.get('flashOnOperate') and
      not (@constructor.name in settings.get('flashOnOperateBlacklist'))

  needTrackChange: ->
    @trackChange

  # [FIXME]
  # For TextObject isLinewise result is changed before / after select.
  # This mean @needStay return value change depending on when you call.
  needStay: ->
    param = if @instanceof('TransformString')
      "stayOnTransformString"
    else
      "stayOn#{@constructor.name}"
    settings.get(param) or (@stayOnLinewise and @target.isLinewise?())

  constructor: ->
    super
    # Guard when Repeated.
    return if @instanceof("Repeat")

    # [important] intialized is not called when Repeated
    @initialize?()
    @setTarget @new(@target) if _.isString(@target)

  markSelectedBufferRange: ->
    @editor.markBufferRange @editor.getSelectedBufferRange(),
      invalidate: 'never'
      persistent: false

  observeSelectAction: ->
    if @needStay()
      @onWillSelectTarget =>
        @restorePoint = preserveSelectionStartPoints(@editor)
    else
      @onDidSelectTarget =>
        @restorePoint = preserveSelectionStartPoints(@editor)

    if @needFlash()
      @onDidSelectTarget =>
        @flash @editor.getSelectedBufferRanges()

    if @needTrackChange()
      marker = null
      @onDidSelectTarget =>
        marker = @markSelectedBufferRange()

      @onDidFinishOperation =>
        @setMarkForChange(range) if (range = marker.getBufferRange())

  # @target - TextObject or Motion to operate on.
  setTarget: (@target) ->
    unless _.isFunction(@target.select)
      @vimState.emitter.emit('did-fail-to-set-target')
      targetName = @target.constructor.name
      operatorName = @constructor.name
      message = "Failed to set '#{targetName}' as target for Operator '#{operatorName}'"
      throw new OperatorError(message)
    @emitDidSetTarget(this)

  # Return true unless all selection is empty.
  # -------------------------
  selectTarget: ->
    @observeSelectAction()
    @emitWillSelectTarget()
    @target.select()
    @emitDidSelectTarget()
    haveSomeSelection(@editor)

  setTextToRegisterForSelection: (selection) ->
    @setTextToRegister(selection.getText(), selection)

  setTextToRegister: (text, selection) ->
    if @target.isLinewise?() and not text.endsWith('\n')
      text += "\n"
    if text
      @vimState.register.set({text, selection})

  flash: (ranges) ->
    if @flashTarget and settings.get('flashOnOperate')
      highlightRanges @editor, ranges,
        class: 'vim-mode-plus-flash'
        timeout: settings.get('flashOnOperateDuration')

  eachSelection: (fn) ->
    return unless @selectTarget()
    @editor.transact =>
      for selection in @editor.getSelections()
        fn(selection)

# -------------------------
class Select extends Operator
  @extend(false)
  flashTarget: false
  recordable: false
  execute: ->
    @selectTarget()
    return if @isMode('operator-pending') or @isMode('visual', 'blockwise')
    unless @isMode('visual')
      submode = swrap.detectVisualModeSubmode(@editor)
      @activateMode('visual', submode)
    else
      if @target.isAllowSubmodeChange?()
        submode = swrap.detectVisualModeSubmode(@editor)
        if submode? and not @isMode('visual', submode)
          @activateMode('visual', submode)

class SelectLatestChange extends Select
  @extend()
  target: 'ALatestChange'

# -------------------------
class Delete extends Operator
  @extend()
  hover: icon: ':delete:', emoji: ':scissors:'
  trackChange: true
  flashTarget: false

  execute: ->
    @eachSelection (selection) =>
      {cursor} = selection
      wasLinewise = swrap(selection).isLinewise()
      @setTextToRegisterForSelection(selection)
      selection.deleteSelectedText()

      vimEof = getVimEofBufferPosition(@editor)
      if cursor.getBufferPosition().isGreaterThan(vimEof)
        cursor.setBufferPosition([vimEof.row, 0])

      cursor.skipLeadingWhitespace() if wasLinewise
    @activateMode('normal')

class DeleteRight extends Delete
  @extend()
  target: 'MoveRight'

class DeleteLeft extends Delete
  @extend()
  target: 'MoveLeft'

class DeleteToLastCharacterOfLine extends Delete
  @extend()
  target: 'MoveToLastCharacterOfLine'

# -------------------------
class TransformString extends Operator
  @extend(false)
  trackChange: true
  stayOnLinewise: true
  setPoint: true
  autoIndent: false

  execute: ->
    @eachSelection (selection) =>
      @mutate(selection)
    @activateMode('normal')

  mutate: (selection) ->
    text = @getNewText(selection.getText(), selection)
    selection.insertText(text, {@autoIndent})
    @restorePoint(selection) if @setPoint

# String Transformer
# -------------------------
class ToggleCase extends TransformString
  @extend()
  displayName: 'Toggle ~'
  hover: icon: ':toggle-case:', emoji: ':clap:'
  toggleCase: (char) ->
    charLower = char.toLowerCase()
    if charLower is char
      char.toUpperCase()
    else
      charLower

  getNewText: (text) ->
    text.split('').map(@toggleCase).join('')

class ToggleCaseAndMoveRight extends ToggleCase
  @extend()
  hover: null
  setPoint: false
  target: 'MoveRight'

class UpperCase extends TransformString
  @extend()
  displayName: 'Upper'
  hover: icon: ':upper-case:', emoji: ':point_up:'
  getNewText: (text) ->
    text.toUpperCase()

class LowerCase extends TransformString
  @extend()
  displayName: 'Lower'
  hover: icon: ':lower-case:', emoji: ':point_down:'
  getNewText: (text) ->
    text.toLowerCase()

class CamelCase extends TransformString
  @extend()
  displayName: 'Camelize'
  hover: icon: ':camel-case:', emoji: ':camel:'
  getNewText: (text) ->
    _.camelize(text)

class SnakeCase extends TransformString
  @extend()
  displayName: 'Underscore _'
  hover: icon: ':snake-case:', emoji: ':snake:'
  getNewText: (text) ->
    _.underscore(text)

class DashCase extends TransformString
  @extend()
  displayName: 'Dasherize -'
  hover: icon: ':dash-case:', emoji: ':dash:'
  getNewText: (text) ->
    _.dasherize(text)

class TitleCase extends TransformString
  @extend()
  displayName: 'Titlize'
  getNewText: (text) ->
    _.humanizeEventName(_.dasherize(text))

class EncodeUriComponent extends TransformString
  @extend()
  displayName: 'Encode URI Component %'
  hover: icon: 'encodeURI', emoji: 'encodeURI'
  getNewText: (text) ->
    encodeURIComponent(text)

class DecodeUriComponent extends TransformString
  @extend()
  displayName: 'Decode URI Component %%'
  hover: icon: 'decodeURI', emoji: 'decodeURI'
  getNewText: (text) ->
    decodeURIComponent(text)

# -------------------------
class TransformStringByExternalCommand extends TransformString
  @extend(false)
  autoIndent: true
  command: '' # e.g. command: 'sort'
  args: [] # e.g args: ['-rn']
  stdoutBySelection: null

  execute: ->
    new Promise (resolve) =>
      @collect(resolve)
    .then =>
      super

  collect: (resolve) ->
    @stdoutBySelection = new Map
    restorePoint = null
    unless @isMode('visual')
      restorePoint = preserveSelectionStartPoints(@editor)
      @target.select()

    running = finished = 0
    for selection in @editor.getSelections()
      running++
      {command, args} = @getCommand(selection) ? {}
      if command? and args?
        do (selection) =>
          stdin = @getStdin(selection)
          stdout = (output) =>
            @stdoutBySelection.set(selection, output)
          exit = (code) ->
            finished++
            resolve() if (running is finished)

          @runExternalCommand {command, args, stdout, exit, stdin}
          restorePoint?(selection)

  runExternalCommand: (options) ->
    {stdin} = options
    delete options.stdin
    bufferedProcess = new BufferedProcess(options)
    bufferedProcess.onWillThrowError ({error, handle}) =>
      # Suppress command not found error intentionally.
      if error.code is 'ENOENT' and error.syscall.indexOf('spawn') is 0
        commandName = @constructor.getCommandName()
        console.log "#{commandName}: Failed to spawn command #{error.path}."
      @cancelOperation()
      handle()

    if stdin
      bufferedProcess.process.stdin.write(stdin)
      bufferedProcess.process.stdin.end()

  getNewText: (text, selection) ->
    @getStdout(selection) ? text

  # For easily extend by vmp plugin.
  getCommand: (selection) ->
    {@command, @args}

  # For easily extend by vmp plugin.
  getStdin: (selection) ->
    selection.getText()

  # For easily extend by vmp plugin.
  getStdout: (selection) ->
    @stdoutBySelection.get(selection)

# -------------------------
class TransformStringBySelectList extends Operator
  @extend()
  requireInput: true
  requireTarget: true
  # Member of transformers can be either of
  # - Operation class name: e.g 'CamelCase'
  # - Operation class itself: e.g. CamelCase
  transformers: [
    'CamelCase'
    'DashCase'
    'SnakeCase'
    'TitleCase'
    'EncodeUriComponent'
    'DecodeUriComponent'
    'Reverse'
    'Surround'
    'MapSurround'
    'IncrementNumber'
    'DecrementNumber'
    'JoinByInput'
    'JoinWithKeepingSpace'
    'SplitString'
    'LowerCase'
    'UpperCase'
    'ToggleCase'
  ]

  getItems: ->
    @transformers.map (klass) ->
      klass = Base.getClass(klass) if _.isString(klass)
      displayName = klass::displayName if klass::hasOwnProperty('displayName')
      displayName ?= _.humanizeEventName(_.dasherize(klass.name))
      {name: klass, displayName}

  initialize: ->
    @onDidSetTarget =>
      @focusSelectList({items: @getItems()})

    @vimState.onDidConfirmSelectList (transformer) =>
      @vimState.reset()
      @vimState.operationStack.run(transformer.name, {target: @target.constructor.name})

  execute: ->
    # NEVER be executed since operationStack is replaced with selected transformer

class TransformWordBySelectList extends TransformStringBySelectList
  @extend()
  target: "InnerWord"

class TransformSmartWordBySelectList extends TransformStringBySelectList
  @extend()
  target: "InnerSmartWord"

# -------------------------
class ReplaceWithRegister extends TransformString
  @extend()
  hover: icon: ':replace-with-register:', emoji: ':pencil:'
  getNewText: (text) ->
    @vimState.register.getText()

# Save text to register before replace
class SwapWithRegister extends TransformString
  @extend()
  getNewText: (text, selection) ->
    newText = @vimState.register.getText()
    @setTextToRegister(text, selection)
    newText

# -------------------------
class Indent extends TransformString
  @extend()
  hover: icon: ':indent:', emoji: ':point_right:'
  stayOnLinewise: false

  mutate: (selection) ->
    @indent(selection)
    @restorePoint(selection)
    unless @needStay()
      selection.cursor.moveToFirstCharacterOfLine()

  indent: (selection) ->
    selection.indentSelectedRows()

class Outdent extends Indent
  @extend()
  hover: icon: ':outdent:', emoji: ':point_left:'
  indent: (selection) ->
    selection.outdentSelectedRows()

class AutoIndent extends Indent
  @extend()
  hover: icon: ':auto-indent:', emoji: ':open_hands:'
  indent: (selection) ->
    selection.autoIndentSelectedRows()

# -------------------------
class ToggleLineComments extends TransformString
  @extend()
  hover: icon: ':toggle-line-comments:', emoji: ':mute:'
  mutate: (selection) ->
    selection.toggleLineComments()
    @restorePoint(selection)

# -------------------------
class Surround extends TransformString
  @extend()
  displayName: "Surround ()"
  pairs: [
    ['[', ']']
    ['(', ')']
    ['{', '}']
    ['<', '>']
  ]
  input: null
  charsMax: 1
  hover: icon: ':surround:', emoji: ':two_women_holding_hands:'
  requireInput: true
  autoIndent: true

  initialize: ->
    return unless @requireInput
    @onDidConfirmInput (input) => @onConfirm(input)
    @onDidChangeInput (input) => @addHover(input)
    @onDidCancelInput => @cancelOperation()
    if @requireTarget
      @onDidSetTarget =>
        @vimState.input.focus({@charsMax})
    else
      @vimState.input.focus({@charsMax})

  onConfirm: (@input) ->
    @processOperation()

  getPair: (input) ->
    pair = _.detect @pairs, (pair) -> input in pair
    pair ?= [input, input]

  surround: (text, pair) ->
    [open, close] = pair
    if LineEndingRegExp.test(text)
      open += "\n"
      close += "\n"

    # if @input in settings.get('charactersToAddSpaceOnSurround')
    if @input in settings.get('charactersToAddSpaceOnSurround')
      open + ' ' + text + ' ' + close
    else
      open + text + close

  getNewText: (text) ->
    @surround text, @getPair(@input)

class SurroundWord extends Surround
  @extend()
  target: 'InnerWord'

class SurroundSmartWord extends Surround
  @extend()
  target: 'InnerSmartWord'

class MapSurround extends Surround
  @extend()
  mapRegExp: /\w+/g
  execute: ->
    @eachSelection (selection) =>
      scanRange = selection.getBufferRange()
      @editor.scanInBufferRange @mapRegExp, scanRange, ({matchText, replace}) =>
        replace(@getNewText(matchText))
      @restorePoint(selection) if @setPoint
    @activateMode('normal')

class DeleteSurround extends Surround
  @extend()
  pairChars: ['[]', '()', '{}'].join('')
  requireTarget: false

  onConfirm: (@input) ->
    # FIXME: dont manage allowNextLine independently. Each Pair text-object can handle by themselvs.
    target = @new 'Pair',
      pair: @getPair(@input)
      inclusive: true
      allowNextLine: @input in @pairChars
    @setTarget(target)
    @processOperation()

  getNewText: (text) ->
    text[1...-1].trim()

class DeleteSurroundAnyPair extends DeleteSurround
  @extend()
  requireInput: false
  target: 'AAnyPair'

class ChangeSurround extends DeleteSurround
  @extend()
  charsMax: 2
  char: null

  onConfirm: (input) ->
    return unless input
    [from, @char] = input.split('')
    super(from)

  getNewText: (text) ->
    @surround super(text), @getPair(@char)

class ChangeSurroundAnyPair extends ChangeSurround
  @extend()
  charsMax: 1
  target: "AAnyPair"

  initialize: ->
    @onDidSetTarget =>
      @restore = preserveSelectionStartPoints(@editor)
      @target.select()
      unless haveSomeSelection(@editor)
        @vimState.reset()
        @abort()
      @addHover(@editor.getSelectedText()[0])
    super

  onConfirm: (@char) ->
    # Clear pre-selected selection to start @eachSelection from non-selection.
    @restore(selection) for selection in @editor.getSelections()
    @input = @char
    @processOperation()

# -------------------------
class Yank extends Operator
  @extend()
  hover: icon: ':yank:', emoji: ':clipboard:'
  trackChange: true
  stayOnLinewise: true

  execute: ->
    @eachSelection (selection) =>
      # We need to preserve selection before selection cleared by @restorePoint()
      if selection.isLastSelection() and @isMode('visual')
        @vimState.modeManager.preservePreviousSelection(selection)
      @setTextToRegisterForSelection(selection)
      @restorePoint(selection)
    @activateMode('normal')

class YankLine extends Yank
  @extend()
  target: 'MoveToRelativeLine'

# -------------------------
# FIXME
# Currently native editor.joinLines() is better for cursor position setting
# So I use native methods for a meanwhile.
class Join extends Operator
  @extend()
  requireTarget: false
  execute: ->
    @editor.transact =>
      _.times @getCount(), =>
        @editor.joinLines()
    @activateMode('normal')

class JoinWithKeepingSpace extends TransformString
  @extend()
  input: ''
  requireTarget: false
  trim: false
  initialize: ->
    @setTarget @new("MoveToRelativeLineWithMinimum", {min: 1})

  mutate: (selection) ->
    [startRow, endRow] = selection.getBufferRowRange()
    swrap(selection).expandOverLine()
    rows = for row in [startRow..endRow]
      text = @editor.lineTextForBufferRow(row)
      if @trim and row isnt startRow
        text.trimLeft()
      else
        text
    selection.insertText @join(rows) + "\n"

  join: (rows) ->
    rows.join(@input)

class JoinByInput extends JoinWithKeepingSpace
  @extend()
  hover: icon: ':join:', emoji: ':couple:'
  requireInput: true
  input: null
  trim: true
  initialize: ->
    super
    @focusInput(charsMax: 10)

  join: (rows) ->
    rows.join(" #{@input} ")

class JoinByInputWithKeepingSpace extends JoinByInput
  @extend()
  trim: false
  join: (rows) ->
    rows.join(@input)

# -------------------------
# String suffix in name is to avoid confusion with 'split' window.
class SplitString extends TransformString
  @extend()
  hover: icon: ':split-string:', emoji: ':hocho:'
  requireInput: true
  input: null

  initialize: ->
    unless @isMode('visual')
      @setTarget @new("MoveToRelativeLine", {min: 1})
    @focusInput(charsMax: 10)

  getNewText: (text) ->
    @input = "\\n" if @input is ''
    regex = ///#{_.escapeRegExp(@input)}///g
    text.split(regex).join("\n")

class Reverse extends TransformString
  @extend()
  mutate: (selection) ->
    swrap(selection).expandOverLine()
    textForRows = swrap(selection).lineTextForBufferRows()
    newText = textForRows.reverse().join("\n") + "\n"
    selection.insertText(newText)
    @restorePoint(selection)

# -------------------------
class Repeat extends Operator
  @extend()
  requireTarget: false
  recordable: false

  execute: ->
    @editor.transact =>
      _.times @getCount(), =>
        if operation = @vimState.operationStack.getRecorded()
          operation.setRepeated()
          operation.execute()

# -------------------------
class Mark extends Operator
  @extend()
  hover: icon: ':mark:', emoji: ':round_pushpin:'
  requireInput: true
  requireTarget: false
  initialize: ->
    @focusInput()

  execute: ->
    @vimState.mark.set(@input, @editor.getCursorBufferPosition())
    @activateMode('normal')

# -------------------------
# [FIXME?]: inconsistent behavior from normal operator
# Since its support visual-mode but not use setTarget() convension.
# Maybe separating complete/in-complete version like IncreaseNow and Increase?
class Increase extends Operator
  @extend()
  requireTarget: false
  step: 1

  execute: ->
    pattern = ///#{settings.get('numberRegex')}///g

    newRanges = []
    @editor.transact =>
      for cursor in @editor.getCursors()
        scanRange = if @isMode('visual')
          cursor.selection.getBufferRange()
        else
          cursor.getCurrentLineBufferRange()
        ranges = @increaseNumber(cursor, scanRange, pattern)
        if not @isMode('visual') and ranges.length
          cursor.setBufferPosition ranges[0].end.translate([0, -1])
        newRanges.push ranges

    if (newRanges = _.flatten(newRanges)).length
      @flash newRanges
    else
      atom.beep()

  increaseNumber: (cursor, scanRange, pattern) ->
    newRanges = []
    @editor.scanInBufferRange pattern, scanRange, ({matchText, range, stop, replace}) =>
      newText = String(parseInt(matchText, 10) + @step * @getCount())
      if @isMode('visual')
        newRanges.push replace(newText)
      else
        return unless range.end.isGreaterThan cursor.getBufferPosition()
        newRanges.push replace(newText)
        stop()
    newRanges

class Decrease extends Increase
  @extend()
  step: -1

# -------------------------
class IncrementNumber extends Operator
  @extend()
  displayName: 'Increment ++'
  step: 1
  baseNumber: null

  execute: ->
    pattern = ///#{settings.get('numberRegex')}///g
    newRanges = null
    @selectTarget()
    @editor.transact =>
      newRanges = for selection in @editor.getSelectionsOrderedByBufferPosition()
        @replaceNumber(selection.getBufferRange(), pattern)
    if (newRanges = _.flatten(newRanges)).length
      @flash newRanges
    else
      atom.beep()
    for selection in @editor.getSelections()
      selection.cursor.setBufferPosition(selection.getBufferRange().start)
    @activateMode('normal')

  replaceNumber: (scanRange, pattern) ->
    newRanges = []
    @editor.scanInBufferRange pattern, scanRange, ({matchText, replace}) =>
      newRanges.push replace(@getNewText(matchText))
    newRanges

  getNewText: (text) ->
    @baseNumber = if @baseNumber?
      @baseNumber + @step * @getCount()
    else
      parseInt(text, 10)
    String(@baseNumber)

class DecrementNumber extends IncrementNumber
  @extend()
  displayName: 'Decrement --'
  step: -1

# Put
# -------------------------
class PutBefore extends Operator
  @extend()
  requireTarget: false
  location: 'before'

  execute: ->
    @editor.transact =>
      for selection in @editor.getSelections()
        {cursor} = selection

        {text, type} = @vimState.register.get(null, selection)
        break unless text
        text = _.multiplyString(text, @getCount())
        newRange = @paste selection, text,
          linewise: (type is 'linewise') or @isMode('visual', 'linewise')
          select: @selectPastedText
        @setMarkForChange(newRange)
        @flash newRange

    if @selectPastedText# and haveSomeSelection(@editor)
      submode = swrap.detectVisualModeSubmode(@editor)
      unless @isMode('visual', submode)
        @activateMode('visual', submode)
    else
      @activateMode('normal')

  paste: (selection, text, {linewise, select}) ->
    {cursor} = selection
    select ?= false
    linewise ?= false
    if linewise
      newRange = @pasteLinewise(selection, text)
      adjustCursor = (range) ->
        cursor.setBufferPosition(range.start)
        cursor.moveToFirstCharacterOfLine()
    else
      newRange = @pasteCharacterwise(selection, text)
      adjustCursor = (range) ->
        cursor.setBufferPosition(range.end.translate([0, -1]))

    if select
      selection.setBufferRange(newRange)
    else
      adjustCursor(newRange)
    newRange

  # Return newRange
  pasteLinewise: (selection, text) ->
    {cursor} = selection
    text += "\n" unless text.endsWith("\n")
    if selection.isEmpty()
      row = cursor.getBufferRow()
      switch @location
        when 'before'
          range = [[row, 0], [row, 0]]
        when 'after'
          unless isEndsWithNewLineForBufferRow(@editor, row)
            text = text.replace(LineEndingRegExp, '')
          cursor.moveToEndOfLine()
          {end} = selection.insertText("\n")
          range = @editor.bufferRangeForBufferRow(end.row, {includeNewline: true})
      @editor.setTextInBufferRange(range, text)
    else
      if @isMode('visual', 'linewise')
        unless selection.getBufferRange().end.column is 0
          text = text.replace(LineEndingRegExp, '')
      else
        selection.insertText("\n")
      selection.insertText(text)

  pasteCharacterwise: (selection, text) ->
    if @location is 'after' and selection.isEmpty()
      selection.cursor.moveRight()
    selection.insertText(text)

class PutAfter extends PutBefore
  @extend()
  location: 'after'

class PutBeforeAndSelect extends PutBefore
  @extend()
  selectPastedText: true

class PutAfterAndSelect extends PutAfter
  @extend()
  selectPastedText: true

# Replace
# -------------------------
class Replace extends Operator
  @extend()
  input: null
  hover: icon: ':replace:', emoji: ':tractor:'
  flashTarget: false
  trackChange: true
  requireInput: true
  requireTarget: false

  initialize: ->
    @setTarget @new('MoveRight') if @isMode('normal')
    @focusInput()

  execute: ->
    @input = "\n" if @input is ''
    @eachSelection (selection) =>
      text = selection.getText().replace(/./g, @input)
      unless (@target.instanceof('MoveRight') and (text.length < @getCount()))
        selection.insertText(text, autoIndentNewline: true)
      @restorePoint(selection) unless @input is "\n"

    # FIXME this is very imperative, handling in very lower level.
    # find better place for operator in blockwise move works appropriately.
    if @isMode('visual', 'blockwise')
      top = @editor.getSelectionsOrderedByBufferPosition()[0]
      for selection in @editor.getSelections() when (selection isnt top)
        selection.destroy()

    @activateMode('normal')

# Insert entering operation
# -------------------------
class ActivateInsertMode extends Operator
  @extend()
  requireTarget: false
  flashTarget: false
  checkpoint: null
  submode: null
  supportInsertionCount: true

  observeWillDeactivateMode: ->
    disposable = @vimState.modeManager.preemptWillDeactivateMode ({mode}) =>
      return unless mode is 'insert'
      disposable.dispose()

      @vimState.mark.set('^', @editor.getCursorBufferPosition())
      if (range = getNewTextRangeFromCheckpoint(@editor, @getCheckpoint('insert')))?
        @setMarkForChange(range) # Marker can track following extra insertion incase count specified
        textByUserInput = @editor.getTextInBufferRange(range)
      else
        textByUserInput = ''
      @saveInsertedText(textByUserInput)
      @vimState.register.set('.', {text: textByUserInput})

      _.times @getInsertionCount(), =>
        text = @textByOperator + textByUserInput
        for selection in @editor.getSelections()
          selection.insertText(text, autoIndent: true)

      # grouping changes for undo checkpoint need to come last
      @editor.groupChangesSinceCheckpoint(@getCheckpoint('undo'))

  initialize: ->
    @checkpoint = {}
    @setCheckpoint('undo') unless @isRepeated()
    @observeWillDeactivateMode()

  # we have to manage two separate checkpoint for different purpose(timing is different)
  # - one for undo(handled by modeManager)
  # - one for preserve last inserted text
  setCheckpoint: (purpose) ->
    @checkpoint[purpose] = @editor.createCheckpoint()

  getCheckpoint: (purpose) ->
    @checkpoint[purpose]

  saveInsertedText: (@insertedText) -> @insertedText

  getInsertedText: ->
    @insertedText ? ''

  # called when repeated
  repeatInsert: (selection, text) ->
    selection.insertText(text, autoIndent: true)

  getInsertionCount: ->
    @insertionCount ?= if @supportInsertionCount then (@getCount() - 1) else 0
    @insertionCount

  execute: ->
    if @isRepeated()
      return unless text = @getInsertedText()
      unless @instanceof('Change')
        @flashTarget = @trackChange = true
        @observeSelectAction()
        @emitDidSelectTarget()
      @editor.transact =>
        for selection in @editor.getSelections()
          @repeatInsert(selection, text)
          moveCursorLeft(selection.cursor)
    else
      if @getInsertionCount() > 0
        range = getNewTextRangeFromCheckpoint(@editor, @getCheckpoint('undo'))
        @textByOperator = if range? then @editor.getTextInBufferRange(range) else ''
      @setCheckpoint('insert')
      @vimState.activate('insert', @submode)

class InsertAtLastInsert extends ActivateInsertMode
  @extend()
  execute: ->
    if (point = @vimState.mark.get('^'))
      @editor.setCursorBufferPosition(point)
      @editor.scrollToCursorPosition({center: true})
    super

class ActivateReplaceMode extends ActivateInsertMode
  @extend()
  submode: 'replace'

  repeatInsert: (selection, text) ->
    for char in text when (char isnt "\n")
      break if selection.cursor.isAtEndOfLine()
      selection.selectRight()
    selection.insertText(text, autoIndent: false)

class InsertAfter extends ActivateInsertMode
  @extend()
  execute: ->
    moveCursorRight(cursor) for cursor in @editor.getCursors()
    super

class InsertAfterEndOfLine extends ActivateInsertMode
  @extend()
  execute: ->
    @editor.moveToEndOfLine()
    super

class InsertAtBeginningOfLine extends ActivateInsertMode
  @extend()
  execute: ->
    @editor.moveToBeginningOfLine()
    @editor.moveToFirstCharacterOfLine()
    super

class InsertByMotion extends ActivateInsertMode
  @extend()
  requireTarget: true
  execute: ->
    if @target.instanceof('Motion')
      @target.execute()
    if @instanceof('InsertAfterByMotion')
      moveCursorRight(cursor) for cursor in @editor.getCursors()
    super

class InsertAfterByMotion extends InsertByMotion
  @extend()

class InsertAtPreviousFoldStart extends InsertByMotion
  @extend()
  target: 'MoveToPreviousFoldStart'

class InsertAtNextFoldStart extends InsertAtPreviousFoldStart
  @extend()
  target: 'MoveToNextFoldStart'

class InsertAboveWithNewline extends ActivateInsertMode
  @extend()
  execute: ->
    @insertNewline()
    super

  insertNewline: ->
    @editor.insertNewlineAbove()

  repeatInsert: (selection, text) ->
    selection.insertText(text.trimLeft(), autoIndent: true)

class InsertBelowWithNewline extends InsertAboveWithNewline
  @extend()
  insertNewline: ->
    @editor.insertNewlineBelow()
# -------------------------
class Change extends ActivateInsertMode
  @extend()
  requireTarget: true
  trackChange: true
  supportInsertionCount: false

  execute: ->
    @selectTarget()
    text = ''
    if @target.instanceof('TextObject') or @target.instanceof('Motion')
      text = "\n" if (swrap.detectVisualModeSubmode(@editor) is 'linewise')
    else
      text = "\n" if @target.isLinewise?()

    @editor.transact =>
      for selection in @editor.getSelections()
        @setTextToRegisterForSelection(selection)
        range = selection.insertText(text, autoIndent: true)
        selection.cursor.moveLeft() unless range.isEmpty()
    super

class Substitute extends Change
  @extend()
  target: 'MoveRight'

class SubstituteLine extends Change
  @extend()
  target: 'MoveToRelativeLine'

class ChangeToLastCharacterOfLine extends Change
  @extend()
  target: 'MoveToLastCharacterOfLine'
