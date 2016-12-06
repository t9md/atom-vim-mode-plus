{Point, CompositeDisposable} = require 'atom'
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

  init: (@options) ->
    @reset()

  reset: ->
    @clearMarkers()
    @mutationsBySelection.clear()

  clearMarkers: (pattern) ->
    for marker in @markerLayer.getMarkers()
      marker.destroy()

  getInitialPointForSelection: (selection, options) ->
    @getMutationForSelection(selection)?.getInitialPoint(options)

  setCheckpoint: (checkpoint) ->
    for selection in @editor.getSelections()
      if @mutationsBySelection.has(selection)
        @mutationsBySelection.get(selection).update(checkpoint)

      else
        initialPoint =
          if @vimState.isMode('visual')
            swrap(selection).getBufferPositionFor('head', fromProperty: true, allowFallback: true)
          else
            # [FIXME] investigate WHY I did: initialPoint can be null when isSelect was true
            swrap(selection).getBufferPositionFor('head') unless @options.isSelect

        {useMarker} = @options
        options = {selection, initialPoint, checkpoint, @markerLayer, useMarker}
        @mutationsBySelection.set(selection, new Mutation(options))

  getMutationForSelection: (selection) ->
    @mutationsBySelection.get(selection)

  getMarkerBufferRanges: ->
    ranges = []
    @mutationsBySelection.forEach (mutation, selection) ->
      if range = mutation.marker?.getBufferRange()
        ranges.push(range)
    ranges

  getBufferRangesForCheckpoint: (checkpoint) ->
    ranges = []
    @mutationsBySelection.forEach (mutation) ->
      if range = mutation.getBufferRangeForCheckpoint(checkpoint)
        ranges.push(range)
    ranges

  restoreInitialPositions: ->
    for selection in @editor.getSelections() when point = @getInitialPointForSelection(selection)
      selection.cursor.setBufferPosition(point)

  restoreCursorPositions: (options) ->
    {stay, isOccurrence, isBlockwise} = options
    if isBlockwise
      # [FIXME] why I need this direct manupilation?
      # Because there's bug that blockwise selecction is not addes to each
      # bsInstance.selection. Need investigation.
      points = []
      @mutationsBySelection.forEach (mutation, selection) ->
        points.push(mutation.bufferRangeByCheckpoint['will-select']?.start)
      points = points.sort (a, b) -> a.compare(b)
      points = points.filter (point) -> point?
      if @vimState.isMode('visual', 'blockwise')
        if point = points[0]
          @vimState.getLastBlockwiseSelection()?.setHeadBufferPosition(point)
      else
        if point = points[0]
          @editor.setCursorBufferPosition(point)
        else
          for selection in @editor.getSelections()
            selection.destroy() unless selection.isLastSelection()
    else
      for selection, i in @editor.getSelections()
        if mutation = @mutationsBySelection.get(selection)
          if isOccurrence and mutation.createdAt isnt 'will-select'
            selection.destroy()
            continue

          if isOccurrence and stay
            point = @vimState.getOriginalCursorPosition()
            selection.cursor.setBufferPosition(point)
          else if point = mutation.getRestorePoint({stay})
            selection.cursor.setBufferPosition(point)
        else
          if isOccurrence
            selection.destroy()

# Mutation information is created even if selection.isEmpty()
# So that we can filter selection by when it was created.
#  e.g. Some selection is created at 'will-select' checkpoint, others at 'did-select' or 'did-select-occurrence'
class Mutation
  constructor: (options) ->
    {@selection, @initialPoint, checkpoint, @markerLayer, @useMarker} = options

    @createdAt = checkpoint
    if @useMarker
      @initialPointMarker = @markerLayer.markBufferPosition(@initialPoint, invalidate: 'never')
    @bufferRangeByCheckpoint = {}
    @marker = null
    @update(checkpoint)

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

  getInitialPoint: ({clip}={}) ->
    point = @initialPointMarker?.getHeadBufferPosition() ? @initialPoint
    if clip
      Point.min(@getEndBufferPosition(), point)
    else
      point

  getBufferRangeForCheckpoint: (checkpoint) ->
    @bufferRangeByCheckpoint[checkpoint]

  getRestorePoint: ({stay}={}) ->
    if stay
      @getInitialPoint(clip: true)
    else
      @bufferRangeByCheckpoint['did-move']?.start ? @bufferRangeByCheckpoint['did-select']?.start
