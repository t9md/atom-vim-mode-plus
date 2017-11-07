"use babel"

const _ = require("underscore-plus")
const {Point, Range} = require("atom")

const Base = require("./base")

class Motion extends Base {
  static operationKind = "motion"
  operator = null
  inclusive = false
  wise = "characterwise"
  jump = false
  verticalMotion = false
  moveSucceeded = null
  moveSuccessOnLinewise = false
  selectSucceeded = false
  requireInput = false
  caseSensitivityKind = null

  isReady() {
    return !this.requireInput || this.input != null
  }

  isLinewise() {
    return this.wise === "linewise"
  }

  isBlockwise() {
    return this.wise === "blockwise"
  }

  forceWise(wise) {
    if (wise === "characterwise") {
      this.inclusive = this.wise === "linewise" ? false : !this.inclusive
    }
    this.wise = wise
  }

  resetState() {
    this.selectSucceeded = false
  }

  moveWithSaveJump(cursor) {
    const originalPosition = this.jump && cursor.isLastCursor() ? cursor.getBufferPosition() : undefined

    this.moveCursor(cursor)

    if (originalPosition && !cursor.getBufferPosition().isEqual(originalPosition)) {
      this.vimState.mark.set("`", originalPosition)
      this.vimState.mark.set("'", originalPosition)
    }
  }

  execute() {
    if (this.operator) {
      this.select()
    } else {
      for (const cursor of this.editor.getCursors()) {
        this.moveWithSaveJump(cursor)
      }
    }
    this.editor.mergeCursors()
    this.editor.mergeIntersectingSelections()
  }

  // NOTE: selection is already "normalized" before this function is called.
  select() {
    // need to care was visual for `.` repeated.
    const isOrWasVisual = this.operator.instanceof("SelectBase") || this.name === "CurrentSelection"

    for (const selection of this.editor.getSelections()) {
      selection.modifySelection(() => this.moveWithSaveJump(selection.cursor))

      const selectSucceeded =
        this.moveSucceeded != null
          ? this.moveSucceeded
          : !selection.isEmpty() || (this.isLinewise() && this.moveSuccessOnLinewise)
      if (!this.selectSucceeded) this.selectSucceeded = selectSucceeded

      if (isOrWasVisual || (selectSucceeded && (this.inclusive || this.isLinewise()))) {
        const $selection = this.swrap(selection)
        $selection.saveProperties(true) // save property of "already-normalized-selection"
        $selection.applyWise(this.wise)
      }
    }

    if (this.wise === "blockwise") {
      this.vimState.getLastBlockwiseSelection().autoscroll()
    }
  }

  setCursorBufferRow(cursor, row, options) {
    if (this.verticalMotion && !this.getConfig("stayOnVerticalMotion")) {
      cursor.setBufferPosition(this.getFirstCharacterPositionForBufferRow(row), options)
    } else {
      this.utils.setBufferRow(cursor, row, options)
    }
  }

  // [NOTE]
  // Since this function checks cursor position change, a cursor position MUST be
  // updated IN callback(=fn)
  // Updating point only in callback is wrong-use of this funciton,
  // since it stops immediately because of not cursor position change.
  moveCursorCountTimes(cursor, fn) {
    let oldPosition = cursor.getBufferPosition()
    this.countTimes(this.getCount(), state => {
      fn(state)
      const newPosition = cursor.getBufferPosition()
      if (newPosition.isEqual(oldPosition)) state.stop()
      oldPosition = newPosition
    })
  }

  isCaseSensitive(term) {
    return this.getConfig(`useSmartcaseFor${this.caseSensitivityKind}`)
      ? term.search(/[A-Z]/) !== -1
      : !this.getConfig(`ignoreCaseFor${this.caseSensitivityKind}`)
  }
}
Motion.register(false)

// Used as operator's target in visual-mode.
class CurrentSelection extends Motion {
  selectionExtent = null
  blockwiseSelectionExtent = null
  inclusive = true
  pointInfoByCursor = new Map()

  moveCursor(cursor) {
    if (this.mode === "visual") {
      this.selectionExtent = this.isBlockwise()
        ? this.swrap(cursor.selection).getBlockwiseSelectionExtent()
        : this.editor.getSelectedBufferRange().getExtent()
    } else {
      // `.` repeat case
      cursor.setBufferPosition(cursor.getBufferPosition().translate(this.selectionExtent))
    }
  }

  select() {
    if (this.mode === "visual") {
      super.select()
    } else {
      for (const cursor of this.editor.getCursors()) {
        const pointInfo = this.pointInfoByCursor.get(cursor)
        if (pointInfo) {
          const {cursorPosition, startOfSelection} = pointInfo
          if (cursorPosition.isEqual(cursor.getBufferPosition())) {
            cursor.setBufferPosition(startOfSelection)
          }
        }
      }
      super.select()
    }

    // * Purpose of pointInfoByCursor? see #235 for detail.
    // When stayOnTransformString is enabled, cursor pos is not set on start of
    // of selected range.
    // But I want following behavior, so need to preserve position info.
    //  1. `vj>.` -> indent same two rows regardless of current cursor's row.
    //  2. `vj>j.` -> indent two rows from cursor's row.
    for (const cursor of this.editor.getCursors()) {
      const startOfSelection = cursor.selection.getBufferRange().start
      this.onDidFinishOperation(() => {
        cursorPosition = cursor.getBufferPosition()
        this.pointInfoByCursor.set(cursor, {startOfSelection, cursorPosition})
      })
    }
  }
}
CurrentSelection.register(false)

