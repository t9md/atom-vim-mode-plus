# Grim  = require 'grim'

module.exports =
class ModeManager
  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState

  isNormalMode: ->
    @vimState.mode is 'normal'

  isInsertMode: ->
    @vimState.mode is 'insert'

  isOperatorPendingMode: ->
    @vimState.mode is 'operator-pending'

  isVisualMode: ->
    @vimState.mode is 'visual'

  isVisualCharacterwiseMode: ->
    @vimState.mode is 'visual' and @vimState.submode is 'characterwise'

  isVisualBlockwiseMode: ->
    @vimState.mode is 'visual' and @vimState.submode is 'blockwise'

  isVisualLinewiseMode: ->
    @vimState.mode is 'visual' and @vimState.submode is 'linewise'


  setMode: (mode, submode=null) ->
    @vimState.mode = mode
    @vimState.submode = submode
    modes = ['normal', 'insert', 'visual', 'operator-pending']

    for _mode in modes
      @editorElement.classList.remove "#{_mode}-mode"
    @editorElement.classList.add "#{mode}-mode"

  activateNormalMode: ->
    @deactivateInsertMode()
    @deactivateVisualMode()
    @setMode('normal')

    @vimState.operationStack.clear()
    for selection in @editor.getSelections()
      selection.clear(autoscroll: false)
    for cursor in @editor.getCursors()
      if cursor.isAtEndOfLine() and not cursor.isAtBeginningOfLine()
        cursor.moveLeft()
    @updateStatusBar()

  activateCommandMode: ->
    Grim.deprecate("Use ::activateNormalMode instead")
    @activateNormalMode()

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
    unless @insertionCheckpoint?
      @insertionCheckpoint = @editor.createCheckpoint()

  deactivateInsertMode: ->
    return unless @vimState.mode in [null, 'insert']
    @editorElement.component.setInputEnabled(false)
    @editorElement.classList.remove('replace-mode')
    @editor.groupChangesSinceCheckpoint(@insertionCheckpoint)
    changes = getChangesSinceCheckpoint(@editor.buffer, @insertionCheckpoint)
    item = @inputOperator(@vimState.history[0])
    @insertionCheckpoint = null
    if item?
      item.confirmChanges(changes)
    for cursor in @editor.getCursors()
      cursor.moveLeft() unless cursor.isAtBeginningOfLine()
    if @replaceModeListener?
      @replaceModeListener.dispose()
      @vimState.subscriptions.remove @replaceModeListener
      @replaceModeListener = null
      @replaceModeUndoListener.dispose()
      @vimState.subscriptions.remove @replaceModeUndoListener
      @replaceModeUndoListener = null

  deactivateVisualMode: ->
    return unless @isVisualMode()
    for selection in @editor.getSelections()
      selection.cursor.moveLeft() unless (selection.isEmpty() or selection.isReversed())

  # Private: Get the input operator that needs to be told about about the
  # typed undo transaction in a recently completed operation, if there
  # is one.
  inputOperator: (item) ->
    return item unless item?
    return item if item.inputOperator?()

    # FIXME maybe code below can remove.
    return item.composedObject if item.composedObject?.inputOperator?()

  # Private: Used to enable visual mode.
  #
  # submode - One of 'characterwise', 'linewise' or 'blockwise'
  #
  # Returns nothing.
  activateVisualMode: (submode) ->
    # Already in 'visual', this means one of following command is
    # executed within `vim-mode.visual-mode`
    #  * activate-blockwise-visual-mode
    #  * activate-characterwise-visual-mode
    #  * activate-linewise-visual-mode
    if @isVisualMode()
      if @vimState.submode is submode
        @activateNormalMode()
        return

      @vimState.submode = submode
      if @vimState.submode is 'linewise'
        for selection in @editor.getSelections()
          # Keep original range as marker's property to get back
          # to characterwise.
          # Since selectLine lost original cursor column.
          originalRange = selection.getBufferRange()
          selection.marker.setProperties({originalRange})
          [start, end] = selection.getBufferRowRange()
          selection.selectLine(row) for row in [start..end]

      else if @vimState.submode in ['characterwise', 'blockwise']
        # Currently, 'blockwise' is not yet implemented.
        # So treat it as characterwise.
        # Recover original range.
        for selection in @editor.getSelections()
          {originalRange} = selection.marker.getProperties()
          if originalRange
            [startRow, endRow] = selection.getBufferRowRange()
            originalRange.start.row = startRow
            originalRange.end.row   = endRow
            selection.setBufferRange(originalRange)
    else
      @deactivateInsertMode()
      @setMode('visual', submode)

      if @vimState.submode is 'linewise'
        @editor.selectLinesContainingCursors()
      else if @editor.getSelectedText() is ''
        @editor.selectRight()
    @updateStatusBar()

  # Private: Used to re-enable visual mode
  resetVisualMode: ->
    @activateVisualMode(@vimState.submode)

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
    @vimState.statusBarManager.update(@vimState.mode, @vimState.submode)

# This uses private APIs and may break if TextBuffer is refactored.
# Package authors - copy and paste this code at your own risk.
getChangesSinceCheckpoint = (buffer, checkpoint) ->
  {history} = buffer

  if (index = history.getCheckpointIndex(checkpoint))?
    history.undoStack.slice(index)
  else
    []
