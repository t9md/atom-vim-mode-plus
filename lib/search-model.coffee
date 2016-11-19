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
    @disposables.add(@editorElement.onDidChangeScrollTop(@refreshMarkers.bind(this)))
    @disposables.add(@editorElement.onDidChangeScrollLeft(@refreshMarkers.bind(this)))
    @markerLayer = @editor.addMarkerLayer()
    @decoationByRange = {}

    @onDidChangeCurrentMatch =>
      @vimState.hoverSearchCounter.reset()
      unless @currentMatch?
        if settings.get('flashScreenOnSearchHasNoMatch')
          @vimState.flash(getVisibleBufferRange(@editor), type: 'screen')
          atom.beep()

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
        @vimState.flash(@currentMatch, type: 'search')

  destroy: ->
    @markerLayer.destroy()
    @disposables.dispose()
    @decoationByRange = null

  clearMarkers: ->
    for marker in @markerLayer.getMarkers()
      marker.destroy()
    @decoationByRange = {}

  classNamesForRange: (range) ->
    classNames = []
    if range is @firstMatch
      classNames.push('first')
    else if range is @lastMatch
      classNames.push('last')

    if range is @currentMatch
      classNames.push('current')

    classNames

  refreshMarkers: ->
    @clearMarkers()
    for range in @getVisibleMatchRanges()
      @decoationByRange[range.toString()] = @decorateRange(range)

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
    if @options.incrementalSearch
      @refreshMarkers()
    @initialCurrentMatchIndex = @currentMatchIndex
    @currentMatch

  updateCurrentMatch: (relativeIndex) ->
    @currentMatchIndex = getIndex(@currentMatchIndex + relativeIndex, @matches)
    @currentMatch = @matches[@currentMatchIndex]
    @emitter.emit('did-change-current-match')

  visit: (relativeIndex) ->
    return unless @matches.length
    oldDecoration = @decoationByRange[@currentMatch.toString()]
    @updateCurrentMatch(relativeIndex)
    newDecoration = @decoationByRange[@currentMatch.toString()]

    if oldDecoration?
      oldClass = oldDecoration.getProperties().class
      oldClass = oldClass.replace(/\s+current(\s+)?$/, '$1')
      oldDecoration.setProperties(type: 'highlight', class: oldClass)

    if newDecoration?
      newClass = newDecoration.getProperties().class
      newClass = newClass.replace(/\s+current(\s+)?$/, '$1')
      newClass += ' current'
      newDecoration.setProperties(type: 'highlight', class: newClass)

  getRelativeIndex: ->
    @currentMatchIndex - @initialCurrentMatchIndex