class MoveLeft extends Motion {
  moveCursor(cursor) {
    const allowWrap = this.getConfig("wrapLeftRightMotion")
    this.moveCursorCountTimes(cursor, () => this.utils.moveCursorLeft(cursor, {allowWrap}))
  }
}
MoveLeft.register()

class MoveRight extends Motion {
  moveCursor(cursor) {
    const allowWrap = this.getConfig("wrapLeftRightMotion")

    this.moveCursorCountTimes(cursor, () => {
      this.editor.unfoldBufferRow(cursor.getBufferRow())

      // - When `wrapLeftRightMotion` enabled and executed as pure-motion in `normal-mode`,
      //   we need to move **again** to wrap to next-line if it rached to EOL.
      // - Expression `!this.operator` means normal-mode motion.
      // - Expression `this.mode === "normal"` is not appropreate since it matches `x` operator's target case.
      const needMoveAgain = allowWrap && !this.operator && !cursor.isAtEndOfLine()

      this.utils.moveCursorRight(cursor, {allowWrap})

      if (needMoveAgain && cursor.isAtEndOfLine()) {
        this.utils.moveCursorRight(cursor, {allowWrap})
      }
    })
  }
}
MoveRight.register()

class MoveRightBufferColumn extends Motion {
  moveCursor(cursor) {
    this.utils.setBufferColumn(cursor, cursor.getBufferColumn() + this.getCount())
  }
}
MoveRightBufferColumn.register(false)

class MoveUp extends Motion {
  wise = "linewise"
  wrap = false
  direction = "up"

  getBufferRow(row) {
    const min = 0
    const max = this.getVimLastBufferRow()

    if (this.direction === "up") {
      row = this.getFoldStartRowForRow(row) - 1
      row = this.wrap && row < min ? max : this.utils.limitNumber(row, {min})
    } else {
      row = this.getFoldEndRowForRow(row) + 1
      row = this.wrap && row > max ? min : this.utils.limitNumber(row, {max})
    }
    return this.getFoldStartRowForRow(row)
  }

  moveCursor(cursor) {
    this.moveCursorCountTimes(cursor, () => this.utils.setBufferRow(cursor, this.getBufferRow(cursor.getBufferRow())))
  }
}
MoveUp.register()

class MoveUpWrap extends MoveUp {
  wrap = true
}
MoveUpWrap.register()

class MoveDown extends MoveUp {
  direction = "down"
}
MoveDown.register()

class MoveDownWrap extends MoveDown {
  wrap = true
}
MoveDownWrap.register()

class MoveUpScreen extends Motion {
  wise = "linewise"
  direction = "up"
  moveCursor(cursor) {
    this.moveCursorCountTimes(cursor, () => this.utils.moveCursorUpScreen(cursor))
  }
}
MoveUpScreen.register()

class MoveDownScreen extends MoveUpScreen {
  wise = "linewise"
  direction = "down"
  moveCursor(cursor) {
    this.moveCursorCountTimes(cursor, () => this.utils.moveCursorDownScreen(cursor))
  }
}
MoveDownScreen.register()

class MoveUpToEdge extends Motion {
  wise = "linewise"
  jump = true
  direction = "previous"
  moveCursor(cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const point = this.getPoint(cursor.getScreenPosition())
      if (point) cursor.setScreenPosition(point)
    })
  }

  getPoint(fromPoint) {
    const {column, row: startRow} = fromPoint
    for (const row of this.getScreenRows({startRow, direction: this.direction})) {
      const point = new Point(row, column)
      if (this.isEdge(point)) return point
    }
  }

  isEdge(point) {
    // If point is stoppable and above or below point is not stoppable, it's Edge!
    return (
      this.isStoppable(point) &&
      (!this.isStoppable(point.translate([-1, 0])) || !this.isStoppable(point.translate([+1, 0])))
    )
  }

  isStoppable(point) {
    return (
      this.isNonWhiteSpace(point) ||
      this.isFirstRowOrLastRowAndEqualAfterClipped(point) ||
      // If right or left column is non-white-space char, it's stoppable.
      (this.isNonWhiteSpace(point.translate([0, -1])) && this.isNonWhiteSpace(point.translate([0, +1])))
    )
  }

  isNonWhiteSpace(point) {
    const char = this.utils.getTextInScreenRange(this.editor, Range.fromPointWithDelta(point, 0, 1))
    return char != null && /\S/.test(char)
  }

  isFirstRowOrLastRowAndEqualAfterClipped(point) {
    // In notmal-mode, cursor is NOT stoppable to EOL of non-blank row.
    // So explicitly guard to not answer it stoppable.
    if (this.mode === "normal" && this.utils.pointIsAtEndOfLineAtNonEmptyRow(this.editor, point)) {
      return false
    }

    return (
      (point.row === 0 || point.row === this.getVimLastScreenRow()) &&
      point.isEqual(this.editor.clipScreenPosition(point))
    )
  }
}
MoveUpToEdge.register()

class MoveDownToEdge extends MoveUpToEdge {
  direction = "next"
}
MoveDownToEdge.register()

// word
// -------------------------
class MoveToNextWord extends Motion {
  wordRegex = null

  getPoint(regex, from) {
    let wordRange
    let found = false

    this.scanForward(regex, {from}, ({range, matchText, stop}) => {
      wordRange = range
      // Ignore 'empty line' matches between '\r' and '\n'
      if (matchText === "" && range.start.column !== 0) return
      if (range.start.isGreaterThan(from)) {
        found = true
        stop()
      }
    })

    if (found) {
      const point = wordRange.start
      return this.utils.pointIsAtEndOfLineAtNonEmptyRow(this.editor, point) &&
        !point.isEqual(this.getVimEofBufferPosition())
        ? point.traverse([1, 0])
        : point
    } else {
      return wordRange ? wordRange.end : from
    }
  }

