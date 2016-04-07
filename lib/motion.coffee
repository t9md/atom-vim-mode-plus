_ = require 'underscore-plus'
{Point} = require 'atom'

globalState = require './global-state'
{
  saveEditorState, getVisibleBufferRange
  moveCursorLeft, moveCursorRight
  moveCursorUp, moveCursorDown
  moveCursorDownBuffer
  moveCursorUpBuffer
  cursorIsAtVimEndOfFile
  getFirstVisibleScreenRow, getLastVisibleScreenRow
  getVimEofBufferPosition
  getVimLastBufferRow, getVimLastScreenRow
  getValidVimScreenRow, getValidVimBufferRow
  characterAtScreenPosition
  highlightRanges
  moveCursorToFirstCharacterAtRow
  sortRanges
  getIndentLevelForBufferRow
  cursorIsOnWhiteSpace
  moveCursorToNextNonWhitespace
  cursorIsAtEmptyRow
  getCodeFoldRowRanges
  isIncludeFunctionScopeForRow
  detectScopeStartPositionForScope
  getTextInScreenRange
  getBufferRows
} = require './utils'

swrap = require './selection-wrapper'
{MatchList} = require './match'
settings = require './settings'
Base = require './base'

IsKeywordDefault = "[@a-zA-Z0-9_\-]+"

class Motion extends Base
  @extend(false)
  inclusive: false
  linewise: false

  constructor: ->
    super
    @initialize?()

  isLinewise: ->
    if @isMode('visual')
      @isMode('visual', 'linewise')
    else
      @linewise

  isBlockwise: ->
    @isMode('visual', 'blockwise')

  isInclusive: ->
    if @isMode('visual')
      @isMode('visual', ['characterwise', 'blockwise'])
    else
      @inclusive

  execute: ->
    @editor.moveCursors (cursor) =>
      @moveCursor(cursor)

  select: ->
    @vimState.modeManager.normalizeSelections() if @isMode('visual')

    for selection in @editor.getSelections()
      if @isInclusive() or @isLinewise()
        @selectInclusively(selection)
      else
        selection.modifySelection =>
          @moveCursor(selection.cursor)

    @editor.mergeCursors()
    @editor.mergeIntersectingSelections()

    # Update characterwise properties on each movement.
    @updateSelectionProperties() if @isMode('visual')

    switch
      when @isLinewise() then @vimState.selectLinewise()
      when @isBlockwise() then @vimState.selectBlockwise()

  # Modify selection inclusively
  # -------------------------
  # * Why we need to allowWrap when moveCursorLeft/Right?
  #  When 'linewise' selection, cursor is at column '0' of NEXT line, so we need to moveLeft
  #  by wrapping, to put cursor on row which actually be selected(from UX point of view).
  #  This adjustment is important so that j, k works without special care in moveCursor.
  selectInclusively: (selection) ->
    {cursor} = selection
    originalPoint = cursor.getBufferPosition()
    # save tailRange(range under cursor) before we start to modify selection
    tailRange = swrap(selection).getTailBufferRange()
    selection.modifySelection =>
      @moveCursor(cursor)

      if @isMode('visual')
        if cursor.isAtEndOfLine()
          # [FIXME] SCATTERED_CURSOR_ADJUSTMENT
          moveCursorLeft(cursor, {preserveGoalColumn: true})
      else
        # Return since not movement was happend, nothing to do left.
        return if cursor.getBufferPosition().isEqual(originalPoint)

      unless selection.isReversed()
        # When cursor is at empty row, we allow to wrap to next line
        # since when we `v`, w have to select line.
        allowWrap = cursorIsAtEmptyRow(cursor)
        # [FIXME] SCATTERED_CURSOR_ADJUSTMENT: -> NECESSARY
        moveCursorRight(cursor, {allowWrap, preserveGoalColumn: true})

      swrap(selection).mergeBufferRange(tailRange, {preserveFolds: true})

