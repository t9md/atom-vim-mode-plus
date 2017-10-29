"use babel"

const {Range} = require("atom")
const Base = require("./base")

class MiscCommand extends Base {
  static operationKind = "misc-command"
}
MiscCommand.register(false)

class Mark extends MiscCommand {
  async execute() {
    const mark = await this.readCharPromised()
    if (mark) {
      this.vimState.mark.set(mark, this.getCursorBufferPosition())
    }
  }
}
Mark.register()

class ReverseSelections extends MiscCommand {
  execute() {
    this.swrap.setReversedState(this.editor, !this.editor.getLastSelection().isReversed())
    if (this.isMode("visual", "blockwise")) {
      this.getLastBlockwiseSelection().autoscroll()
    }
  }
}
ReverseSelections.register()

class BlockwiseOtherEnd extends ReverseSelections {
  execute() {
    for (const blockwiseSelection of this.getBlockwiseSelections()) {
      blockwiseSelection.reverse()
    }
    super.execute()
  }
}
BlockwiseOtherEnd.register()

class Undo extends MiscCommand {
  setCursorPosition({newRanges, oldRanges, strategy}) {
    const lastCursor = this.editor.getLastCursor() // This is restored cursor

    const changedRange =
      strategy === "smart"
        ? this.utils.findRangeContainsPoint(newRanges, lastCursor.getBufferPosition())
        : this.utils.sortRanges(newRanges.concat(oldRanges))[0]

    if (changedRange) {
      if (this.utils.isLinewiseRange(changedRange)) this.utils.setBufferRow(lastCursor, changedRange.start.row)
      else lastCursor.setBufferPosition(changedRange.start)
    }
  }

  mutateWithTrackChanges() {
    const newRanges = []
    const oldRanges = []

    // Collect changed range while mutating text-state by fn callback.
    const disposable = this.editor.getBuffer().onDidChange(({newRange, oldRange}) => {
      if (newRange.isEmpty()) {
        oldRanges.push(oldRange) // Remove only
      } else {
        newRanges.push(newRange)
      }
    })

    this.mutate()
    disposable.dispose()
    return {newRanges, oldRanges}
  }

  flashChanges({newRanges, oldRanges}) {
    const isMultipleSingleLineRanges = ranges => ranges.length > 1 && ranges.every(this.utils.isSingleLineRange)

    if (newRanges.length > 0) {
      if (this.isMultipleAndAllRangeHaveSameColumnAndConsecutiveRows(newRanges)) return

      newRanges = newRanges.map(range => this.utils.humanizeBufferRange(this.editor, range))
      newRanges = this.filterNonLeadingWhiteSpaceRange(newRanges)

      const type = isMultipleSingleLineRanges(newRanges) ? "undo-redo-multiple-changes" : "undo-redo"
      this.flash(newRanges, {type})
    } else {
      if (this.isMultipleAndAllRangeHaveSameColumnAndConsecutiveRows(oldRanges)) return

      if (isMultipleSingleLineRanges(oldRanges)) {
        oldRanges = this.filterNonLeadingWhiteSpaceRange(oldRanges)
        this.flash(oldRanges, {type: "undo-redo-multiple-delete"})
      }
    }
  }

  filterNonLeadingWhiteSpaceRange(ranges) {
    return ranges.filter(range => !this.utils.isLeadingWhiteSpaceRange(this.editor, range))
  }

  // [TODO] Improve further by checking oldText, newText?
  // [Purpose of this function]
  // Suppress flash when undo/redoing toggle-comment while flashing undo/redo of occurrence operation.
  // This huristic approach never be perfect.
  // Ultimately cannnot distinguish occurrence operation.
  isMultipleAndAllRangeHaveSameColumnAndConsecutiveRows(ranges) {
    if (ranges.length <= 1) {
      return false
    }

    const {start: {column: startColumn}, end: {column: endColumn}} = ranges[0]
    let previousRow

    for (const range of ranges) {
      const {start, end} = range
      if (start.column !== startColumn || end.column !== endColumn) return false
      if (previousRow != null && previousRow + 1 !== start.row) return false
      previousRow = start.row
    }
    return true
  }

