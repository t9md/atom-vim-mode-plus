'use babel'

const {Point, Range} = require('atom')

const Base = require('./base')

class Motion extends Base {
  static operationKind = 'motion'
  static command = false

  operator = null
  inclusive = false
  wise = 'characterwise'
  jump = false
  verticalMotion = false
  moveSucceeded = null
  moveSuccessOnLinewise = false
  selectSucceeded = false
  requireInput = false
  caseSensitivityKind = null

  isReady () {
    return !this.requireInput || this.input != null
  }

  isLinewise () {
    return this.wise === 'linewise'
  }

  isBlockwise () {
    return this.wise === 'blockwise'
  }

  forceWise (wise) {
    if (wise === 'characterwise') {
      this.inclusive = this.wise === 'linewise' ? false : !this.inclusive
    }
    this.wise = wise
  }

  resetState () {
    this.selectSucceeded = false
  }

  moveWithSaveJump (cursor) {
    const originalPosition = this.jump && cursor.isLastCursor() ? cursor.getBufferPosition() : undefined

    this.moveCursor(cursor)

    if (originalPosition && !cursor.getBufferPosition().isEqual(originalPosition)) {
      this.vimState.mark.set('`', originalPosition)
      this.vimState.mark.set("'", originalPosition)
    }
  }

  execute () {
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
  select () {
    // need to care was visual for `.` repeated.
    const isOrWasVisual = this.operator.instanceof('SelectBase') || this.name === 'CurrentSelection'

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

    if (this.wise === 'blockwise') {
      this.vimState.getLastBlockwiseSelection().autoscroll()
    }
  }

  setCursorBufferRow (cursor, row, options) {
    if (this.verticalMotion && !this.getConfig('stayOnVerticalMotion')) {
      cursor.setBufferPosition(this.getFirstCharacterPositionForBufferRow(row), options)
    } else {
      this.utils.setBufferRow(cursor, row, options)
    }
  }

  // Call callback count times.
  // But break iteration when cursor position did not change before/after callback.
  moveCursorCountTimes (cursor, fn) {
    let oldPosition = cursor.getBufferPosition()
    this.countTimes(this.getCount(), state => {
      fn(state)
      const newPosition = cursor.getBufferPosition()
      if (newPosition.isEqual(oldPosition)) state.stop()
      oldPosition = newPosition
    })
  }

  isCaseSensitive (term) {
    if (this.getConfig(`useSmartcaseFor${this.caseSensitivityKind}`)) {
      return term.search(/[A-Z]/) !== -1
    } else {
      return !this.getConfig(`ignoreCaseFor${this.caseSensitivityKind}`)
    }
  }

  getLastResortPoint (direction) {
    if (direction === 'next') {
      return this.getVimEofBufferPosition()
    } else {
      return new Point(0, 0)
    }
  }
}

// Used as operator's target in visual-mode.
class CurrentSelection extends Motion {
  static command = false
  selectionExtent = null
  blockwiseSelectionExtent = null
  inclusive = true
  pointInfoByCursor = new Map()

  moveCursor (cursor) {
    if (this.mode === 'visual') {
      this.selectionExtent = this.isBlockwise()
        ? this.swrap(cursor.selection).getBlockwiseSelectionExtent()
        : this.editor.getSelectedBufferRange().getExtent()
    } else {
      // `.` repeat case
      cursor.setBufferPosition(cursor.getBufferPosition().translate(this.selectionExtent))
    }
  }

  select () {
    if (this.mode === 'visual') {
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
        const cursorPosition = cursor.getBufferPosition()
        this.pointInfoByCursor.set(cursor, {startOfSelection, cursorPosition})
      })
    }
  }
}

class MoveLeft extends Motion {
  moveCursor (cursor) {
    const allowWrap = this.getConfig('wrapLeftRightMotion')
    this.moveCursorCountTimes(cursor, () => {
      this.utils.moveCursorLeft(cursor, {allowWrap})
    })
  }
}

class MoveRight extends Motion {
  moveCursor (cursor) {
    const allowWrap = this.getConfig('wrapLeftRightMotion')

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

class MoveRightBufferColumn extends Motion {
  static command = false
  moveCursor (cursor) {
    this.utils.setBufferColumn(cursor, cursor.getBufferColumn() + this.getCount())
  }
}

class MoveUp extends Motion {
  wise = 'linewise'
  wrap = false
  direction = 'up'

  getBufferRow (row) {
    const min = 0
    const max = this.getVimLastBufferRow()

    if (this.direction === 'up') {
      row = this.getFoldStartRowForRow(row) - 1
      row = this.wrap && row < min ? max : this.limitNumber(row, {min})
    } else {
      row = this.getFoldEndRowForRow(row) + 1
      row = this.wrap && row > max ? min : this.limitNumber(row, {max})
    }
    return this.getFoldStartRowForRow(row)
  }

  moveCursor (cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const row = this.getBufferRow(cursor.getBufferRow())
      this.utils.setBufferRow(cursor, row)
    })
  }
}

class MoveUpWrap extends MoveUp {
  wrap = true
}

class MoveDown extends MoveUp {
  direction = 'down'
}

