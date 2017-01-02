{Range} = require 'atom'
_ = require 'underscore-plus'
{
  countChar
  getLineTextToBufferPosition
  isEscapedCharAtPoint
  getRightCharacterForBufferPosition
} = require './utils'

class PairFinder
  constructor: (@editor, {@allowNextLine}={}) ->

  getPattern: ->
    @pattern

  getFilters: ->
    filters = []
    isEscaped = ({range}) => isEscapedCharAtPoint(@editor, range.start)
    filters.push(isEscaped)
    filters

  scanPair: (which, direction, from, fn) ->
    switch direction
      when 'forward'
        scanRange = new Range(from, @editor.buffer.getEndPosition())
        scanFunctionName = 'scanInBufferRange'
      when 'backward'
        scanRange = new Range([0, 0], from)
        scanFunctionName = 'backwardsScanInBufferRange'

    filters = @getFilters()
    @editor[scanFunctionName] @getPattern(), scanRange, (event) =>
      if not @allowNextLine and (from.row isnt event.range.start.row)
        event.stop()
        return

      return if filters.some((filter) -> filter(event))

      fn(event)

  findPair: (which, direction, from, fn) ->
    stack = []
    range = null
    @scanPair which, direction, from, (event) =>
      if @getPairState(event) isnt which
        stack.push(event)
      else
        topEvent = stack.pop()
        if fn(stack, topEvent)
          range = event.range
          event.stop()

    return range

  findCloseForward: (from, {allowForwarding}={}) ->
    @findPair 'close', 'forward', from, (stack, openEvent) ->
      unless openEvent?
        return true

      if stack.length is 0
        {start} = openEvent.range
        start.isEqual(from) or (allowForwarding and start.row is from.row)

  findOpenBackward: (from) ->
    @findPair 'open', 'backward', from, (stack, openEvent) ->
      stack.length is 0

  find: (from, options) ->
    closeRange = @findCloseForward(from, options)
    openRange = @findOpenBackward(closeRange.end, options) if closeRange?

    if closeRange? and openRange?
      {
        aRange: new Range(openRange.start, closeRange.end)
        innerRange: new Range(openRange.end, closeRange.start)
        openRange: openRange
        closeRange: closeRange
      }

class BracketFinder extends PairFinder
  setPatternForPair: (pair) ->
    [open, close] = pair
    @pattern = ///(#{_.escapeRegExp(open)})|(#{_.escapeRegExp(close)})///g

  getPairState: ({match}) ->
    switch
      when match[1] then 'open'
      when match[2] then 'close'

class QuoteFinder extends PairFinder
  setPatternForPair: (pair) ->
    @quoteChar = pair[0]
    @pattern = ///(#{_.escapeRegExp(pair[0])})///g

  detectStateAtPoint: (char, point) ->
    charCount = @countCharTillPoint(char, point)
    if charCount % 2 is 0
      'close'
    else
      'open'

  countCharTillPoint: (char, point) ->
    char = _.escapeRegExp(char)
    backslash = _.escapeRegExp('\\')
    patterns = [
      "(?:#{backslash}#{backslash}#{char})"
      "(?:[^#{backslash}]?#{char})"
    ]
    pattern = new RegExp(patterns.join('|'))
    lineText = getLineTextToBufferPosition(@editor, point)
    countChar(lineText, pattern)

  find: (from, options) ->
    cursorChar = getRightCharacterForBufferPosition(@editor, from)
    # blockCursor is ON char, sor diff in start and end column is 1
    cursorEndPosition = from.translate([0, 1])
    # HACK: Cant determine open/close from quote char itself
    # So preset open/close state to get desiable result.
    # Ideally this should be fixed more straightforward logic.
    if (cursorChar is @quoteChar) and not isEscapedCharAtPoint(@editor, from)
      state = @detectStateAtPoint(@quoteChar, cursorEndPosition)
      if state is 'close'
        @states = ['close', 'close', 'open']
      else
        @states = ['open', 'close', 'close', 'open']
    else
      if options.allowForwarding and @countCharTillPoint(@quoteChar, cursorEndPosition) is 0
        @states = ['open', 'close', 'close', 'open']
      else
        @states = ['close', 'close', 'open']

    super

  getPairState: ->
    @states.shift()

class TagFinder extends PairFinder
  pattern: /<(\/?)([^\s>]+)[^>]*>/g

  getPairState: (event) ->
    backslash = event.match[1]
    {
      state: if (backslash is '') then 'open' else 'close'
      name: event.match[2]
      range: event.range
    }

  findTagState: (stack, state, name) ->
    for tagState in stack by -1 when (tagState.state is state) and (tagState.name is name)
      return tagState

  findPair: (which, direction, from, fn) ->
    stack = []
    range = null
    findingState = which
    oppositeState = switch findingState
      when 'open' then 'close'
      when 'close' then 'open'

    @scanPair which, direction, from, (event) =>
      tagState = @getPairState(event)
      if tagState.state isnt which
        stack.push(tagState)
      else
        if oppositeTagState = @findTagState(stack, oppositeState, tagState.name)
          stack = stack[0...stack.indexOf(oppositeTagState)]

        if fn(stack, oppositeTagState)
          range = event.range
          event.stop()

    return range

module.exports = {
  BracketFinder
  QuoteFinder
  TagFinder
}
