settings = require './settings'
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
        type = @getCopyType(text)
      when '%'
        text = @editor.getURI()
        type = @getCopyType(text)
      when '_' # Blackhole always returns nothing
        text = ''
        type = @getCopyType(text)
      else
        {text, type} = @globalVimState.registers[name.toLowerCase()] ? {}
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
    return unless @isValidRegisterName(name)
    type = @getCopyType(text) unless type

    if name is '"'
      name = settings.defaultRegister()

    switch name
      when '*', '+'
        atom.clipboard.write(text)
      when '_', '%'
        null
      else
        if /^[A-Z]$/.test(name)
          @append(name.toLowerCase(), {text, type})
        else
          @globalVimState.registers[name] = {text, type}

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

  reset: ->
    @name = null

  getName: ->
    @name ? settings.defaultRegister()

  setName: ->
    viewModel = new ViewModel(this, class: 'read-register', singleChar: true, hidden: true)
    viewModel.onDidGetInput (@input) =>
      @name = @input

  # Public: Determines if a string should be considered linewise or character
  #
  # text - The string to consider
  #
  # Returns 'linewise' if the string ends with a line return and 'character'
  #  otherwise.
  getCopyType: (text) ->
    if text.lastIndexOf("\n") is text.length - 1
      'linewise'
    else if text.lastIndexOf("\r") is text.length - 1
      'linewise'
    else
      # [FIXME] should characterwise or line and character
      'character'
