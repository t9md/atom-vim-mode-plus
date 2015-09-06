# Refactoring status: 100%

emoji = require 'emoji-images'
emojiFolder = 'atom://vim-mode/node_modules/emoji-images/pngs'
settings = require './settings'

class Hover
  constructor: (@vimState) ->
    @text = []
    @view = atom.views.getView(this)

  add: (text) ->
    @text.push text
    @view.show()

  getText: ->
    limit =
      switch
        when ':clipboard:' in @text then 3
        when ':scissors:' in @text then 3
        else  1
    return if @text.length < limit
    @text.join('')

  reset: ->
    @text = []
    @view.reset()

  destroy: ->
    @vimState = null
    @view.destroy()

class HoverElement extends HTMLElement
  createdCallback: ->
    @classList.add 'vim-mode-hover'
    this

  initialize: (@model) ->
    this

  emojify: (text, size) ->
    emoji(String(text), emojiFolder, size)

  show: ->
    return unless settings.get('enableHoverIndicator')

    {editor} = @model.vimState
    lineHeightInPixels = editor.getLineHeightInPixels()
    unless text = @model.getText()
      return
    @innerHTML = @emojify(text, lineHeightInPixels * 0.9 + 'px')
    @style.paddingLeft  = '0.2em'
    @style.paddingRight = '0.2em'
    @style.marginLeft   = '-0.2em'
    @style.marginTop = (lineHeightInPixels * -2) + 'px'

    point = editor.getCursorBufferPosition()
    @marker = editor.markBufferPosition point,
      invalidate: "never",
      persistent: false

    decoration = editor.decorateMarker @marker,
      type: 'overlay'
      item: this

  reset: ->
    @textContent = ''
    @marker?.destroy()

  destroy: ->
    @model = null
    @marker?.destroy()
    @remove()

HoverElement = document.registerElement 'vim-mode-hover',
  prototype: HoverElement.prototype
  extends:   'div'

module.exports = {
  Hover, HoverElement
}
