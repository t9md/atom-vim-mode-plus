LineEndingRegExp = /(?:\n|\r\n)$/
_ = require 'underscore-plus'
{Point, Range} = require 'atom'
globalState = require './global-state'

{inspect} = require 'util'
{
  haveSomeSelection
  highlightRanges
  isEndsWithNewLineForBufferRow
  getCurrentWordBufferRangeAndKind
  cursorIsAtEmptyRow
  scanInRanges

  selectedRange
  selectedText
  toString
  debug
} = require './utils'
swrap = require './selection-wrapper'
settings = require './settings'
Base = require './base'
CursorPositionManager = require './cursor-position-manager'
{OperatorError} = require './errors'

class Operator extends Base
  @extend(false)
  requireTarget: true
  recordable: true

  forceWise: null
  withOccurrence: false

  patternForOccurence: null

  stayOnLinewise: false
  stayAtSamePosition: null
  restorePositions: true
  flashTarget: true
  trackChange: false

  # [FIXME]
  # For TextObject, isLinewise result is changed before / after select.
  # This mean return value may change depending on when you call.
  needStay: ->
    @stayAtSamePosition ?= do =>
      if @instanceof('TransformString')
        param = 'stayOnTransformString'
      else if @instanceof('Delete')
        param = 'stayOnDelete'
      else
        param = "stayOn#{@getName()}"

      if @isMode('visual', 'linewise')
        settings.get(param)
      else
        settings.get(param) or (@stayOnLinewise and @target.isLinewise?())

  isWithOccurrence: ->
    @withOccurrence

  setMarkForChange: (range) ->
    @vimState.mark.setRange('[', ']', range)

  flashIfNecessary: (ranges) ->
    return if @isMode('visual')
    return unless @flashTarget
    return unless settings.get('flashOnOperate')
    return if @getName() in settings.get('flashOnOperateBlacklist')

    highlightRanges @editor, ranges,
      class: 'vim-mode-plus-flash'
      timeout: settings.get('flashOnOperateDuration')

  trackChangeIfNecessary: ->
    return unless @trackChange

    changeMarker = @editor.markBufferRange(@editor.getSelectedBufferRange())
    @onDidFinishOperation =>
      @setMarkForChange(changeMarker.getBufferRange())

  constructor: ->
    super
    @initialize()

    #[FIXME] ensure call @setTarget on NG case.
    # OK: new Select(@vimState).setTarget(operation)
    # NG: new Select(@vimState, target: operation}

    @setTarget(@new(@target)) if _.isString(@target)

  # target is TextObject or Motion to operate on.
  setTarget: (target) ->
    unless _.isFunction(target.select)
      @emitDidFailToSetTarget()
      throw new OperatorError("#{@getName()} cannot set #{target?.getName?()} as target")
    @target = target
    @target.setOperator(this)
    @modifyTargetWiseIfNecessary()
    @emitDidSetTarget(this)
    this

  # called by operationStack
  setOperatorModifier: ({occurence, wise}) ->
    if occurence? and occurence isnt @withOccurrence
      @withOccurrence = occurence
      @vimState.operationStack.addToClassList('with-occurrence')

    if wise?
      @forceWise = wise

  modifyTargetWiseIfNecessary: ->
    return unless @forceWise?

    switch @forceWise
      when 'characterwise'
        if @target.linewise
          @target.linewise = false
          @target.inclusive = false
        else
          @target.inclusive = not @target.inclusive
      when 'linewise'
        @target.linewise = true

  getPatternForOccurrence: ->
    if @hasRegisterName()
      pattern = _.escapeRegExp(@getRegisterValueAsText())
    else
      {range, kind} = getCurrentWordBufferRangeAndKind(@editor.getLastCursor())
      cursorWord = @editor.getTextInBufferRange(range)
      pattern = _.escapeRegExp(cursorWord)
      if kind is 'word'
        pattern = "\\b" + pattern + "\\b"
    new RegExp(pattern, 'g')

  setTextToRegisterForSelection: (selection) ->
    @setTextToRegister(selection.getText(), selection)

  setTextToRegister: (text, selection) ->
    text += "\n" if (@target.isLinewise?() and (not text.endsWith('\n')))
    @vimState.register.set({text, selection}) if text

  debug: ->
    # === debug
    debug('# ---------- start')
    debug(selectedRange(@editor))
    debug(selectedText(@editor))
    debug('# ---------- end')

  # Main
  execute: ->
    # We need to preserve selections before selection is cleared as a result of mutation.
    @updatePreviousSelectionIfVisualMode()
    # Mutation phase
    debug "  operator-execute", @toString()
    if @selectTarget()
      debug "    selectTarget[=success]"
      @editor.transact =>
        for selection in @editor.getSelections()
          @mutateSelection(selection)
      @restoreCursorPositions() if @restorePositions
    else
      debug "    selectTarget[=fail]"

    # Even though we fail to select target and fail to mutate,
    # we have to return to normal-mode from operator-pending or visual
    @activateMode('normal')

  selectOccurrence: (fn) ->
    scanRanges = null
    cursorPositionManager = new CursorPositionManager(@editor)

    # Capture Pattern For Occurrence
    if @isMode('visual')
      scanRanges = @editor.getSelectedBufferRanges()
      @vimState.modeManager.deactivate() # clear selection FIXME
      debug "    deactivate on will-select-target"

      unless @isMode('visual', 'blockwise') # extend scanRange to include cursorWord
        # BUG dont extend if register value is specified
        range = getCurrentWordBufferRangeAndKind(@editor.getLastCursor()).range
        newRange = scanRanges.pop().union(range)
        scanRanges.push(newRange)

    cursorPositionManager.save('head')
    @patternForOccurence ?= @getPatternForOccurrence()

    fn()

    # Select Occurrence
    ranges = scanInRanges(@editor, @patternForOccurence, scanRanges ? @editor.getSelectedBufferRanges())
    if (success = ranges.length > 0)
      @editor.setSelectedBufferRanges(ranges)
      cursorPositionManager.destroy()
    else
      # Restoring cursor position also clear selection. Require to avoid unwanted mutation.
      cursorPositionManager.restore()

    if settings.get('debug')
      status = success and 'success' or 'fail'
      debug "    selectOccurrence[=#{status}]"

    status

  # Return true unless all selection is empty.
  selectTarget: ->
    saveAfterSelect = @saveCursorPositionsToRestore()
    selectTarget = =>
      @target.select()
      saveAfterSelect?()

    if @isWithOccurrence()
      @selectOccurrence -> selectTarget()
    else
      selectTarget()

    if haveSomeSelection(@editor)
      @emitDidSelectTarget()
      @flashIfNecessary(@editor.getSelectedBufferRanges())
      @trackChangeIfNecessary()
    haveSomeSelection(@editor)

  updatePreviousSelectionIfVisualMode: ->
    return unless @isMode('visual')

    if @isMode('visual', 'blockwise')
      properties = @vimState.getLastBlockwiseSelection().getCharacterwiseProperties()
    else
      lastSelection = @editor.getLastSelection()
      properties = swrap(lastSelection).detectCharacterwiseProperties()

    submode = @vimState.submode
    globalState.previousSelection = {properties, submode}

  saveCursorPositionsToRestore: ->
    @cursorPositionManager = new CursorPositionManager(@editor)
    stay = @needStay()
    visual = @isMode('visual')

    switch
      when stay and visual
        @cursorPositionManager.save('head', fromProperty: true, allowFallback: true)
      when stay and (not visual)
        @cursorPositionManager.save('head') unless @instanceof('Select')
      when (not stay) and visual
        @cursorPositionManager.save('start')
      when (not stay) and (not visual)
        =>
          @cursorPositionManager.save('start')

  restoreCursorPositions: ->
    @cursorPositionManager.restore(strict: not @isWithOccurrence())
    @cursorPositionManager = null
    @emitDidRestoreCursorPositions()

