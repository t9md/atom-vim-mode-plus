LineEndingRegExp = /(?:\n|\r\n)$/
_ = require 'underscore-plus'
{BufferedProcess, Range} = require 'atom'

{
  haveSomeNonEmptySelection
  isSingleLineText
  limitNumber
} = require './utils'
swrap = require './selection-wrapper'
settings = require './settings'
Base = require './base'
Operator = Base.getClass('Operator')

# TransformString
# ================================
class TransformString extends Operator
  @extend(false)
  trackChange: true
  stayOptionName: 'stayOnTransformString'
  autoIndent: false
  autoIndentNewline: false
  @stringTransformers: []

  @registerToSelectList: ->
    @stringTransformers.push(this)

  mutateSelection: (selection) ->
    if text = @getNewText(selection.getText(), selection)
      selection.insertText(text, {@autoIndent})

class ToggleCase extends TransformString
  @extend()
  @registerToSelectList()
  @description: "`Hello World` -> `hELLO wORLD`"
  displayName: 'Toggle ~'
  hover: icon: ':toggle-case:', emoji: ':clap:'

  toggleCase: (char) ->
    charLower = char.toLowerCase()
    if charLower is char
      char.toUpperCase()
    else
      charLower

  getNewText: (text) ->
    text.replace(/./g, @toggleCase.bind(this))

class ToggleCaseAndMoveRight extends ToggleCase
  @extend()
  hover: null
  flashTarget: false
  restorePositions: false
  target: 'MoveRight'

class UpperCase extends TransformString
  @extend()
  @registerToSelectList()
  @description: "`Hello World` -> `HELLO WORLD`"
  hover: icon: ':upper-case:', emoji: ':point_up:'
  displayName: 'Upper'
  getNewText: (text) ->
    text.toUpperCase()

class LowerCase extends TransformString
  @extend()
  @registerToSelectList()
  @description: "`Hello World` -> `hello world`"
  hover: icon: ':lower-case:', emoji: ':point_down:'
  displayName: 'Lower'
  getNewText: (text) ->
    text.toLowerCase()

# Replace
# -------------------------
class Replace extends TransformString
  @extend()
  input: null
  hover: icon: ':replace:', emoji: ':tractor:'
  flashCheckpoint: 'did-select-occurrence'
  requireInput: true
  autoIndentNewline: true

  initialize: ->
    @onDidSetTarget =>
      @focusInput()
    super

  getNewText: (text) ->
    if @target.is('MoveRightBufferColumn') and text.length isnt @getCount()
      return

    input = @getInput() or "\n"
    if input is "\n"
      @restorePositions = false
    text.replace(/./g, input)

class ReplaceCharacter extends Replace
  @extend()
  target: "MoveRightBufferColumn"

# -------------------------
# DUP meaning with SplitString need consolidate.
class SplitByCharacter extends TransformString
  @extend()
  @registerToSelectList()
  getNewText: (text) ->
    text.split('').join(' ')

class CamelCase extends TransformString
  @extend()
  @registerToSelectList()
  displayName: 'Camelize'
  @description: "`hello-world` -> `helloWorld`"
  hover: icon: ':camel-case:', emoji: ':camel:'
  getNewText: (text) ->
    _.camelize(text)

class SnakeCase extends TransformString
  @extend()
  @registerToSelectList()
  @description: "`HelloWorld` -> `hello_world`"
  displayName: 'Underscore _'
  hover: icon: ':snake-case:', emoji: ':snake:'
  getNewText: (text) ->
    _.underscore(text)

class PascalCase extends TransformString
  @extend()
  @registerToSelectList()
  @description: "`hello_world` -> `HelloWorld`"
  displayName: 'Pascalize'
  hover: icon: ':pascal-case:', emoji: ':triangular_ruler:'
  getNewText: (text) ->
    _.capitalize(_.camelize(text))

class DashCase extends TransformString
  @extend()
  @registerToSelectList()
  displayName: 'Dasherize -'
  @description: "HelloWorld -> hello-world"
  hover: icon: ':dash-case:', emoji: ':dash:'
  getNewText: (text) ->
    _.dasherize(text)

