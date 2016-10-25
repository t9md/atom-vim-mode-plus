{Emitter, CompositeDisposable} = require 'atom'

module.exports =
class Input
  onDidChange: (fn) -> @emitter.on 'did-change', fn
  onDidConfirm: (fn) -> @emitter.on 'did-confirm', fn
  onDidCancel: (fn) -> @emitter.on 'did-cancel', fn
  onDidUnfocus: (fn) -> @emitter.on 'did-unfocus', fn
  onDidCommand: (fn) -> @emitter.on 'did-command', fn

  constructor: (@vimState) ->
    {@editorElement} = @vimState
    @vimState.onDidFailToSetTarget =>
      @cancel()
    @emitter = new Emitter

  destroy: ->
    {@vimState} = {}

  focus: (charsMax=1) ->
    chars = []

    @disposables = new CompositeDisposable()
    @disposables.add @vimState.swapClassName("vim-mode-plus-input-char-waiting is-focused")
    @disposables.add @vimState.onDidSetInputChar (char) =>
      if charsMax is 1
        @confirm(char)
      else
        chars.push(char)
        text = chars.join('')
        @emitter.emit('did-change', text)
        if chars.length >= charsMax
          @confirm(text)

    @disposables.add atom.commands.add @editorElement,
      'core:cancel': (event) =>
        event.stopImmediatePropagation()
        @cancel()
      'core:confirm': (event) =>
        event.stopImmediatePropagation()
        @confirm(chars.join(''))

  confirm: (char) ->
    @unfocus()
    @emitter.emit('did-confirm', char)

  unfocus: ->
    @disposables?.dispose()
    @emitter.emit('did-unfocus')

  cancel: ->
    @emitter.emit('did-cancel')
    @unfocus()
