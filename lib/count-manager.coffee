# Refactoring status: 100%
_ = require 'underscore-plus'
{toggleClassByCondition} = require './utils'

class CountManager
  count: null

  constructor: (@vimState) ->
    {@editorElement} = @vimState

  set: (num) ->
    @count ?= 0
    @count = (@count * 10) + num
    @vimState.hover.add num
    @updateEditorElement()

  get: ->
    @count

  reset: ->
    @count = null
    @updateEditorElement()

  updateEditorElement: ->
    toggleClassByCondition(@editorElement, 'with-count', @count?)

module.exports = CountManager
