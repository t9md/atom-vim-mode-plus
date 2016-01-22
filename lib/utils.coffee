# Refactoring status: 100%
fs = require 'fs-plus'
settings = require './settings'
{Range, Point} = require 'atom'
_ = require 'underscore-plus'

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

getNonBlankCharPositionForRow = (editor, row) ->
  scanRange = editor.bufferRangeForBufferRow(row)
  point = null
  editor.scanInBufferRange /^[ \t]*/, scanRange, ({range}) ->
    point = range.end.translate([0, +1])
  point

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

isLinewiseRange = (range) ->
  (not range.isEmpty()) and (range.start.column is 0) and (range.end.column is 0)

rangeToBeginningOfFileFromPoint = (point) ->
  new Range(Point.ZERO, point)

rangeToEndOfFileFromPoint = (point) ->
  new Range(point, Point.INFINITY)

haveSomeSelection = (editor) ->
  editor.getSelections().some((selection) -> not selection.isEmpty())

sortRanges = (ranges) ->
  ranges.sort((a, b) -> a.compare(b))

# return adjusted index fit whitin length
# return -1 if list is empty.
getIndex = (index, list) ->
  return -1 unless list.length
  index = index % list.length
  if (index >= 0) then index else (list.length + index)

getVisibleBufferRange = (editor) ->
  [startRow, endRow] = getView(editor).getVisibleRowRange().map (row) ->
    editor.bufferRowForScreenRow row
  new Range([startRow, 0], [endRow, Infinity])

# NOTE: depending on getVisibleRowRange
selectVisibleBy = (editor, entries, fn) ->
  range = getVisibleBufferRange(editor)
  (e for e in entries when range.containsRange(fn(e)))

eachSelection = (editor, fn) ->
  for selection in editor.getSelections()
    fn(selection)

toggleClassByCondition = (element, klass, condition) ->
  action = (if condition then 'add' else 'remove')
  element.classList[action](klass)

# This uses private APIs and may break if TextBuffer is refactored.
# Package authors - copy and paste this code at your own risk.
getChangesSinceCheckpoint = (editor, checkpoint) ->
  {history} = editor.getBuffer()
  if (index = history.getCheckpointIndex(checkpoint))?
    history.undoStack.slice(index)
  else
    []

# Takes a transaction and turns it into a string of what was typed.
# This class is an implementation detail of ActivateInsertMode
# Return final newRanges from changes
distanceForRange = ({start, end}) ->
  row = end.row - start.row
  column = end.column - start.column
  new Point(row, column)

getNewTextRangeFromChanges = (changes) ->
  finalRange = null
  for change in changes when change.newRange?
    {oldRange, oldText, newRange, newText} = change
    unless finalRange?
      finalRange = newRange.copy() if newText.length
      continue
    # shrink
    if oldText.length and finalRange.containsRange(oldRange)
      amount = oldRange
      diff = distanceForRange(amount)
      diff.column = 0 unless (amount.end.row is finalRange.end.row)
      finalRange.end = finalRange.end.translate(diff.negate())
    # extend
    if newText.length and finalRange.containsPoint(newRange.start)
      amount = newRange
      diff = distanceForRange(amount)
      diff.column = 0 unless (amount.start.row is finalRange.end.row)
      finalRange.end = finalRange.end.translate(diff)
  finalRange

getNewTextRangeFromCheckpoint = (editor, checkpoint) ->
  changes = getChangesSinceCheckpoint(editor, checkpoint)
  getNewTextRangeFromChanges(changes)

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

getEolBufferPositionForCursor = (cursor) ->
  getEolBufferPositionForRow(cursor.editor, cursor.getBufferRow())

pointIsAtEndOfLine = (editor, point) ->
  point = Point.fromObject(point)
  getEolBufferPositionForRow(editor, point.row).isEqual(point)

characterAtBufferPosition = (editor, point) ->
  range = Range.fromPointWithDelta(point, 0, 1)
  editor.getTextInBufferRange(range)

