_ = require 'underscore-plus'

{Disposable, CompositeDisposable} = require 'atom'
Base = require './base'
{moveCursorLeft} = require './utils'
settings = require './settings'
{CurrentSelection, Select, MoveToRelativeLine} = {}
{OperationStackError, OperatorError, OperationAbortedError} = require './errors'

class OperationStack
  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    CurrentSelection ?= Base.getClass('CurrentSelection')
    Select ?= Base.getClass('Select')
    MoveToRelativeLine ?= Base.getClass('MoveToRelativeLine')
    @reset()

  subscribe: (args...) ->
    @subscriptions.add args...

  composeOperation: (operation) ->
    {mode} = @vimState
    switch
      when operation.isOperator()
        if (mode is 'visual') and operation.isRequireTarget()
          operation = operation.setTarget(new CurrentSelection(@vimState))
      when operation.isTextObject()
        unless mode is 'operator-pending'
          operation = new Select(@vimState, target: operation)
      when operation.isMotion()
        if (mode is 'visual')
          operation = new Select(@vimState, target: operation)
    operation

  run: (klass, properties={}) ->
    klass = Base.getClass(klass) if _.isString(klass)
    try
      # When identical operator repeated, it set target to MoveToRelativeLine.
      #  e.g. `dd`, `cc`, `gUgU`
      if (@peekTop()?.constructor is klass)
        klass = MoveToRelativeLine
      operation = new klass(@vimState, properties)
      @stack.push(@composeOperation(operation))
      @process()
    catch error
      @handleError(error)

  handleError: (error) ->
    @vimState.reset()
    unless error instanceof OperationAbortedError
      throw error

  isProcessing: ->
    @processing

  process: ->
    @processing = true
    if @stack.length > 2
      throw new Error('Operation stack must not exceeds 2 length')

    try
      @reduce()
      if @peekTop().isComplete()
        @execute(@stack.pop())
      else
        if @vimState.isMode('normal') and @peekTop().isOperator()
          @vimState.activate('operator-pending')

        # Temporary set while command is running
        if scope = @peekTop().constructor.getCommandNameWithoutPrefix?()
          scope += "-pending"
          @editorElement.classList.add(scope)
          @subscribe new Disposable =>
            @editorElement.classList.remove(scope)
    catch error
      switch
        when error instanceof OperatorError
          @vimState.resetNormalMode()
        when error instanceof OperationStackError
          @vimState.resetNormalMode()
        else
          throw error

  execute: (operation) ->
    execution = operation.execute()
    if execution instanceof Promise
      finish = => @finish(operation)
      handleError = => @handleError()
      execution
        .then(finish)
        .catch(handleError)
    else
      @finish(operation)

  cancel: ->
    if @vimState.mode not in ['visual', 'insert']
      @vimState.resetNormalMode()
    @finish()

  ensureAllSelectionsAreEmpty: (operation) ->
    unless @editor.getLastSelection().isEmpty()
      if settings.get('throwErrorOnNonEmptySelectionInNormalMode')
        throw new Error("Selection is not empty in normal-mode: #{operation.toString()}")
      else
        @editor.clearSelections()

  ensureAllCursorsAreNotAtEndOfLine: ->
    for cursor in @editor.getCursors() when cursor.isAtEndOfLine()
      # [FIXME] SCATTERED_CURSOR_ADJUSTMENT
      moveCursorLeft(cursor, {preserveGoalColumn: true})

  finish: (operation=null) ->
    @record(operation) if operation?.isRecordable()
    @vimState.emitter.emit('did-finish-operation')
    
    if @vimState.isMode('normal')
      @ensureAllSelectionsAreEmpty(operation)
      @ensureAllCursorsAreNotAtEndOfLine()
    if @vimState.isMode('visual')
      @vimState.modeManager.updateNarrowedState()
    @vimState.updateCursorsVisibility()
    @vimState.reset()

  peekTop: ->
    _.last(@stack)

  reduce: ->
    until @stack.length < 2
      operation = @stack.pop()
      unless @peekTop().setTarget?
        throw new OperationStackError("The top operation in operation stack is not operator!")
      @peekTop().setTarget(operation)

  reset: ->
    @stack = []
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

  setOperatorModifier: (modifier) ->
    # In operator-pending-mode, stack length is always 1 and its' operator.
    # So either of @stack[0] or @peekTop() is OK.
    if @vimState.isMode('operator-pending')
      @stack[0].setOperatorModifier(modifier)

module.exports = OperationStack
