# Refactoring status: 100%
Delegato = require 'delegato'
_ = require 'underscore-plus'
{Emitter, Disposable, CompositeDisposable, Range} = require 'atom'

{Hover} = require './hover'
{Input, Search} = require './input'
settings = require './settings'
{haveSomeSelection, toggleClassByCondition} = require './utils'
swrap = require './selection-wrapper'

OperationStack = require './operation-stack'
CountManager = require './count-manager'
MarkManager = require './mark-manager'
ModeManager = require './mode-manager'
RegisterManager = require './register-manager'
SearchHistoryManager = require './search-history-manager'
FlashManager = require './flash-manager'

packageScope = 'vim-mode-plus'

# Mode handling is delegated to modeManager
delegatingMethods = ['isMode', 'activate', 'setInsertionCheckpoint']
delegatingProperties = ['mode', 'submode']

module.exports =
class VimState
  Delegato.includeInto(this)
  destroyed: false

  @delegatesProperty delegatingProperties..., toProperty: 'modeManager'
  @delegatesMethods delegatingMethods..., toProperty: 'modeManager'

  constructor: (@editor, @statusBarManager) ->
    @editorElement = atom.views.getView(@editor)
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @subscriptions.add @editor.onDidDestroy =>
      @destroy()

    @count = new CountManager(this)
    @mark = new MarkManager(this)
    @register = new RegisterManager(this)
    @flasher = new FlashManager(this)
    @lastPositionInInsertMode = null

    # FIXME: Direct reference for config param name.
    # Handle with config onDidChange subscription?
    @hover = new Hover(this, 'showHoverOnOperate')
    @hoverSearchCounter = new Hover(this, 'showHoverSearchCounter')

    @searchHistory = new SearchHistoryManager(this)
    @input = new Input(this)
    @search = new Search(this)
    @operationStack = new OperationStack(this)
    @modeManager = new ModeManager(this)
    @observeSelection()

    @editorElement.classList.add packageScope
    if settings.get('startInInsertMode')
      @activate('insert')
    else
      @activate('normal')

  saveLastPositionInInsertMode: (@lastPositionInInsertMode) ->

  getLastPositionInInsertMode: ->
    @lastPositionInInsertMode

  destroy: ->
    return if @destroyed
    @destroyed = true
    @subscriptions.dispose()

    if @editor.isAlive()
      @activate('normal') # reset to base mdoe.
      @editorElement.component?.setInputEnabled(true)
      @editorElement.classList.remove packageScope, 'normal-mode'

    ivars = [
      "hover", "hoverSearchCounter",
      "flasher", "searchHistory",
      "input", "search", "modeManager",
      "operationRecords"
    ]
    for ivar in ivars
      this[name]?.destroy?()
      this[name] = null

    {@editor, @editorElement} = {}
    @emitter.emit 'did-destroy'

  observeSelection: ->
    handleSelectionChange = =>
      return unless @editor?
      return if @operationStack.isProcessing()
      someSelection = haveSomeSelection(@editor.getSelections())
      switch
        when @isMode('visual') and (not someSelection) then @activate('normal')
        when @isMode('normal') and someSelection then @activate('visual', 'characterwise')
      @showCursors()

    selectionWatcher = null
    handleMouseDown = =>
      selectionWatcher?.dispose()
      point = @editor.getLastCursor().getBufferPosition()
      tailRange = Range.fromPointWithDelta(point, 0, +1)
      selectionWatcher = @editor.onDidChangeSelectionRange ({selection}) ->
        selection.setBufferRange(selection.getBufferRange().union(tailRange))

    handleMouseUp = ->
      handleSelectionChange()
      selectionWatcher?.dispose()
      selectionWatcher = null

    debouncedHandleSelectionChange = _.debounce(->
      handleSelectionChange() unless selectionWatcher?
    , 100)

    @editorElement.addEventListener 'mousedown', handleMouseDown
    @editorElement.addEventListener 'mouseup', handleMouseUp
    @subscriptions.add new Disposable =>
      @editorElement.removeEventListener 'mousedown', handleMouseDown
      @editorElement.removeEventListener 'mouseup', handleMouseUp

    @subscriptions.add @editor.onDidChangeSelectionRange =>
      return if @operationStack.isProcessing()
      debouncedHandleSelectionChange()

  onDidFailToCompose: (fn) ->
    @emitter.on('failed-to-compose', fn)

  onDidDestroy: (fn) ->
    @emitter.on('did-destroy', fn)

  reset: ->
    @count.reset()
    @register.reset()
    @searchHistory.reset()
    @hover.reset()
    @operationStack.clear()

  showCursors: ->
    return unless (@isMode('visual') and settings.get('showCursorInVisualMode'))
    cursors = switch @submode
      when 'linewise' then []
      when 'characterwise' then @editor.getCursors()
      when 'blockwise'
        @editor.getCursors().filter (c) -> swrap(c.selection).isBlockwiseHead()

    for c in @editor.getCursors()
      if c in cursors
        c.setVisible(true) unless c.isVisible()
        toggleClassByCondition(@editorElement, 'reversed', c.selection.isReversed())
      else
        c.setVisible(false)
