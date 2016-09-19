{Point} = require 'atom'
_ = require 'underscore-plus'

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
module.exports =
class MutationTracker
  editor: null
  mutationsBySelection: null

  constructor: (@vimState, options={}) ->
    {@editor, @markerLayer} = @vimState
    {@stay, @useMarker, @isSelect} = options
    @mutationsBySelection = new Map

  getInitialPointForSelection: (selection) ->
    options = {@useMarker}
    if @vimState.isMode('visual')
      _.extend(options, {fromProperty: true, allowFallback: true})
      swrap(selection).getBufferPositionFor('head', options)
    else
      swrap(selection).getBufferPositionFor('head', options) unless @isSelect

  # mutation information is created even if selection.isEmpty()
  # So we can filter selection by when it was created.
  # e.g. some selection is created at 'will-select' checkpoint, others at 'did-select'
  # This is important since when occurrence modifier is used, selection is created at target.select()
  # In that case some selection have createdAt = `did-select`, and others is createdAt = `will-select`
  createMutation: (selection, checkPoint) ->
    mutation =
      createdAt: checkPoint
      checkPoint: {}
      point: @getInitialPointForSelection(selection) if @stay
    @mutationsBySelection.set(selection, mutation)

  setCheckPoint: (checkPoint) ->
    for selection in @editor.getSelections()
      unless @mutationsBySelection.has(selection)
        @createMutation(selection, checkPoint)

      mutation = @mutationsBySelection.get(selection)
      unless selection.isEmpty()
        mutation.marker ?= @markerLayer.markBufferRange(selection.getBufferRange(), invalidate: 'never')
        range = mutation.marker.getBufferRange()
        mutation.checkPoint[checkPoint] = range
        mutation.point ?= range.start

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

  getMutationEndForMutation: (mutation) ->
    range = mutation.marker.getBufferRange()
    if range.isEmpty()
      range.end
    else
      range.end.translate([0, -1])

  restoreCursorPositions: ({strict}) ->
    for selection in @editor.getSelections() when mutation = @getMutationForSelection(selection)
      if strict and mutation.createdAt is 'did-select'
        selection.destroy()
        continue

      if point = mutation.point
        if @stay
          point = Point.min(@getMutationEndForMutation(mutation), point)
        selection.cursor.setBufferPosition(point)
        # else
        #   if range = mutation.checkPoint['did-select']
        #     selection.cursor.setBufferPosition(range.start)
