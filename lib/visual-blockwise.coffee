Base = require './base'
_ = require 'underscore-plus'

START_ROW = null
class VisualBlockwise extends Base
  @extend()
  complete: true
  recodable: false

  @reset: ->
    START_ROW = null

  adjustSelections: (options) ->
    for selection in @editor.getSelections()
      range = selection.getBufferRange()
      selection.setBufferRange range, options

  reset: ->
    @constructor.reset()

  getCurrentRow: ->
    @currentRow

  constructor: ->
    super
    if @editor.getCursors().length is 1
      @reset()
    @currentRow  = @editor.getLastCursor()?.getBufferRow()
    START_ROW ?= @currentRow

    if @delegateTo
      @vimState.activateNormalMode()
      @vimState.operationStack.push @new(@delegateTo)
      @abort()

class BlockwiseO extends VisualBlockwise
  @extend()
  execute: ->
    START_ROW = @getCurrentRow()

class BlockwiseJ extends VisualBlockwise
  @extend()
  command: 'j'

  execute: ->
    cursors      = @editor.getCursorsOrderedByBufferPosition()
    cursorTop    = _.first cursors
    cursorBottom = _.last cursors

    if (@command is 'j' and cursorTop.getBufferRow() >= START_ROW) or
        (@command is 'k' and cursorBottom.getBufferRow() <= START_ROW)
      lastSelection = @editor.getLastSelection()

      switch @command
        when 'j' then @editor.addSelectionBelow()
        when 'k' then @editor.addSelectionAbove()

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

      switch @command
        when 'j' then cursorTop.destroy()
        when 'k' then cursorBottom.destroy()

class BlockwiseK extends BlockwiseJ
  @extend()
  command: 'k'

class BlockwiseD extends VisualBlockwise
  @extend()
  delegateTo: 'DeleteToLastCharacterOfLine'

class BlockwiseC extends BlockwiseD
  @extend()
  delegateTo: 'ChangeToLastCharacterOfLine'

class BlockwiseI extends VisualBlockwise
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

class BlockwiseA extends BlockwiseI
  @extend()
  command: 'A'

class BlockwiseEscape extends VisualBlockwise
  @extend()
  execute: ->
    @vimState.activateNormalMode()
    @editor.clearSelections()

class BlockwiseCtrlV extends VisualBlockwise
  @extend()
  execute: ->
    @vimState.activateNormalMode()
    @editor.clearSelections()

module.exports = {
  VisualBlockwise,
  BlockwiseO,
  BlockwiseJ,
  BlockwiseK,
  BlockwiseD,
  BlockwiseC,
  BlockwiseI,
  BlockwiseA,
  BlockwiseEscape,
  BlockwiseCtrlV,
}
