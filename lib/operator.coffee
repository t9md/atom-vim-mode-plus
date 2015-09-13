# Refactoring status: 80%
_ = require 'underscore-plus'
{Point, Range} = require 'atom'
{CompositeDisposable} = require 'atom'

settings = require './settings'
Base = require './base'

class OperatorError extends Base
  @extend()
  constructor: (@message) ->
    @name = 'Operator Error'

# General Operator
# -------------------------
class Operator extends Base
  @extend()
  target: null
  complete: false
  recodable: true
  linewiseAlias: false

  isSameOperatorRepeated: ->
    if @linewiseAlias and @vimState.isOperatorPendingMode()
      @vimState.operationStack.peekTop().constructor is @constructor
    else
      false

  constructor: ->
    super
    #  To support, `dd`, `cc`, `yy` `>>`, `<<`, `==`
    if @isSameOperatorRepeated()
      @vimState.operationStack.push @new('MoveToRelativeLine')
      @abort()

  # target - TextObject or Motion to operate on.
  compose: (target) ->
    unless _.isFunction(target.select)
      @vimState.emitter.emit('failed-to-compose')
      throw new OperatorError("Failed to compose #{@getKind()} with #{target.getKind()}")

    @target = target
    if _.isFunction(target.onDidComposeBy)
      @target.onDidComposeBy(this)

  setTextToRegister: (text) ->
    if @target?.isLinewise?() and not text.endsWith('\n')
      text += "\n"
    if text
      @vimState.register.set({text})

  markCursorBufferPositions: ->
    markerByCursor = {}
    for cursor in @editor.getCursors()
      point = cursor.getBufferPosition()
      markerByCursor[cursor.id] = @editor.markBufferPosition point,
        invalidate: 'never',
        persistent: false
    markerByCursor

  restoreMarkedCursorPositions: (markerByCursor) ->
    for cursor in @editor.getCursors()
      if marker = markerByCursor[cursor.id]
        cursor.setBufferPosition marker.getStartBufferPosition()
    for key, marker of markerByCursor
      marker.destroy()

  markSelections: ->
    # [BUG] selection.marker.copy() return undefined.
    # So I explictly create marker from getBufferRange().
    markerBySelections = {}
    for selection in @editor.getSelections()
      range = selection.getBufferRange()
      marker = @editor.markBufferRange range,
        invalidate: 'never',
        persistent: false
      markerBySelections[selection.id] = marker
    markerBySelections

  flash: (range) ->
    marker = @editor.markBufferRange range,
      invalidate: 'never',
      persistent: false

    @editor.decorateMarker marker,
      type: 'highlight'
      class: 'vim-mode-flash'

    setTimeout  ->
      marker.destroy()
    , settings.get('flashOnOperateDurationMilliSeconds')

  withFlashing: (callback) ->
    unless settings.get('flashOnOperate')
      callback()
      return

    markerBySelections = @markSelections()
    callback()
    for selection in @editor.getSelections()
      @editor.decorateMarker markerBySelections[selection.id],
        type: 'highlight'
        class: 'vim-mode-flash'

    # Ensure destroy all marker
    setTimeout  ->
      marker.destroy() for __, marker of markerBySelections
    , settings.get('flashOnOperateDurationMilliSeconds')

class Select extends Operator
  @extend()
  execute: ->
    @target.select()

# # [VERY EXPERIMENTAL DONT USE THIS]
class OperateOnInnerWord extends Operator
  @extend()

  constructor: ->
    super
    @new('Word').select()
    unless @vimState.isVisualMode()
      @vimState.activateVisualMode()

  compose: (target) ->
    if target.isCurrentSelection()
      return

    unless target.isOperator()
      @vimState.emitter.emit('failed-to-compose')
      throw new OperatorError("Failed to compose #{@getKind()} with #{target.getKind()}")
    @operator = target
    @complete = true

  execute: ->
    if @editor.getLastSelection().isEmpty()
      @operator.compose @new('Word')
    else
      @operator.compose @new('CurrentSelection')
    @operator.execute()

class Delete extends Operator
  @extend()
  linewiseAlias: true
  hoverText: ':scissors:'
  hoverIcon: ':delete:'

  execute: ->
    if _.any @target.select()
      @setTextToRegister @editor.getSelectedText()
      @editor.transact =>
        for selection in @editor.getSelections()
          selection.deleteSelectedText()
      if @target.isLinewise?()
        for cursor in @editor.getCursors()
          cursor.skipLeadingWhitespace()
    @vimState.activateNormalMode()

class DeleteRight extends Delete
  @extend()
  constructor: ->
    super
    @compose @new('MoveRight')

class DeleteLeft extends Delete
  @extend()
  constructor: ->
    super
    @compose @new('MoveLeft')

class DeleteToLastCharacterOfLine extends Delete
  @extend()
  constructor: ->
    super
    @compose @new('MoveToLastCharacterOfLine')

