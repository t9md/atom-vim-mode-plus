# Refactoring status: 100%
_ = require 'underscore-plus'

class FlashManager
  timeoutID: null
  markers: null

  constructor: (@vimState) ->
    {@editor} = @vimState

  markerOptions = {ivalidate: 'nerver', persistent: false}
  flash: (range, options) ->
    @reset()
    range = [range] unless _.isArray(range)
    return unless range.length
    @markers = (@editor.markBufferRange(r, markerOptions) for r in range)
    decorationOptions = {type: 'highlight', class: options.class}
    for m in @markers
      @editor.decorateMarker(m, decorationOptions)
    @timeoutID = setTimeout  =>
      @reset()
    , options.timeout

  reset: ->
    return unless @markers?
    m.destroy() for m in @markers
    clearTimeout @timeoutID
    {@markers, @timeoutID} = {}

  destroy: ->
    @reset()
    {@vimState, @editor} = {}

module.exports = FlashManager
