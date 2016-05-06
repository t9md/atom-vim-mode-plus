emoji = require 'emoji-images'

emojiFolder = 'atom://vim-mode-plus/node_modules/emoji-images/pngs'
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
    switch
      when @vimState.isMode('visual', 'linewise')
        swrap(@editor.getLastSelection()).getCharacterwiseHeadPosition()
      when @vimState.isMode('visual', 'blockwise')
        # FIXME #179
        @vimState.getLastBlockwiseSelection()?.getHeadSelection().getHeadBufferPosition()
      else
        @editor.getCursorBufferPosition()

  add: (text, point=@getPoint()) ->
    @text.push(text)
    @show(point)

  replaceLastSection: (text) ->
    @text.pop()
    @add(text)

  convertText: (text, lineHeight) ->
    text = String(text)
    if settings.get('showHoverOnOperateIcon') is 'emoji'
      emoji(text, emojiFolder, lineHeight)
    else
      text.replace /:(.*?):/g, (s, m) ->
        "<span class='icon icon-#{m}'></span>"

  show: (point) ->
    unless @marker?
      @marker = @createOverlay(point)
      @lineHeight = @editor.getLineHeightInPixels()
      @setIconSize(@lineHeight)
      @style.marginTop = (@lineHeight * -2.2) + 'px'

    if @text.length
      @innerHTML = @text.map (text) =>
        @convertText(text, @lineHeight)
      .join('')

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

  setIconSize: (size) ->
    @styleElement?.remove()
    @styleElement = document.createElement 'style'
    document.head.appendChild(@styleElement)
    selector = '.vim-mode-plus-hover .icon::before'
    size = "#{size*0.8}px"
    style = "font-size: #{size}; width: #{size}; hegith: #{size};"
    @styleElement.sheet.addRule(selector, style)

  isVisible: ->
    @marker?

  reset: ->
    @text = []
    clearTimeout @timeoutID
    @className = 'vim-mode-plus-hover'
    @textContent = ''
    @marker?.destroy()
    @styleElement?.remove()
    {
      @marker, @lineHeight
      @timeoutID, @styleElement
    } = {}

  destroy: ->
    @reset()
    {@vimState, @lineHeight} = {}
    @remove()

HoverElement = registerElement "vim-mode-plus-hover",
  prototype: Hover.prototype

module.exports = {
  HoverElement
}
