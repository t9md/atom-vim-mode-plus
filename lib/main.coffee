# Refactoring status: 0%, I won't touch for the time being.
_ = require 'underscore-plus'

{Disposable, CompositeDisposable} = require 'atom'

StatusBarManager = require './status-bar-manager'
globalState = require './global-state'
settings = require './settings'
VimState = require './vim-state'
{Hover, HoverElement} = require './hover'
{Input, InputElement, Search, SearchElement} = require './input'
{kls2cmd, cmd2kls} = require './utils'

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
    @disposables = new CompositeDisposable
    @statusBarManager = new StatusBarManager
    @registerViewProviders()

    @vimStates = new Set
    @vimStatesByEditor = new WeakMap

    @disposables.add atom.workspace.observeTextEditors (editor) =>
      return if editor.isMini() or @vimStatesByEditor.get(editor)

      vimState = new VimState(editor, @statusBarManager)
      @vimStates.add(vimState)
      @vimStatesByEditor.set(editor, vimState)
      vimState.onDidDestroy =>
        @vimStates.delete(vimState)

    @disposables.add new Disposable =>
      @vimStates.forEach (vimState) -> vimState.destroy()

    @registerCommands()

  registerCommand: (name, fn) ->
    @disposables.add atom.commands.add('atom-text-editor', "#{packageScope}:#{name}", fn)

  registerCommands: ->
    getState = =>
      @getEditorState(atom.workspace.getActiveTextEditor())

    run = (klass, properties) ->
      getState().operationStack.run(klass, properties)

    for kind in [TextObject, Misc, InsertMode, Motion, Operator, Scroll, VisualBlockwise]
      for name, klass of kind
        name = kls2cmd(name)
        do (name, klass) =>
          if kind is TextObject
            # e.g 'a-word' and 'inner-word' are mapped to TextObject.Word
            @registerCommand "a-#{name}", -> run(klass)
            @registerCommand "inner-#{name}", -> run(klass, {inner: true})
          else
            @registerCommand name, -> run(klass)

    vimStateCommands =
      'activate-normal-mode': -> getState().activate('normal')
      'activate-linewise-visual-mode': -> getState().activate('visual', 'linewise')
      'activate-characterwise-visual-mode': -> getState().activate('visual', 'characterwise')
      'activate-blockwise-visual-mode': -> getState().activate('visual', 'blockwise')
      'reset-normal-mode': -> getState().activate('reset')
      'set-count': (e) -> getState().count.set(e) # 0-9
      'set-register-name': -> getState().register.setName() # "
      'replace-mode-backspace': -> getState().modeManager.replaceModeBackspace()

    @registerCommand(name, fn) for name, fn of vimStateCommands

  registerViewProviders: ->
    atom.views.addViewProvider Hover, (model) ->
      new HoverElement().initialize(model)
    atom.views.addViewProvider Input, (model) ->
      new InputElement().initialize(model)
    atom.views.addViewProvider Search, (model) ->
      new SearchElement().initialize(model)

  deactivate: ->
    @disposables.dispose()

  getGlobalState: ->
    globalState

  getEditorState: (editor) ->
    @vimStatesByEditor.get(editor)

  consumeStatusBar: (statusBar) ->
    @statusBarManager.initialize(statusBar)
    @statusBarManager.attach()
    @disposables.add new Disposable =>
      @statusBarManager.detach()

  provideVimModePlus: ->
    getGlobalState: @getGlobalState.bind(this)
    getEditorState: @getEditorState.bind(this)
