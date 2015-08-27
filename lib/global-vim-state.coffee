RegisterManager = require './register-manager'

# Refactoring status: 100%
module.exports =
class GlobalVimState
  searchHistory: []
  currentSearch: {}
  currentFind: null
  constructor: ->
    @register = new RegisterManager
