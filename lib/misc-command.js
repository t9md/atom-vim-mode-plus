"use babel"

const {Range} = require("atom")
const Base = require("./base")

class MiscCommand extends Base {
  static command = false
  static operationKind = "misc-command"
}

class Mark extends MiscCommand {
  async execute() {
    const mark = await this.readCharPromised()
    if (mark) {
      this.vimState.mark.set(mark, this.getCursorBufferPosition())
    }
  }
}

class ReverseSelections extends MiscCommand {
  execute() {
    this.swrap.setReversedState(this.editor, !this.editor.getLastSelection().isReversed())
    if (this.isMode("visual", "blockwise")) {
      this.getLastBlockwiseSelection().autoscroll()
    }
  }
}

class BlockwiseOtherEnd extends ReverseSelections {
  execute() {
    for (const blockwiseSelection of this.getBlockwiseSelections()) {
      blockwiseSelection.reverse()
    }
    super.execute()
  }
}

class Undo extends MiscCommand {
  execute() {
    const newRanges = []
    const oldRanges = []

    const disposable = this.editor.getBuffer().onDidChangeText(event => {
      for (const {newRange, oldRange} of event.changes) {
        if (newRange.isEmpty()) {
          oldRanges.push(oldRange) // Remove only
        } else {
          newRanges.push(newRange)
        }
      }
    })

    if (this.name === "Undo") {
      this.editor.undo()
    } else {
      this.editor.redo()
    }

    disposable.dispose()

    for (const selection of this.editor.getSelections()) {
      selection.clear()
    }

    if (this.getConfig("setCursorToStartOfChangeOnUndoRedo")) {
      const strategy = this.getConfig("setCursorToStartOfChangeOnUndoRedoStrategy")
      this.setCursorPosition({newRanges, oldRanges, strategy})
      this.vimState.clearSelections()
    }

    if (this.getConfig("flashOnUndoRedo")) {
      if (newRanges.length) {
        this.flashChanges(newRanges, "changes")
      } else {
        this.flashChanges(oldRanges, "deletes")
      }
    }
    this.activateMode("normal")
  }

  setCursorPosition({newRanges, oldRanges, strategy}) {
    const lastCursor = this.editor.getLastCursor() // This is restored cursor

    let changedRange

    if (strategy === "smart") {
      changedRange = this.utils.findRangeContainsPoint(newRanges, lastCursor.getBufferPosition())
    } else if (strategy === "simple") {
      changedRange = this.utils.sortRanges(newRanges.concat(oldRanges))[0]
    }

    if (changedRange) {
      if (this.utils.isLinewiseRange(changedRange)) this.utils.setBufferRow(lastCursor, changedRange.start.row)
      else lastCursor.setBufferPosition(changedRange.start)
    }
  }

  flashChanges(ranges, mutationType) {
    const isMultipleSingleLineRanges = ranges => ranges.length > 1 && ranges.every(this.utils.isSingleLineRange)
    const humanizeNewLineForBufferRange = this.utils.humanizeNewLineForBufferRange.bind(null, this.editor)
    const isNotLeadingWhiteSpaceRange = this.utils.isNotLeadingWhiteSpaceRange.bind(null, this.editor)
    if (!this.utils.isMultipleAndAllRangeHaveSameColumnAndConsecutiveRows(ranges)) {
      ranges = ranges.map(humanizeNewLineForBufferRange)
      const type = isMultipleSingleLineRanges(ranges) ? `undo-redo-multiple-${mutationType}` : "undo-redo"
      if (!(type === "undo-redo" && mutationType === "deletes")) {
        this.vimState.flash(ranges.filter(isNotLeadingWhiteSpaceRange), {type})
      }
    }
  }
}

class Redo extends Undo {}

// zc
class FoldCurrentRow extends MiscCommand {
  execute() {
    for (const point of this.getCursorBufferPositions()) {
      this.editor.foldBufferRow(point.row)
    }
  }
}

// zo
class UnfoldCurrentRow extends MiscCommand {
  execute() {
    for (const point of this.getCursorBufferPositions()) {
      this.editor.unfoldBufferRow(point.row)
    }
  }
}

// za
class ToggleFold extends MiscCommand {
  execute() {
    for (const point of this.getCursorBufferPositions()) {
      this.editor.toggleFoldAtBufferRow(point.row)
    }
  }
}

