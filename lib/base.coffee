{inspect} = require('util')
_ = require 'underscore-plus'
{inspectObject, report, getAncestors, getParent} = require './introspection'

excludeProperties = [
  '__super__', 'report', 'reportAll'
  'extend', 'getParent', 'getAncestors',
]

module.exports =
class Base
  pure: false

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

  getKind: ->
    @constructor.name

  isPure: ->
    @pure

  # Used by Operator and Motion?
  # Maybe we hould move this function to Operator and Motion?
  getCount: (defaultCount=null) ->
    # Setting count as instance variable make operation repeatable.
    @count ?= @vimState?.counter.get() ? defaultCount
    @count

  @getAncestors: ->
    getAncestors(this)

  @getParent: ->
    getParent(this)

  @reportAll: ->
    (child.report() for child in children).join('\n')
