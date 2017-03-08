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
  getLineTextToBufferPosition
  getIndentLevelForBufferRow
  getCodeFoldRowRangesContainesForRow
  getBufferRangeForRowRange
  isIncludeFunctionScopeForRow
  expandRangeToWhiteSpaces
  getVisibleBufferRange
  translatePointAndClip
  getBufferRows
  getValidVimBufferRow
  trimRange

  sortRanges
  pointIsAtEndOfLine
} = require './utils'
{BracketFinder, QuoteFinder, TagFinder} = require './pair-finder.coffee'

class TextObject extends Base
  @extend(false)
  wise: null
  supportCount: false # FIXME #472, #66

  constructor: ->
    @constructor::inner = @getName().startsWith('Inner')
    super
    @initialize()

  isInner: ->
    @inner

  isA: ->
    not @isInner()

  isSuportCount: ->
    @supportCount

  getWise: ->
    if @wise? and @getOperator().isOccurrence()
      'characterwise'
    else
      @wise

  isCharacterwise: ->
    @getWise() is 'characterwise'

  isLinewise: ->
    @getWise() is 'linewise'

  isBlockwise: ->
    @getWise() is 'blockwise'

  getNormalizedHeadBufferPosition: (selection) ->
    head = selection.getHeadBufferPosition()
    if @isMode('visual') and not selection.isReversed()
      head = translatePointAndClip(@editor, head, 'backward')
    head

  getNormalizedHeadScreenPosition: (selection) ->
    bufferPosition = @getNormalizedHeadBufferPosition(selection)
    @editor.screenPositionForBufferPosition(bufferPosition)

  needToKeepColumn: ->
    @wise is 'linewise' and
      @getConfig('keepColumnOnSelectTextObject') and
      @getOperator().instanceof('Select')

  execute: ->
    # Whennever TextObject is executed, it has @operator
    # Called from Operator::selectTarget()
    #  - `v i p`, is `Select` operator with @target = `InnerParagraph`.
    #  - `d i p`, is `Delete` operator with @target = `InnerParagraph`.
    if @operator?
      @select()
    else
      throw new Error('in TextObject: Must not happen')

  select: ->
    selectResults = []
    @countTimes @getCount(), ({stop}) =>
      @stopSelection = stop

      for selection in @editor.getSelections()
        selectResults.push(@selectTextObject(selection))

      unless @isSuportCount()
        stop() # FIXME: quick-fix for #560

    if @needToKeepColumn()
      for selection in @editor.getSelections()
        swrap(selection).clipPropertiesTillEndOfLine()

    @editor.mergeIntersectingSelections()
    if selectResults.some((value) -> value)
      @wise ?= swrap.detectWise(@editor)
    else
      @wise = null

  selectTextObject: (selection) ->
    if range = @getRange(selection)
      oldRange = selection.getBufferRange()

      needToKeepColumn = @needToKeepColumn()
      if needToKeepColumn and not @isMode('visual', 'linewise')
        @vimState.modeManager.activate('visual', 'linewise')

      # Prevent autoscroll to closing char on `change-surround-any-pair`.
      options = {
        autoscroll: selection.isLastSelection() and not @getOperator().supportEarlySelect
        keepGoalColumn: needToKeepColumn
      }
      swrap(selection).setBufferRangeSafely(range, options)

      newRange = selection.getBufferRange()
      if newRange.isEqual(oldRange)
        @stopSelection() # FIXME: quick-fix for #560

      true
    else
      @stopSelection() # FIXME: quick-fix for #560
      false

  getRange: ->
    # I want to
    # throw new Error('text-object must respond to range by getRange()!')

# -------------------------
class Word extends TextObject
  @extend(false)

  getRange: (selection) ->
    point = @getNormalizedHeadBufferPosition(selection)
    {range} = @getWordBufferRangeAndKindAtBufferPosition(point, {@wordRegex})
    if @isA()
      expandRangeToWhiteSpaces(@editor, range)
    else
      range

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
# Just include _, -
class Subword extends Word
  @extend(false)
  getRange: (selection) ->
    @wordRegex = selection.cursor.subwordRegExp()
    super

class ASubword extends Subword
  @extend()
class InnerSubword extends Subword
  @extend()