# Used as operator's target in visual-mode.
class CurrentSelection extends Motion
  @extend(false)
  selectionExtent: null

  execute: ->
    throw new Error("#{@getName()} should not be executed")

  select: ->
    if @isMode('visual')
      # Preserve extent to be able to replay when repeated.
      @selectionExtent = @editor.getSelectedBufferRange().getExtent()
      @wasLinewise = @isLinewise() # Cache it in case repeated.
    else
      # If we're not in visual mode, it means we are repeated last operation.
      # In this case we re-do the selection.
      @replaySelection()

  # FIXME: This function is not necessary if selectInclusively() is consistent.
  # After refactoring of selectInclusively(), this function will be deleted.
  replaySelection: ->
    for selection in @editor.getSelections()
      {start} = selection.getBufferRange()
      end = start.traverse(@selectionExtent)
      selection.setBufferRange([start, end])
    swrap.expandOverLine(@editor) if @wasLinewise

class MoveLeft extends Motion
  @extend()
  moveCursor: (cursor) ->
    allowWrap = settings.get('wrapLeftRightMotion')
    @countTimes ->
      moveCursorLeft(cursor, {allowWrap})

class MoveRight extends Motion
  @extend()
  canWrapToNextLine: (cursor) ->
    if not @isMode('visual') and @isAsOperatorTarget() and not cursor.isAtEndOfLine()
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
  direction: 'up'

  move: (cursor) ->
    moveCursorUp(cursor)

  moveCursor: (cursor) ->
    isBufferRowWise = @editor.isSoftWrapped() and @isMode('visual', 'linewise')
    vimLastBufferRow = null
    @countTimes =>
      if isBufferRowWise
        vimLastBufferRow ?= getVimLastBufferRow(@editor)
        amount = if @direction is 'up' then -1 else + 1
        row = cursor.getBufferRow() + amount
        if row <= vimLastBufferRow
          column = cursor.goalColumn or cursor.getBufferColumn()
          cursor.setBufferPosition([row, column])
          cursor.goalColumn = column
      else
        @move(cursor)

class MoveDown extends MoveUp
  @extend()
  linewise: true
  direction: 'down'

  move: (cursor) ->
    moveCursorDown(cursor)

# -------------------------
class MoveUpToNonBlank extends Motion
  @extend()
  @description: "Move cursor up to non-blank char at same-column"
  linewise: true
  direction: 'up'

  moveCursor: (cursor) ->
    column = cursor.getScreenColumn()
    @countTimes =>
      for row in @getScanRows(cursor) when @isMovablePoint(new Point(row, column))
        cursor.setScreenPosition([row, column])
        break

  getScanRows: (cursor) ->
    cursorRow = cursor.getScreenRow()
    validRow = getValidVimScreenRow.bind(null, @editor)
    switch @direction
      when 'up' then [validRow(cursorRow - 1)..0]
      when 'down' then [validRow(cursorRow + 1)..getVimLastScreenRow(@editor)]

  isMovablePoint: (point) ->
    @isNonBlankPoint(point)

  isBlankPoint: (point) ->
    char = characterAtScreenPosition(@editor, point)
    if (char.length > 0)
      /\s/.test(char)
    else
      true

  isNonBlankPoint: (point) ->
    not @isBlankPoint(point)

class MoveDownToNonBlank extends MoveUpToNonBlank
  @extend()
  @description: "Move cursor down to non-blank char at same-column"
  direction: 'down'

