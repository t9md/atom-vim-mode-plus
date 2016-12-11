_ = require 'underscore-plus'
{Point, Range} = require 'atom'
Select = null

{
  moveCursorLeft, moveCursorRight
  moveCursorUpScreen, moveCursorDownScreen
  moveCursorDownBuffer
  moveCursorUpBuffer
  cursorIsAtVimEndOfFile
  getFirstVisibleScreenRow, getLastVisibleScreenRow
  getValidVimScreenRow, getValidVimBufferRow
  moveCursorToFirstCharacterAtRow
  sortRanges
  getIndentLevelForBufferRow
  cursorIsOnWhiteSpace
  moveCursorToNextNonWhitespace
  cursorIsAtEmptyRow
  getCodeFoldRowRanges
  getLargestFoldRangeContainsBufferRow
  isIncludeFunctionScopeForRow
  detectScopeStartPositionForScope
  getBufferRows
  getStartPositionForPattern
  getFirstCharacterBufferPositionForScreenRow
  screenPositionIsAtWhiteSpace
  cursorIsAtEndOfLineAtNonEmptyRow
  getFirstCharacterScreenPositionForScreenRow
  setBufferRow
  setBufferColumn
  limitNumber
  getIndex
  smartScrollToBufferPosition
} = require './utils'

swrap = require './selection-wrapper'
settings = require './settings'
Base = require './base'

class Motion extends Base
  @extend(false)
  inclusive: false
  wise: 'characterwise'
  jump: false
  verticalMotion: false

  constructor: ->
    super

    # visual mode can overwrite default wise and inclusiveness
    if @vimState.mode is 'visual'
      @inclusive = true
      @wise = @vimState.submode
    @initialize()

  isInclusive: ->
    @inclusive

  isJump: ->
    @jump

  isVerticalMotion: ->
    @verticalMotion

  isCharacterwise: ->
    @wise is 'characterwise'

  isLinewise: ->
    @wise is 'linewise'

  isBlockwise: ->
    @wise is 'blockwise'

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
    if cursor.isLastCursor() and @isJump()
      cursorPosition = cursor.getBufferPosition()

    @moveCursor(cursor)

    if cursorPosition? and not cursorPosition.isEqual(cursor.getBufferPosition())
      @vimState.mark.set('`', cursorPosition)
      @vimState.mark.set("'", cursorPosition)

  execute: ->
    @editor.moveCursors (cursor) =>
      @moveWithSaveJump(cursor)

  select: ->
    @vimState.modeManager.normalizeSelections() if @isMode('visual')

    for selection in @editor.getSelections()
      @selectByMotion(selection)

    @editor.mergeCursors()
    @editor.mergeIntersectingSelections()

    @updateSelectionProperties() if @isMode('visual')

    if @hasOperator()
      if @isMode('visual')
        if @isMode('visual', 'linewise') and @editor.getLastSelection().isReversed()
          @vimState.mutationManager.setCheckpoint('did-move')
      else
        @vimState.mutationManager.setCheckpoint('did-move')

    # Modify selection to submode-wisely
    switch @wise
      when 'linewise' then @vimState.selectLinewise()
      when 'blockwise' then @vimState.selectBlockwise()

  selectByMotion: (selection) ->
    {cursor} = selection

    selection.modifySelection =>
      @moveWithSaveJump(cursor)

    return if not @isMode('visual') and selection.isEmpty() # Failed to move.
    return unless @isInclusive() or @isLinewise()

    if @isMode('visual') and cursorIsAtEndOfLineAtNonEmptyRow(cursor)
      # Avoid puting cursor on EOL in visual-mode as long as cursor's row was non-empty.
      swrap(selection).translateSelectionHeadAndClip('backward')
    # to select @inclusive-ly
    swrap(selection).translateSelectionEndAndClip('forward')

  setCursorBuffeRow: (cursor, row, options) ->
    if @isVerticalMotion() and settings.get('moveToFirstCharacterOnVerticalMotion')
      cursor.setBufferPosition(@getFirstCharacterPositionForBufferRow(row), options)
    else
      setBufferRow(cursor, row, options)

# Used as operator's target in visual-mode.
class CurrentSelection extends Motion
  @extend(false)
  selectionExtent: null
  inclusive: true

  initialize: ->
    super
    @pointInfoByCursor = new Map

  execute: ->
    throw new Error("#{@getName()} should not be executed")

  moveCursor: (cursor) ->
    if @isMode('visual')
      if @isBlockwise()
        {start, end} = cursor.selection.getBufferRange()
        [head, tail] = if cursor.selection.isReversed() then [start, end] else [end, start]
        @selectionExtent = new Point(head.row - tail.row, head.column - tail.column)
      else
        @selectionExtent = @editor.getSelectedBufferRange().getExtent()
    else
      point = cursor.getBufferPosition()
      if @isBlockwise()
        cursor.setBufferPosition(point.translate(@selectionExtent))
      else
        cursor.setBufferPosition(point.traverse(@selectionExtent))

  select: ->
    if @isMode('visual')
      super
    else
      for cursor in @editor.getCursors() when pointInfo = @pointInfoByCursor.get(cursor)
        {cursorPosition, startOfSelection, atEOL} = pointInfo
        if atEOL or cursorPosition.isEqual(cursor.getBufferPosition())
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
        atEOL = cursor.isAtEndOfLine()
        @pointInfoByCursor.set(cursor, {startOfSelection, cursorPosition, atEOL})

