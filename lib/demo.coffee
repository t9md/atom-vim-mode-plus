{CompositeDisposable, Disposable} = require 'atom'
_ = require 'underscore-plus'
Base = require './base'

DemoCommands = [
  'vim-mode-plus:demo-toggle'
  'vim-mode-plus:demo-toggle-with-auto-hide'
  'vim-mode-plus:demo-stop-or-start-auto-hide'
  'vim-mode-plus:demo-clear'
  'vim-mode-plus:demo-move-hover-up'
  'vim-mode-plus:demo-move-hover-down'
  'vim-mode-plus:demo-move-hover-right'
  'vim-mode-plus:demo-move-hover-left'
]
module.exports =
class Demo
  constructor: (@vimState, options={}) ->
    {@editor, @editorElement, @globalState} = @vimState
    {@autoHide} = options
    @maxKeystrokesToShow = @vimState.getConfig('demoMaxKeystrokeToShow')
    @disposables = new CompositeDisposable

    @editorElement.classList.add('demo')
    @disposables.add new Disposable => @editorElement.classList.remove('demo')

    @disposables.add atom.keymaps.onDidMatchBinding (event) =>
      return unless atom.workspace.getActiveTextEditor() is @editor
      return if event.binding.command in DemoCommands
      @add(event)

    @disposables.add @editorElement.onDidChangeScrollTop =>
      @refresh() if @container?
    @updateStyle()

    @disposables.add @globalState.onDidChange ({name, newValue}) =>
      if name in ['demoMarginTopInEm', 'demoMarginLeftInEm']
        @updateStyle()

  updateStyle: ->
    @styleElement?.remove()
    @styleElement = document.createElement 'style'
    document.head.appendChild(@styleElement)
    top = @globalState.get('demoMarginTopInEm')
    left = @globalState.get('demoMarginLeftInEm')

    @styleElement.sheet.addRule '.vim-mode-plus-demo', """
      margin-top: #{top}em;
      margin-left: #{left}em;
      """
  elementForKeystroke: ({command, keystrokes}) ->
    commandShort = command.replace(/^vim-mode-plus:/, '')
    element = document.createElement('div')
    keystrokes = keystrokes.split(' ')
      .map (keystroke) -> keystroke.replace(/^shift-/, '')
      .join(' ')
    element.className = 'binding'
    kind = @getKindForCommand(command)
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

  refresh: ->
    @marker?.destroy()
    screenRow = @editorElement.getFirstVisibleScreenRow()
    point = @editor.bufferPositionForScreenPosition([screenRow, 0])
    @marker = @editor.markBufferPosition(point, invalidate: 'never')
    @editor.decorateMarker(@marker, {type: 'overlay', item: @getContainer()})

  add: (event) ->
    if @autoHide
      @hideAfter(@vimState.getConfig('demoAutoHideTimeout'))

    container = @getContainer()
    container.appendChild(@elementForKeystroke(event.binding))
    if container.childElementCount > @maxKeystrokesToShow
      container.firstElementChild.remove()
    @refresh() unless @marker?

  hideAfter: (timeout) ->
    clearTimeout(@autoHideTimeoutID) if @autoHideTimeoutID?
    hideCallback = =>
      @autoHideTimeoutID = null
      @container?.remove()
      @marker?.destroy()
      @marker = null
      @container = null
    @autoHideTimeoutID = setTimeout(hideCallback, timeout)

  stopOrStartAutoHide: ->
    if @autoHide
      # Stop scheduled auto hide task to keep it display.
      clearTimeout(@autoHideTimeoutID) if @autoHideTimeoutID?
      @autoHide = false
    else
      @clear()
      @autoHide = true

  clear: ->
    clearTimeout(@autoHideTimeoutID) if @autoHideTimeoutID?
    @container?.remove()
    @marker?.destroy()
    @marker = null
    @container = null

  destroy: ->
    @disposables.dispose()
    @styleElement?.remove()
    @marker?.destroy()
    @container?.remove()

  moveHover: (direction) ->
    return unless @container?

    setValue = (param, delta) =>
      @globalState.set(param, @globalState.get(param) + delta)

    switch direction
      when 'up' then setValue('demoMarginTopInEm', -1)
      when 'down' then setValue('demoMarginTopInEm', +1)
      when 'left' then setValue('demoMarginLeftInEm', -1)
      when 'right' then setValue('demoMarginLeftInEm', +1)
