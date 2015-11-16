# Refactoring status: N/A
_ = require 'underscore-plus'
{Disposable, CompositeDisposable} = require 'atom'

settings = require './settings'
{debug} = require './utils'

packageScope = 'vim-mode-plus'

class Developer
  init: ->
    @subscriptions = new CompositeDisposable
    commands =
      'toggle-debug': => @toggleDebug()
      'open-in-vim': => @openInVim()
      'generate-introspection-report': => @generateIntrospectionReport()

    @addCommand(name, fn) for name, fn of commands
    new Disposable ->
      @subscriptions?.dispose()
      @subscriptions = null

  addCommand: (name, fn) ->
    @subscriptions.add atom.commands.add('atom-text-editor', "#{packageScope}:#{name}", fn)

  toggleDebug: ->
    settings.set('debug', not settings.get('debug'))
    console.log "#{settings.scope} debug:", settings.get('debug')

  openInVim: ->
    {BufferedProcess} = require 'atom'
    editor = atom.workspace.getActiveTextEditor()
    {row} = editor.getCursorBufferPosition()
    new BufferedProcess
      command: "/Applications/MacVim.app/Contents/MacOS/mvim"
      args: [editor.getPath(), "+#{row+1}"]

  generateIntrospectionReport: ->
    Base = require './base'
    {generateIntrospectionReport} = require './introspection'

    generateIntrospectionReport _.values(Base.getRegistory()),
      excludeProperties: [
        'getClass', 'extend', 'getParent', 'getAncestors', 'kind', 'isCommand'
        'getRegistory', 'command'
        'init', 'getCommandName', 'getCommands', 'run', 'registerCommands',
      ]
      recursiveInspect: Base

module.exports = Developer
