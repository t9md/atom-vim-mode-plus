# keep mutation snapshot necessary for Operator processing.

# mutation stored by each Selection have following field
#  marker:
#    marker to track mutation. marker is created when `setCheckPoint` and selection is NOT empty.
#    In other words, this mutationTracker nothing to do for empty selection.
#  createdAt:
#    'string' representing when marker was created.
#  checkPoint: {}
#    key is checkpoint, value is bufferRange for marker at that checkpoint
module.exports =
class MutationTracker
  editor: null
  mutationsBySelection: null

  constructor: (@vimState) ->
    {@editor, @markerLayer} = @vimState
    @mutationsBySelection = new Map

  # mutation information is created even if selection.isEmpty()
  # So we can filter selection by when it was created.
  # e.g. some selection is created at 'will-select' checkpoint, others at 'did-select'
  # This is important since when occurrence modifier is used, selection is created at target.select()
  # In that case some selection have createdAt = `did-select`, and others is createdAt = `will-select`
  createMutation: (selection, checkPoint) ->
    mutation =
      createdAt: checkPoint
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
    @mutationsBySelection.forEach (mutation) ->
      mutation.marker?.destroy()
    @mutationsBySelection.clear()
    [@mutationsBySelection, @editor] = []
    @destroyed = true