# Select
# When text-object is invoked from normal or viusal-mode, operation would be
#  => Select operator with target=text-object
# When motion is invoked from visual-mode, operation would be
#  => Select operator with target=motion)
# ================================
class Select extends Operator
  @extend(false)
  flashTarget: false
  recordable: false

  canChangeMode: ->
    if @isMode('visual')
      @isWithOccurrence() or @target.isAllowSubmodeChange?()
    else
      true

  execute: ->
    @selectTarget()
    if @canChangeMode()
      submode = swrap.detectVisualModeSubmode(@editor)
      @activateModeIfNecessary('visual', submode)

class SelectLatestChange extends Select
  @extend()
  @description: "Select latest yanked or changed range"
  target: 'ALatestChange'

class SelectPreviousSelection extends Select
  @extend()
  target: "PreviousSelection"
  execute: ->
    @selectTarget()
    if @target.submode?
      @activateModeIfNecessary('visual', @target.submode)

class SelectRangeMarker extends Select
  @extend()
  @description: "Select range-marker and clear all range-marker. It's like convert each range-marker to selection"
  target: "ARangeMarker"
  execute: ->
    super
    @vimState.clearRangeMarkers()

class SelectOccurrence extends Select
  @extend()
  @description: "Add selection onto each matching word within target range"
  withOccurrence: true
  initialize: ->
    super
    @onDidSelectTarget =>
      swrap.clearProperties(@editor)

