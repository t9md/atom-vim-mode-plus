_ = require 'underscore-plus'

{Disposable, Emitter, CompositeDisposable} = require 'atom'

Base = require './base'
StatusBarManager = require './status-bar-manager'
globalState = require './global-state'
settings = require './settings'
VimState = require './vim-state'
{getVisibleEditors, poliyFillsToTextBufferHistory} = require './utils'

module.exports =
  config: settings.config

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @statusBarManager = new StatusBarManager
    @vimStatesByEditor = new Map
    @emitter = new Emitter
    @highlightSearchPattern = null

    @subscribe Base.init(@provideVimModePlus())
    @registerCommands()
    @registerVimStateCommands()

    if atom.inDevMode()
      developer = (new (require './developer'))
      @subscribe developer.init(@provideVimModePlus())

    @subscribe atom.workspace.observeTextEditors (editor) =>
      return if editor.isMini()
      unless (history = editor.getBuffer().history).getChangesSinceCheckpoint?
        poliyFillsToTextBufferHistory(history)

      vimState = new VimState(this, editor, @statusBarManager)
      @vimStatesByEditor.set(editor, vimState)

      editorSubscriptions = new CompositeDisposable
      editorSubscriptions.add editor.onDidDestroy =>
        @unsubscribe(editorSubscriptions)
        vimState.destroy()
        @vimStatesByEditor.delete(editor)

      editorSubscriptions.add editor.onDidStopChanging ->
        vimState.refreshHighlightSearch()
      @subscribe(editorSubscriptions)

    @subscribe atom.workspace.onDidStopChangingActivePaneItem (item) =>
      if atom.workspace.isTextEditor?(item)
        # Still there is possibility editor is destroyed and don't have corresponding
        # vimState #196.
        @getEditorState(item)?.refreshHighlightSearch()

    workspaceElement = atom.views.getView(atom.workspace)
    @subscribe atom.workspace.onDidChangeActivePane ->
      workspaceElement.classList.remove('vim-mode-plus-pane-maximized')

    @onDidSetLastSearchPattern =>
      @highlightSearchPattern = globalState.lastSearchPattern
      @refreshHighlightSearchForVisibleEditors()

    @subscribe settings.observe 'highlightSearch', (newValue) =>
      if newValue
        @refreshHighlightSearchForVisibleEditors()
      else
        @clearHighlightSearchForEditors()

  onDidSetLastSearchPattern: (fn) -> @emitter.on('did-set-last-search-pattern', fn)
  emitDidSetLastSearchPattern: (fn) -> @emitter.emit('did-set-last-search-pattern')

  refreshHighlightSearchForVisibleEditors: ->
    for editor in getVisibleEditors()
      @getEditorState(editor).refreshHighlightSearch()

  clearHighlightSearchForEditors: ->
    for editor in atom.workspace.getTextEditors()
      @getEditorState(editor).clearHighlightSearch()
    @highlightSearchPattern = null

  clearRangeMarkerForEditors: ->
    for editor in atom.workspace.getTextEditors()
      @getEditorState(editor).clearRangeMarkers()

  deactivate: ->
    @subscriptions.dispose()
    @vimStatesByEditor.forEach (vimState) ->
      vimState.destroy()

  subscribe: (arg) ->
    @subscriptions.add arg

  unsubscribe: (arg) ->
    arg.dispose?()
    @subscriptions.remove arg

  registerCommands: ->
    @subscribe atom.commands.add 'atom-text-editor:not([mini])',
      # One time clearing highlightSearch. equivalent to `nohlsearch` in pure Vim.
      # Clear all editor's highlight so that we won't see remaining highlight on tab changed.
      'vim-mode-plus:clear-highlight-search': => @clearHighlightSearchForEditors()
      'vim-mode-plus:toggle-highlight-search': -> settings.toggle('highlightSearch')

      'vim-mode-plus:clear-range-marker': => @clearRangeMarkerForEditors()

  registerVimStateCommands: ->
    # all commands here is executed with context where 'this' binded to 'vimState'
    commands =
      'activate-normal-mode': -> @activate('normal')
      'activate-linewise-visual-mode': -> @activate('visual', 'linewise')
      'activate-characterwise-visual-mode': -> @activate('visual', 'characterwise')
      'activate-blockwise-visual-mode': -> @activate('visual', 'blockwise')
      'reset-normal-mode': -> @resetNormalMode()
      'set-register-name': -> @register.setName() # "
      'set-count-0': -> @setCount(0)
      'set-count-1': -> @setCount(1)
      'set-count-2': -> @setCount(2)
      'set-count-3': -> @setCount(3)
      'set-count-4': -> @setCount(4)
      'set-count-5': -> @setCount(5)
      'set-count-6': -> @setCount(6)
      'set-count-7': -> @setCount(7)
      'set-count-8': -> @setCount(8)
      'set-count-9': -> @setCount(9)

      'start-save-mark': -> @startCharInput("save-mark")
      'start-move-to-mark': -> @startCharInput("move-to-mark")
      'start-move-to-mark-line': -> @startCharInput("move-to-mark-line")

    chars = [33..126].map (code) -> String.fromCharCode(code)
    for char in chars
      do (char) ->
        commands["set-input-char-#{char}"] = -> @setInputChar(char)

    scope = 'atom-text-editor:not([mini])'
    for name, fn of commands
      do (fn) =>
        @subscribe atom.commands.add scope, "vim-mode-plus:#{name}", (event) =>
          if editor = atom.workspace.getActiveTextEditor()
            fn.call(@getEditorState(editor))

  consumeStatusBar: (statusBar) ->
    @statusBarManager.initialize(statusBar)
    @statusBarManager.attach()
    @subscribe new Disposable =>
      @statusBarManager.detach()

  # Service API
  # -------------------------
  getGlobalState: ->
    globalState

  getEditorState: (editor) ->
    @vimStatesByEditor.get(editor)

  provideVimModePlus: ->
    Base: Base
    getGlobalState: @getGlobalState.bind(this)
    getEditorState: @getEditorState.bind(this)