  // Special case: "cw" and "cW" are treated like "ce" and "cE" if the cursor is
  // on a non-blank.  This is because "cw" is interpreted as change-word, and a
  // word does not include the following white space.  {Vi: "cw" when on a blank
  // followed by other blanks changes only the first blank; this is probably a
  // bug, because "dw" deletes all the blanks}
  //
  // Another special case: When using the "w" motion in combination with an
  // operator and the last word moved over is at the end of a line, the end of
  // that word becomes the end of the operated text, not the first word in the
  // next line.
  moveCursor(cursor) {
    const cursorPosition = cursor.getBufferPosition()
    if (this.utils.pointIsAtVimEndOfFile(this.editor, cursorPosition)) return

    const wasOnWhiteSpace = this.utils.pointIsOnWhiteSpace(this.editor, cursorPosition)
    const isTargetOfNormalOperator = this.isTargetOfNormalOperator()

    this.moveCursorCountTimes(cursor, ({isFinal}) => {
      const cursorPosition = cursor.getBufferPosition()
      if (this.utils.isEmptyRow(this.editor, cursorPosition.row) && isTargetOfNormalOperator) {
        cursor.setBufferPosition(cursorPosition.traverse([1, 0]))
      } else {
        const regex = this.wordRegex || cursor.wordRegExp()
        let point = this.getPoint(regex, cursorPosition)
        if (isFinal && isTargetOfNormalOperator) {
          if (this.operator.name === "Change" && !wasOnWhiteSpace) {
            point = cursor.getEndOfCurrentWordBufferPosition({wordRegex: this.wordRegex})
          } else {
            point = Point.min(point, this.utils.getEndOfLineForBufferRow(this.editor, cursorPosition.row))
          }
        }
        cursor.setBufferPosition(point)
      }
    })
  }
}
MoveToNextWord.register()

// b
class MoveToPreviousWord extends Motion {
  wordRegex = null

  moveCursor(cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const point = cursor.getBeginningOfCurrentWordBufferPosition({wordRegex: this.wordRegex})
      cursor.setBufferPosition(point)
    })
  }
}
MoveToPreviousWord.register()

class MoveToEndOfWord extends Motion {
  wordRegex = null
  inclusive = true

  moveToNextEndOfWord(cursor) {
    this.utils.moveCursorToNextNonWhitespace(cursor)
    const point = cursor.getEndOfCurrentWordBufferPosition({wordRegex: this.wordRegex}).translate([0, -1])
    cursor.setBufferPosition(Point.min(point, this.getVimEofBufferPosition()))
  }

  moveCursor(cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const originalPoint = cursor.getBufferPosition()
      this.moveToNextEndOfWord(cursor)
      if (originalPoint.isEqual(cursor.getBufferPosition())) {
        // Retry from right column if cursor was already on EndOfWord
        cursor.moveRight()
        this.moveToNextEndOfWord(cursor)
      }
    })
  }
}
MoveToEndOfWord.register()

// [TODO: Improve, accuracy]
class MoveToPreviousEndOfWord extends MoveToPreviousWord {
  inclusive = true

  moveCursor(cursor) {
    const wordRange = cursor.getCurrentWordBufferRange()
    const cursorPosition = cursor.getBufferPosition()

    // if we're in the middle of a word then we need to move to its start
    let times = this.getCount()
    if (cursorPosition.isGreaterThan(wordRange.start) && cursorPosition.isLessThan(wordRange.end)) {
      times += 1
    }

    for (const i in this.utils.getList(1, times)) {
      const point = cursor.getBeginningOfCurrentWordBufferPosition({wordRegex: this.wordRegex})
      cursor.setBufferPosition(point)
    }

    this.moveToNextEndOfWord(cursor)
    if (cursor.getBufferPosition().isGreaterThanOrEqual(cursorPosition)) {
      cursor.setBufferPosition([0, 0])
    }
  }

  moveToNextEndOfWord(cursor) {
    const point = cursor.getEndOfCurrentWordBufferPosition({wordRegex: this.wordRegex}).translate([0, -1])
    cursor.setBufferPosition(Point.min(point, this.getVimEofBufferPosition()))
  }
}
MoveToPreviousEndOfWord.register()

// Whole word
// -------------------------
class MoveToNextWholeWord extends MoveToNextWord {
  wordRegex = /^$|\S+/g
}
MoveToNextWholeWord.register()

class MoveToPreviousWholeWord extends MoveToPreviousWord {
  wordRegex = /^$|\S+/g
}
MoveToPreviousWholeWord.register()

class MoveToEndOfWholeWord extends MoveToEndOfWord {
  wordRegex = /\S+/
}
MoveToEndOfWholeWord.register()

// [TODO: Improve, accuracy]
class MoveToPreviousEndOfWholeWord extends MoveToPreviousEndOfWord {
  wordRegex = /\S+/
}
MoveToPreviousEndOfWholeWord.register()

// Alphanumeric word [Experimental]
// -------------------------
class MoveToNextAlphanumericWord extends MoveToNextWord {
  wordRegex = /\w+/g
}
MoveToNextAlphanumericWord.register()

class MoveToPreviousAlphanumericWord extends MoveToPreviousWord {
  wordRegex = /\w+/
}
MoveToPreviousAlphanumericWord.register()

class MoveToEndOfAlphanumericWord extends MoveToEndOfWord {
  wordRegex = /\w+/
}
MoveToEndOfAlphanumericWord.register()

