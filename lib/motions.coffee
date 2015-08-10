_ = require 'underscore-plus'
{Point, Range} = require 'atom'
settings = require './settings'
{ViewModel, Input} = require './view-models/view-model'
SearchViewModel = require './view-models/search-view-model'
Base = require './base'

WholeWordRegex = /\S+/
WholeWordOrEmptyLineRegex = /^\s*$|\S+/
AllWhitespace = /^\s$/

class MotionError extends Base
  @extend()
  constructor: (@message) ->
    @name = 'Motion Error'

class Motion extends Base
  @extend()
  operatesInclusively: true
  operatesLinewise: false
  complete: true
  recordable: false

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState

  select: (options) ->
    value = for selection in @editor.getSelections()
      if @isLinewise()
        @moveSelectionLinewise(selection, options)
      else if @isInclusive()
        @moveSelectionInclusively(selection, options)
      else
        @moveSelection(selection, options)
      not selection.isEmpty()

    @editor.mergeCursors()
    @editor.mergeIntersectingSelections()
    value

  execute: ->
    for cursor in @editor.getCursors()
      @moveCursor(cursor)
    @editor.mergeCursors()

  moveSelectionLinewise: (selection, options) ->
    selection.modifySelection =>
      [oldStartRow, oldEndRow] = selection.getBufferRowRange()

      wasEmpty = selection.isEmpty()
      wasReversed = selection.isReversed()
      unless wasEmpty or wasReversed
        selection.cursor.moveLeft()

      @moveCursor(selection.cursor, options)

      isEmpty = selection.isEmpty()
      isReversed = selection.isReversed()
      unless isEmpty or isReversed
        selection.cursor.moveRight()

      [newStartRow, newEndRow] = selection.getBufferRowRange()

      if isReversed and not wasReversed
        newEndRow = Math.max(newEndRow, oldStartRow)
      if wasReversed and not isReversed
        newStartRow = Math.min(newStartRow, oldEndRow)

      selection.setBufferRange([[newStartRow, 0], [newEndRow + 1, 0]])

  moveSelectionInclusively: (selection, options) ->
    selection.modifySelection =>
      range = selection.getBufferRange()
      [oldStart, oldEnd] = [range.start, range.end]

      wasEmpty = selection.isEmpty()
      wasReversed = selection.isReversed()
      unless wasEmpty or wasReversed
        selection.cursor.moveLeft()

      @moveCursor(selection.cursor, options)

      isEmpty = selection.isEmpty()
      isReversed = selection.isReversed()
      unless isEmpty or isReversed
        selection.cursor.moveRight()

      range = selection.getBufferRange()
      [newStart, newEnd] = [range.start, range.end]

      if (isReversed or isEmpty) and not (wasReversed or wasEmpty)
        selection.setBufferRange([newStart, [newEnd.row, oldStart.column + 1]])
      if wasReversed and not wasEmpty and not isReversed
        selection.setBufferRange([[newStart.row, oldEnd.column - 1], newEnd])

      # keep a single-character selection non-reversed
      range = selection.getBufferRange()
      [newStart, newEnd] = [range.start, range.end]
      if selection.isReversed() and newStart.row is newEnd.row and newStart.column + 1 is newEnd.column
        selection.setBufferRange(range, reversed: false)

  moveSelection: (selection, options) ->
    selection.modifySelection => @moveCursor(selection.cursor, options)

  isComplete: ->
    @complete

  isRecordable: ->
    @recordable

  isLinewise: ->
    if @vimState.isVisualMode()
      @vimState.submode is 'linewise'
    else
      @operatesLinewise

  isInclusive: ->
    @vimState.isVisualMode() or @operatesInclusively

# Public: Generic class for motions that require extra input
class MotionWithInput extends Motion
  @extend()
  complete: false

  isComplete: ->
    @complete

  canComposeWith: (operation) ->
    return operation.characters?

  compose: (input) ->
    unless input.characters
      throw new MotionError('Must compose with an Input')
    @input = input
    @complete = true

class MoveLeft extends Motion
  @extend()
  operatesInclusively: false

  moveCursor: (cursor) ->
    _.times @getCount(1), ->
      cursor.moveLeft() if not cursor.isAtBeginningOfLine() or settings.wrapLeftRightMotion()

