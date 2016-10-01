{Range, Point} = require 'atom'
_ = require 'underscore-plus'

# [TODO] Need overhaul
#  - [ ] must have getRange(selection) ->
#  - [ ] Remove selectTextObject?
#  - [ ] Make expandable by selection.getBufferRange().union(@getRange(selection))
#  - [ ] Count support(priority low)?
Base = require './base'
swrap = require './selection-wrapper'
{
  sortRanges, sortRangesByEndPosition, countChar, pointIsAtEndOfLine,
  getTextToPoint
  getIndentLevelForBufferRow
  getCodeFoldRowRangesContainesForRow
  getBufferRangeForRowRange
  isIncludeFunctionScopeForRow
  getStartPositionForPattern
  getEndPositionForPattern
  getVisibleBufferRange

  trimRange
} = require './utils'

class TextObject extends Base
  @extend(false)
  allowSubmodeChange: true

  constructor: ->
    @constructor::inner = @getName().startsWith('Inner')
    super
    @initialize()

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
    canSelect = true
    stopSelection = ->
      canSelect = false

    @countTimes =>
      for selection in @editor.getSelections() when canSelect
        @selectTextObject(selection, stopSelection)
    @editor.mergeIntersectingSelections()
    @updateSelectionProperties() if @isMode('visual')

  selectTextObject: (selection, stopSelection) ->
    range = @getRange(selection, stopSelection)
    swrap(selection).setBufferRangeSafely(range)

  getRange: ->
    # I want to
    # throw new Error('text-object must respond to range by getRange()!')

# -------------------------
class Word extends TextObject
  @extend(false)

  select: ->
    @vimState.modeManager.normalizeSelections()
    super

  getRange: (selection) ->
    {range, kind} = @getWordBufferRangeAndKindAtBufferPosition(selection.cursor.getBufferPosition(), {@wordRegex})
    if @isA() and kind is 'word'
      range = @expandRangeToWhiteSpaces(range)
    range

  expandRangeToWhiteSpaces: (range) ->
    if newEnd = getEndPositionForPattern(@editor, range.end, /\s+/, containedOnly: true)
      return new Range(range.start, newEnd)

    if newStart = getStartPositionForPattern(@editor, range.start, /\s+/, containedOnly: true)
      # To comform with pure vim, expand as long as it's not indent(white spaces starting with column 0).
      return new Range(newStart, range.end) unless newStart.column is 0

    range # return original range as fallback

class AWord extends Word
  @extend()

class InnerWord extends Word
  @extend()

# -------------------------
class WholeWord extends Word
  @extend(false)
  wordRegex: /\S+/

class AWholeWord extends WholeWord
  @extend()

class InnerWholeWord extends WholeWord
  @extend()

# -------------------------
# Just include _, -
class SmartWord extends Word
  @extend(false)
  wordRegex: /[\w-]+/

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

# -------------------------
class AnyPair extends Pair
  @extend(false)
  allowForwarding: false
  allowNextLine: null
  skipEmptyPair: false
  member: [
    'DoubleQuote', 'SingleQuote', 'BackTick',
    'CurlyBracket', 'AngleBracket', 'Tag', 'SquareBracket', 'Parenthesis'
  ]

  getRangeBy: (klass, selection) ->
    options = {@inner, @skipEmptyPair}
    options.allowNextLine = @allowNextLine if @allowNextLine?
    @new(klass, options).getRange(selection, {@allowForwarding, @searchFrom})

  getRanges: (selection) ->
    (range for klass in @member when (range = @getRangeBy(klass, selection)))

  getRange: (selection) ->
    ranges = @getRanges(selection)
    _.last(sortRanges(ranges)) if ranges.length

class AAnyPair extends AnyPair
  @extend()

class InnerAnyPair extends AnyPair
  @extend()

# -------------------------
class AnyPairAllowForwarding extends AnyPair
  @extend(false)
  @description: "Range surrounded by auto-detected paired chars from enclosed and forwarding area"
  allowForwarding: true
  skipEmptyPair: false
  searchFrom: 'start'
  getRange: (selection) ->
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
  getRange: (selection) ->
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

  getRange: (selection) ->
    @getRangeFromRow(selection.getBufferRange().start.row)

  getRangeFromRow: (startRow) ->
    isBlank = @editor.isBufferRowBlank.bind(@editor)
    wasBlank = isBlank(startRow)
    fn = (row) -> isBlank(row) is wasBlank
    new Range([@getStartRow(startRow, fn), 0], [@getEndRow(startRow, fn) + 1, 0])

  selectParagraph: (selection, {firstTime}) ->
    [startRow, endRow] = selection.getBufferRowRange()

    if firstTime and not @isMode('visual', 'linewise')
      swrap(selection).setBufferRangeSafely @getRange(selection)
    else if not @instanceof('Indentation')
      point = if selection.isReversed()
        @getRangeFromRow(startRow - 1)?.start
      else
        @getRangeFromRow(endRow + 1)?.end
      selection.selectToBufferPosition point if point?

  selectTextObject: (selection) ->
    # FIXME: don't manage count on each child
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

  getRange: (selection) ->
    startRow = selection.getBufferRange().start.row
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

  getRange: (selection) ->
    row = selection.getBufferRange().start.row
    rowRange = @editor.languageMode.rowRangeForCommentAtBufferRow(row)
    rowRange ?= [row, row] if @editor.isBufferRowCommented(row)

    if rowRange
      getBufferRangeForRowRange(selection.editor, rowRange)

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

  getRange: (selection) ->
    range = selection.getBufferRange()
    rowRanges = @getFoldRowRangesContainsForRow(range.start.row)
    return unless rowRanges.length

    if (rowRange = rowRanges.shift())?
      rowRange = @adjustRowRange(rowRange)
      targetRange = getBufferRangeForRowRange(@editor, rowRange)
      if targetRange.isEqual(range) and rowRanges.length
        rowRange = @adjustRowRange(rowRanges.shift())

    getBufferRangeForRowRange(@editor, rowRange)

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
    super
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
  getRange: (selection) ->
    {cursor} = selection
    range = cursor.getCurrentLineBufferRange()
    if @isA()
      range
    else
      trimRange(@editor, range)

