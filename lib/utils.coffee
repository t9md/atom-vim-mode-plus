fs = require 'fs-plus'
settings = require './settings'

module.exports =
  # Public: Determines if a string should be considered linewise or character
  #
  # text - The string to consider
  #
  # Returns 'linewise' if the string ends with a line return and 'character'
  #  otherwise.
  copyType: (text) ->
    if text.lastIndexOf("\n") is text.length - 1
      'linewise'
    else if text.lastIndexOf("\r") is text.length - 1
      'linewise'
    else
      'character'

  # Include module(object which normaly provides set of methods) to klass
  include: (klass, module) ->
    for key, value of module
      klass::[key] = value

  debug: (msg) ->
    return unless settings.debug()
    msg += "\n"
    if settings.debugOutput() is 'console'
      console.log msg
    else
      filePath = fs.normalize("~/sample.log")
      fs.appendFileSync filePath, msg

  getKeystrokeForEvent: (event) ->
    keyboardEvent = event.originalEvent?.originalEvent ? event.originalEvent
    atom.keymaps.keystrokeForKeyboardEvent(keyboardEvent)
