# Refactoring status: 50%
{Point, Range, CompositeDisposable} = require 'atom'
{selectLines} = require './utils'
{Hover} = require './hover'
{saveEditorState} = require './utils'

_ = require 'underscore-plus'

settings = require './settings'
{Search} = require './input'
Base = require './base'

class Motion extends Base
  @extend()
  complete: true

  inclusive: false
  linewise: false
  options: null

  setOptions: (@options) ->

  isLinewise: ->
    if @vimState.isMode('visual')
      @vimState.isMode('visual', 'linewise')
    else
      @linewise

  isInclusive: ->
    if @vimState.isMode('visual')
      @vimState.isMode('visual', ['characterwise', 'blockwise'])
    else
      @inclusive

  execute: ->
    @editor.moveCursors (cursor) =>
      @moveCursor(cursor)

  select: ->
    for selection in @editor.getSelections()
      switch
        when @isInclusive(), @isLinewise()
          @selectInclusive selection
          selectLines(selection) if @isLinewise()
        else
          selection.modifySelection =>
            @moveCursor selection.cursor

    @editor.mergeCursors()
    @editor.mergeIntersectingSelections()
    @status()

  # This tail position is always selected even if selection isReversed() as a result of cursor movement.
  getTailRange: (selection) ->
    point = selection.getTailBufferPosition()
    columnDelta = if selection.isReversed() then -1 else +1
    Range.fromPointWithDelta(point, 0, columnDelta)

  withKeepingGoalColumn: (cursor, fn) ->
    {goalColumn} = cursor
    fn(cursor)
    cursor.goalColumn = goalColumn if goalColumn

  selectInclusive: (selection) ->
    {cursor} = selection

    # Selection maybe empty when Motion is used as target of Operator.
    if selection.isEmpty()
      originallyEmpty = true
      selection.selectRight()

    selection.modifySelection =>
      tailRange = @getTailRange(selection)
      unless selection.isReversed()
        @withKeepingGoalColumn cursor, (c) ->
          c.moveLeft()
      @moveCursor(cursor)

      # When motion is used as target of operator, return if motion movement not happend.
      return if (selection.isEmpty() and originallyEmpty)

      unless selection.isReversed()
        @withKeepingGoalColumn cursor, (c) ->
          c.moveRight()
      selection.setBufferRange selection.getBufferRange().union(tailRange)

  # Utils
  # -------------------------
  countTimes: (fn) ->
    _.times @getCount(), ->
      fn()

  at: (where, cursor) ->
    switch where
      when 'BOL' then cursor.isAtBeginningOfLine()
      when 'EOL' then cursor.isAtEndOfLine()
      when 'BOF' then cursor.getBufferPosition().isEqual(Point.ZERO)
      when 'EOF' then cursor.getBufferPosition().isEqual(@editor.getEofBufferPosition())
      when 'FirstScreenRow'
        cursor.getScreenRow() is 0
      when 'LastScreenRow'
        cursor.getScreenRow() is @editor.getLastScreenRow()

  moveToFirstCharacterOfLine: (cursor) ->
    cursor.moveToBeginningOfLine()
    cursor.moveToFirstCharacterOfLine()

  getLastRow: ->
    @editor.getBuffer().getLastRow()

  getFirstVisibleScreenRow: ->
    @editorElement.getFirstVisibleScreenRow()

  getLastVisibleScreenRow: ->
    @editorElement.getLastVisibleScreenRow()

  # return boolean that indicates at least one of selections is not isEmpty().
  status: ->
    @editor.getSelections().some((s) -> not s.isEmpty())

class CurrentSelection extends Motion
  @extend()
  selectedRange: null
  constructor: ->
    super
    @selectedRange = @editor.getSelectedBufferRange()
    @wasLinewise = @isLinewise()

  execute: ->
    @countTimes -> true

  select: ->
    # In visual mode, the current selections are already there.
    # If we're not in visual mode, we are repeating some operation and need to re-do the selections
    unless @vimState.isMode('visual')
      @selectCharacters()
      if @wasLinewise
        selectLines(s) for s in @editor.getSelections()
    @status()

  selectCharacters: ->
    extent = @selectedRange.getExtent()
    for selection in @editor.getSelections()
      {start} = selection.getBufferRange()
      end = start.traverse(extent)
      selection.setBufferRange([start, end])

