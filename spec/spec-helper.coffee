# Refactoring status: 70%
_ = require 'underscore-plus'
{Range, Point} = require 'atom'
{inspect} = require 'util'

supportedModeClass = [
  'normal-mode'
  'visual-mode'
  'insert-mode'
  'replace'
  'linewise'
  'blockwise'
  'characterwise'
]

packageName = 'vim-mode-plus'
class SpecError
  constructor: (@message) ->
    @name = 'SpecError'

getVimState = (args...) ->
  [editor, file, callback] = []
  switch args.length
    when 1 then [callback] = args
    when 2 then [file, callback] = args

  waitsForPromise ->
    atom.packages.activatePackage(packageName)

  waitsForPromise ->
    file = atom.project.resolvePath(file) if file
    atom.workspace.open(file).then (e) ->
      editor = e

  runs ->
    pack = atom.packages.getActivePackage(packageName)
    main = pack.mainModule
    vimState = main.getEditorState(editor)
    {editorElement} = vimState
    editorElement.addEventListener 'keydown', (e) ->
      atom.keymaps.handleKeyboardEvent(e)

    callback(vimState, new VimEditor(vimState))

getView = (model) ->
  atom.views.getView(model)

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
    false, # bubbles
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

_keystroke = (keys, {element}) ->
  if keys is 'escape'
    keydown keys, {element}
  else
    for key in keys.split('')
      event = {element}
      event.shift = true if key.match(/[A-Z]/)
      keydown key, event

toArray = (obj, cond=null) ->
  if _.isArray(cond ? obj) then obj else [obj]

