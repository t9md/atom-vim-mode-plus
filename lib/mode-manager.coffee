# Refactoring status: 95%
_ = require 'underscore-plus'
{Emitter, Range, CompositeDisposable, Disposable} = require 'atom'
{BlockwiseSelect, BlockwiseRestoreCharacterwise} = require './visual-blockwise'

swrap = require './selection-wrapper'
{toggleClassByCondition, moveCursorLeft} = require './utils'

supportedModes = ['normal', 'insert', 'visual', 'operator-pending']
supportedSubModes = ['characterwise', 'linewise', 'blockwise', 'replace']

class ModeManager
  mode: 'insert' # Native atom is not modal editor and its default is 'insert'

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    @emitter = new Emitter

    @onDidActivateMode ({mode, submode}) =>
      @updateEditorElement()
      @vimState.statusBarManager.update(mode, submode)
      @vimState.refreshCursors()

  updateEditorElement: ->
    for mode in supportedModes
      toggleClassByCondition(@editorElement, "#{mode}-mode", mode is @mode)
    for submode in supportedSubModes
      toggleClassByCondition(@editorElement, submode, submode is @submode)

  isMode: (mode, submodes) ->
    if submodes?
      submodes = [submodes] unless _.isArray(submodes)
      (@mode is mode) and (@submode in submodes)
    else
      @mode is mode

  onWillActivateMode: (fn) -> @emitter.on 'will-activate-mode', fn
  onDidActivateMode: (fn) -> @emitter.on 'did-activate-mode', fn
  onWillDeactivateMode: (fn) -> @emitter.on 'will-deactivate-mode', fn
  preemptWillDeactivateMode: (fn) -> @emitter.on 'will-deactivate-mode', fn
  onDidDeactivateMode: (fn) -> @emitter.on 'did-deactivate-mode', fn

  # activate: Public
  #  Use this method to change mode, DONT use other direct method.
  # -------------------------
  activate: (mode, submode=null) ->
    @emitter.emit 'will-activate-mode', {mode, submode}
    if mode is 'reset'
      @editor.clearSelections()
      mode = 'normal'
    else if (mode is 'visual')
      if submode is @submode
        mode = 'normal'
        submode = null
      else if submode is 'previous'
        submode = @restorePreviousSelection?() ? 'characterwise'

    # Deactivate old mode
    if (mode isnt @mode)
      @emitter.emit 'will-deactivate-mode', {@mode, @submode}
      @deactivator?.dispose()
      @emitter.emit 'did-deactivate-mode', {@mode, @submode}

    # Activate
    @deactivator = switch mode
      when 'normal' then @activateNormalMode()
      when 'insert' then @activateInsertMode(submode)
      when 'visual' then @activateVisualMode(submode)
      when 'operator-pending' then new Disposable # Nothing to do.

    # Now update mode variables and update CSS selectors.
    [@mode, @submode] = [mode, submode]
    @emitter.emit 'did-activate-mode', {@mode, @submode}

  # Normal
  # -------------------------
  activateNormalMode: ->
    @vimState.reset()
    @editorElement.component.setInputEnabled(false)
    new Disposable

  # ActivateInsertMode
  # -------------------------
  activateInsertMode: (submode=null) ->
    @editorElement.component.setInputEnabled(true)
    replaceModeDeactivator = @activateReplaceMode() if (submode is 'replace')

    new Disposable =>
      replaceModeDeactivator?.dispose()
      replaceModeDeactivator = null
      # When escape from insert-mode, cursor move Left.
      moveCursorLeft(cursor) for cursor in @editor.getCursors()

  activateReplaceMode: ->
    @replacedCharsBySelection = {}
    subs = new CompositeDisposable
    subs.add @editor.onWillInsertText ({text, cancel}) =>
      cancel()
      @editor.getSelections().forEach (selection) =>
        for char in text.split('') ? []
          if (char isnt "\n") and (not selection.cursor.isAtEndOfLine())
            selection.selectRight()
          @replacedCharsBySelection[selection.id] ?= []
          @replacedCharsBySelection[selection.id].push(swrap(selection).replace(char))

    subs.add new Disposable =>
      @replacedCharsBySelection = null
    subs

  getReplacedCharForSelection: (selection) ->
    @replacedCharsBySelection[selection.id]?.pop()

  # Visual
  # -------------------------
  activateVisualMode: (submode) ->
    # If submode shift within visual mode, we first restore characterwise range
    # At this phase @submode is not yet updated to requested submode.
    if @submode?
      @restoreCharacterwiseRange()
    else
      @editor.selectRight() if @editor.getLastSelection().isEmpty()
    # Preserve characterwise range to restore afterward.
    for selection in @editor.getSelections()
      swrap(selection).preserveCharacterwise()

    # Update selection area to final submode.
    switch submode
      when 'linewise'
        swrap.expandOverLine(@editor)
      when 'blockwise'
        unless swrap(@editor.getLastSelection()).isLinewise()
          new BlockwiseSelect(@vimState).execute()

    new Disposable =>
      @restoreCharacterwiseRange()

      # Prepare function to restore selection by `gv`
      properties = swrap(@editor.getLastSelection()).detectCharacterwiseProperties()
      submode = @submode
      @restorePreviousSelection = =>
        selection = @editor.getLastSelection()
        swrap(selection).selectByProperties(properties)
        @editor.scrollToScreenRange(selection.getScreenRange(), {center: true})
        submode

      @editor.getSelections().forEach (selection) ->
        swrap(selection).resetProperties()
        # `vc`, `vs` make selection empty
        if (not selection.isReversed() and not selection.isEmpty())
          selection.selectLeft()
        selection.clear(autoscroll: false)

  restoreCharacterwiseRange: ->
    return if @submode is 'characterwise'
    switch @submode
      when 'linewise'
        @editor.getSelections().forEach (selection) ->
          swrap(selection).restoreCharacterwise() unless selection.isEmpty()
      when 'blockwise'
        # Many VisualBlockwise commands change mode in the middle of processing()
        # in this case, we dont want to loose multi-cursor.
        unless @vimState.operationStack.isProcessing()
          new BlockwiseRestoreCharacterwise(@vimState).execute()

module.exports = ModeManager
