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
  trackChange: false

  patternForOccurrence: null
  stayAtSamePosition: null
  stayOptionName: null
  stayByMarker: false
  restorePositions: true

  acceptPresetOccurrence: true
  acceptPersistentSelection: true

  needStay: ->
    @stayAtSamePosition ?= (@stayOptionName? and settings.get(@stayOptionName))

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
    @vimState.flash(ranges, type: 'operator')

  flashChangeIfNecessary: ->
    return unless @needFlash()

    @onDidFinishOperation =>
      ranges = @mutationManager.getMarkerBufferRanges().filter (range) -> not range.isEmpty()
      if ranges.length
        @flashIfNecessary(ranges)

  trackChangeIfNecessary: ->
    return unless @trackChange

    @onDidFinishOperation =>
      if marker = @mutationManager.getMutationForSelection(@editor.getLastSelection())?.marker
        @setMarkForChange(marker.getBufferRange())

  constructor: ->
    super
    {@mutationManager, @occurrenceManager, @persistentSelection} = @vimState

    @initialize()
    @onDidSetOperatorModifier(@setModifier.bind(this))

    # When preset-occurrence was exists, operate on occurrence-wise
    if @acceptPresetOccurrence and @occurrenceManager.hasMarkers()
      @setOccurrence(true)

    # [FIXME] ORDER-MATTER
    # addOccurrencePattern pick cursor-word to find occurrence base pattern.
    # This has to be done BEFORE converting persistent-selection into real-selection.
    # Since when persistent-selection is actuall selected, it change cursor position.
    @_originalCursorPosition = @getCursorBufferPosition()

    if @isOccurrence()
      @addOccurrencePattern() unless @occurrenceManager.hasMarkers()

    if @canSelectPersistentSelection()
      @selectPersistentSelection() # This change cursor position.
      unless @isMode('visual')
        @vimState.modeManager.activate('visual', swrap.detectVisualModeSubmode(@editor))
    @target = 'CurrentSelection' if @isMode('visual')
    @setTarget(@new(@target)) if _.isString(@target)

    if @acceptPersistentSelection # ??? shouldn't this @acceptPresetOccurrence ?
      @subscribe @onDidDeactivateMode ({mode}) =>
        @occurrenceManager.resetPatterns() if mode is 'operator-pending'

  setModifier: (options) ->
    if options.wise?
      @wise = options.wise

    if options.occurrence?
      @setOccurrence(options.occurrence)
      if @isOccurrence()
        # Reset existing preset-occurrence. e.g. `c o p`, `d o f`
        @occurrenceManager.resetPatterns()
        @addOccurrencePattern()

  canSelectPersistentSelection: ->
    @acceptPersistentSelection and
    @vimState.hasPersistentSelections() and
    settings.get('autoSelectPersistentSelectionOnOperate')

  selectPersistentSelection: ->
    pesistentRanges = @vimState.getPersistentSelectionBufferRanges()
    selectedRanges = @editor.getSelectedBufferRanges().filter (range) -> not range.isEmpty()
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

  # Main
  execute: ->
    canMutate = true
    stopMutation = -> canMutate = false
    if @selectTarget()
      @editor.transact =>
        for selection in @editor.getSelections() when canMutate
          @mutateSelection(selection, stopMutation)
      @restoreCursorPositionsIfNecessary()

    # Even though we fail to select target and fail to mutate,
    # we have to return to normal-mode from operator-pending or visual
    @activateMode('normal')

  selectOccurrence: ->
    # In `.` repeated case, initailize() is never called so need to set here.
    if @isRepeated() and not @occurrenceManager.hasMarkers()
      @addOccurrencePattern()

    # To repoeat(`.`) operation where multiple occurrence patterns was set.
    # Here we save patterns which resresent unioned regex which @occurrenceManager knows.
    @patternForOccurrence ?= @occurrenceManager.buildPattern()

    selectedRanges = @editor.getSelectedBufferRanges()
    ranges = @occurrenceManager.getMarkerRangesIntersectsWithRanges(selectedRanges, @isMode('visual'))

    if ranges.length
      if @isMode('visual')
        @vimState.modeManager.deactivate()
        # So that SelectOccurrence can acivivate visual-mode with correct range, we have to unset submode here.
        @vimState.submode = null

      if rangeForLastSelection = _.detect(ranges, (range) -> range.containsPoint(@_originalCursorPosition))
        _.remove(ranges, rangeForLastSelection)
        ranges.push(rangeForLastSelection)

      @editor.setSelectedBufferRanges(ranges)

    else
      @mutationManager.restoreInitialPositions() # Restoreing position also clear selection.
    @occurrenceManager.resetPatterns()

  # Return true unless all selection is empty.
  selectTarget: ->
    @mutationManager.init
      isSelect: @instanceof('Select')
      useMarker: @needStay() and @stayByMarker
    @mutationManager.setCheckPoint('will-select')

    # Currently only motion have forceWise methods
    @target.forceWise?(@wise) if @wise?
    @emitWillSelectTarget()

    @target.select()
    @selectOccurrence() if @isOccurrence()

    if haveSomeNonEmptySelection(@editor) or @target.getName() is "Empty"
      @mutationManager.setCheckPoint('did-select')
      @emitDidSelectTarget()
      @flashChangeIfNecessary()
      @trackChangeIfNecessary()
      true
    else
      false

  restoreCursorPositionsIfNecessary: ->
    return unless @restorePositions

    options =
      stay: @needStay()
      strict: @isOccurrence()
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
  initialize: ->
    super
    @onDidSelectTarget =>
      swrap.clearProperties(@editor)

  execute: ->
    if @selectTarget()
      submode = swrap.detectVisualModeSubmode(@editor)
      @activateModeIfNecessary('visual', submode)