class TitleCase extends TransformString
  @extend()
  @registerToSelectList()
  @description: "`HelloWorld` -> `Hello World`"
  displayName: 'Titlize'
  getNewText: (text) ->
    _.humanizeEventName(_.dasherize(text))

class EncodeUriComponent extends TransformString
  @extend()
  @registerToSelectList()
  @description: "`Hello World` -> `Hello%20World`"
  displayName: 'Encode URI Component %'
  hover: icon: 'encodeURI', emoji: 'encodeURI'
  getNewText: (text) ->
    encodeURIComponent(text)

class DecodeUriComponent extends TransformString
  @extend()
  @registerToSelectList()
  @description: "`Hello%20World` -> `Hello World`"
  displayName: 'Decode URI Component %%'
  hover: icon: 'decodeURI', emoji: 'decodeURI'
  getNewText: (text) ->
    decodeURIComponent(text)

class TrimString extends TransformString
  @extend()
  @registerToSelectList()
  @description: "` hello ` -> `hello`"
  displayName: 'Trim string'
  getNewText: (text) ->
    text.trim()

class CompactSpaces extends TransformString
  @extend()
  @registerToSelectList()
  @description: "`  a    b    c` -> `a b c`"
  displayName: 'Compact space'
  getNewText: (text) ->
    if text.match(/^[ ]+$/)
      ' '
    else
      # Don't compact for leading and trailing white spaces.
      text.replace /^(\s*)(.*?)(\s*)$/gm, (m, leading, middle, trailing) ->
        leading + middle.split(/[ \t]+/).join(' ') + trailing

class RemoveLeadingWhiteSpaces extends TransformString
  @extend()
  @registerToSelectList()
  wise: 'linewise'
  @description: "`  a b c` -> `a b c`"
  getNewText: (text, selection) ->
    trimLeft = (text) -> text.trimLeft()

    swrap(selection)
      .mapToLineText(trimLeft, includeNewline: true)
      .join("")

class ConvertToSoftTab extends TransformString
  @extend()
  @registerToSelectList()
  displayName: 'Soft Tab'
  wise: 'linewise'

  mutateSelection: (selection) ->
    scanRange = selection.getBufferRange()
    @editor.scanInBufferRange /\t/g, scanRange, ({range, replace}) =>
      # Replace \t to spaces which length is vary depending on tabStop and tabLenght
      # So we directly consult it's screen representing length.
      length = @editor.screenRangeForBufferRange(range).getExtent().column
      replace(" ".repeat(length))

class ConvertToHardTab extends TransformString
  @extend()
  @registerToSelectList()
  displayName: 'Hard Tab'

  mutateSelection: (selection) ->
    tabLength = @editor.getTabLength()
    scanRange = selection.getBufferRange()
    @editor.scanInBufferRange /[ \t]+/g, scanRange, ({range, replace}) =>
      {start, end} = @editor.screenRangeForBufferRange(range)
      startColumn = start.column
      endColumn = end.column

      # We can't naively replace spaces to tab, we have to consider valid tabStop column
      # If nextTabStop column exceeds replacable range, we pad with spaces.
      newText = ''
      loop
        remainder = startColumn %% tabLength
        nextTabStop = startColumn + (if remainder is 0 then tabLength else remainder)
        if nextTabStop > endColumn
          newText += " ".repeat(endColumn - startColumn)
        else
          newText += "\t"
        startColumn = nextTabStop
        break if startColumn >= endColumn

      replace(newText)