class ACurrentLine extends CurrentLine
  @extend()

class InnerCurrentLine extends CurrentLine
  @extend()

# -------------------------
class Entire extends TextObject
  @extend(false)
  getRange: (selection, stopSelection) ->
    stopSelection()
    @editor.buffer.getRange()

class AEntire extends Entire
  @extend()

class InnerEntire extends Entire
  @extend()

# Alias as accessible name
class All extends Entire
  @extend(false)

# -------------------------
class Empty extends TextObject
  @extend(false)

# -------------------------
class LatestChange extends TextObject
  @extend(false)
  getRange: ->
    @vimState.mark.getRange('[', ']')

class ALatestChange extends LatestChange
  @extend()

# No diff from ALatestChange
class InnerLatestChange extends LatestChange
  @extend()

# -------------------------
class SearchMatchForward extends TextObject
  @extend()

  getRange: (selection) ->
    unless pattern = @globalState.get('lastSearchPattern')
      return null

    scanStart = selection.getBufferRange().end
    scanRange = [[scanStart.row, 0], @getVimEofBufferPosition()]
    found = null
    @editor.scanInBufferRange pattern, scanRange, ({range, stop}) ->
      if range.end.isGreaterThan(scanStart)
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
    unless pattern = @globalState.get('lastSearchPattern')
      return null

    scanStart = selection.getBufferRange().start
    scanRange = [[scanStart.row, Infinity], [0, 0]]
    found = null
    @editor.backwardsScanInBufferRange pattern, scanRange, ({range, stop}) ->
      if range.start.isLessThan(scanStart)
        found = range
        stop()
    found

# [Limitation: won't fix]: Selected range is not submode aware. always characterwise.
# So even if original selection was vL or vB, selected range by this text-object
# is always vC range.
class PreviousSelection extends TextObject
  @extend()
  select: ->
    {properties, @submode} = @vimState.previousSelection
    if properties? and @submode?
      selection = @editor.getLastSelection()
      swrap(selection).selectByProperties(properties)

class PersistentSelection extends TextObject
  @extend(false)

  select: ->
    ranges = @vimState.persistentSelection.getMarkerBufferRanges()
    if ranges.length
      @editor.setSelectedBufferRanges(ranges)
    @vimState.clearPersistentSelections()

class APersistentSelection extends PersistentSelection
  @extend()

class InnerPersistentSelection extends PersistentSelection
  @extend()

# -------------------------
class VisibleArea extends TextObject # 822 to 863
  @extend(false)

  getRange: (selection) ->
    range = getVisibleBufferRange(selection.editor)
    # [BUG?] Need translate to shilnk top and bottom to fit actual row.
    # The reason I need -2 at bottom is because of status bar?
    range.translate([+1, 0], [-3, 0])

class AVisibleArea extends VisibleArea
  @extend()

class InnerVisibleArea extends VisibleArea
  @extend()

# Meta text object
# -------------------------
class UnionTextObject extends TextObject
  @extend(false)
  member: []

  getRange: (selection) ->
    unionRange = null
    for member in @member when range = @new(member).getRange(selection)
      if unionRange?
        unionRange = unionRange.union(range)
      else
        unionRange = range
    unionRange

class AFunctionOrInnerParagraph extends UnionTextObject
  @extend()
  member: ['AFunction', 'InnerParagraph']


# FIXME: make Motion.CurrentSelection to TextObject then use concatTextObject
class ACurrentSelectionAndAPersistentSelection extends TextObject
  @extend()
  select: ->
    pesistentRanges = @vimState.getPersistentSelectionBuffferRanges()
    selectedRanges = @editor.getSelectedBufferRanges()
    ranges = pesistentRanges.concat(selectedRanges)

    if ranges.length
      @editor.setSelectedBufferRanges(ranges)
    @vimState.clearPersistentSelections()
    @editor.mergeIntersectingSelections()

# -------------------------
# Not used currently
class TextObjectFirstFound extends TextObject
  @extend(false)
  member: []
  memberOptoins: {allowNextLine: false}

  getRangeBy: (klass, selection) ->
    @new(klass, @memberOptoins).getRange(selection)

  getRanges: (selection) ->
    (range for klass in @member when (range = @getRangeBy(klass, selection)))

  getRange: (selection) ->
    for member in @member when range = @getRangeBy(member, selection)
      return range
