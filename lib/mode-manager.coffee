# Refactoring status: 95%
_ = require 'underscore-plus'
{Range, CompositeDisposable, Disposable} = require 'atom'

swrap = require './selection-wrapper'
{eachSelection} = require './utils'

supportedModes = ['normal', 'insert', 'visual', 'operator-pending']
supportedSubModes = ['characterwise', 'linewise', 'blockwise', 'replace']

class ModeManager
  mode: 'insert' # Native atom is not modal editor and its default is 'insert'

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState

  eachSelection: (fn) ->
    eachSelection(@editor, fn)

  isMode: (mode, submodes) ->
    if submodes?
      submodes = [submodes] unless _.isArray(submodes)
      (@mode is mode) and (@submode in submodes)
    else
      @mode is mode

  # activate: Public
  #  Use this method to change mode, DONT use other direct method.
  activate: (mode, submode=null) ->
    if mode is 'reset'
      @editor.clearSelections()
      mode = 'normal'
    else if (mode is 'visual') and (@submode is submode)
      mode = 'normal'
      submode = null

    # Deactivate old mode
    @deactivator?.dispose() if (mode isnt @mode)

    # Activate
    @deactivator = switch mode
      when 'normal' then @activateNormalMode()
      when 'insert' then @activateInsertMode(submode)
      when 'visual' then @activateVisualMode(submode)
      when 'operator-pending' then new Disposable # Nothing to do.

    # Now update mode variables and update CSS selectors.
    [@mode, @submode] = [mode, submode]
    @vimState.showCursors()
    @updateModeSelector()
    @vimState.statusBarManager.update(mode, submode)

  updateModeSelector: ->
    for mode in supportedModes
      @vimState.updateClassCond(mode is @mode, "#{mode}-mode")
    for submode in supportedSubModes
      @vimState.updateClassCond(submode is @submode, submode)

  # Normal
  # -------------------------
  activateNormalMode: ->
    @vimState.reset()
    @editorElement.component.setInputEnabled(false)
    new Disposable

  # Insert
  # -------------------------
  activateInsertMode: (submode=null) ->
    @editorElement.component.setInputEnabled(true)
    @setInsertionCheckpoint()
    replaceModeDeactivator = @activateReplaceMode() if (submode is 'replace')

    new Disposable =>
      checkpoint = @getInsertionCheckpoint()
      @editor.groupChangesSinceCheckpoint(checkpoint)
      changes = getChangesSinceCheckpoint(@editor.buffer, checkpoint)
      @resetInsertionCheckpoint()
      if (item = @vimState.getLastOperation()) and item.isInsert()
        item.confirmChanges(changes)

      replaceModeDeactivator?.dispose()
      replaceModeDeactivator = null

      # Adjust cursor position
      for c in @editor.getCursors() when not c.isAtBeginningOfLine()
        c.moveLeft()

  activateReplaceMode: ->
    @replacedCharsBySelection = {}
    subs = new CompositeDisposable
    subs.add @editor.onWillInsertText ({text, cancel}) =>
      cancel()
      @eachSelection (s) =>
        for char in text.split('') ? []
          if (char isnt "\n") and (not s.cursor.isAtEndOfLine())
            s.selectRight()
          @replacedCharsBySelection[s.id] ?= []
          @replacedCharsBySelection[s.id].push(swrap(s).replace(char))

    subs.add new Disposable =>
      @replacedCharsBySelection = null
    subs

  replaceModeBackspace: ->
    @eachSelection (s) =>
      char = @replacedCharsBySelection[s.id]?.pop()
      if char? # char maybe empty char ''.
        s.selectLeft()
        range = s.insertText(char)
        s.cursor.moveLeft() unless range.isEmpty()

  setInsertionCheckpoint: ->
    @insertionCheckpoint ?= @editor.createCheckpoint()

  resetInsertionCheckpoint: ->
    @insertionCheckpoint = null

  getInsertionCheckpoint: ->
    @insertionCheckpoint

  # Visual
  # -------------------------
  activateVisualMode: (submode) ->
    # If submode shift within visual mode, we first restore characterwise range
    if @submode?
      @restoreCharacterwiseRange()
    else
      @editor.selectRight() if @editor.getLastSelection().isEmpty()
    # Preserve characterwise range to restore afterward.
    selections = @editor.getSelections()
    swrap(s).preserveCharacterwise() for s in selections

    # Update selection area to final submode.
    switch submode
      when 'linewise' then swrap(s).expandOverLine() for s in selections
      when 'blockwise' then @vimState.operationStack.run('BlockwiseSelect')

    new Disposable =>
      @restoreCharacterwiseRange()
      @eachSelection (s) ->
        swrap(s).resetProperties()
        s.cursor.moveLeft() unless (s.isEmpty() or s.isReversed())
        s.clear(autoscroll: false)

  restoreCharacterwiseRange: ->
    switch @submode
      when 'characterwise'
        null # nothiing to do, but I want to be explicte.
      when 'linewise'
        @eachSelection (s) ->
          swrap(s).restoreCharacterwise() unless s.isEmpty()
      when 'blockwise'
        # Many VisualBlockwise commands change mode in the middle of processing()
        # in this case, we dont want to loose multi-cursor.
        unless @vimState.operationStack.isProcessing()
          @vimState.operationStack.run "BlockwiseRestoreCharacterwise"

# This uses private APIs and may break if TextBuffer is refactored.
# Package authors - copy and paste this code at your own risk.
getChangesSinceCheckpoint = (buffer, checkpoint) ->
  {history} = buffer
  if (index = history.getCheckpointIndex(checkpoint))?
    history.undoStack.slice(index)
  else
    []

module.exports = ModeManager
