_ = require 'underscore-plus'
{
  haveSomeNonEmptySelection
  getValidVimBufferRow
  isEmptyRow
  getWordPatternAtBufferPosition
  getSubwordPatternAtBufferPosition
  insertTextAtBufferPosition
  setBufferRow
  moveCursorToFirstCharacterAtRow
  ensureEndsWithNewLineForBufferRow
} = require './utils'
swrap = require './selection-wrapper'
Base = require './base'

class Operator extends Base
  @extend(false)
  requireTarget: true
  recordable: true

  wise: null
  occurrence: false
  occurrenceType: 'base'

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

  bufferCheckpointByPurpose: null
  mutateSelectionOrderd: false

  # Experimentaly allow selectTarget before input Complete
  # -------------------------
  supportEarlySelect: false
  targetSelected: null
  canEarlySelect: ->
    @supportEarlySelect and not @isRepeated()
  # -------------------------

  # Called when operation finished
  # This is essentially to reset state for `.` repeat.
  resetState: ->
    @targetSelected = null
    @occurrenceSelected = false

  # Two checkpoint for different purpose
  # - one for undo(handled by modeManager)
  # - one for preserve last inserted text
  createBufferCheckpoint: (purpose) ->
    @bufferCheckpointByPurpose ?= {}
    @bufferCheckpointByPurpose[purpose] = @editor.createCheckpoint()

  getBufferCheckpoint: (purpose) ->
    @bufferCheckpointByPurpose?[purpose]

  deleteBufferCheckpoint: (purpose) ->
    if @bufferCheckpointByPurpose?
      delete @bufferCheckpointByPurpose[purpose]

  groupChangesSinceBufferCheckpoint: (purpose) ->
    if checkpoint = @getBufferCheckpoint(purpose)
      @editor.groupChangesSinceCheckpoint(checkpoint)
      @deleteBufferCheckpoint(purpose)

  needStay: ->
    @stayAtSamePosition ?
      (@isOccurrence() and @getConfig('stayOnOccurrence')) or @getConfig(@stayOptionName)

  needStayOnRestore: ->
    @stayAtSamePosition ?
      (@isOccurrence() and @getConfig('stayOnOccurrence') and @occurrenceSelected) or @getConfig(@stayOptionName)

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
      @getConfig('flashOnOperate') and (@getName() not in @getConfig('flashOnOperateBlacklist'))

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
    # To pick cursor-word to find occurrence base pattern.
    # This has to be done BEFORE converting persistent-selection into real-selection.
    # Since when persistent-selection is actuall selected, it change cursor position.
    if @isOccurrence() and not @occurrenceManager.hasMarkers()
      @occurrenceManager.addPattern(@patternForOccurrence ? @getPatternForOccurrenceType(@occurrenceType))

    # This change cursor position.
    if @selectPersistentSelectionIfNecessary()
      if @isMode('visual')
        # [FIXME] Sync selection-wise this phase?
        # e.g. selected persisted selection convert to vB sel in vB-mode?
        null
      else
        @vimState.modeManager.activate('visual', swrap.detectWise(@editor))

    @target = 'CurrentSelection' if @isMode('visual') and @acceptCurrentSelection
    @setTarget(@new(@target)) if _.isString(@target)

  subscribeResetOccurrencePatternIfNeeded: ->
    # [CAUTION]
    # This method has to be called in PROPER timing.
    # If occurrence is true but no preset-occurrence
    # Treat that `occurrence` is BOUNDED to operator itself, so cleanp at finished.
    if @occurrence and not @occurrenceManager.hasMarkers()
      @onDidResetOperationStack(=> @occurrenceManager.resetPatterns())

  setModifier: (options) ->
    if options.wise?
      @wise = options.wise
      return

    if options.occurrence?
      @setOccurrence(options.occurrence)
      if @isOccurrence()
        @occurrenceType = options.occurrenceType
        # This is o modifier case(e.g. `c o p`, `d O f`)
        # We RESET existing occurence-marker when `o` or `O` modifier is typed by user.
        pattern = @getPatternForOccurrenceType(@occurrenceType)
        @occurrenceManager.addPattern(pattern, {reset: true, @occurrenceType})
        @onDidResetOperationStack(=> @occurrenceManager.resetPatterns())

  # return true/false to indicate success
  selectPersistentSelectionIfNecessary: ->
    if @acceptPersistentSelection and
        @getConfig('autoSelectPersistentSelectionOnOperate') and
        not @persistentSelection.isEmpty()

      @persistentSelection.select()
      @editor.mergeIntersectingSelections()
      swrap.saveProperties(@editor)

      true
    else
      false

  getPatternForOccurrenceType: (occurrenceType) ->
    switch occurrenceType
      when 'base'
        getWordPatternAtBufferPosition(@editor, @getCursorBufferPosition())
      when 'subword'
        getSubwordPatternAtBufferPosition(@editor, @getCursorBufferPosition())

  # target is TextObject or Motion to operate on.
  setTarget: (@target) ->
    @target.setOperator(this)
    @emitDidSetTarget(this)

    if @canEarlySelect()
      @normalizeSelectionsIfNecessary()
      @createBufferCheckpoint('undo')
      @selectTarget()
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
    if @canEarlySelect()
      # - Skip selection normalization: already normalized before @selectTarget()
      # - Manual checkpoint grouping: to create checkpoint before @selectTarget()
      fn()
      @emitWillFinishMutation()
      @groupChangesSinceBufferCheckpoint('undo')

    else
      @normalizeSelectionsIfNecessary()
      @editor.transact =>
        fn()
        @emitWillFinishMutation()

    @emitDidFinishMutation()

  # Main
  execute: ->
    @startMutation =>
      if @selectTarget()
        if @mutateSelectionOrderd
          selections = @editor.getSelectionsOrderedByBufferPosition()
        else
          selections = @editor.getSelections()
        for selection in selections
          @mutateSelection(selection)
        @restoreCursorPositionsIfNecessary()

    # Even though we fail to select target and fail to mutate,
    # we have to return to normal-mode from operator-pending or visual
    @activateMode('normal')

  # Return true unless all selection is empty.
  selectTarget: ->
    return @targetSelected if @targetSelected?
    @mutationManager.init(useMarker: @needStay() and @stayByMarker)

    # Currently only motion have forceWise methods
    @target.forceWise?(@wise) if @wise?
    @emitWillSelectTarget()

    # Allow cursor position adjustment 'on-will-select-target' hook.
    # so checkpoint comes AFTER @emitWillSelectTarget()
    @mutationManager.setCheckpoint('will-select')

    # NOTE
    # Since MoveToNextOccurrence, MoveToPreviousOccurrence motion move by
    #  occurrence-marker, occurrence-marker has to be created BEFORE `@target.execute()`
    # And when repeated, occurrence pattern is already cached at @patternForOccurrence
    if @isRepeated() and @isOccurrence() and not @occurrenceManager.hasMarkers()
      @occurrenceManager.addPattern(@patternForOccurrence, {@occurrenceType})

    @target.execute()

    @mutationManager.setCheckpoint('did-select')
    if @isOccurrence()
      # To repoeat(`.`) operation where multiple occurrence patterns was set.
      # Here we save patterns which represent unioned regex which @occurrenceManager knows.
      @patternForOccurrence ?= @occurrenceManager.buildPattern()

      if @occurrenceManager.select()
        # To skip restoreing position from selection prop when shift visual-mode submode on SelectOccurrence
        swrap.clearProperties(@editor)

        @occurrenceSelected = true
        @mutationManager.setCheckpoint('did-select-occurrence')

    if haveSomeNonEmptySelection(@editor) or @target.getName() is "Empty"
      @emitDidSelectTarget()
      @flashChangeIfNecessary()
      @trackChangeIfNecessary()
      @targetSelected = true
      true
    else
      @emitDidFailSelectTarget()
      @targetSelected = false
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
    @startMutation(@selectTarget.bind(this))
    if @target.isTextObject() and wise = @target.getWise()
      if @isMode('visual')
        switch wise
          when 'characterwise'
            swrap.saveProperties(@editor)
          when 'linewise'
            swrap.fixPropertiesForLinewise(@editor)
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
        @activateModeIfNecessary('visual', swrap.detectWise(@editor))