  flash(ranges, options) {
    if (options.timeout == null) options.timeout = 500
    this.onDidFinishOperation(() => this.vimState.flash(ranges, options))
  }

  execute() {
    const {newRanges, oldRanges} = this.mutateWithTrackChanges()

    for (const selection of this.editor.getSelections()) {
      selection.clear()
    }

    if (this.getConfig("setCursorToStartOfChangeOnUndoRedo")) {
      const strategy = this.getConfig("setCursorToStartOfChangeOnUndoRedoStrategy")
      this.setCursorPosition({newRanges, oldRanges, strategy})
      this.vimState.clearSelections()
    }

    if (this.getConfig("flashOnUndoRedo")) this.flashChanges({newRanges, oldRanges})
    this.activateMode("normal")
  }

  mutate() {
    this.editor.undo()
  }
}
Undo.register()

class Redo extends Undo {
  mutate() {
    this.editor.redo()
  }
}
Redo.register()

// zc
class FoldCurrentRow extends MiscCommand {
  execute() {
    for (const point of this.getCursorBufferPositions()) {
      this.editor.foldBufferRow(point.row)
    }
  }
}
FoldCurrentRow.register()

// zo
class UnfoldCurrentRow extends MiscCommand {
  execute() {
    for (const point of this.getCursorBufferPositions()) {
      this.editor.unfoldBufferRow(point.row)
    }
  }
}
UnfoldCurrentRow.register()

// za
class ToggleFold extends MiscCommand {
  execute() {
    for (const point of this.getCursorBufferPositions()) {
      this.editor.toggleFoldAtBufferRow(point.row)
    }
  }
}
ToggleFold.register()

// Base of zC, zO, zA
class FoldCurrentRowRecursivelyBase extends MiscCommand {
  eachFoldStartRow(fn) {
    for (const {row} of this.getCursorBufferPositionsOrdered().reverse()) {
      if (!this.editor.isFoldableAtBufferRow(row)) continue

      this.utils
        .getFoldRowRangesContainedByFoldStartsAtRow(this.editor, row)
        .map(rowRange => rowRange[0]) // mapt to startRow of fold
        .reverse() // reverse to process encolosed(nested) fold first than encolosing fold.
        .forEach(fn)
    }
  }

  foldRecursively() {
    this.eachFoldStartRow(row => {
      if (!this.editor.isFoldedAtBufferRow(row)) this.editor.foldBufferRow(row)
    })
  }

  unfoldRecursively() {
    this.eachFoldStartRow(row => {
      if (this.editor.isFoldedAtBufferRow(row)) this.editor.unfoldBufferRow(row)
    })
  }
}
FoldCurrentRowRecursivelyBase.register(false)

// zC
class FoldCurrentRowRecursively extends FoldCurrentRowRecursivelyBase {
  execute() {
    this.foldRecursively()
  }
}
FoldCurrentRowRecursively.register()

// zO
class UnfoldCurrentRowRecursively extends FoldCurrentRowRecursivelyBase {
  execute() {
    this.unfoldRecursively()
  }
}
UnfoldCurrentRowRecursively.register()

// zA
class ToggleFoldRecursively extends FoldCurrentRowRecursivelyBase {
  execute() {
    if (this.editor.isFoldedAtBufferRow(this.getCursorBufferPosition().row)) {
      this.unfoldRecursively()
    } else {
      this.foldRecursively()
    }
  }
}
ToggleFoldRecursively.register()

// zR
class UnfoldAll extends MiscCommand {
  execute() {
    this.editor.unfoldAll()
  }
}
UnfoldAll.register()

