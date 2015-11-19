# Refactoring status: 100%
_ = require 'underscore-plus'

class FlashManager
  timeoutID: null
  markers: null

  constructor: (@vimState) ->
    {@editor} = @vimState

  flash: ({range, klass, timeout}, fn=null) ->
    range = [range] unless _.isArray(range)
    return unless range.length
    @reset()
    markerOptions = {ivalidate: 'nerver', persistent: false}
    @markers = (@editor.markBufferRange(r, markerOptions) for r in range)
    fn?()
    decorationOptions = {type: 'highlight', class: klass}
    @editor.decorateMarker(m, decorationOptions) for m in @markers

    @timeoutID = setTimeout  =>
      @reset()
    , timeout

  reset: ->
    m.destroy() for m in @markers ? []
    clearTimeout @timeoutID
    {@markers, @timeoutID} = {}

  destroy: ->
    @reset()
    {@vimState, @editor} = {}

module.exports = FlashManager