characterAtScreenPosition = (editor, point) ->
  screenRange = Range.fromPointWithDelta(point, 0, 1)
  range = editor.bufferRangeForScreenRange(screenRange)
  editor.getTextInBufferRange(range)

getTextAtCursor = (cursor) ->
  {editor} = cursor
  bufferRange = editor.bufferRangeForScreenRange(cursor.getScreenRange())
  editor.getTextInBufferRange(bufferRange)

getTextInScreenRange = (editor, screenRange) ->
  bufferRange = editor.bufferRangeForScreenRange(screenRange)
  editor.getTextInBufferRange(bufferRange)

cursorIsOnWhiteSpace = (cursor) ->
  isAllWhiteSpace(getTextAtCursor(cursor))

# return true is moved
moveCursorToNextNonWhitespace = (cursor) ->
  originalPoint = cursor.getBufferPosition()
  while cursorIsOnWhiteSpace(cursor) and (not cursorIsAtVimEndOfFile(cursor))
    cursor.moveRight()
  not originalPoint.isEqual(cursor.getBufferPosition())

getBufferRows = (editor, {startRow, direction, includeStartRow}) ->
  unless includeStartRow
    startRow += (if direction is 'next' then +1 else -1)

  endRow = switch direction
    when 'previous' then 0
    when 'next' then getVimLastBufferRow(editor)
  [getValidVimBufferRow(editor, startRow)..endRow]

# Return Vim's EOF position rather than Atom's EOF position.
# This function change meaning of EOF from native TextEditor::getEofBufferPosition()
# Atom is special(strange) for cursor can past very last newline character.
# Because of this, Atom's EOF position is [actualLastRow+1, 0] provided last-non-blank-row
# ends with newline char.
# But in Vim, curor can NOT past last newline. EOF is next position of very last character.
getVimEofBufferPosition = (editor) ->
  row = editor.getLastBufferRow()
  if editor.bufferRangeForBufferRow(row).isEmpty()
    getEolBufferPositionForRow(editor, Math.max(0, row - 1))
  else
    editor.getEofBufferPosition()

pointIsAtVimEndOfFile = (editor, point) ->
  getVimEofBufferPosition(editor).isEqual(point)

cursorIsAtVimEndOfFile = (cursor) ->
  pointIsAtVimEndOfFile(cursor.editor, cursor.getBufferPosition())

cursorIsAtEmptyRow = (cursor) ->
  cursor.isAtBeginningOfLine() and cursor.isAtEndOfLine()

getVimLastBufferRow = (editor) ->
  getVimEofBufferPosition(editor).row

getVimEofScreenPosition = (editor) ->
  editor.screenPositionForBufferPosition(getVimEofBufferPosition(editor))

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
    null

cursorIsAtFirstCharacter = (cursor) ->
  {editor} = cursor
  column = cursor.getBufferColumn()
  firstCharColumn = getFirstCharacterColumForBufferRow(editor, cursor.getBufferRow())
  firstCharColumn? and column is firstCharColumn

# Cursor motion wrapper
# -------------------------
moveCursor = (cursor, {preserveGoalColumn}, fn) ->
  {goalColumn} = cursor
  fn(cursor)
  if preserveGoalColumn and goalColumn
    cursor.goalColumn = goalColumn

# options:
#   allowWrap: to controll allow wrap
#   preserveGoalColumn: preserve original goalColumn
moveCursorLeft = (cursor, options={}) ->
  {allowWrap} = options
  delete options.allowWrap
  if not cursor.isAtBeginningOfLine() or allowWrap
    moveCursor cursor, options, (cursor) ->
      cursor.moveLeft()

moveCursorRight = (cursor, options={}) ->
  {allowWrap} = options
  delete options.allowWrap
  if not cursor.isAtEndOfLine() or allowWrap
    moveCursor cursor, options, (cursor) ->
      cursor.moveRight()

moveCursorUp = (cursor, options={}) ->
  unless cursor.getScreenRow() is 0
    moveCursor cursor, options, (cursor) ->
      cursor.moveUp()

