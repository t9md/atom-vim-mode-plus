const {CompositeDisposable} = require('atom')

function isAtEndOfLine (editor, bufferPosition) {
  return editor.bufferRangeForBufferRow(bufferPosition.row).end.isEqual(bufferPosition)
}

// Display cursor in visual-mode
// ----------------------------------
module.exports = class CursorStyleManager {
  constructor (vimState) {
    this.vimState = vimState

    const refresh = this.refresh.bind(this)
    this.disposables = new CompositeDisposable(
      atom.config.observe('editor.lineHeight', refresh),
      atom.config.observe('editor.fontSize', refresh)
    )
    vimState.onDidDestroy(() => this.destroy())
  }

  destroy () {
    this.disposables.dispose()
  }

  refresh () {
    // Intentionally skip in spec mode, since not all spec have DOM attached( and don't want to ).
    if (atom.inSpecMode()) return

    const {editor} = this.vimState

    // Clear previously applied cursor style. Intentionally collect decorations
    // from editor instead of managing decorations in this manager.
    // Why? When intersecting multiple selections are auto-merged, it's become
    // wired state where decoration cannot be disposable(not investigated well).
    // And I also want to make sure ALL cursor style change done by vmp is cleared.
    for (const decoration of editor.getDecorations({type: 'cursor', class: 'vim-mode-plus'})) {
      decoration.destroy()
    }

    if (this.vimState.mode !== 'visual') return

    let blockwiseHeadCursors
    if (this.vimState.submode === 'blockwise') {
      blockwiseHeadCursors = this.vimState.getBlockwiseSelections().map(bs => bs.getHeadSelection().cursor)
    }

    const lineHeight = editor.getLineHeightInPixels()
    for (const cursor of editor.getCursors()) {
      if (blockwiseHeadCursors && !blockwiseHeadCursors.includes(cursor)) {
        this.setCursorStyle(cursor, {visibility: 'hidden'})
      } else {
        const {column, row} = this.getCursorScreenPositionToDisplay(cursor).traversalFrom(cursor.getScreenPosition())
        this.setCursorStyle(cursor, {top: lineHeight * row + 'px', left: column + 'ch', visibility: 'visible'})
      }
    }
  }

  setCursorStyle (cursor, style) {
    cursor.editor.decorateMarker(cursor.getMarker(), {type: 'cursor', class: 'vim-mode-plus', style})
  }

  getCursorScreenPositionToDisplay ({selection, editor}) {
    const bufferPosition = this.vimState.swrap(selection).getBufferPositionFor('head', {from: ['property']})
    const screenPosition = editor.screenPositionForBufferPosition(bufferPosition)

    // Why clipping, for what purpose?
    // When following two softtab(four space each) selected, show cursor at end of softtab cell("b" not "a").
    // In other words, show cursor at end of selection in visual-characterwise mode.
    //         a  b c
    //         v  v v
    //   |>>>>|>>>>|>>>>|
    //
    // 1. When preserved cursor position is a.
    // 2. Translate [0, 1] then clip forward make position to c.
    // 3. Then translate [0, -1] make position b(got desired position to display).
    const needClip = editor.hasAtomicSoftTabs() && !selection.isReversed() && !isAtEndOfLine(editor, bufferPosition)
    if (needClip) {
      return editor.clipScreenPosition(screenPosition.translate([0, 1]), {clipDirection: 'forward'}).translate([0, -1])
    } else {
      return screenPosition
    }
  }
}
