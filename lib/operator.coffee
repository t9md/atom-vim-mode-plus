# Refactoring status: 80%
_ = require 'underscore-plus'
{Point, Range, CompositeDisposable} = require 'atom'

{haveSomeSelection} = require './utils'
swrap = require './selection-wrapper'
settings = require './settings'
Base = require './base'

class OperatorError extends Base
  @extend(false)
  constructor: (@message) ->
    @name = 'Operator Error'

# General Operator
# -------------------------
class Operator extends Base
  @extend(false)
  recodable: true
  target: null
  flashTarget: true

  haveSomeSelection: ->
    haveSomeSelection(@editor.getSelections())

  isSameOperatorRepeated: ->
    if @vimState.isMode('operator-pending')
      @vimState.operationStack.peekTop().constructor is @constructor
    else
      false

  constructor: ->
    super
    #  To support, `dd`, `cc` and a like.
    if @isSameOperatorRepeated()
      @vimState.operationStack.run 'MoveToRelativeLine'
      @abort()

  # target - TextObject or Motion to operate on.
  compose: (@target) ->
    unless _.isFunction(@target.select)
      @vimState.emitter.emit('failed-to-compose')
      message = "Failed to compose #{@constructor.name} with #{@target.constructor.name}"
      throw new OperatorError(message)

    if _.isFunction(@target.onDidComposeBy)
      @target.onDidComposeBy(this)

  setTextToRegister: (text) ->
    if @target?.isLinewise?() and not text.endsWith('\n')
      text += "\n"
    if text
      @vimState.register.set({text})

  markCursorBufferPositions: ->
    markerByCursor = new Map
    markerOptions = {invalidate: 'never', persistent: false}
    for cursor in @editor.getCursors()
      point = cursor.getBufferPosition()
      marker = @editor.markBufferPosition point, markerOptions
      markerByCursor.set(cursor, marker)
    markerByCursor

  restoreMarkedCursorPositions: (markerByCursor) ->
    for cursor in @editor.getCursors()
      if marker = markerByCursor.get(cursor)
        cursor.setBufferPosition(marker.getStartBufferPosition())
    markerByCursor.forEach (marker, cursor) ->
      marker.destroy()
    markerByCursor.clear()

  withKeepingCursorPosition: (fn) ->
    markerByCursor = @markCursorBufferPositions()
    fn()
    @restoreMarkedCursorPositions(markerByCursor)

  markSelections: ->
    # [NOTE] selection.marker.copy() return undefined.
    # So I explictly create marker from getBufferRange().
    markerBySelections = {}
    for selection in @editor.getSelections()
      range = selection.getBufferRange()
      marker = @editor.markBufferRange range,
        invalidate: 'never',
        persistent: false
      markerBySelections[selection.id] = marker
    markerBySelections

  flash: (range, fn=null) ->
    options =
      range: range
      klass: 'vim-mode-plus-flash'
      timeout: settings.get('flashOnOperateDuration')
    @vimState.flasher.flash(options, fn)

  eachSelection: (fn) ->
    @target.select() unless @haveSomeSelection()
    return unless @haveSomeSelection()
    @editor.transact =>
      for s in @editor.getSelections()
        if @flashTarget and settings.get('flashOnOperate')
          @flash s.getBufferRange(), -> fn(s)
        else
          fn(s)

class Select extends Operator
  @extend()
  execute: ->
    @target.select()

class Delete extends Operator
  @extend()
  hoverText: ':scissors:'
  hoverIcon: ':delete:'
  flashTarget: false
  execute: ->
    @eachSelection (s) =>
      @setTextToRegister s.getText() if s.isLastSelection()
      s.deleteSelectedText()
      s.cursor.skipLeadingWhitespace() if @target.isLinewise?()
    @vimState.activate('normal')

class DeleteRight extends Delete
  @extend()
  initialize: ->
    @compose @new('MoveRight')

class DeleteLeft extends Delete
  @extend()
  initialize: ->
    @compose @new('MoveLeft')

class DeleteToLastCharacterOfLine extends Delete
  @extend()
  initialize: ->
    @compose @new('MoveToLastCharacterOfLine')