class MoveDownWrap extends MoveDown {
  wrap = true
}

class MoveUpScreen extends Motion {
  wise = 'linewise'
  direction = 'up'
  moveCursor (cursor) {
    this.moveCursorCountTimes(cursor, () => {
      this.utils.moveCursorUpScreen(cursor)
    })
  }
}

class MoveDownScreen extends MoveUpScreen {
  wise = 'linewise'
  direction = 'down'
  moveCursor (cursor) {
    this.moveCursorCountTimes(cursor, () => {
      this.utils.moveCursorDownScreen(cursor)
    })
  }
}

class MoveUpToEdge extends Motion {
  wise = 'linewise'
  jump = true
  direction = 'previous'
  moveCursor (cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const point = this.getPoint(cursor.getScreenPosition())
      if (point) cursor.setScreenPosition(point)
    })
  }

  getPoint (fromPoint) {
    const {column, row: startRow} = fromPoint
    for (const row of this.getScreenRows({startRow, direction: this.direction})) {
      const point = new Point(row, column)
      if (this.isEdge(point)) return point
    }
  }

  isEdge (point) {
    // If point is stoppable and above or below point is not stoppable, it's Edge!
    return (
      this.isStoppable(point) &&
      (!this.isStoppable(point.translate([-1, 0])) || !this.isStoppable(point.translate([+1, 0])))
    )
  }

  isStoppable (point) {
    return (
      this.isNonWhiteSpace(point) ||
      this.isFirstRowOrLastRowAndStoppable(point) ||
      // If right or left column is non-white-space char, it's stoppable.
      (this.isNonWhiteSpace(point.translate([0, -1])) && this.isNonWhiteSpace(point.translate([0, +1])))
    )
  }

  isNonWhiteSpace (point) {
    const char = this.utils.getTextInScreenRange(this.editor, Range.fromPointWithDelta(point, 0, 1))
    return char != null && /\S/.test(char)
  }

  isFirstRowOrLastRowAndStoppable (point) {
    // In notmal-mode, cursor is NOT stoppable to EOL of non-blank row.
    // So explicitly guard to not answer it stoppable.
    if (this.mode === 'normal' && this.utils.pointIsAtEndOfLineAtNonEmptyRow(this.editor, point)) {
      return false
    }

    // If clipped, it means that original ponit was non stoppable(e.g. point.colum > EOL).
    const {row} = point
    return (row === 0 || row === this.getVimLastScreenRow()) && point.isEqual(this.editor.clipScreenPosition(point))
  }
}

class MoveDownToEdge extends MoveUpToEdge {
  direction = 'next'
}

// Word Motion family
// +----------------------------------------------------------------------------+
// | direction | which      | word  | WORD | subword | smartword | alphanumeric |
// |-----------+------------+-------+------+---------+-----------+--------------+
// | next      | word-start | w     | W    | -       | -         | -            |
// | previous  | word-start | b     | b    | -       | -         | -            |
// | next      | word-end   | e     | E    | -       | -         | -            |
// | previous  | word-end   | ge    | g E  | n/a     | n/a       | n/a          |
// +----------------------------------------------------------------------------+

class MotionByWord extends Motion {
  static command = false
  wordRegex = null
  skipBlankRow = false
  skipWhiteSpaceOnlyRow = false

  moveCursor (cursor) {
    this.moveCursorCountTimes(cursor, countState => {
      cursor.setBufferPosition(this.getPoint(cursor, countState))
    })
  }

  getPoint (cursor, countState) {
    const {direction} = this
    let {which} = this
    const regex = this.getWordRegexForCursor(cursor)

    const from = cursor.getBufferPosition()
    if (direction === 'next' && which === 'start' && this.operator && countState.isFinal) {
      // [NOTE] Exceptional behavior for w and W: [Detail in vim help `:help w`.]
      // [case-A] cw, cW treated as ce, cE when cursor is at non-blank.
      // [case-B] when w, W used as TARGET, it doesn't move over new line.
      if (this.isEmptyRow(from.row)) return [from.row + 1, 0]

      // [case-A]
      if (this.operator.name === 'Change' && !this.utils.pointIsAtWhiteSpace(this.editor, from)) {
        which = 'end'
      }
      const point = this.findPoint(direction, regex, which, this.buildOptions(from))
      // [case-B]
      return point ? Point.min(point, [from.row, Infinity]) : this.getLastResortPoint(direction)
    } else {
      return this.findPoint(direction, regex, which, this.buildOptions(from)) || this.getLastResortPoint(direction)
    }
  }

  buildOptions (from) {
    return {
      from: from,
      skipEmptyRow: this.skipEmptyRow,
      skipWhiteSpaceOnlyRow: this.skipWhiteSpaceOnlyRow,
      preTranslate: (this.which === 'end' && [0, +1]) || undefined,
      postTranslate: (this.which === 'end' && [0, -1]) || undefined
    }
  }

