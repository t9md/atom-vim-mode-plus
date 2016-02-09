{Range} = require 'atom'
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
    if @isSingleLine() then false else swrap(@getBottom()).isBlockwiseTail()

  getHead: ->
    if @isReversed() then @getTop() else @getBottom()

  getTail: ->
    if @isReversed() then @getBottom() else @getTop()

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

  setBufferRange: (range, options={}) ->
    head = @getHead()
    for selection in @selections.slice() when selection isnt head
      @removeSelection(selection)
    head.setBufferRange(range)
    @initialize(head)

  getBufferRange: ->
    topRange = @getTop().getBufferRange()
    bottomRange = @getBottom().getBufferRange()
    new Range(topRange.start, bottomRange.end)

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
      switch direction
        when 'up'
          @getTop().addSelectionAbove()
          @selections.unshift(selection = @editor.getLastSelection())
        when 'down'
          @getBottom().addSelectionBelow()
          @selections.push(selection = @editor.getLastSelection())
      swrap(selection).setReversedState(@getTail().isReversed())
    else
      @removeSelection(@getHead())
    @updateProperties()

  removeSelection: (selection) ->
    _.remove(@selections, selection)
    selection.destroy()

  restoreCharacterwise: ->
    reversed = @isReversed()
    head = @getHead()
    [startRow, endRow] = @getBufferRowRange()
    {start, end} = head.getBufferRange()
    range = if @isReversed() isnt head.isReversed()
      [[startRow, end.column - 1], [endRow, start.column + 1]]
    else
      [[startRow, start.column], [endRow, end.column]]
    head.setBufferRange(range, {reversed})
    swrap(head).resetProperties()

    for selection in @selections.slice() when selection isnt head
      selection.destroy()

module.exports = BlockwiseSelection
