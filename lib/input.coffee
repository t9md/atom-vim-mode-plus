# Refactoring status: 100%
{Emitter} = require 'atom'
{CompositeDisposable, Range} = require 'atom'
_ = require 'underscore-plus'

class Input
  subscriptions: null
  marker: null

  constructor: (@vimState) ->
    @emitter = new Emitter
    @view = atom.views.getView(this)
    @vimState.onDidFailToCompose =>
      @view.cancel()

  onDidGet: (spec={}, callback) ->
    @subscriptions ?= new CompositeDisposable
    @view.setSpec(spec)
    @subscriptions.add @emitter.on 'did-get', callback

  onDidChange: (callback) ->
    @subscriptions ?= new CompositeDisposable
    @subscriptions.add @emitter.on 'did-change', callback

  onDidCancel: (callback) ->
    @subscriptions ?= new CompositeDisposable
    @subscriptions.add @emitter.on 'did-cancel', callback

  focus: ->
    {editor} = @vimState
    start = editor.getCursorBufferPosition()
    end = start.translate([0, 1])

    # @marker = editor.markBufferRange Range(start, end),
    #   invalidate: 'never'
    #   persistent: false
    #
    # klass = if @vimState.mode is 'insert' then 'insert' else 'normal'

    # editor.decorateMarker @marker,
    #   type: 'highlight'
    #   class: "vim-mode-cursor-#{klass}"

    @view.focus()

  unfocus: ->
    # @marker?.destroy()
    @subscriptions?.dispose()
    @subscriptions = null

  destroy: ->
    @subscriptions?.dispose()
    @subscriptions = null
    @vimState = null
    @view.destroy()

class InputElement extends HTMLElement
  finishing: false
  spec: null

  createdCallback: ->
    @className = 'vim-mode-input'

    @editorElement = document.createElement 'atom-text-editor'
    @editorElement.classList.add('editor')
    @editorElement.setAttribute('mini', '')
    @editor = @editorElement.getModel()
    @editor.setMini(true)
    @appendChild(@editorElement)
    @panel = atom.workspace.addBottomPanel item: this, visible: false
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
      if charsMax = @getSpec('charsMax')
        @confirm() if text.length >= charsMax

  setSpec: (@spec) ->
    _.defaults(@spec, {defaultInput: '', charsMax: 1})

  getSpec: (name) ->
    @spec[name]

  confirm: ->
    if input = (@editor.getText() or @getSpec('defaultInput'))
      # console.log "called confirm with '#{input}'"
      @model.emitter.emit 'did-get', input
      @unfocus()
    else
      @cancel()

  cancel: ->
    # console.log "called cancel"
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
    @spec = null
    @model = null
    @editor.destroy()
    @editor = null
    @editorElement = null
    @panel.destroy()
    @remove()

class SearchInput extends Input
  input: null

  constructor: ->
    super
    {@searchHistory} = @vimState
    atom.commands.add @view.editorElement,
      'core:move-up':   => @view.editor.setText @searchHistory.get('prev')
      'core:move-down': => @view.editor.setText @searchHistory.get('next')

    @onDidGet {}, (@input) =>
      @vimState.operationStack.process()

    @onDidCancel =>
      unless @vimState.isMode('visual') or @vimState.isMode('insert')
        @vimState.activate('reset')
      @vimState.reset()

  getInput: ->
    @input

  focus: ({@backwards}={}) ->
    @view.classList.add('backwards') if @backwards
    super

  unfocus: ->
    @backwards = null
    @input = null

class SearchInputElement extends InputElement
  createdCallback: ->
    super
    @className = "vim-mode-search-input"

  setSpec: (@spec) ->

  initialize: (@model) ->
    super

  unfocus: ->
    @classList.remove('backwards')
    super

  confirm: ->
    repeatChar = if @model.backwards then '?' else '/'
    if (input = @editor.getText())?
      if (input is '') or (input is repeatChar)
        input = @model.searchHistory.get('prev')
        atom.beep() if input is ''
      @model.emitter.emit 'did-get', input
      @unfocus()
    else
      @cancel()

InputElement = document.registerElement 'vim-mode-input',
  prototype: InputElement.prototype
  extends: 'div',

SearchInputElement = document.registerElement 'vim-mode-search-input',
  prototype: SearchInputElement.prototype
  extends: 'div',

module.exports = {
  Input, InputElement,
  SearchInput, SearchInputElement
}
