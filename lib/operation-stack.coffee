# Refactoring status: 100%
_ = require 'underscore-plus'

{CurrentSelection} = require './motion'
{Select} = require './operator'
{debug, withKeepingGoalColumn} = require './utils'
settings = require './settings'
Base = require './base'

inspectInstance = null

class OperationStack
  constructor: (@vimState) ->
    @stack = []
    {@editor} = @vimState

  run: (klass, properties) ->
    try
      klass = Base.getConstructor(klass) if _.isString(klass)
      @push new klass(@vimState, properties)
    catch error
      throw error unless error.instanceof?('OperationAbortedError')

  push: (op) ->
    if @isEmpty() and settings.get('debug')
      if settings.get('debugOutput') is 'console'
        console.clear()
      debug "#=== Start at #{new Date().toISOString()}"

    # Use implicit Select operator as operator.
    if @vimState.isMode('visual') and _.isFunction(op.select)
      @pushToStack new Select(@vimState), message: "push IMPLICIT Operator.Select"

    @pushToStack op, message: "push <#{op.constructor.name}>"

    # Operate on implicit CurrentSelection TextObject.
    if @vimState.isMode('visual') and op.instanceof('Operator')
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
        debug "-> <#{@peekTop().constructor.name}>.compose(<#{op.constructor.name}>)"
        @peekTop().compose(op)
      catch error
        if error.instanceof?('OperatorError')
          debug error.message
          @vimState.activate('reset')
          return
        else
          throw error

    if @peekTop().isComplete()
      @inspect()
      debug '-> @pop()'
      op = @pop()
      debug " -> <#{op.constructor.name}>.execute()"
      op.execute()
      # debug purpose for a while to refactor further
      @lastExecuted = op
      @recorded = op if op.isRecordable()
      @finish()
      debug "#=== Finish at #{new Date().toISOString()}\n"
    else
      if @vimState.isMode('normal') and @peekTop().instanceof?('Operator')
        @inspect()
        debug '-> @process(): activating: operator-pending-mode'
        @vimState.activate('operator-pending')
      else
        debug "-> @process(): return: not <#{@peekTop().constructor.name}>.isComplete()"
        @inspect()

  cancel: ->
    debug "Cancelled stack size: #{@stack.length}"
    debug(op.constructor.name) for op in @pop()
    unless @vimState.isMode('visual') or @vimState.isMode('insert')
      @vimState.activate('reset')
    @finish()
    debug "#=== Canceled at #{new Date().toISOString()}\n"

  finish: ->
    if @vimState.isMode('normal') and @editor.getLastSelection().isEmpty()
      for c in @editor.getCursors() when c.isAtEndOfLine() and not c.isAtBeginningOfLine()
        # console.log "CALLED", @executing
        withKeepingGoalColumn c, (c) ->
          c.moveLeft()
    @vimState.showCursors()
    @vimState.reset()

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

  getLastExecuted: ->
    @lastExecuted

  getRecorded: ->
    @recorded

  inspect: ->
    return unless settings.get('debug')
    inspectInstance ?= (require './introspection').inspectInstance
    debug "  [@stack] size: #{@stack.length}"
    for op, i in @stack
      debug "  <idx: #{i}>"
      debug inspectInstance op,
        indent: 2
        colors: settings.get('debugOutput') is 'file'
        excludeProperties: [
          'vimState', 'editorElement'
          'report', 'reportAll'
          'extend', 'getParent', 'getAncestors',
        ] # vimState have many properties, occupy DevTool console.
        recursiveInspect: Base

module.exports = OperationStack