class TransformString extends Operator
  @extend(false)
  adjustCursor: true

  # [FIXME] duplicate to Yank, need to consolidate as like adjustCursor().
  execute: ->
    if @points?
      points = @points
    else if @target.isLinewise?() or settings.get('stayOnTransformString')
      points = _.pluck(@editor.getSelectedBufferRanges(), 'start')
    @eachSelection (s) =>
      range = s.insertText @getNewText(s.getText())
      if @adjustCursor
        s.cursor.setBufferPosition(points?.shift() ? range.start)
    @vimState.activate('normal')
    @points = null

class ToggleCase extends TransformString
  @extend()
  hoverText: ':clap:'
  hoverIcon: ':toggle-case:'
  toggleCase: (char) ->
    if (charLower = char.toLowerCase()) is char
      char.toUpperCase()
    else
      charLower

  getNewText: (text) ->
    text.split('').map(@toggleCase).join('')

class ToggleCaseAndMoveRight extends ToggleCase
  @extend()
  hoverText: null
  hoverIcon: null
  adjustCursor: false
  initialize: ->
    @compose @new('MoveRight')

class UpperCase extends TransformString
  @extend()
  hoverText: ':point_up:'
  hoverIcon: ':upper-case:'
  getNewText: (text) ->
    text.toUpperCase()

class LowerCase extends TransformString
  @extend()
  hoverText: ':point_down:'
  hoverIcon: ':lower-case:'
  getNewText: (text) ->
    text.toLowerCase()

class CamelCase extends TransformString
  @extend()
  hoverText: ':camel:'
  hoverIcon: ':camel-case:'
  getNewText: (text) ->
    _.camelize text

class SnakeCase extends TransformString
  @extend()
  hoverText: ':snake:'
  hoverIcon: ':snake-case:'
  getNewText: (text) ->
    _.underscore text

class DashCase extends TransformString
  @extend()
  hoverText: ':dash:'
  hoverIcon: ':dash-case:'
  getNewText: (text) ->
    _.dasherize text

class Surround extends TransformString
  @extend()
  pairs: ['[]', '()', '{}', '<>']
  input: null
  charsMax: 1
  hoverText: ':two_women_holding_hands:'
  hoverIcon: ':surround:'
  requireInput: true

  initialize: ->
    return unless @requireInput
    @onDidConfirmInput (input) => @onConfirm(input)
    @onDidChangeInput (input) => @vimState.hover.add(input)
    @onDidCancelInput => @vimState.operationStack.cancel()
    @vimState.input.focus({@charsMax})

  onConfirm: (@input) ->
    @vimState.operationStack.process()

  getPair: (input) ->
    pair = _.detect @pairs, (pair) -> input in pair
    pair ?= input + input

  surround: (text, pair) ->
    [open, close] = pair.split('')
    open + text + close

  getNewText: (text) ->
    @surround text, @getPair(@input)

class SurroundWord extends Surround
  @extend()
  initialize: ->
    super
    @compose @new('Word')

class DeleteSurround extends Surround
  @extend()
  pairChars: ['[]', '()', '{}'].join('')

  onConfirm: (@input) ->
    # FIXME: dont manage allowNextLine independently. Each Pair text-object can handle by themselvs.
    target = @new 'Pair',
      pair: @getPair(@input)
      inclusive: true
      allowNextLine: @input in @pairChars
    @compose(target)
    @vimState.operationStack.process()

  getNewText: (text) ->
    text[1...-1]

class DeleteSurroundAnyPair extends DeleteSurround
  @extend()
  requireInput: false
  initialize: ->
    super
    @compose @new("AnyPair", inclusive: true)

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

  initialize: ->
    @compose @new("AnyPair", inclusive: true)
    @preSelect()
    unless @haveSomeSelection()
      @vimState.reset()
      @abort()
    @vimState.hover.add(@editor.getSelectedText()[0])
    super

  # FIXME very inperative implementation. find more generic and consistent approach.
  # like preservePoints() and restorePoints().
  preSelect: ->
    if @target.isLinewise?() or settings.get('stayOnTransformString')
      @points = _.pluck(@editor.getSelectedBufferRanges(), 'start')
    @target.select()

  onConfirm: (@char) ->
    @input = @char
    @vimState.operationStack.process()

class Yank extends Operator
  @extend()
  hoverText: ':clipboard:'
  hoverIcon: ':yank:'
  execute: ->
    if @target.isLinewise?()
      points = (s.getBufferRange().start for s in @editor.getSelections())
    @eachSelection (s) =>
      @setTextToRegister s.getText() if s.isLastSelection()
      point = points?.shift() ? s.getBufferRange().start
      s.cursor.setBufferPosition point
    @vimState.activate('normal')

