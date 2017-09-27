const _ = require("underscore-plus")
const {Point, Range} = require("atom")

const {
  moveCursorLeft,
  moveCursorRight,
  moveCursorUpScreen,
  moveCursorDownScreen,
  pointIsAtVimEndOfFile,
  getFirstVisibleScreenRow,
  getLastVisibleScreenRow,
  getValidVimScreenRow,
  getValidVimBufferRow,
  moveCursorToFirstCharacterAtRow,
  sortRanges,
  pointIsOnWhiteSpace,
  moveCursorToNextNonWhitespace,
  isEmptyRow,
  getCodeFoldRowRanges,
  getLargestFoldRangeContainsBufferRow,
  isIncludeFunctionScopeForRow,
  detectScopeStartPositionForScope,
  getBufferRows,
  getTextInScreenRange,
  setBufferRow,
  setBufferColumn,
  limitNumber,
  getIndex,
  smartScrollToBufferPosition,
  pointIsAtEndOfLineAtNonEmptyRow,
  getEndOfLineForBufferRow,
  findRangeInBufferRow,
  saveEditorState,
} = require("./utils")

const Base = require("./base")

class Motion extends Base {
  static initClass() {
    this.extend(false)
    this.operationKind = "motion"
    this.prototype.inclusive = false
    this.prototype.wise = "characterwise"
    this.prototype.jump = false
    this.prototype.verticalMotion = false
    this.prototype.moveSucceeded = null
    this.prototype.moveSuccessOnLinewise = false
    this.prototype.selectSucceeded = false
  }

  constructor(...args) {
    super(...args)
    if (this.mode === "visual") this.wise = this.submode
  }

  isLinewise() {
    return this.wise === "linewise"
  }
  isBlockwise() {
    return this.wise === "blockwise"
  }

  forceWise(wise) {
    if (wise === "characterwise") {
      if (this.wise === "linewise") {
        this.inclusive = false
      } else {
        this.inclusive = !this.inclusive
      }
    }
    return (this.wise = wise)
  }

  resetState() {
    return (this.selectSucceeded = false)
  }

  setBufferPositionSafely(cursor, point) {
    if (point != null) {
      return cursor.setBufferPosition(point)
    }
  }

  setScreenPositionSafely(cursor, point) {
    if (point != null) {
      return cursor.setScreenPosition(point)
    }
  }

  moveWithSaveJump(cursor) {
    let cursorPosition
    if (cursor.isLastCursor() && this.jump) {
      cursorPosition = cursor.getBufferPosition()
    }

    this.moveCursor(cursor)

    if (cursorPosition != null && !cursorPosition.isEqual(cursor.getBufferPosition())) {
      this.vimState.mark.set("`", cursorPosition)
      return this.vimState.mark.set("'", cursorPosition)
    }
  }

  execute() {
    if (this.operator != null) {
      this.select()
    } else {
      for (let cursor of this.editor.getCursors()) {
        this.moveWithSaveJump(cursor)
      }
    }
    this.editor.mergeCursors()
    return this.editor.mergeIntersectingSelections()
  }

  // NOTE: Modify selection by modtion, selection is already "normalized" before this function is called.
  select() {
    const isOrWasVisual =
      (this.operator != null ? this.operator.instanceof("SelectBase") : undefined) || this.is("CurrentSelection") // need to care was visual for `.` repeated.
    for (var selection of this.editor.getSelections()) {
      selection.modifySelection(() => {
        return this.moveWithSaveJump(selection.cursor)
      })

      const selectSucceeded =
        this.moveSucceeded != null
          ? this.moveSucceeded
          : !selection.isEmpty() || (this.isLinewise() && this.moveSuccessOnLinewise)
      if (!this.selectSucceeded) {
        this.selectSucceeded = selectSucceeded
      }

      if (isOrWasVisual || (selectSucceeded && (this.inclusive || this.isLinewise()))) {
        const $selection = this.swrap(selection)
        $selection.saveProperties(true) // save property of "already-normalized-selection"
        $selection.applyWise(this.wise)
      }
    }

    if (this.wise === "blockwise") {
      return this.vimState.getLastBlockwiseSelection().autoscroll()
    }
  }

  setCursorBufferRow(cursor, row, options) {
    if (this.verticalMotion && !this.getConfig("stayOnVerticalMotion")) {
      return cursor.setBufferPosition(this.getFirstCharacterPositionForBufferRow(row), options)
    } else {
      return setBufferRow(cursor, row, options)
    }
  }

  // [NOTE]
  // Since this function checks cursor position change, a cursor position MUST be
  // updated IN callback(=fn)
  // Updating point only in callback is wrong-use of this funciton,
  // since it stops immediately because of not cursor position change.
  moveCursorCountTimes(cursor, fn) {
    let oldPosition = cursor.getBufferPosition()
    return this.countTimes(this.getCount(), function(state) {
      let newPosition
      fn(state)
      if ((newPosition = cursor.getBufferPosition()).isEqual(oldPosition)) {
        state.stop()
      }
      return (oldPosition = newPosition)
    })
  }

  isCaseSensitive(term) {
    if (this.getConfig(`useSmartcaseFor${this.caseSensitivityKind}`)) {
      return term.search(/[A-Z]/) !== -1
    } else {
      return !this.getConfig(`ignoreCaseFor${this.caseSensitivityKind}`)
    }
  }
}
Motion.initClass()

// Used as operator's target in visual-mode.
class CurrentSelection extends Motion {
  static initClass() {
    this.extend(false)
    this.prototype.selectionExtent = null
    this.prototype.blockwiseSelectionExtent = null
    this.prototype.inclusive = true
  }

  constructor(...args) {
    super(...args)
    this.pointInfoByCursor = new Map()
  }

  moveCursor(cursor) {
    if (this.mode === "visual") {
      if (this.isBlockwise()) {
        return (this.blockwiseSelectionExtent = this.swrap(cursor.selection).getBlockwiseSelectionExtent())
      } else {
        return (this.selectionExtent = this.editor.getSelectedBufferRange().getExtent())
      }
    } else {
      // `.` repeat case
      const point = cursor.getBufferPosition()

      if (this.blockwiseSelectionExtent != null) {
        return cursor.setBufferPosition(point.translate(this.blockwiseSelectionExtent))
      } else {
        return cursor.setBufferPosition(point.traverse(this.selectionExtent))
      }
    }
  }

