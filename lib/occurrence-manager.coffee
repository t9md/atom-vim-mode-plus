{
  scanInRanges
  getWordPatternAtCursor
  highlightRanges
  getVisibleBufferRange
} = require './utils'

module.exports =
class OccurrenceManager
  patterns: []
  markers: []

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState

  # Main
  reset: ({clearMarkers, clearPatterns}={}) ->
    @editorElement.classList.remove("occurrence-preset")
    if clearPatterns ? true
      @resetPatterns()
    if clearMarkers ? true
      @clearMarkers()

  highlight: (pattern=null) ->
    @clearMarkers()
    pattern ?= getWordPatternAtCursor(@editor.getLastCursor(), singleNonWordChar: true)
    ranges = scanInRanges(@editor, pattern, [getVisibleBufferRange(@editor)])
    @markers = highlightRanges(@editor, ranges, class: 'vim-mode-plus-occurrence-match')

  # Patterns
  hasPatterns: -> @patterns.length > 0
  getPatterns: -> @patterns
  resetPatterns: -> @patterns = []

  buildPattern: ->
    source = @pattern.map((pattern) -> pattern.source).join('|')
    new RegExp(source, 'g')

  savePattern: (pattern) ->
    @patterns.push(pattern)

    @editorElement.classList.add("occurrence-preset")
    @highlight(@buildPattern())

  removePattern: (removePattern) ->
    @patterns = @patterns.filter (pattern) -> pattern.source isnt removePattern.source

  # Markers
  # -------------------------
  hasMarkers: ->
    @markers.length > 0

  # Return occurrence markers intersecting given ranges
  getMarkersIntersectsWithRanges: (ranges, exclusive=false) ->
    # exclusive set true in visual-mode??? check utils, scanInRanges
    @markers.filter (marker) ->
      ranges.some (range) ->
        range.intersectsWith(marker.getBufferRange(), exclusive)

  getMarkerAtPoint: (point) ->
    exclusive = false
    for marker in @markers
      if marker.getBufferRange().containsPoint(point, exclusive)
        return marker

  removeMarker: (marker) ->
    marker.destroy()
    _.remove(@markers, marker)

  clearMarkers: ->
    marker.destroy() for marker in @markers
    @markers = []
