{inspect} = require('util')
_ = require 'underscore-plus'

getArgumentSignature = (fun) ->
  fun.toString().split("\n")[0].match(/(\(.*\))/)[1]

excludeFromReports = [
  '__super__', 'report', 'reportAll', 'constructor',
  'extend', 'getParent', 'getAncestors',
]

inspectObject = (obj, options={}, prototype=false) ->
  excludeList = excludeFromReports.slice()
  # When observing operationStack, I want vimState excluded,
  #  since its have a lot of properties(occupy DevTools console output).
  excludeList.push 'vimState' if options.excludeVimState
  options.depth ?= 0
  obj = obj.prototype if prototype
  prefix = if prototype then '::' else '@'
  ancesstors = obj.constructor.getAncestors?() ? []
  ancesstors.shift() # drop myself.
  s = ''
  for own prop, value of obj when prop not in excludeList
    s += "- #{prefix}#{prop}"
    if value instanceof Base
      s += ":\n#{value.report(options)}"
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
    ancestors = @getAncestors()
    ancestors.pop() # drop Base class.
    [
      "### " + _.pluck(ancestors, 'name').join(' < ')
      inspectObject(this, options)
      inspectObject(this, options, true)
    ].filter (e) -> e.length
    .join('\n')


  @reportAll: ->
    (child.report() for child in children).join('\n')

  report: (options={}) ->
    options.excludeVimState = true
    ancesstors = @constructor.getAncestors()
    ancesstors.pop()
    indent = _.multiplyString(' ', options.indent ? 0)
    [
      "## #{this}: " + _.pluck(ancesstors, 'name').join(' < ')
      inspectObject(this, options)
      @constructor.report(options)
    ].filter (e) -> e.length
    .join('\n').split('\n').map((e) -> indent + e).join('\n')

  getKind: ->
    @constructor.name

  isPure: ->
    @pure

  # Used by Operator and Motion?
  # Maybe we hould move this function to Operator and Motion?
  getCount: (defaultCount=null) ->
    # Setting count as instance variable make operation repeatable.
    @count ?= @vimState?.counter.get() ? defaultCount
