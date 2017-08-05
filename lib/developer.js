const {Emitter, Disposable, BufferedProcess, CompositeDisposable} = require("atom")

const Base = require("./base")
const settings = require("./settings")
let getEditorState
const OPERATION_KINDS = ["Operator", "Motion", "TextObject", "InsertMode", "MiscCommand", "Scroll"]

// Borrowed from underscore-plus
const ModifierKeyMap = {
  "ctrl-cmd-": "\u2303\u2318",
  "cmd-": "\u2318",
  "ctrl-": "\u2303",
  alt: "\u2325",
  option: "\u2325",
  enter: "\u23ce",
  left: "\u2190",
  right: "\u2192",
  up: "\u2191",
  down: "\u2193",
  backspace: "BS",
  space: "SPC",
}

const SelectorMap = {
  "atom-text-editor.vim-mode-plus": "",
  ".normal-mode": "n",
  ".insert-mode": "i",
  ".replace": "R",
  ".visual-mode": "v",
  ".characterwise": "C",
  ".blockwise": "B",
  ".linewise": "L",
  ".operator-pending-mode": "o",
  ".with-count": "#",
  ".has-persistent-selection": "%",
}

module.exports = class Developer {
  init(_getEditorState) {
    getEditorState = _getEditorState

    const commands = {
      "toggle-debug": () => this.toggleDebug(),
      "open-in-vim": () => this.openInVim(),
      "generate-command-summary-table": () => this.generateCommandSummaryTable(),
      "write-command-table-on-disk"() {
        Base.writeCommandTableOnDisk()
      },
      "clear-debug-output": () => this.clearDebugOutput(),
      reload: () => this.reload(),
      "reload-with-dependencies": () => this.reload(true),
      "report-total-marker-count": () => this.reportTotalMarkerCount(),
      "report-total-and-per-editor-marker-count": () => this.reportTotalMarkerCount(true),
      "report-require-cache": () => this.reportRequireCache({excludeNodModules: true}),
      "report-require-cache-all": () => this.reportRequireCache({excludeNodModules: false}),
    }

    const subscriptions = new CompositeDisposable()
    const addCommand = (name, fn) => atom.commands.add("atom-text-editor", `vim-mode-plus:${name}`, fn)
    subscriptions.add(...Object.keys(commands).map(name => addCommand(name, commands[name])))
    return subscriptions
  }

  reportRequireCache({focus, excludeNodModules}) {
    const path = require("path")
    const packPath = atom.packages.getLoadedPackage("vim-mode-plus").path
    const cachedPaths = Object.keys(require.cache)
      .filter(p => p.startsWith(packPath + path.sep))
      .map(p => p.replace(packPath, ""))

    for (const cachedPath of cachedPaths) {
      if (excludeNodModules && cachedPath.search(/node_modules/) >= 0) {
        continue
      }
      if (focus && cachedPath.search(new RegExp(`${focus}`)) >= 0) {
        cachedPath = `*${cachedPath}`
      }
      console.log(cachedPath)
    }
  }

  reportTotalMarkerCount(showEditorsReport = false) {
    const {inspect} = require("util")
    const {basename} = require("path")
    const total = {
      mark: 0,
      hlsearch: 0,
      mutation: 0,
      occurrence: 0,
      persistentSel: 0,
    }

    for (const editor of atom.workspace.getTextEditors()) {
      const vimState = getEditorState(editor)
      const mark = vimState.mark.markerLayer.getMarkerCount()
      const hlsearch = vimState.highlightSearch.markerLayer.getMarkerCount()
      const mutation = vimState.mutationManager.markerLayer.getMarkerCount()
      const occurrence = vimState.occurrenceManager.markerLayer.getMarkerCount()
      const persistentSel = vimState.persistentSelection.markerLayer.getMarkerCount()
      if (showEditorsReport) {
        console.log(basename(editor.getPath()), inspect({mark, hlsearch, mutation, occurrence, persistentSel}))
      }

      total.mark += mark
      total.hlsearch += hlsearch
      total.mutation += mutation
      total.occurrence += occurrence
      total.persistentSel += persistentSel
    }

    return console.log("total", inspect(total))
  }

  reload(reloadDependencies) {
    function deleteRequireCacheForPathPrefix(prefix) {
      Object.keys(require.cache).filter(p => p.startsWith(prefix)).forEach(p => delete require.cache[p])
    }

    const packagesNeedReload = ["vim-mode-plus"]
    if (reloadDependencies) packagesNeedReload.push(...settings.get("devReloadPackages"))

    const loadedPackages = packagesNeedReload.filter(packName => atom.packages.isPackageLoaded(packName))
    console.log("reload", loadedPackages)

    const pathSeparator = require("path").sep

    loadedPackages.forEach(packName => {
      console.log(`- deactivating ${packName}`)
      const packPath = atom.packages.getLoadedPackage(packName).path
      atom.packages.deactivatePackage(packName)
      atom.packages.unloadPackage(packName)
      deleteRequireCacheForPathPrefix(packPath + pathSeparator)
    })

    console.time("activate")

    loadedPackages.forEach(packName => {
      console.log(`+ activating ${packName}`)
      atom.packages.loadPackage(packName)
      atom.packages.activatePackage(packName)
    })

    console.timeEnd("activate")
  }

  clearDebugOutput(name, fn) {
    const {normalize} = require("fs-plus")
    const filePath = normalize(settings.get("debugOutputFilePath"))
    const options = {searchAllPanes: true, activatePane: false}
    atom.workspace.open(filePath, {searchAllPanes: true, activatePane: false}).then(editor => {
      editor.setText("")
      editor.save()
    })
  }

  toggleDebug() {
    settings.set("debug", !settings.get("debug"))
    console.log(`${settings.scope} debug:`, settings.get("debug"))
  }

  getCommandSpecs() {
    const _ = require("underscore-plus")
    const {getKeyBindingForCommand, getAncestors} = require("./utils")

    const registry = Base.getClassRegistry()
    return Object.keys(registry)
      .filter(name => registry[name].isCommand())
      .map(name => commandSpecForClass(registry[name]))

    function compactSelector(selector) {
      const regex = new RegExp(`(${_.keys(SelectorMap).map(_.escapeRegExp).join("|")})`, "g")
      return selector
        .split(/,\s*/g)
        .map(scope => scope.replace(/:not\((.*?)\)/g, "!$1").replace(regex, s => SelectorMap[s]))
        .join(",")
    }

    function compactKeystrokes(keystrokes) {
      const specialChars = "\\`*_{}[]()#+-.!"
      const specialCharsRegexp = new RegExp(`${specialChars.split("").map(_.escapeRegExp).join("|")}`, "g")
      const modifierKeyRegexp = new RegExp(`(${_.keys(ModifierKeyMap).map(_.escapeRegExp).join("|")})`)
      return (
        keystrokes
          // .replace(/(`|_)/g, '\\$1')
          .replace(modifierKeyRegexp, s => ModifierKeyMap[s])
          .replace(new RegExp(`(${specialCharsRegexp})`, "g"), "\\$1")
          .replace(/\|/g, "&#124;")
          .replace(/\s+/, "")
      )
    }

    function commandSpecForClass(klass) {
      const name = klass.name
      const ancestors = getAncestors(klass)
      ancestors.pop()
      const kind = ancestors.pop().name
      const commandName = klass.getCommandName()
      const description = klass.getDesctiption() ? klass.getDesctiption().replace(/\n/g, "<br/>") : undefined

      const keymaps = getKeyBindingForCommand(commandName, {packageName: "vim-mode-plus"})
      const keymap = keymaps
        ? keymaps
            .map(k => `\`${compactSelector(k.selector)}\` <code>${compactKeystrokes(k.keystrokes)}</code>`)
            .join("<br/>")
        : undefined

      return {name, commandName, kind, description, keymap}
    }
  }

  generateSummaryTableForCommandSpecs(specs, {header} = {}) {
    const _ = require("underscore-plus")

    const grouped = _.groupBy(specs, "kind")
    let result = ""
    for (let kind of OPERATION_KINDS) {
      const specs = grouped[kind]
      if (!specs) continue
      const report = [`## ${kind}`, "", "| Keymap | Command | Description |", "|:-------|:--------|:------------|"]

      for (let {keymap = "", commandName, description = ""} of specs) {
        commandName = commandName.replace(/vim-mode-plus:/, "")
        report.push(`| ${keymap} | \`${commandName}\` | ${description} |`)
      }
      result += report.join("\n") + "\n\n"
    }

    atom.workspace.open().then(editor => {
      if (header) editor.insertText(header + "\n")
      editor.insertText(result)
    })
  }

  generateCommandSummaryTable() {
    const {removeIndent} = require("./utils")
    const header = removeIndent(`
      ## Keymap selector abbreviations

      In this document, following abbreviations are used for shortness.

      | Abbrev | Selector                     | Description                         |
      |:-------|:-----------------------------|:------------------------------------|
      | \`!i\`   | \`:not(.insert-mode)\`         | except insert-mode                  |
      | \`i\`    | \`.insert-mode\`               |                                     |
      | \`o\`    | \`.operator-pending-mode\`     |                                     |
      | \`n\`    | \`.normal-mode\`               |                                     |
      | \`v\`    | \`.visual-mode\`               |                                     |
      | \`vB\`   | \`.visual-mode.blockwise\`     |                                     |
      | \`vL\`   | \`.visual-mode.linewise\`      |                                     |
      | \`vC\`   | \`.visual-mode.characterwise\` |                                     |
      | \`iR\`   | \`.insert-mode.replace\`       |                                     |
      | \`#\`    | \`.with-count\`                | when count is specified             |
      | \`%\`    | \`.has-persistent-selection\`  | when persistent-selection is exists |
      `)

    this.generateSummaryTableForCommandSpecs(this.getCommandSpecs(), {header})
  }

  openInVim() {
    const editor = atom.workspace.getActiveTextEditor()
    const {row, column} = editor.getCursorBufferPosition()
    // e.g. /Applications/MacVim.app/Contents/MacOS/Vim -g /etc/hosts "+call cursor(4, 3)"
    new BufferedProcess({
      command: "/Applications/MacVim.app/Contents/MacOS/Vim",
      args: ["-g", editor.getPath(), `+call cursor(${row + 1}, ${column + 1})`],
    })
  }
}
