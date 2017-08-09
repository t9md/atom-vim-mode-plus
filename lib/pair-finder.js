const {Range} = require("atom")
const _ = require("underscore-plus")
const {
  isEscapedCharRange,
  collectRangeInBufferRow,
  scanEditorInDirection,
  getLineTextToBufferPosition,
} = require("./utils")

function getCharacterRangeInformation(editor, point, char) {
  const regex = new RegExp(_.escapeRegExp(char), "g")
  const total = collectRangeInBufferRow(editor, point.row, regex).filter(range => !isEscapedCharRange(editor, range))
  const [left, right] = _.partition(total, ({start}) => start.isLessThan(point))
  const balanced = total.length % 2 === 0
  return {total, left, right, balanced}
}

class ScopeState {
  constructor(editor, point) {
    this.editor = editor
    this.state = this.getScopeStateForBufferPosition(point)
  }

  getScopeStateForBufferPosition(point) {
    const scopes = this.editor.scopeDescriptorForBufferPosition(point).getScopesArray()
    return {
      inString: scopes.some(scope => scope.startsWith("string.")),
      inComment: scopes.some(scope => scope.startsWith("comment.")),
      inDoubleQuotes: this.isInDoubleQuotes(point),
    }
  }

  isInDoubleQuotes(point) {
    const {total, left, balanced} = getCharacterRangeInformation(this.editor, point, '"')
    return total.length > 0 && balanced && left.length % 2 === 1
  }

  isEqual(other) {
    return _.isEqual(this.state, other.state)
  }

  isInNormalCodeArea() {
    return !(this.state.inString || this.state.inComment || this.state.inDoubleQuotes)
  }
}

class PairFinder {
  constructor(editor, {allowNextLine, allowForwarding, pair, inclusive = true} = {}) {
    this.editor = editor
    this.allowNextLine = allowNextLine
    this.allowForwarding = allowForwarding
    this.pair = pair
    this.inclusive = inclusive
    if (this.pair) this.setPatternForPair(this.pair)
  }

  getPattern() {
    return this.pattern
  }

  filterEvent() {
    return true
  }

  findPair(which, direction, from) {
    const stack = []
    let found

    // Quote is not nestable. So when we encounter 'open' while finding 'close',
    // it is forwarding pair, so stoppable unless @allowForwarding
    const findingNonForwardingClosingQuote = this instanceof QuoteFinder && which === "close" && !this.allowForwarding
    const {allowNextLine} = this
    scanEditorInDirection(this.editor, direction, this.getPattern(), {from, allowNextLine}, event => {
      const {range, stop} = event

      if (isEscapedCharRange(this.editor, range)) return
      if (!this.filterEvent(event)) return
      const eventState = this.getEventState(event)

      if (findingNonForwardingClosingQuote && eventState.state === "open" && range.start.isGreaterThan(from)) {
        stop()
        return
      }

      if (eventState.state !== which) {
        stack.push(eventState)
      } else if (this.onFound(stack, {eventState, from})) {
        found = range
        return stop()
      }
    })

    return found
  }

  spliceStack(stack, eventState) {
    return stack.pop()
  }

  onFound(stack, {eventState, from}) {
    switch (eventState.state) {
      case "open":
        this.spliceStack(stack, eventState)
        return stack.length === 0
      case "close":
        const openState = this.spliceStack(stack, eventState)
        if (!openState) return this.inclusive || eventState.range.start.isGreaterThan(from)

        if (!stack.length) {
          const {start} = openState.range
          return this.inclusive
            ? start.isEqual(from) || (this.allowForwarding && start.row === from.row)
            : start.isLessThan(from) || (this.allowForwarding && start.isGreaterThan(from) && start.row === from.row)
        }
    }
  }

  findCloseForward(from) {
    return this.findPair("close", "forward", from)
  }

  findOpenBackward(from) {
    return this.findPair("open", "backward", from)
  }