  getWordRegexForCursor (cursor) {
    if (this.name.endsWith('Subword')) {
      return cursor.subwordRegExp()
    }

    if (this.wordRegex) {
      return this.wordRegex
    }

    if (this.getConfig('useLanguageIndependentNonWordCharacters')) {
      const nonWordCharacters = this._.escapeRegExp(this.utils.getNonWordCharactersForCursor(cursor))
      const source = `^[\\t\\r ]*$|[^\\s${nonWordCharacters}]+|[${nonWordCharacters}]+`
      return new RegExp(source, 'g')
    }
    return cursor.wordRegExp()
  }
}

// w
class MoveToNextWord extends MotionByWord {
  direction = 'next'
  which = 'start'
}

// W
class MoveToNextWholeWord extends MoveToNextWord {
  wordRegex = /^$|\S+/g
}

// no-keymap
class MoveToNextSubword extends MoveToNextWord {}

// no-keymap
class MoveToNextSmartWord extends MoveToNextWord {
  wordRegex = /[\w-]+/g
}

// no-keymap
class MoveToNextAlphanumericWord extends MoveToNextWord {
  wordRegex = /\w+/g
}

// b
class MoveToPreviousWord extends MotionByWord {
  direction = 'previous'
  which = 'start'
  skipWhiteSpaceOnlyRow = true
}

// B
class MoveToPreviousWholeWord extends MoveToPreviousWord {
  wordRegex = /^$|\S+/g
}

// no-keymap
class MoveToPreviousSubword extends MoveToPreviousWord {}

// no-keymap
class MoveToPreviousSmartWord extends MoveToPreviousWord {
  wordRegex = /[\w-]+/
}

// no-keymap
class MoveToPreviousAlphanumericWord extends MoveToPreviousWord {
  wordRegex = /\w+/
}

// e
class MoveToEndOfWord extends MotionByWord {
  inclusive = true
  direction = 'next'
  which = 'end'
  skipEmptyRow = true
  skipWhiteSpaceOnlyRow = true
}

// E
class MoveToEndOfWholeWord extends MoveToEndOfWord {
  wordRegex = /\S+/g
}

// no-keymap
class MoveToEndOfSubword extends MoveToEndOfWord {}

// no-keymap
class MoveToEndOfSmartWord extends MoveToEndOfWord {
  wordRegex = /[\w-]+/g
}

// no-keymap
class MoveToEndOfAlphanumericWord extends MoveToEndOfWord {
  wordRegex = /\w+/g
}

// ge
class MoveToPreviousEndOfWord extends MotionByWord {
  inclusive = true
  direction = 'previous'
  which = 'end'
  skipWhiteSpaceOnlyRow = true
}

// gE
class MoveToPreviousEndOfWholeWord extends MoveToPreviousEndOfWord {
  wordRegex = /\S+/g
}

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
  sentenceRegex = new RegExp(`(?:[\\.!\\?][\\)\\]"']*\\s+)|(\\n|\\r\\n)`, 'g')
  direction = 'next'

  moveCursor (cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const point =
        this.direction === 'next'
          ? this.getNextStartOfSentence(cursor.getBufferPosition())
          : this.getPreviousStartOfSentence(cursor.getBufferPosition())
      cursor.setBufferPosition(point || this.getLastResortPoint(this.direction))
    })
  }

  isBlankRow (row) {
    return this.editor.isBufferRowBlank(row)
  }

  getNextStartOfSentence (from) {
    return this.findInEditor('forward', this.sentenceRegex, {from}, ({range, match}) => {
      if (match[1] != null) {
        const [startRow, endRow] = [range.start.row, range.end.row]
        if (this.skipBlankRow && this.isBlankRow(endRow)) return
        if (this.isBlankRow(startRow) !== this.isBlankRow(endRow)) {
          return this.getFirstCharacterPositionForBufferRow(endRow)
        }
      } else {
        return range.end
      }
    })
  }

  getPreviousStartOfSentence (from) {
    return this.findInEditor('backward', this.sentenceRegex, {from}, ({range, match}) => {
      if (match[1] != null) {
        const [startRow, endRow] = [range.start.row, range.end.row]
        if (!this.isBlankRow(endRow) && this.isBlankRow(startRow)) {
          const point = this.getFirstCharacterPositionForBufferRow(endRow)
          if (point.isLessThan(from)) return point
          else if (!this.skipBlankRow) return this.getFirstCharacterPositionForBufferRow(startRow)
        }
      } else if (range.end.isLessThan(from)) {
        return range.end
      }
    })
  }
}

class MoveToPreviousSentence extends MoveToNextSentence {
  direction = 'previous'
}

class MoveToNextSentenceSkipBlankRow extends MoveToNextSentence {
  skipBlankRow = true
}

class MoveToPreviousSentenceSkipBlankRow extends MoveToPreviousSentence {
  skipBlankRow = true
}

// Paragraph
// -------------------------
class MoveToNextParagraph extends Motion {
  jump = true
  direction = 'next'

  moveCursor (cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const point = this.getPoint(cursor.getBufferPosition())
      cursor.setBufferPosition(point || this.getLastResortPoint(this.direction))
    })
  }

  getPoint (from) {
    let wasBlankRow = this.editor.isBufferRowBlank(from.row)
    const rows = this.getBufferRows({startRow: from.row, direction: this.direction})
    for (const row of rows) {
      const isBlankRow = this.editor.isBufferRowBlank(row)
      if (!wasBlankRow && isBlankRow) {
        return [row, 0]
      }
      wasBlankRow = isBlankRow
    }
  }
}

