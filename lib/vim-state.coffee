Grim  = require 'grim'
_ = require 'underscore-plus'
{Range, Emitter, CompositeDisposable} = require 'atom'
settings = require './settings'

Base = require './base'
Operators   = require './operators'
Motions     = require './motions'
InsertMode  = require './insert-mode'
TextObjects = require './text-objects'

Scroll = require './scroll'
OperationStack = require './operation-stack'
RegisterManager = require './register-manager'
CountManager = require './count-manager'
{getKeystrokeForEvent} = require './utils'

module.exports =
class VimState
  editor: null
  operationStack: null
  mode: null
  submode: null
  destroyed: false
  replaceModeListener: null

  constructor: (@editorElement, @statusBarManager, @globalVimState) ->
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @editor = @editorElement.getModel()
    @history = []
    @marks = {}
    @subscriptions.add @editor.onDidDestroy => @destroy()

    # [FIXME] Order matter
    @register = new RegisterManager(this)
    @count = new CountManager(this)
    @operationStack = new OperationStack(this)

    @subscriptions.add @editor.onDidChangeSelectionRange _.debounce(=>
      return unless @editor?
      if @editor.getSelections().every((selection) -> selection.isEmpty())
        @activateNormalMode() if @isVisualMode()
      else
        @activateVisualMode('characterwise') if @isNormalMode()
    , 100)

    @subscriptions.add @editor.onDidChangeCursorPosition ({cursor}) =>
      @ensureCursorIsWithinLine(cursor)
    @subscriptions.add @editor.onDidAddCursor @ensureCursorIsWithinLine

    @editorElement.classList.add("vim-mode")
    @init()
    if settings.startInInsertMode()
      @activateInsertMode()
    else
      @activateNormalMode()

  destroy: ->
    return if @destroyed
    @destroyed = true
    @emitter.emit 'did-destroy'
    @subscriptions.dispose()
    if @editor.isAlive()
      @deactivateInsertMode()
      @editorElement.component?.setInputEnabled(true)
      @editorElement.classList.remove("vim-mode")
      @editorElement.classList.remove("normal-mode")
    @editor = null
    @editorElement = null

  # Private: Creates the plugin's bindings
  #
  # Returns nothing.
  init: ->
    @registerCommands
      'toggle-debug': ->
        atom.config.set('vim-mode.debug', not settings.debug())
        console.log "vim-mode debug:", atom.config.get('vim-mode.debug')
      'generate-introspection-report': => @generateIntrospectionReport()
      'activate-normal-mode': => @activateNormalMode()
      'activate-linewise-visual-mode': => @activateVisualMode('linewise')
      'activate-characterwise-visual-mode': => @activateVisualMode('characterwise')
      'activate-blockwise-visual-mode': => @activateVisualMode('blockwise')
      'reset-normal-mode': => @resetNormalMode()
      'set-count': (e) => @count.set(e) # 0-9
      'set-register-name': => @register.setName() # "
      'reverse-selections': => @reverseSelections() # o
      'undo': => @undo() # u
      'replace-mode-backspace': => @replaceModeUndo()
      'copy-from-line-above': => InsertMode.copyCharacterFromAbove(@editor, this)
      'copy-from-line-below': => InsertMode.copyCharacterFromBelow(@editor, this)

    # InsertMode
    # -------------------------
    @registerNewOperationCommands InsertMode, [
      # ctrl-r [a-zA-Z*+%_"]
      'insert-register'
    ]

    # Operator
    # -------------------------
    @registerNewOperationCommands TextObjects, [
      # w
      'select-inside-word', 'select-a-word',
      # W
      'select-inside-whole-word', 'select-a-whole-word',
      # "
      'select-inside-double-quotes'  , 'select-around-double-quotes'
      # '
      'select-inside-single-quotes'  , 'select-around-single-quotes'
      # `
      'select-inside-back-ticks'     , 'select-around-back-ticks'
      # p
      'select-inside-paragraph'      , 'select-around-paragraph'
      # {
      'select-inside-curly-brackets' , 'select-around-curly-brackets'
      # <
      'select-inside-angle-brackets' , 'select-around-angle-brackets'
      # [
      'select-inside-square-brackets', 'select-around-square-brackets'
      # (, b
      'select-inside-parentheses'    , 'select-around-parentheses'
      # t
      'select-inside-tags'           , # why not around version exists?
    ]

    # Motion
    # -------------------------
    @registerNewOperationCommands Motions, [
      'move-to-beginning-of-line' #: (e) => @moveOrRepeat(e)
      # ;, ,
      'repeat-find', 'repeat-find-reverse'
      # j, k, h, l
      'move-down', 'move-up', 'move-left', 'move-right',
      # w, W
      'move-to-next-word'    , 'move-to-next-whole-word'    ,
      # e, E
      'move-to-end-of-word'  , 'move-to-end-of-whole-word'  ,
      # b, B
      'move-to-previous-word', 'move-to-previous-whole-word',
      # }, {
      'move-to-next-paragraph', 'move-to-previous-paragraph',
      # ^, $
      'move-to-first-character-of-line', 'move-to-last-character-of-line',
      # -, +
      'move-to-first-character-of-line-up', 'move-to-first-character-of-line-down',
      # enter
      'move-to-first-character-of-line-and-down',
      # g_
      'move-to-last-nonblank-character-of-line-and-down',
      # gg, G
      'move-to-start-of-file', 'move-to-line',
      # H, L, M
      'move-to-top-of-screen', 'move-to-bottom-of-screen', 'move-to-middle-of-screen',
      # ctrl-u, ctrl-d
      'scroll-half-screen-up', 'scroll-half-screen-down',
      # ctrl-b, ctrl-f
      'scroll-full-screen-up', 'scroll-full-screen-down',
      # n, N
      'repeat-search'          , 'repeat-search-backwards'    ,
      # ', `
      'move-to-mark'           , 'move-to-mark-literal'       ,
      # f, F
      'find'                   , 'find-backwards'             ,
      # t, T
      'till'                   , 'till-backwards'             ,
      # /, ?
      'search'                 , 'reverse-search'             ,
      # *, #
      'search-current-word'    , 'reverse-search-current-word',
      # %
      'bracket-matching-motion',
    ]

    # Operator
    # -------------------------
    @registerNewOperationCommands Operators, [
      # i, a
      'activate-insert-mode', 'insert-after'
      # r
      'activate-replace-mode'
      # s, S
      'substitute', 'substitute-line',
      # I, A
      'insert-at-beginning-of-line', 'insert-after-end-of-line',
      # o, O
      'insert-below-with-newline', 'insert-above-with-newline',
      # d, D
      'delete', 'delete-to-last-character-of-line'
      # x, X
      'delete-right', 'delete-left',
      # c, C
      'change', 'change-to-last-character-of-line'
      # y, Y
      'yank', 'yank-line'
      # p, P
      'put-after', 'put-before'
      # U, u, g~, ~
      'upper-case', 'lower-case', 'toggle-case', 'toggle-case-now'
      # J
      'join'
      # >, <, =
      'indent', 'outdent', 'auto-indent',
      # ctrl-a, ctrl-x
      'increase', 'decrease'
      # ., m, r
      'repeat', 'mark', 'replace'
    ]

    # Scroll
    # -------------------------
    @registerNewOperationCommands Scroll, [
      # ctrl-e, ctrl-y
      'scroll-down', 'scroll-up'
      # z enter, zt
      'scroll-cursor-to-top', 'scroll-cursor-to-top-leave',
      # z., zz
      'scroll-cursor-to-middle', 'scroll-cursor-to-middle-leave',
      # z-, zb
      'scroll-cursor-to-bottom', 'scroll-cursor-to-bottom-leave',
      # zs, ze
      'scroll-cursor-to-left', 'scroll-cursor-to-right'
      ]

  # Private: Register multiple command handlers via an {Object} that maps
  # command names to command handler functions.
  #
  # Prefixes the given command names with 'vim-mode:' to reduce redundancy in
  # the provided object.
  registerCommands: (commands) ->
    for name, fn of commands
      do (fn) =>
        @subscriptions.add atom.commands.add(@editorElement, "vim-mode:#{name}", fn)

  # Private: Register multiple Operators via an {Object} that
  # maps command names to functions that return operations to push.
  #
  # Prefixes the given command names with 'vim-mode:' to reduce redundancy in
  # the given object.
  registerOperationCommands: (operationCommands) ->
    commands = {}
    for name, fn of operationCommands
      do (fn) =>
        commands[name] = (event) => @operationStack.push(fn(event))
    @registerCommands(commands)

  # 'New' is 'new' way of registration to distinguish exisiting function.
  # By maping command name to correspoinding class.
  #  e.g.
  # join -> Join
  # scroll-down -> ScrollDown
  registerNewOperationCommands: (kind, names) ->
    commands = {}
    for name in names
      do (name) =>
        klass = _.capitalize(_.camelize(name))
        commands[name] = => new kind[klass](this)
    @registerOperationCommands(commands)

  onDidFailToCompose: (fn) ->
    @emitter.on('failed-to-compose', fn)

  onDidDestroy: (fn) ->
    @emitter.on('did-destroy', fn)

  undo: ->
    @editor.undo()
    @activateNormalMode()

  ##############################################################################
  # Mark
  ##############################################################################

  # Private: Fetches the value of a given mark.
  #
  # name - The name of the mark to fetch.
  #
  # Returns the value of the given mark or undefined if it hasn't
  # been set.
  getMark: (name) ->
    if @marks[name]
      @marks[name].getBufferRange().start
    else
      undefined

  # Private: Sets the value of a given mark.
  #
  # name  - The name of the mark to fetch.
  # pos {Point} - The value to set the mark to.
  #
  # Returns nothing.
  setMark: (name, pos) ->
    # check to make sure name is in [a-z] or is `
    if (charCode = name.charCodeAt(0)) >= 96 and charCode <= 122
      marker = @editor.markBufferRange(new Range(pos, pos), {invalidate: 'never', persistent: false})
      @marks[name] = marker

  ##############################################################################
  # Search History
  ##############################################################################

  # Public: Append a search to the search history.
  #
  # Motions.Search - The confirmed search motion to append
  #
  # Returns nothing
  pushSearchHistory: (search) -> # should be saveSearchHistory for consistency.
    @globalVimState.searchHistory.unshift search

  # Public: Get the search history item at the given index.
  #
  # index - the index of the search history item
  #
  # Returns a search motion
  getSearchHistoryItem: (index = 0) ->
    @globalVimState.searchHistory[index]

  ##############################################################################
  # Mode Switching
  ##############################################################################

  # Private: Used to enable normal mode.
  #
  # Returns nothing.
  activateNormalMode: ->
    @deactivateInsertMode()
    @deactivateVisualMode()

    @mode = 'normal'
    @submode = null

    @changeModeClass('normal-mode')

    @operationStack.clear()
    selection.clear(autoscroll: false) for selection in @editor.getSelections()
    for cursor in @editor.getCursors()
      if cursor.isAtEndOfLine() and not cursor.isAtBeginningOfLine()
        cursor.moveLeft()

    @updateStatusBar()

  # TODO: remove this method and bump the `vim-mode` service version number.
  activateCommandMode: ->
    Grim.deprecate("Use ::activateNormalMode instead")
    @activateNormalMode()

  # Private: Used to enable insert mode.
  #
  # Returns nothing.
  activateInsertMode: (subtype = null) ->
    @mode = 'insert'
    @editorElement.component.setInputEnabled(true)
    @setInsertionCheckpoint()
    @submode = subtype
    @changeModeClass('insert-mode')
    @updateStatusBar()

  activateReplaceMode: ->
    @activateInsertMode('replace')
    @replaceModeCounter = 0
    @editorElement.classList.add('replace-mode')
    @subscriptions.add @replaceModeListener = @editor.onWillInsertText @replaceModeInsertHandler
    @subscriptions.add @replaceModeUndoListener = @editor.onDidInsertText @replaceModeUndoHandler

  replaceModeInsertHandler: (event) =>
    chars = event.text?.split('') or []
    selections = @editor.getSelections()
    for char in chars
      continue if char is '\n'
      for selection in selections
        selection.delete() unless selection.cursor.isAtEndOfLine()
    return

  replaceModeUndoHandler: (event) =>
    @replaceModeCounter++

  replaceModeUndo: ->
    if @replaceModeCounter > 0
      @editor.undo()
      @editor.undo()
      @editor.moveLeft()
      @replaceModeCounter--

  setInsertionCheckpoint: ->
    @insertionCheckpoint = @editor.createCheckpoint() unless @insertionCheckpoint?

  deactivateInsertMode: ->
    return unless @mode in [null, 'insert']
    @editorElement.component.setInputEnabled(false)
    @editorElement.classList.remove('replace-mode')
    @editor.groupChangesSinceCheckpoint(@insertionCheckpoint)
    changes = getChangesSinceCheckpoint(@editor.buffer, @insertionCheckpoint)
    item = @inputOperator(@history[0])
    @insertionCheckpoint = null
    if item?
      item.confirmChanges(changes)
    for cursor in @editor.getCursors()
      cursor.moveLeft() unless cursor.isAtBeginningOfLine()
    if @replaceModeListener?
      @replaceModeListener.dispose()
      @subscriptions.remove @replaceModeListener
      @replaceModeListener = null
      @replaceModeUndoListener.dispose()
      @subscriptions.remove @replaceModeUndoListener
      @replaceModeUndoListener = null

  deactivateVisualMode: ->
    return unless @isVisualMode()
    for selection in @editor.getSelections()
      selection.cursor.moveLeft() unless (selection.isEmpty() or selection.isReversed())

  # Private: Get the input operator that needs to be told about about the
  # typed undo transaction in a recently completed operation, if there
  # is one.
  inputOperator: (item) ->
    return item unless item?
    return item if item.inputOperator?()
    return item.composedObject if item.composedObject?.inputOperator?()

  # Private: Used to enable visual mode.
  #
  # type - One of 'characterwise', 'linewise' or 'blockwise'
  #
  # Returns nothing.
  activateVisualMode: (type) ->
    # Already in 'visual', this means one of following command is
    # executed within `vim-mode.visual-mode`
    #  * activate-blockwise-visual-mode
    #  * activate-characterwise-visual-mode
    #  * activate-linewise-visual-mode
    if @isVisualMode()
      if @submode is type
        @activateNormalMode()
        return

      @submode = type
      if @submode is 'linewise'
        for selection in @editor.getSelections()
          # Keep original range as marker's property to get back
          # to characterwise.
          # Since selectLine lost original cursor column.
          originalRange = selection.getBufferRange()
          selection.marker.setProperties({originalRange})
          [start, end] = selection.getBufferRowRange()
          selection.selectLine(row) for row in [start..end]

      else if @submode in ['characterwise', 'blockwise']
        # Currently, 'blockwise' is not yet implemented.
        # So treat it as characterwise.
        # Recover original range.
        for selection in @editor.getSelections()
          {originalRange} = selection.marker.getProperties()
          if originalRange
            [startRow, endRow] = selection.getBufferRowRange()
            originalRange.start.row = startRow
            originalRange.end.row   = endRow
            selection.setBufferRange(originalRange)
    else
      @deactivateInsertMode()
      @mode = 'visual'
      @submode = type
      @changeModeClass('visual-mode')

      if @submode is 'linewise'
        @editor.selectLinesContainingCursors()
      else if @editor.getSelectedText() is ''
        @editor.selectRight()

    @updateStatusBar()

  # Private: Used to re-enable visual mode
  resetVisualMode: ->
    @activateVisualMode(@submode)

  # Private: Used to enable operator-pending mode.
  activateOperatorPendingMode: ->
    @deactivateInsertMode()
    @mode = 'operator-pending'
    @submode = null
    @changeModeClass('operator-pending-mode')

    @updateStatusBar()

  changeModeClass: (targetMode) ->
    for mode in ['normal-mode', 'insert-mode', 'visual-mode', 'operator-pending-mode']
      if mode is targetMode
        @editorElement.classList.add(mode)
      else
        @editorElement.classList.remove(mode)

  # Private: Resets the normal mode back to it's initial state.
  #
  # Returns nothing.
  resetNormalMode: ->
    @operationStack.clear()
    @editor.clearSelections()
    @activateNormalMode()

  reverseSelections: ->
    reversed = not @editor.getLastSelection().isReversed()
    for selection in @editor.getSelections()
      selection.setBufferRange(selection.getBufferRange(), {reversed})

  isVisualMode: -> @mode is 'visual'
  isNormalMode: -> @mode is 'normal'
  isInsertMode: -> @mode is 'insert'
  isOperatorPendingMode: -> @mode is 'operator-pending'

  updateStatusBar: ->
    @statusBarManager.update(@mode, @submode)

  ensureCursorIsWithinLine: (cursor) =>
    return if @operationStack.isProcessing() or (not @isNormalMode())

    {goalColumn} = cursor
    if cursor.isAtEndOfLine() and not cursor.isAtBeginningOfLine()
      @operationStack.withLock -> # to ignore the cursor change (and recursion) caused by the next line
        cursor.moveLeft()
    cursor.goalColumn = goalColumn

  generateIntrospectionReport: ->
    excludeProperties = [
      'report', 'reportAll'
      'extend', 'getParent', 'getAncestors',
    ]
    recursiveInspect = Base

    introspection = require './introspection'
    mods = [Operators, Motions, TextObjects, Scroll]
    introspection.generateIntrospectionReport(mods, {excludeProperties, recursiveInspect})

# This uses private APIs and may break if TextBuffer is refactored.
# Package authors - copy and paste this code at your own risk.
getChangesSinceCheckpoint = (buffer, checkpoint) ->
  {history} = buffer

  if (index = history.getCheckpointIndex(checkpoint))?
    history.undoStack.slice(index)
  else
    []
