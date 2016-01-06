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
  tab:       9
  enter:     13
  escape:    27
  space:     32
  delete:    127

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

haveSomeSelection = (selections) ->
  selections.some((s) -> not s.isEmpty())

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
  for s in editor.getSelections()
    fn(s)

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

characterAtPoint = (editor, point) ->
  range = Range.fromPointWithDelta(point, 0, 1)
  char = editor.getTextInBufferRange(range)

getTextAtCursor = (cursor) ->
  {editor} = cursor
  bufferRange = editor.bufferRangeForScreenRange(cursor.getScreenRange())
  editor.getTextInBufferRange(bufferRange)

cursorIsOnWhiteSpace = (cursor) ->
  isAllWhiteSpace(getTextAtCursor(cursor))

# return true is moved
moveCursorToNextNonWhitespace = (cursor) ->
  originalPoint = cursor.getBufferPosition()
  while cursorIsOnWhiteSpace(cursor) and (not cursorIsAtVimEndOfFile(cursor))
    cursor.moveRight()
  not originalPoint.isEqual(cursor.getBufferPosition())

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
    moveCursor cursor, options, (c) ->
      c.moveLeft()

moveCursorRight = (cursor, options={}) ->
  {allowWrap} = options
  delete options.allowWrap
  if not cursor.isAtEndOfLine() or allowWrap
    moveCursor cursor, options, (c) ->
      c.moveRight()

moveCursorUp = (cursor, options={}) ->
  unless cursor.getScreenRow() is 0
    moveCursor cursor, options, (c) ->
      cursor.moveUp()

moveCursorDown = (cursor, options={}) ->
  unless getVimLastScreenRow(cursor.editor) is cursor.getScreenRow()
    moveCursor cursor, options, (c) ->
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
getValidVimRow = (editor, row) ->
  vimLastBufferRow = getVimLastBufferRow(editor)
  switch
    when (row < 0) then 0
    when (row > vimLastBufferRow) then vimLastBufferRow
    else row

# Compensate lack of ternaly operator
# e.g. pick(['one', 'two'], true) get 'one'
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
  characterAtPoint
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
  getValidVimRow
  moveCursorToFirstCharacterAtRow
  countChar
  pick
  clipScreenPositionForBufferPosition
  getTextToPoint
  getTextFromPointToEOL
  getIndentLevelForBufferRow
  isAllWhiteSpace
  getTextAtCursor
  cursorIsOnWhiteSpace
  moveCursorToNextNonWhitespace
  cursorIsAtEmptyRow
}