class TransformString extends Operator
  @extend()
  adjustCursor: true
  linewiseAlias: true

  # [FIXME] duplicate to Yank, need to consolidate as like adjustCursor().
  execute: ->
    if @target.isLinewise?() or settings.get('stayOnTransformString')
      points = _.pluck(@editor.getSelectedBufferRanges(), 'start')
    if _.any @target.select()
      @withFlashing =>
        for selection in @editor.getSelections()
          range = selection.insertText @getNewText(selection.getText())
          if @adjustCursor
            selection.cursor.setBufferPosition(points?.shift() ? range.start)
    @vimState.activateNormalMode()

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
  constructor: ->
    super
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
  hoverIcon: ':snake-case:' # [FIXME]
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

  constructor: ->
    super
    @getInput
      charsMax: @charsMax,
      onGet:    @onDidGetInput.bind(this)
      onChange: @vimState.hover.add.bind(@vimState.hover)

  onDidGetInput: (@input) ->
    @vimState.operationStack.process()

  getPair: (input) ->
    pair = _.detect @pairs, (pair) -> input in pair
    pair ?= input+input

  surround: (text, pair) ->
    [open, close] = pair.split('')
    open + text + close

  getNewText: (text) ->
    @surround text, @getPair(@input)

class DeleteSurround extends Surround
  @extend()
  onDidGetInput: (@input) ->
    @compose @new('Pair', pair: @getPair(@input), inclusive: true)
    @vimState.operationStack.process()

  getNewText: (text) ->
    text[1...-1]

class ChangeSurround extends DeleteSurround
  @extend()
  charsMax: 2
  char: null

  onDidGetInput: (input) ->
    return unless input
    [from, @char] = input.split('')
    super(from)

  getNewText: (text) ->
    @surround text[1...-1], @getPair(@char)

class Yank extends Operator
  @extend()
  linewiseAlias: true
  hoverText: ':clipboard:'
  hoverIcon: ':yank:'
  execute: ->
    if @target.isLinewise?()
      points = (s.getBufferRange().start for s in @editor.getSelections())
    if _.any @target.select()
      @withFlashing ->
      @setTextToRegister @editor.getSelectedText()
      for selection in @editor.getSelections()
        point = points?.shift() ? selection.getBufferRange().start
        selection.cursor.setBufferPosition point
    @vimState.activateNormalMode()

class YankLine extends Yank
  @extend()
  constructor: ->
    super
    @compose @new('MoveToRelativeLine')

class Join extends Operator
  @extend()
  complete: true
  execute: ->
    @editor.transact =>
      _.times @getCount(1), =>
        @editor.joinLines()
    @vimState.activateNormalMode()

class Repeat extends Operator
  @extend()
  complete: true
  recodable: false
  execute: ->
    @editor.transact =>
      _.times @getCount(1), =>
        @vimState.history[0]?.execute()

class Mark extends Operator
  @extend()
  hoverText: ':round_pushpin:'
  hoverIcon: ':mark:'
  requireInput: true
  constructor: ->
    super
    @getInput()

  execute: ->
    @vimState.mark.set(@input, @editor.getCursorBufferPosition())
    @vimState.activateNormalMode()

class Increase extends Operator
  @extend()
  complete: true
  step: 1

  execute: ->
    pattern = new RegExp(settings.get('numberRegex'), 'g')
    @editor.transact =>
      unless _.any(@increaseNumber(c, pattern) for c in @editor.getCursors())
        atom.beep()

  increaseNumber: (cursor, pattern) ->
    success = null
    scanRange = cursor.getCurrentLineBufferRange()
    @editor.scanInBufferRange pattern, scanRange, ({matchText, range, stop, replace}) =>
      unless range.end.isGreaterThan cursor.getBufferPosition()
        return
      number = parseInt(matchText, 10) + @step * @getCount(1)
      newText = String(number)
      replace newText
      stop()
      cursor.setBufferPosition(range.start.translate([0, newText.length-1]))
      success = true
    success

class Decrease extends Increase
  @extend()
  step: -1

class Indent extends Operator
  @extend()
  linewiseAlias: true
  hoverText: ':point_right:'
  # hoverIcon: ':indent:'
  hoverIcon: ':indent:'
  execute: ->
    @target.select()
    startRow = @editor.getSelectedBufferRange().start.row
    @indent()
    @editor.setCursorBufferPosition([startRow, 0])
    @editor.moveToFirstCharacterOfLine()
    @vimState.activateNormalMode()

  indent: ->
    @editor.indentSelectedRows()

class Outdent extends Indent
  @extend()
  hoverText: ':point_left:'
  hoverIcon: ':outdent:'

  indent: ->
    @editor.outdentSelectedRows()

class AutoIndent extends Indent
  @extend()
  hoverText: ':open_hands:'
  hoverIcon: ':auto-indent:'
  indent: ->
    @editor.autoIndentSelectedRows()

