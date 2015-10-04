Base = require './base'
_ = require 'underscore-plus'
{swrap} = require './utils'
{Range} = require 'atom'

# FIXME Currently initally multi selected situation not supported.
class VisualBlockwise extends Base
  @extend()
  complete: true

  clearTail: ->
    prop = tail: false
    for s in @editor.getSelections()
      @updateProperty(s, tail: false)

  clearHead: ->
    prop = head: false
    for s in @editor.getSelections()
      @updateProperty(s, prop)
      s.cursor.setVisible(false)

  updateProperty: (selection, prop) ->
    swrap(selection).update {blockwise: prop}

  getTop: ->
    _.first @editor.getSelectionsOrderedByBufferPosition()

  getBottom: ->
    _.last @editor.getSelectionsOrderedByBufferPosition()

  isReversed: ->
    if @isSingle()
      false
    else
      @getTail().marker.isEqual @getBottom().marker

  isSingle: ->
    @editor.getSelections().length is 1

  getHead: ->
    if @isReversed() then @getTop() else @getBottom()

  getTail: ->
    _.detect @editor.getSelections(), (s) ->
      swrap(s).get().blockwise?.tail

  setTail: (newTail) ->
    @clearTail()
    @updateProperty(newTail, tail: true)

  # Only for making cursor visible.
  setHead: (newHead) ->
    @clearHead()
    @updateProperty(newHead, head: true)

  constructor: ->
    super
    unless @getTail()?
      @setTail @getTop()
      @setHead @getBottom()

  reverse: ->
    [newHead, newTail] = [@getTail(), @getHead()]
    @setTail newTail
    @setHead newHead

class BlockwiseOtherEnd extends VisualBlockwise
  @extend()
  execute: ->
    unless @isSingle()
      @reverse()
    @vimState.reverseSelections()

class BlockwiseMoveDown extends VisualBlockwise
  @extend()
  direction: 'Below'

  isForward: ->
    not @isReversed()

  execute: ->
    if @isForward()
      @editor["addSelection#{@direction}"]()
      @vimState.syncSelectionsReversedSate @getTail()
    else
      @getHead().destroy()
    @setHead @getHead()

class BlockwiseMoveUp extends BlockwiseMoveDown
  @extend()
  direction: 'Above'
  isForward: ->
    @isSingle() or @isReversed()

class BlockwiseDeleteToLastCharacterOfLine extends VisualBlockwise
  @extend()
  delegateTo: 'DeleteToLastCharacterOfLine'
  execute: ->
    @vimState.activate('normal')
    point = @getTop().cursor.getBufferPosition()
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
    @vimState.activate('normal')
    @vimState.activate('insert')

    if @command is 'A' and  cursorsAdjusted.length
      cursor.moveRight() for cursor in cursorsAdjusted

class BlockwiseInsertAfterEndOfLine extends BlockwiseInsertAtBeginningOfLine
  @extend()
  command: 'A'

class BlockwiseEscape extends VisualBlockwise
  @extend()
  execute: ->
    @clearTail()
    @clearHead()
    @vimState.activate('normal')
    @editor.clearSelections()

class BlockwiseSelect extends VisualBlockwise
  @extend()
  execute: ->
    s    = @editor.getLastSelection()
    tail = s.getTailBufferPosition()
    head = s.getHeadBufferPosition()
    {start, end} = s.getBufferRange()
    [action, step] = if s.isReversed() then ['Up', -1] else ['Down', +1]

    range = new Range(tail, [tail.row, head.column])
    range = range.translate([0, -1], [0, +1]) if start.column >= end.column

    s.setBufferRange(range, reversed: head.column < tail.column)
    # NOTE: Need to skip the amount of rows where no selectable chars exist.
    _.times (end.row - start.row), =>
      range = range.translate([step, 0], [step, 0])
      if @editor.getTextInBufferRange(range)
        @new("BlockwiseMove#{action}").execute()

class BlockwiseRestoreCharacterwise extends VisualBlockwise
  @extend()
  execute: ->
    startRow = @getTop().getBufferRowRange().shift()
    endRow = @getBottom().getBufferRowRange().shift()
    range = @editor.getLastSelection().getBufferRange()
    range.start.row = startRow
    range.end.row   = endRow
    @editor.setSelectedBufferRange(range)

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
  BlockwiseSelect,
  BlockwiseRestoreCharacterwise,
}
