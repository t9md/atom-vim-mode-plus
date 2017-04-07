_ = require 'underscore-plus'
{isNotEmpty, replaceDecorationClassBy} = require './utils'

flashTypes =
  operator:
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash operator'
  'operator-long':
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash operator-long'
  'operator-occurrence':
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash operator-occurrence'
  'operator-remove-occurrence':
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash operator-remove-occurrence'
  search:
    allowMultiple: false
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash search'
  screen:
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash screen'
  'undo-redo':
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash undo-redo'
  'undo-redo-multiple-changes':
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash undo-redo-multiple-changes'
  'undo-redo-multiple-delete':
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash undo-redo-multiple-delete'

addDemoSuffix = replaceDecorationClassBy.bind(null, (text) -> text + '-demo')
removeDemoSuffix = replaceDecorationClassBy.bind(null, (text) -> text.replace(/-demo$/, ''))

module.exports =
class FlashManager
  constructor: (@vimState) ->
    {@editor} = @vimState
    @markersByType = new Map
    @vimState.onDidDestroy(@destroy.bind(this))
    @postponedDestroyMarkersTasks = []

  destroy: ->
    @markersByType.forEach (markers) ->
      marker.destroy() for marker in markers
    @markersByType.clear()

  destroyDemoModeMarkers: ->
    for resolve in @postponedDestroyMarkersTasks
      resolve()
    @postponedDestroyMarkersTasks = []

  destroyMarkersAfter: (markers, timeout) ->
    setTimeout ->
      for marker in markers
        marker.destroy()
    , timeout

  flash: (ranges, options, rangeType='buffer') ->
    ranges = [ranges] unless _.isArray(ranges)
    ranges = ranges.filter(isNotEmpty)
    return null unless ranges.length

    {type, timeout} = options
    timeout ?= 1000

    {allowMultiple, decorationOptions} = flashTypes[type]
    markerOptions = {invalidate: 'touch'}

    switch rangeType
      when 'buffer'
        markers = (@editor.markBufferRange(range, markerOptions) for range in ranges)
      when 'screen'
        markers = (@editor.markScreenRange(range, markerOptions) for range in ranges)

    unless allowMultiple
      if @markersByType.has(type)
        marker.destroy() for marker in @markersByType.get(type)
      @markersByType.set(type, markers)

    decorations = markers.map (marker) => @editor.decorateMarker(marker, decorationOptions)

    if @vimState.globalState.get('demoModeIsActive')
      decorations.map(addDemoSuffix)
      @postponedDestroyMarkersTasks.push =>
        decorations.map(removeDemoSuffix)
        @destroyMarkersAfter(markers, timeout)
    else
      @destroyMarkersAfter(markers, timeout)

  flashScreenRange: (args...) ->
    @flash(args.concat('screen')...)
