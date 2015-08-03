_ = require 'underscore-plus'
TextObjects = require './text-objects'
Operators   = require './operators/index'

module.exports =
class OperationStack
  constructor: (@vimState) ->
    @stack = []
    @processing = false

  # Private: Push the given operations onto the operation stack, then process
  # it.
  push: (operations) ->
    return unless operations?
    try
      @startProcessing()
      operations = [operations] unless _.isArray(operations)

      for operation in operations
        # Motions in visual mode perform their selections.
        if @vimState.isVisualMode() and _.isFunction(operation.select)
          unless operation.isRepeat()
            @stack.push(new Operators.Select(@vimState.editor, @vimState))

        # if we have started an operation that responds to canComposeWith check if it can compose
        # with the operation we're going to push onto the stack
        if (topOperation = @getTopOperation())? and topOperation.canComposeWith? and not topOperation.canComposeWith(operation)
          @vimState.resetNormalMode()
          @vimState.emitter.emit('failed-to-compose')
          break

        @stack.push operation

        # If we've received an operator in visual mode, use inplict currentSelection textobject
        # as a target of operator.
        if @vimState.isVisualMode() and operation.isOperator?()
          @stack.push(new TextObjects.CurrentSelection(@vimState.editor, @vimState))

        @process()

    finally
      @finishProcessing()
      for cursor in @vimState.editor.getCursors()
        @vimState.ensureCursorIsWithinLine(cursor)

  # Private: Processes the command if the last operation is complete.
  #
  # Returns nothing.
  process: ->
    return if @isEmpty()

    unless @getTopOperation().isComplete()
      if @vimState.isNormalMode() and @getTopOperation().isOperator?()
        @vimState.activateOperatorPendingMode()
      return

    operation = @pop()
    unless @isEmpty()
      try
        @getTopOperation().compose(operation)
        @process()
      catch e
        if e.isOperatorError?() or e.isMotionError?()
          @vimState.resetNormalMode()
        else
          throw e
    else
      @vimState.history.unshift(operation) if operation.isRecordable()
      operation.execute()

  # Private: Fetches the last operation.
  #
  # Returns the last operation.
  getTopOperation: ->
    _.last @stack

  pop: ->
    @stack.pop()

  # Private: Removes all operations from the stack.
  #
  # Returns nothing.
  clear: ->
    @stack = []

  isSameOperatorPending: (constructor) ->
    _.detect @stack, (operation) ->
      operation instanceof constructor

  isEmpty: ->
    @stack.length is 0

  isProcessing: ->
    @processing

  startProcessing: ->
    @setProcessing true

  finishProcessing: ->
    @setProcessing false

  setProcessing: (value) ->
    @processing = value

  withLockProcessing: (callback) ->
    @startProcessing()
    callback()
    @finishProcessing()