# Move down/up to Edge
# -------------------------
class MoveUpToEdge extends MoveUpToNonBlank
  @extend()
  direction: 'up'
  @description: "Move cursor up to **edge** char at same-column"
  isMovablePoint: (point) ->
    if @isStoppablePoint(point)
      # first and last row is always edge.
      if point.row in [0, getVimLastScreenRow(@editor)]
        true
      else
        # If one of above/below row is not stoppable, it's Edge!
        above = point.translate([-1, 0])
        below = point.translate([+1, 0])
        (not @isStoppablePoint(above)) or (not @isStoppablePoint(below))
    else
      false

  # To avoid stopping on indentation or trailing whitespace,
  # we exclude leading and trailing whitespace from stoppable column.
  isValidStoppablePoint: (point) ->
    {row, column} = point
    text = getTextInScreenRange(@editor, [[row, 0], [row, Infinity]])
    softTabText = _.multiplyString(' ', @editor.getTabLength())
    text = text.replace(/\t/g, softTabText)
    if (match = text.match(/\S/g))?
      [firstChar, ..., lastChar] = match
      text.indexOf(firstChar) <= column <= text.lastIndexOf(lastChar)
    else
      false

  isStoppablePoint: (point) ->
    if @isNonBlankPoint(point)
      true
    else if @isValidStoppablePoint(point)
      left = point.translate([0, -1])
      right = point.translate([0, +1])
      @isNonBlankPoint(left) and @isNonBlankPoint(right)
    else
      false

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
    scanRange = [[cursorPoint.row, 0], @vimEof]
    point = null
    @editor.scanInBufferRange pattern, scanRange, ({stop, range}) ->
      if range.end.isGreaterThan(cursorPoint)
        point = range.end
      if range.start.isGreaterThan(cursorPoint)
        point = range.start
        stop()
    point ? cursorPoint

  moveCursor: (cursor) ->
    return if cursorIsAtVimEndOfFile(cursor)
    @vimEof = getVimEofBufferPosition(@editor) # cache
    lastCount = @getCount()
    wasOnWhiteSpace = cursorIsOnWhiteSpace(cursor)
    @countTimes (num, isFinal) =>
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
    point = Point.min(point, getVimEofBufferPosition(@editor))
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

  getPoint: (cursor) ->
    cursorRow = cursor.getBufferRow()
    wasAtNonBlankRow = not @editor.isBufferRowBlank(cursorRow)
    options = {startRow: cursorRow, @direction, includeStartRow: false}
    for row in getBufferRows(@editor, options)
      if @editor.isBufferRowBlank(row)
        return [row, 0] if wasAtNonBlankRow
      else
        wasAtNonBlankRow = true

    switch @direction
      when 'previous' then [0, 0]
      when 'next' then getVimEofBufferPosition(@editor)

  moveCursor: (cursor) ->
    @countTimes =>
      cursor.setBufferPosition(@getPoint(cursor))

class MoveToPreviousParagraph extends MoveToNextParagraph
  @extend()
  direction: 'previous'

# -------------------------
class MoveToBeginningOfLine extends Motion
  @extend()
  defaultCount: null

  moveCursor: (cursor) ->
    cursor.moveToBeginningOfLine()

class MoveToLastCharacterOfLine extends Motion
  @extend()

  getCount: ->
    super - 1

  getPoint: (cursor) ->
    row = getValidVimBufferRow(@editor, cursor.getBufferRow() + @getCount())
    [row, Infinity]

  moveCursor: (cursor) ->
    cursor.setBufferPosition(@getPoint(cursor))
    cursor.goalColumn = Infinity

class MoveToLastNonblankCharacterOfLineAndDown extends Motion
  @extend()
  inclusive: true

  getCount: ->
    super - 1

  getPoint: (cursor) ->
    row = cursor.getBufferRow() + @getCount()
    row = Math.min(row, getVimLastBufferRow(@editor))
    scanRange = @editor.bufferRangeForBufferRow(row, includeNewline: true)
    point = null
    # [NOTE] this scan would never be fail, so valid point is always returend.
    @editor.scanInBufferRange /\s*$/, scanRange, ({range, matchText}) ->
      point = range.start
    point.translate([0, -1])

  moveCursor: (cursor) ->
    cursor.setBufferPosition(@getPoint(cursor))

# MoveToFirstCharacterOfLine faimily
# ------------------------------------
class MoveToFirstCharacterOfLine extends Motion
  @extend()
  moveCursor: (cursor) ->
    cursor.moveToBeginningOfLine()
    cursor.moveToFirstCharacterOfLine()

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

# keymap: gg
class MoveToFirstLine extends Motion
  @extend()
  linewise: true
  defaultCount: null

  getRow: ->
    if (count = @getCount()) then count - 1 else @getDefaultRow()

  getDefaultRow: ->
    0

  moveCursor: (cursor) ->
    cursor.setBufferPosition [@getRow(), 0]
    cursor.moveToFirstCharacterOfLine()
    cursor.autoscroll({center: true})

