{Emitter, CompositeDisposable} = require 'atom'
{
  highlightRange
  scanInRanges
  getVisibleBufferRange
  smartScrollToBufferPosition
  getIndex
} = require './utils'
settings = require './settings'

module.exports =
class SearchModel
  relativeIndex: 0
  onDidChangeCurrentMatch: (fn) -> @emitter.on 'did-change-current-match', fn

  constructor: (@vimState, @options) ->
    @emitter = new Emitter

    {@editor, @editorElement} = @vimState
    @disposables = new CompositeDisposable
    @disposables.add(@editorElement.onDidChangeScrollTop(@updateView.bind(this)))
    @disposables.add(@editorElement.onDidChangeScrollLeft(@updateView.bind(this)))
    @markerLayer = @editor.addMarkerLayer()

    @onDidChangeCurrentMatch =>
      @updateView() if @options.incrementalSearch

      @vimState.hoverSearchCounter.reset()
      unless @currentMatch?
        @flashScreen() if settings.get('flashScreenOnSearchHasNoMatch')
        return

      if settings.get('showHoverSearchCounter')
        hoverOptions =
          text: "#{@currentMatchIndex + 1}/#{@matches.length}"
          classList: @classNamesForRange(@currentMatch)

        unless @options.incrementalSearch
          hoverOptions.timeout = settings.get('showHoverSearchCounterDuration')

        @vimState.hoverSearchCounter.withTimeout(@currentMatch.start, hoverOptions)

      @editor.unfoldBufferRow(@currentMatch.start.row)
      smartScrollToBufferPosition(@editor, @currentMatch.start)

      if settings.get('flashOnSearch')
        @flashRange(@currentMatch)

  flashMarker = null
  flashRange: (range) ->
    flashMarker?.destroy()
    flashMarker = highlightRange @editor, range,
      class: 'vim-mode-plus-flash'
      timeout: settings.get('flashOnSearchDuration')

  destroy: ->
    @markerLayer.destroy()
    @disposables.dispose()

  clearMarkers: ->
    for marker in @markerLayer.getMarkers()
      marker.destroy()

  classNamesForRange: (range) ->
    classNames = []
    if range is @firstMatch
      classNames.push('first')
    else if range is @lastMatch
      classNames.push('last')

    if range is @currentMatch
      classNames.push('current')

    classNames

  updateView: ->
    @clearMarkers()
    @decorateRange(range) for range in @getVisibleMatchRanges()

  getVisibleMatchRanges: ->
    visibleRange = getVisibleBufferRange(@editor)
    visibleMatchRanges = @matches.filter (range) ->
      range.intersectsWith(visibleRange)

  decorateRange: (range) ->
    classNames = @classNamesForRange(range)
    classNames = ['vim-mode-plus-search-match'].concat(classNames...)
    @editor.decorateMarker @markerLayer.markBufferRange(range),
      type: 'highlight'
      class: classNames.join(' ')

  search: (fromPoint, @pattern, relativeIndex) ->
    @matches = []
    @editor.scan @pattern, ({range}) =>
      @matches.push(range)

    [@firstMatch, ..., @lastMatch] = @matches

    currentMatch = null
    if relativeIndex >= 0
      for range in @matches when range.start.isGreaterThan(fromPoint)
        currentMatch = range
        break
      currentMatch ?= @firstMatch
      relativeIndex--
    else
      for range in @matches by -1 when range.start.isLessThan(fromPoint)
        currentMatch = range
        break
      currentMatch ?= @lastMatch
      relativeIndex++

    @currentMatchIndex = @matches.indexOf(currentMatch)
    @updateCurrentMatch(relativeIndex)
    @initialCurrentMatchIndex = @currentMatchIndex
    @currentMatch

  updateCurrentMatch: (relativeIndex) ->
    @currentMatchIndex = getIndex(@currentMatchIndex + relativeIndex, @matches)
    @currentMatch = @matches[@currentMatchIndex]
    @emitter.emit('did-change-current-match')

  getRelativeIndex: ->
    @currentMatchIndex - @initialCurrentMatchIndex

  flashScreen: ->
    options = {class: 'vim-mode-plus-flash', timeout: 100}
    highlightRange(@editor, getVisibleBufferRange(@editor), options)
    atom.beep()
