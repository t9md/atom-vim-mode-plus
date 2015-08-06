util = require('util')

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
  excludeFromReports = ['__super__', 'report', 'reportAll', 'constructor', 'extend', 'getParent', 'getAncestors']
  inspect = (obj) -> util.inspect(obj, depth: 0)

  @getAncestors: ->
    ancestors = []
    ancestors.push (current=this)
    while current = current.getParent()
      ancestors.push current
    ancestors

  @getParent: ->
    this.__super__?.constructor

  @extend: ->
    klass = this
    Base::["is#{klass.name}"] = ->
      this instanceof klass

    children.push klass

  @report: (detail=false) ->
    ancestors = @getAncestors().map (p) -> p.name
    ancestors.pop()
    s = "### #{ancestors.join(' < ')}\n"
    for own key, value of this when key not in excludeFromReports
      s += "- @#{key}"
      s += ": `#{inspect(value)}`" if detail
      s += "\n"

    for own key, value of this.prototype when key not in excludeFromReports
      s += "- ::#{key}"
      s += ": `#{inspect(value)}`" if detail
      s += "\n"
    s

  @reportAll: (detail=false) ->
    s = ""
    for child in children
      s += child.report(detail)
      s += "\n"
    s

  report: (detail=false) ->
    s = "## #{this}\n"
    for own key, value of this when key not in excludeFromReports
      s += "- @#{key}"
      s += ": `#{inspect(value)}`" if detail
      s += "\n\n"

    s += @constructor.report(detail)
    s

  getName: ->
    @constructor.name

  isPure: ->
    @pure

  # Used by Operator and Motion?
  # Maybe we hould move this function to Operator and Motion?
  getCount: (defaultCount=null) ->
    # Setting count as instance var make operation repeatable.
    # @count ?= @vimState?.getCount() ? defaultCount
    @count ?= @vimState?.counter.get() ? defaultCount
