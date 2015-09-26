# Refactoring status: 100%
{Emitter} = require 'atom'
{CompositeDisposable} = require 'atom'
{getKeystrokeForEvent} = require './utils'

class InputBase
  onChange:  (fn) -> @emitter.on 'change', fn
  onConfirm: (fn) -> @emitter.on 'confirm', fn
  onCancel:  (fn) -> @emitter.on 'cancel', fn
  onUnfocus: (fn) -> @emitter.on 'unfocus', fn
  onCommand: (fn) -> @emitter.on 'command', fn

  constructor: (@vimState) ->
    @emitter = new Emitter
    @view = atom.views.getView(this)
    {@editor, @editorElement} = @view
    @vimState.onDidFailToCompose =>
      @cancel()

    atom.commands.add @editorElement,
      'core:confirm': => @confirm()
      'core:cancel':  => @cancel()
      'blur':         => @cancel() unless @finished

    @editor.onDidChange =>
      return if @finished
      text = @editor.getText()
      # If we can confirm, no need to inform change.
      if @canConfirm()
        @confirm()
      else
        @emitter.emit 'change', text

  canConfirm: ->
    if @options?.charsMax
      @editor.getText().length >= @options.charsMax
    else
      false

  readInput: (options, handlers={}) ->
    @subs?.dispose()
    @subs = new CompositeDisposable
    {onConfirm, onCancel, onChange, onCommand} = handlers

    @subs.add @onChange(onChange)   if onChange?
    @subs.add @onConfirm(onConfirm) if onConfirm?
    @subs.add @onCancel(onCancel)   if onCancel?
    @subs.add @onCommand(onCommand) if onCommand?
    @subs.add @onUnfocus =>
      @subs.dispose()
      @subs = null
    @focus(options)

  focus: (@options={}) ->
    @finished = false
    @view.panel.show()
    @editorElement.focus()

  unfocus: ->
    @finished = true
    @emitter.emit 'unfocus'
    atom.workspace.getActivePane().activate()
    @editor.setText ''
    @view.panel.hide()

  cancel: ->
    @emitter.emit 'cancel'
    @unfocus()

  destroy: ->
    @vimState = null
    @view.destroy()

    @editor = null
    @editorElement = null

  confirm: ->
    if (input = @editor.getText())?
      @emitter.emit 'confirm', input
      @unfocus()
    else
      @cancel()

class InputBaseElement extends HTMLElement
  klass: null

  createdCallback: ->
    @className = @klass
    @editorElement = document.createElement 'atom-text-editor'
    @editorElement.classList.add('editor')
    @editorElement.classList.add @klass
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
  createdCallback: ->
    super
    # @className = @klass
    @editorElement = document.createElement 'atom-text-editor'
    @editorElement.classList.add('editor')
    @editorElement.classList.add @klass
    @editorElement.setAttribute('mini', '')
    @editor = @editorElement.getModel()
    @editor.setMini(true)
    @appendChild @editorElement
    @panel = atom.workspace.addBottomPanel(item: this, visible: false)
    this

class Search extends InputBase
  constructor: ->
    super
    @options = {}
    {@searchHistory} = @vimState

    literalModeSupportCommands =
      "confirm":     => @confirm()
      "cancel":      => @cancel()
      "visit-next":  => @emitter.emit('command', 'visit-next')
      "visit-prev":  => @emitter.emit('command', 'visit-prev')
      "scroll-next": => @emitter.emit('command', 'scroll-next')
      "scroll-prev": => @emitter.emit('command', 'scroll-prev')
    prefix = 'vim-mode:search'
    commands = {}
    for command, fn of literalModeSupportCommands
      do (fn) =>
        commands["#{prefix}-#{command}"] = (event) =>
          if @literalCharMode
            @editor.insertText getKeystrokeForEvent(event)
            @literalCharMode = false
          else
            fn()

    atom.commands.add @editorElement, commands
    atom.commands.add @editorElement,
      "vim-mode:search-set-literal-char": => @setLiteralChar()
      "vim-mode:search-set-cursor-word": => @setCursorWord()
      'core:move-up':   => @editor.setText @searchHistory.get('prev')
      'core:move-down': => @editor.setText @searchHistory.get('next')

  setCursorWord: ->
    @editor.setText @vimState.editor.getWordUnderCursor()

  setLiteralChar: ->
    @literalCharMode = true

  regexSearchStatusChanged: (enabled) ->
    if enabled
      @view.regexSearchStatus.classList.add 'btn-primary'
    else
      @view.regexSearchStatus.classList.remove 'btn-primary'

  focus: ({backwards}) ->
    @view.classList.add('backwards') if backwards
    super({})

  unfocus: ->
    @view.classList.remove('backwards')
    @view.regexSearchStatus.classList.add 'btn-primary'
    super

class SearchElement extends InputBaseElement
  klass: 'vim-mode-search'

  createdCallback: ->
    @className = @klass
    @editorElement = document.createElement 'atom-text-editor'
    @editorElement.classList.add('editor')
    @editorElement.classList.add @klass
    @editorElement.setAttribute('mini', '')
    @editor = @editorElement.getModel()
    @editor.setMini(true)
    # @appendChild @editorElement

    @editorContainer = document.createElement 'div'
    @editorContainer.className = 'editor-container'
    @editorContainer.appendChild @editorElement

    @optionsContainer = document.createElement 'div'
    @optionsContainer.className = 'options-container'
    @regexSearchStatus = document.createElement 'span'
    @regexSearchStatus.classList.add 'inline-block-tight', 'btn', 'btn-primary'
    @regexSearchStatus.textContent = '.*'
    @optionsContainer.appendChild @regexSearchStatus
    @container = document.createElement 'div'
    @container.className = 'container'
    @appendChild @optionsContainer
    @appendChild @editorContainer

    @panel = atom.workspace.addBottomPanel(item: this, visible: false)
    this


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
