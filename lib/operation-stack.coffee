_ = require 'underscore-plus'
TextObjects = require './text-objects'
Operators   = require './operators'
{MoveToRelativeLine} = require './motions'
{debug} = require './utils'
settings = require './settings'
Base = require './base'
introspection = require './introspection'

completableOperators = ['Delete', 'Change', 'Yank', 'Indent', 'Outdent', 'AutoIndent']

module.exports =
class OperationStack
  constructor: (@vimState) ->
    @stack = []
    @processing = false

  # Private: Push the given operations onto the operation stack, then process
  # it.
  push: (op) ->
    return unless op?
    if @isEmpty() and settings.debug()
      debug "#=== Start at #{new Date().toISOString()}"
      if settings.debugOutput() is 'console'
        null
        # console.clear()

    @withLock =>
      # Motions in visual mode perform their selections.
      if @vimState.isVisualMode() and _.isFunction(op.select)
        @stack.push(new Operators.Select(@vimState))

      #  To support, `dd`, `cc`, `yy` `>>`, `<<`, `==`
      if @vimState.isOperatorPendingMode() and
          (op.getKind() in completableOperators) and @isSameOperatorPending(op)
        op = new MoveToRelativeLine(@vimState)

      # if we have started an operation that responds to canComposeWith check if it can compose
      # with the operation we're going to push onto the stack
      if (topOperation = @peekTop())? and topOperation.canComposeWith? and not topOperation.canComposeWith(op)
        @vimState.resetNormalMode()
        @vimState.emitter.emit('failed-to-compose')
        return

      @stack.push op

      # If we've received an operator in visual mode, use inplict currentSelection textobject
      # as a target of operator.
      if @vimState.isVisualMode() and op.isOperator?()
        @stack.push(new TextObjects.CurrentSelection(@vimState))

      @process()

    for cursor in @vimState.editor.getCursors()
      @vimState.ensureCursorIsWithinLine(cursor)

  inspect: ->
    debug "  [@stack] size: #{@stack.length}"
    for op, i in @stack
      debug "  <idx: #{i}>"
      if settings.debug()
        debug introspection.inspectInstance op,
          indent: 2
          colors: settings.debugOutput() is 'file'
          excludeProperties: [
            'vimState', 'editorElement'
            'report', 'reportAll'
            'extend', 'getParent', 'getAncestors',
          ] # vimState have many properties, occupy DevTool console.
          recursiveInspect: Base

  # Private: Processes the command if the last operation is complete.
  #
  # Returns nothing.
  process: ->
    return if @isEmpty()
    debug "-> @process(): start"
    @inspect()

    unless @peekTop().isComplete()
      if @vimState.isNormalMode() and @peekTop().isOperator?()
        @inspect()
        debug "-> @process(): return. activating: operator-pending-mode"
        @vimState.activateOperatorPendingMode()
      return

    @inspect()
    debug "-> @pop()"
    op = @pop()
    debug "  - popped = <#{op.getKind()}>"
    debug "  - newTop = <#{@peekTop()?.getKind()}>"
    unless @isEmpty()
      try
        debug "-> <#{@peekTop().getKind()}>.compose(<#{op.getKind()}>)"
        @peekTop().compose(op)
        debug "-> @process(): recursive"
        @process()
      catch error
        if error.isOperatorError?() or error.isMotionError?()
          @vimState.resetNormalMode()
        else
          throw error
    else
      @vimState.history.unshift(op) if op.isRecordable()
      if op.isPure()
        null # Something new way of execution.
      else
        debug " -> <#{op.getKind()}>.execute()"
        op.execute()
        @vimState.counter.reset()
        debug "#=== Finish at #{new Date().toISOString()}\n"

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

  isSameOperatorPending: (op) ->
    constructor = op.constructor
    _.detect @stack, (op) ->
      op instanceof constructor

  isProcessing: ->
    @processing

  withLock: (callback) ->
    try
      @processing = true
      callback()
    finally
      @processing = false
