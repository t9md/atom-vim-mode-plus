_ = require 'underscore-plus'

{
  sortRanges
  isEmpty
  pointIsAtEndOfLineAtNonEmptyRow
  assertWithException
} = require './utils'
swrap = require './selection-wrapper'

class BlockwiseSelection
  editor: null
  selections: null
  goalColumn: null
  reversed: false

  @blockwiseSelections = []
  @clearSelections: ->
    @blockwiseSelections = []

  @getSelections: ->
    @blockwiseSelections

  getSelectionsOrderedByBufferPosition: ->
    @blockwiseSelections.sort (a, b) ->
      a.getStartSelection().compare(b.getStartSelection())

  @getLastSelection: ->
    _.last(@blockwiseSelections)

  @saveSelection: (blockwiseSelection) ->
    @blockwiseSelections.push(blockwiseSelection)

  constructor: (selection) ->
    assertWithException(swrap.hasProperties(selection.editor), "trying to instantiate vB from properties-less selection")

    {@editor} = selection
    $selection = swrap(selection)

    if pointIsAtEndOfLineAtNonEmptyRow(@editor, selection.getBufferRange().end)
      $selection.translateSelectionEndAndClip('backward')
    $selection.translateSelectionEndAndClip('forward') # NOTE#698 added this line

    @initialize(selection)

    for memberSelection in @getSelections() when $memberSelection = swrap(memberSelection)
      $memberSelection.saveProperties() # TODO#698  remove this?
      $memberSelection.setWiseProperty('blockwise')

    @properties = {}
    @saveProperties()
    @constructor.saveSelection(this)

  getSelections: ->
    @selections

  isEmpty: ->
    @getSelections().every(isEmpty)

  initialize: (selection) ->
    {@goalColumn} = selection.cursor
    @selections = [selection]
    wasReversed = reversed = selection.isReversed()

    range = selection.getBufferRange()
    if range.end.column is 0
      range.end.row -= 1

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
    @reversed = wasReversed
    @updateGoalColumn()

  isReversed: ->
    @reversed

  reverse: ->
    @reversed = not @reversed
    @saveProperties()

  getProperties: ->
    @properties

  saveProperties: ->
    @properties.head = swrap(@getHeadSelection()).getProperties().head
    @properties.tail = swrap(@getTailSelection()).getProperties().tail

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

  getStartBufferPosition: ->
    @getStartSelection().getBufferRange().start

  getEndBufferPosition: ->
    @getEndSelection().getBufferRange().end

  getBufferRowRange: ->
    startRow = @getStartSelection().getBufferRowRange()[0]
    endRow = @getEndSelection().getBufferRowRange()[0]
    [startRow, endRow]

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

  removeSelection: (selection) ->
    swrap(selection).clearProperties()
    _.remove(@selections, selection)
    selection.destroy()

  setHeadBufferRange: (range, options) ->
    head = @getHeadSelection()
    @clearSelections(except: head)
    {goalColumn} = head.cursor
    # When reversed state of selection change, goalColumn is cleared.
    # But here for blockwise, I want to keep goalColumn unchanged.
    # This behavior is not compatible with pure-Vim I know.
    # But I believe this is more unnoisy and less confusion while moving
    # cursor in visual-block mode.
    head.setBufferRange(range, options)
    head.cursor.goalColumn ?= goalColumn if goalColumn?

  normalize: ->
    return if @isEmpty()

    head = @getHeadSelection()
    @clearSelections(except: head)
    {goalColumn} = head.cursor # FIXME this should not be necessary
    $selection = swrap(head)
    $selection.selectByProperties(@properties)
    $selection.saveProperties(true)
    head.cursor.goalColumn ?= goalColumn if goalColumn # FIXME this should not be necessary

  autoscroll: ->
    @getHeadSelection().autoscroll()

module.exports = BlockwiseSelection
