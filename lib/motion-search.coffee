_ = require 'underscore-plus'

{saveEditorState, getNonWordCharactersForCursor, searchByProjectFind} = require './utils'
SearchModel = require './search-model'
Motion = require('./base').getClass('Motion')

class SearchBase extends Motion
  @extend(false)
  jump: true
  backwards: false
  useRegexp: true
  configScope: null
  landingPoint: null # ['start' or 'end']
  defaultLandingPoint: 'start' # ['start' or 'end']
  relativeIndex: null
  updatelastSearchPattern: true

  isBackwards: ->
    @backwards

  isIncrementalSearch: ->
    @instanceof('Search') and not @repeated and @getConfig('incrementalSearch')

  initialize: ->
    super
    @onDidFinishOperation =>
      @finish()

  getCount: ->
    count = super
    if @isBackwards()
      -count
    else
      count

  getCaseSensitivity: ->
    if @getConfig("useSmartcaseFor#{@configScope}")
      'smartcase'
    else if @getConfig("ignoreCaseFor#{@configScope}")
      'insensitive'
    else
      'sensitive'

  isCaseSensitive: (term) ->
    switch @getCaseSensitivity()
      when 'smartcase' then term.search('[A-Z]') isnt -1
      when 'insensitive' then false
      when 'sensitive' then true

  finish: ->
    if @isIncrementalSearch() and @getConfig('showHoverSearchCounter')
      @vimState.hoverSearchCounter.reset()
    @relativeIndex = null
    @searchModel?.destroy()
    @searchModel = null

  getLandingPoint: ->
    @landingPoint ?= @defaultLandingPoint

  getPoint: (cursor) ->
    if @searchModel?
      @relativeIndex = @getCount() + @searchModel.getRelativeIndex()
    else
      @relativeIndex ?= @getCount()

    if range = @search(cursor, @input, @relativeIndex)
      point = range[@getLandingPoint()]

    @searchModel.destroy()
    @searchModel = null

    point

  moveCursor: (cursor) ->
    input = @input
    return unless input

    if point = @getPoint(cursor)
      cursor.setBufferPosition(point, autoscroll: false)

    unless @repeated
      @globalState.set('currentSearch', this)
      @vimState.searchHistory.save(input)

    if @updatelastSearchPattern
      @globalState.set('lastSearchPattern', @getPattern(input))

  getSearchModel: ->
    @searchModel ?= new SearchModel(@vimState, incrementalSearch: @isIncrementalSearch())

  search: (cursor, input, relativeIndex) ->
    searchModel = @getSearchModel()
    if input
      fromPoint = @getBufferPositionForCursor(cursor)
      return searchModel.search(fromPoint, @getPattern(input), relativeIndex)
    else
      @vimState.hoverSearchCounter.reset()
      searchModel.clearMarkers()

# /, ?
# -------------------------
class Search extends SearchBase
  @extend()
  configScope: "Search"
  requireInput: true

  initialize: ->
    super
    return if @isComplete() # When repeated, no need to get user input

    if @isIncrementalSearch()
      @restoreEditorState = saveEditorState(@editor)
      @onDidCommandSearch(@handleCommandEvent.bind(this))

    @onDidConfirmSearch(@handleConfirmSearch.bind(this))
    @onDidCancelSearch(@handleCancelSearch.bind(this))
    @onDidChangeSearch(@handleChangeSearch.bind(this))

    @focusSearchInputEditor()

  focusSearchInputEditor: ->
    classList = []
    classList.push('backwards') if @backwards
    @vimState.searchInput.focus({classList})

  handleCommandEvent: (commandEvent) ->
    return unless commandEvent.input
    switch commandEvent.name
      when 'visit'
        {direction} = commandEvent
        if @isBackwards() and @getConfig('incrementalSearchVisitDirection') is 'relative'
          direction = switch direction
            when 'next' then 'prev'
            when 'prev' then 'next'

        switch direction
          when 'next' then @getSearchModel().visit(+1)
          when 'prev' then @getSearchModel().visit(-1)

      when 'occurrence'
        {operation, input} = commandEvent
        @vimState.occurrenceManager.addPattern(@getPattern(input), reset: operation?)
        @vimState.occurrenceManager.saveLastPattern()

        @vimState.searchHistory.save(input)
        @vimState.searchInput.cancel()

        @vimState.operationStack.run(operation) if operation?

      when 'project-find'
        {input} = commandEvent
        @vimState.searchHistory.save(input)
        @vimState.searchInput.cancel()
        searchByProjectFind(@editor, input)

  handleCancelSearch: ->
    @vimState.resetNormalMode() unless @mode in ['visual', 'insert']
    @restoreEditorState?()
    @vimState.reset()
    @finish()

  isSearchRepeatCharacter: (char) ->
    if @isIncrementalSearch()
      char is ''
    else
      searchChar = if @isBackwards() then '?' else '/'
      char in ['', searchChar]

  handleConfirmSearch: ({@input, @landingPoint}) =>
    if @isSearchRepeatCharacter(@input)
      @input = @vimState.searchHistory.get('prev')
      atom.beep() unless @input
    @processOperation()

  handleChangeSearch: (input) ->
    # If input starts with space, remove first space and disable useRegexp.
    if input.startsWith(' ')
      input = input.replace(/^ /, '')
      @useRegexp = false
    @vimState.searchInput.updateOptionSettings({@useRegexp})

    if @isIncrementalSearch()
      @search(@editor.getLastCursor(), input, @getCount())

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

  moveCursor: (cursor) ->
    @input ?= (
      wordRange = @getCurrentWordBufferRange()
      if wordRange?
        @editor.setCursorBufferPosition(wordRange.start)
        @editor.getTextInBufferRange(wordRange)
      else
        ''
    )
    super

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
    @scanForward wordRegex, {from: [point.row, 0], allowNextLine: false}, ({range, stop}) ->
      if range.end.isGreaterThan(point)
        found = range
        stop()
    found

class SearchCurrentWordBackwards extends SearchCurrentWord
  @extend()
  backwards: true
