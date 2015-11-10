# Refactoring status: 100%
_ = require 'underscore-plus'
{getAncestors, getParent} = require './introspection'
settings = require './settings'

class Base
  complete: false
  recodable: false
  defaultCount: 1
  requireInput: false

  constructor: (@vimState, properties) ->
    {@editor, @editorElement} = @vimState
    if settings.get('showHoverOnOperate')
      @vimState.hover.setPoint() if @hoverText?
      hover =
        switch settings.get('showHoverOnOperateIcon')
          when 'emoji' then @hoverText if @hoverText?
          when 'icon'  then @hoverIcon if @hoverIcon?
          else null
      @vimState.hover.add hover if hover?
    _.extend(this, properties)
    @initialize?()

  # Operation processor execute only when isComplete() return true.
  # If false, operation processor postpone its execution.
  isComplete: ->
    return false if (@requireInput and not @input)
    if @target?
      @target.isComplete()
    else
      @complete

  isRecordable: ->
    @recodable

  abort: ->
    throw new OperationAbortedError('Aborted')

  # TODO: remove in near future
  getKind: ->
    @constructor.name

  getCount: ->
    # Setting count as instance variable allows operation repeatable with same count.
    @count ?= @vimState?.count.get() ? @defaultCount
    @count

  new: (klassName, properties={}) ->
    klass = Base.getConstructor(klassName)
    new klass(@vimState, properties)

  readInput: ({charsMax}={}) ->
    charsMax ?= 1
    @vimState.input.readInput {charsMax},
      onConfirm: (input) =>
        @input = input
        @complete = true
        @vimState.operationStack.process()
      onCancel: =>
        @vimState.operationStack.cancel()

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
  # children = []
  children = Object.create(null)
  @extend: ->
    klass = this
    if klass.name of children
      console.warn "Duplicate constructor #{klass.name}"
    children[klass.name] = klass
    Base::["is#{klass.name}"] = ->
      this instanceof klass

  @getConstructor: (klassName) ->
    children[klassName]

  @getAncestors: ->
    getAncestors(this)

  @getParent: ->
    getParent(this)

class OperationAbortedError extends Base
  @extend()
  constructor: (@message) ->
    @name = 'OperationAborted Error'

module.exports = Base
