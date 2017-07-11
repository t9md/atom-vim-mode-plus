_ = require 'underscore-plus'
{Point, Range} = require 'atom'

{
  moveCursorLeft, moveCursorRight
  moveCursorUpScreen, moveCursorDownScreen
  pointIsAtVimEndOfFile
  getFirstVisibleScreenRow, getLastVisibleScreenRow
  getValidVimScreenRow, getValidVimBufferRow
  moveCursorToFirstCharacterAtRow
  sortRanges
  pointIsOnWhiteSpace
  moveCursorToNextNonWhitespace
  isEmptyRow
  getCodeFoldRowRanges
  getLargestFoldRangeContainsBufferRow
  isIncludeFunctionScopeForRow
  detectScopeStartPositionForScope
  getBufferRows
  getTextInScreenRange
  setBufferRow
  setBufferColumn
  limitNumber
  getIndex
  smartScrollToBufferPosition
  pointIsAtEndOfLineAtNonEmptyRow
  getEndOfLineForBufferRow
  findRangeInBufferRow
} = require './utils'

Base = require './base'

class Motion extends Base
  @extend(false)
  @operationKind: 'motion'
  inclusive: false
  wise: 'characterwise'
  jump: false
  verticalMotion: false
  moveSucceeded: null
  moveSuccessOnLinewise: false

  constructor: ->
    super

    if @mode is 'visual'
      @wise = @submode
    @initialize()

  isLinewise: -> @wise is 'linewise'
  isBlockwise: -> @wise is 'blockwise'

  forceWise: (wise) ->
    if wise is 'characterwise'
      if @wise is 'linewise'
        @inclusive = false
      else
        @inclusive = not @inclusive
    @wise = wise

  setBufferPositionSafely: (cursor, point) ->
    cursor.setBufferPosition(point) if point?

  setScreenPositionSafely: (cursor, point) ->
    cursor.setScreenPosition(point) if point?

  moveWithSaveJump: (cursor) ->
    if cursor.isLastCursor() and @jump
      cursorPosition = cursor.getBufferPosition()

    @moveCursor(cursor)

    if cursorPosition? and not cursorPosition.isEqual(cursor.getBufferPosition())
      @vimState.mark.set('`', cursorPosition)
      @vimState.mark.set("'", cursorPosition)

  execute: ->
    if @operator?
      @select()
    else
      @moveWithSaveJump(cursor) for cursor in @editor.getCursors()
    @editor.mergeCursors()
    @editor.mergeIntersectingSelections()

  # NOTE: Modify selection by modtion, selection is already "normalized" before this function is called.
  select: ->
    isOrWasVisual = @mode is 'visual' or @is('CurrentSelection') # need to care was visual for `.` repeated.
    for selection in @editor.getSelections()
      selection.modifySelection =>
        @moveWithSaveJump(selection.cursor)

      succeeded = @moveSucceeded ? not selection.isEmpty() or (@moveSuccessOnLinewise and @isLinewise())
      if isOrWasVisual or (succeeded and (@inclusive or @isLinewise()))
        $selection = @swrap(selection)
        $selection.saveProperties(true) # save property of "already-normalized-selection"
        $selection.applyWise(@wise)

    @vimState.getLastBlockwiseSelection().autoscroll() if @wise is 'blockwise'

  setCursorBufferRow: (cursor, row, options) ->
    if @verticalMotion and @getConfig('moveToFirstCharacterOnVerticalMotion')
      cursor.setBufferPosition(@getFirstCharacterPositionForBufferRow(row), options)
    else
      setBufferRow(cursor, row, options)

  # [NOTE]
  # Since this function checks cursor position change, a cursor position MUST be
  # updated IN callback(=fn)
  # Updating point only in callback is wrong-use of this funciton,
  # since it stops immediately because of not cursor position change.
  moveCursorCountTimes: (cursor, fn) ->
    oldPosition = cursor.getBufferPosition()
    @countTimes @getCount(), (state) ->
      fn(state)
      if (newPosition = cursor.getBufferPosition()).isEqual(oldPosition)
        state.stop()
      oldPosition = newPosition

