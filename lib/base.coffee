# Refactoring status: 100%
_ = require 'underscore-plus'
{getAncestors, getParent} = require './introspection'

class Base
  pure: false
  complete: null
  recodable: null

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState

  isPure: ->
    @pure

  # Operation processor execute only when isComplete() return true.
  # If false, operation processor postpone its execution.
  isComplete: ->
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
