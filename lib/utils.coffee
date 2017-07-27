fs = null
settings = require './settings'

{Disposable, Range, Point} = require 'atom'
_ = require 'underscore-plus'

assertWithException = (condition, message, fn) ->
  atom.assert condition, message, (error) ->
    throw new Error(error.message)

getAncestors = (obj) ->
  ancestors = []
  current = obj
  loop
    ancestors.push(current)
    current = current.__super__?.constructor
    break unless current
  ancestors

getKeyBindingForCommand = (command, {packageName}) ->
  results = null
  keymaps = atom.keymaps.getKeyBindings()
  if packageName?
    keymapPath = atom.packages.getActivePackage(packageName).getKeymapPaths().pop()
    keymaps = keymaps.filter(({source}) -> source is keymapPath)

  for keymap in keymaps when keymap.command is command
    {keystrokes, selector} = keymap
    keystrokes = keystrokes.replace(/shift-/, '')
    (results ?= []).push({keystrokes, selector})
  results

# Include module(object which normaly provides set of methods) to klass
include = (klass, module) ->
  for key, value of module
    klass::[key] = value

debug = (messages...) ->
  return unless settings.get('debug')
  switch settings.get('debugOutput')
    when 'console'
      console.log messages...
    when 'file'
      fs ?= require 'fs-plus'
      filePath = fs.normalize settings.get('debugOutputFilePath')
      if fs.existsSync(filePath)
        fs.appendFileSync filePath, messages + "\n"

# Return function to restore editor's scrollTop and fold state.
saveEditorState = (editor) ->
  editorElement = editor.element
  scrollTop = editorElement.getScrollTop()

  foldStartRows = editor.displayLayer.foldsMarkerLayer.findMarkers({}).map (m) -> m.getStartPosition().row
  ->
    for row in foldStartRows.reverse() when not editor.isFoldedAtBufferRow(row)
      editor.foldBufferRow(row)
    editorElement.setScrollTop(scrollTop)

isLinewiseRange = ({start, end}) ->
  (start.row isnt end.row) and (start.column is end.column is 0)

isEndsWithNewLineForBufferRow = (editor, row) ->
  {start, end} = editor.bufferRangeForBufferRow(row, includeNewline: true)
  start.row isnt end.row

sortRanges = (collection) ->
  collection.sort (a, b) -> a.compare(b)

# Return adjusted index fit whitin given list's length
# return -1 if list is empty.
getIndex = (index, list) ->
  length = list.length
  if length is 0
    -1
  else
    index = index % length
    if index >= 0
      index
    else
      length + index

# NOTE: endRow become undefined if @editorElement is not yet attached.
# e.g. Beging called immediately after open file.
getVisibleBufferRange = (editor) ->
  [startRow, endRow] = editor.element.getVisibleRowRange()
  return null unless (startRow? and endRow?)
  startRow = editor.bufferRowForScreenRow(startRow)
  endRow = editor.bufferRowForScreenRow(endRow)
  new Range([startRow, 0], [endRow, Infinity])

getVisibleEditors = ->
  (editor for pane in atom.workspace.getPanes() when editor = pane.getActiveEditor())

getEndOfLineForBufferRow = (editor, row) ->
  editor.bufferRangeForBufferRow(row).end

# Point util
# -------------------------
pointIsAtEndOfLine = (editor, point) ->
  point = Point.fromObject(point)
  getEndOfLineForBufferRow(editor, point.row).isEqual(point)

pointIsOnWhiteSpace = (editor, point) ->
  char = getRightCharacterForBufferPosition(editor, point)
  not /\S/.test(char)

pointIsAtEndOfLineAtNonEmptyRow = (editor, point) ->
  point = Point.fromObject(point)
  point.column isnt 0 and pointIsAtEndOfLine(editor, point)

pointIsAtVimEndOfFile = (editor, point) ->
  getVimEofBufferPosition(editor).isEqual(point)

isEmptyRow = (editor, row) ->
  editor.bufferRangeForBufferRow(row).isEmpty()

getRightCharacterForBufferPosition = (editor, point, amount=1) ->
  editor.getTextInBufferRange(Range.fromPointWithDelta(point, 0, amount))

getLeftCharacterForBufferPosition = (editor, point, amount=1) ->
  editor.getTextInBufferRange(Range.fromPointWithDelta(point, 0, -amount))

getTextInScreenRange = (editor, screenRange) ->
  bufferRange = editor.bufferRangeForScreenRange(screenRange)
  editor.getTextInBufferRange(bufferRange)

getNonWordCharactersForCursor = (cursor) ->
  # Atom 1.11.0-beta5 have this experimental method.
  if cursor.getNonWordCharacters?
    cursor.getNonWordCharacters()
  else
    scope = cursor.getScopeDescriptor().getScopesArray()
    atom.config.get('editor.nonWordCharacters', {scope})

