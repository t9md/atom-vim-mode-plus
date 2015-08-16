_ = require 'underscore-plus'
TextObjects = require './text-objects'
Operators   = require './operators'
{debug} = require './utils'
settings = require './settings'
Base = require './base'
introspection = require './introspection'

module.exports =
class OperationStack
  constructor: (@vimState) ->
    @stack = []
    @processing = false

  push: (op) ->
    if @isEmpty() and settings.debug()
      if settings.debugOutput() is 'console'
        console.clear()
      debug "#=== Start at #{new Date().toISOString()}"

    @withLock =>
      # Motions in visual mode perform their selections.
      if @vimState.isVisualMode() and _.isFunction(op.select)
        debug "push INPLICIT Operators.Select"
        @stack.push(new Operators.Select(@vimState))

      # If we have started an operation that responds to canComposeWith check if it can compose
      # with the operation we're going to push onto the stack
      if (topOperation = @peekTop())? and topOperation.canComposeWith? and not topOperation.canComposeWith(op)
        @vimState.resetNormalMode()
        @vimState.emitter.emit('failed-to-compose')
        return

      debug "pushing <#{op.getKind()}>"
      @stack.push op

      # If we've received an operator in visual mode, use inplict currentSelection textobject
      # as a target of operator.
      if @vimState.isVisualMode() and op.isOperator()
        debug "push INPLICIT TextObjects.CurrentSelection"
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

    unless @peekTop().isComplete()
      if @vimState.isNormalMode() and @peekTop().isOperator?()
        @inspect()
        debug "-> @process(): activating: operator-pending-mode"
        @vimState.activateOperatorPendingMode()
      else
        debug "-> @process(): return: not <#{@peekTop().getKind()}>.isComplete()"
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
        @vimState.count.reset()
        @vimState.register.reset()
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

  isProcessing: ->
    @processing

  withLock: (callback) ->
    try
      @processing = true
      callback()
    finally
      @processing = false

  isOperatorPending: ->
    not @isEmpty()
