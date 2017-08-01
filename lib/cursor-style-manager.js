const {Point, Disposable, CompositeDisposable} = require("atom")
let SupportCursorSetVisible = null

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
    this.editor = vimState.editor
    if (SupportCursorSetVisible == null) {
      SupportCursorSetVisible = typeof this.editor.getLastCursor().setVisible === "function"
    }

    this.disposables = new CompositeDisposable()
    const refresh = this.refresh.bind(this)
    this.disposables.add(atom.config.observe("editor.lineHeight", refresh))
    this.disposables.add(atom.config.observe("editor.fontSize", refresh))
    this.vimState.onDidDestroy(() => this.destroy())
  }

  destroy() {
    if (this.styleDisposables) this.styleDisposables.dispose()
    this.disposables.dispose()
  }

  updateCursorStyleOld() {
    // We must dispose previous style modification for non-visual-mode
    if (this.styleDisposables) this.styleDisposables.dispose()

    this.styleDisposables = new CompositeDisposable()
    if (this.mode !== "visual") return

    const cursorsToShow =
      this.submode === "blockwise"
        ? this.vimState.getBlockwiseSelections().map(bs => bs.getHeadSelection().cursor)
        : this.editor.getCursors()

    // In visual-mode or in occurrence operation, cursor are added during operation but selection is added asynchronously.
    // We have to make sure that corresponding cursor's domNode is available at this point to directly modify it's style.
    this.editor.element.component.updateSync()
    for (const cursor of this.editor.getCursors()) {
      if (cursorsToShow.includes(cursor)) {
        cursor.setVisible(true)
        this.styleDisposables.add(this.modifyCursorStyle(cursor, this.getCursorStyle(cursor, true)))
      } else {
        cursor.setVisible(false)
      }
    }
  }

  modifyCursorStyle(cursor, cursorStyle) {
    cursorStyle = this.getCursorStyle(cursor, true)
    // [NOTE] Using non-public API
    const cursorNode = this.editor.element.component.linesComponent.cursorsComponent.cursorNodesById[cursor.id]
    if (cursorNode) {
      cursorNode.style.setProperty("top", cursorStyle.top)
      cursorNode.style.setProperty("left", cursorStyle.left)
      return new Disposable(() => {
        if (cursorNode.style) {
          cursorNode.style.removeProperty("top")
          cursorNode.style.removeProperty("left")
        }
      })
    } else {
      return new Disposable()
    }
  }

  updateCursorStyleNew() {
    // We must dispose previous style modification for non-visual-mode
    // Intentionally collect all decorations from editor instead of managing
    // decorations we created explicitly.
    // Why? when intersecting multiple selections are auto-merged, it's got wired
    // state where decoration cannot be disposable(not investigated well).
    // And I want to assure ALL cursor style modification done by vmp is cleared.
    for (const decoration of this.editor.getDecorations({type: "cursor", class: "vim-mode-plus"})) {
      decoration.destroy()
    }

    if (this.mode !== "visual") return

    const cursorsToShow =
      this.submode === "blockwise"
        ? this.vimState.getBlockwiseSelections().map(bs => bs.getHeadSelection().cursor)
        : this.editor.getCursors()

    for (const cursor of this.editor.getCursors()) {
      this.editor.decorateMarker(cursor.getMarker(), {
        type: "cursor",
        class: "vim-mode-plus",
        style: this.getCursorStyle(cursor, cursorsToShow.includes(cursor)),
      })
    }
  }

  refresh() {
    // Intentionally skip in spec mode, since not all spec have DOM attached( and don't want to ).
    if (atom.inSpecMode()) return

    this.lineHeight = this.editor.getLineHeightInPixels()

    if (SupportCursorSetVisible) {
      this.updateCursorStyleOld()
    } else {
      this.updateCursorStyleNew()
    }
  }

  getCursorBufferPositionToDisplay(selection) {
    let bufferPosition = this.vimState.swrap(selection).getBufferPositionFor("head", {from: ["property"]})

    const editor = this.editor
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
      const bufferPosition = this.getCursorBufferPositionToDisplay(cursor.selection)
      const {column, row} = (() => {
        if (
          this.submode === "linewise" &&
          (this.editor.isSoftWrapped() || this.editor.isFoldedAtBufferRow(bufferPosition.row))
        ) {
          const screenPosition = this.editor.screenPositionForBufferPosition(bufferPosition)
          return screenPosition.traversalFrom(cursor.getScreenPosition())
        } else {
          return bufferPosition.traversalFrom(cursor.getBufferPosition())
        }
      })()

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
