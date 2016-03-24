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

  composeOperation: (operation) ->
    {mode} = @vimState
    switch
      when operation.isOperator()
        if (mode is 'visual')
          operation = operation.setTarget(@currentSelection)
      when operation.isTextObject()
        if (mode in ['visual', 'normal'])
          operation = @select.setTarget(operation)
      when operation.isMotion()
        if (mode is 'visual')
          operation = @select.setTarget(operation)
    operation

  run: (klass, properties) ->
    klass = Base.getClass(klass) if _.isString(klass)
    try
      #  To support, `dd`, `cc` and a like.
      if (@peekTop()?.constructor is klass)
        klass = Base.getClass('MoveToRelativeLine')

      @stack.push @composeOperation(new klass(@vimState, properties))
      @processing = true
      @process()
    catch error
      @handleError(error)

  handleError: (error) ->
    @vimState.reset()
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

    if @peekTop().isComplete()
      @operation = @stack.pop()
      @execute()
    else
      if @vimState.isMode('normal') and @peekTop().isOperator()
        @vimState.activate('operator-pending')

  execute: ->
    execution = @operation.execute()
    if execution instanceof Promise
      onResolve = @finish.bind(this)
      onReject = @handleError.bind(this)
      execution.then(onResolve).catch(onReject)
    else
      @finish()

  cancel: ->
    if @vimState.mode not in ['visual', 'insert']
      @vimState.activate('reset')
    @finish()

  finish: ->
    @record(@operation) if @operation?.isRecordable()
    @vimState.emitter.emit 'did-finish-operation'
    if @vimState.isMode('normal')
      unless @editor.getLastSelection().isEmpty()
        if settings.get('throwErrorOnNonEmptySelectionInNormalMode')
          throw new Error("Selection is not empty in normal-mode: #{@operation.toString()}")
        else
          @editor.clearSelections()

      # Ensure Cursor is NOT at EndOfLine position
      for cursor in @editor.getCursors() when cursor.isAtEndOfLine()
        moveCursorLeft(cursor, {preserveGoalColumn: true})
    @vimState.refreshCursors()
    @vimState.reset()

  peekTop: ->
    _.last @stack

  reset: ->
    @stack = []
    @operation = null
    @processing = false
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
