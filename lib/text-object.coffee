{Range, Point} = require 'atom'
_ = require 'underscore-plus'

Base = require './base'
swrap = require './selection-wrapper'
globalState = require './global-state'
{
  sortRanges, sortRangesByEndPosition, countChar, pointIsAtEndOfLine,
  getTextToPoint
  getIndentLevelForBufferRow
  getCodeFoldRowRangesContainesForRow
  getBufferRangeForRowRange
  isIncludeFunctionScopeForRow
  pointIsSurroundedByWhitespace
  getWordRegExpForPointWithCursor
  getStartPositionForPattern
  getEndPositionForPattern
} = require './utils'

class TextObject extends Base
  @extend(false)
  allowSubmodeChange: true

  constructor: ->
    @constructor::inner = @getName().startsWith('Inner')
    super
    @initialize?()

  isInner: ->
    @inner

  isA: ->
    not @isInner()

  isAllowSubmodeChange: ->
    @allowSubmodeChange

  isLinewise: ->
    if @isAllowSubmodeChange()
      swrap.detectVisualModeSubmode(@editor) is 'linewise'
    else
      @vimState.submode is 'linewise'

  select: ->
    for selection in @editor.getSelections()
      @selectTextObject(selection)
    @updateSelectionProperties() if @isMode('visual')

# -------------------------
class Word extends TextObject
  @extend(false)

  getPattern: (selection) ->
    point = swrap(selection).getNormalizedBufferPosition()
    if pointIsSurroundedByWhitespace(@editor, point)
      /[\t ]*/
    else
      @wordRegExp ? getWordRegExpForPointWithCursor(selection.cursor, point)

  selectTextObject: (selection) ->
    swrap(selection).setBufferRangeSafely(@getRange(selection))

  getRange: (selection) ->
    pattern = @getPattern(selection)
    from = swrap(selection).getNormalizedBufferPosition()
    options = containedOnly: true
    start = getStartPositionForPattern(@editor, from, pattern, options)
    end = getEndPositionForPattern(@editor, from, pattern, options)

    start ?= from
    end ?= from
    if @isA() and endOfSpace = getEndPositionForPattern(@editor, end, /\s+/, options)
      end = endOfSpace

    unless start.isEqual(end)
      new Range(start, end)
    else
      null

class AWord extends Word
  @extend()

class InnerWord extends Word
  @extend()

# -------------------------
class WholeWord extends Word
  @extend(false)
  wordRegExp: /\S+/

class AWholeWord extends WholeWord
  @extend()

class InnerWholeWord extends WholeWord
  @extend()

# -------------------------
# Just include _, -
class SmartWord extends Word
  @extend(false)
  wordRegExp: /[\w-]+/

class ASmartWord extends SmartWord
  @description: "A word that consists of alphanumeric chars(`/[A-Za-z0-9_]/`) and hyphen `-`"
  @extend()

class InnerSmartWord extends SmartWord
  @description: "Currently No diff from `a-smart-word`"
  @extend()

