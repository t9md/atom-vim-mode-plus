{ViewModel} = require './view'
_ = require 'underscore-plus'
Base = require './base'

class InsertMode extends Base
  @extend()
  complete: false
  recodable: false

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState

  # Proxying request to ViewModel to get Input instance.
  getInput: (args...) ->
    viewModel = new ViewModel(args...)
    viewModel.onDidGetInput (@input) =>
      @complete = true
      @vimState.operationStack.process() # Re-process!!

class InsertRegister extends InsertMode
  @extend()

  constructor: ->
    super
    @getInput(this, class: 'insert-register', singleChar: true, hidden: true)

  execute: ->
    name = @input
    text = @vimState.register.get(name)?.text
    @editor.insertText(text) if text?

class CopyFromLineAbove extends InsertMode
  @extend()
  complete: true

  getRow: (row) ->
    row - 1

  getTextInScreenRange: (range) ->
    @editor.getTextInBufferRange(@editor.bufferRangeForScreenRange(range))

  execute: ->
    @editor.transact =>
      for cursor in @editor.getCursors()
        {row, column} = cursor.getScreenPosition()
        row = @getRow(row)
        continue if row < 0
        range = [[row, column], [row, column+1]]
        cursor.selection.insertText @getTextInScreenRange(range)

class CopyFromLineBelow extends CopyFromLineAbove
  @extend()

  getRow: (row) ->
    row + 1

module.exports = {
  CopyFromLineAbove,
  CopyFromLineBelow
  InsertRegister
}
