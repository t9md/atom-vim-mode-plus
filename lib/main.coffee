# Refactoring status: 0%, I won't touch for the time being.
_ = require 'underscore-plus'

{Disposable, CompositeDisposable} = require 'atom'

StatusBarManager = require './status-bar-manager'
globalState = require './global-state'
settings = require './settings'
VimState = require './vim-state'
{Hover, HoverElement} = require './hover'
{Input, InputElement, Search, SearchElement} = require './input'

Base = require './base'
Operator = require './operator'
Motion = require './motion'
TextObject = require './text-object'
InsertMode = require './insert-mode'
Misc = require './misc-commands'
Scroll = require './scroll'
VisualBlockwise = require './visual-blockwise'

packageScope = 'vim-mode-plus'

module.exports =
  config: settings.config

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @statusBarManager = new StatusBarManager
    @vimStates = new Map

    @registerViewProviders()
    service = @provideVimModePlus()
    @subscriptions.add Base.init(service)
    @registerCommands()
    if atom.inDevMode()
      developer = (new (require './developer'))
      @subscriptions.add developer.init(service)

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      return if editor.isMini() or @vimStates.has(editor)
      vimState = new VimState(editor, @statusBarManager)
      @vimStates.set(editor, vimState)
      vimState.onDidDestroy =>
        @vimStates.delete(editor)

    @subscriptions.add new Disposable =>
      @vimStates.forEach (vimState) -> vimState.destroy()

  registerCommands: ->
    for kind in [TextObject, Misc, InsertMode, Motion, Operator, Scroll, VisualBlockwise]
      for klassName, klass of kind
        klass.registerCommands()

    getState = =>
      @getEditorState(atom.workspace.getActiveTextEditor())

    vimStateCommands =
      'activate-normal-mode': -> getState().activate('normal')
      'activate-linewise-visual-mode': -> getState().activate('visual', 'linewise')
      'activate-characterwise-visual-mode': -> getState().activate('visual', 'characterwise')
      'activate-blockwise-visual-mode': -> getState().activate('visual', 'blockwise')
      'reset-normal-mode': -> getState().activate('reset')
      'set-count': (e) -> getState().count.set(e) # 0-9
      'set-register-name': -> getState().register.setName() # "
      'replace-mode-backspace': -> getState().modeManager.replaceModeBackspace()

    @addCommand(name, fn) for name, fn of vimStateCommands

  addCommand: (name, fn) ->
    @subscriptions.add atom.commands.add('atom-text-editor', "#{packageScope}:#{name}", fn)

  registerViewProviders: ->
    atom.views.addViewProvider Hover, (model) ->
      new HoverElement().initialize(model)
    atom.views.addViewProvider Input, (model) ->
      new InputElement().initialize(model)
    atom.views.addViewProvider Search, (model) ->
      new SearchElement().initialize(model)

  deactivate: ->
    @subscriptions.dispose()

  getGlobalState: ->
    globalState

  getEditorState: (editor) ->
    @vimStates.get(editor)

  consumeStatusBar: (statusBar) ->
    @statusBarManager.initialize(statusBar)
    @statusBarManager.attach()
    @subscriptions.add new Disposable =>
      @statusBarManager.detach()

  provideVimModePlus: ->
    getGlobalState: @getGlobalState.bind(this)
    getEditorState: @getEditorState.bind(this)
