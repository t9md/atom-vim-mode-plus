_ = require 'underscore-plus'
{getKeystrokeForEvent} = require './utils'
# Private: A create a Number prefix based on the event.
#
# e - The event that triggered the Number prefix.
#
# Returns nothing.
module.exports =
class CountManager
  count: null

  constructor: (@vimState) ->

  set: (e) ->
    # To cover scenario `10d3y` in this case we use 3, need to trash 10.
    if @vimState.operationStack.isOperatorPending()
      @reset()
    num = if _.isNumber(e) then e else parseInt(getKeystrokeForEvent(e))

    @count ?= 0
    @count = (@count * 10) + num

  get: ->
    @count

  reset: ->
    @count = null

  isEmpty: ->
    not @count
