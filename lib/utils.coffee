# Refactoring status: 100%
fs = require 'fs-plus'
settings = require './settings'
{Range} = require 'atom'

module.exports =
  # Include module(object which normaly provides set of methods) to klass
  include: (klass, module) ->
    for key, value of module
      klass::[key] = value

  debug: (msg) ->
    return unless settings.get('debug')
    msg += "\n"
    if settings.get('debugOutput') is 'console'
      console.log msg
    else
      filePath = fs.normalize("~/sample.log")
      fs.appendFileSync filePath, msg

  selectLines: (selection, rowRange=null) ->
    {editor} = selection
    [startRow, endRow] = if rowRange? then rowRange else selection.getBufferRowRange()
    range = editor.bufferRangeForBufferRow(startRow, includeNewline: true)
    range = range.union(editor.bufferRangeForBufferRow(endRow, includeNewline: true))
    selection.setBufferRange(range)

  getNonBlankCharPositionForRow: (editor, row) ->
    scanRange = editor.bufferRangeForBufferRow(row)
    point = null
    editor.scanInBufferRange /^[ \t]*/, scanRange, ({range}) ->
      point = range.end.translate([0, +1])
    point

  # Return function to restore editor's scrollTop and fold state.
  saveEditorState: (editor) ->
    scrollTop = editor.getScrollTop()
    foldStartRows = editor.displayBuffer.findFoldMarkers().map (m) ->
      editor.displayBuffer.foldForMarker(m).getStartRow()
    ->
      for row in foldStartRows.reverse() when not editor.isFoldedAtBufferRow(row)
        editor.foldBufferRow row
      editor.setScrollTop scrollTop

  getKeystrokeForEvent: (event) ->
    keyboardEvent = event.originalEvent.originalEvent ? event.originalEvent
    atom.keymaps.keystrokeForKeyboardEvent(keyboardEvent)

  getVisibleBufferRange: (editor) ->
    [startRow, endRow] = editor.getVisibleRowRange().map (row) ->
      editor.bufferRowForScreenRow row
    new Range([startRow, 0], [endRow, Infinity])
