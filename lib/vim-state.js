const Delegato = require("delegato")
let jQuery

const {Emitter, Disposable, CompositeDisposable, Range} = require("atom")
const settings = require("./settings")
const ModeManager = require("./mode-manager")

const LazyLoadedLibs = {}
function lazyRequire(file) {
  if (!(file in LazyLoadedLibs)) {
    if (atom.inDevMode() && settings.get("debug")) {
      console.log(`# lazy-require: ${file}`)
    }
    LazyLoadedLibs[file] = require(file)
  }
  return LazyLoadedLibs[file]
}

const __vimStatesByEditor = new Map()

module.exports = class VimState {
  static get vimStatesByEditor() {
    return __vimStatesByEditor
  }
  static getByEditor(editor) {
    return __vimStatesByEditor.get(editor)
  }
  static has(editor) {
    return __vimStatesByEditor.has(editor)
  }
  static delete(editor) {
    return __vimStatesByEditor.delete(editor)
  }
  static forEach(fn) {
    return __vimStatesByEditor.forEach(fn)
  }
  static clear() {
    return __vimStatesByEditor.clear()
  }

  // To modeManager
  get mode() {
    return this.modeManager.mode
  }
  get submode() {
    return this.modeManager.submode
  }
  // FIXME: REMOVE THIS; DONT directly update submode just for skip normalization
  set submode(submode) {
    this.modeManager.submode = submode
  }

  isMode(...args) {
    return this.modeManager.isMode(...args)
  }
  activate(...args) {
    this.modeManager.activate(...args)
  }
  // To flashManager
  flash(...args) {
    this.flashManager.flash(...args)
  }
  flashScreenRange(...args) {
    this.flashManager.flashScreenRange(...args)
  }
  // To OperationStack
  subscribe(...args) {
    return this.operationStack.subscribe(...args)
  }
  getCount(...args) {
    return this.operationStack.getCount(...args)
  }
  setCount(...args) {
    this.operationStack.setCount(...args)
  }
  addToClassList(...args) {
    return this.operationStack.addToClassList(...args)
  }

  // Lazy populated properties for fast package startup
  //=====================================================
  load(fileToLoad, instantiate = true) {
    return instantiate ? new (lazyRequire(fileToLoad))(this) : lazyRequire(fileToLoad)
  }
  get mark() {
    return this.__mark || (this.__mark = this.load("./mark-manager"))
  }
  get register() {
    return this.__register || (this.__register = this.load("./register-manager"))
  }
  get hover() {
    return this.__hover || (this.__hover = this.load("./hover-manager"))
  }
  get hoverSearchCounter() {
    return this.__hoverSearchCounter || (this.__hoverSearchCounter = this.load("./hover-manager"))
  }
  get searchHistory() {
    return this.__searchHistory || (this.__searchHistory = this.load("./search-history-manager"))
  }
  get highlightSearch() {
    return this.__highlightSearch || (this.__highlightSearch = this.load("./highlight-search-manager"))
  }
  get persistentSelection() {
    return this.__persistentSelection || (this.__persistentSelection = this.load("./persistent-selection-manager"))
  }
  get occurrenceManager() {
    return this.__occurrenceManager || (this.__occurrenceManager = this.load("./occurrence-manager"))
  }
  get mutationManager() {
    return this.__mutationManager || (this.__mutationManager = this.load("./mutation-manager"))
  }
  get flashManager() {
    return this.__flashManager || (this.__flashManager = this.load("./flash-manager"))
  }
  get searchInput() {
    return this.__searchInput || (this.__searchInput = this.load("./search-input"))
  }
  get operationStack() {
    return this.__operationStack || (this.__operationStack = this.load("./operation-stack"))
  }
  get cursorStyleManager() {
    return this.__cursorStyleManager || (this.__cursorStyleManager = this.load("./cursor-style-manager"))
  }
  get swrap() {
    return this.__swrap || (this.__swrap = this.load("./selection-wrapper", false))
  }
  get utils() {
    return this.__utils || (this.__utils = this.load("./utils", false))
  }

  constructor(editor, statusBarManager, globalState) {
    this.editor = editor
    this.editorElement = this.editor.element
    this.statusBarManager = statusBarManager
    this.globalState = globalState
    this.emitter = new Emitter()
    this.subscriptions = new CompositeDisposable()
    this.modeManager = new ModeManager(this)
    this.previousSelection = {}
    this.scrollAnimationEffect = null

    this.subscriptions.add(this.observeMouse(), this.observeCommandDispatch())

    this.editorElement.classList.add("vim-mode-plus")

    if (this.getConfig("startInInsertMode") || this.matchScopes(this.getConfig("startInInsertModeScopes"))) {
      this.activate("insert")
    } else {
      this.activate("normal")
    }

    this.editor.onDidDestroy(() => this.destroy())
    this.constructor.vimStatesByEditor.set(this.editor, this)
  }

  getConfig(param) {
    return settings.get(param)
  }

  matchScopes(scopes) {
    // HACK: length guard to avoid utils prop populated unnecessarily
    return scopes.length && this.utils.matchScopes(this.editorElement, scopes)
  }

  // BlockwiseSelections
  // -------------------------
  getBlockwiseSelections() {
    return this.swrap.getBlockwiseSelections(this.editor)
  }

  getLastBlockwiseSelection() {
    return this.swrap.getLastBlockwiseSelections(this.editor)
  }

  getBlockwiseSelectionsOrderedByBufferPosition() {
    return this.swrap.getBlockwiseSelectionsOrderedByBufferPosition(this.editor)
  }

  clearBlockwiseSelections() {
    return this.withProp("swrap", p => p.clearBlockwiseSelections(this.editor))
  }

  // Other
  // -------------------------
  // FIXME: I want to remove this dengerious approach, but I couldn't find the better way.
  swapClassName(...classNames) {
    const oldMode = this.mode
    this.editorElement.classList.remove("vim-mode-plus", oldMode + "-mode")
    this.editorElement.classList.add(...classNames)

    return new Disposable(() => {
      this.editorElement.classList.remove(...classNames)
      const classToAdd = ["vim-mode-plus", "is-focused"]
      if (this.mode === oldMode) classToAdd.push(oldMode + "-mode")
      this.editorElement.classList.add(...classToAdd)
    })
  }

  // All subscriptions here is celared on each operation finished.
  // -------------------------
  onDidChangeSearch(fn) {
    return this.subscribe(this.searchInput.onDidChange(fn))
  }
  onDidConfirmSearch(fn) {
    return this.subscribe(this.searchInput.onDidConfirm(fn))
  }
  onDidCancelSearch(fn) {
    return this.subscribe(this.searchInput.onDidCancel(fn))
  }
  onDidCommandSearch(fn) {
    return this.subscribe(this.searchInput.onDidCommand(fn))
  }

  // Select and text mutation(Change)
  onDidSetTarget(fn) {
    return this.subscribe(this.emitter.on("did-set-target", fn))
  }
  emitDidSetTarget(operator) {
    this.emitter.emit("did-set-target", operator)
  }

  onWillSelectTarget(fn) {
    return this.subscribe(this.emitter.on("will-select-target", fn))
  }
  emitWillSelectTarget() {
    this.emitter.emit("will-select-target")
  }

  onDidSelectTarget(fn) {
    return this.subscribe(this.emitter.on("did-select-target", fn))
  }
  emitDidSelectTarget() {
    this.emitter.emit("did-select-target")
  }

  onDidFailSelectTarget(fn) {
    return this.subscribe(this.emitter.on("did-fail-select-target", fn))
  }
  emitDidFailSelectTarget() {
    this.emitter.emit("did-fail-select-target")
  }

  onWillFinishMutation(fn) {
    return this.subscribe(this.emitter.on("on-will-finish-mutation", fn))
  }
  emitWillFinishMutation() {
    this.emitter.emit("on-will-finish-mutation")
  }

  onDidFinishMutation(fn) {
    return this.subscribe(this.emitter.on("on-did-finish-mutation", fn))
  }
  emitDidFinishMutation() {
    this.emitter.emit("on-did-finish-mutation")
  }

  onDidSetOperatorModifier(fn) {
    return this.subscribe(this.emitter.on("did-set-operator-modifier", fn))
  }
  emitDidSetOperatorModifier(options) {
    this.emitter.emit("did-set-operator-modifier", options)
  }

  onDidFinishOperation(fn) {
    return this.subscribe(this.emitter.on("did-finish-operation", fn))
  }
  emitDidFinishOperation() {
    this.emitter.emit("did-finish-operation")
  }

  onDidResetOperationStack(fn) {
    return this.subscribe(this.emitter.on("did-reset-operation-stack", fn))
  }
  emitDidResetOperationStack() {
    this.emitter.emit("did-reset-operation-stack")
  }

  // Select list view
  onDidConfirmSelectList(fn) {
    return this.subscribe(this.emitter.on("did-confirm-select-list", fn))
  }
  onDidCancelSelectList(fn) {
    return this.subscribe(this.emitter.on("did-cancel-select-list", fn))
  }

  // Proxying modeManger's event hook with short-life subscription.
  onWillActivateMode(fn) {
    return this.subscribe(this.modeManager.onWillActivateMode(fn))
  }
  onDidActivateMode(fn) {
    return this.subscribe(this.modeManager.onDidActivateMode(fn))
  }
  onWillDeactivateMode(fn) {
    return this.subscribe(this.modeManager.onWillDeactivateMode(fn))
  }
  preemptWillDeactivateMode(fn) {
    return this.subscribe(this.modeManager.preemptWillDeactivateMode(fn))
  }
  onDidDeactivateMode(fn) {
    return this.subscribe(this.modeManager.onDidDeactivateMode(fn))
  }

  // Events
  // -------------------------
  onDidFailToPushToOperationStack(fn) {
    return this.emitter.on("did-fail-to-push-to-operation-stack", fn)
  }
  emitDidFailToPushToOperationStack() {
    this.emitter.emit("did-fail-to-push-to-operation-stack")
  }

  onDidDestroy(fn) {
    return this.emitter.on("did-destroy", fn)
  }

  // * `fn` {Function} to be called when mark was set.
  //   * `name` Name of mark such as 'a'.
  //   * `bufferPosition`: bufferPosition where mark was set.
  //   * `editor`: editor where mark was set.
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  //
  //  Usage:
  //   onDidSetMark ({name, bufferPosition}) -> do something..
  onDidSetMark(fn) {
    return this.emitter.on("did-set-mark", fn)
  }

  onDidSetInputChar(fn) {
    return this.emitter.on("did-set-input-char", fn)
  }
  emitDidSetInputChar(char) {
    this.emitter.emit("did-set-input-char", char)
  }

  isAlive() {
    return this.constructor.has(this.editor)
  }

  destroy() {
    if (!this.isAlive()) return

    this.constructor.delete(this.editor)
    this.subscriptions.dispose()

    if (this.editor.isAlive()) {
      this.resetNormalMode()
      this.reset()
      if (this.editorElement.component) this.editorElement.component.setInputEnabled(true)
      this.editorElement.classList.remove("vim-mode-plus", "normal-mode")
    }
    this.emitter.emit("did-destroy")
  }

  haveSomeNonEmptySelection() {
    return this.editor.getSelections().some(selection => !selection.isEmpty())
  }

  observeCommandDispatch() {
    return atom.commands.onDidDispatch(event => {
      if (atom.workspace.getActiveTextEditor() !== this.editor) return
      if (this.withProp("operationStack", p => p.isProcessing())) return
      if (this.mode === "insert") return

      // Intentionally using target.closest('atom-text-editor')
      // Don't use target.getModel() which is work for CustomEvent(=command) but not work for mouse event.
      const {target} = event
      if (!(target && target.closest && target.closest("atom-text-editor") === this.editorElement)) return
      if (event.type.startsWith("vim-mode-plus")) return // to match vim-mode-plus: and vim-mode-plus-user:

      if (this.haveSomeNonEmptySelection()) {
        this.editorElement.component.updateSync()
        const wise = this.swrap.detectWise(this.editor)
        if (this.isMode("visual", wise)) {
          this.swrap.getSelections(this.editor).forEach($s => $s.saveProperties())
          this.cursorStyleManager.refresh()
        } else {
          this.activate("visual", wise)
        }
      } else if (this.mode === "visual") {
        if (this.submode === "blockwise") {
          this.getBlockwiseSelections().forEach(bs => bs.skipNormalization())
        }
        this.activate("normal")
      }
    })
  }

  observeMouse() {
    let selectionChangeObserver,
      activateNormalOnMouseUp,
      nextMouseEvent = "mousedown-capture",
      ignoreSelectionChange = false

    const {editor} = this

    const updateVisualModeWithCurrentSelection = () => {
      if (this.mode === "visual") {
        this.swrap.getSelections(editor).forEach($s => $s.saveProperties())
        this.cursorStyleManager.refresh()
      } else if (this.haveSomeNonEmptySelection()) {
        ignoreSelectionChange = true
        this.activate("visual", this.swrap.detectWise(editor))
        ignoreSelectionChange = false
      }
    }

    const shouldIgnoreMouse = () => {
      return ignoreSelectionChange || this.mode === "insert" || this.withProp("operationStack", p => p.isProcessing())
    }

    // To keep original cursor screen range(tail range of selection) keep selected on `shift+click`
    // At this phase, cursor position is NOT yet updated, so we interact with original before-clicked cursor position.
    const handleMouseDownCapture = () => {
      if (shouldIgnoreMouse()) return

      if (nextMouseEvent !== "mousedown-capture") return
      nextMouseEvent = "mousedown-bubble"

      for (const selection of editor.getSelections()) {
        selection.initialScreenRange = this.swrap(selection).getTailBufferRange()
      }
    }

    const handleMouseDownBubble = () => {
      if (shouldIgnoreMouse()) return

      if (nextMouseEvent !== "mousedown-bubble") return
      nextMouseEvent = "mouseup"

      activateNormalOnMouseUp = false

      if (this.mode === "visual" && !this.haveSomeNonEmptySelection()) {
        if (this.submode === "blockwise") {
          this.getBlockwiseSelections().forEach(bs => bs.skipNormalization())
        }
        // We can't switch to normal mode here since selection might be modified by mousemove(drag).
        activateNormalOnMouseUp = true
      }

      for (const selection of editor.getSelections().filter(s => s.isEmpty())) {
        selection.initialScreenRange = this.swrap(selection).getTailBufferRange()
      }

      // For shilft+click which not involve mousemove event.
      updateVisualModeWithCurrentSelection()

      selectionChangeObserver = editor.onDidChangeSelectionRange(() => {
        if (ignoreSelectionChange) return
        activateNormalOnMouseUp = false
        updateVisualModeWithCurrentSelection()
      })
    }

    const handleMouseUp = () => {
      if (shouldIgnoreMouse()) return

      // Why explicitly assure mouse-event lifecycle? see #830 for detail.
      if (nextMouseEvent !== "mouseup") return
      nextMouseEvent = "mousedown-capture"

      if (selectionChangeObserver) selectionChangeObserver.dispose()
      if (activateNormalOnMouseUp) this.activate("normal")
    }

    this.editorElement.addEventListener("mousedown", handleMouseDownCapture, true)
    this.editorElement.addEventListener("mousedown", handleMouseDownBubble, false)
    this.editorElement.addEventListener("mouseup", handleMouseUp)

    return new Disposable(() => {
      this.editorElement.removeEventListener("mousedown", handleMouseDownCapture, true)
      this.editorElement.removeEventListener("mousedown", handleMouseDownBubble, false)
      this.editorElement.removeEventListener("mouseup", handleMouseUp)
    })
  }

  // What's this?
  // editor.clearSelections() doesn't respect lastCursor positoin.
  // This method works in same way as editor.clearSelections() but respect last cursor position.
  clearSelections() {
    this.editor.setCursorBufferPosition(this.editor.getCursorBufferPosition())
  }

  resetNormalMode({userInvocation = false} = {}) {
    this.clearBlockwiseSelections()

    if (userInvocation) {
      if (this.editor.hasMultipleCursors()) {
        this.clearSelections()
      } else if (this.hasPersistentSelections() && this.getConfig("clearPersistentSelectionOnResetNormalMode")) {
        this.clearPersistentSelections()
      } else if (this.withProp("occurrenceManager", p => p.hasPatterns())) {
        this.occurrenceManager.resetPatterns()
      }
      if (this.getConfig("clearHighlightSearchOnResetNormalMode")) this.globalState.set("highlightSearchPattern", null)
    } else {
      this.clearSelections()
    }
    this.activate("normal")
  }

  init() {
    this.saveOriginalCursorPosition()
  }

  reset() {
    // Reset each props only if it's already populated.
    this.withProp("register", p => p.reset())
    this.withProp("searchHistory", p => p.reset())
    this.withProp("hover", p => p.reset())
    this.withProp("operationStack", p => p.reset())
    this.withProp("mutationManager", p => p.reset())
  }

  isVisible() {
    return this.utils.getVisibleEditors().includes(this.editor)
  }

  // FIXME: naming, updateLastSelectedInfo ?
  updatePreviousSelection() {
    let properties

    if (this.isMode("visual", "blockwise")) {
      const blockwiseSelection = this.getLastBlockwiseSelection()
      properties = blockwiseSelection && blockwiseSelection.getProperties()
    } else {
      properties = this.swrap(this.editor.getLastSelection()).getProperties()
    }

    // TODO#704 when cursor is added in visual-mode, corresponding selection prop yet not exists.
    if (!properties) return

    // Copy by extracting only used item.
    properties = {head: properties.head, tail: properties.tail}

    const [whichStart, whichEnd] = properties.head.isGreaterThanOrEqual(properties.tail)
      ? ["tail", "head"]
      : ["head", "tail"]
    properties[whichEnd] = this.utils.translatePointAndClip(this.editor, properties[whichEnd], "forward")

    this.mark.set("<", properties[whichStart])
    this.mark.set(">", properties[whichEnd])
    this.previousSelection = {properties, submode: this.submode}
  }

  // Persistent selection
  // -------------------------
  hasPersistentSelections() {
    return this.withProp("persistentSelection", p => p.hasMarkers())
  }

  getPersistentSelectionBufferRanges() {
    return this.withProp("persistentSelection", p => p.getMarkerBufferRanges()) || []
  }

  withProp(name, fn) {
    const prop = this["__" + name]
    if (prop) return fn(prop)
  }

  clearPersistentSelections() {
    this.withProp("persistentSelection", p => p.clearMarkers())
  }

  requestScrollAnimation(from, to, options) {
    if (!jQuery) jQuery = require("atom-space-pen-views").jQuery
    this.scrollAnimationEffect = jQuery(from).animate(to, options)
  }

  finishScrollAnimation() {
    if (this.scrollAnimationEffect) {
      this.scrollAnimationEffect.finish()
      this.scrollAnimationEffect = null
    }
  }

  // Other
  // -------------------------
  updateStatusBar() {
    this.statusBarManager.update(this.mode, this.submode)
  }

  saveOriginalCursorPosition() {
    if (this.originalCursorPositionByMarker) {
      this.originalCursorPositionByMarker.destroy()
    }

    this.originalCursorPosition =
      this.mode === "visual"
        ? this.swrap(this.editor.getLastSelection()).getBufferPositionFor("head", {from: ["property", "selection"]})
        : this.editor.getCursorBufferPosition()

    this.originalCursorPositionByMarker = this.editor.markBufferPosition(this.originalCursorPosition, {
      invalidate: "never",
    })
  }

  restoreOriginalCursorPosition() {
    this.editor.setCursorBufferPosition(this.getOriginalCursorPosition())
  }

  getOriginalCursorPosition() {
    return this.originalCursorPosition
  }

  getOriginalCursorPositionByMarker() {
    return this.originalCursorPositionByMarker.getStartBufferPosition()
  }
}