# Used as operator's target in visual-mode.
class CurrentSelection extends Motion
  @extend(false)
  selectionExtent: null
  blockwiseSelectionExtent: null
  inclusive: true

  initialize: ->
    super
    @pointInfoByCursor = new Map

  moveCursor: (cursor) ->
    if @mode is 'visual'
      if @isBlockwise()
        @blockwiseSelectionExtent = @swrap(cursor.selection).getBlockwiseSelectionExtent()
      else
        @selectionExtent = @editor.getSelectedBufferRange().getExtent()
    else
      # `.` repeat case
      point = cursor.getBufferPosition()

      if @blockwiseSelectionExtent?
        cursor.setBufferPosition(point.translate(@blockwiseSelectionExtent))
      else
        cursor.setBufferPosition(point.traverse(@selectionExtent))

  select: ->
    if @mode is 'visual'
      super
    else
      for cursor in @editor.getCursors() when pointInfo = @pointInfoByCursor.get(cursor)
        {cursorPosition, startOfSelection} = pointInfo
        if cursorPosition.isEqual(cursor.getBufferPosition())
          cursor.setBufferPosition(startOfSelection)
      super

    # * Purpose of pointInfoByCursor? see #235 for detail.
    # When stayOnTransformString is enabled, cursor pos is not set on start of
    # of selected range.
    # But I want following behavior, so need to preserve position info.
    #  1. `vj>.` -> indent same two rows regardless of current cursor's row.
    #  2. `vj>j.` -> indent two rows from cursor's row.
    for cursor in @editor.getCursors()
      startOfSelection = cursor.selection.getBufferRange().start
      @onDidFinishOperation =>
        cursorPosition = cursor.getBufferPosition()
        @pointInfoByCursor.set(cursor, {startOfSelection, cursorPosition})

class MoveLeft extends Motion
  @extend()
  moveCursor: (cursor) ->
    allowWrap = @getConfig('wrapLeftRightMotion')
    @moveCursorCountTimes cursor, ->
      moveCursorLeft(cursor, {allowWrap})

class MoveRight extends Motion
  @extend()
  canWrapToNextLine: (cursor) ->
    if @isAsTargetExceptSelect() and not cursor.isAtEndOfLine()
      false
    else
      @getConfig('wrapLeftRightMotion')

  moveCursor: (cursor) ->
    @moveCursorCountTimes cursor, =>
      cursorPosition = cursor.getBufferPosition()
      @editor.unfoldBufferRow(cursorPosition.row)
      allowWrap = @canWrapToNextLine(cursor)
      moveCursorRight(cursor)
      if cursor.isAtEndOfLine() and allowWrap and not pointIsAtVimEndOfFile(@editor, cursorPosition)
        moveCursorRight(cursor, {allowWrap})

class MoveRightBufferColumn extends Motion
  @extend(false)

  moveCursor: (cursor) ->
    setBufferColumn(cursor, cursor.getBufferColumn() + @getCount())

class MoveUp extends Motion
  @extend()
  wise: 'linewise'
  wrap: false

  getBufferRow: (row) ->
    row = @getNextRow(row)
    if @editor.isFoldedAtBufferRow(row)
      getLargestFoldRangeContainsBufferRow(@editor, row).start.row
    else
      row

  getNextRow: (row) ->
    min = 0
    if @wrap and row is min
      @getVimLastBufferRow()
    else
      limitNumber(row - 1, {min})

  moveCursor: (cursor) ->
    @moveCursorCountTimes cursor, =>
      setBufferRow(cursor, @getBufferRow(cursor.getBufferRow()))

class MoveUpWrap extends MoveUp
  @extend()
  wrap: true

class MoveDown extends MoveUp
  @extend()
  wise: 'linewise'
  wrap: false

  getBufferRow: (row) ->
    if @editor.isFoldedAtBufferRow(row)
      row = getLargestFoldRangeContainsBufferRow(@editor, row).end.row
    @getNextRow(row)

  getNextRow: (row) ->
    max = @getVimLastBufferRow()
    if @wrap and row >= max
      0
    else
      limitNumber(row + 1, {max})

class MoveDownWrap extends MoveDown
  @extend()
  wrap: true

class MoveUpScreen extends Motion
  @extend()
  wise: 'linewise'
  direction: 'up'

  moveCursor: (cursor) ->
    @moveCursorCountTimes cursor, ->
      moveCursorUpScreen(cursor)

class MoveDownScreen extends MoveUpScreen
  @extend()
  wise: 'linewise'
  direction: 'down'

  moveCursor: (cursor) ->
    @moveCursorCountTimes cursor, ->
      moveCursorDownScreen(cursor)

# Move down/up to Edge
# -------------------------
# See t9md/atom-vim-mode-plus#236
# At least v1.7.0. bufferPosition and screenPosition cannot convert accurately
# when row is folded.
class MoveUpToEdge extends Motion
  @extend()
  wise: 'linewise'
  jump: true
  direction: 'up'
  @description: "Move cursor up to **edge** char at same-column"

  moveCursor: (cursor) ->
    @moveCursorCountTimes cursor, =>
      @setScreenPositionSafely(cursor, @getPoint(cursor.getScreenPosition()))

  getPoint: (fromPoint) ->
    column = fromPoint.column
    for row in @getScanRows(fromPoint) when @isEdge(point = new Point(row, column))
      return point

  getScanRows: ({row}) ->
    validRow = getValidVimScreenRow.bind(null, @editor)
    switch @direction
      when 'up' then [validRow(row - 1)..0]
      when 'down' then [validRow(row + 1)..@getVimLastScreenRow()]

  isEdge: (point) ->
    if @isStoppablePoint(point)
      # If one of above/below point was not stoppable, it's Edge!
      above = point.translate([-1, 0])
      below = point.translate([+1, 0])
      (not @isStoppablePoint(above)) or (not @isStoppablePoint(below))
    else
      false

  isStoppablePoint: (point) ->
    if @isNonWhiteSpacePoint(point)
      true
    else
      leftPoint = point.translate([0, -1])
      rightPoint = point.translate([0, +1])
      @isNonWhiteSpacePoint(leftPoint) and @isNonWhiteSpacePoint(rightPoint)

  isNonWhiteSpacePoint: (point) ->
    char = getTextInScreenRange(@editor, Range.fromPointWithDelta(point, 0, 1))
    char? and /\S/.test(char)