# FIXME: remove this
# return true if moved
moveCursorToNextNonWhitespace = (cursor) ->
  originalPoint = cursor.getBufferPosition()
  editor = cursor.editor
  vimEof = getVimEofBufferPosition(editor)

  while pointIsOnWhiteSpace(editor, point = cursor.getBufferPosition()) and not point.isGreaterThanOrEqual(vimEof)
    cursor.moveRight()
  not originalPoint.isEqual(cursor.getBufferPosition())

getBufferRows = (editor, {startRow, direction}) ->
  switch direction
    when 'previous'
      if startRow <= 0
        []
      else
        [(startRow - 1)..0]
    when 'next'
      endRow = getVimLastBufferRow(editor)
      if startRow >= endRow
        []
      else
        [(startRow + 1)..endRow]

# Return Vim's EOF position rather than Atom's EOF position.
# This function change meaning of EOF from native TextEditor::getEofBufferPosition()
# Atom is special(strange) for cursor can past very last newline character.
# Because of this, Atom's EOF position is [actualLastRow+1, 0] provided last-non-blank-row
# ends with newline char.
# But in Vim, curor can NOT past last newline. EOF is next position of very last character.
getVimEofBufferPosition = (editor) ->
  eof = editor.getEofBufferPosition()
  if (eof.row is 0) or (eof.column > 0)
    eof
  else
    getEndOfLineForBufferRow(editor, eof.row - 1)

getVimEofScreenPosition = (editor) ->
  editor.screenPositionForBufferPosition(getVimEofBufferPosition(editor))

getVimLastBufferRow = (editor) -> getVimEofBufferPosition(editor).row
getVimLastScreenRow = (editor) -> getVimEofScreenPosition(editor).row
getFirstVisibleScreenRow = (editor) -> editor.element.getFirstVisibleScreenRow()
getLastVisibleScreenRow = (editor) -> editor.element.getLastVisibleScreenRow()

getFirstCharacterPositionForBufferRow = (editor, row) ->
  range = findRangeInBufferRow(editor, /\S/, row)
  range?.start ? new Point(row, 0)

trimRange = (editor, scanRange) ->
  pattern = /\S/
  [start, end] = []
  setStart = ({range}) -> {start} = range
  setEnd = ({range}) -> {end} = range
  editor.scanInBufferRange(pattern, scanRange, setStart)
  editor.backwardsScanInBufferRange(pattern, scanRange, setEnd) if start?
  if start? and end?
    new Range(start, end)
  else
    scanRange

# Cursor motion wrapper
# -------------------------
# Just update bufferRow with keeping column by respecting goalColumn
setBufferRow = (cursor, row, options) ->
  column = cursor.goalColumn ? cursor.getBufferColumn()
  cursor.setBufferPosition([row, column], options)
  cursor.goalColumn = column

setBufferColumn = (cursor, column) ->
  cursor.setBufferPosition([cursor.getBufferRow(), column])

moveCursor = (cursor, {preserveGoalColumn}, fn) ->
  {goalColumn} = cursor
  fn(cursor)
  if preserveGoalColumn and goalColumn?
    cursor.goalColumn = goalColumn

# Workaround issue for t9md/vim-mode-plus#226 and atom/atom#3174
# I cannot depend cursor's column since its claim 0 and clipping emmulation don't
# return wrapped line, but It actually wrap, so I need to do very dirty work to
# predict wrap huristically.
shouldPreventWrapLine = (cursor) ->
  {row, column} = cursor.getBufferPosition()
  if atom.config.get('editor.softTabs')
    tabLength = atom.config.get('editor.tabLength')
    if 0 < column < tabLength
      text = cursor.editor.getTextInBufferRange([[row, 0], [row, tabLength]])
      /^\s+$/.test(text)
    else
      false

# options:
#   allowWrap: to controll allow wrap
#   preserveGoalColumn: preserve original goalColumn
moveCursorLeft = (cursor, options={}) ->
  {allowWrap, needSpecialCareToPreventWrapLine} = options
  delete options.allowWrap
  if needSpecialCareToPreventWrapLine
    return if shouldPreventWrapLine(cursor)

  if not cursor.isAtBeginningOfLine() or allowWrap
    motion = (cursor) -> cursor.moveLeft()
    moveCursor(cursor, options, motion)

moveCursorRight = (cursor, options={}) ->
  {allowWrap} = options
  delete options.allowWrap
  if not cursor.isAtEndOfLine() or allowWrap
    motion = (cursor) -> cursor.moveRight()
    moveCursor(cursor, options, motion)

moveCursorUpScreen = (cursor, options={}) ->
  unless cursor.getScreenRow() is 0
    motion = (cursor) -> cursor.moveUp()
    moveCursor(cursor, options, motion)

moveCursorDownScreen = (cursor, options={}) ->
  unless getVimLastScreenRow(cursor.editor) is cursor.getScreenRow()
    motion = (cursor) -> cursor.moveDown()
    moveCursor(cursor, options, motion)

