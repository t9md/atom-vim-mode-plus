Input = require './input'

REGISTERS = /// (
  ?: [a-zA-Z*+%_".]
) ///

# TODO: Vim support following registers.
# x: complete, -: partially
#  [x] 1. The unnamed register ""
#  [ ] 2. 10 numbered registers "0 to "9
#  [ ] 3. The small delete register "-
#  [x] 4. 26 named registers "a to "z or "A to "Z
#  [-] 5. three read-only registers ":, "., "%
#  [ ] 6. alternate buffer register "#
#  [ ] 7. the expression register "=
#  [ ] 8. The selection and drop registers "*, "+ and "~
#  [x] 9. The black hole register "_
#  [ ] 10. Last search pattern register "/

module.exports =
class RegisterManager
  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    @data = @vimState.globalState.get('register')
    @subscriptionBySelection = new Map
    @clipboardBySelection = new Map

    @vimState.onDidDestroy(@destroy)

  reset: ->
    @name = null
    @editorElement.classList.toggle('with-register', false)

  destroy: =>
    @subscriptionBySelection.forEach (disposable) ->
      disposable.dispose()
    @subscriptionBySelection.clear()
    @clipboardBySelection.clear()
    {@subscriptionBySelection, @clipboardBySelection} = {}

  isValidName: (name) ->
    REGISTERS.test(name)

  getText: (name, selection) ->
    @get(name, selection)?.text ? ''

  readClipboard: (selection=null) ->
    if selection?.editor.hasMultipleCursors() and @clipboardBySelection.has(selection)
      @clipboardBySelection.get(selection)
    else
      atom.clipboard.read()

  writeClipboard: (selection=null, text) ->
    if selection?.editor.hasMultipleCursors() and not @clipboardBySelection.has(selection)
      disposable = selection.onDidDestroy =>
        @subscriptionBySelection.delete(selection)
        @clipboardBySelection.delete(selection)
      @subscriptionBySelection.set(selection, disposable)

    if (selection is null) or selection.isLastSelection()
      atom.clipboard.write(text)
    @clipboardBySelection.set(selection, text) if selection?

  getRegisterNameToUse: (name) ->
    if name? and not @isValidName(name)
      return null

    name ?= @name ? '"'
    if name is '"' and @vimState.getConfig('useClipboardAsDefaultRegister')
      '*'
    else
      name

  get: (name, selection) ->
    name = @getRegisterNameToUse(name)
    return unless name?

    switch name
      when '*', '+' then text = @readClipboard(selection)
      when '%' then text = @editor.getURI()
      when '_' then text = '' # Blackhole always returns nothing
      else
        {text, type} = @data[name.toLowerCase()] ? {}
    type ?= @getCopyType(text ? '')
    {text, type}

  # Private: Sets the value of a given register.
  #
  # name  - The name of the register to fetch.
  # value - The value to set the register to, with following properties.
  #  text: text to save to register.
  #  type: (optional) if ommited automatically set from text.
  #
  # Returns nothing.
  set: (name, value) ->
    name = @getRegisterNameToUse(name)
    return unless name?

    value.type ?= @getCopyType(value.text)

    selection = value.selection
    delete value.selection

    switch name
      when '*', '+' then @writeClipboard(selection, value.text)
      when '_', '%' then null
      else
        if /^[A-Z]$/.test(name)
          name = name.toLowerCase()
          if @data[name]?
            @append(name, value)
          else
            @data[name] = value
        else
          @data[name] = value

  append: (name, value) ->
    register = @data[name]
    if 'linewise' in [register.type, value.type]
      if register.type isnt 'linewise'
        register.type = 'linewise'
        register.text += '\n'
      if value.type isnt 'linewise'
        value.text += '\n'
    register.text += value.text

  setName: (name) ->
    if name?
      @name = name
      @editorElement.classList.toggle('with-register', true)
      @vimState.hover.set('"' + @name)
    else
      inputUI = new Input(@vimState)
      inputUI.onDidConfirm (name) =>
        if @isValidName(name)
          @setName(name)
        else
          @vimState.hover.reset()
      inputUI.onDidCancel => @vimState.hover.reset()
      @vimState.hover.set('"')
      inputUI.focus(1)

  getCopyType: (text) ->
    if text.endsWith("\n") or text.endsWith("\r")
      'linewise'
    else
      'characterwise'
