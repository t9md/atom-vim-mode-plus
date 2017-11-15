const {Emitter, Disposable, BufferedProcess, CompositeDisposable} = require("atom")

const Base = require("./base")
const settings = require("./settings")
const VimState = require("./vim-state")

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

class Developer {
  init() {
    return atom.commands.add("atom-text-editor", {
      "vim-mode-plus:toggle-debug": () => this.toggleDebug(),
      "vim-mode-plus:open-in-vim": () => this.openInVim(),
      "vim-mode-plus:generate-command-summary-table": () => this.generateCommandSummaryTable(),
      "vim-mode-plus:write-command-table-and-file-table-to-disk": () => Base.writeCommandTableAndFileTableToDisk(),
      "vim-mode-plus:set-global-vim-state": () => this.setGlobalVimState(),
      "vim-mode-plus:clear-debug-output": () => this.clearDebugOutput(),
      "vim-mode-plus:reload": () => this.reload(),
      "vim-mode-plus:reload-with-dependencies": () => this.reload(true),
      "vim-mode-plus:report-total-marker-count": () => this.reportTotalMarkerCount(),
      "vim-mode-plus:report-total-and-per-editor-marker-count": () => this.reportTotalMarkerCount(true),
      "vim-mode-plus:report-require-cache": () => this.reportRequireCache({excludeNodModules: true}),
      "vim-mode-plus:report-require-cache-all": () => this.reportRequireCache({excludeNodModules: false}),
    })
  }

  setGlobalVimState() {
    global.vimState = VimState.get(atom.workspace.getActiveTextEditor())
    console.log("set global.vimState for debug", global.vimState)
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
      const vimState = VimState.get(editor)
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
      Object.keys(require.cache)
        .filter(p => p.startsWith(prefix))
        .forEach(p => delete require.cache[p])
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
    const {getKeyBindingForCommand} = require("./utils")

    const filesToLoad = [
      "./operator",
      "./operator-insert",
      "./operator-transform-string",
      "./motion",
      "./motion-search",
      "./text-object",
      "./misc-command",
    ]

    const specs = []
    for (const file of filesToLoad) {
      for (const klass of Object.values(require(file))) {
        if (!klass.isCommand()) continue

        const commandName = klass.getCommandName()

        const keymaps = getKeyBindingForCommand(commandName, {packageName: "vim-mode-plus"})
        const keymap = keymaps
          ? keymaps
              .map(k => `\`${compactSelector(k.selector)}\` <code>${compactKeystrokes(k.keystrokes)}</code>`)
              .join("<br/>")
          : undefined

        specs.push({
          name: klass.name,
          commandName: commandName,
          kind: klass.operationKind,
          keymap: keymap,
        })
      }
    }

    return specs

    function compactSelector(selector) {
      const sources = _.keys(SelectorMap).map(_.escapeRegExp)
      const regex = new RegExp(`(${sources.join("|")})`, "g")
      return selector
        .split(/,\s*/g)
        .map(scope => scope.replace(/:not\((.*?)\)/g, "!$1").replace(regex, s => SelectorMap[s]))
        .join(",")
    }

    function compactKeystrokes(keystrokes) {
      const specialChars = "\\`*_{}[]()#+-.!"

      const modifierKeyRegexSources = _.keys(ModifierKeyMap).map(_.escapeRegExp)
      const modifierKeyRegex = new RegExp(`(${modifierKeyRegexSources.join("|")})`)
      const specialCharsRegexSources = specialChars.split("").map(_.escapeRegExp)
      const specialCharsRegex = new RegExp(`(${specialCharsRegexSources.join("|")})`, "g")

      return (
        keystrokes
          // .replace(/(`|_)/g, '\\$1')
          .replace(modifierKeyRegex, s => ModifierKeyMap[s])
          .replace(specialCharsRegex, "\\$1")
          .replace(/\|/g, "&#124;")
          .replace(/\s+/, "")
      )
    }
  }

  generateSummaryTableForCommandSpecs(specs, {header} = {}) {
    const _ = require("underscore-plus")

    const grouped = _.groupBy(specs, "kind")
    let result = ""
    const OPERATION_KINDS = ["operator", "motion", "text-object", "misc-command"]

    for (let kind of OPERATION_KINDS) {
      const specs = grouped[kind]
      if (!specs) continue

      // prettier-ignore
      const table = [
        "| Keymap | Command | Description |",
        "|:-------|:--------|:------------|",
      ]

      for (let {keymap = "", commandName, description = ""} of specs) {
        commandName = commandName.replace(/vim-mode-plus:/, "")
        table.push(`| ${keymap} | \`${commandName}\` | ${description} |`)
      }
      result += `## ${kind}\n\n` + table.join("\n") + "\n\n"
    }

    atom.workspace.open().then(editor => {
      if (header) editor.insertText(header + "\n\n")
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
module.exports = new Developer()
