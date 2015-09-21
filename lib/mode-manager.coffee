# Refactoring status: 20%
_ = require 'underscore-plus'
{selectLines, debug} = require './utils'
{BlockwiseSelect, BlockwiseRestoreCharacterwise} = require './visual-blockwise'
{Range} = require 'atom'

module.exports =
class ModeManager
  mode: null

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState

  isMode: (mode, submode=null) ->
    if submode
      submode = [submode] if _.isString(submode)
      @mode is mode and (@submode in submode)
    else
      @mode is mode

  setMode: (@mode, @submode=null) ->
    for mode in ['normal', 'insert', 'visual', 'operator-pending']
      @editorElement.classList.remove "#{mode}-mode"
    @editorElement.classList.add "#{@mode}-mode"
    for submode in ['characterwise', 'linewise', 'blockwise', 'replace']
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
    @editorElement.classList.remove('replace')
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
    return unless @isMode('visual')
    {lastOperation} = @vimState
    restoreColumn = not (lastOperation?.isYank() or lastOperation?.isIndent())
    if restoreColumn and @isMode('visual', 'linewise')
      @selectCharacterwise()
    for s in @editor.getSelections() when not (s.isEmpty() or s.isReversed())
      s.cursor.moveLeft()

  activateVisualMode: (submode) ->
    if @isMode('visual', submode)
      @activateNormalMode()
      return

    # [FIXME] comment out to evaluate necessity.
    # Since I can't understand why this is necessary.
    # unless @isMode('visual')
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
      selectLines(selection)
    @hideCursors()

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

  # resetVisualMode: ->
  #   @activateVisualMode(@submode)

  activateOperatorPendingMode: ->
    @deactivateInsertMode()
    @setMode('operator-pending')

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
