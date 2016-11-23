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
    entries = _.uniq([entry].concat(@getEntries()))
    if @getSize() > settings.get('historySize')
      entries.splice(settings.get('historySize'))
    @globalState.set('searchHistory', entries)

  reset: ->
    @idx = -1

  clear: ->
    @globalState.reset('searchHistory')

  getSize: ->
    @getEntries().length

  getEntries: ->
    @globalState.get('searchHistory')

  destroy: ->
    @idx = null
