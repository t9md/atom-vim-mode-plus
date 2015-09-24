module.exports =
class FlashManager
  timeoutID: null
  marker: null

  constructor: (@vimState) ->
    {@editor} = @vimState

  flash: ({range, klass, timeout}, fn=null) ->
    @reset()

    @marker = @editor.markBufferRange range,
      invalidate: 'never',
      persistent: false

    fn?()

    @editor.decorateMarker @marker,
      type: 'highlight'
      class: klass

    @timeoutID = setTimeout  =>
      @reset()
    , timeout

  reset: ->
    @marker?.destroy()
    @marker = null
    clearTimeout @timeoutID
    @timeoutID = null

  destroy: ->
    @reset()
    @vimState = null
    @editor   = null