class MoveLeft extends Motion
  @extend()
  moveCursor: (cursor) ->
    allowWrap = settings.get('wrapLeftRightMotion')
    @countTimes ->
      moveCursorLeft(cursor, {allowWrap})

class MoveRight extends Motion
  @extend()
  canWrapToNextLine: (cursor) ->
    if @isAsOperatorTarget() and not cursor.isAtEndOfLine()
      false
    else
      settings.get('wrapLeftRightMotion')

  moveCursor: (cursor) ->
    @countTimes =>
      @editor.unfoldBufferRow(cursor.getBufferRow())
      allowWrap = @canWrapToNextLine(cursor)
      moveCursorRight(cursor)
      if cursor.isAtEndOfLine() and allowWrap and not cursorIsAtVimEndOfFile(cursor)
        moveCursorRight(cursor, {allowWrap})

class MoveRightBufferColumn extends Motion
  @extend(false)

  moveCursor: (cursor) ->
    setBufferColumn(cursor, cursor.getBufferColumn() + @getCount())

class MoveUp extends Motion
  @extend()
  wise: 'linewise'

  getBufferRow: (row) ->
    row = limitNumber(row - 1, min: 0)
    if @editor.isFoldedAtBufferRow(row)
      getLargestFoldRangeContainsBufferRow(@editor, row).start.row
    else
      row

  moveCursor: (cursor) ->
    @countTimes =>
      setBufferRow(cursor, @getBufferRow(cursor.getBufferRow()))

class MoveDown extends MoveUp
  @extend()
  wise: 'linewise'

  getBufferRow: (row) ->
    if @editor.isFoldedAtBufferRow(row)
      row = getLargestFoldRangeContainsBufferRow(@editor, row).end.row
    limitNumber(row + 1, max: @getVimLastBufferRow())

class MoveUpScreen extends Motion
  @extend()
  wise: 'linewise'
  direction: 'up'

  moveCursor: (cursor) ->
    @countTimes ->
      moveCursorUpScreen(cursor)

class MoveDownScreen extends MoveUpScreen
  @extend()
  wise: 'linewise'
  direction: 'down'

  moveCursor: (cursor) ->
    @countTimes ->
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
    point = cursor.getScreenPosition()
    @countTimes ({stop}) =>
      if (newPoint = @getPoint(point))
        point = newPoint
      else
        stop()
    @setScreenPositionSafely(cursor, point)

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
    screenPositionIsAtWhiteSpace(@editor, point)

class MoveDownToEdge extends MoveUpToEdge
  @extend()
  @description: "Move cursor down to **edge** char at same-column"
  direction: 'down'

# word
# -------------------------
class MoveToNextWord extends Motion
  @extend()
  wordRegex: null

  getPoint: (cursor) ->
    cursorPoint = cursor.getBufferPosition()
    pattern = @wordRegex ? cursor.wordRegExp()
    scanRange = [cursorPoint, @getVimEofBufferPosition()]

    wordRange = null
    found = false
    @editor.scanInBufferRange pattern, scanRange, ({range, matchText, stop}) ->
      wordRange = range
      # Ignore 'empty line' matches between '\r' and '\n'
      return if matchText is '' and range.start.column isnt 0
      if range.start.isGreaterThan(cursorPoint)
        found = true
        stop()

    if found
      wordRange.start
    else
      wordRange?.end ? cursorPoint

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
    return if cursorIsAtVimEndOfFile(cursor)
    wasOnWhiteSpace = cursorIsOnWhiteSpace(cursor)
    @countTimes ({isFinal}) =>
      cursorRow = cursor.getBufferRow()
      if cursorIsAtEmptyRow(cursor) and @isAsOperatorTarget()
        point = [cursorRow + 1, 0]
      else
        point = @getPoint(cursor)
        if isFinal and @isAsOperatorTarget()
          if @getOperator().is('Change') and (not wasOnWhiteSpace)
            point = cursor.getEndOfCurrentWordBufferPosition({@wordRegex})
          else if (point.row > cursorRow)
            point = [cursorRow, Infinity]
        else
      cursor.setBufferPosition(point)

