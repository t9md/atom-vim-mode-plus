# Refactoring status: 100%
{Emitter} = require 'atom'
{CompositeDisposable} = require 'atom'
{getCharacterForEvent} = require './utils'
packageScope = 'vim-mode-plus'
searchScope = "#{packageScope}-search"

class InputBase
  onDidChange:  (fn) -> @emitter.on 'did-change', fn
  onDidConfirm: (fn) -> @emitter.on 'did-confirm', fn
  onDidCancel:  (fn) -> @emitter.on 'did-cancel', fn
  onDidUnfocus: (fn) -> @emitter.on 'did-unfocus', fn
  onDidCommand: (fn) -> @emitter.on 'did-command', fn

  constructor: (@vimState) ->
    @emitter = new Emitter
    @view = atom.views.getView(this)
    {@editor, @editorElement} = @view
    @vimState.onDidFailToSetTarget =>
      @cancel()

    atom.commands.add @editorElement,
      'core:confirm': => @confirm()
      'core:cancel':  => @cancel()
      'blur':         => @cancel() unless @finished
      'vim-mode-plus:input-cancel': => @cancel()

    @editor.onDidChange =>
      return if @finished
      input = @editor.getText()
      @emitter.emit 'did-change', input
      @confirm() if @canConfirm()

  canConfirm: ->
    if @options?.charsMax
      @editor.getText().length >= @options.charsMax
    else
      false

  focus: (@options={}) ->
    @finished = false
    @view.panel.show()
    @editorElement.focus()

  unfocus: ->
    @finished = true
    @emitter.emit 'did-unfocus'
    atom.workspace.getActivePane().activate()
    @editor.setText ''
    @view.panel.hide()

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
  klass: "#{packageScope}-input"
  createdCallback: ->
    super
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
      "visit-next":  => @emitter.emit('did-command', 'visit-next')
      "visit-prev":  => @emitter.emit('did-command', 'visit-prev')
      "scroll-next": => @emitter.emit('did-command', 'scroll-next')
      "scroll-prev": => @emitter.emit('did-command', 'scroll-prev')
      "insert-wild-pattern": => @editor.insertText '.*?'

    prefix = "#{packageScope}:search"
    commands = {}
    for command, fn of literalModeSupportCommands
      do (fn) =>
        commands["#{prefix}-#{command}"] = (event) =>
          if @literalCharMode
            @editor.insertText getCharacterForEvent(event)
            @literalCharMode = false
          else
            fn()

    atom.commands.add @editorElement, commands
    atom.commands.add @editorElement,
      "vim-mode-plus:search-set-literal-char": => @setLiteralChar()
      "vim-mode-plus:search-set-cursor-word": => @setCursorWord()
      'core:move-up':   => @editor.setText @searchHistory.get('prev')
      'core:move-down': => @editor.setText @searchHistory.get('next')

  setCursorWord: ->
    @editor.setText @vimState.editor.getWordUnderCursor()

  setLiteralChar: ->
    @literalCharMode = true

  updateOptionSettings: ({escapeRegExp}={}) ->
    if escapeRegExp
      @view.regexSearchStatus.classList.remove 'btn-primary'
    else
      @view.regexSearchStatus.classList.add 'btn-primary'

  focus: ({backwards}) ->
    @editorElement.classList.add('backwards') if backwards
    super({})

  unfocus: ->
    @editorElement.classList.remove('backwards')
    @view.regexSearchStatus.classList.add 'btn-primary'
    super

class SearchElement extends InputBaseElement
  klass: "#{searchScope}-container"

  createdCallback: ->
    @className = @klass
    @editorElement = document.createElement 'atom-text-editor'
    @editorElement.classList.add('editor')
    @editorElement.classList.add "#{searchScope}"
    @editorElement.setAttribute('mini', '')
    @editor = @editorElement.getModel()
    @editor.setMini(true)

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


InputElement = document.registerElement "#{packageScope}-input",
  prototype: InputElement.prototype
  extends: 'div',

SearchElement = document.registerElement "#{packageScope}",
  prototype: SearchElement.prototype
  extends: 'div',

module.exports = {
  Input, InputElement,
  Search, SearchElement
}
