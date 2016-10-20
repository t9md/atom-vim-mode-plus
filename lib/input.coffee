{Emitter, Disposable} = require 'atom'
{registerElement} = require './utils'

class Input extends HTMLElement
  onDidChange: (fn) -> @emitter.on 'did-change', fn
  onDidConfirm: (fn) -> @emitter.on 'did-confirm', fn
  onDidCancel: (fn) -> @emitter.on 'did-cancel', fn
  onDidUnfocus: (fn) -> @emitter.on 'did-unfocus', fn
  onDidCommand: (fn) -> @emitter.on 'did-command', fn

  createdCallback: ->
    @className = "vim-mode-plus-input"
    @buildElements()
    @editor = @editorElement.getModel()
    @editor.setMini(true)

    @emitter = new Emitter

    @editor.onDidChange =>
      return if @finished
      text = @editor.getText()
      @emitter.emit 'did-change', text
      if (charsMax = @options?.charsMax) and text.length >= @options.charsMax
        @confirm()
    @panel = atom.workspace.addBottomPanel(item: this, visible: false)
    this

  buildElements: ->
    @innerHTML = """
    <atom-text-editor mini class='editor vim-mode-plus-input'></atom-text-editor>
    """
    @editorElement = @firstElementChild

  initialize: (@vimState) ->
    @vimState.onDidFailToSetTarget =>
      @cancel()
    this

  destroy: ->
    @editor.destroy()
    @panel?.destroy()
    {@editor, @panel, @editorElement, @vimState} = {}
    @remove()

  handleEvents: ->
    atom.commands.add @editorElement,
      'core:confirm': => @confirm()
      'core:cancel': => @cancel()
      'blur': => @cancel() unless @finished
      'vim-mode-plus:input-cancel': => @cancel()

  focus: (@options={}) ->
    @finished = false
    @panel.show()
    @vimState.addToClassList('hidden-input-focused')
    @editorElement.focus()
    @commandSubscriptions = @handleEvents()

    # Cancel on tab switch
    disposable = atom.workspace.onDidChangeActivePaneItem =>
      disposable.dispose()
      @cancel() unless @finished

  unfocus: ->
    @commandSubscriptions?.dispose()
    @finished = true
    atom.workspace.getActivePane().activate()
    @editor.setText ''
    @panel?.hide()
    @emitter.emit('did-unfocus')

  isVisible: ->
    @panel?.isVisible()

  cancel: ->
    @emitter.emit('did-cancel')
    @unfocus()

  confirm: ->
    @emitter.emit('did-confirm', @editor.getText())
    @unfocus()

InputElement = registerElement 'vim-mode-plus-input',
  prototype: Input.prototype

module.exports = {
  InputElement
}