class MoveRight extends Motion
  @extend()
  operatesInclusively: false
  composed: false

  onDidComposeBy: (operation) ->
    # Don't save oeration to instance variable to avoid reference before I understand it correctly.
    # Also reflection support circular reference detection to stop infinit reflection loop.
    @composed = true if operation.isOperator()

  isOperatorPending: ->
    @vimState.isOperatorPendingMode() or @composed

  moveCursor: (cursor) ->
    _.times @getCount(1), =>
      wrapToNextLine = settings.wrapLeftRightMotion()

      # when the motion is combined with an operator, we will only wrap to the next line
      # if we are already at the end of the line (after the last character)
      if @isOperatorPending() and not cursor.isAtEndOfLine()
      # if @composer?.isOperator() and not cursor.isAtEndOfLine()
        wrapToNextLine = false

      cursor.moveRight() unless cursor.isAtEndOfLine()
      cursor.moveRight() if wrapToNextLine and cursor.isAtEndOfLine()

class MoveUp extends Motion
  @extend()
  operatesLinewise: true

  moveCursor: (cursor) ->
    _.times @getCount(1), ->
      unless cursor.getScreenRow() is 0
        cursor.moveUp()

class MoveDown extends Motion
  @extend()
  operatesLinewise: true

  moveCursor: (cursor) ->
    _.times @getCount(1), =>
      unless cursor.getScreenRow() is @editor.getLastScreenRow()
        cursor.moveDown()

class MoveToPreviousWord extends Motion
  @extend()
  operatesInclusively: false

  moveCursor: (cursor) ->
    _.times @getCount(1), ->
      cursor.moveToBeginningOfWord()

class MoveToPreviousWholeWord extends Motion
  @extend()
  operatesInclusively: false

  moveCursor: (cursor) ->
    _.times @getCount(1), =>
      cursor.moveToBeginningOfWord()
      while not @isWholeWord(cursor) and not @isBeginningOfFile(cursor)
        cursor.moveToBeginningOfWord()

  isWholeWord: (cursor) ->
    char = cursor.getCurrentWordPrefix().slice(-1)
    AllWhitespace.test(char)

  isBeginningOfFile: (cursor) ->
    cur = cursor.getBufferPosition()
    not cur.row and not cur.column

class MoveToNextWord extends Motion
  @extend()
  wordRegex: null
  operatesInclusively: false

  moveCursor: (cursor, options) ->
    _.times @getCount(1), =>
      current = cursor.getBufferPosition()

      next = if options?.excludeWhitespace
        cursor.getEndOfCurrentWordBufferPosition(wordRegex: @wordRegex)
      else
        cursor.getBeginningOfNextWordBufferPosition(wordRegex: @wordRegex)

      return if @isEndOfFile(cursor)

      if cursor.isAtEndOfLine()
        cursor.moveDown()
        cursor.moveToBeginningOfLine()
        cursor.skipLeadingWhitespace()
      else if current.row is next.row and current.column is next.column
        cursor.moveToEndOfWord()
      else
        cursor.setBufferPosition(next)

  isEndOfFile: (cursor) ->
    cur = cursor.getBufferPosition()
    eof = @editor.getEofBufferPosition()
    cur.row is eof.row and cur.column is eof.column

class MoveToNextWholeWord extends MoveToNextWord
  @extend()
  wordRegex: WholeWordOrEmptyLineRegex

class MoveToEndOfWord extends Motion
  @extend()
  wordRegex: null

  moveCursor: (cursor) ->
    _.times @getCount(1), =>
      current = cursor.getBufferPosition()

      next = cursor.getEndOfCurrentWordBufferPosition(wordRegex: @wordRegex)
      next.column-- if next.column > 0

      if next.isEqual(current)
        cursor.moveRight()
        if cursor.isAtEndOfLine()
          cursor.moveDown()
          cursor.moveToBeginningOfLine()

        next = cursor.getEndOfCurrentWordBufferPosition(wordRegex: @wordRegex)
        next.column-- if next.column > 0

      cursor.setBufferPosition(next)

class MoveToEndOfWholeWord extends MoveToEndOfWord
  @extend()
  wordRegex: WholeWordRegex

