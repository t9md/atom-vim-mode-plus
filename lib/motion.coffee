_ = require 'underscore-plus'
{Point, Range} = require 'atom'
Select = null

{
  saveEditorState, getVisibleBufferRange
  moveCursorLeft, moveCursorRight
  moveCursorUpScreen, moveCursorDownScreen
  moveCursorDownBuffer
  moveCursorUpBuffer
  cursorIsAtVimEndOfFile
  getFirstVisibleScreenRow, getLastVisibleScreenRow
  getValidVimScreenRow, getValidVimBufferRow
  highlightRanges
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
  getEndPositionForPattern
  getFirstCharacterPositionForBufferRow
  getFirstCharacterBufferPositionForScreenRow
  getTextInScreenRange
  cursorIsAtEndOfLineAtNonEmptyRow

  debug
} = require './utils'

swrap = require './selection-wrapper'
{MatchList} = require './match'
settings = require './settings'
Base = require './base'

class Motion extends Base
  @extend(false)
  inclusive: false
  linewise: false

  constructor: ->
    super
    @initialize()

  isBlockwise: ->
    @isMode('visual', 'blockwise')

  isInclusive: ->
    @isMode('visual') or @isAsOperatorTarget() and @inclusive

  isLinewise: ->
    @isMode('visual', 'linewise') or @isAsOperatorTarget() and @linewise

  setBufferPositionSafely: (cursor, point) ->
    cursor.setBufferPosition(point) if point?

  setScreenPositionSafely: (cursor, point) ->
    cursor.setScreenPosition(point) if point?

  execute: ->
    @editor.moveCursors (cursor) =>
      @moveCursor(cursor)

  select: ->
    @vimState.modeManager.normalizeSelections() if @isMode('visual')

    for selection in @editor.getSelections()
      @selectByMotion(selection)

    @editor.mergeCursors()
    @editor.mergeIntersectingSelections()

    @updateSelectionProperties() if @isMode('visual')

    # Modify selection to submode-wisely
    switch
      when @isLinewise() then @vimState.selectLinewise()
      when @isBlockwise() then @vimState.selectBlockwise()

  selectByMotion: (selection) ->
    {cursor} = selection

    selection.modifySelection =>
      @moveCursor(cursor)

    return if not @isMode('visual') and selection.isEmpty() # Failed to move.
    return unless @isInclusive() or @isLinewise()

    if @isMode('visual') and cursorIsAtEndOfLineAtNonEmptyRow(cursor)
      # Avoid puting cursor on EOL in visual-mode as long as cursor's row was non-empty.
      swrap(selection).translateSelectionHeadAndClip('backward')
    # to select @inclusive-ly
    swrap(selection).translateSelectionEndAndClip('forward')

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
        @isBlockwise = -> true
        {start, end} = cursor.selection.getBufferRange()
        [head, tail] = if cursor.selection.isReversed() then [start, end] else [end, start]
        @selectionExtent = new Point(head.row - tail.row, head.column - tail.column)
      else
        @selectionExtent = @editor.getSelectedBufferRange().getExtent()

      @linewise = @isLinewise() # Cache it in case repeated.
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

class MoveUp extends Motion
  @extend()
  linewise: true

  getPoint: (cursor) ->
    row = @getRow(cursor.getBufferRow())
    new Point(row, cursor.goalColumn)

  getRow: (row) ->
    row = Math.max(row - 1, 0)
    if @editor.isFoldedAtBufferRow(row)
      row = getLargestFoldRangeContainsBufferRow(@editor, row).start.row
    row

  moveCursor: (cursor) ->
    @countTimes =>
      cursor.goalColumn ?= cursor.getBufferColumn()
      {goalColumn} = cursor
      cursor.setBufferPosition(@getPoint(cursor))
      cursor.goalColumn = goalColumn

class MoveDown extends MoveUp
  @extend()
  linewise: true

  getRow: (row) ->
    if @editor.isFoldedAtBufferRow(row)
      row = getLargestFoldRangeContainsBufferRow(@editor, row).end.row
    Math.min(row + 1, @getVimLastBufferRow())

class MoveUpScreen extends Motion
  @extend()
  linewise: true
  direction: 'up'

  moveCursor: (cursor) ->
    @countTimes ->
      moveCursorUpScreen(cursor)

