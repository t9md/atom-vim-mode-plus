Base = require './base'

class ViewModel
  char: null

  constructor: (@operation, opts={}) ->
    {@editor, @vimState} = @operation
    @view = new VimNormalModeInputElement().initialize(this, opts)
    @editor.normalModeInputView = @view
    @vimState.onDidFailToCompose => @view.remove()

  confirm: (view) ->
    if @operation.isMotion() or @operation.isOperator()
      @setInput(@view.value)
    else
      @vimState.operationStack.push(new Input(@view.value))

  setInput: (input) ->
    @operation.setInput(new Input(input))
    @vimState.operationStack.process() # Re-process!!

  getInput: ->
    @input

  cancel: (view) ->
    if @vimState.isOperatorPending()
      if @operation.isMotion() or @operation.isOperator()
        @setInput('')
      else
        @vimState.operationStack.push(new Input(''))

class Input extends Base
  @extend()
  complete: true
  recodable: true

  constructor: (@characters) ->

class VimNormalModeInputElement extends HTMLDivElement
  createdCallback: ->
    @className = "normal-mode-input"

    @editorContainer = document.createElement("div")
    @editorContainer.className = "editor-container"

    @appendChild(@editorContainer)

  initialize: (@viewModel, opts = {}) ->
    if opts.class?
      @editorContainer.classList.add(opts.class)

    if opts.hidden
      @editorContainer.style.height = "0px"

    @editorElement = document.createElement "atom-text-editor"
    @editorElement.classList.add('editor')
    @editorElement.getModel().setMini(true)
    @editorElement.setAttribute('mini', '')
    @editorContainer.appendChild(@editorElement)

    @singleChar = opts.singleChar
    @defaultText = opts.defaultText ? ''

    @panel = atom.workspace.addBottomPanel(item: this, priority: 100)

    @focus()
    @handleEvents()

    this

  handleEvents: ->
    if @singleChar?
      @editorElement.getModel().getBuffer().onDidChange (e) =>
        @confirm() if e.newText
    else
      atom.commands.add(@editorElement, 'editor:newline', @confirm.bind(this))

    atom.commands.add(@editorElement, 'core:confirm', @confirm.bind(this))
    atom.commands.add(@editorElement, 'core:cancel', @cancel.bind(this))
    atom.commands.add(@editorElement, 'blur', @cancel.bind(this))

  confirm: ->
    @value = @editorElement.getModel().getText() or @defaultText
    @viewModel.confirm(this)
    @removePanel()

  focus: ->
    @editorElement.focus()

  cancel: (e) ->
    @viewModel.cancel(this)
    @removePanel()

  removePanel: ->
    atom.workspace.getActivePane().activate()
    @panel.destroy()

class SearchViewModel extends ViewModel
  constructor: (@searchMotion) ->
    super(@searchMotion, class: 'search')
    @historyIndex = -1

    atom.commands.add(@view.editorElement, 'core:move-up', @increaseHistorySearch)
    atom.commands.add(@view.editorElement, 'core:move-down', @decreaseHistorySearch)

  restoreHistory: (index) ->
    @view.editorElement.getModel().setText(@history(index))

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
      @view.editorElement.getModel().setText('')
    else
      @historyIndex -= 1
      @restoreHistory(@historyIndex)

  confirm: (view) =>
    repeatChar = if @searchMotion.initiallyReversed then '?' else '/'
    if @view.value is '' or @view.value is repeatChar
      lastSearch = @history(0)
      if lastSearch?
        @view.value = lastSearch
      else
        @view.value = ''
        atom.beep()
    super(view)
    @vimState.pushSearchHistory(@view.value)

VimNormalModeInputElement = document.registerElement "vim-normal-mode-input",
  extends: "div",
  prototype: VimNormalModeInputElement.prototype

module.exports = {ViewModel, Input, SearchViewModel, VimNormalModeInputElement}
