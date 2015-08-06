fs = require 'fs-plus'
settings = require './settings'

debugEditor = null

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

  initDebugEditor: ->
    return debugEditor if debugEditor?
    filePath = fs.normalize("~/vim-mode-debug.log")
    atom.workspace.open(filePath, activatePane: false).then (editor) ->
      debugEditor = editor
    debugEditor

  debug: (msg) ->
    return unless settings.debug()
    if settings.debugTarget() is 'console'
      console.log msg
    else
      debugEditor.insertText(msg)

  debugClear: ->
    return unless settings.debug()
    if settings.debugTarget() is 'console'
      console.clear()
    else
      debugEditor.setText('')
