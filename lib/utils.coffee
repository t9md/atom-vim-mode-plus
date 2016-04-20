fs = require 'fs-plus'
settings = require './settings'

{Disposable, Range, Point} = require 'atom'
_ = require 'underscore-plus'

getParent = (obj) ->
  obj.__super__?.constructor

getAncestors = (obj) ->
  ancestors = []
  ancestors.push (current=obj)
  while current = getParent(current)
    ancestors.push current
  ancestors

getKeyBindingForCommand = (command, {packageName}) ->
  results = null
  keymaps = atom.keymaps.getKeyBindings()
  if packageName?
    keymapPath = atom.packages.getActivePackage(packageName).getKeymapPaths().pop()
    keymaps = keymaps.filter ({source}) -> source is keymapPath

  for keymap in keymaps when keymap.command is command
    {keystrokes, selector} = keymap
    keystrokes = keystrokes.replace(/shift-/, '')
    (results ?= []).push({keystrokes, selector})
  results

# Include module(object which normaly provides set of methods) to klass
include = (klass, module) ->
  for key, value of module
    klass::[key] = value

debug = (message) ->
  return unless settings.get('debug')
  message += "\n"
  switch settings.get('debugOutput')
    when 'console'
      console.log message
    when 'file'
      filePath = fs.normalize settings.get('debugOutputFilePath')
      if fs.existsSync(filePath)
        fs.appendFileSync filePath, message

getView = (model) ->
  atom.views.getView(model)

# Return function to restore editor's scrollTop and fold state.
saveEditorState = (editor) ->
  editorElement = getView(editor)
  scrollTop = editorElement.getScrollTop()
  foldStartRows = editor.displayBuffer.findFoldMarkers({}).map (m) ->
    editor.displayBuffer.foldForMarker(m).getStartRow()
  ->
    for row in foldStartRows.reverse() when not editor.isFoldedAtBufferRow(row)
      editor.foldBufferRow row
    editorElement.setScrollTop scrollTop

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
  {start, end} = editor.bufferRangeForBufferRow(row, {includeNewline: true})
  end.isGreaterThan(start) and end.column is 0

haveSomeSelection = (editor) ->
  editor.getSelections().some (selection) ->
    not selection.isEmpty()

sortRanges = (ranges) ->
  ranges.sort((a, b) -> a.compare(b))

sortRangesByEndPosition = (ranges, fn) ->
  ranges.sort((a, b) -> a.end.compare(b.end))

# return adjusted index fit whitin length
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
    disposable = getView(editor).onDidAttach ->
      disposable.dispose()
      range = getVisibleBufferRange(editor)
      fn(range)

# NOTE: endRow become undefined if @editorElement is not yet attached.
# e.g. Beging called immediately after open file.
getVisibleBufferRange = (editor) ->
  [startRow, endRow] = getView(editor).getVisibleRowRange()
  return null unless (startRow? and endRow?)
  startRow = editor.bufferRowForScreenRow(startRow)
  endRow = editor.bufferRowForScreenRow(endRow)
  new Range([startRow, 0], [endRow, Infinity])

getVisibleEditors = ->
  for pane in atom.workspace.getPanes() when editor = pane.getActiveEditor()
    editor

eachSelection = (editor, fn) ->
  for selection in editor.getSelections()
    fn(selection)

eachCursor = (editor, fn) ->
  for cursor in editor.getCursors()
    fn(cursor)

bufferPositionForScreenPositionWithoutClip = (editor, screenPosition) ->
  {row, column} = Point.fromObject(screenPosition)
  bufferRow = editor.bufferRowForScreenRow(row)
  bufferColumn = editor.displayBuffer
    .tokenizedLineForScreenRow(row)
    .bufferColumnForScreenColumn(column)
  new Point(bufferRow, bufferColumn)

screenPositionForBufferPositionWithoutClip = (editor, bufferPosition) ->
  {row, column} = Point.fromObject(bufferPosition)
  screenRow = editor.screenRowForBufferRow(row)
  screenColumn = editor.displayBuffer
    .tokenizedLineForScreenRow(row)
    .screenColumnForBufferColumn(column)
  new Point(screenRow, screenColumn)