# -------------------------
class Pair extends TextObject
  @extend(false)
  allowNextLine: null
  adjustInnerRange: true
  pair: null
  wise: 'characterwise'
  supportCount: true

  isAllowNextLine: ->
    @allowNextLine ? (@pair? and @pair[0] isnt @pair[1])

  constructor: ->
    # auto-set property from class name.
    @allowForwarding ?= @getName().endsWith('AllowForwarding')
    super

  adjustRange: ({start, end}) ->
    # Dirty work to feel natural for human, to behave compatible with pure Vim.
    # Where this adjustment appear is in following situation.
    # op-1: `ci{` replace only 2nd line
    # op-2: `di{` delete only 2nd line.
    # text:
    #  {
    #    aaa
    #  }
    if pointIsAtEndOfLine(@editor, start)
      start = start.traverse([1, 0])

    if getLineTextToBufferPosition(@editor, end).match(/^\s*$/)
      if @isMode('visual')
        # This is slightly innconsistent with regular Vim
        # - regular Vim: select new line after EOL
        # - vim-mode-plus: select to EOL(before new line)
        # This is intentional since to make submode `characterwise` when auto-detect submode
        # innerEnd = new Point(innerEnd.row - 1, Infinity)
        end = new Point(end.row - 1, Infinity)
      else
        end = new Point(end.row, 0)

    new Range(start, end)

  getFinder: ->
    options = {allowNextLine: @isAllowNextLine(), @allowForwarding, @pair}
    if @pair[0] is @pair[1]
      new QuoteFinder(@editor, options)
    else
      new BracketFinder(@editor, options)

  getPairInfo: (from) ->
    pairInfo = @getFinder().find(from)
    unless pairInfo?
      return null
    pairInfo.innerRange = @adjustRange(pairInfo.innerRange) if @adjustInnerRange
    pairInfo.targetRange = if @isInner() then pairInfo.innerRange else pairInfo.aRange
    pairInfo

  getPointToSearchFrom: (selection, searchFrom) ->
    switch searchFrom
      when 'head' then @getNormalizedHeadBufferPosition(selection)
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

# Used by DeleteSurround
class APair extends Pair
  @extend(false)

# -------------------------
class AnyPair extends Pair
  @extend(false)
  allowForwarding: false
  member: [
    'DoubleQuote', 'SingleQuote', 'BackTick',
    'CurlyBracket', 'AngleBracket', 'SquareBracket', 'Parenthesis'
  ]

  getRangeBy: (klass, selection) ->
    @new(klass).getRange(selection, {@allowForwarding, @searchFrom})

  getRanges: (selection) ->
    prefix = if @isInner() then 'Inner' else 'A'
    ranges = []
    for klass in @member when range = @getRangeBy(prefix + klass, selection)
      ranges.push(range)
    ranges

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

# -------------------------
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

class ACurlyBracket extends CurlyBracket
  @extend()
class InnerCurlyBracket extends CurlyBracket
  @extend()
class ACurlyBracketAllowForwarding extends CurlyBracket
  @extend()
class InnerCurlyBracketAllowForwarding extends CurlyBracket
  @extend()

# -------------------------
class SquareBracket extends Pair
  @extend(false)
  pair: ['[', ']']

class ASquareBracket extends SquareBracket
  @extend()
class InnerSquareBracket extends SquareBracket
  @extend()
class ASquareBracketAllowForwarding extends SquareBracket
  @extend()
class InnerSquareBracketAllowForwarding extends SquareBracket
  @extend()

# -------------------------
class Parenthesis extends Pair
  @extend(false)
  pair: ['(', ')']

class AParenthesis extends Parenthesis
  @extend()
class InnerParenthesis extends Parenthesis
  @extend()
class AParenthesisAllowForwarding extends Parenthesis
  @extend()
class InnerParenthesisAllowForwarding extends Parenthesis
  @extend()

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
class InnerAngleBracketAllowForwarding extends AngleBracket
  @extend()

# Tag
# -------------------------
class Tag extends Pair
  @extend(false)
  allowNextLine: true
  allowForwarding: true
  adjustInnerRange: false

  getTagStartPoint: (from) ->
    tagRange = null
    pattern = TagFinder::pattern
    @scanForward pattern, {from: [from.row, 0]}, ({range, stop}) ->
      if range.containsPoint(from, true)
        tagRange = range
        stop()
    tagRange?.start

  getFinder: ->
    new TagFinder(@editor, {allowNextLine: @isAllowNextLine(), @allowForwarding})

  getPairInfo: (from) ->
    super(@getTagStartPoint(from) ? from)

class ATag extends Tag
  @extend()
class InnerTag extends Tag
  @extend()