# keymap: G
class MoveToLastLine extends MoveToFirstLine
  @extend()
  getDefaultRow: ->
    getVimLastBufferRow(@editor)

# keymap: N% e.g. 10%
class MoveToLineByPercent extends MoveToFirstLine
  @extend()
  getRow: ->
    percent = Math.min(100, @getCount())
    Math.floor(getVimLastScreenRow(@editor) * (percent / 100))

class MoveToRelativeLine extends Motion
  @extend(false)
  linewise: true

  getCount: ->
    super - 1

  getPoint: (cursor) ->
    row = cursor.getBufferRow() + @getCount()
    [row, 0]

  moveCursor: (cursor) ->
    cursor.setBufferPosition(@getPoint(cursor))

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
    cursor.setScreenPosition([@getRow(), 0])
    cursor.moveToFirstCharacterOfLine()

  getRow: ->
    row = getFirstVisibleScreenRow(@editor)
    offset = @scrolloff
    offset = 0 if (row is 0)
    row + Math.max(@getCount(), offset)

# keymap: M
class MoveToMiddleOfScreen extends MoveToTopOfScreen
  @extend()
  getRow: ->
    startRow = getFirstVisibleScreenRow(@editor)
    vimLastScreenRow = getVimLastScreenRow(@editor)
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
    vimLastScreenRow = getVimLastScreenRow(@editor)
    row = Math.min(@editor.getLastVisibleScreenRow(), vimLastScreenRow)
    offset = @scrolloff + 1
    offset = 0 if (row is vimLastScreenRow)
    row - Math.max(@getCount(), offset)

# Scrolling
# Half: ctrl-d, ctrl-u
# Full: ctrl-f, ctrl-b
# -------------------------
# [FIXME] count behave differently from original Vim.
# [BUG] continous execution make cursor out of screen
# This is maybe becauseof getRowsPerPage calculation is not accurate
# Need to change approach to keep ratio of cursor row against scroll top.
class ScrollFullScreenDown extends Motion
  @extend()
  coefficient: +1

  initialize: ->
    @rowsToScroll = @editor.getRowsPerPage() * @coefficient
    amountInPixel = @rowsToScroll * @editor.getLineHeightInPixels()
    @newScrollTop = @editorElement.getScrollTop() + amountInPixel

  scroll: ->
    @editorElement.setScrollTop(@newScrollTop)

  select: ->
    super
    @scroll()

  execute: ->
    super
    @scroll()

  moveCursor: (cursor) ->
    row = Math.floor(@editor.getCursorScreenPosition().row + @rowsToScroll)
    row = Math.min(getVimLastScreenRow(@editor), row)
    cursor.setScreenPosition([row, 0] , autoscroll: false)

# keymap: ctrl-b
class ScrollFullScreenUp extends ScrollFullScreenDown
  @extend()
  coefficient: -1

# keymap: ctrl-d
class ScrollHalfScreenDown extends ScrollFullScreenDown
  @extend()
  coefficient: +1 / 2

# keymap: ctrl-u
class ScrollHalfScreenUp extends ScrollHalfScreenDown
  @extend()
  coefficient: -1 / 2

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
    @focusInput() unless @isRepeated()

  isBackwards: ->
    @backwards

  find: (cursor) ->
    cursorPoint = cursor.getBufferPosition()
    {start, end} = @editor.bufferRangeForBufferRow(cursorPoint.row)

    offset = if @isBackwards() then @offset else -@offset
    unOffset = -offset * @isRepeated()
    if @isBackwards()
      scanRange = [start, cursorPoint.translate([0, unOffset])]
      method = 'backwardsScanInBufferRange'
    else
      scanRange = [cursorPoint.translate([0, 1 + unOffset]), end]
      method = 'scanInBufferRange'

    points = []
    @editor[method] ///#{_.escapeRegExp(@input)}///g, scanRange, ({range}) ->
      points.push(range.start)
    points[@getCount()]?.translate([0, offset])

  getCount: ->
    super - 1

  moveCursor: (cursor) ->
    if point = @find(cursor)
      cursor.setBufferPosition(point)
    unless @isRepeated()
      globalState.currentFind = this

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

  find: ->
    @point = super

  selectInclusively: (selection) ->
    super
    if selection.isEmpty() and (@point? and not @backwards)
      selection.modifySelection ->
        selection.cursor.moveRight()

