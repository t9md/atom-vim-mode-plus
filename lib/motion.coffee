# Refactoring status: 80%
_ = require 'underscore-plus'
{Point} = require 'atom'

globalState = require './global-state'
{
  saveEditorState, getVisibleBufferRange
  moveCursorLeft, moveCursorRight
  moveCursorUp, moveCursorDown
  moveCursorDownBuffer
  moveCursorUpBuffer
  unfoldAtCursorRow
  pointIsAtEndOfLine,
  cursorIsAtVimEndOfFile
  getFirstVisibleScreenRow, getLastVisibleScreenRow
  getVimEofBufferPosition, getVimEofScreenPosition
  getVimLastBufferRow, getVimLastScreenRow
  getValidVimScreenRow
  characterAtScreenPosition
  highlightRanges
  moveCursorToFirstCharacterAtRow
  sortRanges
  getIndentLevelForBufferRow
  getTextFromPointToEOL
  isAllWhiteSpace
  getTextAtCursor
  getEolBufferPositionForCursor
  cursorIsOnWhiteSpace
  moveCursorToNextNonWhitespace
  cursorIsAtEmptyRow
  getCodeFoldRowRanges
  isIncludeFunctionScopeForRow
  detectScopeStartPositionByScope
  getTextInScreenRange
  getBufferRows
  getFirstCharacterColumForScreenRow
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
  options: null
  operator: null

  constructor: ->
    super
    @onDidSetTarget (@operator) => @operator
    @initialize?()

  isLinewise: ->
    if @isMode('visual')
      @isMode('visual', 'linewise')
    else
      @linewise

  isInclusive: ->
    if @isMode('visual')
      @isMode('visual', ['characterwise', 'blockwise'])
    else
      @inclusive

  execute: ->
    @editor.moveCursors (cursor) =>
      @moveCursor(cursor)

  select: ->
    for selection in @editor.getSelections()
      if @isInclusive() or @isLinewise()
        @normalizeVisualModeCursorPosition(selection) if @isMode('visual')
        @selectInclusively(selection)
        if @isLinewise()
          swrap(selection).preserveCharacterwise() if @isMode('visual', 'linewise')
          swrap(selection).expandOverLine(preserveGoalColumn: true)
      else
        selection.modifySelection =>
          @moveCursor(selection.cursor)

    @editor.mergeCursors()
    @editor.mergeIntersectingSelections()

  # Modify selection inclusively
  # -------------------------
  # * Why we need to allowWrap when moveCursorLeft/Right?
  #  When 'linewise' selection, cursor is at column '0' of NEXT line, so we need to moveLeft
  #  by wrapping, to put cursor on row which actually be selected(from UX point of view).
  #  This adjustment is important so that j, k works without special care in moveCursor.
  selectInclusively: (selection) ->
    {cursor} = selection
    selection.modifySelection =>
      tailRange = swrap(selection).getTailBufferRange()
      if @isMode('visual', 'blockwise')
        originalPoint = cursor.getBufferPosition()

      @moveCursor(cursor)

      if @isMode('visual', 'blockwise')
        currentPoint = cursor.getBufferPosition()
        if originalPoint.row isnt currentPoint.row
          column = if currentPoint.isGreaterThan(originalPoint)
            Infinity
          else
            0
          cursor.setBufferPosition([originalPoint.row, column])
      if @isMode('visual') and cursor.isAtEndOfLine()
        moveCursorLeft(cursor, {preserveGoalColumn: true})

      # When mode isnt 'visual' selection.isEmpty() at this point means no movement happened.
      if selection.isEmpty() and (not @isMode('visual'))
        return

      unless selection.isReversed()
        allowWrap = cursorIsAtEmptyRow(cursor)
        moveCursorRight(cursor, {allowWrap, preserveGoalColumn: true})
      # Merge tailRange(= under cursor range where you start selection) into selection
      newRange = selection.getBufferRange().union(tailRange)
      selection.setBufferRange(newRange, {autoscroll: false, preserveFolds: true})

  # Normalize visual-mode cursor position
  # The purpose for this is @moveCursor works consistently in both normal and visual mode.
  normalizeVisualModeCursorPosition: (selection) ->
    if @isMode('visual', 'linewise')
      swrap(selection).restoreCharacterwise(preserveGoalColumn: true)

    # We selectRight()ed in visual-mode, so reset this effect here.
    # For selection.isEmpty() guard, selection possibily become in case selection is
    # cleared without calling vimState.modeManager.activate().
    # e.g. BlockwiseDeleteToLastCharacterOfLine
    unless selection.isReversed() or selection.isEmpty()
      selection.modifySelection ->
        moveCursorLeft(selection.cursor, {allowWrap: true, preserveGoalColumn: true})

# Used as operator's target in visual-mode.
class CurrentSelection extends Motion
  @extend(false)
  selectionExtent: null

  execute: ->
    throw new Error("#{@constructor.name} should not be executed")

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
      unfoldAtCursorRow(cursor)
      allowWrap = @canWrapToNextLine(cursor)
      moveCursorRight(cursor)
      if cursor.isAtEndOfLine() and allowWrap and not cursorIsAtVimEndOfFile(cursor)
        moveCursorRight(cursor, {allowWrap})

class MoveUp extends Motion
  @extend()
  linewise: true
  amount: -1

  move: (cursor) ->
    moveCursorUp(cursor)

  moveCursor: (cursor) ->
    isBufferRowWise = @editor.isSoftWrapped() and @isMode('visual', 'linewise')
    vimLastBufferRow = null
    @countTimes =>
      if isBufferRowWise
        vimLastBufferRow ?= getVimLastBufferRow(@editor)
        row = cursor.getBufferRow() + @amount
        if row <= vimLastBufferRow
          column = cursor.goalColumn or cursor.getBufferColumn()
          cursor.setBufferPosition([row, column])
          cursor.goalColumn = column
      else
        @move(cursor)

class MoveDown extends MoveUp
  @extend()
  linewise: true
  amount: +1

  move: (cursor) ->
    moveCursorDown(cursor)

# -------------------------
class MoveUpToNonBlank extends Motion
  @extend()
  linewise: true
  direction: 'up'

  moveCursor: (cursor) ->
    column = cursor.getScreenColumn()
    @countTimes =>
      newRow = _.detect @getScanRows(cursor), (row) =>
        @isMovablePoint(new Point(row, column))
      if newRow?
        cursor.setScreenPosition([newRow, column])

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
  direction: 'down'

# Move down/up to Edge
# -------------------------
class MoveUpToEdge extends MoveUpToNonBlank
  @extend()
  direction: 'up'
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
  direction: 'down'

# -------------------------
class MoveToPreviousWord extends Motion
  @extend()
  wordRegex: null

  moveCursor: (cursor) ->
    @countTimes =>
      point = cursor.getBeginningOfCurrentWordBufferPosition({@wordRegex})
      cursor.setBufferPosition(point)

class MoveToPreviousWholeWord extends MoveToPreviousWord
  @extend()
  wordRegex: /^\s*$|\S+/

class MoveToNextWord extends Motion
  @extend()
  wordRegex: null

  getPoint: (cursor) ->
    point = cursor.getBeginningOfNextWordBufferPosition({@wordRegex})
    cursorPoint = cursor.getBufferPosition()
    if point.isEqual(cursorPoint) or (point.row > getVimLastBufferRow(@editor))
      point = cursor.getEndOfCurrentWordBufferPosition({@wordRegex})
    point

  # [FIXME] This is workaround for Atom's Cursor::isInsideWord() return `true`
  # when text from cursor to EOL is all white space
  textToEndOfLineIsAllWhiteSpace: (cursor) ->
    textToEOL = getTextFromPointToEOL(@editor, cursor.getBufferPosition())
    isAllWhiteSpace(textToEOL)

  moveCursor: (cursor) ->
    return if cursorIsAtVimEndOfFile(cursor)
    lastCount = @getCount()
    wasOnWhiteSpace = cursorIsOnWhiteSpace(cursor)

    @countTimes (num) =>
      isLastCount = (num is lastCount)
      bufferRow = cursor.getBufferRow()
      if cursorIsAtEmptyRow(cursor) and @isAsOperatorTarget()
        cursor.moveDown()
      else
        if @textToEndOfLineIsAllWhiteSpace(cursor) and not cursorIsAtVimEndOfFile(cursor)
          cursor.moveDown()
          cursor.moveToBeginningOfLine()
          cursor.skipLeadingWhitespace()
        else
          point = if @operator?.directInstanceof('Change') and (not wasOnWhiteSpace) and isLastCount
            cursor.getEndOfCurrentWordBufferPosition({@wordRegex})
          else
            @getPoint(cursor)
          cursor.setBufferPosition(point)

        if @isAsOperatorTarget() and isLastCount and (cursor.getBufferRow() > bufferRow)
          cursor.setBufferPosition([bufferRow, Infinity])

class MoveToNextWholeWord extends MoveToNextWord
  @extend()
  wordRegex: /^\s*$|\S+/

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

class MoveToEndOfWholeWord extends MoveToEndOfWord
  @extend()
  wordRegex: /\S+/

class MoveToNextParagraph extends Motion
  @extend()
  direction: 'next'

  getPoint: (cursor) ->
    inSection = not @editor.isBufferRowBlank(cursor.getBufferRow())
    startRow = cursor.getBufferRow()
    rows = getBufferRows(@editor, {startRow, @direction, includeStartRow: false})
    for row in rows
      if @editor.isBufferRowBlank(row)
        return [row, 0] if inSection
      else
        inSection = true

    switch @direction
      when 'previous' then [0, 0]
      when 'next' then getVimEofBufferPosition(@editor)

  moveCursor: (cursor) ->
    @countTimes =>
      cursor.setBufferPosition @getPoint(cursor)

class MoveToPreviousParagraph extends MoveToNextParagraph
  @extend()
  direction: 'previous'
  moveCursor: (cursor) ->
    @countTimes =>
      cursor.setBufferPosition @getPoint(cursor)

class MoveToBeginningOfLine extends Motion
  @extend()
  defaultCount: null

  moveCursor: (cursor) ->
    cursor.moveToBeginningOfLine()

class MoveToLastCharacterOfLine extends Motion
  @extend()

  moveCursor: (cursor) ->
    @countTimes ->
      cursor.moveToEndOfLine()
      cursor.goalColumn = Infinity

class MoveToLastNonblankCharacterOfLineAndDown extends Motion
  @extend()
  inclusive: true

  # moves cursor to the last non-whitespace character on the line
  # similar to skipLeadingWhitespace() in atom's cursor.coffee
  skipTrailingWhitespace: (cursor) ->
    position = cursor.getBufferPosition()
    scanRange = cursor.getCurrentLineBufferRange()
    startOfTrailingWhitespace = [scanRange.end.row, scanRange.end.column - 1]
    @editor.scanInBufferRange /[ \t]+$/, scanRange, ({range}) ->
      startOfTrailingWhitespace = range.start
      startOfTrailingWhitespace.column -= 1
    cursor.setBufferPosition(startOfTrailingWhitespace)

  getCount: -> super - 1

  moveCursor: (cursor) ->
    @countTimes =>
      if cursor.getBufferRow() isnt getVimLastBufferRow(@editor)
        cursor.moveDown()
    @skipTrailingWhitespace(cursor)

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

  moveCursor: (cursor) ->
    newRow = cursor.getBufferRow() + @getCount()
    cursor.setBufferPosition [newRow, 0]

  getCount: -> super - 1

class MoveToRelativeLineWithMinimum extends MoveToRelativeLine
  @extend(false)
  min: 0
  getCount: ->
    count = super
    Math.max(@min, count)

# Position cursor without scrolling., H, M, L
# -------------------------
# keymap: H
class MoveToTopOfScreen extends Motion
  @extend()
  linewise: true
  scrolloff: 2
  defaultCount: 0

  moveCursor: (cursor) ->
    cursor.setScreenPosition([@getRow(), 0])
    cursor.moveToFirstCharacterOfLine()

  getRow: ->
    row = getFirstVisibleScreenRow(@editor)
    offset = if row is 0 then 0 else @scrolloff
    row + Math.max(@getCount(), offset)

  getCount: -> super - 1

# keymap: L
class MoveToBottomOfScreen extends MoveToTopOfScreen
  @extend()
  getRow: ->
    row = getLastVisibleScreenRow(@editor)
    offset = if row is getVimLastBufferRow(@editor) then 0 else @scrolloff
    row - Math.max(@getCount(), offset)

# keymap: M
class MoveToMiddleOfScreen extends MoveToTopOfScreen
  @extend()
  getRow: ->
    row = getFirstVisibleScreenRow(@editor)
    offset = Math.floor(@editor.getRowsPerPage() / 2) - 1
    row + Math.max(offset, 0)

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
    @editorElement.setScrollTop @newScrollTop

  select: ->
    super()
    @scroll()

  execute: ->
    super()
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

    offset   = if @isBackwards() then @offset else -@offset
    unOffset = -offset * @isRepeated()
    if @isBackwards()
      scanRange = [start, cursorPoint.translate([0, unOffset])]
      method    = 'backwardsScanInBufferRange'
    else
      scanRange = [cursorPoint.translate([0, 1 + unOffset]), end]
      method    = 'scanInBufferRange'

    points   = []
    @editor[method] ///#{_.escapeRegExp(@input)}///g, scanRange, ({range}) ->
      points.push range.start
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
  hover: icon: ':find:',  emoji: ':mag:'

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
    markPosition = @vimState.mark.get(@input)

    if @input is '`' # double '`' pressed
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
  escapeRegExp: false

  initialize: ->
    unless @instanceof('RepeatSearch')
      globalState.currentSearch = this

  isCaseSensitive: (term) ->
    switch @getCaseSensitivity()
      when 'smartcase' then term.search('[A-Z]') isnt -1
      when 'insensitive' then false
      when 'sensitive' then true

  isBackwards: ->
    @backwards

  getInput: ->
    @input

  # Not sure if I should support count but keep this for compatibility to official vim-mode.
  getCount: ->
    count = super
    if @isBackwards() then -count else count - 1

  flash: (range, {timeout}) ->
    highlightRanges @editor, range,
      class: 'vim-mode-plus-flash'
      timeout: timeout

  finish: ->
    @matches?.destroy()
    @matches = null

  moveCursor: (cursor) ->
    @matches ?= new MatchList(@vimState, @scan(cursor), @getCount())
    if @matches.isEmpty()
      unless @input is ''
        if settings.get('flashScreenOnSearchHasNoMatch')
          @flash getVisibleBufferRange(@editor), timeout: 100 # screen beep.
        atom.beep()
    else
      current = @matches.get()
      if @isComplete()
        @visit(current, cursor)
      else
        @visit(current, null)

    if @isComplete()
      if input = @getInput()
        @vimState.searchHistory.save(input)
        globalState.highlightSearchPattern = @getPattern(input)
        @vimState.main.emitDidSetHighlightSearchPattern()
      @finish()

  # If cursor is passed, it move actual move, otherwise
  # just visit matched point with decorate other matching.
  visit: (match, cursor=null) ->
    match.visit()
    if cursor
      match.flash() unless @isIncrementalSearch()
      timeout = settings.get('showHoverSearchCounterDuration')
      @matches.showHover({timeout})
      cursor.setBufferPosition(match.getStartPoint())
    else
      @matches.show()
      @matches.showHover(timeout: null)
      match.flash()

  isIncrementalSearch: ->
    settings.get('incrementalSearch') and @instanceof('Search')

  scan: (cursor) ->
    ranges = []

    # FIXME: ORDER MATTER
    # In SearchCurrentWord, @getInput move cursor, which is necessary movement.
    # So we need to call @getInput() BEFORE setting fromPoint
    input = @getInput()
    return ranges if input is ''

    fromPoint = if @isMode('visual', 'linewise') and @isIncrementalSearch()
      swrap(cursor.selection).getCharacterwiseHeadPosition()
    else
      cursor.getBufferPosition()

    @editor.scan @getPattern(input), ({range}) ->
      ranges.push range

    [pre, post] = _.partition ranges, ({start}) =>
      if @isBackwards()
        start.isLessThan(fromPoint)
      else
        start.isLessThanOrEqual(fromPoint)

    post.concat(pre)

  getPattern: (term) ->
    modifiers = if @isCaseSensitive(term) then 'g' else 'gi'

    # FIXME this prevent search \\c itself.
    # DONT thinklessly mimic pure Vim. Instead, provide ignorecase button and shortcut.
    if term.indexOf('\\c') >= 0
      term = term.replace('\\c', '')
      modifiers += 'i' unless 'i' in modifiers

    if @escapeRegExp
      new RegExp(_.escapeRegExp(term), modifiers)
    else
      try
        new RegExp(term, modifiers)
      catch
        new RegExp(_.escapeRegExp(term), modifiers)

  # NOTE: trim first space if it is.
  # experimental if search word start with ' ' we switch escape mode.
  updateEscapeRegExpOption: (input) ->
    if @escapeRegExp = /^ /.test(input)
      input = input.replace(/^ /, '')
    @updateUI {@escapeRegExp}
    input

  updateUI: (options) ->
    @vimState.searchInput.updateOptionSettings(options)

class Search extends SearchBase
  @extend()
  requireInput: true
  confirmed: false

  initialize: ->
    super
    if settings.get('incrementalSearch')
      @restoreEditorState = saveEditorState(@editor)
      @subscribeScrollChange()
      @onDidCommandSearch @onCommand

    @onDidConfirmSearch @onConfirm
    @onDidCancelSearch @onCancel
    @onDidChangeSearch @onChange
    @vimState.searchInput.focus({@backwards})

  isComplete: ->
    return false unless @confirmed
    super

  getCaseSensitivity: ->
    if settings.get('useSmartcaseForSearch')
      'smartcase'
    else if settings.get('ignoreCaseForSearch')
      'insensitive'
    else
      'sensitive'

  subscribeScrollChange: ->
    @subscribe @editorElement.onDidChangeScrollTop =>
      @matches?.show()
    @subscribe @editorElement.onDidChangeScrollLeft =>
      @matches?.show()

  isRepeatLastSearch: (input) ->
    input in ['', (if @isBackwards() then '?' else '/')]

  finish: ->
    if @isIncrementalSearch() and settings.get('showHoverSearchCounter')
      @vimState.hoverSearchCounter.reset()
    super

  onConfirm: (@input) => # fat-arrow
    @confirmed = true
    if @isRepeatLastSearch(@input)
      unless @input = @vimState.searchHistory.get('prev')
        atom.beep()
    @processOperation()
    @finish()

  onCancel: => # fat-arrow
    unless @isMode('visual') or @isMode('insert')
      @vimState.activate('reset')
    @restoreEditorState?()
    @vimState.reset()
    @finish()

  onChange: (@input) => # fat-arrow
    @input = @updateEscapeRegExpOption(@input)
    return unless @isIncrementalSearch()
    @matches?.destroy()
    if settings.get('showHoverSearchCounter')
      @vimState.hoverSearchCounter.reset()
    @matches = null
    unless @input is ''
      @moveCursor(cursor) for cursor in @editor.getCursors()

  onCommand: (command) => # fat-arrow
    [action, args...] = command.split('-')
    return unless @input
    return if @matches.isEmpty()
    switch action
      when 'visit'
        @visit @matches.get(args...)
      when 'scroll'
        # arg is 'next' or 'prev'
        @matches.scroll(args[0])
        @visit @matches.get()

class SearchBackwards extends Search
  @extend()
  backwards: true

class SearchCurrentWord extends SearchBase
  @extend()

  getInput: ->
    @input ?= (
      # [FIXME] @getCurrentWord() have side effect(moving cursor), so don't call twice.
      @getCurrentWord(new RegExp(settings.get('iskeyword') ? IsKeywordDefault))
    )

  getCaseSensitivity: ->
    if settings.get('useSmartcaseForSearchCurrentWord')
      'smartcase'
    else if settings.get('ignoreCaseForSearchCurrentWord')
      'insensitive'
    else
      'sensitive'

  getPattern: (term) ->
    modifiers = if @isCaseSensitive(term) then 'g' else 'gi'
    pattern = _.escapeRegExp(term)
    pattern = if /\W/.test(term) then "#{pattern}\\b" else "\\b#{pattern}\\b"
    new RegExp(pattern, modifiers)

  # FIXME: Should not move cursor.
  getCurrentWord: (wordRegex) ->
    cursor = @editor.getLastCursor()
    rowStart = cursor.getBufferRow()
    range = cursor.getCurrentWordBufferRange({wordRegex})
    if range.end.isEqual(cursor.getBufferPosition())
      point = cursor.getBeginningOfNextWordBufferPosition({wordRegex})
      if point.row is rowStart
        cursor.setBufferPosition(point)
        range = cursor.getCurrentWordBufferRange({wordRegex})

    if range.isEmpty()
      ''
    else
      cursor.setBufferPosition(range.start)
      @editor.getTextInBufferRange(range)

class SearchCurrentWordBackwards extends SearchCurrentWord
  @extend()
  backwards: true

class RepeatSearch extends SearchBase
  @extend()

  initialize: ->
    unless search = globalState.currentSearch
      @abort()
    {@input, @backwards, @getPattern, @getCaseSensitivity} = search

class RepeatSearchReverse extends RepeatSearch
  @extend()
  isBackwards: ->
    not @backwards

# Fold
# -------------------------
class MoveToPreviousFoldStart extends Motion
  @extend()
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
  direction: 'next'

class MoveToPreviousFoldStartWithSameIndent extends MoveToPreviousFoldStart
  @extend()
  detectRow: (cursor) ->
    baseIndentLevel = getIndentLevelForBufferRow(@editor, cursor.getBufferRow())
    for row in @getScanRows(cursor)
      if getIndentLevelForBufferRow(@editor, row) is baseIndentLevel
        return row
    null

class MoveToNextFoldStartWithSameIndent extends MoveToPreviousFoldStartWithSameIndent
  @extend()
  direction: 'next'

class MoveToPreviousFoldEnd extends MoveToPreviousFoldStart
  @extend()
  which: 'end'

class MoveToNextFoldEnd extends MoveToPreviousFoldEnd
  @extend()
  direction: 'next'

# -------------------------
class MoveToPreviousFunction extends MoveToPreviousFoldStart
  @extend()
  direction: 'prev'
  detectRow: (cursor) ->
    _.detect @getScanRows(cursor), (row) =>
      isIncludeFunctionScopeForRow(@editor, row)

class MoveToNextFunction extends MoveToPreviousFunction
  @extend()
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
      if point = detectScopeStartPositionByScope(@editor, from, @direction, @scope)
        cursor.setBufferPosition(point)

class MoveToPreviousString extends MoveToPositionByScope
  @extend()
  direction: 'backward'
  scope: 'string.begin'

class MoveToNextString extends MoveToPreviousString
  @extend()
  direction: 'forward'

class MoveToPreviousNumber extends MoveToPositionByScope
  @extend()
  direction: 'backward'
  scope: 'constant.numeric'

class MoveToNextNumber extends MoveToPreviousNumber
  @extend()
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
