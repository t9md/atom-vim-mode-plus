# Refactoring status: 100%
_ = require 'underscore-plus'

Base = require './base'
{debug, withKeepingGoalColumn} = require './utils'
settings = require './settings'
{CurrentSelection, Select} = {}

inspectInstance = null

class OperationStack
  constructor: (@vimState) ->
    @stack = []
    {@editor} = @vimState
    Select ?= Base.getClass('Select')
    CurrentSelection ?= Base.getClass('CurrentSelection')

  run: (klass, properties) ->
    klass = Base.getClass(klass) if _.isString(klass)
    try
      @push new klass(@vimState, properties)
      @processing = true
      @process()
    catch error
      @vimState.reset()
      throw error unless error.instanceof?('OperationAbortedError')
    finally
      @processing = false

  push: (op) ->
    if @isEmpty() and settings.get('debug')
      console.clear() if settings.get('debugOutput') is 'console'
      debug "#=== Start at #{new Date().toISOString()}"

    if @vimState.isMode('visual') and _.isFunction(op.select)
      @pushToStack new Select(@vimState)
    @pushToStack op
    if @vimState.isMode('visual') and op.instanceof('Operator')
      @pushToStack new CurrentSelection(@vimState)

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

  pushToStack: (operation) ->
    if settings.get('debug')
      kind = operation.constructor.kind
      debug "push <#{kind}.#{operation.constructor.name}>"
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