class MoveLeft extends Motion
  @extend()
  moveCursor: (cursor) ->
    @countTimes =>
      if not @at('BOL', cursor) or settings.get('wrapLeftRightMotion')
        cursor.moveLeft()

class MoveRight extends Motion
  @extend()
  composed: false

  onDidComposeBy: (operation) ->
    # Don't save oeration to instance variable to avoid reference before I understand it correctly.
    # Also introspection need to support circular reference detection to stop infinit reflection loop.
    if operation.isOperator()
      @composed = true

  isOperatorPending: ->
    @vimState.isMode('operator-pending') or @composed

  moveCursor: (cursor) ->
    @countTimes =>
      wrapToNextLine = settings.get('wrapLeftRightMotion')

      # when the motion is combined with an operator, we will only wrap to the next line
      # if we are already at the end of the line (after the last character)
      if @isOperatorPending() and not @at('EOL', cursor)
        wrapToNextLine = false

      cursor.moveRight() unless @at('EOL', cursor)
      cursor.moveRight() if wrapToNextLine and @at('EOL', cursor)

class MoveUp extends Motion
  @extend()
  linewise: true

  moveCursor: (cursor) ->
    @countTimes =>
      cursor.moveUp() unless @at('FirstScreenRow', cursor)

class MoveDown extends Motion
  @extend()
  linewise: true

  moveCursor: (cursor) ->
    @countTimes =>
      cursor.moveDown() unless @at('LastScreenRow', cursor)

class MoveToPreviousWord extends Motion
  @extend()
  moveCursor: (cursor) ->
    @countTimes ->
      cursor.moveToBeginningOfWord()

class MoveToPreviousWholeWord extends Motion
  @extend()
  wordRegex: /^\s*$|\S+/

  moveCursor: (cursor) ->
    @countTimes =>
      point = cursor.getBeginningOfCurrentWordBufferPosition({@wordRegex})
      cursor.setBufferPosition(point)

class MoveToNextWord extends Motion
  @extend()
  wordRegex: null

  getNext: (cursor) ->
    if @options?.excludeWhitespace
      cursor.getEndOfCurrentWordBufferPosition(wordRegex: @wordRegex)
    else
      cursor.getBeginningOfNextWordBufferPosition(wordRegex: @wordRegex)

  moveCursor: (cursor) ->
    return if @at('EOF', cursor)
    @countTimes =>
      if @at('EOL', cursor)
        cursor.moveDown()
        cursor.moveToFirstCharacterOfLine()
      else
        next = @getNext(cursor)
        if next.isEqual(cursor.getBufferPosition())
          cursor.moveToEndOfWord()
        else
          cursor.setBufferPosition(next)

class MoveToNextWholeWord extends MoveToNextWord
  @extend()
  wordRegex: /^\s*$|\S+/

class MoveToEndOfWord extends Motion
  @extend()
  wordRegex: null
  inclusive: true

  getNext: (cursor) ->
    point = cursor.getEndOfCurrentWordBufferPosition(wordRegex: @wordRegex)
    if point.column > 0
      point.column--
    point

  moveCursor: (cursor) ->
    @countTimes =>
      point = @getNext(cursor)
      if point.isEqual(cursor.getBufferPosition())
        cursor.moveRight()
        if @at('EOL', cursor)
          cursor.moveDown()
          cursor.moveToBeginningOfLine()
        point = @getNext(cursor)
      cursor.setBufferPosition(point)

class MoveToEndOfWholeWord extends MoveToEndOfWord
  @extend()
  wordRegex: /\S+/

class MoveToNextParagraph extends Motion
  @extend()
  moveCursor: (cursor) ->
    @countTimes ->
      cursor.moveToBeginningOfNextParagraph()

class MoveToPreviousParagraph extends Motion
  @extend()
  moveCursor: (cursor) ->
    @countTimes ->
      cursor.moveToBeginningOfPreviousParagraph()

