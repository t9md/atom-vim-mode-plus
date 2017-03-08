_ = require 'underscore-plus'

{Disposable, Emitter, CompositeDisposable} = require 'atom'

Base = require './base'
StatusBarManager = require './status-bar-manager'
globalState = require './global-state'
settings = require './settings'
VimState = require './vim-state'
{forEachPaneAxis, addClassList, removeClassList} = require './utils'

module.exports =
  config: settings.config

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @statusBarManager = new StatusBarManager
    @emitter = new Emitter

    service = @provideVimModePlus()
    @subscribe(Base.init(service))
    @registerCommands()
    @registerVimStateCommands()

    if atom.inDevMode()
      developer = new (require './developer')
      @subscribe(developer.init(service))

    @subscribe @observeVimMode ->
      message = """
        ## Message by vim-mode-plus: vim-mode detected!
        To use vim-mode-plus, you must **disable vim-mode** manually.
        """
      atom.notifications.addWarning(message, dismissable: true)

    @subscribe atom.workspace.observeTextEditors (editor) =>
      return if editor.isMini()
      vimState = new VimState(editor, @statusBarManager, globalState)
      @emitter.emit('did-add-vim-state', vimState)

    @subscribe atom.workspace.onDidChangeActivePane(@demaximizePane.bind(this))

    @subscribe atom.workspace.onDidChangeActivePaneItem ->
      if settings.get('automaticallyEscapeInsertModeOnActivePaneItemChange')
        VimState.forEach (vimState) ->
          vimState.activate('normal') if vimState.mode is 'insert'

    @subscribe atom.workspace.onDidStopChangingActivePaneItem (item) =>
      if atom.workspace.isTextEditor(item)
        # Still there is possibility editor is destroyed and don't have corresponding
        # vimState #196.
        @getEditorState(item)?.highlightSearch.refresh()

    @subscribe settings.observe 'highlightSearch', (newValue) ->
      if newValue
        # Re-setting value trigger highlightSearch refresh
        globalState.set('highlightSearchPattern', globalState.get('lastSearchPattern'))
      else
        globalState.set('highlightSearchPattern', null)

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
    VimState.forEach(fn)
    @onDidAddVimState(fn)

  clearPersistentSelectionForEditors: ->
    for editor in atom.workspace.getTextEditors()
      @getEditorState(editor).clearPersistentSelections()

  deactivate: ->
    @subscriptions.dispose()
    VimState.forEach (vimState) ->
      vimState.destroy()
    VimState.clear()

  subscribe: (arg) ->
    @subscriptions.add(arg)

  unsubscribe: (arg) ->
    @subscriptions.remove(arg)

  registerCommands: ->
    @subscribe atom.commands.add 'atom-text-editor:not([mini])',
      'vim-mode-plus:clear-highlight-search': -> globalState.set('highlightSearchPattern', null)
      'vim-mode-plus:toggle-highlight-search': -> settings.toggle('highlightSearch')
      'vim-mode-plus:clear-persistent-selection': => @clearPersistentSelectionForEditors()

    @subscribe atom.commands.add 'atom-workspace',
      'vim-mode-plus:maximize-pane': => @maximizePane()
      'vim-mode-plus:equalize-panes': => @equalizePanes()

  demaximizePane: ->
    if @maximizePaneDisposable?
      @maximizePaneDisposable.dispose()
      @unsubscribe(@maximizePaneDisposable)
      @maximizePaneDisposable = null

  maximizePane: ->
    if @maximizePaneDisposable?
      @demaximizePane()
      return

    getView = (model) -> atom.views.getView(model)
    classPaneMaximized = 'vim-mode-plus--pane-maximized'
    classHideTabBar = 'vim-mode-plus--hide-tab-bar'
    classHideStatusBar = 'vim-mode-plus--hide-status-bar'
    classActivePaneAxis = 'vim-mode-plus--active-pane-axis'

    workspaceElement = getView(atom.workspace)
    paneElement = getView(atom.workspace.getActivePane())

    workspaceClassNames = [classPaneMaximized]
    workspaceClassNames.push(classHideTabBar) if settings.get('hideTabBarOnMaximizePane')
    workspaceClassNames.push(classHideStatusBar) if settings.get('hideStatusBarOnMaximizePane')

    addClassList(workspaceElement, workspaceClassNames...)

    forEachPaneAxis (axis) ->
      paneAxisElement = getView(axis)
      if paneAxisElement.contains(paneElement)
        addClassList(paneAxisElement, classActivePaneAxis)

    @maximizePaneDisposable = new Disposable ->
      forEachPaneAxis (axis) ->
        removeClassList(getView(axis), classActivePaneAxis)
      removeClassList(workspaceElement, workspaceClassNames...)

    @subscribe(@maximizePaneDisposable)

  equalizePanes: ->
    setFlexScale = (newValue, base) ->
      base ?= atom.workspace.getActivePane().getContainer().getRoot()
      base.setFlexScale(newValue)
      for child in base.children ? []
        setFlexScale(newValue, child)

    setFlexScale(1)

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
    @statusBarManager.initialize(statusBar)
    @statusBarManager.attach()
    @subscribe new Disposable =>
      @statusBarManager.detach()

  # Service API
  # -------------------------
  getGlobalState: ->
    globalState

  getEditorState: (editor) ->
    VimState.getByEditor(editor)

  provideVimModePlus: ->
    Base: Base
    getGlobalState: @getGlobalState.bind(this)
    getEditorState: @getEditorState.bind(this)
    observeVimStates: @observeVimStates.bind(this)
    onDidAddVimState: @onDidAddVimState.bind(this)
