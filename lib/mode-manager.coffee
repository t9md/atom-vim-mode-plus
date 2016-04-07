_ = require 'underscore-plus'
{Emitter, Range, CompositeDisposable, Disposable} = require 'atom'
Base = require './base'
swrap = require './selection-wrapper'
{moveCursorLeft} = require './utils'
settings = require './settings'

class ModeManager
  mode: 'insert' # Native atom is not modal editor and its default is 'insert'

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    @emitter = new Emitter

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
    else if mode is 'visual'
      if submode is @submode
        mode = 'normal'
        submode = null
      else if submode is 'previous'
        submode = @restorePreviousSelection?() ? 'characterwise'

    @deactivate() if (mode isnt @mode)

    # Activate
    @deactivator = switch mode
      when 'normal' then @activateNormalMode()
      when 'insert' then @activateInsertMode(submode)
      when 'visual' then @activateVisualMode(submode)

    # Remove OLD mode, submode CSS class
    @editorElement.classList.remove("#{@mode}-mode")
    @editorElement.classList.remove(@submode)

    [@mode, @submode] = [mode, submode]

    # Add NEW mode, submode CSS class
    @editorElement.classList.add("#{@mode}-mode")
    @editorElement.classList.add(@submode) if @submode?

    @vimState.statusBarManager.update(@mode, @submode)
    @vimState.updateCursorsVisibility()
    @emitter.emit 'did-activate-mode', {@mode, @submode}

  deactivate: ->
    @emitter.emit 'will-deactivate-mode', {@mode, @submode}
    @deactivator?.dispose()
    @emitter.emit 'did-deactivate-mode', {@mode, @submode}

  # Normal
  # -------------------------
  activateNormalMode: ->
    @vimState.reset()
    # [FIXME] Component is not necessary avaiable see #98.
    @editorElement.component?.setInputEnabled(false)
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
    if @submode?
      # If submode shift within visual mode, we first restore characterwise range
      # At this phase @submode is not yet updated to requested submode.
      @restoreCharacterwiseRange()
    else
      @editor.selectRight() if @editor.getLastSelection().isEmpty()

    # Preserve characterwise range to restore afterward.
    @vimState.updateSelectionProperties()

    # Update selection area to final submode.
    switch submode
      when 'linewise'
        @vimState.selectLinewise()
      when 'blockwise'
        @vimState.selectBlockwise() unless swrap(@editor.getLastSelection()).isLinewise()

    new Disposable =>
      @normalizeSelections(preservePreviousSelection: true)
      for selection in @editor.getSelections()
        selection.clear(autoscroll: false)

  # Prepare function to restore selection by `gv`
  preservePreviousSelection: (selection) ->
    properties = if selection.isBlockwise?()
      selection.getCharacterwiseProperties()
    else
      swrap(selection).detectCharacterwiseProperties()
    submode = @submode
    @restorePreviousSelection = =>
      selection = @editor.getLastSelection()
      swrap(selection).selectByProperties({characterwise: properties})
      @editor.scrollToScreenRange(selection.getScreenRange(), {center: true})
      submode

  restoreCharacterwiseRange: ->
    switch @submode
      when 'linewise'
        for selection in @editor.getSelections() when not selection.isEmpty()
          swrap(selection).restoreCharacterwise(preserveGoalColumn: true)
      when 'blockwise'
        for blockwiseSelection in @vimState.getBlockwiseSelections()
          # When all selection is empty, we don't want to loose multi-cursor
          # by restoreing characterwise range.
          unless blockwiseSelection.selections.every((selection) -> selection.isEmpty())
            blockwiseSelection.restoreCharacterwise()
        @vimState.clearBlockwiseSelections()

    @editor.getSelections().forEach (selection) ->
      swrap(selection).resetProperties()

  normalizeSelections: ({preservePreviousSelection}={}) ->
    @restoreCharacterwiseRange()
    preservePreviousSelection ?= false
    if preservePreviousSelection
      unless (selection = @editor.getLastSelection()).isEmpty()
        @preservePreviousSelection(selection)

    # We selectRight()ed in visual-mode, so reset this effect here.
    @editor.getSelections().forEach (selection) ->
      # `vc`, `vs` make selection empty
      unless (selection.isReversed() or selection.isEmpty())
        selection.modifySelection ->
          # [FIXME] SCATTERED_CURSOR_ADJUSTMENT
          moveCursorLeft(selection.cursor, {allowWrap: true, preserveGoalColumn: true})

module.exports = ModeManager
