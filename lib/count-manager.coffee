# Refactoring status: 100%
_ = require 'underscore-plus'
{getKeystrokeForEvent} = require './utils'

module.exports =
class CountManager
  count: null

  constructor: (@vimState) ->

  set: (e) ->
    num = if _.isNumber(e) then e else parseInt(getKeystrokeForEvent(e))
    @count ?= 0
    @count = (@count * 10) + num
    @vimState.hover.add num

  get: ->
    @count

  reset: ->
    @count = null