class MoveToBeginningOfLine extends Motion
  @extend()
  defaultCount: null

  constructor: ->
    super
    # 0 is special need to differenciate `10`, 0
    if @getCount()?
      # if true, it means preceeding number exist, so we should behave as `0`.
      @vimState.count.set(0)
      @abort()

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
    @countTimes ->
      cursor.moveDown()
    @skipTrailingWhitespace(cursor)

# MoveToFirstCharacterOfLine faimily
# ------------------------------------
class MoveToFirstCharacterOfLine extends Motion
  @extend()
  moveCursor: (cursor) ->
    @moveToFirstCharacterOfLine(cursor)

class MoveToFirstCharacterOfLineUp extends MoveToFirstCharacterOfLine
  @extend()
  linewise: true
  moveCursor: (cursor) ->
    @countTimes ->
      cursor.moveUp()
    super

class MoveToFirstCharacterOfLineDown extends MoveToFirstCharacterOfLine
  @extend()
  linewise: true
  moveCursor: (cursor) ->
    @countTimes ->
      cursor.moveDown()
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

  getDefaultRow: -> 0

  moveCursor: (cursor) ->
    cursor.setBufferPosition [@getRow(), 0]
    cursor.moveToFirstCharacterOfLine()

# keymap: G
class MoveToLastLine extends MoveToFirstLine
  @extend()
  getDefaultRow: ->
    @getLastRow()

class MoveToRelativeLine extends Motion
  @extend()
  linewise: true

  moveCursor: (cursor) ->
    newRow = cursor.getBufferRow() + @getCount()
    cursor.setBufferPosition [newRow, 0]

  getCount: -> super - 1

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
    row = @getFirstVisibleScreenRow()
    offset = if row is 0 then 0 else @scrolloff
    row + Math.max(@getCount(), offset)

  getCount: -> super - 1

# keymap: L
class MoveToBottomOfScreen extends MoveToTopOfScreen
  @extend()
  getRow: ->
    row = @getLastVisibleScreenRow()
    offset = if row is @getLastRow() then 0 else @scrolloff
    row - Math.max(@getCount(), offset)

# keymap: M
class MoveToMiddleOfScreen extends MoveToTopOfScreen
  @extend()
  getRow: ->
    row = @getFirstVisibleScreenRow()
    offset = Math.floor(@editor.getRowsPerPage() / 2) - 1
    row + Math.max(offset, 0)

# Scrolling
# -------------------------
# [FIXME] count behave differently from original Vim.
class ScrollFullScreenDown extends Motion
  @extend()
  scrolledRows: 0
  direction: +1

  withScroll: (fn) ->
    newScreenTop = @scroll()
    fn()
    @editor.setScrollTop newScreenTop

  select: ->
    @withScroll =>
      super()
    @status()

  execute: -> @withScroll => super()

  moveCursor: (cursor) ->
    row = @editor.getCursorScreenPosition().row + @scrolledRows
    cursor.setScreenPosition([row, 0])

  # just scroll, not move cursor in this function.
  scroll: ->
    firstScreenRowOrg = @getFirstVisibleScreenRow()
    px = @getCount() * @getAmountInPixel() * @direction
    @editor.setScrollTop (@editor.getScrollTop() + px)
    @scrolledRows = @getFirstVisibleScreenRow() - firstScreenRowOrg
    @editor.getScrollTop()

  getAmountInPixel: ->
    @editor.getHeight()

# keymap: ctrl-b
class ScrollFullScreenUp extends ScrollFullScreenDown
  @extend()
  direction: -1

# keymap: ctrl-d
class ScrollHalfScreenDown extends ScrollFullScreenDown
  @extend()
  getAmountInPixel: ->
    Math.floor(@editor.getRowsPerPage() / 2) * @editor.getLineHeightInPixels()

# keymap: ctrl-u
class ScrollHalfScreenUp extends ScrollHalfScreenDown
  @extend()
  direction: -1

# Find
# -------------------------
# keymap: f
class Find extends Motion
  @extend()
  backwards: false
  complete: false
  requireInput: true
  inclusive: true
  hoverText: ':mag_right:'
  hoverIcon: ':find:'
  offset: 0

  constructor: ->
    super
    @readInput() unless @isRepeatFind()

  isBackwards: ->
    @backwards

  find: (cursor) ->
    cursorPoint = cursor.getBufferPosition()
    {start, end} = @editor.bufferRangeForBufferRow(cursorPoint.row)

    offset   = if @isBackwards() then @offset else -@offset
    unOffset = -offset * @isRepeatFind()
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
    unless @isRepeatFind()
      @vimState.globalVimState.currentFind = this

