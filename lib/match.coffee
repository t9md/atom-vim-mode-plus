_ = require 'underscore-plus'
{
  sortRanges
  getIndex
  highlightRanges
  smartScrollToBufferPosition
  getVisibleBufferRange
} = require './utils'
settings = require './settings'

class MatchList
  index: null
  entries: null

  @fromScan: (vimState, {fromPoint, pattern, direction, countOffset}) ->
    {editor} = vimState
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
    new this(vimState, ranges, index)

  constructor: (@vimState, ranges, @index) ->
    {@editor} = @vimState
    @entries = []
    return unless ranges.length
    @entries = ranges.map (range) =>
      new Match(@vimState, range)

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

  flashCurrent: ->
    @get().flash()

  scrollToCurrent: ->
    @get().visit()

  visit: (direction=null) ->
    @get(direction)
    @scrollToCurrent()
    @refresh()
    @flashCurrent()
    @showHover(timeout: null)

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

  showHover: ({timeout}) ->
    current = @get()
    if settings.get('showHoverSearchCounter')
      @vimState.hoverSearchCounter.withTimeout current.range.start,
        text: "#{@index + 1}/#{@entries.length}"
        classList: current.getClassList()
        timeout: timeout

class Match
  first: false
  last: false
  current: false

  constructor: (@vimState, @range) ->
    {@editor} = @vimState

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

  visit: ->
    point = @getStartPoint()
    @editor.unfoldBufferRow(point.row)
    smartScrollToBufferPosition(@editor, point)

  # Flash only single match at the given moment.
  markersForFlash = null
  flash: ->
    markersForFlash?[0]?.destroy()
    if settings.get('flashOnSearch')
      markersForFlash = highlightRanges @editor, @range,
        class: 'vim-mode-plus-flash'
        timeout: settings.get('flashOnSearchDuration')

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
    {@marker, @vimState, @range, @editor, @first, @last, @current} = {}

module.exports = {MatchList}
