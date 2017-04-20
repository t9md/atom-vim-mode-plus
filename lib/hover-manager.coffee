module.exports =
class HoverManager
  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    @container = document.createElement('div')
    @decorationOptions = {type: 'overlay', item: @container}
    @vimState.onDidDestroy(@destroy)
    @reset()

  getPoint: ->
    if @vimState.isMode('visual', 'blockwise')
      @vimState.getLastBlockwiseSelection().getHeadSelection().getHeadBufferPosition()
    else
      selection = @editor.getLastSelection()
      @vimState.swrap(selection).getBufferPositionFor('head', from: ['property', 'selection'])

  set: (text, point=@getPoint(), options={}) ->
    unless @marker?
      @marker = @editor.markBufferPosition(point)
      @editor.decorateMarker(@marker, @decorationOptions)

    if options.classList?.length
      @container.classList.add(options.classList...)
    @container.textContent = text

  reset: ->
    @container.className = 'vim-mode-plus-hover'
    @marker?.destroy()
    @marker = null

  destroy: =>
    @container.remove()
    @marker?.destroy()
    @marker = null
