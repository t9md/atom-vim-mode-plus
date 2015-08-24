# Refactoring status: 50%
VimState = require '../lib/vim-state'
GlobalVimState = require '../lib/global-vim-state'
VimMode  = require '../lib/vim-mode'
StatusBarManager = require '../lib/status-bar-manager'
_ = require 'underscore-plus'

[globalVimState, statusBarManager] = []

# [FIXME] maybe can remove.
beforeEach ->
  atom.workspace ?= {}
  statusBarManager = null
  globalVimState = null

EDITOR = null
EDITOR_ELEMENT = null

getEditorElement = (callback) ->
  editor = null

  waitsForPromise ->
    atom.project.open().then (e) ->
      editor = e

  runs ->
    editorElement = document.createElement("atom-text-editor")
    editorElement.setModel(editor)
    editorElement.classList.add('vim-mode')
    statusBarManager ?= new StatusBarManager
    globalVimState ?= new GlobalVimState
    editorElement.vimState = new VimState(editorElement, statusBarManager, globalVimState)

    editorElement.addEventListener "keydown", (e) ->
      atom.keymaps.handleKeyboardEvent(e)

    init = ->
      EDITOR = editor
      EDITOR_ELEMENT = editorElement
    callback(editorElement, init)

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

keystroke = (keys) ->
  if keys is 'escape'
    keydown(keys, element: EDITOR_ELEMENT)
    return

  for key in keys.split('')
    if key.match(/[A-Z]/)
      keydown(key, shift: true, element: EDITOR_ELEMENT)
    else
      keydown(key, element: EDITOR_ELEMENT)

normalModeInputKeydown = (key, options={}) ->
  theEditor = options.editor ? EDITOR
  theEditor.normalModeInputView.editorElement.getModel().setText(key)

submitNormalModeInputText = (text) ->
  inputEditor = EDITOR.normalModeInputView.editorElement
  inputEditor.getModel().setText(text)
  atom.commands.dispatch(inputEditor, 'core:confirm')

set = (options={}) ->
  if options.text?
    EDITOR.setText(options.text)
  if options.cursor?
    EDITOR.setCursorScreenPosition options.cursor
  if options.cursorBuffer?
    EDITOR.setCursorBufferPosition options.cursorBuffer
  if options.addCursor?
    EDITOR.addCursorAtBufferPosition options.addCursor
  if options.register?
    EDITOR_ELEMENT.vimState.register.set '"', text: options.register
  if options.selectedBufferRange?
    EDITOR.setSelectedBufferRange options.selectedBufferRange
  if options.selectedBufferRanges?
    EDITOR.setSelectedBufferRanges options.selectedBufferRanges
  if options.spy?
    if _.isArray(options.spy)
      for s in options.spy
        spyOn(s.obj, s.method).andReturn(s.return)
    else
      spyOn(options.spy.obj, options.spy.method).andReturn(options.spy.return)
  if options.keystroke?
    keystroke(options.keystroke)

ensure = (_keystroke, options={}) ->
  # input
  unless _.isEmpty(_keystroke)
    if _.isArray(_keystroke)
      for k in _keystroke
        if _.isString(k)
          keystroke(k)
        else
          if k.platform?
            mockPlatform(EDITOR_ELEMENT, k.platform)
          else if k.char?
            normalModeInputKeydown k.char
          else if k.chars?
            submitNormalModeInputText k.chars
          else if k.ctrl?
            keydown k.ctrl, ctrl: true, element: EDITOR_ELEMENT
          else if k.cmd?
            atom.commands.dispatch(k.cmd.target, k.cmd.name)
      if k.platform?
        unmockPlatform(EDITOR_ELEMENT)
    else
      keystroke(_keystroke)

  # validate
  # [NOTE] Order is important.
  # e.g. Text need to be set before changing cursor position.
  if options.text?
    if options.text.editor?
      expect(options.text.editor.getText()).toEqual(options.text.value)
    else
      expect(EDITOR.getText()).toEqual(options.text)
  if options.selectedText?
    if _.isArray(options.selectedText)
      texts = (s.getText() for s in EDITOR.getSelections())
      expect(texts).toEqual options.selectedText
    else
      expect(EDITOR.getSelectedText()).toEqual options.selectedText
  if options.cursor?
    expect(EDITOR.getCursorScreenPosition()).toEqual options.cursor
  if options.cursorBuffer?
    if _.isArray(options.cursorBuffer[0])
      expect(EDITOR.getCursorBufferPositions()).toEqual options.cursorBuffer
    else
      expect(EDITOR.getCursorBufferPosition()).toEqual options.cursorBuffer
  if options.register?
    expect(EDITOR_ELEMENT.vimState.register.get('"').text).toBe options.register
  if options.numCursors?
    expect(EDITOR.getCursors().length).toBe options.numCursors

  if options.selectedScreenRange?
    expect(EDITOR.getSelectedScreenRange()).toEqual options.selectedScreenRange
  if options.selectedScreenRanges?
    expect(EDITOR.getSelectedScreenRanges()).toEqual options.selectedScreenRanges
  if options.selectedBufferRange?
    expect(EDITOR.getSelectedBufferRange()).toEqual options.selectedBufferRange
  if options.selectedBufferRanges?
    expect(EDITOR.getSelectedBufferRanges()).toEqual options.selectedBufferRanges

  if options.selectedBufferRangeStartRow?
    {start} = EDITOR.getSelectedBufferRange()
    expect(start.row).toEqual options.selectedBufferRangeStartRow
  if options.selectedBufferRangeEndRow?
    {end} = EDITOR.getSelectedBufferRange()
    expect(end.row).toEqual options.selectedBufferRangeEndRow
  if options.selectionIsReversed?
    expect(EDITOR.getLastSelection().isReversed()).toBe(options.selectionIsReversed)

  if options.scrollTop?
    expect(EDITOR.getScrollTop()).toEqual options.scrollTop

  if options.called?
    if options.called.func
      expect(options.called.func).toHaveBeenCalledWith(options.called.with)
    else
      expect(options.called).toHaveBeenCalled()

  if options.mode?
    expect(EDITOR_ELEMENT.vimState.mode).toEqual options.mode
  if options.submode?
    expect(EDITOR_ELEMENT.vimState.submode).toEqual options.submode

  if options.classListContains?
    if _.isArray(options.classListContains)
      for klass in options.classListContains
        expect(EDITOR_ELEMENT.classList.contains(klass)).toBe(true)
    else
      expect(EDITOR_ELEMENT.classList.contains(options.classListContains)).toBe(true)
  if options.classListNotContains?
    if _.isArray(options.classListNotContains)
      for klass in options.classListNotContains
        expect(EDITOR_ELEMENT.classList.contains(klass)).toBe(false)
    else
      expect(EDITOR_ELEMENT.classList.contains(options.classListNotContains)).toBe(false)

module.exports = {set, ensure, keydown, keystroke, getEditorElement, mockPlatform, unmockPlatform}