class MoveDownScreen extends MoveUpScreen
  @extend()
  linewise: true
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
  linewise: true
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
    for row in @getScanRows(fromPoint)
      if @isMovablePoint(point = new Point(row, fromPoint.column))
        return point

  getScanRows: ({row}) ->
    validRow = getValidVimScreenRow.bind(null, @editor)
    switch @direction
      when 'up' then [validRow(row - 1)..0]
      when 'down' then [validRow(row + 1)..@getVimLastScreenRow()]

  isMovablePoint: (point) ->
    if @isStoppablePoint(point)
      # first and last row is always edge.
      if point.row in [0, @getVimLastScreenRow()]
        true
      else
        @isEdge(point)
    else
      false

  isEdge: (point) ->
    # If one of above/below row is not stoppable, it's Edge!
    above = point.translate([-1, 0])
    below = point.translate([+1, 0])
    (not @isStoppablePoint(above)) or (not @isStoppablePoint(below))

  # Avoid stopping on leading and trailing whitespace,
  isValidStoppablePoint: ({row, column}) ->
    text = getTextInScreenRange(@editor, [[row, 0], [row, Infinity]])
    softTabText = _.multiplyString(' ', @editor.getTabLength())
    text = text.replace(/\t/g, softTabText)
    if (match = text.match(/\S/g))?
      [firstChar, ..., lastChar] = match
      text.indexOf(firstChar) <= column <= text.lastIndexOf(lastChar)
    else
      false

  isStoppablePoint: (point) ->
    if point.row in [0, @getVimLastScreenRow()]
      true
    else if @isNonBlankPoint(point)
      true
    else if @isValidStoppablePoint(point)
      left = point.translate([0, -1])
      right = point.translate([0, +1])
      @isNonBlankPoint(left) and @isNonBlankPoint(right)
    else
      false

  isNonBlankPoint: (point) ->
    screenRange = Range.fromPointWithDelta(point, 0, 1)
    char = getTextInScreenRange(@editor, screenRange)
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

  moveCursor: (cursor) ->
    return if cursorIsAtVimEndOfFile(cursor)
    wasOnWhiteSpace = cursorIsOnWhiteSpace(cursor)
    @countTimes ({isFinal}) =>
      cursorRow = cursor.getBufferRow()
      if cursorIsAtEmptyRow(cursor) and @isAsOperatorTarget()
        point = [cursorRow+1, 0]
      else
        point = @getPoint(cursor)
        if isFinal and @isAsOperatorTarget()
          if @getOperator().getName() is 'Change' and (not wasOnWhiteSpace)
            point = cursor.getEndOfCurrentWordBufferPosition({@wordRegex})
          else if (point.row > cursorRow)
            point = [cursorRow, Infinity]
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

# Paragraph
# -------------------------
class MoveToNextParagraph extends Motion
  @extend()
  direction: 'next'

  moveCursor: (cursor) ->
    point = cursor.getBufferPosition()
    @countTimes =>
      point = @getPoint(point)
    cursor.setBufferPosition(point)

  getPoint: (fromPoint) ->
    wasAtNonBlankRow = not @editor.isBufferRowBlank(fromPoint.row)
    for row in getBufferRows(@editor, {startRow: fromPoint.row, @direction})
      if @editor.isBufferRowBlank(row)
        return new Point(row, 0) if wasAtNonBlankRow
      else
        wasAtNonBlankRow = true

    switch @direction
      when 'previous' then new Point(0, 0)
      when 'next' then @getVimEofBufferPosition()

class MoveToPreviousParagraph extends MoveToNextParagraph
  @extend()
  direction: 'previous'

# -------------------------
class MoveToBeginningOfLine extends Motion
  @extend()

  getPoint: ({row}) ->
    new Point(row, 0)

  moveCursor: (cursor) ->
    point = @getPoint(cursor.getBufferPosition())
    cursor.setBufferPosition(point)

class MoveToColumn extends Motion
  @extend()
  getCount: ->
    super - 1

  getPoint: ({row}) ->
    new Point(row, @getCount())

  moveCursor: (cursor) ->
    point = @getPoint(cursor.getScreenPosition())
    cursor.setScreenPosition(point)

class MoveToLastCharacterOfLine extends Motion
  @extend()

  getCount: ->
    super - 1

  getPoint: ({row}) ->
    row = getValidVimBufferRow(@editor, row + @getCount())
    new Point(row, Infinity)

  moveCursor: (cursor) ->
    point = @getPoint(cursor.getBufferPosition())
    cursor.setBufferPosition(point)
    cursor.goalColumn = Infinity

