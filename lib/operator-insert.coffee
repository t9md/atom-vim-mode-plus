_ = require 'underscore-plus'

{
  moveCursorLeft, moveCursorRight
  getNewTextRangeFromCheckpoint
} = require './utils'
swrap = require './selection-wrapper'
settings = require './settings'
Operator = require('./base').getClass('Operator')

# Insert entering operation
# -------------------------
class ActivateInsertMode extends Operator
  @extend()
  requireTarget: false
  flashTarget: false
  checkpoint: null
  finalSubmode: null
  supportInsertionCount: true

  observeWillDeactivateMode: ->
    disposable = @vimState.modeManager.preemptWillDeactivateMode ({mode}) =>
      return unless mode is 'insert'
      disposable.dispose()

      @vimState.mark.set('^', @editor.getCursorBufferPosition())
      if (range = getNewTextRangeFromCheckpoint(@editor, @getCheckpoint('insert')))?
        @setMarkForChange(range) # Marker can track following extra insertion incase count specified
        textByUserInput = @editor.getTextInBufferRange(range)
      else
        textByUserInput = ''
      @saveInsertedText(textByUserInput)
      @vimState.register.set('.', {text: textByUserInput})

      _.times @getInsertionCount(), =>
        text = @textByOperator + textByUserInput
        for selection in @editor.getSelections()
          selection.insertText(text, autoIndent: true)

      # grouping changes for undo checkpoint need to come last
      if settings.get('groupChangesWhenLeavingInsertMode')
        @editor.groupChangesSinceCheckpoint(@getCheckpoint('undo'))

  initialize: ->
    super
    @checkpoint = {}
    @setCheckpoint('undo') unless @isRepeated()
    @observeWillDeactivateMode()

  # we have to manage two separate checkpoint for different purpose(timing is different)
  # - one for undo(handled by modeManager)
  # - one for preserve last inserted text
  setCheckpoint: (purpose) ->
    @checkpoint[purpose] = @editor.createCheckpoint()

  getCheckpoint: (purpose) ->
    @checkpoint[purpose]

  saveInsertedText: (@insertedText) -> @insertedText

  getInsertedText: ->
    @insertedText ? ''

  # called when repeated
  repeatInsert: (selection, text) ->
    selection.insertText(text, autoIndent: true)

  getInsertionCount: ->
    @insertionCount ?= if @supportInsertionCount then (@getCount() - 1) else 0
    @insertionCount

  execute: ->
    if @isRepeated()
      return unless text = @getInsertedText()
      unless @instanceof('Change')
        @flashTarget = @trackChange = true
        @emitDidSelectTarget()
      @editor.transact =>
        for selection in @editor.getSelections()
          @repeatInsert(selection, text)
          moveCursorLeft(selection.cursor)

      if settings.get('clearMultipleCursorsOnEscapeInsertMode')
        @editor.clearSelections()

    else
      if @getInsertionCount() > 0
        range = getNewTextRangeFromCheckpoint(@editor, @getCheckpoint('undo'))
        @textByOperator = if range? then @editor.getTextInBufferRange(range) else ''
      @setCheckpoint('insert')
      @vimState.activate('insert', @finalSubmode)

class ActivateReplaceMode extends ActivateInsertMode
  @extend()
  finalSubmode: 'replace'

  repeatInsert: (selection, text) ->
    for char in text when (char isnt "\n")
      break if selection.cursor.isAtEndOfLine()
      selection.selectRight()
    selection.insertText(text, autoIndent: false)

class InsertAfter extends ActivateInsertMode
  @extend()
  execute: ->
    moveCursorRight(cursor) for cursor in @editor.getCursors()
    super

class InsertAfterEndOfLine extends ActivateInsertMode
  @extend()
  execute: ->
    @editor.moveToEndOfLine()
    super

class InsertAtBeginningOfLine extends ActivateInsertMode
  @extend()
  execute: ->
    @editor.moveToBeginningOfLine()
    @editor.moveToFirstCharacterOfLine()
    super

class InsertAtLastInsert extends ActivateInsertMode
  @extend()
  execute: ->
    if (point = @vimState.mark.get('^'))
      @editor.setCursorBufferPosition(point)
      @editor.scrollToCursorPosition({center: true})
    super

