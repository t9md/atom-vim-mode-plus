_ = require 'underscore-plus'
{Range, Point, Disposable} = require 'atom'
{inspect} = require 'util'
swrap = require '../lib/selection-wrapper'

KeymapManager = atom.keymaps.constructor
{normalizeKeystrokes} = require(atom.config.resourcePath + "/node_modules/atom-keymap/lib/helpers")

supportedModeClass = [
  'normal-mode'
  'visual-mode'
  'insert-mode'
  'replace'
  'linewise'
  'blockwise'
  'characterwise'
]

class SpecError
  constructor: (@message) ->
    @name = 'SpecError'

# Utils
# -------------------------
getView = (model) ->
  atom.views.getView(model)

dispatch = (target, command) ->
  atom.commands.dispatch(target, command)

withMockPlatform = (target, platform, fn) ->
  wrapper = document.createElement('div')
  wrapper.className = platform
  wrapper.appendChild(target)
  fn()
  target.parentNode.removeChild(target)

buildKeydownEvent = (key, options) ->
  KeymapManager.buildKeydownEvent(key, options)

buildKeydownEventFromKeystroke = (keystroke, target) ->
  modifier = ['ctrl', 'alt', 'shift', 'cmd']
  parts = if keystroke is '-'
    ['-']
  else
    keystroke.split('-')

  options = {target}
  key = null
  for part in parts
    if part in modifier
      options[part] = true
    else
      key = part
  key = ' ' if key is 'space'
  buildKeydownEvent(key, options)

buildTextInputEvent = (key) ->
  eventArgs = [
    true # bubbles
    true # cancelable
    window # view
    key  # key char
  ]
  event = document.createEvent('TextEvent')
  event.initTextEvent("textInput", eventArgs...)
  event

getHiddenInputElementForEditor = (editor) ->
  editorElement = atom.views.getView(editor)
  editorElement.component.hiddenInputComponent.getDomNode()

# FIX orignal characterForKeyboardEvent(it can't handle 'space')
characterForKeyboardEvent = (event) ->
  unless event.ctrlKey or event.altKey or event.metaKey
    if key = atom.keymaps.keystrokeForKeyboardEvent(event)
      key = ' ' if key is 'space'
      key = key[key.length - 1] if key.startsWith('shift-')
      key if key.length is 1

# --[START] I want to use this in future
newKeydown = (key, target) ->
  target ?= document.activeElement
  event = buildKeydownEventFromKeystroke(key, target)
  atom.keymaps.handleKeyboardEvent(event)

  # unless event.defaultPrevented
  #   editor = atom.workspace.getActiveTextEditor()
  #   target = getHiddenInputElementForEditor(editor)
  #   char = ' ' if key is 'space'
  #   char ?= characterForKeyboardEvent(event)
  #   target.dispatchEvent(buildTextInputEvent(char)) if char?

newKeystroke = (keystrokes, target) ->
  for key in normalizeKeystrokes(keystrokes).split(/\s+/)
    newKeydown(key, target)
# --[END] I want to use this in future

keydown = (key, options) ->
  event = buildKeydownEvent(key, options)
  atom.keymaps.handleKeyboardEvent(event)

_keystroke = (keys, event) ->
  if keys in ['escape', 'backspace']
    keydown(keys, event)
  else
    for key in keys.split('')
      if key.match(/[A-Z]/)
        event.shift = true
      else
        delete event.shift
      keydown(key, event)

isPoint = (obj) ->
  if obj instanceof Point
    true
  else
    obj.length is 2 and _.isNumber(obj[0]) and _.isNumber(obj[1])

isRange = (obj) ->
  if obj instanceof Range
    true
  else
    _.all([
      _.isArray(obj),
      (obj.length is 2),
      isPoint(obj[0]),
      isPoint(obj[1])
    ])

toArray = (obj, cond=null) ->
  if _.isArray(cond ? obj) then obj else [obj]

toArrayOfPoint = (obj) ->
  if _.isArray(obj) and isPoint(obj[0])
    obj
  else
    [obj]

toArrayOfRange = (obj) ->
  if _.isArray(obj) and _.all(obj.map (e) -> isRange(e))
    obj
  else
    [obj]

# Main
# -------------------------
getVimState = (args...) ->
  [editor, file, callback] = []
  switch args.length
    when 1 then [callback] = args
    when 2 then [file, callback] = args

  waitsForPromise ->
    atom.packages.activatePackage('vim-mode-plus')

  waitsForPromise ->
    file = atom.project.resolvePath(file) if file
    atom.workspace.open(file).then (e) -> editor = e

  runs ->
    main = atom.packages.getActivePackage('vim-mode-plus').mainModule
    vimState = main.getEditorState(editor)
    callback(vimState, new VimEditor(vimState))

class TextData
  constructor: (@rawData) ->
    @lines = @rawData.split("\n")

  getLines: (lines, {chomp}={}) ->
    chomp ?= false
    text = (@lines[line] for line in lines).join("\n")
    if chomp
      text
    else
      text + "\n"

  getRaw: ->
    @rawData

