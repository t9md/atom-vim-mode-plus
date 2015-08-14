settings = require './settings'
{getCopyType, getKeystrokeForEvent} = require './utils'
{ViewModel} = require './view'

# Private: Fetches the value of a given register.
#
# name - The name of the register to fetch.
#
# Returns the value of the given register or undefined if it hasn't
# been set.
validRegisterNames = /[a-zA-Z*+%_"]/

module.exports =
class RegisterManager
  constructor: (@vimState) ->
    {@editor, @globalVimState} = @vimState

  isValidRegisterName: (name) ->
    validRegisterNames.test(name)

  get: (name) ->
    return unless @isValidRegisterName(name)
    if name is '"'
      name = settings.defaultRegister()

    switch name
      when '*', '+'
        text = atom.clipboard.read()
        type = getCopyType(text)
      when '%'
        text = @editor.getURI()
        type = getCopyType(text)
      when '_' # Blackhole always returns nothing
        text = ''
        type = getCopyType(text)
      else
        {text, type} = @globalVimState.registers[name.toLowerCase()] ? {}
    {text, type}

  # Private: Sets the value of a given register.
  #
  # name  - The name of the register to fetch.
  # value - The value to set the register to.
  #
  # Returns nothing.
  set: (name, value) ->
    return unless @isValidRegisterName(name)
    if name is '"'
      name = settings.defaultRegister()

    switch name
      when '*', '+'
        atom.clipboard.write(value.text)
      when '_'
        null
      else
        if /^[A-Z]$/.test(name)
          @append(name.toLowerCase(), value)
        else
          @globalVimState.registers[name] = value

  # Private: append a value into a given register
  # like setRegister, but appends the value
  append: (name, {type, text}) ->
    register = @globalVimState.registers[name] ?=
      type: 'character'
      text: ''

    if register.type is 'linewise' and type isnt 'linewise'
      register.text += "#{text}\n"
    else if register.type isnt 'linewise' and type is 'linewise'
      register.text += "\n#{text}"
      register.type = 'linewise'
    else
      register.text += text

  getName: ->
    @name ? settings.defaultRegister()

  setName: ->
    viewModel = new ViewModel(this, class: 'read-register', singleChar: true, hidden: true)
    viewModel.onDidGetInput (@input) =>
      @name = @input

  reset: ->
    @name = null
