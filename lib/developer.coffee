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

getParent = (obj) ->
  obj.__super__?.constructor

getAncestors = (obj) ->
  ancestors = []
  ancestors.push (current=obj)
  while current = getParent(current)
    ancestors.push current
  ancestors

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
      'generate-command-summary-table-for-commands-have-no-default-keymap': =>
        @generateCommandSummaryTableForCommandsHaveNoDefaultKeymap()
      'generate-command-summary-table': =>
        @generateCommandSummaryTable()
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

  getCommandSpecs: ->
    compactSelector = (selector) ->
      selector.split(/,\s*/g).map (scope) ->
        scope
          .replace(/atom-text-editor\.vim-mode-plus/, '')
          .replace(/:not\((.*)\)/, '!$1')
          .replace(/\.normal-mode/, 'n')
          .replace(/\.visual-mode\.blockwise/, 'vB')
          .replace(/\.visual-mode\.linewise/, 'vL')
          .replace(/\.visual-mode\.characterwise/, 'vC')
          .replace(/\.visual-mode/, 'v')
          .replace(/\.insert-mode\.replace/, 'iR')
          .replace(/\.insert-mode/, 'i')
          .replace(/\.operator-pending-mode/, 'o')
      .join(",")

    modifierKeyMap =
      cmd: '\u2318'
      ctrl: '\u2303'
      alt: '\u2325'
      option: '\u2325'
      shift: '\u21e7'
      enter: '\u23ce'
      left: '\u2190'
      right: '\u2192'
      up: '\u2191'
      down: '\u2193'

    compactKeystrokes = (keystrokes) ->
      keystrokes
        .replace(/(`|_)/g, '\\$1')
        .replace(/ctrl-/, modifierKeyMap["ctrl"])
        .replace(/down|up|left|right|enter|cmd|option/, (s) -> modifierKeyMap[s])
        .replace('backspace', 'BS')
        .replace('space', 'SPC')
        .replace(/\s+/, '')

    commands = (
      for name, klass of Base.getRegistries() when klass.isCommand()
        kind = getAncestors(klass).map((k) -> k.name)[-2..-2][0]
        commandName = klass.getCommandName()
        description = klass.getDesctiption()

        keymap = null
        if keymaps = getKeyBindingForCommand(commandName)
          keymap = keymaps.map ({keystrokes, selector}) ->
            "`#{compactSelector(selector)}` <kbd>#{compactKeystrokes(keystrokes)}</kbd>"
          .join("<br/>")

        # keystrokes<kbd>#{keystrokes}</kbd>"

        {name, commandName, kind, description, keymap}
    )
    commands

  kinds = ["Operator", "Motion", "TextObject", "InsertMode", "Misc", "Scroll", "VisualBlockwise"]
  generateSummaryTableForCommandSpecs: (specs, {header}={}) ->
    grouped = _.groupBy(specs, 'kind')
    str = ""
    for kind in kinds
      specs = grouped[kind]

      report = [
        "## #{kind}"
        ""
        "| Keymap | Command | Description |"
        "|:-------|:--------|:------------|"
      ]
      for {keymap, commandName, description} in specs
        commandName = commandName.replace(/vim-mode-plus:/, '')
        description ?= ""
        keymap ?= ""
        report.push "| #{keymap} | `#{commandName}` | #{description} |"
      str += report.join("\n") + "\n\n"

    atom.workspace.open().then (editor) ->
      editor.insertText(header + "\n") if header?
      editor.insertText(str)

  generateCommandSummaryTable: ->
    header = """
    # Description

    - `!i`: :not(.insert-mode)
    - `i`: insert-mode
    - `o`: operator-pending-mode
    - `n`: normal-mode
    - `v`: visual-mode
    - `vB`: visual-mode.blockwise
    - `vL`: visual-mode.linewise
    - `vC`: visual-mode.characterwise
    - `iR`: insert-mode.replace

    """
    @generateSummaryTableForCommandSpecs(@getCommandSpecs(), {header})

  generateCommandSummaryTableForCommandsHaveNoDefaultKeymap: ->
    commands = @getCommandSpecs().filter (command) -> not getKeyBindingForCommand(command.commandName)
    @generateSummaryTableForCommandSpecs(commands)

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
        'getDesctiption', 'description'
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
