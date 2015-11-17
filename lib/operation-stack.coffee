# Refactoring status: 100%
_ = require 'underscore-plus'

Base = require './base'
CurrentSelection = null
Select = null
{debug, withKeepingGoalColumn} = require './utils'
settings = require './settings'

inspectInstance = null

class OperationStack
  constructor: (@vimState) ->
    @stack = []
    {@editor} = @vimState

  run: (klass, properties) ->
    try
      klass = Base.getClass(klass) if _.isString(klass)
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
      Select ?= Base.getClass('Select')
      @pushToStack new Select(@vimState), message: "push IMPLICIT Operator.Select"

    @pushToStack op, message: "push <#{op.constructor.name}>"

    # Operate on implicit CurrentSelection TextObject.
    if @vimState.isMode('visual') and op.instanceof('Operator')
      CurrentSelection ?= Base.getClass('CurrentSelection')
      @pushToStack new CurrentSelection(@vimState), message: "push IMPLICIT Motion.CurrentSelection"

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

    unless @peekTop().isComplete()
      if @vimState.isMode('normal') and @peekTop().instanceof?('Operator')
        @inspect()
        debug '-> @process(): activating: operator-pending-mode'
        @vimState.activate('operator-pending')
      else
        debug "-> @process(): return: not <#{@peekTop().constructor.name}>.isComplete()"
        @inspect()
      return

    @inspect()
    debug '-> @pop()'
    op = @pop()
    debug " -> <#{op.constructor.name}>.execute()"
    op.execute()
    @record(op) if op.isRecordable()
    @finish()
    debug "#=== Finish at #{new Date().toISOString()}\n"

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

  record: (@recorded) ->

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
         # vimState have many properties, occupy DevTool console.
        excludeProperties: ['vimState', 'editorElement', 'extend']
        recursiveInspect: Base

module.exports = OperationStack
