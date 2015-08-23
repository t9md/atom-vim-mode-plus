_ = require 'underscore-plus'
TextObjects = require './text-objects'
Operators   = require './operators'
{debug} = require './utils'
settings = require './settings'
Base = require './base'
introspection = require './introspection'

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
      # If we've started in visual-mode, and pushed operation with select method,
      # set implicit Select operator as operator to modify selection with select
      # method on target. Here target is Motion or TextObject.
      # So use implicit Select operator as operator.
      if @vimState.isVisualMode() and _.isFunction(op.select)
        debug "push INPLICIT Operators.Select"
        @stack.push(new Operators.Select(@vimState))

      debug "pushing <#{op.getKind()}>"
      @stack.push op

      # If we've received an operator in visual mode, set inplict CurrentSelection TextObject
      # as a target of operator.
      if @vimState.isVisualMode() and op.isOperator()
        debug "push INPLICIT TextObjects.CurrentSelection"
        @stack.push(new TextObjects.CurrentSelection(@vimState))
      @process()

    for cursor in @vimState.editor.getCursors()
      @vimState.ensureCursorIsWithinLine(cursor)

  inspect: ->
    debug "  [@stack] size: #{@stack.length}"
    for op, i in @stack
      debug "  <idx: #{i}>"
      if settings.get('debug')
        debug introspection.inspectInstance op,
          indent: 2
          colors: settings.get('debugOutput') is 'file'
          excludeProperties: [
            'vimState', 'editorElement'
            'report', 'reportAll'
            'extend', 'getParent', 'getAncestors',
          ] # vimState have many properties, occupy DevTool console.
          recursiveInspect: Base

  # Processes the command if the last operation is complete.
  process: ->
    debug "-> @process(): start"

    if @stack.length > 2
      throw "Must not happen"

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
        debug "-> @process(): activating: operator-pending-mode"
        @vimState.activateOperatorPendingMode()
      else
        debug "-> @process(): return: not <#{@peekTop().getKind()}>.isComplete()"
      return

    @inspect()
    debug "-> @pop()"
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