moveCursorDown = (cursor, options={}) ->
  unless getVimLastScreenRow(cursor.editor) is cursor.getScreenRow()
    moveCursor cursor, options, (cursor) ->
      cursor.moveDown()

moveCursorToFirstCharacterAtRow = (cursor, row) ->
  cursor.setBufferPosition([row, 0])
  cursor.moveToFirstCharacterOfLine()

unfoldAtCursorRow = (cursor) ->
  {editor} = cursor
  row = cursor.getBufferRow()
  if editor.isFoldedAtBufferRow(row)
    editor.unfoldBufferRow row

markerOptions = {ivalidate: 'never', persistent: false}
flashRanges = (ranges, options) ->
  ranges = [ranges] unless _.isArray(ranges)
  return unless ranges.length

  {editor} = options
  markers = (editor.markBufferRange(r, markerOptions) for r in ranges)

  decorationOptions = {type: 'highlight', class: options.class}
  editor.decorateMarker(m, decorationOptions) for m in markers

  setTimeout  ->
    m.destroy() for m in markers
  , options.timeout

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

# Compensate lack of ternaly operator
# e.g.
#  pick(['1st', '2nd'], true)  # => '1st'
#  pick(['1st', '2nd'], false) # => '2nd'
pick = (choice, boolean) ->
  if boolean
    choice[0]
  else
    choice[1]

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

detectScopeStartPositionByScope = (editor, fromPoint, direction, scope) ->
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

# Debugging purpose
# -------------------------
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

# Return function to restore original start position.
preserveSelectionStartPoints = (editor) ->
  rangeBySelection = new Map
  for selection in editor.getSelections()
    rangeBySelection.set(selection, selection.getBufferRange())

  (selection) ->
    point = rangeBySelection.get(selection).start
    selection.cursor.setBufferPosition(point)

module.exports = {
  include
  debug
  getNonBlankCharPositionForRow
  getView
  saveEditorState
  getKeystrokeForEvent
  getCharacterForEvent
  isLinewiseRange
  rangeToBeginningOfFileFromPoint
  rangeToEndOfFileFromPoint
  haveSomeSelection
  sortRanges
  getIndex
  getVisibleBufferRange
  selectVisibleBy
  eachSelection
  toggleClassByCondition
  getNewTextRangeFromCheckpoint
  findIndex
  mergeIntersectingRanges
  pointIsAtEndOfLine
  pointIsAtVimEndOfFile
  cursorIsAtVimEndOfFile
  characterAtBufferPosition
  characterAtScreenPosition
  getVimEofBufferPosition
  getVimEofScreenPosition
  getVimLastBufferRow
  getVimLastScreenRow
  moveCursorLeft
  moveCursorRight
  moveCursorUp
  moveCursorDown
  unfoldAtCursorRow
  getEolBufferPositionForRow
  getEolBufferPositionForCursor
  getFirstVisibleScreenRow
  getLastVisibleScreenRow
  flashRanges
  getValidVimBufferRow
  getValidVimScreenRow
  moveCursorToFirstCharacterAtRow
  countChar
  pick
  clipScreenPositionForBufferPosition
  getTextToPoint
  getTextFromPointToEOL
  getIndentLevelForBufferRow
  isAllWhiteSpace
  getTextAtCursor
  getTextInScreenRange
  cursorIsOnWhiteSpace
  moveCursorToNextNonWhitespace
  cursorIsAtEmptyRow
  getCodeFoldRowRanges
  getCodeFoldRowRangesContainesForRow
  getBufferRangeForRowRange
  getFirstCharacterColumForBufferRow
  cursorIsAtFirstCharacter
  isFunctionScope
  isIncludeFunctionScopeForRow
  getTokenizedLineForRow
  getScopesForTokenizedLine
  scanForScopeStart
  detectScopeStartPositionByScope
  getBufferRows
  preserveSelectionStartPoints

  # Debugging
  reportSelection,
  reportCursor
  withTrackingCursorPositionChange
}