// zM
class FoldAll extends MiscCommand {
  execute() {
    const {allFold} = this.utils.getFoldInfoByKind(this.editor)
    if (!allFold) return

    this.editor.unfoldAll()
    for (const {indent, startRow, endRow} of allFold.rowRangesWithIndent) {
      if (indent <= this.getConfig("maxFoldableIndentLevel")) {
        this.editor.foldBufferRowRange(startRow, endRow)
      }
    }
    this.editor.scrollToCursorPosition({center: true})
  }
}
FoldAll.register()

// zr
class UnfoldNextIndentLevel extends MiscCommand {
  execute() {
    const {folded} = this.utils.getFoldInfoByKind(this.editor)
    if (!folded) return
    const {minIndent, rowRangesWithIndent} = folded
    const count = this.utils.limitNumber(this.getCount() - 1, {min: 0})
    const targetIndents = this.utils.getList(minIndent, minIndent + count)
    for (const {indent, startRow} of rowRangesWithIndent) {
      if (targetIndents.includes(indent)) {
        this.editor.unfoldBufferRow(startRow)
      }
    }
  }
}
UnfoldNextIndentLevel.register()

// zm
class FoldNextIndentLevel extends MiscCommand {
  execute() {
    const {unfolded, allFold} = this.utils.getFoldInfoByKind(this.editor)
    if (!unfolded) return
    // FIXME: Why I need unfoldAll()? Why can't I just fold non-folded-fold only?
    // Unless unfoldAll() here, @editor.unfoldAll() delete foldMarker but fail
    // to render unfolded rows correctly.
    // I believe this is bug of text-buffer's markerLayer which assume folds are
    // created **in-order** from top-row to bottom-row.
    this.editor.unfoldAll()

    const maxFoldable = this.getConfig("maxFoldableIndentLevel")
    let fromLevel = Math.min(unfolded.maxIndent, maxFoldable)
    const count = this.utils.limitNumber(this.getCount() - 1, {min: 0})
    fromLevel = this.utils.limitNumber(fromLevel - count, {min: 0})
    const targetIndents = this.utils.getList(fromLevel, maxFoldable)
    for (const {indent, startRow, endRow} of allFold.rowRangesWithIndent) {
      if (targetIndents.includes(indent)) {
        this.editor.foldBufferRowRange(startRow, endRow)
      }
    }
  }
}
FoldNextIndentLevel.register()

class ReplaceModeBackspace extends MiscCommand {
  static commandScope = "atom-text-editor.vim-mode-plus.insert-mode.replace"

  execute() {
    for (const selection of this.editor.getSelections()) {
      // char might be empty.
      const char = this.vimState.modeManager.getReplacedCharForSelection(selection)
      if (char != null) {
        selection.selectLeft()
        if (!selection.insertText(char).isEmpty()) selection.cursor.moveLeft()
      }
    }
  }
}
ReplaceModeBackspace.register()

// ctrl-e scroll lines downwards
class MiniScrollDown extends MiscCommand {
  defaultCount = this.getConfig("defaultScrollRowsOnMiniScroll")
  direction = "down"

  keepCursorOnScreen(scrollRows) {
    const cursor = this.editor.getLastCursor()
    const row = cursor.getScreenRow()
    const offset = 2
    const validScreenRow =
      this.direction === "down"
        ? this.utils.limitNumber(row, {min: this.editor.getFirstVisibleScreenRow() + offset})
        : this.utils.limitNumber(row, {max: this.editor.getLastVisibleScreenRow() - offset})
    if (row !== validScreenRow) {
      this.utils.setBufferRow(cursor, this.editor.bufferRowForScreenRow(validScreenRow), {autoscroll: false})
    }
  }

  execute() {
    const amountOfScreenRows = this.direction === "down" ? this.getCount() : -this.getCount()
    const duration = this.getConfig("smoothScrollOnMiniScroll") ? this.getConfig("smoothScrollOnMiniScrollDuration") : 0
    this.vimState.requestScroll({amountOfScreenRows, duration, onFinish: this.keepCursorOnScreen.bind(this)})
  }
}
MiniScrollDown.register()

