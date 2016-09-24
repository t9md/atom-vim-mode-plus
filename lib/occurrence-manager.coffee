{Emitter, CompositeDisposable} = require 'atom'

{getWordPatternAtCursor} = require './utils'

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

    @onDidResetPatterns(@clearMarkers.bind(this))
    @markerLayer.onDidUpdate(@updateView.bind(this))

  onDidResetPatterns: (fn) ->
    @emitter.on('did-reset-patterns', fn)

  # Main
  reset: ->
    @resetPatterns()

  updateView: ->
    @editorElement.classList.toggle("occurrence-preset", @hasMarkers())

  destroy: ->
    @decorationLayer.destroy()
    @disposables.dispose()
    @markerLayer.destroy()

  # Patterns
  hasPatterns: ->
    @patterns.length > 0

  resetPatterns: ->
    @patterns = []
    @emitter.emit('did-reset-patterns')

  buildPattern: ->
    source = @patterns.map((pattern) -> pattern.source).join('|')
    new RegExp(source, 'g')

  addMarker: (pattern=null) ->
    pattern ?= getWordPatternAtCursor(@editor.getLastCursor(), singleNonWordChar: true)
    @patterns.push(pattern)
    @addMarkersForPattern(pattern)

  addMarkersForPattern: (pattern) ->
    ranges = []
    @editor.scan pattern, ({range}) -> ranges.push(range)
    for range in ranges
      @markerLayer.markBufferRange(range, invalidate: 'never')

  # Markers
  # -------------------------
  hasMarkers: ->
    @markerLayer.getMarkerCount() > 0

  # Return occurrence markers intersecting given ranges
  getMarkersIntersectsWithRanges: (ranges, exclusive=false) ->
    # findmarkers()'s intersectsBufferRange param have no exclusive cotntroll
    # So I need extra check to filter out unwanted marker.
    # But basically I should prefer findMarker since It's fast than iterating
    # whole markers manually.
    results = []
    for range in ranges
      markers = @markerLayer.findMarkers(intersectsBufferRange: range).filter (marker) ->
        range.intersectsWith(marker.getBufferRange(), exclusive)
      results.push(markers...)
    results

  getMarkerAtPoint: (point) ->
    @markerLayer.findMarkers(containsBufferPosition: point)[0]

  clearMarkers: ->
    for marker in @markerLayer.getMarkers()
      marker.destroy()