# Paragraph
# -------------------------
# Paragraph is defined as consecutive (non-)blank-line.
class Paragraph extends TextObject
  @extend(false)
  wise: 'linewise'
  supportCount: true

  findRow: (fromRow, direction, fn) ->
    fn.reset?()
    foundRow = fromRow
    for row in getBufferRows(@editor, {startRow: fromRow, direction})
      break unless fn(row, direction)
      foundRow = row

    foundRow

  findRowRangeBy: (fromRow, fn) ->
    startRow = @findRow(fromRow, 'previous', fn)
    endRow = @findRow(fromRow, 'next', fn)
    [startRow, endRow]

  getPredictFunction: (fromRow, selection) ->
    fromRowResult = @editor.isBufferRowBlank(fromRow)

    if @isInner()
      predict = (row, direction) =>
        @editor.isBufferRowBlank(row) is fromRowResult
    else
      if selection.isReversed()
        directionToExtend = 'previous'
      else
        directionToExtend = 'next'

      flip = false
      predict = (row, direction) =>
        result = @editor.isBufferRowBlank(row) is fromRowResult
        if flip
          not result
        else
          if (not result) and (direction is directionToExtend)
            flip = true
            return true
          result

      predict.reset = ->
        flip = false
    predict

  getRange: (selection) ->
    originalRange = selection.getBufferRange()
    fromRow = @getNormalizedHeadBufferPosition(selection).row

    if @isMode('visual', 'linewise')
      if selection.isReversed()
        fromRow--
      else
        fromRow++
      fromRow = getValidVimBufferRow(@editor, fromRow)

    rowRange = @findRowRangeBy(fromRow, @getPredictFunction(fromRow, selection))
    selection.getBufferRange().union(getBufferRangeForRowRange(@editor, rowRange))

class AParagraph extends Paragraph
  @extend()
class InnerParagraph extends Paragraph
  @extend()

# -------------------------
class Indentation extends Paragraph
  @extend(false)

  getRange: (selection) ->
    fromRow = @getNormalizedHeadBufferPosition(selection).row

    baseIndentLevel = getIndentLevelForBufferRow(@editor, fromRow)
    predict = (row) =>
      if @editor.isBufferRowBlank(row)
        @isA()
      else
        getIndentLevelForBufferRow(@editor, row) >= baseIndentLevel

    rowRange = @findRowRangeBy(fromRow, predict)
    getBufferRangeForRowRange(@editor, rowRange)

class AIndentation extends Indentation
  @extend()
class InnerIndentation extends Indentation
  @extend()

# -------------------------
class Comment extends TextObject
  @extend(false)
  wise: 'linewise'

  getRange: (selection) ->
    row = swrap(selection).getStartRow()
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
  wise: 'linewise'

  adjustRowRange: (rowRange) ->
    return rowRange unless @isInner()

    [startRow, endRow] = rowRange
    startRowIndentLevel = getIndentLevelForBufferRow(@editor, startRow)
    endRowIndentLevel = getIndentLevelForBufferRow(@editor, endRow)
    endRow -= 1 if (startRowIndentLevel is endRowIndentLevel)
    startRow += 1
    [startRow, endRow]

  getFoldRowRangesContainsForRow: (row) ->
    getCodeFoldRowRangesContainesForRow(@editor, row, includeStartRow: true).reverse()

  getRange: (selection) ->
    rowRanges = @getFoldRowRangesContainsForRow(swrap(selection).getStartRow())
    return unless rowRanges.length

    range = getBufferRangeForRowRange(@editor, @adjustRowRange(rowRanges.shift()))
    if rowRanges.length and range.isEqual(selection.getBufferRange())
      range = getBufferRangeForRowRange(@editor, @adjustRowRange(rowRanges.shift()))
    range

class AFold extends Fold
  @extend()
class InnerFold extends Fold
  @extend()

# -------------------------
# NOTE: Function range determination is depending on fold.
class Function extends Fold
  @extend(false)

  # Some language don't include closing `}` into fold.
  scopeNamesOmittingEndRow: ['source.go', 'source.elixir']

  getFoldRowRangesContainsForRow: (row) ->
    rowRanges = getCodeFoldRowRangesContainesForRow(@editor, row)?.reverse()
    rowRanges?.filter (rowRange) =>
      isIncludeFunctionScopeForRow(@editor, rowRange[0])

  adjustRowRange: (rowRange) ->
    [startRow, endRow] = super
    if @isA() and @editor.getGrammar().scopeName in @scopeNamesOmittingEndRow
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
    row = @getNormalizedHeadBufferPosition(selection).row
    range = @editor.bufferRangeForBufferRow(row)
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

  getRange: (selection) ->
    @stopSelection()
    @editor.buffer.getRange()

class AEntire extends Entire
  @extend()
class InnerEntire extends Entire
  @extend()
class All extends Entire # Alias as accessible name
  @extend(false)

# -------------------------
class Empty extends TextObject
  @extend(false)

# -------------------------
class LatestChange extends TextObject
  @extend(false)
  getRange: ->
    @stopSelection()
    @vimState.mark.getRange('[', ']')

class ALatestChange extends LatestChange
  @extend()
class InnerLatestChange extends LatestChange # No diff from ALatestChange
  @extend()