# [FIXME] Polyfills: Remove after atom/text-buffer is updated
poliyFillsToTextBufferHistory = (history) ->
  Patch = null
  History = history.constructor
  History::getChangesSinceCheckpoint = (checkpointId) ->
    checkpointIndex = null
    patchesSinceCheckpoint = []

    for entry, i in @undoStack by -1
      break if checkpointIndex?

      switch entry.constructor.name
        when 'Checkpoint'
          if entry.id is checkpointId
            checkpointIndex = i
        when 'Transaction'
          Patch ?= entry.patch.constructor
          patchesSinceCheckpoint.unshift(entry.patch)
        when 'Patch'
          Patch ?= entry.constructor
          patchesSinceCheckpoint.unshift(entry)
        else
          throw new Error("Unexpected undo stack entry type: #{entry.constructor.name}")

    if checkpointIndex?
      Patch?.compose(patchesSinceCheckpoint)
    else
      null

normalizePatchChanges = (changes) ->
  changes.map (change) ->
    start: Point.fromObject(change.newStart)
    oldExtent: Point.fromObject(change.oldExtent)
    newExtent: Point.fromObject(change.newExtent)
    newText: change.newText

getNewTextRangeFromCheckpoint = (editor, checkpoint) ->
  {history} = editor.getBuffer()
  range = null
  if patch = history.getChangesSinceCheckpoint(checkpoint)
    # Take only first chage, ignore change by multi-cursor.
    if change = normalizePatchChanges(patch.getChanges()).shift()
      range = new Range(change.start, change.start.traverse(change.newExtent))
  range

# char can be regExp pattern
countChar = (string, char) ->
  string.split(char).length - 1

findIndex = (list, fn) ->
  for e, i in list when fn(e)
    return i
  null

mergeIntersectingRanges = (ranges) ->
  result = []
  for range, i in ranges
    if index = findIndex(result, (r) -> r.intersectsWith(range))
      result[index] = result[index].union(range)
    else
      result.push(range)
  result

getEolBufferPositionForRow = (editor, row) ->
  editor.bufferRangeForBufferRow(row).end

pointIsAtEndOfLine = (editor, point) ->
  point = Point.fromObject(point)
  getEolBufferPositionForRow(editor, point.row).isEqual(point)

getTextAtCursor = (cursor) ->
  {editor} = cursor
  bufferRange = editor.bufferRangeForScreenRange(cursor.getScreenRange())
  editor.getTextInBufferRange(bufferRange)

getTextInScreenRange = (editor, screenRange) ->
  bufferRange = editor.bufferRangeForScreenRange(screenRange)
  editor.getTextInBufferRange(bufferRange)

cursorIsOnWhiteSpace = (cursor) ->
  isAllWhiteSpace(getTextAtCursor(cursor))

getWordRegExpForPointWithCursor = (cursor, point) ->
  options = {}
  if pointIsBetweenWordAndNonWord(cursor.editor, point, cursor.getScopeDescriptor())
    options.includeNonWordCharacters = false
  cursor.wordRegExp(options)

# borrowed from Cursor::isBetweenWordAndNonWord
pointIsBetweenWordAndNonWord = (editor, point, scope) ->
  point = Point.fromObject(point)
  {row, column} = point
  return false if (column is 0) or (pointIsAtEndOfLine(editor, point))
  range = [[row, column - 1], [row, column + 1]]
  [before, after] = editor.getTextInBufferRange(range)
  if /\s/.test(before) or /\s/.test(after)
    false
  else
    nonWordCharacters = atom.config.get('editor.nonWordCharacters', {scope}).split('')
    _.contains(nonWordCharacters, before) isnt _.contains(nonWordCharacters, after)

pointIsSurroundedByWhitespace = (editor, point) ->
  {row, column} = Point.fromObject(point)
  range = [[row, column - 1], [row, column + 1]]
  /^\s+$/.test editor.getTextInBufferRange(range)

# return true if moved
moveCursorToNextNonWhitespace = (cursor) ->
  originalPoint = cursor.getBufferPosition()
  while cursorIsOnWhiteSpace(cursor) and (not cursorIsAtVimEndOfFile(cursor))
    cursor.moveRight()
  not originalPoint.isEqual(cursor.getBufferPosition())