moveCursorToFirstCharacterAtRow = (cursor, row) ->
  cursor.setBufferPosition([row, 0])
  cursor.moveToFirstCharacterOfLine()

getValidVimBufferRow = (editor, row) -> limitNumber(row, min: 0, max: getVimLastBufferRow(editor))

getValidVimScreenRow = (editor, row) -> limitNumber(row, min: 0, max: getVimLastScreenRow(editor))

# By default not include column
getLineTextToBufferPosition = (editor, {row, column}, {exclusive}={}) ->
  if exclusive ? true
    editor.lineTextForBufferRow(row)[0...column]
  else
    editor.lineTextForBufferRow(row)[0..column]

getIndentLevelForBufferRow = (editor, row) ->
  editor.indentLevelForLine(editor.lineTextForBufferRow(row))

getCodeFoldRowRanges = (editor) ->
  [0..editor.getLastBufferRow()]
    .map (row) ->
      editor.languageMode.rowRangeForCodeFoldAtBufferRow(row)
    .filter (rowRange) ->
      rowRange? and rowRange[0]? and rowRange[1]?

# Used in vmp-jasmine-increase-focus
getCodeFoldRowRangesContainesForRow = (editor, bufferRow, {includeStartRow}={}) ->
  includeStartRow ?= true
  getCodeFoldRowRanges(editor).filter ([startRow, endRow]) ->
    if includeStartRow
      startRow <= bufferRow <= endRow
    else
      startRow < bufferRow <= endRow

getFoldRowRangesContainedByFoldStartsAtRow = (editor, row) ->
  return null unless editor.isFoldableAtBufferRow(row)

  [startRow, endRow] = editor.languageMode.rowRangeForFoldAtBufferRow(row)

  seen = {}
  [startRow..endRow]
    .map (row) ->
      editor.languageMode.rowRangeForFoldAtBufferRow(row)
    .filter (rowRange) ->
      rowRange? and rowRange[0]? and rowRange[1]?
    .filter (rowRange) ->
      if seen[rowRange] then false else seen[rowRange] = true

getFoldRowRanges = (editor) ->
  seen = {}
  [0..editor.getLastBufferRow()]
    .map (row) ->
      editor.languageMode.rowRangeForCodeFoldAtBufferRow(row)
    .filter (rowRange) ->
      rowRange? and rowRange[0]? and rowRange[1]?
    .filter (rowRange) ->
      if seen[rowRange] then false else seen[rowRange] = true

getFoldRangesWithIndent = (editor) ->
  getFoldRowRanges(editor)
    .map ([startRow, endRow]) ->
      indent = editor.indentationForBufferRow(startRow)
      {startRow, endRow, indent}

getFoldInfoByKind = (editor) ->
  foldInfoByKind = {}

  updateFoldInfo = (kind, rowRangeWithIndent) ->
    foldInfo = (foldInfoByKind[kind] ?= {})
    foldInfo.rowRangesWithIndent ?= []
    foldInfo.rowRangesWithIndent.push(rowRangeWithIndent)
    indent = rowRangeWithIndent.indent
    foldInfo.minIndent = Math.min(foldInfo.minIndent ? indent, indent)
    foldInfo.maxIndent = Math.max(foldInfo.maxIndent ? indent, indent)

  for rowRangeWithIndent in getFoldRangesWithIndent(editor)
    updateFoldInfo('allFold', rowRangeWithIndent)
    if editor.isFoldedAtBufferRow(rowRangeWithIndent.startRow)
      updateFoldInfo('folded', rowRangeWithIndent)
    else
      updateFoldInfo('unfolded', rowRangeWithIndent)
  foldInfoByKind

getBufferRangeForRowRange = (editor, rowRange) ->
  [startRange, endRange] = rowRange.map (row) ->
    editor.bufferRangeForBufferRow(row, includeNewline: true)
  startRange.union(endRange)

getTokenizedLineForRow = (editor, row) ->
  editor.tokenizedBuffer.tokenizedLineForRow(row)

getScopesForTokenizedLine = (line) ->
  for tag in line.tags when tag < 0 and (tag % 2 is -1)
    atom.grammars.scopeForId(tag)

scanForScopeStart = (editor, fromPoint, direction, fn) ->
  fromPoint = Point.fromObject(fromPoint)
  scanRows = switch direction
    when 'forward' then [(fromPoint.row)..editor.getLastBufferRow()]
    when 'backward' then [(fromPoint.row)..0]

  continueScan = true
  stop = ->
    continueScan = false

  isValidToken = switch direction
    when 'forward' then ({position}) -> position.isGreaterThan(fromPoint)
    when 'backward' then ({position}) -> position.isLessThan(fromPoint)

  for row in scanRows when tokenizedLine = getTokenizedLineForRow(editor, row)
    column = 0
    results = []

    tokenIterator = tokenizedLine.getTokenIterator()
    for tag in tokenizedLine.tags
      tokenIterator.next()
      if tag < 0 # Negative: start/stop token
        scope = atom.grammars.scopeForId(tag)
        if (tag % 2) is 0 # Even: scope stop
          null
        else # Odd: scope start
          position = new Point(row, column)
          results.push {scope, position, stop}
      else
        column += tag

    results = results.filter(isValidToken)
    results.reverse() if direction is 'backward'
    for result in results
      fn(result)
      return unless continueScan
    return unless continueScan