class MoveToPreviousParagraph extends MoveToNextParagraph {
  direction = 'previous'
}

class MoveToNextDiffHunk extends Motion {
  jump = true
  direction = 'next'

  moveCursor (cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const point = this.getPoint(cursor.getBufferPosition())
      if (point) cursor.setBufferPosition(point)
    })
  }

  getPoint (from) {
    const getHunkRange = row => this.utils.getHunkRangeAtBufferRow(this.editor, row)
    let hunkRange = getHunkRange(from.row)
    return this.findInEditor(this.direction, /^[+-]/g, {from}, ({range}) => {
      if (hunkRange && hunkRange.containsPoint(range.start)) return

      return getHunkRange(range.start.row).start
    })
  }
}

class MoveToPreviousDiffHunk extends MoveToNextDiffHunk {
  direction = 'previous'
}

// -------------------------
// keymap: 0
class MoveToBeginningOfLine extends Motion {
  moveCursor (cursor) {
    this.utils.setBufferColumn(cursor, 0)
  }
}

class MoveToColumn extends Motion {
  moveCursor (cursor) {
    this.utils.setBufferColumn(cursor, this.getCount() - 1)
  }
}

class MoveToLastCharacterOfLine extends Motion {
  moveCursor (cursor) {
    const row = this.getValidVimBufferRow(cursor.getBufferRow() + this.getCount() - 1)
    cursor.setBufferPosition([row, Infinity])
    cursor.goalColumn = Infinity
  }
}

class MoveToLastNonblankCharacterOfLineAndDown extends Motion {
  inclusive = true

  moveCursor (cursor) {
    const row = this.limitNumber(cursor.getBufferRow() + this.getCount() - 1, {max: this.getVimLastBufferRow()})
    const options = {from: [row, Infinity], allowNextLine: false}
    const point = this.findInEditor('backward', /\S|^/, options, event => event.range.start)
    cursor.setBufferPosition(point)
  }
}

// MoveToFirstCharacterOfLine faimily
// ------------------------------------
// ^
class MoveToFirstCharacterOfLine extends Motion {
  moveCursor (cursor) {
    cursor.setBufferPosition(this.getFirstCharacterPositionForBufferRow(cursor.getBufferRow()))
  }
}

class MoveToFirstCharacterOfLineUp extends MoveToFirstCharacterOfLine {
  wise = 'linewise'
  moveCursor (cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const row = this.getValidVimBufferRow(cursor.getBufferRow() - 1)
      cursor.setBufferPosition([row, 0])
    })
    super.moveCursor(cursor)
  }
}

class MoveToFirstCharacterOfLineDown extends MoveToFirstCharacterOfLine {
  wise = 'linewise'
  moveCursor (cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const point = cursor.getBufferPosition()
      if (point.row < this.getVimLastBufferRow()) {
        cursor.setBufferPosition(point.translate([+1, 0]))
      }
    })
    super.moveCursor(cursor)
  }
}

class MoveToFirstCharacterOfLineAndDown extends MoveToFirstCharacterOfLineDown {
  getCount () {
    return super.getCount() - 1
  }
}

class MoveToScreenColumn extends Motion {
  static command = false
  moveCursor (cursor) {
    const point = this.utils.getScreenPositionForScreenRow(this.editor, cursor.getScreenRow(), this.which, {
      allowOffScreenPosition: this.getConfig('allowMoveToOffScreenColumnOnScreenLineMotion')
    })
    if (point) cursor.setScreenPosition(point)
  }
}

// keymap: g 0
class MoveToBeginningOfScreenLine extends MoveToScreenColumn {
  which = 'beginning'
}

// g ^: `move-to-first-character-of-screen-line`
class MoveToFirstCharacterOfScreenLine extends MoveToScreenColumn {
  which = 'first-character'
}

// keymap: g $
class MoveToLastCharacterOfScreenLine extends MoveToScreenColumn {
  which = 'last-character'
}

// keymap: g g
class MoveToFirstLine extends Motion {
  wise = 'linewise'
  jump = true
  verticalMotion = true
  moveSuccessOnLinewise = true

  moveCursor (cursor) {
    this.setCursorBufferRow(cursor, this.getValidVimBufferRow(this.getRow()))
    cursor.autoscroll({center: true})
  }

  getRow () {
    return this.getCount() - 1
  }
}

// keymap: G
class MoveToLastLine extends MoveToFirstLine {
  defaultCount = Infinity
}

// keymap: N% e.g. 10%
class MoveToLineByPercent extends MoveToFirstLine {
  getRow () {
    const percent = this.limitNumber(this.getCount(), {max: 100})
    return Math.floor(this.getVimLastBufferRow() * (percent / 100))
  }
}

class MoveToRelativeLine extends Motion {
  static command = false
  wise = 'linewise'
  moveSuccessOnLinewise = true

