_ = require 'underscore-plus'
settings = require './settings'

module.exports =
class SearchHistoryManager
  idx: null

  constructor: (@vimState) ->
    {@globalVimState} = @vimState
    @idx = -1

  get: (direction) ->
    switch direction
      when 'prev' then @idx += 1 unless (@idx + 1) is @getSize()
      when 'next' then @idx -= 1 unless (@idx is -1)
    @globalVimState.searchHistory[@idx] ? ''

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
    @globalVimState.searchHistory

  replaceEntries: (entries) ->
    @globalVimState.searchHistory = entries

  destroy: ->
    @idx = null
