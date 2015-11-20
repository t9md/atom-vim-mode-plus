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

  validateOptions: (options, validOptions, message) ->
    invalidOptions = _.without(_.keys(options), validOptions...)
    if invalidOptions.length
      throw new SpecError("#{message}: #{inspect(invalidOptions)}")

  setOptionsOrdered = [
    'text', 'cursor', 'cursorBuffer', 'addCursor', 'addCursors', 'register'
    'selectedBufferRange'
  ]
  set: (options) =>
    @validateOptions(options, setOptionsOrdered, 'Invalid set options')
    for name in setOptionsOrdered when options[name]?
      method = 'set' + _.capitalize(_.camelize(name))
      this[method](options[name])

  setText: (text) =>
    @editor.setText(text)

  setCursor: (point) =>
    @editor.setCursorScreenPosition(point)

  setCursorBuffer: (cursor) =>
    @editor.setCursorBufferPosition(cursor)

  setAddCursor: (point) =>
    @editor.addCursorAtBufferPosition(point)

  setAddCursors: (points) =>
    @setAddCursor(point) for point in points

  setRegister: (register) =>
    if _.isObject(register)
      for name, value of register
        @vimState.register.set(name, value)
    else
      @vimState.register.set '"', text: register

  setSelectedBufferRange: (range) =>
    @editor.setSelectedBufferRange(range)

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
    if mocked
      unmockPlatform(element)

  ensureOptionsOrdered = [
    'text', 'selectedText', 'selectedTextOrdered'
    'cursor', 'cursors', 'cursorBuffer'
    'register', 'numCursors', 'selectedScreenRange',
    'selectedBufferRange',
    'selectedBufferRangeOrdered',
    'selectedBufferRangeStartRow',
    'selectedBufferRangeEndRow',
    'selectionIsReversed',
    'scrollTop',
    'mode',
  ]
  ensure: (args...) =>
    switch args.length
      when 1 then [options] = args
      when 2 then [keystroke, options] = args
    @validateOptions(options, ensureOptionsOrdered, 'Invalid ensure option')
    # Input
    unless _.isEmpty(keystroke)
      @keystroke(keystroke, {element: @editorElement})

    for name in ensureOptionsOrdered when options[name]?
      method = 'ensure' + _.capitalize(_.camelize(name))
      this[method](options[name])

  ensureText: (text) ->
    expect(@editor.getText()).toEqual(text)

  ensureSelectedText: (text) ->
    selections = @editor.getSelections()
    texts = (s.getText() for s in selections)
    expect(texts).toEqual(toArray(text))

  ensureSelectedTextOrdered: (text) ->
    selections = @editor.getSelectionsOrderedByBufferPosition()
    texts = (s.getText() for s in selections)
    expect(texts).toEqual(toArray(text))

  ensureCursor: (cursor) ->
    cursor = if cursor instanceof Point or not _.isArray(cursor[0])
      [cursor]
    else
      cursor
    points = @editor.getCursorScreenPositions()
    expect(points).toEqual(toArray(cursor, cursor))

  ensureCursors: (cursors) ->
    points = @editor.getCursorScreenPositions()
    expect(points).toEqual(cursors)

  ensureCursorBuffer: (cursor) ->
    points = @editor.getCursorBufferPositions()
    expect(points).toEqual(toArray(cursor, cursor[0]))

  ensureRegister: (register) ->
    if _.isObject(register)
      for name, value of register
        reg = @vimState.register.get(name)
        for prop, _value of value
          expect(reg[prop]).toEqual(_value)
    else
      expect(@vimState.register.get('"').text).toBe register

  ensureNumCursors: (number) ->
    expect(@editor.getCursors()).toHaveLength number

  ensureSelectedScreenRange: (range) ->
    actual = @editor.getSelectedScreenRanges()
    expected = toArray(range, range[0][0])
    expect(actual).toEqual(expected)

  ensureSelectedBufferRange: (range) ->
    if (range instanceof Range) or
        (not (range[0] instanceof Range)) and (not _.isArray(range[0][0]))
      range = [range]
    actual = @editor.getSelectedBufferRanges()
    expect(actual).toEqual(range)

  ensureSelectedBufferRangeOrdered: (range) ->
    if (range instanceof Range) or
        (not (range[0] instanceof Range)) and (not _.isArray(range[0][0]))
      range = [range]
    actual = @editor.getSelectionsOrderedByBufferPosition().map (e) -> e.getBufferRange()
    expect(actual).toEqual(range)

  ensureSelectedBufferRangeStartRow: (row) ->
    {start} = @editor.getSelectedBufferRange()
    expect(start.row).toEqual row

  ensureSelectedBufferRangeEndRow: (row) ->
    {end} = @editor.getSelectedBufferRange()
    expect(end.row).toEqual row

  ensureSelectionIsReversed: (reversed) ->
    actual = @editor.getLastSelection().isReversed()
    expect(actual).toBe(reversed)

  ensureScrollTop: (scrollTop) ->
    actual = @editorElement.getScrollTop()
    expect(actual).toEqual scrollTop

  ensureMode: (mode) ->
    mode = toArray(mode)
    expect(@vimState.isMode(mode...)).toBe(true)

    mode[0] = "#{mode[0]}-mode"
    mode = mode.filter((m) -> m)
    expect(@editorElement.classList.contains('vim-mode-plus')).toBe(true)
    for m in mode
      expect(@editorElement.classList.contains(m)).toBe(true)
    shouldNotContainClasses = _.difference(supportedModeClass, mode)
    for m in shouldNotContainClasses
      expect(@editorElement.classList.contains(m)).toBe(false)

dispatch = (target, command) ->
  atom.commands.dispatch(target, command)

module.exports = {getVimState, getView, dispatch}