  select() {
    let cursor, cursorPosition, startOfSelection
    if (this.mode === "visual") {
      super.select(...arguments)
    } else {
      for (cursor of this.editor.getCursors()) {
        var pointInfo
        if ((pointInfo = this.pointInfoByCursor.get(cursor))) {
          ;({cursorPosition, startOfSelection} = pointInfo)
          if (cursorPosition.isEqual(cursor.getBufferPosition())) {
            cursor.setBufferPosition(startOfSelection)
          }
        }
      }
      super.select(...arguments)
    }

    // * Purpose of pointInfoByCursor? see #235 for detail.
    // When stayOnTransformString is enabled, cursor pos is not set on start of
    // of selected range.
    // But I want following behavior, so need to preserve position info.
    //  1. `vj>.` -> indent same two rows regardless of current cursor's row.
    //  2. `vj>j.` -> indent two rows from cursor's row.
    return (() => {
      const result = []
      for (cursor of this.editor.getCursors()) {
        startOfSelection = cursor.selection.getBufferRange().start
        result.push(
          this.onDidFinishOperation(() => {
            cursorPosition = cursor.getBufferPosition()
            return this.pointInfoByCursor.set(cursor, {startOfSelection, cursorPosition})
          })
        )
      }
      return result
    })()
  }
}
CurrentSelection.initClass()

class MoveLeft extends Motion {
  static initClass() {
    this.extend()
  }
  moveCursor(cursor) {
    const allowWrap = this.getConfig("wrapLeftRightMotion")
    return this.moveCursorCountTimes(cursor, () => moveCursorLeft(cursor, {allowWrap}))
  }
}
MoveLeft.initClass()

class MoveRight extends Motion {
  static initClass() {
    this.extend()
  }
  canWrapToNextLine(cursor) {
    if (this.isAsTargetExceptSelectInVisualMode() && !cursor.isAtEndOfLine()) {
      return false
    } else {
      return this.getConfig("wrapLeftRightMotion")
    }
  }

  moveCursor(cursor) {
    return this.moveCursorCountTimes(cursor, () => {
      const cursorPosition = cursor.getBufferPosition()
      this.editor.unfoldBufferRow(cursorPosition.row)
      const allowWrap = this.canWrapToNextLine(cursor)
      moveCursorRight(cursor)
      if (cursor.isAtEndOfLine() && allowWrap && !pointIsAtVimEndOfFile(this.editor, cursorPosition)) {
        return moveCursorRight(cursor, {allowWrap})
      }
    })
  }
}
MoveRight.initClass()

class MoveRightBufferColumn extends Motion {
  static initClass() {
    this.extend(false)
  }

  moveCursor(cursor) {
    return setBufferColumn(cursor, cursor.getBufferColumn() + this.getCount())
  }
}
MoveRightBufferColumn.initClass()

class MoveUp extends Motion {
  static initClass() {
    this.extend()
    this.prototype.wise = "linewise"
    this.prototype.wrap = false
  }

  getBufferRow(row) {
    row = this.getNextRow(row)
    if (this.editor.isFoldedAtBufferRow(row)) {
      return getLargestFoldRangeContainsBufferRow(this.editor, row).start.row
    } else {
      return row
    }
  }

  getNextRow(row) {
    const min = 0
    if (this.wrap && row === min) {
      return this.getVimLastBufferRow()
    } else {
      return limitNumber(row - 1, {min})
    }
  }

  moveCursor(cursor) {
    return this.moveCursorCountTimes(cursor, () => {
      return setBufferRow(cursor, this.getBufferRow(cursor.getBufferRow()))
    })
  }
}
MoveUp.initClass()

class MoveUpWrap extends MoveUp {
  static initClass() {
    this.extend()
    this.prototype.wrap = true
  }
}
MoveUpWrap.initClass()

class MoveDown extends MoveUp {
  static initClass() {
    this.extend()
    this.prototype.wise = "linewise"
    this.prototype.wrap = false
  }

  getBufferRow(row) {
    if (this.editor.isFoldedAtBufferRow(row)) {
      ;({row} = getLargestFoldRangeContainsBufferRow(this.editor, row).end)
    }
    return this.getNextRow(row)
  }

  getNextRow(row) {
    const max = this.getVimLastBufferRow()
    if (this.wrap && row >= max) {
      return 0
    } else {
      return limitNumber(row + 1, {max})
    }
  }
}
MoveDown.initClass()

class MoveDownWrap extends MoveDown {
  static initClass() {
    this.extend()
    this.prototype.wrap = true
  }
}
MoveDownWrap.initClass()

class MoveUpScreen extends Motion {
  static initClass() {
    this.extend()
    this.prototype.wise = "linewise"
    this.prototype.direction = "up"
  }

  moveCursor(cursor) {
    return this.moveCursorCountTimes(cursor, () => moveCursorUpScreen(cursor))
  }
}
MoveUpScreen.initClass()

class MoveDownScreen extends MoveUpScreen {
  static initClass() {
    this.extend()
    this.prototype.wise = "linewise"
    this.prototype.direction = "down"
  }

  moveCursor(cursor) {
    return this.moveCursorCountTimes(cursor, () => moveCursorDownScreen(cursor))
  }
}
MoveDownScreen.initClass()

// Move down/up to Edge
// -------------------------
// See t9md/atom-vim-mode-plus#236
// At least v1.7.0. bufferPosition and screenPosition cannot convert accurately
// when row is folded.
class MoveUpToEdge extends Motion {
  static initClass() {
    this.extend()
    this.prototype.wise = "linewise"
    this.prototype.jump = true
    this.prototype.direction = "up"
    this.description = "Move cursor up to **edge** char at same-column"
  }

  moveCursor(cursor) {
    return this.moveCursorCountTimes(cursor, () => {
      return this.setScreenPositionSafely(cursor, this.getPoint(cursor.getScreenPosition()))
    })
  }

  getPoint(fromPoint) {
    const {column} = fromPoint
    for (let row of this.getScanRows(fromPoint)) {
      var point
      if (this.isEdge((point = new Point(row, column)))) {
        return point
      }
    }
  }

  getScanRows({row}) {
    const validRow = getValidVimScreenRow.bind(null, this.editor)
    switch (this.direction) {
      case "up":
        return __range__(validRow(row - 1), 0, true)
      case "down":
        return __range__(validRow(row + 1), this.getVimLastScreenRow(), true)
    }
  }

  isEdge(point) {
    if (this.isStoppablePoint(point)) {
      // If one of above/below point was not stoppable, it's Edge!
      const above = point.translate([-1, 0])
      const below = point.translate([+1, 0])
      return !this.isStoppablePoint(above) || !this.isStoppablePoint(below)
    } else {
      return false
    }
  }

  isStoppablePoint(point) {
    if (this.isNonWhiteSpacePoint(point) || this.isFirstRowOrLastRowAndStoppable(point)) {
      return true
    } else {
      const leftPoint = point.translate([0, -1])
      const rightPoint = point.translate([0, +1])
      return this.isNonWhiteSpacePoint(leftPoint) && this.isNonWhiteSpacePoint(rightPoint)
    }
  }

  isNonWhiteSpacePoint(point) {
    const char = getTextInScreenRange(this.editor, Range.fromPointWithDelta(point, 0, 1))
    return char != null && /\S/.test(char)
  }

