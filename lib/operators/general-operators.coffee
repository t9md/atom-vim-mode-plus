_ = require 'underscore-plus'
{Point, Range} = require 'atom'
{ViewModel} = require '../view-models/view-model'
Utils = require '../utils'
settings = require '../settings'
Base = require '../base'

class OperatorError extends Base
  @extend()
  constructor: (@message) ->
    @name = 'Operator Error'

class Operator extends Base
  @extend()
  vimState: null
  target: null
  complete: null

  constructor: (@editor, @vimState) ->
    @complete = false

  # Public: Determines when the command can be executed.
  #
  # Returns true if ready to execute and false otherwise.
  isComplete: -> @complete

  # Public: Determines if this command should be recorded in the command
  # history for repeats.
  #
  # Returns true if this command should be recorded.
  isRecordable: -> true

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

  canComposeWith: (operation) -> operation.select?

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
  canComposeWith: (operation) -> operation.characters? or operation.select?

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

  constructor: (@editor, @vimState) ->
    @complete = false
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

#
# It toggles the case of everything selected by the following motion
#
class ToggleCase extends Operator
  @extend()
  constructor: (@editor, @vimState, {@complete}={}) ->

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

#
# In visual mode or after `g` with a motion, it makes the selection uppercase
#
class UpperCase extends Operator
  @extend()
  constructor: (@editor, @vimState) ->
    @complete = false

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
  constructor: (@editor, @vimState) ->
    @complete = false

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

  constructor: (@editor, @vimState) ->
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

#
# It combines the current line with the following line.
#
class Join extends Operator
  @extend()
  constructor: (@editor, @vimState) -> @complete = true

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
  constructor: (@editor, @vimState) -> @complete = true

  isRecordable: -> false

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
  constructor: (@editor, @vimState) ->
    super(@editor, @vimState)
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

  constructor: ->
    super
    @complete = true
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

class Autoindent extends AdjustIndentation
  @extend()
  indent: ->
    @editor.autoIndentSelectedRows()

module.exports = {
  Operator, OperatorWithInput, OperatorError, Delete, ToggleCase,
  Select,
  UpperCase, LowerCase, Yank, Join, Repeat, Mark
  Increase, Decrease
  Indent, Outdent, Autoindent
}
