{Operator}   = require './operators/index'
{Repeat}    = require './prefixes'
{Motion}     = require './motions/index'
{TextObject} = require './text-objects'

module.exports =
  isOperator: ->
    this instanceof Operators.Operator

  isTextObject: ->
    this instanceof TextObjects.TextObject

  isMotion: ->
    this instanceof Motions.Motion

  isRepeat: ->
    this instanceof Prefixes.Repeat
