_ = require 'underscore-plus'
{Range, Point, Disposable} = require 'atom'
{
  translatePointAndClip
  getRangeByTranslatePointAndClip
  shrinkRangeEndToBeforeNewLine
  getFirstCharacterPositionForBufferRow
  getEndOfLineForBufferRow
  limitNumber
} = require './utils'

propertyStore = new Map

class SelectionWrapper
  constructor: (@selection) ->

  hasProperties: -> propertyStore.has(@selection)
  getProperties: -> propertyStore.get(@selection) ? {}
  setProperties: (prop) -> propertyStore.set(@selection, prop)
  clearProperties: -> propertyStore.delete(@selection)

  setBufferRangeSafely: (range, options) ->
    if range
      @setBufferRange(range, options)

  getBufferRange: ->
    @selection.getBufferRange()

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

  extendToEOL: ->
    [startRow, endRow] = @selection.getBufferRowRange()
    endRowRange = @selection.editor.bufferRangeForBufferRow(endRow)
    newRange = new Range(@getBufferRange().start, endRowRange.end)
    @setBufferRange(newRange)

  reverse: ->
    @setReversedState(not @selection.isReversed())

  setReversedState: (reversed) ->
    return if @selection.isReversed() is reversed
    {head, tail} = @getProperties()
    if head? and tail?
      @setProperties(head: tail, tail: head)

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
    if @selection.isReversed()
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

  setWise: (value) ->
    @saveProperties() unless @hasProperties()
    properties = @getProperties()
    properties.wise = value

  getWise: ->
    @getProperties()?.wise ? 'characterwise'

  applyWise: (newWise) ->
    # NOTE:
    # Must call against normalized selection
    # Don't call non-normalized selection

    switch newWise
      when 'characterwise'
        @translateSelectionEndAndClip('forward')
        @saveProperties()
        @setWise('characterwise')
      when 'linewise'
        @complementGoalColumn()
        @expandOverLine(preserveGoalColumn: true)
        @setWise('linewise')

  complementGoalColumn: ->
    unless @selection.cursor.goalColumn?
      column = @getBufferPositionFor('head', fromProperty: true, allowFallback: true).column
      @selection.cursor.goalColumn = column

  # [FIXME]
  # When `keepColumnOnSelectTextObject` was true,
  #  cursor marker in vL-mode exceed EOL if initial row is longer than endRow of
  #  selected text-object.
  # To avoid this wired cursor position representation, this fucntion clip
  #  selection properties not exceeds EOL.
  # But this should be temporal workaround, depending this kind of ad-hoc adjustment is
  # basically bad in the long run.
  clipPropertiesTillEndOfLine: ->
    return unless @hasProperties()

    editor = @selection.editor
    headRowEOL = getEndOfLineForBufferRow(editor, @getHeadRow())
    tailRowEOL = getEndOfLineForBufferRow(editor, @getTailRow())
    headMaxColumn = limitNumber(headRowEOL.column - 1, min: 0)
    tailMaxColumn = limitNumber(tailRowEOL.column - 1, min: 0)

    properties = @getProperties()
    if properties.head.column > headMaxColumn
      properties.head.column = headMaxColumn

    if properties.tail.column > tailMaxColumn
      properties.tail.column = tailMaxColumn

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

  applyColumnFromProperties: ->
    selectionProperties = @getProperties()
    return unless selectionProperties?
    {head, tail} = selectionProperties

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
    {keepGoalColumn} = options
    delete options.keepGoalColumn
    options.autoscroll ?= false
    setBufferRange = =>
      @selection.setBufferRange(range, options)

    if keepGoalColumn
      @withKeepingGoalColumn(setBufferRange)
    else
      setBufferRange()

  # Return original text
  replace: (text) ->
    originalText = @selection.getText()
    @selection.insertText(text)
    originalText

  lineTextForBufferRows: ->
    {editor} = @selection
    @getRows().map (row) ->
      editor.lineTextForBufferRow(row)

  mapToLineText: (fn, {includeNewline}={}) ->
    {editor} = @selection
    textForRow = (row) ->
      range = editor.bufferRangeForBufferRow(row, {includeNewline})
      editor.getTextInBufferRange(range)

    @getRows().map(textForRow).map(fn)

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
    @selection.cursor.goalColumn = goalColumn if goalColumn?

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

  shrinkEndToBeforeNewLine: ->
    newRange = shrinkRangeEndToBeforeNewLine(@getBufferRange())
    @setBufferRange(newRange)

  setStartToFirstCharacterOfLine: ->
    {start, end} = @getBufferRange()
    newStart = getFirstCharacterPositionForBufferRow(@selection.editor, start.row)
    newRange = new Range(newStart, end)
    @setBufferRange(newRange)

  # Return selection extent to replay blockwise selection on `.` repeating.
  getBlockwiseSelectionExtent: ->
    head = @selection.getHeadBufferPosition()
    tail = @selection.getTailBufferPosition()
    new Point(head.row - tail.row, head.column - tail.column)

  normalize: ->
    unless @selection.isEmpty()
      switch @getWise()
        when 'characterwise'
          @translateSelectionEndAndClip('backward')
        when 'linewise'
          @applyColumnFromProperties()
        when 'blockwise'
          @translateSelectionEndAndClip('backward')
    @clearProperties()

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

swrap.saveProperties = (editor) ->
  for selection in editor.getSelections()
    swrap(selection).saveProperties()

swrap.complementGoalColumn = (editor) ->
  for selection in editor.getSelections()
    swrap(selection).complementGoalColumn()

swrap.normalize = (editor) ->
  for selection in editor.getSelections()
    swrap(selection).normalize()

swrap.setWise = (editor, value) ->
  for selection in editor.getSelections()
    swrap(selection).setWise(value)

swrap.applyWise = (editor, value) ->
  for selection in editor.getSelections()
    swrap(selection).applyWise(value)

swrap.clearProperties = (editor) ->
  for selection in editor.getSelections()
    swrap(selection).clearProperties()

module.exports = swrap
