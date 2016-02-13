_ = require 'underscore-plus'
{Range} = require 'atom'
{isLinewiseRange} = require './utils'

class SelectionWrapper
  scope: 'vim-mode-plus'

  constructor: (@selection) ->

  getProperties: ->
    @selection.marker.getProperties()[@scope] ? {}

  setProperties: (newProp) ->
    prop = {}
    prop[@scope] = newProp
    @selection.marker.setProperties prop

  resetProperties: ->
    @setProperties null

  setBufferRangeSafely: (range) ->
    if range
      @setBufferRange(range, {autoscroll: false})
      if @selection.isLastSelection()
        @selection.cursor.autoscroll()

  getBufferRange: ->
    @selection.getBufferRange()

  reverse: ->
    @setReversedState(not @selection.isReversed())

    {head, tail} = @getProperties().characterwise ? {}
    if head? and tail?
      @setProperties characterwise: head: tail, tail: head

  setReversedState: (reversed) ->
    @setBufferRange @getBufferRange(), {autoscroll: true, reversed, preserveFolds: true}

  getRows: ->
    [startRow, endRow] = @selection.getBufferRowRange()
    [startRow..endRow]

  getRowCount: ->
    [startRow, endRow] = @selection.getBufferRowRange()
    endRow - startRow + 1

  selectRowRange: (rowRange) ->
    {editor} = @selection
    [startRow, endRow] = rowRange
    rangeStart = editor.bufferRangeForBufferRow(startRow, includeNewline: true)
    rangeEnd = editor.bufferRangeForBufferRow(endRow, includeNewline: true)
    @setBufferRange rangeStart.union(rangeEnd), {preserveFolds: true}

  # Native selection.expandOverLine is not aware of actual rowRange of selection.
  expandOverLine: (options={}) ->
    {preserveGoalColumn} = options
    if preserveGoalColumn
      {goalColumn} = @selection.cursor

    @selectRowRange @selection.getBufferRowRange()
    @selection.cursor.goalColumn = goalColumn if goalColumn

  getBufferRangeForTailRow: ->
    [startRow, endRow] = @selection.getBufferRowRange()
    row = if @selection.isReversed() then endRow else startRow
    @selection.editor.bufferRangeForBufferRow(row, includeNewline: true)

  getTailBufferRange: ->
    if (@isSingleRow() and @isLinewise())
      @getBufferRangeForTailRow()
    else
      {editor} = @selection
      start = @selection.getTailScreenPosition()
      end = if @selection.isReversed()
        editor.clipScreenPosition(start.translate([0, -1]), {clip: 'backward'})
      else
        editor.clipScreenPosition(start.translate([0, +1]), {clip: 'forward', wrapBeyondNewlines: true})
      editor.bufferRangeForScreenRange([start, end])

  preserveCharacterwise: ->
    {characterwise} = @detectCharacterwiseProperties()
    endPoint = if @selection.isReversed() then 'tail' else 'head'
    point = characterwise[endPoint].translate([0, -1])
    characterwise[endPoint] = @selection.editor.clipBufferPosition(point)
    @setProperties {characterwise}

  detectCharacterwiseProperties: ->
    characterwise:
      head: @selection.getHeadBufferPosition()
      tail: @selection.getTailBufferPosition()

  getCharacterwiseHeadPosition: ->
    @getProperties().characterwise?.head

  selectByProperties: (properties) ->
    {head, tail} = properties.characterwise
    # No problem if head is greater than tail, Range constructor swap start/end.
    @setBufferRange([tail, head])
    @setReversedState(true) if head.isLessThan(tail)

  restoreCharacterwise: (options={}) ->
    {preserveGoalColumn} = options
    {goalColumn} = @selection.cursor if preserveGoalColumn

    unless characterwise = @getProperties().characterwise
      return
    {head, tail} = characterwise
    [start, end] = if @selection.isReversed()
      [head, tail]
    else
      [tail, head]
    [start.row, end.row] = @selection.getBufferRowRange()
    @setBufferRange([start, end], {preserveFolds: true})
    if @selection.isReversed()
      @reverse()
      @selection.selectRight()
      @reverse()
    else
      @selection.selectRight()
    # [NOTE] Important! reset to null after restored.
    @resetProperties()
    @selection.cursor.goalColumn = goalColumn if goalColumn


  # Only for setting autoscroll option to false by default
  setBufferRange: (range, options={}) ->
    options.autoscroll ?= false
    @selection.setBufferRange(range, options)

  isBlockwiseHead: ->
    @getProperties().blockwise?.head

  isBlockwiseTail: ->
    @getProperties().blockwise?.tail

  # Return original text
  replace: (text) ->
    originalText = @selection.getText()
    @selection.insertText(text)
    originalText

  lineTextForBufferRows: ->
    {editor} = @selection
    @getRows().map (row) ->
      editor.lineTextForBufferRow(row)

  translate: (startDelta, endDelta=startDelta, options) ->
    newRange = @getBufferRange().translate(startDelta, endDelta)
    @setBufferRange(newRange, options)

  isSingleRow: ->
    [startRow, endRow] = @selection.getBufferRowRange()
    startRow is endRow

  isLinewise: ->
    isLinewiseRange(@getBufferRange())

  detectVisualModeSubmode: ->
    switch
      when @isLinewise() then 'linewise'
      when not @selection.isEmpty() then 'characterwise'
      else null

  switchToLinewise: (fn) ->
    @preserveCharacterwise()
    @expandOverLine(preserveGoalColumn: true)
    fn()
    @restoreCharacterwise()

swrap = (selection) ->
  new SelectionWrapper(selection)

swrap.setReversedState = (editor, reversed) ->
  editor.getSelections().forEach (selection) ->
    swrap(selection).setReversedState(reversed)

swrap.expandOverLine = (editor) ->
  editor.getSelections().forEach (selection) ->
    swrap(selection).expandOverLine()

swrap.reverse = (editor) ->
  editor.getSelections().forEach (selection) ->
    swrap(selection).reverse()

swrap.detectVisualModeSubmode = (editor) ->
  selections = editor.getSelections()
  results = (swrap(selection).detectVisualModeSubmode() for selection in selections)

  if results.every((r) -> r is 'linewise')
    'linewise'
  else if results.some((r) -> r is 'characterwise')
    'characterwise'
  else
    null

module.exports = swrap
