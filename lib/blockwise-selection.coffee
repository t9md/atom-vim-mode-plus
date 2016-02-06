_ = require 'underscore-plus'

swrap = require './selection-wrapper'

class BlockwiseSelection
  constructor: (selection) ->
    {@editor} = selection
    @initialize(selection)
    @updateProperties()

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
    @updateProperties(reversed: wasReversed)
    console.log 'initialized reversed state = ', wasReversed, @isReversed()

  updateProperties: ({reversed}={}) ->
    reversed ?= @isReversed()
    [head, tail] = if reversed
      [@getTop(), @getBottom()]
    else
      [@getBottom(), @getTop()]

    for selection in @selections
      swrap(selection).setProperties
        blockwise:
          head: selection is head
          tail: selection is tail

  isSingleLine: ->
    @selections.length is 1

  getTop: ->
    @selections[0]

  getBottom: ->
    _.last(@selections)

  isReversed: ->
    (not @isSingleLine()) and @getTail() is @getBottom()

  getHead: ->
    if @isReversed() then @getTop() else @getBottom()

  getTail: ->
    _.detect @selections, (selection) ->
      swrap(selection).isBlockwiseTail()

  hasTail: ->
    @getTail()?

  reverse: ->
    @updateProperties(reversed: not @isReversed())

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
      @removeSelection(@getHead())
    @updateProperties()

  addSelection: (direction) ->
    switch direction
      when 'up'
        selection = @addSelectionAbove()
        @selections.unshift(selection)
      when 'down'
        selection = @addSelectionBelow()
        @selections.push(selection)
    swrap(selection).setReversedState(@getTail().isReversed())

  removeSelection: (selection) ->
    _.remove(@selections, selection)
    selection.destroy()

  addSelectionBelow: ->
    @getBottom().addSelectionBelow()
    @editor.getLastSelection()

  addSelectionAbove: ->
    @getTop().addSelectionAbove()
    @editor.getLastSelection()

  restoreCharacterwise: ->
    reversed = @isReversed()
    head = @getHead()
    headIsReversed = head.isReversed()
    [startRow, endRow] = @getBufferRowRange()
    {start, end} = head.getBufferRange()
    range = if reversed isnt headIsReversed
      [[startRow, end.column - 1], [endRow, start.column + 1]]
    else
      [[startRow, start.column], [endRow, end.column]]
    head.setBufferRange(range, {reversed})
    swrap(head).resetProperties()

    for selection in @selections.slice() when selection isnt head
      selection.destroy()

module.exports = BlockwiseSelection