class SelectOccurrenceInARangeMarker extends SelectOccurrence
  @extend()
  target: "ARangeMarker"

# Range Marker
# =========================
class CreateRangeMarker extends Operator
  @extend()
  flashTarget: false
  stayAtSamePosition: true

  mutateSelection: (selection) ->
    @vimState.addRangeMarkersForRanges(selection.getBufferRange())

class ToggleRangeMarker extends CreateRangeMarker
  @extend()
  rangeMarkerToRemove: null

  isComplete: ->
    point = @editor.getCursorBufferPosition()
    if @rangeMarkerToRemove = @vimState.getRangeMarkerAtBufferPosition(point)
      true
    else
      super

  execute: ->
    if @rangeMarkerToRemove
      @rangeMarkerToRemove.destroy()
      @vimState.removeRangeMarker(@rangeMarkerToRemove)
    else
      super

class ToggleRangeMarkerOnInnerWord extends ToggleRangeMarker
  @extend()
  target: 'InnerWord'

# Delete
# ================================
class Delete extends Operator
  @extend()
  hover: icon: ':delete:', emoji: ':scissors:'
  trackChange: true
  flashTarget: false
  wasLinewise: null

  execute: ->
    wasLinewise = null
    @onDidSelectTarget =>
      wasLinewise = @target.isLinewise()
      if @needStay()
        isCharacterwise = @vimState.isMode('visual', 'characterwise')
        @cursorPositionManager.updateBy (selection, point) ->
          start = selection.getBufferRange().start
          if isCharacterwise
            start
          else
            new Point(start.row, point.column)

    @onDidRestoreCursorPositions =>
      return unless wasLinewise
      vimEof = @getVimEofBufferPosition()
      for cursor in @editor.getCursors()
        # Ensure cursor never exceeds VimEOF
        if cursor.getBufferPosition().isGreaterThan(vimEof)
          cursor.setBufferPosition([vimEof.row, 0])
        cursor.skipLeadingWhitespace() unless @needStay()
    super

  mutateSelection: (selection) =>
    @setTextToRegisterForSelection(selection)
    selection.deleteSelectedText()

class DeleteRight extends Delete
  @extend()
  target: 'MoveRight'
  hover: null

class DeleteLeft extends Delete
  @extend()
  target: 'MoveLeft'