# keymap: F
class FindBackwards extends Find
  @extend()
  backwards: true
  hoverText: ':mag:'
  hoverIcon: ':find:'

# keymap: t
class Till extends Find
  @extend()
  offset: 1

  find: ->
    @point = super

  selectInclusive: (selection) ->
    super
    if selection.isEmpty() and (@point? and not @backwards)
      selection.modifySelection ->
        selection.cursor.moveRight()

# keymap: T
class TillBackwards extends Till
  @extend()
  backwards: true

class RepeatFind extends Find
  @extend()
  constructor: ->
    super
    unless findObj = @vimState.globalVimState.currentFind
      @abort()
    {@offset, @backwards, @complete, @input} = findObj

class RepeatFindReverse extends RepeatFind
  @extend()
  isBackwards: ->
    not @backwards

# Mark
# -------------------------
# keymap: `
class MoveToMark extends Motion
  @extend()
  complete: false
  requireInput: true
  hoverText: ":round_pushpin:`"
  hoverIcon: ":move-to-mark:`"
  # hoverChar: '`'

  constructor: ->
    super
    @readInput()

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
  hoverText: ":round_pushpin:'"
  hoverIcon: ":move-to-mark:'"
  # hoverChar: "'"

# Search
# -------------------------
class SearchBase extends Motion
  @extend()
  saveCurrentSearch: true
  complete: false
  backwards: false

  isBackwards: ->
    @backwards

  constructor: ->
    super
    if @saveCurrentSearch
      @vimState.globalVimState.currentSearch.backwards = @backwards

  getCount: ->
    super - 1

  flash: (range, {timeout}={}) ->
    options =
      range: range
      klass: 'vim-mode-flash'
      timeout: timeout ? settings.get('flashOnSearchDurationMilliSeconds')
    @vimState.flasher.flash(options)

  moveCursor: (cursor) ->
    if @index?
      @visit(@index, cursor)
    else
      @ranges = @scan(cursor)
      if @ranges.length is 0
        @flash(@getVisibleBufferRange(), timeout: 100)
        atom.beep()
        return
      @index = @getCount() % @ranges.length
      @visit(@index, cursor)
    if @isComplete()
      @index = null

  visit: (index, cursor=null) ->
    @current = @ranges[index]
    point = @current.start
    if @isComplete() and cursor?
      cursor.setBufferPosition(point, center: true)
      @vimState.searchHistory.save(@input)
    else
      # dont do acutual move in temporal visit in inclemental search.
      @showMatched()
      @editor.scrollToBufferPosition(point, center: true)
      if @editor.isFoldedAtBufferRow(point.row)
        @editor.unfoldBufferRow point

    @flash(@current) if settings.get('flashOnSearch')
    @showHover(point, @getCounter()) if settings.get('enableHoverSearchCounter')

  showHover: (point, content) ->
    timeout = null
    if @isComplete()
      timeout = switch
        when @vimState.hoverSearchCounter.isVisibleAtPoint(point) then 0
        else settings.get('searchCounterHoverDuration')
    @vimState.hoverSearchCounter.addWithTimeout content, point, timeout

  showMatched: ->
    @destroyMarkers()
    @markers = []
    visibleRange = @getVisibleBufferRange()
    rangesToRender = (r for r in @ranges when visibleRange.containsRange(r))
    for r in rangesToRender
      klass = 'vim-mode-search-match'
      klass += ' current' if r.isEqual(@current)
      @markers.push(@decorate r, class: klass)

  getVisibleBufferRange: ->
    [startRow, endRow] = @editor.getVisibleRowRange().map (row) =>
      @editor.bufferRowForScreenRow row
    new Range([startRow, 0], [endRow, Infinity])

  destroyMarkers: ->
    m.destroy() for m in @markers ? []
    @markers = null

  decorate: (range, {class: klass}) ->
    marker = @editor.markBufferRange range,
      invalidate: 'never'
      persistent: false
    @editor.decorateMarker marker,
      type: 'highlight'
      class: klass
    marker

  getCounter: ->
    rangeSorted = @ranges.slice().sort (a, b) -> a.compare(b)
    currentIndex = rangeSorted.indexOf(@current) + 1
    "#{currentIndex}/#{@ranges.length}"

  scan: (cursor) ->
    return [] if @input is ""

    cursorPosition = cursor.getBufferPosition()
    ranges = []
    pattern = @getPattern(@input)
    @editor.scan pattern, ({range}) ->
      ranges.push range

    [rangesBefore, rangesAfter] = _.partition ranges, ({start}) =>
      if @isBackwards()
        start.isLessThan(cursorPosition)
      else
        start.isLessThanOrEqual(cursorPosition)

    ranges = rangesAfter.concat(rangesBefore)
    ranges.reverse() if @isBackwards()
    ranges

  getPattern: (term) ->
    modifiers = {'g': true}
    if not term.match('[A-Z]') and settings.get('useSmartcaseForSearch')
      modifiers['i'] = true

    if term.indexOf('\\c') >= 0
      term = term.replace('\\c', '')
      modifiers['i'] = true

    modFlags = Object.keys(modifiers).join('')

    try
      new RegExp(term, modFlags)
    catch
      new RegExp(_.escapeRegExp(term), modFlags)

