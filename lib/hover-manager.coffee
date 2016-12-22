swrap = require './selection-wrapper'

module.exports =
class HoverManager
  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    @container = document.createElement('div')
    @container.className = 'vim-mode-plus-hover'

  getPoint: ->
    if @vimState.isMode('visual', 'blockwise')
      # FIXME #179
      @vimState.getLastBlockwiseSelection()?.getHeadSelection().getHeadBufferPosition()
    else
      swrapOptions = {fromProperty: true, allowFallback: true}
      swrap(@editor.getLastSelection()).getBufferPositionFor('head', swrapOptions)

  set: (text, point=@getPoint()) ->
    unless @marker?
      @marker = @editor.markBufferPosition(point)
      decorationOptions = {type: 'overlay', item: @container}
      decoration = @editor.decorateMarker(@marker, decorationOptions)
    @container.textContent = text

  withTimeout: (point, options) ->
    @reset()
    if options.classList.length
      @container.classList.add(options.classList...)

    @add(options.text, point)
    if options.timeout?
      @timeoutID = setTimeout  =>
        @reset()
      , options.timeout

  reset: ->
    @container.className = 'vim-mode-plus-hover'
    clearTimeout(@timeoutID)
    @marker?.destroy()
    {@marker, @timeoutID} = {}

  destroy: ->
    {@vimState} = {}
    @reset()
