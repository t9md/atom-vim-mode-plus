# Refactoring status: 80%
_ = require 'underscore-plus'
swrap = require './selection-wrapper'
{BlockwiseSelect, BlockwiseRestoreCharacterwise} = require './visual-blockwise'
{Range, CompositeDisposable, Disposable} = require 'atom'

supportedModes = ['normal', 'insert', 'visual', 'operator-pending']
supportedSubModes = ['characterwise', 'linewise', 'blockwise', 'replace']

class ModeManager
  mode: 'insert' # Native atom is not modal editor and its default is 'insert'

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState

  isMode: (mode, submodes) ->
    if submodes?
      submodes = [submodes] unless _.isArray(submodes)
      (@mode is mode) and (@submode in submodes)
    else
      @mode is mode

  activate: (mode, submode=null) ->
    if mode is 'reset'
      @editor.clearSelections()
      mode = 'normal'

    # Deactivate old mode
    if mode isnt @mode
      switch @mode
        when 'insert' then @deactivateInsertMode()
        when 'visual' then @deactivateVisualMode()

    # Activate
    switch mode
      when 'normal' then @activateNormalMode()
      when 'insert' then @activateInsertMode(submode)
      when 'visual'
        return @activate('normal') if @isMode('visual', submode)
        @activateVisualMode(submode)
      when 'operator-pending'
        null # This is just placeholder, nothing to do without updating selector.

    [@mode, @submode] = [mode, submode]
    @vimState.showCursors() if @mode is 'visual'
    @updateModeSelector(mode, submode)
    @vimState.statusBarManager.update(mode, submode)

  updateModeSelector: (mode, submode) ->
    for _mode in supportedModes
      @vimState.updateClassCond(_mode is mode, "#{_mode}-mode")
    for _submode in supportedSubModes
      @vimState.updateClassCond(_submode is submode, _submode)

  # Normal
  # -------------------------
  activateNormalMode: ->
    @vimState.reset()
    @editorElement.component.setInputEnabled(false)

  # Insert
  # -------------------------
  activateInsertMode: (submode=null) ->
    @editorElement.component.setInputEnabled(true)
    @setInsertionCheckpoint()

    if submode is 'replace'
      @replacedCharsBySelection = {}
      @replaceModeSubscriptions ?= new CompositeDisposable

      @replaceModeSubscriptions.add @editor.onWillInsertText ({text, cancel}) =>
        cancel()
        for s in @editor.getSelections()
          for char in text.split('') ? []
            if (char isnt "\n") and (not s.cursor.isAtEndOfLine())
              s.selectRight()
            @replacedCharsBySelection[s.id] ?= []
            @replacedCharsBySelection[s.id].push(swrap(s).replace(char))

      @replaceModeSubscriptions.add new Disposable =>
        @replacedCharsBySelection = null

  deactivateInsertMode: ->
    @editor.groupChangesSinceCheckpoint(@insertionCheckpoint)
    changes = getChangesSinceCheckpoint(@editor.buffer, @insertionCheckpoint)
    @insertionCheckpoint = null
    if (item = @vimState.getLastOperation()) and item.isInsert()
      item.confirmChanges(changes)

    if @submode is 'replace'
      @replaceModeSubscriptions?.dispose()
      @replaceModeSubscriptions = null

    # Adjust cursor position
    for c in @editor.getCursors() when not c.isAtBeginningOfLine()
      c.moveLeft()

  replaceModeBackspace: ->
    for s in @editor.getSelections()
      char = @replacedCharsBySelection[s.id].pop()
      if char? # char maybe empty char ''.
        s.selectLeft()
        unless s.insertText(char).isEmpty()
          s.cursor.moveLeft()

  setInsertionCheckpoint: ->
    @insertionCheckpoint ?= @editor.createCheckpoint()

  # Visual
  # -------------------------
  activateVisualMode: (submode) ->
    # Restern to charwise selection then preserve charwise range.
    if @submode?
      @restoreCharacterwiseRange {fromMode: @submode}
    else
      @editor.selectRight() if @editor.getLastSelection().isEmpty()
    swrap(s).preserveCharacterwise() for s in @editor.getSelections()

    # Change selection range to final submode.
    switch submode
      when 'linewise'
        swrap(s).expandOverLine() for s in @editor.getSelections()
      when 'blockwise'
        @vimState.operationStack.push new BlockwiseSelect(@vimState)

  deactivateVisualMode: ->
    @restoreCharacterwiseRange({fromMode: @submode})
    for s in @editor.getSelections()
      swrap(s).resetProperties()
      if (not s.isEmpty()) and (not s.isReversed())
        s.cursor.moveLeft()
      s.clear(autoscroll: false)

  restoreCharacterwiseRange: ({fromMode}) ->
    switch fromMode
      when 'characterwise'
        null # nothiing to do, but I want to be explicte.
      when 'linewise'
        for s in @editor.getSelections() when not s.isEmpty()
          swrap(s).restoreCharacterwise()
      when 'blockwise'
        # Many VisualBlockwise commands change mode in the middle of processing()
        # in this case, we dont want to loose multi-cursor.
        unless @vimState.operationStack.isProcessing()
          @vimState.operationStack.push new BlockwiseRestoreCharacterwise(@vimState)

# This uses private APIs and may break if TextBuffer is refactored.
# Package authors - copy and paste this code at your own risk.
getChangesSinceCheckpoint = (buffer, checkpoint) ->
  {history} = buffer
  if (index = history.getCheckpointIndex(checkpoint))?
    history.undoStack.slice(index)
  else
    []

module.exports = ModeManager