// Alphanumeric word [Experimental]
// -------------------------
class MoveToNextSmartWord extends MoveToNextWord {
  wordRegex = /[\w-]+/g
}
MoveToNextSmartWord.register()

class MoveToPreviousSmartWord extends MoveToPreviousWord {
  wordRegex = /[\w-]+/
}
MoveToPreviousSmartWord.register()

class MoveToEndOfSmartWord extends MoveToEndOfWord {
  wordRegex = /[\w-]+/
}
MoveToEndOfSmartWord.register()

// Subword
// -------------------------
class MoveToNextSubword extends MoveToNextWord {
  moveCursor(cursor) {
    this.wordRegex = cursor.subwordRegExp()
    super.moveCursor(cursor)
  }
}
MoveToNextSubword.register()

class MoveToPreviousSubword extends MoveToPreviousWord {
  moveCursor(cursor) {
    this.wordRegex = cursor.subwordRegExp()
    super.moveCursor(cursor)
  }
}
MoveToPreviousSubword.register()

class MoveToEndOfSubword extends MoveToEndOfWord {
  moveCursor(cursor) {
    this.wordRegex = cursor.subwordRegExp()
    super.moveCursor(cursor)
  }
}
MoveToEndOfSubword.register()

// Sentence
// -------------------------
// Sentence is defined as below
//  - end with ['.', '!', '?']
//  - optionally followed by [')', ']', '"', "'"]
//  - followed by ['$', ' ', '\t']
//  - paragraph boundary is also sentence boundary
//  - section boundary is also sentence boundary(ignore)
class MoveToNextSentence extends Motion {
  jump = true
  sentenceRegex = new RegExp(`(?:[\\.!\\?][\\)\\]"']*\\s+)|(\\n|\\r\\n)`, "g")
  direction = "next"

  moveCursor(cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const cursorPosition = cursor.getBufferPosition()

      const point =
        this.direction === "next"
          ? this.getNextStartOfSentence(cursorPosition)
          : this.getPreviousStartOfSentence(cursorPosition)

      cursor.setBufferPosition(point)
    })
  }

  isBlankRow(row) {
    return this.editor.isBufferRowBlank(row)
  }

  getNextStartOfSentence(from) {
    let foundPoint
    this.scanForward(this.sentenceRegex, {from}, ({range, matchText, match, stop}) => {
      if (match[1] != null) {
        const [startRow, endRow] = [range.start.row, range.end.row]
        if (this.skipBlankRow && this.isBlankRow(endRow)) return
        if (this.isBlankRow(startRow) !== this.isBlankRow(endRow)) {
          foundPoint = this.getFirstCharacterPositionForBufferRow(endRow)
        }
      } else {
        foundPoint = range.end
      }
      if (foundPoint) stop()
    })
    return foundPoint || this.getVimEofBufferPosition()
  }

  getPreviousStartOfSentence(from) {
    let foundPoint
    this.scanBackward(this.sentenceRegex, {from}, ({range, matchText, match, stop}) => {
      if (match[1] != null) {
        const [startRow, endRow] = [range.start.row, range.end.row]
        if (!this.isBlankRow(endRow) && this.isBlankRow(startRow)) {
          const point = this.getFirstCharacterPositionForBufferRow(endRow)
          if (point.isLessThan(from)) {
            foundPoint = point
          } else {
            if (this.skipBlankRow) return
            foundPoint = this.getFirstCharacterPositionForBufferRow(startRow)
          }
        }
      } else {
        if (range.end.isLessThan(from)) foundPoint = range.end
      }
      if (foundPoint) stop()
    })
    return foundPoint || [0, 0]
  }
}
MoveToNextSentence.register()

class MoveToPreviousSentence extends MoveToNextSentence {
  direction = "previous"
}
MoveToPreviousSentence.register()

class MoveToNextSentenceSkipBlankRow extends MoveToNextSentence {
  skipBlankRow = true
}
MoveToNextSentenceSkipBlankRow.register()

class MoveToPreviousSentenceSkipBlankRow extends MoveToPreviousSentence {
  skipBlankRow = true
}
MoveToPreviousSentenceSkipBlankRow.register()

// Paragraph
// -------------------------
class MoveToNextParagraph extends Motion {
  jump = true
  direction = "next"

  moveCursor(cursor) {
    this.moveCursorCountTimes(cursor, () => {
      cursor.setBufferPosition(this.getPoint(cursor.getBufferPosition()))
    })
  }

  getPoint(fromPoint) {
    const startRow = fromPoint.row
    let wasBlankRow = this.editor.isBufferRowBlank(startRow)
    for (const row of this.getBufferRows({startRow, direction: this.direction})) {
      const isBlankRow = this.editor.isBufferRowBlank(row)
      if (!wasBlankRow && isBlankRow) {
        return new Point(row, 0)
      }
      wasBlankRow = isBlankRow
    }

    // fallback
    return this.direction === "previous" ? new Point(0, 0) : this.getVimEofBufferPosition()
  }
}
MoveToNextParagraph.register()

class MoveToPreviousParagraph extends MoveToNextParagraph {
  direction = "previous"
}
MoveToPreviousParagraph.register()

// -------------------------
// keymap: 0
class MoveToBeginningOfLine extends Motion {
  moveCursor(cursor) {
    this.utils.setBufferColumn(cursor, 0)
  }
}
MoveToBeginningOfLine.register()

class MoveToColumn extends Motion {
  moveCursor(cursor) {
    this.utils.setBufferColumn(cursor, this.getCount(-1))
  }
}
MoveToColumn.register()

