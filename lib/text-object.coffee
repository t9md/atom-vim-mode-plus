{Range, Point} = require 'atom'
_ = require 'underscore-plus'

# [TODO] Need overhaul
#  - [ ] Make expandable by selection.getBufferRange().union(@getRange(selection))
#  - [ ] Count support(priority low)?
Base = require './base'
{
  getLineTextToBufferPosition
  getCodeFoldRowRangesContainesForRow
  isIncludeFunctionScopeForRow
  expandRangeToWhiteSpaces
  getVisibleBufferRange
  translatePointAndClip
  getBufferRows
  getValidVimBufferRow
  trimRange
  sortRanges
  pointIsAtEndOfLine
  splitArguments
  traverseTextFromPoint
} = require './utils'
PairFinder = null

class TextObject extends Base
  @extend(false)
  @operationKind: 'text-object'
  wise: 'characterwise'
  supportCount: false # FIXME #472, #66
  selectOnce: false

  @deriveInnerAndA: ->
    @generateClass("A" + @name, false)
    @generateClass("Inner" + @name, true)

  @deriveInnerAndAForAllowForwarding: ->
    @generateClass("A" + @name + "AllowForwarding", false, true)
    @generateClass("Inner" + @name + "AllowForwarding", true, true)

  @generateClass: (klassName, inner, allowForwarding) ->
    klass = class extends this
    Object.defineProperty klass, 'name', get: -> klassName
    klass::inner = inner
    klass::allowForwarding = true if allowForwarding
    klass.extend()

  constructor: ->
    super
    @initialize()

  isInner: ->
    @inner

  isA: ->
    not @inner

  isLinewise: -> @wise is 'linewise'
  isBlockwise: -> @wise is 'blockwise'

  forceWise: (wise) ->
    @wise = wise # FIXME currently not well supported

  resetState: ->
    @selectSucceeded = null

  execute: ->
    @resetState()

    # Whennever TextObject is executed, it has @operator
    # Called from Operator::selectTarget()
    #  - `v i p`, is `Select` operator with @target = `InnerParagraph`.
    #  - `d i p`, is `Delete` operator with @target = `InnerParagraph`.
    if @operator?
      @select()
    else
      throw new Error('in TextObject: Must not happen')

  select: ->
    if @isMode('visual', 'blockwise')
      @swrap.normalize(@editor)

    @countTimes @getCount(), ({stop}) =>
      stop() unless @supportCount # quick-fix for #560
      for selection in @editor.getSelections()
        oldRange = selection.getBufferRange()
        if @selectTextObject(selection)
          @selectSucceeded = true
        stop() if selection.getBufferRange().isEqual(oldRange)
        break if @selectOnce

    @editor.mergeIntersectingSelections()
    # Some TextObject's wise is NOT deterministic. It has to be detected from selected range.
    @wise ?= @swrap.detectWise(@editor)

    if @mode is 'visual'
      if @selectSucceeded
        switch @wise
          when 'characterwise'
            $selection.saveProperties() for $selection in @swrap.getSelections(@editor)
          when 'linewise'
            # When target is persistent-selection, new selection is added after selectTextObject.
            # So we have to assure all selection have selction property.
            # Maybe this logic can be moved to operation stack.
            for $selection in @swrap.getSelections(@editor)
              if @getConfig('keepColumnOnSelectTextObject')
                $selection.saveProperties() unless $selection.hasProperties()
              else
                $selection.saveProperties()
              $selection.fixPropertyRowToRowRange()

      if @submode is 'blockwise'
        for $selection in @swrap.getSelections(@editor)
          $selection.normalize()
          $selection.applyWise('blockwise')

  # Return true or false
  selectTextObject: (selection) ->
    if range = @getRange(selection)
      @swrap(selection).setBufferRange(range)
      return true

  # to override
  getRange: (selection) ->
    null

# Section: Word
# =========================
class Word extends TextObject
  @extend(false)
  @deriveInnerAndA()

  getRange: (selection) ->
    point = @getCursorPositionForSelection(selection)
    {range} = @getWordBufferRangeAndKindAtBufferPosition(point, {@wordRegex})
    if @isA()
      expandRangeToWhiteSpaces(@editor, range)
    else
      range

class WholeWord extends Word
  @extend(false)
  @deriveInnerAndA()
  wordRegex: /\S+/

# Just include _, -
class SmartWord extends Word
  @extend(false)
  @deriveInnerAndA()
  @description: "A word that consists of alphanumeric chars(`/[A-Za-z0-9_]/`) and hyphen `-`"
  wordRegex: /[\w-]+/