detectScopeStartPositionForScope = (editor, fromPoint, direction, scope) ->
  point = null
  scanForScopeStart editor, fromPoint, direction, (info) ->
    if info.scope.search(scope) >= 0
      info.stop()
      point = info.position
  point

isIncludeFunctionScopeForRow = (editor, row) ->
  # [FIXME] Bug of upstream?
  # Sometime tokenizedLines length is less than last buffer row.
  # So tokenizedLine is not accessible even if valid row.
  # In that case I simply return empty Array.
  if tokenizedLine = getTokenizedLineForRow(editor, row)
    getScopesForTokenizedLine(tokenizedLine).some (scope) ->
      isFunctionScope(editor, scope)
  else
    false

# [FIXME] very rough state, need improvement.
isFunctionScope = (editor, scope) ->
  switch editor.getGrammar().scopeName
    when 'source.go', 'source.elixir', 'source.rust'
      scopes = ['entity.name.function']
    when 'source.ruby'
      scopes = ['meta.function.', 'meta.class.', 'meta.module.']
    else
      scopes = ['meta.function.', 'meta.class.']
  pattern = new RegExp('^' + scopes.map(_.escapeRegExp).join('|'))
  pattern.test(scope)

# Scroll to bufferPosition with minimum amount to keep original visible area.
# If target position won't fit within onePageUp or onePageDown, it center target point.
smartScrollToBufferPosition = (editor, point) ->
  editorElement = editor.element
  editorAreaHeight = editor.getLineHeightInPixels() * (editor.getRowsPerPage() - 1)
  onePageUp = editorElement.getScrollTop() - editorAreaHeight # No need to limit to min=0
  onePageDown = editorElement.getScrollBottom() + editorAreaHeight
  target = editorElement.pixelPositionForBufferPosition(point).top

  center = (onePageDown < target) or (target < onePageUp)
  editor.scrollToBufferPosition(point, {center})

matchScopes = (editorElement, scopes) ->
  classes = scopes.map (scope) -> scope.split('.')

  for classNames in classes
    containsCount = 0
    for className in classNames
      containsCount += 1 if editorElement.classList.contains(className)
    return true if containsCount is classNames.length
  false

isSingleLineText = (text) ->
  text.split(/\n|\r\n/).length is 1

# Return bufferRange and kind ['white-space', 'non-word', 'word']
#
# This function modify wordRegex so that it feel NATURAL in Vim's normal mode.
# In normal-mode, cursor is ractangle(not pipe(|) char).
# Cursor is like ON word rather than BETWEEN word.
# The modification is tailord like this
#   - ON white-space: Includs only white-spaces.
#   - ON non-word: Includs only non word char(=excludes normal word char).
#
# Valid options
#  - wordRegex: instance of RegExp
#  - nonWordCharacters: string
getWordBufferRangeAndKindAtBufferPosition = (editor, point, options={}) ->
  {singleNonWordChar, wordRegex, nonWordCharacters, cursor} = options
  if not wordRegex? or not nonWordCharacters? # Complement from cursor
    cursor ?= editor.getLastCursor()
    {wordRegex, nonWordCharacters} = _.extend(options, buildWordPatternByCursor(cursor, options))
  singleNonWordChar ?= true

  characterAtPoint = getRightCharacterForBufferPosition(editor, point)
  nonWordRegex = new RegExp("[#{_.escapeRegExp(nonWordCharacters)}]+")

  if /\s/.test(characterAtPoint)
    source = "[\t ]+"
    kind = 'white-space'
    wordRegex = new RegExp(source)
  else if nonWordRegex.test(characterAtPoint) and not wordRegex.test(characterAtPoint)
    kind = 'non-word'
    if singleNonWordChar
      source = _.escapeRegExp(characterAtPoint)
      wordRegex = new RegExp(source)
    else
      wordRegex = nonWordRegex
  else
    kind = 'word'

  range = getWordBufferRangeAtBufferPosition(editor, point, {wordRegex})
  {kind, range}

getWordPatternAtBufferPosition = (editor, point, options={}) ->
  boundarizeForWord = options.boundarizeForWord ? true
  delete options.boundarizeForWord
  {range, kind} = getWordBufferRangeAndKindAtBufferPosition(editor, point, options)
  text = editor.getTextInBufferRange(range)
  pattern = _.escapeRegExp(text)

  if kind is 'word' and boundarizeForWord
    # Set word-boundary( \b ) anchor only when it's effective #689
    startBoundary = if /^\w/.test(text) then "\\b" else ''
    endBoundary = if /\w$/.test(text) then "\\b" else ''
    pattern = startBoundary + pattern + endBoundary
  new RegExp(pattern, 'g')