# -------------------------
class TransformStringByExternalCommand extends TransformString
  @extend(false)
  autoIndent: true
  command: '' # e.g. command: 'sort'
  args: [] # e.g args: ['-rn']
  stdoutBySelection: null

  execute: ->
    @normalizeSelectionsIfNecessary()
    if @selectTarget()
      new Promise (resolve) =>
        @collect(resolve)
      .then =>
        for selection in @editor.getSelections()
          text = @getNewText(selection.getText(), selection)
          selection.insertText(text, {@autoIndent})
        @restoreCursorPositionsIfNecessary()
        @activateMode(@finalMode, @finalSubmode)

  collect: (resolve) ->
    @stdoutBySelection = new Map
    processRunning = processFinished = 0
    for selection in @editor.getSelections()
      {command, args} = @getCommand(selection) ? {}
      return unless (command? and args?)
      processRunning++
      do (selection) =>
        stdin = @getStdin(selection)
        stdout = (output) =>
          @stdoutBySelection.set(selection, output)
        exit = (code) ->
          processFinished++
          resolve() if (processRunning is processFinished)
        @runExternalCommand {command, args, stdout, exit, stdin}

  runExternalCommand: (options) ->
    stdin = options.stdin
    delete options.stdin
    bufferedProcess = new BufferedProcess(options)
    bufferedProcess.onWillThrowError ({error, handle}) =>
      # Suppress command not found error intentionally.
      if error.code is 'ENOENT' and error.syscall.indexOf('spawn') is 0
        commandName = @constructor.getCommandName()
        console.log "#{commandName}: Failed to spawn command #{error.path}."
        handle()
      @cancelOperation()

    if stdin
      bufferedProcess.process.stdin.write(stdin)
      bufferedProcess.process.stdin.end()

  getNewText: (text, selection) ->
    @getStdout(selection) ? text

  # For easily extend by vmp plugin.
  getCommand: (selection) -> {@command, @args}
  getStdin: (selection) -> selection.getText()
  getStdout: (selection) -> @stdoutBySelection.get(selection)

# -------------------------
class TransformStringBySelectList extends TransformString
  @extend()
  @description: "Interactively choose string transformation operator from select-list"
  @selectListItems: null
  requireInput: true

  getItems: ->
    @constructor.selectListItems ?= @constructor.stringTransformers.map (klass) ->
      if klass::hasOwnProperty('displayName')
        displayName = klass::displayName
      else
        displayName = _.humanizeEventName(_.dasherize(klass.name))
      {name: klass, displayName}

  initialize: ->
    super

    @vimState.onDidConfirmSelectList (item) =>
      transformer = item.name
      @target = transformer::target if transformer::target?
      @vimState.reset()
      if @target?
        @vimState.operationStack.run(transformer, {@target})
      else
        @vimState.operationStack.run(transformer)

    @focusSelectList(items: @getItems())

  execute: ->
    # NEVER be executed since operationStack is replaced with selected transformer
    throw new Error("#{@getName()} should not be executed")

class TransformWordBySelectList extends TransformStringBySelectList
  @extend()
  target: "InnerWord"

class TransformSmartWordBySelectList extends TransformStringBySelectList
  @extend()
  @description: "Transform InnerSmartWord by `transform-string-by-select-list`"
  target: "InnerSmartWord"

# -------------------------
class ReplaceWithRegister extends TransformString
  @extend()
  @description: "Replace target with specified register value"
  hover: icon: ':replace-with-register:', emoji: ':pencil:'
  getNewText: (text) ->
    @vimState.register.getText()

# Save text to register before replace
class SwapWithRegister extends TransformString
  @extend()
  @description: "Swap register value with target"
  getNewText: (text, selection) ->
    newText = @vimState.register.getText()
    @setTextToRegister(text, selection)
    newText

# Indent < TransformString
# -------------------------
class Indent extends TransformString
  @extend()
  hover: icon: ':indent:', emoji: ':point_right:'
  stayByMarker: true
  wise: 'linewise'

  execute: ->
    unless @needStay()
      @onDidRestoreCursorPositions =>
        @editor.moveToFirstCharacterOfLine()
    super

  mutateSelection: (selection) ->
    # Need count times indentation in visual-mode and its repeat(`.`).
    if @target.is('CurrentSelection')
      oldText = null
       # limit to 100 to avoid freezing by accidental big number.
      count = limitNumber(@getCount(), max: 100)
      @countTimes count, ({stop}) =>
        oldText = selection.getText()
        @indent(selection)
        newText = selection.getText()
        stop() if oldText is newText
    else
      @indent(selection)

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

