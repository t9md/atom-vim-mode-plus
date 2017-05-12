{Emitter, CompositeDisposable} = require 'atom'
{
  getVisibleBufferRange
  smartScrollToBufferPosition
  getIndex
  replaceDecorationClassBy
} = require './utils'

hoverCounterTimeoutID = null
removeCurrentClassForDecoration = null
addCurrentClassForDecoration = null

module.exports =
class SearchModel
  relativeIndex: 0
  lastRelativeIndex: null
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
        if @vimState.getConfig('flashScreenOnSearchHasNoMatch')
          @vimState.flash(getVisibleBufferRange(@editor), type: 'screen')
          atom.beep()
        return

      if @vimState.getConfig('showHoverSearchCounter')
        text = String(@currentMatchIndex + 1) + '/' + @matches.length
        point = @currentMatch.start
        classList = @classNamesForRange(@currentMatch)

        @resetHover()
        @vimState.hoverSearchCounter.set(text, point, {classList})

        unless @options.incrementalSearch
          timeout = @vimState.getConfig('showHoverSearchCounterDuration')
          hoverCounterTimeoutID = setTimeout(@resetHover.bind(this), timeout)

      @editor.unfoldBufferRow(@currentMatch.start.row)
      smartScrollToBufferPosition(@editor, @currentMatch.start)

      if @vimState.getConfig('flashOnSearch')
        @vimState.flash(@currentMatch, type: 'search')

  resetHover: ->
    if hoverCounterTimeoutID?
      clearTimeout(hoverCounterTimeoutID)
      hoverCounterTimeoutID = null
    # See #674
    # This method called with setTimeout
    # hoverSearchCounter might not be available when editor destroyed.
    @vimState.hoverSearchCounter?.reset()

  destroy: ->
    @markerLayer.destroy()
    @disposables.dispose()
    @decoationByRange = null

  clearMarkers: ->
    @markerLayer.clear()
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
    for range in @getVisibleMatchRanges() when not range.isEmpty()
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

  visit: (relativeIndex=null) ->
    if relativeIndex?
      @lastRelativeIndex = relativeIndex
    else
      relativeIndex = @lastRelativeIndex ? +1

    return unless @matches.length
    oldDecoration = @decoationByRange[@currentMatch.toString()]
    @updateCurrentMatch(relativeIndex)
    newDecoration = @decoationByRange[@currentMatch.toString()]

    removeCurrentClassForDecoration ?= replaceDecorationClassBy.bind null , (text) ->
      text.replace(/\s+current(\s+)?$/, '$1')

    addCurrentClassForDecoration ?= replaceDecorationClassBy.bind null , (text) ->
      text.replace(/\s+current(\s+)?$/, '$1') + ' current'

    if oldDecoration?
      removeCurrentClassForDecoration(oldDecoration)

    if newDecoration?
      addCurrentClassForDecoration(newDecoration)

  getRelativeIndex: ->
    @currentMatchIndex - @initialCurrentMatchIndex
