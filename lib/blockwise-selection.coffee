_ = require 'underscore-plus'
swrap = require './selection-wrapper'
{sortComparable} = require './utils'

class BlockwiseSelection
  constructor: (@vimState, @selections) ->
    {@editor, @editorElement} = @vimState
    unless @hasTail()
      @setProperties {head: @getBottom(), tail: @getTop()}

  eachSelection: (fn) ->
    for selection in @selections
      fn(selection)

  updateProperties: ({head, tail}={}) ->
    head ?= @getHead()
    tail ?= @getTail()
    @setProperties {head, tail}

  setProperties: ({head, tail}) ->
    @eachSelection (selection) ->
      prop = {}
      prop.head = (selection is head) if head?
      prop.tail = (selection is tail) if tail?
      swrap(selection).setProperties(blockwise: prop)

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

  modifySelection: (direction) ->
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
