_ = require 'underscore-plus'
{Range} = require 'atom'

class SelectionWrapper
  scope: 'vim-mode-plus'

  constructor: (@selection) ->

  getProperties: ->
    @selection.marker.getProperties()[@scope] ? {}

  setProperties: (newProp) ->
    prop = {}
    prop[@scope] = newProp
    @selection.marker.setProperties prop

  updateProperties: (value) ->
    # @getProperties() get result of getProperties() which is safe to extend.
    # So OK to directly extend.
    @setProperties _.deepExtend(@getProperties(), value)

  resetProperties: ->
    @setProperties null

  setBufferRangeSafely: (range) ->
    if range
      @setBufferRange(range, {autoscroll: true})

  reverse: ->
    @setReversedState(not @selection.isReversed())

  setReversedState: (boolean) ->
    options = {autoscroll: true, reversed: boolean}
    @setBufferRange @selection.getBufferRange(), options

  selectRowRange: (rowRange) ->
    {editor} = @selection
    [startRow, endRow] = rowRange
    rangeStart = editor.bufferRangeForBufferRow(startRow, includeNewline: true)
    rangeEnd   = editor.bufferRangeForBufferRow(endRow, includeNewline: true)
    @setBufferRange rangeStart.union(rangeEnd), {preserveFolds: true}

  # Native selection.expandOverLine is not aware of actual rowRange of selection.
  expandOverLine: ->
    @selectRowRange @selection.getBufferRowRange()

  getTailRange: ->
    {start, end} = @selection.getBufferRange()
    if (start.row isnt end.row) and (start.column is 0) and (end.column is 0)
      [startRow, endRow] = @selection.getBufferRowRange()
      row = if @selection.isReversed() then endRow else startRow
      @selection.editor.bufferRangeForBufferRow(row, includeNewline: true)
    else
      point = @selection.getTailBufferPosition()
      columnDelta = if @selection.isReversed() then -1 else +1
      Range.fromPointWithDelta(point, 0, columnDelta)

  preserveCharacterwise: ->
    @updateProperties
      characterwise:
        range: @selection.getBufferRange()
        reversed: @selection.isReversed()

  restoreCharacterwise: ->
    {characterwise} = @getProperties()
    return unless characterwise
    {range: {start, end}, reversed} = characterwise
    rows = @selection.getBufferRowRange()

    reversedChanged = (@selection.isReversed() isnt reversed) # reverse status changed
    rows.reverse() if reversedChanged

    [startRow, endRow] = rows
    start.row = startRow
    end.row = endRow
    range = new Range(start, end)

    if reversedChanged
      rangeTaranslation = [[0, +1], [0, -1]]
      rangeTaranslation.reverse() if @selection.isReversed()
      range = range.translate(rangeTaranslation...)

    @setBufferRange(range)
    # [NOTE] Important! reset to null after restored.
    @resetProperties()

  # Only for setting autoscroll option to false by default
  setBufferRange: (range, options={}) ->
    options.autoscroll ?= false
    @selection.setBufferRange(range, options)

  isBlockwiseHead: ->
    @getProperties().blockwise?.head

  isBlockwiseTail: ->
    @getProperties().blockwise?.tail

swrap = (selection) ->
  new SelectionWrapper(selection)

module.exports = swrap
