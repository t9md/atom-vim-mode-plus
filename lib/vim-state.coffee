Grim  = require 'grim'
Delegato = require 'delegato'
_ = require 'underscore-plus'
{Range, Emitter, CompositeDisposable} = require 'atom'
settings = require './settings'

Base = require './base'
Operators   = require './operators'
Motions     = require './motions'
TextObjects = require './text-objects'
InsertMode  = require './insert-mode'

Scroll = require './scroll'
OperationStack = require './operation-stack'
RegisterManager = require './register-manager'
CountManager = require './count-manager'
MarkManager = require './mark-manager'
ModeManager = require './mode-manager'

path = require 'path'

module.exports =
class VimState
  Delegato.includeInto(this)

  editor: null
  operationStack: null
  destroyed: false
  replaceModeListener: null

  # Mode handling is delegated to modeManager
  delegatingMethods = [
    'isNormalMode'
    'isInsertMode'
    'isOperatorPendingMode'
    'isVisualMode'
    'activateNormalMode'
    'activateInsertMode'
    'activateOperatorPendingMode'
    'activateReplaceMode'
    'replaceModeUndo'
    'deactivateInsertMode'
    'deactivateVisualMode'
    'activateVisualMode'
    'resetNormalMode'
    'setInsertionCheckpoint'
  ]
  delegatingProperties = [
    'mode'
    'submode'
  ]
  @delegatesProperty delegatingProperties..., toProperty: 'modeManager'
  @delegatesMethods delegatingMethods..., toProperty: 'modeManager'

  constructor: (@editorElement, @statusBarManager, @globalVimState) ->
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @editor = @editorElement.getModel()
    @history = []
    @subscriptions.add @editor.onDidDestroy => @destroy()

    @register = new RegisterManager(this)
    @count = new CountManager(this)
    @mark = new MarkManager(this)
    @operationStack = new OperationStack(this)
    @modeManager = new ModeManager(this)

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
    if settings.get('startInInsertMode')
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

  onDidFailToCompose: (fn) ->
    @emitter.on('failed-to-compose', fn)

  onDidDestroy: (fn) ->
    @emitter.on('did-destroy', fn)

  registerCommands: (commands) ->
    for name, fn of commands
      do (fn) =>
        @subscriptions.add atom.commands.add(@editorElement, "vim-mode:#{name}", fn)

  # Register operation command.
  # command-name is automatically mapped to correspoinding class.
  # e.g.
  #   join -> Join
  #   scroll-down -> ScrollDown
  registerOperationCommands: (kind, names) ->
    commands = {}
    for name in names
      do (name) =>
        klass = _.capitalize(_.camelize(name))
        commands[name] = =>
          try
            @operationStack.push new kind[klass](this)
          catch error
            unless error.isOperationAbortedError?()
              throw error
    @registerCommands(commands)

  # Initialize all of vim-mode' commands.
  init: ->
    @registerCommands
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

      # Temproal dev-help commands. Might be removed after refactoring finished.
      'toggle-debug': ->
        atom.config.set('vim-mode.debug', not settings.get('debug'))
        console.log "vim-mode debug:", atom.config.get('vim-mode.debug')
      'generate-introspection-report': => @generateIntrospectionReport()
      'jump-to-related': => @jumpToRelated()
      'report-key-binding': => @reportKeyBinding()
      'open-in-vim': => @openInVim()

    @registerOperationCommands InsertMode, [
      'insert-register'
      'copy-from-line-above', 'copy-from-line-below'
    ]

    @registerOperationCommands TextObjects, [
      'select-inside-word', 'select-a-word',
      'select-inside-whole-word', 'select-a-whole-word',
      'select-inside-double-quotes'  , 'select-around-double-quotes'
      'select-inside-single-quotes'  , 'select-around-single-quotes'
      'select-inside-back-ticks'     , 'select-around-back-ticks'
      'select-inside-paragraph'      , 'select-around-paragraph'
      'select-inside-curly-brackets' , 'select-around-curly-brackets'
      'select-inside-angle-brackets' , 'select-around-angle-brackets'
      'select-inside-square-brackets', 'select-around-square-brackets'
      'select-inside-parentheses'    , 'select-around-parentheses'
      'select-inside-tags'           , # why not around version exists?
    ]

    @registerOperationCommands Motions, [
      'move-to-beginning-of-line'
      'repeat-find', 'repeat-find-reverse'
      'move-down', 'move-up', 'move-left', 'move-right',
      'move-to-next-word'     , 'move-to-next-whole-word'    ,
      'move-to-end-of-word'   , 'move-to-end-of-whole-word'  ,
      'move-to-previous-word' , 'move-to-previous-whole-word',
      'move-to-next-paragraph', 'move-to-previous-paragraph' ,
      'move-to-first-character-of-line', 'move-to-last-character-of-line',
      'move-to-first-character-of-line-up', 'move-to-first-character-of-line-down',
      'move-to-first-character-of-line-and-down',
      'move-to-last-nonblank-character-of-line-and-down',
      'move-to-start-of-file', 'move-to-line',
      'move-to-top-of-screen', 'move-to-bottom-of-screen', 'move-to-middle-of-screen',
      'scroll-half-screen-up', 'scroll-half-screen-down',
      'scroll-full-screen-up', 'scroll-full-screen-down',
      'repeat-search'          , 'repeat-search-backwards'    ,
      'move-to-mark'           , 'move-to-mark-literal'       ,
      'find'                   , 'find-backwards'             ,
      'till'                   , 'till-backwards'             ,
      'search'                 , 'reverse-search'             ,
      'search-current-word'    , 'reverse-search-current-word',
      'bracket-matching-motion',
    ]

    @registerOperationCommands Operators, [
      'activate-insert-mode', 'insert-after'
      'activate-replace-mode'
      'substitute', 'substitute-line',
      'insert-at-beginning-of-line', 'insert-after-end-of-line',
      'insert-below-with-newline', 'insert-above-with-newline',
      'delete', 'delete-to-last-character-of-line'
      'delete-right', 'delete-left',
      'change', 'change-to-last-character-of-line'
      'yank', 'yank-line'
      'put-after', 'put-before'
      'upper-case', 'lower-case', 'toggle-case', 'toggle-case-now'
      'join'
      'indent', 'outdent', 'auto-indent',
      'increase', 'decrease'
      'repeat', 'mark', 'replace'
    ]

    @registerOperationCommands Scroll, [
      'scroll-down', 'scroll-up'
      'scroll-cursor-to-top', 'scroll-cursor-to-top-leave',
      'scroll-cursor-to-middle', 'scroll-cursor-to-middle-leave',
      'scroll-cursor-to-bottom', 'scroll-cursor-to-bottom-leave',
      'scroll-cursor-to-left', 'scroll-cursor-to-right'
      ]

  # Miscellaneous commands
  # -------------------------
  undo: ->
    @editor.undo()
    @activateNormalMode()

  reverseSelections: ->
    reversed = not @editor.getLastSelection().isReversed()
    for selection in @editor.getSelections()
      selection.setBufferRange(selection.getBufferRange(), {reversed})

  # Search History
  # -------------------------
  pushSearchHistory: (search) -> # should be saveSearchHistory for consistency.
    @globalVimState.searchHistory.unshift search

  getSearchHistoryItem: (index = 0) ->
    @globalVimState.searchHistory[index]

  # Other
  # -------------------------
  # TODO: remove this method and bump the `vim-mode` service version number.
  activateCommandMode: ->
    Grim.deprecate("Use ::activateNormalMode instead")
    @activateNormalMode()

  ensureCursorIsWithinLine: (cursor) =>
    return if @operationStack.isProcessing() or (not @isNormalMode())
    # # [FIXME] I'm developping in buffer 'tryit.coffee'.
    # # So disable auto-cursor modification especially for this bufffer temporarily.
    # return if path.basename(@editor.getPath()) is 'tryit.coffee'

    {goalColumn} = cursor
    if cursor.isAtEndOfLine() and not cursor.isAtBeginningOfLine()
      @operationStack.withLock -> # to ignore the cursor change (and recursion) caused by the next line
        cursor.moveLeft()
    cursor.goalColumn = goalColumn

  # Developper helpeing,
  # [FIXME] clean up needed and make it available only in dev-mode.
  # -------------------------
  generateIntrospectionReport: ->
    excludeProperties = [
      'findClass'
      'extend', 'getParent', 'getAncestors',
    ]
    recursiveInspect = Base

    introspection = require './introspection'
    mods = [Operators, Motions, TextObjects, Scroll, InsertMode]
    introspection.generateIntrospectionReport(mods, {excludeProperties, recursiveInspect})

  jumpToRelated: ->
    isCamelCase  = (s) -> _.camelize(s) is s
    isDashCase   = (s) -> _.dasherize(s) is s
    getClassCase = (s) -> _.capitalize(_.camelize(s))

    range = @editor.getLastCursor().getCurrentWordBufferRange(wordRegex: /[-\w/\.]+/)
    srcName = @editor.getTextInBufferRange(range)
    return unless srcName

    # if isDashCase(srcName) and @editor.getPath().endsWith('vim-mode.cson')
    #   point = null
    #   @editor.scan ///#{srcName}///, ({range, stop}) ->
    #     point = range.start
    #     stop()
    #   if point
    #     @editor.setCursorBufferPosition(point)
    #     return

    if isDashCase(srcName)
      klass2file =
        Motion:     'motions.coffee'
        Operator:   'operators.coffee'
        TextObject: 'text-objects.coffee'
        Scroll:     'scroll.coffee'
        InsertMode: 'insert-mode.coffee'

      klassName = getClassCase(srcName)
      unless klass = Base.findClass(klassName)
        return
      parentNames = (parent.name for parent in klass.getAncestors())
      parentNames.pop() # trash Base
      parent = _.last(parentNames)
      if parent in _.keys(klass2file)
        fileName = klass2file[parent]
        filePath = atom.project.resolvePath("lib/#{fileName}")
        atom.workspace.open(filePath).done (editor) ->
          editor.scan ///^class\s+#{klassName}///, ({range, stop}) ->
            editor.setCursorBufferPosition(range.start.translate([0, 'class '.length]))
            stop()
    else if isCamelCase(srcName)
      files = [
        "keymaps/vim-mode.cson"
        "lib/vim-state.coffee"
      ]
      dashName = _.dasherize(srcName)
      fileName = files[0]
      filePath = atom.project.resolvePath fileName
      atom.workspace.open(filePath).done (editor) ->
        editor.scan ///#{dashName}///, ({range, stop}) ->
          editor.setCursorBufferPosition(range.start)
          stop()

  reportKeyBinding: ->
    range = @editor.getLastCursor().getCurrentWordBufferRange(wordRegex: /[-\w/\.]+/)
    klass = @editor.getTextInBufferRange(range)
    {getKeyBindingInfo} = require './introspection'
    console.log getKeyBindingInfo(klass)

  openInVim: ->
    {BufferedProcess} = require 'atom'
    {row} = @editor.getCursorBufferPosition()
    new BufferedProcess
      command: "/Applications/MacVim.app/Contents/MacOS/mvim"
      args: [@editor.getPath(), "+#{row+1}"]
