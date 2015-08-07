_ = require 'underscore-plus'
TextObjects = require './text-objects'
Operators   = require './operators/index'
utils = require './utils'
{debug, debugClear} = require './utils'
settings = require './settings'

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
      debugClear()
    @withLock =>
      operations = [operations] unless _.isArray(operations)

      for operation in operations
        # Motions in visual mode perform their selections.
        if @vimState.isVisualMode() and _.isFunction(operation.select)
          # unless operation.isRepeat()
          @stack.push(new Operators.Select(@vimState.editor, @vimState))

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
    indentString = _.multiplyString(' ', 2)
    debug "#{indentString}@stack length = #{@stack.length}"
    for op, i in @stack
      debug "#{indentString}[stack: idx = #{i}]"
      debug op.report(indent: 2, colors: settings.debugOutput() is 'file')

  # Private: Processes the command if the last operation is complete.
  #
  # Returns nothing.
  process: ->
    return if @isEmpty()
    debug "<--- @process(): enter --->"

    unless @peekTop().isComplete()
      if @vimState.isNormalMode() and @peekTop().isOperator?()
        @inspectStack()
        @vimState.activateOperatorPendingMode()
        debug "<--- @process(): return. Operator Pending Mode --->"
      return

    @inspectStack()
    operation = @pop()
    unless @isEmpty()
      try
        debug "<--- Compose --->"
        debug "  - owner = #{@peekTop().getKind()}"
        debug "  - target = #{operation.getKind()}"
        @peekTop().compose(operation)
        debug "  --- @process(): call @process() again!"
        @process()
      catch e
        if e.isOperatorError?() or e.isMotionError?()
          @vimState.resetNormalMode()
        else
          throw e
    else
      @vimState.history.unshift(operation) if operation.isRecordable()
      unless operation.isPure()
        debug "<--- Execute --->"
        debug "#=== Finish at #{new Date().toISOString()}\n"
        operation.execute()
        @vimState.counter.reset()
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

  isSameOperatorPending: (constructor) ->
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
