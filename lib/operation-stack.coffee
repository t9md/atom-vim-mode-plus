# Refactoring status: 100%
_ = require 'underscore-plus'
{CurrentSelection} = require './text-objects'
{Select} = require './operators'
{debug} = require './utils'

settings = require './settings'

module.exports =
class OperationStack
  constructor: (@vimState) ->
    @stack = []
    @processing = false

  push: (op) ->
    if @isEmpty() and settings.get('debug')
      if settings.get('debugOutput') is 'console'
        console.clear()
      debug "#=== Start at #{new Date().toISOString()}"

    @withLock =>
      # Use implicit Select operator as operator.
      if @vimState.isVisualMode() and _.isFunction(op.select)
        debug "push INPLICIT Operators.Select"
        @stack.push(new Select(@vimState))

      debug "pushing <#{op.getKind()}>"
      @stack.push op

      # Operate on implicit CurrentSelection TextObject.
      if @vimState.isVisualMode() and op.isOperator()
        debug "push INPLICIT TextObjects.CurrentSelection"
        @stack.push(new CurrentSelection(@vimState))
      @process()

    for cursor in @vimState.editor.getCursors()
      @vimState.ensureCursorIsWithinLine(cursor)

  process: ->
    debug '-> @process(): start'

    if @stack.length > 2
      throw 'Must not happen'

    if @stack.length is 2
      try
        op = @pop()
        debug "-> <#{@peekTop().getKind()}>.compose(<#{op.getKind()}>)"
        @peekTop().compose(op)
      catch error
        if error.isOperatorError?()
          debug error.message
          @vimState.resetNormalMode()
          return
        else
          throw error

    unless @peekTop().isComplete()
      if @vimState.isNormalMode() and @peekTop().isOperator?()
        @inspect()
        debug '-> @process(): activating: operator-pending-mode'
        @vimState.activateOperatorPendingMode()
      else
        debug "-> @process(): return: not <#{@peekTop().getKind()}>.isComplete()"
      return

    @inspect()
    debug '-> @pop()'
    op = @pop()
    @vimState.history.unshift(op) if op.isRecordable()
    debug " -> <#{op.getKind()}>.execute()"
    op.execute()
    @vimState.count.reset()
    @vimState.register.reset()
    debug "#=== Finish at #{new Date().toISOString()}\n"

  peekTop: ->
    _.last @stack

  pop: ->
    @stack.pop()

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

  inspect: ->
    @vimState.developer?.inspectOperationStack()