// ctrl-y scroll lines upwards
class MiniScrollUp extends MiniScrollDown {
  direction = "up"
}
MiniScrollUp.register()

// RedrawCursorLineAt{XXX} in viewport.
// +-------------------------------------------+
// | where        | no move | move to 1st char |
// |--------------+---------+------------------|
// | top          | z t     | z enter          |
// | upper-middle | z u     | z space          |
// | middle       | z z     | z .              |
// | bottom       | z b     | z -              |
// +-------------------------------------------+
class RedrawCursorLine extends MiscCommand {
  moveToFirstCharacterOfLine = false

  execute() {
    const scrollTop = Math.round(this.getScrollTop())
    const onFinish = () => {
      if (this.editorElement.getScrollTop() !== scrollTop && !this.editor.getScrollPastEnd()) {
        this.recommendToEnableScrollPastEnd()
      }
    }
    const duration = this.getConfig("smoothScrollOnRedrawCursorLine")
      ? this.getConfig("smoothScrollOnRedrawCursorLineDuration")
      : 0
    this.vimState.requestScroll({scrollTop, duration, onFinish})
    if (this.moveToFirstCharacterOfLine) this.editor.moveToFirstCharacterOfLine()
  }

  getScrollTop() {
    const {top} = this.editorElement.pixelPositionForScreenPosition(this.editor.getCursorScreenPosition())
    const editorHeight = this.editorElement.getHeight()
    const lineHeightInPixel = this.editor.getLineHeightInPixels()
    return this.utils.limitNumber(top - editorHeight * this.coefficient, {
      min: top - editorHeight + lineHeightInPixel * 3,
      max: top - lineHeightInPixel * 2,
    })
  }

  recommendToEnableScrollPastEnd() {
    const message = [
      "vim-mode-plus",
      "- Failed to scroll. To successfully scroll, `editor.scrollPastEnd` need to be enabled.",
      '- You can do it from `"Settings" > "Editor" > "Scroll Past End"`.',
      "- Or **do you allow vmp enable it for you now?**",
    ].join("\n")

    const notification = atom.notifications.addInfo(message, {
      dismissable: true,
      buttons: [
        {
          text: "No thanks.",
          onDidClick: () => notification.dismiss(),
        },
        {
          text: "OK. Enable it now!!",
          onDidClick: () => {
            atom.config.set(`editor.scrollPastEnd`, true)
            notification.dismiss()
          },
        },
      ],
    })
  }
}
RedrawCursorLine.register(false)

// top: zt
class RedrawCursorLineAtTop extends RedrawCursorLine {
  coefficient = 0
}
RedrawCursorLineAtTop.register()

// top: z enter
class RedrawCursorLineAtTopAndMoveToFirstCharacterOfLine extends RedrawCursorLine {
  coefficient = 0
  moveToFirstCharacterOfLine = true
}
RedrawCursorLineAtTopAndMoveToFirstCharacterOfLine.register()

// upper-middle: zu
class RedrawCursorLineAtUpperMiddle extends RedrawCursorLine {
  coefficient = 0.25
}
RedrawCursorLineAtUpperMiddle.register()

// upper-middle: z space
class RedrawCursorLineAtUpperMiddleAndMoveToFirstCharacterOfLine extends RedrawCursorLine {
  coefficient = 0.25
  moveToFirstCharacterOfLine = true
}
RedrawCursorLineAtUpperMiddleAndMoveToFirstCharacterOfLine.register()

// middle: zz
class RedrawCursorLineAtMiddle extends RedrawCursorLine {
  coefficient = 0.5
}
RedrawCursorLineAtMiddle.register()