  find(from) {
    const closeRange = (this.closeRange = this.findCloseForward(from))
    const openRange = closeRange ? this.findOpenBackward(closeRange.end) : undefined

    if (openRange && closeRange) {
      return {
        aRange: new Range(openRange.start, closeRange.end),
        innerRange: new Range(openRange.end, closeRange.start),
        openRange,
        closeRange,
      }
    }
  }
}

class BracketFinder extends PairFinder {
  constructor(...args) {
    super(...args)
    this.retry = false
  }

  setPatternForPair([open, close]) {
    this.pattern = new RegExp(`(${_.escapeRegExp(open)})|(${_.escapeRegExp(close)})`, "g")
  }

  // This method can be called recursively
  find(from) {
    if (!this.initialScope) this.initialScope = new ScopeState(this.editor, from)

    const found = super.find(from)
    if (found) return found

    if (!this.retry) {
      this.retry = true
      this.closeRange = this.closeRangeScope = null
      return this.find(from)
    }
  }

  filterEvent({range}) {
    const scope = new ScopeState(this.editor, range.start)
    if (!this.closeRange) {
      // Now finding closeRange
      if (!this.retry) {
        return this.initialScope.isEqual(scope)
      } else {
        return this.initialScope.isInNormalCodeArea() ? !scope.isInNormalCodeArea() : scope.isInNormalCodeArea()
      }
    } else {
      // Now finding openRange: search from same scope
      if (!this.closeRangeScope) {
        this.closeRangeScope = new ScopeState(this.editor, this.closeRange.start)
      }
      return this.closeRangeScope.isEqual(scope)
    }
  }

  getEventState({match, range}) {
    let state
    if (match[1]) state = "open"
    else if (match[2]) state = "close"
    return {state, range}
  }
}

class QuoteFinder extends PairFinder {
  setPatternForPair(pair) {
    this.quoteChar = pair[0]
    this.pattern = new RegExp(`(${_.escapeRegExp(pair[0])})`, "g")
  }

  find(from) {
    // HACK: Cant determine open/close from quote char itself
    // So preset open/close state to get desiable result.
    let nextQuoteIsOpen
    {
      const {left, right, balanced} = getCharacterRangeInformation(this.editor, from, this.quoteChar)
      const onQuoteChar = right[0] && right[0].start.isEqual(from)
      if (balanced && onQuoteChar) {
        nextQuoteIsOpen = left.length % 2 === 0
      } else {
        nextQuoteIsOpen = left.length === 0
      }
    }

    this.pairStates = nextQuoteIsOpen ? ["open", "close", "close", "open"] : ["close", "close", "open"]

    return super.find(from)
  }

  getEventState({range}) {
    return {state: this.pairStates.shift(), range}
  }
}

const TAG_REGEX = /<(\/?)([^\s>]+)[^>]*>/g

class TagFinder extends PairFinder {
  static get pattern() {
    return TAG_REGEX
  }

  constructor(...args) {
    super(...args)
    this.pattern = TAG_REGEX
  }

  lineTextToPointContainsNonWhiteSpace(point) {
    return /\S/.test(getLineTextToBufferPosition(this.editor, point))
  }

  find(from) {
    const found = super.find(from)
    if (found && this.allowForwarding) {
      const tagStart = found.aRange.start
      if (tagStart.isGreaterThan(from) && this.lineTextToPointContainsNonWhiteSpace(tagStart)) {
        // We found range but also found that we are IN another tag,
        // so will retry by excluding forwarding range.
        this.allowForwarding = false
        return this.find(from) // retry
      }
    }
    return found
  }

  getEventState(event) {
    const backslash = event.match[1]
    return {
      state: backslash === "" ? "open" : "close",
      name: event.match[2],
      range: event.range,
    }
  }

  spliceStack(stack, eventState) {
    const pairEventState = stack.slice().reverse().find(state => state.name === eventState.name)
    if (pairEventState) stack.splice(stack.indexOf(pairEventState))
    return pairEventState
  }
}

module.exports = {
  BracketFinder,
  QuoteFinder,
  TagFinder,
}