class YankLine extends Yank
  @extend()
  initialize: ->
    @compose @new('MoveToRelativeLine')

class Join extends Operator
  @extend()
  complete: true
  execute: ->
    @editor.transact =>
      _.times @getCount(), =>
        @editor.joinLines()
    @vimState.activate('normal')

class Repeat extends Operator
  @extend()
  complete: true
  recodable: false
  execute: ->
    @editor.transact =>
      _.times @getCount(), =>
        @vimState.operationStack.getRecorded()?.execute()

class Mark extends Operator
  @extend()
  hoverText: ':round_pushpin:'
  hoverIcon: ':mark:'
  requireInput: true
  initialize: ->
    @focusInput()

  execute: ->
    @vimState.mark.set(@input, @editor.getCursorBufferPosition())
    @vimState.activate('normal')

# [FIXME?]: inconsistent behavior from normal operator
# Since its support visual-mode but not use @target and compose convension.
# Maybe separating complete/in-complete version like IncreaseNow and Increase?
class Increase extends Operator
  @extend()
  complete: true
  step: 1

  execute: ->
    pattern = ///#{settings.get('numberRegex')}///g

    newRanges = []
    @editor.transact =>
      for c in @editor.getCursors()
        scanRange = if @vimState.isMode('visual')
          c.selection.getBufferRange()
        else
          c.getCurrentLineBufferRange()
        ranges = @increaseNumber(c, scanRange, pattern)
        if not @vimState.isMode('visual') and ranges.length
          c.setBufferPosition ranges[0].end.translate([0, -1])
        newRanges.push ranges

    if (newRanges = _.flatten(newRanges)).length
      @flash newRanges if settings.get('flashOnOperate')
    else
      atom.beep()

  increaseNumber: (cursor, scanRange, pattern) ->
    newRanges = []
    @editor.scanInBufferRange pattern, scanRange, ({matchText, range, stop, replace}) =>
      newText = String(parseInt(matchText, 10) + @step * @getCount())
      if @vimState.isMode('visual')
        newRanges.push replace(newText)
      else
        return unless range.end.isGreaterThan cursor.getBufferPosition()
        newRanges.push replace(newText)
        stop()
    newRanges

class Decrease extends Increase
  @extend()
  step: -1

class IncrementNumber extends Operator
  @extend()
  step: 1
  baseNumber: null

  execute: ->
    pattern = ///#{settings.get('numberRegex')}///g
    newRanges = null
    @target.select() unless @haveSomeSelection()
    @editor.transact =>
      newRanges = for s in @editor.getSelectionsOrderedByBufferPosition()
        @replaceNumber(s.getBufferRange(), pattern)
    if (newRanges = _.flatten(newRanges)).length
      @flash newRanges if settings.get('flashOnOperate')
    else
      atom.beep()
    # Reverseing selection put cursor on start position of selection.
    # This allow increment/decrement works in same target range when repeated.
    swrap.setReversedState(@editor, true)
    @vimState.activate('normal')

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
  step: -1

class Indent extends Operator
  @extend()
  hoverText: ':point_right:'
  hoverIcon: ':indent:'
  execute: ->
    @eachSelection (s) =>
      startRow = s.getBufferRange().start.row
      @indent(s)
      s.cursor.setBufferPosition([startRow, 0])
      s.cursor.moveToFirstCharacterOfLine()
    @vimState.activate('normal')

  indent: (s) ->
    s.indentSelectedRows()

class Outdent extends Indent
  @extend()
  hoverText: ':point_left:'
  hoverIcon: ':outdent:'

  indent: (s) ->
    s.outdentSelectedRows()

class AutoIndent extends Indent
  @extend()
  hoverText: ':open_hands:'
  hoverIcon: ':auto-indent:'
  indent: (s) ->
    s.autoIndentSelectedRows()

