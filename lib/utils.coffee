fs = require 'fs-plus'
settings = require './settings'

{Disposable, Range, Point} = require 'atom'
_ = require 'underscore-plus'

getParent = (obj) ->
  obj.__super__?.constructor

getAncestors = (obj) ->
  ancestors = []
  current = obj
  loop
    ancestors.push(current)
    current = getParent(current)
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
      filePath = fs.normalize settings.get('debugOutputFilePath')
      if fs.existsSync(filePath)
        fs.appendFileSync filePath, messages + "\n"

# Return function to restore editor's scrollTop and fold state.
saveEditorState = (editor) ->
  editorElement = editor.element
  scrollTop = editorElement.getScrollTop()

  foldStartRows = editor.displayLayer.findFoldMarkers({}).map (m) -> m.getStartPosition().row
  ->
    for row in foldStartRows.reverse() when not editor.isFoldedAtBufferRow(row)
      editor.foldBufferRow(row)
    editorElement.setScrollTop(scrollTop)

# Return function to restore cursor position
# When restoring, removed cursors are ignored.
saveCursorPositions = (editor) ->
  points = new Map
  for cursor in editor.getCursors()
    points.set(cursor, cursor.getBufferPosition())
  ->
    for cursor in editor.getCursors() when points.has(cursor)
      point = points.get(cursor)
      cursor.setBufferPosition(point)

getKeystrokeForEvent = (event) ->
  keyboardEvent = event.originalEvent.originalEvent ? event.originalEvent
  atom.keymaps.keystrokeForKeyboardEvent(keyboardEvent)

keystrokeToCharCode =
  backspace: 8
  tab: 9
  enter: 13
  escape: 27
  space: 32
  delete: 127

getCharacterForEvent = (event) ->
  keystroke = getKeystrokeForEvent(event)
  if charCode = keystrokeToCharCode[keystroke]
    String.fromCharCode(charCode)
  else
    keystroke

isLinewiseRange = ({start, end}) ->
  (start.row isnt end.row) and (start.column is end.column is 0)

isEndsWithNewLineForBufferRow = (editor, row) ->
  {start, end} = editor.bufferRangeForBufferRow(row, includeNewline: true)
  (not start.isEqual(end)) and end.column is 0

haveSomeNonEmptySelection = (editor) ->
  editor.getSelections().some (selection) ->
    not selection.isEmpty()

sortRanges = (ranges) ->
  ranges.sort((a, b) -> a.compare(b))

sortRangesByEndPosition = (ranges, fn) ->
  ranges.sort((a, b) -> a.end.compare(b.end))

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

withVisibleBufferRange = (editor, fn) ->
  if range = getVisibleBufferRange(editor)
    fn(range)
  else
    disposable = editor.element.onDidAttach ->
      disposable.dispose()
      range = getVisibleBufferRange(editor)
      fn(range)

# NOTE: endRow become undefined if @editorElement is not yet attached.
# e.g. Beging called immediately after open file.
getVisibleBufferRange = (editor) ->
  [startRow, endRow] = editor.element.getVisibleRowRange()
  return null unless (startRow? and endRow?)
  startRow = editor.bufferRowForScreenRow(startRow)
  endRow = editor.bufferRowForScreenRow(endRow)
  new Range([startRow, 0], [endRow, Infinity])

getVisibleEditors = ->
  for pane in atom.workspace.getPanes() when editor = pane.getActiveEditor()
    editor

# char can be regExp pattern
countChar = (string, char) ->
  string.split(char).length - 1

findIndexBy = (list, fn) ->
  for item, i in list when fn(item)
    return i
  null

mergeIntersectingRanges = (ranges) ->
  result = []
  for range, i in ranges
    if index = findIndexBy(result, (r) -> r.intersectsWith(range))
      result[index] = result[index].union(range)
    else
      result.push(range)
  result

getEndOfLineForBufferRow = (editor, row) ->
  editor.bufferRangeForBufferRow(row).end

pointIsAtEndOfLine = (editor, point) ->
  point = Point.fromObject(point)
  getEndOfLineForBufferRow(editor, point.row).isEqual(point)

getCharacterAtCursor = (cursor) ->
  getTextInScreenRange(cursor.editor, cursor.getScreenRange())

getCharacterAtBufferPosition = (editor, startPosition) ->
  endPosition = startPosition.translate([0, 1])
  editor.getTextInBufferRange([startPosition, endPosition])

