_ = require 'underscore-plus'
{Point, Range} = require 'atom'

{ViewModel} = require './view'
Utils = require './utils'
settings = require './settings'
Base = require './base'
Motions = require './motions'

class OperatorError extends Base
  @extend()
  constructor: (@message) ->
    @name = 'Operator Error'

# General Operators
# -------------------------
class Operator extends Base
  @extend()
  vimState: null
  target: null
  complete: false
  recodable: true

  constructor: (@vimState, @options={}) ->
    {@editor} = @vimState
    {@complete} = @options if @options.complete?

  # Public: Marks this as ready to execute and saves the motion.
  #
  # target - TextObject or Motion to operate on.
  #
  # Returns nothing.
  compose: (target) ->
    unless _.isFunction(target.select)
      throw new OperatorError('Must respond to select')

    @target = target
    @complete = true
    if _.isFunction(target.onDidComposeBy)
      @target.onDidComposeBy(this)

  canComposeWith: (operation) ->
    operation.select?

  # Public: Preps text and sets the text register
  #
  # Returns nothing
  setTextRegister: (register, text) ->
    if @target?.isLinewise?()
      type = 'linewise'
      if text[-1..] isnt '\n'
        text += '\n'
    else
      type = Utils.copyType(text)
    @vimState.setRegister(register, {text, type}) unless text is ''

# Public: Generic class for an operator that requires extra input
class OperatorWithInput extends Operator
  @extend()
  canComposeWith: (operation) ->
    operation.characters? or operation.select?

  compose: (operation) ->
    if operation.select?
      @target = operation
    if operation.characters?
      @input = operation
      @complete = true

class Select extends Operator
  @extend()
  execute: ->
    @target.select(@getCount())

#
# It deletes everything selected by the following motion.
#
class Delete extends Operator
  @extend()
  register: null

  constructor: ->
    super
    @register = settings.defaultRegister()

  # Public: Deletes the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: ->
    if _.contains(@target.select(), true)
      @setTextRegister(@register, @editor.getSelectedText())
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
  complete: true

  constructor: ->
    super
    @compose(new Motions.MoveRight(@vimState))

class DeleteLeft extends Delete
  @extend()
  complete: true
  constructor: ->
    super
    @compose(new Motions.MoveLeft(@vimState))

class DeleteToLastCharacterOfLine extends Delete
  @extend()
  complete: true
  constructor: ->
    super
    @compose(new Motions.MoveToLastCharacterOfLine(@vimState))

#
# It toggles the case of everything selected by the following motion
#
class ToggleCase extends Operator
  @extend()

  execute: ->
    if @target?
      if _.contains(@target.select(), true)
        @editor.replaceSelectedText {}, (text) ->
          text.split('').map((char) ->
            lower = char.toLowerCase()
            if char is lower
              char.toUpperCase()
            else
              lower
          ).join('')
    else
      @editor.transact =>
        for cursor in @editor.getCursors()
          point = cursor.getBufferPosition()
          lineLength = @editor.lineTextForBufferRow(point.row).length
          cursorCount = Math.min(@getCount(1), lineLength - point.column)

          _.times cursorCount, =>
            point = cursor.getBufferPosition()
            range = Range.fromPointWithDelta(point, 0, 1)
            char = @editor.getTextInBufferRange(range)

            if char is char.toLowerCase()
              @editor.setTextInBufferRange(range, char.toUpperCase())
            else
              @editor.setTextInBufferRange(range, char.toLowerCase())

            cursor.moveRight() unless point.column >= lineLength - 1

    @vimState.activateNormalMode()

class ToggleCaseNow extends ToggleCase
  @extend()
  complete: true

#
# In visual mode or after `g` with a motion, it makes the selection uppercase
#
class UpperCase extends Operator
  @extend()
  execute: ->
    # if _.contains(@target.select(@getCount(1)), true)
    if _.contains(@target.select(), true)
      @editor.replaceSelectedText {}, (text) ->
        text.toUpperCase()

    @vimState.activateNormalMode()

