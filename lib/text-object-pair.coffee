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

getPatternForPair = (pair) ->
  [open, close] = pair
  if open is close
    new RegExp("(#{_.escapeRegExp(open)})", 'g')
  else
    new RegExp("(#{_.escapeRegExp(open)})|(#{_.escapeRegExp(close)})", 'g')

findPair = (editor, from, pair, direction, fn) ->
  pattern = getPatternForPair(pair)
  switch direction
    when 'forward'
      findPairForward(editor, from, pattern, fn)
    when 'backward'
      findPairBackward(editor, from, pattern, fn)

findPairForward = (editor, from, pattern, fn) ->
  scanRange = new Range(from, editor.buffer.getEndPosition())
  editor.scanInBufferRange(pattern, scanRange, fn)

findPairBackward = (editor, from, pattern, fn) ->
  scanRange = new Range([0, 0], from)
  editor.backwardsScanInBufferRange(pattern, scanRange, fn)

# Take start point of matched range.
backSlashPattern = _.escapeRegExp('\\')
isEscapedCharAtPoint = (editor, point) ->
  escaped = false
  pattern = new RegExp("[^#{backSlashPattern}]#{backSlashPattern}")
  scanRange = [[point.row, 0], point]
  editor.backwardsScanInBufferRange pattern, scanRange, ({matchText, range, stop}) ->
    if range.end.isEqual(point)
      stop()
      escaped = true
  escaped

# -------------------------
class Pair extends TextObject
  @extend(false)

  _newStyle: true # REMOVE after rewrite DONE

  allowNextLine: false
  adjustInnerRange: true
  pair: null
  wise: 'characterwise'
  supportCount: true

  # Return 'open' or 'close'
  getPairState: ({matchText, range, match}) ->
    switch match.length
      when 2
        @pairStateInBufferRange(range, matchText)
      when 3
        switch
          when match[1] then 'open'
          when match[2] then 'close'

  pairStateInBufferRange: (range, char) ->
    text = getLineTextToBufferPosition(@editor, range.end)
    escapedChar = _.escapeRegExp(char)
    bs = backSlashPattern
    patterns = [
      "#{bs}#{bs}#{escapedChar}"
      "[^#{bs}]?#{escapedChar}"
    ]
    pattern = new RegExp(patterns.join('|'))
    ['close', 'open'][(countChar(text, pattern) % 2)]

  getFilters: (from) ->
    filters = []
    if not @allowNextLine
      isNotSameLine = ({range, stop}) ->
        if from.row isnt range.start.row
          stop()
          true
        else
          false

      filters.push(isNotSameLine)

    isEscaped = ({range}) => isEscapedCharAtPoint(@editor, range.start)

    filters.push(isEscaped)

    filters

  findOpen: (from) ->
    stack = []
    found = null

    filters = @getFilters(from)

    findPair @editor, from, @pair, 'backward', (event) =>
      {range, stop} = event
      return if filters.some((filter) -> filter(event))

      if @getPairState(event) is 'close'
        stack.push({range})
      else
        stack.pop()
        found = range if stack.length is 0
      stop() if found?
    found

  findClose: (from) ->
    stack = []
    found = null

    filters = @getFilters(from)

    findPair @editor, from, @pair, 'forward', (event) =>
      {range, stop} = event
      return if filters.some((filter) -> filter(event))

      if @getPairState(event) is 'open'
        stack.push({range})
      else
        entry = stack.pop()
        if stack.length is 0
          if (openStart = entry?.range.start)
            if @allowForwarding
              return if openStart.row isnt from.row
            else
              return if openStart.isGreaterThan(from)
          found = range
      stop() if found?
    found

  getPairInfo: (from) ->
    pairInfo = null
    if @_newStyle
      closeRange = @findClose(from)
      openRange = @findOpen(closeRange.end) if closeRange?
    else
      pattern = @getPattern()
      closeRange = @findClose(from, pattern)
      openRange = @findOpen(closeRange.end, pattern) if closeRange?

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
      if pointIsAtEndOfLine(@editor, innerStart)
        innerStart = new Point(innerStart.row + 1, 0)

      if getLineTextToBufferPosition(@editor, innerEnd).match(/^\s*$/)
        if @isMode('visual')
          # This is slightly innconsistent with regular Vim
          # - regular Vim: select new line after EOL
          # - vim-mode-plus: select to EOL(before new line)
          # This is intentional since to make submode `characterwise` when auto-detect submode
          innerEnd = new Point(innerEnd.row - 1, Infinity)
        else
          innerEnd = new Point(innerEnd.row, 0)

    innerRange = new Range(innerStart, innerEnd)
    targetRange = if @isInner() then innerRange else aRange
    {openRange, closeRange, aRange, innerRange, targetRange}

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

# -------------------------
class AnyPair extends Pair
  @extend(false)
  allowForwarding: false
  allowNextLine: null
  member: [
    'DoubleQuote', 'SingleQuote', 'BackTick',
    'CurlyBracket', 'AngleBracket', 'SquareBracket', 'Parenthesis'
  ]

  getRangeBy: (klass, selection) ->
    options = {@inner}
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
  allowNextLine: true

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

  _newStyle: false # REMOVE after rewrite DONE

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