getSubwordPatternAtBufferPosition = (editor, point, options={}) ->
  options = {wordRegex: editor.getLastCursor().subwordRegExp(), boundarizeForWord: false}
  getWordPatternAtBufferPosition(editor, point, options)

# Return options used for getWordBufferRangeAtBufferPosition
buildWordPatternByCursor = (cursor, {wordRegex}) ->
  nonWordCharacters = getNonWordCharactersForCursor(cursor)
  wordRegex ?= new RegExp("^[\t ]*$|[^\\s#{_.escapeRegExp(nonWordCharacters)}]+")
  {wordRegex, nonWordCharacters}

getBeginningOfWordBufferPosition = (editor, point, {wordRegex}={}) ->
  scanRange = [[point.row, 0], point]

  found = null
  editor.backwardsScanInBufferRange wordRegex, scanRange, ({range, matchText, stop}) ->
    return if matchText is '' and range.start.column isnt 0

    if range.start.isLessThan(point)
      if range.end.isGreaterThanOrEqual(point)
        found = range.start
      stop()

  found ? point

getEndOfWordBufferPosition = (editor, point, {wordRegex}={}) ->
  scanRange = [point, [point.row, Infinity]]

  found = null
  editor.scanInBufferRange wordRegex, scanRange, ({range, matchText, stop}) ->
    return if matchText is '' and range.start.column isnt 0

    if range.end.isGreaterThan(point)
      if range.start.isLessThanOrEqual(point)
        found = range.end
      stop()

  found ? point

getWordBufferRangeAtBufferPosition = (editor, position, options={}) ->
  endPosition = getEndOfWordBufferPosition(editor, position, options)
  startPosition = getBeginningOfWordBufferPosition(editor, endPosition, options)
  new Range(startPosition, endPosition)

# When range is linewise range, range end have column 0 of NEXT row.
# Which is very unintuitive and unwanted result.
shrinkRangeEndToBeforeNewLine = (range) ->
  {start, end} = range
  if end.column is 0
    endRow = limitNumber(end.row - 1, min: start.row)
    new Range(start, [endRow, Infinity])
  else
    range

scanEditor = (editor, pattern) ->
  ranges = []
  editor.scan pattern, ({range}) ->
    ranges.push(range)
  ranges

collectRangeInBufferRow = (editor, row, pattern) ->
  ranges = []
  scanRange = editor.bufferRangeForBufferRow(row)
  editor.scanInBufferRange pattern, scanRange, ({range}) ->
    ranges.push(range)
  ranges

findRangeInBufferRow = (editor, pattern, row, {direction}={}) ->
  if direction is 'backward'
    scanFunctionName = 'backwardsScanInBufferRange'
  else
    scanFunctionName = 'scanInBufferRange'

  range = null
  scanRange = editor.bufferRangeForBufferRow(row)
  editor[scanFunctionName] pattern, scanRange, (event) -> range = event.range
  range

getLargestFoldRangeContainsBufferRow = (editor, row) ->
  markers = editor.displayLayer.foldsMarkerLayer.findMarkers(intersectsRow: row)

  startPoint = null
  endPoint = null

  for marker in markers ? []
    {start, end} = marker.getRange()
    unless startPoint
      startPoint = start
      endPoint = end
      continue

    if start.isLessThan(startPoint)
      startPoint = start
      endPoint = end

  if startPoint? and endPoint?
    new Range(startPoint, endPoint)

# take bufferPosition
translatePointAndClip = (editor, point, direction) ->
  point = Point.fromObject(point)

  dontClip = false
  switch direction
    when 'forward'
      point = point.translate([0, +1])
      eol = editor.bufferRangeForBufferRow(point.row).end

      if point.isEqual(eol)
        dontClip = true
      else if point.isGreaterThan(eol)
        dontClip = true
        point = new Point(point.row + 1, 0) # move point to new-line selected point

      point = Point.min(point, editor.getEofBufferPosition())

    when 'backward'
      point = point.translate([0, -1])

      if point.column < 0
        dontClip = true
        newRow = point.row - 1
        eol = editor.bufferRangeForBufferRow(newRow).end
        point = new Point(newRow, eol.column)

      point = Point.max(point, Point.ZERO)

  if dontClip
    point
  else
    screenPoint = editor.screenPositionForBufferPosition(point, clipDirection: direction)
    editor.bufferPositionForScreenPosition(screenPoint)

getRangeByTranslatePointAndClip = (editor, range, which, direction) ->
  newPoint = translatePointAndClip(editor, range[which], direction)
  switch which
    when 'start'
      new Range(newPoint, range.end)
    when 'end'
      new Range(range.start, newPoint)

