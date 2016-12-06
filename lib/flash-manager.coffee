_ = require 'underscore-plus'
{isNotEmpty} = require './utils'

flashTypes =
  "operator-add":
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash operator-add'
  "operator-remove":
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash operator-remove'
  "operator-nomutate":
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash operator-nomutate'
  'operator-add-long':
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash operator-add-long'
  'operator-remove-long':
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash operator-remove-long'
  'operator-nomutate-long':
    allowMultiple: true
    decorationOptions:
      type: 'highlight'
      class: 'vim-mode-plus-flash operator-nomutate-long'
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

    @editor.decorateMarker(marker, decorationOptions) for marker in markers

    setTimeout ->
      for marker in markers
        marker.destroy()
    , timeout

  flashScreenRange: (args...) ->
    @flash(args.concat('screen')...)
