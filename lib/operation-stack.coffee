Delegato = require 'delegato'
_ = require 'underscore-plus'

{Disposable, CompositeDisposable} = require 'atom'
Base = require './base'
{moveCursorLeft} = require './utils'
settings = require './settings'
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
  Delegato.includeInto(this)
  @delegatesProperty('mode', 'submode', toProperty: 'modeManager')

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
    handler # DONT REMOVE

  reset: ->
    @resetCount()
    @stack = []
    @processing = false
    @operationSubscriptions?.dispose()
    @operationSubscriptions = new CompositeDisposable

  destroy: ->
    @subscriptions.dispose()
    @operationSubscriptions?.dispose()
    {@stack, @operationSubscriptions} = {}

  # Stack manipulation
  # -------------------------
  push: (operation) ->
    @stack.push(operation)

  pop: ->
    @stack.pop()

  peekTop: ->
    _.last(@stack)

  peekBottom: ->
    @stack[0]

  isEmpty: ->
    @stack.length is 0

  isFull: ->
    @stack.length is 2

  hasPending: ->
    @stack.length is 1

  # Main
  # -------------------------
  run: (klass, properties={}) ->
    try
      type = typeof(klass)
      unless type in ['string', 'function', 'object']
        throw new Error('Unsupported type of operation')

      if type is 'object' # . repeat case we can execute as-it-is.
        operation = klass
      else
        klass = Base.getClass(klass) if type is 'string'
        # Replace operator when identical one repeated, e.g. `dd`, `cc`, `gUgU`
        if @peekTop()?.constructor is klass
          operation = new MoveToRelativeLine(@vimState)
        else
          operation = new klass(@vimState, properties)

      # Compliment implicit Select operator
      if operation.isTextObject() and @mode isnt 'operator-pending' or operation.isMotion() and @mode is 'visual'
        operation = new Select(@vimState).setTarget(operation)

      if @isEmpty() or (@peekTop().isOperator() and operation.isTarget())
        @push(operation)
        @process()
      else
        @vimState.emitDidFailToSetTarget() if @peekTop().isOperator()
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

      # [FIXME] Degradation, this `transact` should not be necessary
      @editor.transact =>
        @run(operation)

  runCurrentFind: ({reverse}={}) ->
    if operation = @vimState.globalState.get('currentFind')
      operation = operation.clone(@vimState)
      operation.setRepeated()
      operation.resetCount()
      if reverse
        operation.backwards = not operation.backwards
      @run(operation)

  handleError: (error) ->
    @vimState.reset()
    unless error instanceof OperationAbortedError
      throw error

  isProcessing: ->
    @processing

  process: ->
    @processing = true
    if @isFull()
      operation = @pop()
      @peekTop().setTarget(operation)

    top = @peekTop()
    if top.isComplete()
      @execute(@pop())
    else
      if @mode is 'normal' and top.isOperator()
        @vimState.activate('operator-pending')

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
    @finish()

  finish: (operation=null) ->
    @recordedOperation = operation if operation?.isRecordable()
    @vimState.emitter.emit('did-finish-operation')

    if @mode is 'normal'
      @ensureAllSelectionsAreEmpty(operation)
      @ensureAllCursorsAreNotAtEndOfLine()
    if @mode is 'visual'
      @vimState.modeManager.updateNarrowedState()
      @vimState.updatePreviousSelection()
    @vimState.updateCursorsVisibility()
    @vimState.reset()

  ensureAllSelectionsAreEmpty: (operation) ->
    unless @editor.getLastSelection().isEmpty()
      if settings.get('throwErrorOnNonEmptySelectionInNormalMode')
        throw new Error("Selection is not empty in normal-mode: #{operation.toString()}")
      else
        @editor.clearSelections()

  ensureAllCursorsAreNotAtEndOfLine: ->
    for cursor in @editor.getCursors() when cursor.isAtEndOfLine()
      # [FIXME] SCATTERED_CURSOR_ADJUSTMENT
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
    if @mode is 'operator-pending'
      mode = @mode
    else
      mode = 'normal'
    @count[mode] ?= 0
    @count[mode] = (@count[mode] * 10) + number
    @vimState.hover.add(number)
    @vimState.toggleClassList('with-count', true)

  resetCount: ->
    @count = {}
    @vimState.toggleClassList('with-count', false)

module.exports = OperationStack