# Just include _, -
class Subword extends Word
  @extend(false)
  @deriveInnerAndA()
  getRange: (selection) ->
    @wordRegex = selection.cursor.subwordRegExp()
    super

# Section: Pair
# =========================
class Pair extends TextObject
  @extend(false)
  supportCount: true
  allowNextLine: null
  adjustInnerRange: true
  pair: null
  inclusive: true

  initialize: ->
    PairFinder ?= require './pair-finder.coffee'
    super


  isAllowNextLine: ->
    @allowNextLine ? (@pair? and @pair[0] isnt @pair[1])

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
      if @mode is 'visual'
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
    options = {allowNextLine: @isAllowNextLine(), @allowForwarding, @pair, @inclusive}
    if @pair[0] is @pair[1]
      new PairFinder.QuoteFinder(@editor, options)
    else
      new PairFinder.BracketFinder(@editor, options)

  getPairInfo: (from) ->
    pairInfo = @getFinder().find(from)
    unless pairInfo?
      return null
    pairInfo.innerRange = @adjustRange(pairInfo.innerRange) if @adjustInnerRange
    pairInfo.targetRange = if @isInner() then pairInfo.innerRange else pairInfo.aRange
    pairInfo

  getRange: (selection) ->
    originalRange = selection.getBufferRange()
    pairInfo = @getPairInfo(@getCursorPositionForSelection(selection))
    # When range was same, try to expand range
    if pairInfo?.targetRange.isEqual(originalRange)
      pairInfo = @getPairInfo(pairInfo.aRange.end)
    pairInfo?.targetRange

# Used by DeleteSurround
class APair extends Pair
  @extend(false)

class AnyPair extends Pair
  @extend(false)
  @deriveInnerAndA()
  allowForwarding: false
  member: [
    'DoubleQuote', 'SingleQuote', 'BackTick',
    'CurlyBracket', 'AngleBracket', 'SquareBracket', 'Parenthesis'
  ]

  getRanges: (selection) ->
    @member
      .map (klass) => @new(klass, {@inner, @allowForwarding, @inclusive}).getRange(selection)
      .filter (range) -> range?

  getRange: (selection) ->
    _.last(sortRanges(@getRanges(selection)))

class AnyPairAllowForwarding extends AnyPair
  @extend(false)
  @deriveInnerAndA()
  @description: "Range surrounded by auto-detected paired chars from enclosed and forwarding area"
  allowForwarding: true
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

class AnyQuote extends AnyPair
  @extend(false)
  @deriveInnerAndA()
  allowForwarding: true
  member: ['DoubleQuote', 'SingleQuote', 'BackTick']
  getRange: (selection) ->
    ranges = @getRanges(selection)
    # Pick range which end.colum is leftmost(mean, closed first)
    _.first(_.sortBy(ranges, (r) -> r.end.column)) if ranges.length

class Quote extends Pair
  @extend(false)
  allowForwarding: true

class DoubleQuote extends Quote
  @extend(false)
  @deriveInnerAndA()
  pair: ['"', '"']

class SingleQuote extends Quote
  @extend(false)
  @deriveInnerAndA()
  pair: ["'", "'"]

class BackTick extends Quote
  @extend(false)
  @deriveInnerAndA()
  pair: ['`', '`']

class CurlyBracket extends Pair
  @extend(false)
  @deriveInnerAndA()
  @deriveInnerAndAForAllowForwarding()
  pair: ['{', '}']

class SquareBracket extends Pair
  @extend(false)
  @deriveInnerAndA()
  @deriveInnerAndAForAllowForwarding()
  pair: ['[', ']']

class Parenthesis extends Pair
  @extend(false)
  @deriveInnerAndA()
  @deriveInnerAndAForAllowForwarding()
  pair: ['(', ')']

class AngleBracket extends Pair
  @extend(false)
  @deriveInnerAndA()
  @deriveInnerAndAForAllowForwarding()
  pair: ['<', '>']

class Tag extends Pair
  @extend(false)
  @deriveInnerAndA()
  allowNextLine: true
  allowForwarding: true
  adjustInnerRange: false

  getTagStartPoint: (from) ->
    tagRange = null
    pattern = PairFinder.TagFinder::pattern
    @scanForward pattern, {from: [from.row, 0]}, ({range, stop}) ->
      if range.containsPoint(from, true)
        tagRange = range
        stop()
    tagRange?.start

  getFinder: ->
    new PairFinder.TagFinder(@editor, {allowNextLine: @isAllowNextLine(), @allowForwarding, @inclusive})

  getPairInfo: (from) ->
    super(@getTagStartPoint(from) ? from)

