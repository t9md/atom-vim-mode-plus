{Emitter} = require 'atom'
{CompositeDisposable} = require 'atom'

class Input
  subscriptions: null
  constructor: (@vimState) ->
    @emitter = new Emitter
    @view = atom.views.getView(this)
    @vimState.onDidFailToCompose =>
      @view.cancel()

  onDidGet: ({charsMax, defaultInput}={}, callback) ->
    @subscriptions ?= new CompositeDisposable
    @view.charsMax = charsMax ? 1
    @view.defaultInput = defaultInput ? ''
    @subscriptions.add @emitter.on 'did-get', callback

  onDidChange: (callback) ->
    @subscriptions ?= new CompositeDisposable
    @subscriptions.add @emitter.on 'did-change', callback

  onDidCancel: (callback) ->
    @subscriptions ?= new CompositeDisposable
    @subscriptions.add @emitter.on 'did-cancel', callback

  focus: ->
    @view.focus()

  unfocus: ->
    @subscriptions?.dispose()
    @subscriptions = null

  destroy: ->
    @subscriptions?.dispose()
    @subscriptions = null
    @vimState = null
    @view.destroy()

class InputElement extends HTMLElement
  finishing: false

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
      # 'blur':         => @cancel()
    @handleInput()
    this

  handleInput: ->
    @editor.onDidChange =>
      return if @finishing
      text = @editor.getText()
      @model.emitter.emit 'did-change', text
      if text.length >= @charsMax
        @confirm()

  confirm: ->
    if input = (@editor.getText() or @defaultInput)
      # console.log "called confirm with '#{input}'"
      @model.emitter.emit 'did-get', input
      @unfocus()
    else
      @cancel()

  cancel: ->
    # console.log "called cancel"
    @model.emitter.emit 'did-cancel'
    @unfocus()

  focus: ->
    @panel.show()
    @editorElement.focus()

  unfocus: ->
    @finishing = true
    atom.workspace.getActivePane().activate()
    @editor.setText ''
    @panel.hide()
    @model.unfocus()
    @finishing = false

  destroy: ->
    @model = null
    @editor.destroy()
    @editor = null
    @editorElement = null
    @panel.destroy()
    @remove()

InputElement = document.registerElement 'vim-mode-input',
  prototype: InputElement.prototype
  extends: 'div',

module.exports = {
  Input, InputElement
}
