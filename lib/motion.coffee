# Refactoring status: 50%
_ = require 'underscore-plus'
{Point, Range, CompositeDisposable} = require 'atom'

globalState = require './global-state'
{
  saveEditorState, getVisibleBufferRange, withKeepingGoalColumn
  cursorIsAtEndOfBuffer, getEofBufferPosition
} = require './utils'
swrap = require './selection-wrapper'
{Hover} = require './hover'
{MatchList} = require './match'
settings = require './settings'
{Search} = require './input'
Base = require './base'

class Motion extends Base
  @extend(false)
  inclusive: false
  linewise: false
  options: null

  constructor: ->
    super
    @initialize?()

  setOptions: (@options) ->

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
        @selectInclusive selection
        swrap(selection).expandOverLine() if @isLinewise()
      else
        selection.modifySelection =>
          @moveCursor selection.cursor
    @editor.mergeCursors()
    @editor.mergeIntersectingSelections()
    @emitDidSelect()

  selectInclusive: (selection) ->
    {cursor} = selection

    # Selection maybe empty when Motion is used as target of Operator.
    if selection.isEmpty()
      originallyEmpty = true
      selection.selectRight()

    selection.modifySelection =>
      tailRange = swrap(selection).getTailRange()
      unless selection.isReversed() or
         (cursorIsAtEndOfBuffer(@editor, cursor) and selection.isEmpty()) # become empty at EndOfBuffer
        withKeepingGoalColumn cursor, (c) ->
          c.moveLeft()
      @moveCursor(cursor)

      # When motion is used as target of operator, return if motion movement not happend.
      return if (selection.isEmpty() and originallyEmpty)

      unless selection.isReversed()
        withKeepingGoalColumn cursor, (c) ->
          unless (c.isAtEndOfLine() and not c.isAtBeginningOfLine())
            c.moveRight()
      newRange = selection.getBufferRange().union(tailRange)
      options = {autoscroll: false, preserveFolds: true}
      selection.setBufferRange(newRange, options)

  getEolBufferPosition: (cursor) ->
    cursor.getCurrentLineBufferRange().end

  # Cursor motion wrapper
  # -------------------------
  moveCursorUp: (cursor) ->
    unless @at('FirstScreenRow', cursor)
      cursor.moveUp()

  moveCursorDown: (cursor) ->
    unless @at('LastScreenRow', cursor)
      cursor.moveDown()

  moveCursorRight: (cursor, allowWrap=false) ->
    {row, column} = cursor.getScreenPosition()
    column++
    column++ if allowWrap and @getEolBufferPosition(cursor).isEqual([row, column])
    point = Point.min([row, column], @getEofScreenPosition())
    cursor.setScreenPosition point,
      clip: 'forward',
      wrapBeyondNewlines: allowWrap
      wrapAtSoftNewlines: true

  moveCursorLeft: (cursor, allowWrap=false) ->
    if not cursor.isAtBeginningOfLine() or allowWrap
      cursor.moveLeft()

  # Utils
  # -------------------------
  countTimes: (fn) ->
    _.times @getCount(), ->
      fn()

  at: (where, cursor) ->
    switch where
      when 'EOL' then cursor.isAtEndOfLine()
      when 'EOF' then cursor.getBufferPosition().isEqual(@getEofBufferPosition())
      when 'FirstScreenRow' then cursor.getScreenRow() is 0
      when 'LastBufferRow' then cursor.getBufferRow() is @getLastBufferRow()
      when 'LastScreenRow' then cursor.getScreenRow() is @getLastScreenRow()

  moveToFirstCharacterOfLine: (cursor) ->
    cursor.moveToBeginningOfLine()
    cursor.moveToFirstCharacterOfLine()

  getEofBufferPosition: ->
    getEofBufferPosition(@editor)

  getEofScreenPosition: ->
    @editor.screenPositionForBufferPosition(@getEofBufferPosition())

  getLastBufferRow: ->
    @getEofBufferPosition().row

  getLastScreenRow: ->
    @getEofScreenPosition().row

  getFirstVisibleScreenRow: ->
    @editorElement.getFirstVisibleScreenRow()

  getLastVisibleScreenRow: ->
    @editorElement.getLastVisibleScreenRow()

  unfoldAtCursorRow: (cursor) ->
    row = cursor.getBufferRow()
    if @editor.isFoldedAtBufferRow(row)
      @editor.unfoldBufferRow row

  # Debuging purpose
  # -------------------------
  # [TODO] remove after dev finished
  reportCursor: (subject, cursor) ->
    EOL = cursor.getCurrentLineBufferRange().end
    point = cursor.getBufferPosition()
    console.log "#{subject}: c = #{point.toString()}, eol = #{EOL.toString()}"

  withReporting: (subject, cursor, fn) ->
    @reportCursor("#{subject}: before", cursor)
    fn()
    @reportCursor("#{subject}: after", cursor)
    console.log '--------------------'

# Used as operator's target in visual-mode.
# Never be execute()ed as stand-alone motion
class CurrentSelection extends Motion
  @extend(false)
  selectedRange: null
  initialize: ->
    @selectedRange = @editor.getSelectedBufferRange()
    @wasLinewise = @isLinewise()

  # Never be called but put here for consistency
  execute: ->

  select: ->
    # In visual mode, the current selections are already there.
    # If we're not in visual mode, we are repeating some operation and need to re-do the selections
    unless @isMode('visual')
      @selectCharacters()
      if @wasLinewise
        swrap(s).expandOverLine() for s in @editor.getSelections()
    @emitDidSelect()

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
      @moveCursorLeft(cursor, settings.get('wrapLeftRightMotion'))

