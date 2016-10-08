_ = require 'underscore-plus'
{Range, Point, Disposable} = require 'atom'
{
  translatePointAndClip
  getRangeByTranslatePointAndClip
} = require './utils'

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
  expandOverLine: ({preserveGoalColumn}={}) ->
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
    {editor} = @selection
    tailPoint = @selection.getTailBufferPosition()
    if @selection.isReversed()
      point = translatePointAndClip(editor, tailPoint, 'backward')
      new Range(point, tailPoint)
    else
      point = translatePointAndClip(editor, tailPoint, 'forward', hello: 'when getting tailRange')
      new Range(tailPoint, point)

  saveProperties: ->
    properties = @captureProperties()
    unless @selection.isEmpty()
      # We select righted in visual-mode, this translation de-effect select-right-effect
      # so that after restoring preserved poperty we can do activate-visual mode without
      # special care
      endPoint = @selection.getBufferRange().end.translate([0, -1])
      endPoint = @selection.editor.clipBufferPosition(endPoint)
      if @selection.isReversed()
        properties.tail = endPoint
      else
        properties.head = endPoint
    @setProperties(properties)

  captureProperties: ->
    head: @selection.getHeadBufferPosition()
    tail: @selection.getTailBufferPosition()

  selectByProperties: ({head, tail}) ->
    # No problem if head is greater than tail, Range constructor swap start/end.
    @setBufferRange([tail, head])
    @setReversedState(head.isLessThan(tail))

  # Return true if selection was non-empty and non-reversed selection.
  # Equivalent to not selection.isEmpty() and not selection.isReversed()"
  isForwarding: ->
    head = @selection.getHeadBufferPosition()
    tail = @selection.getTailBufferPosition()
    head.isGreaterThan(tail)

  restoreColumnFromProperties: ->
    {head, tail} = @getProperties()
    return unless head? and tail?
    return if @selection.isEmpty()

    if @selection.isReversed()
      [start, end] = [head, tail]
    else
      [start, end] = [tail, head]
    [start.row, end.row] = @selection.getBufferRowRange()
    @withKeepingGoalColumn =>
      @setBufferRange([start, end], preserveFolds: true)
      @translateSelectionEndAndClip('backward', translate: false)

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

  withKeepingGoalColumn: (fn) ->
    {goalColumn} = @selection.cursor
    {start, end} = @getBufferRange()
    fn()
    @selection.cursor.goalColumn = goalColumn if goalColumn

  # direction must be one of ['forward', 'backward']
  # options: {translate: true or false} default true
  translateSelectionEndAndClip: (direction, options) ->
    editor = @selection.editor
    range = @getBufferRange()
    newRange = getRangeByTranslatePointAndClip(editor, range, "end", direction, options)
    @withKeepingGoalColumn =>
      @setBufferRange(newRange, preserveFolds: true)

  translateSelectionHeadAndClip: (direction, options) ->
    editor = @selection.editor
    which  = if @selection.isReversed() then 'start' else 'end'

    range = @getBufferRange()
    newRange = getRangeByTranslatePointAndClip(editor, range, which, direction, options)
    @withKeepingGoalColumn =>
      @setBufferRange(newRange, preserveFolds: true)

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

swrap.updateSelectionProperties = (editor, {unknownOnly}={}) ->
  for selection in editor.getSelections()
    continue if unknownOnly and swrap(selection).hasProperties()
    swrap(selection).saveProperties()

module.exports = swrap