class VimEditor
  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState

  validOptions = [
    'text', 'cursor', 'cursorBuffer', 'addCursor',
    'register', 'selectedBufferRange', 'spy'
  ]
  validateOptions: (options) ->
    invalidOptions = _.without(_.keys(options), validOptions...)
    if invalidOptions.length
      throw new SpecError("invalidOptions: #{inspect(invalidOptions)}")

  set: (options) =>
    @validateOptions(options)
    optionsOrdered = [
      'text', 'cursor', 'cursorBuffer', 'addCursor', 'register'
      'selectedBufferRange', 'spy'
    ]
    for name in optionsOrdered when options[name]?
      method = _.capitalize(_.camelize(name))
      this["set#{method}"](options[name])

  setText: (text) =>
    @editor.setText(text)

  setCursor: (cursor) =>
    @editor.setCursorScreenPosition(cursor)

  setCursorBuffer: (cursor) =>
    @editor.setCursorBufferPosition(cursor)

  setAddCursor: (cursors) =>
    for point in toArray(cursors, cursors[0])
      @editor.addCursorAtBufferPosition(point)

  setRegister: (register) =>
    if _.isObject(register)
      for name, value of register
        @vimState.register.set(name, value)
    else
      @vimState.register.set '"', text: register

  setSelectedBufferRange: (range) =>
    @editor.setSelectedBufferRange(range)

  setSpy: (spy) ->
    # e.g.
    # spyOn(editor, 'getURI').andReturn('/Users/atom/known_value.txt')
    for s in toArray(spy)
      spyOn(s.obj, s.method).andReturn(s.return)

  ensure: (args...) =>
    [keys, o] = []
    switch args.length
      when 1 then [o] = args
      when 2 then [keys, o] = args

    # Input
    unless _.isEmpty(keys)
      @keystroke(keys, {element: @editorElement})

    # Validate
    # [NOTE] Order is important.
    # e.g. Text need to be set before changing cursor position.
    if o.text?
      if o.text.editor?
        expect(o.text.editor.getText()).toEqual(o.text.value)
      else
        expect(@editor.getText()).toEqual(o.text)

    if o.selectedText?
      expect(s.getText() for s in @editor.getSelections()).toEqual(
        toArray(o.selectedText))

    if o.selectedTextOrdered?
      expect(s.getText() for s in @editor.getSelectionsOrderedByBufferPosition()).toEqual(
        toArray(o.selectedTextOrdered))

    if o.cursor?
      o.cursor = if o.cursor instanceof Point or not _.isArray(o.cursor[0])
        [o.cursor]
      else
        o.cursor
      expect(@editor.getCursorScreenPositions()).toEqual(
        toArray(o.cursor, o.cursor))

    if o.cursors?
      expect(@editor.getCursorScreenPositions()).toEqual(o.cursors)

    if o.cursorBuffer?
      expect(@editor.getCursorBufferPositions()).toEqual(
        toArray(o.cursorBuffer, o.cursorBuffer[0]))

    if o.register?
      if _.isObject(o.register)
        for name, value of o.register
          reg = @vimState.register.get(name)
          for prop, _value of value
            expect(reg[prop]).toEqual(_value)
      else
        expect(@vimState.register.get('"').text).toBe o.register

    if o.numCursors?
      expect(@editor.getCursors().length).toBe o.numCursors

    if o.selectedScreenRange?
      expect(@editor.getSelectedScreenRanges()).toEqual(
        toArray(o.selectedScreenRange, o.selectedScreenRange[0][0]))

    if o.selectedBufferRange?
      if (o.selectedBufferRange instanceof Range) or
          (not (o.selectedBufferRange[0] instanceof Range)) and (not _.isArray(o.selectedBufferRange[0][0]))
        o.selectedBufferRange = [o.selectedBufferRange]
      expect(@editor.getSelectedBufferRanges()).toEqual(o.selectedBufferRange)

    if o.selectedBufferRangeOrdered?
      if (o.selectedBufferRangeOrdered instanceof Range) or
          (not (o.selectedBufferRangeOrdered[0] instanceof Range)) and (not _.isArray(o.selectedBufferRangeOrdered[0][0]))
        o.selectedBufferRangeOrdered = [o.selectedBufferRangeOrdered]
      actual = @editor.getSelectionsOrderedByBufferPosition().map (e) -> e.getBufferRange()
      expect(actual).toEqual(o.selectedBufferRangeOrdered)

    if o.selectedBufferRangeStartRow?
      {start} = @editor.getSelectedBufferRange()
      expect(start.row).toEqual o.selectedBufferRangeStartRow

    if o.selectedBufferRangeEndRow?
      {end} = @editor.getSelectedBufferRange()
      expect(end.row).toEqual o.selectedBufferRangeEndRow

    if o.selectionIsReversed?
      expect(@editor.getLastSelection().isReversed()).toBe(o.selectionIsReversed)

    if o.scrollTop?
      expect(@editorElement.getScrollTop()).toEqual o.scrollTop

    if o.called?
      for c in toArray(o.called)
        if c.func
          expect(c.func).toHaveBeenCalledWith(c.with)
        else
          expect(c).toHaveBeenCalled()

    if o.mode?
      currentMode = toArray(o.mode)
      expect(@vimState.isMode(currentMode...)).toBe(true)

      currentMode[0] = "#{currentMode[0]}-mode"
      currentMode = currentMode.filter((m) -> m)
      expect(@editorElement.classList.contains('vim-mode-plus')).toBe(true)
      for m in currentMode
        expect(@editorElement.classList.contains(m)).toBe(true)
      shouldNotContainClasses = _.difference(supportedModeClass, currentMode)
      for m in shouldNotContainClasses
        expect(@editorElement.classList.contains(m)).toBe(false)

  keystroke: (keys, {element}={}) =>
    # keys must be String or Array
    # Not support Object for keys to avoid ambiguity.
    element ?= @editorElement
    mocked = null
    keys = [keys] unless _.isArray(keys)

    for k in keys
      if _.isString(k)
        _keystroke(k, {element})
      else
        switch
          when k.platform?
            mockPlatform(element, k.platform)
            mocked = true
          when k.char?
            chars =
              # [FIXME] Cause insertText('escape'), useless.
              if k.char in ['', 'escape']
                toArray(k.char)
              else
                k.char.split('')
            for c in chars
              @vimState.input.view.editor.insertText(c)
          when k.search?
            {editor, editorElement} = @vimState.search.view
            editor.insertText(k.search)
            atom.commands.dispatch(editorElement, 'core:confirm')
          when k.ctrl?  then keydown k.ctrl, {ctrl: true, element}
          when k.raw?   then keydown k.raw, {raw: true, element}
          when k.cmd?   then atom.commands.dispatch(k.cmd.target, k.cmd.name)
    if mocked
      unmockPlatform(element)

module.exports = {getVimState, getView}
