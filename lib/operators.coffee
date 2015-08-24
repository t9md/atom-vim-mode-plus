# Refactoring status: 80%
_ = require 'underscore-plus'
{Point, Range} = require 'atom'

{ViewModel} = require './view'
settings = require './settings'
Base = require './base'
{
  MoveToRelativeLine
  MoveRight
  MoveLeft
  MoveToLastCharacterOfLine
  MoveToRelativeLine
} = require './motions'


class OperatorError extends Base
  @extend()
  constructor: (@message) ->
    @name = 'Operator Error'

# General Operators
# -------------------------
class Operator extends Base
  @extend()
  target: null
  complete: false
  recodable: true
  lineWiseAlias: false

  constructor: ->
    super
    #  To support, `dd`, `cc`, `yy` `>>`, `<<`, `==`
    if @lineWiseAlias and @vimState.isOperatorPendingMode() and
      @vimState.operationStack.peekTop().constructor is @constructor
        @vimState.operationStack.push new MoveToRelativeLine(@vimState)
        @abort()

  # target - TextObject or Motion to operate on.
  compose: (target) ->
    unless _.isFunction(target.select)
      @vimState.emitter.emit('failed-to-compose')
      throw new OperatorError("Failed to compose #{@getKind()} with #{target.getKind()}")

    @target = target
    if _.isFunction(target.onDidComposeBy)
      @target.onDidComposeBy(this)

  getInput: (args...) ->
    viewModel = new ViewModel(args...)
    viewModel.onDidGetInput (@input) =>
      @complete = true
      @vimState.operationStack.process() # Re-process!!

  getRegisterName: ->
    @vimState.register.getName()

  setTextToRegister: (text) ->
    if @target?.isLinewise?() and not text.endsWith('\n')
      text += "\n"
    if text
      @vimState.register.set(@getRegisterName(), {text})

  execute: ->
    @editor.transact =>
      @operate()
    @vimState.activateNormalMode()

class Select extends Operator
  @extend()
  execute: ->
    @target.select @getCount()

class Delete extends Operator
  @extend()
  lineWiseAlias: true

  execute: ->
    if _.any @target.select()
      @setTextToRegister @editor.getSelectedText()
      @editor.transact =>
        for selection in @editor.getSelections()
          selection.deleteSelectedText()
      for cursor in @editor.getCursors()
        if @target.isLinewise?()
          cursor.skipLeadingWhitespace()
        else
          cursor.moveLeft() if cursor.isAtEndOfLine() and not cursor.isAtBeginningOfLine()

    @vimState.activateNormalMode()

class DeleteRight extends Delete
  @extend()
  constructor: ->
    super
    @compose(new MoveRight(@vimState))

class DeleteLeft extends Delete
  @extend()
  constructor: ->
    super
    @compose(new MoveLeft(@vimState))

class DeleteToLastCharacterOfLine extends Delete
  @extend()
  constructor: ->
    super
    @compose(new MoveToLastCharacterOfLine(@vimState))

class ToggleCase extends Operator
  @extend()
  toggleCase: (char) ->
    if (charLower = char.toLowerCase()) is char
      char.toUpperCase()
    else
      charLower

  getNewText: (text) ->
    (@toggleCase(char) for char in text.split('')).join('')

  execute: ->
    if _.any @target.select()
      @editor.replaceSelectedText {}, @getNewText.bind(this)
    @vimState.activateNormalMode()

# [TODO] Rename to ToggleCaseAndMoveRight
class ToggleCaseNow extends ToggleCase
  @extend()
  constructor: ->
    super
    @compose(new MoveRight(@vimState))

class UpperCase extends ToggleCase
  @extend()
  getNewText: (text) ->
    text.toUpperCase()

class LowerCase extends ToggleCase
  @extend()
  getNewText: (text) ->
    text.toLowerCase()