  isFirstRowOrLastRowAndStoppable(point) {
    // In normal-mode we adjust cursor by moving-left if cursor at EOL of non-blank row.
    // So explicitly guard to not answer it stoppable.
    if (this.isMode("normal") && pointIsAtEndOfLineAtNonEmptyRow(this.editor, point)) {
      return false
    } else {
      return (
        point.isEqual(this.editor.clipScreenPosition(point)) &&
        (point.row === 0 || point.row === this.getVimLastScreenRow())
      )
    }
  }
}
MoveUpToEdge.initClass()

class MoveDownToEdge extends MoveUpToEdge {
  static initClass() {
    this.extend()
    this.description = "Move cursor down to **edge** char at same-column"
    this.prototype.direction = "down"
  }
}
MoveDownToEdge.initClass()

// word
// -------------------------
class MoveToNextWord extends Motion {
  static initClass() {
    this.extend()
    this.prototype.wordRegex = null
  }

  getPoint(pattern, from) {
    let wordRange = null
    let found = false
    const vimEOF = this.getVimEofBufferPosition(this.editor)

    this.scanForward(pattern, {from}, function({range, matchText, stop}) {
      wordRange = range
      // Ignore 'empty line' matches between '\r' and '\n'
      if (matchText === "" && range.start.column !== 0) {
        return
      }
      if (range.start.isGreaterThan(from)) {
        found = true
        return stop()
      }
    })

    if (found) {
      const point = wordRange.start
      if (pointIsAtEndOfLineAtNonEmptyRow(this.editor, point) && !point.isEqual(vimEOF)) {
        return point.traverse([1, 0])
      } else {
        return point
      }
    } else {
      return (wordRange != null ? wordRange.end : undefined) != null
        ? wordRange != null ? wordRange.end : undefined
        : from
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
    let cursorPosition = cursor.getBufferPosition()
    if (pointIsAtVimEndOfFile(this.editor, cursorPosition)) {
      return
    }
    const wasOnWhiteSpace = pointIsOnWhiteSpace(this.editor, cursorPosition)

    const isAsTargetExceptSelectInVisualMode = this.isAsTargetExceptSelectInVisualMode()
    return this.moveCursorCountTimes(cursor, ({isFinal}) => {
      let point
      cursorPosition = cursor.getBufferPosition()
      if (isEmptyRow(this.editor, cursorPosition.row) && isAsTargetExceptSelectInVisualMode) {
        point = cursorPosition.traverse([1, 0])
      } else {
        const pattern = this.wordRegex != null ? this.wordRegex : cursor.wordRegExp()
        point = this.getPoint(pattern, cursorPosition)
        if (isFinal && isAsTargetExceptSelectInVisualMode) {
          if (this.operator.is("Change") && !wasOnWhiteSpace) {
            point = cursor.getEndOfCurrentWordBufferPosition({wordRegex: this.wordRegex})
          } else {
            point = Point.min(point, getEndOfLineForBufferRow(this.editor, cursorPosition.row))
          }
        }
      }
      return cursor.setBufferPosition(point)
    })
  }
}
MoveToNextWord.initClass()

// b
class MoveToPreviousWord extends Motion {
  static initClass() {
    this.extend()
    this.prototype.wordRegex = null
  }

  moveCursor(cursor) {
    return this.moveCursorCountTimes(cursor, () => {
      const point = cursor.getBeginningOfCurrentWordBufferPosition({wordRegex: this.wordRegex})
      return cursor.setBufferPosition(point)
    })
  }
}
MoveToPreviousWord.initClass()

class MoveToEndOfWord extends Motion {
  static initClass() {
    this.extend()
    this.prototype.wordRegex = null
    this.prototype.inclusive = true
  }

  moveToNextEndOfWord(cursor) {
    moveCursorToNextNonWhitespace(cursor)
    let point = cursor.getEndOfCurrentWordBufferPosition({wordRegex: this.wordRegex}).translate([0, -1])
    point = Point.min(point, this.getVimEofBufferPosition())
    return cursor.setBufferPosition(point)
  }

  moveCursor(cursor) {
    return this.moveCursorCountTimes(cursor, () => {
      const originalPoint = cursor.getBufferPosition()
      this.moveToNextEndOfWord(cursor)
      if (originalPoint.isEqual(cursor.getBufferPosition())) {
        // Retry from right column if cursor was already on EndOfWord
        cursor.moveRight()
        return this.moveToNextEndOfWord(cursor)
      }
    })
  }
}
MoveToEndOfWord.initClass()

// [TODO: Improve, accuracy]
class MoveToPreviousEndOfWord extends MoveToPreviousWord {
  static initClass() {
    this.extend()
    this.prototype.inclusive = true
  }

  moveCursor(cursor) {
    let times = this.getCount()
    const wordRange = cursor.getCurrentWordBufferRange()
    const cursorPosition = cursor.getBufferPosition()

    // if we're in the middle of a word then we need to move to its start
    if (cursorPosition.isGreaterThan(wordRange.start) && cursorPosition.isLessThan(wordRange.end)) {
      times += 1
    }

    for (let i = 1, end = times, asc = 1 <= end; asc ? i <= end : i >= end; asc ? i++ : i--) {
      const point = cursor.getBeginningOfCurrentWordBufferPosition({wordRegex: this.wordRegex})
      cursor.setBufferPosition(point)
    }

    this.moveToNextEndOfWord(cursor)
    if (cursor.getBufferPosition().isGreaterThanOrEqual(cursorPosition)) {
      return cursor.setBufferPosition([0, 0])
    }
  }