getTextInScreenRange = (editor, screenRange) ->
  bufferRange = editor.bufferRangeForScreenRange(screenRange)
  editor.getTextInBufferRange(bufferRange)

cursorIsOnWhiteSpace = (cursor) ->
  isAllWhiteSpace(getCharacterAtCursor(cursor))

pointIsOnWhiteSpace = (editor, point) ->
  isAllWhiteSpace(getCharacterAtBufferPosition(editor, point))

screenPositionIsAtWhiteSpace = (editor, screenPosition) ->
  screenRange = Range.fromPointWithDelta(screenPosition, 0, 1)
  char = getTextInScreenRange(editor, screenRange)
  char? and /\S/.test(char)

getNonWordCharactersForCursor = (cursor) ->
  # Atom 1.11.0-beta5 have this experimental method.
  if cursor.getNonWordCharacters?
    cursor.getNonWordCharacters()
  else
    scope = cursor.getScopeDescriptor().getScopesArray()
    atom.config.get('editor.nonWordCharacters', {scope})

# return true if moved
moveCursorToNextNonWhitespace = (cursor) ->
  originalPoint = cursor.getBufferPosition()
  vimEof = getVimEofBufferPosition(cursor.editor)
  while cursorIsOnWhiteSpace(cursor) and not cursor.getBufferPosition().isGreaterThanOrEqual(vimEof)
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
      vimLastBufferRow = getVimLastBufferRow(editor)
      if startRow >= vimLastBufferRow
        []
      else
        [(startRow + 1)..vimLastBufferRow]

getParagraphBoundaryRow = (editor, startRow, direction, fn) ->
  wasAtNonBlankRow = not editor.isBufferRowBlank(startRow)
  for row in getBufferRows(editor, {startRow, direction})
    isAtNonBlankRow = not editor.isBufferRowBlank(row)
    if wasAtNonBlankRow isnt isAtNonBlankRow
      if fn?
        return row if fn?(isAtNonBlankRow)
      else
        return row
    wasAtNonBlankRow = isAtNonBlankRow

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

pointIsAtVimEndOfFile = (editor, point) ->
  getVimEofBufferPosition(editor).isEqual(point)

cursorIsAtVimEndOfFile = (cursor) ->
  pointIsAtVimEndOfFile(cursor.editor, cursor.getBufferPosition())

isEmptyRow = (editor, row) ->
  editor.bufferRangeForBufferRow(row).isEmpty()

cursorIsAtEmptyRow = (cursor) ->
  isEmptyRow(cursor.editor, cursor.getBufferRow())

cursorIsAtEndOfLineAtNonEmptyRow = (cursor) ->
  cursor.isAtEndOfLine() and not cursor.isAtBeginningOfLine()

getVimLastBufferRow = (editor) ->
  getVimEofBufferPosition(editor).row

getVimLastScreenRow = (editor) ->
  getVimEofScreenPosition(editor).row

getFirstVisibleScreenRow = (editor) ->
  editor.element.getFirstVisibleScreenRow()

getLastVisibleScreenRow = (editor) ->
  editor.element.getLastVisibleScreenRow()

getFirstCharacterColumForBufferRow = (editor, row) ->
  text = editor.lineTextForBufferRow(row)
  if (column = text.search(/\S/)) >= 0
    column
  else
    0

trimRange = (editor, scanRange) ->
  pattern = /\S/
  [start, end] = []
  setStart = ({range}) -> {start} = range
  editor.scanInBufferRange(pattern, scanRange, setStart)
  if start?
    setEnd = ({range}) -> {end} = range
    editor.backwardsScanInBufferRange(pattern, scanRange, setEnd)
    new Range(start, end)
  else
    scanRange

getFirstCharacterPositionForBufferRow = (editor, row) ->
  from = [row, 0]
  getEndPositionForPattern(editor, from, /\s*/, containedOnly: true) or from

getFirstCharacterBufferPositionForScreenRow = (editor, screenRow) ->
  start = editor.clipScreenPosition([screenRow, 0], skipSoftWrapIndentation: true)
  end = [screenRow, Infinity]
  scanRange = editor.bufferRangeForScreenRange([start, end])

  point = null
  editor.scanInBufferRange /\S/, scanRange, ({range, stop}) ->
    point = range.start
    stop()
  point ? scanRange.start