# -------------------------
class Pair extends TextObject
  @extend(false)
  allowNextLine: false
  allowSubmodeChange: false
  adjustInnerRange: true
  pair: null
  getPattern: ->
    [open, close] = @pair
    if open is close
      new RegExp("(#{_.escapeRegExp(open)})", 'g')
    else
      new RegExp("(#{_.escapeRegExp(open)})|(#{_.escapeRegExp(close)})", 'g')

  # Return 'open' or 'close'
  getPairState: ({matchText, range, match}) ->
    switch match.length
      when 2
        @pairStateInBufferRange(range, matchText)
      when 3
        switch
          when match[1] then 'open'
          when match[2] then 'close'

  backSlashPattern = _.escapeRegExp('\\')
  pairStateInBufferRange: (range, char) ->
    text = getTextToPoint(@editor, range.end)
    escapedChar = _.escapeRegExp(char)
    bs = backSlashPattern
    patterns = [
      "#{bs}#{bs}#{escapedChar}"
      "[^#{bs}]?#{escapedChar}"
    ]
    pattern = new RegExp(patterns.join('|'))
    ['close', 'open'][(countChar(text, pattern) % 2)]

  # Take start point of matched range.
  isEscapedCharAtPoint: (point) ->
    found = false

    bs = backSlashPattern
    pattern = new RegExp("[^#{bs}]#{bs}")
    scanRange = [[point.row, 0], point]
    @editor.backwardsScanInBufferRange pattern, scanRange, ({matchText, range, stop}) ->
      if range.end.isEqual(point)
        stop()
        found = true
    found

  findPair: (which, options, fn) ->
    {from, pattern, scanFunc, scanRange} = options
    @editor[scanFunc] pattern, scanRange, (event) =>
      {matchText, range, stop} = event
      unless @allowNextLine or (from.row is range.start.row)
        return stop()
      return if @isEscapedCharAtPoint(range.start)
      fn(event)

  findOpen: (from,  pattern) ->
    scanFunc = 'backwardsScanInBufferRange'
    scanRange = new Range([0, 0], from)
    stack = []
    found = null
    @findPair 'open', {from, pattern, scanFunc, scanRange}, (event) =>
      {matchText, range, stop} = event
      pairState = @getPairState(event)
      if pairState is 'close'
        stack.push({pairState, matchText, range})
      else
        stack.pop()
        if stack.length is 0
          found = range
      stop() if found?
    found

  findClose: (from,  pattern) ->
    scanFunc = 'scanInBufferRange'
    scanRange = new Range(from, @editor.buffer.getEndPosition())
    stack = []
    found = null
    @findPair 'close', {from, pattern, scanFunc, scanRange}, (event) =>
      {range, stop} = event
      pairState = @getPairState(event)
      if pairState is 'open'
        stack.push({pairState, range})
      else
        entry = stack.pop()
        if stack.length is 0
          if (openStart = entry?.range.start)
            if @allowForwarding
              return if openStart.row > from.row
            else
              return if openStart.isGreaterThan(from)
          found = range
      stop() if found?
    found

  getPairInfo: (from) ->
    pairInfo = null
    pattern = @getPattern()
    closeRange = @findClose from, pattern
    openRange = @findOpen closeRange.end, pattern if closeRange?

    unless (openRange? and closeRange?)
      return null

    aRange = new Range(openRange.start, closeRange.end)
    [innerStart, innerEnd] = [openRange.end, closeRange.start]
    if @adjustInnerRange
      # Dirty work to feel natural for human, to behave compatible with pure Vim.
      # Where this adjustment appear is in following situation.
      # op-1: `ci{` replace only 2nd line
      # op-2: `di{` delete only 2nd line.
      # text:
      #  {
      #    aaa
      #  }
      innerStart = new Point(innerStart.row + 1, 0) if pointIsAtEndOfLine(@editor, innerStart)
      innerEnd = new Point(innerEnd.row, 0) if getTextToPoint(@editor, innerEnd).match(/^\s*$/)
      if (innerEnd.column is 0) and (innerStart.column isnt 0)
        innerEnd = new Point(innerEnd.row - 1, Infinity)

    innerRange = new Range(innerStart, innerEnd)
    targetRange = if @isInner() then innerRange else aRange
    if @skipEmptyPair and innerRange.isEmpty()
      @getPairInfo(aRange.end)
    else
      {openRange, closeRange, aRange, innerRange, targetRange}

  getPointToSearchFrom: (selection, searchFrom) ->
    switch searchFrom
      when 'head' then swrap(selection).getNormalizedBufferPosition()
      when 'start' then swrap(selection).getBufferPositionFor('start')

  # Allow override @allowForwarding by 2nd argument.
  getRange: (selection, options={}) ->
    {allowForwarding, searchFrom} = options
    searchFrom ?= 'head'
    @allowForwarding = allowForwarding if allowForwarding?
    originalRange = selection.getBufferRange()
    pairInfo = @getPairInfo(@getPointToSearchFrom(selection, searchFrom))
    # When range was same, try to expand range
    if pairInfo?.targetRange.isEqual(originalRange)
      pairInfo = @getPairInfo(pairInfo.aRange.end)
    pairInfo?.targetRange

  selectTextObject: (selection) ->
    swrap(selection).setBufferRangeSafely(@getRange(selection))

