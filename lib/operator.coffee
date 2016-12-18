LineEndingRegExp = /(?:\n|\r\n)$/
_ = require 'underscore-plus'
{Point, Range, Disposable} = require 'atom'

{inspect} = require 'util'
{
  haveSomeNonEmptySelection
  isEndsWithNewLineForBufferRow
  getValidVimBufferRow
  cursorIsAtEmptyRow
  getWordPatternAtBufferPosition
  destroyNonLastSelection
  getEndOfLineForBufferRow
  setTextAtBufferPosition
  setBufferRow
  moveCursorToFirstCharacterAtRow
  ensureEndsWithNewLineForBufferRow
  isNotEmpty
} = require './utils'
swrap = require './selection-wrapper'
settings = require './settings'
Base = require './base'

class Operator extends Base
  @extend(false)
  requireTarget: true
  recordable: true

  wise: null
  occurrence: false

  flashTarget: true
  flashCheckpoint: 'did-finish'
  flashType: 'operator'
  flashTypeForOccurrence: 'operator-occurrence'
  trackChange: false

  patternForOccurrence: null
  stayAtSamePosition: null
  stayOptionName: null
  stayByMarker: false
  restorePositions: true

  acceptPresetOccurrence: true
  acceptPersistentSelection: true
  acceptCurrentSelection: true

  needStay: ->
    @stayAtSamePosition ?
      (@isOccurrence() and settings.get('stayOnOccurrence')) or settings.get(@stayOptionName)

  needStayOnRestore: ->
    @stayAtSamePosition ?
      (@isOccurrence() and settings.get('stayOnOccurrence') and @occurrenceSelected) or settings.get(@stayOptionName)

  isOccurrence: ->
    @occurrence

  setOccurrence: (@occurrence) ->
    @occurrence

  setMarkForChange: (range) ->
    @vimState.mark.setRange('[', ']', range)

  needFlash: ->
    return unless @flashTarget
    {mode, submode} = @vimState
    if mode isnt 'visual' or (@target.isMotion() and submode isnt @target.wise)
      settings.get('flashOnOperate') and (@getName() not in settings.get('flashOnOperateBlacklist'))

  flashIfNecessary: (ranges) ->
    return unless @needFlash()
    @vimState.flash(ranges, type: @getFlashType())

  flashChangeIfNecessary: ->
    return unless @needFlash()

    @onDidFinishOperation =>
      if @flashCheckpoint is 'did-finish'
        ranges = @mutationManager.getMarkerBufferRanges().filter (range) -> not range.isEmpty()
      else
        ranges = @mutationManager.getBufferRangesForCheckpoint(@flashCheckpoint)
      @vimState.flash(ranges, type: @getFlashType())

  getFlashType: ->
    if @occurrenceSelected
      @flashTypeForOccurrence
    else
      @flashType

  trackChangeIfNecessary: ->
    return unless @trackChange

    @onDidFinishOperation =>
      if marker = @mutationManager.getMutationForSelection(@editor.getLastSelection())?.marker
        @setMarkForChange(marker.getBufferRange())

  constructor: ->
    super
    {@mutationManager, @occurrenceManager, @persistentSelection} = @vimState
    @subscribeResetOccurrencePatternIfNeeded()

    @initialize()
    @onDidSetOperatorModifier(@setModifier.bind(this))

    # When preset-occurrence was exists, operate on occurrence-wise
    if @acceptPresetOccurrence and @occurrenceManager.hasMarkers()
      @setOccurrence(true)

    # [FIXME] ORDER-MATTER
    # addOccurrencePattern pick cursor-word to find occurrence base pattern.
    # This has to be done BEFORE converting persistent-selection into real-selection.
    # Since when persistent-selection is actuall selected, it change cursor position.
    if @isOccurrence()
      @addOccurrencePattern() unless @occurrenceManager.hasMarkers()

    if @canSelectPersistentSelection()
      @selectPersistentSelection() # This change cursor position.
      unless @isMode('visual')
        @vimState.modeManager.activate('visual', swrap.detectVisualModeSubmode(@editor))
    @target = 'CurrentSelection' if @isMode('visual') and @acceptCurrentSelection
    @setTarget(@new(@target)) if _.isString(@target)

  subscribeResetOccurrencePatternIfNeeded: ->
    # [CAUTION]
    # This method has to be called in PROPER timing.
    # If occurrence is true but no preset-occurrence
    # Treat that `occurrence` is BOUNDED to operator itself, so cleanp at finished.
    if @occurrence and not @occurrenceManager.hasMarkers()
      @onDidResetOperationStack(@resetOccurrencePattern.bind(this))

  setModifier: (options) ->
    if options.wise?
      @wise = options.wise

    if options.occurrence?
      @setOccurrence(options.occurrence)
      if @isOccurrence()
        # Reset existing preset-occurrence. e.g. `c o p`, `d o f`
        @occurrenceManager.resetPatterns()
        @addOccurrencePattern()
        @onDidResetOperationStack(@resetOccurrencePattern.bind(this))

  canSelectPersistentSelection: ->
    @acceptPersistentSelection and
    @vimState.hasPersistentSelections() and
    settings.get('autoSelectPersistentSelectionOnOperate')

  selectPersistentSelection: ->
    pesistentRanges = @vimState.getPersistentSelectionBufferRanges()
    selectedRanges = @editor.getSelectedBufferRanges().filter(isNotEmpty)
    ranges = pesistentRanges.concat(selectedRanges)

    @editor.setSelectedBufferRanges(ranges)

    @vimState.clearPersistentSelections()
    @editor.mergeIntersectingSelections()
    @vimState.updateSelectionProperties()

  addOccurrencePattern: (pattern=null) ->
    pattern ?= @patternForOccurrence
    unless pattern?
      point = @getCursorBufferPosition()
      pattern = getWordPatternAtBufferPosition(@editor, point, singleNonWordChar: true)
    @occurrenceManager.addPattern(pattern)

  resetOccurrencePattern: ->
    @occurrenceManager.resetPatterns()

  # target is TextObject or Motion to operate on.
  setTarget: (@target) ->
    @target.setOperator(this)
    @emitDidSetTarget(this)
    this

  setTextToRegisterForSelection: (selection) ->
    @setTextToRegister(selection.getText(), selection)

  setTextToRegister: (text, selection) ->
    text += "\n" if (@target.isLinewise() and (not text.endsWith('\n')))
    @vimState.register.set({text, selection}) if text

  normalizeSelectionsIfNecessary: ->
    if @target?.isMotion() and @isMode('visual')
      @vimState.modeManager.normalizeSelections()

  startMutation: (fn) ->
    @emitWillMutateTarget()
    @normalizeSelectionsIfNecessary()
    @editor.transact(fn)
    @emitDidMutateTarget()

  # Main
  execute: ->
    canMutate = true
    stopMutation = -> canMutate = false

    @startMutation =>
      if @selectTarget()
        for selection in @editor.getSelections() when canMutate
          @mutateSelection(selection, stopMutation)
        @restoreCursorPositionsIfNecessary()

    # Even though we fail to select target and fail to mutate,
    # we have to return to normal-mode from operator-pending or visual
    @activateMode('normal')

  # Return true unless all selection is empty.
  selectTarget: ->
    @occurrenceSelected = false
    @mutationManager.init(
      isSelect: @instanceof('Select')
      useMarker: @needStay() and @stayByMarker
    )

    # Currently only motion have forceWise methods
    @target.forceWise?(@wise) if @wise?
    @emitWillSelectTarget()

    # Allow cursor position adjustment 'on-will-select-target' hook.
    # so checkpoint comes AFTER @emitWillSelectTarget()
    @mutationManager.setCheckpoint('will-select')

    # NOTE
    # Since MoveToNextOccurrence, MoveToPreviousOccurrence motion move by
    #  occurrence-marker, occurrence-marker has to be created BEFORE `@target.execute()`
    if @isRepeated() and @isOccurrence() and not @occurrenceManager.hasMarkers()
      @addOccurrencePattern()

    @target.execute()

    @mutationManager.setCheckpoint('did-select')
    if @isOccurrence()
      # To repoeat(`.`) operation where multiple occurrence patterns was set.
      # Here we save patterns which represent unioned regex which @occurrenceManager knows.
      @patternForOccurrence ?= @occurrenceManager.buildPattern()
      if @occurrenceManager.select()
        @occurrenceSelected = true
        @mutationManager.setCheckpoint('did-select-occurrence')

    if haveSomeNonEmptySelection(@editor) or @target.getName() is "Empty"
      @emitDidSelectTarget()
      @flashChangeIfNecessary()
      @trackChangeIfNecessary()
      true
    else
      false

  restoreCursorPositionsIfNecessary: ->
    return unless @restorePositions

    options =
      stay: @needStayOnRestore()
      occurrenceSelected: @occurrenceSelected
      isBlockwise: @target?.isBlockwise?()

    @mutationManager.restoreCursorPositions(options)
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
  acceptPresetOccurrence: false
  acceptPersistentSelection: false

  execute: ->
    @startMutation =>
      @selectTarget()
    if @target.isTextObject() and wise = @target.getWise()
      @activateModeIfNecessary('visual', wise)