class MoveDownToEdge extends MoveUpToEdge
  @extend()
  @description: "Move cursor down to **edge** char at same-column"
  direction: 'down'

# word
# -------------------------
class MoveToNextWord extends Motion
  @extend()
  wordRegex: null

  getPoint: (pattern, from) ->
    wordRange = null
    found = false
    vimEOF = @getVimEofBufferPosition(@editor)

    @scanForward pattern, {from}, ({range, matchText, stop}) ->
      wordRange = range
      # Ignore 'empty line' matches between '\r' and '\n'
      return if matchText is '' and range.start.column isnt 0
      if range.start.isGreaterThan(from)
        found = true
        stop()

    if found
      point = wordRange.start
      if pointIsAtEndOfLineAtNonEmptyRow(@editor, point) and not point.isEqual(vimEOF)
        point.traverse([1, 0])
      else
        point
    else
      wordRange?.end ? from

  # Special case: "cw" and "cW" are treated like "ce" and "cE" if the cursor is
  # on a non-blank.  This is because "cw" is interpreted as change-word, and a
  # word does not include the following white space.  {Vi: "cw" when on a blank
  # followed by other blanks changes only the first blank; this is probably a
  # bug, because "dw" deletes all the blanks}
  #
  # Another special case: When using the "w" motion in combination with an
  # operator and the last word moved over is at the end of a line, the end of
  # that word becomes the end of the operated text, not the first word in the
  # next line.
  moveCursor: (cursor) ->
    cursorPosition = cursor.getBufferPosition()
    return if pointIsAtVimEndOfFile(@editor, cursorPosition)
    wasOnWhiteSpace = pointIsOnWhiteSpace(@editor, cursorPosition)

    isAsTargetExceptSelect = @isAsTargetExceptSelect()
    @moveCursorCountTimes cursor, ({isFinal}) =>
      cursorPosition = cursor.getBufferPosition()
      if isEmptyRow(@editor, cursorPosition.row) and isAsTargetExceptSelect
        point = cursorPosition.traverse([1, 0])
      else
        pattern = @wordRegex ? cursor.wordRegExp()
        point = @getPoint(pattern, cursorPosition)
        if isFinal and isAsTargetExceptSelect
          if @operator.is('Change') and (not wasOnWhiteSpace)
            point = cursor.getEndOfCurrentWordBufferPosition({@wordRegex})
          else
            point = Point.min(point, getEndOfLineForBufferRow(@editor, cursorPosition.row))
      cursor.setBufferPosition(point)

# b
class MoveToPreviousWord extends Motion
  @extend()
  wordRegex: null

  moveCursor: (cursor) ->
    @moveCursorCountTimes cursor, =>
      point = cursor.getBeginningOfCurrentWordBufferPosition({@wordRegex})
      cursor.setBufferPosition(point)

class MoveToEndOfWord extends Motion
  @extend()
  wordRegex: null
  inclusive: true

  moveToNextEndOfWord: (cursor) ->
    moveCursorToNextNonWhitespace(cursor)
    point = cursor.getEndOfCurrentWordBufferPosition({@wordRegex}).translate([0, -1])
    point = Point.min(point, @getVimEofBufferPosition())
    cursor.setBufferPosition(point)

  moveCursor: (cursor) ->
    @moveCursorCountTimes cursor, =>
      originalPoint = cursor.getBufferPosition()
      @moveToNextEndOfWord(cursor)
      if originalPoint.isEqual(cursor.getBufferPosition())
        # Retry from right column if cursor was already on EndOfWord
        cursor.moveRight()
        @moveToNextEndOfWord(cursor)

