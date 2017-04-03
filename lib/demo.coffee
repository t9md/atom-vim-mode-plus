{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'
Base = require './base'

MaxKeystrokeToShows = 5
AutoHideTimeout = 2000
module.exports =
class Demo
  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    @showKeystrokeDisposable = null
    @disposables = new CompositeDisposable
    @point = @editor.getCursorBufferPosition()
    @disposables.add atom.keymaps.onDidMatchBinding (event) =>
      return unless atom.workspace.getActiveTextEditor() is @editor
      @add(event.binding)

  elementForKeystroke: ({command, keystrokes, kind}) ->
    commandShort = command.replace(/^vim-mode-plus:/, '')
    element = document.createElement('div')
    keystrokes = keystrokes.split(' ')
      .map (keystroke) -> keystroke.replace(/^shift-/, '')
      .join(' ')
    element.className = 'binding'
    element.innerHTML = """
      <span class='keystroke'>#{keystrokes}</span>
      <span class='commmaand'>#{commandShort}</span>
      <span class='kind pull-right'>#{kind}</span>
      """
    element

  getKindForCommand: (command) ->
    if command.startsWith('vim-mode-plus')
      command = command.replace(/^vim-mode-plus:/, '')
      if command.startsWith('operator-modifier')
        kind = 'op-modifier'
      else
        Base.getKindForCommandName(command) ? 'vmp-other'
    else
      'non-vmp'

  add: ({keystrokes, command}) ->
    return if command in ['vim-mode-plus:demo-start', 'vim-mode-plus:demo-reset']

    unless @marker?
      screenRow = @editorElement.getFirstVisibleScreenRow()
      point = @editor.bufferPositionForScreenPosition([screenRow, 0])
      @container = document.createElement('div')
      @container.className = 'keystroke-hover'
      @marker = @editor.markBufferPosition(point, invalidate: 'never')
      @editor.decorateMarker(@marker, {type: 'overlay', item: @container})

    kind = @getKindForCommand(command)
    element = @elementForKeystroke({keystrokes, command, kind})
    if @container.childElementCount >= (MaxKeystrokeToShows - 1)
      @container.firstElementChild.remove()
    @container.appendChild(element)

   reset: ->
     @cancelReset()
     resetCallback = =>
       @resetTimeoutID = null
       @resetImmediate()
     @resetTimeoutID = setTimeout(resetCallback, AutoHideTimeout)

  cancelReset: ->
    clearTimeout(@resetTimeoutID) if @resetTimeoutID?

  resetImmediate: ->
    @cancelReset()
    @container?.remove()
    @marker?.destroy()
    @marker = null

  destroy: ->
    # console.log 'destroyed'
    @disposables.dispose()
    @marker?.destroy()
    @container?.remove()