class MoveToLastCharacterOfLine extends Motion {
  moveCursor(cursor) {
    const row = this.getValidVimBufferRow(cursor.getBufferRow() + this.getCount(-1))
    cursor.setBufferPosition([row, Infinity])
    cursor.goalColumn = Infinity
  }
}
MoveToLastCharacterOfLine.register()

class MoveToLastNonblankCharacterOfLineAndDown extends Motion {
  inclusive = true

  moveCursor(cursor) {
    const row = this.utils.limitNumber(cursor.getBufferRow() + this.getCount(-1), {max: this.getVimLastBufferRow()})
    const range = this.utils.findRangeInBufferRow(this.editor, /\S|^/, row, {direction: "backward"})
    cursor.setBufferPosition(range ? range.start : new Point(row, 0))
  }
}
MoveToLastNonblankCharacterOfLineAndDown.register()

// MoveToFirstCharacterOfLine faimily
// ------------------------------------
// ^
class MoveToFirstCharacterOfLine extends Motion {
  moveCursor(cursor) {
    const point = this.getFirstCharacterPositionForBufferRow(cursor.getBufferRow())
    cursor.setBufferPosition(point)
  }
}
MoveToFirstCharacterOfLine.register()

class MoveToFirstCharacterOfLineUp extends MoveToFirstCharacterOfLine {
  wise = "linewise"
  moveCursor(cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const row = this.getValidVimBufferRow(cursor.getBufferRow() - 1)
      cursor.setBufferPosition([row, 0])
    })
    super.moveCursor(cursor)
  }
}
MoveToFirstCharacterOfLineUp.register()

class MoveToFirstCharacterOfLineDown extends MoveToFirstCharacterOfLine {
  wise = "linewise"
  moveCursor(cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const point = cursor.getBufferPosition()
      if (point.row < this.getVimLastBufferRow()) {
        cursor.setBufferPosition(point.translate([+1, 0]))
      }
    })
    super.moveCursor(cursor)
  }
}
MoveToFirstCharacterOfLineDown.register()

class MoveToFirstCharacterOfLineAndDown extends MoveToFirstCharacterOfLineDown {
  getCount() {
    return super.getCount(-1)
  }
}
MoveToFirstCharacterOfLineAndDown.register()

class MoveToScreenColumn extends Motion {
  moveCursor(cursor) {
    const allowOffScreenPosition = this.getConfig("allowMoveToOffScreenColumnOnScreenLineMotion")
    const point = this.utils.getScreenPositionForScreenRow(this.editor, cursor.getScreenRow(), this.which, {
      allowOffScreenPosition,
    })
    if (point) cursor.setScreenPosition(point)
  }
}
MoveToScreenColumn.register(false)

// keymap: g 0
class MoveToBeginningOfScreenLine extends MoveToScreenColumn {
  which = "beginning"
}
MoveToBeginningOfScreenLine.register()

// g ^: `move-to-first-character-of-screen-line`
class MoveToFirstCharacterOfScreenLine extends MoveToScreenColumn {
  which = "first-character"
}
MoveToFirstCharacterOfScreenLine.register()

// keymap: g $
class MoveToLastCharacterOfScreenLine extends MoveToScreenColumn {
  which = "last-character"
}
MoveToLastCharacterOfScreenLine.register()

// keymap: g g
class MoveToFirstLine extends Motion {
  wise = "linewise"
  jump = true
  verticalMotion = true
  moveSuccessOnLinewise = true

  moveCursor(cursor) {
    this.setCursorBufferRow(cursor, this.getValidVimBufferRow(this.getRow()))
    cursor.autoscroll({center: true})
  }

  getRow() {
    return this.getCount(-1)
  }
}
MoveToFirstLine.register()

// keymap: G
class MoveToLastLine extends MoveToFirstLine {
  defaultCount = Infinity
}
MoveToLastLine.register()

// keymap: N% e.g. 10%
class MoveToLineByPercent extends MoveToFirstLine {
  getRow() {
    const percent = this.utils.limitNumber(this.getCount(), {max: 100})
    return Math.floor(this.editor.getLastBufferRow() * (percent / 100))
  }
}
MoveToLineByPercent.register()

class MoveToRelativeLine extends Motion {
  wise = "linewise"
  moveSuccessOnLinewise = true

  moveCursor(cursor) {
    let row
    let count = this.getCount()
    if (count < 0) {
      // Support negative count
      // Negative count can be passed like `operationStack.run("MoveToRelativeLine", {count: -5})`.
      // Currently used in vim-mode-plus-ex-mode pkg.
      count += 1
      row = this.getFoldStartRowForRow(cursor.getBufferRow())
      while (count++ < 0) row = this.getFoldStartRowForRow(row - 1)
    } else {
      count -= 1
      row = this.getFoldEndRowForRow(cursor.getBufferRow())
      while (count-- > 0) row = this.getFoldEndRowForRow(row + 1)
    }
    this.utils.setBufferRow(cursor, row)
  }
}
MoveToRelativeLine.register(false)

class MoveToRelativeLineMinimumTwo extends MoveToRelativeLine {
  getCount(...args) {
    return this.utils.limitNumber(super.getCount(...args), {min: 2})
  }
}
MoveToRelativeLineMinimumTwo.register(false)

// Position cursor without scrolling., H, M, L
// -------------------------
// keymap: H
class MoveToTopOfScreen extends Motion {
  wise = "linewise"
  jump = true
  defaultCount = 0
  verticalMotion = true
  where = "top"

  moveCursor(cursor) {
    const bufferRow = this.editor.bufferRowForScreenRow(this.getScreenRow())
    this.setCursorBufferRow(cursor, bufferRow)
  }

