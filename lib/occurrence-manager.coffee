_ = require 'underscore-plus'
{Emitter, CompositeDisposable} = require 'atom'

{
  shrinkRangeEndToBeforeNewLine
  collectRangeInBufferRow
} = require './utils'

isInvalidMarker = (marker) -> not marker.isValid()

module.exports =
class OccurrenceManager
  patterns: null
  markerOptions: {invalidate: 'inside'}

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    @disposables = new CompositeDisposable
    @disposables.add @vimState.onDidDestroy(@destroy.bind(this))
    @emitter = new Emitter
    @patterns = []

    @markerLayer = @editor.addMarkerLayer()
    decorationOptions = {type: 'highlight', class: "vim-mode-plus-occurrence-base"}
    @decorationLayer = @editor.decorateMarkerLayer(@markerLayer, decorationOptions)

    # @patterns is single source of truth (SSOT)
    # All maker create/destroy/css-update is done by reacting @patters's change.
    # -------------------------
    @onDidChangePatterns ({pattern, occurrenceType}) =>
      if pattern
        @markBufferRangeByPattern(pattern, occurrenceType)
        @updateEditorElement()
      else
        @clearMarkers()

    @markerLayer.onDidUpdate(@destroyInvalidMarkers.bind(this))

  markBufferRangeByPattern: (pattern, occurrenceType) ->
    if occurrenceType is 'subword'
      subwordRangesByRow = {} # cache
      subwordPattern = @editor.getLastCursor().subwordRegExp()
      isSubwordRange = (range) =>
        row = range.start.row
        subwordRanges = subwordRangesByRow[row] ?= collectRangeInBufferRow(@editor, row, subwordPattern)
        subwordRanges.some (subwordRange) -> subwordRange.isEqual(range)

    @editor.scan pattern, ({range, matchText}) =>
      if occurrenceType is 'subword'
        return unless isSubwordRange(range)
      @markerLayer.markBufferRange(range, @markerOptions)

  updateEditorElement: ->
    @editorElement.classList.toggle("has-occurrence", @hasMarkers())

  # Callback get passed following object
  # - pattern: can be undefined on reset event
  onDidChangePatterns: (fn) ->
    @emitter.on('did-change-patterns', fn)

  destroy: ->
    @decorationLayer.destroy()
    @disposables.dispose()
    @markerLayer.destroy()

  # Patterns
  hasPatterns: ->
    @patterns.length > 0

  resetPatterns: ->
    @patterns = []
    @emitter.emit('did-change-patterns', {})

  addPattern: (pattern=null, {reset, occurrenceType}={}) ->
    @clearMarkers() if reset
    @patterns.push(pattern)
    occurrenceType ?= 'base'
    @emitter.emit('did-change-patterns', {pattern, occurrenceType})

  saveLastPattern: (occurrenceType=null) ->
    @vimState.globalState.set("lastOccurrencePattern", @buildPattern())
    @vimState.globalState.set("lastOccurrenceType", occurrenceType)

  # Return regex representing final pattern.
  # Used to cache final pattern to each instance of operator so that we can
  # repeat recorded operation by `.`.
  # Pattern can be added interactively one by one, but we save it as union pattern.
  buildPattern: ->
    source = @patterns.map((pattern) -> pattern.source).join('|')
    new RegExp(source, 'g')

  # Markers
  # -------------------------
  clearMarkers: ->
    @markerLayer.clear()
    @updateEditorElement()

  destroyMarkers: (markers) ->
    marker.destroy() for marker in markers
    # whenerver we destroy marker, we should sync `has-occurrence` scope in marker state..
    @updateEditorElement()

  destroyInvalidMarkers: ->
    @destroyMarkers(@getMarkers().filter(isInvalidMarker))

  hasMarkers: ->
    @markerLayer.getMarkerCount() > 0

  getMarkers: ->
    @markerLayer.getMarkers()

  getMarkerBufferRanges: ->
    @markerLayer.getMarkers().map (marker) -> marker.getBufferRange()

  getMarkerCount: ->
    @markerLayer.getMarkerCount()

  # Return occurrence markers intersecting given ranges
  getMarkersIntersectsWithRanges: (ranges, exclusive=false) ->
    # findmarkers()'s intersectsBufferRange param have no exclusive control
    # So I need extra check to filter out unwanted marker.
    # But basically I should prefer findMarker since It's fast than iterating
    # whole markers manually.
    results = []
    for range in ranges.map(shrinkRangeEndToBeforeNewLine)
      markers = @markerLayer.findMarkers(intersectsBufferRange: range).filter (marker) ->
        range.intersectsWith(marker.getBufferRange(), exclusive)
      results.push(markers...)
    results

  getMarkerAtPoint: (point) ->
    @markerLayer.findMarkers(containsBufferPosition: point)[0]

  # Select occurrence marker bufferRange intersecting current selections.
  # - Return: true/false to indicate success or fail
  #
  # Do special handling for which occurrence range become lastSelection
  # e.g.
  #  - c(change): So that autocomplete+popup shows at original cursor position or near.
  #  - g U(upper-case): So that undo/redo can respect last cursor position.
  select: ->
    isVisualMode = @vimState.mode is 'visual'
    markers = @getMarkersIntersectsWithRanges(@editor.getSelectedBufferRanges(), isVisualMode)

    if markers.length
      # NOTE: immediately destroy occurrence-marker which we are operates on from now.
      # Markers are not beeing immediately destroyed unless explictly destroy.
      # Manually destroying markers here gives us several benefits like bellow.
      #  - Easy to write spec since markers are destroyed in-sync.
      #  - SelectOccurrence operation not invalidate marker but destroyed once selected.
      ranges = markers.map (marker) -> marker.getBufferRange()
      @destroyMarkers(markers)

      if isVisualMode
        @vimState.modeManager.deactivate()
        # So that SelectOccurrence can acivivate visual-mode with correct range, we have to unset submode here.
        @vimState.submode = null

      # Important: To make last-cursor become original cursor position.
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
