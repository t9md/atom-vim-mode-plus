{Range} = require 'atom'
_ = require 'underscore-plus'
{
  isEscapedCharRange
  scanBufferRow
} = require './utils'

class PairFinder
  constructor: (@editor, {@allowNextLine}={}) ->

  getPattern: ->
    @pattern

  getFilters: ->
    filters = []
    isEscaped = ({range}) => isEscapedCharRange(@editor, range)
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

  getCharacterRangeInformation: (char, point) ->
    pattern = ///#{_.escapeRegExp(char)}///g
    total = scanBufferRow(@editor, point.row, pattern).filter (range) =>
      not isEscapedCharRange(@editor, range)
    [left, right] = _.partition(total, ({start}) -> start.isLessThan(point))
    {total, left, right}

  find: (from, options) ->
    # HACK: Cant determine open/close from quote char itself
    # So preset open/close state to get desiable result.
    {total, left, right} = @getCharacterRangeInformation(@quoteChar, from)
    quoteIsBalanced = (total.length % 2) is 0
    onQuoteChar = right[0]?.start.isEqual(from) # from point is on quote char
    if quoteIsBalanced and onQuoteChar
      nextQuoteIsOpen = left.length % 2 is 0
    else
      nextQuoteIsOpen = left.length is 0

    if nextQuoteIsOpen
      @pairStates = ['open', 'close', 'close', 'open']
    else
      @pairStates = ['close', 'close', 'open']

    super

  getPairState: ->
    @pairStates.shift()

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