class ToggleLineComments extends TransformString
  @extend()
  hover: icon: ':toggle-line-comments:', emoji: ':mute:'
  stayByMarker: true
  mutateSelection: (selection) ->
    selection.toggleLineComments()

# Surround < TransformString
# -------------------------
class SurroundBase extends TransformString
  @extend(false)
  pairs: [
    ['[', ']']
    ['(', ')']
    ['{', '}']
    ['<', '>']
  ]
  pairCharsAllowForwarding: '[](){}'
  input: null
  autoIndent: false

  requireInput: true
  requireTarget: true
  supportEarlySelect: true # Experimental

  initialize: ->
    @subscribeForInput()
    super

  focusInputForSurround: ->
    inputUI = @newInputUI()
    inputUI.onDidConfirm(@onConfirmSurround.bind(this))
    inputUI.onDidCancel(@cancelOperation.bind(this))
    inputUI.focus()

  focusInputForDeleteSurround: ->
    inputUI = @newInputUI()
    inputUI.onDidConfirm(@onConfirmDeleteSurround.bind(this))
    inputUI.onDidCancel(@cancelOperation.bind(this))
    inputUI.focus()

  getPair: (char) ->
    if pair = _.detect(@pairs, (pair) -> char in pair)
      pair
    else
      [char, char]

  surround: (text, char, options={}) ->
    keepLayout = options.keepLayout ? false
    [open, close] = @getPair(char)
    if (not keepLayout) and LineEndingRegExp.test(text)
      @autoIndent = true # [FIXME]
      open += "\n"
      close += "\n"

    if char in settings.get('charactersToAddSpaceOnSurround') and isSingleLineText(text)
      text = ' ' + text + ' '

    open + text + close

  deleteSurround: (text) ->
    [open, innerText..., close] = text
    innerText = innerText.join('')
    if isSingleLineText(text) and (open isnt close)
      innerText.trim()
    else
      innerText

  onConfirmSurround: (@input) ->
    @processOperation()

  onConfirmDeleteSurround: (char) ->
    @setTarget @new 'Pair',
      pair: @getPair(char)
      inner: false
      allowNextLine: char in @pairCharsAllowForwarding

class Surround extends SurroundBase
  @extend()
  @description: "Surround target by specified character like `(`, `[`, `\"`"
  hover: icon: ':surround:', emoji: ':two_women_holding_hands:'

  subscribeForInput: ->
    @onDidSelectTarget(@focusInputForSurround.bind(this))

  getNewText: (text) ->
    @surround(text, @input)

class SurroundWord extends Surround
  @extend()
  @description: "Surround **word**"
  target: 'InnerWord'

class SurroundSmartWord extends Surround
  @extend()
  @description: "Surround **smart-word**"
  target: 'InnerSmartWord'

class MapSurround extends Surround
  @extend()
  @description: "Surround each word(`/\w+/`) within target"
  occurrence: true
  patternForOccurrence: /\w+/g

# Delete Surround
# -------------------------
class DeleteSurround extends SurroundBase
  @extend()
  @description: "Delete specified surround character like `(`, `[`, `\"`"
  requireTarget: false

  subscribeForInput: ->
    unless @hasTarget()
      @focusInputForDeleteSurround()

  onConfirmDeleteSurround: (input) ->
    super
    @input = input
    @processOperation()

  getNewText: (text) ->
    @deleteSurround(text)

class DeleteSurroundAnyPair extends DeleteSurround
  @extend()
  @description: "Delete surround character by auto-detect paired char from cursor enclosed pair"
  target: 'AAnyPair'
  requireInput: false

class DeleteSurroundAnyPairAllowForwarding extends DeleteSurroundAnyPair
  @extend()
  @description: "Delete surround character by auto-detect paired char from cursor enclosed pair and forwarding pair within same line"
  target: 'AAnyPairAllowForwarding'

