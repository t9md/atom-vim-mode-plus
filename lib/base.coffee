# Refactoring status: 100%
_ = require 'underscore-plus'
{getAncestors, getParent} = require './introspection'
settings = require './settings'

class Base
  pure: false
  complete: null
  recodable: null
  requireInput: false
  canceled: false

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    if settings.get('enableHoverIcon')
      hover =
        switch settings.get('hoverStyle')
          when 'emoji' then @hoverText if @hoverText?
          when 'icon'  then @hoverIcon if @hoverIcon?
      @vimState.hover.add hover if hover?

  isPure: ->
    @pure

  # Operation processor execute only when isComplete() return true.
  # If false, operation processor postpone its execution.
  isComplete: ->
    if @isCanceled()
      return true

    if @requireInput and not @input
      return false

    if @target?
      @target.isComplete()
    else
      @complete

  isRecordable: ->
    @recodable

  abort: ->
    throw new OperationAbortedError('Aborted')

  getKind: ->
    @constructor.name

  getCount: (defaultCount=null) ->
    # Setting count as instance variable make operation repeatable.
    @count ?= @vimState?.count.get() ? defaultCount
    @count

  new: (klassName, properties={}) ->
    obj = new (Base.findClass(klassName))(@vimState)
    _.extend(obj, properties)

  getInput: (options={}) ->
    @vimState.input.onDidGet options, (input) =>
      # console.log "#{@constructor.name}: #{@input}"
      # console.log "get input"
      if options.onGet?
        options.onGet(input)
      else
        @input = input
        @complete = true
        @vimState.operationStack.process()

    @vimState.input.onDidCancel =>
      # console.log "Cancelled!"
      @canceled = true
      @vimState.operationStack.process()

    if options.onChange?
      @vimState.input.onDidChange (input) ->
        options.onChange(input)

    @vimState.input.focus()

  isCanceled: ->
    @canceled

  cancel: ->
    unless @vimState.isVisualMode() or @vimState.isInsertMode()
      @vimState.resetNormalMode()

  # Expected to be called by child class.
  # It automatically create typecheck function like
  #
  # e.g.
  #   class Operator extends base
  #     @extends()
  #
  # Above code automatically define following function.
  #
  # Base::isOperator: ->
  #   this instanceof Operator
  #
  children = []
  @extend: ->
    klass = this
    Base::["is#{klass.name}"] = ->
      this instanceof klass
    children.push klass

  @findClass: (klassName) ->
    # [FIXME] currently not care acncesstor's chain.
    # Not accurate if there is different class with same.
    _.detect children, (child) ->
      child.name is klassName

  @getAncestors: ->
    getAncestors(this)

  @getParent: ->
    getParent(this)

class OperationAbortedError extends Base
  @extend()
  constructor: (@message) ->
    @name = 'OperationAborted Error'

module.exports = Base
