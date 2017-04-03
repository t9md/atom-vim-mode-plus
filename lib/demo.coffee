{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'
Base = require './base'

MaxKeystrokeToShows = 5
module.exports =
class Demo
  constructor: (@vimState, options={}) ->
    {@autoHide} = options
    @maxKeystrokes = @vimState.getConfig('demoMaxKeystrokeToShow')
    {@editor, @editorElement} = @vimState
    @showKeystrokeDisposable = null
    @disposables = new CompositeDisposable
    @point = @editor.getCursorBufferPosition()
    @disposables.add atom.keymaps.onDidMatchBinding (event) =>
      return unless atom.workspace.getActiveTextEditor() is @editor
      @add(event.binding)
    @disposables.add @editorElement.onDidChangeScrollTop =>
      @marker?.destroy()
      if container = @getContainer()
        @render(container)

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

  getContainer: ->
    if @container?
      @container
    else
      @container = document.createElement('div')
      @container.className = 'vim-mode-plus-demo'
      @container

  render: (item) ->
    @marker?.destroy()
    screenRow = @editorElement.getFirstVisibleScreenRow()
    point = @editor.bufferPositionForScreenPosition([screenRow, 0])
    @marker = @editor.markBufferPosition(point, invalidate: 'never')
    @editor.decorateMarker(@marker, {type: 'overlay', item: item})

  add: ({keystrokes, command}) ->
    return if command in ['vim-mode-plus:demo-toggle', 'vim-mode-plus:demo-toggle-auto-hide']

    if @autoHide
      @hideAfter(@vimState.getConfig('demoAutoHideTimeout'))

    kind = @getKindForCommand(command)
    container = @getContainer()
    element = @elementForKeystroke({keystrokes, command, kind})
    container.appendChild(element)
    if container.childElementCount > @maxKeystrokes
      container.firstElementChild.remove()
    @render(container) unless @marker?

   hideAfter: (timeout) ->
     clearTimeout(@autoHideTimeoutID) if @autoHideTimeoutID?
     hideCallback = =>
       @autoHideTimeoutID = null
       @container?.remove()
       @marker?.destroy()
       @marker = null
       @container = null
     @autoHideTimeoutID = setTimeout(hideCallback, timeout)

  destroy: ->
    @disposables.dispose()
    @marker?.destroy()
    @container?.remove()
