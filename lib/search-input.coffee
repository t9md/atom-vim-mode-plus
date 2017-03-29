{Emitter, Disposable, CompositeDisposable} = require 'atom'

module.exports =
class SearchInput
  literalModeDeactivator: null

  onDidChange: (fn) -> @emitter.on 'did-change', fn
  onDidConfirm: (fn) -> @emitter.on 'did-confirm', fn
  onDidCancel: (fn) -> @emitter.on 'did-cancel', fn
  onDidCommand: (fn) -> @emitter.on 'did-command', fn

  constructor: (@vimState) ->
    @emitter = new Emitter
    @disposables = new CompositeDisposable
    @disposables.add @vimState.onDidDestroy(@destroy.bind(this))

    @container = document.createElement('div')
    @container.className = 'vim-mode-plus-search-container'
    @container.innerHTML = """
      <div class='options-container'>
        <span class='inline-block-tight btn btn-primary'>.*</span>
      </div>
      <div class='editor-container'>
      </div>
      """

    [optionsContainer, editorContainer] = @container.getElementsByTagName('div')
    @regexSearchStatus = optionsContainer.firstElementChild
    @editor = atom.workspace.buildTextEditor(mini: true)
    @editorElement = @editor.element
    @editorElement.classList.add('vim-mode-plus-search')
    editorContainer.appendChild(@editorElement)
    @editor.onDidChange =>
      return if @finished
      @emitter.emit('did-change', @editor.getText())

    @panel = atom.workspace.addBottomPanel(item: @container, visible: false)

    @vimState.onDidFailToPushToOperationStack =>
      @cancel()

    @registerCommands()

  destroy: ->
    @disposables.dispose()
    @editor.destroy()
    @panel?.destroy()
    {@editor, @panel, @editorElement, @vimState} = {}

  handleEvents: ->
    atom.commands.add @editorElement,
      'core:confirm': => @confirm()
      'core:cancel': => @cancel()
      'core:backspace': => @backspace()
      'vim-mode-plus:input-cancel': => @cancel()

  focus: (@options={}) ->
    @finished = false

    @editorElement.classList.add(@options.classList...) if @options.classList?
    @panel.show()
    @editorElement.focus()

    @focusSubscriptions = new CompositeDisposable
    @focusSubscriptions.add @handleEvents()
    cancel = @cancel.bind(this)
    @vimState.editorElement.addEventListener('click', cancel)
    # Cancel on mouse click
    @focusSubscriptions.add new Disposable =>
      @vimState.editorElement.removeEventListener('click', cancel)

    # Cancel on tab switch
    @focusSubscriptions.add(atom.workspace.onDidChangeActivePaneItem(cancel))

  unfocus: ->
    @finished = true
    @editorElement.classList.remove(@options.classList...) if @options?.classList?
    @regexSearchStatus.classList.add 'btn-primary'
    @literalModeDeactivator?.dispose()

    @focusSubscriptions?.dispose()
    atom.workspace.getActivePane().activate()
    @editor.setText ''
    @panel?.hide()

  updateOptionSettings: ({useRegexp}={}) ->
    @regexSearchStatus.classList.toggle('btn-primary', useRegexp)

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

  isVisible: ->
    @panel?.isVisible()

  cancel: ->
    return if @finished
    @emitter.emit('did-cancel')
    @unfocus()

  backspace: ->
    @cancel() if @editor.getText().length is 0

  confirm: (landingPoint=null) ->
    @emitter.emit('did-confirm', {input: @editor.getText(), landingPoint})
    @unfocus()

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


  emitDidCommand: (name, options={}) ->
    options.name = name
    options.input = @editor.getText()
    @emitter.emit('did-command', options)

  registerCommands: ->
    atom.commands.add @editorElement, @stopPropagation(
      "search-confirm": => @confirm()
      "search-land-to-start": => @confirm()
      "search-land-to-end": => @confirm('end')
      "search-cancel": => @cancel()

      "search-visit-next": => @emitDidCommand('visit', direction: 'next')
      "search-visit-prev": => @emitDidCommand('visit', direction: 'prev')

      "select-occurrence-from-search": => @emitDidCommand('occurrence', operation: 'SelectOccurrence')
      "change-occurrence-from-search": => @emitDidCommand('occurrence', operation: 'ChangeOccurrence')
      "add-occurrence-pattern-from-search": => @emitDidCommand('occurrence')
      "project-find-from-search": => @emitDidCommand('project-find')

      "search-insert-wild-pattern": => @editor.insertText('.*?')
      "search-activate-literal-mode": => @activateLiteralMode()
      "search-set-cursor-word": => @setCursorWord()
      'core:move-up': => @editor.setText @vimState.searchHistory.get('prev')
      'core:move-down': => @editor.setText @vimState.searchHistory.get('next')
    )
