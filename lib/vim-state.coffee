Delegato = require 'delegato'
_ = require 'underscore-plus'
{Emitter, Disposable, CompositeDisposable, Range, Point} = require 'atom'
{basename} = require 'path'

{Hover} = require './hover'
{Input, SearchInput} = require './input'
settings = require './settings'
{haveSomeSelection, highlightRanges, getVisibleBufferRange} = require './utils'
swrap = require './selection-wrapper'
globalState = require './global-state'

OperationStack = require './operation-stack'
MarkManager = require './mark-manager'
ModeManager = require './mode-manager'
RegisterManager = require './register-manager'
SearchHistoryManager = require './search-history-manager'
CursorStyleManager = require './cursor-style-manager'

packageScope = 'vim-mode-plus'

module.exports =
class VimState
  Delegato.includeInto(this)
  destroyed: false

  @delegatesProperty 'mode', 'submode', toProperty: 'modeManager'
  @delegatesMethods 'isMode', 'activate', toProperty: 'modeManager'

  constructor: (@main, @editor, @statusBarManager) ->
    @editorElement = atom.views.getView(@editor)
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @modeManager = new ModeManager(this)
    @count = null
    @mark = new MarkManager(this)
    @register = new RegisterManager(this)
    @hover = new Hover(this)
    @hoverSearchCounter = new Hover(this)

    @searchHistory = new SearchHistoryManager(this)
    @input = new Input(this)
    @searchInput = new SearchInput(this)
    @operationStack = new OperationStack(this)
    @cursorStyleManager = new CursorStyleManager(this)
    @blockwiseSelections = []
    @observeSelection()

    @highlightSearchSubscription = @editorElement.onDidChangeScrollTop =>
      @refreshHighlightSearch()

    @editorElement.classList.add packageScope
    if settings.get('startInInsertMode')
      @activate('insert')
    else
      @activate('normal')

  subscribe: (args...) ->
    @operationStack.subscribe args...

  # BlockwiseSelections
  # -------------------------
  getBlockwiseSelections: ->
    @blockwiseSelections

  getLastBlockwiseSelections: ->
    _.last(@blockwiseSelections)

  getBlockwiseSelectionsOrderedByBufferPosition: ->
    @getBlockwiseSelections().sort (a, b) ->
      a.getTop().compare(b.getTop())

  clearBlockwiseSelections: ->
    @blockwiseSelections = []

  addBlockwiseSelection: (blockwiseSelection) ->
    @blockwiseSelections.push(blockwiseSelection)

  # Count
  # -------------------------
  getCount: ->
    @count

  hasCount: ->
    @count?

  setCount: (number) ->
    @count ?= 0
    @count = (@count * 10) + number
    @hover.add number
    @updateEditorElement()

  resetCount: ->
    @count = null
    @updateEditorElement()

  updateEditorElement: (kind) ->
    @editorElement.classList.toggle('with-count', @hasCount())

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

  destroy: ->
    return if @destroyed
    @destroyed = true
    @subscriptions.dispose()

    if @editor.isAlive()
      @activate('normal') # reset to base mdoe.
      @editorElement.component?.setInputEnabled(true)
      @editorElement.classList.remove packageScope, 'normal-mode'

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
      @count
      @editor, @editorElement, @subscriptions,
      @highlightSearchSubscription
    } = {}
    @emitter.emit 'did-destroy'

  observeSelection: ->
    handleSelectionChange = =>
      return unless @editor?
      return if @operationStack.isProcessing()

      if haveSomeSelection(@editor)
        @activate('visual', 'characterwise') if @isMode('normal')
      else
        @activate('normal') if @isMode('visual')

    selectionWatcher = null
    handleMouseDown = =>
      selectionWatcher?.dispose()
      point = @editor.getLastCursor().getBufferPosition()
      tailRange = Range.fromPointWithDelta(point, 0, +1)
      selectionWatcher = @editor.onDidChangeSelectionRange ({selection}) =>
        handleSelectionChange()
        selection.setBufferRange(selection.getBufferRange().union(tailRange))
        @refreshCursors()

    handleMouseUp = ->
      selectionWatcher?.dispose()
      selectionWatcher = null

    @editorElement.addEventListener 'mousedown', handleMouseDown
    @editorElement.addEventListener 'mouseup', handleMouseUp
    @subscriptions.add new Disposable =>
      @editorElement.removeEventListener 'mousedown', handleMouseDown
      @editorElement.removeEventListener 'mouseup', handleMouseUp

    @subscriptions.add atom.commands.onDidDispatch ({target, type}) =>
      if target is @editorElement and not type.startsWith('vim-mode-plus:')
        handleSelectionChange() unless selectionWatcher?

  reset: ->
    @resetCount()
    @register.reset()
    @searchHistory.reset()
    @hover.reset()
    @operationStack.reset()

  refreshCursors: ->
    @cursorStyleManager.refresh()

  # highlightSearch
  # -------------------------
  clearHighlightSearch: ->
    for marker in @highlightSearchMarkers ? []
      marker.destroy()
    @highlightSearchMarkers = null

  highlightSearch: ->
    scanRange = getVisibleBufferRange(@editor)
    pattern = globalState.highlightSearchPattern
    ranges = []
    @editor.scanInBufferRange pattern, scanRange, ({range}) ->
      ranges.push(range)

    highlightRanges @editor, ranges,
      class: 'vim-mode-plus-highlight-search'

  refreshHighlightSearch: ->
    # NOTE: endRow become undefined if @editorElement is not yet attached.
    # e.g. Beging called immediately after open file.
    [startRow, endRow] = @editorElement.getVisibleRowRange()
    return unless (startRow? and endRow?)

    @clearHighlightSearch() if @highlightSearchMarkers
    if settings.get('highlightSearch') and globalState.highlightSearchPattern?
      @highlightSearchMarkers = @highlightSearch()
