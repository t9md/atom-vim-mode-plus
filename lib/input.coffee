{Emitter} = require 'atom'
_ = require 'underscore-plus'

# [FIXME] why normalModeInputView need to be property of @editor?
class Input
  constructor: (@vimState) ->
    @emitter = new Emitter
    @view = atom.views.getView(this)
    @vimState.onDidFailToCompose =>
      @view.destroy()

  onDidGet: (options={}, callback) ->
    @view.charsMax = options.charsMax ? 1
    @view.defaultInput = options.defaultInput ? ''
    @emitter.on 'did-get', callback

  onDidChange: (callback) ->
    @emitter.on 'did-change', callback

  focus: ->
    @view.focus()

  cancel: ->
    if @vimState.operationStack.isOperatorPending()
      # [FIXME] callbacking with empty string '' is BAD.
      # its clear former value regardless its important or not.
      @emitter.emit 'did-get', ''

  destroy: ->
    @vimState = null
    @view.destroy()

class InputElement extends HTMLElement
  createdCallback: ->
    @className = 'vim-mode-input'
    @style.height = '0px'

    @editorElement = document.createElement 'atom-text-editor'
    @editorElement.classList.add('editor')
    @editorElement.setAttribute('mini', '')
    @editor = @editorElement.getModel()
    @editor.setMini(true)
    @appendChild(@editorElement)
    @panel = atom.workspace.addBottomPanel item: this, visible: false
    this

  initialize: (@model) ->
    atom.commands.add @editorElement,
      'core:confirm': => @confirm()
      'core:cancel':  => @cancel()
      'blur':         => @cancel()
    @handleInput()
    this

  handleInput: ->
    @editor.onDidChange =>
      text = @editor.getText()
      @model.emitter.emit 'did-change', text
      if text.length >= @charsMax
        @confirm()

  confirm: ->
    @model.emitter.emit 'did-get', (@editor.getText() or @defaultInput)
    atom.workspace.getActivePane().activate()
    @reset()
    @panel.hide()

  reset: ->
    @editor.setText ''

  focus: ->
    @panel.show()
    @editorElement.focus()

  cancel: ->
    atom.workspace.getActivePane().activate()
    @reset()
    @panel.hide()
    @model.cancel()

  destroy: ->
    @model = null
    @panel.destroy()
    @remove()

InputElement = document.registerElement 'vim-mode-input',
  prototype: InputElement.prototype
  extends: 'div',

module.exports = {
  Input, InputElement
}