  moveToNextEndOfWord(cursor) {
    let point = cursor.getEndOfCurrentWordBufferPosition({wordRegex: this.wordRegex}).translate([0, -1])
    point = Point.min(point, this.getVimEofBufferPosition())
    return cursor.setBufferPosition(point)
  }
}
MoveToPreviousEndOfWord.initClass()

// Whole word
// -------------------------
class MoveToNextWholeWord extends MoveToNextWord {
  static initClass() {
    this.extend()
    this.prototype.wordRegex = /^$|\S+/g
  }
}
MoveToNextWholeWord.initClass()

class MoveToPreviousWholeWord extends MoveToPreviousWord {
  static initClass() {
    this.extend()
    this.prototype.wordRegex = /^$|\S+/g
  }
}
MoveToPreviousWholeWord.initClass()

class MoveToEndOfWholeWord extends MoveToEndOfWord {
  static initClass() {
    this.extend()
    this.prototype.wordRegex = /\S+/
  }
}
MoveToEndOfWholeWord.initClass()

// [TODO: Improve, accuracy]
class MoveToPreviousEndOfWholeWord extends MoveToPreviousEndOfWord {
  static initClass() {
    this.extend()
    this.prototype.wordRegex = /\S+/
  }
}
MoveToPreviousEndOfWholeWord.initClass()

// Alphanumeric word [Experimental]
// -------------------------
class MoveToNextAlphanumericWord extends MoveToNextWord {
  static initClass() {
    this.extend()
    this.description = "Move to next alphanumeric(`/w+/`) word"
    this.prototype.wordRegex = /\w+/g
  }
}
MoveToNextAlphanumericWord.initClass()

class MoveToPreviousAlphanumericWord extends MoveToPreviousWord {
  static initClass() {
    this.extend()
    this.description = "Move to previous alphanumeric(`/w+/`) word"
    this.prototype.wordRegex = /\w+/
  }
}
MoveToPreviousAlphanumericWord.initClass()

class MoveToEndOfAlphanumericWord extends MoveToEndOfWord {
  static initClass() {
    this.extend()
    this.description = "Move to end of alphanumeric(`/w+/`) word"
    this.prototype.wordRegex = /\w+/
  }
}
MoveToEndOfAlphanumericWord.initClass()

// Alphanumeric word [Experimental]
// -------------------------
class MoveToNextSmartWord extends MoveToNextWord {
  static initClass() {
    this.extend()
    this.description = "Move to next smart word (`/[w-]+/`) word"
    this.prototype.wordRegex = /[\w-]+/g
  }
}
MoveToNextSmartWord.initClass()

class MoveToPreviousSmartWord extends MoveToPreviousWord {
  static initClass() {
    this.extend()
    this.description = "Move to previous smart word (`/[w-]+/`) word"
    this.prototype.wordRegex = /[\w-]+/
  }
}
MoveToPreviousSmartWord.initClass()

class MoveToEndOfSmartWord extends MoveToEndOfWord {
  static initClass() {
    this.extend()
    this.description = "Move to end of smart word (`/[w-]+/`) word"
    this.prototype.wordRegex = /[\w-]+/
  }
}
MoveToEndOfSmartWord.initClass()

// Subword
// -------------------------
class MoveToNextSubword extends MoveToNextWord {
  static initClass() {
    this.extend()
  }
  moveCursor(cursor) {
    this.wordRegex = cursor.subwordRegExp()
    return super.moveCursor(...arguments)
  }
}
MoveToNextSubword.initClass()

class MoveToPreviousSubword extends MoveToPreviousWord {
  static initClass() {
    this.extend()
  }
  moveCursor(cursor) {
    this.wordRegex = cursor.subwordRegExp()
    return super.moveCursor(...arguments)
  }
}
MoveToPreviousSubword.initClass()

class MoveToEndOfSubword extends MoveToEndOfWord {
  static initClass() {
    this.extend()
  }
  moveCursor(cursor) {
    this.wordRegex = cursor.subwordRegExp()
    return super.moveCursor(...arguments)
  }
}
MoveToEndOfSubword.initClass()

// Sentence
// -------------------------
// Sentence is defined as below
//  - end with ['.', '!', '?']
//  - optionally followed by [')', ']', '"', "'"]
//  - followed by ['$', ' ', '\t']
//  - paragraph boundary is also sentence boundary
//  - section boundary is also sentence boundary(ignore)
class MoveToNextSentence extends Motion {
  static initClass() {
    this.extend()
    this.prototype.jump = true
    this.prototype.sentenceRegex = new RegExp(`(?:[\\.!\\?][\\)\\]"']*\\s+)|(\\n|\\r\\n)`, "g")
    this.prototype.direction = "next"
  }

  moveCursor(cursor) {
    return this.moveCursorCountTimes(cursor, () => {
      return this.setBufferPositionSafely(cursor, this.getPoint(cursor.getBufferPosition()))
    })
  }

  getPoint(fromPoint) {
    if (this.direction === "next") {
      return this.getNextStartOfSentence(fromPoint)
    } else if (this.direction === "previous") {
      return this.getPreviousStartOfSentence(fromPoint)
    }
  }

  isBlankRow(row) {
    return this.editor.isBufferRowBlank(row)
  }

  getNextStartOfSentence(from) {
    let foundPoint = null
    this.scanForward(this.sentenceRegex, {from}, ({range, matchText, match, stop}) => {
      if (match[1] != null) {
        const [startRow, endRow] = Array.from([range.start.row, range.end.row])
        if (this.skipBlankRow && this.isBlankRow(endRow)) {
          return
        }
        if (this.isBlankRow(startRow) !== this.isBlankRow(endRow)) {
          foundPoint = this.getFirstCharacterPositionForBufferRow(endRow)
        }
      } else {
        foundPoint = range.end
      }
      if (foundPoint != null) {
        return stop()
      }
    })
    return foundPoint != null ? foundPoint : this.getVimEofBufferPosition()
  }

  getPreviousStartOfSentence(from) {
    let foundPoint = null
    this.scanBackward(this.sentenceRegex, {from}, ({range, match, stop, matchText}) => {
      if (match[1] != null) {
        const [startRow, endRow] = Array.from([range.start.row, range.end.row])
        if (!this.isBlankRow(endRow) && this.isBlankRow(startRow)) {
          const point = this.getFirstCharacterPositionForBufferRow(endRow)
          if (point.isLessThan(from)) {
            foundPoint = point
          } else {
            if (this.skipBlankRow) {
              return
            }
            foundPoint = this.getFirstCharacterPositionForBufferRow(startRow)
          }
        }
      } else {
        if (range.end.isLessThan(from)) {
          foundPoint = range.end
        }
      }
      if (foundPoint != null) {
        return stop()
      }
    })
    return foundPoint != null ? foundPoint : [0, 0]
  }
}
MoveToNextSentence.initClass()

class MoveToPreviousSentence extends MoveToNextSentence {
  static initClass() {
    this.extend()
    this.prototype.direction = "previous"
  }
}
MoveToPreviousSentence.initClass()

class MoveToNextSentenceSkipBlankRow extends MoveToNextSentence {
  static initClass() {
    this.extend()
    this.prototype.skipBlankRow = true
  }
}
MoveToNextSentenceSkipBlankRow.initClass()

class MoveToPreviousSentenceSkipBlankRow extends MoveToPreviousSentence {
  static initClass() {
    this.extend()
    this.prototype.skipBlankRow = true
  }
}
MoveToPreviousSentenceSkipBlankRow.initClass()

// Paragraph
// -------------------------
class MoveToNextParagraph extends Motion {
  static initClass() {
    this.extend()
    this.prototype.jump = true
    this.prototype.direction = "next"
  }

  moveCursor(cursor) {
    return this.moveCursorCountTimes(cursor, () => {
      return this.setBufferPositionSafely(cursor, this.getPoint(cursor.getBufferPosition()))
    })
  }

  getPoint(fromPoint) {
    const startRow = fromPoint.row
    let wasAtNonBlankRow = !this.editor.isBufferRowBlank(startRow)
    for (let row of getBufferRows(this.editor, {startRow, direction: this.direction})) {
      if (this.editor.isBufferRowBlank(row)) {
        if (wasAtNonBlankRow) {
          return new Point(row, 0)
        }
      } else {
        wasAtNonBlankRow = true
      }
    }

    // fallback
    switch (this.direction) {
      case "previous":
        return new Point(0, 0)
      case "next":
        return this.getVimEofBufferPosition()
    }
  }
}
MoveToNextParagraph.initClass()

class MoveToPreviousParagraph extends MoveToNextParagraph {
  static initClass() {
    this.extend()
    this.prototype.direction = "previous"
  }
}
MoveToPreviousParagraph.initClass()

// -------------------------
// keymap: 0
class MoveToBeginningOfLine extends Motion {
  static initClass() {
    this.extend()
  }