class MoveToNextParagraph extends Motion
  @extend()
  operatesInclusively: false

  moveCursor: (cursor) ->
    _.times @getCount(1), ->
      cursor.moveToBeginningOfNextParagraph()

class MoveToPreviousParagraph extends Motion
  @extend()
  moveCursor: (cursor) ->
    _.times @getCount(1), ->
      cursor.moveToBeginningOfPreviousParagraph()

class MoveToBeginningOfLine extends Motion
  @extend()

  operatesInclusively: false

  moveCursor: (cursor) ->
    _.times @getCount(1), ->
      cursor.moveToBeginningOfLine()

class MoveToFirstCharacterOfLine extends Motion
  @extend()

  operatesInclusively: false

  moveCursor: (cursor) ->
    _.times @getCount(1), ->
      cursor.moveToBeginningOfLine()
      cursor.moveToFirstCharacterOfLine()

class MoveToFirstCharacterOfLineAndDown extends Motion
  @extend()

  operatesLinewise: true
  operatesInclusively: true

  moveCursor: (cursor) ->
    _.times (@getCount(0) - 1), ->
      cursor.moveDown()
    cursor.moveToBeginningOfLine()
    cursor.moveToFirstCharacterOfLine()

class MoveToLastCharacterOfLine extends Motion
  @extend()

  operatesInclusively: false

  moveCursor: (cursor) ->
    _.times @getCount(1), ->
      cursor.moveToEndOfLine()
      cursor.goalColumn = Infinity

class MoveToLastNonblankCharacterOfLineAndDown extends Motion
  @extend()

  operatesInclusively: true

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

  moveCursor: (cursor) ->
    _.times (@getCount(1) - 1), ->
      cursor.moveDown()
    @skipTrailingWhitespace(cursor)

class MoveToFirstCharacterOfLineUp extends Motion
  @extend()

  operatesLinewise: true
  operatesInclusively: true

  moveCursor: (cursor) ->
    _.times @getCount(1), ->
      cursor.moveUp()
    cursor.moveToBeginningOfLine()
    cursor.moveToFirstCharacterOfLine()

class MoveToFirstCharacterOfLineDown extends Motion
  @extend()

  operatesLinewise: true

  moveCursor: (cursor) ->
    _.times @getCount(1), ->
      cursor.moveDown()
    cursor.moveToBeginningOfLine()
    cursor.moveToFirstCharacterOfLine()

# Not directly used.
class MoveToLineBase extends Motion
  @extend()
  operatesLinewise: true

  getDestinationRow: (count) ->
    if count? then count - 1 else (@editor.getLineCount() - 1)

class MoveToLine extends MoveToLineBase
  @extend()

  moveCursor: (cursor) ->
    cursor.setBufferPosition([@getDestinationRow(@getCount()), Infinity])
    cursor.moveToFirstCharacterOfLine()
    cursor.moveToEndOfLine() if cursor.getBufferColumn() is 0

class MoveToRelativeLine extends MoveToLineBase
  @extend()
  operatesLinewise: true

  moveCursor: (cursor) ->
    {row, column} = cursor.getBufferPosition()
    cursor.setBufferPosition([row + (@getCount(1) - 1), 0])

# Not directly used.
class MoveToScreenLine extends MoveToLineBase
  @extend()
  scrolloff: 2

  moveCursor: (cursor) ->
    {row, column} = cursor.getBufferPosition()
    cursor.setScreenPosition([@getDestinationRow(@getCount(1)), 0])

# keymap: gg
class MoveToStartOfFile extends MoveToLineBase
  @extend()

  moveCursor: (cursor) ->
    {row, column} = @editor.getCursorBufferPosition()
    cursor.setBufferPosition([@getDestinationRow(@getCount(1)), 0])
    unless @isLinewise()
      cursor.moveToFirstCharacterOfLine()

# keymap: H
class MoveToTopOfScreen extends MoveToScreenLine
  @extend()
  getDestinationRow: ->
    count = @getCount(0)
    firstScreenRow = @editorElement.getFirstVisibleScreenRow()
    if firstScreenRow > 0
      offset = Math.max(count - 1, @scrolloff)
    else
      offset = if count > 0 then count - 1 else count
    firstScreenRow + offset

