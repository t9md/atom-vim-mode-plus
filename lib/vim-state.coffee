semver = require 'semver'
Delegato = require 'delegato'
{jQuery} = require 'atom-space-pen-views'

_ = require 'underscore-plus'
{Emitter, Disposable, CompositeDisposable, Range} = require 'atom'

settings = require './settings'
{HoverElement} = require './hover'
SearchInputElement = require './search-input'
{
  getVisibleEditors
  matchScopes

  debug
} = require './utils'
swrap = require './selection-wrapper'

OperationStack = require './operation-stack'
MarkManager = require './mark-manager'
ModeManager = require './mode-manager'
RegisterManager = require './register-manager'
SearchHistoryManager = require './search-history-manager'
CursorStyleManager = require './cursor-style-manager'
BlockwiseSelection = require './blockwise-selection'
OccurrenceManager = require './occurrence-manager'
HighlightSearchManager = require './highlight-search-manager'
MutationManager = require './mutation-manager'
PersistentSelectionManager = require './persistent-selection-manager'
FlashManager = require './flash-manager'

packageScope = 'vim-mode-plus'

module.exports =
class VimState
  @vimStatesByEditor: new Map

  @getByEditor: (editor) ->
    @vimStatesByEditor.get(editor)

  @forEach: (fn) ->
    @vimStatesByEditor.forEach(fn)

  @clear: ->
    @vimStatesByEditor.clear()

  Delegato.includeInto(this)

  @delegatesProperty('mode', 'submode', toProperty: 'modeManager')
  @delegatesMethods('isMode', 'activate', toProperty: 'modeManager')
  @delegatesMethods('flash', 'flashScreenRange', toProperty: 'flashManager')
  @delegatesMethods('subscribe', 'getCount', 'setCount', 'hasCount', 'addToClassList', toProperty: 'operationStack')

  constructor: (@editor, @statusBarManager, @globalState) ->
    @editorElement = @editor.element
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @modeManager = new ModeManager(this)
    @mark = new MarkManager(this)
    @register = new RegisterManager(this)
    @hover = new HoverElement().initialize(this)
    @hoverSearchCounter = new HoverElement().initialize(this)
    @searchHistory = new SearchHistoryManager(this)
    @highlightSearch = new HighlightSearchManager(this)
    @persistentSelection = new PersistentSelectionManager(this)
    @occurrenceManager = new OccurrenceManager(this)
    @mutationManager = new MutationManager(this)
    @flashManager = new FlashManager(this)

    @searchInput = new SearchInputElement().initialize(this)

    @operationStack = new OperationStack(this)
    @cursorStyleManager = new CursorStyleManager(this)
    @blockwiseSelections = []
    @previousSelection = {}
    @observeSelections()

    refreshHighlightSearch = =>
      @highlightSearch.refresh()
    @subscriptions.add @editor.onDidStopChanging(refreshHighlightSearch)

    @editorElement.classList.add(packageScope)
    if settings.get('startInInsertMode') or matchScopes(@editorElement, settings.get('startInInsertModeScopes'))
      @activate('insert')
    else
      @activate('normal')

    @subscriptions.add @editor.onDidDestroy(@destroy.bind(this))
    @constructor.vimStatesByEditor.set(@editor, this)

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

  selectBlockwise: ->
    for selection in @editor.getSelections()
      @blockwiseSelections.push(new BlockwiseSelection(selection))
    @updateSelectionProperties()
    @getLastBlockwiseSelection().autoscrollIfReversed()

  # Other
  # -------------------------
  selectLinewise: ->
    swrap.expandOverLine(@editor, preserveGoalColumn: true)

  updateSelectionProperties: (options) ->
    swrap.updateSelectionProperties(@editor, options)

  # -------------------------
  toggleClassList: (className, bool=undefined) ->
    @editorElement.classList.toggle(className, bool)

  # FIXME: remove this dengerous approarch ASAP and revert to read-inpu-via-mini-editor
  swapClassName: (classNames...) ->
    oldMode = @mode
    @editorElement.classList.remove(oldMode + "-mode")
    @editorElement.classList.remove('vim-mode-plus')
    @editorElement.classList.add(classNames...)

    new Disposable =>
      @editorElement.classList.remove(classNames...)
      if @mode is oldMode
        @editorElement.classList.add(oldMode + "-mode")
      @editorElement.classList.add('vim-mode-plus')
      @editorElement.classList.add('is-focused')

  # All subscriptions here is celared on each operation finished.
  # -------------------------
  onDidChangeSearch: (fn) -> @subscribe @searchInput.onDidChange(fn)
  onDidConfirmSearch: (fn) -> @subscribe @searchInput.onDidConfirm(fn)
  onDidCancelSearch: (fn) -> @subscribe @searchInput.onDidCancel(fn)
  onDidCommandSearch: (fn) -> @subscribe @searchInput.onDidCommand(fn)

  # Select and text mutation(Change)
  onDidSetTarget: (fn) -> @subscribe @emitter.on('did-set-target', fn)
  onWillSelectTarget: (fn) -> @subscribe @emitter.on('will-select-target', fn)
  onDidSelectTarget: (fn) -> @subscribe @emitter.on('did-select-target', fn)
  preemptWillSelectTarget: (fn) -> @subscribe @emitter.preempt('will-select-target', fn)
  preemptDidSelectTarget: (fn) -> @subscribe @emitter.preempt('did-select-target', fn)
  onDidRestoreCursorPositions: (fn) -> @subscribe @emitter.on('did-restore-cursor-positions', fn)

  onDidSetOperatorModifier: (fn) -> @subscribe @emitter.on('did-set-operator-modifier', fn)
  emitDidSetOperatorModifier: (options) -> @emitter.emit('did-set-operator-modifier', options)

  onDidFinishOperation: (fn) -> @subscribe @emitter.on('did-finish-operation', fn)
  emitDidFinishOperation: -> @emitter.emit('did-finish-operation')

  onDidResetOperationStack: (fn) -> @subscribe @emitter.on('did-reset-operation-stack', fn)
  emitDidResetOperationStack: -> @emitter.emit('did-reset-operation-stack')

  # Select list view
  onDidConfirmSelectList: (fn) -> @subscribe @emitter.on('did-confirm-select-list', fn)
  onDidCancelSelectList: (fn) -> @subscribe @emitter.on('did-cancel-select-list', fn)

  # Proxying modeManger's event hook with short-life subscription.
  onWillActivateMode: (fn) -> @subscribe @modeManager.onWillActivateMode(fn)
  onDidActivateMode: (fn) -> @subscribe @modeManager.onDidActivateMode(fn)
  onWillDeactivateMode: (fn) -> @subscribe @modeManager.onWillDeactivateMode(fn)
  preemptWillDeactivateMode: (fn) -> @subscribe @modeManager.preemptWillDeactivateMode(fn)
  onDidDeactivateMode: (fn) -> @subscribe @modeManager.onDidDeactivateMode(fn)

  # Events
  # -------------------------
  onDidFailToSetTarget: (fn) -> @emitter.on('did-fail-to-set-target', fn)
  emitDidFailToSetTarget: -> @emitter.emit('did-fail-to-set-target')

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

  onDidSetInputChar: (fn) -> @emitter.on('did-set-input-char', fn)
  emitDidSetInputChar: (char) -> @emitter.emit('did-set-input-char', char)

  isAlive: ->
    @constructor.vimStatesByEditor.has(@editor)

  destroy: ->
    return unless @isAlive()
    @constructor.vimStatesByEditor.delete(@editor)

    @subscriptions.dispose()

    if @editor.isAlive()
      @resetNormalMode()
      @reset()
      @editorElement.component?.setInputEnabled(true)
      @editorElement.classList.remove(packageScope, 'normal-mode')

    @hover?.destroy?()
    @hoverSearchCounter?.destroy?()
    @searchHistory?.destroy?()
    @cursorStyleManager?.destroy?()
    @search?.destroy?()
    @register?.destroy?
    {
      @hover, @hoverSearchCounter, @operationStack,
      @searchHistory, @cursorStyleManager
      @search, @modeManager, @register
      @editor, @editorElement, @subscriptions,
      @occurrenceManager
      @previousSelection
      @persistentSelection
    } = {}
    @emitter.emit 'did-destroy'

  isInterestingEvent: ({target, type}) ->
    if @mode is 'insert'
      false
    else
      @editor? and
        target?.closest?('atom-text-editor') is @editorElement and
        not @isMode('visual', 'blockwise') and
        not type.startsWith('vim-mode-plus:')

  checkSelection: (event) ->
    return if @operationStack.isProcessing()
    return unless @isInterestingEvent(event)

    nonEmptySelecitons = @editor.getSelections().filter (selection) -> not selection.isEmpty()
    if nonEmptySelecitons.length
      submode = swrap.detectVisualModeSubmode(@editor)
      if @isMode('visual', submode)
        for selection in nonEmptySelecitons when not swrap(selection).hasProperties()
          swrap(selection).saveProperties()
        @updateCursorsVisibility()
      else
        @activate('visual', submode)
    else
      @activate('normal') if @isMode('visual')

  saveProperties: (event) ->
    return unless @isInterestingEvent(event)
    for selection in @editor.getSelections()
      swrap(selection).saveProperties()

  observeSelections: ->
    checkSelection = @checkSelection.bind(this)
    @editorElement.addEventListener('mouseup', checkSelection)
    @subscriptions.add new Disposable =>
      @editorElement.removeEventListener('mouseup', checkSelection)

    # [FIXME]
    # Hover position get wired when focus-change between more than two pane.
    # commenting out is far better than introducing Buggy behavior.
    # @subscriptions.add atom.commands.onWillDispatch(saveProperties)
    @subscriptions.add atom.commands.onDidDispatch(checkSelection)

  # What's this?
  # editor.clearSelections() doesn't respect lastCursor positoin.
  # This method works in same way as editor.clearSelections() but respect last cursor position.
  clearSelections: ->
    @editor.setCursorBufferPosition(@editor.getCursorBufferPosition())

  resetNormalMode: ({userInvocation}={}) ->
    if userInvocation ? false
      if @editor.hasMultipleCursors()
        @clearSelections()

      else if @hasPersistentSelections() and settings.get('clearPersistentSelectionOnResetNormalMode')
        @clearPersistentSelections()
      else if @occurrenceManager.hasPatterns()
        @occurrenceManager.resetPatterns()

      if settings.get('clearHighlightSearchOnResetNormalMode')
        @globalState.set('highlightSearchPattern', null)
    else
      @clearSelections()
    @activate('normal')

  init: ->
    @saveOriginalCursorPosition()

  reset: ->
    @resetOriginalCursorPosition()
    @register.reset()
    @searchHistory.reset()
    @hover.reset()
    @operationStack.reset()
    @mutationManager.reset()

  isVisible: ->
    @editor in getVisibleEditors()

  updateCursorsVisibility: ->
    @cursorStyleManager.refresh()

  updatePreviousSelection: -> # FIXME: naming, updateLastSelectedInfo ?
    if @isMode('visual', 'blockwise')
      properties = @getLastBlockwiseSelection()?.getCharacterwiseProperties()
    else
      properties = swrap(@editor.getLastSelection()).captureProperties()

    return unless properties?

    {head, tail} = properties
    if head.isGreaterThan(tail)
      @mark.setRange('<', '>', [tail, head])
    else
      @mark.setRange('<', '>', [head, tail])
    @previousSelection = {properties, @submode}

  # Persistent selection
  # -------------------------
  hasPersistentSelections: ->
    @persistentSelection.hasMarkers()

  getPersistentSelectionBufferRanges: ->
    @persistentSelection.getMarkerBufferRanges()

  clearPersistentSelections: ->
    @persistentSelection.clearMarkers()

  # Animation management
  # -------------------------
  scrollAnimationEffect: null
  requestScrollAnimation: (from, to, options) ->
    @scrollAnimationEffect = jQuery(from).animate(to, options)

  finishScrollAnimation: ->
    @scrollAnimationEffect?.finish()
    @scrollAnimationEffect = null

  # Other
  # -------------------------
  saveOriginalCursorPosition: ->
    if @mode is 'visual'
      options = {fromProperty: true, allowFallback: true}
      @originalCursorPosition = swrap(@editor.getLastSelection()).getBufferPositionFor('head', options)
    else
      @originalCursorPosition = @editor.getCursorBufferPosition()

  getOriginalCursorPosition: ->
    @originalCursorPosition

  resetOriginalCursorPosition: ->
    @originalCursorPosition = null