getPackage = (name, fn) ->
  new Promise (resolve) ->
    if atom.packages.isPackageActive(name)
      pkg = atom.packages.getActivePackage(name)
      resolve(pkg)
    else
      disposable = atom.packages.onDidActivatePackage (pkg) ->
        if pkg.name is name
          disposable.dispose()
          resolve(pkg)

searchByProjectFind = (editor, text) ->
  atom.commands.dispatch(editor.element, 'project-find:show')
  getPackage('find-and-replace').then (pkg) ->
    {projectFindView} = pkg.mainModule
    if projectFindView?
      projectFindView.findEditor.setText(text)
      projectFindView.confirm()

limitNumber = (number, {max, min}={}) ->
  number = Math.min(number, max) if max?
  number = Math.max(number, min) if min?
  number

findRangeContainsPoint = (ranges, point) ->
  for range in ranges when range.containsPoint(point)
    return range
  null

negateFunction = (fn) ->
  (args...) ->
    not fn(args...)

isEmpty = (target) -> target.isEmpty()
isNotEmpty = negateFunction(isEmpty)

isSingleLineRange = (range) -> range.isSingleLine()
isNotSingleLineRange = negateFunction(isSingleLineRange)

isLeadingWhiteSpaceRange = (editor, range) -> /^[\t ]*$/.test(editor.getTextInBufferRange(range))
isNotLeadingWhiteSpaceRange = negateFunction(isLeadingWhiteSpaceRange)

isEscapedCharRange = (editor, range) ->
  range = Range.fromObject(range)
  chars = getLeftCharacterForBufferPosition(editor, range.start, 2)
  chars.endsWith('\\') and not chars.endsWith('\\\\')

insertTextAtBufferPosition = (editor, point, text) ->
  editor.setTextInBufferRange([point, point], text)

ensureEndsWithNewLineForBufferRow = (editor, row) ->
  unless isEndsWithNewLineForBufferRow(editor, row)
    eol = getEndOfLineForBufferRow(editor, row)
    insertTextAtBufferPosition(editor, eol, "\n")

modifyClassList = (action, element, classNames...) ->
  element.classList[action](classNames...)

addClassList = modifyClassList.bind(null, 'add')
removeClassList = modifyClassList.bind(null, 'remove')
toggleClassList = modifyClassList.bind(null, 'toggle')

toggleCaseForCharacter = (char) ->
  charLower = char.toLowerCase()
  if charLower is char
    char.toUpperCase()
  else
    charLower

splitTextByNewLine = (text) ->
  if text.endsWith("\n")
    text.trimRight().split(/\r?\n/g)
  else
    text.split(/\r?\n/g)

replaceDecorationClassBy = (fn, decoration) ->
  props = decoration.getProperties()
  decoration.setProperties(_.defaults({class: fn(props.class)}, props))

# Modify range used for undo/redo flash highlight to make it feel naturally for human.
#  - Trim starting new line("\n")
#     "\nabc" -> "abc"
#  - If range.end is EOL extend range to first column of next line.
#     "abc" -> "abc\n"
# e.g.
# - when 'c' is atEOL: "\nabc" -> "abc\n"
# - when 'c' is NOT atEOL: "\nabc" -> "abc"
#
# So always trim initial "\n" part range because flashing trailing line is counterintuitive.
humanizeBufferRange = (editor, range) ->
  if isSingleLineRange(range) or isLinewiseRange(range)
    return range

  {start, end} = range
  if pointIsAtEndOfLine(editor, start)
    newStart = start.traverse([1, 0])

  if pointIsAtEndOfLine(editor, end)
    newEnd = end.traverse([1, 0])

  if newStart? or newEnd?
    new Range(newStart ? start, newEnd ? end)
  else
    range

# Expand range to white space
#  1. Expand to forward direction, if suceed return new range.
#  2. Expand to backward direction, if succeed return new range.
#  3. When faild to expand either direction, return original range.
expandRangeToWhiteSpaces = (editor, range) ->
  {start, end} = range

  newEnd = null
  scanRange = [end, getEndOfLineForBufferRow(editor, end.row)]
  editor.scanInBufferRange /\S/, scanRange, ({range}) -> newEnd = range.start

  if newEnd?.isGreaterThan(end)
    return new Range(start, newEnd)

  newStart = null
  scanRange = [[start.row, 0], range.start]
  editor.backwardsScanInBufferRange /\S/, scanRange, ({range}) -> newStart = range.end

  if newStart?.isLessThan(start)
    return new Range(newStart, end)

  return range # fallback

