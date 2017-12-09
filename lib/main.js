const {Disposable, Emitter, CompositeDisposable} = require("atom")
const classify = s => s[0].toUpperCase() + s.slice(1).replace(/-(\w)/g, m => m[1].toUpperCase())

let Base
const settings = require("./settings")
const VimState = require("./vim-state")

module.exports = {
  config: settings.config,

  activate() {
    this.emitter = new Emitter()
    settings.silentlyRemoveUnusedParams()
    settings.migrateRenamedParams()

    if (atom.inSpecMode()) settings.set("strictAssertion", true)

    this.subscriptions = new CompositeDisposable(
      atom.commands.add("atom-text-editor:not([mini])", {
        "vim-mode-plus:clear-highlight-search": () => this.clearHighlightSearch(),
        "vim-mode-plus:toggle-highlight-search": () => this.toggleHighlightSearch(),
      }),
      atom.commands.add("atom-workspace", {
        "vim-mode-plus:maximize-pane": () => this.paneUtils.maximizePane(),
        "vim-mode-plus:maximize-pane-without-center": () => this.paneUtils.maximizePane(false),
        "vim-mode-plus:equalize-panes": () => this.paneUtils.equalizePanes(),
        "vim-mode-plus:exchange-pane": () => this.paneUtils.exchangePane(),
        "vim-mode-plus:move-pane-to-very-top": () => this.paneUtils.movePaneToVery("top"),
        "vim-mode-plus:move-pane-to-very-bottom": () => this.paneUtils.movePaneToVery("bottom"),
        "vim-mode-plus:move-pane-to-very-left": () => this.paneUtils.movePaneToVery("left"),
        "vim-mode-plus:move-pane-to-very-right": () => this.paneUtils.movePaneToVery("right"),
      }),
      this.registerEditorCommands(),
      this.registerVimStateCommands(),
      atom.workspace.onDidChangeActivePane(() => this.demaximizePane()),
      atom.workspace.observeTextEditors(editor => {
        if (!editor.isMini()) {
          this.emitter.emit("did-add-vim-state", new VimState(editor, this.statusBarManager))
        }
      }),
      atom.workspace.onDidStopChangingActivePaneItem(item => {
        if (atom.workspace.isTextEditor(item) && item.isMini()) return

        const autoEscapeInsertMode = settings.get("automaticallyEscapeInsertModeOnActivePaneItemChange")

        VimState.forEach(vimState => {
          if (vimState.editor === item) {
            vimState.updateStatusBar()
          } else if (autoEscapeInsertMode && vimState.mode === "insert") {
            vimState.activate("normal")
          }

          // [FIXME] Clear existing flash markers for all vimState to avoid hide/show editor re-start flash animation.
          // This is workaround for "the keyframe animation being restarted on re-activating editor"-issue.
          // Ideally I want to remove this and keyframe animation state is mainained across hide/show editor item.
          vimState.clearFlash()

          if (vimState.__highlightSearch || this.globalState.get("highlightSearchPattern")) {
            vimState.highlightSearch.refresh()
          }
        })

        if (!atom.workspace.isTextEditor(item)) {
          this.statusBarManager.clear()
        }
      }),
      settings.onDidChange("highlightSearch", ({newValue}) => {
        if (newValue) {
          this.globalState.set("highlightSearchPattern", this.globalState.get("lastSearchPattern"))
        } else {
          this.clearHighlightSearch()
        }
      }),
      ...settings.observeConditionalKeymaps()
    )

    if (atom.inDevMode()) {
      const developer = require("./developer")
      this.subscriptions.add(developer.init())
      if (settings.get("debug")) {
        developer.reportRequireCache({excludeNodModules: false})
      }
    }
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
    this.subscriptions.dispose()
    VimState.forEach(vimState => vimState.destroy())
    VimState.clear()
  },

  // atom-text-editor commands
  clearHighlightSearch() {
    this.globalState.set("highlightSearchPattern", null)
  },

  toggleHighlightSearch() {
    settings.toggle("highlightSearch")
  },

  demaximizePane() {
    this.__paneUtils && this.paneUtils.demaximizePane()
  },

  registerEditorCommands() {
    const commands = {}
    const dispatcher = VimState.getDispatcherDispatchBy(event => classify(event.type.replace("vim-mode-plus:", "")))
    require("./json/command-table.json").forEach(name => (commands[name] = dispatcher))
    return atom.commands.add("atom-text-editor", commands)
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
      "operator-modifier-characterwise"() { this.setOperatorModifier({wise: "characterwise"}) },
      "operator-modifier-linewise"() { this.setOperatorModifier({wise: "linewise"}) },
      "operator-modifier-occurrence"() { this.setOperatorModifier({occurrence: true, occurrenceType: "base"}) },
      "operator-modifier-subword-occurrence"() { this.setOperatorModifier({occurrence: true, occurrenceType: "subword"}) },
      "repeat"() { this.operationStack.runRecorded() },
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

    function bindToVimState(commands) {
      const boundCommands = {}
      for (const name of Object.keys(commands)) {
        const fn = commands[name]
        boundCommands[`vim-mode-plus:${name}`] = {
          hiddenInCommandPalette: true,
          didDispatch(event) {
            event.stopPropagation()
            const vimState = VimState.get(this.getModel())
            if (vimState) fn.call(vimState)
          },
        }
      }
      return boundCommands
    }

    return atom.commands.add("atom-text-editor:not([mini])", bindToVimState(commands))
  },

  consumeStatusBar(service) {
    this.subscriptions.add(this.statusBarManager.init(service))
  },

  consumeDemoMode(service) {
    this.subscriptions.add(this.demoModeSupport.init(service))
  },

  // Computed props
  // -------------------------
  get statusBarManager() { return this.__statusBarManager || (this.__statusBarManager = require("./status-bar-manager")) }, // prettier-ignore
  get demoModeSupport() { return this.__demoModeSupport || (this.__demoModeSupport = require("./demo-mode-support")) }, // prettier-ignore
  get paneUtils() { return this.__paneUtils || (this.__paneUtils = require("./pane-utils")) }, // prettier-ignore
  get globalState() { return this.__globalState || (this.__globalState = require("./global-state")) }, // prettier-ignore

  // Service API
  // -------------------------
  getGlobalState() {
    return this.globalState
  },
  getEditorState(editor) {
    return VimState.get(editor)
  },

  provideVimModePlus() {
    const getBase = () => Base || (Base = require("./base"))

    return {
      Base: {
        get getClass() {
          const Grim = require("grim")
          Grim.deprecate(
            `\`Base\` will be not available soon, Use \`service.getClass()\` instead of \`service.Base.getClass()\``
          )
          return (...args) => getBase().getClass(...args)
        },
      },
      get getClass() {
        return (...args) => getBase().getClass(...args)
      },
      registerCommandFromSpec: VimState.registerCommandFromSpec.bind(VimState),
      registerCommandsFromSpec: VimState.registerCommandsFromSpec.bind(VimState),
      getGlobalState: this.getGlobalState.bind(this),
      getEditorState: this.getEditorState.bind(this),
      observeVimStates: this.observeVimStates.bind(this),
      onDidAddVimState: this.onDidAddVimState.bind(this),
    }
  },
}