class MoveToLastNonblankCharacterOfLineAndDown extends Motion
  @extend()
  inclusive: true

  getCount: ->
    super - 1

  moveCursor: (cursor) ->
    point = @getPoint(cursor.getBufferPosition())
    cursor.setBufferPosition(point)

  getPoint: ({row}) ->
    row = Math.min(row + @getCount(), @getVimLastBufferRow())
    from = new Point(row, Infinity)
    point = getStartPositionForPattern(@editor, from, /\s*$/)
    (point ? from).translate([0, -1])

# MoveToFirstCharacterOfLine faimily
# ------------------------------------
class MoveToFirstCharacterOfLine extends Motion
  @extend()
  moveCursor: (cursor) ->
    @setBufferPositionSafely(cursor, @getPoint(cursor))

  getPoint: (cursor) ->
    getFirstCharacterPositionForBufferRow(@editor, cursor.getBufferRow())

class MoveToFirstCharacterOfLineUp extends MoveToFirstCharacterOfLine
  @extend()
  linewise: true
  moveCursor: (cursor) ->
    @countTimes ->
      moveCursorUpBuffer(cursor)
    super

class MoveToFirstCharacterOfLineDown extends MoveToFirstCharacterOfLine
  @extend()
  linewise: true
  moveCursor: (cursor) ->
    @countTimes ->
      moveCursorDownBuffer(cursor)
    super

class MoveToFirstCharacterOfLineAndDown extends MoveToFirstCharacterOfLineDown
  @extend()
  defaultCount: 0
  getCount: -> super - 1

class MoveToFirstLine extends Motion
  @extend()
  linewise: true
  defaultCount: null

  moveCursor: (cursor) ->
    cursor.setBufferPosition(@getPoint())
    cursor.autoscroll({center: true})

  getPoint: ->
    getFirstCharacterPositionForBufferRow(@editor, @getRow())

  getRow: ->
    if (count = @getCount()) then count - 1 else @getDefaultRow()

  getDefaultRow: ->
    0

# keymap: G
class MoveToLastLine extends MoveToFirstLine
  @extend()
  getDefaultRow: ->
    @getVimLastBufferRow()

# keymap: N% e.g. 10%
class MoveToLineByPercent extends MoveToFirstLine
  @extend()
  getRow: ->
    percent = Math.min(100, @getCount())
    Math.floor(@getVimLastScreenRow() * (percent / 100))

class MoveToRelativeLine extends Motion
  @extend(false)
  linewise: true

  moveCursor: (cursor) ->
    point = @getPoint(cursor.getBufferPosition())
    cursor.setBufferPosition(point)

  getCount: ->
    super - 1

  getPoint: ({row}) ->
    [row + @getCount(), 0]

class MoveToRelativeLineWithMinimum extends MoveToRelativeLine
  @extend(false)
  min: 0

  getCount: ->
    Math.max(@min, super)

# Position cursor without scrolling., H, M, L
# -------------------------
# keymap: H
class MoveToTopOfScreen extends Motion
  @extend()
  linewise: true
  scrolloff: 2
  defaultCount: 0

  getCount: ->
    super - 1

  moveCursor: (cursor) ->
    cursor.setBufferPosition(@getPoint())

  getPoint: ->
    getFirstCharacterBufferPositionForScreenRow(@editor, @getRow())

  getScrolloff: ->
    if @isAsOperatorTarget()
      0
    else
      @scrolloff

  getRow: ->
    row = getFirstVisibleScreenRow(@editor)
    offset = @getScrolloff()
    offset = 0 if (row is 0)
    offset = Math.max(@getCount(), offset)
    row + offset

# keymap: M
class MoveToMiddleOfScreen extends MoveToTopOfScreen
  @extend()
  getRow: ->
    startRow = getFirstVisibleScreenRow(@editor)
    vimLastScreenRow = @getVimLastScreenRow()
    endRow = Math.min(@editor.getLastVisibleScreenRow(), vimLastScreenRow)
    startRow + Math.floor((endRow - startRow) / 2)

# keymap: L
class MoveToBottomOfScreen extends MoveToTopOfScreen
  @extend()
  getRow: ->
    # [FIXME]
    # At least Atom v1.6.0, there are two implementation of getLastVisibleScreenRow()
    # editor.getLastVisibleScreenRow() and editorElement.getLastVisibleScreenRow()
    # Those two methods return different value, editor's one is corrent.
    # So I intentionally use editor.getLastScreenRow here.
    vimLastScreenRow = @getVimLastScreenRow()
    row = Math.min(@editor.getLastVisibleScreenRow(), vimLastScreenRow)
    offset = @getScrolloff() + 1
    offset = 0 if row is vimLastScreenRow
    offset = Math.max(@getCount(), offset)
    row - offset

