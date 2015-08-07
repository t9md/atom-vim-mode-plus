{inspect} = require('util')
_ = require 'underscore-plus'

getArgumentSignature = (fun) ->
  fun.toString().split("\n")[0].match(/(\(.*\))/)[1]

excludeFromReports = [
  '__super__', 'report', 'reportAll', 'constructor',
  'extend', 'getParent', 'getAncestors',
]
# 'vimState'

inspectObject = (obj, options={}, prototype=false) ->
  excludeList = excludeFromReports.slice()
  excludeList.push 'vimState' if options.excludeVimState
  options.depth ?= 0
  obj = obj.prototype if prototype
  prefix = if prototype then '::' else '@'
  s = ''
  ancesstors = obj.constructor.getAncestors?() ? []
  ancesstors.shift() # drop myself.
  for own prop, value of obj when prop not in excludeList
    s += "- #{prefix}#{prop}"
    if value instanceof Base
      s += ":\n"
      s += value.report(options)
    else
      if _.isFunction(value)
        s += getArgumentSignature(value)
      s += ": `#{inspect(value, options)}`"
      if _.detect(ancesstors, (ancestor) -> ancestor::.hasOwnProperty(prop))
        s += ": **Overridden**"
    s += "\n"
  s

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
    s += inspectObject(this, options)
    s += inspectObject(this, options, true)
    s

  @reportAll: ->
    s = ""
    for child in children
      s += child.report()
      s += "\n"
    s

  report: (options={}) ->
    options.excludeVimState = true
    ancesstors = @constructor.getAncestors().map (p) -> p.name
    ancesstors.pop()
    s = "## #{this}: #{ancesstors.join(' < ')}\n"
    s += inspectObject(this, options) + '\n'
    s += @constructor.report(options)

    if options?.indent?
      indent = _.multiplyString(' ', options.indent)
      s = s.split('\n').map (e) ->
        indent + e
      .join('\n')
    s

  getKind: ->
    @constructor.name

  isPure: ->
    @pure

  # Used by Operator and Motion?
  # Maybe we hould move this function to Operator and Motion?
  getCount: (defaultCount=null) ->
    # Setting count as instance var make operation repeatable.
    @count ?= @vimState?.counter.get() ? defaultCount