# [TODO: Improve, accuracy]
class MoveToPreviousEndOfWord extends MoveToPreviousWord
  @extend()
  inclusive: true

  moveCursor: (cursor) ->
    times = @getCount()
    wordRange = cursor.getCurrentWordBufferRange()
    cursorPosition = cursor.getBufferPosition()

    # if we're in the middle of a word then we need to move to its start
    if cursorPosition.isGreaterThan(wordRange.start) and cursorPosition.isLessThan(wordRange.end)
      times += 1

    for [1..times]
      point = cursor.getBeginningOfCurrentWordBufferPosition({@wordRegex})
      cursor.setBufferPosition(point)

    @moveToNextEndOfWord(cursor)
    if cursor.getBufferPosition().isGreaterThanOrEqual(cursorPosition)
      cursor.setBufferPosition([0, 0])

  moveToNextEndOfWord: (cursor) ->
    point = cursor.getEndOfCurrentWordBufferPosition({@wordRegex}).translate([0, -1])
    point = Point.min(point, @getVimEofBufferPosition())
    cursor.setBufferPosition(point)

# Whole word
# -------------------------
class MoveToNextWholeWord extends MoveToNextWord
  @extend()
  wordRegex: /^$|\S+/g

class MoveToPreviousWholeWord extends MoveToPreviousWord
  @extend()
  wordRegex: /^$|\S+/g

class MoveToEndOfWholeWord extends MoveToEndOfWord
  @extend()
  wordRegex: /\S+/

# [TODO: Improve, accuracy]
class MoveToPreviousEndOfWholeWord extends MoveToPreviousEndOfWord
  @extend()
  wordRegex: /\S+/

# Alphanumeric word [Experimental]
# -------------------------
class MoveToNextAlphanumericWord extends MoveToNextWord
  @extend()
  @description: "Move to next alphanumeric(`/\w+/`) word"
  wordRegex: /\w+/g

class MoveToPreviousAlphanumericWord extends MoveToPreviousWord
  @extend()
  @description: "Move to previous alphanumeric(`/\w+/`) word"
  wordRegex: /\w+/

class MoveToEndOfAlphanumericWord extends MoveToEndOfWord
  @extend()
  @description: "Move to end of alphanumeric(`/\w+/`) word"
  wordRegex: /\w+/

# Alphanumeric word [Experimental]
# -------------------------
class MoveToNextSmartWord extends MoveToNextWord
  @extend()
  @description: "Move to next smart word (`/[\w-]+/`) word"
  wordRegex: /[\w-]+/g

class MoveToPreviousSmartWord extends MoveToPreviousWord
  @extend()
  @description: "Move to previous smart word (`/[\w-]+/`) word"
  wordRegex: /[\w-]+/

class MoveToEndOfSmartWord extends MoveToEndOfWord
  @extend()
  @description: "Move to end of smart word (`/[\w-]+/`) word"
  wordRegex: /[\w-]+/

# Subword
# -------------------------
class MoveToNextSubword extends MoveToNextWord
  @extend()
  moveCursor: (cursor) ->
    @wordRegex = cursor.subwordRegExp()
    super

class MoveToPreviousSubword extends MoveToPreviousWord
  @extend()
  moveCursor: (cursor) ->
    @wordRegex = cursor.subwordRegExp()
    super

class MoveToEndOfSubword extends MoveToEndOfWord
  @extend()
  moveCursor: (cursor) ->
    @wordRegex = cursor.subwordRegExp()
    super

# Sentence
# -------------------------
# Sentence is defined as below
#  - end with ['.', '!', '?']
#  - optionally followed by [')', ']', '"', "'"]
#  - followed by ['$', ' ', '\t']
#  - paragraph boundary is also sentence boundary
#  - section boundary is also sentence boundary(ignore)
class MoveToNextSentence extends Motion
  @extend()
  jump: true
  sentenceRegex: ///(?:[\.!\?][\)\]"']*\s+)|(\n|\r\n)///g
  direction: 'next'

  moveCursor: (cursor) ->
    @moveCursorCountTimes cursor, =>
      @setBufferPositionSafely(cursor, @getPoint(cursor.getBufferPosition()))

  getPoint: (fromPoint) ->
    if @direction is 'next'
      @getNextStartOfSentence(fromPoint)
    else if @direction is 'previous'
      @getPreviousStartOfSentence(fromPoint)

  isBlankRow: (row) ->
    @editor.isBufferRowBlank(row)

  getNextStartOfSentence: (from) ->
    foundPoint = null
    @scanForward @sentenceRegex, {from}, ({range, matchText, match, stop}) =>
      if match[1]?
        [startRow, endRow] = [range.start.row, range.end.row]
        return if @skipBlankRow and @isBlankRow(endRow)
        if @isBlankRow(startRow) isnt @isBlankRow(endRow)
          foundPoint = @getFirstCharacterPositionForBufferRow(endRow)
      else
        foundPoint = range.end
      stop() if foundPoint?
    foundPoint ? @getVimEofBufferPosition()

  getPreviousStartOfSentence: (from) ->
    foundPoint = null
    @scanBackward @sentenceRegex, {from}, ({range, match, stop, matchText}) =>
      if match[1]?
        [startRow, endRow] = [range.start.row, range.end.row]
        if not @isBlankRow(endRow) and @isBlankRow(startRow)
          point = @getFirstCharacterPositionForBufferRow(endRow)
          if point.isLessThan(from)
            foundPoint = point
          else
            return if @skipBlankRow
            foundPoint = @getFirstCharacterPositionForBufferRow(startRow)
      else
        if range.end.isLessThan(from)
          foundPoint = range.end
      stop() if foundPoint?
    foundPoint ? [0, 0]