# Split and join after mutate item by callback with keep original separator unchanged.
#
# 1. Trim leading and trainling white spaces and remember
# 1. Split text with given pattern and remember original separators.
# 2. Change order by callback
# 3. Join with original spearator and concat with remembered leading and trainling white spaces.
#
splitAndJoinBy = (text, pattern, fn) ->
  leadingSpaces = trailingSpaces = ''
  start = text.search(/\S/)
  end = text.search(/\s*$/)
  leadingSpaces = trailingSpaces = ''
  leadingSpaces = text[0...start] if start isnt -1
  trailingSpaces = text[end...] if end isnt -1
  text = text[start...end]

  flags = 'g'
  flags += 'i' if pattern.ignoreCase
  regexp = new RegExp("(#{pattern.source})", flags)
  # e.g.
  # When text = "a, b, c", pattern = /,?\s+/
  #   items = ['a', 'b', 'c'], spearators = [', ', ', ']
  # When text = "a b\n c", pattern = /,?\s+/
  #   items = ['a', 'b', 'c'], spearators = [' ', '\n ']
  items = []
  separators = []
  for segment, i in text.split(regexp)
    if i % 2 is 0
      items.push(segment)
    else
      separators.push(segment)
  separators.push('')
  items = fn(items)
  result = ''
  for [item, separator] in _.zip(items, separators)
    result += item + separator
  leadingSpaces + result + trailingSpaces

class ArgumentsSplitter
  constructor: ->
    @allTokens = []
    @currentSection = null

  settlePending: ->
    if @pendingToken
      @allTokens.push({text: @pendingToken, type: @currentSection})
      @pendingToken = ''

  changeSection: (newSection) ->
    if @currentSection isnt newSection
      @settlePending() if @currentSection
      @currentSection = newSection

splitArguments = (text, joinSpaceSeparatedToken) ->
  joinSpaceSeparatedToken ?= true
  separatorChars = "\t, \r\n"
  quoteChars = "\"'`"
  closeCharToOpenChar = {
    ")": "("
    "}": "{"
    "]": "["
  }
  closePairChars = _.keys(closeCharToOpenChar).join('')
  openPairChars = _.values(closeCharToOpenChar).join('')
  escapeChar = "\\"

  pendingToken = ''
  inQuote = false
  isEscaped = false
  # Parse text as list of tokens which is commma separated or white space separated.
  # e.g. 'a, fun1(b, c), d' => ['a', 'fun1(b, c), 'd']
  # Not perfect. but far better than simple string split by regex pattern.
  allTokens = []
  currentSection = null

  settlePending = ->
    if pendingToken
      allTokens.push({text: pendingToken, type: currentSection})
      pendingToken = ''

  changeSection = (newSection) ->
    if currentSection isnt newSection
      settlePending() if currentSection
      currentSection = newSection

  pairStack = []
  for char in text
    if (pairStack.length is 0) and (char in separatorChars)
      changeSection('separator')
    else
      changeSection('argument')
      if isEscaped
        isEscaped = false
      else if char is escapeChar
        isEscaped = true
      else if inQuote
        if (char in quoteChars) and _.last(pairStack) is char
          pairStack.pop()
          inQuote = false
      else if char in quoteChars
        inQuote = true
        pairStack.push(char)
      else if char in openPairChars
        pairStack.push(char)
      else if char in closePairChars
        pairStack.pop() if _.last(pairStack) is closeCharToOpenChar[char]

    pendingToken += char
  settlePending()

  if joinSpaceSeparatedToken and allTokens.some(({type, text}) -> type is 'separator' and ',' in text)
    # When some separator contains `,` treat white-space separator is just part of token.
    # So we move white-space only sparator into tokens by joining mis-separatoed tokens.
    newAllTokens = []
    while allTokens.length
      token = allTokens.shift()
      switch token.type
        when 'argument'
          newAllTokens.push(token)
        when 'separator'
          if ',' in token.text
            newAllTokens.push(token)
          else
            # 1. Concatnate white-space-separator and next-argument
            # 2. Then join into latest argument
            lastArg = newAllTokens.pop() ? {text: '', 'argument'}
            lastArg.text += token.text + (allTokens.shift()?.text ? '') # concat with next-argument
            newAllTokens.push(lastArg)
    allTokens = newAllTokens
  allTokens

scanEditorInDirection = (editor, direction, pattern, options={}, fn) ->
  {allowNextLine, from, scanRange} = options
  if not from? and not scanRange?
    throw new Error("You must either of 'from' or 'scanRange' options")

  if scanRange
    allowNextLine = true
  else
    allowNextLine ?= true
  from = Point.fromObject(from) if from?
  switch direction
    when 'forward'
      scanRange ?= new Range(from, getVimEofBufferPosition(editor))
      scanFunction = 'scanInBufferRange'
    when 'backward'
      scanRange ?= new Range([0, 0], from)
      scanFunction = 'backwardsScanInBufferRange'

  editor[scanFunction] pattern, scanRange, (event) ->
    if not allowNextLine and event.range.start.row isnt from.row
      event.stop()
      return
    fn(event)