class DeleteToLastCharacterOfLine extends Delete
  @extend()
  target: 'MoveToLastCharacterOfLine'
  execute: ->
    # Ensure all selections to un-reversed
    if isBlockwise = @isMode('visual', 'blockwise')
      swrap.setReversedState(@editor, false)

    super

    if isBlockwise
      @getBlockwiseSelections().forEach (blockwiseSelection) ->
        startPosition = blockwiseSelection.getStartBufferPosition()
        blockwiseSelection.setHeadBufferPosition(startPosition)

class DeleteLine extends Delete
  @extend()
  @commandScope: 'atom-text-editor.vim-mode-plus.visual-mode'
  mutateSelection: (selection) ->
    swrap(selection).expandOverLine()
    super

# Yank
# =========================
class Yank extends Operator
  @extend()
  hover: icon: ':yank:', emoji: ':clipboard:'
  trackChange: true
  stayOnLinewise: true

  mutateSelection: (selection) ->
    @setTextToRegisterForSelection(selection)

class YankLine extends Yank
  @extend()
  target: 'MoveToRelativeLine'

  execute: ->
    if @isMode('visual')
      unless @isMode('visual', 'linewise')
        @vimState.modeManager.activate('visual', 'linewise')
    super

class YankToLastCharacterOfLine extends Yank
  @extend()
  target: 'MoveToLastCharacterOfLine'

# -------------------------
# [FIXME?]: inconsistent behavior from normal operator
# Since its support visual-mode but not use setTarget() convension.
# Maybe separating complete/in-complete version like IncreaseNow and Increase?
class Increase extends Operator
  @extend()
  requireTarget: false
  step: 1

  execute: ->
    pattern = ///#{settings.get('numberRegex')}///g

    newRanges = []
    @editor.transact =>
      for cursor in @editor.getCursors()
        scanRange = if @isMode('visual')
          cursor.selection.getBufferRange()
        else
          cursor.getCurrentLineBufferRange()
        ranges = @increaseNumber(cursor, scanRange, pattern)
        if not @isMode('visual') and ranges.length
          cursor.setBufferPosition ranges[0].end.translate([0, -1])
        newRanges.push ranges

    if (newRanges = _.flatten(newRanges)).length
      @flashIfNecessary(newRanges)
    else
      atom.beep()

  increaseNumber: (cursor, scanRange, pattern) ->
    newRanges = []
    @editor.scanInBufferRange pattern, scanRange, ({matchText, range, stop, replace}) =>
      newText = String(parseInt(matchText, 10) + @step * @getCount())
      if @isMode('visual')
        newRanges.push replace(newText)
      else
        return unless range.end.isGreaterThan cursor.getBufferPosition()
        newRanges.push replace(newText)
        stop()
    newRanges

class Decrease extends Increase
  @extend()
  step: -1

# -------------------------
class IncrementNumber extends Operator
  @extend()
  displayName: 'Increment ++'
  step: 1
  baseNumber: null

  execute: ->
    pattern = ///#{settings.get('numberRegex')}///g
    newRanges = null
    @selectTarget()
    @editor.transact =>
      newRanges = for selection in @editor.getSelectionsOrderedByBufferPosition()
        @replaceNumber(selection.getBufferRange(), pattern)
    if (newRanges = _.flatten(newRanges)).length
      @flashIfNecessary(newRanges)
    else
      atom.beep()
    for selection in @editor.getSelections()
      selection.cursor.setBufferPosition(selection.getBufferRange().start)
    @activateModeIfNecessary('normal')

  replaceNumber: (scanRange, pattern) ->
    newRanges = []
    @editor.scanInBufferRange pattern, scanRange, ({matchText, replace}) =>
      newRanges.push replace(@getNewText(matchText))
    newRanges

  getNewText: (text) ->
    @baseNumber = if @baseNumber?
      @baseNumber + @step * @getCount()
    else
      parseInt(text, 10)
    String(@baseNumber)

