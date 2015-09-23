# Refactoring status: 50%
{Emitter} = require 'atom'

class SearchViewModel
  constructor: (@vimState, @backwards) ->
    @emitter = new Emitter
    {@searchHistory} = @vimState
    @view = new VimNormalModeInputElement().initialize(this, {class: 'search', @backwards})

    @vimState.editor.normalModeInputView = @view
    @vimState.onDidFailToCompose =>
      @view.remove()

    atom.commands.add @view.editorElement,
      'core:move-up':   => @view.editor.setText @searchHistory.get('prev')
      'core:move-down': => @view.editor.setText @searchHistory.get('next')

  onDidGetInput: (callback) ->
    @emitter.on 'did-get-input', callback

  confirm: =>
    repeatChar = if @backwards then '?' else '/'
    item = @view.value
    if (item is '') or (item is repeatChar)
      item = @searchHistory.get('prev')
      atom.beep() if item is ''
    @emitter.emit 'did-get-input', item

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