  getScreenRow() {
    const {limitNumber} = this.utils
    const firstVisibleRow = this.editor.getFirstVisibleScreenRow()
    const lastVisibleRow = limitNumber(this.editor.getLastVisibleScreenRow(), {max: this.getVimLastScreenRow()})

    const baseOffset = 2
    if (this.where === "top") {
      const offset = firstVisibleRow === 0 ? 0 : baseOffset
      return limitNumber(firstVisibleRow + this.getCount(-1), {min: firstVisibleRow + offset, max: lastVisibleRow})
    } else if (this.where === "middle") {
      return firstVisibleRow + Math.floor((lastVisibleRow - firstVisibleRow) / 2)
    } else if (this.where === "bottom") {
      const offset = lastVisibleRow === this.getVimLastScreenRow() ? 0 : baseOffset + 1
      return limitNumber(lastVisibleRow - this.getCount(-1), {min: firstVisibleRow, max: lastVisibleRow - offset})
    }
  }
}
MoveToTopOfScreen.register()

// keymap: M
class MoveToMiddleOfScreen extends MoveToTopOfScreen {
  where = "middle"
}
MoveToMiddleOfScreen.register()

// keymap: L
class MoveToBottomOfScreen extends MoveToTopOfScreen {
  where = "bottom"
}
MoveToBottomOfScreen.register()

// Scrolling
// Half: ctrl-d, ctrl-u
// Full: ctrl-f, ctrl-b
// -------------------------
// [FIXME] count behave differently from original Vim.
class Scroll extends Motion {
  static scrollTask = null
  verticalMotion = true

  execute() {
    this.amountOfRowsToScroll = Math.trunc(this.amountOfPage * this.editor.getRowsPerPage() * this.getCount())

    super.execute()

    this.vimState.requestScroll({
      amountOfScreenRows: this.amountOfRowsToScroll,
      duration: this.getSmoothScrollDuation((Math.abs(this.amountOfPage) === 1 ? "Full" : "Half") + "ScrollMotion"),
    })
  }

  moveCursor(cursor) {
    const screenRow = this.getValidVimScreenRow(cursor.getScreenRow() + this.amountOfRowsToScroll)
    this.setCursorBufferRow(cursor, this.editor.bufferRowForScreenRow(screenRow), {autoscroll: false})
  }
}
Scroll.register(false)

// keymap: ctrl-f
class ScrollFullScreenDown extends Scroll {
  amountOfPage = +1
}
ScrollFullScreenDown.register()

// keymap: ctrl-b
class ScrollFullScreenUp extends Scroll {
  amountOfPage = -1
}
ScrollFullScreenUp.register()

// keymap: ctrl-d
class ScrollHalfScreenDown extends Scroll {
  amountOfPage = 0.5
}
ScrollHalfScreenDown.register()

// keymap: ctrl-u
class ScrollHalfScreenUp extends Scroll {
  amountOfPage = -0.5
}
ScrollHalfScreenUp.register()

// keymap: g ctrl-d
class ScrollQuarterScreenDown extends Scroll {
  amountOfPage = 0.25
}
ScrollQuarterScreenDown.register()

// keymap: g ctrl-u
class ScrollQuarterScreenUp extends Scroll {
  amountOfPage = -0.25
}
ScrollQuarterScreenUp.register()

// Find
// -------------------------
// keymap: f
class Find extends Motion {
  backwards = false
  inclusive = true
  offset = 0
  requireInput = true
  caseSensitivityKind = "Find"

  restoreEditorState() {
    if (this._restoreEditorState) this._restoreEditorState()
    this._restoreEditorState = null
  }

  cancelOperation() {
    this.restoreEditorState()
    super.cancelOperation()
  }

  initialize() {
    if (this.getConfig("reuseFindForRepeatFind")) this.repeatIfNecessary()

    if (!this.repeated) {
      const charsMax = this.getConfig("findCharsMax")
      const optionsBase = {purpose: "find", charsMax}

      if (charsMax === 1) {
        this.focusInput(optionsBase)
      } else {
        this._restoreEditorState = this.utils.saveEditorState(this.editor)
        const options = {
          autoConfirmTimeout: this.getConfig("findConfirmByTimeout"),
          onConfirm: input => {
            this.input = input
            if (input) this.processOperation()
            else this.cancelOperation()
          },
          onChange: preConfirmedChars => {
            this.preConfirmedChars = preConfirmedChars
            this.highlightTextInCursorRows(this.preConfirmedChars, "pre-confirm", this.isBackwards())
          },
          onCancel: () => {
            this.vimState.highlightFind.clearMarkers()
            this.cancelOperation()
          },
          commands: {
            "vim-mode-plus:find-next-pre-confirmed": () => this.findPreConfirmed(+1),
            "vim-mode-plus:find-previous-pre-confirmed": () => this.findPreConfirmed(-1),
          },
        }
        this.focusInput(Object.assign(options, optionsBase))
      }
    }
    super.initialize()
  }

  findPreConfirmed(delta) {
    if (this.preConfirmedChars && this.getConfig("highlightFindChar")) {
      const index = this.highlightTextInCursorRows(
        this.preConfirmedChars,
        "pre-confirm",
        this.isBackwards(),
        this.getCount(-1) + delta,
        true
      )
      this.count = index + 1
    }
  }

  repeatIfNecessary() {
    const findCommandNames = ["Find", "FindBackwards", "Till", "TillBackwards"]
    const currentFind = this.globalState.get("currentFind")
    if (currentFind && findCommandNames.includes(this.vimState.operationStack.getLastCommandName())) {
      this.input = currentFind.input
      this.repeated = true
    }
  }

  isBackwards() {
    return this.backwards
  }

