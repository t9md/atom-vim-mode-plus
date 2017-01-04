{Range} = require 'atom'
_ = require 'underscore-plus'
{
  isEscapedCharRange
  getEndOfLineForBufferRow
  scanBufferRow
  scanEditorInDirection
} = require './utils'

isMatchScope = (pattern, scopes) ->
  for scope in scopes when pattern.test(scope)
    return true
  false

getCharacterRangeInformation = (editor, point, char) ->
  pattern = ///#{_.escapeRegExp(char)}///g
  total = scanBufferRow(editor, point.row, pattern).filter (range) ->
    not isEscapedCharRange(editor, range)
  [left, right] = _.partition(total, ({start}) -> start.isLessThan(point))
  balanced = (total.length % 2) is 0
  {total, left, right, balanced}

class ScopeState
  constructor: (@editor, point) ->
    @state = @getScopeStateForBufferPosition(point)

  getScopeStateForBufferPosition: (point) ->
    scopes = @editor.scopeDescriptorForBufferPosition(point).getScopesArray()
    {
      inString: isMatchScope(/^string\.*/, scopes)
      inComment: isMatchScope(/^comment\.*/, scopes)
      inDoubleQuotes: @isInDoubleQuotes(point)
    }

  isInDoubleQuotes: (point) ->
    {total, left, balanced} = getCharacterRangeInformation(@editor, point, '"')
    if total.length is 0 or not balanced
      false
    else
      left.length % 2 is 1

  isEqual: (other) ->
    _.isEqual(@state, other.state)

class PairFinder
  constructor: (@editor, options={}) ->
    {@allowNextLine, @allowForwarding} = options

  getPattern: ->
    @pattern

  filterEvent: ->
    true

  findPair: (which, direction, from) ->
    stack = []
    found = null

    # Quote is not nestable. So when we encounter 'open' while finding 'close',
    # it is forwarding pair, so stoppable is not @allowForwarding
    findingNonForwardingClosingQuote = (this instanceof QuoteFinder) and which is 'close' and not @allowForwarding
    scanEditorInDirection @editor, direction, @getPattern(), from, {@allowNextLine}, (event) =>
      {range, stop} = event

      return if isEscapedCharRange(@editor, range)
      return unless @filterEvent(event)

      eventState = @getEventState(event)

      if findingNonForwardingClosingQuote and eventState.state is 'open' and range.start.isGreaterThan(from)
        stop()
        return

      if eventState.state isnt which
        stack.push(eventState)
      else
        if @onFound(stack, {eventState, from})
          found = range
          stop()

    return found

  spliceStack: (stack, eventState) ->
    stack.pop()

  onFound: (stack, {eventState, from}) ->
    switch eventState.state
      when 'open'
        @spliceStack(stack, eventState)
        stack.length is 0
      when 'close'
        openState = @spliceStack(stack, eventState)
        unless openState?
          return true

        if stack.length is 0
          {start} = openState.range
          start.isEqual(from) or (@allowForwarding and start.row is from.row)

  findCloseForward: (from) ->
    @findPair('close', 'forward', from)

  findOpenBackward: (from) ->
    @findPair('open', 'backward', from)

  find: (from) ->
    closeRange = @closeRange = @findCloseForward(from)
    openRange = @findOpenBackward(closeRange.end) if closeRange?

    if closeRange? and openRange?
      {
        aRange: new Range(openRange.start, closeRange.end)
        innerRange: new Range(openRange.end, closeRange.start)
        openRange: openRange
        closeRange: closeRange
      }

class BracketFinder extends PairFinder
  retry: false

  setPatternForPair: (pair) ->
    [open, close] = pair
    @pattern = ///(#{_.escapeRegExp(open)})|(#{_.escapeRegExp(close)})///g

  # This method can be called recursively
  find: (from, options) ->
    @initialScopeState ?= new ScopeState(@editor, from)

    return found if found = super

    if not @retry
      @retry = true
      [@closeRange, @closeScopeState] = []
      @find(from, options)

  filterEvent: ({range}) ->
    scopeState = new ScopeState(@editor, range.start)
    if @closeRange?
      @closeScopeState ?= new ScopeState(@editor, @closeRange.start)
      @closeScopeState.isEqual(scopeState)
    else
      if not @retry
        @initialScopeState.isEqual(scopeState)
      else
        not @initialScopeState.isEqual(scopeState)

  getEventState: ({match, range}) ->
    state = switch
      when match[1] then 'open'
      when match[2] then 'close'
    {state, range}

class QuoteFinder extends PairFinder
  setPatternForPair: (pair) ->
    @quoteChar = pair[0]
    @pattern = ///(#{_.escapeRegExp(pair[0])})///g

  find: (from, options) ->
    # HACK: Cant determine open/close from quote char itself
    # So preset open/close state to get desiable result.
    {total, left, right, balanced} = getCharacterRangeInformation(@editor, from, @quoteChar)
    onQuoteChar = right[0]?.start.isEqual(from) # from point is on quote char
    if balanced and onQuoteChar
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