class SelectLatestChange extends Select
  @extend()
  @description: "Select latest yanked or changed range"
  target: 'ALatestChange'

class SelectPreviousSelection extends Select
  @extend()
  target: "PreviousSelection"

class SelectPersistentSelection extends Select
  @extend()
  @description: "Select persistent-selection and clear all persistent-selection, it's like convert to real-selection"
  target: "APersistentSelection"

class SelectOccurrence extends Operator
  @extend()
  @description: "Add selection onto each matching word within target range"
  occurrence: true

  execute: ->
    @startMutation =>
      if @selectTarget()
        submode = swrap.detectVisualModeSubmode(@editor)
        @activateModeIfNecessary('visual', submode)

# Persistent Selection
# =========================
class CreatePersistentSelection extends Operator
  @extend()
  flashTarget: false
  stayAtSamePosition: true
  acceptPresetOccurrence: false
  acceptPersistentSelection: false

  initialize: ->
    @restorePositions = false if @isMode('visual', 'blockwise')

  mutateSelection: (selection) ->
    @persistentSelection.markBufferRange(selection.getBufferRange())

class TogglePersistentSelection extends CreatePersistentSelection
  @extend()

  isComplete: ->
    point = @editor.getCursorBufferPosition()
    if @markerToRemove = @persistentSelection.getMarkerAtPoint(point)
      true
    else
      super

  execute: ->
    if @markerToRemove
      @markerToRemove.destroy()
    else
      super

