# Refactoring status: 100%
_ = require 'underscore-plus'
{CurrentSelection} = require './motion'
{Select} = require './operator'
{debug} = require './utils'
settings = require './settings'

module.exports =
class OperationStack
  constructor: (@vimState) ->
    @stack = []

  push: (op) ->
    if @isEmpty() and settings.get('debug')
      if settings.get('debugOutput') is 'console'
        console.clear()
      debug "#=== Start at #{new Date().toISOString()}"

    # Use implicit Select operator as operator.
    if @vimState.isMode('visual') and _.isFunction(op.select)
      debug "push IMPLICIT Operator.Select"
      @stack.push(new Select(@vimState))

    debug "pushing <#{op.getKind()}>"
    @stack.push op

    # Operate on implicit CurrentSelection TextObject.
    if @vimState.isMode('visual') and op.isOperator()
      debug "push IMPLICIT Motion.CurrentSelection"
      @stack.push(new CurrentSelection(@vimState))

    @withLock =>
      @process()

  withLock: (fn) ->
    try
      @processing = true
      fn()
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

    unless @peekTop().isComplete()
      if @vimState.isMode('normal') and @peekTop().isOperator?()
        @inspect()
        debug '-> @process(): activating: operator-pending-mode'
        @vimState.activate('operator-pending')
      else
        debug "-> @process(): return: not <#{@peekTop().getKind()}>.isComplete()"
        @inspect()
      return

    @inspect()
    debug '-> @pop()'
    op = @pop()
    debug " -> <#{op.getKind()}>.execute()"
    op.execute()

    @vimState.recordOperation(op) if op.isRecordable()
    @finish()
    debug "#=== Finish at #{new Date().toISOString()}\n"

  cancel: ->
    debug "Cancelled stack size: #{@stack.length}"
    for op in @pop()
      debug  op.getKind()
    unless @vimState.isMode('visual') or @vimState.isMode('insert')
      @vimState.activate('reset')
    @finish()
    debug "#=== Canceled at #{new Date().toISOString()}\n"

  finish: ->
    {editor} = @vimState
    if @vimState.isMode('normal')
      if editor.getLastSelection().isEmpty()
        @dontPutCursorsAtEndOfLine()
    if @vimState.isMode('visual', 'blockwise')
      @vimState.showCursors()
    @vimState.reset()

  dontPutCursorsAtEndOfLine: ->
    for c in @vimState.editor.getCursors() when c.isAtEndOfLine() and not c.isAtBeginningOfLine()
      {goalColumn} = c
      c.moveLeft()
      c.goalColumn = goalColumn

  peekTop: ->
    _.last @stack

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
