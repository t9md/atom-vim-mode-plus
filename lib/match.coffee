_ = require 'underscore-plus'
{
  sortRanges
  getIndex
  unfoldAtBufferRow
  highlightRanges
  smartScrollToBufferPosition
  getVisibleBufferRange
} = require './utils'
settings = require './settings'

class MatchList
  index: null
  entries: null

  constructor: (@vimState, ranges, index) ->
    {@editor, @editorElement} = @vimState
    @entries = []
    return unless ranges.length

    # ranges are initially not sorted, so we sort and adjust index here.
    current = ranges[getIndex(index, ranges)]
    ranges = sortRanges(ranges)
    @index = ranges.indexOf(current)

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

  getVisible: ->
    range = getVisibleBufferRange(@editor)
    @entries.filter (match) ->
      range.intersectsWith(match.range)

  getOffSetPixelHeight: (lineDelta=0) ->
    scrolloff = 2
    @editor.getLineHeightInPixels() * (2 + lineDelta)

  # make prev entry of first visible entry to bottom of screen
  scroll: (direction) ->
    switch direction
      when 'next'
        return if (match = _.last(@getVisible())).isLast()
        step = +1
        offsetPixel = @getOffSetPixelHeight()
      when 'prev'
        return if (match = _.first(@getVisible())).isFirst()
        step = -1
        offsetPixel = (@editorElement.getHeight() - @getOffSetPixelHeight(1))

    @setIndex (@entries.indexOf(match) + step)
    point = @editor.screenPositionForBufferPosition match.getStartPoint()
    scrollTop = @editorElement.pixelPositionForScreenPosition(point).top
    @editor.setScrollTop (scrollTop -= offsetPixel)

  show: ->
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

  isFirst: -> @first
  isLast: -> @last
  isCurrent: -> @current

  compare: (other) ->
    @range.compare(other.range)

  isEqual: (other) ->
    @range.isEqual other.range

  getStartPoint: ->
    @range.start

  visit: ->
    point = @getStartPoint()
    smartScrollToBufferPosition(@editor, point)
    @editor.unfoldBufferRow(point.row)

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
    @marker = null

  destroy: ->
    @reset()
    {@marker, @vimState, @range, @editor, @first, @last, @current} = {}

module.exports = {MatchList}