# Change Surround
# -------------------------
class ChangeSurround extends SurroundBase
  @extend()
  @description: "Change surround character, specify both from and to pair char"

  showDeleteCharOnHover: ->
    char = @editor.getSelectedText()[0]
    @vimState.hover.showLight(char, @vimState.getOriginalCursorPosition())

  subscribeForInput: ->
    if @hasTarget()
      @onDidFailSelectTarget(@abort.bind(this))
    else
      @onDidFailSelectTarget(@cancelOperation.bind(this))
      @focusInputForDeleteSurround()

    @onDidSelectTarget =>
      @showDeleteCharOnHover()
      @focusInputForSurround()

  onConfirmSurround: (@input) ->
    @processOperation()

  getNewText: (text) ->
    innerText = @deleteSurround(text)
    @surround(innerText, @input, keepLayout: true)

class ChangeSurroundAnyPair extends ChangeSurround
  @extend()
  @description: "Change surround character, from char is auto-detected"
  target: "AAnyPair"

class ChangeSurroundAnyPairAllowForwarding extends ChangeSurroundAnyPair
  @extend()
  @description: "Change surround character, from char is auto-detected from enclosed and forwarding area"
  target: "AAnyPairAllowForwarding"

# -------------------------
# FIXME
# Currently native editor.joinLines() is better for cursor position setting
# So I use native methods for a meanwhile.
class Join extends TransformString
  @extend()
  target: "MoveToRelativeLine"
  flashTarget: false
  restorePositions: false

  mutateSelection: (selection) ->
    if swrap(selection).isLinewise()
      range = selection.getBufferRange()
      selection.setBufferRange(range.translate([0, 0], [-1, Infinity]))
    selection.joinLines()
    end = selection.getBufferRange().end
    selection.cursor.setBufferPosition(end.translate([0, -1]))

class JoinWithKeepingSpace extends TransformString
  @extend()
  @registerToSelectList()
  input: ''
  requireTarget: false
  trim: false
  initialize: ->
    @setTarget @new("MoveToRelativeLineWithMinimum", {min: 1})

  mutateSelection: (selection) ->
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
  @registerToSelectList()
  @description: "Transform multi-line to single-line by with specified separator character"
  hover: icon: ':join:', emoji: ':couple:'
  requireInput: true
  input: null
  trim: true
  initialize: ->
    super
    charsMax = 10
    @focusInput(charsMax)

  join: (rows) ->
    rows.join(" #{@input} ")

class JoinByInputWithKeepingSpace extends JoinByInput
  @description: "Join lines without padding space between each line"
  @extend()
  @registerToSelectList()
  trim: false
  join: (rows) ->
    rows.join(@input)

# -------------------------
# String suffix in name is to avoid confusion with 'split' window.
class SplitString extends TransformString
  @extend()
  @registerToSelectList()
  @description: "Split single-line into multi-line by splitting specified separator chars"
  hover: icon: ':split-string:', emoji: ':hocho:'
  requireInput: true
  input: null
  target: "MoveToRelativeLine"

  initialize: ->
    @onDidSetTarget =>
      @focusInput(charsMax = 10)
    super

  getNewText: (text) ->
    @input = "\\n" if @input is ''
    regex = ///#{_.escapeRegExp(@input)}///g
    text.split(regex).join("\n")

class ChangeOrder extends TransformString
  @extend(false)
  wise: 'linewise'

  mutateSelection: (selection) ->
    textForRows = swrap(selection).lineTextForBufferRows()
    rows = @getNewRows(textForRows)
    newText = rows.join("\n") + "\n"
    selection.insertText(newText)

class Reverse extends ChangeOrder
  @extend()
  @registerToSelectList()
  @description: "Reverse lines(e.g reverse selected three line)"
  getNewRows: (rows) ->
    rows.reverse()

class Sort extends ChangeOrder
  @extend()
  @registerToSelectList()
  @description: "Sort lines alphabetically"
  getNewRows: (rows) ->
    rows.sort()
