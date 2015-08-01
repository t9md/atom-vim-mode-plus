VimNormalModeInputElement = require './vim-normal-mode-input-element'

class ViewModel
  constructor: (@operation, opts={}) ->
    {@editor, @vimState} = @operation
    @view = new VimNormalModeInputElement().initialize(this, opts)
    @editor.normalModeInputView = @view
    @vimState.onDidFailToCompose => @view.remove()

  confirm: (view) ->
    @vimState.enqueueOperations(new Input(@view.value))

  cancel: (view) ->
    if @vimState.isOperatorPending()
      @vimState.enqueueOperations(new Input(''))

class Input
  constructor: (@characters) ->
  isComplete: -> true
  isRecordable: -> true

module.exports = {
  ViewModel, Input
}
