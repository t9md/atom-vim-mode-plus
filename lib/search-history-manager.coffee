_ = require 'underscore-plus'
settings = require './settings'

module.exports =
class SearchHistoryManager
  idx: null

  constructor: (@vimState) ->
    {@globalState} = @vimState
    @idx = -1

  get: (direction) ->
    switch direction
      when 'prev' then @idx += 1 unless (@idx + 1) is @getSize()
      when 'next' then @idx -= 1 unless (@idx is -1)
    @globalState.get('searchHistory')[@idx] ? ''

  save: (entry) ->
    return if _.isEmpty(entry)
    @replaceEntries _.uniq([entry].concat @getEntries())
    if @getSize() > settings.get('historySize')
      @getEntries().splice settings.get('historySize')

  reset: ->
    @idx = -1

  clear: ->
    @replaceEntries []

  getSize: ->
    @getEntries().length

  getEntries: ->
    @globalState.get('searchHistory')

  replaceEntries: (entries) ->
    @globalState.set('searchHistory', entries)

  destroy: ->
    @idx = null
