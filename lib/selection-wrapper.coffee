# TODO-#698 remove when finished
{inspect} = require 'util'
p = (args...) -> console.log inspect(args...)

{Range, Point, Disposable} = require 'atom'
{
  translatePointAndClip
  getRangeByTranslatePointAndClip
  getEndOfLineForBufferRow
  getBufferRangeForRowRange
  limitNumber
  isLinewiseRange
  assertWithException
} = require './utils'

propertyStore = new Map

class SelectionWrapper
  constructor: (@selection) ->

  hasProperties: -> propertyStore.has(@selection)
  getProperties: -> propertyStore.get(@selection)
  setProperties: (prop) -> propertyStore.set(@selection, prop)
  clearProperties: -> propertyStore.delete(@selection)
  setWiseProperty: (value) -> @getProperties().wise = value

  setBufferRangeSafely: (range, options) ->
    if range
      @setBufferRange(range, options)

  getBufferRange: ->
    @selection.getBufferRange()

  getBufferPositionFor: (which, {from}={}) ->
    from ?= ['selection']

    getPosition = (which) ->
      switch which
        when 'start' then start
        when 'end' then end
        when 'head' then head
        when 'tail' then tail

    if ('property' in from) and @hasProperties()
      {head, tail} = @getProperties()
      if head.isGreaterThanOrEqual(tail)
        [start, end] = [tail, head]
      else
        [start, end] = [head, tail]
      return getPosition(which)

    if 'selection' in from
      {start, end} = @selection.getBufferRange()
      head = @selection.getHeadBufferPosition()
      tail = @selection.getTailBufferPosition()
      return getPosition(which)

  setBufferPositionTo: (which, options) ->
    point = @getBufferPositionFor(which, options)
    @selection.cursor.setBufferPosition(point)

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
      point = translatePointAndClip(editor, tailPoint, 'forward')
      new Range(tailPoint, point)

  saveProperties: ->
    head = @selection.getHeadBufferPosition()
    tail = @selection.getTailBufferPosition()
    if @selection.isEmpty()
      properties = {head, tail}
    else
      # We selectRight-ed in visual-mode, this translation de-effect select-right-effect
      # So that we can activate-visual-mode without special translation after restoreing properties.
      {end} = @getBufferRange()
      end = translatePointAndClip(@selection.editor, end, 'backward')
      if @selection.isReversed()
        properties = {head: head, tail: end}
      else
        properties = {head: end, tail: tail}
    @setProperties(properties)

  fixPropertyRowToRowRange: ->
    assertWithException(@hasProperties(), "trying to fixPropertyRowToRowRange on properties-less selection")

    {head, tail} = @getProperties()
    if @selection.isReversed()
      [start, end] = [head, tail]
    else
      [start, end] = [tail, head]
    [start.row, end.row] = @selection.getBufferRowRange()

  # wise must be 'characterwise' or 'linewise'
  applyWise: (wise) ->
    assertWithException(@hasProperties(), "trying to applyWise on properties-less selection")
    # NOTE:
    # Must call against normalized selection
    # Don't call non-normalized selection
    switch wise
      when 'characterwise'
        @translateSelectionEndAndClip('forward') # equivalent to core selection.selectRight but keep goalColumn
      when 'linewise'
        @complementGoalColumn()
        # Even if end.column is 0, expand over that end.row( don't care selection.getRowRange() )
        {start, end} = @getBufferRange()
        range = getBufferRangeForRowRange(@selection.editor, [start.row, end.row])
        @setBufferRange(range)

    @setWiseProperty(wise)

  complementGoalColumn: ->
    unless @selection.cursor.goalColumn?
      column = @getBufferPositionFor('head', from: ['property', 'selection']).column
      @selection.cursor.goalColumn = column

  captureProperties: ->
    head = @selection.getHeadBufferPosition()
    tail = @selection.getTailBufferPosition()
    {head, tail}

  selectByProperties: ({head, tail}, options) ->
    # No problem if head is greater than tail, Range constructor swap start/end.
    @setBufferRange([tail, head], options)
    @setReversedState(head.isLessThan(tail))

  applyColumnFromProperties: ->
    selectionProperties = @getProperties()
    return unless selectionProperties?
    {head, tail} = selectionProperties

    if @selection.isReversed()
      [start, end] = [head, tail]
    else
      [start, end] = [tail, head]
    [start.row, end.row] = @selection.getBufferRowRange()
    @setBufferRange([start, end])
    @translateSelectionEndAndClip('backward', translate: false)

  # set selections bufferRange with default option {autoscroll: false, preserveFolds: true}
  setBufferRange: (range, options={}) ->
    if options.keepGoalColumn ? true
      goalColumn = @selection.cursor.goalColumn
    delete options.keepGoalColumn
    options.autoscroll ?= false
    options.preserveFolds ?= true
    @selection.setBufferRange(range, options)
    @selection.cursor.goalColumn = goalColumn if goalColumn?

  isSingleRow: ->
    [startRow, endRow] = @selection.getBufferRowRange()
    startRow is endRow

  isLinewiseRange: ->
    isLinewiseRange(@getBufferRange())

  detectWise: ->
    if @isLinewiseRange()
      'linewise'
    else
      'characterwise'

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

  # Return selection extent to replay blockwise selection on `.` repeating.
  getBlockwiseSelectionExtent: ->
    head = @selection.getHeadBufferPosition()
    tail = @selection.getTailBufferPosition()
    new Point(head.row - tail.row, head.column - tail.column)

  normalize: ->
    assertWithException(not @selection.isEmpty(), "attempted to normalize for empty selection")
    assertWithException(@hasProperties(), "attempted to normalize for un-propertized selection")
    if @getProperties().wise is 'linewise'
      @fixPropertyRowToRowRange()
    @selectByProperties(@getProperties())

swrap = (selection) ->
  new SelectionWrapper(selection)

swrap.setReversedState = (editor, reversed) ->
  for selection in editor.getSelections()
    swrap(selection).setReversedState(reversed)

swrap.detectWise = (editor) ->
  if editor.getSelections().every((selection) -> swrap(selection).isLinewiseRange())
    'linewise'
  else
    'characterwise'

swrap.saveProperties = (editor) ->
  for selection in editor.getSelections()
    swrap(selection).saveProperties()

swrap.clearProperties = (editor) ->
  for selection in editor.getSelections()
    swrap(selection).clearProperties()

swrap.hasProperties = (editor) ->
  editor.getSelections().every (selection) ->
    swrap(selection).hasProperties()

{inspect} = require 'util'
swrap.dumpProperties = (editor) ->
  for selection in editor.getSelections() when swrap(selection).hasProperties()
    console.log inspect(swrap(selection).getProperties())

swrap.normalize = (editor) ->
  for selection in editor.getSelections()
    swrap(selection).normalize()

swrap.applyWise = (editor, value) ->
  for selection in editor.getSelections()
    swrap(selection).applyWise(value)

swrap.fixPropertyRowToRowRange = (editor) ->
  for selection in editor.getSelections()
    swrap(selection).fixPropertyRowToRowRange()

# Return function to restore
# Used in vmp-move-selected-text
swrap.switchToLinewise = (editor) ->
  swrap.saveProperties(editor)
  swrap.applyWise(editor, 'linewise')
  new Disposable ->
    swrap.normalize(editor)
    swrap.applyWise(editor, 'characterwise')

module.exports = swrap
