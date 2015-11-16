# Refactoring status: N/A
_ = require 'underscore-plus'
{Disposable, CompositeDisposable} = require 'atom'

settings = require './settings'
{debug} = require './utils'

packageScope = 'vim-mode-plus'

class Developer
  init: (service) ->
    {@getEditorState} = service
    @subscriptions = new CompositeDisposable
    commands =
      'toggle-debug': => @toggleDebug()
      'open-in-vim': => @openInVim()
      'generate-introspection-report': => @generateIntrospectionReport()

    @addCommand(name, fn) for name, fn of commands
    new Disposable ->
      @subscriptions.dispose()
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
    Operator = require './operator'
    Motion = require './motion'
    TextObject = require './text-object'
    InsertMode = require './insert-mode'
    Misc = require './misc-commands'
    Scroll = require './scroll'
    VisualBlockwise = require './visual-blockwise'
    {generateIntrospectionReport} = require './introspection'
    mods = [Operator, Motion, TextObject, Scroll, InsertMode, VisualBlockwise, Misc]
    generateIntrospectionReport mods,
      excludeProperties: ['getConstructor', 'extend', 'getParent', 'getAncestors']
      recursiveInspect: Base

module.exports = Developer