class InsertAboveWithNewline extends ActivateInsertMode
  @extend()
  execute: ->
    @insertNewline()
    super

  insertNewline: ->
    @editor.insertNewlineAbove()

  repeatInsert: (selection, text) ->
    selection.insertText(text.trimLeft(), autoIndent: true)

class InsertBelowWithNewline extends InsertAboveWithNewline
  @extend()
  insertNewline: ->
    @editor.insertNewlineBelow()

# Advanced Insertion
# -------------------------
class InsertByTarget extends ActivateInsertMode
  @extend(false)
  requireTarget: true
  which: null # one of ['start', 'end', 'head', 'tail']
  execute: ->
    @selectTarget()
    for selection in @editor.getSelections()
      swrap(selection).setBufferPositionTo(@which)
    super

class InsertAtStartOfTarget extends InsertByTarget
  @extend()
  which: 'start'

class InsertAtEndOfTarget extends InsertByTarget
  @extend()
  which: 'end'

class InsertAtStartOfInnerSmartWord extends InsertByTarget
  @extend()
  which: 'start'
  target: "InnerSmartWord"

class InsertAtEndOfInnerSmartWord extends InsertByTarget
  @extend()
  which: 'end'
  target: "InnerSmartWord"

class InsertAtHeadOfTarget extends InsertByTarget
  @extend()
  which: 'head'

class InsertAtTailOfTarget extends InsertByTarget
  @extend()
  which: 'tail'

class InsertAtPreviousFoldStart extends InsertAtHeadOfTarget
  @extend()
  @description: "Move to previous fold start then enter insert-mode"
  target: 'MoveToPreviousFoldStart'

class InsertAtNextFoldStart extends InsertAtHeadOfTarget
  @extend()
  @description: "Move to next fold start then enter insert-mode"
  target: 'MoveToNextFoldStart'

class InsertAtStartOfSearchCurrentLine extends InsertAtEndOfTarget
  @extend()
  defaultLandingPoint: 'start'
  initialize: ->
    super
    @setTarget @new 'SearchCurrentLine',
      updateSearchHistory: false
      defaultLandingPoint: @defaultLandingPoint
      quiet: true

class InsertAtEndOfSearchCurrentLine extends InsertAtStartOfSearchCurrentLine
  @extend()
  defaultLandingPoint: 'end'

# -------------------------
class Change extends ActivateInsertMode
  @extend()
  requireTarget: true
  trackChange: true
  supportInsertionCount: false

  execute: ->
    if @isRepeated()
      @flashTarget = true

    selected = @selectTarget()
    if @isOccurrence() and not selected
      @vimState.activate('normal')
      return

    text = ''
    if @target.isTextObject() or @target.isMotion()
      text = "\n" if (swrap.detectVisualModeSubmode(@editor) is 'linewise')
    else
      text = "\n" if @target.isLinewise?()

    @editor.transact =>
      for selection in @editor.getSelections()
        @setTextToRegisterForSelection(selection)
        range = selection.insertText(text, autoIndent: true)
        selection.cursor.moveLeft() unless range.isEmpty()
    # FIXME calling super on OUTSIDE of editor.transact.
    # That's why repeatRecorded() need transact.wrap
    super

class ChangeOccurrence extends Change
  @extend()
  @description: "Change all matching word within target range"
  occurrence: true

class ChangeOccurrenceInAFunctionOrInnerParagraph extends ChangeOccurrence
  @extend()
  target: 'AFunctionOrInnerParagraph'

class ChangeOccurrenceInAPersistentSelection extends ChangeOccurrence
  @extend()
  target: "APersistentSelection"

class Substitute extends Change
  @extend()
  target: 'MoveRight'

class SubstituteLine extends Change
  @extend()
  target: 'MoveToRelativeLine'

class ChangeToLastCharacterOfLine extends Change
  @extend()
  target: 'MoveToLastCharacterOfLine'

  execute: ->
    # Ensure all selections to un-reversed
    if @isMode('visual', 'blockwise')
      swrap.setReversedState(@editor, false)
    super
