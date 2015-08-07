{inspect} = require('util')
_ = require 'underscore-plus'

getArgumentSignature = (fun) ->
  fun.toString().split("\n")[0].match(/(\(.*\))/)[1]

extractBetween = (str, s1, s2) ->
  str.substring(str.indexOf(s1)+1, str.lastIndexOf(s2))

inspectFunction = (fun, name) ->
  superBase = _.escapeRegExp("#{fun.name}.__super__.#{name}")
  superAsIs = superBase + _.escapeRegExp(".apply(this, arguments);")
  superWithModify = superBase + '\\.call\\((.*)\\)'

  body = extractBetween(fun.toString(), '{', '}')
  body = body.split("\n").map (e) -> e.trim()
  superSignature = null
  for line in body
    # if m = line.match(noConstructor)
    #   superSignature = 'no constructor'
    #   break
    if m = line.match(superAsIs)
      superSignature = 'super'
      break
    else if m = line.match(superWithModify)
      args = m[1].replace(/this,?\s*/, '')
      args = args.replace(/this\./g, '@')
      superSignature = "super(#{args})"
      break
  # superSignature ?= 'no super'
  superSignature

# parseConstructor = (fun) ->
#   superBase = _.escapeRegExp("#{fun.name}.__super__.constructor")
#   superAsIs = superBase + _.escapeRegExp(".apply(this, arguments);")
#   superWithModify = superBase + '\\.call\\((.*)\\)'
#
#   body = fun.toString().split("\n").map (e) -> e.trim()
#   superSignature = ''
#   for line in body
#     if m = line.match(superAsIs)
#       superSignature = 'super'
#       break
#     else if m = line.match(superWithModify)
#       args = m[1].replace(/this,?\s*/, '')
#       superSignature = "super(#{args})"
#       break
#   superSignature

excludeProperties = [
  '__super__', 'report', 'reportAll'
  'extend', 'getParent', 'getAncestors',
]

inspectObject = (obj, options={}, prototype=false) ->
  excludeList = excludeProperties.concat (options.excludeProperties ? [])
  options.depth ?= 0
  prefix = '@'
  if prototype
    obj = obj.prototype
    prefix = '::'
  ancesstors = obj.constructor.getAncestors?() ? []
  ancesstors.shift() # drop myself.
  s = ''
  for own prop, value of obj when prop not in excludeList
    s += "- #{prefix}:#{prop}"
    if value instanceof Base
      s += ":\n#{value.report(options)}"
    else
      isOverridden = _.detect(ancesstors, (ancestor) -> ancestor::.hasOwnProperty(prop))
      if _.isFunction(value)
        s += "`#{getArgumentSignature(value)}`"
        if isOverridden
          if result = inspectFunction(value, prop)
            s += ": `#{result}`"
      else
        s += ": `#{inspect(value, options)}`"
      if isOverridden
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
    # children = children.filter (c) -> c.name is 'Operator'
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
