# Refactoring status: 100%
_ = require 'underscore-plus'

{CompositeDisposable} = require 'atom'
Base = require './base'
{withKeepingGoalColumn} = require './utils'
settings = require './settings'
{CurrentSelection, Select} = {}

class OperationStackError
  constructor: (@message) ->
    @name = 'OperationStack Error'

class OperationStack
  constructor: (@vimState) ->
    {@editor} = @vimState
    CurrentSelection ?= Base.getClass('CurrentSelection')
    Select ?= Base.getClass('Select')
    @reset()

  subscribe: (args...) ->
    @subscriptions.add args...

  run: (klass, properties) ->
    klass = Base.getClass(klass) if _.isString(klass)
    try
      op = new klass(@vimState, properties)
      if @vimState.isMode('visual') and _.isFunction(op.select)
        @stack.push(new Select(@vimState))
      @stack.push(op)
      if @vimState.isMode('visual') and op.instanceof('Operator')
        @stack.push(new CurrentSelection(@vimState))

      @processing = true
      @process()
    catch error
      @vimState.reset()
      unless error.instanceof?('OperationAbortedError')
        throw error
    finally
      @processing = false

  isProcessing: ->
    @processing

  process: ->
    if @stack.length > 2
      throw new OperationStackError('Must not happen')

    if @stack.length > 1
      try
        op = @stack.pop()
        @peekTop().setTarget(op)
      catch error
        if error.instanceof?('OperatorError')
          @vimState.activate('reset')
          return
        else
          throw error

    unless @peekTop().isComplete()
      if @vimState.isMode('normal') and @peekTop().instanceof?('Operator')
        @vimState.activate('operator-pending')
    else
      op = @stack.pop()
      op.execute()
      @test = op
      @record(op) if op.isRecordable()
      @finish()

  cancel: ->
    unless @vimState.isMode('visual') or @vimState.isMode('insert')
      @vimState.activate('reset')
    @finish()

  finish: ->
    @vimState.emitter.emit 'did-operation-finish'
    if @vimState.isMode('normal')
      unless @editor.getLastSelection().isEmpty()
        throw new OperationStackError('Selection remains on normal-mode')
      @ensureCursorNotOnEOL()
    @vimState.showCursors()
    @vimState.reset()

  ensureCursorNotOnEOL: ->
    for c in @editor.getCursors() when c.isAtEndOfLine() and not c.isAtBeginningOfLine()
      withKeepingGoalColumn c, (c) ->
        c.moveLeft()

  peekTop: ->
    _.last @stack

  reset: ->
    @stack = []
    @subscriptions?.dispose()
    @subscriptions = new CompositeDisposable

  destroy: ->
    @subscriptions?.dispose()
    {@stack, @subscriptions} = {}

  isEmpty: ->
    @stack.length is 0

  record: (@recorded) ->

  getRecorded: ->
    @recorded

module.exports = OperationStack
