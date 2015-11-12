Delegato = require 'delegato'
_ = require 'underscore-plus'
{Emitter, Disposable, CompositeDisposable, Range} = require 'atom'

{Hover} = require './hover'
{Input, Search} = require './input'
settings = require './settings'
{haveSomeSelection} = require './utils'
swrap = require './selection-wrapper'

Operator = require './operator'
Motion = require './motion'
TextObject = require './text-object'
InsertMode = require './insert-mode'
Scroll = require './scroll'
VisualBlockwise = require './visual-blockwise'

OperationStack = require './operation-stack'
CountManager = require './count-manager'
MarkManager = require './mark-manager'
ModeManager = require './mode-manager'
RegisterManager = require './register-manager'
SearchHistoryManager = require './search-history-manager'
FlashManager = require './flash-manager'

Developer = null # delay
packageScope = 'vim-mode-plus'

module.exports =
class VimState
  Delegato.includeInto(this)

  editor: null
  operationStack: null
  destroyed: false
  replaceModeListener: null
  developer: null

  # Mode handling is delegated to modeManager
  delegatingMethods = [
    'isMode'
    'activate'
    'replaceModeBackspace'
    'setInsertionCheckpoint'
  ]
  delegatingProperties = ['mode', 'submode']
  @delegatesProperty delegatingProperties..., toProperty: 'modeManager'
  @delegatesMethods delegatingMethods..., toProperty: 'modeManager'

  constructor: (@editor, @statusBarManager) ->
    @editorElement = atom.views.getView(@editor)
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @operationRecords = []
    @subscriptions.add @editor.onDidDestroy =>
      @destroy()

    @count = new CountManager(this)
    @mark = new MarkManager(this)
    @register = new RegisterManager(this)
    @flasher = new FlashManager(this)

    # FIXME: Direct reference for config param name.
    # Handle with config onDidChange subscription?
    @hover = new Hover(this, 'showHoverOnOperate')
    @hoverSearchCounter = new Hover(this, 'showHoverSearchCounter')

    @searchHistory = new SearchHistoryManager(this)
    @input = new Input(this)
    @search = new Search(this)
    @operationStack = new OperationStack(this)
    @modeManager = new ModeManager(this)
    @observeSelectionChange()

    @editorElement.classList.add packageScope
    @init()
    if settings.get('startInInsertMode')
      @activate('insert')
    else
      @activate('normal')

  getLastOperation: ->
    @operationRecords[0]

  # TODO: Is this really need to be history?
  # I think just keeping last operation is enough for current requirement.
  recordOperation: (operation) ->
    @operationRecords.unshift(operation)

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

  observeSelectionChange: ->
    handleSelectionChange = =>
      return unless @editor?
      return if @operationStack.isProcessing()
      someSelection = haveSomeSelection(@editor.getSelections())
      switch
        when @isMode('visual') and (not someSelection)
          @activate('normal')
        when @isMode('normal') and someSelection
          @activate('visual', 'characterwise')
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
    @subscriptions.add @editor.onDidChangeSelectionRange =>
      return if @operationStack.isProcessing()
      debouncedHandleSelectionChange()
    @subscriptions.add new Disposable =>
      @editorElement.removeEventListener 'mousedown', handleMouseDown
      @editorElement.removeEventListener 'mouseup', handleMouseUp

  onDidFailToCompose: (fn) ->
    @emitter.on('failed-to-compose', fn)

  onDidDestroy: (fn) ->
    @emitter.on('did-destroy', fn)

  registerCommands: (commands) ->
    for name, fn of commands
      do (fn) =>
        cmd = "#{packageScope}:#{name}"
        @subscriptions.add atom.commands.add(@editorElement, cmd, fn)

  # command-name is automatically mapped to correspoinding class.
  # e.g.
  #   join -> Join
  #   scroll-down -> ScrollDown
  registerOperationCommands: (kind, names) ->
    commands = {}
    for name in names
      commands[name] = @getOperationCommand(kind, name)
    @registerCommands(commands)

  getOperationCommand: (kind, name) ->
    properties = null
    if kind is TextObject
      # Split into [prefix, name] pair for TextObject commands.
      # e.g. 'inner-double-quote' -> ['inner', 'double-quote']
      [prefix, name] = name.split(/-(.+)/, 2)
      properties = {inner} if inner = (prefix is 'inner')
    klassName = kind[_.capitalize(_.camelize(name))]
    => @operationStack.run(klassName, properties)

  # Initialize all commands.
  init: ->
    @registerCommands
      'activate-normal-mode': => @activate('normal')
      'activate-linewise-visual-mode': => @activate('visual', 'linewise')
      'activate-characterwise-visual-mode': => @activate('visual', 'characterwise')
      'activate-blockwise-visual-mode': => @activate('visual', 'blockwise')
      'reset-normal-mode': => @activate('reset')

      'set-count': (e) => @count.set(e) # 0-9
      'set-register-name': => @register.setName() # "
      'reverse-selections': => @reverseSelections() # o
      'undo': => @undo() # u
      'redo': => @redo() # ctrl-r
      'replace-mode-backspace': => @replaceModeBackspace()

    @registerOperationCommands InsertMode, [
      'insert-register',
      'copy-from-line-above',
      'copy-from-line-below'
    ]

    @registerOperationCommands TextObject, [
      'inner-word'           , 'a-word'
      'inner-whole-word'     , 'a-whole-word'
      'inner-double-quote'  , 'a-double-quote'
      'inner-single-quote'  , 'a-single-quote'
      'inner-back-tick'     , 'a-back-tick'
      'inner-any-quote'     , 'a-any-quote'
      'inner-paragraph'      , 'a-paragraph'
      'inner-any-pair'       , 'a-any-pair'
      'inner-curly-bracket' , 'a-curly-bracket'
      'inner-angle-bracket' , 'a-angle-bracket'
      'inner-square-bracket', 'a-square-bracket'
      'inner-parenthesis'    , 'a-parenthesis'
      'inner-tag'           , # 'a-tag'
      'inner-comment'        , 'a-comment'
      'inner-indentation'    , 'a-indentation'
      'inner-fold'           , 'a-fold'
      'inner-function'       , 'a-function'
      'inner-current-line'   , 'a-current-line'
      'inner-entire'         , 'a-entire'
    ]

    @registerOperationCommands Motion, [
      'move-to-beginning-of-line',
      'repeat-find', 'repeat-find-reverse',
      'move-down', 'move-up', 'move-left', 'move-right',
      'move-to-next-word'     , 'move-to-next-whole-word'    ,
      'move-to-end-of-word'   , 'move-to-end-of-whole-word'  ,
      'move-to-previous-word' , 'move-to-previous-whole-word',
      'move-to-next-paragraph', 'move-to-previous-paragraph' ,
      'move-to-first-character-of-line'         , 'move-to-last-character-of-line'      ,
      'move-to-first-character-of-line-up'      , 'move-to-first-character-of-line-down',
      'move-to-first-character-of-line-and-down',
      'move-to-last-nonblank-character-of-line-and-down',
      'move-to-first-line', 'move-to-last-line',
      'move-to-top-of-screen', 'move-to-bottom-of-screen', 'move-to-middle-of-screen',
      'scroll-half-screen-up'  , 'scroll-half-screen-down'      ,
      'scroll-full-screen-up'  , 'scroll-full-screen-down'      ,
      'move-to-mark'           , 'move-to-mark-line'            ,
      'find'                   , 'find-backwards'               ,
      'till'                   , 'till-backwards'               ,
      'search'                 , 'search-backwards'             ,
      'search-current-word'    , 'search-current-word-backwards',
      'repeat-search'          , 'repeat-search-reverse'        ,
      'bracket-matching-motion',
    ]

    @registerOperationCommands Operator, [
      'activate-insert-mode', 'insert-after',
      'activate-replace-mode',
      'substitute', 'substitute-line',
      'insert-at-beginning-of-line', 'insert-after-end-of-line',
      'insert-below-with-newline', 'insert-above-with-newline',
      'delete', 'delete-to-last-character-of-line',
      'delete-right', 'delete-left',
      'change', 'change-to-last-character-of-line',
      'yank', 'yank-line',
      'put-after', 'put-before',
      'upper-case', 'lower-case', 'toggle-case', 'toggle-case-and-move-right',
      'camel-case', 'snake-case', 'dash-case',
      'surround'       , 'surround-word'           ,
      'delete-surround', 'delete-surround-any-pair'
      'change-surround', 'change-surround-any-pair'
      'join',
      'indent', 'outdent', 'auto-indent',
      'increase', 'decrease',
      'repeat', 'mark', 'replace',
      'replace-with-register'
      'toggle-line-comments'
    ]

    @registerOperationCommands Scroll, [
      'scroll-down'            , 'scroll-up'                    ,
      'scroll-cursor-to-top'   , 'scroll-cursor-to-top-leave'   ,
      'scroll-cursor-to-middle', 'scroll-cursor-to-middle-leave',
      'scroll-cursor-to-bottom', 'scroll-cursor-to-bottom-leave',
      'scroll-cursor-to-left'  , 'scroll-cursor-to-right'       ,
    ]

    @registerOperationCommands VisualBlockwise, [
      'blockwise-other-end',
      'blockwise-move-down',
      'blockwise-move-up',
      'blockwise-delete-to-last-character-of-line',
      'blockwise-change-to-last-character-of-line',
      'blockwise-insert-at-beginning-of-line',
      'blockwise-insert-after-end-of-line',
      'blockwise-escape',
    ]

    # Load developer helper commands.
    if atom.inDevMode()
      Developer ?= require './developer'
      @developer = new Developer(this)
      @developer.init()

  reset: ->
    @count.reset()
    @register.reset()
    @searchHistory.reset()
    @hover.reset()
    @operationStack.clear()

  # Miscellaneous commands
  # -------------------------
  undo: ->
    @editor.undo()
    s.clear() for s in @editor.getSelections()
    @activate('normal')

  redo: ->
    @editor.redo()
    s.clear() for s in @editor.getSelections()
    @activate('normal')

  reverseSelections: ->
    swrap(s = @editor.getLastSelection()).reverse()
    @syncSelectionsReversedState(s)

  syncSelectionsReversedState: (selection) ->
    reversed = selection.isReversed()
    for s in @editor.getSelections() when not (s is selection)
      swrap(s).setReversedState(reversed)

  # Search History
  # -------------------------
  # TODO: Put here for compatibility remove in future
  pushSearchHistory: (search) ->
    @searchHistory.save(search)

  getSearchHistoryItem: (index=0) ->
    @searchHistory.getEntries[index]

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
        @updateClassCond c.selection.isReversed(), 'reversed'
      else
        c.setVisible(false)

  updateClassCond: (condition, klass) ->
    action = (if condition then 'add' else 'remove')
    @editorElement.classList[action](klass)
