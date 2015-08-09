{inspect} = require('util')
_ = require 'underscore-plus'

extractBetween = (str, s1, s2) ->
  str.substring(str.indexOf(s1)+1, str.lastIndexOf(s2))

inspectFunction = (fun, name) ->
  superBase = _.escapeRegExp("#{fun.name}.__super__.#{name}")
  superAsIs = superBase + _.escapeRegExp(".apply(this, arguments);")
  superWithModify = superBase + '\\.call\\((.*)\\)'
  defaultConstructor = '^return '+  superAsIs

  funString = fun.toString()
  body = extractBetween(funString, '{', '}').split("\n").map (e) -> e.trim()

  # Extract arguments from funString. e.g. function(a1, a1){} -> ['a1', 'a2'].
  funArgs = funString.split("\n")[0].match(/\((.*)\)/)[1].split(/,\s*/g)

  # Replace ['arg1', 'arg2'] to ['@arg1', '@arg2'].
  # Only when instance variable assignment statement was found.
  funArgs = funArgs.map (arg) ->
    iVarAssign = '^' + _.escapeRegExp("this.#{arg} = #{arg};") + '$'
    if (_.detect(body, (line) -> line.match(iVarAssign)))
      '@' + arg
    else
      arg

  argumentSignature = '(' + funArgs.join(', ') + ')'

  # C1.__super__.constructor.apply(this, arguments);
  # C1.__super__.hello.call(this, a1);
  superSignature = null
  for line in body
    if name is 'constructor' and line.match(defaultConstructor)
      superSignature = 'default'
    else if line.match(superAsIs)
      superSignature = "super"
    else if m = line.match(superWithModify)
      args = m[1].replace(/this,?\s*/, '')
      args = args.replace(/this\./g, '@')
      superSignature = "super(#{args})"
    break if superSignature?
  {argumentSignature, superSignature}

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
  results = []
  for own prop, value of obj when prop not in excludeList
    s = "- #{prefix}#{prop}"
    if value instanceof Base
      s += ":\n#{value.report(options)}"
    else
      if _.isFunction(value)
        {argumentSignature, superSignature} = inspectFunction(value, prop)
        # hide default constructor
        continue if (prop is 'constructor') and (superSignature is 'default')
        s += "`#{argumentSignature}`"
        s += ": `#{superSignature}`" if superSignature?
      else
        s += ": `#{inspect(value, options)}`"
      isOverridden = _.detect(ancesstors, (ancestor) -> ancestor::.hasOwnProperty(prop))
      s += ": **Overridden**" if isOverridden
    results.push s
  results.join('\n')

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
    .join('\n') + '\n'

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