getBufferRows = (editor, {startRow, direction, includeStartRow}) ->
  switch direction
    when 'previous'
      unless includeStartRow
        return [] if startRow is 0
        startRow -= 1 if startRow > 0
      [startRow..0]
    when 'next'
      vimLastBufferRow = getVimLastBufferRow(editor)
      unless includeStartRow
        return [] if startRow is vimLastBufferRow
        startRow += 1 if startRow < vimLastBufferRow
      [startRow..vimLastBufferRow]

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
    getEolBufferPositionForRow(editor, eof.row - 1)

getVimEofScreenPosition = (editor) ->
  editor.screenPositionForBufferPosition(getVimEofBufferPosition(editor))

pointIsAtVimEndOfFile = (editor, point) ->
  getVimEofBufferPosition(editor).isEqual(point)

cursorIsAtVimEndOfFile = (cursor) ->
  pointIsAtVimEndOfFile(cursor.editor, cursor.getBufferPosition())

cursorIsAtEmptyRow = (cursor) ->
  cursor.isAtBeginningOfLine() and cursor.isAtEndOfLine()

getVimLastBufferRow = (editor) ->
  getVimEofBufferPosition(editor).row

getVimLastScreenRow = (editor) ->
  getVimEofScreenPosition(editor).row

getFirstVisibleScreenRow = (editor) ->
  getView(editor).getFirstVisibleScreenRow()

getLastVisibleScreenRow = (editor) ->
  getView(editor).getLastVisibleScreenRow()

getFirstCharacterColumForBufferRow = (editor, row) ->
  text = editor.lineTextForBufferRow(row)
  if (column = text.search(/\S/)) >= 0
    column
  else
    0

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
  if preserveGoalColumn and goalColumn
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

moveCursorUp = (cursor, options={}) ->
  unless cursor.getScreenRow() is 0
    motion = (cursor) -> cursor.moveUp()
    moveCursor(cursor, options, motion)

moveCursorDown = (cursor, options={}) ->
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

markerOptions = {ivalidate: 'never', persistent: false}
# Return markers
highlightRanges = (editor, ranges, options) ->
  ranges = [ranges] unless _.isArray(ranges)
  return null unless ranges.length

  markers = ranges.map (range) ->
    editor.markBufferRange(range, markerOptions)

  for marker in markers
    editor.decorateMarker marker,
      type: 'highlight'
      class: options.class

  {timeout} = options
  if timeout?
    setTimeout  ->
      marker.destroy() for marker in markers
    , timeout
  markers

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

# special {translate} option is used to translate AFTER converting to
# screenPosition
# Since translate in bufferPosition is abondoned when converted to screenPosition.
clipScreenPositionForBufferPosition = (editor, bufferPosition, options) ->
  screenPosition = editor.screenPositionForBufferPosition(bufferPosition)
  {translate} = options
  delete options.translate
  screenPosition = screenPosition.translate(translate) if translate
  editor.clipScreenPosition(screenPosition, options)

# By default not include column
getTextToPoint = (editor, {row, column}, {exclusive}={}) ->
  exclusive ?= true
  if exclusive
    editor.lineTextForBufferRow(row)[0...column]
  else
    editor.lineTextForBufferRow(row)[0..column]

getTextFromPointToEOL = (editor, {row, column}, {exclusive}={}) ->
  exclusive ?= false
  start = column
  start += 1 if exclusive
  editor.lineTextForBufferRow(row)[start..]

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
getCodeFoldRowRangesContainesForRow = (editor, bufferRow, exclusive=false) ->
  getCodeFoldRowRanges(editor).filter ([startRow, endRow]) ->
    if exclusive
      startRow < bufferRow <= endRow
    else
      startRow <= bufferRow <= endRow

getBufferRangeForRowRange = (editor, rowRange) ->
  [rangeStart, rangeEnd] = rowRange.map (row) ->
    editor.bufferRangeForBufferRow(row, includeNewline: true)
  rangeStart.union(rangeEnd)

getTokenizedLineForRow = (editor, row) ->
  editor.displayBuffer.tokenizedBuffer.tokenizedLineForRow(row)

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
      if tag > 0
        column += switch
          when tokenIterator.isHardTab() then 1
          when tokenIterator.isSoftWrapIndentation() then 0
          else tag
      else if (tag % 2 is -1)
        scope = atom.grammars.scopeForId(tag)
        position = new Point(row, column)
        results.push {scope, position, stop}

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