  moveCursor (cursor) {
    let row
    let count = this.getCount()
    if (count < 0) {
      // Support negative count
      // Negative count can be passed like `operationStack.run("MoveToRelativeLine", {count: -5})`.
      // Currently used in vim-mode-plus-ex-mode pkg.
      while (count++ < 0) {
        row = this.getFoldStartRowForRow(row == null ? cursor.getBufferRow() : row - 1)
        if (row <= 0) break
      }
    } else {
      const maxRow = this.getVimLastBufferRow()
      while (count-- > 0) {
        row = this.getFoldEndRowForRow(row == null ? cursor.getBufferRow() : row + 1)
        if (row >= maxRow) break
      }
    }
    this.utils.setBufferRow(cursor, row)
  }
}

class MoveToRelativeLineMinimumTwo extends MoveToRelativeLine {
  static command = false
  getCount () {
    return this.limitNumber(super.getCount(), {min: 2})
  }
}

// Position cursor without scrolling., H, M, L
// -------------------------
// keymap: H
class MoveToTopOfScreen extends Motion {
  wise = 'linewise'
  jump = true
  defaultCount = 0
  verticalMotion = true

  moveCursor (cursor) {
    const bufferRow = this.editor.bufferRowForScreenRow(this.getScreenRow())
    this.setCursorBufferRow(cursor, bufferRow)
  }

  getScreenRow () {
    const firstVisibleRow = this.editor.getFirstVisibleScreenRow()
    const lastVisibleRow = this.limitNumber(this.editor.getLastVisibleScreenRow(), {max: this.getVimLastScreenRow()})

    const baseOffset = 2
    if (this.name === 'MoveToTopOfScreen') {
      const offset = firstVisibleRow === 0 ? 0 : baseOffset
      const count = this.getCount() - 1
      return this.limitNumber(firstVisibleRow + count, {min: firstVisibleRow + offset, max: lastVisibleRow})
    } else if (this.name === 'MoveToMiddleOfScreen') {
      return firstVisibleRow + Math.floor((lastVisibleRow - firstVisibleRow) / 2)
    } else if (this.name === 'MoveToBottomOfScreen') {
      const offset = lastVisibleRow === this.getVimLastScreenRow() ? 0 : baseOffset + 1
      const count = this.getCount() - 1
      return this.limitNumber(lastVisibleRow - count, {min: firstVisibleRow, max: lastVisibleRow - offset})
    }
  }
}

class MoveToMiddleOfScreen extends MoveToTopOfScreen {} // keymap: M
class MoveToBottomOfScreen extends MoveToTopOfScreen {} // keymap: L

// Scrolling
// Half: ctrl-d, ctrl-u
// Full: ctrl-f, ctrl-b
// -------------------------
// [FIXME] count behave differently from original Vim.
class Scroll extends Motion {
  static command = false
  static scrollTask = null
  static amountOfPageByName = {
    ScrollFullScreenDown: 1,
    ScrollFullScreenUp: -1,
    ScrollHalfScreenDown: 0.5,
    ScrollHalfScreenUp: -0.5,
    ScrollQuarterScreenDown: 0.25,
    ScrollQuarterScreenUp: -0.25
  }
  verticalMotion = true

  execute () {
    const amountOfPage = this.constructor.amountOfPageByName[this.name]
    const amountOfScreenRows = Math.trunc(amountOfPage * this.editor.getRowsPerPage() * this.getCount())
    this.amountOfPixels = amountOfScreenRows * this.editor.getLineHeightInPixels()

    super.execute()

    this.vimState.requestScroll({
      amountOfPixels: this.amountOfPixels,
      duration: this.getSmoothScrollDuation((Math.abs(amountOfPage) === 1 ? 'Full' : 'Half') + 'ScrollMotion')
    })
  }

  moveCursor (cursor) {
    const cursorPixel = this.editorElement.pixelPositionForScreenPosition(cursor.getScreenPosition())
    cursorPixel.top += this.amountOfPixels
    const screenPosition = this.editorElement.screenPositionForPixelPosition(cursorPixel)
    const screenRow = this.getValidVimScreenRow(screenPosition.row)
    this.setCursorBufferRow(cursor, this.editor.bufferRowForScreenRow(screenRow), {autoscroll: false})
  }
}

class ScrollFullScreenDown extends Scroll {} // ctrl-f
class ScrollFullScreenUp extends Scroll {} // ctrl-b
class ScrollHalfScreenDown extends Scroll {} // ctrl-d
class ScrollHalfScreenUp extends Scroll {} // ctrl-u
class ScrollQuarterScreenDown extends Scroll {} // g ctrl-d
class ScrollQuarterScreenUp extends Scroll {} // g ctrl-u

// Find
// -------------------------
// keymap: f
class Find extends Motion {
  backwards = false
  inclusive = true
  offset = 0
  requireInput = true
  caseSensitivityKind = 'Find'

  restoreEditorState () {
    if (this._restoreEditorState) this._restoreEditorState()
    this._restoreEditorState = null
  }

  cancelOperation () {
    this.restoreEditorState()
    super.cancelOperation()
  }