class Yank extends Operator
  @extend()
  lineWiseAlias: true
  execute: ->
    originalPositions = @editor.getCursorBufferPositions()
    if _.any @target.select()
      @setTextToRegister @editor.getSelectedText()
      startPositions = _.pluck(@editor.getSelectedBufferRanges(), "start")
      # [FIXME] I can't understand this complexity.
      # Let activateNormalMode do cursor position handling.
      newPositions =
        for originalPosition, i in originalPositions
          if startPositions[i] and (@vimState.isVisualMode() or not @target.isLinewise?())
            Point.min(startPositions[i], originalPositions[i])
          else
            originalPosition
      @editor.setSelectedBufferRanges(newPositions.map (p) ->
        new Range(p, p))

    @vimState.activateNormalMode()

class YankLine extends Yank
  @extend()
  constructor: ->
    super
    @compose(new MoveToRelativeLine(@vimState))

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
  constructor: ->
    super
    @getInput this,
      class: 'mark'
      singleChar: true
      hidden: true

  execute: ->
    @vimState.mark.set(@input, @editor.getCursorBufferPosition())
    @vimState.activateNormalMode()

class Increase extends Operator
  @extend()
  complete: true
  step: 1

  constructor: ->
    super
    @numberRegex = new RegExp(settings.get('numberRegex'), 'g')

  execute: ->
    @editor.transact =>
      results = (@increaseNumber(cursor) for cursor in @editor.getCursors())
      unless _.any(results)
        atom.beep()

  increaseNumber: (cursor) ->
    success = null
    scanRange = cursor.getCurrentLineBufferRange()
    @editor.scanInBufferRange @numberRegex, scanRange, ({matchText, range, stop, replace}) =>
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
  lineWiseAlias: true
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
  indent: ->
    @editor.outdentSelectedRows()

class AutoIndent extends Indent
  @extend()
  indent: ->
    @editor.autoIndentSelectedRows()

# Put
# -------------------------
class Put extends Operator
  @extend()
  register: null
  complete: true
  execute: ->
    {text, type} = @vimState.register.get(@getRegisterName()) ? {}
    return unless text

    text = _.multiplyString(text, @getCount(1))

    selection = @editor.getSelectedBufferRange()
    if selection.isEmpty()
      # Clean up some corner cases on the last line of the file
      if type is 'linewise'
        text = text.replace(/\n$/, '')
        if @location is 'after' and @onLastRow()
          text = "\n#{text}"
        else
          text = "#{text}\n"

      if @location is 'after'
        if type is 'linewise'
          if @onLastRow()
            @editor.moveToEndOfLine()

            originalPosition = @editor.getCursorScreenPosition()
            originalPosition.row += 1
          else
            @editor.moveDown()
        else
          unless @onLastColumn()
            @editor.moveRight()

      if type is 'linewise' and not originalPosition?
        @editor.moveToBeginningOfLine()
        originalPosition = @editor.getCursorScreenPosition()

    @editor.insertText(text)

    if originalPosition?
      @editor.setCursorScreenPosition(originalPosition)
      @editor.moveToFirstCharacterOfLine()

    if type isnt 'linewise'
      @editor.moveLeft()
    @vimState.activateNormalMode()

  # Private: Helper to determine if the editor is currently on the last row.
  #
  # Returns true on the last row and false otherwise.
  onLastRow: ->
    {row, column} = @editor.getCursorBufferPosition()
    row is @editor.getBuffer().getLastRow()

  onLastColumn: ->
    @editor.getLastCursor().isAtEndOfLine()

class PutBefore extends Put
  @extend()
  location: 'before'

class PutAfter extends Put
  @extend()
  location: 'after'

# Input
# -------------------------
# The operation for text entered in input mode. Broadly speaking, input
# operators manage an undo transaction and set a @typingCompleted variable when
# it's done. When the input operation is completed, the typingCompleted variable
# tells the operation to repeat itself instead of enter insert mode.
class Insert extends Operator
  @extend()
  complete: true

  confirmChanges: (changes) ->
    bundler = new TransactionBundler(changes, @editor)
    @typedText = bundler.buildInsertText()

  execute: ->
    if @typingCompleted
      return unless @typedText? and @typedText.length > 0
      @editor.insertText(@typedText, normalizeLineEndings: true, autoIndent: true)
      for cursor in @editor.getCursors()
        cursor.moveLeft() unless cursor.isAtBeginningOfLine()
    else
      @vimState.activateInsertMode()
      @typingCompleted = true
    return

  inputOperator: ->
    true

