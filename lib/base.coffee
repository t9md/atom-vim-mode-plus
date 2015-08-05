module.exports =
class Base
  pure: false
  getName: ->
    @constructor.name

  isPure: ->
    @pure
