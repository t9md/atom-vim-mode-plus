LineEndingRegExp = /(?:\n|\r\n)$/
_ = require 'underscore-plus'
{BufferedProcess, Range} = require 'atom'

{
  haveSomeNonEmptySelection
  isSingleLine
} = require './utils'
swrap = require './selection-wrapper'
settings = require './settings'
Base = require './base'
Operator = Base.getClass('Operator')

# TransformString
# ================================
transformerRegistry = []
class TransformString extends Operator
  @extend(false)
  trackChange: true
  stayOnLinewise: true
  autoIndent: false

  @registerToSelectList: ->
    transformerRegistry.push(this)

  mutateSelection: (selection, stopMutation) ->
    if text = @getNewText(selection.getText(), selection, stopMutation)
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
  requireInput: true

  initialize: ->
    super
    if @isMode('normal')
      @target = 'MoveRightBufferColumn'
    @focusInput()

  getInput: ->
    super or "\n"

  mutateSelection: (selection) ->
    if @target.is('MoveRightBufferColumn')
      return unless selection.getText().length is @getCount()

    input = @getInput()
    @restorePositions = false if input is "\n"
    text = selection.getText().replace(/./g, input)
    selection.insertText(text, autoIndentNewline: true)

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
      screenRange = @editor.screenRangeForBufferRange(range)
      {start: {column: startColumn}, end: {column: endColumn}} = screenRange

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
selectListItems = null
class TransformStringBySelectList extends TransformString
  @extend()
  @description: "Interactively choose string transformation operator from select-list"
  requireInput: true

  getItems: ->
    selectListItems ?= transformerRegistry.map (klass) ->
      if klass::hasOwnProperty('displayName')
        displayName = klass::displayName
      else
        displayName = _.humanizeEventName(_.dasherize(klass.name))
      {name: klass, displayName}

  initialize: ->
    super

    @vimState.onDidConfirmSelectList (transformer) =>
      @vimState.reset()
      target = @target?.constructor.name
      @vimState.operationStack.run(transformer.name, {target})
    @focusSelectList({items: @getItems()})

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
  stayOnLinewise: false
  useMarkerForStay: true
  clipToMutationEndOnStay: false

  execute: ->
    unless @needStay()
      @onDidRestoreCursorPositions =>
        @editor.moveToFirstCharacterOfLine()
    super

  mutateSelection: (selection) ->
    selection.indentSelectedRows()

class Outdent extends Indent
  @extend()
  hover: icon: ':outdent:', emoji: ':point_left:'
  mutateSelection: (selection) ->
    selection.outdentSelectedRows()

class AutoIndent extends Indent
  @extend()
  hover: icon: ':auto-indent:', emoji: ':open_hands:'
  mutateSelection: (selection) ->
    selection.autoIndentSelectedRows()

class ToggleLineComments extends TransformString
  @extend()
  hover: icon: ':toggle-line-comments:', emoji: ':mute:'
  useMarkerForStay: true
  mutateSelection: (selection) ->
    selection.toggleLineComments()

# Surround < TransformString
# -------------------------
class Surround extends TransformString
  @extend()
  @description: "Surround target by specified character like `(`, `[`, `\"`"
  displayName: "Surround ()"
  hover: icon: ':surround:', emoji: ':two_women_holding_hands:'
  pairs: [
    ['[', ']']
    ['(', ')']
    ['{', '}']
    ['<', '>']
  ]
  input: null
  charsMax: 1
  requireInput: true
  autoIndent: false

  initialize: ->
    super

    return unless @requireInput
    if @requireTarget
      @onDidSetTarget =>
        @onDidConfirmInput (input) => @onConfirm(input)
        @onDidChangeInput (input) => @addHover(input)
        @onDidCancelInput => @cancelOperation()
        @vimState.input.focus(@charsMax)
    else
      @onDidConfirmInput (input) => @onConfirm(input)
      @onDidChangeInput (input) => @addHover(input)
      @onDidCancelInput => @cancelOperation()
      @vimState.input.focus(@charsMax)

  onConfirm: (@input) ->
    @processOperation()

  getPair: (char) ->
    pair = _.detect(@pairs, (pair) -> char in pair)
    pair ?= [char, char]

  surround: (text, char, options={}) ->
    keepLayout = options.keepLayout ? false
    [open, close] = @getPair(char)
    if (not keepLayout) and LineEndingRegExp.test(text)
      @autoIndent = true # [FIXME]
      open += "\n"
      close += "\n"

    if char in settings.get('charactersToAddSpaceOnSurround') and isSingleLine(text)
      open + ' ' + text + ' ' + close
    else
      open + text + close

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

class DeleteSurround extends Surround
  @extend()
  @description: "Delete specified surround character like `(`, `[`, `\"`"
  pairChars: ['[]', '()', '{}'].join('')
  requireTarget: false

  onConfirm: (@input) ->
    # FIXME: dont manage allowNextLine independently. Each Pair text-object can handle by themselvs.
    @setTarget @new 'Pair',
      pair: @getPair(@input)
      inner: false
      allowNextLine: (@input in @pairChars)
    @processOperation()

  getNewText: (text) ->
    [openChar, closeChar] = [text[0], _.last(text)]
    text = text[1...-1]
    if isSingleLine(text)
      text = text.trim() if openChar isnt closeChar
    text

class DeleteSurroundAnyPair extends DeleteSurround
  @extend()
  @description: "Delete surround character by auto-detect paired char from cursor enclosed pair"
  requireInput: false
  target: 'AAnyPair'

class DeleteSurroundAnyPairAllowForwarding extends DeleteSurroundAnyPair
  @extend()
  @description: "Delete surround character by auto-detect paired char from cursor enclosed pair and forwarding pair within same line"
  target: 'AAnyPairAllowForwarding'

class ChangeSurround extends DeleteSurround
  @extend()
  @description: "Change surround character, specify both from and to pair char"
  charsMax: 2
  char: null

  onConfirm: (input) ->
    return unless input
    [from, @char] = input.split('')
    super(from)

  getNewText: (text) ->
    innerText = super # Delete surround
    @surround(innerText, @char, keepLayout: true)

class ChangeSurroundAnyPair extends ChangeSurround
  @extend()
  @description: "Change surround character, from char is auto-detected"
  charsMax: 1
  target: "AAnyPair"

  highlightTargetRange: (selection) ->
    if range = @target.getRange(selection)
      marker = @editor.markBufferRange(range)
      @editor.decorateMarker(marker, type: 'highlight', class: 'vim-mode-plus-target-range')
      marker
    else
      null

  initialize: ->
    marker = null
    @onDidSetTarget =>
      if marker = @highlightTargetRange(@editor.getLastSelection())
        textRange = Range.fromPointWithDelta(marker.getBufferRange().start, 0, 1)
        char = @editor.getTextInBufferRange(textRange)
        @addHover(char, {}, @editor.getCursorBufferPosition())
      else
        @vimState.input.cancel()
        @abort()

    @onDidResetOperationStack ->
      marker?.destroy()
    super

  onConfirm: (@char) ->
    @input = @char
    @processOperation()

class ChangeSurroundAnyPairAllowForwarding extends ChangeSurroundAnyPair
  @extend()
  @description: "Change surround character, from char is auto-detected from enclosed and forwarding area"
  target: "AAnyPairAllowForwarding"

# Join < TransformString
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

  initialize: ->
    super
    unless @isMode('visual')
      @setTarget @new("MoveToRelativeLine", {min: 1})
    charsMax = 10
    @focusInput(charsMax)

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
