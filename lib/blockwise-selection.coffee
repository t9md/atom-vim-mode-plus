{Range} = require 'atom'
_ = require 'underscore-plus'

{sortRanges, getBufferRows} = require './utils'
swrap = require './selection-wrapper'

class BlockwiseSelection
  editor: null
  selections: null
  goalColumn: null
  reversed: false

  constructor: (selection) ->
    {@editor} = selection
    @initialize(selection)

  getSelections: ->
    @selections

  isBlockwise: ->
    true

  isEmpty: ->
    @getSelections().every (selection) ->
      selection.isEmpty()

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
    @reverse() if wasReversed
    @updateGoalColumn()

  isReversed: ->
    @reversed

  reverse: ->
    @reversed = not @reversed

  updateGoalColumn: ->
    if @goalColumn?
      for selection in @selections
        selection.cursor.goalColumn = @goalColumn

  isSingleRow: ->
    @selections.length is 1

  getHeight: ->
    [startRow, endRow] = @getBufferRowRange()
    (endRow - startRow) + 1

  getStartSelection: ->
    @selections[0]

  getEndSelection: ->
    _.last(@selections)

  getHeadSelection: ->
    if @isReversed()
      @getStartSelection()
    else
      @getEndSelection()

  getTailSelection: ->
    if @isReversed()
      @getEndSelection()
    else
      @getStartSelection()

  getHeadBufferPosition: ->
    @getHeadSelection().getHeadBufferPosition()

  getTailBufferPosition: ->
    @getTailSelection().getTailBufferPosition()

  getBufferRowRange: ->
    startRow = @getStartSelection().getBufferRowRange()[0]
    endRow = @getEndSelection().getBufferRowRange()[0]
    [startRow, endRow]

  headReversedStateIsInSync: ->
    @isReversed() is @getHeadSelection().isReversed()

  # [NOTE] Used by plugin package vmp:move-selected-text
  setSelectedBufferRanges: (ranges, {reversed}) ->
    sortRanges(ranges)
    range = ranges.shift()
    @setHeadBufferRange(range, {reversed})
    for range in ranges
      @selections.push @editor.addSelectionForBufferRange(range, {reversed})
    @updateGoalColumn()

  # which must one of ['start', 'end', 'head', 'tail']
  setPositionForSelections: (which) ->
    for selection in @selections
      swrap(selection).setBufferPositionTo(which)

  clearSelections: ({except}={}) ->
    for selection in @selections.slice() when (selection isnt except)
      @removeSelection(selection)

  setHeadBufferPosition: (point) ->
    head = @getHeadSelection()
    @clearSelections(except: head)
    head.cursor.setBufferPosition(point)

  removeEmptySelections: ->
    for selection in @selections.slice() when selection.isEmpty()
      @removeSelection(selection)

  removeSelection: (selection) ->
    _.remove(@selections, selection)
    selection.destroy()

  setHeadBufferRange: (range, options) ->
    head = @getHeadSelection()
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
    head = @getHeadBufferPosition()
    tail = @getTailBufferPosition()

    if @isReversed()
      [start, end] = [head, tail]
    else
      [start, end] = [tail, head]
    end.row += 1 if end.column is 0

    unless (@isSingleRow() or @headReversedStateIsInSync())
      start.column -= 1
      end.column += 1
    {head, tail}

  getBufferRange: ->
    if @headReversedStateIsInSync()
      start = @getStartSelection.getBufferrange().start
      end = @getEndSelection.getBufferrange().end
    else
      start = @getStartSelection.getBufferrange().end.translate([0, -1])
      end = @getEndSelection.getBufferrange().start.translate([0, +1])
    {start, end}

  # [FIXME] duplicate codes with setHeadBufferRange
  restoreCharacterwise: ->
    # When all selection is empty, we don't want to loose multi-cursor
    # by restoreing characterwise range.
    return if @isEmpty()

    properties = @getCharacterwiseProperties()
    head = @getHeadSelection()
    @clearSelections(except: head)
    {goalColumn} = head.cursor
    swrap(head).selectByProperties(properties)
    head.cursor.goalColumn ?= goalColumn if goalColumn?

module.exports = BlockwiseSelection
