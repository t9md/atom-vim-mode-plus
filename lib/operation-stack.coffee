_ = require 'underscore-plus'

{Disposable, CompositeDisposable} = require 'atom'
Base = require './base'
{moveCursorLeft, getVisibleBufferRange} = require './utils'
settings = require './settings'
{CurrentSelection, Select, MoveToRelativeLine} = {}
{OperationAbortedError} = require './errors'
swrap = require './selection-wrapper'

# opration life in operationStack
# 1. run
#    instantiated by new
#    composed with implicit Operator.Select or Motion.CurrentSelection if necessary
#    push composed opration to stack
# 2. process
#    reduce stack by
#     pop operation and set it as target of new stack top(which should be operator).
#    check if remaining top of stack is executable by calling isComplete()
#    if executable, then pop stack then execute(poppedOperation)
#    if not executable, enter "operator-pending-mode"
class OperationStack
  constructor: (@vimState) ->
    {@editor, @editorElement, @occurrenceManager} = @vimState

    CurrentSelection ?= Base.getClass('CurrentSelection')
    Select ?= Base.getClass('Select')
    MoveToRelativeLine ?= Base.getClass('MoveToRelativeLine')

    @reset()

  # Return handler
  subscribe: (handler) ->
    @operationSubscriptions.add(handler)
    handler # DONT REMOVE

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

  # Compliment implicit operator or target(motion or text-object)
  # -------------------------
  composeOperation: (operation) ->
    {mode} = @vimState
    switch
      when operation.isOperator()
        if (mode is 'visual') and not operation.hasTarget() # don't want to override target
          operation = operation.setTarget(new CurrentSelection(@vimState))
      when operation.isTextObject()
        if mode isnt 'operator-pending'
          operation = new Select(@vimState).setTarget(operation)
      when operation.isMotion()
        if (mode is 'visual')
          operation = new Select(@vimState).setTarget(operation)
    operation

  # Main
  # -------------------------
  run: (klass, properties={}) ->
    try
      switch type = typeof(klass)
        when 'string', 'function'
          klass = Base.getClass(klass) if type is 'string'
          # When identical operator repeated, it set target to MoveToRelativeLine.
          #  e.g. `dd`, `cc`, `gUgU`
          klass = MoveToRelativeLine if (@peekTop()?.constructor is klass)
          operation = @composeOperation(new klass(@vimState, properties))
        when 'object' # . repeat case
          operation = klass
        else
          throw new Error('Unsupported type of operation')

      if @isEmpty() or (@peekTop().isOperator() and operation.isTarget())
        @push(operation)
        @process()
      else
        @vimState.emitDidFailToSetTarget() if @peekTop().isOperator()
        @vimState.resetNormalMode()
    catch error
      @handleError(error)

  runRecorded: ->
    if operation = @getRecorded()
      operation.setRepeated()
      if @hasCount()
        count = @getCount()
        operation.count = count
        operation.target?.count = count # Some opeartor have no target like ctrl-a(increase).

      # [FIXME] Degradation, this `transact` should not be necessary
      @editor.transact =>
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
      if @vimState.isMode('normal') and top.isOperator()
        @vimState.activate('operator-pending')
        if top.isOccurrence()
          @addToClassList('with-occurrence')
          unless @occurrenceManager.hasMarkers()
            @occurrenceManager.addPattern(top.patternForOccurence)

      # Temporary set while command is running
      if commandName = top.constructor.getCommandNameWithoutPrefix?()
        @addToClassList(commandName + "-pending")

  addToClassList: (className) ->
    @editorElement.classList.add(className)
    @subscribe new Disposable =>
      @editorElement.classList.remove(className)

  execute: (operation) ->
    execution = operation.execute()
    if execution instanceof Promise
      execution
        .then => @finish(operation)
        .catch => @handleError()
    else
      @finish(operation)

  cancel: ->
    if @vimState.mode not in ['visual', 'insert']
      @vimState.resetNormalMode()
    @finish()

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

  finish: (operation=null) ->
    @record(operation) if operation?.isRecordable()
    @vimState.emitter.emit('did-finish-operation')

    if @vimState.isMode('normal')
      @ensureAllSelectionsAreEmpty(operation)
      @ensureAllCursorsAreNotAtEndOfLine()
    if @vimState.isMode('visual')
      @vimState.modeManager.updateNarrowedState()
    @vimState.updateCursorsVisibility()
    @vimState.reset()

  reset: ->
    @resetCount()
    @stack = []
    @processing = false
    @operationSubscriptions?.dispose()
    @operationSubscriptions = new CompositeDisposable

  destroy: ->
    @operationSubscriptions?.dispose()
    {@stack, @operationSubscriptions} = {}

  record: (@recorded) ->

  getRecorded: ->
    @recorded

  # This is method is called only by user explicitly by `o` e.g. `c o i p`, `d v j`.
  setOperatorModifier: (modifiers) ->
    # In operator-pending-mode, stack length is always 1 and its' operator.
    # So either of @peekTop() or @peekBottom() is OK
    operator = @peekBottom()
    for name, value of modifiers when name in ['occurrence', 'wise']
      operator[name] = value
      if name is "occurrence" and value
        @addToClassList('with-occurrence')
        @occurrenceManager.replacePattern()

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
    if @vimState.mode is 'operator-pending'
      mode = @vimState.mode
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