# Range Marker
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

  execute: ->
    {@occurrenceManager} = @vimState
    if marker = @occurrenceManager.getMarkerAtPoint(@editor.getCursorBufferPosition())
      marker.destroy()
    else
      pattern = null
      isNarrowed = @vimState.modeManager.isNarrowed()
      if @isMode('visual') and not isNarrowed
        text = @editor.getSelectedText()
        pattern = new RegExp(_.escapeRegExp(text), 'g')

      @addOccurrencePattern(pattern)
      @activateMode('normal') unless isNarrowed

# Delete
# ================================
class Delete extends Operator
  @extend()
  hover: icon: ':delete:', emoji: ':scissors:'
  trackChange: true
  flashTarget: false
  stayOptionName: 'stayOnDelete'

  execute: ->
    @onDidSelectTarget =>
      @requestAdjustCursorPositions() if @target.isLinewise()
    super

  mutateSelection: (selection) =>
    @setTextToRegisterForSelection(selection)
    selection.deleteSelectedText()

  requestAdjustCursorPositions: ->
    @onDidRestoreCursorPositions =>
      for cursor in @editor.getCursors()
        @adjustCursor(cursor)

  adjustCursor: (cursor) ->
    row = getValidVimBufferRow(@editor, cursor.getBufferRow())
    if @needStay()
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
  execute: ->
    # Ensure all selections to un-reversed
    if @isMode('visual', 'blockwise')
      for selection in @editor.getSelections()
        swrap(selection).extendToEOL()
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
  restorePositions: false
  location: 'before'

  initialize: ->
    @target = 'Empty' if @isMode('normal')

  mutateSelection: (selection) ->
    {text, type} = @vimState.register.get(null, selection)
    return unless text

    text = _.multiplyString(text, @getCount())
    linewise = (type is 'linewise') or @isMode('visual', 'linewise')
    @paste(selection, text, {linewise, @selectPastedText})

  paste: (selection, text, {linewise, selectPastedText}) ->
    {cursor} = selection
    if linewise
      newRange = @pasteLinewise(selection, text)
      adjustCursor = (range) ->
        cursor.setBufferPosition(range.start)
        cursor.moveToFirstCharacterOfLine()
    else
      newRange = @pasteCharacterwise(selection, text)
      adjustCursor = (range) ->
        cursor.setBufferPosition(range.end.translate([0, -1]))

    @setMarkForChange(newRange)
    if selectPastedText
      selection.setBufferRange(newRange)
    else
      adjustCursor(newRange)

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
          # Possible in last buffer line not have ending newLine
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

  activateMode: ->
    submode = swrap.detectVisualModeSubmode(@editor)
    unless @vimState.isMode('visual', submode)
      super('visual', submode)

class PutAfterAndSelect extends PutBeforeAndSelect
  @extend()
  @description: "Paste after then select"
  location: 'after'

class Mark extends Operator
  @extend()
  # hover: icon: ':mark:', emoji: ':round_pushpin:'
  requireInput: true
  requireTarget: false
  initialize: ->
    @focusInput()

  execute: ->
    @vimState.mark.set(@input, @editor.getCursorBufferPosition())
    @activateMode('normal')
