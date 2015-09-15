# Refactoring status: 20%
_ = require 'underscore-plus'
{BlockwiseSelect, BlockwiseRestoreCharacterwise} = require './visual-blockwise'
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
    @vimState.statusBarManager.update(@mode, @submode)

  activateNormalMode: ->
    @deactivateInsertMode()
    @deactivateVisualMode()
    @vimState.reset()
    @setMode('normal')

    @vimState.operationStack.clear()
    selection.clear(autoscroll: false) for selection in @editor.getSelections()
    for cursor in @editor.getCursors() when cursor.isAtEndOfLine()
      unless cursor.isAtBeginningOfLine()
        cursor.moveLeft()

  activateInsertMode: (submode=null) ->
    @setMode('insert', submode)
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

  activateVisualMode: (submode) ->
    if @isVisualMode(submode)
      @activateNormalMode()
      return

    # [FIXME] comment out to evaluate necessity.
    # Since I can't understand why this is necessary.
    # unless @isVisualMode()
    #   @deactivateInsertMode()

    oldSubmode = @submode
    # [NOTE] following operation depend operationStack
    # So @setMode at first is important since operationStack do
    # special cursor treatment depending on current mode.
    @setMode('visual', submode)
    switch submode
      when 'linewise' then @selectLinewise(oldSubmode)
      when 'characterwise' then @selectCharacterwise(oldSubmode)
      when 'blockwise' then @selectBlockwise(oldSubmode)

  selectLinewise: (oldSubmode) ->
    unless oldSubmode is 'characterwise'
      @selectCharacterwise()

    # Keep original range as marker's property to restore column.
    for selection in @editor.getSelections()
      originalRange = selection.getBufferRange()
      selection.marker.setProperties({originalRange})
      for row in selection.getBufferRowRange()
        selection.selectLine(row)
    @hideCursors()

  # Private:
  selectCharacterwise: (oldSubmode) ->
    if @editor.getLastSelection().isEmpty()
      @editor.selectRight()
      return

    if oldSubmode is 'blockwise'
      @vimState.operationStack.push new BlockwiseRestoreCharacterwise(@vimState)
    else
      for selection in @editor.getSelections()
        {originalRange} = selection.marker.getProperties()
        if originalRange
          [startRow, endRow] = selection.getBufferRowRange()
          originalRange.start.row = startRow
          originalRange.end.row   = endRow
          selection.setBufferRange(originalRange)

  selectBlockwise: (oldSubmode) ->
    unless oldSubmode is 'characterwise'
      @selectCharacterwise()
    @vimState.operationStack.push new BlockwiseSelect(@vimState)

  # Private: Used to re-enable visual mode
  resetVisualMode: ->
    @activateVisualMode(@submode)

  # Private: Used to enable operator-pending mode.
  activateOperatorPendingMode: ->
    @deactivateInsertMode()
    @setMode('operator-pending')

  # Private: Resets the normal mode back to it's initial state.
  #
  # Returns nothing.
  resetNormalMode: ->
    @vimState.operationStack.clear()
    @editor.clearSelections()
    @activateNormalMode()

  hideCursors: ->
    for c in @editor.getCursors() when c.isVisible()
      c.setVisible(false)

# This uses private APIs and may break if TextBuffer is refactored.
# Package authors - copy and paste this code at your own risk.
getChangesSinceCheckpoint = (buffer, checkpoint) ->
  {history} = buffer

  if (index = history.getCheckpointIndex(checkpoint))?
    history.undoStack.slice(index)
  else
    []
