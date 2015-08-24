_ = require 'underscore-plus'

module.exports =
class CountManager
  count: null

  constructor: (@vimState) ->

  set: (e) ->
    # To cover scenario `10d3y` in this case we use 3, need to trash 10.
    if @vimState.operationStack.isOperatorPending()
      @reset()
    num = if _.isNumber(e) then e else parseInt(@getKeystrokeForEvent(e))

    @count ?= 0
    @count = (@count * 10) + num

  get: ->
    @count

  reset: ->
    @count = null

  isEmpty: ->
    not @count

  getKeystrokeForEvent: (event) ->
    keyboardEvent = event.originalEvent?.originalEvent ? event.originalEvent
    atom.keymaps.keystrokeForKeyboardEvent(keyboardEvent)
