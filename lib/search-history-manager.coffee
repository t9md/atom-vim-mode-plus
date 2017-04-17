_ = require 'underscore-plus'

module.exports =
class SearchHistoryManager
  idx: null

  constructor: (@vimState) ->
    {@globalState} = @vimState
    @idx = -1
    @vimState.onDidDestroy(@destroy)

  get: (direction) ->
    switch direction
      when 'prev' then @idx += 1 unless (@idx + 1) is @getSize()
      when 'next' then @idx -= 1 unless (@idx is -1)
    @globalState.get('searchHistory')[@idx] ? ''

  save: (entry) ->
    return if _.isEmpty(entry)

    entries = @globalState.get('searchHistory').slice()
    entries.unshift(entry)
    entries = _.uniq(entries)
    if @getSize() > @vimState.getConfig('historySize')
      entries.splice(@vimState.getConfig('historySize'))
    @globalState.set('searchHistory', entries)

  reset: ->
    @idx = -1

  clear: ->
    @globalState.reset('searchHistory')

  getSize: ->
    @globalState.get('searchHistory').length

  destroy: =>
    @idx = null
