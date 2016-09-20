{Point} = require 'atom'
swrap = require './selection-wrapper'

# keep mutation snapshot necessary for Operator processing.

# mutation stored by each Selection have following field
#  marker:
#    marker to track mutation. marker is created when `setCheckPoint` and selection is NOT empty.
#    In other words, this mutationTracker nothing to do for empty selection.
#  createdAt:
#    'string' representing when marker was created.
#  checkPoint: {}
#    key is checkpoint, value is bufferRange for marker at that checkpoint
#  selection:
#    Selection beeing tracked
module.exports =
class MutationTracker
  editor: null
  mutationsBySelection: null
  pointsBySelection: null

  constructor: (@vimState, options={}) ->
    {@editor, @markerLayer} = @vimState
    {@stay, @useMarker, @isSelect} = options
    @mutationsBySelection = new Map
    @pointsBySelection = new Map

    if @stay
      for selection in @editor.getSelections()
        point = @getInitialPointForSelection(selection)
        if @useMarker
          point = @markerLayer.markBufferPosition(point, invalidate: 'never')
        @pointsBySelection.set(selection, point)

  getInitialPointForSelection: (selection) ->
    if @vimState.isMode('visual')
      swrap(selection).getBufferPositionFor('head', fromProperty: true, allowFallback: true)
    else
      swrap(selection).getBufferPositionFor('head') unless @isSelect

  # mutation information is created even if selection.isEmpty()
  # So we can filter selection by when it was created.
  # e.g. some selection is created at 'will-select' checkpoint, others at 'did-select'
  # This is important since when occurrence modifier is used, selection is created at target.select()
  # In that case some selection have createdAt = `did-select`, and others is createdAt = `will-select`
  createMutation: (selection, checkPoint) ->
    mutation =
      createdAt: checkPoint
      selection: selection
      checkPoint: {}
    @mutationsBySelection.set(selection, mutation)

  setCheckPoint: (checkPoint) ->
    for selection in @editor.getSelections()
      unless @mutationsBySelection.has(selection)
        @createMutation(selection, checkPoint)

      mutation = @mutationsBySelection.get(selection)
      unless selection.isEmpty()
        mutation.marker ?= @markerLayer.markBufferRange(selection.getBufferRange(), invalidate: 'never')
        mutation.checkPoint[checkPoint] = mutation.marker.getBufferRange()

  getMutationForSelection: (selection) ->
    @mutationsBySelection.get(selection)

  getMarkerBufferRanges: ->
    ranges = []
    @mutationsBySelection.forEach (mutation, selection) ->
      ranges.push(mutation.marker.getBufferRange())
    ranges

  destroy: ->
    return if @destroyed
    @mutationsBySelection.forEach (mutation) -> mutation.marker?.destroy()
    @mutationsBySelection.clear()
    @pointsBySelection.clear()

    {@mutationsBySelection, @pointsBySelection, @editor} = {}
    @destroyed = true

  getRestorePointForMutation: (mutation, {clipToMutationEnd}={}) ->
    if @stay
      if point = @pointsBySelection.get(mutation.selection)
        unless point instanceof Point
          point = point.getHeadBufferPosition()

        if clipToMutationEnd
          range = mutation.marker.getBufferRange()
          if range.isEmpty()
            mutationEnd = range.end
          else
            mutationEnd = range.end.translate([0, -1])
          Point.min(mutationEnd, point)
        else
          point
    else
      if range = mutation.checkPoint['did-select']
        range.start

  restoreCursorPositions: ({strict, clipToMutationEnd, isBlockwise}) ->
    if isBlockwise
      # [FIXME] why I need this direct manupilation?
      # Because there's bug that blockwise selecction is not addes to each
      # bsInstance.selection. Need investigation.
      points = []
      @mutationsBySelection.forEach (mutation, selection) ->
        points.push(mutation.checkPoint['will-select']?.start)
      points = points.sort (a, b) -> a.compare(b)
      points = points.filter (point) -> point?
      # console.log points
      if @vimState.isMode('visual', 'blockwise')
        if point = points[0]
          @vimState.getLastBlockwiseSelection().setHeadBufferPosition(point)
      else
        if point = points[0]
          @editor.setCursorBufferPosition(point)
        else
          for selection in @editor.getSelections()
            selection.destroy() unless selection.isLastSelection()
    else
      for selection in @editor.getSelections() when mutation = @getMutationForSelection(selection)
        if strict and mutation.createdAt is 'did-select'
          selection.destroy()
          continue

        if point = @getRestorePointForMutation(mutation, {clipToMutationEnd})
          selection.cursor.setBufferPosition(point)
