{Emitter, CompositeDisposable} = require 'atom'
{getCharacterForEvent} = require './utils'
packageScope = 'vim-mode-plus'
searchScope = "#{packageScope}-search"

class InputBase
  onDidChange: (fn) -> @emitter.on 'did-change', fn
  onDidConfirm: (fn) -> @emitter.on 'did-confirm', fn
  onDidCancel: (fn) -> @emitter.on 'did-cancel', fn
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
      'core:cancel': => @cancel()
      'blur': => @cancel() unless @finished
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
    @view.destroy()
    {@vimState, @editor, @editorElement} = {}

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
    @editorElement = @createElement 'atom-text-editor',
      classList: ['editor', @klass]
      attribute: {mini: ''}

    @editor = @editorElement.getModel()
    @editor.setMini(true)

    @appendChild @editorElement
    @panel = atom.workspace.addBottomPanel(item: this, visible: false)
    this

  initialize: (@model) ->
    this

  createElement: (element, {classList, textContent, attribute}) ->
    element = document.createElement element
    element.classList.add classList...
    element.textContent = textContent
    for name, value of attribute ? {}
      element.setAttribute(name, value)
    element

  destroy: ->
    @editor.destroy()
    @panel.destroy()
    {@model, @editor, @panel, @editorElement} = {}
    @remove()

class Input extends InputBase

class InputElement extends InputBaseElement
  klass: "#{packageScope}-input"

# [TODO] Differenciating literal-mode should be done by scope and scope based keymap.
class SearchInput extends InputBase
  constructor: ->
    super
    @options = {}
    {@searchHistory} = @vimState

    literalModeSupportCommands =
      "confirm": => @confirm()
      "cancel": => @cancel()
      "visit-next": => @emitter.emit('did-command', 'visit-next')
      "visit-prev": => @emitter.emit('did-command', 'visit-prev')
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
      'core:move-up': => @editor.setText @searchHistory.get('prev')
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

class SearchInputElement extends InputBaseElement
  klass: "#{searchScope}-container"

  createdCallback: ->
    @className = @klass
    @editorElement = @createElement 'atom-text-editor',
      classList: ['editor', searchScope]
      attribute: {mini: ''}
    @editor = @editorElement.getModel()
    @editor.setMini(true)

    @editorContainer = @createElement 'div', classList: ['editor-container']
    @editorContainer.appendChild @editorElement

    @optionsContainer = @createElement 'div', classList: ['options-container']

    @regexSearchStatus = @createElement 'span',
      classList: ['inline-block-tight', 'btn', 'btn-primary']
      textContent: '.*'

    @optionsContainer.appendChild @regexSearchStatus
    @container = @createElement 'div', classList: ['container']

    @appendChild @optionsContainer
    @appendChild @editorContainer

    @panel = atom.workspace.addBottomPanel(item: this, visible: false)
    this

InputElement = document.registerElement "#{packageScope}-input",
  prototype: InputElement.prototype
  extends: 'div',

SearchInputElement = document.registerElement "#{packageScope}-search-input",
  prototype: SearchInputElement.prototype
  extends: 'div',

module.exports = {
  Input, InputElement,
  SearchInput, SearchInputElement
}
