# Refactoring status: 100%
{Emitter} = require 'atom'
{CompositeDisposable, Range} = require 'atom'
_ = require 'underscore-plus'

class InputBase
  constructor: (@vimState) ->
    @emitter = new Emitter
    @view = atom.views.getView(this)
    @vimState.onDidFailToCompose =>
      @view.cancel()

  onDidChange:   (fn) -> @emitter.on 'did-change', fn
  onDidConfirm:  (fn) -> @emitter.on 'did-confirm', fn
  onDidCancel:   (fn) -> @emitter.on 'did-cancel', fn
  onWillUnfocus: (fn) -> @emitter.on 'wil-unfocus', fn

  focus: (@options={}) ->
    @view.focus()

  readInput: (options, handlers={}) ->
    subs = new CompositeDisposable
    {onDidConfirm, onDidCancel, onDidChange} = handlers

    subs.add @onDidChange(onDidChange) if onDidChange?
    subs.add @onDidConfirm(onDidConfirm) if onDidConfirm?
    subs.add @onDidCancel(onDidCancel) if onDidCancel?
    subs.add @onWillUnfocus ->
      subs.dispose()
      subs = null
    @focus(options)

  unfocus: ->
    @model.emitter.emit 'will-unfocus'

  destroy: ->
    @vimState = null
    @view.destroy()

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
    atom.commands.add @editorElement,
      'core:confirm': => @confirm()
      'core:cancel':  => @cancel()
      # 'blur':         => @cancel()
    @handleInput()
    this

  handleInput: ->
    @editor.onDidChange =>
      @editor.getText()
      return if @finishing
      text = @editor.getText()
      @model.emitter.emit 'did-change', text
      if charsMax = @model.options.charsMax
        @confirm() if text.length >= charsMax

  confirm: ->
    if input = (@editor.getText() or @model.options.defaultInput)
      @model.emitter.emit 'did-confirm', input
      @unfocus()
    else
      @cancel()

  cancel: ->
    @model.emitter.emit 'did-cancel'
    @unfocus()

  focus: ->
    @panel.show()
    @editorElement.focus()

  unfocus: ->
    @finishing = true
    atom.workspace.getActivePane().activate()
    @editor.setText ''
    @panel.hide()
    @model.unfocus()
    @finishing = false

  destroy: ->
    @options = null
    @model = null
    @editor.destroy()
    @editor = null
    @panel.destroy()
    @panel = null
    @editorElement = null
    @remove()

class Input extends InputBase
  # marker: null
  focus: ->
    # {editor} = @vimState
    # start = editor.getCursorBufferPosition()
    # end = start.translate([0, 1])

    # @marker = editor.markBufferRange Range(start, end),
    #   invalidate: 'never'
    #   persistent: false
    #
    # klass = if @vimState.mode is 'insert' then 'insert' else 'normal'

    # editor.decorateMarker @marker,
    #   type: 'highlight'
    #   class: "vim-mode-cursor-#{klass}"
    super

  unfocus: ->
    # @marker?.destroy()
    @subscriptions?.dispose()
    @subscriptions = null

class InputElement extends InputBaseElement
  klass: 'vim-mode-input'

class Search extends InputBase
  input: null

  constructor: ->
    super
    @options = {}
    {@searchHistory} = @vimState
    atom.commands.add @view.editorElement,
      'core:move-up':   => @view.editor.setText @searchHistory.get('prev')
      'core:move-down': => @view.editor.setText @searchHistory.get('next')

    @onDidConfirm (@input) =>
      @vimState.operationStack.process()

    @onDidCancel =>
      unless @vimState.isMode('visual') or @vimState.isMode('insert')
        @vimState.activate('reset')
      @vimState.reset()

  getInput: ->
    @input

  focus: ({@backwards}={}) ->
    @view.classList.add('backwards') if @backwards
    @view.focus()

  unfocus: ->
    @backwards = null
    @input = null

class SearchElement extends InputBaseElement
  klass: 'vim-mode-search'

  # setSpec: (@spec) ->

  unfocus: ->
    @classList.remove('backwards')
    super

  confirm: ->
    repeatChar = if @model.backwards then '?' else '/'
    if (input = @editor.getText())?
      if (input is '') or (input is repeatChar)
        input = @model.searchHistory.get('prev')
        atom.beep() if input is ''
      @model.emitter.emit 'did-confirm', input
      @unfocus()
    else
      @cancel()

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
