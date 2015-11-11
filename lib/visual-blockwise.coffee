_ = require 'underscore-plus'
{Range} = require 'atom'

Base = require './base'
swrap = require './selection-wrapper'

# FIXME Currently initally multi selected situation not supported.
class VisualBlockwise extends Base
  @extend()
  complete: true

  eachSelection: (fn) ->
    for s in @editor.getSelections()
      fn(s)

  updateProperties: ({head, tail}) ->
    @eachSelection (s) ->
      prop = {}
      prop.head = (s is head) if head?
      prop.tail = (s is tail) if tail?
      swrap(s).updateProperties(blockwise: prop)

  getTop: ->
    @editor.getSelectionsOrderedByBufferPosition()[0]

  getBottom: ->
    _.last @editor.getSelectionsOrderedByBufferPosition()

  isReversed: ->
    if @isSingleLine()
      false
    else
      @getTail() is @getBottom()

  isSingleLine: ->
    @editor.getSelections().length is 1

  getHead: ->
    if @isReversed() then @getTop() else @getBottom()

  getTail: ->
    _.detect @editor.getSelections(), (s) -> swrap(s).isBlockwiseTail()

  initialize: ->
    # PlantTail
    unless @getTail()?
      @updateProperties {tail: @getTop(), head: @getBottom()}

class BlockwiseOtherEnd extends VisualBlockwise
  @extend()
  execute: ->
    unless @isSingleLine()
      @updateProperties {tail: @getHead(), head: @getTail()}
    @vimState.reverseSelections()

class BlockwiseMoveDown extends VisualBlockwise
  @extend()
  direction: 'Below'

  isForward: ->
    not @isReversed()

  execute: ->
    if @isForward()
      @editor["addSelection#{@direction}"]()
      @vimState.syncSelectionsReversedState @getTail()
    else
      @getHead().destroy()
    @updateProperties {head: @getHead()}

class BlockwiseMoveUp extends BlockwiseMoveDown
  @extend()
  direction: 'Above'
  isForward: ->
    @isSingleLine() or @isReversed()

class BlockwiseDeleteToLastCharacterOfLine extends VisualBlockwise
  @extend()
  delegateTo: 'DeleteToLastCharacterOfLine'
  execute: ->
    @eachSelection (s) ->
      {start} = s.getBufferRange()
      s.cursor.setBufferPosition(start)
    @vimState.activate('normal')
    @new(@delegateTo).execute()
    @editor.clearSelections()
    @editor.setCursorBufferPosition(@getTop().cursor.getBufferPosition())

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
      pointTarget = {'I': start, 'A': end}[@command]
      {cursor} = selection

      if pointTarget.isGreaterThanOrEqual(pointEndOfLine)
        pointTarget = pointEndOfLine
        cursorsAdjusted.push cursor
      cursor.setBufferPosition(pointTarget)

    @eachSelection (s) ->
      adjustCursor(s)
    @vimState.activate('normal')
    @vimState.activate('insert')

    if @command is 'A' and  cursorsAdjusted.length
      for cursor in cursorsAdjusted when not cursor.isAtEndOfLine()
        cursor.moveRight()

class BlockwiseInsertAfterEndOfLine extends BlockwiseInsertAtBeginningOfLine
  @extend()
  command: 'A'

class BlockwiseSelect extends VisualBlockwise
  @extend()
  execute: ->
    s = @editor.getLastSelection()
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
    reversed = @isReversed()
    head = @getHead()
    headIsReversed = head.isReversed()
    startRow = @getTop().getBufferRowRange().shift()
    endRow = @getBottom().getBufferRowRange().shift()
    {start: {column: startColumn}, end: {column: endColumn}} = head.getBufferRange()
    if reversed isnt headIsReversed
      [startColumn, endColumn] = [endColumn, startColumn]
    range = new Range([startRow, startColumn], [endRow, endColumn])
    {start, end} = range
    range = range.translate([0, -1], [0, +1]) if start.column >= end.column
    @editor.setSelectedBufferRange(range, {reversed})

module.exports = {
  VisualBlockwise,
  BlockwiseOtherEnd,
  BlockwiseMoveDown,
  BlockwiseMoveUp,
  BlockwiseDeleteToLastCharacterOfLine,
  BlockwiseChangeToLastCharacterOfLine,
  BlockwiseInsertAtBeginningOfLine,
  BlockwiseInsertAfterEndOfLine,
  BlockwiseSelect,
  BlockwiseRestoreCharacterwise,
}
