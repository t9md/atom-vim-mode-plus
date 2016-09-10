{
  getIndex
  highlightRanges
  smartScrollToBufferPosition
  getVisibleBufferRange
  scanInRanges
} = require './utils'

class MatchList
  index: null
  entries: null
  pattern: null

  @fromScan: (editor, {fromPoint, pattern, direction, countOffset, scanRanges}) ->
    index = 0
    if scanRanges.length
      ranges = scanInRanges(editor, pattern, scanRanges)
    else
      ranges = []
      editor.scan pattern, ({range}) ->
        ranges.push(range)

    if direction is 'backward'
      for range in ranges by -1 when range.start.isLessThan(fromPoint)
        current = range
        break
      current ?= ranges.slice(-1)[0] # last

    else if direction is 'forward'
      for range in ranges when range.start.isGreaterThan(fromPoint)
        current = range
        break
      current ?= ranges[0]

    index = ranges.indexOf(current)
    index = getIndex(index + countOffset, ranges)
    new this(editor, ranges, index, pattern)

  constructor: (@editor, ranges, @index, @pattern) ->
    @entries = []
    return unless ranges.length
    @entries = ranges.map (range) =>
      new Match(@editor, range)

    [first, others..., last] = @entries
    first.first = true
    last?.last = true

  getPattern: ->
    @pattern

  isEmpty: ->
    @entries.length is 0

  setIndex: (index) ->
    @index = getIndex(index, @entries)

  get: (direction=null) ->
    @entries[@index].current = false
    switch direction
      when 'next' then @setIndex(@index + 1)
      when 'prev' then @setIndex(@index - 1)
    match = @entries[@index]
    match.current = true
    match

  getCurrentStartPosition: ->
    @get().getStartPoint()

  getCurrentEndPosition: ->
    @get().getEndPoint()

  getVisible: ->
    range = getVisibleBufferRange(@editor)
    @entries.filter (match) ->
      range.intersectsWith(match.range)

  refresh: ->
    @reset()
    for match in @getVisible()
      match.show()

  reset: ->
    for match in @entries
      match.reset()

  destroy: ->
    for match in @entries
      match.destroy()
    {@entries, @index, @editor} = {}

  getCounterText: ->
    "#{@index + 1}/#{@entries.length}"

class Match
  first: false
  last: false
  current: false

  constructor: (@editor, @range) ->

  getClassList: ->
    # first and last is exclusive, prioritize 'first'.
    classes = []
    classes.push('first') if @first
    classes.push('last') if (not @first and @last)
    classes.push('current') if @current
    classes

  compare: (other) ->
    @range.compare(other.range)

  isEqual: (other) ->
    @range.isEqual other.range

  getStartPoint: ->
    @range.start

  getEndPoint: ->
    @range.end

  scrollToStartPoint: ->
    point = @getStartPoint()
    @editor.unfoldBufferRow(point.row)
    smartScrollToBufferPosition(@editor, point)

  # Flash only single match at the given moment.
  markersForFlash = null
  flash: (options) ->
    markersForFlash?[0]?.destroy()
    markersForFlash = highlightRanges @editor, @range,
      class: options.class
      timeout: options.timeout

  show: ->
    classes = ['vim-mode-plus-search-match'].concat(@getClassList()...)
    @marker = @editor.markBufferRange(@range)
    @editor.decorateMarker @marker,
      type: 'highlight'
      class: classes.join(" ")

  reset: ->
    @marker?.destroy()

  destroy: ->
    @reset()
    {@marker, @range, @editor, @first, @last, @current} = {}

module.exports = {MatchList}