# -------------------------
class AnyPair extends Pair
  @extend(false)
  allowForwarding: false
  skipEmptyPair: false
  member: [
    'DoubleQuote', 'SingleQuote', 'BackTick',
    'CurlyBracket', 'AngleBracket', 'Tag', 'SquareBracket', 'Parenthesis'
  ]

  getRangeBy: (klass, selection) ->
    @new(klass, {@inner, @skipEmptyPair}).getRange(selection, {@allowForwarding, @searchFrom})

  getRanges: (selection) ->
    (range for klass in @member when (range = @getRangeBy(klass, selection)))

  getNearestRange: (selection) ->
    ranges = @getRanges(selection)
    _.last(sortRanges(ranges)) if ranges.length

  selectTextObject: (selection) ->
    swrap(selection).setBufferRangeSafely @getNearestRange(selection)

class AAnyPair extends AnyPair
  @extend()

class InnerAnyPair extends AnyPair
  @extend()

# -------------------------
class AnyPairAllowForwarding extends AnyPair
  @extend(false)
  @description: "Range surrounded by auto-detected paired chars from enclosed and forwarding area"
  allowForwarding: true
  allowNextLine: false
  skipEmptyPair: false
  searchFrom: 'start'
  getNearestRange: (selection) ->
    ranges = @getRanges(selection)
    from = selection.cursor.getBufferPosition()
    [forwardingRanges, enclosingRanges] = _.partition ranges, (range) ->
      range.start.isGreaterThanOrEqual(from)
    enclosingRange = _.last(sortRanges(enclosingRanges))
    forwardingRanges = sortRanges(forwardingRanges)

    # When enclosingRange is exists,
    # We don't go across enclosingRange.end.
    # So choose from ranges contained in enclosingRange.
    if enclosingRange
      forwardingRanges = forwardingRanges.filter (range) ->
        enclosingRange.containsRange(range)

    forwardingRanges[0] or enclosingRange

class AAnyPairAllowForwarding extends AnyPairAllowForwarding
  @extend()

class InnerAnyPairAllowForwarding extends AnyPairAllowForwarding
  @extend()

# -------------------------
class AnyQuote extends AnyPair
  @extend(false)
  allowForwarding: true
  member: ['DoubleQuote', 'SingleQuote', 'BackTick']
  getNearestRange: (selection) ->
    ranges = @getRanges(selection)
    # Pick range which end.colum is leftmost(mean, closed first)
    _.first(_.sortBy(ranges, (r) -> r.end.column)) if ranges.length

class AAnyQuote extends AnyQuote
  @extend()

class InnerAnyQuote extends AnyQuote
  @extend()

# -------------------------
class Quote extends Pair
  @extend(false)
  allowForwarding: true
  allowNextLine: false

class DoubleQuote extends Quote
  @extend(false)
  pair: ['"', '"']

class ADoubleQuote extends DoubleQuote
  @extend()

class InnerDoubleQuote extends DoubleQuote
  @extend()

# -------------------------
class SingleQuote extends Quote
  @extend(false)
  pair: ["'", "'"]

class ASingleQuote extends SingleQuote
  @extend()

class InnerSingleQuote extends SingleQuote
  @extend()

# -------------------------
class BackTick extends Quote
  @extend(false)
  pair: ['`', '`']

class ABackTick extends BackTick
  @extend()

class InnerBackTick extends BackTick
  @extend()

# Pair expands multi-lines
# -------------------------
class CurlyBracket extends Pair
  @extend(false)
  pair: ['{', '}']
  allowNextLine: true

