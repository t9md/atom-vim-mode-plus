module.exports =
class Base
  pure: false

  # Expected to be called by child class.
  # it automatically create typecheck function like
  # isOperator: ->
  #   this instanceof Operator
  @extend: ->
    klass = this
    Base::["is#{klass.name}"] = ->
      this instanceof klass

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