# Section: Paragraph
# =========================
# Paragraph is defined as consecutive (non-)blank-line.
class Paragraph extends TextObject
  @extend(false)
  @deriveInnerAndA()
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
    fromRow = @getCursorPositionForSelection(selection).row
    if @isMode('visual', 'linewise')
      if selection.isReversed()
        fromRow--
      else
        fromRow++
      fromRow = getValidVimBufferRow(@editor, fromRow)

    rowRange = @findRowRangeBy(fromRow, @getPredictFunction(fromRow, selection))
    selection.getBufferRange().union(@getBufferRangeForRowRange(rowRange))

class Indentation extends Paragraph
  @extend(false)
  @deriveInnerAndA()

  getRange: (selection) ->
    fromRow = @getCursorPositionForSelection(selection).row

    baseIndentLevel = @getIndentLevelForBufferRow(fromRow)
    predict = (row) =>
      if @editor.isBufferRowBlank(row)
        @isA()
      else
        @getIndentLevelForBufferRow(row) >= baseIndentLevel

    rowRange = @findRowRangeBy(fromRow, predict)
    @getBufferRangeForRowRange(rowRange)

# Section: Comment
# =========================
class Comment extends TextObject
  @extend(false)
  @deriveInnerAndA()
  wise: 'linewise'

  getRange: (selection) ->
    row = @getCursorPositionForSelection(selection).row
    rowRange = @editor.languageMode.rowRangeForCommentAtBufferRow(row)
    rowRange ?= [row, row] if @editor.isBufferRowCommented(row)
    if rowRange?
      @getBufferRangeForRowRange(rowRange)

class CommentOrParagraph extends TextObject
  @extend(false)
  @deriveInnerAndA()
  wise: 'linewise'

  getRange: (selection) ->
    for klass in ['Comment', 'Paragraph']
      if range = @new(klass, {@inner}).getRange(selection)
        return range

# Section: Fold
# =========================
class Fold extends TextObject
  @extend(false)
  @deriveInnerAndA()
  wise: 'linewise'

  adjustRowRange: (rowRange) ->
    return rowRange if @isA()

    [startRow, endRow] = rowRange
    if @getIndentLevelForBufferRow(startRow) is @getIndentLevelForBufferRow(endRow)
      endRow -= 1
    startRow += 1
    [startRow, endRow]

  getFoldRowRangesContainsForRow: (row) ->
    getCodeFoldRowRangesContainesForRow(@editor, row).reverse()

  getRange: (selection) ->
    row = @getCursorPositionForSelection(selection).row
    selectedRange = selection.getBufferRange()
    for rowRange in @getFoldRowRangesContainsForRow(row)
      range = @getBufferRangeForRowRange(@adjustRowRange(rowRange))

      # Don't change to `if range.containsRange(selectedRange, true)`
      # There is behavior diff when cursor is at beginning of line( column 0 ).
      unless selectedRange.containsRange(range)
        return range

# NOTE: Function range determination is depending on fold.
class Function extends Fold
  @extend(false)
  @deriveInnerAndA()
  # Some language don't include closing `}` into fold.
  scopeNamesOmittingEndRow: ['source.go', 'source.elixir']

  isGrammarNotFoldEndRow: ->
    {scopeName, packageName} = @editor.getGrammar()
    if scopeName in @scopeNamesOmittingEndRow
      true
    else
      # HACK: Rust have two package `language-rust` and `atom-language-rust`
      # language-rust don't fold ending `}`, but atom-language-rust does.
      scopeName is 'source.rust' and packageName is "language-rust"

  getFoldRowRangesContainsForRow: (row) ->
    (super).filter (rowRange) =>
      isIncludeFunctionScopeForRow(@editor, rowRange[0])

  adjustRowRange: (rowRange) ->
    [startRow, endRow] = super
    # NOTE: This adjustment shoud not be necessary if language-syntax is properly defined.
    if @isA() and @isGrammarNotFoldEndRow()
      endRow += 1
    [startRow, endRow]

