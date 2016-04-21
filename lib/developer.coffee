_ = require 'underscore-plus'
path = require 'path'
{Emitter, Disposable, BufferedProcess, CompositeDisposable} = require 'atom'

Base = require './base'
{generateIntrospectionReport} = require './introspection'
settings = require './settings'
{debug, getParent, getAncestors, getKeyBindingForCommand} = require './utils'

packageScope = 'vim-mode-plus'
getEditorState = null

class Developer
  init: (service) ->
    {getEditorState} = service
    @devEnvironmentByBuffer = new Map
    @reloadSubscriptionByBuffer = new Map

    commands =
      'toggle-debug': => @toggleDebug()

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

  # Borrowed from underscore-plus
  modifierKeyMap =
    cmd: '\u2318'
    "ctrl-": '\u2303'
    alt: '\u2325'
    option: '\u2325'
    enter: '\u23ce'
    left: '\u2190'
    right: '\u2192'
    up: '\u2191'
    down: '\u2193'
    backspace: 'BS'
    space: 'SPC'

  selectorMap =
    "atom-text-editor.vim-mode-plus": ''
    ".normal-mode": 'n'
    ".insert-mode": 'i'
    ".replace": 'R'
    ".visual-mode": 'v'
    ".characterwise": 'C'
    ".blockwise": 'B'
    ".linewise": 'L'
    ".operator-pending-mode": 'o'
    ".with-count": '#'

  getCommandSpecs: ->
    compactSelector = (selector) ->
      pattern = ///(#{_.keys(selectorMap).map(_.escapeRegExp).join('|')})///g
      selector.split(/,\s*/g).map (scope) ->
        scope
          .replace(/:not\((.*)\)/, '!$1')
          .replace(pattern, (s) -> selectorMap[s])
      .join(",")

    compactKeystrokes = (keystrokes) ->
      pattern = ///(#{_.keys(modifierKeyMap).map(_.escapeRegExp).join('|')})///
      keystrokes
        .replace(/(`|_)/g, '\\$1')
        .replace(pattern, (s) -> modifierKeyMap[s])
        .replace(/\s+/, '')

    commands = (
      for name, klass of Base.getRegistries() when klass.isCommand()
        kind = getAncestors(klass).map((k) -> k.name)[-2..-2][0]
        commandName = klass.getCommandName()
        description = klass.getDesctiption()?.replace(/\n/g, '<br/>')

        keymap = null
        if keymaps = getKeyBindingForCommand(commandName, packageName: "vim-mode-plus")
          keymap = keymaps.map ({keystrokes, selector}) ->
            "`#{compactSelector(selector)}` <kbd>#{compactKeystrokes(keystrokes)}</kbd>"
          .join("<br/>")

        {name, commandName, kind, description, keymap}
    )
    commands

  kinds = ["Operator", "Motion", "TextObject", "InsertMode", "MiscCommand", "Scroll", "VisualBlockwise"]
  generateSummaryTableForCommandSpecs: (specs, {header}={}) ->
    grouped = _.groupBy(specs, 'kind')
    str = ""
    for kind in kinds when specs = grouped[kind]

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
    # Keymap selector abbreviations

    In this document, following abbreviations are used for shortness.

    | Abbrev | Selector                     | Description             |
    |:-------|:-----------------------------|:------------------------|
    | `!i`   | `:not(.insert-mode)`         | except insert-mode      |
    | `i`    | `.insert-mode`               |                         |
    | `o`    | `.operator-pending-mode`     |                         |
    | `n`    | `.normal-mode`               |                         |
    | `v`    | `.visual-mode`               |                         |
    | `vB`   | `.visual-mode.blockwise`     |                         |
    | `vL`   | `.visual-mode.linewise`      |                         |
    | `vC`   | `.visual-mode.characterwise` |                         |
    | `iR`   | `.insert-mode.replace`       |                         |
    | `#`    | `.with-count`                | when count is specified |

    """
    @generateSummaryTableForCommandSpecs(@getCommandSpecs(), {header})

  generateCommandSummaryTableForCommandsHaveNoDefaultKeymap: ->
    commands = @getCommandSpecs().filter (command) -> not getKeyBindingForCommand(command.commandName, packageName: 'vim-mode-plus')
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
        'run'
        'getCommandNameWithoutPrefix'
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
