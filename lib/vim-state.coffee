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
FlashManager = require './flash-manager'

packageScope = 'vim-mode-plus'

# Mode handling is delegated to modeManager
delegatingProperties = ['mode', 'submode']
delegatingMethods = ['isMode', 'activate']

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

    @modeManager = new ModeManager(this)
    @count = new CountManager(this)
    @mark = new MarkManager(this)
    @register = new RegisterManager(this)
    @flasher = new FlashManager(this)
    @hover = new Hover(this)
    @hoverSearchCounter = new Hover(this)

    @searchHistory = new SearchHistoryManager(this)
    @input = new Input(this)
    @search = new SearchInput(this)
    @operationStack = new OperationStack(this)
    @observeSelection()

    @editorElement.classList.add packageScope
    if settings.get('startInInsertMode')
      @activate('insert')
    else
      @activate('normal')

  subscribe: (args...) ->
    @operationStack.subscribe args...

  # Input subscriptions
  # -------------------------
  onDidChangeInput: (fn) -> @subscribe @input.onDidChange(fn)
  onDidConfirmInput: (fn) -> @subscribe @input.onDidConfirm(fn)
  onDidCancelInput: (fn) -> @subscribe @input.onDidCancel(fn)
  onDidUnfocusInput: (fn) -> @subscribe @input.onDidUnfocus(fn)
  onDidCommandInput: (fn) -> @subscribe @input.onDidCommand(fn)

  onDidChangeSearch: (fn) -> @subscribe @search.onDidChange(fn)
  onDidConfirmSearch: (fn) -> @subscribe @search.onDidConfirm(fn)
  onDidCancelSearch: (fn) -> @subscribe @search.onDidCancel(fn)
  onDidUnfocusSearch: (fn) -> @subscribe @search.onDidUnfocus(fn)
  onDidCommandSearch: (fn) -> @subscribe @search.onDidCommand(fn)

  # Select and text mutation(Change)
  onWillSelect: (fn) -> @subscribe @emitter.on('will-select', fn)
  onDidSelect: (fn) -> @subscribe @emitter.on('did-select', fn)
  onDidSetTarget: (fn) -> @subscribe @emitter.on('did-set-target', fn)
  onDidOperationFinish: (fn) -> @subscribe @emitter.on('did-operation-finish', fn)

  destroy: ->
    return if @destroyed
    @destroyed = true
    @subscriptions.dispose()

    if @editor.isAlive()
      @activate('normal') # reset to base mdoe.
      @editorElement.component?.setInputEnabled(true)
      @editorElement.classList.remove packageScope, 'normal-mode'

    ivars = [
      "hover", "hoverSearchCounter", "operationStack"
      "flasher", "searchHistory",
      "input", "search", "modeManager",
      "operationRecords"
    ]
    for ivar in ivars
      this[name]?.destroy?()
      this[name] = null

    {@editor, @editorElement, @subscriptions} = {}
    @emitter.emit 'did-destroy'

  observeSelection: ->
    handleSelectionChange = =>
      return unless @editor?
      return if @operationStack.isProcessing()
      someSelection = haveSomeSelection(@editor.getSelections())
      switch
        when @isMode('visual') and (not someSelection) then @activate('normal')
        when @isMode('normal') and someSelection then @activate('visual', 'characterwise')

    selectionWatcher = null
    handleMouseDown = =>
      selectionWatcher?.dispose()
      point = @editor.getLastCursor().getBufferPosition()
      tailRange = Range.fromPointWithDelta(point, 0, +1)
      selectionWatcher = @editor.onDidChangeSelectionRange ({selection}) =>
        handleSelectionChange()
        selection.setBufferRange(selection.getBufferRange().union(tailRange))
        @showCursors()

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

  getDomNodeForCursor: (cursor) ->
    cursorsComponent = @editorElement.component.linesComponent.cursorsComponent
    cursorsComponent.cursorNodesById[cursor.id]

  updateStyleForCursor: (cursor) ->
    domNode = @getDomNodeForCursor(cursor)
    unless domNode
      return (new Disposable)

    {selection} = cursor
    {style} = domNode
    switch @submode
      when 'linewise'
        point = swrap(selection).getCharacterwiseHeadPosition()
        style.setProperty('left', "#{point.column}ch") if point?
        style.setProperty('top', '-1.5em') unless selection.isReversed()
      when 'characterwise', 'blockwise'
        unless selection.isReversed()
          if cursor.isAtBeginningOfLine()
            style.setProperty('top', '-1.5em')
          else
            style.setProperty('left', '-1ch')

    new Disposable ->
      style.removeProperty('top')
      style.removeProperty('left')

  cursorStyleDisposer = null
  showCursors: ->
    cursorStyleDisposer?.dispose()
    cursorStyleDisposer = new CompositeDisposable
    return unless (@isMode('visual') and settings.get('showCursorInVisualMode'))

    cursors = @editor.getCursors()
    cursorsToShow = if @submode is 'blockwise'
      (cursor for cursor in cursors when swrap(cursor.selection).isBlockwiseHead())
    else
      cursors

    for cursor in cursors
      if cursor in cursorsToShow
        cursor.setVisible(true) unless cursor.isVisible()
      else
        cursor.setVisible(false) if cursor.isVisible()

    @editorElement.component.updateSync()
    for cursor in cursorsToShow
      cursorStyleDisposer.add @updateStyleForCursor(cursor)
