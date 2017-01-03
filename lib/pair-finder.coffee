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

  scanPair: (which, direction, from, fn) ->
    switch direction
      when 'forward'
        scanRange = new Range(from, @editor.buffer.getEndPosition())
        scanFunctionName = 'scanInBufferRange'
      when 'backward'
        scanRange = new Range([0, 0], from)
        scanFunctionName = 'backwardsScanInBufferRange'

    @editor[scanFunctionName] @getPattern(), scanRange, (event) =>
      if not @allowNextLine and (from.row isnt event.range.start.row)
        event.stop()
        return

      if isEscapedCharRange(@editor, event.range)
        return

      fn(event)

  findPair: (which, direction, from, fn) ->
    stack = []
    range = null
    @scanPair which, direction, from, (event) =>
      eventState = @getEventState(event)
      if eventState.state isnt which
        stack.push(eventState)
      else
        if fn(stack, eventState)
          range = event.range
          event.stop()

    return range

  spliceStack: (stack, eventState) ->
    stack.pop()

  findCloseForward: (from, {allowForwarding}={}) ->
    @findPair 'close', 'forward', from, (stack, closeState) =>
      openState = @spliceStack(stack, closeState)
      unless openState?
        return true

      if stack.length is 0
        {start} = openState.range
        start.isEqual(from) or (allowForwarding and start.row is from.row)

  findOpenBackward: (from) ->
    @findPair 'open', 'backward', from, (stack, openState) =>
      @spliceStack(stack, openState)
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

  getEventState: ({match, range}) ->
    state = switch
      when match[1] then 'open'
      when match[2] then 'close'
    {state, range}

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

  getEventState: ({range}) ->
    state = @pairStates.shift()
    {state, range}

class TagFinder extends PairFinder
  pattern: /<(\/?)([^\s>]+)[^>]*>/g

  getEventState: (event) ->
    backslash = event.match[1]
    {
      state: if (backslash is '') then 'open' else 'close'
      name: event.match[2]
      range: event.range
    }

  findPairState: (stack, {name}) ->
    for state in stack by -1 when state.name is name
      return state

  spliceStack: (stack, eventState) ->
    if pairEventState = @findPairState(stack, eventState)
      stack.splice(stack.indexOf(pairEventState))
    pairEventState

module.exports = {
  BracketFinder
  QuoteFinder
  TagFinder
}
