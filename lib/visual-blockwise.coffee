_ = require 'underscore-plus'
{Range} = require 'atom'

Base = require './base'
swrap = require './selection-wrapper'

class VisualBlockwise extends Base
  @extend(false)
  constructor: ->
    super
    @initialize?()

  initialize: ->
    # PlantTail
    unless @getTail()?
      @setProperties {head: @getBottom(), tail: @getTop()}

  eachSelection: (fn) ->
    for selection in @editor.getSelections()
      fn(selection)

  setProperties: ({head, tail}) ->
    @eachSelection (selection) ->
      prop = {}
      prop.head = (selection is head) if head?
      prop.tail = (selection is tail) if tail?
      swrap(selection).setProperties(blockwise: prop)

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
    _.detect @editor.getSelections(), (selection) ->
      swrap(selection).isBlockwiseTail()

  getBufferRowRange: ->
    startRow = @getTop().getBufferRowRange()[0]
    endRow = @getBottom().getBufferRowRange()[0]
    [startRow, endRow]

class BlockwiseOtherEnd extends VisualBlockwise
  @extend()
  execute: ->
    unless @isSingleLine()
      @setProperties {head: @getTail(), tail: @getHead()}
    @new('ReverseSelections').execute()

class BlockwiseMoveDown extends VisualBlockwise
  @extend()
  direction: 'down'

  isExpanding: ->
    return true if @isSingleLine()
    switch @direction
      when 'down' then not @isReversed()
      when 'up' then @isReversed()

  execute: ->
    @countTimes =>
      if @isExpanding()
        switch @direction
          when 'down' then @editor.addSelectionBelow()
          when 'up' then @editor.addSelectionAbove()
        swrap.setReversedState @editor, @getTail().isReversed()
      else
        @getHead().destroy()
    @setProperties {head: @getHead(), tail: @getTail()}

class BlockwiseMoveUp extends BlockwiseMoveDown
  @extend()
  direction: 'up'

class BlockwiseDeleteToLastCharacterOfLine extends VisualBlockwise
  @extend()
  delegateTo: 'DeleteToLastCharacterOfLine'
  recordable: true

  execute: ->
    @eachSelection (selection) ->
      selection.cursor.setBufferPosition(selection.getBufferRange().start)
    point = @getTop().cursor.getBufferPosition()
    @vimState.activate('normal')
    @new(@delegateTo).execute()
    @editor.clearSelections()
    @editor.setCursorBufferPosition(point)

class BlockwiseChangeToLastCharacterOfLine extends BlockwiseDeleteToLastCharacterOfLine
  @extend()
  delegateTo: 'ChangeToLastCharacterOfLine'

class BlockwiseInsertAtBeginningOfLine extends VisualBlockwise
  @extend()
  delegateTo: 'ActivateInsertMode'
  recordable: true
  whichSide: 'start'

  execute: ->
    @eachSelection (selection) =>
      point = selection.getBufferRange()[@whichSide]
      selection.cursor.setBufferPosition(point)
    @new(@delegateTo).execute()

class BlockwiseInsertAfterEndOfLine extends BlockwiseInsertAtBeginningOfLine
  @extend()
  whichSide: 'end'

class BlockwiseSelect extends VisualBlockwise
  @extend(false)
  execute: ->
    selection = @editor.getLastSelection()
    wasReversed = reversed = selection.isReversed()
    range = selection.getScreenRange()
    if range.start.column >= range.end.column
      reversed = not reversed
      range = range.translate([0, 1], [0, -1])

    {start, end} = range
    ranges = [start.row..end.row].map (row) -> [[row, start.column], [row, end.column]]
    # If selection is single line we don't need to add selection.
    # This tweeking allow find-and-replace:select-next then ctrl-v, I(or A) flow work.
    @editor.setSelectedScreenRanges(ranges, {reversed}) unless selection.isSingleScreenLine()
    if wasReversed
      @setProperties {head: @getTop(), tail: @getBottom()}
    else
      @setProperties {head: @getBottom(), tail: @getTop()}
    @eachSelection (selection) ->
      selection.destroy() if selection.isEmpty()

class BlockwiseRestoreCharacterwise extends VisualBlockwise
  @extend(false)

  execute: ->
    reversed = @isReversed()
    head = @getHead()
    headIsReversed = head.isReversed()
    [startRow, endRow] = @getBufferRowRange()
    {start: {column: startColumn}, end: {column: endColumn}} = head.getBufferRange()
    if reversed isnt headIsReversed
      [startColumn, endColumn] = [endColumn, startColumn]
      startColumn -= 1
      endColumn += 1
    range = [[startRow, startColumn], [endRow, endColumn]]
    @editor.setSelectedBufferRange(range, {reversed})
