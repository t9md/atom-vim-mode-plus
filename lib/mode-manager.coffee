# Refactoring status: 20%
_ = require 'underscore-plus'
{VisualBlockwise} = require './visual-blockwise'
{Range} = require 'atom'
module.exports =
class ModeManager
  mode: null

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState

  isNormalMode: ->
    @mode is 'normal'

  isInsertMode: ->
    @mode is 'insert'

  isOperatorPendingMode: ->
    @mode is 'operator-pending'

  isVisualMode: (submode=null) ->
    if submode
      @mode is 'visual' and @submode is submode
    else
      @mode is 'visual'

  setMode: (@mode, @submode=null) ->
    for mode in ['normal', 'insert', 'visual', 'operator-pending']
      @editorElement.classList.remove "#{mode}-mode"
    @editorElement.classList.add "#{@mode}-mode"
    for submode in ['characterwise', 'linewise', 'blockwise']
      @editorElement.classList.remove submode
    if @submode
      @editorElement.classList.add @submode

  activateNormalMode: ->
    @deactivateInsertMode()
    @deactivateVisualMode()
    @vimState.reset()
    @setMode('normal')

    @vimState.operationStack.clear()
    for selection in @editor.getSelections()
      selection.clear(autoscroll: false)
    for cursor in @editor.getCursors()
      if cursor.isAtEndOfLine() and not cursor.isAtBeginningOfLine()
        cursor.moveLeft()
    @updateStatusBar()

  activateInsertMode: (submode=null) ->
    @setMode('insert', submode)
    @updateStatusBar()
    @editorElement.component.setInputEnabled(true)
    @setInsertionCheckpoint()

  activateReplaceMode: ->
    @activateInsertMode('replace')
    @editorElement.classList.add('replace-mode')

    @replaceModeCounter = 0
    @vimState.subscriptions.add @replaceModeListener = @editor.onWillInsertText @replaceModeInsertHandler
    @vimState.subscriptions.add @replaceModeUndoListener = @editor.onDidInsertText @replaceModeUndoHandler

  replaceModeInsertHandler: (event) =>
    chars = event.text?.split('') or []
    selections = @editor.getSelections()
    for char in chars
      continue if char is '\n'
      for selection in selections
        selection.delete() unless selection.cursor.isAtEndOfLine()
    return

  replaceModeUndoHandler: (event) =>
    @replaceModeCounter++

  replaceModeUndo: ->
    if @replaceModeCounter > 0
      @editor.undo()
      @editor.undo()
      @editor.moveLeft()
      @replaceModeCounter--

  setInsertionCheckpoint: ->
    @insertionCheckpoint ?= @editor.createCheckpoint()

  deactivateInsertMode: ->
    return unless @mode in [null, 'insert']
    @editorElement.component.setInputEnabled(false)
    @editorElement.classList.remove('replace-mode')
    @editor.groupChangesSinceCheckpoint(@insertionCheckpoint)
    changes = getChangesSinceCheckpoint(@editor.buffer, @insertionCheckpoint)
    @insertionCheckpoint = null
    if (item = @vimState.history[0]) and item.isInsert()
      item.confirmChanges(changes)
    for cursor in @editor.getCursors() when not cursor.isAtBeginningOfLine()
      cursor.moveLeft()
    if @replaceModeListener?
      @replaceModeListener.dispose()
      @vimState.subscriptions.remove @replaceModeListener
      @replaceModeListener = null
      @replaceModeUndoListener.dispose()
      @vimState.subscriptions.remove @replaceModeUndoListener
      @replaceModeUndoListener = null

  deactivateVisualMode: ->
    return unless @isVisualMode()
    {lastOperation} = @vimState
    restoreColumn = not (lastOperation?.isYank() or lastOperation?.isIndent())
    if restoreColumn and @submode is 'linewise'
      @selectCharacterwise()
    for s in @editor.getSelections() when not (s.isEmpty() or s.isReversed())
      s.cursor.moveLeft()

  # Private: Used to enable visual mode.
  #
  # submode - One of 'characterwise', 'linewise' or 'blockwise'
  #
  # Returns nothing.
  activateVisualMode: (submode) ->
    if @isVisualMode(submode)
      @activateNormalMode()
      return

    # [FIXME] comment out to evaluate necessity.
    # Since I can't understand why this is necessary.
    # unless @isVisualMode()
    #   @deactivateInsertMode()

    switch submode
      when 'linewise' then @selectLinewise()
      when 'characterwise' then @selectCharacterwise()
      when 'blockwise' then @selectBlockwise()
    @setMode('visual', submode)
    @updateStatusBar()

  selectLinewise: ->
    unless @isVisualMode('characterwise')
      @selectCharacterwise()

    # Keep original range as marker's property to restore column.
    for selection in @editor.getSelections()
      originalRange = selection.getBufferRange()
      selection.marker.setProperties({originalRange})
      for row in selection.getBufferRowRange()
        selection.selectLine(row)
    @vimState.hideCursor()

  # Private:
  selectCharacterwise: ->
    if @editor.getLastSelection().isEmpty()
      @editor.selectRight()
      return

    # [FIXME] could be simplified further if we improve
    #  handling of START_ROW, revesed state ofvisual-blockwise.coffee.
    if @isVisualMode('blockwise')
      selections = @editor.getSelectionsOrderedByBufferPosition()
      startRow   = _.first(selections).getBufferRowRange()[0]
      endRow     = _.last(selections).getBufferRowRange()[0]
      selection = @editor.getLastSelection()
      range = selection.getBufferRange()
      range.start.row = startRow
      range.end.row = endRow
      @editor.setSelectedBufferRange(range)
    else
      for selection in @editor.getSelections()
        {originalRange} = selection.marker.getProperties()
        if originalRange
          [startRow, endRow] = selection.getBufferRowRange()
          originalRange.start.row = startRow
          originalRange.end.row   = endRow
          selection.setBufferRange(originalRange)

  selectBlockwise: ->
    unless @isVisualMode('characterwise')
      @selectCharacterwise()

    for selection in @editor.getSelections()
      tail = selection.getTailBufferPosition()
      head = selection.getHeadBufferPosition()
      {start, end} = selection.getBufferRange()
      range = new Range(tail, [tail.row, head.column])
      if start.column >= end.column
        range = range.translate([0, -1], [0, +1])
      selection.setBufferRange(range)
      direction = if selection.isReversed() then 'Above' else 'Below'
      _.times (end.row - start.row), =>
        @editor["addSelection#{direction}"]()
      VisualBlockwise.setStartRow(tail.row)
    @vimState.hideCursor()
    @vimState.syncSelectionsReversedSate(head.column < tail.column)

  # Private: Used to re-enable visual mode
  resetVisualMode: ->
    @activateVisualMode(@submode)

  # Private: Used to enable operator-pending mode.
  activateOperatorPendingMode: ->
    @deactivateInsertMode()
    @setMode('operator-pending')
    @updateStatusBar()

  # Private: Resets the normal mode back to it's initial state.
  #
  # Returns nothing.
  resetNormalMode: ->
    @vimState.operationStack.clear()
    @editor.clearSelections()
    @activateNormalMode()

  updateStatusBar: ->
    @vimState.statusBarManager.update(@mode, @submode)

# This uses private APIs and may break if TextBuffer is refactored.
# Package authors - copy and paste this code at your own risk.
getChangesSinceCheckpoint = (buffer, checkpoint) ->
  {history} = buffer

  if (index = history.getCheckpointIndex(checkpoint))?
    history.undoStack.slice(index)
  else
    []
