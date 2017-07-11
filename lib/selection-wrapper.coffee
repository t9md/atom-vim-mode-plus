{Range, Point, Disposable} = require 'atom'
{
  translatePointAndClip
  getRangeByTranslatePointAndClip
  getEndOfLineForBufferRow
  getBufferRangeForRowRange
  limitNumber
  isLinewiseRange
  assertWithException
  getFoldEndRowForRow
} = require './utils'
settings = require './settings'
BlockwiseSelection = require './blockwise-selection'

propertyStore = new Map

class SelectionWrapper
  constructor: (@selection) ->
  hasProperties: -> propertyStore.has(@selection)
  getProperties: -> propertyStore.get(@selection)
  setProperties: (prop) -> propertyStore.set(@selection, prop)
  clearProperties: -> propertyStore.delete(@selection)

  setBufferRangeSafely: (range, options) ->
    if range
      @setBufferRange(range, options)

  getBufferRange: ->
    @selection.getBufferRange()

  getBufferPositionFor: (which, {from}={}) ->
    for _from in from ? ['selection']
      switch _from
        when 'property'
          continue unless @hasProperties()

          properties = @getProperties()
          return switch which
            when 'start' then (if @selection.isReversed() then properties.head else properties.tail)
            when 'end' then (if @selection.isReversed() then properties.tail else properties.head)
            when 'head' then properties.head
            when 'tail' then properties.tail

        when 'selection'
          return switch which
            when 'start' then @selection.getBufferRange().start
            when 'end' then @selection.getBufferRange().end
            when 'head' then @selection.getHeadBufferPosition()
            when 'tail' then @selection.getTailBufferPosition()
    null

  setBufferPositionTo: (which) ->
    @selection.cursor.setBufferPosition(@getBufferPositionFor(which))

  setReversedState: (isReversed) ->
    return if @selection.isReversed() is isReversed
    assertWithException(@hasProperties(), "trying to reverse selection which is non-empty and property-lesss")

    {head, tail} = @getProperties()
    @setProperties(head: tail, tail: head)

    @setBufferRange @getBufferRange(),
      autoscroll: true
      reversed: isReversed
      keepGoalColumn: false

  getRows: ->
    [startRow, endRow] = @selection.getBufferRowRange()
    [startRow..endRow]

  getRowCount: ->
    @getRows().length

  getTailBufferRange: ->
    {editor} = @selection
    tailPoint = @selection.getTailBufferPosition()
    if @selection.isReversed()
      point = translatePointAndClip(editor, tailPoint, 'backward')
      new Range(point, tailPoint)
    else
      point = translatePointAndClip(editor, tailPoint, 'forward')
      new Range(tailPoint, point)

  saveProperties: (isNormalized) ->
    head = @selection.getHeadBufferPosition()
    tail = @selection.getTailBufferPosition()
    if @selection.isEmpty() or isNormalized
      properties = {head, tail}
    else
      # We selectRight-ed in visual-mode, this translation de-effect select-right-effect
      # So that we can activate-visual-mode without special translation after restoreing properties.
      end = translatePointAndClip(@selection.editor, @getBufferRange().end, 'backward')
      if @selection.isReversed()
        properties = {head: head, tail: end}
      else
        properties = {head: end, tail: tail}
    @setProperties(properties)

  fixPropertyRowToRowRange: ->
    {head, tail} = @getProperties()
    if @selection.isReversed()
      [head.row, tail.row] = @selection.getBufferRowRange()
    else
      [tail.row, head.row] = @selection.getBufferRowRange()

  # NOTE:
  # 'wise' must be 'characterwise' or 'linewise'
  # Use this for normalized(non-select-right-ed) selection.
  applyWise: (wise) ->
    switch wise
      when 'characterwise'
        @translateSelectionEndAndClip('forward') # equivalent to core selection.selectRight but keep goalColumn
      when 'linewise'
        # Even if end.column is 0, expand over that end.row( don't use selection.getRowRange() )
        {start, end} = @getBufferRange()
        endRow = getFoldEndRowForRow(@selection.editor, end.row) # cover folded rowRange
        @setBufferRange(getBufferRangeForRowRange(@selection.editor, [start.row, endRow]))
      when 'blockwise'
        new BlockwiseSelection(@selection)

  selectByProperties: ({head, tail}) ->
    # No problem if head is greater than tail, Range constructor swap start/end.
    @setBufferRange [tail, head],
      autoscroll: true
      reversed: head.isLessThan(tail)
      keepGoalColumn: false

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
  translateSelectionEndAndClip: (direction) ->
    newRange = getRangeByTranslatePointAndClip(@selection.editor, @getBufferRange(), "end", direction)
    @setBufferRange(newRange)

  # Return selection extent to replay blockwise selection on `.` repeating.
  getBlockwiseSelectionExtent: ->
    head = @selection.getHeadBufferPosition()
    tail = @selection.getTailBufferPosition()
    new Point(head.row - tail.row, head.column - tail.column)

  # What's the normalize?
  # Normalization is restore selection range from property.
  # As a result it range became range where end of selection moved to left.
  # This end-move-to-left de-efect of end-mode-to-right effect( this is visual-mode orientation )
  normalize: ->
    # empty selection IS already 'normalized'
    return if @selection.isEmpty()
    unless @hasProperties()
      if settings.get('strictAssertion')
        assertWithException(false, "attempted to normalize but no properties to restore")
      @saveProperties()
    {head, tail} = @getProperties()
    @setBufferRange([tail, head])

swrap = (selection) ->
  new SelectionWrapper(selection)

# BlockwiseSelection proxy
swrap.getBlockwiseSelections = (editor) ->
  BlockwiseSelection.getSelections(editor)

swrap.getLastBlockwiseSelections = (editor) ->
  BlockwiseSelection.getLastSelection(editor)

swrap.getBlockwiseSelectionsOrderedByBufferPosition = (editor) ->
  BlockwiseSelection.getSelectionsOrderedByBufferPosition(editor)

swrap.clearBlockwiseSelections = (editor) ->
  BlockwiseSelection.clearSelections(editor)

swrap.getSelections = (editor) ->
  editor.getSelections(editor).map(swrap)

swrap.setReversedState = (editor, reversed) ->
  $selection.setReversedState(reversed) for $selection in @getSelections(editor)

swrap.detectWise = (editor) ->
  if @getSelections(editor).every(($selection) -> $selection.detectWise() is 'linewise')
    'linewise'
  else
    'characterwise'

swrap.clearProperties = (editor) ->
  $selection.clearProperties() for $selection in @getSelections(editor)

swrap.dumpProperties = (editor) ->
  {inspect} = require 'util'
  for $selection in @getSelections(editor) when $selection.hasProperties()
    console.log inspect($selection.getProperties())

swrap.normalize = (editor) ->
  if BlockwiseSelection.has(editor)
    for blockwiseSelection in BlockwiseSelection.getSelections(editor)
      blockwiseSelection.normalize()
    BlockwiseSelection.clearSelections(editor)
  else
    for $selection in @getSelections(editor)
      $selection.normalize()

swrap.hasProperties = (editor) ->
  @getSelections(editor).every ($selection) -> $selection.hasProperties()

# Return function to restore
# Used in vmp-move-selected-text
swrap.switchToLinewise = (editor) ->
  for $selection in swrap.getSelections(editor)
    $selection.saveProperties()
    $selection.applyWise('linewise')
  new Disposable ->
    for $selection in swrap.getSelections(editor)
      $selection.normalize()
      $selection.applyWise('characterwise')

swrap.getPropertyStore = ->
  propertyStore

module.exports = swrap