cursorIsAtFirstCharacter = (cursor) ->
  {editor} = cursor
  column = cursor.getBufferColumn()
  firstCharColumn = getFirstCharacterColumForBufferRow(editor, cursor.getBufferRow())
  column is firstCharColumn

# Cursor motion wrapper
# -------------------------
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

# FIXME
moveCursorDownBuffer = (cursor) ->
  point = cursor.getBufferPosition()
  unless getVimLastBufferRow(cursor.editor) is point.row
    cursor.setBufferPosition(point.translate([+1, 0]))

# FIXME
moveCursorUpBuffer = (cursor) ->
  point = cursor.getBufferPosition()
  unless point.row is 0
    cursor.setBufferPosition(point.translate([-1, 0]))

moveCursorToFirstCharacterAtRow = (cursor, row) ->
  cursor.setBufferPosition([row, 0])
  cursor.moveToFirstCharacterOfLine()

# Return markers
highlightRanges = (editor, ranges, options) ->
  ranges = [ranges] unless _.isArray(ranges)
  return null unless ranges.length

  invalidate = options.invalidate ? 'never'
  markers = (editor.markBufferRange(range, {invalidate}) for range in ranges)

  decorateOptions = {type: 'highlight', class: options.class}
  editor.decorateMarker(marker, decorateOptions) for marker in markers

  {timeout} = options
  if timeout?
    destroyMarkers = -> _.invoke(markers, 'destroy')
    setTimeout(destroyMarkers, timeout)
  markers

highlightRange = (editor, range, options) ->
  highlightRanges(editor, [range], options)[0]

# Return valid row from 0 to vimLastBufferRow
getValidVimBufferRow = (editor, row) ->
  vimLastBufferRow = getVimLastBufferRow(editor)
  switch
    when (row < 0) then 0
    when (row > vimLastBufferRow) then vimLastBufferRow
    else row

# Return valid row from 0 to vimLastScreenRow
getValidVimScreenRow = (editor, row) ->
  vimLastScreenRow = getVimLastScreenRow(editor)
  switch
    when (row < 0) then 0
    when (row > vimLastScreenRow) then vimLastScreenRow
    else row

# By default not include column
getTextToPoint = (editor, {row, column}, {exclusive}={}) ->
  exclusive ?= true
  if exclusive
    editor.lineTextForBufferRow(row)[0...column]
  else
    editor.lineTextForBufferRow(row)[0..column]

getIndentLevelForBufferRow = (editor, row) ->
  text = editor.lineTextForBufferRow(row)
  editor.indentLevelForLine(text)

WhiteSpaceRegExp = /^\s*$/
isAllWhiteSpace = (text) ->
  WhiteSpaceRegExp.test(text)

getCodeFoldRowRanges = (editor) ->
  [0..editor.getLastBufferRow()]
    .map (row) ->
      editor.languageMode.rowRangeForCodeFoldAtBufferRow(row)
    .filter (rowRange) ->
      rowRange? and rowRange[0]? and rowRange[1]?

# * `exclusive` to exclude startRow to determine inclusion.
getCodeFoldRowRangesContainesForRow = (editor, bufferRow, {includeStartRow}={}) ->
  includeStartRow ?= true
  getCodeFoldRowRanges(editor).filter ([startRow, endRow]) ->
    if includeStartRow
      startRow <= bufferRow <= endRow
    else
      startRow < bufferRow <= endRow

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
  {scopeName} = editor.getGrammar()
  switch scopeName
    when 'source.go'
      /^entity\.name\.function/.test(scope)
    else
      /^meta\.function\./.test(scope)

getStartPositionForPattern = (editor, from, pattern, options={}) ->
  from = Point.fromObject(from)
  containedOnly = options.containedOnly ? false
  scanRange = [[from.row, 0], from]
  point = null
  editor.backwardsScanInBufferRange pattern, scanRange, ({range, matchText, stop}) ->
    # Ignore 'empty line' matches between '\r' and '\n'
    return if matchText is '' and range.start.column isnt 0

    if (not containedOnly) or range.end.isGreaterThanOrEqual(from)
      point = range.start
      stop()
  point

getEndPositionForPattern = (editor, from, pattern, options={}) ->
  from = Point.fromObject(from)
  containedOnly = options.containedOnly ? false
  scanRange = [from, [from.row, Infinity]]
  point = null
  editor.scanInBufferRange pattern, scanRange, ({range, matchText, stop}) ->
    # Ignore 'empty line' matches between '\r' and '\n'
    return if matchText is '' and range.start.column isnt 0

    if (not containedOnly) or range.start.isLessThanOrEqual(from)
      point = range.end
      stop()
  point