class MoveToPreviousSentence extends MoveToNextSentence
  @extend()
  direction: 'previous'

class MoveToNextSentenceSkipBlankRow extends MoveToNextSentence
  @extend()
  skipBlankRow: true

class MoveToPreviousSentenceSkipBlankRow extends MoveToPreviousSentence
  @extend()
  skipBlankRow: true

# Paragraph
# -------------------------
class MoveToNextParagraph extends Motion
  @extend()
  jump: true
  direction: 'next'

  moveCursor: (cursor) ->
    @moveCursorCountTimes cursor, =>
      @setBufferPositionSafely(cursor, @getPoint(cursor.getBufferPosition()))

  getPoint: (fromPoint) ->
    startRow = fromPoint.row
    wasAtNonBlankRow = not @editor.isBufferRowBlank(startRow)
    for row in getBufferRows(@editor, {startRow, @direction})
      if @editor.isBufferRowBlank(row)
        return new Point(row, 0) if wasAtNonBlankRow
      else
        wasAtNonBlankRow = true

    # fallback
    switch @direction
      when 'previous' then new Point(0, 0)
      when 'next' then @getVimEofBufferPosition()

class MoveToPreviousParagraph extends MoveToNextParagraph
  @extend()
  direction: 'previous'

# -------------------------
class MoveToBeginningOfLine extends Motion
  @extend()

  moveCursor: (cursor) ->
    setBufferColumn(cursor, 0)

class MoveToColumn extends Motion
  @extend()

  moveCursor: (cursor) ->
    setBufferColumn(cursor, @getCount(-1))

class MoveToLastCharacterOfLine extends Motion
  @extend()

  moveCursor: (cursor) ->
    row = getValidVimBufferRow(@editor, cursor.getBufferRow() + @getCount(-1))
    cursor.setBufferPosition([row, Infinity])
    cursor.goalColumn = Infinity

class MoveToLastNonblankCharacterOfLineAndDown extends Motion
  @extend()
  inclusive: true

  moveCursor: (cursor) ->
    point = @getPoint(cursor.getBufferPosition())
    cursor.setBufferPosition(point)

  getPoint: ({row}) ->
    row = limitNumber(row + @getCount(-1), max: @getVimLastBufferRow())
    range = findRangeInBufferRow(@editor, /\S|^/, row, direction: 'backward')
    range?.start ? new Point(row, 0)

# MoveToFirstCharacterOfLine faimily
# ------------------------------------
class MoveToFirstCharacterOfLine extends Motion
  @extend()
  moveCursor: (cursor) ->
    point = @getFirstCharacterPositionForBufferRow(cursor.getBufferRow())
    @setBufferPositionSafely(cursor, point)

class MoveToFirstCharacterOfLineUp extends MoveToFirstCharacterOfLine
  @extend()
  wise: 'linewise'
  moveCursor: (cursor) ->
    @moveCursorCountTimes cursor, ->
      point = cursor.getBufferPosition()
      unless point.row is 0
        cursor.setBufferPosition(point.translate([-1, 0]))
    super

class MoveToFirstCharacterOfLineDown extends MoveToFirstCharacterOfLine
  @extend()
  wise: 'linewise'
  moveCursor: (cursor) ->
    @moveCursorCountTimes cursor, =>
      point = cursor.getBufferPosition()
      unless @getVimLastBufferRow() is point.row
        cursor.setBufferPosition(point.translate([+1, 0]))
    super

class MoveToFirstCharacterOfLineAndDown extends MoveToFirstCharacterOfLineDown
  @extend()
  defaultCount: 0
  getCount: -> super - 1

# keymap: g g
class MoveToFirstLine extends Motion
  @extend()
  wise: 'linewise'
  jump: true
  verticalMotion: true
  moveSuccessOnLinewise: true

  moveCursor: (cursor) ->
    @setCursorBufferRow(cursor, getValidVimBufferRow(@editor, @getRow()))
    cursor.autoscroll(center: true)

  getRow: ->
    @getCount(-1)

# keymap: G
class MoveToLastLine extends MoveToFirstLine
  @extend()
  defaultCount: Infinity

# keymap: N% e.g. 10%
class MoveToLineByPercent extends MoveToFirstLine
  @extend()

  getRow: ->
    percent = limitNumber(@getCount(), max: 100)
    Math.floor((@editor.getLineCount() - 1) * (percent / 100))

