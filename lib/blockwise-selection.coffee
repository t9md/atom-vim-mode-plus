_ = require 'underscore-plus'

{sortRanges, assertWithException, trimRange} = require './utils'
settings = require './settings'

__swrap = null
swrap = (args...) ->
  __swrap ?= require './selection-wrapper'
  __swrap(args...)

class BlockwiseSelection
  editor: null
  selections: null
  goalColumn: null
  reversed: false

  @blockwiseSelectionsByEditor = new Map()

  @clearSelections: (editor) ->
    @blockwiseSelectionsByEditor.delete(editor)

  @has: (editor) ->
    @blockwiseSelectionsByEditor.has(editor)

  @getSelections: (editor) ->
    @blockwiseSelectionsByEditor.get(editor) ? []

  @getSelectionsOrderedByBufferPosition: (editor) ->
    @getSelections(editor).sort (a, b) ->
      a.getStartSelection().compare(b.getStartSelection())

  @getLastSelection: (editor) ->
    _.last(@blockwiseSelectionsByEditor.get(editor))

  @saveSelection: (blockwiseSelection) ->
    editor = blockwiseSelection.editor
    @blockwiseSelectionsByEditor.set(editor, []) unless @has(editor)
    @blockwiseSelectionsByEditor.get(editor).push(blockwiseSelection)

  constructor: (selection) ->
    @needSkipNormalization = false
    @properties = {}
    @editor = selection.editor
    $selection = swrap(selection)
    unless $selection.hasProperties()
      if settings.get('strictAssertion')
        assertWithException(false, "Trying to instantiate vB from properties-less selection")
      $selection.saveProperties()

    @goalColumn = selection.cursor.goalColumn
    @reversed = memberReversed = selection.isReversed()

    {head: {column: headColumn}, tail: {column: tailColumn}} = $selection.getProperties()
    start = $selection.getBufferPositionFor('start', from: ['property'])
    end = $selection.getBufferPositionFor('end', from: ['property'])

    # Respect goalColumn only when it's value is Infinity and selection's head-column is bigger than tail-column
    if (@goalColumn is Infinity) and headColumn >= tailColumn
      if selection.isReversed()
        start.column = @goalColumn
      else
        end.column = @goalColumn

    if start.column > end.column
      memberReversed = not memberReversed
      startColumn = end.column
      endColumn = start.column + 1
    else
      startColumn = start.column
      endColumn = end.column + 1

    ranges = [start.row..end.row].map (row) ->
      [[row, startColumn], [row, endColumn]]

    selection.setBufferRange(ranges.shift(), reversed: memberReversed)
    @selections = [selection]
    for range in ranges
      @selections.push(@editor.addSelectionForBufferRange(range, reversed: memberReversed))
    @updateGoalColumn()

    for memberSelection in @getSelections() when $memberSelection = swrap(memberSelection)
      $memberSelection.saveProperties() # TODO#698  remove this?
      $memberSelection.getProperties().head.column = headColumn
      $memberSelection.getProperties().tail.column = tailColumn

    @constructor.saveSelection(this)

  getSelections: ->
    @selections

  extendMemberSelectionsToEndOfLine: ->
    for selection in @getSelections()
      {start, end} = selection.getBufferRange()
      end.column = Infinity
      selection.setBufferRange([start, end])

  expandMemberSelectionsOverLineWithTrimRange: ->
    for selection in @getSelections()
      start = selection.getBufferRange().start
      range = trimRange(@editor, @editor.bufferRangeForBufferRow(start.row))
      selection.setBufferRange(range)

  isReversed: ->
    @reversed

  reverse: ->
    @reversed = not @reversed

  getProperties: ->
    {
      head: swrap(@getHeadSelection()).getProperties().head
      tail: swrap(@getTailSelection()).getProperties().tail
    }

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

  getBufferRowRange: ->
    startRow = @getStartSelection().getBufferRowRange()[0]
    endRow = @getEndSelection().getBufferRowRange()[0]
    [startRow, endRow]

  # [NOTE] Used by plugin package vmp:move-selected-text
  setSelectedBufferRanges: (ranges, {reversed}) ->
    sortRanges(ranges)
    range = ranges.shift()

    head = @getHeadSelection()
    @removeSelections(except: head)
    {goalColumn} = head.cursor
    # When reversed state of selection change, goalColumn is cleared.
    # But here for blockwise, I want to keep goalColumn unchanged.
    # This behavior is not compatible with pure-Vim I know.
    # But I believe this is more unnoisy and less confusion while moving
    # cursor in visual-block mode.
    head.setBufferRange(range, {reversed})
    head.cursor.goalColumn ?= goalColumn if goalColumn?

    for range in ranges
      @selections.push @editor.addSelectionForBufferRange(range, {reversed})
    @updateGoalColumn()

  removeSelections: ({except}={}) ->
    for selection in @selections.slice() when (selection isnt except)
      swrap(selection).clearProperties()
      _.remove(@selections, selection)
      selection.destroy()

  setHeadBufferPosition: (point) ->
    head = @getHeadSelection()
    @removeSelections(except: head)
    head.cursor.setBufferPosition(point)

  skipNormalization: ->
    @needSkipNormalization = true

  normalize: ->
    return if @needSkipNormalization

    properties = @getProperties() # Save prop BEFORE removing member selections.

    head = @getHeadSelection()
    @removeSelections(except: head)

    {goalColumn} = head.cursor # FIXME this should not be necessary
    $selection = swrap(head)
    $selection.selectByProperties(properties)
    $selection.saveProperties(true)
    head.cursor.goalColumn ?= goalColumn if goalColumn # FIXME this should not be necessary

  autoscroll: ->
    @getHeadSelection().autoscroll()

module.exports = BlockwiseSelection
