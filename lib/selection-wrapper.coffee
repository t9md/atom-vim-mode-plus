_ = require 'underscore-plus'
{Range} = require 'atom'

swrap = (selection) ->
  scope = 'vimModePlus'
  get: ->
    selection.marker.getProperties()[scope] ? {}

  set: (newProp) ->
    prop = {}
    prop[scope] = newProp
    selection.marker.setProperties prop

  update: (value) ->
    # @get() get result of getProperties() which is safe to extend.
    # So OK to directly extend.
    @set _.deepExtend(@get(), value)

  clear: ->
    @set null

  setBufferRangeSafely: (range) ->
    if range
      selection.setBufferRange(range)

  reverse: ->
    @setReversedState(not selection.isReversed())

  setReversedState: (boolean) ->
    selection.setBufferRange(selection.getBufferRange(), reversed: boolean)

  selectRowRange: (rowRange) ->
    {editor} = selection
    [startRow, endRow] = rowRange
    rangeStart = editor.bufferRangeForBufferRow(startRow, includeNewline: true)
    rangeEnd   = editor.bufferRangeForBufferRow(endRow, includeNewline: true)
    selection.setBufferRange(rangeStart.union(rangeEnd))

  # Native selection.expandOverLine is not aware of actual rowRange of selection.
  expandOverLine: ->
    @selectRowRange selection.getBufferRowRange()

  preserveCharacterwise: ->
    @update
      characterwise:
        range: selection.getBufferRange()
        reversed: selection.isReversed()

  restoreCharacterwise: ->
    {characterwise} = @get()
    return unless characterwise
    {range: {start, end}, reversed} = characterwise
    rows = selection.getBufferRowRange()

    reversedChanged = (selection.isReversed() isnt reversed) # reverse status changed
    rows.reverse() if reversedChanged

    [startRow, endRow] = rows
    start.row = startRow
    end.row = endRow
    range = new Range(start, end)

    if reversedChanged
      rangeTaranslation = [[0, +1], [0, -1]]
      rangeTaranslation.reverse() if selection.isReversed()
      range = range.translate(rangeTaranslation...)

    selection.setBufferRange(range)
    # [NOTE] Important! reset to null after restored.
    @clear()

module.exports = swrap
