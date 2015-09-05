# Refactoring status: 50%
{Emitter} = require 'atom'

class SearchViewModel
  # [FIXME] constructor argument is not consitent
  constructor: (@searchMotion) ->
    {@vimState} = @searchMotion
    @emitter = new Emitter
    @view = new VimNormalModeInputElement().initialize(this, class: 'search')
    @vimState.editor.normalModeInputView = @view
    @vimState.onDidFailToCompose =>
      @view.remove()
    @historyIndex = -1

    atom.commands.add @view.editorElement,
      'core:move-up': @increaseHistorySearch
      'core:move-down': @decreaseHistorySearch

  onDidGetInput: (callback) ->
    @emitter.on 'did-get-input', callback

  restoreHistory: (index) ->
    @view.editor.setText(@history(index))

  history: (index) ->
    @vimState.getSearchHistoryItem(index)

  increaseHistorySearch: =>
    if @history(@historyIndex + 1)?
      @historyIndex += 1
      @restoreHistory(@historyIndex)

  decreaseHistorySearch: =>
    if @historyIndex <= 0
      # get us back to a clean slate
      @historyIndex = -1
      @view.editor.setText('')
    else
      @historyIndex -= 1
      @restoreHistory(@historyIndex)

  confirm: =>
    repeatChar = if @searchMotion.initiallyReversed then '?' else '/'
    if @view.value is '' or @view.value is repeatChar
      lastSearch = @history(0)
      if lastSearch?
        @view.value = lastSearch
      else
        @view.value = ''
        atom.beep()
    @emitter.emit 'did-get-input', @view.value
    @vimState.pushSearchHistory(@view.value)

  cancel: ->
    if @vimState.operationStack.isOperatorPending()
      # [FIXME] callbacking with empty string '' is BAD.
      # its clear former value regardless its important or not.
      @emitter.emit 'did-get-input', ''
    # delete @editor.normalModeInputView
    atom.workspace.getActivePane().activate()

class VimNormalModeInputElement extends HTMLDivElement
  createdCallback: ->
    @className = "normal-mode-input"

    @editorContainer = document.createElement("div")
    @editorContainer.className = "editor-container"

    @appendChild(@editorContainer)

  initialize: (@viewModel, options={}) ->
    if options.class?
      @editorContainer.classList.add(options.class)

    if options.hidden
      @editorContainer.style.height = "0px"

    @editorElement = document.createElement "atom-text-editor"
    @editorElement.classList.add('editor')
    @editorElement.setAttribute('mini', '')
    @editor = @editorElement.getModel()
    @editor.setMini(true)
    @editorContainer.appendChild(@editorElement)

    @charsMax = options.charsMax
    @defaultText = options.defaultText ? ''

    @panel = atom.workspace.addBottomPanel(item: this, priority: 100)

    @handleEvents()
    @focus()
    this

  handleEvents: ->
    if @charsMax?
      @editor.onDidChange =>
        @viewModel.emitter.emit 'did-change-input', @editor.getText()
        text = @editor.getText()
        if text.length >= @charsMax
          @confirm()
    else
      atom.commands.add @editorElement, 'editor:newline': => @confirm()

    atom.commands.add @editorElement,
      'core:confirm': => @confirm()
      'core:cancel':  => @cancel()
      'blur':         => @cancel()

  confirm: ->
    @value = @editor.getText() or @defaultText
    @viewModel.confirm()
    @removePanel()

  focus: ->
    @editorElement.focus()

  cancel: (e) ->
    @viewModel.cancel()
    @removePanel()

  removePanel: ->
    atom.workspace.getActivePane().activate()
    @panel.destroy()

VimNormalModeInputElement = document.registerElement "vim-normal-mode-input",
  extends: "div",
  prototype: VimNormalModeInputElement.prototype

module.exports = {
  SearchViewModel
  VimNormalModeInputElement
}