  moveCursor(cursor) {
    return setBufferColumn(cursor, 0)
  }
}
MoveToBeginningOfLine.initClass()

class MoveToColumn extends Motion {
  static initClass() {
    this.extend()
  }

  moveCursor(cursor) {
    return setBufferColumn(cursor, this.getCount(-1))
  }
}
MoveToColumn.initClass()

class MoveToLastCharacterOfLine extends Motion {
  static initClass() {
    this.extend()
  }

  moveCursor(cursor) {
    const row = getValidVimBufferRow(this.editor, cursor.getBufferRow() + this.getCount(-1))
    cursor.setBufferPosition([row, Infinity])
    return (cursor.goalColumn = Infinity)
  }
}
MoveToLastCharacterOfLine.initClass()

class MoveToLastNonblankCharacterOfLineAndDown extends Motion {
  static initClass() {
    this.extend()
    this.prototype.inclusive = true
  }

  moveCursor(cursor) {
    const point = this.getPoint(cursor.getBufferPosition())
    return cursor.setBufferPosition(point)
  }

  getPoint({row}) {
    row = limitNumber(row + this.getCount(-1), {max: this.getVimLastBufferRow()})
    const range = findRangeInBufferRow(this.editor, /\S|^/, row, {direction: "backward"})
    return (range != null ? range.start : undefined) != null
      ? range != null ? range.start : undefined
      : new Point(row, 0)
  }
}
MoveToLastNonblankCharacterOfLineAndDown.initClass()

// MoveToFirstCharacterOfLine faimily
// ------------------------------------
// ^
class MoveToFirstCharacterOfLine extends Motion {
  static initClass() {
    this.extend()
  }
  moveCursor(cursor) {
    const point = this.getFirstCharacterPositionForBufferRow(cursor.getBufferRow())
    return this.setBufferPositionSafely(cursor, point)
  }
}
MoveToFirstCharacterOfLine.initClass()

class MoveToFirstCharacterOfLineUp extends MoveToFirstCharacterOfLine {
  static initClass() {
    this.extend()
    this.prototype.wise = "linewise"
  }
  moveCursor(cursor) {
    this.moveCursorCountTimes(cursor, function() {
      const point = cursor.getBufferPosition()
      if (point.row !== 0) {
        return cursor.setBufferPosition(point.translate([-1, 0]))
      }
    })
    return super.moveCursor(...arguments)
  }
}
MoveToFirstCharacterOfLineUp.initClass()

class MoveToFirstCharacterOfLineDown extends MoveToFirstCharacterOfLine {
  static initClass() {
    this.extend()
    this.prototype.wise = "linewise"
  }
  moveCursor(cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const point = cursor.getBufferPosition()
      if (this.getVimLastBufferRow() !== point.row) {
        return cursor.setBufferPosition(point.translate([+1, 0]))
      }
    })
    return super.moveCursor(...arguments)
  }
}
MoveToFirstCharacterOfLineDown.initClass()

class MoveToFirstCharacterOfLineAndDown extends MoveToFirstCharacterOfLineDown {
  static initClass() {
    this.extend()
    this.prototype.defaultCount = 0
  }
  getCount() {
    return super.getCount(...arguments) - 1
  }
}
MoveToFirstCharacterOfLineAndDown.initClass()

// keymap: g g
class MoveToFirstLine extends Motion {
  static initClass() {
    this.extend()
    this.prototype.wise = "linewise"
    this.prototype.jump = true
    this.prototype.verticalMotion = true
    this.prototype.moveSuccessOnLinewise = true
  }

  moveCursor(cursor) {
    this.setCursorBufferRow(cursor, getValidVimBufferRow(this.editor, this.getRow()))
    return cursor.autoscroll({center: true})
  }

  getRow() {
    return this.getCount(-1)
  }
}
MoveToFirstLine.initClass()

class MoveToScreenColumn extends Motion {
  static initClass() {
    this.extend(false)
  }
  moveCursor(cursor) {
    const allowOffScreenPosition = this.getConfig("allowMoveToOffScreenColumnOnScreenLineMotion")
    const point = this.vimState.utils.getScreenPositionForScreenRow(this.editor, cursor.getScreenRow(), this.which, {
      allowOffScreenPosition,
    })
    return this.setScreenPositionSafely(cursor, point)
  }
}
MoveToScreenColumn.initClass()

// keymap: g 0
class MoveToBeginningOfScreenLine extends MoveToScreenColumn {
  static initClass() {
    this.extend()
    this.prototype.which = "beginning"
  }
}
MoveToBeginningOfScreenLine.initClass()

// g ^: `move-to-first-character-of-screen-line`
class MoveToFirstCharacterOfScreenLine extends MoveToScreenColumn {
  static initClass() {
    this.extend()
    this.prototype.which = "first-character"
  }
}
MoveToFirstCharacterOfScreenLine.initClass()

// keymap: g $
class MoveToLastCharacterOfScreenLine extends MoveToScreenColumn {
  static initClass() {
    this.extend()
    this.prototype.which = "last-character"
  }
}
MoveToLastCharacterOfScreenLine.initClass()

// keymap: G
class MoveToLastLine extends MoveToFirstLine {
  static initClass() {
    this.extend()
    this.prototype.defaultCount = Infinity
  }
}
MoveToLastLine.initClass()

// keymap: N% e.g. 10%
class MoveToLineByPercent extends MoveToFirstLine {
  static initClass() {
    this.extend()
  }

  getRow() {
    const percent = limitNumber(this.getCount(), {max: 100})
    return Math.floor((this.editor.getLineCount() - 1) * (percent / 100))
  }
}
MoveToLineByPercent.initClass()

class MoveToRelativeLine extends Motion {
  static initClass() {
    this.extend(false)
    this.prototype.wise = "linewise"
    this.prototype.moveSuccessOnLinewise = true
  }

  moveCursor(cursor) {
    let row = this.getFoldEndRowForRow(cursor.getBufferRow())

    let count = this.getCount(-1)
    while (count > 0) {
      row = this.getFoldEndRowForRow(row + 1)
      count--
    }

    return setBufferRow(cursor, row)
  }
}
MoveToRelativeLine.initClass()

class MoveToRelativeLineMinimumOne extends MoveToRelativeLine {
  static initClass() {
    this.extend(false)
  }

  getCount() {
    return limitNumber(super.getCount(...arguments), {min: 1})
  }
}
MoveToRelativeLineMinimumOne.initClass()

