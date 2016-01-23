Delegato = require 'delegato'
_ = require 'underscore-plus'
{Emitter, Disposable, CompositeDisposable, Range, Point} = require 'atom'

{Hover} = require './hover'
{Input, SearchInput} = require './input'
settings = require './settings'
{haveSomeSelection, toggleClassByCondition} = require './utils'
swrap = require './selection-wrapper'

OperationStack = require './operation-stack'
CountManager = require './count-manager'
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

  constructor: (@editor, @statusBarManager) ->
    @editorElement = atom.views.getView(@editor)
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable

    @subscriptions.add @editor.onDidDestroy =>
      @destroy()

    @modeManager = new ModeManager(this)
    @count = new CountManager(this)
    @mark = new MarkManager(this)
    @register = new RegisterManager(this)
    @hover = new Hover(this)
    @hoverSearchCounter = new Hover(this)

    @searchHistory = new SearchHistoryManager(this)
    @input = new Input(this)
    @searchInput = new SearchInput(this)
    @operationStack = new OperationStack(this)
    @cursorStyleManager = new CursorStyleManager(this)
    @observeSelection()

    @editorElement.classList.add packageScope
    if settings.get('startInInsertMode')
      @activate('insert')
    else
      @activate('normal')

  subscribe: (args...) ->
    @operationStack.subscribe args...

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
  onWillExecuteOperation: (fn) -> @subscribe @emitter.on('will-execute-operation', fn)
  onDidExecuteOperation: (fn) -> @subscribe @emitter.on('did-execute-operation', fn)
  onDidFinishOperation: (fn) -> @subscribe @emitter.on('did-finish-operation', fn)

  # Select list view
  onDidConfirmSelectList: (fn) -> @subscribe @emitter.on('did-confirm-select-list', fn)
  onDidCancelSelectList: (fn) -> @subscribe @emitter.on('did-cancel-select-list', fn)

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

    {
      @hover, @hoverSearchCounter, @operationStack,
      @searchHistory, @cursorStyleManager
      @input, @search, @modeManager, @operationRecords
      @register
    } = {}

    {@editor, @editorElement, @subscriptions} = {}
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

  onDidFailToSetTarget: (fn) ->
    @emitter.on('did-fail-to-set-target', fn)

  onDidDestroy: (fn) ->
    @emitter.on('did-destroy', fn)

  reset: ->
    @count.reset()
    @register.reset()
    @searchHistory.reset()
    @hover.reset()
    @operationStack.reset()

  refreshCursors: ->
    @cursorStyleManager.refresh()
