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

    @deactivate() unless @isMode(mode)
    switch mode
      when 'normal' then @activateNormalMode()
      when 'insert' then @activateInsertMode(submode)
      when 'visual'
        return @activate('normal') if @isMode('visual', submode)
        @activateVisualMode(submode)
      when 'operator-pending'
        null # This is just placeholder, nothing to do without updating selector.

    [@mode, @submode] = [mode, submode]
    @updateModeSelector(mode, submode)
    @vimState.statusBarManager.update(mode, submode)

  deactivate: ->
    switch @mode
      when 'insert' then @deactivateInsertMode(@submode)
      when 'visual' then @deactivateVisualMode(@submode)

  updateModeSelector: (mode, submode) ->
    for _mode in supportedModes
      @vimState.updateClassCond(_mode is mode, "#{_mode}-mode")
    for _submode in supportedSubModes
      @vimState.updateClassCond(_submode is submode, _submode)

  # Normal
  # -------------------------
  activateNormalMode: ->
    # NOTE: Since cursor is serialized and restored in next session.
    # If we don't reset this propety, first find-and-replace:select-next will
    # put selection wrong place.
    for s in @editor.getSelections()
      swrap(s).resetProperties()
      s.clear(autoscroll: false)
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

  deactivateInsertMode: (oldSubmode) ->
    @editor.groupChangesSinceCheckpoint(@insertionCheckpoint)
    changes = getChangesSinceCheckpoint(@editor.buffer, @insertionCheckpoint)
    @insertionCheckpoint = null
    if (item = @vimState.getLastOperation()) and item.isInsert()
      item.confirmChanges(changes)

    if oldSubmode is 'replace'
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
    oldSubmode = @submode
    # [FIXME] following operation depend operationStack
    # So @activate at first is important since operationStack do
    # special cursor treatment depending on current mode.
    @mode = 'visual'
    @submode = submode
    switch submode
      when 'linewise'
        @selectCharacterwise(oldSubmode)
        @selectLinewise()
      when 'characterwise'
        @selectCharacterwise(oldSubmode)
      when 'blockwise'
        @selectCharacterwise(oldSubmode)
        @selectBlockwise()

  deactivateVisualMode: (oldSubmode) ->
    @selectCharacterwise(oldSubmode)
    # Adjust cursor position
    for s in @editor.getSelections()
      swrap(s).resetProperties()
      if (not s.isEmpty()) and (not s.isReversed())
        s.cursor.moveLeft()

  # FIXME: Eliminate complexity.
  selectCharacterwise: (oldSubmode) ->
    selection = @editor.getLastSelection()
    switch
      when oldSubmode is 'characterwise'
        # null
        for s in @editor.getSelections()
          swrap(s).preserveCharacterwise()
      when oldSubmode is 'blockwise'
        @vimState.operationStack.push new BlockwiseRestoreCharacterwise(@vimState)
      when oldSubmode is 'linewise' and selection.isEmpty()
        null
      when not oldSubmode? and selection.isEmpty()
        @editor.selectRight()
        for s in @editor.getSelections()
          swrap(s).preserveCharacterwise()
      else
        for s in @editor.getSelections()
          swrap(s).restoreCharacterwise()

  selectLinewise: ->
    # Keep original range as marker's property to restore column.
    for s in @editor.getSelections()
      # swrap(s).preserveCharacterwise()
      swrap(s).expandOverLine()
      {cursor} = s
      cursor.setVisible(false) if cursor.isVisible()

  selectBlockwise: ->
    @vimState.operationStack.push new BlockwiseSelect(@vimState)

# This uses private APIs and may break if TextBuffer is refactored.
# Package authors - copy and paste this code at your own risk.
getChangesSinceCheckpoint = (buffer, checkpoint) ->
  {history} = buffer
  if (index = history.getCheckpointIndex(checkpoint))?
    history.undoStack.slice(index)
  else
    []

module.exports = ModeManager
