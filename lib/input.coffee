{Emitter, CompositeDisposable} = require 'atom'

module.exports =
class Input
  onDidChange: (fn) -> @emitter.on 'did-change', fn
  onDidConfirm: (fn) -> @emitter.on 'did-confirm', fn
  onDidCancel: (fn) -> @emitter.on 'did-cancel', fn

  constructor: (@vimState) ->
    {@editorElement} = @vimState
    @vimState.onDidFailToPushToOperationStack =>
      @cancel()
    @emitter = new Emitter

  destroy: ->
    {@vimState} = {}

  focus: (options={}) ->
    {charsMax, hideCursor} = options
    charsMax ?= 1
    chars = []

    @disposables = new CompositeDisposable()
    classNames = ["vim-mode-plus-input-char-waiting",  "is-focused"]
    classNames.push('hide-cursor') if hideCursor
    @disposables.add @vimState.swapClassName(classNames...)
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
    @disposables?.dispose()
    @emitter.emit('did-confirm', char)

  cancel: ->
    @disposables?.dispose()
    @emitter.emit('did-cancel')