# Preset Occurrence
# =========================
class TogglePresetOccurrence extends Operator
  @extend()
  flashTarget: false
  requireTarget: false
  acceptPresetOccurrence: false
  acceptPersistentSelection: false

  execute: ->
    {@occurrenceManager} = @vimState
    if marker = @occurrenceManager.getMarkerAtPoint(@editor.getCursorBufferPosition())
      @occurrenceManager.destroyMarkers([marker])
    else
      pattern = null
      isNarrowed = @vimState.modeManager.isNarrowed()
      if @isMode('visual') and not isNarrowed
        text = @editor.getSelectedText()
        pattern = new RegExp(_.escapeRegExp(text), 'g')

      @addOccurrencePattern(pattern)
      @occurrenceManager.saveLastOccurrencePattern()
      @activateMode('normal') unless isNarrowed

class AddPresetOccurrenceFromLastOccurrencePattern extends TogglePresetOccurrence
  @extend()
  execute: ->
    if pattern = @vimState.globalState.get('lastOccurrencePattern')
      @occurrenceManager.resetPatterns()
      @addOccurrencePattern(pattern)
      @activateMode('normal')

# Delete
# ================================
class Delete extends Operator
  @extend()
  hover: icon: ':delete:', emoji: ':scissors:'
  trackChange: true
  flashCheckpoint: 'did-select-occurrence'
  flashTypeForOccurrence: 'operator-remove-occurrence'
  stayOptionName: 'stayOnDelete'

  execute: ->
    @onDidSelectTarget =>
      return if @occurrenceSelected
      if @target.isLinewise()
        @onDidRestoreCursorPositions =>
          @adjustCursor(cursor) for cursor in @editor.getCursors()
    super

  mutateSelection: (selection) =>
    @setTextToRegisterForSelection(selection)
    selection.deleteSelectedText()

  adjustCursor: (cursor) ->
    row = getValidVimBufferRow(@editor, cursor.getBufferRow())
    if @needStayOnRestore()
      point = @mutationManager.getInitialPointForSelection(cursor.selection)
      cursor.setBufferPosition([row, point.column])
    else
      cursor.setBufferPosition(@getFirstCharacterPositionForBufferRow(row))

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
  initialize: ->
    if @isMode('visual', 'blockwise')
      # FIXME Maybe because of bug of CurrentSelection,
      # we use MoveToLastCharacterOfLine as target
      @acceptCurrentSelection = false
      swrap.setReversedState(@editor, false) # Ensure all selections to un-reversed
    super

class DeleteLine extends Delete
  @extend()
  wise: 'linewise'

  initialize: ->
    super
    @target = 'MoveToRelativeLine' if @isMode('normal')

