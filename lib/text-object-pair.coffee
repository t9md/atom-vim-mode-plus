{Range, Point} = require 'atom'
_ = require 'underscore-plus'
swrap = require './selection-wrapper'

TextObject = require('./base').getClass('TextObject')
{
  sortRanges
  countChar
  pointIsAtEndOfLine
  getLineTextToBufferPosition
} = require './utils'

pairStateInBufferRange = (editor, {matchText, range}) ->
  matchText = _.escapeRegExp(matchText)
  backslash = _.escapeRegExp('\\')
  patterns = [
    "#{backslash}#{backslash}#{matchText}"
    "[^#{backslash}]?#{matchText}"
  ]
  pattern = new RegExp(patterns.join('|'))
  lineText = getLineTextToBufferPosition(editor, range.end)
  charCount = countChar(lineText, pattern)
  if charCount % 2 is 0
    'close'
  else
    'open'

getQuotePairRule = (char) ->
  pattern: ///(#{_.escapeRegExp(char)})///g
  getPairState: pairStateInBufferRange

getBracketPairRule = (open, close) ->
  pattern: ///(#{_.escapeRegExp(open)})|(#{_.escapeRegExp(close)})///g
  getPairState: (editor, {match}) ->
    switch
      when match[1] then 'open'
      when match[2] then 'close'

getRuleForPair = (editor, pair) ->
  [open, close] = pair
  if open is close
    getQuotePairRule(open)
  else
    getBracketPairRule(open, close)

findPairRange = (which, direction, options, fn) ->
  {editor, from, pair, filters, allowNextLine} = options
  switch direction
    when 'forward'
      scanRange = new Range(from, editor.buffer.getEndPosition())
      scanFunctionName = 'scanInBufferRange'
    when 'backward'
      scanRange = new Range([0, 0], from)
      scanFunctionName = 'backwardsScanInBufferRange'

  stack = []
  range = null
  {pattern, getPairState} = getRuleForPair(editor, pair)
  editor[scanFunctionName] pattern, scanRange, (event) ->
    if not allowNextLine and (from.row isnt event.range.start.row)
      event.stop()
      return

    if filters? and filters.some((filter) -> filter(event))
      return

    if getPairState(editor, event) isnt which
      stack.push(event)
    else
      topEvent = stack.pop()
      if fn(stack, topEvent)
        range = event.range
        event.stop()

  return range

findClosePairRangeForward = (options, fn) ->
  {allowForwarding, from} = options
  delete options.allowForwarding

  findPairRange 'close', 'forward', options, (stack, openEvent) ->
    unless openEvent?
      return true

    if stack.length is 0
      {start} = openEvent.range
      start.isEqual(from) or (allowForwarding and start.row is from.row)

findOpenPairRangeBackward = (options, fn) ->
  findPairRange 'open', 'backward', options, (stack, openEvent) ->
    stack.length is 0

getPairRangeInformation = (options) ->
  if closeRange = findClosePairRangeForward(options)
    options.from = closeRange.end
    openRange = findOpenPairRangeBackward(options)

  if openRange?
    {
      aRange: new Range(openRange.start, closeRange.end)
      innerRange: new Range(openRange.end, closeRange.start)
      openRange: openRange
      closeRange: closeRange
    }

isEscapedCharAtPoint = (editor, point) ->
  text = getLineTextToBufferPosition(editor, point)
  text.endsWith('\\') and not text.endsWith('\\\\')

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

  getFilters: ->
    filters = []
    isEscaped = ({range}) => isEscapedCharAtPoint(@editor, range.start)
    filters.push(isEscaped)
    filters

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

  getPairInfo: (from) ->
    filters = @getFilters()
    allowNextLine = @isAllowNextLine()
    pairInfo = getPairRangeInformation({@editor, from, @pair, filters, allowNextLine, @allowForwarding})
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
    (range for klass in @member when (range = @getRangeBy(prefix + klass, selection)))

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
tagPattern = /<(\/?)([^\s>]+)[^>]*>/g

findTagRange = (which, direction, options, fn) ->
  {editor, from, filters, allowNextLine} = options
  switch direction
    when 'forward'
      scanRange = new Range(from, editor.buffer.getEndPosition())
      scanFunctionName = 'scanInBufferRange'
    when 'backward'
      scanRange = new Range([0, 0], from)
      scanFunctionName = 'backwardsScanInBufferRange'

  stack = []
  range = null

  findingState = which
  oppositeState = switch findingState
    when 'open' then 'close'
    when 'close' then 'open'

  editor[scanFunctionName] tagPattern, scanRange, (event) ->
    if not allowNextLine and (from.row isnt event.range.start.row)
      event.stop()
      return

    if filters? and filters.some((filter) -> filter(event))
      return

    tagState = getTagState(event)
    if tagState.state is oppositeState
      stack.push(tagState)
    else
      if oppositeTagState = findTagState(stack, oppositeState, tagState.name)
        stack = stack[0...stack.indexOf(oppositeTagState)]

      if fn(stack, oppositeTagState)
        range = event.range
        event.stop()

  return range

getTagState = (event) ->
  backslash = event.match[1]
  {
    state: if (backslash is '') then 'open' else 'close'
    name: event.match[2]
    event: event
  }

findTagState = (stack, state, name) ->
  for tagState in stack by -1 when (tagState.state is state) and (tagState.name is name)
    return tagState

findCloseTagRangeForward = (options) ->
  {from, allowForwarding} = options
  delete options.allowForwarding

  findTagRange 'close', 'forward', options, (stack, openTagState) ->
    unless openTagState?
      # I'm very torelant for orphan tag like 'br', 'hr', or unclosed tag.
      return true

    if stack.length is 0
      {start} = openTagState.event.range
      start.isEqual(from) or (allowForwarding and start.row is from.row)

findOpenTagRangeBackward = (options) ->
  findTagRange 'open', 'backward', options, (stack, closeTagState) ->
    stack.length is 0

class Tag extends Pair
  @extend(false)
  allowNextLine: true
  allowForwarding: true
  adjustInnerRange: false

  getTagStartPoint: (from) ->
    tagRange = null
    scanRange = @editor.bufferRangeForBufferRow(from.row)
    @editor.scanInBufferRange tagPattern, scanRange, ({range, stop}) ->
      if range.containsPoint(from, true)
        tagRange = range
        stop()
    tagRange?.start ? from

  getPairInfo: (from) ->
    from = @getTagStartPoint(from)
    filters = @getFilters()
    options = {@editor, from, filters, @allowNextLine, @allowForwarding}

    return unless closeRange = findCloseTagRangeForward(options)

    options.from = closeRange.end
    return unless openRange = findOpenTagRangeBackward(options)

    aRange = new Range(openRange.start, closeRange.end)
    innerRange = new Range(openRange.end, closeRange.start)
    targetRange = if @isInner() then innerRange else aRange
    {openRange, closeRange, aRange, innerRange, targetRange}

class ATag extends Tag
  @extend()

class InnerTag extends Tag
  @extend()