class Search extends SearchBase
  @extend()
  constructor: ->
    super
    handlers = {@onConfirm, @onCancel}
    if settings.get('enableIncrementalSearch')
      @restoreEditorState = saveEditorState(@editor)
      @subscriptions = new CompositeDisposable
      @subscriptions.add @editor.onDidChangeScrollTop => @showMatched()
      @subscriptions.add @editor.onDidChangeScrollLeft => @showMatched()
      _.extend(handlers, {@onChange, @onCommand})
    @vimState.search.readInput {@backwards}, handlers

  onConfirm: (input) => # fat-arrow
    latestSeachChars = ['', (if @isBackwards() then '?' else '/')]
    if input in latestSeachChars
      input = @vimState.searchHistory.get('prev')
      atom.beep() if input is ''
    @input = input
    @complete = true
    @vimState.operationStack.process()
    @subscriptions?.dispose()
    @subscriptions = null
    @destroyMarkers()

  onCancel: => # fat-arrow
    unless @vimState.isMode('visual') or @vimState.isMode('insert')
      @vimState.activate('reset')
    @destroyMarkers()
    @vimState.hoverSearchCounter.reset()
    @vimState.reset()
    @subscriptions?.dispose()
    @subscriptions = null
    @restoreEditorState?()

  reset: ->
    @index = null
    @ranges = null
    @destroyMarkers()
    @vimState.hoverSearchCounter.reset()

  onChange: (@input) => # fat-arrow
    return unless settings.get('enableIncrementalSearch')
    @reset()
    unless @input is ''
      @moveCursor(c) for c in @editor.getCursors()

  onCommand: (command) => # fat-arrow
    return unless @ranges.length
    switch command
      when 'visit-next'
        @index = (@index + 1) % @ranges.length
      when 'visit-prev'
        @index -= 1
        @index = (@ranges.length - 1) if @index is -1
    @visit(@index)

class SearchBackwards extends Search
  @extend()
  backwards: true

class SearchCurrentWord extends SearchBase
  @extend()
  wordRegex: null
  complete: true

  constructor: ->
    super
    # FIXME: This must depend on the current language
    defaultIsKeyword = "[@a-zA-Z0-9_\-]+"
    userIsKeyword = atom.config.get('vim-mode.iskeyword')
    @wordRegex = new RegExp(userIsKeyword or defaultIsKeyword)
    unless @input = @getCurrentWord()
      @abort()

  getPattern: (text) ->
    pattern = _.escapeRegExp(text)
    pattern = if /\W/.test(text) then "#{pattern}\\b" else "\\b#{pattern}\\b"
    new RegExp(pattern, 'gi') # always case insensitive.

  # FIXME: Should not move cursor.
  getCurrentWord: ->
    cursor = @editor.getLastCursor()
    rowStart = cursor.getBufferRow()
    range = cursor.getCurrentWordBufferRange({@wordRegex})
    if range.end.isEqual(cursor.getBufferPosition())
      point = cursor.getBeginningOfNextWordBufferPosition({@wordRegex})
      if point.row is rowStart
        cursor.setBufferPosition(point)
        range = cursor.getCurrentWordBufferRange({@wordRegex})

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
  complete: true
  saveCurrentSearch: false

  constructor: ->
    super
    @input = @vimState.searchHistory.get('prev')
    @backwards = @vimState.globalVimState.currentSearch.backwards

