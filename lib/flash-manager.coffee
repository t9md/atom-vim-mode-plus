_ = require 'underscore-plus'

flashTypes =
  operator:
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash operator'
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
  added:
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash added'
  removed:
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash removed'
  'screen-line': # unused.
    allowMultiple: false
    decorationOptions:
      type: 'line'
      class: 'vim-mode-plus-flash-screen-line'

module.exports =
class FlashManager
  constructor: (@vimState) ->
    {@editor} = @vimState
    @markersByType = new Map
    @vimState.onDidDestroy(@destroy.bind(this))

  destroy: ->
    @markersByType.forEach (markers) ->
      marker.destroy() for marker in markers
    @markersByType.clear()

  flash: (ranges, options, rangeType='buffer') ->
    ranges = [ranges] unless _.isArray(ranges)
    return null unless ranges.length

    {type, timeout} = options
    timeout ?= 1000

    {allowMultiple, decorationOptions} = flashTypes[type]

    switch rangeType
      when 'buffer'
        markers = (@editor.markBufferRange(range) for range in ranges)
      when 'screen'
        markers = (@editor.markScreenRange(range) for range in ranges)

    unless allowMultiple
      if @markersByType.has(type)
        marker.destroy() for marker in @markersByType.get(type)
      @markersByType.set(type, markers)

    @editor.decorateMarker(marker, decorationOptions) for marker in markers

    setTimeout ->
      for marker in markers
        marker.destroy()
    , timeout

  flashScreenRange: (args...) ->
    @flash(args.concat('screen')...)