# Scrolling
# Half: ctrl-d, ctrl-u
# Full: ctrl-f, ctrl-b
# -------------------------
# [FIXME] count behave differently from original Vim.
class ScrollFullScreenDown extends Motion
  @extend()
  amountOfPage: +1

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

  smoothScroll: (fromRow, toRow, options) ->
    topPixelFrom = {top: @getPixelRectTopForSceenRow(fromRow)}
    topPixelTo = {top: @getPixelRectTopForSceenRow(toRow)}
    options.step = (newTop) => @editor.element.setScrollTop(newTop)
    options.duration = @getSmoothScrollDuation()
    @vimState.requestScrollAnimation(topPixelFrom, topPixelTo, options)

  highlightScreenRow: (screenRow) ->
    screenRange = new Range([screenRow, 0], [screenRow, Infinity])
    marker = @editor.markScreenRange(screenRange)
    @editor.decorateMarker(marker, type: 'highlight', class: 'vim-mode-plus-flash')
    marker

  getAmountOfRows: ->
    Math.ceil(@amountOfPage * @editor.getRowsPerPage() * @getCount())

  getPoint: (cursor) ->
    row = getValidVimScreenRow(@editor, cursor.getScreenRow() + @getAmountOfRows())
    new Point(row, 0)

  moveCursor: (cursor) ->
    cursor.setScreenPosition(@getPoint(cursor), autoscroll: false)

    if cursor.isLastCursor()
      if @isSmoothScrollEnabled()
        @vimState.finishScrollAnimation()

      currentTopRow = @editor.getFirstVisibleScreenRow()
      finalTopRow = currentTopRow + @getAmountOfRows()
      done = => @editor.setFirstVisibleScreenRow(finalTopRow)

      if @isSmoothScrollEnabled()
        marker = @highlightScreenRow(cursor.getScreenRow())
        complete = -> marker.destroy()
        @smoothScroll(currentTopRow, finalTopRow, {done, complete})
      else
        done()

# keymap: ctrl-b
class ScrollFullScreenUp extends ScrollFullScreenDown
  @extend()
  amountOfPage: -1

# keymap: ctrl-d
class ScrollHalfScreenDown extends ScrollFullScreenDown
  @extend()
  amountOfPage: +1 / 2

# keymap: ctrl-u
class ScrollHalfScreenUp extends ScrollHalfScreenDown
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
    points[@getCount()]?.translate([0, offset])

  getCount: ->
    super - 1

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
  requireInput: true
  hover: icon: ":move-to-mark:`", emoji: ":round_pushpin:`"
  input: null # set when instatntiated via vimState::moveToMark()

  initialize: ->
    super
    @focusInput() unless @isComplete()

  getPoint: (fromPoint) ->
    input = @getInput()
    point = null

    point = @vimState.mark.get(input)
    if input is '`' # double '`' pressed
      point ?= [0, 0] # if mark was not set, go to the beginning of the file
      @vimState.mark.set('`', fromPoint)

    if point? and @linewise
      point = getFirstCharacterPositionForBufferRow(@editor, point.row)
    point

  moveCursor: (cursor) ->
    point = cursor.getBufferPosition()
    @setBufferPositionSafely(cursor, @getPoint(point))

# keymap: '
class MoveToMarkLine extends MoveToMark
  @extend()
  hover: icon: ":move-to-mark:'", emoji: ":round_pushpin:'"
  linewise: true

