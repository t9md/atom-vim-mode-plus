emoji = require 'emoji-images'
emojiFolder = 'atom://autocomplete-emojis/node_modules/emoji-images/pngs'

class Hover
  constructor: (@vimState) ->
    @text = ''
    @view = atom.views.getView(this)

  add: (text) ->
    @text += text
    @view.show()

  reset: ->
    @text = ''
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

  emojify: (text) ->
    emoji(String(text), emojiFolder, 20)

  show: ->
    @innerHTML = @emojify(@model.text)
    {editor} = @model.vimState
    @style.paddingLeft  = '0.2em'
    @style.paddingRight = '0.2em'
    @style.marginLeft   = '-0.2em'
    @style.marginTop = (editor.getLineHeightInPixels() * -2) + 'px'

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
