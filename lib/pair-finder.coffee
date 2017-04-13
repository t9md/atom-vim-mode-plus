{Range} = require 'atom'
_ = require 'underscore-plus'
{
  isEscapedCharRange
  collectRangeInBufferRow
  scanEditorInDirection
  getLineTextToBufferPosition
} = require './utils'

getCharacterRangeInformation = (editor, point, char) ->
  pattern = ///#{_.escapeRegExp(char)}///g
  total = collectRangeInBufferRow(editor, point.row, pattern).filter (range) ->
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
      inString: scopes.some (scope) -> scope.startsWith('string.')
      inComment: scopes.some (scope) -> scope.startsWith('comment.')
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

  isInNormalCodeArea: ->
    not (@state.inString or @state.inComment or @state.inDoubleQuotes)

class PairFinder
  constructor: (@editor, options={}) ->
    {@allowNextLine, @allowForwarding, @pair, @inclusive} = options
    @inclusive ?= true
    if @pair?
      @setPatternForPair(@pair)

  getPattern: ->
    @pattern

  filterEvent: ->
    true

  findPair: (which, direction, from) ->
    stack = []
    found = null

    # Quote is not nestable. So when we encounter 'open' while finding 'close',
    # it is forwarding pair, so stoppable unless @allowForwarding
    findingNonForwardingClosingQuote = (this instanceof QuoteFinder) and which is 'close' and not @allowForwarding
    scanner = scanEditorInDirection.bind(null, @editor, direction, @getPattern(), {from, @allowNextLine})
    scanner (event) =>
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
          return @inclusive or eventState.range.start.isGreaterThan(from)

        if stack.length is 0
          openRange = openState.range
          openStart = openRange.start
          if @inclusive
            openStart.isEqual(from) or (@allowForwarding and openStart.row is from.row)
          else
            openStart.isLessThan(from) or (@allowForwarding and openStart.isGreaterThan(from) and openStart.row is from.row)

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
  find: (from) ->
    @initialScope ?= new ScopeState(@editor, from)

    return found if found = super

    if not @retry
      @retry = true
      [@closeRange, @closeRangeScope] = []
      @find(from)

  filterEvent: ({range}) ->
    scope = new ScopeState(@editor, range.start)
    if not @closeRange
      # Now finding closeRange
      if not @retry
        @initialScope.isEqual(scope)
      else
        if @initialScope.isInNormalCodeArea()
          not scope.isInNormalCodeArea()
        else
          scope.isInNormalCodeArea()
    else
      # Now finding openRange: search from same scope
      @closeRangeScope ?= new ScopeState(@editor, @closeRange.start)
      @closeRangeScope.isEqual(scope)

  getEventState: ({match, range}) ->
    state = switch
      when match[1] then 'open'
      when match[2] then 'close'
    {state, range}

class QuoteFinder extends PairFinder
  setPatternForPair: (pair) ->
    @quoteChar = pair[0]
    @pattern = ///(#{_.escapeRegExp(pair[0])})///g

  find: (from) ->
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

  lineTextToPointContainsNonWhiteSpace: (point) ->
    /\S/.test(getLineTextToBufferPosition(@editor, point))

  find: (from) ->
    found = super
    if found? and @allowForwarding
      tagStart = found.aRange.start
      if tagStart.isGreaterThan(from) and @lineTextToPointContainsNonWhiteSpace(tagStart)
        # We found range but also found that we are IN another tag,
        # so will retry by excluding forwarding range.
        @allowForwarding = false
        return @find(from) # retry
    found

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