// Base of zC, zO, zA
class FoldCurrentRowRecursivelyBase extends MiscCommand {
  static command = false
  eachFoldStartRow(fn) {
    for (const {row} of this.getCursorBufferPositionsOrdered().reverse()) {
      if (!this.editor.isFoldableAtBufferRow(row)) continue

      const foldRanges = this.utils.getCodeFoldRanges(this.editor)
      const enclosingFoldRange = foldRanges.find(range => range.start.row === row)
      const enclosedFoldRanges = foldRanges.filter(range => enclosingFoldRange.containsRange(range))

      // Why reverse() is to process encolosed(nested) fold first than encolosing fold.
      enclosedFoldRanges.reverse().forEach(range => fn(range.start.row))
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

// zC
class FoldCurrentRowRecursively extends FoldCurrentRowRecursivelyBase {
  execute() {
    this.foldRecursively()
  }
}

// zO
class UnfoldCurrentRowRecursively extends FoldCurrentRowRecursivelyBase {
  execute() {
    this.unfoldRecursively()
  }
}

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

// zR
class UnfoldAll extends MiscCommand {
  execute() {
    this.editor.unfoldAll()
  }
}

// zM
class FoldAll extends MiscCommand {
  execute() {
    const {allFold} = this.utils.getFoldInfoByKind(this.editor)
    if (!allFold) return

    this.editor.unfoldAll()
    for (const {indent, range} of allFold.listOfRangeAndIndent) {
      if (indent <= this.getConfig("maxFoldableIndentLevel")) {
        this.editor.foldBufferRange(range)
      }
    }
    this.editor.scrollToCursorPosition({center: true})
  }
}

// zr
class UnfoldNextIndentLevel extends MiscCommand {
  execute() {
    const {folded} = this.utils.getFoldInfoByKind(this.editor)
    if (!folded) return
    const {minIndent, listOfRangeAndIndent} = folded
    const targetIndents = this.utils.getList(minIndent, minIndent + this.getCount() - 1)
    for (const {indent, range} of listOfRangeAndIndent) {
      if (targetIndents.includes(indent)) {
        this.editor.unfoldBufferRow(range.start.row)
      }
    }
  }
}

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
    fromLevel = this.limitNumber(fromLevel - this.getCount() - 1, {min: 0})
    const targetIndents = this.utils.getList(fromLevel, maxFoldable)
    for (const {indent, range} of allFold.listOfRangeAndIndent) {
      if (targetIndents.includes(indent)) {
        this.editor.foldBufferRange(range)
      }
    }
  }
}

// ctrl-e scroll lines downwards
class MiniScrollDown extends MiscCommand {
  defaultCount = this.getConfig("defaultScrollRowsOnMiniScroll")
  direction = "down"

  keepCursorOnScreen() {
    const cursor = this.editor.getLastCursor()
    const row = cursor.getScreenRow()
    const offset = 2
    const validRow =
      this.direction === "down"
        ? this.limitNumber(row, {min: this.editor.getFirstVisibleScreenRow() + offset})
        : this.limitNumber(row, {max: this.editor.getLastVisibleScreenRow() - offset})
    if (row !== validRow) {
      this.utils.setBufferRow(cursor, this.editor.bufferRowForScreenRow(validRow), {autoscroll: false})
    }
  }

  execute() {
    this.vimState.requestScroll({
      amountOfPixels: (this.direction === "down" ? 1 : -1) * this.getCount() * this.editor.getLineHeightInPixels(),
      duration: this.getSmoothScrollDuation("MiniScroll"),
      onFinish: () => this.keepCursorOnScreen(),
    })
  }
}

// ctrl-y scroll lines upwards
class MiniScrollUp extends MiniScrollDown {
  direction = "up"
}

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
  static command = false
  static coefficientByName = {
    RedrawCursorLineAtTop: 0,
    RedrawCursorLineAtUpperMiddle: 0.25,
    RedrawCursorLineAtMiddle: 0.5,
    RedrawCursorLineAtBottom: 1,
  }

  initialize() {
    const baseName = this.name.replace(/AndMoveToFirstCharacterOfLine$/, "")
    this.coefficient = this.constructor.coefficientByName[baseName]
    this.moveToFirstCharacterOfLine = this.name.endsWith("AndMoveToFirstCharacterOfLine")
    super.initialize()
  }

  execute() {
    const scrollTop = Math.round(this.getScrollTop())
    this.vimState.requestScroll({
      scrollTop: scrollTop,
      duration: this.getSmoothScrollDuation("RedrawCursorLine"),
      onFinish: () => {
        if (this.editorElement.getScrollTop() !== scrollTop && !this.editor.getScrollPastEnd()) {
          this.recommendToEnableScrollPastEnd()
        }
      },
    })
    if (this.moveToFirstCharacterOfLine) this.editor.moveToFirstCharacterOfLine()
  }

