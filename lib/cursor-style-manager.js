const {CompositeDisposable} = require("atom")

// Display cursor in visual-mode
// ----------------------------------
module.exports = class CursorStyleManager {
  get mode() {
    return this.vimState.mode
  }

  get submode() {
    return this.vimState.submode
  }

  constructor(vimState) {
    this.vimState = vimState

    const refresh = this.refresh.bind(this)
    this.disposables = new CompositeDisposable(
      atom.config.observe("editor.lineHeight", refresh),
      atom.config.observe("editor.fontSize", refresh)
    )
    this.vimState.onDidDestroy(() => this.destroy())
  }

  destroy() {
    if (this.styleDisposables) this.styleDisposables.dispose()
    this.disposables.dispose()
  }

  refresh() {
    // Intentionally skip in spec mode, since not all spec have DOM attached( and don't want to ).
    if (atom.inSpecMode()) return

    const {editor} = this.vimState

    // Clear previously applied cursor style. Intentionally collect decorations
    // from editor instead of managing decorations in this manager.
    // Why? When intersecting multiple selections are auto-merged, it's become
    // wired state where decoration cannot be disposable(not investigated well).
    // And I also want to make sure ALL cursor style change done by vmp is cleared.
    for (const decoration of editor.getDecorations({type: "cursor", class: "vim-mode-plus"})) {
      decoration.destroy()
    }

    if (this.mode !== "visual") return

    this.lineHeight = editor.getLineHeightInPixels()

    const cursorsToShow =
      this.submode === "blockwise"
        ? this.vimState.getBlockwiseSelections().map(bs => bs.getHeadSelection().cursor)
        : editor.getCursors()

    for (const cursor of editor.getCursors()) {
      editor.decorateMarker(cursor.getMarker(), {
        type: "cursor",
        class: "vim-mode-plus",
        style: this.getCursorStyle(cursor, cursorsToShow.includes(cursor)),
      })
    }
  }

  getCursorBufferPositionToDisplay(selection) {
    let bufferPosition = this.vimState.swrap(selection).getBufferPositionFor("head", {from: ["property"]})

    const {editor} = this.vimState
    if (editor.hasAtomicSoftTabs() && !selection.isReversed()) {
      const screenPosition = editor.screenPositionForBufferPosition(bufferPosition.translate([0, 1]), {
        clipDirection: "forward",
      })
      const bufferPositionToDisplay = editor.bufferPositionForScreenPosition(screenPosition).translate([0, -1])
      if (bufferPositionToDisplay.isGreaterThan(bufferPosition)) {
        bufferPosition = bufferPositionToDisplay
      }
    }

    return editor.clipBufferPosition(bufferPosition)
  }

  getCursorStyle(cursor, visible) {
    if (visible) {
      const {editor} = this.vimState
      const bufferPosition = this.getCursorBufferPositionToDisplay(cursor.selection)
      const {column, row} =
        this.submode === "linewise" && (editor.isSoftWrapped() || editor.isFoldedAtBufferRow(bufferPosition.row))
          ? editor.screenPositionForBufferPosition(bufferPosition).traversalFrom(cursor.getScreenPosition())
          : bufferPosition.traversalFrom(cursor.getBufferPosition())

      return {
        top: this.lineHeight * row + "px",
        left: column + "ch",
        visibility: "visible",
      }
    } else {
      return {visibility: "hidden"}
    }
  }
}
