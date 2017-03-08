{Disposable, CompositeDisposable} = require 'atom'
Base = require './base'
{moveCursorLeft} = require './utils'
{Select, MoveToRelativeLine} = {}
{OperationAbortedError} = require './errors'
swrap = require './selection-wrapper'

# opration life in operationStack
# 1. run
#    instantiated by new.
#    compliment implicit Operator.Select operator if necessary.
#    push operation to stack.
# 2. process
#    reduce stack by, popping top of stack then set it as target of new top.
#    check if remaining top of stack is executable by calling isComplete()
#    if executable, then pop stack then execute(poppedOperation)
#    if not executable, enter "operator-pending-mode"
class OperationStack
  Object.defineProperty @prototype, 'mode', get: -> @modeManager.mode
  Object.defineProperty @prototype, 'submode', get: -> @modeManager.submode

  constructor: (@vimState) ->
    {@editor, @editorElement, @modeManager} = @vimState

    @subscriptions = new CompositeDisposable
    @subscriptions.add @vimState.onDidDestroy(@destroy.bind(this))

    Select ?= Base.getClass('Select')
    MoveToRelativeLine ?= Base.getClass('MoveToRelativeLine')

    @reset()

  # Return handler
  subscribe: (handler) ->
    @operationSubscriptions.add(handler)
    return handler # DONT REMOVE

  reset: ->
    @resetCount()
    @stack = []
    @processing = false

    # this has to be BEFORE @operationSubscriptions.dispose()
    @vimState.emitDidResetOperationStack()

    @operationSubscriptions?.dispose()
    @operationSubscriptions = new CompositeDisposable

  destroy: ->
    @subscriptions.dispose()
    @operationSubscriptions?.dispose()
    {@stack, @operationSubscriptions} = {}

  peekTop: ->
    @stack[@stack.length - 1]

  isEmpty: ->
    @stack.length is 0

  # Main
  # -------------------------
  run: (klass, properties) ->
    try
      @vimState.init() if @isEmpty()
      type = typeof(klass)
      if type is 'object' # . repeat case we can execute as-it-is.
        operation = klass
      else
        klass = Base.getClass(klass) if type is 'string'
        # Replace operator when identical one repeated, e.g. `dd`, `cc`, `gUgU`
        if @peekTop()?.constructor is klass
          operation = new MoveToRelativeLine(@vimState)
        else
          operation = new klass(@vimState, properties)

      if @isEmpty()
        isValidOperation = true
        if (@mode is 'visual' and operation.isMotion()) or operation.isTextObject()
          operation = new Select(@vimState).setTarget(operation)
      else
        isValidOperation = @peekTop().isOperator() and (operation.isMotion() or operation.isTextObject())

      if isValidOperation
        @stack.push(operation)
        @process()
      else
        @vimState.emitDidFailToPushToOperationStack()
        @vimState.resetNormalMode()
    catch error
      @handleError(error)

  runRecorded: ->
    if operation = @recordedOperation
      operation.setRepeated()
      if @hasCount()
        count = @getCount()
        operation.count = count
        operation.target?.count = count # Some opeartor have no target like ctrl-a(increase).

      operation.subscribeResetOccurrencePatternIfNeeded()
      @run(operation)

  runRecordedMotion: (key, {reverse}={}) ->
    return unless operation = @vimState.globalState.get(key)

    operation = operation.clone(@vimState)
    operation.setRepeated()
    operation.resetCount()
    if reverse
      operation.backwards = not operation.backwards
    @run(operation)

  runCurrentFind: (options) ->
    @runRecordedMotion('currentFind', options)

  runCurrentSearch: (options) ->
    @runRecordedMotion('currentSearch', options)

  handleError: (error) ->
    @vimState.reset()
    unless error instanceof OperationAbortedError
      throw error

  isProcessing: ->
    @processing

  process: ->
    @processing = true
    if @stack.length is 2
      # [FIXME ideally]
      # If target is not complete, we postpone composing target with operator to keep situation simple.
      # So that we can assume when target is set to operator it's complete.
      # e.g. `y s t a'(surround for range from here to till a)
      return unless @peekTop().isComplete()

      operation = @stack.pop()
      @peekTop().setTarget(operation)

    top = @peekTop()

    if top.isComplete()
      @execute(@stack.pop())
    else
      if @mode is 'normal' and top.isOperator()
        @modeManager.activate('operator-pending')

      # Temporary set while command is running
      if commandName = top.constructor.getCommandNameWithoutPrefix?()
        @addToClassList(commandName + "-pending")

  execute: (operation) ->
    @vimState.updatePreviousSelection() if @mode is 'visual'
    execution = operation.execute()
    if execution instanceof Promise
      execution
        .then => @finish(operation)
        .catch => @handleError()
    else
      @finish(operation)

  cancel: ->
    if @mode not in ['visual', 'insert']
      @vimState.resetNormalMode()
      @vimState.restoreOriginalCursorPosition()
    @finish()

  finish: (operation=null) ->
    @recordedOperation = operation if operation?.isRecordable()
    @vimState.emitDidFinishOperation()
    if operation?.isOperator()
      operation.resetState()

    if @mode is 'normal'
      swrap.clearProperties(@editor)
      @ensureAllSelectionsAreEmpty(operation)
      @ensureAllCursorsAreNotAtEndOfLine()
    else if @mode is 'visual'
      @modeManager.updateNarrowedState()
      @vimState.updatePreviousSelection()
    @vimState.updateCursorsVisibility()
    @vimState.reset()

  ensureAllSelectionsAreEmpty: (operation) ->
    # When @vimState.selectBlockwise() is called in non-visual-mode.
    # e.g. `.` repeat of operation targeted blockwise `CurrentSelection`.
    # We need to manually clear blockwiseSelection.
    # See #647
    @vimState.clearBlockwiseSelections()

    unless @editor.getLastSelection().isEmpty()
      if @vimState.getConfig('devThrowErrorOnNonEmptySelectionInNormalMode')
        throw new Error("Selection is not empty in normal-mode: #{operation.toString()}")
      else
        @vimState.clearSelections()

  ensureAllCursorsAreNotAtEndOfLine: ->
    for cursor in @editor.getCursors() when cursor.isAtEndOfLine()
      moveCursorLeft(cursor, {preserveGoalColumn: true})

  addToClassList: (className) ->
    @editorElement.classList.add(className)
    @subscribe new Disposable =>
      @editorElement.classList.remove(className)

  # Count
  # -------------------------
  # keystroke `3d2w` delete 6(3*2) words.
  #  2nd number(2 in this case) is always enterd in operator-pending-mode.
  #  So count have two timing to be entered. that's why here we manage counter by mode.
  hasCount: ->
    @count['normal']? or @count['operator-pending']?

  getCount: ->
    if @hasCount()
      (@count['normal'] ? 1) * (@count['operator-pending'] ? 1)
    else
      null

  setCount: (number) ->
    mode = 'normal'
    mode = @mode if @mode is 'operator-pending'
    @count[mode] ?= 0
    @count[mode] = (@count[mode] * 10) + number
    @vimState.hover.set(@buildCountString())
    @vimState.toggleClassList('with-count', true)

  buildCountString: ->
    [@count['normal'], @count['operator-pending']]
      .filter (count) -> count?
      .map (count) -> String(count)
      .join('x')

  resetCount: ->
    @count = {}
    @vimState.toggleClassList('with-count', false)

module.exports = OperationStack
