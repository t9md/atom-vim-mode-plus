{Emitter, Disposable} = require 'atom'

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

  handleCapture: (event) =>
    event.stopImmediatePropagation()
    isCharacterKey = not (event.ctrlKey or event.metaKey)
    if isCharacterKey
      if event.key.length is 1
        @confirm(event.key)
    else
      @cancel()

  focus: (@options={}) ->
    # console.log "FOCUSED?"
    @finished = false
    @vimState.addToClassList('hidden-input-focused')
    @editorElement.addEventListener('keydown', @handleCapture, true)
    disposable = atom.workspace.onDidChangeActivePaneItem =>
      disposable.dispose()
      @cancel() unless @finished

  confirm: (char) ->
    @emitter.emit('did-confirm', char)
    @unfocus()

  unfocus: ->
    return if @finished
    @finished = true
    @editorElement.removeEventListener('keydown', @handleCapture, true)
    @emitter.emit('did-unfocus')

  cancel: ->
    @emitter.emit('did-cancel')
    @unfocus()