getBufferRangeForPatternFromPoint = (editor, fromPoint, pattern) ->
  end = getEndPositionForPattern(editor, fromPoint, pattern, containedOnly: true)
  start = getStartPositionForPattern(editor, end, pattern, containedOnly: true) if end?
  new Range(start, end) if start?

sortComparable = (collection) ->
  collection.sort (a, b) -> a.compare(b)

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

isSingleLine = (text) ->
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
  if not wordRegex? and not nonWordCharacters? # Complement from cursor
    cursor ?= editor.getLastCursor()
    {wordRegex, nonWordCharacters} = _.extend(options, buildWordPatternByCursor(cursor, options))
  singleNonWordChar ?= false

  characterAtPoint = getCharacterAtBufferPosition(editor, point)
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
  {range, kind} = getWordBufferRangeAndKindAtBufferPosition(editor, point, options)
  pattern = _.escapeRegExp(editor.getTextInBufferRange(range))
  if kind is 'word'
    pattern = "\\b" + pattern + "\\b"
  new RegExp(pattern, 'g')

# Return options used for getWordBufferRangeAtBufferPosition
buildWordPatternByCursor = (cursor, {wordRegex}) ->
  nonWordCharacters = getNonWordCharactersForCursor(cursor)
  wordRegex ?= new RegExp("^[\t ]*$|[^\\s#{_.escapeRegExp(nonWordCharacters)}]+")
  {wordRegex, nonWordCharacters}

getCurrentWordBufferRangeAndKind = (cursor, options={}) ->
  getWordBufferRangeAndKindAtBufferPosition(cursor.editor, cursor.getBufferPosition(), options)

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
  startPosition = getBeginningOfWordBufferPosition(editor, position, options)
  endPosition = getEndOfWordBufferPosition(editor, startPosition, options)
  new Range(startPosition, endPosition)

adjustRangeToRowRange = ({start, end}, options={}) ->
  # when linewise, end row is at column 0 of NEXT line
  # So need adjust to actually selected row in same way as Seleciton::getBufferRowRange()
  endRow = end.row
  if end.column is 0
    endRow = Math.max(start.row, end.row - 1)
  if options.endOnly ? false
    new Range(start, [endRow, Infinity])
  else
    new Range([start.row, 0], [endRow, Infinity])

# When range is linewise range, range end have column 0 of NEXT row.
# Which is very unintuitive and unwanted result.
shrinkRangeEndToBeforeNewLine = (range) ->
  {start, end} = range
  if end.column is 0
    endRow = Math.max(start.row, end.row - 1)
    new Range(start, [endRow, Infinity])
  else
    range

scanInRanges = (editor, pattern, scanRanges, {includeIntersects, exclusiveIntersects}={}) ->
  if includeIntersects
    originalScanRanges = scanRanges.slice()

    # We need to scan each whole row to find intersects.
    scanRanges = scanRanges.map(adjustRangeToRowRange)
    isIntersects = ({range, scanRange}) ->
      # exclusiveIntersects set true in visual-mode
      scanRange.intersectsWith(range, exclusiveIntersects)

  ranges = []
  for scanRange, i in scanRanges
    editor.scanInBufferRange pattern, scanRange, ({range}) ->
      if includeIntersects
        if isIntersects({range, scanRange: originalScanRanges[i]})
          ranges.push(range)
      else
        ranges.push(range)
  ranges

scanEditor = (editor, pattern) ->
  ranges = []
  editor.scan pattern, ({range}) ->
    ranges.push(range)
  ranges

isRangeContainsSomePoint = (range, points, {exclusive}={}) ->
  exclusive ?= false
  points.some (point) ->
    range.containsPoint(point, exclusive)

destroyNonLastSelection = (editor) ->
  for selection in editor.getSelections() when not selection.isLastSelection()
    selection.destroy()

getLargestFoldRangeContainsBufferRow = (editor, row) ->
  markers = editor.displayLayer.findFoldMarkers(intersectsRow: row)

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

