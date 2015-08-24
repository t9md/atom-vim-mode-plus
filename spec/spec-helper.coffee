# Refactoring status: 0%
VimState = require '../lib/vim-state'
GlobalVimState = require '../lib/global-vim-state'
VimMode  = require '../lib/vim-mode'
StatusBarManager = require '../lib/status-bar-manager'

[globalVimState, statusBarManager] = []

# [FIXME] maybe can remove.
beforeEach ->
  atom.workspace ?= {}
  statusBarManager = null
  globalVimState = null

getEditorElement = (callback) ->
  textEditor = null

  waitsForPromise ->
    atom.project.open().then (e) ->
      textEditor = e

  runs ->
    element = document.createElement("atom-text-editor")
    element.setModel(textEditor)
    element.classList.add('vim-mode')
    statusBarManager ?= new StatusBarManager
    globalVimState ?= new GlobalVimState
    element.vimState = new VimState(element, statusBarManager, globalVimState)

    element.addEventListener "keydown", (e) ->
      atom.keymaps.handleKeyboardEvent(e)

    callback(element)

mockPlatform = (editorElement, platform) ->
  wrapper = document.createElement('div')
  wrapper.className = platform
  wrapper.appendChild(editorElement)

unmockPlatform = (editorElement) ->
  editorElement.parentNode.removeChild(editorElement)

dispatchKeyboardEvent = (target, eventArgs...) ->
  e = document.createEvent('KeyboardEvent')
  e.initKeyboardEvent(eventArgs...)
  # 0 is the default, and it's valid ASCII, but it's wrong.
  if e.keyCode is 0
    Object.defineProperty(e, 'keyCode', get: -> undefined)
  target.dispatchEvent e

dispatchTextEvent = (target, eventArgs...) ->
  e = document.createEvent('TextEvent')
  e.initTextEvent(eventArgs...)
  target.dispatchEvent e

keydown = (key, {element, ctrl, shift, alt, meta, raw}={}) ->
  unless key is 'escape' or raw?
    key = "U+#{key.charCodeAt(0).toString(16)}"
  element ?= document.activeElement
  eventArgs = [
    true, # bubbles
    true, # cancelable
    null, # view
    key,  # key
    0,    # location
    ctrl, alt, shift, meta
  ]

  canceled = not dispatchKeyboardEvent(element, 'keydown', eventArgs...)
  # [FIXME] I think I can remove keypress event dispatch.
  dispatchKeyboardEvent(element, 'keypress', eventArgs...)
  unless canceled
    if dispatchTextEvent(element, 'textInput', eventArgs...)
      element.value += key
  dispatchKeyboardEvent(element, 'keyup', eventArgs...)

module.exports = {keydown, getEditorElement, mockPlatform, unmockPlatform}
