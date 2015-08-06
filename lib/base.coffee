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
  @extend: ->
    klass = this
    Base::["is#{klass.name}"] = ->
      this instanceof klass
    children.push klass

  excludeFromReports = ['__super__', 'report', 'reportAll', 'constructor', 'extend', 'getParent', 'getAncestors']
  inspect = (obj, options={}) ->
    options.depth ?= 0
    util.inspect(obj, options)

  @getAncestors: ->
    ancestors = []
    ancestors.push (current=this)
    while current = current.getParent()
      ancestors.push current
    ancestors

  @getParent: ->
    this.__super__?.constructor

  @report: (options) ->
    ancestors = @getAncestors().map (p) -> p.name
    ancestors.pop()
    s = "### #{ancestors.join(' < ')}\n"
    for own key, value of this when key not in excludeFromReports
      s += "- @#{key}"
      s += ": `#{inspect(value, options)}`"
      s += "\n"

    for own key, value of this.prototype when key not in excludeFromReports
      s += "- ::#{key}"
      s += ": `#{inspect(value, options)}`"
      s += "\n"
    s

  @reportAll: ->
    s = ""
    for child in children
      s += child.report()
      s += "\n"
    s

  report: (options) ->
    s = "## #{this}\n"
    for own key, value of this when key not in excludeFromReports
      s += "- @#{key}"
      s += ": `#{inspect(value, options)}`"
      s += "\n\n"

    s += @constructor.report(options)
    s

  getKind: ->
    @constructor.name

  isPure: ->
    @pure

  # Used by Operator and Motion?
  # Maybe we hould move this function to Operator and Motion?
  getCount: (defaultCount=null) ->
    # Setting count as instance var make operation repeatable.
    # @count ?= @vimState?.getCount() ? defaultCount
    @count ?= @vimState?.counter.get() ? defaultCount
