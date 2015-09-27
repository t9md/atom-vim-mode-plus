Base = require './base'
_ = require 'underscore-plus'
{getSelectionProperty, updateSelectionProperty} = require './utils'
{Range} = require 'atom'

# FIXME Currently initally multi selected situation not supported.
class VisualBlockwise extends Base
  @extend()
  complete: true

  clearTail: ->
    @setProperties(blockwiseTail: false)

  clearHead: ->
    @setProperties(blockwiseHead: false)
    for s in @editor.getSelections()
      s.cursor.setVisible(false)

  setProperties: (prop) ->
    for s in @editor.getSelections()
      updateSelectionProperty(s, 'vimModePlus', prop)

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
    if @isReversed()
      @getTop()
    else
      @getBottom()

  getTail: ->
    _.detect @editor.getSelections(), (s) ->
      getSelectionProperty(s, 'vimModePlus')?.blockwiseTail

  setTail: (newTail) ->
    @clearTail()
    updateSelectionProperty(newTail, 'vimModePlus', blockwiseTail: true)


  # Only for making cursor visible.
  setHead: (newHead) ->
    @clearHead()
    updateSelectionProperty(newHead, 'vimModePlus', blockwiseHead: true)

  constructor: ->
    super
    if @isSingle()
      @clearTail()

  # dump: (header) ->
  #   console.log "--#{header}-"
  #   for s in @editor.getSelections()
  #     range = s.marker.getBufferRange().toString()
  #     isTail = getSelectionProperty(s, 'vimModePlus')?.blockwiseTail
  #     console.log "#{range} #{isTail}"
  #   console.log "---"

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
    if @isSingle()
      @setTail @getTop()

    if @isForward()
      @editor["addSelection#{@direction}"]()
      @vimState.syncSelectionsReversedSate(@getTail().isReversed())
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
    @vimState.activate('normal')
    @editor.clearSelections()

class BlockwiseSelect extends VisualBlockwise
  @extend()
  execute: ->
    selection = @editor.getLastSelection()
    tail      = selection.getTailBufferPosition()
    head      = selection.getHeadBufferPosition()
    {start, end} = selection.getBufferRange()

    range = new Range(tail, [tail.row, head.column])
    if start.column >= end.column
      range = range.translate([0, -1], [0, +1])

    klass =
      if selection.isReversed()
        "BlockwiseMoveUp"
      else
        "BlockwiseMoveDown"
    selection.setBufferRange(range, reversed: head.column < tail.column)
    _.times (end.row - start.row), =>
      @new(klass).execute()

class BlockwiseRestoreCharacterwise extends VisualBlockwise
  @extend()
  execute: ->
    selections = @editor.getSelectionsOrderedByBufferPosition()
    startRow = @getTop().getBufferRowRange()[0]
    endRow = @getBottom().getBufferRowRange()[0]
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
