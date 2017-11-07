const {Emitter, Range, CompositeDisposable, Disposable} = require("atom")
let moveCursorLeft

module.exports = class ModeManager {
  constructor(vimState) {
    this.vimState = vimState
    this.editor = vimState.editor
    this.editorElement = vimState.editorElement

    this.mode = "insert" // Bare atom is not modal editor, thus it's `insert` mode.
    this.submode = null

    this.emitter = new Emitter()
    vimState.onDidDestroy(() => this.destroy())
  }

  destroy() {}

  isMode(mode, submode) {
    return mode === this.mode && (submode ? submode === this.submode : true)
  }

  // Event
  // -------------------------
  onWillActivateMode(fn) { return this.emitter.on("will-activate-mode", fn) } // prettier-ignore
  onDidActivateMode(fn) { return this.emitter.on("did-activate-mode", fn) } // prettier-ignore
  onWillDeactivateMode(fn) { return this.emitter.on("will-deactivate-mode", fn) } // prettier-ignore
  preemptWillDeactivateMode(fn) { return this.emitter.preempt("will-deactivate-mode", fn) } // prettier-ignore
  onDidDeactivateMode(fn) { return this.emitter.on("did-deactivate-mode", fn) } // prettier-ignore

  // activate: Public
  //  Use this method to change mode, DONT use other direct method.
  // -------------------------
  activate(newMode, newSubmode = null) {
    // Avoid odd state(=visual-mode but selection is empty)
    if (newMode === "visual" && this.editor.isEmpty()) return
    this.vimState.ignoreSelectionChange = true

    this.emitter.emit("will-activate-mode", {mode: newMode, submode: newSubmode})

    if (newMode === "visual" && newSubmode && newSubmode === this.submode) {
      newMode = "normal"
      newSubmode = null
    }

    if (newMode !== this.mode) {
      this.emitter.emit("will-deactivate-mode", {mode: this.mode, submode: this.submode})
      if (this.deactivator) {
        this.deactivator.dispose()
        this.deactivator = null
      }
      this.emitter.emit("did-deactivate-mode", {mode: this.mode, submode: this.submode})
    }

    if (newMode === "normal") this.activateNormalMode()
    else if (newMode === "insert") this.editorElement.component.setInputEnabled(true)
    else if (newMode === "visual") this.deactivator = this.activateVisualMode(newSubmode)

    this.editorElement.classList.remove(`${this.mode}-mode`)
    this.editorElement.classList.remove(this.submode)

    const oldMode = this.mode
    this.mode = newMode
    this.submode = newSubmode

    if (oldMode === "visual" || this.mode === "visual") this.updateNarrowedState()

    // Prevent swrap from loaded on initial mode-setup on startup.
    if (this.mode === "visual") {
      this.vimState.updatePreviousSelection()
    } else {
      if (this.vimState.__swrap) this.vimState.swrap.clearProperties(this.editor)
    }

    this.editorElement.classList.add(`${this.mode}-mode`)
    if (this.submode) this.editorElement.classList.add(this.submode)

    this.vimState.statusBarManager.update(this.mode, this.submode)
    if (this.mode === "visual" || this.vimState.__cursorStyleManager) {
      this.vimState.cursorStyleManager.refresh()
    }

    this.emitter.emit("did-activate-mode", {mode: this.mode, submode: this.submode})
    this.vimState.ignoreSelectionChange = false
  }

  // Normal
  // -------------------------
  activateNormalMode() {
    this.vimState.reset()
    // Component is not necessary avaiable see #98.
    if (this.editorElement.component) {
      this.editorElement.component.setInputEnabled(false)
    }

    // In visual-mode, cursor can place at EOL. move left if cursor is at EOL
    // We should not do this in visual-mode deactivation phase.
    // e.g. `A` directly shift from visua-mode to `insert-mode`, and cursor should remain at EOL.
    for (const cursor of this.editor.getCursors()) {
      // Don't use utils moveCursorLeft to skip require('./utils') for faster startup.
      if (cursor.isAtEndOfLine() && !cursor.isAtBeginningOfLine()) {
        const {goalColumn} = cursor
        cursor.moveLeft()
        if (goalColumn != null) cursor.goalColumn = goalColumn
      }
    }
  }

  // Visual
  // -------------------------
  // We treat all selection is initially NOT normalized
  //
  // 1. First we normalize selection
  // 2. Then update selection orientation(=wise).
  //
  // Regardless of selection is modified by vmp-command or outer-vmp-command like `cmd-l`.
  // When normalize, we move cursor to left(selectLeft equivalent).
  // Since Vim's visual-mode is always selectRighted.
  //
  // - un-normalized selection: This is the range we see in visual-mode.( So normal visual-mode range in user perspective ).
  // - normalized selection: One column left selcted at selection end position
  // - When selectRight at end position of normalized-selection, it become un-normalized selection
  //   which is the range in visual-mode.
  activateVisualMode(submode) {
    const swrap = this.vimState.swrap
    swrap.saveProperties(this.editor)
    swrap.normalize(this.editor)

    for (const $selection of swrap.getSelections(this.editor)) {
      $selection.applyWise(submode)
    }
    if (submode === "blockwise") this.vimState.getLastBlockwiseSelection().autoscroll()

    return new Disposable(() => {
      swrap.normalize(this.editor)
      if (this.submode === "blockwise") swrap.setReversedState(this.editor, true)
      for (const selection of this.editor.getSelections()) {
        selection.clear({autoscroll: false})
      }
    })
  }

  // Narrowed selection
  // -------------------------
  updateNarrowedState() {
    const isSingleRowSelection = this.isMode("visual", "blockwise")
      ? this.vimState.getLastBlockwiseSelection().isSingleRow()
      : this.vimState.swrap(this.editor.getLastSelection()).isSingleRow()
    this.editorElement.classList.toggle("is-narrowed", !isSingleRowSelection)
  }

  isNarrowed() {
    return this.editorElement.classList.contains("is-narrowed")
  }
}
