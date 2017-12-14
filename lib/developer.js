"use babel"

const {Emitter, Disposable, BufferedProcess, CompositeDisposable} = require("atom")

const settings = require("./settings")
const VimState = require("./vim-state")

// NOTE: changing order affects output of lib/json/command-table.json
const VMPOperationFiles = [
  "./operator",
  "./operator-insert",
  "./operator-transform-string",
  "./motion",
  "./motion-search",
  "./text-object",
  "./misc-command",
]

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
      "vim-mode-plus:write-command-table-and-file-table-to-disk": () => this.writeCommandTableAndFileTableToDisk(),
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

    for (let cachedPath of cachedPaths) {
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

  async reload(reloadDependencies) {
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

    for (const packName of loadedPackages) {
      console.log(`- deactivating ${packName}`)
      const packPath = atom.packages.getLoadedPackage(packName).path
      await atom.packages.deactivatePackage(packName)
      atom.packages.unloadPackage(packName)
      deleteRequireCacheForPathPrefix(packPath + pathSeparator)
    }
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
    const {escapeRegExp} = require("underscore-plus")
    const {getKeyBindingForCommand} = require("./utils")

    const specs = []
    for (const file of VMPOperationFiles) {
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
      const sources = Object.keys(SelectorMap).map(escapeRegExp)
      const regex = new RegExp(`(${sources.join("|")})`, "g")
      return selector
        .split(/,\s*/g)
        .map(scope => scope.replace(/:not\((.*?)\)/g, "!$1").replace(regex, s => SelectorMap[s]))
        .join(",")
    }

    function compactKeystrokes(keystrokes) {
      const specialChars = "\\`*_{}[]()#+-.!"

      const modifierKeyRegexSources = Object.keys(ModifierKeyMap).map(escapeRegExp)
      const modifierKeyRegex = new RegExp(`(${modifierKeyRegexSources.join("|")})`)
      const specialCharsRegexSources = specialChars.split("").map(escapeRegExp)
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
    const grouped = {}
    for (const spec of specs) grouped[spec.kind] = spec

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

  buildCommandTableAndFileTable() {
    const fileTable = {}
    const commandTable = []
    const seen = {} // Just to detect duplicate name

    for (const file of VMPOperationFiles) {
      fileTable[file] = []

      for (const klass of Object.values(require(file))) {
        if (seen[klass.name]) {
          throw new Error(`Duplicate class ${klass.name} in "${file}" and "${seen[klass.name]}"`)
        }
        seen[klass.name] = file
        fileTable[file].push(klass.name)
        if (klass.isCommand()) commandTable.push(klass.getCommandName())
      }
    }
    return {commandTable, fileTable}
  }

  // # How vmp commands become available?
  // #========================================
  // Vmp have many commands, loading full commands at startup slow down pkg activation.
  // So vmp load summary command table at startup then lazy require command body on-use timing.
  // Here is how vmp commands are registerd and invoked.
  // Initially introduced in PR #758
  //
  // 1. [On dev]: Preparation done by developer
  //   - Invoking `Vim Mode Plus:Write Command Table And File Table To Disk`. it does following.
  //   - "./json/command-table.json" and "./json/file-table.json". are updated.
  //
  // 2. [On atom/vmp startup]
  //   - Register commands(e.g. `move-down`) from "./json/command-table.json".
  //
  // 3. [On run time]: e.g. Invoke `move-down` by `j` keystroke
  //   - Fire `move-down` command.
  //   - It execute `vimState.operationStack.run("MoveDown")`
  //   - Determine files to require from "./json/file-table.json".
  //   - Load `MoveDown` class by require('./motions') and run it!
  //
  async writeCommandTableAndFileTableToDisk() {
    const fs = require("fs-plus")
    const path = require("path")

    const {commandTable, fileTable} = this.buildCommandTableAndFileTable()

    const getStateFor = (baseName, object, pretty) => {
      const filePath = path.join(__dirname, "json", baseName) + (pretty ? "-pretty.json" : ".json")
      const jsonString = pretty ? JSON.stringify(object, null, "  ") : JSON.stringify(object)
      const needUpdate = fs.readFileSync(filePath, "utf8").trimRight() !== jsonString
      return {filePath, jsonString, needUpdate}
    }

    const statesNeedUpdate = [
      getStateFor("command-table", commandTable, false),
      getStateFor("command-table", commandTable, true),
      getStateFor("file-table", fileTable, false),
      getStateFor("file-table", fileTable, true),
    ].filter(state => state.needUpdate)

    if (!statesNeedUpdate.length) {
      atom.notifications.addInfo("No changfes in commandTable and fileTable", {dismissable: true})
      return
    }

    for (const {jsonString, filePath} of statesNeedUpdate) {
      await atom.workspace.open(filePath, {activatePane: false, activateItem: false}).then(editor => {
        editor.setText(jsonString)
        return editor.save().then(() => {
          atom.notifications.addInfo(`Updated ${path.basename(filePath)}`, {dismissable: true})
        })
      })
    }
  }
}

module.exports = new Developer()
