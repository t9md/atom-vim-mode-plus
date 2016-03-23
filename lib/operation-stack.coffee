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

    # [Experimental] Cache for performance
    @currentSelection = new CurrentSelection(@vimState)
    @select = new Select(@vimState)

    @reset()

  subscribe: (args...) ->
    @subscriptions.add args...

  run: (klass, properties) ->
    klass = Base.getClass(klass) if _.isString(klass)
    try
      #  To support, `dd`, `cc` and a like.
      if (@peekTop()?.constructor is klass)
        klass = Base.getClass('MoveToRelativeLine')

      operation = new klass(@vimState, properties)
      if @vimState.isMode('visual')
        switch
          when operation.isOperator()
            operation.setTarget(@currentSelection)
          when operation.isMotion(), operation.isTextObject()
            operation = @select.setTarget(operation)
        @stack.push(operation)
      else if @isEmpty() and operation.isTextObject()
        # when TextObject invoked directly
        @stack.push(@select.setTarget(operation))
      else
        @stack.push(operation)

      @processing = true
      @process()
    catch error
      @handleError(error)

  handleError: (error) ->
    @vimState.reset()
    @processing = false
    unless error.instanceof?('OperationAbortedError')
      throw error

  isProcessing: ->
    @processing

  process: ->
    if @stack.length > 2
      throw new Error('Operation stack length exceeds 2')

    if @stack.length > 1
      try
        operation = @stack.pop()
        @peekTop().setTarget(operation)
      catch error
        if error.instanceof?('OperatorError')
          @vimState.activate('reset')
          return
        else
          throw error

    unless @peekTop().isComplete()
      if @vimState.isMode('normal') and @peekTop().isOperator()
        @vimState.activate('operator-pending')
    else
      @operation = @stack.pop()
      @execute()

  execute: ->
    execution = @operation.execute()
    if execution instanceof Promise
      onResolve = @finish.bind(this)
      onReject = @handleError.bind(this)
      execution.then(onResolve).catch(onReject)
    else
      @finish()

  cancel: ->
    unless @vimState.isMode('visual') or @vimState.isMode('insert')
      @vimState.activate('reset')
    @finish()

  finish: ->
    @record(@operation) if @operation?.isRecordable()
    @vimState.emitter.emit 'did-finish-operation'
    if @vimState.isMode('normal')
      unless @editor.getLastSelection().isEmpty()
        if settings.get('throwErrorOnNonEmptySelectionInNormalMode')
          operationName = @operation.constructor.name
          message = "Selection is not empty in normal-mode: #{operationName}"
          if @operation.hasTarget()
            message += ", target= #{@operation.getTarget().constructor.name}"
          throw new Error(message)
        else
          @editor.clearSelections()

      # Ensure Cursor is NOT at EndOfLine position
      for cursor in @editor.getCursors() when cursor.isAtEndOfLine()
        moveCursorLeft(cursor, {preserveGoalColumn: true})
    @operation = null
    @vimState.refreshCursors()
    @vimState.reset()
    @processing = false

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