# -------------------------
class SearchMatchForward extends TextObject
  @extend()
  backward: false

  findMatch: (fromPoint, pattern) ->
    fromPoint = translatePointAndClip(@editor, fromPoint, "forward") if @isMode('visual')
    found = null
    @scanForward pattern, {from: [fromPoint.row, 0]}, ({range, stop}) ->
      if range.end.isGreaterThan(fromPoint)
        found = range
        stop()
    {range: found, whichIsHead: 'end'}

  getRange: (selection) ->
    pattern = @globalState.get('lastSearchPattern')
    return unless pattern?

    fromPoint = selection.getHeadBufferPosition()
    {range, whichIsHead} = @findMatch(fromPoint, pattern)
    if range?
      @unionRangeAndDetermineReversedState(selection, range, whichIsHead)

  unionRangeAndDetermineReversedState: (selection, found, whichIsHead) ->
    if selection.isEmpty()
      found
    else
      head = found[whichIsHead]
      tail = selection.getTailBufferPosition()

      if @backward
        head = translatePointAndClip(@editor, head, 'forward') if tail.isLessThan(head)
      else
        head = translatePointAndClip(@editor, head, 'backward') if head.isLessThan(tail)

      @reversed = head.isLessThan(tail)
      new Range(tail, head).union(swrap(selection).getTailBufferRange())

  selectTextObject: (selection) ->
    return unless range = @getRange(selection)
    swrap(selection).setBufferRange(range, {reversed: @reversed ? @backward})
    selection.cursor.autoscroll()
    true

class SearchMatchBackward extends SearchMatchForward
  @extend()
  backward: true

  findMatch: (fromPoint, pattern) ->
    fromPoint = translatePointAndClip(@editor, fromPoint, "backward") if @isMode('visual')
    found = null
    @scanBackward pattern, {from: [fromPoint.row, Infinity]}, ({range, stop}) ->
      if range.start.isLessThan(fromPoint)
        found = range
        stop()
    {range: found, whichIsHead: 'start'}

# [Limitation: won't fix]: Selected range is not submode aware. always characterwise.
# So even if original selection was vL or vB, selected range by this text-object
# is always vC range.
class PreviousSelection extends TextObject
  @extend()

  select: ->
    {properties, submode} = @vimState.previousSelection
    if properties? and submode?
      selection = @editor.getLastSelection()
      swrap(selection).selectByProperties(properties, keepGoalColumn: false)
      @wise = submode

class PersistentSelection extends TextObject
  @extend(false)

  select: ->
    {persistentSelection} = @vimState
    unless persistentSelection.isEmpty()
      persistentSelection.setSelectedBufferRanges()
      @wise = swrap.detectWise(@editor)

class APersistentSelection extends PersistentSelection
  @extend()
class InnerPersistentSelection extends PersistentSelection
  @extend()

# -------------------------
class VisibleArea extends TextObject # 822 to 863
  @extend(false)

  getRange: (selection) ->
    @stopSelection()
    # [BUG?] Need translate to shilnk top and bottom to fit actual row.
    # The reason I need -2 at bottom is because of status bar?
    bufferRange = getVisibleBufferRange(@editor)
    if bufferRange.getRows() > @editor.getRowsPerPage()
      bufferRange.translate([+1, 0], [-3, 0])
    else
      bufferRange

class AVisibleArea extends VisibleArea
  @extend()
class InnerVisibleArea extends VisibleArea
  @extend()

# -------------------------
# [FIXME] wise mismatch sceenPosition vs bufferPosition
class Edge extends TextObject
  @extend(false)
  wise: 'linewise'

  getRange: (selection) ->
    fromPoint = @getNormalizedHeadScreenPosition(selection)

    moveUpToEdge = @new('MoveUpToEdge')
    moveDownToEdge = @new('MoveDownToEdge')
    return unless moveUpToEdge.isStoppablePoint(fromPoint)

    startScreenPoint = endScreenPoint = null
    startScreenPoint = endScreenPoint = fromPoint if moveUpToEdge.isEdge(fromPoint)

    if moveUpToEdge.isStoppablePoint(fromPoint.translate([-1, 0]))
      startScreenPoint = moveUpToEdge.getPoint(fromPoint)

    if moveDownToEdge.isStoppablePoint(fromPoint.translate([+1, 0]))
      endScreenPoint = moveDownToEdge.getPoint(fromPoint)

    if startScreenPoint? and endScreenPoint?
      screenRange = new Range(startScreenPoint, endScreenPoint)
      range = @editor.bufferRangeForScreenRange(screenRange)
      getBufferRangeForRowRange(@editor, [range.start.row, range.end.row])

class AEdge extends Edge
  @extend()
class InnerEdge extends Edge
  @extend()
