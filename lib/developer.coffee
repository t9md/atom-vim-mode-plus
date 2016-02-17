# Refactoring status: N/A
_ = require 'underscore-plus'
path = require 'path'
{Emitter, Disposable, BufferedProcess, CompositeDisposable} = require 'atom'

Base = require './base'
{generateIntrospectionReport, getKeyBindingForCommand} = require './introspection'
settings = require './settings'
{debug} = require './utils'

packageScope = 'vim-mode-plus'
getEditorState = null

class Developer
  init: (service) ->
    {getEditorState} = service
    @devEnvironmentByBuffer = new Map
    @reloadSubscriptionByBuffer = new Map

    commands =
      'toggle-debug': => @toggleDebug()

      # TODO remove once finished #158
      'debug-highlight-search': ->
        globalState = require './global-state'
        editor = atom.workspace.getActiveTextEditor()
        vimState = getEditorState(editor)
        console.log 'highlightSearchPattern', globalState.highlightSearchPattern
        console.log "vimState's id is #{vimState.id}"
        console.log "hlmarkers are"
        vimState.highlightSearchMarkers.forEach (marker) ->
          console.log marker.getBufferRange().toString()

      'open-in-vim': => @openInVim()
      'generate-introspection-report': => @generateIntrospectionReport()
      'report-commands-have-no-default-keymap': => @reportCommandsHaveNoDefaultKeymap()
      'toggle-dev-environment': => @toggleDevEnvironment()
      'reload-packages': => @reloadPackages()
      'toggle-reload-packages-on-save': => @toggleReloadPackagesOnSave()

    subscriptions = new CompositeDisposable
    for name, fn of commands
      subscriptions.add @addCommand(name, fn)
    subscriptions

  reloadPackages: ->
    packages = settings.get('devReloadPackages') ? []
    packages.push('vim-mode-plus')
    for packName in packages
      pack = atom.packages.getLoadedPackage(packName)

      if pack?
        console.log "deactivating #{packName}"
        atom.packages.deactivatePackage(packName)
        atom.packages.unloadPackage(packName)

        packPath = pack.path
        Object.keys(require.cache)
          .filter (p) ->
            p.indexOf(packPath + path.sep) is 0
          .forEach (p) ->
            delete require.cache[p]

        atom.packages.loadPackage(packName)
        atom.packages.activatePackage(packName)

  toggleReloadPackagesOnSave: ->
    return unless editor = atom.workspace.getActiveTextEditor()
    buffer = editor.getBuffer()
    fileName = path.basename(editor.getPath())

    if subscription = @reloadSubscriptionByBuffer.get(buffer)
      subscription.dispose()
      @reloadSubscriptionByBuffer.delete(buffer)
      console.log "disposed reloadPackagesOnSave for #{fileName}"
    else
      @reloadSubscriptionByBuffer.set buffer, buffer.onDidSave =>
        console.clear()
        @reloadPackages()
      console.log "activated reloadPackagesOnSave for #{fileName}"

  toggleDevEnvironment: ->
    return unless editor = atom.workspace.getActiveTextEditor()
    buffer = editor.getBuffer()
    fileName = path.basename(editor.getPath())

    if @devEnvironmentByBuffer.has(buffer)
      @devEnvironmentByBuffer.get(buffer).dispose()
      @devEnvironmentByBuffer.delete(buffer)
      console.log "disposed dev env #{fileName}"
    else
      @devEnvironmentByBuffer.set(buffer, new DevEnvironment(editor))
      console.log "activated dev env #{fileName}"

  addCommand: (name, fn) ->
    atom.commands.add('atom-text-editor', "#{packageScope}:#{name}", fn)

  toggleDebug: ->
    settings.set('debug', not settings.get('debug'))
    console.log "#{settings.scope} debug:", settings.get('debug')

  reportCommandsHaveNoDefaultKeymap: ->
    packPath = atom.packages.resolvePackagePath('vim-mode-plus')
    path.join(packPath, "keymaps", )

    commandNames = (klass.getCommandName() for __, klass of Base.getRegistries() when klass.isCommand())
    commandNames = commandNames.filter (commandName) ->
      not getKeyBindingForCommand(commandName)

    atom.workspace.open().then (editor) ->
      editor.setText commandNames.join("\n")

  openInVim: ->
    editor = atom.workspace.getActiveTextEditor()
    {row} = editor.getCursorBufferPosition()
    new BufferedProcess
      command: "/Applications/MacVim.app/Contents/MacOS/mvim"
      args: [editor.getPath(), "+#{row+1}"]

  generateIntrospectionReport: ->
    generateIntrospectionReport _.values(Base.getRegistries()),
      excludeProperties: [
        'getClass', 'extend', 'getParent', 'getAncestors', 'isCommand'
        'getRegistries', 'command', 'reset'
        'init', 'getCommandName', 'getCommandScope', 'registerCommand',
        'delegatesProperties', 'subscriptions', 'commandPrefix', 'commandScope'
        'delegatesMethods',
        'delegatesProperty',
        'delegatesMethod',
      ]
      recursiveInspect: Base

class DevEnvironment
  constructor: (@editor) ->
    @editorElement = atom.views.getView(@editor)
    @emitter = new Emitter
    fileName = path.basename(@editor.getPath())
    @disposable = @editor.onDidSave =>
      console.clear()
      Base.suppressWarning = true
      @reload()
      Base.suppressWarning = false
      Base.reset()
      @emitter.emit 'did-reload'
      console.log "reloaded #{fileName}"

  dispose: ->
    @disposable?.dispose()

  onDidReload: (fn) -> @emitter.on('did-reload', fn)

  reload: ->
    packPath = atom.packages.resolvePackagePath('vim-mode-plus')
    originalRequire = global.require
    global.require = (libPath) ->
      if libPath.startsWith './'
        originalRequire "#{packPath}/lib/#{libPath}"
      else
        originalRequire libPath

    atom.commands.dispatch(@editorElement, 'run-in-atom:run-in-atom')
    global.require = originalRequire

module.exports = Developer
