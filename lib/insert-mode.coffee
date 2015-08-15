{ViewModel} = require './view'
_ = require 'underscore-plus'
Base = require './base'

class InsertMode extends Base
  @extend()
  complete: false
  recodable: false

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState

  # Proxying request to ViewModel to get input.
  getInput: (args...) ->
    viewModel = new ViewModel(args...)
    viewModel.onDidGetInput (@input) =>
      @complete = true
      # Now completed, so re-process me(this)!
      @vimState.operationStack.process()

class InsertRegister extends InsertMode
  @extend()

  constructor: ->
    super
    @getInput this,
      class: 'insert-register'
      singleChar: true
      hidden: true

  execute: ->
    if text = @vimState.register.get(@input)?.text
      @editor.insertText(text)

class CopyFromLineAbove extends InsertMode
  @extend()
  complete: true
  rowTransration: -1

  getTextInScreenRange: (range) ->
    @editor.getTextInBufferRange(@editor.bufferRangeForScreenRange(range))

  execute: ->
    @editor.transact =>
      for cursor in @editor.getCursors()
        {row, column} = cursor.getScreenPosition()
        row += @rowTransration
        continue if row < 0 # No line to copy from.
        range = [[row, column], [row, column+1]]
        cursor.selection.insertText @getTextInScreenRange(range)

class CopyFromLineBelow extends CopyFromLineAbove
  @extend()
  rowTransration: +1

module.exports = {
  CopyFromLineAbove,
  CopyFromLineBelow
  InsertRegister
}
