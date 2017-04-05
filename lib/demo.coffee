{CompositeDisposable, Disposable} = require 'atom'
_ = require 'underscore-plus'
Base = require './base'
globalState = require './global-state'
settings = require './settings'

DemoCommands = [
  'vim-mode-plus:demo-toggle'
  'vim-mode-plus:demo-toggle-with-auto-hide'
  'vim-mode-plus:demo-stop-or-start-auto-hide'
  'vim-mode-plus:demo-clear'
]

module.exports =
class Demo
  constructor: (options={}) ->
    @editor = atom.workspace.getActiveTextEditor()
    @editorElement = @editor.element
    @workspaceElement = atom.views.getView(atom.workspace)
    {@autoHide} = options
    @disposables = new CompositeDisposable
    @containerMounted = false

    globalState.set('demo', true)
    @editorElement.classList.add('demo')

    @disposables.add new Disposable =>
      globalState.set('demo', false)
      @editorElement.classList.remove('demo')

    @disposables.add atom.keymaps.onDidMatchBinding (event) =>
      return if event.binding.command in DemoCommands
      @add(event)

    @disposables.add globalState.onDidChange ({name, newValue}) =>
      if name in ['demoMarginTopInEm', 'demoMarginLeftInEm']
        @setMargin()

  setMargin: ->
    @styleElement?.remove()
    @styleElement = document.createElement 'style'
    document.head.appendChild(@styleElement)
    top = globalState.get('demoMarginTopInEm') ? settings.get('demoInitialMarginTopInEm')
    left = globalState.get('demoMarginLeftInEm') ? settings.get('demoInitialMarginLeftInEm')

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
      @container.tabIndex = -1
      @container.className = 'vim-mode-plus-demo'
      @container

  add: (event) ->
    if @autoHide
      @hideAfter(settings.get('demoAutoHideTimeout'))

    container = @getContainer()
    container.appendChild(@elementForKeystroke(event.binding))
    if container.childElementCount > settings.get('demoMaxKeystrokeToShow')
      container.firstElementChild.remove()
    @mountContainer() unless @containerMounted

  hideAfter: (timeout) ->
    clearTimeout(@autoHideTimeoutID) if @autoHideTimeoutID?
    hideCallback = =>
      @autoHideTimeoutID = null
      @unmountContainer()

    @autoHideTimeoutID = setTimeout(hideCallback, timeout)

  mountContainer: ->
    @setMargin()
    @workspaceElement.appendChild(@getContainer())
    @containerMounted = true

  unmountContainer: ->
    @container?.remove()
    @container = null
    @containerMounted = false

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
    @unmountContainer()

  destroy: ->
    @disposables.dispose()
    @styleElement?.remove()
    @container?.remove()

  moveHover: (direction) ->
    return unless @container?

    updateValue = (param, delta) ->
      globalState.set(param, globalState.get(param) + delta)

    switch direction
      when 'up' then updateValue('demoMarginTopInEm', -1)
      when 'down' then updateValue('demoMarginTopInEm', +1)
      when 'left' then updateValue('demoMarginLeftInEm', -1)
      when 'right' then updateValue('demoMarginLeftInEm', +1)