class DecrementNumber extends IncrementNumber
  @extend()
  displayName: 'Decrement --'
  step: -1

# Put
# -------------------------
class PutBefore extends Operator
  @extend()
  requireTarget: false
  location: 'before'

  execute: ->
    @editor.transact =>
      for selection in @editor.getSelections()
        {cursor} = selection
        {text, type} = @vimState.register.get(null, selection)
        break unless text
        text = _.multiplyString(text, @getCount())
        newRange = @paste selection, text,
          linewise: (type is 'linewise') or @isMode('visual', 'linewise')
          select: @selectPastedText
        @setMarkForChange(newRange)
        @flashIfNecessary(newRange)

    if @selectPastedText
      @activateModeIfNecessary('visual', swrap.detectVisualModeSubmode(@editor))
    else
      @activateMode('normal')

  paste: (selection, text, {linewise, select}) ->
    {cursor} = selection
    select ?= false
    linewise ?= false
    if linewise
      newRange = @pasteLinewise(selection, text)
      adjustCursor = (range) ->
        cursor.setBufferPosition(range.start)
        cursor.moveToFirstCharacterOfLine()
    else
      newRange = @pasteCharacterwise(selection, text)
      adjustCursor = (range) ->
        cursor.setBufferPosition(range.end.translate([0, -1]))

    if select
      selection.setBufferRange(newRange)
    else
      adjustCursor(newRange)
    newRange

  # Return newRange
  pasteLinewise: (selection, text) ->
    {cursor} = selection
    text += "\n" unless text.endsWith("\n")
    if selection.isEmpty()
      row = cursor.getBufferRow()
      switch @location
        when 'before'
          range = [[row, 0], [row, 0]]
        when 'after'
          unless isEndsWithNewLineForBufferRow(@editor, row)
            text = text.replace(LineEndingRegExp, '')
          cursor.moveToEndOfLine()
          {end} = selection.insertText("\n")
          range = @editor.bufferRangeForBufferRow(end.row, {includeNewline: true})
      @editor.setTextInBufferRange(range, text)
    else
      if @isMode('visual', 'linewise')
        unless selection.getBufferRange().end.column is 0
          text = text.replace(LineEndingRegExp, '')
      else
        selection.insertText("\n")
      selection.insertText(text)

  pasteCharacterwise: (selection, text) ->
    if @location is 'after' and selection.isEmpty() and not cursorIsAtEmptyRow(selection.cursor)
      selection.cursor.moveRight()
    selection.insertText(text)

class PutAfter extends PutBefore
  @extend()
  location: 'after'

class PutBeforeAndSelect extends PutBefore
  @extend()
  @description: "Paste before then select"
  selectPastedText: true

class PutAfterAndSelect extends PutAfter
  @extend()
  @description: "Paste after then select"
  selectPastedText: true

# Replace
# -------------------------
class Replace extends Operator
  @extend()
  input: null
  hover: icon: ':replace:', emoji: ':tractor:'
  flashTarget: false
  trackChange: true
  requireInput: true

  initialize: ->
    super
    @setTarget(@new('MoveRight')) if @isMode('normal')
    @focusInput()

  getInput: ->
    input = super
    input = "\n" if input is ''
    input

  execute: ->
    input = @getInput()
    return unless @selectTarget()
    @editor.transact =>
      for selection in @editor.getSelections()
        text = selection.getText()
        if @target.instanceof('MoveRight') and text.length isnt @getCount()
          continue

        newText = text.replace(/./g, input)
        newRange = selection.insertText(newText, autoIndentNewline: true)
        if input isnt "\n"
          selection.cursor.setBufferPosition(newRange.start)

    # FIXME this is very imperative, handling in very lower level.
    # find better place for operator in blockwise move works appropriately.
    if @getTarget().isBlockwise()
      top = @editor.getSelectionsOrderedByBufferPosition()[0]
      for selection in @editor.getSelections() when (selection isnt top)
        selection.destroy()

    @activateMode('normal')