# Persistent Selection
# =========================
class CreatePersistentSelection extends Operator
  @extend()
  flashTarget: false
  stayAtSamePosition: true
  acceptPresetOccurrence: false
  acceptPersistentSelection: false

  execute: ->
    @restorePositions = not @isMode('visual', 'blockwise')
    super

  mutateSelection: (selection) ->
    @persistentSelection.markBufferRange(selection.getBufferRange())

class TogglePersistentSelection extends CreatePersistentSelection
  @extend()

  isComplete: ->
    point = @editor.getCursorBufferPosition()
    @markerToRemove = @persistentSelection.getMarkerAtPoint(point)
    if @markerToRemove
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
  occurrenceType: 'base'

  execute: ->
    if marker = @occurrenceManager.getMarkerAtPoint(@editor.getCursorBufferPosition())
      @occurrenceManager.destroyMarkers([marker])
    else
      pattern = null
      isNarrowed = @vimState.modeManager.isNarrowed()

      if @isMode('visual') and not isNarrowed
        @occurrenceType = 'base'
        pattern = new RegExp(_.escapeRegExp(@editor.getSelectedText()), 'g')
      else
        pattern = @getPatternForOccurrenceType(@occurrenceType)

      @occurrenceManager.addPattern(pattern, {@occurrenceType})
      @occurrenceManager.saveLastPattern(@occurrenceType)

      @activateMode('normal') unless isNarrowed

