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

getLineTextToPoint = (editor, point) ->
  editor.lineTextForBufferRow(point.row)[0..point.column]

eachSelection = (editor, fn) ->
  for s in editor.getSelections()
    fn(s)

withKeepingGoalColumn = (cursor, fn) ->
  {goalColumn} = cursor
  fn(cursor)
  cursor.goalColumn = goalColumn if goalColumn

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

pointIsAtEndOfLine = (editor, point) ->
  editor.bufferRangeForBufferRow(point.row).end.isEqual(point)

pointIsAtEndOfBuffer = (editor, point) ->
  point.isEqual(editor.getEofBufferPosition())

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
  getLineTextToPoint
  eachSelection
  withKeepingGoalColumn
  toggleClassByCondition
  getNewTextRangeFromCheckpoint
  findIndex
  mergeIntersectingRanges
  pointIsAtEndOfLine
  pointIsAtEndOfBuffer
}
