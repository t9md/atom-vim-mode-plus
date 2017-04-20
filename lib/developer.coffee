{Emitter, Disposable, BufferedProcess, CompositeDisposable} = require 'atom'

Base = require './base'
settings = require './settings'
getEditorState = null

class Developer
  init: (_getEditorState) ->
    getEditorState = _getEditorState
    @devEnvironmentByBuffer = new Map
    @reloadSubscriptionByBuffer = new Map

    commands =
      'toggle-debug': => @toggleDebug()
      'open-in-vim': => @openInVim()
      'generate-introspection-report': => @generateIntrospectionReport()
      'generate-command-summary-table': => @generateCommandSummaryTable()
      'write-command-table-on-disk': -> Base.writeCommandTableOnDisk()
      'clear-debug-output': => @clearDebugOutput()
      'reload': => @reload()
      'reload-with-dependencies': => @reload(true)
      'report-total-marker-count': => @getAllMarkerCount()
      'report-total-and-per-editor-marker-count': => @getAllMarkerCount(true)
      'report-require-cache': => @reportRequireCache(excludeNodModules: true)
      'report-require-cache-all': => @reportRequireCache(excludeNodModules: false)

    subscriptions = new CompositeDisposable
    for name, fn of commands
      subscriptions.add @addCommand(name, fn)
    subscriptions

  reportRequireCache: ({focus, excludeNodModules}) ->
    pathSeparator = require('path').sep
    packPath = atom.packages.getLoadedPackage("vim-mode-plus").path
    cachedPaths = Object.keys(require.cache)
      .filter (p) -> p.startsWith(packPath + pathSeparator)
      .map (p) -> p.replace(packPath, '')

    for cachedPath in cachedPaths
      if excludeNodModules and cachedPath.search(/node_modules/) >= 0
        continue
      if focus and cachedPath.search(///#{focus}///) >= 0
        cachedPath = '*' + cachedPath
      console.log cachedPath

  getAllMarkerCount: (showEditorsReport=false) ->
    {inspect} = require 'util'
    basename = require('path').basename
    total =
      mark: 0
      hlsearch: 0
      mutation: 0
      occurrence: 0
      persistentSel: 0

    for editor in atom.workspace.getTextEditors()
      vimState = getEditorState(editor)
      mark = vimState.mark.markerLayer.getMarkerCount()
      hlsearch = vimState.highlightSearch.markerLayer.getMarkerCount()
      mutation = vimState.mutationManager.markerLayer.getMarkerCount()
      occurrence = vimState.occurrenceManager.markerLayer.getMarkerCount()
      persistentSel = vimState.persistentSelection.markerLayer.getMarkerCount()
      if showEditorsReport
        console.log basename(editor.getPath()), inspect({mark, hlsearch, mutation, occurrence, persistentSel})

      total.mark += mark
      total.hlsearch += hlsearch
      total.mutation += mutation
      total.occurrence += occurrence
      total.persistentSel += persistentSel

    console.log 'total', inspect(total)

  reload: (reloadDependencies) ->
    pathSeparator = require('path').sep

    packages = ['vim-mode-plus']
    if reloadDependencies
      packages.push(settings.get('devReloadPackages')...)

    invalidateRequireCacheForPackage = (packPath) ->
      Object.keys(require.cache)
        .filter (p) -> p.startsWith(packPath + pathSeparator)
        .forEach (p) -> delete require.cache[p]

    deactivate = (packName) ->
      console.log "- deactivating #{packName}"
      packPath = atom.packages.getLoadedPackage(packName).path
      atom.packages.deactivatePackage(packName)
      atom.packages.unloadPackage(packName)
      invalidateRequireCacheForPackage(packPath)

    activate = (packName) ->
      console.log "+ activating #{packName}"
      atom.packages.loadPackage(packName)
      atom.packages.activatePackage(packName)

    loadedPackages = packages.filter (packName) -> atom.packages.getLoadedPackages(packName)
    console.log "reload", loadedPackages
    loadedPackages.map(deactivate)
    console.time('activate')
    loadedPackages.map(activate)
    console.timeEnd('activate')

  addCommand: (name, fn) ->
    atom.commands.add('atom-text-editor', "vim-mode-plus:#{name}", fn)

  clearDebugOutput: (name, fn) ->
    {normalize} = require('fs-plus')
    filePath = normalize(settings.get('debugOutputFilePath'))
    options = {searchAllPanes: true, activatePane: false}
    atom.workspace.open(filePath, options).then (editor) ->
      editor.setText('')
      editor.save()

  toggleDebug: ->
    settings.set('debug', not settings.get('debug'))
    console.log "#{settings.scope} debug:", settings.get('debug')

  # Borrowed from underscore-plus
  modifierKeyMap =
    "ctrl-cmd-": '\u2303\u2318'
    "cmd-": '\u2318'
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
    ".has-persistent-selection": '%'

  getCommandSpecs: ->
    _ = require 'underscore-plus'

    compactSelector = (selector) ->
      pattern = ///(#{_.keys(selectorMap).map(_.escapeRegExp).join('|')})///g
      selector.split(/,\s*/g).map (scope) ->
        scope
          .replace(/:not\((.*)\)/, '!$1')
          .replace(pattern, (s) -> selectorMap[s])
      .join(",")

    compactKeystrokes = (keystrokes) ->
      specialChars = '\\`*_{}[]()#+-.!'
      specialCharsRegexp = ///#{specialChars.split('').map(_.escapeRegExp).join('|')}///g
      modifierKeyRegexp = ///(#{_.keys(modifierKeyMap).map(_.escapeRegExp).join('|')})///
      keystrokes
        # .replace(/(`|_)/g, '\\$1')
        .replace(modifierKeyRegexp, (s) -> modifierKeyMap[s])
        .replace(///(#{specialCharsRegexp})///g, "\\$1")
        .replace(/\|/g, '&#124;')
        .replace(/\s+/, '')

    {getKeyBindingForCommand, getAncestors} = @vimstate.utils
    commands = (
      for name, klass of Base.getClassRegistry() when klass.isCommand()
        kind = getAncestors(klass).map((k) -> k.name)[-2..-2][0]
        commandName = klass.getCommandName()
        description = klass.getDesctiption()?.replace(/\n/g, '<br/>')

        keymap = null
        if keymaps = getKeyBindingForCommand(commandName, packageName: "vim-mode-plus")
          keymap = keymaps.map ({keystrokes, selector}) ->
            "`#{compactSelector(selector)}` <code>#{compactKeystrokes(keystrokes)}</code>"
          .join("<br/>")

        {name, commandName, kind, description, keymap}
    )
    commands

  generateCommandTableForMotion: ->
    require('./motion')


  kinds = ["Operator", "Motion", "TextObject", "InsertMode", "MiscCommand", "Scroll"]
  generateSummaryTableForCommandSpecs: (specs, {header}={}) ->
    _ = require 'underscore-plus'

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
    ## Keymap selector abbreviations

    In this document, following abbreviations are used for shortness.

    | Abbrev | Selector                     | Description                         |
    |:-------|:-----------------------------|:------------------------------------|
    | `!i`   | `:not(.insert-mode)`         | except insert-mode                  |
    | `i`    | `.insert-mode`               |                                     |
    | `o`    | `.operator-pending-mode`     |                                     |
    | `n`    | `.normal-mode`               |                                     |
    | `v`    | `.visual-mode`               |                                     |
    | `vB`   | `.visual-mode.blockwise`     |                                     |
    | `vL`   | `.visual-mode.linewise`      |                                     |
    | `vC`   | `.visual-mode.characterwise` |                                     |
    | `iR`   | `.insert-mode.replace`       |                                     |
    | `#`    | `.with-count`                | when count is specified             |
    | `%`    | `.has-persistent-selection` | when persistent-selection is exists |

    """
    @generateSummaryTableForCommandSpecs(@getCommandSpecs(), {header})

  openInVim: ->
    editor = atom.workspace.getActiveTextEditor()
    {row, column} = editor.getCursorBufferPosition()
    # e.g. /Applications/MacVim.app/Contents/MacOS/Vim -g /etc/hosts "+call cursor(4, 3)"
    new BufferedProcess
      command: "/Applications/MacVim.app/Contents/MacOS/Vim"
      args: ['-g', editor.getPath(), "+call cursor(#{row+1}, #{column+1})"]

  generateIntrospectionReport: ->
    _ = require 'underscore-plus'
    generateIntrospectionReport = require './introspection'

    generateIntrospectionReport _.values(Base.getClassRegistry()),
      excludeProperties: [
        'run'
        'getCommandNameWithoutPrefix'
        'getClass', 'extend', 'getParent', 'getAncestors', 'isCommand'
        'getClassRegistry', 'command', 'reset'
        'getDesctiption', 'description'
        'init', 'getCommandName', 'getCommandScope', 'registerCommand',
        'delegatesProperties', 'subscriptions', 'commandPrefix', 'commandScope'
        'delegatesMethods',
        'delegatesProperty',
        'delegatesMethod',
      ]
      recursiveInspect: Base

module.exports = Developer
