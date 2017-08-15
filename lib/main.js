const {Disposable, Emitter, CompositeDisposable} = require("atom")

const Base = require("./base")
const globalState = require("./global-state")
const settings = require("./settings")
const VimState = require("./vim-state")

module.exports = {
  config: settings.config,

  getStatusBarManager() {
    if (!this.statusBarManager) this.statusBarManager = new (require("./status-bar-manager"))()
    return this.statusBarManager
  },

  getPaneUtils() {
    if (!this.paneUtils) this.paneUtils = new (require("./pane-utils"))()
    return this.paneUtils
  },

  activate() {
    this.emitter = new Emitter()
    settings.notifyDeprecatedParams()

    if (atom.inSpecMode()) settings.set("strictAssertion", true)

    this.subscriptions = new CompositeDisposable(
      ...Base.init(this.getEditorState),
      ...this.registerCommands(),
      this.registerVimStateCommands(),
      this.observeAndWarnVimMode(),
      atom.workspace.observeTextEditors(editor => {
        if (!editor.isMini()) {
          this.emitter.emit("did-add-vim-state", new VimState(editor, this.getStatusBarManager(), globalState))
        }
      }),
      atom.workspace.onDidChangeActivePaneItem(() => {
        this.demaximizePane()
        if (settings.get("automaticallyEscapeInsertModeOnActivePaneItemChange")) {
          VimState.forEach(vimState => {
            if (vimState.mode === "insert") vimState.activate("normal")
          })
        }
      }),
      atom.workspace.onDidStopChangingActivePaneItem(item => {
        if (!atom.workspace.isTextEditor(item)) {
          if (this.statusBarManager) this.statusBarManager.clear()
          return
        }
        if (item.isMini()) return

        // Still there is possibility editor is destroyed and don't have corresponding
        // vimState #196.
        const vimState = this.getEditorState(item)
        if (!vimState) return

        vimState.updateStatusBar()
        if (globalState.get("highlightSearchPattern") || vimState.__highlightSearch) {
          vimState.highlightSearch.refresh()
        }
      }),
      // Refresh highlight based on globalState.highlightSearchPattern changes.
      // -------------------------
      globalState.onDidChange(({name, newValue}) => {
        if (name !== "highlightSearchPattern") return
        if (newValue) {
          VimState.forEach(vimState => vimState.highlightSearch.refresh())
        } else {
          VimState.forEach(vimState => {
            // avoid populate prop unnecessarily on vimState.reset on startup
            if (vimState.__highlightSearch) vimState.highlightSearch.clearMarkers()
          })
        }
      }),
      settings.observe("highlightSearch", enabled => {
        globalState.set("highlightSearchPattern", enabled ? globalState.get("lastSearchPattern") : null)
      }),
      ...settings.observeConditionalKeymaps()
    )

    if (atom.inDevMode()) {
      this.developer = new (require("./developer"))()
      this.subscriptions.add(this.developer.init(this.getEditorState))
      if (settings.get("debug")) {
        this.developer.reportRequireCache({excludeNodModules: false})
      }
    }
  },

  observeAndWarnVimMode(fn) {
    const warn = () => {
      const message = [
        "## Message by vim-mode-plus: vim-mode detected!",
        "To use vim-mode-plus, you must **disable vim-mode** manually.",
      ].join("\n")

      atom.notifications.addWarning(message, {dismissable: true})
    }

    if (atom.packages.isPackageActive("vim-mode")) warn()
    return atom.packages.onDidActivatePackage(pack => {
      if (pack.name === "vim-mode") warn()
    })
  },

  // * `fn` {Function} to be called when vimState instance was created.
  //  Usage:
  //   onDidAddVimState (vimState) -> do something..
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidAddVimState(fn) {
    return this.emitter.on("did-add-vim-state", fn)
  },

  // * `fn` {Function} to be called with all current and future vimState
  //  Usage:
  //   observeVimStates (vimState) -> do something..
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  observeVimStates(fn) {
    VimState.forEach(fn)
    return this.onDidAddVimState(fn)
  },

  deactivate() {
    this.demaximizePane()
    if (this.demoModeSupport) this.demoModeSupport.destroy()

    this.subscriptions.dispose()
    VimState.forEach(vimState => vimState.destroy())
    VimState.clear()
  },

  registerCommands() {
    return [
      atom.commands.add("atom-text-editor:not([mini])", {
        "vim-mode-plus:clear-highlight-search": () => this.clearHighlightSearch(),
        "vim-mode-plus:toggle-highlight-search": () => this.toggleHighlightSearch(),
      }),
      atom.commands.add("atom-workspace", {
        "vim-mode-plus:maximize-pane": () => this.getPaneUtils().maximizePane(),
        "vim-mode-plus:maximize-pane-without-center": () => this.getPaneUtils().maximizePane(false),
        "vim-mode-plus:equalize-panes": () => this.getPaneUtils().equalizePanes(),
        "vim-mode-plus:exchange-pane": () => this.getPaneUtils().exchangePane(),
        "vim-mode-plus:move-pane-to-very-top": () => this.getPaneUtils().movePaneToVery("top"),
        "vim-mode-plus:move-pane-to-very-bottom": () => this.getPaneUtils().movePaneToVery("bottom"),
        "vim-mode-plus:move-pane-to-very-left": () => this.getPaneUtils().movePaneToVery("left"),
        "vim-mode-plus:move-pane-to-very-right": () => this.getPaneUtils().movePaneToVery("right"),
      }),
    ]
  },

  // atom-text-editor commands
  clearHighlightSearch() {
    globalState.set("highlightSearchPattern", null)
  },

  toggleHighlightSearch() {
    settings.toggle("highlightSearch")
  },

  demaximizePane() {
    if (this.paneUtils) this.paneUtils.demaximizePane()
  },

  registerVimStateCommands() {
    // all commands here is executed with context where 'this' bound to 'vimState'
    // prettier-ignore
    const commands = {
      "activate-normal-mode"() { this.activate("normal") },
      "activate-linewise-visual-mode"() { this.activate("visual", "linewise") },
      "activate-characterwise-visual-mode"() { this.activate("visual", "characterwise") },
      "activate-blockwise-visual-mode"() { this.activate("visual", "blockwise") },
      "reset-normal-mode"() { this.resetNormalMode({userInvocation: true}) },
      "clear-persistent-selections"() { this.clearPersistentSelections() },
      "set-register-name"() { this.register.setName() },
      "set-register-name-to-_"() { this.register.setName("_") },
      "set-register-name-to-*"() { this.register.setName("*") },
      "operator-modifier-characterwise"() { this.emitDidSetOperatorModifier({wise: "characterwise"}) },
      "operator-modifier-linewise"() { this.emitDidSetOperatorModifier({wise: "linewise"}) },
      "operator-modifier-occurrence"() { this.emitDidSetOperatorModifier({occurrence: true, occurrenceType: "base"}) },
      "operator-modifier-subword-occurrence"() { this.emitDidSetOperatorModifier({occurrence: true, occurrenceType: "subword"}) },
      repeat() { this.operationStack.runRecorded() },
      "repeat-find"() { this.operationStack.runCurrentFind() },
      "repeat-find-reverse"() { this.operationStack.runCurrentFind({reverse: true}) },
      "repeat-search"() { this.operationStack.runCurrentSearch() },
      "repeat-search-reverse"() { this.operationStack.runCurrentSearch({reverse: true}) },
      "set-count-0"() { this.setCount(0) },
      "set-count-1"() { this.setCount(1) },
      "set-count-2"() { this.setCount(2) },
      "set-count-3"() { this.setCount(3) },
      "set-count-4"() { this.setCount(4) },
      "set-count-5"() { this.setCount(5) },
      "set-count-6"() { this.setCount(6) },
      "set-count-7"() { this.setCount(7) },
      "set-count-8"() { this.setCount(8) },
      "set-count-9"() { this.setCount(9) },
    }

    for (let code = 32; code <= 126; code++) {
      const char = String.fromCharCode(code)
      const charForKeymap = char === " " ? "space" : char
      commands[`set-input-char-${charForKeymap}`] = function() {
        this.emitDidSetInputChar(char)
      }
    }

    const getEditorState = this.getEditorState.bind(this)

    function bindToVimState(commands) {
      const boundCommands = {}
      for (const name of Object.keys(commands)) {
        const fn = commands[name]
        boundCommands[`vim-mode-plus:${name}`] = function(event) {
          event.stopPropagation()
          const vimState = getEditorState(this.getModel())
          if (vimState) fn.call(vimState, event)
        }
      }
      return boundCommands
    }

    return atom.commands.add("atom-text-editor:not([mini])", bindToVimState(commands))
  },

  consumeStatusBar(statusBar) {
    const statusBarManager = this.getStatusBarManager()
    statusBarManager.initialize(statusBar)
    statusBarManager.attach()
    this.subscriptions.add(new Disposable(() => statusBarManager.detach()))
  },

  consumeDemoMode(demoModeService) {
    this.demoModeSupport = new (require("./demo-mode-support"))(demoModeService)
  },

  // Service API
  // -------------------------
  getGlobalState() {
    return globalState
  },

  getEditorState(editor) {
    return VimState.getByEditor(editor)
  },

  provideVimModePlus() {
    return {
      Base: Base,
      registerCommandFromSpec: Base.registerCommandFromSpec,
      getGlobalState: this.getGlobalState,
      getEditorState: this.getEditorState,
      observeVimStates: this.observeVimStates.bind(this),
      onDidAddVimState: this.onDidAddVimState.bind(this),
    }
  },
}
