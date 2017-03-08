_ = require 'underscore-plus'
{Range, Point, Disposable} = require 'atom'
{
  translatePointAndClip
  getRangeByTranslatePointAndClip
  shrinkRangeEndToBeforeNewLine
  getFirstCharacterPositionForBufferRow
  getEndOfLineForBufferRow
  getBufferRangeForRowRange
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

  reverse: ->
    @setReversedState(not @selection.isReversed())

  setReversedState: (isReversed) ->
    return if @selection.isReversed() is isReversed

    if @hasProperties()
      {head, tail, wise} = @getProperties()
      @setProperties(head: tail, tail: head, wise: wise)

    @setBufferRange @getBufferRange(),
      autoscroll: true
      reversed: isReversed
      keepGoalColumn: false

  getRows: ->
    [startRow, endRow] = @selection.getBufferRowRange()
    [startRow..endRow]

  getRowCount: ->
    @getRows().length

  # Native selection.expandOverLine is not aware of actual rowRange of selection.
  # unused
  expandOverLine: ->
    rowRange = @selection.getBufferRowRange()
    range = getBufferRangeForRowRange(@selection.editor, rowRange)
    @setBufferRange(range)

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

  fixPropertiesForLinewise: ->
    return unless @hasProperties()
    {head, tail} = @getProperties()
    if @selection.isReversed()
      [start, end] = [head, tail]
    else
      [start, end] = [tail, head]
    [start.row, end.row] = @selection.getBufferRowRange()

  setWise: (value) ->
    @saveProperties() unless @hasProperties()
    @getProperties().wise = value

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
        @expandOverLine()
        @setWise('linewise')
        @fixPropertiesForLinewise()

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
    head = @selection.getHeadBufferPosition()
    tail = @selection.getTailBufferPosition()
    {head, tail}

  selectByProperties: ({head, tail}, options) ->
    # No problem if head is greater than tail, Range constructor swap start/end.
    @setBufferRange([tail, head], options)
    @setReversedState(head.isLessThan(tail))

  # Return true if selection was non-empty and non-reversed selection.
  # Equivalent to not selection.isEmpty() and not selection.isReversed()"
  isForwarding: ->
    head = @selection.getHeadBufferPosition()
    tail = @selection.getTailBufferPosition()
    head.isGreaterThan(tail)

  restoreFromProperties: ->
    @selectByProperties(@getProperties()) if @hasProperties()

  # set selections bufferRange with default option {autoscroll: false, preserveFolds: true}
  setBufferRange: (range, options={}) ->
    keepGoalColumn = options.keepGoalColumn ? true
    delete options.keepGoalColumn

    setBufferRange = =>
      @selection.setBufferRange(range, options)
    options.autoscroll ?= false
    options.preserveFolds ?= true

    if keepGoalColumn
      @withKeepingGoalColumn(setBufferRange)
    else
      setBufferRange()

  # Return original text
  replace: (text) ->
    originalText = @selection.getText()
    @selection.insertText(text)
    originalText

  isSingleRow: ->
    [startRow, endRow] = @selection.getBufferRowRange()
    startRow is endRow

  isLinewise: ->
    {start, end} = @getBufferRange()
    (start.row isnt end.row) and (start.column is end.column is 0)

  detectWise: ->
    if @isLinewise()
      'linewise'
    else
      'characterwise'

  withKeepingGoalColumn: (fn) ->
    goalColumn = @selection.cursor.goalColumn
    fn()
    @selection.cursor.goalColumn = goalColumn if goalColumn?

  # direction must be one of ['forward', 'backward']
  # options: {translate: true or false} default true
  translateSelectionEndAndClip: (direction, options) ->
    editor = @selection.editor
    range = @getBufferRange()
    newRange = getRangeByTranslatePointAndClip(editor, range, "end", direction, options)
    @setBufferRange(newRange)

  translateSelectionHeadAndClip: (direction, options) ->
    editor = @selection.editor
    which = if @selection.isReversed() then 'start' else 'end'

    range = @getBufferRange()
    newRange = getRangeByTranslatePointAndClip(editor, range, which, direction, options)
    @setBufferRange(newRange)

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
      if @getWise() is 'linewise'
        @restoreFromProperties()
        @translateSelectionEndAndClip('backward', translate: false)
      else
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

swrap.detectWise = (editor) ->
  if editor.getSelections().every((selection) -> swrap(selection).detectWise() is 'linewise')
    'linewise'
  else
    'characterwise'

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

swrap.fixPropertiesForLinewise = (editor) ->
  for selection in editor.getSelections()
    swrap(selection).fixPropertiesForLinewise()

module.exports = swrap