adjustIndentWithKeepingLayout = (editor, range) ->
  # Adjust indentLevel with keeping original layout of pasting text.
  # Suggested indent level of range.start.row is correct as long as range.start.row have minimum indent level.
  # But when we paste following already indented three line text, we have to adjust indent level
  #  so that `varFortyTwo` line have suggestedIndentLevel.
  #
  #        varOne: value # suggestedIndentLevel is determined by this line
  #   varFortyTwo: value # We need to make final indent level of this row to be suggestedIndentLevel.
  #      varThree: value
  #
  # So what we are doing here is apply suggestedIndentLevel with fixing issue above.
  # 1. Determine minimum indent level among pasted range(= range ) excluding empty row
  # 2. Then update indentLevel of each rows to final indentLevel of minimum-indented row have suggestedIndentLevel.
  suggestedLevel = editor.suggestedIndentForBufferRow(range.start.row)
  minLevel = null
  rowAndActualLevels = []
  for row in [range.start.row...range.end.row]
    actualLevel = getIndentLevelForBufferRow(editor, row)
    rowAndActualLevels.push([row, actualLevel])
    unless isEmptyRow(editor, row)
      minLevel = Math.min(minLevel ? Infinity, actualLevel)

  if minLevel? and (deltaToSuggestedLevel = suggestedLevel - minLevel)
    for [row, actualLevel] in rowAndActualLevels
      newLevel = actualLevel + deltaToSuggestedLevel
      editor.setIndentationForBufferRow(row, newLevel)

# Check point containment with end position exclusive
rangeContainsPointWithEndExclusive = (range, point) ->
  range.start.isLessThanOrEqual(point) and
    range.end.isGreaterThan(point)

traverseTextFromPoint = (point, text) ->
  point.traverse(getTraversalForText(text))

getTraversalForText = (text) ->
  row = 0
  column = 0
  for char in text
    if char is "\n"
      row++
      column = 0
    else
      column++
  [row, column]


# Return endRow of fold if row was folded or just return passed row.
getFoldEndRowForRow = (editor, row) ->
  if editor.isFoldedAtBufferRow(row)
    getLargestFoldRangeContainsBufferRow(editor, row).end.row
  else
    row

module.exports = {
  assertWithException
  getAncestors
  getKeyBindingForCommand
  include
  debug
  saveEditorState
  isLinewiseRange
  sortRanges
  getIndex
  getVisibleBufferRange
  getVisibleEditors
  pointIsAtEndOfLine
  pointIsOnWhiteSpace
  pointIsAtEndOfLineAtNonEmptyRow
  pointIsAtVimEndOfFile
  getVimEofBufferPosition
  getVimEofScreenPosition
  getVimLastBufferRow
  getVimLastScreenRow
  setBufferRow
  setBufferColumn
  moveCursorLeft
  moveCursorRight
  moveCursorUpScreen
  moveCursorDownScreen
  getEndOfLineForBufferRow
  getFirstVisibleScreenRow
  getLastVisibleScreenRow
  getValidVimBufferRow
  getValidVimScreenRow
  moveCursorToFirstCharacterAtRow
  getLineTextToBufferPosition
  getIndentLevelForBufferRow
  getTextInScreenRange
  moveCursorToNextNonWhitespace
  isEmptyRow
  getCodeFoldRowRanges
  getCodeFoldRowRangesContainesForRow
  getFoldRowRangesContainedByFoldStartsAtRow
  getFoldRowRanges
  getFoldRangesWithIndent
  getFoldInfoByKind
  getBufferRangeForRowRange
  trimRange
  getFirstCharacterPositionForBufferRow
  isIncludeFunctionScopeForRow
  detectScopeStartPositionForScope
  getBufferRows
  smartScrollToBufferPosition
  matchScopes
  isSingleLineText
  getWordBufferRangeAtBufferPosition
  getWordBufferRangeAndKindAtBufferPosition
  getWordPatternAtBufferPosition
  getSubwordPatternAtBufferPosition
  getNonWordCharactersForCursor
  shrinkRangeEndToBeforeNewLine
  scanEditor
  collectRangeInBufferRow
  findRangeInBufferRow
  getLargestFoldRangeContainsBufferRow
  translatePointAndClip
  getRangeByTranslatePointAndClip
  getPackage
  searchByProjectFind
  limitNumber
  findRangeContainsPoint

  isEmpty, isNotEmpty
  isSingleLineRange, isNotSingleLineRange

  insertTextAtBufferPosition
  ensureEndsWithNewLineForBufferRow
  isLeadingWhiteSpaceRange
  isNotLeadingWhiteSpaceRange
  isEscapedCharRange

  addClassList
  removeClassList
  toggleClassList
  toggleCaseForCharacter
  splitTextByNewLine
  replaceDecorationClassBy
  humanizeBufferRange
  expandRangeToWhiteSpaces
  splitAndJoinBy
  splitArguments
  scanEditorInDirection
  adjustIndentWithKeepingLayout
  rangeContainsPointWithEndExclusive
  traverseTextFromPoint
  getFoldEndRowForRow
}
