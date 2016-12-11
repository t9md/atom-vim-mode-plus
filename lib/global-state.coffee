{Emitter} = require 'atom'

class GlobalState
  constructor: ->
    @reset()
    @emitter = new Emitter

    @onDidChange ({name, newValue}) =>
      # auto sync value, but highlightSearchPattern is solely cleared to clear hlsearch.
      if name is 'lastSearchPattern'
        @set('highlightSearchPattern', newValue)

  get: (name) ->
    @state[name]

  set: (name, newValue) ->
    oldValue = @get(name)
    @state[name] = newValue
    @emitDidChange({name, oldValue, newValue})

  onDidChange: (fn) ->
    @emitter.on('did-change', fn)

  emitDidChange: (event) ->
    @emitter.emit('did-change', event)

  reset: (name) ->
    initialState = getInitialState()
    if name?
      @set(name, initialState[name])
    else
      @state = initialState

getInitialState = ->
  searchHistory: []
  currentSearch: null
  lastSearchPattern: null
  lastOccurrencePattern: null
  highlightSearchPattern: null
  currentFind: null
  register: {}

module.exports = new GlobalState()
