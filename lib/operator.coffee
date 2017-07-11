_ = require 'underscore-plus'
{
  isEmptyRow
  getWordPatternAtBufferPosition
  getSubwordPatternAtBufferPosition
  insertTextAtBufferPosition
  setBufferRow
  moveCursorToFirstCharacterAtRow
  ensureEndsWithNewLineForBufferRow
  adjustIndentWithKeepingLayout
} = require './utils'
Base = require './base'

class Operator extends Base
  @extend(false)
  @operationKind: 'operator'
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
  setToFirstCharacterOnLinewise: false

  acceptPresetOccurrence: true
  acceptPersistentSelection: true

  bufferCheckpointByPurpose: null
  mutateSelectionOrderd: false

  # Experimentaly allow selectTarget before input Complete
  # -------------------------
  supportEarlySelect: false
  targetSelected: null
  canEarlySelect: ->
    @supportEarlySelect and not @repeated
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

  setMarkForChange: (range) ->
    @vimState.mark.set('[', range.start)
    @vimState.mark.set(']', range.end)

  needFlash: ->
    @flashTarget and @getConfig('flashOnOperate') and
      (@name not in @getConfig('flashOnOperateBlacklist')) and
      ((@mode isnt 'visual') or (@submode isnt @target.wise)) # e.g. Y in vC

  flashIfNecessary: (ranges) ->
    if @needFlash()
      @vimState.flash(ranges, type: @getFlashType())

  flashChangeIfNecessary: ->
    if @needFlash()
      @onDidFinishOperation =>
        ranges = @mutationManager.getSelectedBufferRangesForCheckpoint(@flashCheckpoint)
        @vimState.flash(ranges, type: @getFlashType())

  getFlashType: ->
    if @occurrenceSelected
      @flashTypeForOccurrence
    else
      @flashType

  trackChangeIfNecessary: ->
    return unless @trackChange

    @onDidFinishOperation =>
      if range = @mutationManager.getMutatedBufferRangeForSelection(@editor.getLastSelection())
        @setMarkForChange(range)

  constructor: ->
    super
    {@mutationManager, @occurrenceManager, @persistentSelection} = @vimState
    @subscribeResetOccurrencePatternIfNeeded()
    @initialize()
    @onDidSetOperatorModifier(@setModifier.bind(this))

    # When preset-occurrence was exists, operate on occurrence-wise
    if @acceptPresetOccurrence and @occurrenceManager.hasMarkers()
      @occurrence = true

    # [FIXME] ORDER-MATTER
    # To pick cursor-word to find occurrence base pattern.
    # This has to be done BEFORE converting persistent-selection into real-selection.
    # Since when persistent-selection is actuall selected, it change cursor position.
    if @occurrence and not @occurrenceManager.hasMarkers()
      @occurrenceManager.addPattern(@patternForOccurrence ? @getPatternForOccurrenceType(@occurrenceType))


    # This change cursor position.
    if @selectPersistentSelectionIfNecessary()
      # [FIXME] selection-wise is not synched if it already visual-mode
      unless @mode is 'visual'
        @vimState.modeManager.activate('visual', @swrap.detectWise(@editor))

    @target = 'CurrentSelection' if @mode is 'visual' and @requireTarget
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
      @occurrence = options.occurrence
      if @occurrence
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
      for $selection in @swrap.getSelections(@editor) when not $selection.hasProperties()
        $selection.saveProperties()
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
    @target.operator = this
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
    @vimState.register.set(null, {text, selection}) if text

  normalizeSelectionsIfNecessary: ->
    if @target?.isMotion() and (@mode is 'visual')
      @swrap.normalize(@editor)

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
        @mutationManager.setCheckpoint('did-finish')
        @restoreCursorPositionsIfNecessary()

    # Even though we fail to select target and fail to mutate,
    # we have to return to normal-mode from operator-pending or visual
    @activateMode('normal')

  # Return true unless all selection is empty.
  selectTarget: ->
    return @targetSelected if @targetSelected?
    @mutationManager.init({@stayByMarker})

    @target.forceWise(@wise) if @wise?
    @emitWillSelectTarget()

    # Allow cursor position adjustment 'on-will-select-target' hook.
    # so checkpoint comes AFTER @emitWillSelectTarget()
    @mutationManager.setCheckpoint('will-select')

    # NOTE
    # Since MoveToNextOccurrence, MoveToPreviousOccurrence motion move by
    #  occurrence-marker, occurrence-marker has to be created BEFORE `@target.execute()`
    # And when repeated, occurrence pattern is already cached at @patternForOccurrence
    if @repeated and @occurrence and not @occurrenceManager.hasMarkers()
      @occurrenceManager.addPattern(@patternForOccurrence, {@occurrenceType})

    @target.execute()

    @mutationManager.setCheckpoint('did-select')
    if @occurrence
      # To repoeat(`.`) operation where multiple occurrence patterns was set.
      # Here we save patterns which represent unioned regex which @occurrenceManager knows.
      @patternForOccurrence ?= @occurrenceManager.buildPattern()

      if @occurrenceManager.select()
        @occurrenceSelected = true
        @mutationManager.setCheckpoint('did-select-occurrence')

    if @targetSelected = @vimState.haveSomeNonEmptySelection() or @target.name is "Empty"
      @emitDidSelectTarget()
      @flashChangeIfNecessary()
      @trackChangeIfNecessary()
    else
      @emitDidFailSelectTarget()
    return @targetSelected

  restoreCursorPositionsIfNecessary: ->
    return unless @restorePositions
    stay = @stayAtSamePosition ? @getConfig(@stayOptionName) or (@occurrenceSelected and @getConfig('stayOnOccurrence'))
    wise = if @occurrenceSelected then 'characterwise' else @target.wise
    @mutationManager.restoreCursorPositions({stay, wise, @setToFirstCharacterOnLinewise})