# keymap: L
class MoveToBottomOfScreen extends MoveToScreenLine
  @extend()
  getDestinationRow: ->
    count = @getCount(0)
    lastScreenRow = @editorElement.getLastVisibleScreenRow()
    lastRow = @editor.getBuffer().getLastRow()
    if lastScreenRow isnt lastRow
      offset = Math.max(count - 1, @scrolloff)
    else
      offset = if count > 0 then count - 1 else count
    lastScreenRow - offset

class MoveToMiddleOfScreen extends MoveToScreenLine
  @extend()
  getDestinationRow: ->
    firstScreenRow = @editorElement.getFirstVisibleScreenRow()
    lastScreenRow = @editorElement.getLastVisibleScreenRow()
    height = lastScreenRow - firstScreenRow
    Math.floor(firstScreenRow + (height / 2))

class ScrollKeepingCursor extends MoveToLineBase
  @extend()
  previousFirstScreenRow: 0
  currentFirstScreenRow: 0

  select: (options) ->
    finalDestination = @scrollScreen()
    super(options)
    @editor.setScrollTop(finalDestination)

  execute: ->
    finalDestination = @scrollScreen()
    super
    @editor.setScrollTop(finalDestination)

  moveCursor: (cursor) ->
    cursor.setScreenPosition([@getDestinationRow(@getCount(1)), 0])

  getDestinationRow: ->
    {row, column} = @editor.getCursorScreenPosition()
    @currentFirstScreenRow - @previousFirstScreenRow + row

  scrollScreen: ->
    @previousFirstScreenRow = @editorElement.getFirstVisibleScreenRow()
    destination = @scrollDestination()
    @editor.setScrollTop(destination)
    @currentFirstScreenRow = @editorElement.getFirstVisibleScreenRow()
    destination

class ScrollHalfUpKeepCursor extends ScrollKeepingCursor
  @extend()
  scrollDestination: ->
    half = (Math.floor(@editor.getRowsPerPage() / 2) * @editor.getLineHeightInPixels())
    @editor.getScrollTop() - @getCount(1) * half

class ScrollFullUpKeepCursor extends ScrollKeepingCursor
  @extend()
  scrollDestination: ->
    @editor.getScrollTop() - (@getCount(1) * @editor.getHeight())

class ScrollHalfDownKeepCursor extends ScrollKeepingCursor
  @extend()
  scrollDestination: ->
    half = (Math.floor(@editor.getRowsPerPage() / 2) * @editor.getLineHeightInPixels())
    @editor.getScrollTop() + @getCount(1) * half

class ScrollFullDownKeepCursor extends ScrollKeepingCursor
  @extend()
  scrollDestination: ->
    @editor.getScrollTop() + (@getCount(1) * @editor.getHeight())

# Find Motion
# -------------------------
class Find extends MotionWithInput
  @extend()
  backwards: false
  offset: 0
  constructor: (@vimState, options={}) ->
    super(@vimState)

    if not options.repeated
      @viewModel = new ViewModel(this, class: 'find', singleChar: true, hidden: true)
      # @backwards = false # Moved to prototype property `backwards: false`
      @repeated = false
      @vimState.globalVimState.currentFind = this

    else
      @repeated = true

      orig = @vimState.globalVimState.currentFind
      @backwards = orig.backwards
      @complete = orig.complete
      @input = orig.input

      @reverse() if options.reverse

  match: (cursor, count) ->
    currentPosition = cursor.getBufferPosition()
    line = @editor.lineTextForBufferRow(currentPosition.row)
    if @backwards
      index = currentPosition.column
      for i in [0..count-1]
        return if index <= 0 # we can't move backwards any further, quick return
        index = line.lastIndexOf(@input.characters, index-1-(@offset*@repeated))
      if index >= 0
        new Point(currentPosition.row, index + @offset)
    else
      index = currentPosition.column
      for i in [0..count-1]
        index = line.indexOf(@input.characters, index+1+(@offset*@repeated))
        return if index < 0 # no match found
      if index >= 0
        new Point(currentPosition.row, index - @offset)

  reverse: ->
    @backwards = not @backwards
    this

  moveCursor: (cursor) ->
    if (match = @match(cursor, @getCount(1)))?
      cursor.setBufferPosition(match)

class FindBackwards extends Find
  @extend()
  backwards: true