class ACurlyBracket extends CurlyBracket
  @extend()

class InnerCurlyBracket extends CurlyBracket
  @extend()

class ACurlyBracketAllowForwarding extends CurlyBracket
  @extend()
  allowForwarding: true

class InnerCurlyBracketAllowForwarding extends CurlyBracket
  @extend()
  allowForwarding: true

# -------------------------
class SquareBracket extends Pair
  @extend(false)
  pair: ['[', ']']
  allowNextLine: true

class ASquareBracket extends SquareBracket
  @extend()

class InnerSquareBracket extends SquareBracket
  @extend()

class ASquareBracketAllowForwarding extends SquareBracket
  @extend()
  allowForwarding: true

class InnerSquareBracketAllowForwarding extends SquareBracket
  @extend()
  allowForwarding: true

# -------------------------
class Parenthesis extends Pair
  @extend(false)
  pair: ['(', ')']
  allowNextLine: true

class AParenthesis extends Parenthesis
  @extend()

class InnerParenthesis extends Parenthesis
  @extend()

class AParenthesisAllowForwarding extends Parenthesis
  @extend()
  allowForwarding: true

class InnerParenthesisAllowForwarding extends Parenthesis
  @extend()
  allowForwarding: true

# -------------------------
class AngleBracket extends Pair
  @extend(false)
  pair: ['<', '>']

class AAngleBracket extends AngleBracket
  @extend()

class InnerAngleBracket extends AngleBracket
  @extend()

class AAngleBracketAllowForwarding extends AngleBracket
  @extend()
  allowForwarding: true

class InnerAngleBracketAllowForwarding extends AngleBracket
  @extend()
  allowForwarding: true

# -------------------------
tagPattern = /(<(\/?))([^\s>]+)[^>]*>/g
class Tag extends Pair
  @extend(false)
  allowNextLine: true
  allowForwarding: true
  adjustInnerRange: false
  getPattern: ->
    tagPattern

  getPairState: ({match, matchText}) ->
    [__, __, slash, tagName] = match
    if slash is ''
      ['open', tagName]
    else
      ['close', tagName]

  getTagStartPoint: (from) ->
    tagRange = null
    scanRange = @editor.bufferRangeForBufferRow(from.row)
    @editor.scanInBufferRange tagPattern, scanRange, ({range, stop}) ->
      if range.containsPoint(from, true)
        tagRange = range
        stop()
    tagRange?.start ? from

  findTagState: (stack, tagState) ->
    return null if stack.length is 0
    for i in [(stack.length - 1)..0]
      entry = stack[i]
      if entry.tagState is tagState
        return entry
    null

  findOpen: (from,  pattern) ->
    scanFunc = 'backwardsScanInBufferRange'
    scanRange = new Range([0, 0], from)
    stack = []
    found = null
    @findPair 'open', {from, pattern, scanFunc, scanRange}, (event) =>
      {range, stop} = event
      [pairState, tagName] = @getPairState(event)
      if pairState is 'close'
        tagState = pairState + tagName
        stack.push({tagState, range})
      else
        if entry = @findTagState(stack, "close#{tagName}")
          stack = stack[0...stack.indexOf(entry)]
        if stack.length is 0
          found = range
      stop() if found?
    found

  findClose: (from,  pattern) ->
    scanFunc = 'scanInBufferRange'
    from = @getTagStartPoint(from)
    scanRange = new Range(from, @editor.buffer.getEndPosition())
    stack = []
    found = null
    @findPair 'close', {from, pattern, scanFunc, scanRange}, (event) =>
      {range, stop} = event
      [pairState, tagName] = @getPairState(event)
      if pairState is 'open'
        tagState = pairState + tagName
        stack.push({tagState, range})
      else
        if entry = @findTagState(stack, "open#{tagName}")
          stack = stack[0...stack.indexOf(entry)]
        else
          # I'm very torelant for orphan tag like 'br', 'hr', or unclosed tag.
          stack = []
        if stack.length is 0
          if (openStart = entry?.range.start)
            if @allowForwarding
              return if openStart.row > from.row
            else
              return if openStart.isGreaterThan(from)
          found = range
      stop() if found?
    found

