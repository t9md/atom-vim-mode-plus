_ = require 'underscore-plus'
swrap = require './selection-wrapper'
{sortComparable} = require './utils'

class BlockwiseSelection
  constructor: (selection) ->
    {@editor} = selection
    @initialize(selection)
    @setProperties {head: @getBottom(), tail: @getTop()} unless @hasTail()

  initialize: (selection) ->
    @selections = [selection]
    wasReversed = reversed = selection.isReversed()

    # If selection is single line we don't need to add selection.
    # This tweeking allow find-and-replace:select-next then ctrl-v, I(or A) flow work.
    unless selection.isSingleScreenLine()
      range = selection.getScreenRange()
      if range.start.column >= range.end.column
        reversed = not reversed
        range = range.translate([0, 1], [0, -1])

      {start, end} = range
      ranges = [start.row..end.row].map (row) ->
        [[row, start.column], [row, end.column]]

      selection.setBufferRange(ranges.shift(), {reversed})
      newSelections = ranges.map (range) =>
        @editor.addSelectionForScreenRange(range, {reversed})
      for selection in newSelections
        if selection.isEmpty()
          selection.destroy()
        else
          @selections.push(selection)
      sortComparable(@selections) # sorted in-place

    if wasReversed
      @setProperties {head: @getTop(), tail: @getBottom()}
    else
      @setProperties {head: @getBottom(), tail: @getTop()}

  setProperties: ({head, tail}={}) ->
    for selection in @selections
      swrap(selection).setProperties
        blockwise:
          head: selection is (head ? @getHead())
          tail: selection is (tail ? @getTail())

  isSingleLine: ->
    @selections.length is 1

  getTop: ->
    sortComparable(@selections)[0]

  getBottom: ->
    _.last(sortComparable(@selections))

  isReversed: ->
    (not @isSingleLine()) and @getTail() is @getBottom()

  getHead: ->
    if @isReversed() then @getTop() else @getBottom()

  getTail: ->
    _.detect @selections, (selection) ->
      swrap(selection).isBlockwiseTail()

  hasTail: ->
    @getTail()?

  otherEnd: ->
    @setProperties {head: @getTail(), tail: @getHead()}

  getBufferRowRange: ->
    startRow = @getTop().getBufferRowRange()[0]
    endRow = @getBottom().getBufferRowRange()[0]
    [startRow, endRow]

  setBufferPosition: (point) ->
    head = @getHead()
    for selection in @selections.slice() when selection isnt head
      @removeSelection(selection)
    head.cursor.setBufferPosition(point)

  # which must be 'start' or 'end'
  setPositionForSelections: (which) ->
    for selection in @selections
      point = selection.getBufferRange()[which]
      selection.cursor.setBufferPosition(point)

  moveSelection: (direction) ->
    isExpanding = =>
      return true if @isSingleLine()
      switch direction
        when 'down' then not @isReversed()
        when 'up' then @isReversed()

    if isExpanding()
      @addSelection(direction)
    else
      # FIXME: Since removed selection is always head
      # I can update head property automatically
      @removeSelection(@getHead())
    @setProperties()

  addSelection: (direction) ->
    @selections.push switch direction
      when 'up' then @addSelectionAbove()
      when 'down' then @addSelectionBelow()
    swrap.setReversedState(@editor, @getTail().isReversed())

  removeSelection: (selection) ->
    _.remove(@selections, selection)
    selection.destroy()

  getLastSelection: ->
    @editor.getLastSelection()

  addSelectionBelow: ->
    @getBottom().addSelectionBelow()
    @getLastSelection()

  addSelectionAbove: ->
    @getTop().addSelectionAbove()
    @getLastSelection()

  restoreCharacterwise: ->
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

module.exports = BlockwiseSelection
