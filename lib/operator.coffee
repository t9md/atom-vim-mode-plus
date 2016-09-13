LineEndingRegExp = /(?:\n|\r\n)$/
_ = require 'underscore-plus'
globalState = require './global-state'

{
  haveSomeSelection
  highlightRanges
  isEndsWithNewLineForBufferRow
  getCurrentWordBufferRange
  getBufferRangeForPatternFromPoint
  cursorIsOnWhiteSpace
  cursorIsAtEmptyRow
  scanInRanges
  getCharacterAtCursor
} = require './utils'
swrap = require './selection-wrapper'
settings = require './settings'
Base = require './base'
{OperatorError} = require './errors'

# -------------------------
class Operator extends Base
  @extend(false)
  requireTarget: true
  recordable: true

  forceWise: null
  withOccurrence: false

  patternForOccurence: null

  stayAtSamePosition: null
  flashTarget: true
  trackChange: false

  finalMode: "normal"
  finalSubmode: null


  setMarkForChange: (range) ->
    @vimState.mark.setRange('[', ']', range)

  needFlash: ->
    return false if @isMode('visual')
    if @flashTarget and settings.get('flashOnOperate')
      @getName() not in settings.get('flashOnOperateBlacklist')
    else
      false

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

  constructor: ->
    super
    # Guard when Repeated.
    return if @instanceof("Repeat")

    # [important] intialized is not called when Repeated
    @initialize()
    @setTarget(@new(@target)) if _.isString(@target)

  restorePoint: (selection) ->
    which = if @needStay() then 'head' else 'start'
    restore = ->
      swrap(selection).setBufferPositionTo(which, fromProperty: true)

    if swrap(selection).getProperties().head?
      if @isWithOccurrence()
        # Deffer restoring cursor point.
        # restorePoint is processed one by one, so immediately updating cursorPosition result in
        # intersecting to other selection which is still not restored.
        # When intersecting selection is destroyed, cursor got involved moved automatically.
        @onDidFinishOperation -> restore()
      else
        restore()
    else
      selection.destroy()

  observeSelectAction: ->
    # Select operator is used only in visual-mode.
    # visual-mode selection modification should be handled by Motion::select(), TextObject::select()
    unless @instanceof('Select')
      if @needStay()
        @onWillSelectTarget => @updateSelectionProperties() unless @isMode('visual')
      else
        @onDidSelectTarget => @updateSelectionProperties()

    if @isWithOccurrence()
      scanRanges = null
      @onWillSelectTarget =>
        if @isMode('visual')
          scanRanges = @editor.getSelectedBufferRanges()
          @vimState.modeManager.deactivate() # clear selection

        unless @patternForOccurence
          {pattern, bufferRange} = @getPatternAndBufferRangeForOccurrence()
          @patternForOccurence = pattern
          if scanRanges?.length and bufferRange? and not @isMode('visual', 'blockwise')
            lastRangeIndex = scanRanges.length - 1
            scanRanges[lastRangeIndex] = scanRanges[lastRangeIndex].union(bufferRange)

      @onDidSelectTarget =>
        scanRanges ?= @editor.getSelectedBufferRanges()
        ranges = scanInRanges(@editor, @patternForOccurence, scanRanges)
        if ranges.length
          @editor.setSelectedBufferRanges(ranges)
        else
          # [FIXME]
          @restorePoint(selection) for selection in @editor.getSelections()
          @editor.clearSelections() unless @isMode('visual')
          @cancelOperation()
          @abort()

    markerForTrackChange = null
    @onDidSelectTarget =>
      @flash(@editor.getSelectedBufferRanges()) if @needFlash()
      if @trackChange
        markerForTrackChange = @editor.markBufferRange(@editor.getSelectedBufferRange())

    @onDidFinishOperation =>
      if markerForTrackChange?
        @setMarkForChange(range) if (range = markerForTrackChange.getBufferRange())

  # called by operationStack
  setOperatorModifier: ({occurence, wise}) ->
    if occurence? and occurence isnt @withOccurrence
      @withOccurrence = occurence
      @vimState.operationStack.addToClassList('with-occurrence')

    if wise?
      @forceWise = wise

  # @target - TextObject or Motion to operate on.
  setTarget: (target) ->
    unless _.isFunction(target.select)
      @vimState.emitter.emit('did-fail-to-set-target')
      throw new OperatorError("#{@getName()} cannot set #{target?.getName?()} as target")
    @target = target
    @target.setOperator(this)
    @modifyTargetWise(@target, @forceWise) if @hasForceWise()
    @emitDidSetTarget(this)
    this

  modifyTargetWise: (target, wise) ->
    switch wise
      when 'characterwise'
        if target.linewise
          target.linewise = false
          target.inclusive = false
        else
          target.inclusive = not target.inclusive
      when 'linewise'
        target.linewise = true

  isWithOccurrence: ->
    @withOccurrence

  hasForceWise: ->
    @forceWise?

  # Return true unless all selection is empty.
  selectTarget: ->
    @observeSelectAction()
    @emitWillSelectTarget()
    @target.select()
    @emitDidSelectTarget()
    haveSomeSelection(@editor)

  setTextToRegisterForSelection: (selection) ->
    @setTextToRegister(selection.getText(), selection)

  setTextToRegister: (text, selection) ->
    text += "\n" if (@target.isLinewise?() and (not text.endsWith('\n')))
    @vimState.register.set({text, selection}) if text

  flash: (ranges) ->
    highlightRanges @editor, ranges,
      class: 'vim-mode-plus-flash'
      timeout: settings.get('flashOnOperateDuration')

  updatePreviousSelection: ->
    if @isMode('visual', 'blockwise')
      properties = @vimState.getLastBlockwiseSelection().getCharacterwiseProperties()
    else
      lastSelection = @editor.getLastSelection()
      properties = swrap(lastSelection).detectCharacterwiseProperties()

    submode = @vimState.submode
    globalState.previousSelection = {properties, submode}

  execute: ->
    # We need to preserve selection before selection is cleared as a result of mutation.
    @updatePreviousSelection() if @isMode('visual')

    if @selectTarget()
      @editor.transact =>
        for selection in @editor.getSelections()
          @mutateSelection(selection)

    @activateMode(@finalMode, @finalSubmode)

  # Return {pattern, bufferRange},
  #   - Mandatory: pattern
  #   - Optional: bufferRange
  getPatternAndBufferRangeForOccurrence: ->
    if @hasRegisterName()
      return {pattern: ///#{_.escapeRegExp(@getRegisterValueAsText())}///g }

    cursor = @editor.getLastCursor()
    char = getCharacterAtCursor(cursor)
    scope = cursor.getScopeDescriptor().getScopesArray()
    nonWordCharacters = atom.config.get('editor.nonWordCharacters', {scope})

    if char in nonWordCharacters
      return {pattern:  ///#{_.escapeRegExp(char)}///g }

    if cursorIsOnWhiteSpace(cursor)
      # When cursor is at just before whit space(| position in text below)
      #   aaa| bbb
      # Atom's native cursor.getCurrentWordBufferRange() return range for aaa text.
      # This is not very intuitive in Vim's cursor representation.
      # So here we return range of single or multiple white spaces.
      point = cursor.getBufferPosition()
      bufferRange = getBufferRangeForPatternFromPoint(@editor, point, /[ \t]*/)
      if bufferRange?
        cursorWord = @editor.getTextInBufferRange(bufferRange)
        return {pattern: ///#{_.escapeRegExp(cursorWord)}///g, bufferRange}

    bufferRange = getCurrentWordBufferRange(cursor)
    cursorWord = @editor.getTextInBufferRange(bufferRange)
    {pattern: ///\b#{_.escapeRegExp(cursorWord)}\b///g, bufferRange}

# Repeat
# =========================
class Repeat extends Operator
  @extend()
  requireTarget: false
  recordable: false

  execute: ->
    @editor.transact =>
      @countTimes =>
        if operation = @vimState.operationStack.getRecorded()
          operation.setRepeated()
          operation.execute()

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
    # FIXME don't trying to do everytin in event
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
    @restorePoint(selection)

class ToggleRangeMarker extends CreateRangeMarker
  @extend()
  getRangeMarkerAtCursor: ->
    point = @editor.getCursorBufferPosition()

    containsPoint = (rangeMarker, point) ->
      rangeMarker.getBufferRange().containsPoint(point, exclusive)

    exclusive = false
    for rangeMarker in @vimState.getRangeMarkers() when containsPoint(rangeMarker, point)
      return rangeMarker

  initialize: ->
    rangeMarker = @getRangeMarkerAtCursor()
    if rangeMarker?
      rangeMarker.destroy()
      @vimState.removeRangeMarker(rangeMarker)
      @abort()

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

  mutateSelection: (selection) =>
    {cursor} = selection
    wasLinewise = swrap(selection).isLinewise()
    @setTextToRegisterForSelection(selection)
    selection.deleteSelectedText()
    vimEof = @getVimEofBufferPosition()
    if cursor.getBufferPosition().isGreaterThan(vimEof)
      cursor.setBufferPosition([vimEof.row, 0])

    if wasLinewise
      if @needStay()
        headPosition = swrap(selection).getBufferPositionFor('head', fromProperty: true)
        cursor.setBufferPosition([cursor.getBufferRow(), headPosition.column])
        cursor.goalColumn = headPosition.column
      else
        cursor.skipLeadingWhitespace()

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
    if @isVisualBlockwise = @isMode('visual', 'blockwise')
      @requireTarget = false
    super

  execute: ->
    # Ensure all selections to un-reversed
    if @isVisualBlockwise
      swrap.setReversedState(@editor, false)

    super

    if @isVisualBlockwise
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
    @restorePoint(selection)

class YankLine extends Yank
  @extend()
  target: 'MoveToRelativeLine'

  mutateSelection: (selection) ->
    if @isMode('visual')
      swrap(selection).expandOverLine()
      swrap(selection).preserveCharacterwise()
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
      @flash(newRanges) if @needFlash()
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
      @flash(newRanges) if @needFlash()
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
        @flash(newRange) if @needFlash()

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
        text = selection.getText().replace(/./g, input)
        insertText = (text) ->
          selection.insertText(text, autoIndentNewline: true)
        if @target.instanceof('MoveRight')
          insertText(text) if text.length >= @getCount()
        else
          insertText(text)
        @restorePoint(selection) unless (input is "\n")

    # FIXME this is very imperative, handling in very lower level.
    # find better place for operator in blockwise move works appropriately.
    if @getTarget().isBlockwise()
      top = @editor.getSelectionsOrderedByBufferPosition()[0]
      for selection in @editor.getSelections() when (selection isnt top)
        selection.destroy()

    @activateMode('normal')

# [SHOULD remove?]
class SetCursorsToStartOfTarget extends Operator
  @extend()
  flashTarget: false
  mutateSelection: (selection) ->
    swrap(selection).setBufferPositionTo('start')

class SetCursorsToStartOfRangeMarker extends SetCursorsToStartOfTarget
  @extend()
  flashTarget: false
  target: "RangeMarker"
