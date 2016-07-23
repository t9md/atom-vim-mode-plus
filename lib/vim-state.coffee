Delegato = require 'delegato'
_ = require 'underscore-plus'
{Emitter, Disposable, CompositeDisposable, Range} = require 'atom'

settings = require './settings'
globalState = require './global-state'
{HoverElement} = require './hover'
{InputElement, SearchInputElement} = require './input'
{haveSomeSelection, highlightRanges, getVisibleBufferRange, matchScopes} = require './utils'
swrap = require './selection-wrapper'

OperationStack = require './operation-stack'
MarkManager = require './mark-manager'
ModeManager = require './mode-manager'
RegisterManager = require './register-manager'
SearchHistoryManager = require './search-history-manager'
CursorStyleManager = require './cursor-style-manager'
BlockwiseSelection = null # delay

packageScope = 'vim-mode-plus'

module.exports =
class VimState
  Delegato.includeInto(this)
  destroyed: false

  @delegatesProperty('mode', 'submode', toProperty: 'modeManager')
  @delegatesMethods('isMode', 'activate', toProperty: 'modeManager')

  constructor: (@main, @editor, @statusBarManager) ->
    @editorElement = atom.views.getView(@editor)
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @modeManager = new ModeManager(this)
    @mark = new MarkManager(this)
    @register = new RegisterManager(this)
    @rangeMarkers = []

    @hover = new HoverElement().initialize(this)
    @hoverSearchCounter = new HoverElement().initialize(this)
    @searchHistory = new SearchHistoryManager(this)

    @input = new InputElement().initialize(this)
    @searchInput = new SearchInputElement().initialize(this)

    @operationStack = new OperationStack(this)
    @cursorStyleManager = new CursorStyleManager(this)
    @blockwiseSelections = []
    @observeSelection()

    @highlightSearchSubscription = @editorElement.onDidChangeScrollTop =>
      @refreshHighlightSearch()

    @editorElement.classList.add(packageScope)
    if settings.get('startInInsertMode') or matchScopes(@editorElement, settings.get('startInInsertModeScopes'))
      @activate('insert')
    else
      @activate('normal')

  subscribe: (args...) ->
    @operationStack.subscribe args...

  # BlockwiseSelections
  # -------------------------
  getBlockwiseSelections: ->
    @blockwiseSelections

  getLastBlockwiseSelection: ->
    _.last(@blockwiseSelections)

  getBlockwiseSelectionsOrderedByBufferPosition: ->
    @getBlockwiseSelections().sort (a, b) ->
      a.getStartSelection().compare(b.getStartSelection())

  clearBlockwiseSelections: ->
    @blockwiseSelections = []

  addBlockwiseSelectionFromSelection: (selection) ->
    BlockwiseSelection ?= require './blockwise-selection'
    @blockwiseSelections.push(new BlockwiseSelection(selection))

  selectBlockwise: ->
    for selection in @editor.getSelections()
      @addBlockwiseSelectionFromSelection(selection)
    @updateSelectionProperties()

  # Other
  # -------------------------
  selectLinewise: ->
    swrap.expandOverLine(@editor, preserveGoalColumn: true)

  forceOperatorWise: null
  setForceOperatorWise: (@forceOperatorWise) ->
  getForceOperatorWise: -> @forceOperatorWise
  resetForceOperatorWise: -> @setForceOperatorWise(null)

  # Count
  # -------------------------
  # keystroke `3d2w` delete 6(3*2) words
  #  Each time, operation instantiated(new Operation), count are preserved.
  #  pushed to @counts, then while operation executed, operation::getCount()
  #  call vimState::getCount which return multiplied value for each of preserved counts.
  count: null
  counts: []
  hasCount: -> @count?
  preserveCount: ->
    if @hasCount()
      @counts.push(@count)
      @count = null

  getCount: ->
    if @counts.length > 0
      @counts.reduce (a, b) -> a * b
    else
      null

  setCount: (number) ->
    @count ?= 0
    @count = (@count * 10) + number
    @hover.add(number)
    @toggleClassList('with-count', @hasCount())

  resetCount: ->
    @count = null
    @counts = []
    @toggleClassList('with-count', @hasCount())

  # Mark
  # -------------------------
  startCharInput: (@charInputAction) ->
    @inputCharSubscriptions = new CompositeDisposable()
    @inputCharSubscriptions.add @swapClassName('vim-mode-plus-input-char-waiting')
    @inputCharSubscriptions.add atom.commands.add @editorElement,
      'core:cancel': => @resetCharInput()

  setInputChar: (char) ->
    switch @charInputAction
      when 'save-mark'
        @mark.set(char, @editor.getCursorBufferPosition())
      when 'move-to-mark'
        @operationStack.run("MoveToMark", input: char)
      when 'move-to-mark-line'
        @operationStack.run("MoveToMarkLine", input: char)
    @resetCharInput()

  resetCharInput: ->
    @inputCharSubscriptions?.dispose()

  # -------------------------
  toggleClassList: (className, bool) ->
    @editorElement.classList.toggle(className, bool)

  swapClassName: (className) ->
    oldClassName = @editorElement.className
    @editorElement.className = className
    new Disposable =>
      @editorElement.className = oldClassName

  # All subscriptions here is celared on each operation finished.
  # -------------------------
  onDidChangeInput: (fn) -> @subscribe @input.onDidChange(fn)
  onDidConfirmInput: (fn) -> @subscribe @input.onDidConfirm(fn)
  onDidCancelInput: (fn) -> @subscribe @input.onDidCancel(fn)
  onDidUnfocusInput: (fn) -> @subscribe @input.onDidUnfocus(fn)
  onDidCommandInput: (fn) -> @subscribe @input.onDidCommand(fn)

  onDidChangeSearch: (fn) -> @subscribe @searchInput.onDidChange(fn)
  onDidConfirmSearch: (fn) -> @subscribe @searchInput.onDidConfirm(fn)
  onDidCancelSearch: (fn) -> @subscribe @searchInput.onDidCancel(fn)
  onDidUnfocusSearch: (fn) -> @subscribe @searchInput.onDidUnfocus(fn)
  onDidCommandSearch: (fn) -> @subscribe @searchInput.onDidCommand(fn)

  # Select and text mutation(Change)
  onWillSelectTarget: (fn) -> @subscribe @emitter.on('will-select-target', fn)
  onDidSelectTarget: (fn) -> @subscribe @emitter.on('did-select-target', fn)
  onDidSetTarget: (fn) -> @subscribe @emitter.on('did-set-target', fn)

  # Event for operation execution life cycle.
  onDidFinishOperation: (fn) -> @subscribe @emitter.on('did-finish-operation', fn)

  # Select list view
  onDidConfirmSelectList: (fn) -> @subscribe @emitter.on('did-confirm-select-list', fn)
  onDidCancelSelectList: (fn) -> @subscribe @emitter.on('did-cancel-select-list', fn)

  # Events
  # -------------------------
  onDidFailToSetTarget: (fn) -> @emitter.on('did-fail-to-set-target', fn)
  onDidDestroy: (fn) -> @emitter.on('did-destroy', fn)

  # * `fn` {Function} to be called when mark was set.
  #   * `name` Name of mark such as 'a'.
  #   * `bufferPosition`: bufferPosition where mark was set.
  #   * `editor`: editor where mark was set.
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  #
  #  Usage:
  #   onDidSetMark ({name, bufferPosition}) -> do something..
  onDidSetMark: (fn) -> @emitter.on('did-set-mark', fn)

  destroy: ->
    return if @destroyed
    @destroyed = true
    @subscriptions.dispose()

    if @editor.isAlive()
      @resetNormalMode()
      @reset()
      @editorElement.component?.setInputEnabled(true)
      @editorElement.classList.remove(packageScope, 'normal-mode')

    @hover?.destroy?()
    @hoverSearchCounter?.destroy?()
    @operationStack?.destroy?()
    @searchHistory?.destroy?()
    @cursorStyleManager?.destroy?()
    @input?.destroy?()
    @search?.destroy?()
    @modeManager?.destroy?()
    @operationRecords?.destroy?()
    @register?.destroy?
    @clearHighlightSearch()
    @highlightSearchSubscription?.dispose()
    {
      @hover, @hoverSearchCounter, @operationStack,
      @searchHistory, @cursorStyleManager
      @input, @search, @modeManager, @operationRecords, @register
      @count, @rangeMarkers
      @editor, @editorElement, @subscriptions,
      @inputCharSubscriptions
      @highlightSearchSubscription
    } = {}
    @emitter.emit 'did-destroy'

  observeSelection: ->
    isInterestingEvent = ({target, type}) =>
      if @mode is 'insert'
        false
      else
        @editor? and
          target is @editorElement and
          not @isMode('visual', 'blockwise') and
          not type.startsWith('vim-mode-plus:')

    onInterestingEvent = (fn) ->
      (event) -> fn() if isInterestingEvent(event)

    _checkSelection = =>
      return if @operationStack.isProcessing()
      if haveSomeSelection(@editor)
        submode = swrap.detectVisualModeSubmode(@editor)
        if @isMode('visual', submode)
          @updateCursorsVisibility()
        else
          @activate('visual', submode)
      else
        @activate('normal') if @isMode('visual')

    _preserveCharacterwise = =>
      for selection in @editor.getSelections()
        swrap(selection).preserveCharacterwise()

    checkSelection = onInterestingEvent(_checkSelection)
    preserveCharacterwise = onInterestingEvent(_preserveCharacterwise)

    @editorElement.addEventListener('mouseup', checkSelection)
    @subscriptions.add new Disposable =>
      @editorElement.removeEventListener('mouseup', checkSelection)
    @subscriptions.add atom.commands.onWillDispatch(preserveCharacterwise)
    @subscriptions.add atom.commands.onDidDispatch(checkSelection)

  resetNormalMode: ->
    @editor.clearSelections()
    @activate('normal')
    @main.clearRangeMarkerForEditors() if settings.get('clearRangeMarkerOnResetNormalMode')
    @main.clearHighlightSearchForEditors() if settings.get('clearHighlightSearchOnResetNormalMode')

  reset: ->
    @resetCount()
    @resetCharInput()
    @resetForceOperatorWise()
    @register.reset()
    @searchHistory.reset()
    @hover.reset()
    @operationStack.reset()

  updateCursorsVisibility: ->
    @cursorStyleManager.refresh()

  updateSelectionProperties: ({force}={}) ->
    selections = @editor.getSelections()
    unless (force ? true)
      selections = selections.filter (selection) ->
        not swrap(selection).getCharacterwiseHeadPosition()?

    for selection in selections
      swrap(selection).preserveCharacterwise()

  # highlightSearch
  # -------------------------
  clearHighlightSearch: ->
    for marker in @highlightSearchMarkers ? []
      marker.destroy()
    @highlightSearchMarkers = null

  hasHighlightSearch: ->
    @highlightSearchMarkers?

  getHighlightSearch: ->
    @highlightSearchMarkers

  highlightSearch: (pattern, scanRange) ->
    ranges = []
    @editor.scanInBufferRange pattern, scanRange, ({range}) ->
      ranges.push(range)
    markers = highlightRanges @editor, ranges,
      invalidate: 'inside'
      class: 'vim-mode-plus-highlight-search'
    markers

  refreshHighlightSearch: ->
    [startRow, endRow] = @editorElement.getVisibleRowRange()
    return unless scanRange = getVisibleBufferRange(@editor)
    @clearHighlightSearch()
    return if matchScopes(@editorElement, settings.get('highlightSearchExcludeScopes'))

    if settings.get('highlightSearch') and @main.highlightSearchPattern?
      @highlightSearchMarkers = @highlightSearch(@main.highlightSearchPattern, scanRange)

  # rangeMarkers for narrowRange
  # -------------------------
  addRangeMarkers: (markers) ->
    @rangeMarkers.push(markers...)
    @toggleClassList('with-range-marker', @hasRangeMarkers())

  hasRangeMarkers: ->
    @rangeMarkers.length > 0

  getRangeMarkers: (markers) ->
    @rangeMarkers

  clearRangeMarkers: ->
    marker.destroy() for marker in @rangeMarkers
    @rangeMarkers = []
    @toggleClassList('with-range-marker', @hasRangeMarkers())
