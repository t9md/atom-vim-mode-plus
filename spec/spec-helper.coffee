_ = require 'underscore-plus'
semver = require 'semver'
{Range, Point, Disposable} = require 'atom'
{inspect} = require 'util'
globalState = require '../lib/global-state'

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

# Init spec state
# -------------------------
beforeEach ->
  globalState.reset()

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

  if semver.satisfies(atom.getVersion(), '< 1.12')
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

rawKeystroke = (keystrokes, target) ->
  for key in normalizeKeystrokes(keystrokes).split(/\s+/)
    event = buildKeydownEventFromKeystroke(key, target)
    atom.keymaps.handleKeyboardEvent(event)

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

collectIndexInText = (char, text) ->
  indexes = []
  fromIndex = 0
  while (index = text.indexOf(char, fromIndex)) >= 0
    fromIndex = index + 1
    indexes.push(index)
  indexes

collectCharPositionsInText = (char, text) ->
  positions = []
  for lineText, rowNumber in text.split(/\n/)
    for index, i in collectIndexInText(char, lineText)
      positions.push([rowNumber, index - i])
  positions

class VimEditor
  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState

  validateOptions: (options, validOptions, message) ->
    invalidOptions = _.without(_.keys(options), validOptions...)
    if invalidOptions.length
      throw new Error("#{message}: #{inspect(invalidOptions)}")

  validateExclusiveOptions: (options, rules) ->
    allOptions = Object.keys(options)
    for option, exclusiveOptions of rules when option of options
      violatingOptions = exclusiveOptions.filter (exclusiveOption) -> exclusiveOption in allOptions
      if violatingOptions.length
        throw new Error("#{option} is exclusive with [#{violatingOptions}]")

  setOptionsOrdered = [
    'text', 'text_',
    'textC', 'textC_',
    'grammar',
    'cursor', 'cursorScreen'
    'addCursor', 'cursorScreen'
    'register',
    'selectedBufferRange'
  ]

  setExclusiveRules =
    textC: ['cursor', 'cursorScreen']
    textC_: ['cursor', 'cursorScreen']

  # Public
  set: (options) =>
    @validateOptions(options, setOptionsOrdered, 'Invalid set options')
    @validateExclusiveOptions(options, setExclusiveRules)

    for name in setOptionsOrdered when options[name]?
      method = 'set' + _.capitalize(_.camelize(name))
      this[method](options[name])

  setText: (text) ->
    @editor.setText(text)

  setText_: (text) ->
    @setText(text.replace(/_/g, ' '))

  setTextC: (text) ->
    cursors = collectCharPositionsInText('|', text.replace(/!/g, ''))
    lastCursor = collectCharPositionsInText('!', text.replace(/\|/g, ''))
    @setText(text.replace(/[\|!]/g, ''))
    cursors = cursors.concat(lastCursor)
    if cursors.length
      @setCursor(cursors)

  setTextC_: (text) ->
    @setTextC(text.replace(/_/g, ' '))

  setGrammar: (scope) ->
    @editor.setGrammar(atom.grammars.grammarForScopeName(scope))

  setCursor: (points) ->
    points = toArrayOfPoint(points)
    @editor.setCursorBufferPosition(points.shift())
    for point in points
      @editor.addCursorAtBufferPosition(point)

  setCursorScreen: (points) ->
    points = toArrayOfPoint(points)
    @editor.setCursorScreenPosition(points.shift())
    for point in points
      @editor.addCursorAtScreenPosition(point)

  setAddCursor: (points) ->
    for point in toArrayOfPoint(points)
      @editor.addCursorAtBufferPosition(point)

  setRegister: (register) ->
    for name, value of register
      @vimState.register.set(name, value)

  setSelectedBufferRange: (range) ->
    @editor.setSelectedBufferRange(range)

  ensureOptionsOrdered = [
    'text', 'text_',
    'textC', 'textC_',
    'selectedText', 'selectedText_', 'selectedTextOrdered', "selectionIsNarrowed"
    'cursor', 'cursorScreen'
    'numCursors'
    'register',
    'selectedScreenRange', 'selectedScreenRangeOrdered'
    'selectedBufferRange', 'selectedBufferRangeOrdered'
    'selectionIsReversed',
    'persistentSelectionBufferRange', 'persistentSelectionCount'
    'occurrenceCount', 'occurrenceText'
    'propertyHead'
    'propertyTail'
    'scrollTop',
    'mark'
    'mode',
  ]
  ensureExclusiveRules =
    textC: ['cursor', 'cursorScreen']
    textC_: ['cursor', 'cursorScreen']

  getAndDeleteKeystrokeOptions: (options) ->
    {partialMatchTimeout} = options
    delete options.partialMatchTimeout
    {partialMatchTimeout}

  # Public
  ensure: (args...) =>
    switch args.length
      when 1 then [options] = args
      when 2 then [keystroke, options] = args

    unless typeof(options) is 'object'
      throw new Error("Invalid options for 'ensure': must be 'object' but got '#{typeof(options)}'")
    if keystroke? and not (typeof(keystroke) is 'string' or Array.isArray(keystroke))
      throw new Error("Invalid keystroke for 'ensure': must be 'string' or 'array' but got '#{typeof(keystroke)}'")

    keystrokeOptions = @getAndDeleteKeystrokeOptions(options)

    @validateOptions(options, ensureOptionsOrdered, 'Invalid ensure option')
    @validateExclusiveOptions(options, ensureExclusiveRules)

    # Input
    unless _.isEmpty(keystroke)
      @keystroke(keystroke, keystrokeOptions)

    for name in ensureOptionsOrdered when options[name]?
      method = 'ensure' + _.capitalize(_.camelize(name))
      this[method](options[name])

  bindEnsureOption: (optionsBase) =>
    (keystroke, options) =>
      intersectingOptions = _.intersection(_.keys(options), _.keys(optionsBase))
      if intersectingOptions.length
        throw new Error("conflict with bound options #{inspect(intersectingOptions)}")

      @ensure(keystroke, _.defaults(_.clone(options), optionsBase))

  ensureByDispatch: (command, options) =>
    dispatch(atom.views.getView(@editor), command)
    for name in ensureOptionsOrdered when options[name]?
      method = 'ensure' + _.capitalize(_.camelize(name))
      this[method](options[name])

  ensureText: (text) ->
    expect(@editor.getText()).toEqual(text)

  ensureText_: (text) ->
    @ensureText(text.replace(/_/g, ' '))

  ensureTextC: (text) ->
    cursors = collectCharPositionsInText('|', text.replace(/!/g, ''))
    lastCursor = collectCharPositionsInText('!', text.replace(/\|/g, ''))
    cursors = cursors.concat(lastCursor)
    cursors = cursors
      .map (point) -> Point.fromObject(point)
      .sort (a, b) -> a.compare(b)
    @ensureText(text.replace(/[\|!]/g, ''))
    if cursors.length
      @ensureCursor(cursors, true)

    if lastCursor.length
      expect(@editor.getCursorBufferPosition()).toEqual(lastCursor[0])

  ensureTextC_: (text) ->
    @ensureTextC(text.replace(/_/g, ' '))

  ensureSelectedText: (text, ordered=false) ->
    selections = if ordered
      @editor.getSelectionsOrderedByBufferPosition()
    else
      @editor.getSelections()
    actual = (s.getText() for s in selections)
    expect(actual).toEqual(toArray(text))

  ensureSelectedText_: (text, ordered) ->
    @ensureSelectedText(text.replace(/_/g, ' '), ordered)

  ensureSelectionIsNarrowed: (isNarrowed) ->
    actual = @vimState.modeManager.isNarrowed()
    expect(actual).toEqual(isNarrowed)

  ensureSelectedTextOrdered: (text) ->
    @ensureSelectedText(text, true)

  ensureCursor: (points, ordered=false) ->
    actual = @editor.getCursorBufferPositions()
    actual = actual.sort (a, b) -> a.compare(b) if ordered
    expect(actual).toEqual(toArrayOfPoint(points))

  ensureCursorScreen: (points) ->
    actual = @editor.getCursorScreenPositions()
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
    for selection in @editor.getSelections()
      actual = selection.isReversed()
      expect(actual).toBe(reversed)

  ensurePersistentSelectionBufferRange: (range) ->
    actual = @vimState.persistentSelection.getMarkerBufferRanges()
    expect(actual).toEqual(toArrayOfRange(range))

  ensurePersistentSelectionCount: (number) ->
    actual = @vimState.persistentSelection.getMarkerCount()
    expect(actual).toBe number

  ensureOccurrenceCount: (number) ->
    actual = @vimState.occurrenceManager.getMarkerCount()
    expect(actual).toBe number

  ensureOccurrenceText: (text) ->
    markers = @vimState.occurrenceManager.getMarkers()
    ranges = (r.getBufferRange() for r in markers)
    actual = (@editor.getTextInBufferRange(r) for r in ranges)
    expect(actual).toEqual(toArray(text))

  ensurePropertyHead: (points) ->
    getHeadProperty = (selection) =>
      @vimState.swrap(selection).getBufferPositionFor('head', from: ['property'])
    actual = (getHeadProperty(s) for s in @editor.getSelections())
    expect(actual).toEqual(toArrayOfPoint(points))

  ensurePropertyTail: (points) ->
    getTailProperty = (selection) =>
      @vimState.swrap(selection).getBufferPositionFor('tail', from: ['property'])
    actual = (getTailProperty(s) for s in @editor.getSelections())
    expect(actual).toEqual(toArrayOfPoint(points))

  ensureScrollTop: (scrollTop) ->
    actual = @editorElement.getScrollTop()
    expect(actual).toEqual scrollTop

  ensureMark: (mark) ->
    for name, point of mark
      actual = @vimState.mark.get(name)
      expect(actual).toEqual(point)

  ensureMode: (mode) ->
    mode = toArray(mode).slice()
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
        rawKeystroke(k, target)
      else
        switch
          when k.input?
            # TODO no longer need to use [input: 'char'] style.
            rawKeystroke(_key, target) for _key in k.input.split('')
          when k.search?
            @vimState.searchInput.editor.insertText(k.search) if k.search
            atom.commands.dispatch(@vimState.searchInput.editorElement, 'core:confirm')
          else
            rawKeystroke(k, target)

    if options.partialMatchTimeout
      advanceClock(atom.keymaps.getPartialMatchTimeout())

module.exports = {getVimState, getView, dispatch, TextData, withMockPlatform, rawKeystroke}
