_ = require 'underscore-plus'
{Range} = require 'atom'

{
  moveCursorLeft
  moveCursorRight
  limitNumber
  shrinkRangeEndToBeforeNewLine
} = require './utils'
swrap = require './selection-wrapper'
Operator = require('./base').getClass('Operator')

# Insert entering operation
# -------------------------
# [NOTE]
# Rule: Don't make any text mutation before calling `@selectTarget()`.
class ActivateInsertMode extends Operator
  @extend()
  requireTarget: false
  flashTarget: false
  finalSubmode: null
  supportInsertionCount: true
  flashCheckpoint: 'custom'

  observeWillDeactivateMode: ->
    disposable = @vimState.modeManager.preemptWillDeactivateMode ({mode}) =>
      return unless mode is 'insert'
      disposable.dispose()

      @vimState.mark.set('^', @editor.getCursorBufferPosition()) # Last insert-mode position
      textByUserInput = ''
      if change = @getChangeSinceCheckpoint('insert')
        @lastChange = change
        changedRange = new Range(change.start, change.start.traverse(change.newExtent))
        @vimState.mark.setRange('[', ']', changedRange)
        textByUserInput = change.newText
      @vimState.register.set('.', text: textByUserInput) # Last inserted text

      _.times @getInsertionCount(), =>
        text = @textByOperator + textByUserInput
        for selection in @editor.getSelections()
          selection.insertText(text, autoIndent: true)

      # This cursor state is restored on undo.
      # So cursor state has to be updated before next groupChangesSinceCheckpoint()
      if @getConfig('clearMultipleCursorsOnEscapeInsertMode')
        @vimState.clearSelections()

      # grouping changes for undo checkpoint need to come last
      if @getConfig('groupChangesWhenLeavingInsertMode')
        @groupChangesSinceBufferCheckpoint('undo')

  # When each mutaion's extent is not intersecting, muitiple changes are recorded
  # e.g
  #  - Multicursors edit
  #  - Cursor moved in insert-mode(e.g ctrl-f, ctrl-b)
  # But I don't care multiple changes just because I'm lazy(so not perfect implementation).
  # I only take care of one change happened at earliest(topCursor's change) position.
  # Thats' why I save topCursor's position to @topCursorPositionAtInsertionStart to compare traversal to deletionStart
  # Why I use topCursor's change? Just because it's easy to use first change returned by getChangeSinceCheckpoint().
  getChangeSinceCheckpoint: (purpose) ->
    checkpoint = @getBufferCheckpoint(purpose)
    @editor.buffer.getChangesSinceCheckpoint(checkpoint)[0]

  # [BUG-BUT-OK] Replaying text-deletion-operation is not compatible to pure Vim.
  # Pure Vim record all operation in insert-mode as keystroke level and can distinguish
  # character deleted by `Delete` or by `ctrl-u`.
  # But I can not and don't trying to minic this level of compatibility.
  # So basically deletion-done-in-one is expected to work well.
  replayLastChange: (selection) ->
    if @lastChange?
      {start, newExtent, oldExtent, newText} = @lastChange
      unless oldExtent.isZero()
        traversalToStartOfDelete = start.traversalFrom(@topCursorPositionAtInsertionStart)
        deletionStart = selection.cursor.getBufferPosition().traverse(traversalToStartOfDelete)
        deletionEnd = deletionStart.traverse(oldExtent)
        selection.setBufferRange([deletionStart, deletionEnd])
    else
      newText = ''
    selection.insertText(newText, autoIndent: true)

  # called when repeated
  # [FIXME] to use replayLastChange in repeatInsert overriding subclasss.
  repeatInsert: (selection, text) ->
    @replayLastChange(selection)

  getInsertionCount: ->
    @insertionCount ?= if @supportInsertionCount then @getCount(-1) else 0
    # Avoid freezing by acccidental big count(e.g. `5555555555555i`), See #560, #596
    limitNumber(@insertionCount, max: 100)

  execute: ->
    if @isRepeated()
      @flashTarget = @trackChange = true

      @startMutation =>
        @selectTarget() if @isRequireTarget()
        @mutateText?()
        mutatedRanges = []
        for selection in @editor.getSelections()
          mutatedRanges.push(@repeatInsert(selection, @lastChange?.newText ? ''))
          moveCursorLeft(selection.cursor)
        @mutationManager.setBufferRangesForCustomCheckpoint(mutatedRanges)

      if @getConfig('clearMultipleCursorsOnEscapeInsertMode')
        @vimState.clearSelections()

    else
      @normalizeSelectionsIfNecessary() if @isRequireTarget()
      @createBufferCheckpoint('undo')
      @selectTarget() if @isRequireTarget()
      @observeWillDeactivateMode()

      @mutateText?()

      if @getInsertionCount() > 0
        @textByOperator = @getChangeSinceCheckpoint('undo')?.newText ? ''

      @createBufferCheckpoint('insert')
      topCursor = @editor.getCursorsOrderedByBufferPosition()[0]
      @topCursorPositionAtInsertionStart = topCursor.getBufferPosition()
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

# key: 'g I' in all mode
class InsertAtBeginningOfLine extends ActivateInsertMode
  @extend()
  execute: ->
    if @isMode('visual', ['characterwise', 'linewise'])
      @editor.splitSelectionsIntoLines()
    @editor.moveToBeginningOfLine()
    super