# Put
# -------------------------
class PutBefore extends Operator
  @extend()
  complete: true
  location: 'before'

  execute: ->
    {text, type} = @vimState.register.get()
    return unless text
    text = _.multiplyString(text, @getCount())
    paste = switch
      when type is 'linewise', @vimState.isMode('visual', 'linewise')
        @pasteLinewise
      when 'character'
        @pasteCharacterwise

    @editor.transact =>
      paste(s, text) for s in @editor.getSelections()
    @vimState.activate('normal')

  pasteLinewise: (selection, text) => # fat
    cursor = selection.cursor
    if selection.isEmpty()
      if @location is 'before'
        cursor.moveToBeginningOfLine()
        selection.insertText("\n")
        cursor.moveUp()
      else
        cursor.moveToEndOfLine()
        selection.insertText("\n")
      text = text.replace(/\n$/, '')
    else
      if @vimState.isMode('visual', 'linewise')
        text += '\n' unless text.endsWith('\n')
      else
        selection.insertText("\n")
    range = selection.insertText(text)
    @flash range
    cursor.setBufferPosition(range.start)
    cursor.moveToFirstCharacterOfLine()

  pasteCharacterwise: (selection, text) => # fat
    cursor = selection.cursor
    if @location is 'after' and selection.isEmpty()
      cursor.moveRight()
    range = selection.insertText(text)
    @flash range
    cursor.setBufferPosition(range.end.translate([0, -1]))

class PutAfter extends PutBefore
  @extend()
  location: 'after'

class ReplaceWithRegister extends Operator
  @extend()
  hoverText: ':pencil:'
  hoverIcon: ':replace-with-register:'
  execute: ->
    @eachSelection (s) =>
      range = s.getBufferRange()
      newText = @vimState.register.get().text ? s.getText()
      s.deleteSelectedText()
      s.insertText(newText)
      s.cursor.setBufferPosition(range.start)
    @vimState.activate('normal')

class ToggleLineComments extends Operator
  @extend()
  hoverText: ':mute:'
  hoverIcon: ':toggle-line-comment:'
  execute: ->
    @withKeepingCursorPosition =>
      @eachSelection (s) ->
        s.toggleLineComments()
    @vimState.activate('normal')

# Input
# -------------------------
# The operation for text entered in input mode. Broadly speaking, input
# operators manage an undo transaction and set a @typingCompleted variable when
# it's done. When the input operation is completed, the typingCompleted variable
# tells the operation to repeat itself instead of enter insert mode.
class ActivateInsertMode extends Operator
  @extend()
  complete: true
  typedText: null
  flashTarget: false

  confirmChanges: (changes) ->
    bundler = new TransactionBundler(changes, @editor)
    @typedText = bundler.buildInsertText()

  execute: ->
    if @typedText?
      return unless @typedText
      @editor.insertText(@typedText, normalizeLineEndings: true, autoIndent: true)
      for cursor in @editor.getCursors() when not cursor.isAtBeginningOfLine()
        cursor.moveLeft()
    else
      @vimState.activate('insert')

class InsertAtLastInsert extends ActivateInsertMode
  @extend()
  initialize: ->
    if (point = @vimState.mark.get('^'))
      @editor.setCursorBufferPosition(point)
      @editor.scrollToCursorPosition({center: true})

class ActivateReplaceMode extends ActivateInsertMode
  @extend()

  execute: ->
    if @typedText?
      return unless @typedText
      @editor.transact =>
        @editor.insertText(@typedText, normalizeLineEndings: true)
        toDelete = @typedText.length - @countChars('\n', @typedText)
        for selection in @editor.getSelections()
          count = toDelete
          selection.delete() while count-- and not selection.cursor.isAtEndOfLine()
        for cursor in @editor.getCursors() when not cursor.isAtBeginningOfLine()
          cursor.moveLeft()
    else
      @vimState.activate('insert', 'replace')

  countChars: (char, string) ->
    string.split(char).length - 1

class InsertAfter extends ActivateInsertMode
  @extend()
  execute: ->
    @editor.moveRight() unless @editor.getLastCursor().isAtEndOfLine()
    super

class InsertAfterEndOfLine extends ActivateInsertMode
  @extend()
  execute: ->
    @editor.moveToEndOfLine()
    super

class InsertAtBeginningOfLine extends ActivateInsertMode
  @extend()
  execute: ->
    @editor.moveToFirstCharacterOfLine()
    super

# FIXME need support count
class InsertAboveWithNewline extends ActivateInsertMode
  @extend()
  direction: 'above'
  execute: ->
    @vimState.setInsertionCheckpoint() unless @typedText?
    switch @direction
      when 'above' then @editor.insertNewlineAbove()
      when 'below' then @editor.insertNewlineBelow()
    @editor.getLastCursor().skipLeadingWhitespace()

    if @typedText?
      # We'll have captured the inserted newline, but we want to do that
      # over again by hand, or differing indentations will be wrong.
      @typedText = @typedText.trimLeft()
      super
    else
      @vimState.activate('insert')