# b
class MoveToPreviousWord extends Motion
  @extend()
  wordRegex: null

  moveCursor: (cursor) ->
    @countTimes =>
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
    @countTimes =>
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
  wordRegex: /^\s*$|\S+/g

class MoveToPreviousWholeWord extends MoveToPreviousWord
  @extend()
  wordRegex: /^\s*$|\S+/

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
    point = cursor.getBufferPosition()
    @countTimes =>
      point = @getPoint(point)
    cursor.setBufferPosition(point)

  getPoint: (fromPoint) ->
    if @direction is 'next'
      @getNextStartOfSentence(fromPoint)
    else if @direction is 'previous'
      @getPreviousStartOfSentence(fromPoint)

  isBlankRow: (row) ->
    @editor.isBufferRowBlank(row)

  getNextStartOfSentence: (fromPoint) ->
    scanRange = new Range(fromPoint, @getVimEofBufferPosition())
    foundPoint = null
    @editor.scanInBufferRange @sentenceRegex, scanRange, ({range, matchText, match, stop}) =>
      if match[1]?
        [startRow, endRow] = [range.start.row, range.end.row]
        return if @skipBlankRow and @isBlankRow(endRow)
        if @isBlankRow(startRow) isnt @isBlankRow(endRow)
          foundPoint = @getFirstCharacterPositionForBufferRow(endRow)
      else
        foundPoint = range.end
      stop() if foundPoint?
    foundPoint ? scanRange.end

  getPreviousStartOfSentence: (fromPoint) ->
    scanRange = new Range(fromPoint, [0, 0])
    foundPoint = null
    @editor.backwardsScanInBufferRange @sentenceRegex, scanRange, ({range, match, stop, matchText}) =>
      if match[1]?
        [startRow, endRow] = [range.start.row, range.end.row]
        if not @isBlankRow(endRow) and @isBlankRow(startRow)
          point = @getFirstCharacterPositionForBufferRow(endRow)
          if point.isLessThan(fromPoint)
            foundPoint = point
          else
            return if @skipBlankRow
            foundPoint = @getFirstCharacterPositionForBufferRow(startRow)
      else
        if range.end.isLessThan(fromPoint)
          foundPoint = range.end
      stop() if foundPoint?
    foundPoint ? scanRange.start

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
    point = cursor.getBufferPosition()
    @countTimes =>
      point = @getPoint(point)
    cursor.setBufferPosition(point)

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
    from = new Point(row, Infinity)
    point = getStartPositionForPattern(@editor, from, /\s*$/)
    (point ? from).translate([0, -1])

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
    @countTimes ->
      moveCursorUpBuffer(cursor)
    super

class MoveToFirstCharacterOfLineDown extends MoveToFirstCharacterOfLine
  @extend()
  wise: 'linewise'
  moveCursor: (cursor) ->
    @countTimes ->
      moveCursorDownBuffer(cursor)
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

  moveCursor: (cursor) ->
    @setCursorBuffeRow(cursor, getValidVimBufferRow(@editor, @getRow()))
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

  moveCursor: (cursor) ->
    setBufferRow(cursor, cursor.getBufferRow() + @getCount(-1))

class MoveToRelativeLineWithMinimum extends MoveToRelativeLine
  @extend(false)
  min: 0

  getCount: ->
    limitNumber(super, {@min})

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
    @setCursorBuffeRow(cursor, bufferRow)

  getScrolloff: ->
    if @isAsOperatorTarget()
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
      settings.get('smoothScrollOnFullScrollMotion')
    else
      settings.get('smoothScrollOnHalfScrollMotion')

  getSmoothScrollDuation: ->
    if Math.abs(@amountOfPage) is 1
      settings.get('smoothScrollOnFullScrollMotionDuration')
    else
      settings.get('smoothScrollOnHalfScrollMotionDuration')

  getPixelRectTopForSceenRow: (row) ->
    point = new Point(row, 0)
    @editor.element.pixelRectForScreenRange(new Range(point, point)).top

  smoothScroll: (fromRow, toRow, options={}) ->
    topPixelFrom = {top: @getPixelRectTopForSceenRow(fromRow)}
    topPixelTo = {top: @getPixelRectTopForSceenRow(toRow)}
    options.step = (newTop) => @editor.element.setScrollTop(newTop)
    options.duration = @getSmoothScrollDuation()
    @vimState.requestScrollAnimation(topPixelFrom, topPixelTo, options)

  getAmountOfRows: ->
    Math.ceil(@amountOfPage * @editor.getRowsPerPage() * @getCount())

  getBufferRow: (cursor) ->
    screenRow = getValidVimScreenRow(@editor, cursor.getScreenRow() + @getAmountOfRows())
    @editor.bufferRowForScreenRow(screenRow)

  moveCursor: (cursor) ->
    bufferRow = @getBufferRow(cursor)
    @setCursorBuffeRow(cursor, @getBufferRow(cursor), autoscroll: false)

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
        @editor.element.component.updateSync()

      if @isSmoothScrollEnabled()
        @smoothScroll(firstVisibileScreenRow, newFirstVisibileScreenRow, {done})
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
  hover: icon: ':find:', emoji: ':mag_right:'
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
    unOffset = -offset * @isRepeated()
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
    @globalState.set('currentFind', this) unless @isRepeated()

