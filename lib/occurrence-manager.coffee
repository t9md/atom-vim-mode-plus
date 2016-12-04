_ = require 'underscore-plus'
{Emitter, CompositeDisposable} = require 'atom'

{
  scanEditor
  shrinkRangeEndToBeforeNewLine
  findRangeContainsPoint
} = require './utils'

module.exports =
class OccurrenceManager
  patterns: null

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    @disposables = new CompositeDisposable
    @disposables.add @vimState.onDidDestroy(@destroy.bind(this))
    @emitter = new Emitter
    @patterns = []

    @markerLayer = @editor.addMarkerLayer()
    options = {type: 'highlight', class: 'vim-mode-plus-occurrence-match'}
    @decorationLayer = @editor.decorateMarkerLayer(@markerLayer, options)

    # @patterns is single source of truth (SSOT)
    # All maker create/destroy/css-update is done by reacting @patters's change.
    # -------------------------
    @onDidChangePatterns ({newPattern}) =>
      if newPattern
        @markerLayer.markBufferRange(range) for range in scanEditor(@editor, newPattern)
      else
        # When patterns were cleared, destroy all marker.
        marker.destroy() for marker in @markerLayer.getMarkers()

    # Update css on every marker update.
    @markerLayer.onDidUpdate =>
      @editorElement.classList.toggle("has-occurrence", @hasMarkers())

  # Callback get passed following object
  # - newPattern: can be undefined on reset event
  onDidChangePatterns: (fn) ->
    @emitter.on('did-change-patterns', fn)

  destroy: ->
    @decorationLayer.destroy()
    @disposables.dispose()
    @markerLayer.destroy()

  getMarkerRangesIntersectsWithRanges: (ranges, exclusive=false) ->
    @getMarkersIntersectsWithRanges(ranges, exclusive).map (marker) ->
      marker.getBufferRange()

  # Patterns
  hasPatterns: ->
    @patterns.length > 0

  resetPatterns: ->
    @patterns = []
    @emitter.emit('did-change-patterns', {})

  addPattern: (pattern=null) ->
    @patterns.push(pattern)
    @emitter.emit('did-change-patterns', {newPattern: pattern})

  # Return regex representing final pattern.
  # Used to cache final pattern to each instance of operator so that we can
  # repeat recorded operation by `.`.
  # Pattern can be added interactively one by one, but we save it as union pattern.
  buildPattern: ->
    source = @patterns.map((pattern) -> pattern.source).join('|')
    new RegExp(source, 'g')

  # Markers
  # -------------------------
  hasMarkers: ->
    @markerLayer.getMarkerCount() > 0

  getMarkers: ->
    @markerLayer.getMarkers()

  getMarkerCount: ->
    @markerLayer.getMarkerCount()

  # Return occurrence markers intersecting given ranges
  getMarkersIntersectsWithRanges: (ranges, exclusive=false) ->
    # findmarkers()'s intersectsBufferRange param have no exclusive control
    # So I need extra check to filter out unwanted marker.
    # But basically I should prefer findMarker since It's fast than iterating
    # whole markers manually.
    ranges = ranges.map (range) -> shrinkRangeEndToBeforeNewLine(range)

    results = []
    for range in ranges
      markers = @markerLayer.findMarkers(intersectsBufferRange: range).filter (marker) ->
        range.intersectsWith(marker.getBufferRange(), exclusive)
      results.push(markers...)
    results

  getMarkerAtPoint: (point) ->
    @markerLayer.findMarkers(containsBufferPosition: point)[0]

  # Select occurrence marker bufferRange intersecting current selections.
  # - Return: true/false to indicate success or fail
  #
  # When startInsertMode was true, do special handling for which occurrence range
  #  become lastSelection so that autocomplete+popup shows at original cursor position or near.
  select: ({startInsertMode}={}) ->
    isVisualMode = @vimState.mode is 'visual'
    markers = @getMarkersIntersectsWithRanges(@editor.getSelectedBufferRanges(), isVisualMode)
    ranges = markers.map (marker) -> marker.getBufferRange()
    @resetPatterns()

    if ranges.length
      if isVisualMode
        @vimState.modeManager.deactivate()
        # So that SelectOccurrence can acivivate visual-mode with correct range, we have to unset submode here.
        @vimState.submode = null

      if startInsertMode
        range = @getRangeForLastSelection(ranges)
        _.remove(ranges, range)
        ranges.push(range)

      @editor.setSelectedBufferRanges(ranges)

      true
    else
      false

  # Which occurrence become lastSelection is determined by following order
  #  1. Occurrence under original cursor position
  #  2. forwarding in same row
  #  3. first occurrence in same row
  #  4. forwarding (wrap-end)
  getRangeForLastSelection: (ranges) ->
    point = @vimState.getOriginalCursorPosition()

    for range in ranges when range.containsPoint(point)
      return range

    rangesStartFromSameRow = ranges.filter((range) -> range.start.row is point.row)

    if rangesStartFromSameRow.length
      for range in rangesStartFromSameRow when range.start.isGreaterThan(point)
        return range # Forwarding
      return rangesStartFromSameRow[0]

    for range in ranges when range.start.isGreaterThan(point)  # Forwarding
      return range

    ranges[0] # return first as fallback