class Till extends Find
  @extend()
  offset: 1

  match: ->
    @selectAtLeastOne = false
    retval = super
    if retval? and not @backwards
      @selectAtLeastOne = true
    retval

  moveSelectionInclusively: (selection, options) ->
    super
    if selection.isEmpty() and @selectAtLeastOne
      selection.modifySelection ->
        selection.cursor.moveRight()

class TillBackwards extends Till
  @extend()
  backwards: true

# MoveToMark
# -------------------------
class MoveToMark extends MotionWithInput
  @extend()
  operatesInclusively: false

  constructor: (@vimState, @linewise=true) ->
    super(@vimState)
    @operatesLinewise = @linewise
    @viewModel = new ViewModel(this, class: 'move-to-mark', singleChar: true, hidden: true)

  isLinewise: -> @linewise

  moveCursor: (cursor) ->
    markPosition = @vimState.getMark(@input.characters)

    if @input.characters is '`' # double '`' pressed
      markPosition ?= [0, 0] # if markPosition not set, go to the beginning of the file
      @vimState.setMark('`', cursor.getBufferPosition())

    cursor.setBufferPosition(markPosition) if markPosition?
    if @linewise
      cursor.moveToFirstCharacterOfLine()

class MoveToMarkLiteral extends MoveToMark
  @extend()

  constructor: (@vimState) ->
    super(@vimState, false)

class SearchBase extends MotionWithInput
  @extend()
  operatesInclusively: false

  constructor: (@vimState, options={}) ->
    super(@vimState)
    @reverse = @initiallyReversed = false
    @updateCurrentSearch() unless options.dontUpdateCurrentSearch

  reversed: =>
    @initiallyReversed = @reverse = true
    @updateCurrentSearch()
    this

  moveCursor: (cursor) ->
    ranges = @scan(cursor)
    if ranges.length > 0
      range = ranges[(@getCount(1) - 1) % ranges.length]
      cursor.setBufferPosition(range.start)
    else
      atom.beep()

  scan: (cursor) ->
    return [] if @input.characters is ""

    currentPosition = cursor.getBufferPosition()

    [rangesBefore, rangesAfter] = [[], []]
    @editor.scan @getSearchTerm(@input.characters), ({range}) =>
      isBefore = if @reverse
        range.start.compare(currentPosition) < 0
      else
        range.start.compare(currentPosition) <= 0

      if isBefore
        rangesBefore.push(range)
      else
        rangesAfter.push(range)

    if @reverse
      rangesAfter.concat(rangesBefore).reverse()
    else
      rangesAfter.concat(rangesBefore)

  getSearchTerm: (term) ->
    modifiers = {'g': true}

    if not term.match('[A-Z]') and settings.useSmartcaseForSearch()
      modifiers['i'] = true

    if term.indexOf('\\c') >= 0
      term = term.replace('\\c', '')
      modifiers['i'] = true

    modFlags = Object.keys(modifiers).join('')

    try
      new RegExp(term, modFlags)
    catch
      new RegExp(_.escapeRegExp(term), modFlags)

  updateCurrentSearch: ->
    @vimState.globalVimState.currentSearch.reverse = @reverse
    @vimState.globalVimState.currentSearch.initiallyReversed = @initiallyReversed

  replicateCurrentSearch: ->
    @reverse = @vimState.globalVimState.currentSearch.reverse
    @initiallyReversed = @vimState.globalVimState.currentSearch.initiallyReversed

# Search Motion
# -------------------------
class Search extends SearchBase
  @extend()
  constructor: ->
    super
    @viewModel = new SearchViewModel(this)

class ReverseSearch extends Search
  @extend()
  constructor: ->
    super
    @reversed()