# Yank
# =========================
class Yank extends Operator
  @extend()
  hover: icon: ':yank:', emoji: ':clipboard:'
  trackChange: true
  stayOptionName: 'stayOnYank'

  mutateSelection: (selection) ->
    @setTextToRegisterForSelection(selection)

class YankLine extends Yank
  @extend()
  wise: 'linewise'

  initialize: ->
    super
    @target = 'MoveToRelativeLine' if @isMode('normal')

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
  stayOptionName: 'stayOnIncrease'
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

    @startMutation =>
      @selectTarget()
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
# Cursor placement:
# - place at end of mutation: paste non-multiline characterwise text
# - place at start of mutation: non-multiline characterwise text(characterwise, linewise)
class PutBefore extends Operator
  @extend()
  location: 'before'
  target: 'Empty'
  flashType: 'operator-long'
  restorePositions: false # manage manually
  flashTarget: true # manage manually
  trackChange: false # manage manually

  execute: ->
    @mutationsBySelection = new Map()
    @onDidMutateTarget(@adjustCursorPosition.bind(this))

    @onDidFinishOperation =>
      # TrackChange
      if newRange = @mutationsBySelection.get(@editor.getLastSelection())
        @setMarkForChange(newRange)

      # Flash
      if settings.get('flashOnOperate') and (@getName() not in settings.get('flashOnOperateBlacklist'))
        toRange = (selection) => @mutationsBySelection.get(selection)
        @vimState.flash(@editor.getSelections().map(toRange), type: @getFlashType())
    super

  adjustCursorPosition: ->
    for selection in @editor.getSelections()
      {cursor} = selection
      {start, end} = newRange = @mutationsBySelection.get(selection)
      @setMarkForChange(newRange) if selection.isLastSelection()
      if @linewisePaste
        moveCursorToFirstCharacterAtRow(cursor, start.row)
      else
        if newRange.isSingleLine()
          cursor.setBufferPosition(end.translate([0, -1]))
        else
          cursor.setBufferPosition(start)

  mutateSelection: (selection) ->
    {text, type} = @vimState.register.get(null, selection)
    return unless text
    text = _.multiplyString(text, @getCount())
    @linewisePaste = type is 'linewise' or @isMode('visual', 'linewise')
    newRange = @paste(selection, text, {linewise: @linewisePaste})
    @mutationsBySelection.set(selection, newRange)

  paste: (selection, text, {linewise}) ->
    if linewise
      @pasteLinewise(selection, text)
    else
      @pasteCharacterwise(selection, text)

  pasteCharacterwise: (selection, text) ->
    {cursor} = selection
    if selection.isEmpty() and @location is 'after' and not cursorIsAtEmptyRow(cursor)
      cursor.moveRight()
    return selection.insertText(text)

  # Return newRange
  pasteLinewise: (selection, text) ->
    {cursor} = selection
    cursorRow = cursor.getBufferRow()
    text += "\n" unless text.endsWith("\n")
    newRange = null
    if selection.isEmpty()
      if @location is 'before'
        newRange = setTextAtBufferPosition(@editor, [cursorRow, 0], text)
        setBufferRow(cursor, newRange.start.row)
      else if @location is 'after'
        ensureEndsWithNewLineForBufferRow(@editor, cursorRow)
        newRange = setTextAtBufferPosition(@editor, [cursorRow + 1, 0], text)
    else
      selection.insertText("\n") unless @isMode('visual', 'linewise')
      newRange = selection.insertText(text)

    return newRange

class PutAfter extends PutBefore
  @extend()
  location: 'after'

class Mark extends Operator
  @extend()
  # hover: icon: ':mark:', emoji: ':round_pushpin:'
  recordable: false
  requireInput: true
  requireTarget: false
  acceptPersistentSelection: false
  initialize: ->
    @focusInput()

  execute: ->
    @vimState.mark.set(@input, @editor.getCursorBufferPosition())
    @activateMode('normal')

class AddBlankLineBelow extends Operator
  @extend()
  flashTarget: false
  target: "Empty"
  stayAtSamePosition: true
  stayByMarker: true
  where: 'below'

  mutateSelection: (selection, stopMutation) ->
    row = selection.getHeadBufferPosition().row
    row += 1 if @where is 'below'
    point = [row, 0]
    @editor.setTextInBufferRange([point, point], "\n".repeat(@getCount()))

class AddBlankLineAbove extends AddBlankLineBelow
  @extend()
  where: 'above'
