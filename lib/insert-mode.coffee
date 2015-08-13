{ViewModel, Input, SearchViewModel} = require './view'
_ = require 'underscore-plus'
Base = require './base'

class InsertMode extends Base
  @extend()
  complete: true
  recodable: false

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState

  # Proxying request to ViewModel to get Input instance.
  getInput: (args...) ->
    new ViewModel(args...)

  # Callbacked by @getInput()
  setInput: (@input) ->
    @complete = true

class InsertRegister extends InsertMode
  @extend()
  complete: false

  constructor: ->
    super
    @getInput(this, class: 'insert-register', singleChar: true, hidden: true)

  execute: ->
    name = @input.characters
    console.log name
    text = @vimState.register.get(name)?.text
    @editor.insertText(text) if text?

copyCharacterFromAbove = (editor, vimState) ->
  editor.transact ->
    for cursor in editor.getCursors()
      {row, column} = cursor.getScreenPosition()
      continue if row is 0
      range = [[row-1, column], [row-1, column+1]]
      cursor.selection.insertText(editor.getTextInBufferRange(editor.bufferRangeForScreenRange(range)))

copyCharacterFromBelow = (editor, vimState) ->
  editor.transact ->
    for cursor in editor.getCursors()
      {row, column} = cursor.getScreenPosition()
      range = [[row+1, column], [row+1, column+1]]
      cursor.selection.insertText(editor.getTextInBufferRange(editor.bufferRangeForScreenRange(range)))

module.exports = {
  copyCharacterFromAbove,
  copyCharacterFromBelow
  InsertRegister
}
