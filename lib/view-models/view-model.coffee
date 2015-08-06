Base = require '../base'
VimNormalModeInputElement = require './vim-normal-mode-input-element'

class ViewModel
  constructor: (@operation, opts={}) ->
    {@editor, @vimState} = @operation
    @view = new VimNormalModeInputElement().initialize(this, opts)
    @editor.normalModeInputView = @view
    @vimState.onDidFailToCompose => @view.remove()

  confirm: (view) ->
    @vimState.operationStack.push(new Input(@view.value))

  cancel: (view) ->
    if @vimState.isOperatorPending()
      @vimState.operationStack.push(new Input(''))

class Input extends Base
  @extend()
  constructor: (@characters) ->
  isComplete: -> true
  isRecordable: -> true

module.exports = {
  ViewModel, Input
}
