{Disposable, CompositeDisposable} = require 'atom'
StatusBarManager = require './status-bar-manager'
GlobalVimState = require './global-vim-state'
VimState = require './vim-state'
settings = require './settings'
_ = require 'underscore-plus'

module.exports =
  config: settings.config

  activate: (state) ->
    @disposables = new CompositeDisposable
    @globalVimState = new GlobalVimState
    @statusBarManager = new StatusBarManager

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
      vimState.onDidDestroy => @vimStates.delete(vimState)

    @disposables.add new Disposable =>
      @vimStates.forEach (vimState) -> vimState.destroy()

    @disposables.add atom.commands.add 'atom-workspace',
      'vim-mode:report': => @showReport()

  getTableOfContent: (content) ->
    toc = _.chain content.split('\n')
      .filter (e) -> /^#/.test(e)
      .map (s) ->
        name = s.replace(/^#+\s/, '')
        link = name.replace ///#{_.escapeRegExp(' < ')}///g, '--'
        "- [#{name}](##{link.toLowerCase()})"
      .value().join('\n')
    toc

  showReport: ->
    Base = require './base'
    fs = require 'fs-plus'
    path = require 'path'
    fileName = 'TOM-report.md'
    filePath = path.join(atom.config.get('core.projectHome'), 'vim-mode', 'docs', fileName)
    header = "# TOM report"
    desc = 'All TOMs inherits Base class  \n'
    desc += 'Base class omitted from ancesstors list for screen spaces  '
    content = Base.reportAll()
    toc = @getTableOfContent content
    body = [header, desc, toc, content].join("\n\n")
    atom.workspace.open(filePath).then (editor) ->
      editor.setText body

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

  provideVimMode: ->
    getGlobalState: @getGlobalState.bind(this)
    getEditorState: @getEditorState.bind(this)