// middle: z.
class RedrawCursorLineAtMiddleAndMoveToFirstCharacterOfLine extends RedrawCursorLine {
  coefficient = 0.5
  moveToFirstCharacterOfLine = true
}
RedrawCursorLineAtMiddleAndMoveToFirstCharacterOfLine.register()

// bottom: zb
class RedrawCursorLineAtBottom extends RedrawCursorLine {
  coefficient = 1
}
RedrawCursorLineAtBottom.register()

// bottom: z-
class RedrawCursorLineAtBottomAndMoveToFirstCharacterOfLine extends RedrawCursorLine {
  coefficient = 1
  moveToFirstCharacterOfLine = true
}
RedrawCursorLineAtBottomAndMoveToFirstCharacterOfLine.register()

// Horizontal Scroll without changing cursor position
// -------------------------
// zs
class ScrollCursorToLeft extends MiscCommand {
  which = "left"
  execute() {
    const translation = this.which === "left" ? [0, 0] : [0, 1]
    const screenPosition = this.editor.getCursorScreenPosition().translate(translation)
    const pixel = this.editorElement.pixelPositionForScreenPosition(screenPosition)
    if (this.which === "left") {
      this.editorElement.setScrollLeft(pixel.left)
    } else {
      this.editorElement.setScrollRight(pixel.left)
      this.editor.component.updateSync() // FIXME: This is necessary maybe because of bug of atom-core.
    }
  }
}
ScrollCursorToLeft.register()

// ze
class ScrollCursorToRight extends ScrollCursorToLeft {
  which = "right"
}
ScrollCursorToRight.register()

// insert-mode specific commands
// -------------------------
class InsertMode extends MiscCommand {}
InsertMode.commandScope = "atom-text-editor.vim-mode-plus.insert-mode"

class ActivateNormalModeOnce extends InsertMode {
  execute() {
    const cursorsToMoveRight = this.editor.getCursors().filter(cursor => !cursor.isAtBeginningOfLine())
    this.vimState.activate("normal")
    for (const cursor of cursorsToMoveRight) {
      this.utils.moveCursorRight(cursor)
    }

    let disposable = atom.commands.onDidDispatch(event => {
      if (event.type === this.getCommandName()) return

      disposable.dispose()
      disposable = null
      this.vimState.activate("insert")
    })
  }
}
ActivateNormalModeOnce.register()

class InsertRegister extends InsertMode {
  async execute() {
    const input = await this.readCharPromised()
    if (input) {
      this.editor.transact(() => {
        for (const selection of this.editor.getSelections()) {
          const text = this.vimState.register.getText(input, selection)
          selection.insertText(text)
        }
      })
    }
  }
}
InsertRegister.register()

class InsertLastInserted extends InsertMode {
  execute() {
    const text = this.vimState.register.getText(".")
    this.editor.insertText(text)
  }
}
InsertLastInserted.register()

class CopyFromLineAbove extends InsertMode {
  rowDelta = -1

  execute() {
    const translation = [this.rowDelta, 0]
    this.editor.transact(() => {
      for (let selection of this.editor.getSelections()) {
        const point = selection.cursor.getBufferPosition().translate(translation)
        if (point.row < 0) continue

        const range = Range.fromPointWithDelta(point, 0, 1)
        const text = this.editor.getTextInBufferRange(range)
        if (text) selection.insertText(text)
      }
    })
  }
}
CopyFromLineAbove.register()

class CopyFromLineBelow extends CopyFromLineAbove {
  rowDelta = +1
}
CopyFromLineBelow.register()

class NextTab extends MiscCommand {
  defaultCount = 0

  execute() {
    const count = this.getCount()
    const pane = atom.workspace.paneForItem(this.editor)

    if (count) pane.activateItemAtIndex(count - 1)
    else pane.activateNextItem()
  }
}
NextTab.register()

class PreviousTab extends MiscCommand {
  execute() {
    atom.workspace.paneForItem(this.editor).activatePreviousItem()
  }
}
PreviousTab.register()