class InsertBelowWithNewline extends InsertAboveWithNewline
  @extend()
  direction: 'below'

# Delete the following motion and enter insert mode to replace it.
class Change extends ActivateInsertMode
  @extend()
  complete: false

  execute: ->
    # If we've typed, we're being repeated. If we're being repeated,
    # undo transactions are already handled.
    @vimState.setInsertionCheckpoint() unless @typedText?

    @target.setOptions? excludeWhitespace: true

    @target.select()
    if @haveSomeSelection()
      @setTextToRegister @editor.getSelectedText()
      if @target.isLinewise?() and not @typedText?
        for selection in @editor.getSelections()
          selection.insertText("\n", autoIndent: true)
          selection.cursor.moveLeft()
      else
        for selection in @editor.getSelections()
          selection.deleteSelectedText()

    return super if @typedText?

    @vimState.activate('insert')

class Substitute extends Change
  @extend()
  initialize: ->
    @compose @new('MoveRight')

class SubstituteLine extends Change
  @extend()
  initialize: ->
    @compose @new("MoveToRelativeLine")

class ChangeToLastCharacterOfLine extends Change
  @extend()
  initialize: ->
    @compose @new('MoveToLastCharacterOfLine')

# Takes a transaction and turns it into a string of what was typed.
# This class is an implementation detail of ActivateInsertMode
class TransactionBundler
  constructor: (@changes, @editor) ->
    @start = null
    @end = null

  buildInsertText: ->
    @addChange(change) for change in @changes
    if @start?
      @editor.getTextInBufferRange [@start, @end]
    else
      ""

  addChange: (change) ->
    return unless change.newRange?
    if @isRemovingFromPrevious(change)
      @subtractRange change.oldRange
    if @isAddingWithinPrevious(change)
      @addRange change.newRange

  isAddingWithinPrevious: (change) ->
    return false unless @isAdding(change)

    return true if @start is null

    @start.isLessThanOrEqual(change.newRange.start) and
      @end.isGreaterThanOrEqual(change.newRange.start)

  isRemovingFromPrevious: (change) ->
    return false unless @isRemoving(change) and @start?

    @start.isLessThanOrEqual(change.oldRange.start) and
      @end.isGreaterThanOrEqual(change.oldRange.end)

  isAdding: (change) ->
    change.newText.length > 0

  isRemoving: (change) ->
    change.oldText.length > 0

  addRange: (range) ->
    if @start is null
      {@start, @end} = range
      return

    rows = range.end.row - range.start.row

    if (range.start.row is @end.row)
      cols = range.end.column - range.start.column
    else
      cols = 0

    @end = @end.translate [rows, cols]

  subtractRange: (range) ->
    rows = range.end.row - range.start.row

    if (range.end.row is @end.row)
      cols = range.end.column - range.start.column
    else
      cols = 0
    @end = @end.translate [-rows, -cols]

# Replace
# -------------------------
class Replace extends Operator
  @extend()
  input: null
  hoverText: ':tractor:'
  requireInput: true

  initialize: ->
    @focusInput()

  isComplete: ->
    @input = "\n" if @input is ''
    super

  execute: ->
    count = @getCount()

    @editor.transact =>
      if @target?
        @target.select()
        if @haveSomeSelection()
          @editor.replaceSelectedText null, (text) =>
            text.replace(/./g, @input)
          for selection in @editor.getSelections()
            point = selection.getBufferRange().start
            selection.setBufferRange(Range.fromPointWithDelta(point, 0, 0))
      else
        for cursor in @editor.getCursors()
          pos = cursor.getBufferPosition()
          currentRowLength = @editor.lineTextForBufferRow(pos.row).length
          continue unless currentRowLength - pos.column >= count

          _.times count, =>
            point = cursor.getBufferPosition()
            @editor.setTextInBufferRange(Range.fromPointWithDelta(point, 0, 1), @input)
            cursor.moveRight()
          cursor.setBufferPosition(pos)

        # Special case: when replaced with a newline move to the start of the
        # next row.
        if @input is "\n"
          _.times count, =>
            @editor.moveDown()
          @editor.moveToFirstCharacterOfLine()

    @vimState.activate('normal')
