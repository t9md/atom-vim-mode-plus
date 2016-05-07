_ = require 'underscore-plus'
{Range, Point} = require 'atom'
{inspect} = require 'util'
swrap = require '../lib/selection-wrapper'

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

mockPlatform = (editorElement, platform) ->
  wrapper = document.createElement('div')
  wrapper.className = platform
  wrapper.appendChild(editorElement)

unmockPlatform = (editorElement) ->
  editorElement.parentNode.removeChild(editorElement)

KeymapManager = null
buildKeydownEvent = (key, options) ->
  KeymapManager ?= atom.keymaps.constructor
  KeymapManager.buildKeydownEvent(key, options)

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

  ensureText: (text) ->
    expect(@editor.getText()).toEqual(text)

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
    # {element} = options
    # console.log element
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
    mocked = null
    keys = [keys] unless _.isArray(keys)

    for k in keys
      if _.isString(k)
        _keystroke(k, {target})
        continue
      else
        switch
          when k.platform?
            mockPlatform(target, k.platform)
            mocked = true
          when k.char?
            chars =
              # [FIXME] Cause insertText('escape'), useless.
              if k.char in ['', 'escape']
                toArray(k.char)
              else
                k.char.split('')
            for c in chars
              @vimState.input.editor.insertText(c)
          when k.search?
            {editor, editorElement} = @vimState.searchInput
            editor.insertText(k.search)
            atom.commands.dispatch(editorElement, 'core:confirm')
          when k.ctrl? then _keystroke(k.ctrl, {ctrl: true, target})
          when k.cmd? then _keystroke(k.cmd, {meta: true, target})
          when k.raw? then _keystroke(k.raw, {raw: true, target})
    unmockPlatform(target) if mocked

module.exports = {getVimState, getView, dispatch, TextData}
