_ = require 'underscore-plus'
{isNotEmpty} = require './utils'

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
