Base = require './base'
BlockwiseSelection = require './blockwise-selection'

class VisualBlockwise extends Base
  eachBlockwiseSelection: (fn) ->
    selections = @editor.getSelections()
    blockwiseSelection = new BlockwiseSelection(@vimState, selections)
    fn(blockwiseSelection)

class BlockwiseOtherEnd extends VisualBlockwise
  @extend()
  execute: ->
    @eachBlockwiseSelection (blockwiseSelection) ->
      unless blockwiseSelection.isSingleLine()
        blockwiseSelection.otherEnd()
    @new('ReverseSelections').execute()

class BlockwiseMoveDown extends VisualBlockwise
  @extend()
  direction: 'down'

  execute: ->
    @eachBlockwiseSelection (blockwiseSelection) =>
      @countTimes =>
        blockwiseSelection.modifySelection(@direction)

class BlockwiseMoveUp extends BlockwiseMoveDown
  @extend()
  direction: 'up'

class BlockwiseDeleteToLastCharacterOfLine extends VisualBlockwise
  @extend()
  delegateTo: 'DeleteToLastCharacterOfLine'
  recordable: true

  execute: ->
    pointByBlockwiseSelection = new Map

    @eachBlockwiseSelection (blockwiseSelection) ->
      blockwiseSelection.eachSelection (selection) ->
        {start} = selection.getBufferRange()
        selection.cursor.setBufferPosition(start)

      point = blockwiseSelection.getTop().getHeadBufferPosition()
      pointByBlockwiseSelection.set(blockwiseSelection, point)

    @vimState.activate('normal')
    @new(@delegateTo).execute()

    pointByBlockwiseSelection.forEach (point, blockwiseSelection) ->
      blockwiseSelection.setBufferPosition(point)

class BlockwiseChangeToLastCharacterOfLine extends BlockwiseDeleteToLastCharacterOfLine
  @extend()
  delegateTo: 'ChangeToLastCharacterOfLine'

class BlockwiseInsertAtBeginningOfLine extends VisualBlockwise
  @extend()
  delegateTo: 'ActivateInsertMode'
  recordable: true
  whichSide: 'start'

  execute: ->
    for selection in @editor.getSelections()
      point = selection.getBufferRange()[@whichSide]
      selection.cursor.setBufferPosition(point)
    @new(@delegateTo).execute()

class BlockwiseInsertAfterEndOfLine extends BlockwiseInsertAtBeginningOfLine
  @extend()
  whichSide: 'end'

class BlockwiseRestoreCharacterwise extends VisualBlockwise
  @extend(false)
  execute: ->
    @eachBlockwiseSelection (blockwiseSelection) ->
      blockwiseSelection.restoreCharacterwise()