// Position cursor without scrolling., H, M, L
// -------------------------
// keymap: H
class MoveToTopOfScreen extends Motion {
  static initClass() {
    this.extend()
    this.prototype.wise = "linewise"
    this.prototype.jump = true
    this.prototype.scrolloff = 2
    this.prototype.defaultCount = 0
    this.prototype.verticalMotion = true
  }

  moveCursor(cursor) {
    const bufferRow = this.editor.bufferRowForScreenRow(this.getScreenRow())
    return this.setCursorBufferRow(cursor, bufferRow)
  }

  getScrolloff() {
    if (this.isAsTargetExceptSelectInVisualMode()) {
      return 0
    } else {
      return this.scrolloff
    }
  }

  getScreenRow() {
    const firstRow = getFirstVisibleScreenRow(this.editor)
    let offset = this.getScrolloff()
    if (firstRow === 0) {
      offset = 0
    }
    offset = limitNumber(this.getCount(-1), {min: offset})
    return firstRow + offset
  }
}
MoveToTopOfScreen.initClass()

// keymap: M
class MoveToMiddleOfScreen extends MoveToTopOfScreen {
  static initClass() {
    this.extend()
  }
  getScreenRow() {
    const startRow = getFirstVisibleScreenRow(this.editor)
    const endRow = limitNumber(this.editor.getLastVisibleScreenRow(), {max: this.getVimLastScreenRow()})
    return startRow + Math.floor((endRow - startRow) / 2)
  }
}
MoveToMiddleOfScreen.initClass()

// keymap: L
class MoveToBottomOfScreen extends MoveToTopOfScreen {
  static initClass() {
    this.extend()
  }
  getScreenRow() {
    // [FIXME]
    // At least Atom v1.6.0, there are two implementation of getLastVisibleScreenRow()
    // editor.getLastVisibleScreenRow() and editorElement.getLastVisibleScreenRow()
    // Those two methods return different value, editor's one is corrent.
    // So I intentionally use editor.getLastScreenRow here.
    const vimLastScreenRow = this.getVimLastScreenRow()
    const row = limitNumber(this.editor.getLastVisibleScreenRow(), {max: vimLastScreenRow})
    let offset = this.getScrolloff() + 1
    if (row === vimLastScreenRow) {
      offset = 0
    }
    offset = limitNumber(this.getCount(-1), {min: offset})
    return row - offset
  }
}
MoveToBottomOfScreen.initClass()

// Scrolling
// Half: ctrl-d, ctrl-u
// Full: ctrl-f, ctrl-b
// -------------------------
// [FIXME] count behave differently from original Vim.
class Scroll extends Motion {
  static initClass() {
    this.extend(false)
    this.prototype.verticalMotion = true
  }

  isSmoothScrollEnabled() {
    if (Math.abs(this.amountOfPage) === 1) {
      return this.getConfig("smoothScrollOnFullScrollMotion")
    } else {
      return this.getConfig("smoothScrollOnHalfScrollMotion")
    }
  }

  getSmoothScrollDuation() {
    if (Math.abs(this.amountOfPage) === 1) {
      return this.getConfig("smoothScrollOnFullScrollMotionDuration")
    } else {
      return this.getConfig("smoothScrollOnHalfScrollMotionDuration")
    }
  }

  getPixelRectTopForSceenRow(row) {
    const point = new Point(row, 0)
    return this.editor.element.pixelRectForScreenRange(new Range(point, point)).top
  }

  smoothScroll(fromRow, toRow, done) {
    const topPixelFrom = {top: this.getPixelRectTopForSceenRow(fromRow)}
    const topPixelTo = {top: this.getPixelRectTopForSceenRow(toRow)}
    // [NOTE]
    // intentionally use `element.component.setScrollTop` instead of `element.setScrollTop`.
    // SInce element.setScrollTop will throw exception when element.component no longer exists.
    const step = newTop => {
      if (this.editor.element.component != null) {
        this.editor.element.component.setScrollTop(newTop)
        return this.editor.element.component.updateSync()
      }
    }

    const duration = this.getSmoothScrollDuation()
    return this.vimState.requestScrollAnimation(topPixelFrom, topPixelTo, {duration, step, done})
  }

  getAmountOfRows() {
    return Math.ceil(this.amountOfPage * this.editor.getRowsPerPage() * this.getCount())
  }

  getBufferRow(cursor) {
    const screenRow = getValidVimScreenRow(this.editor, cursor.getScreenRow() + this.getAmountOfRows())
    return this.editor.bufferRowForScreenRow(screenRow)
  }

  moveCursor(cursor) {
    const bufferRow = this.getBufferRow(cursor)
    this.setCursorBufferRow(cursor, this.getBufferRow(cursor), {autoscroll: false})

    if (cursor.isLastCursor()) {
      if (this.isSmoothScrollEnabled()) {
        this.vimState.finishScrollAnimation()
      }

      const firstVisibileScreenRow = this.editor.getFirstVisibleScreenRow()
      const newFirstVisibileBufferRow = this.editor.bufferRowForScreenRow(
        firstVisibileScreenRow + this.getAmountOfRows()
      )
      const newFirstVisibileScreenRow = this.editor.screenRowForBufferRow(newFirstVisibileBufferRow)
      const done = () => {
        this.editor.setFirstVisibleScreenRow(newFirstVisibileScreenRow)
        // [FIXME] sometimes, scrollTop is not updated, calling this fix.
        // Investigate and find better approach then remove this workaround.
        return this.editor.element.component != null ? this.editor.element.component.updateSync() : undefined
      }

      if (this.isSmoothScrollEnabled()) {
        return this.smoothScroll(firstVisibileScreenRow, newFirstVisibileScreenRow, done)
      } else {
        return done()
      }
    }
  }
}
Scroll.initClass()

// keymap: ctrl-f
class ScrollFullScreenDown extends Scroll {
  static initClass() {
    this.extend(true)
    this.prototype.amountOfPage = +1
  }
}
ScrollFullScreenDown.initClass()

// keymap: ctrl-b
class ScrollFullScreenUp extends Scroll {
  static initClass() {
    this.extend()
    this.prototype.amountOfPage = -1
  }
}
ScrollFullScreenUp.initClass()

// keymap: ctrl-d
class ScrollHalfScreenDown extends Scroll {
  static initClass() {
    this.extend()
    this.prototype.amountOfPage = +1 / 2
  }
}
ScrollHalfScreenDown.initClass()

// keymap: ctrl-u
class ScrollHalfScreenUp extends Scroll {
  static initClass() {
    this.extend()
    this.prototype.amountOfPage = -1 / 2
  }
}
ScrollHalfScreenUp.initClass()

// Find
// -------------------------
// keymap: f
class Find extends Motion {
  static initClass() {
    this.extend()
    this.prototype.backwards = false
    this.prototype.inclusive = true
    this.prototype.offset = 0
    this.prototype.requireInput = true
    this.prototype.caseSensitivityKind = "Find"
  }

  restoreEditorState() {
    if (typeof this._restoreEditorState === "function") {
      this._restoreEditorState()
    }
    return (this._restoreEditorState = null)
  }