#
# In visual mode or after `g` with a motion, it makes the selection lowercase
#
class LowerCase extends Operator
  @extend()
  execute: ->
    if _.contains(@target.select(), true)
      @editor.replaceSelectedText {}, (text) ->
        text.toLowerCase()

    @vimState.activateNormalMode()

#
# It copies everything selected by the following motion.
#
class Yank extends Operator
  @extend()
  register: null

  constructor: ->
    super
    @register = settings.defaultRegister()

  # Public: Copies the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: ->
    originalPositions = @editor.getCursorBufferPositions()
    if _.contains(@target.select(), true)
      text = @editor.getSelectedText()
      startPositions = _.pluck(@editor.getSelectedBufferRanges(), "start")
      newPositions = for originalPosition, i in originalPositions
        if startPositions[i] and (@vimState.isVisualMode() or not @target.isLinewise?())
          Point.min(startPositions[i], originalPositions[i])
        else
          originalPosition
    else
      text = ''
      newPositions = originalPositions

    @setTextRegister(@register, text)

    @editor.setSelectedBufferRanges(newPositions.map (p) -> new Range(p, p))
    @vimState.activateNormalMode()

class YankLine extends Yank
  @extend()
  complete: true
  constructor: ->
    super
    @compose(new Motions.MoveToRelativeLine(@vimState))

#
# It combines the current line with the following line.
#
class Join extends Operator
  @extend()
  complete: true

  # Public: Combines the current with the following lines
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: ->
    @editor.transact =>
      _.times @getCount(1), =>
        @editor.joinLines()
    @vimState.activateNormalMode()

#
# Repeat the last operation
#
class Repeat extends Operator
  @extend()
  complete: true
  recodable: false

  execute: ->
    @editor.transact =>
      _.times @getCount(1), =>
        cmd = @vimState.history[0]
        cmd?.execute()
#
# It creates a mark at the current cursor position
#
class Mark extends OperatorWithInput
  @extend()
  constructor: ->
    super
    @viewModel = new ViewModel(this, class: 'mark', singleChar: true, hidden: true)

  # Public: Creates the mark in the specified mark register (from user input)
  # at the current position
  #
  # Returns nothing.
  execute: ->
    @vimState.setMark(@input.characters, @editor.getCursorBufferPosition())
    @vimState.activateNormalMode()

# Increase/Decrease
# -------------------------
#
# It increases or decreases the next number on the line
#
class Increase extends Operator
  @extend()
  step: 1
  complete: true

  constructor: ->
    super
    @numberRegex = new RegExp(settings.numberRegex())

  execute: ->
    @editor.transact =>
      increased = false
      for cursor in @editor.getCursors()
        if @increaseNumber(cursor) then increased = true
      atom.beep() unless increased

  increaseNumber: (cursor) ->
    # find position of current number, adapted from from SearchCurrentWord
    cursorPosition = cursor.getBufferPosition()
    numEnd = cursor.getEndOfCurrentWordBufferPosition(wordRegex: @numberRegex, allowNext: false)

    if numEnd.column is cursorPosition.column
      # either we don't have a current number, or it ends on cursor, i.e. precedes it, so look for the next one
      numEnd = cursor.getEndOfCurrentWordBufferPosition(wordRegex: @numberRegex, allowNext: true)
      return if numEnd.row isnt cursorPosition.row # don't look beyond the current line
      return if numEnd.column is cursorPosition.column # no number after cursor

    cursor.setBufferPosition numEnd
    numStart = cursor.getBeginningOfCurrentWordBufferPosition(wordRegex: @numberRegex, allowPrevious: false)

    range = new Range(numStart, numEnd)

    # parse number, increase/decrease
    number = parseInt(@editor.getTextInBufferRange(range), 10)
    if isNaN(number)
      cursor.setBufferPosition(cursorPosition)
      return

    number += @step * @getCount(1)

    # replace current number with new
    newValue = String(number)
    @editor.setTextInBufferRange(range, newValue, normalizeLineEndings: false)

    cursor.setBufferPosition(row: numStart.row, column: numStart.column-1+newValue.length)
    return true