  execute() {
    super.execute()
    let decorationType = "post-confirm"
    if (this.operator && !this.operator.instanceof("SelectBase")) {
      decorationType += " long"
    }

    // HACK: When repeated by ",", this.backwards is temporary inverted and
    // restored after execution finished.
    // But final highlightTextInCursorRows is executed in async(=after operation finished).
    // Thus we need to preserve before restored `backwards` value and pass it.
    const backwards = this.isBackwards()
    this.editor.component.getNextUpdatePromise().then(() => {
      this.highlightTextInCursorRows(this.input, decorationType, backwards)
    })
  }

  getPoint(fromPoint) {
    const scanRange = this.editor.bufferRangeForBufferRow(fromPoint.row)
    const points = []
    const regex = this.getRegex(this.input)
    const indexWantAccess = this.getCount(-1)

    const translation = new Point(0, this.isBackwards() ? this.offset : -this.offset)
    if (this.repeated) {
      fromPoint = fromPoint.translate(translation.negate())
    }

    if (this.isBackwards()) {
      if (this.getConfig("findAcrossLines")) scanRange.start = Point.ZERO

      this.editor.backwardsScanInBufferRange(regex, scanRange, ({range, stop}) => {
        if (range.start.isLessThan(fromPoint)) {
          points.push(range.start)
          if (points.length > indexWantAccess) {
            stop()
          }
        }
      })
    } else {
      if (this.getConfig("findAcrossLines")) scanRange.end = this.editor.getEofBufferPosition()
      this.editor.scanInBufferRange(regex, scanRange, ({range, stop}) => {
        if (range.start.isGreaterThan(fromPoint)) {
          points.push(range.start)
          if (points.length > indexWantAccess) {
            stop()
          }
        }
      })
    }

    const point = points[indexWantAccess]
    if (point) return point.translate(translation)
  }

  // FIXME: bad naming, this function must return index
  highlightTextInCursorRows(text, decorationType, backwards, index = this.getCount(-1), adjustIndex = false) {
    if (!this.getConfig("highlightFindChar")) return

    return this.vimState.highlightFind.highlightCursorRows(
      this.getRegex(text),
      decorationType,
      backwards,
      this.offset,
      index,
      adjustIndex
    )
  }

  moveCursor(cursor) {
    const point = this.getPoint(cursor.getBufferPosition())
    if (point) cursor.setBufferPosition(point)
    else this.restoreEditorState()

    if (!this.repeated) this.globalState.set("currentFind", this)
  }

  getRegex(term) {
    const modifiers = this.isCaseSensitive(term) ? "g" : "gi"
    return new RegExp(_.escapeRegExp(term), modifiers)
  }
}
Find.register()

// keymap: F
class FindBackwards extends Find {
  inclusive = false
  backwards = true
}
FindBackwards.register()

// keymap: t
class Till extends Find {
  offset = 1
  getPoint(...args) {
    const point = super.getPoint(...args)
    this.moveSucceeded = point != null
    return point
  }
}
Till.register()

// keymap: T
class TillBackwards extends Till {
  inclusive = false
  backwards = true
}
TillBackwards.register()

// Mark
// -------------------------
// keymap: `
class MoveToMark extends Motion {
  jump = true
  requireInput = true
  input = null
  moveToFirstCharacterOfLine = false

  initialize() {
    this.readChar()
    super.initialize()
  }

  moveCursor(cursor) {
    let point = this.vimState.mark.get(this.input)
    if (point) {
      if (this.moveToFirstCharacterOfLine) {
        point = this.getFirstCharacterPositionForBufferRow(point.row)
      }
      cursor.setBufferPosition(point)
      cursor.autoscroll({center: true})
    }
  }
}
MoveToMark.register()

// keymap: '
class MoveToMarkLine extends MoveToMark {
  wise = "linewise"
  moveToFirstCharacterOfLine = true
}
MoveToMarkLine.register()

// Fold
// -------------------------
class MoveToPreviousFoldStart extends Motion {
  wise = "characterwise"
  which = "start"
  direction = "previous"

  execute() {
    this.rows = this.getFoldRows(this.which)
    if (this.direction === "previous") this.rows.reverse()
    super.execute()
  }

  getFoldRows(which) {
    const toRow = ([startRow, endRow]) => (which === "start" ? startRow : endRow)
    const rows = this.utils.getCodeFoldRowRanges(this.editor).map(toRow)
    return _.sortBy(_.uniq(rows), row => row)
  }

  getScanRows(cursor) {
    const cursorRow = cursor.getBufferRow()
    const isVald = this.direction === "previous" ? row => row < cursorRow : row => row > cursorRow
    return this.rows.filter(isVald)
  }

  detectRow(cursor) {
    return this.getScanRows(cursor)[0]
  }

  moveCursor(cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const row = this.detectRow(cursor)
      if (row != null) this.utils.moveCursorToFirstCharacterAtRow(cursor, row)
    })
  }
}
MoveToPreviousFoldStart.register()

class MoveToNextFoldStart extends MoveToPreviousFoldStart {
  direction = "next"
}
MoveToNextFoldStart.register()

class MoveToPreviousFoldStartWithSameIndent extends MoveToPreviousFoldStart {
  detectRow(cursor) {
    const baseIndentLevel = this.editor.indentationForBufferRow(cursor.getBufferRow())
    return this.getScanRows(cursor).find(row => this.editor.indentationForBufferRow(row) === baseIndentLevel)
  }
}
MoveToPreviousFoldStartWithSameIndent.register()

class MoveToNextFoldStartWithSameIndent extends MoveToPreviousFoldStartWithSameIndent {
  direction = "next"
}
MoveToNextFoldStartWithSameIndent.register()

