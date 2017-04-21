Delegato = require 'delegato'
jQuery = null

{Emitter, Disposable, CompositeDisposable, Range} = require 'atom'

settings = require './settings'
ModeManager = require './mode-manager'

LazyLoadedLibs = {}

lazyRequire = (file) ->
  unless file of LazyLoadedLibs

    if atom.inDevMode() and settings.get('debug')
      console.log "# lazy-require: #{file}"
      # console.trace()

    LazyLoadedLibs[file] = require(file)
  LazyLoadedLibs[file]

module.exports =
class VimState
  @vimStatesByEditor: new Map

  @getByEditor: (editor) -> @vimStatesByEditor.get(editor)
  @has: (editor) -> @vimStatesByEditor.has(editor)
  @delete: (editor) -> @vimStatesByEditor.delete(editor)
  @forEach: (fn) -> @vimStatesByEditor.forEach(fn)
  @clear: -> @vimStatesByEditor.clear()

  Delegato.includeInto(this)
  @delegatesProperty('mode', 'submode', toProperty: 'modeManager')
  @delegatesMethods('isMode', 'activate', toProperty: 'modeManager')
  @delegatesMethods('flash', 'flashScreenRange', toProperty: 'flashManager')
  @delegatesMethods('subscribe', 'getCount', 'setCount', 'hasCount', 'addToClassList', toProperty: 'operationStack')

  @defineLazyProperty: (name, fileToLoad, instantiate=true) ->
    Object.defineProperty @prototype, name,
      get: -> this["__#{name}"] ?= do =>
        if instantiate
          new (lazyRequire(fileToLoad))(this)
        else
          lazyRequire(fileToLoad)

  getProp: (name) ->
    this[name] if this["__#{name}"]?

  @defineLazyProperty('swrap', './selection-wrapper', false)
  @defineLazyProperty('utils', './utils', false)

  @lazyProperties =
    mark: './mark-manager'
    register: './register-manager'
    hover: './hover-manager'
    hoverSearchCounter: './hover-manager'
    searchHistory: './search-history-manager'
    highlightSearch: './highlight-search-manager'
    persistentSelection: './persistent-selection-manager'
    occurrenceManager: './occurrence-manager'
    mutationManager: './mutation-manager'
    flashManager: './flash-manager'
    searchInput: './search-input'
    operationStack: './operation-stack'
    cursorStyleManager: './cursor-style-manager'

  for propName, fileToLoad of @lazyProperties
    @defineLazyProperty(propName, fileToLoad)

  reportRequireCache: ({focus, excludeNodModules}) ->
    {inspect} = require 'util'
    path = require 'path'
    packPath = atom.packages.getLoadedPackage("vim-mode-plus").path
    cachedPaths = Object.keys(require.cache)
      .filter (p) -> p.startsWith(packPath + path.sep)
      .map (p) -> p.replace(packPath, '')

    for cachedPath in cachedPaths
      if excludeNodModules and cachedPath.search(/node_modules/) >= 0
        continue
      if focus and cachedPath.search(///#{focus}///) >= 0
        cachedPath = '*' + cachedPath

      console.log cachedPath


  constructor: (@editor, @statusBarManager, @globalState) ->
    @editorElement = @editor.element
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @modeManager = new ModeManager(this)
    @previousSelection = {}
    @observeSelections()

    @editorElement.classList.add('vim-mode-plus')
    startInsertScopes = @getConfig('startInInsertModeScopes')

    if @getConfig('startInInsertMode') or startInsertScopes.length and @utils.matchScopes(@editorElement, startInsertScopes)
      @activate('insert')
    else
      @activate('normal')

    @editor.onDidDestroy(@destroy)
    @constructor.vimStatesByEditor.set(@editor, this)

  getConfig: (param) ->
    settings.get(param)

  # BlockwiseSelections
  # -------------------------
  getBlockwiseSelections: ->
    @swrap.getBlockwiseSelections(@editor)

  getLastBlockwiseSelection: ->
    @swrap.getLastBlockwiseSelections(@editor)

  getBlockwiseSelectionsOrderedByBufferPosition: ->
    @swrap.getBlockwiseSelectionsOrderedByBufferPosition(@editor)

  clearBlockwiseSelections: ->
    @getProp('swrap')?.clearBlockwiseSelections(@editor)

  # Other
  # -------------------------
  # FIXME: I want to remove this dengerious approach, but I couldn't find the better way.
  swapClassName: (classNames...) ->
    oldMode = @mode
    @editorElement.classList.remove('vim-mode-plus', oldMode + "-mode")
    @editorElement.classList.add(classNames...)

    new Disposable =>
      @editorElement.classList.remove(classNames...)
      classToAdd = ['vim-mode-plus', 'is-focused']
      if @mode is oldMode
        classToAdd.push(oldMode + "-mode")
      @editorElement.classList.add(classToAdd...)

  # All subscriptions here is celared on each operation finished.
  # -------------------------
  onDidChangeSearch: (fn) -> @subscribe @searchInput.onDidChange(fn)
  onDidConfirmSearch: (fn) -> @subscribe @searchInput.onDidConfirm(fn)
  onDidCancelSearch: (fn) -> @subscribe @searchInput.onDidCancel(fn)
  onDidCommandSearch: (fn) -> @subscribe @searchInput.onDidCommand(fn)

  # Select and text mutation(Change)
  onDidSetTarget: (fn) -> @subscribe @emitter.on('did-set-target', fn)
  emitDidSetTarget: (operator) -> @emitter.emit('did-set-target', operator)

  onWillSelectTarget: (fn) -> @subscribe @emitter.on('will-select-target', fn)
  emitWillSelectTarget: -> @emitter.emit('will-select-target')

  onDidSelectTarget: (fn) -> @subscribe @emitter.on('did-select-target', fn)
  emitDidSelectTarget: -> @emitter.emit('did-select-target')

  onDidFailSelectTarget: (fn) -> @subscribe @emitter.on('did-fail-select-target', fn)
  emitDidFailSelectTarget: -> @emitter.emit('did-fail-select-target')

  onWillFinishMutation: (fn) -> @subscribe @emitter.on('on-will-finish-mutation', fn)
  emitWillFinishMutation: -> @emitter.emit('on-will-finish-mutation')

  onDidFinishMutation: (fn) -> @subscribe @emitter.on('on-did-finish-mutation', fn)
  emitDidFinishMutation: -> @emitter.emit('on-did-finish-mutation')

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
  onDidFailToPushToOperationStack: (fn) -> @emitter.on('did-fail-to-push-to-operation-stack', fn)
  emitDidFailToPushToOperationStack: -> @emitter.emit('did-fail-to-push-to-operation-stack')

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
    @constructor.has(@editor)

  destroy: =>
    return unless @isAlive()
    @constructor.delete(@editor)
    @subscriptions.dispose()

    if @editor.isAlive()
      @resetNormalMode()
      @reset()
      @editorElement.component?.setInputEnabled(true)
      @editorElement.classList.remove('vim-mode-plus', 'normal-mode')

    {
      @hover, @hoverSearchCounter, @operationStack,
      @searchHistory, @cursorStyleManager
      @modeManager, @register
      @editor, @editorElement, @subscriptions,
      @occurrenceManager
      @previousSelection
      @persistentSelection
    } = {}
    @emitter.emit 'did-destroy'

  haveSomeNonEmptySelection: ->
    @editor.getSelections().some((selection) -> not selection.isEmpty())

  checkSelection: (event) ->
    return unless atom.workspace.getActiveTextEditor() is @editor
    return if @getProp('operationStack')?.isProcessing() # Don't populate lazy-prop on startup
    return if @mode is 'insert'
    # Intentionally using target.closest('atom-text-editor')
    # Don't use target.getModel() which is work for CustomEvent but not work for mouse event.
    return unless @editorElement is event.target?.closest?('atom-text-editor')
    return if event.type.startsWith('vim-mode-plus') # to match vim-mode-plus: and vim-mode-plus-user:

    if @haveSomeNonEmptySelection()
      @editorElement.component.updateSync()
      wise = @swrap.detectWise(@editor)
      if @isMode('visual', wise)
        for $selection in @swrap.getSelections(@editor)
          $selection.saveProperties()
        @cursorStyleManager.refresh()
      else
        @activate('visual', wise)
    else
      @activate('normal') if @mode is 'visual'

  observeSelections: ->
    checkSelection = @checkSelection.bind(this)
    @editorElement.addEventListener('mouseup', checkSelection)
    @subscriptions.add new Disposable =>
      @editorElement.removeEventListener('mouseup', checkSelection)

    @subscriptions.add atom.commands.onDidDispatch(checkSelection)

    @editorElement.addEventListener('focus', checkSelection)
    @subscriptions.add new Disposable =>
      @editorElement.removeEventListener('focus', checkSelection)

  # What's this?
  # editor.clearSelections() doesn't respect lastCursor positoin.
  # This method works in same way as editor.clearSelections() but respect last cursor position.
  clearSelections: ->
    @editor.setCursorBufferPosition(@editor.getCursorBufferPosition())

  resetNormalMode: ({userInvocation}={}) ->
    @clearBlockwiseSelections()

    if userInvocation ? false
      switch
        when @editor.hasMultipleCursors()
          @clearSelections()
        when @hasPersistentSelections() and @getConfig('clearPersistentSelectionOnResetNormalMode')
          @clearPersistentSelections()
        when @getProp('occurrenceManager')?.hasPatterns()
          @occurrenceManager.resetPatterns()

      if @getConfig('clearHighlightSearchOnResetNormalMode')
        @globalState.set('highlightSearchPattern', null)
    else
      @clearSelections()
    @activate('normal')

  init: ->
    @saveOriginalCursorPosition()

  reset: ->
    # Don't populate lazy-prop on startup
    @getProp('register')?.reset()
    @getProp('searchHistory')?.reset()
    @getProp('hover')?.reset()
    @getProp('operationStack')?.reset()
    @getProp('mutationManager')?.reset()

  isVisible: ->
    @editor in @utils.getVisibleEditors()

  # FIXME: naming, updateLastSelectedInfo ?
  updatePreviousSelection: ->
    if @isMode('visual', 'blockwise')
      properties = @getLastBlockwiseSelection()?.getProperties()
    else
      properties = @swrap(@editor.getLastSelection()).getProperties()

    # TODO#704 when cursor is added in visual-mode, corresponding selection prop yet not exists.
    return unless properties

    {head, tail} = properties

    if head.isGreaterThanOrEqual(tail)
      [start, end] = [tail, head]
      head = end = @utils.translatePointAndClip(@editor, end, 'forward')
    else
      [start, end] = [head, tail]
      tail = end = @utils.translatePointAndClip(@editor, end, 'forward')

    @mark.set('<', start)
    @mark.set('>', end)
    @previousSelection = {properties: {head, tail}, @submode}

  # Persistent selection
  # -------------------------
  hasPersistentSelections: ->
    @getProp('persistentSelection')?.hasMarkers()

  getPersistentSelectionBufferRanges: ->
    @getProp('persistentSelection')?.getMarkerBufferRanges() ? []

  clearPersistentSelections: ->
    @getProp('persistentSelection')?.clearMarkers()

  # Animation management
  # -------------------------
  scrollAnimationEffect: null
  requestScrollAnimation: (from, to, options) ->
    jQuery ?= require('atom-space-pen-views').jQuery
    @scrollAnimationEffect = jQuery(from).animate(to, options)

  finishScrollAnimation: ->
    @scrollAnimationEffect?.finish()
    @scrollAnimationEffect = null

  # Other
  # -------------------------
  saveOriginalCursorPosition: ->
    @originalCursorPosition = null
    @originalCursorPositionByMarker?.destroy()

    if @mode is 'visual'
      selection = @editor.getLastSelection()
      point = @swrap(selection).getBufferPositionFor('head', from: ['property', 'selection'])
    else
      point = @editor.getCursorBufferPosition()
    @originalCursorPosition = point
    @originalCursorPositionByMarker = @editor.markBufferPosition(point, invalidate: 'never')

  restoreOriginalCursorPosition: ->
    @editor.setCursorBufferPosition(@getOriginalCursorPosition())

  getOriginalCursorPosition: ->
    @originalCursorPosition

  getOriginalCursorPositionByMarker: ->
    @originalCursorPositionByMarker.getStartBufferPosition()