  cancelOperation() {
    this.restoreEditorState()
    return super.cancelOperation(...arguments)
  }

  constructor(...args) {
    super(...args)

    if (this.getConfig("reuseFindForRepeatFind")) {
      this.repeatIfNecessary()
    }

    if (!this.isComplete()) {
      let options

      const charsMax = this.getConfig("findCharsMax")
      if (charsMax > 1) {
        this._restoreEditorState = saveEditorState(this.editor)

        options = {
          autoConfirmTimeout: this.getConfig("findConfirmByTimeout"),
          onConfirm: input => {
            this.input = input
            if (input) this.processOperation()
            else this.cancelOperation()
          },
          onChange: preConfirmedChars => {
            this.preConfirmedChars = preConfirmedChars
            this.highlightTextInCursorRows(this.preConfirmedChars, "pre-confirm")
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
      }

      this.focusInput(Object.assign(options || {}, {purpose: "find", charsMax: charsMax}))
    }
  }

  findPreConfirmed(delta) {
    if (this.preConfirmedChars && this.getConfig("highlightFindChar")) {
      const index = this.highlightTextInCursorRows(
        this.preConfirmedChars,
        "pre-confirm",
        this.getCount(-1) + delta,
        true
      )
      return (this.count = index + 1)
    }
  }

  repeatIfNecessary() {
    const findCommandNames = ["Find", "FindBackwards", "Till", "TillBackwards"]
    const currentFind = this.vimState.globalState.get("currentFind")
    if (currentFind && findCommandNames.includes(this.vimState.operationStack.getLastCommandName())) {
      this.input = currentFind.input
      this.repeated = true
    }
  }

  isBackwards() {
    return this.backwards
  }

  execute() {
    super.execute(...arguments)
    let decorationType = "post-confirm"
    if (this.operator != null && !(this.operator != null ? this.operator.instanceof("SelectBase") : undefined)) {
      decorationType += " long"
    }
    this.editor.component.getNextUpdatePromise().then(() => {
      return this.highlightTextInCursorRows(this.input, decorationType)
    })

    // Don't return Promise here. OperationStack treat Promise differently.
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
      if (this.getConfig("findAcrossLines")) {
        scanRange.start = Point.ZERO
      }
      this.editor.backwardsScanInBufferRange(regex, scanRange, function({range, stop}) {
        if (range.start.isLessThan(fromPoint)) {
          points.push(range.start)
          if (points.length > indexWantAccess) {
            return stop()
          }
        }
      })
    } else {
      if (this.getConfig("findAcrossLines")) {
        scanRange.end = this.editor.getEofBufferPosition()
      }
      this.editor.scanInBufferRange(regex, scanRange, function({range, stop}) {
        if (range.start.isGreaterThan(fromPoint)) {
          points.push(range.start)
          if (points.length > indexWantAccess) {
            return stop()
          }
        }
      })
    }

    return points[indexWantAccess] != null ? points[indexWantAccess].translate(translation) : undefined
  }

  highlightTextInCursorRows(text, decorationType, index = this.getCount(-1), adjustIndex = false) {
    if (!this.getConfig("highlightFindChar")) {
      return
    }
    return this.vimState.highlightFind.highlightCursorRows(
      this.getRegex(text),
      decorationType,
      this.isBackwards(),
      this.offset,
      index,
      adjustIndex
    )
  }

  moveCursor(cursor) {
    const point = this.getPoint(cursor.getBufferPosition())
    if (point != null) {
      cursor.setBufferPosition(point)
    } else {
      this.restoreEditorState()
    }

    if (!this.repeated) {
      return this.globalState.set("currentFind", this)
    }
  }

  getRegex(term) {
    const modifiers = this.isCaseSensitive(term) ? "g" : "gi"
    return new RegExp(_.escapeRegExp(term), modifiers)
  }
}
Find.initClass()

// keymap: F
class FindBackwards extends Find {
  static initClass() {
    this.extend()
    this.prototype.inclusive = false
    this.prototype.backwards = true
  }
}
FindBackwards.initClass()

// keymap: t
class Till extends Find {
  static initClass() {
    this.extend()
    this.prototype.offset = 1
  }

  getPoint() {
    this.point = super.getPoint(...arguments)
    this.moveSucceeded = this.point != null
    return this.point
  }
}
Till.initClass()

// keymap: T
class TillBackwards extends Till {
  static initClass() {
    this.extend()
    this.prototype.inclusive = false
    this.prototype.backwards = true
  }
}
TillBackwards.initClass()

// Mark
// -------------------------
// keymap: `
class MoveToMark extends Motion {
  static initClass() {
    this.extend()
    this.prototype.jump = true
    this.prototype.requireInput = true
    this.prototype.input = null
  }

  constructor(...args) {
    super(...args)
    if (!this.isComplete()) this.readChar()
  }

  getPoint() {
    return this.vimState.mark.get(this.input)
  }

  moveCursor(cursor) {
    const point = this.getPoint()
    if (point) {
      cursor.setBufferPosition(point)
      cursor.autoscroll({center: true})
    }
  }
}
MoveToMark.initClass()

// keymap: '
class MoveToMarkLine extends MoveToMark {
  static initClass() {
    this.extend()
    this.prototype.wise = "linewise"
  }

  getPoint() {
    const point = super.getPoint()
    if (point) return this.getFirstCharacterPositionForBufferRow(point.row)
  }
}
MoveToMarkLine.initClass()

// Fold
// -------------------------
class MoveToPreviousFoldStart extends Motion {
  static initClass() {
    this.extend()
    this.description = "Move to previous fold start"
    this.prototype.wise = "characterwise"
    this.prototype.which = "start"
    this.prototype.direction = "prev"
  }

  constructor(...args) {
    super(...args)
    this.rows = this.getFoldRows(this.which)
    if (this.direction === "prev") this.rows.reverse()
  }

  getFoldRows(which) {
    const index = which === "start" ? 0 : 1
    const rows = getCodeFoldRowRanges(this.editor).map(rowRange => rowRange[index])
    return _.sortBy(_.uniq(rows), row => row)
  }

  getScanRows(cursor) {
    const cursorRow = cursor.getBufferRow()
    const isValidRow = (() => {
      switch (this.direction) {
        case "prev":
          return row => row < cursorRow
        case "next":
          return row => row > cursorRow
      }
    })()
    return this.rows.filter(isValidRow)
  }

  detectRow(cursor) {
    return this.getScanRows(cursor)[0]
  }

