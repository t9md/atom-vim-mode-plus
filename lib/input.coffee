# Refactoring status: 100%
{Emitter} = require 'atom'
{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'

class Input
  subscriptions: null

  constructor: (@vimState) ->
    @emitter = new Emitter
    @view = atom.views.getView(this)
    @vimState.onDidFailToCompose =>
      @view.cancel()

  onDidGet: (spec={}, callback) ->
    @subscriptions ?= new CompositeDisposable
    @view.setSpec(spec)
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
  spec: null

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
      if text.length >= @getSpec('charsMax')
        @confirm()

  setSpec: (@spec) ->
    _.defaults(@spec, {defaultInput: '', charsMax: 1})

  getSpec: (name) ->
    @spec[name]

  confirm: ->
    if input = (@editor.getText() or @getSpec('defaultInput'))
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
    @spec = null
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