class MoveToPreviousFoldEnd extends MoveToPreviousFoldStart {
  which = "end"
}
MoveToPreviousFoldEnd.register()

class MoveToNextFoldEnd extends MoveToPreviousFoldEnd {
  direction = "next"
}
MoveToNextFoldEnd.register()

// -------------------------
class MoveToPreviousFunction extends MoveToPreviousFoldStart {
  direction = "previous"
  detectRow(cursor) {
    return this.getScanRows(cursor).find(row => this.utils.isIncludeFunctionScopeForRow(this.editor, row))
  }
}
MoveToPreviousFunction.register()

class MoveToNextFunction extends MoveToPreviousFunction {
  direction = "next"
}
MoveToNextFunction.register()

class MoveToPreviousFunctionAndRedrawCursorLineAtUpperMiddle extends MoveToPreviousFunction {
  execute() {
    super.execute()
    this.getInstance("RedrawCursorLineAtUpperMiddle").execute()
  }
}
MoveToPreviousFunctionAndRedrawCursorLineAtUpperMiddle.register()

class MoveToNextFunctionAndRedrawCursorLineAtUpperMiddle extends MoveToPreviousFunctionAndRedrawCursorLineAtUpperMiddle {
  direction = "next"
}
MoveToNextFunctionAndRedrawCursorLineAtUpperMiddle.register()

// Scope based
// -------------------------
class MoveToPositionByScope extends Motion {
  direction = "backward"
  scope = "."

  moveCursor(cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const cursorPosition = cursor.getBufferPosition()
      const point = this.utils.detectScopeStartPositionForScope(this.editor, cursorPosition, this.direction, this.scope)
      if (point) cursor.setBufferPosition(point)
    })
  }
}
MoveToPositionByScope.register(false)

class MoveToPreviousString extends MoveToPositionByScope {
  direction = "backward"
  scope = "string.begin"
}
MoveToPreviousString.register()

class MoveToNextString extends MoveToPreviousString {
  direction = "forward"
}
MoveToNextString.register()

class MoveToPreviousNumber extends MoveToPositionByScope {
  direction = "backward"
  scope = "constant.numeric"
}
MoveToPreviousNumber.register()

class MoveToNextNumber extends MoveToPreviousNumber {
  direction = "forward"
}
MoveToNextNumber.register()

class MoveToNextOccurrence extends Motion {
  // Ensure this command is available when only has-occurrence
  static commandScope = "atom-text-editor.vim-mode-plus.has-occurrence"
  jump = true
  direction = "next"

  execute() {
    this.ranges = this.utils.sortRanges(this.occurrenceManager.getMarkers().map(marker => marker.getBufferRange()))
    super.execute()
  }

  moveCursor(cursor) {
    const range = this.ranges[this.utils.getIndex(this.getIndex(cursor.getBufferPosition()), this.ranges)]
    const point = range.start
    cursor.setBufferPosition(point, {autoscroll: false})

    this.editor.unfoldBufferRow(point.row)
    if (cursor.isLastCursor()) {
      this.utils.smartScrollToBufferPosition(this.editor, point)
    }

    if (this.getConfig("flashOnMoveToOccurrence")) {
      this.vimState.flash(range, {type: "search"})
    }
  }

  getIndex(fromPoint) {
    const index = this.ranges.findIndex(range => range.start.isGreaterThan(fromPoint))
    return (index >= 0 ? index : 0) + this.getCount(-1)
  }
}
MoveToNextOccurrence.register()

class MoveToPreviousOccurrence extends MoveToNextOccurrence {
  direction = "previous"

  getIndex(fromPoint) {
    const ranges = this.ranges.slice().reverse()
    const range = ranges.find(range => range.end.isLessThan(fromPoint))
    const index = range ? this.ranges.indexOf(range) : this.ranges.length - 1
    return index - this.getCount(-1)
  }
}
MoveToPreviousOccurrence.register()

// -------------------------
// keymap: %
class MoveToPair extends Motion {
  inclusive = true
  jump = true
  member = ["Parenthesis", "CurlyBracket", "SquareBracket"]

  moveCursor(cursor) {
    const point = this.getPoint(cursor)
    if (point) cursor.setBufferPosition(point)
  }

  getPointForTag(point) {
    const pairInfo = this.getInstance("ATag").getPairInfo(point)
    if (!pairInfo) return

    let {openRange, closeRange} = pairInfo
    openRange = openRange.translate([0, +1], [0, -1])
    closeRange = closeRange.translate([0, +1], [0, -1])
    if (openRange.containsPoint(point) && !point.isEqual(openRange.end)) {
      return closeRange.start
    }
    if (closeRange.containsPoint(point) && !point.isEqual(closeRange.end)) {
      return openRange.start
    }
  }

  getPoint(cursor) {
    const cursorPosition = cursor.getBufferPosition()
    const cursorRow = cursorPosition.row
    const point = this.getPointForTag(cursorPosition)
    if (point) return point

    // AAnyPairAllowForwarding return forwarding range or enclosing range.
    const range = this.getInstance("AAnyPairAllowForwarding", {member: this.member}).getRange(cursor.selection)
    if (!range) return

    const {start, end} = range
    if (start.row === cursorRow && start.isGreaterThanOrEqual(cursorPosition)) {
      // Forwarding range found
      return end.translate([0, -1])
    } else if (end.row === cursorPosition.row) {
      // Enclosing range was returned
      // We move to start( open-pair ) only when close-pair was at same row as cursor-row.
      return start
    }
  }
}
MoveToPair.register()
