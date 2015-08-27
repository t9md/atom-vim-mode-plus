# Refactoring status: 50%
# TODO: make global instead of refereing globalVimState.
# no need to instantiate per vimState.
settings = require './settings'
{ViewModel} = require './view'

# Private: Fetches the value of a given register.
#
# name - The name of the register to fetch.
#
# Returns the value of the given register or undefined
validNames = /[a-zA-Z*+%_"]/

module.exports =
class RegisterManager
  constructor: ->
    @data = {}

  isValidName: (name) ->
    validNames.test(name)

  get: (name) ->
    return unless @isValidName(name)
    name = settings.get('defaultRegister') if name is '"'

    switch name
      when '*', '+'
        text = atom.clipboard.read()
        type = @getCopyType(text)
      when '%'
        text = atom.workspace.getActiveTextEditor().getURI()
        type = @getCopyType(text)
      when '_' # Blackhole always returns nothing
        text = ''
        type = @getCopyType(text)
      else
        {text, type} = @data[name.toLowerCase()] ? {}
    {text, type}

  # Private: Sets the value of a given register.
  #
  # name  - The name of the register to fetch.
  # value - The value to set the register to, with following properties.
  #  text: text to save to register.
  #  type: (optional) if ommited automatically set from text.
  #
  # Returns nothing.
  set: (name, {text, type}={}) ->
    return unless @isValidName(name)
    type ?= @getCopyType(text)
    name = settings.get('defaultRegister') if name is '"'

    switch name
      when '*', '+'
        atom.clipboard.write(text)
      when '_', '%'
        null
      else
        if /^[A-Z]$/.test(name)
          @append(name.toLowerCase(), {text, type})
        else
          @data[name] = {text, type}

  # Private: append a value into a given register
  # like setRegister, but appends the value
  append: (name, {type, text}) ->
    register = @data[name] ?= type: 'character', text: ''
    if 'linewise' in [register.type, type]
      if register.type isnt 'linewise'
        register.text += '\n'
        register.type = 'linewise'
      text += '\n' if type isnt 'linewise'
    register.text += text

  reset: ->
    @name = null

  getName: ->
    @name ? settings.get('defaultRegister')

  setName: (vimState) ->
    viewModel = new ViewModel vimState,
      class: 'read-register'
      singleChar: true
      hidden: true
    viewModel.onDidGetInput (@name) =>

  getCopyType: (text) ->
    if text.lastIndexOf("\n") is text.length - 1
      'linewise'
    else if text.lastIndexOf("\r") is text.length - 1
      'linewise'
    else
      # [FIXME] should characterwise or line and character
      'character'