class ATag extends Tag
  @extend()

class InnerTag extends Tag
  @extend()

# Paragraph
# -------------------------
# Paragraph is defined as consecutive (non-)blank-line.
class Paragraph extends TextObject
  @extend(false)

  getStartRow: (startRow, fn) ->
    startRow = Math.max(0, startRow)
    for row in [startRow..0] when not fn(row)
      return row + 1
    0

  getEndRow: (startRow, fn) ->
    lastRow = @editor.getLastBufferRow()
    startRow = Math.min(lastRow, startRow)
    for row in [startRow..lastRow] when not fn(row)
      return row - 1
    lastRow

  getRange: (startRow) ->
    isBlank = @editor.isBufferRowBlank.bind(@editor)
    wasBlank = isBlank(startRow)
    fn = (row) -> isBlank(row) is wasBlank
    new Range([@getStartRow(startRow, fn), 0], [@getEndRow(startRow, fn) + 1, 0])

  selectParagraph: (selection, {firstTime}) ->
    [startRow, endRow] = selection.getBufferRowRange()

    if firstTime and not @isMode('visual', 'linewise')
      swrap(selection).setBufferRangeSafely @getRange(startRow)
    else
      point = if selection.isReversed()
        @getRange(startRow - 1)?.start
      else
        @getRange(endRow + 1)?.end
      selection.selectToBufferPosition point if point?

  selectTextObject: (selection) ->
    firstTime = true
    _.times @getCount(), =>
      @selectParagraph(selection, {firstTime})
      firstTime = false
      @selectParagraph(selection, {firstTime}) if @instanceof('AParagraph')

class AParagraph extends Paragraph
  @extend()

class InnerParagraph extends Paragraph
  @extend()

# -------------------------
class Indentation extends Paragraph
  @extend(false)

  getRange: (startRow) ->
    return if @editor.isBufferRowBlank(startRow)
    baseIndentLevel = getIndentLevelForBufferRow(@editor, startRow)
    fn = (row) =>
      if @editor.isBufferRowBlank(row)
        @isA()
      else
        getIndentLevelForBufferRow(@editor, row) >= baseIndentLevel
    new Range([@getStartRow(startRow, fn), 0], [@getEndRow(startRow, fn) + 1, 0])

class AIndentation extends Indentation
  @extend()

class InnerIndentation extends Indentation
  @extend()

# -------------------------
class Comment extends TextObject
  @extend(false)

  selectTextObject: (selection) ->
    row = selection.getBufferRange().start.row
    if rowRange = @getRowRangeForCommentAtBufferRow(row)
      swrap(selection).selectRowRange(rowRange)

  getRowRangeForCommentAtBufferRow: (row) ->
    switch
      when rowRange = @editor.languageMode.rowRangeForCommentAtBufferRow(row)
        rowRange
      when @editor.isBufferRowCommented(row)
        [row, row]

class AComment extends Comment
  @extend()

class InnerComment extends Comment
  @extend()

# -------------------------
class Fold extends TextObject
  @extend(false)

  adjustRowRange: ([startRow, endRow]) ->
    return [startRow, endRow] unless @isInner()
    startRowIndentLevel = getIndentLevelForBufferRow(@editor, startRow)
    endRowIndentLevel = getIndentLevelForBufferRow(@editor, endRow)
    endRow -= 1 if (startRowIndentLevel is endRowIndentLevel)
    startRow += 1
    [startRow, endRow]

  getFoldRowRangesContainsForRow: (row) ->
    getCodeFoldRowRangesContainesForRow(@editor, row, true)?.reverse()

  selectTextObject: (selection) ->
    range = selection.getBufferRange()
    rowRanges = @getFoldRowRangesContainsForRow(range.start.row)
    return unless rowRanges?

    if (rowRange = rowRanges.shift())?
      rowRange = @adjustRowRange(rowRange)
      targetRange = getBufferRangeForRowRange(@editor, rowRange)
      if targetRange.isEqual(range) and rowRanges.length
        rowRange = @adjustRowRange(rowRanges.shift())
    if rowRange?
      swrap(selection).selectRowRange(rowRange)