  getScrollTop() {
    const {top} = this.editorElement.pixelPositionForScreenPosition(this.editor.getCursorScreenPosition())
    const editorHeight = this.editorElement.getHeight()
    const lineHeightInPixel = this.editor.getLineHeightInPixels()

    return this.limitNumber(top - editorHeight * this.coefficient, {
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

class RedrawCursorLineAtTop extends RedrawCursorLine {} // zt
class RedrawCursorLineAtTopAndMoveToFirstCharacterOfLine extends RedrawCursorLine {} // z enter
class RedrawCursorLineAtUpperMiddle extends RedrawCursorLine {} // zu
class RedrawCursorLineAtUpperMiddleAndMoveToFirstCharacterOfLine extends RedrawCursorLine {} // z space
class RedrawCursorLineAtMiddle extends RedrawCursorLine {} // z z
class RedrawCursorLineAtMiddleAndMoveToFirstCharacterOfLine extends RedrawCursorLine {} // z .
class RedrawCursorLineAtBottom extends RedrawCursorLine {} // z b
class RedrawCursorLineAtBottomAndMoveToFirstCharacterOfLine extends RedrawCursorLine {} // z -

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

// ze
class ScrollCursorToRight extends ScrollCursorToLeft {
  which = "right"
}

// insert-mode specific commands
// -------------------------
class InsertMode extends MiscCommand {} // just namespace

class ActivateNormalModeOnce extends InsertMode {
  execute() {
    const cursorsToMoveRight = this.editor.getCursors().filter(cursor => !cursor.isAtBeginningOfLine())
    this.vimState.activate("normal")
    for (const cursor of cursorsToMoveRight) {
      this.utils.moveCursorRight(cursor)
    }

    const disposable = atom.commands.onDidDispatch(event => {
      if (event.type !== this.getCommandName()) {
        disposable.dispose()
        this.vimState.activate("insert")
      }
    })
  }
}

class InsertRegister extends InsertMode {
  async execute() {
    const input = await this.readCharPromised()
    if (input) {
      this.editor.transact(() => {
        for (const selection of this.editor.getSelections()) {
          selection.insertText(this.vimState.register.getText(input, selection))
        }
      })
    }
  }
}

class InsertLastInserted extends InsertMode {
  execute() {
    this.editor.insertText(this.vimState.register.getText("."))
  }
}

class CopyFromLineAbove extends InsertMode {
  rowDelta = -1

  execute() {
    const translation = [this.rowDelta, 0]
    this.editor.transact(() => {
      for (const selection of this.editor.getSelections()) {
        const point = selection.cursor.getBufferPosition().translate(translation)
        if (point.row >= 0) {
          const range = Range.fromPointWithDelta(point, 0, 1)
          const text = this.editor.getTextInBufferRange(range)
          if (text) selection.insertText(text)
        }
      }
    })
  }
}

class CopyFromLineBelow extends CopyFromLineAbove {
  rowDelta = +1
}

class NextTab extends MiscCommand {
  defaultCount = 0

  execute() {
    const count = this.getCount()
    const pane = atom.workspace.paneForItem(this.editor)

    if (count) pane.activateItemAtIndex(count - 1)
    else pane.activateNextItem()
  }
}

class PreviousTab extends MiscCommand {
  execute() {
    atom.workspace.paneForItem(this.editor).activatePreviousItem()
  }
}

module.exports = {
  MiscCommand,
  Mark,
  ReverseSelections,
  BlockwiseOtherEnd,
  Undo,
  Redo,
  FoldCurrentRow,
  UnfoldCurrentRow,
  ToggleFold,
  FoldCurrentRowRecursivelyBase,
  FoldCurrentRowRecursively,
  UnfoldCurrentRowRecursively,
  ToggleFoldRecursively,
  UnfoldAll,
  FoldAll,
  UnfoldNextIndentLevel,
  FoldNextIndentLevel,
  MiniScrollDown,
  MiniScrollUp,
  RedrawCursorLine,
  RedrawCursorLineAtTop,
  RedrawCursorLineAtTopAndMoveToFirstCharacterOfLine,
  RedrawCursorLineAtUpperMiddle,
  RedrawCursorLineAtUpperMiddleAndMoveToFirstCharacterOfLine,
  RedrawCursorLineAtMiddle,
  RedrawCursorLineAtMiddleAndMoveToFirstCharacterOfLine,
  RedrawCursorLineAtBottom,
  RedrawCursorLineAtBottomAndMoveToFirstCharacterOfLine,
  ScrollCursorToLeft,
  ScrollCursorToRight,
  ActivateNormalModeOnce,
  InsertRegister,
  InsertLastInserted,
  CopyFromLineAbove,
  CopyFromLineBelow,
  NextTab,
  PreviousTab,
}
