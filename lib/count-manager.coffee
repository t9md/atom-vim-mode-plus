_ = require 'underscore-plus'
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
    if _.isNumber(e)
      num = e
    else
      keyboardEvent = e.originalEvent?.originalEvent ? e.originalEvent
      num = parseInt(atom.keymaps.keystrokeForKeyboardEvent(keyboardEvent))

    # To cover scenario `10d3y` in this case we use 3, need to trash 10.
    if @vimState.operationStack.isOperatorPending()
      @reset()
    @count ?= 0
    @count = (@count * 10) + num

  get: ->
    @count

  reset: ->
    @count = null

  isEmpty: ->
    @count?
