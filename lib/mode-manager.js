const {Emitter, Range, CompositeDisposable, Disposable} = require("atom")
let moveCursorLeft

module.exports = class ModeManager {
  constructor(vimState) {
    this.vimState = vimState
    this.editor = vimState.editor
    this.editorElement = vimState.editorElement

    this.mode = "insert" // Bare atom is not modal editor, thus it's `insert` mode.
    this.submode = null
    this.replacedCharsBySelection = null

    this.emitter = new Emitter()
    this.vimState.onDidDestroy(() => this.destroy())
  }

  destroy() {}

  isMode(mode, submode = null) {
    return mode === this.mode && submode === this.submode
  }

  // Event
  // -------------------------
  onWillActivateMode(fn) {
    return this.emitter.on("will-activate-mode", fn)
  }
  onDidActivateMode(fn) {
    return this.emitter.on("did-activate-mode", fn)
  }
  onWillDeactivateMode(fn) {
    return this.emitter.on("will-deactivate-mode", fn)
  }
  preemptWillDeactivateMode(fn) {
    return this.emitter.preempt("will-deactivate-mode", fn)
  }
  onDidDeactivateMode(fn) {
    return this.emitter.on("did-deactivate-mode", fn)
  }

  // activate: Public
  //  Use this method to change mode, DONT use other direct method.
  // -------------------------
  activate(newMode, newSubmode = null) {
    // Avoid odd state(=visual-mode but selection is empty)
    if (newMode === "visual" && this.editor.isEmpty()) return

    this.emitter.emit("will-activate-mode", {mode: newMode, submode: newSubmode})

    if (newMode === "visual" && newSubmode && newSubmode === this.submode) {
      newMode = "normal"
      newSubmode = null
    }

    if (newMode !== this.mode) this.deactivate()

    if (newMode === "normal") this.deactivator = this.activateNormalMode()
    else if (newMode === "operator-pending") this.deactivator = this.activateOperatorPendingMode()
    else if (newMode === "insert") this.deactivator = this.activateInsertMode(newSubmode)
    else if (newMode === "visual") this.deactivator = this.activateVisualMode(newSubmode)

    this.editorElement.classList.remove(`${this.mode}-mode`)
    this.editorElement.classList.remove(this.submode)

    this.mode = newMode
    this.submode = newSubmode

    if (this.mode === "visual") {
      this.updateNarrowedState()
      this.vimState.updatePreviousSelection()
    } else {
      // Prevent swrap from loaded on initial mode-setup on startup.
      this.vimState.withProp("swrap", p => p.clearProperties(this.editor))
    }

    this.editorElement.classList.add(`${this.mode}-mode`)
    if (this.submode) this.editorElement.classList.add(this.submode)

    this.vimState.statusBarManager.update(this.mode, this.submode)
    if (this.mode === "visual" || this.vimState.__cursorStyleManager) {
      this.vimState.cursorStyleManager.refresh()
    }

    this.emitter.emit("did-activate-mode", {mode: this.mode, submode: this.submode})
  }

  deactivate() {
    if (!this.deactivator || this.deactivator.disposed) return

    this.emitter.emit("will-deactivate-mode", {mode: this.mode, submode: this.submode})

    this.deactivator.dispose()
    // Remove css class here in-case this.deactivate() called solely(occurrence in visual-mode)
    this.editorElement.classList.remove(`${this.mode}-mode`)
    this.editorElement.classList.remove(this.submode)
    this.emitter.emit("did-deactivate-mode", {mode: this.mode, submode: this.submode})
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
    return new Disposable()
  }

  // Operator Pending
  // -------------------------
  activateOperatorPendingMode() {
    return new Disposable()
  }

  // Insert
  // -------------------------
  activateInsertMode(submode = null) {
    let replaceModeDeactivator
    this.editorElement.component.setInputEnabled(true)
    if (submode === "replace") replaceModeDeactivator = this.activateReplaceMode()

    return new Disposable(() => {
      if (!moveCursorLeft) moveCursorLeft = require("./utils").moveCursorLeft

      if (replaceModeDeactivator) replaceModeDeactivator.dispose()
      replaceModeDeactivator = null

      // When escape from insert-mode, cursor move Left.
      const needSpecialCareToPreventWrapLine = this.editor.hasAtomicSoftTabs()
      for (const cursor of this.editor.getCursors()) {
        moveCursorLeft(cursor, {needSpecialCareToPreventWrapLine})
      }
    })
  }

  activateReplaceMode() {
    this.replacedCharsBySelection = new WeakMap()
    return new CompositeDisposable(
      this.editor.onWillInsertText(({text = "", cancel}) => {
        cancel()
        this.editor.getSelections().forEach(selection => {
          for (const char of text.split("")) {
            if (char !== "\n" && !selection.cursor.isAtEndOfLine()) {
              selection.selectRight()
            }
            if (!this.replacedCharsBySelection.has(selection)) {
              this.replacedCharsBySelection.set(selection, [])
            }
            this.replacedCharsBySelection.get(selection).push(selection.getText())
            selection.insertText(char)
          }
        })
      }),
      new Disposable(() => {
        this.replacedCharsBySelection = null
      })
    )
  }

  getReplacedCharForSelection(selection) {
    const chars = this.replacedCharsBySelection.get(selection)
    if (chars) return chars.pop()
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
    for (const $selection of swrap.getSelections(this.editor)) {
      if (!$selection.hasProperties()) {
        $selection.saveProperties()
      }
    }

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
      this.updateNarrowedState(false)
    })
  }

  // Narrow to selection
  // -------------------------
  hasMultiLineSelection() {
    if (this.isMode("visual", "blockwise")) {
      // [FIXME] why I need null guard here
      const blockwiseSelection = this.vimState.getLastBlockwiseSelection()
      return !blockwiseSelection ? false : !blockwiseSelection.isSingleRow()
    } else {
      return !this.vimState.swrap(this.editor.getLastSelection()).isSingleRow()
    }
  }

  updateNarrowedState(value) {
    this.editorElement.classList.toggle("is-narrowed", value ? value : this.hasMultiLineSelection())
  }

  isNarrowed() {
    return this.editorElement.classList.contains("is-narrowed")
  }
}
