_ = require 'underscore-plus'

{
  saveEditorState
  getNonWordCharactersForCursor
} = require './utils'
SearchModel = require './search-model'

settings = require './settings'
Motion = require('./base').getClass('Motion')

getCaseSensitivity = (searchName) ->
  # [TODO] deprecate old setting and auto-migrate to caseSensitivityForXXX
  if settings.get("useSmartcaseFor#{searchName}")
    'smartcase'
  else if settings.get("ignoreCaseFor#{searchName}")
    'insensitive'
  else
    'sensitive'

class SearchBase extends Motion
  @extend(false)
  backwards: false
  useRegexp: true
  configScope: null
  updateSearchHistory: true
  landingPoint: null # ['start' or 'end']
  defaultLandingPoint: 'start' # ['start' or 'end']
  quiet: false

  isQuiet: ->
    @quiet

  isBackwards: ->
    @backwards

  getCount: ->
    count = super
    if @isBackwards()
      -count
    else
      count

  getVisualEffectFor: (key) ->
    if @isQuiet()
      false
    else
      settings.get(key)

  needToUpdateSearchHistory: ->
    @updateSearchHistory and not @isRepeated()

  isCaseSensitive: (term) ->
    switch getCaseSensitivity(@configScope)
      when 'smartcase' then term.search('[A-Z]') isnt -1
      when 'insensitive' then false
      when 'sensitive' then true

  finish: ->
    if @isIncrementalSearch?() and @getVisualEffectFor('showHoverSearchCounter')
      @vimState.hoverSearchCounter.reset()
    @searchModel?.destroy()
    @searchModel = null

  getLandingPoint: ->
    @landingPoint ?= @defaultLandingPoint

  getPoint: (cursor) ->
    range = @getSearchModel().getCurrentMatch()
    range ?= @search(cursor, @input, @getCount())
    if range?
      range[@getLandingPoint()]

  moveCursor: (cursor) ->
    input = @getInput()
    if input is ''
      @finish()
      return

    if point = @getPoint(cursor)
      cursor.setBufferPosition(point, autoscroll: false)

    if @needToUpdateSearchHistory()
      @globalState.set('currentSearch', this)
      @vimState.searchHistory.save(input)

    unless @isQuiet()
      @globalState.set('lastSearchPattern', @getPattern(input))

    @finish()

  getScanRanges: ->
    []

  getSearchModel: ->
    if @searchModel?
      @searchModel
    else
      options = {
        scanRanges: @getScanRanges()
        incrementalSearch: @isIncrementalSearch?()
      }
      @searchModel = new SearchModel(@vimState, options)

  search: (cursor, input, relativeIndex) ->
    searchModel = @getSearchModel()
    searchModel.scan(@getPattern(input))
    fromPoint = @getBufferPositionForCursor(cursor)
    searchModel.findMatch(fromPoint, relativeIndex)

# /, ?
# -------------------------
class Search extends SearchBase
  @extend()
  configScope: "Search"
  requireInput: true

  isIncrementalSearch: ->
    settings.get('incrementalSearch') and not @isRepeated()

  initialize: ->
    super
    # When repeated, no need to get user input
    return if @isComplete()

    restoreEditorState = null
    if @isIncrementalSearch()
      restoreEditorState = saveEditorState(@editor)

      @onDidCommandSearch (commandEvent) =>
        return unless @input
        switch commandEvent.name
          when 'visit' then @handleVisitCommand(commandEvent)
          when 'occurrence' then @handleOccurrenceCommand(commandEvent)

      @onDidConfirmSearch (event) =>
        {@input, @landingPoint} = event
        @processOperation()
    else
      @onDidConfirmSearch ({@input, @landingPoint}) =>
        searchChar = if @isBackwards() then '?' else '/'
        if @input in ['', searchChar]
          @input = @vimState.searchHistory.get('prev')
          atom.beep() unless @input
        @processOperation()

    @onDidCancelSearch =>
      unless @isMode('visual') or @isMode('insert')
        @vimState.resetNormalMode()
      restoreEditorState?()
      @vimState.reset()
      @finish()

    # If input starts with space, remove first space and disable useRegexp.
    @onDidChangeSearch (@input) =>
      if @input.startsWith(' ')
        @input = input.replace(/^ /, '')
        @useRegexp = false
      @vimState.searchInput.updateOptionSettings({@useRegexp})

      if @isIncrementalSearch()
        @search(@editor.getLastCursor(), @input, @getCount())

    @vimState.searchInput.focus({@backwards})

  handleVisitCommand: ({direction}) ->
    if @isBackwards() and settings.get('incrementalSearchVisitDirection') is 'relative'
      direction = switch direction
        when 'next' then 'prev'
        when 'prev' then 'next'

    relativeIndex = if direction is 'next' then +1 else -1
    @getSearchModel().updateCurrentMatch(relativeIndex)

  handleOccurrenceCommand: ({operation, pattern}) ->
    @vimState.occurrenceManager.resetPatterns() if operation?

    @vimState.occurrenceManager.addPattern(@getPattern(@input))
    @vimState.searchHistory.save(@input)
    @vimState.searchInput.cancel()

    @vimState.operationStack.run(operation) if operation?

  getPattern: (term) ->
    modifiers = if @isCaseSensitive(term) then 'g' else 'gi'
    # FIXME this prevent search \\c itself.
    # DONT thinklessly mimic pure Vim. Instead, provide ignorecase button and shortcut.
    if term.indexOf('\\c') >= 0
      term = term.replace('\\c', '')
      modifiers += 'i' unless 'i' in modifiers

    if @useRegexp
      try
        return new RegExp(term, modifiers)
      catch
        null

    new RegExp(_.escapeRegExp(term), modifiers)

class SearchBackwards extends Search
  @extend()
  backwards: true

# *, #
# -------------------------
class SearchCurrentWord extends SearchBase
  @extend()
  configScope: "SearchCurrentWord"

  getInput: ->
    @input ?= (
      wordRange = @getCurrentWordBufferRange()
      if wordRange?
        @editor.setCursorBufferPosition(wordRange.start)
        @editor.getTextInBufferRange(wordRange)
      else
        ''
    )

  getPattern: (term) ->
    modifiers = if @isCaseSensitive(term) then 'g' else 'gi'
    pattern = _.escapeRegExp(term)
    if /\W/.test(term)
      new RegExp("#{pattern}\\b", modifiers)
    else
      new RegExp("\\b#{pattern}\\b", modifiers)

  getCurrentWordBufferRange: ->
    cursor = @editor.getLastCursor()
    point = cursor.getBufferPosition()

    nonWordCharacters = getNonWordCharactersForCursor(cursor)
    wordRegex = new RegExp("[^\\s#{_.escapeRegExp(nonWordCharacters)}]+", 'g')

    found = null
    scanRange = @editor.bufferRangeForBufferRow(point.row)
    @editor.scanInBufferRange wordRegex, scanRange, ({range, stop}) ->
      if range.end.isGreaterThan(point)
        found = range
        stop()
    found

class SearchCurrentWordBackwards extends SearchCurrentWord
  @extend()
  backwards: true