  moveCursor(cursor) {
    return this.moveCursorCountTimes(cursor, () => {
      let row
      if ((row = this.detectRow(cursor)) != null) {
        return moveCursorToFirstCharacterAtRow(cursor, row)
      }
    })
  }
}
MoveToPreviousFoldStart.initClass()

class MoveToNextFoldStart extends MoveToPreviousFoldStart {
  static initClass() {
    this.extend()
    this.description = "Move to next fold start"
    this.prototype.direction = "next"
  }
}
MoveToNextFoldStart.initClass()

class MoveToPreviousFoldStartWithSameIndent extends MoveToPreviousFoldStart {
  static initClass() {
    this.extend()
    this.description = "Move to previous same-indented fold start"
  }
  detectRow(cursor) {
    const baseIndentLevel = this.getIndentLevelForBufferRow(cursor.getBufferRow())
    for (let row of this.getScanRows(cursor)) {
      if (this.getIndentLevelForBufferRow(row) === baseIndentLevel) {
        return row
      }
    }
    return null
  }
}
MoveToPreviousFoldStartWithSameIndent.initClass()

class MoveToNextFoldStartWithSameIndent extends MoveToPreviousFoldStartWithSameIndent {
  static initClass() {
    this.extend()
    this.description = "Move to next same-indented fold start"
    this.prototype.direction = "next"
  }
}
MoveToNextFoldStartWithSameIndent.initClass()

class MoveToPreviousFoldEnd extends MoveToPreviousFoldStart {
  static initClass() {
    this.extend()
    this.description = "Move to previous fold end"
    this.prototype.which = "end"
  }
}
MoveToPreviousFoldEnd.initClass()

class MoveToNextFoldEnd extends MoveToPreviousFoldEnd {
  static initClass() {
    this.extend()
    this.description = "Move to next fold end"
    this.prototype.direction = "next"
  }
}
MoveToNextFoldEnd.initClass()

// -------------------------
class MoveToPreviousFunction extends MoveToPreviousFoldStart {
  static initClass() {
    this.extend()
    this.description = "Move to previous function"
    this.prototype.direction = "prev"
  }
  detectRow(cursor) {
    return _.detect(this.getScanRows(cursor), row => {
      return isIncludeFunctionScopeForRow(this.editor, row)
    })
  }
}
MoveToPreviousFunction.initClass()

class MoveToNextFunction extends MoveToPreviousFunction {
  static initClass() {
    this.extend()
    this.description = "Move to next function"
    this.prototype.direction = "next"
  }
}
MoveToNextFunction.initClass()

// Scope based
// -------------------------
class MoveToPositionByScope extends Motion {
  static initClass() {
    this.extend(false)
    this.prototype.direction = "backward"
    this.prototype.scope = "."
  }

  getPoint(fromPoint) {
    return detectScopeStartPositionForScope(this.editor, fromPoint, this.direction, this.scope)
  }

  moveCursor(cursor) {
    return this.moveCursorCountTimes(cursor, () => {
      return this.setBufferPositionSafely(cursor, this.getPoint(cursor.getBufferPosition()))
    })
  }
}
MoveToPositionByScope.initClass()

class MoveToPreviousString extends MoveToPositionByScope {
  static initClass() {
    this.extend()
    this.description = "Move to previous string(searched by `string.begin` scope)"
    this.prototype.direction = "backward"
    this.prototype.scope = "string.begin"
  }
}
MoveToPreviousString.initClass()

class MoveToNextString extends MoveToPreviousString {
  static initClass() {
    this.extend()
    this.description = "Move to next string(searched by `string.begin` scope)"
    this.prototype.direction = "forward"
  }
}
MoveToNextString.initClass()

class MoveToPreviousNumber extends MoveToPositionByScope {
  static initClass() {
    this.extend()
    this.prototype.direction = "backward"
    this.description = "Move to previous number(searched by `constant.numeric` scope)"
    this.prototype.scope = "constant.numeric"
  }
}
MoveToPreviousNumber.initClass()

class MoveToNextNumber extends MoveToPreviousNumber {
  static initClass() {
    this.extend()
    this.description = "Move to next number(searched by `constant.numeric` scope)"
    this.prototype.direction = "forward"
  }
}
MoveToNextNumber.initClass()

class MoveToNextOccurrence extends Motion {
  static initClass() {
    this.extend()
    // Ensure this command is available when has-occurrence
    this.commandScope = "atom-text-editor.vim-mode-plus.has-occurrence"
    this.prototype.jump = true
    this.prototype.direction = "next"
  }

  getRanges() {
    return this.vimState.occurrenceManager.getMarkers().map(marker => marker.getBufferRange())
  }

  execute() {
    this.ranges = this.vimState.utils.sortRanges(this.getRanges())
    return super.execute(...arguments)
  }

  moveCursor(cursor) {
    const range = this.ranges[getIndex(this.getIndex(cursor.getBufferPosition()), this.ranges)]
    const point = range.start
    cursor.setBufferPosition(point, {autoscroll: false})

    if (cursor.isLastCursor()) {
      this.editor.unfoldBufferRow(point.row)
      smartScrollToBufferPosition(this.editor, point)
    }

    if (this.getConfig("flashOnMoveToOccurrence")) {
      return this.vimState.flash(range, {type: "search"})
    }
  }

  getIndex(fromPoint) {
    let index = null
    for (let i = 0; i < this.ranges.length; i++) {
      const range = this.ranges[i]
      if (range.start.isGreaterThan(fromPoint)) {
        index = i
        break
      }
    }
    return (index != null ? index : 0) + this.getCount(-1)
  }
}
MoveToNextOccurrence.initClass()

class MoveToPreviousOccurrence extends MoveToNextOccurrence {
  static initClass() {
    this.extend()
    this.prototype.direction = "previous"
  }

  getIndex(fromPoint) {
    let index = null
    for (let i = this.ranges.length - 1; i >= 0; i--) {
      const range = this.ranges[i]
      if (range.end.isLessThan(fromPoint)) {
        index = i
        break
      }
    }
    return (index != null ? index : this.ranges.length - 1) - this.getCount(-1)
  }
}
MoveToPreviousOccurrence.initClass()

// -------------------------
// keymap: %
class MoveToPair extends Motion {
  static initClass() {
    this.extend()
    this.prototype.inclusive = true
    this.prototype.jump = true
    this.prototype.member = ["Parenthesis", "CurlyBracket", "SquareBracket"]
  }

  moveCursor(cursor) {
    return this.setBufferPositionSafely(cursor, this.getPoint(cursor))
  }

  getPointForTag(point) {
    const pairInfo = this.new("ATag").getPairInfo(point)
    if (pairInfo == null) {
      return null
    }
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
    let point
    const cursorPosition = cursor.getBufferPosition()
    const cursorRow = cursorPosition.row
    if ((point = this.getPointForTag(cursorPosition))) {
      return point
    }

    // AAnyPairAllowForwarding return forwarding range or enclosing range.
    const range = this.new("AAnyPairAllowForwarding")
      .assign({member: this.member})
      .getRange(cursor.selection)
    if (range == null) {
      return null
    }
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
MoveToPair.initClass()

function __range__(left, right, inclusive) {
  let range = []
  let ascending = left < right
  let end = !inclusive ? right : ascending ? right + 1 : right - 1
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) {
    range.push(i)
  }
  return range
}
