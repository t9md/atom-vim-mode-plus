# Refactoring status: N/A
_ = require 'underscore-plus'
{Disposable, BufferedProcess, CompositeDisposable} = require 'atom'

Base = require './base'
{generateIntrospectionReport} = require './introspection'
settings = require './settings'
{debug} = require './utils'

packageScope = 'vim-mode-plus'

class Developer
  init: ->
    commands =
      'toggle-debug': => @toggleDebug()
      'open-in-vim': => @openInVim()
      'generate-introspection-report': => @generateIntrospectionReport()

    subscriptions = new CompositeDisposable
    for name, fn of commands
      subscriptions.add @addCommand(name, fn)
    subscriptions

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

module.exports = Developer
