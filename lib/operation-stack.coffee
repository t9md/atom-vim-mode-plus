# Refactoring status: 100%
_ = require 'underscore-plus'

{CurrentSelection} = require './motion'
{Select} = require './operator'
{debug} = require './utils'
settings = require './settings'
Base = require './base'

class OperationStack
  constructor: (@vimState) ->
    @stack = []
    {@editor} = @vimState

  run: (klass, properties) ->
    try
      klass = Base.getConstructor(klass) if _.isString(klass)
      @push new klass(@vimState, properties)
    catch error
      throw error unless error.isOperationAbortedError?()

  push: (op) ->
    if @isEmpty() and settings.get('debug')
      if settings.get('debugOutput') is 'console'
        console.clear()
      debug "#=== Start at #{new Date().toISOString()}"

    # Use implicit Select operator as operator.
    if @vimState.isMode('visual') and _.isFunction(op.select)
      @pushToStack new Select(@vimState), message: "push IMPLICIT Operator.Select"

    @pushToStack op, message: "push <#{op.getKind()}>"

    # Operate on implicit CurrentSelection TextObject.
    if @vimState.isMode('visual') and op.isOperator()
      @pushToStack new CurrentSelection(@vimState),
        message: "push IMPLICIT Motion.CurrentSelection"

    try
      @processing = true
      @process()
    finally
      @processing = false

  isProcessing: ->
    @processing

  process: ->
    debug '-> @process(): start'

    while @stack.length > 1
      try
        op = @pop()
        debug "-> <#{@peekTop().getKind()}>.compose(<#{op.getKind()}>)"
        @peekTop().compose(op)
      catch error
        if error.isOperatorError?()
          debug error.message
          @vimState.activate('reset')
          return
        else
          throw error

    if @peekTop().isComplete()
      @inspect()
      debug '-> @pop()'
      op = @pop()
      debug " -> <#{op.getKind()}>.execute()"
      op.execute()

      @vimState.recordOperation(op) if op.isRecordable()
      @finish()
      debug "#=== Finish at #{new Date().toISOString()}\n"
    else
      if @vimState.isMode('normal') and @peekTop().isOperator?()
        @inspect()
        debug '-> @process(): activating: operator-pending-mode'
        @vimState.activate('operator-pending')
      else
        debug "-> @process(): return: not <#{@peekTop().getKind()}>.isComplete()"
        @inspect()

  cancel: ->
    debug "Cancelled stack size: #{@stack.length}"
    debug(op.getKind()) for op in @pop()
    unless @vimState.isMode('visual') or @vimState.isMode('insert')
      @vimState.activate('reset')
    @finish()
    debug "#=== Canceled at #{new Date().toISOString()}\n"

  finish: ->
    if @vimState.isMode('normal') and @editor.getLastSelection().isEmpty()
      @dontPutCursorsAtEndOfLine()
    @vimState.showCursors()
    @vimState.reset()

  dontPutCursorsAtEndOfLine: ->
    for c in @editor.getCursors() when c.isAtEndOfLine() and not c.isAtBeginningOfLine()
      {goalColumn} = c
      c.moveLeft()
      c.goalColumn = goalColumn

  peekTop: ->
    _.last @stack

  pushToStack: (operation, {message}={}) ->
    debug message if message?
    @stack.push(operation)

  pop: ->
    @stack.pop()

  clear: ->
    @stack = []

  isEmpty: ->
    @stack.length is 0

  isOperatorPending: ->
    not @isEmpty()

  inspect: ->
    @vimState.developer?.inspectOperationStack()

module.exports = OperationStack
