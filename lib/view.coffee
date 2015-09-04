# Refactoring status: 30%
Base = require './base'
_ = require 'underscore-plus'
{Emitter} = require 'atom'

# [FIXME] why normalModeInputView need to be property of @editor?
class ViewModel
  constructor: (@vimState, options={}) ->
    @emitter = new Emitter
    @view = new VimNormalModeInputElement().initialize(this, options)
    @vimState.editor.normalModeInputView = @view
    @hover = new HoverElemnt().initialize(this, options)
    @vimState.onDidFailToCompose =>
      @view.remove()

  onDidGetInput: (callback) ->
    @emitter.on 'did-get-input', callback

  onDidChangeInput: (callback) ->
    @emitter.on 'did-change-input', callback

  confirm: ->
    @emitter.emit 'did-get-input', @view.value
    @hover.destroy()

  cancel: ->
    if @vimState.operationStack.isOperatorPending()
      # [FIXME] callbacking with empty string '' is BAD.
      # its clear former value regardless its important or not.
      @emitter.emit 'did-get-input', ''
    # delete @editor.normalModeInputView
    atom.workspace.getActivePane().activate()
    @hover.destroy()

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

class SearchViewModel extends ViewModel
  # [FIXME] constructor argument is not consitent
  constructor: (@searchMotion) ->
    super(@searchMotion.vimState, class: 'search')
    @historyIndex = -1

    atom.commands.add @view.editorElement,
      'core:move-up': @increaseHistorySearch
      'core:move-down': @decreaseHistorySearch

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
    super()
    @vimState.pushSearchHistory(@view.value)

class HoverElement extends HTMLElement
  createdCallback: ->
    @classList.add 'vim-mode-hover'
    this

  initialize: (@viewModel, {prefix, @lineOffset}={}) ->
    prefix ?= ''
    @lineOffset ?= 0
    @textContent = prefix
    @viewModel.onDidChangeInput (input) =>
      @textContent = prefix + input
    @setup()
    this

  setup: ->
    editor = @viewModel.vimState.editor
    @style.paddingLeft  = '0.2em'
    @style.paddingRight = '0.2em'
    @style.marginLeft   = '-0.2em'
    @style.marginTop = (editor.getLineHeightInPixels() * @lineOffset) + 'px'
    # @style.marginTop = if top <= 10 then '0px' else '-20px'
    # @style.marginTop = '-50px'

    point = editor.getCursorBufferPosition()
    @marker = editor.markBufferPosition point,
      invalidate: "never",
      persistent: false

    decoration = editor.decorateMarker @marker,
      type: 'overlay'
      item: this

  destroy: ->
    @marker.destroy()
    @remove()

VimNormalModeInputElement = document.registerElement "vim-normal-mode-input",
  extends: "div",
  prototype: VimNormalModeInputElement.prototype

HoverElemnt = document.registerElement 'vim-mode-hover',
  prototype: HoverElement.prototype
  extends:   'div'

module.exports = {
  ViewModel
  SearchViewModel
  VimNormalModeInputElement
  HoverElemnt
}
