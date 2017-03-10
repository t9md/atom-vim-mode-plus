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
    properties = @captureProperties()
    unless @selection.isEmpty()
      # We selectRight-ed in visual-mode, this translation de-effect select-right-effect
      # So that we can activate-visual-mode without special translation after restoreing properties.
      endPoint = @getBufferRange().end.translate([0, -1])
      endPoint = @selection.editor.clipBufferPosition(endPoint)
      if @selection.isReversed()
        properties.tail = endPoint
      else
        properties.head = endPoint
    @setProperties(properties)

  fixPropertiesForLinewise: ->
    assertWithException(@hasProperties(), "trying to fixPropertiesForLinewise on properties-less selection")

    {head, tail} = @getProperties()
    if @selection.isReversed()
      [start, end] = [head, tail]
    else
      [start, end] = [tail, head]
    [start.row, end.row] = @selection.getBufferRowRange()

  applyWise: (newWise) ->
    # NOTE:
    # Must call against normalized selection
    # Don't call non-normalized selection
    switch newWise
      when 'characterwise'
        @translateSelectionEndAndClip('forward')
        @saveProperties()
        @setWiseProperty(newWise)
      when 'linewise'
        @complementGoalColumn()
        @expandOverLine()
        @saveProperties() unless @hasProperties()
        @setWiseProperty(newWise)
        @fixPropertiesForLinewise()

  complementGoalColumn: ->
    unless @selection.cursor.goalColumn?
      column = @getBufferPositionFor('head', from: ['property', 'selection']).column
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

  detectWise: ->
    if isLinewiseRange(@getBufferRange())
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
    unless @selection.isEmpty()
      if @hasProperties() and @getProperties().wise is 'linewise'
        @applyColumnFromProperties()
      else
        @translateSelectionEndAndClip('backward')
    @clearProperties()

swrap = (selection) ->
  new SelectionWrapper(selection)

swrap.setReversedState = (editor, reversed) ->
  for selection in editor.getSelections()
    swrap(selection).setReversedState(reversed)

swrap.detectWise = (editor) ->
  selectionWiseIsLinewise = (selection) -> swrap(selection).detectWise() is 'linewise'
  if editor.getSelections().every(selectionWiseIsLinewise)
    'linewise'
  else
    'characterwise'

swrap.saveProperties = (editor) ->
  for selection in editor.getSelections()
    swrap(selection).saveProperties()

swrap.clearProperties = (editor) ->
  for selection in editor.getSelections()
    swrap(selection).clearProperties()

swrap.normalize = (editor) ->
  for selection in editor.getSelections()
    swrap(selection).normalize()

swrap.applyWise = (editor, value) ->
  for selection in editor.getSelections()
    swrap(selection).applyWise(value)

swrap.fixPropertiesForLinewise = (editor) ->
  for selection in editor.getSelections()
    swrap(selection).fixPropertiesForLinewise()

# Return function to restore
# Used in vmp-move-selected-text
swrap.switchToLinewise = (editor) ->
  swrap.saveProperties(editor)
  swrap.applyWise(editor, 'linewise')
  new Disposable ->
    swrap.normalize(editor)
    swrap.applyWise(editor, 'characterwise')

module.exports = swrap