class Decrease extends Increase
  @extend()
  step: -1

# AdjustIndentation
# -------------------------
class AdjustIndentation extends Operator
  @extend()
  execute: ->
    mode = @vimState.mode
    @target.select() # FIXME how to respect count of default 1 without passing count
    {start} = @editor.getSelectedBufferRange()

    @indent()

    @editor.setCursorBufferPosition([start.row, 0])
    @editor.moveToFirstCharacterOfLine()
    @vimState.activateNormalMode()

class Indent extends AdjustIndentation
  @extend()
  indent: ->
    @editor.indentSelectedRows()

class Outdent extends AdjustIndentation
  @extend()
  indent: ->
    @editor.outdentSelectedRows()

class AutoIndent extends AdjustIndentation
  @extend()
  indent: ->
    @editor.autoIndentSelectedRows()

# Put
# -------------------------
#
# It pastes everything contained within the specifed register
#
# Used by PutAfter and PutBefore, Put itself is not exposed.
class Put extends Operator
  @extend()
  register: null
  complete: true

  constructor: ->
    super
    @register = settings.defaultRegister()

  # Public: Pastes the text in the given register.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: ->
    {text, type} = @vimState.getRegister(@register) or {}
    return unless text

    textToInsert = _.times(@getCount(1), -> text).join('')

    selection = @editor.getSelectedBufferRange()
    if selection.isEmpty()
      # Clean up some corner cases on the last line of the file
      if type is 'linewise'
        textToInsert = textToInsert.replace(/\n$/, '')
        if @location is 'after' and @onLastRow()
          textToInsert = "\n#{textToInsert}"
        else
          textToInsert = "#{textToInsert}\n"

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

    @editor.insertText(textToInsert)

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

  inputOperator: -> true


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
  register: null

  constructor: ->
    super
    @register = settings.defaultRegister()

  # Public: Changes the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: ->
    # If we've typed, we're being repeated. If we're being repeated,
    # undo transactions are already handled.
    @vimState.setInsertionCheckpoint() unless @typingCompleted

    if _.contains(@target.select(excludeWhitespace: true), true)
      @setTextRegister(@register, @editor.getSelectedText())
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
  complete: true

  constructor: ->
    super
    @compose(new Motions.MoveRight(@vimState))

class SubstituteLine extends Change
  @extend()
  complete: true
  register: null

  constructor: ->
    super
    @register = settings.defaultRegister()
    @target = new Motions.MoveToRelativeLine(@vimState)

class ChangeToLastCharacterOfLine extends Change
  @extend()
  complete: true

  constructor: ->
    super
    @compose(new Motions.MoveToLastCharacterOfLine(@vimState))

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
class Replace extends OperatorWithInput
  @extend()
  constructor: ->
    super
    @viewModel = new ViewModel(this, class: 'replace', hidden: true, singleChar: true, defaultText: '\n')

  execute: ->
    count = @getCount(1)
    if @input.characters is ""
      # replace canceled
      if @vimState.isVisualMode()
        @vimState.resetVisualMode()
      else
        @vimState.activateNormalMode()
      return

    @editor.transact =>
      if @target?
        if _.contains(@target.select(), true)
          @editor.replaceSelectedText null, (text) =>
            text.replace(/./g, @input.characters)
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
            @editor.setTextInBufferRange(Range.fromPointWithDelta(point, 0, 1), @input.characters)
            cursor.moveRight()
          cursor.setBufferPosition(pos)

        # Special case: when replaced with a newline move to the start of the
        # next row.
        if @input.characters is "\n"
          _.times count, =>
            @editor.moveDown()
          @editor.moveToFirstCharacterOfLine()

    @vimState.activateNormalMode()

# Alias
ActivateInsertMode = Insert
ActivateReplaceMode = ReplaceMode

module.exports = {
  # General
  Operator, OperatorWithInput, OperatorError, Delete,
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