class ReplaceMode extends Insert
  @extend()

  execute: ->
    if @typingCompleted
      return unless @typedText? and @typedText.length > 0
      @editor.transact =>
        @editor.insertText(@typedText, normalizeLineEndings: true)
        toDelete = @typedText.length - @countChars('\n', @typedText)
        for selection in @editor.getSelections()
          count = toDelete
          selection.delete() while count-- and not selection.cursor.isAtEndOfLine()
        for cursor in @editor.getCursors()
          cursor.moveLeft() unless cursor.isAtBeginningOfLine()
    else
      @vimState.activateReplaceMode()
      @typingCompleted = true

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
    @editor.moveToBeginningOfLine()
    @editor.moveToFirstCharacterOfLine()
    super

class InsertAboveWithNewline extends Insert
  @extend()
  # FIXME need support count
  execute: ->
    @vimState.setInsertionCheckpoint() unless @typingCompleted
    @editor.insertNewlineAbove()
    @editor.getLastCursor().skipLeadingWhitespace()

    if @typingCompleted
      # We'll have captured the inserted newline, but we want to do that
      # over again by hand, or differing indentations will be wrong.
      @typedText = @typedText.trimLeft()
      return super

    @vimState.activateInsertMode()
    @typingCompleted = true

class InsertBelowWithNewline extends Insert
  @extend()
  # FIXME need support count
  execute: ->
    @vimState.setInsertionCheckpoint() unless @typingCompleted
    @editor.insertNewlineBelow()
    @editor.getLastCursor().skipLeadingWhitespace()

    if @typingCompleted
      # We'll have captured the inserted newline, but we want to do that
      # over again by hand, or differing indentations will be wrong.
      @typedText = @typedText.trimLeft()
      return super

    @vimState.activateInsertMode()
    @typingCompleted = true

#
# Delete the following motion and enter insert mode to replace it.
#
class Change extends Insert
  @extend()
  complete: false
  lineWiseAlias: true

  execute: ->
    # If we've typed, we're being repeated. If we're being repeated,
    # undo transactions are already handled.
    @vimState.setInsertionCheckpoint() unless @typingCompleted

    if _.any @target.select(excludeWhitespace: true)
      @setTextToRegister @editor.getSelectedText()
      if @target.isLinewise?() and not @typingCompleted
        for selection in @editor.getSelections()
          selection.insertText("\n", autoIndent: true)
          selection.cursor.moveLeft()
      else
        for selection in @editor.getSelections()
          selection.deleteSelectedText()

    return super if @typingCompleted

    @vimState.activateInsertMode()
    @typingCompleted = true

class Substitute extends Change
  @extend()
  constructor: ->
    super
    @compose(new MoveRight(@vimState))

class SubstituteLine extends Change
  @extend()
  constructor: ->
    super
    @compose(new MoveToRelativeLine(@vimState))

class ChangeToLastCharacterOfLine extends Change
  @extend()
  constructor: ->
    super
    @compose(new MoveToLastCharacterOfLine(@vimState))

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
  constructor: ->
    super
    @getInput this,
      class: 'replace'
      hidden: true
      singleChar: true
      defaultText: '\n'

  isComplete: ->
    @input?

  execute: ->
    count = @getCount(1)
    if @input is '' # replace canceled
      unless @vimState.isVisualMode()
        @vimState.activateNormalMode()
      # replace canceled
      return

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
  ToggleCase, ToggleCaseNow,
  Select,
  UpperCase, LowerCase, Yank, Join, Repeat, Mark,
  Increase, Decrease,
  Indent, Outdent, AutoIndent,

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
}
