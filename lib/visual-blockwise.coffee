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
    for bs in @vimState.getBlockwiseSelections() when not bs.isSingleLine()
      bs.reverse()
    @new('ReverseSelections').execute()

class BlockwiseMoveDown extends VisualBlockwise
  @extend()
  direction: 'down'

  execute: ->
    for bs in @vimState.getBlockwiseSelections()
      @countTimes =>
        bs.moveSelection(@direction)

class BlockwiseMoveUp extends BlockwiseMoveDown
  @extend()
  direction: 'up'

class BlockwiseDeleteToLastCharacterOfLine extends VisualBlockwise
  @extend()
  delegateTo: 'DeleteToLastCharacterOfLine'
  recordable: true

  execute: ->
    pointByBlockwiseSelection = new Map

    for bs in @vimState.getBlockwiseSelections()
      bs.setPositionForSelections('start')
      pointByBlockwiseSelection.set(bs, bs.getTop().getHeadBufferPosition())

    @new(@delegateTo).execute()

    pointByBlockwiseSelection.forEach (point, bs) ->
      bs.setBufferPosition(point)

class BlockwiseChangeToLastCharacterOfLine extends BlockwiseDeleteToLastCharacterOfLine
  @extend()
  delegateTo: 'ChangeToLastCharacterOfLine'

class BlockwiseInsertAtBeginningOfLine extends VisualBlockwise
  @extend()
  delegateTo: 'ActivateInsertMode'
  recordable: true
  which: 'start'

  execute: ->
    for bs in @vimState.getBlockwiseSelections()
      bs.setPositionForSelections(@which)
    @new(@delegateTo).execute()

class BlockwiseInsertAfterEndOfLine extends BlockwiseInsertAtBeginningOfLine
  @extend()
  which: 'end'
