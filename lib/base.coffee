module.exports =
class Base
  pure: false

  getName: ->
    @constructor.name

  isPure: ->
    @pure

  # Used by Operator and Motion?
  # Maybe we hould move this function to Operator and Motion?
  getCount: (defaultCount=null) ->
    # Setting count as instance var make operation repeatable.
    @count ?= @vimState?.getCount() ? defaultCount
