_ = require 'underscore-plus'
{Emitter, CompositeDisposable} = require 'atom'

{
  scanEditor
  shrinkRangeEndToBeforeNewLine
  getWordBufferRangeAndKindAtBufferPosition
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
      @editorElement.classList.toggle("occurrence-preset", @hasMarkers())

  # Callback get passed following object
  # - newPattern: can be undefined on reset event
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

  addPatternForWordAtPoint: (point) ->
    pattern = @getWordPatternAtBufferPosition(point, singleNonWordChar: true)
    @addPattern(pattern)

  addPattern: (pattern=null) ->
    unless pattern
      point = @editor.getCursorBufferPosition()
      pattern = @getWordPatternAtBufferPosition(point)
    @patterns.push(pattern)
    @emitter.emit('did-change-patterns', {newPattern: pattern})

  # Return regex representing final pattern.
  # Used to cache final pattern to each instance of operator so that we can
  # repeat recorded operation by `.`.
  # Pattern can be added interactively one by one, but we save it as union pattern.
  buildPattern: ->
    source = @patterns.map((pattern) -> pattern.source).join('|')
    new RegExp(source, 'g')

  getWordPatternAtBufferPosition: (point, options={}) ->
    {range, kind} = getWordBufferRangeAndKindAtBufferPosition(@editor, point, options)
    pattern = _.escapeRegExp(@editor.getTextInBufferRange(range))
    if kind is 'word'
      pattern = "\\b" + pattern + "\\b"
    new RegExp(pattern, 'g')

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
    ranges = ranges.map (range) -> shrinkRangeEndToBeforeNewLine(range)

    results = []
    for range in ranges
      markers = @markerLayer.findMarkers(intersectsBufferRange: range).filter (marker) ->
        range.intersectsWith(marker.getBufferRange(), exclusive)
      results.push(markers...)
    results

  getMarkerAtPoint: (point) ->
    @markerLayer.findMarkers(containsBufferPosition: point)[0]