class VimEditor
  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState

  validateOptions: (options, validOptions, message) ->
    invalidOptions = _.without(_.keys(options), validOptions...)
    if invalidOptions.length
      throw new SpecError("#{message}: #{inspect(invalidOptions)}")

  setOptionsOrdered = [
    'text',
    'text_',
    'grammar',
    'cursor', 'cursorBuffer',
    'addCursor', 'addCursorBuffer'
    'register',
    'selectedBufferRange'
  ]

  # Public
  set: (options) =>
    @validateOptions(options, setOptionsOrdered, 'Invalid set options')
    for name in setOptionsOrdered when options[name]?
      method = 'set' + _.capitalize(_.camelize(name))
      this[method](options[name])

  setText: (text) ->
    @editor.setText(text)

  setText_: (text) ->
    @setText(text.replace(/_/g, ' '))

  setGrammar: (scope) ->
    @editor.setGrammar(atom.grammars.grammarForScopeName(scope))

  setCursor: (points) ->
    points = toArrayOfPoint(points)
    @editor.setCursorScreenPosition(points.shift())
    for point in points
      @editor.addCursorAtScreenPosition(point)

  setCursorBuffer: (points) ->
    points = toArrayOfPoint(points)
    @editor.setCursorBufferPosition(points.shift())
    for point in points
      @editor.addCursorAtBufferPosition(point)

  setAddCursor: (points) ->
    for point in toArrayOfPoint(points)
      @editor.addCursorAtScreenPosition(point)

  setAddCursorBuffer: (points) ->
    for point in toArrayOfPoint(points)
      @editor.addCursorAtBufferPosition(point)

  setRegister: (register) ->
    for name, value of register
      @vimState.register.set(name, value)

  setSelectedBufferRange: (range) ->
    @editor.setSelectedBufferRange(range)

  ensureOptionsOrdered = [
    'text',
    'text_',
    'selectedText', 'selectedTextOrdered'
    'cursor', 'cursorBuffer',
    'numCursors'
    'register',
    'selectedScreenRange', 'selectedScreenRangeOrdered'
    'selectedBufferRange', 'selectedBufferRangeOrdered'
    'selectionIsReversed',
    'characterwiseHead'
    'scrollTop',
    'mode',
  ]
  # Public
  ensure: (args...) =>
    switch args.length
      when 1 then [options] = args
      when 2 then [keystroke, options] = args
    @validateOptions(options, ensureOptionsOrdered, 'Invalid ensure option')
    # Input
    unless _.isEmpty(keystroke)
      @keystroke(keystroke)

    for name in ensureOptionsOrdered when options[name]?
      method = 'ensure' + _.capitalize(_.camelize(name))
      this[method](options[name])

  ensureText: (text) -> expect(@editor.getText()).toEqual(text)

  ensureText_: (text) ->
    @ensureText(text.replace(/_/g, ' '))

  ensureSelectedText: (text, ordered=false) ->
    selections = if ordered
      @editor.getSelectionsOrderedByBufferPosition()
    else
      @editor.getSelections()
    actual = (s.getText() for s in selections)
    expect(actual).toEqual(toArray(text))

  ensureSelectedTextOrdered: (text) ->
    @ensureSelectedText(text, true)

  ensureCursor: (points) ->
    actual = @editor.getCursorScreenPositions()
    expect(actual).toEqual(toArrayOfPoint(points))

  ensureCursorBuffer: (points) ->
    actual = @editor.getCursorBufferPositions()
    expect(actual).toEqual(toArrayOfPoint(points))

  ensureRegister: (register) ->
    for name, ensure of register
      {selection} = ensure
      delete ensure.selection
      reg = @vimState.register.get(name, selection)
      for property, _value of ensure
        expect(reg[property]).toEqual(_value)

  ensureNumCursors: (number) ->
    expect(@editor.getCursors()).toHaveLength number

  _ensureSelectedRangeBy: (range, ordered=false, fn) ->
    selections = if ordered
      @editor.getSelectionsOrderedByBufferPosition()
    else
      @editor.getSelections()
    actual = (fn(s) for s in selections)
    expect(actual).toEqual(toArrayOfRange(range))

  ensureSelectedScreenRange: (range, ordered=false) ->
    @_ensureSelectedRangeBy range, ordered, (s) -> s.getScreenRange()

  ensureSelectedScreenRangeOrdered: (range) ->
    @ensureSelectedScreenRange(range, true)

  ensureSelectedBufferRange: (range, ordered=false) ->
    @_ensureSelectedRangeBy range, ordered, (s) -> s.getBufferRange()

  ensureSelectedBufferRangeOrdered: (range) ->
    @ensureSelectedBufferRange(range, true)

  ensureSelectionIsReversed: (reversed) ->
    actual = @editor.getLastSelection().isReversed()
    expect(actual).toBe(reversed)

  ensureCharacterwiseHead: (points) ->
    actual = (swrap(s).getCharacterwiseHeadPosition() for s in @editor.getSelections())
    expect(actual).toEqual(toArrayOfPoint(points))

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

  # Public
  # options
  # - waitsForFinish
  keystroke: (keys, options={}) =>
    if options.waitsForFinish
      finished = false
      @vimState.onDidFinishOperation -> finished = true
      delete options.waitsForFinish
      @keystroke(keys, options)
      waitsFor -> finished
      return

    # keys must be String or Array
    # Not support Object for keys to avoid ambiguity.
    target = @editorElement

    for k in toArray(keys)
      if _.isString(k)
        newKeystroke(k, target)
      else
        switch
          when k.input?
            @vimState.input.editor.insertText(k.input)
          when k.search?
            @vimState.searchInput.editor.insertText(k.search)
            atom.commands.dispatch(@vimState.searchInput.editorElement, 'core:confirm')
          else
            newKeystroke(k, target)

module.exports = {getVimState, getView, dispatch, TextData, withMockPlatform}
