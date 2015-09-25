# Refactoring status: 100%

{debug} = require './utils'
emoji = require 'emoji-images'
emojiFolder = 'atom://vim-mode-plus/node_modules/emoji-images/pngs'
settings = require './settings'

class Hover
  lineHeight: null
  visible: false

  constructor: (@vimState) ->
    @text = []
    @view = atom.views.getView(this)

  add: (text, point) ->
    @text.push text
    @view.show(point)
    @point = point

  # Return boolean to indicate hover is shown at given Point.
  isVisibleAtPoint: (point) ->
    @point?.isEqual point

  withTimeout: (point, {text, timeout}) ->
    @reset()
    @add(text, point)
    if timeout?
      @timeoutID = setTimeout  =>
        @reset()
      , timeout

  iconRegexp = /^:.*:$/
  getText: (lineHeight) ->
    unless @text.length
      return null

    @text.map (text) ->
      text = String(text)
      if settings.get('hoverStyle') is 'emoji'
        emoji(String(text), emojiFolder, lineHeight)
      else
        text.replace /:(.*?):/g, (s, m) ->
          "<span class='icon icon-#{m}'></span>"
    .join('')

  reset: ->
    @text = []
    clearTimeout @timeoutID
    @timeoutID = null
    @view.reset()
    @point = null

  destroy: ->
    @vimState = null
    @view.destroy()

class HoverElement extends HTMLElement
  createdCallback: ->
    @classList.add 'vim-mode-hover'
    this

  initialize: (@model) ->
    this

  show: (point) ->
    return unless settings.get('enableHoverIndicator')
    {editor} = @model.vimState
    unless @marker
      @createOverlay(point)
      @lineHeight = editor.getLineHeightInPixels()
      @setIconSize(@lineHeight)

    # [FIXME] now investigationg overlay position become wrong
    # randomly happen.
    # console.log  @marker.getBufferRange().toString()
    @style.marginTop = (@lineHeight * -2.2) + 'px'
    if text = @model.getText(@lineHeight)
      @innerHTML = text

  createOverlay: (point) ->
    {editor} = @model.vimState
    point ?= editor.getCursorBufferPosition()
    @marker = editor.markBufferPosition point,
      invalidate: "never",
      persistent: false

    decoration = editor.decorateMarker @marker,
      type: 'overlay'
      item: this

  setIconSize: (size) ->
    @styleElement?.remove()
    @styleElement = document.createElement 'style'
    document.head.appendChild(@styleElement)
    selector = '.vim-mode-hover .icon::before'
    size = "#{size*0.8}px"
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
