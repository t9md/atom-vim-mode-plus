# Refactoring status: 100%
{Emitter} = require 'atom'
{CompositeDisposable} = require 'atom'

class InputBase
  onDidChange:   (fn) -> @emitter.on 'did-change', fn
  onDidConfirm:  (fn) -> @emitter.on 'did-confirm', fn
  onDidCancel:   (fn) -> @emitter.on 'did-cancel', fn
  onWillUnfocus: (fn) -> @emitter.on 'wil-unfocus', fn

  constructor: (@vimState) ->
    @emitter = new Emitter
    @view = atom.views.getView(this)
    {@editor, @editorElement} = @view
    @vimState.onDidFailToCompose =>
      @cancel()

    atom.commands.add @editorElement,
      'core:confirm': => @confirm()
      'core:cancel':  => @cancel()
      # 'blur':         => @cancel()

    @editor.onDidChange =>
      return if @finishing
      text = @editor.getText()
      # If we can confirm, no need to inform change.
      if @canConfirm()
        @confirm()
      else
        @emitter.emit 'did-change', text

  canConfirm: ->
    if @options?.charsMax
      @editor.getText().length >= @options.charsMax
    else
      false

  readInput: (options, handlers={}) ->
    @subs?.dispose()
    @subs = new CompositeDisposable
    {onDidConfirm, onDidCancel, onDidChange} = handlers

    @subs.add @onDidChange(onDidChange) if onDidChange?
    @subs.add @onDidConfirm(onDidConfirm) if onDidConfirm?
    @subs.add @onDidCancel(onDidCancel) if onDidCancel?
    @subs.add @onWillUnfocus =>
      @subs.dispose()
      @subs = null
    @focus(options)

  focus: (@options={}) ->
    @view.panel.show()
    @editorElement.focus()

  unfocus: ->
    @finishing = true
    @emitter.emit 'will-unfocus'
    atom.workspace.getActivePane().activate()
    @editor.setText ''
    @view.panel.hide()
    @finishing = false

  cancel: ->
    @emitter.emit 'did-cancel'
    @unfocus()

  destroy: ->
    @vimState = null
    @view.destroy()

    @editor = null
    @editorElement = null

  confirm: ->
    if (input = @editor.getText())?
      @emitter.emit 'did-confirm', input
      @unfocus()
    else
      @cancel()

class InputBaseElement extends HTMLElement
  finishing: false
  klass: null

  createdCallback: ->
    @className = @klass
    @editorElement = document.createElement 'atom-text-editor'
    @editorElement.classList.add('editor')
    @editorElement.setAttribute('mini', '')
    @editor = @editorElement.getModel()
    @editor.setMini(true)
    @appendChild @editorElement
    @panel = atom.workspace.addBottomPanel(item: this, visible: false)
    this

  initialize: (@model) ->
    this

  destroy: ->
    @model = null
    @editor.destroy()
    @editor = null
    @panel.destroy()
    @panel = null
    @editorElement = null
    @remove()

class Input extends InputBase

class InputElement extends InputBaseElement
  klass: 'vim-mode-input'

class Search extends InputBase
  constructor: ->
    super
    @options = {}
    {@searchHistory} = @vimState
    atom.commands.add @editorElement,
      'core:move-up':   => @editor.setText @searchHistory.get('prev')
      'core:move-down': => @editor.setText @searchHistory.get('next')

  focus: ({backwards}) ->
    @view.classList.add('backwards') if backwards
    super({})

  unfocus: ->
    @view.classList.remove('backwards')
    super

class SearchElement extends InputBaseElement
  klass: 'vim-mode-search'

InputElement = document.registerElement 'vim-mode-plus-input',
  prototype: InputElement.prototype
  extends: 'div',

SearchElement = document.registerElement 'vim-mode-plus-search',
  prototype: SearchElement.prototype
  extends: 'div',

module.exports = {
  Input, InputElement,
  Search, SearchElement
}