  initialize () {
    if (this.getConfig('reuseFindForRepeatFind')) this.repeatIfNecessary()

    if (!this.repeated) {
      const charsMax = this.getConfig('findCharsMax')
      const optionsBase = {purpose: 'find', charsMax}

      if (charsMax === 1) {
        this.focusInput(optionsBase)
      } else {
        this._restoreEditorState = this.utils.saveEditorState(this.editor)
        const options = {
          autoConfirmTimeout: this.getConfig('findConfirmByTimeout'),
          onConfirm: input => {
            this.input = input
            if (input) this.processOperation()
            else this.cancelOperation()
          },
          onChange: preConfirmedChars => {
            this.preConfirmedChars = preConfirmedChars
            this.highlightTextInCursorRows(this.preConfirmedChars, 'pre-confirm', this.isBackwards())
          },
          onCancel: () => {
            this.vimState.highlightFind.clearMarkers()
            this.cancelOperation()
          },
          commands: {
            'vim-mode-plus:find-next-pre-confirmed': () => this.findPreConfirmed(+1),
            'vim-mode-plus:find-previous-pre-confirmed': () => this.findPreConfirmed(-1)
          }
        }
        this.focusInput(Object.assign(options, optionsBase))
      }
    }
    super.initialize()
  }

  findPreConfirmed (delta) {
    if (this.preConfirmedChars && this.getConfig('highlightFindChar')) {
      const index = this.highlightTextInCursorRows(
        this.preConfirmedChars,
        'pre-confirm',
        this.isBackwards(),
        this.getCount() - 1 + delta,
        true
      )
      this.count = index + 1
    }
  }

  repeatIfNecessary () {
    const findCommandNames = ['Find', 'FindBackwards', 'Till', 'TillBackwards']
    const currentFind = this.globalState.get('currentFind')
    if (currentFind && findCommandNames.includes(this.vimState.operationStack.getLastCommandName())) {
      this.input = currentFind.input
      this.repeated = true
    }
  }

  isBackwards () {
    return this.backwards
  }

