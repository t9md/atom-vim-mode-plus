# Refactoring status: 100%
fs = require 'fs-plus'
settings = require './settings'

module.exports =
  # Include module(object which normaly provides set of methods) to klass
  include: (klass, module) ->
    for key, value of module
      klass::[key] = value

  debug: (msg) ->
    return unless settings.get('debug')
    msg += "\n"
    if settings.get('debugOutput') is 'console'
      console.log msg
    else
      filePath = fs.normalize("~/sample.log")
      fs.appendFileSync filePath, msg

  selectLines: (selection, option) ->
    {editor} = selection
    [startRow, endRow] = selection.getBufferRowRange()
    range = editor.bufferRangeForBufferRow(startRow, includeNewline: true)
    range = range.union(editor.bufferRangeForBufferRow(endRow, includeNewline: true))
    selection.setBufferRange(range, option)