# Search
# -------------------------
class SearchBase extends Motion
  @extend(false)
  backwards: false
  useRegexp: true
  configScope: null
  updateSearchHistory: true
  scanRanges: null
  landingPoint: null # ['start' or 'end']
  defaultLandingPoint: 'start' # ['start' or 'end']
  caseSensitivity: null
  quiet: false

  isQuiet: ->
    @quiet

  getCount: ->
    count = super - 1
    count = -count if @isBackwards()
    count

  isBackwards: ->
    @backwards

  getVisualEffectFor: (key) ->
    if @isQuiet()
      false
    else
      settings.get(key)

  needToUpdateSearchHistory: ->
    @updateSearchHistory

  isCaseSensitive: (term) ->
    switch @getCaseSensitivity()
      when 'smartcase' then term.search('[A-Z]') isnt -1
      when 'insensitive' then false
      when 'sensitive' then true

  getCaseSensitivity: ->
    @caseSensitivity ?=
      if settings.get("useSmartcaseFor#{@configScope}")
        'smartcase'
      else if settings.get("ignoreCaseFor#{@configScope}")
        'insensitive'
      else
        'sensitive'

  finish: ->
    if @isIncrementalSearch?() and @getVisualEffectFor('showHoverSearchCounter')
      @vimState.hoverSearchCounter.reset()
    @scanRanges = null
    @matches?.destroy()
    @matches = null

  flashScreen: ->
    highlightRanges @editor, getVisibleBufferRange(@editor),
      class: 'vim-mode-plus-flash'
      timeout: 100
    atom.beep()

  getLandingPoint: ->
    @landingPoint ?= @defaultLandingPoint

  getPoint: (cursor) ->
    input = @getInput()
    @matches ?= @getMatchList(cursor, input)
    if @matches.isEmpty()
      null
    else
      if @getLandingPoint() is 'start'
        @matches.getCurrentStartPosition()
      else
        @matches.getCurrentEndPosition()

  moveCursor: (cursor) ->
    input = @getInput()
    if input is ''
      @finish()
      return

    if point = @getPoint(cursor)
      @visitMatch "current",
        timeout: settings.get('showHoverSearchCounterDuration')
        landing: true
      cursor.setBufferPosition(point, autoscroll: false)
    else
      @flashScreen() if @getVisualEffectFor('flashScreenOnSearchHasNoMatch')

    if @needToUpdateSearchHistory()
      @globalState.set('currentSearch', this)
      @vimState.searchHistory.save(input)

    unless @isQuiet()
      @globalState.set('lastSearchPattern', @getPattern(input))
    @finish()

  getFromPoint: (cursor) ->
    if @isMode('visual', 'linewise') and @isIncrementalSearch?()
      swrap(cursor.selection).getBufferPositionFor('head', fromProperty: true)
    else
      cursor.getBufferPosition()

  getScanRanges: ->
    @scanRanges ? []

  getMatchList: (cursor, input) ->
    MatchList.fromScan @editor,
      fromPoint: @getFromPoint(cursor)
      pattern: @getPattern(input)
      direction: (if @isBackwards() then 'backward' else 'forward')
      countOffset: @getCount()
      scanRanges: @getScanRanges()

  visitMatch: (direction=null, options={}) ->
    {timeout, landing} = options
    landing ?= false
    match = @matches.get(direction)
    match.scrollToStartPoint()

    flashOptions =
      class: 'vim-mode-plus-flash'
      timeout: settings.get('flashOnSearchDuration')

    if landing
      if @getVisualEffectFor('flashOnSearch') and not @isIncrementalSearch?()
        match.flash(flashOptions)
    else
      @matches.refresh()
      if @getVisualEffectFor('flashOnSearch')
        match.flash(flashOptions)

    if @getVisualEffectFor('showHoverSearchCounter')
      @vimState.hoverSearchCounter.withTimeout match.getStartPoint(),
        text: @matches.getCounterText()
        classList: match.getClassList()
        timeout: timeout

