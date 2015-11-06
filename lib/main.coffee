# Refactoring status: 0%, I won't touch for the time being.
_ = require 'underscore-plus'

{Disposable, CompositeDisposable} = require 'atom'

StatusBarManager = require './status-bar-manager'
GlobalVimState = require './global-vim-state'
VimState = require './vim-state'
settings = require './settings'
{Hover, HoverElement} = require './hover'
{Input, InputElement, Search, SearchElement} = require './input'

module.exports =
  config: settings.config

  activate: (state) ->
    @disposables = new CompositeDisposable
    @globalVimState = new GlobalVimState
    @statusBarManager = new StatusBarManager
    @registerViewProviders()

    @vimStates = new Set
    @vimStatesByEditor = new WeakMap

    @disposables.add atom.workspace.observeTextEditors (editor) =>
      return if editor.isMini() or @vimStatesByEditor.get(editor)

      vimState = new VimState(
        atom.views.getView(editor),
        @statusBarManager,
        @globalVimState
      )
      @vimStates.add(vimState)
      @vimStatesByEditor.set(editor, vimState)
      vimState.onDidDestroy =>
        @vimStates.delete(vimState)

    @disposables.add new Disposable =>
      @vimStates.forEach (vimState) -> vimState.destroy()

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
    @globalVimState

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
