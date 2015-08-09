_ = require 'underscore-plus'
TextObjects = require './text-objects'
Operators   = require './operators'
{MoveToRelativeLine} = require './motions'
{debug} = require './utils'
settings = require './settings'

completableOperators = ['Delete', 'Change', 'Yank', 'Indent', 'Outdent', 'Autoindent']

module.exports =
class OperationStack
  constructor: (@vimState) ->
    @stack = []
    @processing = false

  # Private: Push the given operations onto the operation stack, then process
  # it.
  push: (operations) ->
    return unless operations?
    if @isEmpty() and settings.debug()
      debug "#=== Start at #{new Date().toISOString()}"
      if settings.debugOutput() is 'console'
        console.clear()

    @withLock =>
      operations = [operations] unless _.isArray(operations)

      for operation in operations
        # Experiment
        if _.isString(operation)
          operation = @vimState.newOperation(operation)

        # Motions in visual mode perform their selections.
        if @vimState.isVisualMode() and _.isFunction(operation.select)
          # unless operation.isRepeat()
          @stack.push(new Operators.Select(@vimState))

        #  To support, `dd`, `cc`, `yy` `>>`, `<<`, `==`
        if @vimState.isOperatorPendingMode() and
            (operation.getKind() in completableOperators) and @isSameOperatorPending(operation)
          operation = new MoveToRelativeLine(@vimState.editor, @vimState)

        # if we have started an operation that responds to canComposeWith check if it can compose
        # with the operation we're going to push onto the stack
        if (topOperation = @peekTop())? and topOperation.canComposeWith? and not topOperation.canComposeWith(operation)
          @vimState.resetNormalMode()
          @vimState.emitter.emit('failed-to-compose')
          break

        @stack.push operation

        # If we've received an operator in visual mode, use inplict currentSelection textobject
        # as a target of operator.
        if @vimState.isVisualMode() and operation.isOperator?()
          @stack.push(new TextObjects.CurrentSelection(@vimState.editor, @vimState))

        @process()

    for cursor in @vimState.editor.getCursors()
      @vimState.ensureCursorIsWithinLine(cursor)

  inspectStack: ->
    debug "  [@stack] size: #{@stack.length}"
    for op, i in @stack
      debug "  <idx: #{i}>"
      if settings.debug()
        debug op.report
          indent: 2
          colors: settings.debugOutput() is 'file'
          excludeProperties: ['vimState', 'editorElement'] # vimState have many properties, occupy DevTool console.

  # Private: Processes the command if the last operation is complete.
  #
  # Returns nothing.
  process: ->
    return if @isEmpty()
    debug "-> @process(): start"

    unless @peekTop().isComplete()
      if @vimState.isNormalMode() and @peekTop().isOperator?()
        @inspectStack()
        debug "-> @process(): return. activate: operator-pending-mode"
        @vimState.activateOperatorPendingMode()
      return

    @inspectStack()
    debug "-> @pop()"
    operation = @pop()
    debug "  - popped = <#{operation.getKind()}>"
    debug "  - newTop = <#{@peekTop()?.getKind()}>"
    unless @isEmpty()
      try
        debug "-> <#{@peekTop().getKind()}>.compose(<#{operation.getKind()}>)"
        @peekTop().compose(operation)
        debug "-> @process(): recursive"
        @process()
      catch e
        if e.isOperatorError?() or e.isMotionError?()
          @vimState.resetNormalMode()
        else
          throw e
    else
      @vimState.history.unshift(operation) if operation.isRecordable()
      unless operation.isPure()
        debug " -> <#{operation.getKind()}>.execute()"
        operation.execute()
        @vimState.counter.reset()
        debug "#=== Finish at #{new Date().toISOString()}\n"
      else
        null # Something new way of execution.

  # Private: Fetches the last operation.
  #
  # Returns the last operation.
  peekTop: ->
    _.last @stack

  pop: ->
    @stack.pop()

  # Private: Removes all operations from the stack.
  #
  # Returns nothing.
  clear: ->
    @stack = []

  isEmpty: ->
    @stack.length is 0

  isSameOperatorPending: (operation) ->
    constructor = operation.constructor
    _.detect @stack, (operation) ->
      operation instanceof constructor

  isProcessing: ->
    @processing

  withLock: (callback) ->
    try
      @processing = true
      callback()
    finally
      @processing = false