# keymap: T
class TillBackwards extends Till
  @extend()
  inclusive: false
  backwards: true

class RepeatFind extends Find
  @extend()
  repeated: true

  initialize: ->
    unless findObj = globalState.currentFind
      @abort()
    {@offset, @backwards, @input} = findObj

class RepeatFindReverse extends RepeatFind
  @extend()
  isBackwards: ->
    not @backwards

# Mark
# -------------------------
# keymap: `
class MoveToMark extends Motion
  @extend()
  requireInput: true
  hover: icon: ":move-to-mark:`", emoji: ":round_pushpin:`"

  initialize: ->
    @focusInput()

  moveCursor: (cursor) ->
    input = @getInput()
    markPosition = @vimState.mark.get(input)

    if input is '`' # double '`' pressed
      markPosition ?= [0, 0] # if markPosition not set, go to the beginning of the file
      @vimState.mark.set('`', cursor.getBufferPosition())

    if markPosition?
      cursor.setBufferPosition(markPosition)
      cursor.moveToFirstCharacterOfLine() if @linewise

# keymap: '
class MoveToMarkLine extends MoveToMark
  @extend()
  linewise: true
  hover: icon: ":move-to-mark:'", emoji: ":round_pushpin:'"

# Search
# -------------------------
class SearchBase extends Motion
  @extend(false)
  backwards: false
  useRegexp: true
  configScope: null

  getCount: ->
    count = super - 1
    count = -count if @isBackwards()
    count

  isBackwards: ->
    @backwards

  isCaseSensitive: (term) ->
    switch @getCaseSensitivity()
      when 'smartcase' then term.search('[A-Z]') isnt -1
      when 'insensitive' then false
      when 'sensitive' then true

  getCaseSensitivity: ->
    if settings.get("useSmartcaseFor#{@configScope}")
      'smartcase'
    else if settings.get("ignoreCaseFor#{@configScope}")
      'insensitive'
    else
      'sensitive'

  finish: ->
    if @isIncrementalSearch?() and settings.get('showHoverSearchCounter')
      @vimState.hoverSearchCounter.reset()
    @matches?.destroy()
    @matches = null

  flashScreen: ->
    highlightRanges @editor, getVisibleBufferRange(@editor),
      class: 'vim-mode-plus-flash'
      timeout: 100
    atom.beep()

  moveCursor: (cursor) ->
    # console.log "moving!"
    input = @getInput()
    if input is ''
      @finish()
      return

    @matches ?= @getMatchList(cursor, input)
    if @matches.isEmpty()
      @flashScreen() if settings.get('flashScreenOnSearchHasNoMatch')
    else
      @visitMatch "current",
        timeout: settings.get('showHoverSearchCounterDuration')
        landing: true

      point = @matches.getCurrentStartPosition()
      cursor.setBufferPosition(point, {autoscroll: false})

    globalState.currentSearch = this
    @vimState.searchHistory.save(input)
    globalState.highlightSearchPattern = @getPattern(input)
    @vimState.main.emitDidSetHighlightSearchPattern()
    @finish()

  getFromPoint: (cursor) ->
    if @isMode('visual', 'linewise') and @isIncrementalSearch?()
      swrap(cursor.selection).getCharacterwiseHeadPosition()
    else
      cursor.getBufferPosition()

  getMatchList: (cursor, input) ->
    MatchList.fromScan @editor,
      fromPoint: @getFromPoint(cursor)
      pattern: @getPattern(input)
      direction: (if @isBackwards() then 'backward' else 'forward')
      countOffset: @getCount()

  visitMatch: (direction=null, options={}) ->
    {timeout, landing} = options
    landing ?= false
    match = @matches.get(direction)
    match.scrollToStartPoint()

    flashOptions =
      class: 'vim-mode-plus-flash'
      timeout: settings.get('flashOnSearchDuration')

    if landing
      if settings.get('flashOnSearch') and not @isIncrementalSearch?()
        match.flash(flashOptions)
    else
      @matches.refresh()
      if settings.get('flashOnSearch')
        match.flash(flashOptions)

    if settings.get('showHoverSearchCounter')
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
    @setIncrementalSearch() if @isIncrementalSearch()

    @onDidConfirmSearch (@input) =>
      unless @isIncrementalSearch()
        searchChar = if @isBackwards() then '?' else '/'
        if @input in ['', searchChar]
          @input = @vimState.searchHistory.get('prev')
          atom.beep() unless @input
      @processOperation()

    @onDidCancelSearch =>
      unless @isMode('visual') or @isMode('insert')
        @vimState.activate('reset')
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

  setIncrementalSearch: ->
    @restoreEditorState = saveEditorState(@editor)
    @subscribe @editorElement.onDidChangeScrollTop => @matches?.refresh()
    @subscribe @editorElement.onDidChangeScrollLeft => @matches?.refresh()

    @onDidCommandSearch (command) =>
      return unless @input
      return if @matches.isEmpty()
      switch command
        when 'visit-next' then @visitMatch('next')
        when 'visit-prev' then @visitMatch('prev')

  visitCursors: ->
    visitCursor = (cursor) =>
      @matches ?= @getMatchList(cursor, input)
      if @matches.isEmpty()
        @flashScreen() if settings.get('flashScreenOnSearchHasNoMatch')
      else
        @visitMatch()

    @matches?.destroy()
    @matches = null
    @vimState.hoverSearchCounter.reset() if settings.get('showHoverSearchCounter')

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

  getCurrentWordBufferRange: ->
    wordRange = null
    cursorPosition = @editor.getCursorBufferPosition()
    scanRange = @editor.bufferRangeForBufferRow(cursorPosition.row)
    pattern = new RegExp(settings.get('iskeyword') ? IsKeywordDefault, 'g')

    @editor.scanInBufferRange pattern, scanRange, ({range, stop}) ->
      if range.end.isGreaterThan(cursorPosition)
        wordRange = range
        stop()
    wordRange

