# Refactoring status: 95%
_ = require 'underscore-plus'
{Emitter, Range, CompositeDisposable, Disposable} = require 'atom'

swrap = require './selection-wrapper'
{eachSelection, toggleClassByCondition, getNewTextRangeFromCheckpoint} = require './utils'

supportedModes = ['normal', 'insert', 'visual', 'operator-pending']
supportedSubModes = ['characterwise', 'linewise', 'blockwise', 'replace']

class ModeManager
  mode: 'insert' # Native atom is not modal editor and its default is 'insert'

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    @emitter = new Emitter

    @onDidActivateMode ({mode, submode}) =>
      @vimState.showCursors()
      @updateEditorElement()
      @vimState.statusBarManager.update(mode, submode)

  updateEditorElement: ->
    for mode in supportedModes
      toggleClassByCondition(@editorElement, "#{mode}-mode", mode is @mode)
    for submode in supportedSubModes
      toggleClassByCondition(@editorElement, submode, submode is @submode)

  eachSelection: (fn) ->
    eachSelection(@editor, fn)

  isMode: (mode, submodes) ->
    if submodes?
      submodes = [submodes] unless _.isArray(submodes)
      (@mode is mode) and (@submode in submodes)
    else
      @mode is mode

  onWillDeactivateMode: (fn) ->
    @emitter.on 'will-deactivate-mode', fn

  onDidActivateMode: (fn) ->
    @emitter.on 'did-activate-mode', fn

  # activate: Public
  #  Use this method to change mode, DONT use other direct method.
  activate: (mode, submode=null) ->
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
      if (item = @vimState.operationStack.getRecorded()) and item.getCheckpoint?
        {undo, insert} = item.getCheckpoint()
        range = getNewTextRangeFromCheckpoint(@editor, insert)
        text = @editor.getTextInBufferRange(range ? [])
        # grouping changes for undo checkpoint need to come later than
        @editor.groupChangesSinceCheckpoint(undo)

        @vimState.register.set('.', {text})
        @vimState.mark.set('^', @editor.getCursorBufferPosition())
        if range
          @vimState.mark.set('[', range.start)
          @vimState.mark.set(']', range.end)

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
    selections = @editor.getSelections()
    swrap(s).preserveCharacterwise() for s in selections

    # Update selection area to final submode.
    switch submode
      when 'linewise' then swrap(s).expandOverLine() for s in selections
      when 'blockwise' then @vimState.operationStack.run('BlockwiseSelect')

    new Disposable =>
      @restoreCharacterwiseRange()

      # Prepare function to restore selection by `gv`
      properties = swrap(@editor.getLastSelection()).detectCharacterwiseProperties()
      submode = @submode
      @restorePreviousSelection = =>
        selection = @editor.getLastSelection()
        swrap(s).selectByProperties(properties)
        @editor.scrollToScreenRange(s.getScreenRange(), {center: true})
        submode

      @eachSelection (s) ->
        {cursor} = s
        swrap(s).resetProperties()
        unless s.isReversed() or s.isEmpty() or cursor.isAtBeginningOfLine()
          cursor.moveLeft()
        s.clear(autoscroll: false)

  restoreCharacterwiseRange: ->
    return if @isMode('visual', 'characterwise')
    switch @submode
      when 'linewise'
        @eachSelection (s) ->
          swrap(s).restoreCharacterwise() unless s.isEmpty()
      when 'blockwise'
        # Many VisualBlockwise commands change mode in the middle of processing()
        # in this case, we dont want to loose multi-cursor.
        unless @vimState.operationStack.isProcessing()
          @vimState.operationStack.run "BlockwiseRestoreCharacterwise"

module.exports = ModeManager