class RepeatSearchReverse extends RepeatSearch
  @extend()
  isBackwards: ->
    not @backwards

# keymap: %
OpenBrackets = ['(', '{', '[']
CloseBrackets = [')', '}', ']']
AnyBracket = new RegExp(OpenBrackets.concat(CloseBrackets).map(_.escapeRegExp).join("|"))

class BracketMatchingMotion extends SearchBase
  @extend()
  inclusive: true
  complete: true

  searchForMatch: (startPosition, reverse, inCharacter, outCharacter) ->
    depth = 0
    point = startPosition.copy()
    lineLength = @editor.lineTextForBufferRow(point.row).length
    eofPosition = @editor.getEofBufferPosition().translate([0, 1])
    increment = if reverse then -1 else 1

    loop
      character = @characterAt(point)
      depth++ if character is inCharacter
      depth-- if character is outCharacter

      return point if depth is 0

      point.column += increment

      return null if depth < 0
      return null if point.isEqual([0, -1])
      return null if point.isEqual(eofPosition)

      if point.column < 0
        point.row--
        lineLength = @editor.lineTextForBufferRow(point.row).length
        point.column = lineLength - 1
      else if point.column >= lineLength
        point.row++
        lineLength = @editor.lineTextForBufferRow(point.row).length
        point.column = 0

  characterAt: (position) ->
    @editor.getTextInBufferRange([position, position.translate([0, 1])])

  getSearchData: (position) ->
    character = @characterAt(position)
    if (index = OpenBrackets.indexOf(character)) >= 0
      [character, CloseBrackets[index], false]
    else if (index = CloseBrackets.indexOf(character)) >= 0
      [character, OpenBrackets[index], true]
    else
      []

  moveCursor: (cursor) ->
    startPosition = cursor.getBufferPosition()

    [inCharacter, outCharacter, reverse] = @getSearchData(startPosition)

    unless inCharacter?
      restOfLine = [startPosition, [startPosition.row, Infinity]]
      @editor.scanInBufferRange AnyBracket, restOfLine, ({range, stop}) ->
        startPosition = range.start
        stop()

    [inCharacter, outCharacter, reverse] = @getSearchData(startPosition)

    return unless inCharacter?

    if matchPosition = @searchForMatch(startPosition, reverse, inCharacter, outCharacter)
      cursor.setBufferPosition(matchPosition)

module.exports = {
  CurrentSelection
  MoveLeft, MoveRight, MoveUp, MoveDown
  MoveToPreviousWord, MoveToNextWord, MoveToEndOfWord
  MoveToPreviousWholeWord, MoveToNextWholeWord, MoveToEndOfWholeWord
  MoveToNextParagraph, MoveToPreviousParagraph
  MoveToLastLine, MoveToFirstLine,
  MoveToRelativeLine, MoveToBeginningOfLine
  MoveToFirstCharacterOfLine, MoveToFirstCharacterOfLineUp
  MoveToLastCharacterOfLine, MoveToFirstCharacterOfLineDown
  MoveToFirstCharacterOfLineAndDown, MoveToLastNonblankCharacterOfLineAndDown
  MoveToTopOfScreen, MoveToBottomOfScreen, MoveToMiddleOfScreen,

  ScrollFullScreenDown, ScrollFullScreenUp,
  ScrollHalfScreenDown, ScrollHalfScreenUp

  MoveToMark, MoveToMarkLine,

  Find, FindBackwards
  Till, TillBackwards
  RepeatFind, RepeatFindReverse,

  Search, SearchBackwards
  SearchCurrentWord, SearchCurrentWordBackwards
  RepeatSearch, RepeatSearchReverse
  BracketMatchingMotion
}