class AFold extends Fold
  @extend()

class InnerFold extends Fold
  @extend()

# -------------------------
# NOTE: Function range determination is depending on fold.
class Function extends Fold
  @extend(false)

  # Some language don't include closing `}` into fold.
  omittingClosingCharLanguages: ['go']

  initialize: ->
    @language = @editor.getGrammar().scopeName.replace(/^source\./, '')

  getFoldRowRangesContainsForRow: (row) ->
    rowRanges = getCodeFoldRowRangesContainesForRow(@editor, row)?.reverse()
    rowRanges?.filter (rowRange) =>
      isIncludeFunctionScopeForRow(@editor, rowRange[0])

  adjustRowRange: (rowRange) ->
    [startRow, endRow] = super
    if @isA() and (@language in @omittingClosingCharLanguages)
      endRow += 1
    [startRow, endRow]

class AFunction extends Function
  @extend()

class InnerFunction extends Function
  @extend()

# -------------------------
class CurrentLine extends TextObject
  @extend(false)
  selectTextObject: (selection) ->
    {cursor} = selection
    cursor.moveToBeginningOfLine()
    cursor.moveToFirstCharacterOfLine() if @isInner()
    selection.selectToEndOfBufferLine()

class ACurrentLine extends CurrentLine
  @extend()

class InnerCurrentLine extends CurrentLine
  @extend()

# -------------------------
class Entire extends TextObject
  @extend(false)
  selectTextObject: (selection) ->
    @editor.selectAll()

class AEntire extends Entire
  @extend()

class InnerEntire extends Entire
  @extend()

# -------------------------
class LatestChange extends TextObject
  @extend(false)
  getRange: ->
    @vimState.mark.getRange('[', ']')

  selectTextObject: (selection) ->
    swrap(selection).setBufferRangeSafely(@getRange())

class ALatestChange extends LatestChange
  @extend()

# No diff from ALatestChange
class InnerLatestChange extends LatestChange
  @extend()

# -------------------------
class SearchMatchForward extends TextObject
  @extend()

  getRange: (selection) ->
    unless pattern = globalState.lastSearchPattern
      return null

    point = selection.getBufferRange().end
    scanRange = [point.row, @getVimEofBufferPosition()]
    found = null
    @editor.scanInBufferRange pattern, scanRange, ({range, stop}) ->
      if range.end.isGreaterThan(point)
        found = range
        stop()
    found

  selectTextObject: (selection) ->
    return unless range = @getRange(selection)

    if selection.isEmpty()
      reversed = @backward
      swrap(selection).setBufferRange(range, {reversed})
      selection.cursor.autoscroll()
    else
      swrap(selection).mergeBufferRange(range)

class SearchMatchBackward extends SearchMatchForward
  @extend()
  backward: true

  getRange: (selection) ->
    unless pattern = globalState.lastSearchPattern
      return null

    point = selection.getBufferRange().start
    scanRange = [[point.row, Infinity], [0, 0]]
    found = null
    @editor.backwardsScanInBufferRange pattern, scanRange, ({range, stop}) ->
      if range.start.isLessThan(point)
        found = range
        stop()
    found

# [FIXME] Currently vB range is treated as vC range, how I should do?
class PreviousSelection extends TextObject
  @extend()
  backward: true

  select: ->
    return unless range = @vimState.mark.getRange('<', '>')
    @editor.getLastSelection().setBufferRange(range)

class MarkedRange extends TextObject
  @extend()
  backward: true

  select: ->
    ranges = @vimState.getRangeMarkers().map((m) -> m.getBufferRange())
    if ranges.length
      @editor.setSelectedBufferRanges(ranges)
