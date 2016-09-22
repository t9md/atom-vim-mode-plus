_ = require 'underscore-plus'
{Range, Disposable} = require 'atom'

propertyStore = new Map

class SelectionWrapper
  constructor: (@selection) ->

  hasProperties: -> propertyStore.has(@selection)
  getProperties: -> propertyStore.get(@selection) ? {}
  setProperties: (prop) -> propertyStore.set(@selection, prop)
  clearProperties: -> propertyStore.delete(@selection)

  setBufferRangeSafely: (range) ->
    if range
      @setBufferRange(range)
      if @selection.isLastSelection()
        @selection.cursor.autoscroll()

  getBufferRange: ->
    @selection.getBufferRange()

  getNormalizedBufferPosition: ->
    point = @selection.getHeadBufferPosition()
    if @isForwarding()
      {editor} = @selection
      screenPoint = editor.screenPositionForBufferPosition(point).translate([0, -1])
      editor.bufferPositionForScreenPosition(screenPoint, clipDirection: 'backward')
    else
      point

  # Return function to dispose(=revert) normalization.
  normalizeBufferPosition: ->
    head = @selection.getHeadBufferPosition()
    point = @getNormalizedBufferPosition()
    @selection.modifySelection =>
      @selection.cursor.setBufferPosition(point)

    new Disposable =>
      unless head.isEqual(point)
        @selection.modifySelection =>
          @selection.cursor.setBufferPosition(head)

  getBufferPositionFor: (which, {fromProperty, allowFallback}={}) ->
    fromProperty ?= false
    allowFallback ?= false

    if fromProperty and (not @hasProperties()) and allowFallback
      fromProperty = false

    if fromProperty
      {head, tail} = @getProperties()
      if head.isGreaterThanOrEqual(tail)
        [start, end] = [tail, head]
      else
        [start, end] = [head, tail]
    else
      {start, end} = @selection.getBufferRange()
      head = @selection.getHeadBufferPosition()
      tail = @selection.getTailBufferPosition()

    switch which
      when 'start' then start
      when 'end' then end
      when 'head' then head
      when 'tail' then tail

  # options: {fromProperty}
  setBufferPositionTo: (which, options) ->
    point = @getBufferPositionFor(which, options)
    @selection.cursor.setBufferPosition(point)

  mergeBufferRange: (range, option) ->
    @setBufferRange(@getBufferRange().union(range), option)

  reverse: ->
    @setReversedState(not @selection.isReversed())

    {head, tail} = @getProperties()
    if head? and tail?
      @setProperties(head: tail, tail: head)

  setReversedState: (reversed) ->
    options = {autoscroll: true, reversed, preserveFolds: true}
    @setBufferRange(@getBufferRange(), options)

  getRows: ->
    [startRow, endRow] = @selection.getBufferRowRange()
    [startRow..endRow]

  getRowCount: ->
    @getRows().length

  selectRowRange: (rowRange) ->
    {editor} = @selection
    [startRange, endRange] = rowRange.map (row) ->
      editor.bufferRangeForBufferRow(row, includeNewline: true)
    range = startRange.union(endRange)
    @setBufferRange(range, preserveFolds: true)

  # Native selection.expandOverLine is not aware of actual rowRange of selection.
  expandOverLine: (options={}) ->
    {preserveGoalColumn} = options
    if preserveGoalColumn
      {goalColumn} = @selection.cursor

    @selectRowRange(@selection.getBufferRowRange())
    @selection.cursor.goalColumn = goalColumn if goalColumn

  getRowFor: (where) ->
    [startRow, endRow] = @selection.getBufferRowRange()
    unless @selection.isReversed()
      [headRow, tailRow] = [startRow, endRow]
    else
      [headRow, tailRow] = [endRow, startRow]

    switch where
      when 'start' then startRow
      when 'end' then endRow
      when 'head' then headRow
      when 'tail' then tailRow

  getHeadRow: -> @getRowFor('head')
  getTailRow: -> @getRowFor('tail')
  getStartRow: -> @getRowFor('start')
  getEndRow: -> @getRowFor('end')

  getTailBufferRange: ->
    if (@isSingleRow() and @isLinewise())
      @selection.editor.bufferRangeForBufferRow(@getTailRow(), includeNewline: true)
    else
      {editor} = @selection
      start = @selection.getTailScreenPosition()
      end = if @selection.isReversed()
        editor.clipScreenPosition(start.translate([0, -1]), clipDirection: 'backward')
      else
        editor.clipScreenPosition(start.translate([0, +1]), clipDirection: 'forward')

      editor.bufferRangeForScreenRange([start, end])

  preserveCharacterwise: ->
    basename = require('path').basename
    properties = @detectCharacterwiseProperties()
    unless @selection.isEmpty()
      endPoint = if @selection.isReversed() then 'tail' else 'head'
      # In case selection is empty, I don't want to translate end position
      # [FIXME] Check if removing this translation logic can simplify code?
      point = properties[endPoint].translate([0, -1])
      properties[endPoint] = @selection.editor.clipBufferPosition(point)
    @setProperties(properties)

  detectCharacterwiseProperties: ->
    head: @selection.getHeadBufferPosition()
    tail: @selection.getTailBufferPosition()

  getCharacterwiseHeadPosition: ->
    @getProperties().head

  selectByProperties: ({head, tail}) ->
    # No problem if head is greater than tail, Range constructor swap start/end.
    @setBufferRange([tail, head])
    @setReversedState(head.isLessThan(tail))

  # Equivalent to
  # "not (selection.isReversed() or selection.isEmpty())"
  isForwarding: ->
    head = @selection.getHeadBufferPosition()
    tail = @selection.getTailBufferPosition()
    head.isGreaterThan(tail)

  restoreCharacterwise: (options={}) ->
    {preserveGoalColumn} = options
    {goalColumn} = @selection.cursor if preserveGoalColumn

    {head, tail} = @getProperties()
    return unless head? and tail?

    if @selection.isReversed()
      [start, end] = [head, tail]
    else
      [start, end] = [tail, head]
    [start.row, end.row] = @selection.getBufferRowRange()

    editor = @selection.editor
    screenPoint = editor.screenPositionForBufferPosition(end).translate([0, 1])
    end = editor.bufferPositionForScreenPosition(screenPoint, clipDirection: 'forward')

    @setBufferRange([start, end], {preserveFolds: true})
    @clearProperties()
    @selection.cursor.goalColumn = goalColumn if goalColumn

  # Only for setting autoscroll option to false by default
  setBufferRange: (range, options={}) ->
    options.autoscroll ?= false
    @selection.setBufferRange(range, options)

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
    {start, end} = @getBufferRange()
    (start.row isnt end.row) and (start.column is end.column is 0)

  detectVisualModeSubmode: ->
    if @selection.isEmpty()
      null
    else if @isLinewise()
      'linewise'
    else
      'characterwise'

swrap = (selection) ->
  new SelectionWrapper(selection)

swrap.setReversedState = (editor, reversed) ->
  editor.getSelections().forEach (selection) ->
    swrap(selection).setReversedState(reversed)

swrap.expandOverLine = (editor, options) ->
  editor.getSelections().forEach (selection) ->
    swrap(selection).expandOverLine(options)

swrap.reverse = (editor) ->
  editor.getSelections().forEach (selection) ->
    swrap(selection).reverse()

swrap.clearProperties = (editor) ->
  editor.getSelections().forEach (selection) ->
    swrap(selection).clearProperties()

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
