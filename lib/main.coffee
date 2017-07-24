{Disposable, Emitter, CompositeDisposable} = require 'atom'

Base = require './base'
globalState = require './global-state'
settings = require './settings'
VimState = require './vim-state'
forEachPaneAxis = null
paneUtils = null

module.exports =
  config: settings.config

  getStatusBarManager: ->
    @statusBarManager ?= new (require './status-bar-manager')

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @emitter = new Emitter

    getEditorState = @getEditorState.bind(this)
    @subscribe(Base.init(getEditorState)...)
    @registerCommands()
    @registerVimStateCommands()

    settings.notifyDeprecatedParams()

    if atom.inSpecMode()
      settings.set('strictAssertion', true)

    if atom.inDevMode()
      developer = new (require './developer')
      @subscribe(developer.init(getEditorState))

    @subscribe @observeVimMode ->
      message = """
        ## Message by vim-mode-plus: vim-mode detected!
        To use vim-mode-plus, you must **disable vim-mode** manually.
        """
      atom.notifications.addWarning(message, dismissable: true)

    @subscribe atom.workspace.observeTextEditors (editor) =>
      @createVimState(editor) unless editor.isMini()

    @subscribe atom.workspace.onDidChangeActivePaneItem =>
      @demaximizePane()

    @subscribe atom.workspace.onDidChangeActivePaneItem ->
      if settings.get('automaticallyEscapeInsertModeOnActivePaneItemChange')
        VimState.forEach (vimState) ->
          vimState.activate('normal') if vimState.mode is 'insert'

    @subscribe atom.workspace.onDidStopChangingActivePaneItem (item) =>
      if atom.workspace.isTextEditor(item) and not item.isMini()
        # Still there is possibility editor is destroyed and don't have corresponding
        # vimState #196.
        vimState = @getEditorState(item)
        return unless vimState?
        if globalState.get('highlightSearchPattern')
          vimState.highlightSearch.refresh()
        else
          vimState.getProp('highlightSearch')?.refresh()

    # @subscribe  globalState.get('highlightSearchPattern')
    # Refresh highlight based on globalState.highlightSearchPattern changes.
    # -------------------------
    @subscribe globalState.onDidChange ({name, newValue}) ->
      if name is 'highlightSearchPattern'
        if newValue
          VimState.forEach (vimState) ->
            vimState.highlightSearch.refresh()
        else
          VimState.forEach (vimState) ->
            # avoid populate prop unnecessarily on vimState.reset on startup
            if vimState.__highlightSearch
              vimState.highlightSearch.clearMarkers()

    @subscribe settings.observe 'highlightSearch', (newValue) ->
      if newValue
        # Re-setting value trigger highlightSearch refresh
        globalState.set('highlightSearchPattern', globalState.get('lastSearchPattern'))
      else
        globalState.set('highlightSearchPattern', null)

    @subscribe(settings.observeConditionalKeymaps()...)

    if settings.get('debug')
      developer?.reportRequireCache(excludeNodModules: false)

  observeVimMode: (fn) ->
    fn() if atom.packages.isPackageActive('vim-mode')
    atom.packages.onDidActivatePackage (pack) ->
      fn() if pack.name is 'vim-mode'

  # * `fn` {Function} to be called when vimState instance was created.
  #  Usage:
  #   onDidAddVimState (vimState) -> do something..
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidAddVimState: (fn) -> @emitter.on('did-add-vim-state', fn)

  # * `fn` {Function} to be called with all current and future vimState
  #  Usage:
  #   observeVimStates (vimState) -> do something..
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  observeVimStates: (fn) ->
    VimState?.forEach(fn)
    @onDidAddVimState(fn)

  clearPersistentSelectionForEditors: ->
    for editor in atom.workspace.getTextEditors()
      @getEditorState(editor).clearPersistentSelections()

  deactivate: ->
    @demaximizePane()

    @subscriptions.dispose()
    VimState?.forEach (vimState) ->
      vimState.destroy()
    VimState?.clear()

  subscribe: (args...) ->
    @subscriptions.add(args...)

  unsubscribe: (arg) ->
    @subscriptions.remove(arg)

  registerCommands: ->
    @subscribe atom.commands.add 'atom-text-editor:not([mini])',
      'vim-mode-plus:clear-highlight-search': -> globalState.set('highlightSearchPattern', null)
      'vim-mode-plus:toggle-highlight-search': -> settings.toggle('highlightSearch')
      'vim-mode-plus:clear-persistent-selection': => @clearPersistentSelectionForEditors()

    @subscribe atom.commands.add 'atom-workspace',
      "vim-mode-plus:maximize-pane": => @maximizePane()
      "vim-mode-plus:equalize-panes": => @equalizePanes()
      "vim-mode-plus:exchange-pane": => @exchangePane()
      "vim-mode-plus:move-pane-to-very-top": => @movePaneToVery("top")
      "vim-mode-plus:move-pane-to-very-bottom": => @movePaneToVery("bottom")
      "vim-mode-plus:move-pane-to-very-left": => @movePaneToVery("left")
      "vim-mode-plus:move-pane-to-very-right": => @movePaneToVery("right")

  exchangePane: ->
    paneUtils ?= require("./pane-utils")
    paneUtils.exchangePane()

  demaximizePane: ->
    if @maximizePaneDisposable?
      @maximizePaneDisposable.dispose()
      @maximizePaneDisposable = null

  maximizePane: ->
    if @maximizePaneDisposable?
      @demaximizePane()
      return

    paneUtils ?= require("./pane-utils")
    @maximizePaneDisposable = paneUtils.maximizePane()

  equalizePanes: ->
    paneUtils ?= require("./pane-utils")
    paneUtils.equalizePanes()

  movePaneToVery: (direction) ->
    paneUtils ?= require("./pane-utils")
    paneUtils.movePaneToVery(direction)

  registerVimStateCommands: ->
    # all commands here is executed with context where 'this' bound to 'vimState'
    commands =
      'activate-normal-mode': -> @activate('normal')
      'activate-linewise-visual-mode': -> @activate('visual', 'linewise')
      'activate-characterwise-visual-mode': -> @activate('visual', 'characterwise')
      'activate-blockwise-visual-mode': -> @activate('visual', 'blockwise')
      'reset-normal-mode': -> @resetNormalMode(userInvocation: true)
      'set-register-name': -> @register.setName() # "
      'set-register-name-to-_': -> @register.setName('_')
      'set-register-name-to-*': -> @register.setName('*')
      'operator-modifier-characterwise': -> @emitDidSetOperatorModifier(wise: 'characterwise')
      'operator-modifier-linewise': -> @emitDidSetOperatorModifier(wise: 'linewise')
      'operator-modifier-occurrence': -> @emitDidSetOperatorModifier(occurrence: true, occurrenceType: 'base')
      'operator-modifier-subword-occurrence': -> @emitDidSetOperatorModifier(occurrence: true, occurrenceType: 'subword')
      'repeat': -> @operationStack.runRecorded()
      'repeat-find': -> @operationStack.runCurrentFind()
      'repeat-find-reverse': -> @operationStack.runCurrentFind(reverse: true)
      'repeat-search': -> @operationStack.runCurrentSearch()
      'repeat-search-reverse': -> @operationStack.runCurrentSearch(reverse: true)
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

    chars = [32..126].map (code) -> String.fromCharCode(code)
    for char in chars
      do (char) ->
        charForKeymap = if char is ' ' then 'space' else char
        commands["set-input-char-#{charForKeymap}"] = ->
          @emitDidSetInputChar(char)

    getEditorState = @getEditorState.bind(this)

    bindToVimState = (oldCommands) ->
      newCommands = {}
      for name, fn of oldCommands
        do (fn) ->
          newCommands["vim-mode-plus:#{name}"] = (event) ->
            event.stopPropagation()
            if vimState = getEditorState(@getModel())
              fn.call(vimState, event)
      newCommands

    @subscribe atom.commands.add('atom-text-editor:not([mini])', bindToVimState(commands))

  consumeStatusBar: (statusBar) ->
    statusBarManager = @getStatusBarManager()
    statusBarManager.initialize(statusBar)
    statusBarManager.attach()
    @subscribe new Disposable ->
      statusBarManager.detach()

  consumeDemoMode: ({onWillAddItem, onDidStart, onDidStop, onDidRemoveHover}) ->
    @subscribe(
      onDidStart(-> globalState.set('demoModeIsActive', true))
      onDidStop(-> globalState.set('demoModeIsActive', false))
      onDidRemoveHover(@destroyAllDemoModeFlasheMarkers.bind(this))
      onWillAddItem(({item, event}) =>
        if event.binding.command.startsWith('vim-mode-plus:')
          commandElement = item.getElementsByClassName('command')[0]
          commandElement.textContent = commandElement.textContent.replace(/^vim-mode-plus:/, '')

        element = document.createElement('span')
        element.classList.add('kind', 'pull-right')
        element.textContent = @getKindForCommand(event.binding.command)
        item.appendChild(element)
      )
    )

  destroyAllDemoModeFlasheMarkers: ->
    VimState?.forEach (vimState) ->
      vimState.flashManager.destroyDemoModeMarkers()

  getKindForCommand: (command) ->
    if command.startsWith('vim-mode-plus')
      command = command.replace(/^vim-mode-plus:/, '')
      if command.startsWith('operator-modifier')
        kind = 'op-modifier'
      else
        Base.getKindForCommandName(command) ? 'vmp-other'
    else
      'non-vmp'

  createVimState: (editor) ->
    vimState = new VimState(editor, @getStatusBarManager(), globalState)
    @emitter.emit('did-add-vim-state', vimState)

  createVimStateIfNecessary: (editor) ->
    return if VimState.has(editor)
    vimState = new VimState(editor, @getStatusBarManager(), globalState)
    @emitter.emit('did-add-vim-state', vimState)

  # Service API
  # -------------------------
  getGlobalState: ->
    globalState

  getEditorState: (editor) ->
    VimState.getByEditor(editor)

  provideVimModePlus: ->
    Base: Base
    registerCommandFromSpec: Base.registerCommandFromSpec
    getGlobalState: @getGlobalState
    getEditorState: @getEditorState
    observeVimStates: @observeVimStates.bind(this)
    onDidAddVimState: @onDidAddVimState.bind(this)