# Put
# -------------------------
class PutBefore extends Operator
  @extend()
  complete: true
  location: 'before'

  execute: ->
    {text, type} = @vimState.register.get()
    return unless text
    text = _.multiplyString(text, @getCount(1))
    @editor.transact =>
      for selection in @editor.getSelections()
        switch type
          when 'linewise'  then @pasteLinewise(selection, text)
          when 'character' then @pasteCharacterwise(selection, text)
    @vimState.activateNormalMode()

  pasteLinewise: (selection, text) ->
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
      range = selection.insertText(text)
      @flash range
      cursor.setBufferPosition(range.start)
      cursor.moveToFirstCharacterOfLine()
    else
      selection.insertText("\n")
      range = selection.insertText(text)
      @flash range
      cursor.setBufferPosition(range.start)

  pasteCharacterwise: (selection, text) ->
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
    if _.any @target.select()
      @withFlashing =>
        points = _.pluck(@editor.getSelectedBufferRanges(), 'start')
        @editor.replaceSelectedText {}, (text) =>
          @vimState.register.get().text ? text
        ranges = (new Range(p, p) for p in points)
        @editor.setSelectedBufferRanges(ranges)
    @vimState.activateNormalMode()

class ToggleLineComments extends Operator
  @extend()
  hoverText: ':mute:'
  hoverIcon: ':toggle-line-comment:'
  execute: ->
    markerByCursor = @markCursorBufferPositions()
    if _.any @target.select()
      @withFlashing =>
        @editor.transact =>
          for s in @editor.getSelections()
            s.toggleLineComments()
    @restoreMarkedCursorPositions markerByCursor
    @vimState.activateNormalMode()

# Input
# -------------------------
# The operation for text entered in input mode. Broadly speaking, input
# operators manage an undo transaction and set a @typingCompleted variable when
# it's done. When the input operation is completed, the typingCompleted variable
# tells the operation to repeat itself instead of enter insert mode.
class Insert extends Operator
  @extend()
  complete: true
  typedText: null

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
      @vimState.activateInsertMode()

class ReplaceMode extends Insert
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
      @vimState.activateReplaceMode()

  countChars: (char, string) ->
    string.split(char).length - 1

class InsertAfter extends Insert
  @extend()
  execute: ->
    @editor.moveRight() unless @editor.getLastCursor().isAtEndOfLine()
    super

class InsertAfterEndOfLine extends Insert
  @extend()
  execute: ->
    @editor.moveToEndOfLine()
    super

class InsertAtBeginningOfLine extends Insert
  @extend()
  execute: ->
    @editor.moveToFirstCharacterOfLine()
    super

# FIXME need support count
class InsertAboveWithNewline extends Insert
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
      @vimState.activateInsertMode()

class InsertBelowWithNewline extends InsertAboveWithNewline
  @extend()
  direction: 'below'

#
# Delete the following motion and enter insert mode to replace it.
#
class Change extends Insert
  @extend()
  complete: false
  linewiseAlias: true

  execute: ->
    # If we've typed, we're being repeated. If we're being repeated,
    # undo transactions are already handled.
    @vimState.setInsertionCheckpoint() unless @typedText?

    @target.setOptions? excludeWhitespace: true

    if _.any @target.select()
      @setTextToRegister @editor.getSelectedText()
      if @target.isLinewise?() and not @typedText?
        for selection in @editor.getSelections()
          selection.insertText("\n", autoIndent: true)
          selection.cursor.moveLeft()
      else
        for selection in @editor.getSelections()
          selection.deleteSelectedText()

    return super if @typedText?

    @vimState.activateInsertMode()

class Substitute extends Change
  @extend()
  constructor: ->
    super
    @compose @new('MoveRight')

class SubstituteLine extends Change
  @extend()
  constructor: ->
    super
    @compose @new("MoveToRelativeLine")

class ChangeToLastCharacterOfLine extends Change
  @extend()
  constructor: ->
    super
    @compose @new('MoveToLastCharacterOfLine')

# Takes a transaction and turns it into a string of what was typed.
# This class is an implementation detail of Insert
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

  constructor: ->
    super
    @getInput(defaultInput: "\n")

  execute: ->
    count = @getCount(1)

    @editor.transact =>
      if @target?
        if _.any @target.select()
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

    @vimState.activateNormalMode()

# Alias
ActivateInsertMode = Insert
ActivateReplaceMode = ReplaceMode

module.exports = {
  # General
  Operator, OperatorError, Delete,
  Select,

  Yank, Join, Repeat, Mark,
  Increase, Decrease,
  Indent, Outdent, AutoIndent,

  # String transformation
  ToggleCase, ToggleCaseAndMoveRight,
  UpperCase, LowerCase
  CamelCase, SnakeCase, DashCase
  Surround, DeleteSurround, ChangeSurround

  # Put
  PutBefore, PutAfter,

  # Input
  Insert
  InsertAfter
  InsertAfterEndOfLine
  InsertAtBeginningOfLine
  InsertAboveWithNewline
  InsertBelowWithNewline
  ReplaceMode
  Change
  Substitute
  SubstituteLine
  Replace

  ChangeToLastCharacterOfLine
  DeleteRight
  DeleteLeft
  DeleteToLastCharacterOfLine
  YankLine

  # [FIXME] Only to map from command-name. remove in future.
  ActivateInsertMode
  ActivateReplaceMode

  ReplaceWithRegister
  ToggleLineComments

  OperateOnInnerWord
}
