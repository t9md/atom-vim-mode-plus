{Emitter, Disposable, CompositeDisposable} = require 'atom'
{registerElement, getCharacterForEvent, ElementBuilder} = require './utils'
packageScope = 'vim-mode-plus'

# InputBase, InputElementBase
# -------------------------
class Input extends HTMLElement
  ElementBuilder.includeInto(this)
  klass: "vim-mode-plus-input"

  onDidChange: (fn) -> @emitter.on 'did-change', fn
  onDidConfirm: (fn) -> @emitter.on 'did-confirm', fn
  onDidCancel: (fn) -> @emitter.on 'did-cancel', fn
  onDidUnfocus: (fn) -> @emitter.on 'did-unfocus', fn
  onDidCommand: (fn) -> @emitter.on 'did-command', fn

  createdCallback: ->
    @className = @klass
    @buildElements()
    @editor = @editorElement.getModel()
    @editor.setMini(true)

    @emitter = new Emitter

    @editor.onDidChange =>
      return if @finished
      text = @editor.getText()
      @emitter.emit 'did-change', text
      if (charsMax = @options?.charsMax) and text.length >= @options.charsMax
        @confirm()
    @panel = atom.workspace.addBottomPanel(item: this, visible: false)
    this

  buildElements: ->
    @innerHTML = """
    <atom-text-editor mini class='editor vim-mode-plus-input'></atom-text-editor>
    """
    @editorElement = @firstElementChild

  initialize: (@vimState) ->
    @vimState.onDidFailToSetTarget =>
      @cancel()
    this

  destroy: ->
    @editor.destroy()
    @panel?.destroy()
    {@editor, @panel, @editorElement, @vimState} = {}
    @remove()

  handleEvents: ->
    atom.commands.add @editorElement,
      'core:confirm': => @confirm()
      'core:cancel': => @cancel()
      'blur': => @cancel() unless @finished
      'vim-mode-plus:input-cancel': => @cancel()

  focus: (@options={}) ->
    @finished = false
    @panel.show()
    @editorElement.focus()
    @commandSubscriptions = @handleEvents()

    # Cancel on tab switch
    disposable = atom.workspace.onDidChangeActivePaneItem =>
      disposable.dispose()
      @cancel() unless @finished

  unfocus: ->
    @commandSubscriptions?.dispose()
    @finished = true
    atom.workspace.getActivePane().activate()
    @editor.setText ''
    @panel?.hide()
    @emitter.emit('did-unfocus')

  isVisible: ->
    @panel?.isVisible()

  cancel: ->
    @emitter.emit('did-cancel')
    @unfocus()

  confirm: ->
    @emitter.emit('did-confirm', @editor.getText())
    @unfocus()

# SearchInput
# -------------------------
class SearchInput extends Input
  klass: "vim-mode-plus-search-container"
  literalModeDeactivator: null

  buildElements: ->
    @innerHTML = """
    <div class='options-container'>
      <span class='inline-block-tight btn btn-primary'>.*</span>
    </div>
    <div class='editor-container'>
      <atom-text-editor mini class='editor vim-mode-plus-search'></atom-text-editor>
    </div>
    """
    [@optionsContainer, @editorContainer] = @getElementsByTagName('div')
    @regexSearchStatus = @optionsContainer.firstElementChild
    @editorElement = @editorContainer.firstElementChild

  stopPropagation: (oldCommands) ->
    newCommands = {}
    for name, fn of oldCommands
      do (fn) ->
        if ':' in name
          commandName = name
        else
          commandName = "vim-mode-plus:#{name}"
        newCommands[commandName] = (event) ->
          event.stopImmediatePropagation()
          fn(event)
    newCommands

  initialize: (@vimState) ->
    super
    @options = {}

    atom.commands.add @editorElement, @stopPropagation(
      "search-confirm": => @confirm()
      "search-land-to-start": => @confirm()
      "search-land-to-end": => @confirm('end')
      "search-cancel": => @cancel()

      "search-visit-next": => @emitter.emit('did-command', name: 'visit', direction: 'next')
      "search-visit-prev": => @emitter.emit('did-command', name: 'visit', direction: 'prev')
      "select-occurrence-from-search": => @emitter.emit('did-command', name: 'occurrence', operation: 'SelectOccurrence')
      "change-occurrence-from-search": => @emitter.emit('did-command', name: 'occurrence', operation: 'ChangeOccurrence')
      "add-occurrence-pattern-from-search": => @emitter.emit('did-command', name: 'occurrence')

      "search-insert-wild-pattern": => @editor.insertText('.*?')
      "search-activate-literal-mode": => @activateLiteralMode()
      "search-set-cursor-word": => @setCursorWord()
      'core:move-up': => @editor.setText @vimState.searchHistory.get('prev')
      'core:move-down': => @editor.setText @vimState.searchHistory.get('next')
    )
    this

  confirm: (landingPoint=null) ->
    searchConfirmEvent = {input: @editor.getText(), landingPoint}
    @emitter.emit('did-confirm', searchConfirmEvent)
    @unfocus()

  setCursorWord: ->
    @editor.insertText(@vimState.editor.getWordUnderCursor())

  activateLiteralMode: ->
    if @literalModeDeactivator?
      @literalModeDeactivator.dispose()
    else
      @literalModeDeactivator = new CompositeDisposable()
      @editorElement.classList.add('literal-mode')

      @literalModeDeactivator.add new Disposable =>
        @editorElement.classList.remove('literal-mode')
        @literalModeDeactivator = null

  updateOptionSettings: ({useRegexp}={}) ->
    @regexSearchStatus.classList.toggle('btn-primary', useRegexp)

  focus: ({backwards}) ->
    @editorElement.classList.add('backwards') if backwards
    super({})

  unfocus: ->
    @editorElement.classList.remove('backwards')
    @regexSearchStatus.classList.add 'btn-primary'
    @literalModeDeactivator?.dispose()
    super

InputElement = registerElement 'vim-mode-plus-input',
  prototype: Input.prototype

SearchInputElement = registerElement 'vim-mode-plus-search-input',
  prototype: SearchInput.prototype

module.exports = {
  InputElement, SearchInputElement
}