  execute () {
    super.execute()
    let decorationType = 'post-confirm'
    if (this.operator && !this.operator.instanceof('SelectBase')) {
      decorationType += ' long'
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

  getPoint (fromPoint) {
    const scanRange = this.editor.bufferRangeForBufferRow(fromPoint.row)
    const points = []
    const regex = this.getRegex(this.input)
    const indexWantAccess = this.getCount() - 1

    const translation = new Point(0, this.isBackwards() ? this.offset : -this.offset)
    if (this.repeated) {
      fromPoint = fromPoint.translate(translation.negate())
    }

    if (this.isBackwards()) {
      if (this.getConfig('findAcrossLines')) scanRange.start = Point.ZERO

      this.editor.backwardsScanInBufferRange(regex, scanRange, ({range, stop}) => {
        if (range.start.isLessThan(fromPoint)) {
          points.push(range.start)
          if (points.length > indexWantAccess) stop()
        }
      })
    } else {
      if (this.getConfig('findAcrossLines')) scanRange.end = this.editor.getEofBufferPosition()

      this.editor.scanInBufferRange(regex, scanRange, ({range, stop}) => {
        if (range.start.isGreaterThan(fromPoint)) {
          points.push(range.start)
          if (points.length > indexWantAccess) stop()
        }
      })
    }

    const point = points[indexWantAccess]
    if (point) return point.translate(translation)
  }

  // FIXME: bad naming, this function must return index
  highlightTextInCursorRows (text, decorationType, backwards, index = this.getCount() - 1, adjustIndex = false) {
    if (!this.getConfig('highlightFindChar')) return

    return this.vimState.highlightFind.highlightCursorRows(
      this.getRegex(text),
      decorationType,
      backwards,
      this.offset,
      index,
      adjustIndex
    )
  }

  moveCursor (cursor) {
    const point = this.getPoint(cursor.getBufferPosition())
    if (point) cursor.setBufferPosition(point)
    else this.restoreEditorState()

    if (!this.repeated) this.globalState.set('currentFind', this)
  }

  getRegex (term) {
    const modifiers = this.isCaseSensitive(term) ? 'g' : 'gi'
    return new RegExp(this._.escapeRegExp(term), modifiers)
  }
}

// keymap: F
class FindBackwards extends Find {
  inclusive = false
  backwards = true
}

// keymap: t
class Till extends Find {
  offset = 1
  getPoint (...args) {
    const point = super.getPoint(...args)
    this.moveSucceeded = point != null
    return point
  }
}

// keymap: T
class TillBackwards extends Till {
  inclusive = false
  backwards = true
}

// Mark
// -------------------------
// keymap: `
class MoveToMark extends Motion {
  jump = true
  requireInput = true
  input = null
  moveToFirstCharacterOfLine = false

  initialize () {
    this.readChar()
    super.initialize()
  }

  moveCursor (cursor) {
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

// keymap: '
class MoveToMarkLine extends MoveToMark {
  wise = 'linewise'
  moveToFirstCharacterOfLine = true
}

// Fold motion
// -------------------------
class MotionByFold extends Motion {
  static command = false
  wise = 'characterwise'
  which = null
  direction = null

  execute () {
    this.foldRanges = this.utils.getCodeFoldRanges(this.editor)
    super.execute()
  }

  getRows () {
    const rows = this.foldRanges.map(foldRange => foldRange[this.which].row).sort((a, b) => a - b)
    if (this.direction === 'previous') {
      return rows.reverse()
    } else {
      return rows
    }
  }

  findRowBy (cursor, fn) {
    const cursorRow = cursor.getBufferRow()
    return this.getRows().find(row => {
      if (this.direction === 'previous') {
        return row < cursorRow && fn(row)
      } else {
        return row > cursorRow && fn(row)
      }
    })
  }

  findRow (cursor) {
    return this.findRowBy(cursor, () => true)
  }

  moveCursor (cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const row = this.findRow(cursor)
      if (row != null) this.utils.moveCursorToFirstCharacterAtRow(cursor, row)
    })
  }
}

class MoveToPreviousFoldStart extends MotionByFold {
  which = 'start'
  direction = 'previous'
}

class MoveToNextFoldStart extends MotionByFold {
  which = 'start'
  direction = 'next'
}

class MoveToPreviousFoldEnd extends MotionByFold {
  which = 'end'
  direction = 'previous'
}

class MoveToNextFoldEnd extends MotionByFold {
  which = 'end'
  direction = 'next'
}

// -------------------------
class MoveToPreviousFunction extends MotionByFold {
  which = 'start'
  direction = 'previous'
  findRow (cursor) {
    return this.findRowBy(cursor, row => this.utils.isIncludeFunctionScopeForRow(this.editor, row))
  }
}

class MoveToNextFunction extends MoveToPreviousFunction {
  direction = 'next'
}

class MoveToPreviousFunctionAndRedrawCursorLineAtUpperMiddle extends MoveToPreviousFunction {
  execute () {
    super.execute()
    this.getInstance('RedrawCursorLineAtUpperMiddle').execute()
  }
}

class MoveToNextFunctionAndRedrawCursorLineAtUpperMiddle extends MoveToPreviousFunctionAndRedrawCursorLineAtUpperMiddle {
  direction = 'next'
}

// -------------------------
class MotionByFoldWithSameIndent extends MotionByFold {
  static command = false

  findRow (cursor) {
    const closestFoldRange = this.utils.getClosestFoldRangeContainsRow(this.editor, cursor.getBufferRow())
    const indentationForBufferRow = row => this.editor.indentationForBufferRow(row)
    const baseIndentLevel = closestFoldRange ? indentationForBufferRow(closestFoldRange.start.row) : 0
    const isEqualIndentLevel = range => indentationForBufferRow(range.start.row) === baseIndentLevel

    const cursorRow = cursor.getBufferRow()
    const foldRanges = this.direction === 'previous' ? this.foldRanges.slice().reverse() : this.foldRanges
    const foldRange = foldRanges.find(foldRange => {
      const row = foldRange[this.which].row
      if (this.direction === 'previous') {
        return row < cursorRow && isEqualIndentLevel(foldRange)
      } else {
        return row > cursorRow && isEqualIndentLevel(foldRange)
      }
    })
    if (foldRange) {
      return foldRange[this.which].row
    }
  }
}

class MoveToPreviousFoldStartWithSameIndent extends MotionByFoldWithSameIndent {
  which = 'start'
  direction = 'previous'
}

class MoveToNextFoldStartWithSameIndent extends MotionByFoldWithSameIndent {
  which = 'start'
  direction = 'next'
}

class MoveToPreviousFoldEndWithSameIndent extends MotionByFoldWithSameIndent {
  which = 'end'
  direction = 'previous'
}

class MoveToNextFoldEndWithSameIndent extends MotionByFoldWithSameIndent {
  which = 'end'
  direction = 'next'
}

// Scope based
// -------------------------
class MotionByScope extends Motion {
  static command = false
  direction = 'backward'
  scope = '.'

  moveCursor (cursor) {
    this.moveCursorCountTimes(cursor, () => {
      const cursorPosition = cursor.getBufferPosition()
      const point = this.utils.detectScopeStartPositionForScope(this.editor, cursorPosition, this.direction, this.scope)
      if (point) cursor.setBufferPosition(point)
    })
  }
}

class MoveToPreviousString extends MotionByScope {
  direction = 'backward'
  scope = 'string.begin'
}

class MoveToNextString extends MoveToPreviousString {
  direction = 'forward'
}

class MoveToPreviousNumber extends MotionByScope {
  direction = 'backward'
  scope = 'constant.numeric'
}

class MoveToNextNumber extends MoveToPreviousNumber {
  direction = 'forward'
}

class MoveToNextOccurrence extends Motion {
  // Ensure this command is available when only has-occurrence
  static commandScope = 'atom-text-editor.vim-mode-plus.has-occurrence'
  jump = true
  direction = 'next'

  execute () {
    this.ranges = this.utils.sortRanges(this.occurrenceManager.getMarkers().map(marker => marker.getBufferRange()))
    super.execute()
  }

  moveCursor (cursor) {
    const range = this.ranges[this.utils.getIndex(this.getIndex(cursor.getBufferPosition()), this.ranges)]
    const point = range.start
    cursor.setBufferPosition(point, {autoscroll: false})

    this.editor.unfoldBufferRow(point.row)
    if (cursor.isLastCursor()) {
      this.utils.smartScrollToBufferPosition(this.editor, point)
    }

    if (this.getConfig('flashOnMoveToOccurrence')) {
      this.vimState.flash(range, {type: 'search'})
    }
  }

  getIndex (fromPoint) {
    const index = this.ranges.findIndex(range => range.start.isGreaterThan(fromPoint))
    return (index >= 0 ? index : 0) + this.getCount() - 1
  }
}

class MoveToPreviousOccurrence extends MoveToNextOccurrence {
  direction = 'previous'

  getIndex (fromPoint) {
    const ranges = this.ranges.slice().reverse()
    const range = ranges.find(range => range.end.isLessThan(fromPoint))
    const index = range ? this.ranges.indexOf(range) : this.ranges.length - 1
    return index - (this.getCount() - 1)
  }
}

// -------------------------
// keymap: %
class MoveToPair extends Motion {
  inclusive = true
  jump = true
  member = ['Parenthesis', 'CurlyBracket', 'SquareBracket']

  moveCursor (cursor) {
    const point = this.getPoint(cursor)
    if (point) cursor.setBufferPosition(point)
  }

  getPointForTag (point) {
    const pairInfo = this.getInstance('ATag').getPairInfo(point)
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

  getPoint (cursor) {
    const cursorPosition = cursor.getBufferPosition()
    const cursorRow = cursorPosition.row
    const point = this.getPointForTag(cursorPosition)
    if (point) return point

    // AAnyPairAllowForwarding return forwarding range or enclosing range.
    const range = this.getInstance('AAnyPairAllowForwarding', {member: this.member}).getRange(cursor.selection)
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

module.exports = {
  Motion,
  CurrentSelection,
  MoveLeft,
  MoveRight,
  MoveRightBufferColumn,
  MoveUp,
  MoveUpWrap,
  MoveDown,
  MoveDownWrap,
  MoveUpScreen,
  MoveDownScreen,
  MoveUpToEdge,
  MoveDownToEdge,
  MotionByWord,
  MoveToNextWord,
  MoveToNextWholeWord,
  MoveToNextAlphanumericWord,
  MoveToNextSmartWord,
  MoveToNextSubword,
  MoveToPreviousWord,
  MoveToPreviousWholeWord,
  MoveToPreviousAlphanumericWord,
  MoveToPreviousSmartWord,
  MoveToPreviousSubword,
  MoveToEndOfWord,
  MoveToEndOfWholeWord,
  MoveToEndOfAlphanumericWord,
  MoveToEndOfSmartWord,
  MoveToEndOfSubword,
  MoveToPreviousEndOfWord,
  MoveToPreviousEndOfWholeWord,
  MoveToNextSentence,
  MoveToPreviousSentence,
  MoveToNextSentenceSkipBlankRow,
  MoveToPreviousSentenceSkipBlankRow,
  MoveToNextParagraph,
  MoveToPreviousParagraph,
  MoveToNextDiffHunk,
  MoveToPreviousDiffHunk,
  MoveToBeginningOfLine,
  MoveToColumn,
  MoveToLastCharacterOfLine,
  MoveToLastNonblankCharacterOfLineAndDown,
  MoveToFirstCharacterOfLine,
  MoveToFirstCharacterOfLineUp,
  MoveToFirstCharacterOfLineDown,
  MoveToFirstCharacterOfLineAndDown,
  MoveToScreenColumn,
  MoveToBeginningOfScreenLine,
  MoveToFirstCharacterOfScreenLine,
  MoveToLastCharacterOfScreenLine,
  MoveToFirstLine,
  MoveToLastLine,
  MoveToLineByPercent,
  MoveToRelativeLine,
  MoveToRelativeLineMinimumTwo,
  MoveToTopOfScreen,
  MoveToMiddleOfScreen,
  MoveToBottomOfScreen,
  Scroll,
  ScrollFullScreenDown,
  ScrollFullScreenUp,
  ScrollHalfScreenDown,
  ScrollHalfScreenUp,
  ScrollQuarterScreenDown,
  ScrollQuarterScreenUp,
  Find,
  FindBackwards,
  Till,
  TillBackwards,
  MoveToMark,
  MoveToMarkLine,
  MotionByFold,
  MoveToPreviousFoldStart,
  MoveToNextFoldStart,
  MotionByFoldWithSameIndent,
  MoveToPreviousFoldStartWithSameIndent,
  MoveToNextFoldStartWithSameIndent,
  MoveToPreviousFoldEndWithSameIndent,
  MoveToNextFoldEndWithSameIndent,
  MoveToPreviousFoldEnd,
  MoveToNextFoldEnd,
  MoveToPreviousFunction,
  MoveToNextFunction,
  MoveToPreviousFunctionAndRedrawCursorLineAtUpperMiddle,
  MoveToNextFunctionAndRedrawCursorLineAtUpperMiddle,
  MotionByScope,
  MoveToPreviousString,
  MoveToNextString,
  MoveToPreviousNumber,
  MoveToNextNumber,
  MoveToNextOccurrence,
  MoveToPreviousOccurrence,
  MoveToPair
}
