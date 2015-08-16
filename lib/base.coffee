_ = require 'underscore-plus'
{getAncestors, getParent} = require './introspection'

module.exports =
class Base
  pure: false
  complete: null
  recodable: null

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState

  isPure: ->
    @pure

  isComplete: ->
    @complete

  isRecordable: ->
    @recodable

  getKind: ->
    @constructor.name

  getCount: (defaultCount=null) ->
    # Setting count as instance variable make operation repeatable.
    @count ?= @vimState?.count.get() ? defaultCount
    @count

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
