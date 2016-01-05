# Refactoring status: N/A
_ = require 'underscore-plus'
path = require 'path'
{Emitter, Disposable, BufferedProcess, CompositeDisposable} = require 'atom'

Base = require './base'
{generateIntrospectionReport} = require './introspection'
settings = require './settings'
{debug} = require './utils'

packageScope = 'vim-mode-plus'

class Developer
  init: ->
    @devEnvironmentByBuffer = new Map

    commands =
      'toggle-debug': => @toggleDebug()
      'open-in-vim': => @openInVim()
      'generate-introspection-report': => @generateIntrospectionReport()
      'toggle-dev-environment': => @toggleDevEnvironment()

    subscriptions = new CompositeDisposable
    for name, fn of commands
      subscriptions.add @addCommand(name, fn)
    subscriptions

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
        'getRegistries', 'command'
        'init', 'getCommandName', 'registerCommand',
        'delegatesProperties',
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