class MoveToRelativeLine extends Motion
  @extend(false)
  wise: 'linewise'
  moveSuccessOnLinewise: true

  moveCursor: (cursor) ->
    row = @getFoldEndRowForRow(cursor.getBufferRow())

    count = @getCount(-1)
    while (count > 0)
      row = @getFoldEndRowForRow(row + 1)
      count--

    setBufferRow(cursor, row)

class MoveToRelativeLineMinimumOne extends MoveToRelativeLine
  @extend(false)

  getCount: ->
    limitNumber(super, min: 1)

# Position cursor without scrolling., H, M, L
# -------------------------
# keymap: H
class MoveToTopOfScreen extends Motion
  @extend()
  wise: 'linewise'
  jump: true
  scrolloff: 2
  defaultCount: 0
  verticalMotion: true

  moveCursor: (cursor) ->
    bufferRow = @editor.bufferRowForScreenRow(@getScreenRow())
    @setCursorBufferRow(cursor, bufferRow)

  getScrolloff: ->
    if @isAsTargetExceptSelect()
      0
    else
      @scrolloff

  getScreenRow: ->
    firstRow = getFirstVisibleScreenRow(@editor)
    offset = @getScrolloff()
    offset = 0 if firstRow is 0
    offset = limitNumber(@getCount(-1), min: offset)
    firstRow + offset

# keymap: M
class MoveToMiddleOfScreen extends MoveToTopOfScreen
  @extend()
  getScreenRow: ->
    startRow = getFirstVisibleScreenRow(@editor)
    endRow = limitNumber(@editor.getLastVisibleScreenRow(), max: @getVimLastScreenRow())
    startRow + Math.floor((endRow - startRow) / 2)

# keymap: L
class MoveToBottomOfScreen extends MoveToTopOfScreen
  @extend()
  getScreenRow: ->
    # [FIXME]
    # At least Atom v1.6.0, there are two implementation of getLastVisibleScreenRow()
    # editor.getLastVisibleScreenRow() and editorElement.getLastVisibleScreenRow()
    # Those two methods return different value, editor's one is corrent.
    # So I intentionally use editor.getLastScreenRow here.
    vimLastScreenRow = @getVimLastScreenRow()
    row = limitNumber(@editor.getLastVisibleScreenRow(), max: vimLastScreenRow)
    offset = @getScrolloff() + 1
    offset = 0 if row is vimLastScreenRow
    offset = limitNumber(@getCount(-1), min: offset)
    row - offset

# Scrolling
# Half: ctrl-d, ctrl-u
# Full: ctrl-f, ctrl-b
# -------------------------
# [FIXME] count behave differently from original Vim.
class Scroll extends Motion
  @extend(false)
  verticalMotion: true

  isSmoothScrollEnabled: ->
    if Math.abs(@amountOfPage) is 1
      @getConfig('smoothScrollOnFullScrollMotion')
    else
      @getConfig('smoothScrollOnHalfScrollMotion')

  getSmoothScrollDuation: ->
    if Math.abs(@amountOfPage) is 1
      @getConfig('smoothScrollOnFullScrollMotionDuration')
    else
      @getConfig('smoothScrollOnHalfScrollMotionDuration')

  getPixelRectTopForSceenRow: (row) ->
    point = new Point(row, 0)
    @editor.element.pixelRectForScreenRange(new Range(point, point)).top

  smoothScroll: (fromRow, toRow, done) ->
    topPixelFrom = {top: @getPixelRectTopForSceenRow(fromRow)}
    topPixelTo = {top: @getPixelRectTopForSceenRow(toRow)}
    # [NOTE]
    # intentionally use `element.component.setScrollTop` instead of `element.setScrollTop`.
    # SInce element.setScrollTop will throw exception when element.component no longer exists.
    step = (newTop) =>
      if @editor.element.component?
        @editor.element.component.setScrollTop(newTop)
        @editor.element.component.updateSync()

    duration = @getSmoothScrollDuation()
    @vimState.requestScrollAnimation(topPixelFrom, topPixelTo, {duration, step, done})

  getAmountOfRows: ->
    Math.ceil(@amountOfPage * @editor.getRowsPerPage() * @getCount())

  getBufferRow: (cursor) ->
    screenRow = getValidVimScreenRow(@editor, cursor.getScreenRow() + @getAmountOfRows())
    @editor.bufferRowForScreenRow(screenRow)

  moveCursor: (cursor) ->
    bufferRow = @getBufferRow(cursor)
    @setCursorBufferRow(cursor, @getBufferRow(cursor), autoscroll: false)

    if cursor.isLastCursor()
      if @isSmoothScrollEnabled()
        @vimState.finishScrollAnimation()

      firstVisibileScreenRow = @editor.getFirstVisibleScreenRow()
      newFirstVisibileBufferRow = @editor.bufferRowForScreenRow(firstVisibileScreenRow + @getAmountOfRows())
      newFirstVisibileScreenRow = @editor.screenRowForBufferRow(newFirstVisibileBufferRow)
      done = =>
        @editor.setFirstVisibleScreenRow(newFirstVisibileScreenRow)
        # [FIXME] sometimes, scrollTop is not updated, calling this fix.
        # Investigate and find better approach then remove this workaround.
        @editor.element.component?.updateSync()

      if @isSmoothScrollEnabled()
        @smoothScroll(firstVisibileScreenRow, newFirstVisibileScreenRow, done)
      else
        done()


