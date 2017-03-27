{Point, CompositeDisposable} = require 'atom'
{getFirstCharacterPositionForBufferRow, getValidVimBufferRow} = require './utils'
swrap = require './selection-wrapper'

# keep mutation snapshot necessary for Operator processing.
# mutation stored by each Selection have following field
#  marker:
#    marker to track mutation. marker is created when `setCheckpoint`
#  createdAt:
#    'string' representing when marker was created.
#  checkpoint: {}
#    key is ['will-select', 'did-select', 'will-mutate', 'did-mutate']
#    key is checkpoint, value is bufferRange for marker at that checkpoint
#  selection:
#    Selection beeing tracked
module.exports =
class MutationManager
  constructor: (@vimState) ->
    {@editor} = @vimState

    @disposables = new CompositeDisposable
    @disposables.add @vimState.onDidDestroy(@destroy.bind(this))

    @markerLayer = @editor.addMarkerLayer()
    @mutationsBySelection = new Map

  destroy: ->
    @reset()
    {@mutationsBySelection, @editor, @vimState} = {}

  init: ({@stayByMarker}) ->
    @reset()

  reset: ->
    @markerLayer.clear()
    @mutationsBySelection.clear()

  setCheckpoint: (checkpoint) ->
    for selection in @editor.getSelections()
      @setCheckpointForSelection(selection, checkpoint)

  setCheckpointForSelection: (selection, checkpoint) ->
    if @mutationsBySelection.has(selection)
      @mutationsBySelection.get(selection).update(checkpoint)
    else
      initialPoint = swrap(selection).getBufferPositionFor('head', from: ['property', 'selection'])
      options = {selection, initialPoint, checkpoint, @markerLayer, @stayByMarker, @vimState}
      @mutationsBySelection.set(selection, new Mutation(options))

  getMutatedBufferRange: (selection) ->
    if marker = @getMutationForSelection(selection)?.marker
      marker.getBufferRange()

  getMutationForSelection: (selection) ->
    @mutationsBySelection.get(selection)

  getBufferRangesForCheckpoint: (checkpoint) ->
    ranges = []
    @mutationsBySelection.forEach (mutation) ->
      if range = mutation.getBufferRangeForCheckpoint(checkpoint)
        ranges.push(range)
    ranges

  restoreCursorPositions: (options) ->
    {stay, wise, occurrenceSelected, setToFirstCharacterOnLinewise} = options
    if wise is 'blockwise'
      for blockwiseSelection in @vimState.getBlockwiseSelections()
        {head, tail} = blockwiseSelection.getProperties()
        point = if stay then head else Point.min(head, tail)
        blockwiseSelection.setHeadBufferPosition(point)
        blockwiseSelection.skipNormalization()
    else
      for selection in @editor.getSelections() when mutation = @mutationsBySelection.get(selection)
        if occurrenceSelected and not mutation.isCreatedAt('will-select')
          selection.destroy()

        if occurrenceSelected and stay
          # This is essencially to clipToMutationEnd when `d o f`, `d o p` case.
          point = @clipToMutationEndIfSomeMutationContainsPoint(@vimState.getOriginalCursorPosition())
          selection.cursor.setBufferPosition(point)
        else if point = mutation.getRestorePoint({stay, wise})
          if (not stay) and setToFirstCharacterOnLinewise and (wise is 'linewise')
            point = getFirstCharacterPositionForBufferRow(@editor, point.row)
          selection.cursor.setBufferPosition(point)

  clipToMutationEndIfSomeMutationContainsPoint: (point) ->
    if mutation = @findMutationContainsPointAtCheckpoint(point, 'did-select-occurrence')
      Point.min(mutation.getEndBufferPosition(), point)
    else
      point

  findMutationContainsPointAtCheckpoint: (point, checkpoint) ->
    # Coffeescript cannot iterate over iterator by JavaScript's 'of' because of syntax conflicts.
    iterator = @mutationsBySelection.values()
    while (entry = iterator.next()) and not entry.done
      mutation = entry.value
      if mutation.getBufferRangeForCheckpoint(checkpoint).containsPoint(point)
        return mutation

# Mutation information is created even if selection.isEmpty()
# So that we can filter selection by when it was created.
#  e.g. Some selection is created at 'will-select' checkpoint, others at 'did-select' or 'did-select-occurrence'
class Mutation
  constructor: (options) ->
    {@selection, @initialPoint, checkpoint, @markerLayer, @stayByMarker, @vimState} = options

    @createdAt = checkpoint
    if @stayByMarker
      @initialPointMarker = @markerLayer.markBufferPosition(@initialPoint, invalidate: 'never')
    @bufferRangeByCheckpoint = {}
    @marker = null
    @update(checkpoint)

  isCreatedAt: (timing) ->
    @createdAt is timing

  update: (checkpoint) ->
    # Current non-empty selection is prioritized over existing marker's range.
    # We invalidate old marker to re-track from current selection.
    unless @selection.getBufferRange().isEmpty()
      @marker?.destroy()
      @marker = null

    @marker ?= @markerLayer.markBufferRange(@selection.getBufferRange(), invalidate: 'never')
    @bufferRangeByCheckpoint[checkpoint] = @marker.getBufferRange()

  getStartBufferPosition: ->
    @marker.getBufferRange().start

  getEndBufferPosition: ->
    {start, end} = @marker.getBufferRange()
    point = Point.max(start, end.translate([0, -1]))
    @selection.editor.clipBufferPosition(point)

  getInitialPoint: ({clip, wise}={}) ->
    point = @initialPointMarker?.getHeadBufferPosition() ? @initialPoint
    clip ?= not @getBufferRangeForCheckpoint('did-select')?.isEqual(@marker.getBufferRange())
    if clip
      if wise is 'linewise'
        Point.min([@getEndBufferPosition().row, point.column], point)
      else
        Point.min(@getEndBufferPosition(), point)
    else
      point

  getBufferRangeForCheckpoint: (checkpoint) ->
    @bufferRangeByCheckpoint[checkpoint]

  getRestorePoint: ({stay, wise}={}) ->
    if stay
      point = @getInitialPoint({wise})
    else
      {mode, submode} = @vimState
      if (mode isnt 'visual') or (submode is 'linewise' and @selection.isReversed())
        point = swrap(@selection).getBufferPositionFor('start', from: ['property'])
      point = point ? @bufferRangeByCheckpoint['did-select']?.start

    if point?
      point.row = getValidVimBufferRow(@selection.editor, point.row)
    point