class TogglePresetSubwordOccurrence extends TogglePresetOccurrence
  @extend()
  occurrenceType: 'subword'

# Want to rename RestoreOccurrenceMarker
class AddPresetOccurrenceFromLastOccurrencePattern extends TogglePresetOccurrence
  @extend()
  execute: ->
    @occurrenceManager.resetPatterns()
    if pattern = @vimState.globalState.get('lastOccurrencePattern')
      occurrenceType = @vimState.globalState.get("lastOccurrenceType")
      @occurrenceManager.addPattern(pattern, {occurrenceType})
      @activateMode('normal')

# Delete
# ================================
class Delete extends Operator
  @extend()
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
  target: "MoveToRelativeLine"

# Yank
# =========================
class Yank extends Operator
  @extend()
  trackChange: true
  stayOptionName: 'stayOnYank'

  mutateSelection: (selection) ->
    @setTextToRegisterForSelection(selection)

class YankLine extends Yank
  @extend()
  wise: 'linewise'
  target: "MoveToRelativeLine"

class YankToLastCharacterOfLine extends Yank
  @extend()
  target: 'MoveToLastCharacterOfLine'

# -------------------------
# [ctrl-a]
class Increase extends Operator
  @extend()
  target: "InnerCurrentLine" # ctrl-a in normal-mode find target number in CurrentLine
  flashTarget: false # do manually
  restorePositions: false # do manually
  step: 1

  execute: ->
    @newRanges = []
    super
    if @newRanges.length
      if @getConfig('flashOnOperate') and (@getName() not in @getConfig('flashOnOperateBlacklist'))
        @vimState.flash(@newRanges, type: @flashTypeForOccurrence)

  replaceNumberInBufferRange: (scanRange, fn=null) ->
    newRanges = []
    @pattern ?= ///#{@getConfig('numberRegex')}///g
    @scanForward @pattern, {scanRange}, (event) =>
      return if fn? and not fn(event)
      {matchText, replace} = event
      nextNumber = @getNextNumber(matchText)
      newRanges.push(replace(String(nextNumber)))
    newRanges

  mutateSelection: (selection) ->
    scanRange = selection.getBufferRange()
    if @instanceof('IncrementNumber') or @target.is('CurrentSelection')
      @newRanges.push(@replaceNumberInBufferRange(scanRange)...)
      selection.cursor.setBufferPosition(scanRange.start)
    else
      # ctrl-a, ctrl-x in `normal-mode`
      initialPoint = @mutationManager.getInitialPointForSelection(selection)
      newRanges = @replaceNumberInBufferRange scanRange, ({range, stop}) ->
        if range.end.isGreaterThan(initialPoint)
          stop()
          true
        else
          false

      point = newRanges[0]?.end.translate([0, -1]) ? initialPoint
      selection.cursor.setBufferPosition(point)

  getNextNumber: (numberString) ->
    Number.parseInt(numberString, 10) + @step * @getCount()