# Section: Other
# =========================
class Arguments extends TextObject
  @extend(false)
  @deriveInnerAndA()

  newArgInfo: (argStart, arg, separator) ->
    argEnd = traverseTextFromPoint(argStart, arg)
    argRange = new Range(argStart, argEnd)

    separatorEnd = traverseTextFromPoint(argEnd, separator ? '')
    separatorRange = new Range(argEnd, separatorEnd)

    innerRange = argRange
    aRange = argRange.union(separatorRange)
    {argRange, separatorRange, innerRange, aRange}

  getArgumentsRangeForSelection: (selection) ->
    member = [
      'CurlyBracket'
      'SquareBracket'
      'Parenthesis'
    ]
    @new("InnerAnyPair", {inclusive: false, member: member}).getRange(selection)

  getRange: (selection) ->
    range = @getArgumentsRangeForSelection(selection)
    pairRangeFound = range?
    range ?= @new("InnerCurrentLine").getRange(selection) # fallback
    return unless range

    range = trimRange(@editor, range)

    text = @editor.getTextInBufferRange(range)
    allTokens = splitArguments(text, pairRangeFound)

    argInfos = []
    argStart = range.start

    # Skip starting separator
    if allTokens.length and allTokens[0].type is 'separator'
      token = allTokens.shift()
      argStart = traverseTextFromPoint(argStart, token.text)

    while allTokens.length
      token = allTokens.shift()
      if token.type is 'argument'
        separator = allTokens.shift()?.text
        argInfo = @newArgInfo(argStart, token.text, separator)

        if (allTokens.length is 0) and (lastArgInfo = _.last(argInfos))
          argInfo.aRange = argInfo.argRange.union(lastArgInfo.separatorRange)

        argStart = argInfo.aRange.end
        argInfos.push(argInfo)
      else
        throw new Error('must not happen')

    point = @getCursorPositionForSelection(selection)
    for {innerRange, aRange} in argInfos
      if innerRange.end.isGreaterThanOrEqual(point)
        return if @isInner() then innerRange else aRange
    null

class CurrentLine extends TextObject
  @extend(false)
  @deriveInnerAndA()

  getRange: (selection) ->
    row = @getCursorPositionForSelection(selection).row
    range = @editor.bufferRangeForBufferRow(row)
    if @isA()
      range
    else
      trimRange(@editor, range)

class Entire extends TextObject
  @extend(false)
  @deriveInnerAndA()
  wise: 'linewise'
  selectOnce: true

  getRange: (selection) ->
    @editor.buffer.getRange()

class Empty extends TextObject
  @extend(false)
  selectOnce: true

class LatestChange extends TextObject
  @extend(false)
  @deriveInnerAndA()
  wise: null
  selectOnce: true
  getRange: (selection) ->
    start = @vimState.mark.get('[')
    end = @vimState.mark.get(']')
    if start? and end?
      new Range(start, end)

class SearchMatchForward extends TextObject
  @extend()
  backward: false

  findMatch: (fromPoint, pattern) ->
    fromPoint = translatePointAndClip(@editor, fromPoint, "forward") if (@mode is 'visual')
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
      new Range(tail, head).union(@swrap(selection).getTailBufferRange())

  selectTextObject: (selection) ->
    if range = @getRange(selection)
      @swrap(selection).setBufferRange(range, {reversed: @reversed ? @backward})
      return true

class SearchMatchBackward extends SearchMatchForward
  @extend()
  backward: true

  findMatch: (fromPoint, pattern) ->
    fromPoint = translatePointAndClip(@editor, fromPoint, "backward") if (@mode is 'visual')
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
  wise: null
  selectOnce: true

  selectTextObject: (selection) ->
    {properties, submode} = @vimState.previousSelection
    if properties? and submode?
      @wise = submode
      @swrap(@editor.getLastSelection()).selectByProperties(properties)
      return true

class PersistentSelection extends TextObject
  @extend(false)
  @deriveInnerAndA()
  wise: null
  selectOnce: true

  selectTextObject: (selection) ->
    if @vimState.hasPersistentSelections()
      @vimState.persistentSelection.setSelectedBufferRanges()
      return true

class VisibleArea extends TextObject
  @extend(false)
  @deriveInnerAndA()
  selectOnce: true

  getRange: (selection) ->
    # [BUG?] Need translate to shilnk top and bottom to fit actual row.
    # The reason I need -2 at bottom is because of status bar?
    bufferRange = getVisibleBufferRange(@editor)
    if bufferRange.getRows() > @editor.getRowsPerPage()
      bufferRange.translate([+1, 0], [-3, 0])
    else
      bufferRange
