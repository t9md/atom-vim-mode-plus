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

  isSingleLine: ->
    @editor.getSelections().length is 1

  getTop: ->
    @editor.getSelectionsOrderedByBufferPosition()[0]

  getBottom: ->
    _.last @editor.getSelectionsOrderedByBufferPosition()

  isReversed: ->
    (not @isSingleLine()) and @getTail() is @getBottom()

  getHead: ->
    if @isReversed() then @getTop() else @getBottom()

  getTail: ->
    _.detect @editor.getSelections(), (s) -> swrap(s).isBlockwiseTail()

  initialize: ->
    # PlantTail
    unless @getTail()?
      @updateProperties {head: @getBottom(), tail: @getTop()}

class BlockwiseOtherEnd extends VisualBlockwise
  @extend()
  execute: ->
    unless @isSingleLine()
      @updateProperties {head: @getTail(), tail: @getHead()}
    @vimState.reverseSelections()

class BlockwiseMoveDown extends VisualBlockwise
  @extend()
  direction: 'Below'

  isExpanding: ->
    return true if @isSingleLine()
    switch @direction
      when 'Below' then not @isReversed()
      when 'Above' then @isReversed()

  execute: ->
    if @isExpanding()
      @editor["addSelection#{@direction}"]()
      swrap.setReversedState @editor, @getTail().isReversed()
    else
      @getHead().destroy()
    @updateProperties {head: @getHead()}

class BlockwiseMoveUp extends BlockwiseMoveDown
  @extend()
  direction: 'Above'

class BlockwiseDeleteToLastCharacterOfLine extends VisualBlockwise
  @extend()
  delegateTo: 'DeleteToLastCharacterOfLine'
  execute: ->
    @eachSelection (s) ->
      s.cursor.setBufferPosition s.getBufferRange().start
    finalPoint = @getTop().cursor.getBufferPosition()
    @vimState.activate('normal')
    @new(@delegateTo).execute()
    @editor.clearSelections()
    @editor.setCursorBufferPosition finalPoint

class BlockwiseChangeToLastCharacterOfLine extends BlockwiseDeleteToLastCharacterOfLine
  @extend()
  delegateTo: 'ChangeToLastCharacterOfLine'

class BlockwiseInsertAtBeginningOfLine extends VisualBlockwise
  @extend()
  after: false

  execute: ->
    which = if @after then 'end' else 'start'
    @eachSelection (s) ->
      s.cursor.setBufferPosition s.getBufferRange()[which]
    @vimState.activate('normal')
    @vimState.activate('insert')

class BlockwiseInsertAfterEndOfLine extends BlockwiseInsertAtBeginningOfLine
  @extend()
  after: true

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
