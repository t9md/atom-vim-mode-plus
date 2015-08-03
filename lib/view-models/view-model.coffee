VimNormalModeInputElement = require './vim-normal-mode-input-element'

class ViewModel
  constructor: (@operation, opts={}) ->
    {@editor, @vimState} = @operation
    @view = new VimNormalModeInputElement().initialize(this, opts)
    @editor.normalModeInputView = @view
    @vimState.onDidFailToCompose => @view.remove()

  confirm: (view) ->
    @vimState.pushToOperationStack(new Input(@view.value))

  cancel: (view) ->
    if @vimState.isOperatorPending()
      @vimState.pushToOperationStack(new Input(''))

class Input
  constructor: (@characters) ->
  isComplete: -> true
  isRecordable: -> true

module.exports = {
  ViewModel, Input
}