# [ctrl-x]
class Decrease extends Increase
  @extend()
  step: -1

# -------------------------
# [g ctrl-a]
class IncrementNumber extends Increase
  @extend()
  baseNumber: null
  target: null
  mutateSelectionOrderd: true

  getNextNumber: (numberString) ->
    if @baseNumber?
      @baseNumber += @step * @getCount()
    else
      @baseNumber = Number.parseInt(numberString, 10)
    @baseNumber

# [g ctrl-x]
class DecrementNumber extends IncrementNumber
  @extend()
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
    {text, type} = @vimState.register.get(null, @editor.getLastSelection())
    return unless text
    @onDidFinishMutation(@adjustCursorPosition.bind(this))

    @onDidFinishOperation =>
      # TrackChange
      if newRange = @mutationsBySelection.get(@editor.getLastSelection())
        @setMarkForChange(newRange)

      # Flash
      if @getConfig('flashOnOperate') and (@getName() not in @getConfig('flashOnOperateBlacklist'))
        toRange = (selection) => @mutationsBySelection.get(selection)
        @vimState.flash(@editor.getSelections().map(toRange), type: @getFlashType())

    super

  adjustCursorPosition: ->
    for selection in @editor.getSelections()
      {cursor} = selection
      {start, end} = newRange = @mutationsBySelection.get(selection)
      if @linewisePaste
        moveCursorToFirstCharacterAtRow(cursor, start.row)
      else
        if newRange.isSingleLine()
          cursor.setBufferPosition(end.translate([0, -1]))
        else
          cursor.setBufferPosition(start)

  mutateSelection: (selection) ->
    {text, type} = @vimState.register.get(null, selection)
    text = _.multiplyString(text, @getCount())
    @linewisePaste = type is 'linewise' or @isMode('visual', 'linewise')
    newRange = @paste(selection, text, {@linewisePaste})
    @mutationsBySelection.set(selection, newRange)

  paste: (selection, text, {linewisePaste}) ->
    if linewisePaste
      @pasteLinewise(selection, text)
    else
      @pasteCharacterwise(selection, text)

  pasteCharacterwise: (selection, text) ->
    {cursor} = selection
    if selection.isEmpty() and @location is 'after' and not isEmptyRow(@editor, cursor.getBufferRow())
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
        newRange = insertTextAtBufferPosition(@editor, [cursorRow, 0], text)
        setBufferRow(cursor, newRange.start.row)
      else if @location is 'after'
        ensureEndsWithNewLineForBufferRow(@editor, cursorRow)
        newRange = insertTextAtBufferPosition(@editor, [cursorRow + 1, 0], text)
    else
      selection.insertText("\n") unless @isMode('visual', 'linewise')
      newRange = selection.insertText(text)

    return newRange

class PutAfter extends PutBefore
  @extend()
  location: 'after'

class AddBlankLineBelow extends Operator
  @extend()
  flashTarget: false
  target: "Empty"
  stayAtSamePosition: true
  stayByMarker: true
  where: 'below'

  mutateSelection: (selection) ->
    row = selection.getHeadBufferPosition().row
    row += 1 if @where is 'below'
    point = [row, 0]
    @editor.setTextInBufferRange([point, point], "\n".repeat(@getCount()))

class AddBlankLineAbove extends AddBlankLineBelow
  @extend()
  where: 'above'