class MoveRight extends Motion
  @extend()
  canWrapToNextLine: (cursor) ->
    if @isAsTarget() and not @at('EOL', cursor)
      false
    else
      settings.get('wrapLeftRightMotion')

  moveCursor: (cursor) ->
    @countTimes =>
      @unfoldAtCursorRow(cursor)
      @moveCursorRight(cursor, @canWrapToNextLine(cursor))

class MoveUp extends Motion
  @extend()
  linewise: true
  amount: -1

  move: (cursor) ->
    @moveCursorUp(cursor)

  moveCursor: (cursor) ->
    isBufferRowWise = @editor.isSoftWrapped() and @isMode('visual', 'linewise')
    @countTimes =>
      if isBufferRowWise
        point = cursor.getBufferPosition().translate([@amount, 0])
        cursor.setBufferPosition(point)
      else
        @move(cursor)

class MoveDown extends MoveUp
  @extend()
  linewise: true
  amount: +1

  move: (cursor) ->
    @moveCursorDown(cursor)

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
      if @at('EOL', cursor) and not @at('EOF', cursor)
        cursor.moveDown()
        cursor.moveToFirstCharacterOfLine()
      else
        next = @getNext(cursor)
        if next.isEqual(cursor.getBufferPosition())
          cursor.moveToEndOfWord()
        else
          if next.row is @getLastBufferRow() + 1
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
        if @at('EOL', cursor) and not @at('EOF', cursor)
          cursor.moveDown()
          cursor.moveToBeginningOfLine()
        point = Point.min(@getEofBufferPosition(), @getNext(cursor))
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
      unless @at('LastBufferRow', cursor)
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
    @countTimes =>
      @moveCursorUp(cursor)
    super

class MoveToFirstCharacterOfLineDown extends MoveToFirstCharacterOfLine
  @extend()
  linewise: true
  moveCursor: (cursor) ->
    @countTimes =>
      @moveCursorDown(cursor)
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
    cursor.setBufferPosition [@getRow(), cursor.getBufferColumn()]

# keymap: G
class MoveToLastLine extends MoveToFirstLine
  @extend()
  getDefaultRow: ->
    @getLastScreenRow()

# keymap: N% e.g. 10%
class MoveToLineByPercent extends MoveToFirstLine
  @extend()
  getRow: ->
    percent = Math.min(100, @getCount())
    Math.floor(@getLastScreenRow() * (percent / 100))

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
    row = @getFirstVisibleScreenRow()
    offset = if row is 0 then 0 else @scrolloff
    row + Math.max(@getCount(), offset)

  getCount: -> super - 1

# keymap: L
class MoveToBottomOfScreen extends MoveToTopOfScreen
  @extend()
  getRow: ->
    row = @getLastVisibleScreenRow()
    offset = if row is @getLastBufferRow() then 0 else @scrolloff
    row - Math.max(@getCount(), offset)

# keymap: M
class MoveToMiddleOfScreen extends MoveToTopOfScreen
  @extend()
  getRow: ->
    row = @getFirstVisibleScreenRow()
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
    row = Math.min(@getLastScreenRow(), row)
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

  selectInclusive: (selection) ->
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
  saveCurrentSearch: true
  backwards: false
  escapeRegExp: false

  initialize: ->
    if @saveCurrentSearch
      globalState.currentSearch.backwards = @backwards

  isBackwards: ->
    @backwards

  # Not sure if I should support count but keep this for compatibility to official vim-mode.
  getCount: ->
    count = super
    if @isBackwards() then -count else count - 1

  flash: (range, {timeout}={}) ->
    @vimState.flasher.flash range,
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
      @vimState.searchHistory.save(@input)
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
    return ranges if @input is ''

    @editor.scan @getPattern(@input), ({range}) ->
      ranges.push range

    point = cursor.getBufferPosition()
    [pre, post] = _.partition ranges, ({start}) =>
      if @isBackwards()
        start.isLessThan(point)
      else
        start.isLessThanOrEqual(point)

    post.concat(pre)

  getPattern: (term) ->
    modifiers = {'g': true}

    if not term.match('[A-Z]') and settings.get('useSmartcaseForSearch')
      modifiers['i'] = true

    if term.indexOf('\\c') >= 0
      term = term.replace('\\c', '')
      modifiers['i'] = true

    modFlags = Object.keys(modifiers).join('')

    if @escapeRegExp
      new RegExp(_.escapeRegExp(term), modFlags)
    else
      try
        new RegExp(term, modFlags)
      catch
        new RegExp(_.escapeRegExp(term), modFlags)

  # NOTE: trim first space if it is.
  # experimental if search word start with ' ' we switch escape mode.
  updateEscapeRegExpOption: (input) ->
    if @escapeRegExp = /^ /.test(input)
      input = input.replace(/^ /, '')
    @updateUI {@escapeRegExp}
    input

  updateUI: (options) ->
    @vimState.search.updateOptionSettings(options)

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
    @vimState.search.focus({@backwards})

  isComplete: ->
    return false unless @confirmed
    super

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
    @vimState.operationStack.process()
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
      @moveCursor(c) for c in @editor.getCursors()

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
  wordRegex: null

  initialize: ->
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
  saveCurrentSearch: false

  initialize: ->
    super
    @input = @vimState.searchHistory.get('prev')
    @backwards = globalState.currentSearch.backwards

class RepeatSearchReverse extends RepeatSearch
  @extend()
  isBackwards: ->
    not @backwards

# keymap: %
OpenBrackets = ['(', '{', '[']
CloseBrackets = [')', '}', ']']
AnyBracket = new RegExp(OpenBrackets.concat(CloseBrackets).map(_.escapeRegExp).join("|"))

# TODO: refactor.
class BracketMatchingMotion extends SearchBase
  @extend()
  inclusive: true

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