class SearchCurrentWord extends SearchBase
  @extend()
  @keywordRegex: null

  constructor: (@vimState) ->
    super

    # FIXME: This must depend on the current language
    defaultIsKeyword = "[@a-zA-Z0-9_\-]+"
    userIsKeyword = atom.config.get('vim-mode.iskeyword')
    @keywordRegex = new RegExp(userIsKeyword or defaultIsKeyword)

    searchString = @getCurrentWordMatch()
    @input = new Input(searchString)
    @vimState.pushSearchHistory(searchString) unless searchString is @vimState.getSearchHistoryItem()

  getCurrentWord: ->
    cursor = @editor.getLastCursor()
    wordStart = cursor.getBeginningOfCurrentWordBufferPosition(wordRegex: @keywordRegex, allowPrevious: false)
    wordEnd   = cursor.getEndOfCurrentWordBufferPosition      (wordRegex: @keywordRegex, allowNext: false)
    cursorPosition = cursor.getBufferPosition()

    if wordEnd.column is cursorPosition.column
      # either we don't have a current word, or it ends on cursor, i.e. precedes it, so look for the next one
      wordEnd = cursor.getEndOfCurrentWordBufferPosition      (wordRegex: @keywordRegex, allowNext: true)
      return "" if wordEnd.row isnt cursorPosition.row # don't look beyond the current line

      cursor.setBufferPosition wordEnd
      wordStart = cursor.getBeginningOfCurrentWordBufferPosition(wordRegex: @keywordRegex, allowPrevious: false)

    cursor.setBufferPosition wordStart

    @editor.getTextInBufferRange([wordStart, wordEnd])

  cursorIsOnEOF: (cursor) ->
    pos = cursor.getNextWordBoundaryBufferPosition(wordRegex: @keywordRegex)
    eofPos = @editor.getEofBufferPosition()
    pos.row is eofPos.row and pos.column is eofPos.column

  getCurrentWordMatch: ->
    characters = @getCurrentWord()
    if characters.length > 0
      if /\W/.test(characters) then "#{characters}\\b" else "\\b#{characters}\\b"
    else
      characters

  isComplete: -> true

  execute: ->
    # @getCount(1)
    super() if @input.characters.length > 0

class ReverseSearchCurrentWord extends SearchCurrentWord
  @extend()
  constructor: ->
    super
    @reversed()

OpenBrackets = ['(', '{', '[']
CloseBrackets = [')', '}', ']']
AnyBracket = new RegExp(OpenBrackets.concat(CloseBrackets).map(_.escapeRegExp).join("|"))

class BracketMatchingMotion extends SearchBase
  @extend()
  operatesInclusively: true

  isComplete: -> true

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

class RepeatSearch extends SearchBase
  @extend()
  constructor: (@vimState) ->
    super(@vimState, dontUpdateCurrentSearch: true)
    @input = new Input(@vimState.getSearchHistoryItem(0) ? "")
    @replicateCurrentSearch()

  isComplete: -> true

  reversed: ->
    @reverse = not @initiallyReversed
    this

class RepeatSearchBackwards extends RepeatSearch
  @extend()
  constructor: ->
    super
    @reversed()

# Alias
# MoveToLine = MoveToAbsoluteLine
ScrollHalfScreenUp = ScrollHalfUpKeepCursor
ScrollHalfScreenDown = ScrollHalfDownKeepCursor
ScrollFullScreenUp = ScrollFullUpKeepCursor
ScrollFullScreenDown = ScrollFullDownKeepCursor

module.exports = {
  MotionError
  Motion
  MotionWithInput
  MoveLeft, MoveRight, MoveUp, MoveDown
  MoveToPreviousWord, MoveToNextWord, MoveToEndOfWord
  MoveToPreviousWholeWord, MoveToNextWholeWord, MoveToEndOfWholeWord
  MoveToNextParagraph, MoveToPreviousParagraph
  MoveToLine,
  MoveToRelativeLine, MoveToBeginningOfLine
  MoveToFirstCharacterOfLine, MoveToFirstCharacterOfLineUp
  MoveToLastCharacterOfLine, MoveToFirstCharacterOfLineDown
  MoveToFirstCharacterOfLineAndDown, MoveToLastNonblankCharacterOfLineAndDown
  MoveToStartOfFile,
  MoveToTopOfScreen, MoveToBottomOfScreen, MoveToMiddleOfScreen,

  # Aliased
  ScrollHalfScreenUp
  ScrollHalfScreenDown
  ScrollFullScreenUp
  ScrollFullScreenDown

  Find
  FindBackwards
  Till
  TillBackwards
  MoveToMark
  MoveToMarkLiteral
  Search
  ReverseSearch
  SearchCurrentWord
  ReverseSearchCurrentWord
  BracketMatchingMotion
  RepeatSearch
  RepeatSearchBackwards
}
