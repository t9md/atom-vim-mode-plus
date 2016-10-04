_ = require 'underscore-plus'
{Range, Point, Disposable} = require 'atom'

propertyStore = new Map

translatePointAndClip = (editor, point, direction, {translate, hello}={}) ->
  translate ?= true
  point = Point.fromObject(point)

  switch direction
    when 'forward'
      point = point.translate([0, +1]) if translate
      eol = editor.bufferRangeForBufferRow(point.row).end
      # console.log 'point, eol, hello', [point.toString(), eol.toString(), hello]

      if point.isEqual(eol)
        return Point.min(point, editor.getEofBufferPosition())

      if point.isGreaterThan(eol)
        return Point.min(Point(point.row + 1, 0), editor.getEofBufferPosition())

      point = Point.min(point, editor.getEofBufferPosition())
    when 'backward'
      point = point.translate([0, -1]) if translate
      # console.log 'point, hello', [point.toString(), hello]

      if point.column < 0
        newRow = point.row - 1
        eol = editor.bufferRangeForBufferRow(newRow).end
        point = new Point(newRow, eol.column)

      point = Point.max(point, Point.ZERO)

  screenPoint = editor.screenPositionForBufferPosition(point, clipDirection: direction)
  editor.bufferPositionForScreenPosition(screenPoint)

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

  preserveCharacterwise: ->
    properties = @detectCharacterwiseProperties()
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
  # "not selection.isReversed() and not selection.isEmpty()"
  isForwarding: ->
    head = @selection.getHeadBufferPosition()
    tail = @selection.getTailBufferPosition()
    head.isGreaterThan(tail)

  normalize: ->
    {head, tail} = @getProperties()
    return unless head? and tail?
    return if @selection.isEmpty()

    if @selection.isReversed()
      [start, end] = [head, tail]
    else
      [start, end] = [tail, head]
    [start.row, end.row] = @selection.getBufferRowRange()

    {goalColumn} = @selection.cursor
    end = translatePointAndClip(@selection.editor, end, 'backward', translate: false)
    @setBufferRange([start, end], {preserveFolds: true})
    @selection.cursor.goalColumn = goalColumn if goalColumn?

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

  # direction must be one of ['forward', 'backward']
  # options: {translate: true or false} default true
  translateSelectionEndAndClip: (direction, options) ->
    {goalColumn} = @selection.cursor
    {start, end} = @getBufferRange()
    # console.log 'bef', end.toString()
    newEnd = translatePointAndClip(@selection.editor, end, direction, options)
    # console.log 'aft', newEnd.toString()
    @setBufferRange([start, newEnd], {preserveFolds: true})
    @selection.cursor.goalColumn = goalColumn if goalColumn

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
    swrap(selection).preserveCharacterwise()

module.exports = swrap