# key: normal 'A'
class InsertAfterEndOfLine extends ActivateInsertMode
  @extend()
  execute: ->
    @editor.moveToEndOfLine()
    super

# key: normal 'I'
class InsertAtFirstCharacterOfLine extends ActivateInsertMode
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

  # This is for `o` and `O` operator.
  # On undo/redo put cursor at original point where user type `o` or `O`.
  groupChangesSinceBufferCheckpoint: ->
    lastCursor = @editor.getLastCursor()
    cursorPosition = lastCursor.getBufferPosition()
    lastCursor.setBufferPosition(@vimState.getOriginalCursorPositionByMarker())

    super

    lastCursor.setBufferPosition(cursorPosition)

  mutateText: ->
    @editor.insertNewlineAbove()

  repeatInsert: (selection, text) ->
    selection.insertText(text.trimLeft(), autoIndent: true)

class InsertBelowWithNewline extends InsertAboveWithNewline
  @extend()
  mutateText: ->
    @editor.insertNewlineBelow()

# Advanced Insertion
# -------------------------
class InsertByTarget extends ActivateInsertMode
  @extend(false)
  requireTarget: true
  which: null # one of ['start', 'end', 'head', 'tail']

  initialize: ->
    # HACK
    # When g i is mapped to `insert-at-start-of-target`.
    # `g i 3 l` start insert at 3 column right position.
    # In this case, we don't want repeat insertion 3 times.
    # This @getCount() call cache number at the timing BEFORE '3' is specified.
    @getCount()
    super

  execute: ->
    @onDidSelectTarget =>
      @modifySelection() if @vimState.isMode('visual')
      for selection in @editor.getSelections()
        swrap(selection).setBufferPositionTo(@which)
    super

  modifySelection: ->
    switch @vimState.submode
      when 'characterwise'
        # `I(or A)` is short-hand of `ctrl-v I(or A)`
        @vimState.selectBlockwise()
        @vimState.clearBlockwiseSelections() # just reset vimState's storage.

      when 'linewise'
        @editor.splitSelectionsIntoLines()
        for selection in @editor.getSelections()
          {start, end} = range = selection.getBufferRange()
          if @which is 'start'
            newRange = [@getFirstCharacterPositionForBufferRow(start.row), end]
          else
            newRange = shrinkRangeEndToBeforeNewLine(range)

          selection.setBufferRange(newRange)

# key: 'I', Used in 'visual-mode.characterwise', visual-mode.blockwise
class InsertAtStartOfTarget extends InsertByTarget
  @extend()
  which: 'start'

# key: 'A', Used in 'visual-mode.characterwise', 'visual-mode.blockwise'
class InsertAtEndOfTarget extends InsertByTarget
  @extend()
  which: 'end'

class InsertAtStartOfOccurrence extends InsertByTarget
  @extend()
  which: 'start'
  occurrence: true

class InsertAtEndOfOccurrence extends InsertByTarget
  @extend()
  which: 'end'
  occurrence: true

class InsertAtStartOfSmartWord extends InsertByTarget
  @extend()
  which: 'start'
  target: "MoveToPreviousSmartWord"

class InsertAtEndOfSmartWord extends InsertByTarget
  @extend()
  which: 'end'
  target: "MoveToEndOfSmartWord"

class InsertAtPreviousFoldStart extends InsertByTarget
  @extend()
  @description: "Move to previous fold start then enter insert-mode"
  which: 'start'
  target: 'MoveToPreviousFoldStart'

class InsertAtNextFoldStart extends InsertByTarget
  @extend()
  @description: "Move to next fold start then enter insert-mode"
  which: 'end'
  target: 'MoveToNextFoldStart'

# -------------------------
class Change extends ActivateInsertMode
  @extend()
  requireTarget: true
  trackChange: true
  supportInsertionCount: false

  mutateText: ->
    # Allways dynamically determine selection wise wthout consulting target.wise
    # Reason: when `c i {`, wise is 'characterwise', but actually selected range is 'linewise'
    #   {
    #     a
    #   }
    isLinewiseTarget = swrap.detectWise(@editor) is 'linewise'
    for selection in @editor.getSelections()
      @setTextToRegisterForSelection(selection)
      if isLinewiseTarget
        selection.insertText("\n", autoIndent: true)
        selection.cursor.moveLeft()
      else
        selection.insertText('', autoIndent: true)

class ChangeOccurrence extends Change
  @extend()
  @description: "Change all matching word within target range"
  occurrence: true

class Substitute extends Change
  @extend()
  target: 'MoveRight'

class SubstituteLine extends Change
  @extend()
  wise: 'linewise' # [FIXME] to re-override target.wise in visual-mode
  target: 'MoveToRelativeLine'

# alias
class ChangeLine extends SubstituteLine
  @extend()

class ChangeToLastCharacterOfLine extends Change
  @extend()
  target: 'MoveToLastCharacterOfLine'

  initialize: ->
    if @isMode('visual', 'blockwise')
      # FIXME Maybe because of bug of CurrentSelection,
      # we use MoveToLastCharacterOfLine as target
      @acceptCurrentSelection = false
      swrap.setReversedState(@editor, false) # Ensure all selections to un-reversed
    super
