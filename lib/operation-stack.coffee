_ = require 'underscore-plus'

{Disposable, CompositeDisposable} = require 'atom'
Base = require './base'
{moveCursorLeft, getVisibleBufferRange} = require './utils'
settings = require './settings'
{CurrentSelection, Select, MoveToRelativeLine} = {}
{OperationStackError, OperatorError, OperationAbortedError} = require './errors'
swrap = require './selection-wrapper'

{debug, getWordPatternAtCursor, scanInRanges, highlightRanges} = require './utils'


# opration life in operationStack
# 1. run
#    instantiated by new
#    composed with implicit Operator.Select or Motion.CurrentSelection if necessary
#    push composed opration to stack
# 2. process
#    reduce stack by
#     pop operation and set it as target of new stack top(which should be operator).
#    check if remaining top of stack is executable by calling isComplete()
#    if executable, then pop stack then execute(poppedOperation)
#    if not executable, enter "operator-pending-mode"
class OperationStack
  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    CurrentSelection ?= Base.getClass('CurrentSelection')
    Select ?= Base.getClass('Select')
    MoveToRelativeLine ?= Base.getClass('MoveToRelativeLine')
    @reset()

  # Return handler
  subscribe: (handler) ->
    @subscriptions.add(handler)
    handler # DONT REMOVE

  composeOperation: (operation) ->
    {mode} = @vimState
    switch
      when operation.isOperator()
        if (mode is 'visual') and not operation.hasTarget() # don't want to override target
          operation = operation.setTarget(new CurrentSelection(@vimState))
      when operation.isTextObject()
        unless mode is 'operator-pending'
          operation = new Select(@vimState).setTarget(operation)
      when operation.isMotion()
        if (mode is 'visual')
          operation = new Select(@vimState).setTarget(operation)
    operation

  hasSelectionProperty: ->
    swrap(@editor.getLastSelection()).hasProperties()

  run: (klass, properties={}) ->
    # @reportAliveMakerLength('run')
    if settings.get('debug')
      debug 'run-start:', @hasSelectionProperty()
    try
      switch type = typeof(klass)
        when 'string', 'function'
          klass = Base.getClass(klass) if type is 'string'
          # When identical operator repeated, it set target to MoveToRelativeLine.
          #  e.g. `dd`, `cc`, `gUgU`
          klass = MoveToRelativeLine if (@peekTop()?.constructor is klass)
          operation = @composeOperation(new klass(@vimState, properties))
        when 'object' # . repeat case
          operation = klass
        else
          throw new Error('Unsupported type of operation')

      @stack.push(operation)
      @vimState.emitter.emit('did-push-operation', operation)
      @process()
    catch error
      @handleError(error)

  runRecorded: ->
    if operation = @getRecorded()
      operation.setRepeated()
      if @hasCount()
        count = @getCount()
        operation.count = count
        operation.target?.count = count # Some opeartor have no target like ctrl-a(increase).

      # [FIXME] Degradation, this `transact` should not be necessary
      @editor.transact =>
        @run(operation)

  handleError: (error) ->
    @vimState.reset()
    unless error instanceof OperationAbortedError
      throw error

  isProcessing: ->
    @processing

  updateOccurrenceView: ->
    @addToClassList('with-occurrence')
    unless @hasOccurrenceMarkers()
      @highlightOccurrence()
      @clearOccurrenceMarkersOnReset()

  process: ->
    @processing = true
    if @stack.length > 2
      throw new Error('Operation stack must not exceeds 2 length')

    try
      @reduce()
      top = @peekTop()

      if top.isComplete()
        debug "will-execute:", top.toString()
        @execute(@stack.pop())
      else
        if @vimState.isMode('normal') and top.isOperator()
          @vimState.activate('operator-pending')
          @updateOccurrenceView() if top.isOccurrence()

        # Temporary set while command is running
        if commandName = top.constructor.getCommandNameWithoutPrefix?()
          @addToClassList(commandName + "-pending")
    catch error
      switch
        when error instanceof OperatorError
          @vimState.resetNormalMode()
        when error instanceof OperationStackError
          @vimState.resetNormalMode()
        else
          throw error

  addToClassList: (className) ->
    @editorElement.classList.add(className)
    @subscribe new Disposable =>
      @editorElement.classList.remove(className)

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

  reportAliveMakerLength: (subject) ->
    length = @vimState.markerLayer.getMarkers().length
    console.log "#{subject}:", length

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
    debug '---------------'
    # @reportAliveMakerLength('fin')

  peekTop: ->
    _.last(@stack)

  peekBottom: ->
    @stack[0]

  reduce: ->
    until @stack.length < 2
      operation = @stack.pop()
      unless @peekTop().setTarget?
        throw new OperationStackError("The top operation in operation stack is not operator!")
      @peekTop().setTarget(operation)

  reset: ->
    @resetCount()
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

  setOperatorModifier: (modifiers) ->
    # In operator-pending-mode, stack length is always 1 and its' operator.
    # So either of @peekTop() or @peekBottom() is OK
    operator = @peekBottom()
    for name, value of modifiers when name in ['occurrence', 'wise']
      operator[name] = value
      if name is "occurrence" and value
        operator.patternForOccurence = null
        @clearOccurrenceMarkers()
        @updateOccurrenceView()

  # Count
  # -------------------------
  # keystroke `3d2w` delete 6(3*2) words.
  #  2nd number(2 in this case) is always enterd in operator-pending-mode.
  #  So count have two timing to be entered. that's why here we manage counter by mode.
  hasCount: ->
    @count['normal']? or @count['operator-pending']?

  getCount: ->
    if @hasCount()
      (@count['normal'] ? 1) * (@count['operator-pending'] ? 1)
    else
      null

  setCount: (number) ->
    if @vimState.mode is 'operator-pending'
      mode = @vimState.mode
    else
      mode = 'normal'
    @count[mode] ?= 0
    @count[mode] = (@count[mode] * 10) + number
    @vimState.hover.add(number)
    @vimState.toggleClassList('with-count', true)

  resetCount: ->
    @count = {}
    @vimState.toggleClassList('with-count', false)

  occurrenceMarkers: null
  hasOccurrenceMarkers: ->
    @occurrenceMarkers?

  clearOccurrenceMarkers: ->
    marker.destroy() for marker in @occurrenceMarkers ? []
    @occurrenceMarkers = null

  clearOccurrenceMarkersOnReset: ->
    @subscribe new Disposable =>
      @clearOccurrenceMarkers()

  highlightOccurrence: (pattern=null) ->
    pattern ?= getWordPatternAtCursor(@editor.getLastCursor(), singleNonWordChar: true)
    scanRanges = [getVisibleBufferRange(@editor)]
    @occurrenceMarkers = highlightRanges(
      @editor,
      scanInRanges(@editor, pattern, scanRanges),
      class: 'vim-mode-plus-occurrence-match'
    )

module.exports = OperationStack
