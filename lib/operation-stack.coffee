# Refactoring status: 100%
_ = require 'underscore-plus'

{CompositeDisposable} = require 'atom'
Base = require './base'
{moveCursorLeft} = require './utils'
settings = require './settings'
{CurrentSelection, Select} = {}

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
      #  To support, `dd`, `cc` and a like.
      if not @isEmpty() and (@peekTop().constructor is klass)
        klass = Base.getClass('MoveToRelativeLine')
      op = new klass(@vimState, properties)
      if (@vimState.isMode('visual') and _.isFunction(op.select)) or
          (@isEmpty() and op.instanceof('TextObject')) # when TextObject invoked directly
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
      throw new Error('Operation stack length exceeds 2')

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
      @lastOperation = op # Used for better error message.
      op.execute()
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
        operationName = @lastOperation.constructor.name
        message = "Selection is not empty in normal-mode: #{operationName}"
        if @lastOperation.target?
          message += ", target= #{@lastOperation.target.constructor.name}"
        throw new Error(message)

      # Ensure Cursor is NOT at EndOfLine position
      for c in @editor.getCursors() when c.isAtEndOfLine()
        moveCursorLeft(c, {preserveGoalColumn: true})
    @lastOperation = null
    @vimState.refreshCursors()
    @vimState.reset()

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