translatePointAndClip = (editor, point, direction, {translate}={}) ->
  translate ?= true
  point = Point.fromObject(point)

  dontClip = false
  switch direction
    when 'forward'
      point = point.translate([0, +1]) if translate
      eol = editor.bufferRangeForBufferRow(point.row).end

      if point.isEqual(eol)
        dontClip = true

      if point.isGreaterThan(eol)
        point = new Point(point.row + 1, 0)
        dontClip = true

      point = Point.min(point, editor.getEofBufferPosition())

    when 'backward'
      point = point.translate([0, -1]) if translate

      if point.column < 0
        newRow = point.row - 1
        eol = editor.bufferRangeForBufferRow(newRow).end
        point = new Point(newRow, eol.column)

      point = Point.max(point, Point.ZERO)

  if dontClip
    point
  else
    screenPoint = editor.screenPositionForBufferPosition(point, clipDirection: direction)
    editor.bufferPositionForScreenPosition(screenPoint)

getRangeByTranslatePointAndClip = (editor, range, which, direction, options) ->
  newPoint = translatePointAndClip(editor, range[which], direction, options)
  switch which
    when 'start'
      new Range(newPoint, range.end)
    when 'end'
      new Range(range.start, newPoint)

# Reloadable registerElement
registerElement = (name, options) ->
  element = document.createElement(name)
  # if constructor is HTMLElement, we haven't registerd yet
  if element.constructor is HTMLElement
    Element = document.registerElement(name, options)
  else
    Element = element.constructor
    Element.prototype = options.prototype if options.prototype?
  Element

module.exports = {
  getParent
  getAncestors
  getKeyBindingForCommand
  include
  debug
  saveEditorState
  saveCursorPositions
  getKeystrokeForEvent
  getCharacterForEvent
  isLinewiseRange
  isEndsWithNewLineForBufferRow
  haveSomeNonEmptySelection
  sortRanges
  sortRangesByEndPosition
  getIndex
  getVisibleBufferRange
  withVisibleBufferRange
  getVisibleEditors
  findIndexBy
  mergeIntersectingRanges
  pointIsAtEndOfLine
  pointIsAtVimEndOfFile
  cursorIsAtVimEndOfFile
  getVimEofBufferPosition
  getVimEofScreenPosition
  getVimLastBufferRow
  getVimLastScreenRow
  moveCursorLeft
  moveCursorRight
  moveCursorUpScreen
  moveCursorDownScreen
  getEndOfLineForBufferRow
  getFirstVisibleScreenRow
  getLastVisibleScreenRow
  highlightRanges
  highlightRange
  getValidVimBufferRow
  getValidVimScreenRow
  moveCursorToFirstCharacterAtRow
  countChar
  getTextToPoint
  getIndentLevelForBufferRow
  isAllWhiteSpace
  getCharacterAtCursor
  getTextInScreenRange
  cursorIsOnWhiteSpace
  screenPositionIsAtWhiteSpace
  moveCursorToNextNonWhitespace
  isEmptyRow
  cursorIsAtEmptyRow
  cursorIsAtEndOfLineAtNonEmptyRow
  getCodeFoldRowRanges
  getCodeFoldRowRangesContainesForRow
  getBufferRangeForRowRange
  getFirstCharacterColumForBufferRow
  trimRange
  getFirstCharacterPositionForBufferRow
  getFirstCharacterBufferPositionForScreenRow
  cursorIsAtFirstCharacter
  isFunctionScope
  getStartPositionForPattern
  getEndPositionForPattern
  isIncludeFunctionScopeForRow
  getTokenizedLineForRow
  getScopesForTokenizedLine
  scanForScopeStart
  detectScopeStartPositionForScope
  getBufferRows
  getParagraphBoundaryRow
  registerElement
  getBufferRangeForPatternFromPoint
  sortComparable
  smartScrollToBufferPosition
  matchScopes
  moveCursorDownBuffer
  moveCursorUpBuffer
  isSingleLine
  getCurrentWordBufferRangeAndKind
  buildWordPatternByCursor
  getWordBufferRangeAtBufferPosition
  getWordBufferRangeAndKindAtBufferPosition
  getWordPatternAtBufferPosition
  getNonWordCharactersForCursor
  adjustRangeToRowRange
  shrinkRangeEndToBeforeNewLine
  scanInRanges
  scanEditor
  isRangeContainsSomePoint
  destroyNonLastSelection
  getLargestFoldRangeContainsBufferRow
  translatePointAndClip
  getRangeByTranslatePointAndClip
}
