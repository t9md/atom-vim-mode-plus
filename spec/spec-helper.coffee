_ = require 'underscore-plus'
semver = require 'semver'
{Range, Point, Disposable} = require 'atom'
{inspect} = require 'util'
globalState = require '../lib/global-state'
settings = require '../lib/settings'

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
  settings.set("stayOnTransformString", false)
  settings.set("stayOnYank", false)
  settings.set("stayOnDelete", false)
  settings.set("stayOnSelectTextObject", false)
  settings.set("stayOnVerticalMotion", true)

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

  getLine: (line, options) ->
    @getLines([line], options)

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
    {partialMatchTimeout, waitsForFinish} = options
    delete options.partialMatchTimeout
    delete options.waitsForFinish
    {partialMatchTimeout, waitsForFinish}

  # Public
  ensure: (keystroke, options={}) =>
    unless typeof(options) is 'object'
      throw new Error("Invalid options for 'ensure': must be 'object' but got '#{typeof(options)}'")
    if keystroke? and not (typeof(keystroke) is 'string' or Array.isArray(keystroke))
      throw new Error("Invalid keystroke for 'ensure': must be 'string' or 'array' but got '#{typeof(keystroke)}'")

    keystrokeOptions = @getAndDeleteKeystrokeOptions(options)

    @validateOptions(options, ensureOptionsOrdered, 'Invalid ensure option')
    @validateExclusiveOptions(options, ensureExclusiveRules)

    runSmart = (fn) -> if keystrokeOptions.waitsForFinish then runs(fn) else fn()

    runSmart =>
      @_keystroke(keystroke, keystrokeOptions) unless _.isEmpty(keystroke)

    runSmart =>
      for name in ensureOptionsOrdered when options[name]?
        method = 'ensure' + _.capitalize(_.camelize(name))
        this[method](options[name])

  ensureWait: (keystroke, options={}) =>
    @ensure(keystroke, Object.assign(options, waitsForFinish: true))

  bindEnsureOption: (optionsBase, wait=false) =>
    (keystroke, options) =>
      intersectingOptions = _.intersection(_.keys(options), _.keys(optionsBase))
      if intersectingOptions.length
        throw new Error("conflict with bound options #{inspect(intersectingOptions)}")

      options = _.defaults(_.clone(options), optionsBase)
      options.waitsForFinish = true if wait
      @ensure(keystroke, options)

  bindEnsureWaitOption: (optionsBase) =>
    @bindEnsureOption(optionsBase, true)

  _keystroke: (keys, options={}) =>
    target = @editorElement
    keystrokesToExecute = keys.split(/\s+/)
    lastKeystrokeIndex = keystrokesToExecute.length - 1

    for key, i in keystrokesToExecute
      waitsForFinish = (i is lastKeystrokeIndex) and options.waitsForFinish
      if waitsForFinish
        finished = false
        @vimState.onDidFinishOperation -> finished = true

      # [FIXME] Why can't I let atom.keymaps handle enter/escape by buildEvent and handleKeyboardEvent
      if @vimState.__searchInput?.hasFocus() # to avoid auto populate
        target = @vimState.searchInput.editorElement
        switch key
          when "enter" then atom.commands.dispatch(target, 'core:confirm')
          when "escape" then atom.commands.dispatch(target, 'core:cancel')
          else @vimState.searchInput.editor.insertText(key)

      else if @vimState.inputEditor?
        target = @vimState.inputEditor.element
        switch key
          when "enter" then atom.commands.dispatch(target, 'core:confirm')
          when "escape" then atom.commands.dispatch(target, 'core:cancel')
          else @vimState.inputEditor.insertText(key)

      else
        event = buildKeydownEventFromKeystroke(normalizeKeystrokes(key), target)
        atom.keymaps.handleKeyboardEvent(event)

      if waitsForFinish
        waitsFor -> finished

    if options.partialMatchTimeout
      advanceClock(atom.keymaps.getPartialMatchTimeout())

  keystroke: ->
    # DONT remove this method since field extraction is still used in vmp plugins
    throw new Error('Dont use `keystroke("x y z")`, instead use `ensure("x y z")`')

  # Ensure each options from here
  # -----------------------------
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
    actual = @vimState.isNarrowed()
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

module.exports = {getVimState, getView, dispatch, TextData, withMockPlatform}
