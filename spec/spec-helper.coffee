# Refactoring status: 50%
VimState = require '../lib/vim-state'
GlobalVimState = require '../lib/global-vim-state'
VimMode  = require '../lib/vim-mode'
StatusBarManager = require '../lib/status-bar-manager'
_ = require 'underscore-plus'

[globalVimState, statusBarManager] = []

beforeEach ->
  atom.workspace ?= {}
  statusBarManager = null
  globalVimState = null

E  = null # editor
EL = null # editorElement

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
      E = editor
      EL = editorElement
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

keystroke = (keys, {element}={}) ->
  # keys must be String or Array
  # Not support Object for keys intentionally to avoid ambiguity.
  element ?= EL
  editor = element.getModel()
  mocked = null
  if _.isString(keys)
    _keystroke(keys, {element})
    return

  unless _.isArray(keys)
    throw "Must not happen"

  for k in keys
    if _.isString(k)
      _keystroke(k, {element})
    else
      if k.platform?
        mockPlatform(element, k.platform)
        mocked = true
      else if k.char?  then normalModeInputKeydown k.char, {editor}
      else if k.chars? then submitNormalModeInputText k.chars
      else if k.ctrl? then keydown k.ctrl, {ctrl: true, element}
      else if k.cmd? then atom.commands.dispatch(k.cmd.target, k.cmd.name)
  if mocked
    unmockPlatform(EL)

_keystroke = (keys, {element}) ->
  if keys is 'escape'
    keydown keys, {element}
    return
  for key in keys.split('')
    if key.match(/[A-Z]/)
      keydown key, {shift: true, element}
    else
      keydown key, {element}

normalModeInputKeydown = (key, options={}) ->
  theEditor = options.editor ? E
  theEditor.normalModeInputView.editorElement.getModel().setText(key)

submitNormalModeInputText = (text) ->
  inputEditor = E.normalModeInputView.editorElement
  inputEditor.getModel().setText(text)
  atom.commands.dispatch(inputEditor, 'core:confirm')

toArray = (obj, cond=null) ->
  if _.isArray(cond ? obj)
    obj
  else
    [obj]

set = (o={}) ->
  E.setText(o.text) if o.text?
  E.setCursorScreenPosition o.cursor if o.cursor?
  E.setCursorBufferPosition o.cursorBuffer if o.cursorBuffer?
  E.addCursorAtBufferPosition o.addCursor if o.addCursor?

  if o.register?
    if _.isObject(o.register)
      for name, value of o.register
        EL.vimState.register.set(name, value)
    else
      EL.vimState.register.set '"', text: o.register

  E.setSelectedBufferRange o.selectedBufferRange if o.selectedBufferRange?
  if o.spy?
    # e.g.
    # spyOn(editor, 'getURI').andReturn('/Users/atom/known_value.txt')
    for s in toArray(o.spy)
      spyOn(s.obj, s.method).andReturn(s.return)
  keystroke(o.keystroke) if o.keystroke?

# ensure = (_keystroke, o={}) ->
ensure = (args...) ->
  [keys, o] = []
  switch args.length
    when 1 then [o] = args
    when 2 then [keys, o] = args

  # Input
  keystroke(keys) unless _.isEmpty(keys)

  # Validate
  # [NOTE] Order is important.
  # e.g. Text need to be set before changing cursor position.
  if o.text?
    if o.text.editor?
      expect(o.text.editor.getText()).toEqual(o.text.value)
    else
      expect(E.getText()).toEqual(o.text)

  if o.selectedText?
    expect(s.getText() for s in E.getSelections()).toEqual(
      toArray(o.selectedText))

  if o.cursor?
    expect(E.getCursorScreenPosition()).toEqual(o.cursor)

  if o.cursorBuffer?
    expect(E.getCursorBufferPositions()).toEqual(
      toArray(o.cursorBuffer, o.cursorBuffer[0]))

  if o.register?
    if _.isObject(o.register)
      for name, value of o.register
        reg = EL.vimState.register.get(name)
        for prop, _value of value
          expect(reg[prop]).toEqual(_value)
    else
      expect(EL.vimState.register.get('"').text).toBe o.register

  if o.numCursors?
    expect(E.getCursors().length).toBe o.numCursors

  if o.selectedScreenRange?
    expect(E.getSelectedScreenRanges()).toEqual(
      toArray(o.selectedScreenRange, o.selectedScreenRange[0][0]))

  if o.selectedBufferRange?
    expect(E.getSelectedBufferRanges()).toEqual(
      toArray(o.selectedBufferRange, o.selectedBufferRange[0][0]))

  if o.selectedBufferRangeStartRow?
    {start} = E.getSelectedBufferRange()
    expect(start.row).toEqual o.selectedBufferRangeStartRow
  if o.selectedBufferRangeEndRow?
    {end} = E.getSelectedBufferRange()
    expect(end.row).toEqual o.selectedBufferRangeEndRow
  if o.selectionIsReversed?
    expect(E.getLastSelection().isReversed()).toBe(o.selectionIsReversed)

  if o.scrollTop?
    expect(E.getScrollTop()).toEqual o.scrollTop

  if o.called?
    if o.called.func
      expect(o.called.func).toHaveBeenCalledWith(o.called.with)
    else
      expect(o.called).toHaveBeenCalled()

  if o.mode?
    expect(EL.vimState.mode).toEqual o.mode
  if o.submode?
    expect(EL.vimState.submode).toEqual o.submode

  if o.classListContains?
    for klass in toArray(o.classListContains)
      expect(EL.classList.contains(klass)).toBe(true)
  if o.classListNotContains?
    for klass in toArray(o.classListNotContains)
      expect(EL.classList.contains(klass)).toBe(false)

module.exports = {
  set, ensure,
  keydown, keystroke,
  getEditorElement,
  normalModeInputKeydown
  submitNormalModeInputText
  mockPlatform, unmockPlatform
}