# Select
# When text-object is invoked from normal or viusal-mode, operation would be
#  => Select operator with target=text-object
# When motion is invoked from visual-mode, operation would be
#  => Select operator with target=motion)
# ================================
# Select is used in TWO situation.
# - visual-mode operation
#   - e.g: `v l`, `V j`, `v i p`...
# - Directly invoke text-object from normal-mode
#   - e.g: Invoke `Inner Paragraph` from command-palette.
class Select extends Operator
  @extend(false)
  flashTarget: false
  recordable: false
  acceptPresetOccurrence: false
  acceptPersistentSelection: false

  execute: ->
    @startMutation(@selectTarget.bind(this))

    if @target.isTextObject() and @target.selectSucceeded
      @editor.scrollToCursorPosition()
      @activateModeIfNecessary('visual', @target.wise)

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
        @activateModeIfNecessary('visual', 'characterwise')

# Persistent Selection
# =========================
class CreatePersistentSelection extends Operator
  @extend()
  flashTarget: false
  stayAtSamePosition: true
  acceptPresetOccurrence: false
  acceptPersistentSelection: false

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
  target: "Empty"
  flashTarget: false
  acceptPresetOccurrence: false
  acceptPersistentSelection: false
  occurrenceType: 'base'

  execute: ->
    if marker = @occurrenceManager.getMarkerAtPoint(@editor.getCursorBufferPosition())
      @occurrenceManager.destroyMarkers([marker])
    else
      pattern = null
      isNarrowed = @vimState.modeManager.isNarrowed()

      if @mode is 'visual' and not isNarrowed
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
  setToFirstCharacterOnLinewise: true

  execute: ->
    if @target.wise is 'blockwise'
      @restorePositions = false
    super

  mutateSelection: (selection) =>
    @setTextToRegisterForSelection(selection)
    selection.deleteSelectedText()

class DeleteRight extends Delete
  @extend()
  target: 'MoveRight'

class DeleteLeft extends Delete
  @extend()
  target: 'MoveLeft'

class DeleteToLastCharacterOfLine extends Delete
  @extend()
  target: 'MoveToLastCharacterOfLine'

  execute: ->
    if @target.wise is 'blockwise'
      @onDidSelectTarget =>
        for blockwiseSelection in @getBlockwiseSelections()
          blockwiseSelection.extendMemberSelectionsToEndOfLine()
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
  target: "Empty" # ctrl-a in normal-mode find target number in current line manually
  flashTarget: false # do manually
  restorePositions: false # do manually
  step: 1

  execute: ->
    @newRanges = []
    super
    if @newRanges.length
      if @getConfig('flashOnOperate') and @name not in @getConfig('flashOnOperateBlacklist')
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
    {cursor} = selection
    if @target.is('Empty') # ctrl-a, ctrl-x in `normal-mode`
      cursorPosition = cursor.getBufferPosition()
      scanRange = @editor.bufferRangeForBufferRow(cursorPosition.row)
      newRanges = @replaceNumberInBufferRange scanRange, ({range, stop}) ->
        if range.end.isGreaterThan(cursorPosition)
          stop()
          true
        else
          false

      point = newRanges[0]?.end.translate([0, -1]) ? cursorPosition
      cursor.setBufferPosition(point)
    else
      scanRange = selection.getBufferRange()
      @newRanges.push(@replaceNumberInBufferRange(scanRange)...)
      cursor.setBufferPosition(scanRange.start)

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
      if @getConfig('flashOnOperate') and @name not in @getConfig('flashOnOperateBlacklist')
        toRange = (selection) => @mutationsBySelection.get(selection)
        @vimState.flash(@editor.getSelections().map(toRange), type: @getFlashType())

    super

  adjustCursorPosition: ->
    for selection in @editor.getSelections() when @mutationsBySelection.has(selection)
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
        targetRow = @getFoldEndRowForRow(cursorRow)
        ensureEndsWithNewLineForBufferRow(@editor, targetRow)
        newRange = insertTextAtBufferPosition(@editor, [targetRow + 1, 0], text)
    else
      selection.insertText("\n") unless @isMode('visual', 'linewise')
      newRange = selection.insertText(text)

    return newRange

class PutAfter extends PutBefore
  @extend()
  location: 'after'

class PutBeforeWithAutoIndent extends PutBefore
  @extend()

  pasteLinewise: (selection, text) ->
    newRange = super
    adjustIndentWithKeepingLayout(@editor, newRange)
    return newRange

class PutAfterWithAutoIndent extends PutBeforeWithAutoIndent
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
