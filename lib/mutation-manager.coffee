{Point} = require 'atom'

module.exports =
class MutationManager
  constructor: (@vimState) ->
    {@editor, @swrap} = @vimState
    @vimState.onDidDestroy(@destroy)

    @markerLayer = @editor.addMarkerLayer()
    @mutationsBySelection = new Map

  destroy: =>
    @markerLayer.destroy()
    @mutationsBySelection.clear()

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
      # Current non-empty selection is prioritized over existing marker's range.
      # We invalidate old marker to re-track from current selection.
      resetMarker = not selection.getBufferRange().isEmpty()
    else
      resetMarker = true
      initialPoint = @swrap(selection).getBufferPositionFor('head', from: ['property', 'selection'])
      if @stayByMarker
        initialPointMarker = @markerLayer.markBufferPosition(initialPoint, invalidate: 'never')

      options = {selection, initialPoint, initialPointMarker, checkpoint, @swrap}
      @mutationsBySelection.set(selection, new Mutation(options))

    if resetMarker
      marker = @markerLayer.markBufferRange(selection.getBufferRange(), invalidate: 'never')
    @mutationsBySelection.get(selection).update(checkpoint, marker, @vimState.mode)

  migrateMutation: (oldSelection, newSelection) ->
    mutation = @mutationsBySelection.get(oldSelection)
    @mutationsBySelection.delete(oldSelection)
    mutation.selection = newSelection
    @mutationsBySelection.set(newSelection, mutation)

  getMutatedBufferRangeForSelection: (selection) ->
    if @mutationsBySelection.has(selection)
      @mutationsBySelection.get(selection).marker.getBufferRange()

  getSelectedBufferRangesForCheckpoint: (checkpoint) ->
    ranges = []
    @mutationsBySelection.forEach (mutation) ->
      if range = mutation.bufferRangeByCheckpoint[checkpoint]
        ranges.push(range)
    ranges

  restoreCursorPositions: ({stay, wise, setToFirstCharacterOnLinewise}) ->
    if wise is 'blockwise'
      for blockwiseSelection in @vimState.getBlockwiseSelections()
        {head, tail} = blockwiseSelection.getProperties()
        point = if stay then head else Point.min(head, tail)
        blockwiseSelection.setHeadBufferPosition(point)
        blockwiseSelection.skipNormalization()
    else
      # Make sure destroying all temporal selection BEFORE starting to set cursors to final position.
      # This is important to avoid destroy order dependent bugs.
      for selection in @editor.getSelections() when mutation = @mutationsBySelection.get(selection)
        if mutation.createdAt isnt 'will-select'
          selection.destroy()

      for selection in @editor.getSelections() when mutation = @mutationsBySelection.get(selection)
        if stay
          point = @clipPoint(mutation.getStayPosition(wise))
        else
          point = @clipPoint(mutation.startPositionOnDidSelect)
          if setToFirstCharacterOnLinewise and wise is 'linewise'
            point = @vimState.utils.getFirstCharacterPositionForBufferRow(@editor, point.row)
        selection.cursor.setBufferPosition(point)

  clipPoint: (point) ->
    point.row = Math.min(@vimState.utils.getVimLastBufferRow(@editor), point.row)
    @editor.clipBufferPosition(point)

# Mutation information is created even if selection.isEmpty()
# So that we can filter selection by when it was created.
#  e.g. Some selection is created at 'will-select' checkpoint, others at 'did-select' or 'did-select-occurrence'
class Mutation
  constructor: (options) ->
    {@selection, @initialPoint, @initialPointMarker, checkpoint, @swrap} = options
    @createdAt = checkpoint
    @bufferRangeByCheckpoint = {}
    @marker = null
    @startPositionOnDidSelect = null

  update: (checkpoint, marker, mode) ->
    if marker?
      @marker?.destroy()
      @marker = marker
    @bufferRangeByCheckpoint[checkpoint] = @marker.getBufferRange()
    # NOTE: stupidly respect pure-Vim's behavior which is inconsistent.
    # Maybe I'll remove this blindly-following-to-pure-Vim code.
    #  - `V k y`: don't move cursor
    #  - `V j y`: move curor to start of selected line.(Inconsistent!)
    if checkpoint is 'did-select'
      if (mode is 'visual' and not @selection.isReversed())
        from = ['selection']
      else
        from = ['property', 'selection']
      @startPositionOnDidSelect = @swrap(@selection).getBufferPositionFor('start', {from})

  getStayPosition: (wise) ->
    point = @initialPointMarker?.getHeadBufferPosition() ? @initialPoint
    selectedRange = @bufferRangeByCheckpoint['did-select-occurrence'] ? @bufferRangeByCheckpoint['did-select']
    if selectedRange.isEqual(@marker.getBufferRange()) # Check if need Clip
      point
    else
      {start, end} = @marker.getBufferRange()
      end = Point.max(start, end.translate([0, -1]))
      if wise is 'linewise'
        point.row = Math.min(end.row, point.row)
        point
      else
        Point.min(end, point)