sortComparable = (collection) ->
  collection.sort (a, b) -> a.compare(b)

# Scroll to bufferPosition with minimum amount to keep original visible area.
# If target position won't fit within onePageUp or onePageDown, it center target point.
smartScrollToBufferPosition = (editor, point) ->
  editorElement = getView(editor)
  editorAreaHeight = editor.getLineHeightInPixels() * (editor.getRowsPerPage() - 1)
  onePageUp = editorElement.getScrollTop() - editorAreaHeight # No need to limit to min=0
  onePageDown = editorElement.getScrollBottom() + editorAreaHeight
  target = editorElement.pixelPositionForBufferPosition(point).top

  center = (onePageDown < target) or (target < onePageUp)
  editor.scrollToBufferPosition(point, {center})

# Debugging purpose
# -------------------------
logGoalColumnForSelection = (subject, selection) ->
  console.log "#{subject}: goalColumn = ", selection.cursor.goalColumn

reportSelection = (subject, selection) ->
  console.log subject, selection.getBufferRange().toString()

reportCursor = (subject, cursor) ->
  console.log subject, cursor.getBufferPosition().toString()

withTrackingCursorPositionChange = (cursor, fn) ->
  cursorBefore = cursor.getBufferPosition()
  fn()
  cursorAfter = cursor.getBufferPosition()
  unless cursorBefore.isEqual(cursorAfter)
    console.log "Changed: #{cursorBefore.toString()} -> #{cursorAfter.toString()}"

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

ElementBuilder =
  includeInto: (target) ->
    for name, value of this when name isnt "includeInto"
      target::[name] = value.bind(this)

  div: (params) ->
    @createElement 'div', params

  span: (params) ->
    @createElement 'span', params

  atomTextEditor: (params) ->
    @createElement 'atom-text-editor', params

  createElement: (element, {classList, textContent, id, attribute}) ->
    element = document.createElement element

    element.id = id if id?
    element.classList.add classList... if classList?
    element.textContent = textContent if textContent?
    for name, value of attribute ? {}
      element.setAttribute(name, value)
    element

module.exports = {
  getParent
  getAncestors
  getKeyBindingForCommand
  include
  debug
  getView
  saveEditorState
  getKeystrokeForEvent
  getCharacterForEvent
  isLinewiseRange
  isEndsWithNewLineForBufferRow
  haveSomeSelection
  sortRanges
  sortRangesByEndPosition
  getIndex
  getVisibleBufferRange
  withVisibleBufferRange
  getVisibleEditors
  eachSelection
  eachCursor
  bufferPositionForScreenPositionWithoutClip
  screenPositionForBufferPositionWithoutClip
  getNewTextRangeFromCheckpoint
  findIndex
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
  moveCursorUp
  moveCursorDown
  getEolBufferPositionForRow
  getFirstVisibleScreenRow
  getLastVisibleScreenRow
  highlightRanges
  getValidVimBufferRow
  getValidVimScreenRow
  moveCursorToFirstCharacterAtRow
  countChar
  clipScreenPositionForBufferPosition
  getTextToPoint
  getTextFromPointToEOL
  getIndentLevelForBufferRow
  isAllWhiteSpace
  getTextAtCursor
  getTextInScreenRange
  cursorIsOnWhiteSpace
  getWordRegExpForPointWithCursor
  pointIsBetweenWordAndNonWord
  pointIsSurroundedByWhitespace
  moveCursorToNextNonWhitespace
  cursorIsAtEmptyRow
  getCodeFoldRowRanges
  getCodeFoldRowRangesContainesForRow
  getBufferRangeForRowRange
  getFirstCharacterColumForBufferRow
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
  ElementBuilder
  registerElement
  sortComparable
  smartScrollToBufferPosition
  moveCursorDownBuffer
  moveCursorUpBuffer

  poliyFillsToTextBufferHistory

  # Debugging
  reportSelection,
  reportCursor
  withTrackingCursorPositionChange
  logGoalColumnForSelection
}
