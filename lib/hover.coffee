emoji = require 'emoji-images'

emojiFolder = 'atom://vim-mode-plus/node_modules/emoji-images/pngs'
{registerElement} = require './utils'
settings = require './settings'
swrap = require './selection-wrapper'

class Hover
  lineHeight: null
  point: null

  constructor: (@vimState, @param) ->
    {@editor, @editorElement} = @vimState
    @text = []
    @view = atom.views.getView(this)

  setPoint: ->
    switch
      when @vimState.isMode('visual', 'linewise')
        swrap(@editor.getLastSelection()).getCharacterwiseHeadPosition()
      when @vimState.isMode('visual', 'blockwise')
        # FIXME #179
        @vimState.getLastBlockwiseSelection()?.getHead().getHeadBufferPosition()
      else
        @editor.getCursorBufferPosition()

  add: (text, point) ->
    @text.push text
    @view.show(point ? @setPoint())

  replaceLastSection: (text, point) ->
    @text.pop()
    @add(text, point)

  withTimeout: (point, options) ->
    @reset()
    {text, timeout} = options
    if options.classList.length
      @view.classList.add(options.classList...)
    @add(text, point)
    if timeout?
      @timeoutID = setTimeout  =>
        @reset()
      , timeout

  getText: (lineHeight) ->
    unless @text.length
      return null

    @text.map (text) ->
      text = String(text)
      if settings.get('showHoverOnOperateIcon') is 'emoji'
        emoji(String(text), emojiFolder, lineHeight)
      else
        text.replace /:(.*?):/g, (s, m) ->
          "<span class='icon icon-#{m}'></span>"
    .join('')

  reset: ->
    @text = []
    clearTimeout @timeoutID
    @view.reset()
    {@timeoutID, @point} = {}

  isVisible: ->
    @view.isVisible()

  destroy: ->
    {@param, @vimState} = {}
    @view.destroy()

class HoverElement extends HTMLElement
  createdCallback: ->
    @className = 'vim-mode-plus-hover'
    this

  initialize: (@model) ->
    this

  isVisible: ->
    @marker?

  show: (point) ->
    {editor} = @model.vimState
    unless @marker
      @marker = @createOverlay(point ? editor.getCursorBufferPosition())
      @lineHeight = editor.getLineHeightInPixels()
      @setIconSize(@lineHeight)

    # [FIXME] overlay position become wrong randomly happen.
    @style.marginTop = (@lineHeight * -2.2) + 'px'
    if text = @model.getText(@lineHeight)
      @innerHTML = text

  createOverlay: (point) ->
    {editor} = @model.vimState
    marker = editor.markBufferPosition point,
      invalidate: "never",
      persistent: false

    decoration = editor.decorateMarker marker,
      type: 'overlay'
      item: this
    marker

  setIconSize: (size) ->
    @styleElement?.remove()
    @styleElement = document.createElement 'style'
    document.head.appendChild(@styleElement)
    selector = '.vim-mode-plus-hover .icon::before'
    size = "#{size*0.8}px"
    style = "font-size: #{size}; width: #{size}; hegith: #{size};"
    @styleElement.sheet.addRule(selector, style)

  reset: ->
    @className = 'vim-mode-plus-hover'
    @textContent = ''
    @marker?.destroy()
    @styleElement?.remove()
    {@marker, @lineHeight} = {}

  destroy: ->
    @marker?.destroy()
    {@model, @lineHeight} = {}
    @remove()

HoverElement = registerElement "vim-mode-plus-hover",
  prototype: HoverElement.prototype

module.exports = {
  Hover, HoverElement
}
