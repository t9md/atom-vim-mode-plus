Base = require './base'
_ = require 'underscore-plus'

# FIXME START_ROW handling is not 100% correct currently
# FIXME Currently initally multi selected situation not supported.
START_ROW = null
class VisualBlockwise extends Base
  @extend()
  complete: true
  recodable: false

  @reset: ->
    START_ROW = null

  @setStartRow: (row) ->
    START_ROW = row

  adjustSelections: (options) ->
    for selection in @editor.getSelections()
      range = selection.getBufferRange()
      selection.setBufferRange range, options

  reset: ->
    @constructor.reset()

  getCurrentRow: ->
    @currentRow

  getTopCursor: ->
    _.first @editor.getCursorsOrderedByBufferPosition()

  getBottomCursor: ->
    _.last @editor.getCursorsOrderedByBufferPosition()

  constructor: ->
    super
    if @editor.getCursors().length is 1
      @reset()
    @currentRow  = @editor.getLastCursor()?.getBufferRow()
    START_ROW ?= @currentRow

class BlockwiseOtherEnd extends VisualBlockwise
  @extend()
  execute: ->
    START_ROW = @getCurrentRow()
    @vimState.reverseSelections()

class BlockwiseMoveDown extends VisualBlockwise
  @extend()
  command: 'j'

  execute: ->
    cursorTop    = @getTopCursor()
    cursorBottom = @getBottomCursor()
    if (@command is 'j' and cursorTop.getBufferRow() >= START_ROW) or
        (@command is 'k' and cursorBottom.getBufferRow() <= START_ROW)

      lastSelection = @editor.getLastSelection()
      @addSelection()
      # [FIXME]
      # When addSelectionAbove(), addSelectionBelow() doesn't respect
      # reversed stated, need improved.
      #
      # and one more..
      #
      # When selection is NOT empty and add selection by addSelectionAbove()
      # and then move right, selection range got wrong, maybe this is bug..
      @adjustSelections reversed: lastSelection.isReversed()
    else
      # [FIXME]
      # Guard to not destroying last cursor
      # This guard is no longer needed
      # Remove unnecessary code after re-think.
      if (@editor.getCursors().length < 2)
        @reset()
        return

      @destroyCursor()

  addSelection: ->
    @editor.addSelectionBelow()

  destroyCursor: ->
    @getTopCursor().destroy()

class BlockwiseMoveUp extends BlockwiseMoveDown
  @extend()
  command: 'k'
  addSelection: ->
    @editor.addSelectionAbove()
  destroyCursor: ->
    @getBottomCursor().destroy()

class BlockwiseDeleteToLastCharacterOfLine extends VisualBlockwise
  @extend()
  delegateTo: 'DeleteToLastCharacterOfLine'
  execute: ->
    @vimState.activateNormalMode()
    point = @getTopCursor().getBufferPosition()
    @new(@delegateTo).execute()
    @editor.clearSelections()
    @editor.setCursorBufferPosition(point)

class BlockwiseChangeToLastCharacterOfLine extends BlockwiseDeleteToLastCharacterOfLine
  @extend()
  delegateTo: 'ChangeToLastCharacterOfLine'

class BlockwiseInsertAtBeginningOfLine extends VisualBlockwise
  @extend()
  command: 'I'
  execute: ->
    cursorsAdjusted = []

    adjustCursor = (selection) =>
      {start, end} = selection.getBufferRange()
      pointEndOfLine = @editor.bufferRangeForBufferRow(start.row).end
      pointTarget    = {'I': start, 'A': end}[@command]
      {cursor}       = selection

      if pointTarget.isGreaterThanOrEqual(pointEndOfLine)
        pointTarget = pointEndOfLine
        cursorsAdjusted.push cursor
      cursor.setBufferPosition(pointTarget)

    for selection in @editor.getSelections()
      adjustCursor(selection)
    @vimState.activateNormalMode()
    @vimState.activateInsertMode()

    if @command is 'A' and  cursorsAdjusted.length
      cursor.moveRight() for cursor in cursorsAdjusted

class BlockwiseInsertAfterEndOfLine extends BlockwiseInsertAtBeginningOfLine
  @extend()
  command: 'A'

class BlockwiseEscape extends VisualBlockwise
  @extend()
  execute: ->
    @reset()
    @vimState.activateNormalMode()
    @editor.clearSelections()

module.exports = {
  VisualBlockwise,
  BlockwiseOtherEnd,
  BlockwiseMoveDown,
  BlockwiseMoveUp,
  BlockwiseDeleteToLastCharacterOfLine,
  BlockwiseChangeToLastCharacterOfLine,
  BlockwiseInsertAtBeginningOfLine,
  BlockwiseInsertAfterEndOfLine,
  BlockwiseEscape,
}
