{Emitter, CompositeDisposable} = require 'atom'
{
  highlightRanges
  scanInRanges
  getVisibleBufferRange
  smartScrollToBufferPosition
  getIndex
} = require './utils'
settings = require './settings'

module.exports =
class SearchModel
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

      unless @currentMatch?
        @flashScreen() if settings.get('flashScreenOnSearchHasNoMatch')
        @vimState.hoverSearchCounter.reset()
        return

      if settings.get('showHoverSearchCounter')
        hoverOptions =
          text: "#{@currentMatchIndex + 1}/#{@matches.length}"
          classList: @classNamesForRange(@currentMatch)

        unless @options.incrementalSearch
          hoverOptions.timeout = settings.get('showHoverSearchCounterDuration')

        @vimState.hoverSearchCounter.withTimeout(@currentMatch.start, hoverOptions)

      if settings.get('flashOnSearch')
        @flashRange(@currentMatch)

      @editor.unfoldBufferRow(@currentMatch.start.row)
      smartScrollToBufferPosition(@editor, @currentMatch.start)

  flashMarkers = []
  flashRange: (range) ->
    marker.destroy() for marker in flashMarkers
    options = {class: 'vim-mode-plus-flash', timeout: settings.get('flashOnSearchDuration')}
    flashMarkers = highlightRanges(@editor, range, options)

  destroy: ->
    @markerLayer.destroy()
    @disposables.dispose()

  clearMarkers: ->
    for marker in @markerLayer.getMarkers()
      marker.destroy()

  scan: (@pattern) ->
    @matches = []
    {scanRanges} = @options
    if scanRanges.length
      for range in scanInRanges(@editor, @pattern, scanRanges)
        @matches.push(range)
    else
      @editor.scan @pattern, ({range}) =>
        @matches.push(range)

    # [NOTE] others is not used, but dont changge this to bare ...
    # It affect behavior when matched range was only one.
    [@firstMatch, others..., @lastMatch] = @matches

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

  findMatch: (fromPoint, relativeIndex) ->
    currentMatch = null

    [firstMatch, ..., lastMatch] = @matches

    if relativeIndex >= 0
      for range in @matches when range.start.isGreaterThan(fromPoint)
        currentMatch = range
        break
      currentMatch ?= firstMatch
      relativeIndex--
    else
      for range in @matches by -1 when range.start.isLessThan(fromPoint)
        currentMatch = range
        break
      currentMatch ?= lastMatch
      relativeIndex++

    @currentMatchIndex = @matches.indexOf(currentMatch)
    @updateCurrentMatch(relativeIndex)
    @currentMatch

  updateCurrentMatch: (relativeIndex) ->
    @currentMatchIndex = getIndex(@currentMatchIndex + relativeIndex, @matches)
    @currentMatch = @matches[@currentMatchIndex]
    @emitter.emit('did-change-current-match')

  getCurrentMatch: ->
    @currentMatch

  flashScreen: ->
    options = {class: 'vim-mode-plus-flash', timeout: 100}
    highlightRanges(@editor, getVisibleBufferRange(@editor), options)
    atom.beep()
