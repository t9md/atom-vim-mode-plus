{Range} = require 'atom'
_ = require 'underscore-plus'

{sortRanges, getBufferRows} = require './utils'
swrap = require './selection-wrapper'

class BlockwiseSelection
  constructor: (selection) ->
    {@editor} = selection
    @initialize(selection)

  isBlockwise: ->
    true

  initialize: (selection) ->
    {@goalColumn} = selection.cursor
    @selections = [selection]
    wasReversed = reversed = selection.isReversed()

    # If selection is single line we don't need to add selection.
    # This tweeking allow find-and-replace:select-next then ctrl-v, I(or A) flow work.
    unless swrap(selection).isSingleRow()
      range = selection.getBufferRange()
      if range.end.column is 0
        range.end.row = range.end.row - 1

      if @goalColumn?
        if wasReversed
          range.start.column = @goalColumn
        else
          range.end.column = @goalColumn + 1

      if range.start.column >= range.end.column
        reversed = not reversed
        range = range.translate([0, 1], [0, -1])

      {start, end} = range
      ranges = [start.row..end.row].map (row) ->
        [[row, start.column], [row, end.column]]

      selection.setBufferRange(ranges.shift(), {reversed})
      for range in ranges
        @selections.push(@editor.addSelectionForBufferRange(range, {reversed}))
    @updateProperties()
    @reverse() if wasReversed

  updateProperties: ->
    head = @getHead()
    tail = @getTail()

    for selection in @selections
      selection.cursor.goalColumn = @goalColumn if @goalColumn?
      swrap(selection).setProperties
        blockwise:
          head: selection is head
          tail: selection is tail

  isSingleLine: ->
    @selections.length is 1

  getHeight: ->
    [startRow, endRow] = @getBufferRowRange()
    (endRow - startRow) + 1

  getTop: ->
    @selections[0]

  getBottom: ->
    _.last(@selections)

  isReversed: ->
    if @isSingleLine()
      @getTop().isReversed()
    else
      swrap(@getBottom()).isBlockwiseTail()

  getHead: ->
    if @isReversed() then @getTop() else @getBottom()

  getTail: ->
    if @isReversed() then @getBottom() else @getTop()

  reverse: ->
    return if @isSingleLine()
    head = @getHead()
    tail = @getTail()
    swrap(head).setProperties(blockwise: head: false, tail: true)
    swrap(tail).setProperties(blockwise: head: true, tail: false)

  getBufferRowRange: ->
    startRow = @getTop().getBufferRowRange()[0]
    endRow = @getBottom().getBufferRowRange()[0]
    [startRow, endRow]

  headReversedStateIsInSync: ->
    @isReversed() is @getHead().isReversed()

  # [NOTE] sused by plugin package vmp:move-selected-text
  setSelectedBufferRanges: (ranges, {reversed}) ->
    sortRanges(ranges)
    range = ranges.shift()
    @setHeadBufferRange(range, {reversed})
    for range in ranges
      @selections.push @editor.addSelectionForBufferRange(range, {reversed})
    @updateProperties()

  # which must be 'start' or 'end'
  setPositionForSelections: (which) ->
    for selection in @selections
      point = selection.getBufferRange()[which]
      selection.cursor.setBufferPosition(point)

  clearSelections: ({except}={}) ->
    for selection in @selections.slice() when (selection isnt except)
      @removeSelection(selection)

  setHeadBufferPosition: (point) ->
    head = @getHead()
    @clearSelections(except: head)
    head.cursor.setBufferPosition(point)

  removeEmptySelections: ->
    for selection in @selections.slice() when selection.isEmpty()
      @removeSelection(selection)

  removeSelection: (selection) ->
    _.remove(@selections, selection)
    selection.destroy()

  setHeadBufferRange: (range, options) ->
    head = @getHead()
    @clearSelections(except: head)
    {goalColumn} = head.cursor
    # When reversed state of selection change, goalColumn is cleared.
    # But here for blockwise, I want to keep goalColumn unchanged.
    # This behavior is not identical to pure Vim I know.
    # But I believe this is more unnoisy and less confusion while moving
    # cursor in visual-block mode.
    head.setBufferRange(range, options)
    head.cursor.goalColumn ?= goalColumn if goalColumn?

  getCharacterwiseProperties: ->
    head = @getHead().getHeadBufferPosition()
    tail = @getTail().getTailBufferPosition()

    if @isReversed()
      [start, end] = [head, tail]
    else
      [start, end] = [tail, head]
    end.row += 1 if end.column is 0

    unless (@isSingleLine() or @headReversedStateIsInSync())
      start.column -= 1
      end.column += 1
    {head, tail}

  # [FIXME] duplicate codes with setHeadBufferRange
  restoreCharacterwise: ->
    properties = {characterwise: @getCharacterwiseProperties()}
    head = @getHead()
    @clearSelections(except: head)
    {goalColumn} = head.cursor
    swrap(head).selectByProperties(properties)
    head.cursor.goalColumn ?= goalColumn if goalColumn?

  getSelections: ->
    @selections

module.exports = BlockwiseSelection
