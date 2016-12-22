{registerElement} = require './utils'
settings = require './settings'
swrap = require './selection-wrapper'

class Hover extends HTMLElement
  createdCallback: ->
    @className = 'vim-mode-plus-hover'
    @text = []
    this

  initialize: (@vimState) ->
    {@editor, @editorElement} = @vimState
    this

  getPoint: ->
    if @vimState.isMode('visual', 'blockwise')
      # FIXME #179
      @vimState.getLastBlockwiseSelection()?.getHeadSelection().getHeadBufferPosition()
    else
      swrap(@editor.getLastSelection()).getBufferPositionFor('head', fromProperty: true, allowFallback: true)

  add: (text, point=@getPoint()) ->
    @text.push(text)
    @show(point)

  replaceLastSection: (text, point) ->
    @text.pop()
    @add(text)

  showLight: (char, point=@getPoint()) ->
    unless @lightHover?
      @lightHover = document.createElement('div')
      @lightHover.className = 'vim-mode-plus-hover-light'

    @lightHoverMarker?.destroy()
    @lightHoverMarker = @editor.markBufferPosition(point)
    @lightHover.textContent = char
    @editor.decorateMarker(@lightHoverMarker, type: 'overlay', item: @lightHover)

  resetLight: ->
    @lightHoverMarker?.destroy()

  show: (point) ->
    unless @marker?
      @marker = @createOverlay(point)

    if @text.length
      @innerHTML = @text.map((text) -> String(text)).join('')

  withTimeout: (point, options) ->
    @reset()
    if options.classList.length
      @classList.add(options.classList...)
    @add(options.text, point)
    if options.timeout?
      @timeoutID = setTimeout  =>
        @reset()
      , options.timeout

  createOverlay: (point) ->
    marker = @editor.markBufferPosition(point)
    decoration = @editor.decorateMarker marker,
      type: 'overlay'
      item: this
    marker

  isVisible: ->
    @marker?

  reset: ->
    @text = []
    @resetLight()
    clearTimeout @timeoutID
    @className = 'vim-mode-plus-hover'
    @textContent = ''
    @marker?.destroy()
    {@marker, @timeoutID} = {}

  destroy: ->
    @reset()
    {@vimState} = {}
    @remove()

HoverElement = registerElement "vim-mode-plus-hover",
  prototype: Hover.prototype

module.exports = {
  HoverElement
}