# keymap: F
class FindBackwards extends Find
  @extend()
  inclusive: false
  backwards: true
  hover: icon: ':find:', emoji: ':mag:'

# keymap: t
class Till extends Find
  @extend()
  offset: 1

  getPoint: ->
    @point = super

  selectByMotion: (selection) ->
    super
    if selection.isEmpty() and (@point? and not @backwards)
      swrap(selection).translateSelectionEndAndClip('forward')

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
  hover: icon: ":move-to-mark:`", emoji: ":round_pushpin:`"
  input: null # set when instatntiated via vimState::moveToMark()

  initialize: ->
    super
    @focusInput() unless @isComplete()

  getPoint: ->
    @vimState.mark.get(@getInput())

  moveCursor: (cursor) ->
    if point = @getPoint()
      cursor.setBufferPosition(point)
      cursor.autoscroll(center: true)

# keymap: '
class MoveToMarkLine extends MoveToMark
  @extend()
  hover: icon: ":move-to-mark:'", emoji: ":round_pushpin:'"
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
    @countTimes =>
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
    baseIndentLevel = getIndentLevelForBufferRow(@editor, cursor.getBufferRow())
    for row in @getScanRows(cursor)
      if getIndentLevelForBufferRow(@editor, row) is baseIndentLevel
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
    point = cursor.getBufferPosition()
    @countTimes ({stop}) =>
      if (newPoint = @getPoint(point))
        point = newPoint
      else
        stop()
    @setBufferPositionSafely(cursor, point)

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
  jump: true
  direction: 'next'

  initialize: ->
    super
    # point
    {@occurrenceManager} = @vimState
    if @occurrenceManager.hasMarkers()
      @ranges = @occurrenceManager.getMarkers().map (marker) -> marker.getBufferRange()
    else
      # point
      @abort()

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

      if settings.get('flashOnMoveToOccurrence')
        @vimState.flash(range, type: 'search')

  getIndex: (fromPoint) ->
    for range, i in @ranges when range.start.isGreaterThan(fromPoint)
      return i
    0

class MoveToPreviousOccurrence extends MoveToNextOccurrence
  @extend()
  direction: 'previous'

  getIndex: (fromPoint) ->
    for range, i in @ranges by -1 when range.start.isLessThan(fromPoint)
      return i
    @ranges.length - 1

# -------------------------
# keymap: %
class MoveToPair extends Motion
  @extend()
  inclusive: true
  jump: true
  member: ['Parenthesis', 'CurlyBracket', 'SquareBracket', 'AngleBracket']

  moveCursor: (cursor) ->
    @setBufferPositionSafely(cursor, @getPoint(cursor))

  getPoint: (cursor) ->
    cursorPosition = cursor.getBufferPosition()
    cursorRow = cursorPosition.row

    getPointForTag = =>
      p = cursorPosition
      pairInfo = @new("ATag").getPairInfo(p)
      return null unless pairInfo?
      {openRange, closeRange} = pairInfo
      openRange = openRange.translate([0, +1], [0, -1])
      closeRange = closeRange.translate([0, +1], [0, -1])
      return closeRange.start if openRange.containsPoint(p) and (not p.isEqual(openRange.end))
      return openRange.start if closeRange.containsPoint(p) and (not p.isEqual(closeRange.end))

    point = getPointForTag()
    return point if point?

    ranges = @new("AAnyPair", {allowForwarding: true, @member}).getRanges(cursor.selection)
    ranges = ranges.filter ({start, end}) ->
      p = cursorPosition
      (p.row is start.row) and start.isGreaterThanOrEqual(p) or
        (p.row is end.row) and end.isGreaterThanOrEqual(p)

    return null unless ranges.length
    # Calling containsPoint exclusive(pass true as 2nd arg) make opening pair under
    # cursor is grouped to forwardingRanges
    [enclosingRanges, forwardingRanges] = _.partition ranges, (range) ->
      range.containsPoint(cursorPosition, true)
    enclosingRange = _.last(sortRanges(enclosingRanges))
    forwardingRanges = sortRanges(forwardingRanges)

    if enclosingRange
      forwardingRanges = forwardingRanges.filter (range) ->
        enclosingRange.containsRange(range)

    forwardingRanges[0]?.end.translate([0, -1]) or enclosingRange?.start