# keymap: ctrl-f
class ScrollFullScreenDown extends Scroll
  @extend(true)
  amountOfPage: +1

# keymap: ctrl-b
class ScrollFullScreenUp extends Scroll
  @extend()
  amountOfPage: -1

# keymap: ctrl-d
class ScrollHalfScreenDown extends Scroll
  @extend()
  amountOfPage: +1 / 2

# keymap: ctrl-u
class ScrollHalfScreenUp extends Scroll
  @extend()
  amountOfPage: -1 / 2

# Find
# -------------------------
# keymap: f
class Find extends Motion
  @extend()
  backwards: false
  inclusive: true
  offset: 0
  requireInput: true

  initialize: ->
    super
    @focusInput() unless @isComplete()

  isBackwards: ->
    @backwards

  getPoint: (fromPoint) ->
    {start, end} = @editor.bufferRangeForBufferRow(fromPoint.row)

    offset = if @isBackwards() then @offset else -@offset
    unOffset = -offset * @repeated
    if @isBackwards()
      scanRange = [start, fromPoint.translate([0, unOffset])]
      method = 'backwardsScanInBufferRange'
    else
      scanRange = [fromPoint.translate([0, 1 + unOffset]), end]
      method = 'scanInBufferRange'

    points = []
    @editor[method] ///#{_.escapeRegExp(@input)}///g, scanRange, ({range}) ->
      points.push(range.start)
    points[@getCount(-1)]?.translate([0, offset])

  moveCursor: (cursor) ->
    point = @getPoint(cursor.getBufferPosition())
    @setBufferPositionSafely(cursor, point)
    @globalState.set('currentFind', this) unless @repeated

# keymap: F
class FindBackwards extends Find
  @extend()
  inclusive: false
  backwards: true

# keymap: t
class Till extends Find
  @extend()
  offset: 1

  getPoint: ->
    @point = super
    @moveSucceeded = @point?
    return @point

# keymap: T
class TillBackwards extends Till
  @extend()
  inclusive: false
  backwards: true

# Mark
# -------------------------
# keymap: `
class MoveToMark extends Motion
  @extend()
  jump: true
  requireInput: true
  input: null # set when instatntiated via vimState::moveToMark()

  initialize: ->
    super
    @focusInput() unless @isComplete()

  getPoint: ->
    @vimState.mark.get(@input)

  moveCursor: (cursor) ->
    if point = @getPoint()
      cursor.setBufferPosition(point)
      cursor.autoscroll(center: true)

# keymap: '
class MoveToMarkLine extends MoveToMark
  @extend()
  wise: 'linewise'

  getPoint: ->
    if point = super
      @getFirstCharacterPositionForBufferRow(point.row)

# Fold
# -------------------------
class MoveToPreviousFoldStart extends Motion
  @extend()
  @description: "Move to previous fold start"
  wise: 'characterwise'
  which: 'start'
  direction: 'prev'

  initialize: ->
    super
    @rows = @getFoldRows(@which)
    @rows.reverse() if @direction is 'prev'

  getFoldRows: (which) ->
    index = if which is 'start' then 0 else 1
    rows = getCodeFoldRowRanges(@editor).map (rowRange) ->
      rowRange[index]
    _.sortBy(_.uniq(rows), (row) -> row)

  getScanRows: (cursor) ->
    cursorRow = cursor.getBufferRow()
    isValidRow = switch @direction
      when 'prev' then (row) -> row < cursorRow
      when 'next' then (row) -> row > cursorRow
    @rows.filter(isValidRow)

  detectRow: (cursor) ->
    @getScanRows(cursor)[0]

  moveCursor: (cursor) ->
    @moveCursorCountTimes cursor, =>
      if (row = @detectRow(cursor))?
        moveCursorToFirstCharacterAtRow(cursor, row)

class MoveToNextFoldStart extends MoveToPreviousFoldStart
  @extend()
  @description: "Move to next fold start"
  direction: 'next'

class MoveToPreviousFoldStartWithSameIndent extends MoveToPreviousFoldStart
  @extend()
  @description: "Move to previous same-indented fold start"
  detectRow: (cursor) ->
    baseIndentLevel = @getIndentLevelForBufferRow(cursor.getBufferRow())
    for row in @getScanRows(cursor)
      if @getIndentLevelForBufferRow(row) is baseIndentLevel
        return row
    null

class MoveToNextFoldStartWithSameIndent extends MoveToPreviousFoldStartWithSameIndent
  @extend()
  @description: "Move to next same-indented fold start"
  direction: 'next'

