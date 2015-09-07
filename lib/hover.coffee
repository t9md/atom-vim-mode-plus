# Refactoring status: 100%

{debug} = require './utils'
emoji = require 'emoji-images'
emojiFolder = 'atom://vim-mode/node_modules/emoji-images/pngs'
settings = require './settings'

class Hover
  lineHeight: null

  constructor: (@vimState) ->
    @text = []
    @view = atom.views.getView(this)

  add: (text) ->
    @text.push text
    @view.show()

  iconRegexp = /^:.*:$/
  getText: (lineHeight)->
    unless @text.length
      return null

    @text.map (text) =>
      text = String(text)
      if settings.get('hoverStyle') is 'emoji'
        emoji(String(text), emojiFolder, lineHeight)
      else
        text.replace /:(.*?):/g, (s, m) ->
          "<span class='icon icon-#{m}'></span>"
    .join('')

  reset: ->
    @text = []
    @view.reset()

  destroy: ->
    @vimState = null
    @view.destroy()

class HoverElement extends HTMLElement
  createdCallback: ->
    @classList.add 'vim-mode-hover'
    # @style['line-height'] = '10'
    # @classList.add 'inline-block'
    this

  initialize: (@model) ->
    @style.paddingLeft  = '0.2em'
    @style.paddingRight = '0.2em'
    @style.marginLeft   = '-0.5em'
    this

  show: ->
    return unless settings.get('enableHoverIndicator')
    {editor} = @model.vimState
    unless @marker
      @createOverlay()
      @lineHeight = editor.getLineHeightInPixels()
      @setIconSize(@lineHeight)

    # [FIXME] now investigationg overlay position become wrong
    # randomly happen.
    console.log  @marker.getBufferRange().toString()
    @style.marginTop = (@lineHeight * -2) + 'px'
    if text = @model.getText(@lineHeight)
      @innerHTML = text

  createOverlay: ->
    {editor} = @model.vimState
    point = editor.getCursorBufferPosition()
    @marker = editor.markBufferPosition point,
      invalidate: "never",
      persistent: false

    decoration = editor.decorateMarker @marker,
      type: 'overlay'
      item: this

  setIconSize: (size) ->
    @styleElement?.remove()
    @styleElement = document.createElement 'style'
    document.head.appendChild(@styleElement);
    selector = '.vim-mode-hover .icon::before'
    size = "#{size*0.9}px"
    style = "font-size: #{size}; width: #{size}; hegith: #{size};"
    @styleElement.sheet.addRule(selector, style)

  reset: ->
    @textContent = ''
    @marker?.destroy()
    @styleElement?.remove()
    @marker = null
    @lineHeight = null

  destroy: ->
    @model = null
    @lineHeight = null
    @marker?.destroy()
    @remove()

HoverElement = document.registerElement 'vim-mode-hover',
  prototype: HoverElement.prototype
  extends:   'div'

module.exports = {
  Hover, HoverElement
}
