{Emitter} = require 'atom'

class GlobalState
  constructor: (@state) ->
    @emitter = new Emitter

  get: (name) ->
    @state[name]

  set: (name, newValue) ->
    oldValue = @get(name)
    @state[name] = newValue
    @emitDidChange({name, oldValue, newValue})

  onDidChange: (fn) ->
    @emitter.on('did-change-value', fn)

  emitDidChange: (event) ->
    @emitter.emit('did-change-value', event)

module.exports = new GlobalState
  searchHistory: []
  currentSearch: null
  lastSearchPattern: null
  currentFind: null
  previousSelection:
    properties: null
    submode: null
  register: {}
