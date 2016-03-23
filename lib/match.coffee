_ = require 'underscore-plus'
{
  getIndex
  highlightRanges
  smartScrollToBufferPosition
  getVisibleBufferRange
} = require './utils'

class MatchList
  index: null
  entries: null

  @fromScan: (editor, {fromPoint, pattern, direction, countOffset}) ->
    index = 0
    ranges = []
    editor.scan pattern, ({range}) ->
      ranges.push range

    if direction is 'backward'
      reversed = ranges.slice().reverse()
      current = _.detect(reversed, ({start}) -> start.isLessThan(fromPoint))
      current ?= _.last(ranges)
    else if direction is 'forward'
      current = _.detect(ranges, ({start}) -> start.isGreaterThan(fromPoint))
      current ?= ranges[0]

    index = ranges.indexOf(current)
    index = getIndex(index + countOffset, ranges)
    new this(editor, ranges, index)

  constructor: (@editor, ranges, @index) ->
    @entries = []
    return unless ranges.length
    @entries = ranges.map (range) =>
      new Match(@editor, range)

    [first, others..., last] = @entries
    first.first = true
    last?.last = true

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

    @marker = @editor.markBufferRange @range,
      invalidate: 'never'
      persistent: false

    @editor.decorateMarker @marker,
      type: 'highlight'
      class: classes.join(" ")

  reset: ->
    @marker?.destroy()

  destroy: ->
    @reset()
    {@marker, @range, @editor, @first, @last, @current} = {}

module.exports = {MatchList}