class MoveToPreviousFoldEnd extends MoveToPreviousFoldStart
  @extend()
  @description: "Move to previous fold end"
  which: 'end'

class MoveToNextFoldEnd extends MoveToPreviousFoldEnd
  @extend()
  @description: "Move to next fold end"
  direction: 'next'

# -------------------------
class MoveToPreviousFunction extends MoveToPreviousFoldStart
  @extend()
  @description: "Move to previous function"
  direction: 'prev'
  detectRow: (cursor) ->
    _.detect @getScanRows(cursor), (row) =>
      isIncludeFunctionScopeForRow(@editor, row)

class MoveToNextFunction extends MoveToPreviousFunction
  @extend()
  @description: "Move to next function"
  direction: 'next'

# Scope based
# -------------------------
class MoveToPositionByScope extends Motion
  @extend(false)
  direction: 'backward'
  scope: '.'

  getPoint: (fromPoint) ->
    detectScopeStartPositionForScope(@editor, fromPoint, @direction, @scope)

  moveCursor: (cursor) ->
    @moveCursorCountTimes cursor, =>
      @setBufferPositionSafely(cursor, @getPoint(cursor.getBufferPosition()))

class MoveToPreviousString extends MoveToPositionByScope
  @extend()
  @description: "Move to previous string(searched by `string.begin` scope)"
  direction: 'backward'
  scope: 'string.begin'

class MoveToNextString extends MoveToPreviousString
  @extend()
  @description: "Move to next string(searched by `string.begin` scope)"
  direction: 'forward'

class MoveToPreviousNumber extends MoveToPositionByScope
  @extend()
  direction: 'backward'
  @description: "Move to previous number(searched by `constant.numeric` scope)"
  scope: 'constant.numeric'

class MoveToNextNumber extends MoveToPreviousNumber
  @extend()
  @description: "Move to next number(searched by `constant.numeric` scope)"
  direction: 'forward'

class MoveToNextOccurrence extends Motion
  @extend()
  # Ensure this command is available when has-occurrence
  @commandScope: 'atom-text-editor.vim-mode-plus.has-occurrence'
  jump: true
  direction: 'next'

  getRanges: ->
    @vimState.occurrenceManager.getMarkers().map (marker) ->
      marker.getBufferRange()

  execute: ->
    @ranges = @getRanges()
    super

  moveCursor: (cursor) ->
    index = @getIndex(cursor.getBufferPosition())
    if index?
      offset = switch @direction
        when 'next' then @getCount(-1)
        when 'previous' then -@getCount(-1)
      range = @ranges[getIndex(index + offset, @ranges)]
      point = range.start

      cursor.setBufferPosition(point, autoscroll: false)

      if cursor.isLastCursor()
        @editor.unfoldBufferRow(point.row)
        smartScrollToBufferPosition(@editor, point)

      if @getConfig('flashOnMoveToOccurrence')
        @vimState.flash(range, type: 'search')

  getIndex: (fromPoint) ->
    for range, i in @ranges when range.start.isGreaterThan(fromPoint)
      return i
    0

class MoveToPreviousOccurrence extends MoveToNextOccurrence
  @extend()
  direction: 'previous'

  getIndex: (fromPoint) ->
    for range, i in @ranges by -1 when range.end.isLessThan(fromPoint)
      return i
    @ranges.length - 1

# -------------------------
# keymap: %
class MoveToPair extends Motion
  @extend()
  inclusive: true
  jump: true
  member: ['Parenthesis', 'CurlyBracket', 'SquareBracket']

  moveCursor: (cursor) ->
    @setBufferPositionSafely(cursor, @getPoint(cursor))

  getPointForTag: (point) ->
    pairInfo = @new("ATag").getPairInfo(point)
    return null unless pairInfo?
    {openRange, closeRange} = pairInfo
    openRange = openRange.translate([0, +1], [0, -1])
    closeRange = closeRange.translate([0, +1], [0, -1])
    return closeRange.start if openRange.containsPoint(point) and (not point.isEqual(openRange.end))
    return openRange.start if closeRange.containsPoint(point) and (not point.isEqual(closeRange.end))

  getPoint: (cursor) ->
    cursorPosition = cursor.getBufferPosition()
    cursorRow = cursorPosition.row
    return point if point = @getPointForTag(cursorPosition)

    # AAnyPairAllowForwarding return forwarding range or enclosing range.
    range = @new("AAnyPairAllowForwarding", {@member}).getRange(cursor.selection)
    return null unless range?
    {start, end} = range
    if (start.row is cursorRow) and start.isGreaterThanOrEqual(cursorPosition)
      # Forwarding range found
      end.translate([0, -1])
    else if end.row is cursorPosition.row
      # Enclosing range was returned
      # We move to start( open-pair ) only when close-pair was at same row as cursor-row.
      start
