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

  flash: (editor, marker, klass, duration=300) ->
    decoration = editor.decorateMarker marker,
      type: 'highlight'
      class: klass
    setTimeout  =>
      decoration.getMarker().destroy()
    , duration
