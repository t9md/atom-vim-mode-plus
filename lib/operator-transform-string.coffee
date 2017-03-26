LineEndingRegExp = /(?:\n|\r\n)$/
_ = require 'underscore-plus'
{BufferedProcess, Range} = require 'atom'

{
  isSingleLineText
  isLinewiseRange
  limitNumber
  toggleCaseForCharacter
  splitTextByNewLine
} = require './utils'
swrap = require './selection-wrapper'
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

  getNewText: (text) ->
    text.replace(/./g, toggleCaseForCharacter)

class ToggleCaseAndMoveRight extends ToggleCase
  @extend()
  flashTarget: false
  restorePositions: false
  target: 'MoveRight'

class UpperCase extends TransformString
  @extend()
  @registerToSelectList()
  @description: "`Hello World` -> `HELLO WORLD`"
  displayName: 'Upper'
  getNewText: (text) ->
    text.toUpperCase()

class LowerCase extends TransformString
  @extend()
  @registerToSelectList()
  @description: "`Hello World` -> `hello world`"
  displayName: 'Lower'
  getNewText: (text) ->
    text.toLowerCase()

# Replace
# -------------------------
class Replace extends TransformString
  @extend()
  input: null
  flashCheckpoint: 'did-select-occurrence'
  requireInput: true
  autoIndentNewline: true
  supportEarlySelect: true

  initialize: ->
    @onDidSelectTarget(@focusInput.bind(this))
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
  getNewText: (text) ->
    _.camelize(text)

class SnakeCase extends TransformString
  @extend()
  @registerToSelectList()
  @description: "`HelloWorld` -> `hello_world`"
  displayName: 'Underscore _'
  getNewText: (text) ->
    _.underscore(text)

class PascalCase extends TransformString
  @extend()
  @registerToSelectList()
  @description: "`hello_world` -> `HelloWorld`"
  displayName: 'Pascalize'
  getNewText: (text) ->
    _.capitalize(_.camelize(text))

class DashCase extends TransformString
  @extend()
  @registerToSelectList()
  displayName: 'Dasherize -'
  @description: "HelloWorld -> hello-world"
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
  getNewText: (text) ->
    encodeURIComponent(text)

class DecodeUriComponent extends TransformString
  @extend()
  @registerToSelectList()
  @description: "`Hello%20World` -> `Hello World`"
  displayName: 'Decode URI Component %%'
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
    splitTextByNewLine(text).map(trimLeft).join("\n") + "\n"

class ConvertToSoftTab extends TransformString
  @extend()
  @registerToSelectList()
  displayName: 'Soft Tab'
  wise: 'linewise'

  mutateSelection: (selection) ->
    @scanForward /\t/g, {scanRange: selection.getBufferRange()}, ({range, replace}) =>
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
    @scanForward /[ \t]+/g, {scanRange: selection.getBufferRange()}, ({range, replace}) =>
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
        stop() if selection.getText() is oldText
    else
      @indent(selection)

  indent: (selection) ->
    selection.indentSelectedRows()

class Outdent extends Indent
  @extend()
  indent: (selection) ->
    selection.outdentSelectedRows()

class AutoIndent extends Indent
  @extend()
  indent: (selection) ->
    selection.autoIndentSelectedRows()

class ToggleLineComments extends TransformString
  @extend()
  stayByMarker: true
  mutateSelection: (selection) ->
    selection.toggleLineComments()

class AutoFlow extends TransformString
  @extend()
  mutateSelection: (selection) ->
    atom.commands.dispatch(@editorElement, 'autoflow:reflow-selection')

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

    if char in @getConfig('charactersToAddSpaceOnSurround') and isSingleLineText(text)
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
    @setTarget @new('APair', pair: @getPair(char))

class Surround extends SurroundBase
  @extend()
  @description: "Surround target by specified character like `(`, `[`, `\"`"

  initialize: ->
    @onDidSelectTarget(@focusInputForSurround.bind(this))
    super

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

  initialize: ->
    @focusInputForDeleteSurround() unless @hasTarget()
    super

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
    @vimState.hover.set(char, @vimState.getOriginalCursorPosition())

  initialize: ->
    if @hasTarget()
      @onDidFailSelectTarget(@abort.bind(this))
    else
      @onDidFailSelectTarget(@cancelOperation.bind(this))
      @focusInputForDeleteSurround()
    super

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
    if isLinewiseRange(range = selection.getBufferRange())
      selection.setBufferRange(range.translate([0, 0], [-1, Infinity]))
    selection.joinLines()
    end = selection.getBufferRange().end
    selection.cursor.setBufferPosition(end.translate([0, -1]))

class JoinBase extends TransformString
  @extend(false)
  wise: 'linewise'
  trim: false
  target: "MoveToRelativeLineMinimumOne"

  initialize: ->
    @focusInput(10) if @isRequireInput()
    super

  getNewText: (text) ->
    if @trim
      pattern = /\r?\n[ \t]*/g
    else
      pattern = /\r?\n/g
    text.trimRight().replace(pattern, @input) + "\n"

class JoinWithKeepingSpace extends JoinBase
  @extend()
  @registerToSelectList()
  input: ''

class JoinByInput extends JoinBase
  @extend()
  @registerToSelectList()
  @description: "Transform multi-line to single-line by with specified separator character"
  requireInput: true
  trim: true

class JoinByInputWithKeepingSpace extends JoinByInput
  @extend()
  @registerToSelectList()
  @description: "Join lines without padding space between each line"
  trim: false

# -------------------------
# String suffix in name is to avoid confusion with 'split' window.
class SplitString extends TransformString
  @extend()
  @registerToSelectList()
  @description: "Split single-line into multi-line by splitting specified separator chars"
  requireInput: true
  input: null
  target: "MoveToRelativeLine"
  keepSplitter: false

  initialize: ->
    @onDidSetTarget =>
      @focusInput(10)
    super

  getNewText: (text) ->
    input = @input or "\\n"
    regex = ///#{_.escapeRegExp(input)}///g
    if @keepSplitter
      lineSeparator = @input + "\n"
    else
      lineSeparator = "\n"
    text.replace(regex, lineSeparator)

class SplitStringWithKeepingSplitter extends SplitString
  @extend()
  @registerToSelectList()
  keepSplitter: true

class ChangeOrder extends TransformString
  @extend(false)
  wise: 'linewise'

  getNewText: (text) ->
    @getNewRows(splitTextByNewLine(text)).join("\n") + "\n"

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

class SortCaseInsensitively extends ChangeOrder
  @extend()
  @registerToSelectList()
  @description: "Sort lines alphabetically (case insensitive)"
  getNewRows: (rows) ->
    rows.sort (rowA, rowB) ->
      rowA.localeCompare(rowB, sensitivity: 'base')

class SortByNumber extends ChangeOrder
  @extend()
  @registerToSelectList()
  @description: "Sort lines numerically"
  getNewRows: (rows) ->
    _.sortBy rows, (row) ->
      Number.parseInt(row) or Infinity
