{Emitter, Disposable, CompositeDisposable} = require 'atom'
{registerElement, getCharacterForEvent, ElementBuilder} = require './utils'
packageScope = 'vim-mode-plus'
searchScope = "#{packageScope}-search"

# InputBase, InputElementBase
# -------------------------
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
      text = @editor.getText()
      @emitter.emit 'did-change', text
      if (charsMax = @options?.charsMax) and text.length >= @options.charsMax
        @confirm()

  focus: (@options={}) ->
    @finished = false
    @view.panel.show()
    @editorElement.focus()
    # Cancel on tab switch
    disposable = atom.workspace.onDidChangeActivePaneItem =>
      disposable.dispose()
      @cancel() unless @finished

  unfocus: ->
    @finished = true
    @emitter.emit 'did-unfocus'
    atom.workspace.getActivePane().activate()
    @editor.setText ''
    @view.panel.hide()

  isVisible: ->
    @view.panel.isVisible()

  cancel: ->
    @emitter.emit 'did-cancel'
    @unfocus()

  confirm: ->
    @emitter.emit 'did-confirm', @editor.getText()
    @unfocus()

  destroy: ->
    @view.destroy()
    {@vimState, @editor, @editorElement} = {}

class InputElementBase extends HTMLElement
  ElementBuilder.includeInto(this)
  klass: null
  createdCallback: ->
    @className = @klass
    @buildElements()
    @editor = @editorElement.getModel()
    @editor.setMini(true)
    @panel = atom.workspace.addBottomPanel(item: this, visible: false)
    this

  buildElements: ->
    @appendChild(
      @editorElement = @atomTextEditor
        classList: ['editor', @klass]
        attribute: {mini: ''}
    )

  initialize: (@model) ->
    this

  destroy: ->
    @editor.destroy()
    @panel.destroy()
    {@model, @editor, @panel, @editorElement} = {}
    @remove()

# Input
# -------------------------
class Input extends InputBase

class InputElement extends InputElementBase
  klass: "#{packageScope}-input"

InputElement = registerElement "#{packageScope}-input",
  prototype: InputElement.prototype

# SearchInput
# -------------------------
class SearchInput extends InputBase
  constructor: ->
    super
    @options = {}
    {@searchHistory} = @vimState

    atom.commands.add @editorElement,
      "vim-mode-plus:search-confirm": => @confirm()
      "vim-mode-plus:search-cancel": => @cancel()
      "vim-mode-plus:search-visit-next": => @emitter.emit('did-command', 'visit-next')
      "vim-mode-plus:search-visit-prev": => @emitter.emit('did-command', 'visit-prev')
      "vim-mode-plus:search-insert-wild-pattern": => @editor.insertText('.*?')
      "vim-mode-plus:search-activate-literal-mode": => @activateLiteralMode()
      "vim-mode-plus:search-set-cursor-word": => @setCursorWord()
      'core:move-up': => @editor.setText @searchHistory.get('prev')
      'core:move-down': => @editor.setText @searchHistory.get('next')

  setCursorWord: ->
    @editor.setText @vimState.editor.getWordUnderCursor()

  isLiteralMode: ->
    @editorElement.classList.contains('literal-mode')

  activateLiteralMode: ->
    if @isLiteralMode()
      @literalModeDeactivator?.dispose()
    else
      @literalModeDeactivator = new CompositeDisposable()
      @editorElement.classList.add('literal-mode')

      @literalModeDeactivator.add new Disposable =>
        @editorElement.classList.remove('literal-mode')
        @literalModeDeactivator = null

      @literalModeDeactivator.add @editor.onDidChange =>
        @literalModeDeactivator.dispose()

  updateOptionSettings: ({useRegexp}={}) ->
    @view.regexSearchStatus.classList.toggle('btn-primary', useRegexp)

  focus: ({backwards}) ->
    @editorElement.classList.add('backwards') if backwards
    super({})

  unfocus: ->
    @editorElement.classList.remove('backwards')
    @view.regexSearchStatus.classList.add 'btn-primary'
    super

class SearchInputElement extends InputElementBase
  klass: "#{searchScope}-container"
  buildElements: ->
    @appendChild(
      @optionsContainer = @div
        classList: ['options-container']
    ).appendChild(
      @regexSearchStatus = @span
        classList: ['inline-block-tight', 'btn', 'btn-primary']
        textContent: '.*'
    )

    @appendChild(
      @editorContainer = @div
        classList: ['editor-container']
    ).appendChild(
      @editorElement = @atomTextEditor
        classList: ['editor', searchScope]
        attribute: {mini: ''}
    )


SearchInputElement = registerElement "#{packageScope}-search-input",
  prototype: SearchInputElement.prototype

module.exports = {
  Input, InputElement,
  SearchInput, SearchInputElement
}
