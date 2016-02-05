Base = require './base'
BlockwiseSelection = require './blockwise-selection'

class VisualBlockwise extends Base
  @extend(false)
  constructor: ->
    super
    @initialize?()

class BlockwiseOtherEnd extends VisualBlockwise
  @extend()
  execute: ->
    for blockwiseSelection in @vimState.getBlockwiseSelections()
      unless blockwiseSelection.isSingleLine()
        blockwiseSelection.reverse()
    @new('ReverseSelections').execute()

class BlockwiseMoveDown extends VisualBlockwise
  @extend()
  direction: 'down'

  execute: ->
    for blockwiseSelection in @vimState.getBlockwiseSelections()
      @countTimes =>
        blockwiseSelection.moveSelection(@direction)

class BlockwiseMoveUp extends BlockwiseMoveDown
  @extend()
  direction: 'up'

class BlockwiseDeleteToLastCharacterOfLine extends VisualBlockwise
  @extend()
  delegateTo: 'DeleteToLastCharacterOfLine'
  recordable: true

  execute: ->
    pointByBlockwiseSelection = new Map

    for blockwiseSelection in @vimState.getBlockwiseSelections()
      blockwiseSelection.setPositionForSelections('start')

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
  which: 'start'

  execute: ->
    for blockwiseSelection in @vimState.getBlockwiseSelections()
      blockwiseSelection.setPositionForSelections(@which)
    @new(@delegateTo).execute()

class BlockwiseInsertAfterEndOfLine extends BlockwiseInsertAtBeginningOfLine
  @extend()
  which: 'end'

class BlockwiseRestoreCharacterwise extends VisualBlockwise
  @extend(false)
  execute: ->
    for blockwiseSelection in @vimState.getBlockwiseSelections()
      blockwiseSelection.restoreCharacterwise()