class SearchCurrentWordBackwards extends SearchCurrentWord
  @extend()
  backwards: true

class RepeatSearch extends SearchBase
  @extend()

  initialize: ->
    unless search = globalState.currentSearch
      @abort()
    {@input, @backwards, @getPattern, @getCaseSensitivity, @configScope} = search

class RepeatSearchReverse extends RepeatSearch
  @extend()
  isBackwards: ->
    not @backwards

# Fold
# -------------------------
class MoveToPreviousFoldStart extends Motion
  @extend()
  @description: "Move to previous fold start"
  linewise: true
  which: 'start'
  direction: 'prev'

  initialize: ->
    @rows = @getFoldRow(@which)
    @rows.reverse() if @direction is 'prev'

  getFoldRow: (which) ->
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

  moveCursor: (cursor) ->
    @countTimes =>
      from = cursor.getBufferPosition()
      if point = detectScopeStartPositionForScope(@editor, from, @direction, @scope)
        cursor.setBufferPosition(point)

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
  member: ['Parenthesis', 'CurlyBracket', 'SquareBracket']

  getPoint: (cursor) ->
    ranges = @new("AAnyPair", {allowForwarding: true, @member}).getRanges(cursor.selection)
    cursorPosition = cursor.getBufferPosition()
    cursorRow = cursorPosition.row
    ranges = ranges.filter ({start, end}) ->
      if (cursorRow is start.row) and start.isGreaterThanOrEqual(cursorPosition)
        return true
      if (cursorRow is end.row) and end.isGreaterThanOrEqual(cursorPosition)
        return true

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

  moveCursor: (cursor) ->
    if point = @getPoint(cursor)
      cursor.setBufferPosition(point)
