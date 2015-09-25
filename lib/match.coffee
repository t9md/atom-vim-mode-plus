_ = require 'underscore-plus'
{getVisibleBufferRange} = require './utils'

# Match wrap Range in TextEditor with useful method.
class MatchList
  constructor: (@vimState, ranges, index) ->
    {@editor} = @vimState
    @entries = (new Match(@vimState, r) for r in ranges)
    @setIndex(index)

  isEmpty: ->
    @entries.length is 0

  setIndex: (index) ->
    if index >= 0
      @index = index % @entries.length
    else
      @index = (@entries.length + index)

  get: (direction=null) ->
    switch direction
      when 'next' then @setIndex(@index + 1)
      when 'prev' then @setIndex(@index - 1)
    @entries[@index]

  getVisible: ->
    range = getVisibleBufferRange(@editor)
    for m in @entries when range.containsRange(m.range)
      m

  show: ->
    @reset()
    current = @get()
    for m in @getVisible()
      klass = 'vim-mode-search-match'
      klass += ' current' if m.isEqual(current)
      m.decorate class: klass

  getInfo: ->
    sorted = @entries.slice().sort (a, b) -> a.compare(b)
    current = sorted.indexOf(@get()) + 1
    "#{current}/#{@entries.length}"

  reset: ->
    m.reset() for m in @entries

  destroy: ->
    m.destroy() for m in @entries
    {@entries, @index, @editor} = {}

class Match
  constructor: (@vimState, @range) ->
    {@editor} = @vimState

  compare: (other) ->
    @range.compare(other.range)

  isEqual: (other) ->
    @range.isEqual other.range

  getStartPoint: ->
    @range.start

  visit: ->
    point = @getStartPoint()
    @editor.scrollToBufferPosition(point, center: true)
    if @editor.isFoldedAtBufferRow(point.row)
      @editor.unfoldBufferRow point.row

  decorate: ({class: klass}) ->
    @marker = @editor.markBufferRange @range,
      invalidate: 'never'
      persistent: false
    @editor.decorateMarker @marker,
      type: 'highlight'
      class: klass

  reset: ->
    @marker?.destroy()
    @marker = null

  destroy: ->
    @marker?.destroy()
    {@marker, @vimState, @range, @editor} = {}

module.exports = {MatchList}