# /, ?
# -------------------------
class Search extends SearchBase
  @extend()
  configScope: "Search"
  requireInput: true

  isIncrementalSearch: ->
    settings.get('incrementalSearch')

  initialize: ->
    super
    @activateIncrementalSearch() if @isIncrementalSearch()

    @onDidConfirmSearch ({@input, @landingPoint}) =>
      unless @isIncrementalSearch()
        searchChar = if @isBackwards() then '?' else '/'
        if @input in ['', searchChar]
          @input = @vimState.searchHistory.get('prev')
          atom.beep() unless @input
      @processOperation()

    @onDidCancelSearch =>
      unless @isMode('visual') or @isMode('insert')
        @vimState.resetNormalMode()
      @restoreEditorState?()
      @vimState.reset()
      @finish()

    @onDidChangeSearch (@input) =>
      # If input starts with space, remove first space and disable useRegexp.
      if @input.startsWith(' ')
        @useRegexp = false
        @input = input.replace(/^ /, '')
      else
        @useRegexp = true
      @vimState.searchInput.updateOptionSettings({@useRegexp})

      @visitCursors() if @isIncrementalSearch()
    @vimState.searchInput.focus({@backwards})

  activateIncrementalSearch: ->
    @restoreEditorState = saveEditorState(@editor)
    refresh = => @matches?.refresh()
    @subscribe @editorElement.onDidChangeScrollTop(refresh)
    @subscribe @editorElement.onDidChangeScrollLeft(refresh)

    @onDidCommandSearch (command) =>
      return unless @input
      return if @matches.isEmpty()
      switch command.name
        when 'visit'
          direction = command.direction
          if @isBackwards() and settings.get('incrementalSearchVisitDirection') is 'relative'
            direction = switch direction
              when 'next' then 'prev'
              when 'prev' then 'next'
          @visitMatch(direction)
        when 'occurrence'
          if command.operation?
            @vimState.occurrenceManager.resetPatterns()

          @vimState.occurrenceManager.addPattern(@matches.pattern)
          @vimState.searchHistory.save(@input)
          @vimState.searchInput.cancel()

          if command.operation?
            @vimState.operationStack.run(command.operation)

  visitCursors: ->
    visitCursor = (cursor) =>
      @matches ?= @getMatchList(cursor, input)
      if @matches.isEmpty()
        @flashScreen() if @getVisualEffectFor('flashScreenOnSearchHasNoMatch')
      else
        @visitMatch()

    @matches?.destroy()
    @matches = null
    @vimState.hoverSearchCounter.reset() if @getVisualEffectFor('showHoverSearchCounter')

    input = @getInput()
    if input isnt ''
      visitCursor(cursor) for cursor in @editor.getCursors()

  getPattern: (term) ->
    modifiers = if @isCaseSensitive(term) then 'g' else 'gi'

    # FIXME this prevent search \\c itself.
    # DONT thinklessly mimic pure Vim. Instead, provide ignorecase button and shortcut.
    if term.indexOf('\\c') >= 0
      term = term.replace('\\c', '')
      modifiers += 'i' unless 'i' in modifiers

    if @useRegexp
      try
        new RegExp(term, modifiers)
      catch
        new RegExp(_.escapeRegExp(term), modifiers)
    else
      new RegExp(_.escapeRegExp(term), modifiers)

class SearchBackwards extends Search
  @extend()
  backwards: true

class SearchCurrentLine extends Search
  @extend()
  quiet: true
  getScanRanges: ->
    [@editor.getLastCursor().getCurrentLineBufferRange()]

class SearchCurrentLineBackwards extends SearchCurrentLine
  @extend()
  backwards: true

# *, #
# -------------------------
class SearchCurrentWord extends SearchBase
  @extend()
  configScope: "SearchCurrentWord"

  # NOTE: have side-effect. moving cursor to start of current word.
  getInput: ->
    @input ?= (
      wordRange = @getCurrentWordBufferRange()
      if wordRange?
        @editor.setCursorBufferPosition(wordRange.start)
        @editor.getTextInBufferRange(wordRange)
      else
        ''
    )

  getPattern: (term) ->
    modifiers = if @isCaseSensitive(term) then 'g' else 'gi'
    pattern = _.escapeRegExp(term)
    if /\W/.test(term)
      new RegExp("#{pattern}\\b", modifiers)
    else
      new RegExp("\\b#{pattern}\\b", modifiers)

  getNextNonWhiteSpacePoint: (from) ->
    point = null
    scanRange = [from, [from.row, Infinity]]
    @editor.scanInBufferRange /\S/, scanRange, ({range, stop}) ->
      point = range.start
    point

  getCurrentWordBufferRange: ->
    cursor = @editor.getLastCursor()
    originalPoint = cursor.getBufferPosition()
    fromPoint = @getNextNonWhiteSpacePoint(originalPoint)
    return unless fromPoint
    cursor.setBufferPosition(fromPoint)
    options = {}
    options.includeNonWordCharacters = false if cursor.isBetweenWordAndNonWord()
    wordRange = cursor.getCurrentWordBufferRange(options)
    cursor.setBufferPosition(originalPoint)
    wordRange

class SearchCurrentWordBackwards extends SearchCurrentWord
  @extend()
  backwards: true

class RepeatSearch extends SearchBase
  @extend()

  initialize: ->
    super
    unless search = @globalState.get('currentSearch')
      @abort()
    {@input, @backwards, @getPattern, @getCaseSensitivity, @configScope, @quiet} = search

class RepeatSearchReverse extends RepeatSearch
  @extend()
  isBackwards: ->
    not @backwards

# Fold
# -------------------------
class MoveToPreviousFoldStart extends Motion
  @extend()
  @description: "Move to previous fold start"
  linewise: false
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

# -------------------------
# keymap: %
class MoveToPair extends Motion
  @extend()
  inclusive: true
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
