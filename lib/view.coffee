# Refactoring status: 50%
# Planed to be eliminiated
{Emitter} = require 'atom'

class SearchViewModel
  # [FIXME] constructor argument is not consitent
  constructor: (@vimState, @backwards) ->
    # {@vimState} = @searchMotion
    @emitter = new Emitter
    @view = new VimNormalModeInputElement().initialize(this, {class: 'search', @backwards})

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
    repeatChar = if @backwards then '?' else '/'
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
    @editorElement = document.createElement "atom-text-editor"
    @editorElement.classList.add('editor')
    @editorElement.setAttribute('mini', '')
    @editor = @editorElement.getModel()
    @editor.setMini(true)
    @editorContainer.appendChild(@editorElement)

    @editorContainer.classList.add('search-input')
    @editorContainer.classList.add('backwards') if options.backwards
    @panel = atom.workspace.addBottomPanel(item: this, priority: 100)

    @handleEvents()
    @focus()
    this

  handleEvents: ->
    atom.commands.add @editorElement,
      'editor:newline': => @confirm()
      'core:confirm':   => @confirm()
      'core:cancel':    => @cancel()
      'blur':           => @cancel()

  confirm: ->
    @value = @editor.getText()
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
