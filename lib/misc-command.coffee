{Range, Point} = require 'atom'
Base = require './base'
_ = require 'underscore-plus'

{
  moveCursorRight
  isLinewiseRange
  setBufferRow
  sortRanges
  findRangeContainsPoint
  isSingleLineRange
  isLeadingWhiteSpaceRange
  humanizeBufferRange
  getFoldInfoByKind
  limitNumber
  getFoldRowRangesContainedByFoldStartsAtRow
} = require './utils'

class MiscCommand extends Base
  @extend(false)
  @operationKind: 'misc-command'
  constructor: ->
    super
    @initialize()

class Mark extends MiscCommand
  @extend()
  requireInput: true
  initialize: ->
    @focusInput()
    super

  execute: ->
    @vimState.mark.set(@input, @editor.getCursorBufferPosition())
    @activateMode('normal')

class ReverseSelections extends MiscCommand
  @extend()
  execute: ->
    @swrap.setReversedState(@editor, not @editor.getLastSelection().isReversed())
    if @isMode('visual', 'blockwise')
      @getLastBlockwiseSelection().autoscroll()

class BlockwiseOtherEnd extends ReverseSelections
  @extend()
  execute: ->
    for blockwiseSelection in @getBlockwiseSelections()
      blockwiseSelection.reverse()
    super

class Undo extends MiscCommand
  @extend()

  setCursorPosition: ({newRanges, oldRanges, strategy}) ->
    lastCursor = @editor.getLastCursor() # This is restored cursor

    if strategy is 'smart'
      changedRange = findRangeContainsPoint(newRanges, lastCursor.getBufferPosition())
    else
      changedRange = sortRanges(newRanges.concat(oldRanges))[0]

    if changedRange?
      if isLinewiseRange(changedRange)
        setBufferRow(lastCursor, changedRange.start.row)
      else
        lastCursor.setBufferPosition(changedRange.start)

  mutateWithTrackChanges: ->
    newRanges = []
    oldRanges = []

    # Collect changed range while mutating text-state by fn callback.
    disposable = @editor.getBuffer().onDidChange ({newRange, oldRange}) ->
      if newRange.isEmpty()
        oldRanges.push(oldRange) # Remove only
      else
        newRanges.push(newRange)

    @mutate()

    disposable.dispose()
    {newRanges, oldRanges}

  flashChanges: ({newRanges, oldRanges}) ->
    isMultipleSingleLineRanges = (ranges) ->
      ranges.length > 1 and ranges.every(isSingleLineRange)

    if newRanges.length > 0
      return if @isMultipleAndAllRangeHaveSameColumnAndConsecutiveRows(newRanges)
      newRanges = newRanges.map (range) => humanizeBufferRange(@editor, range)
      newRanges = @filterNonLeadingWhiteSpaceRange(newRanges)

      if isMultipleSingleLineRanges(newRanges)
        @flash(newRanges, type: 'undo-redo-multiple-changes')
      else
        @flash(newRanges, type: 'undo-redo')
    else
      return if @isMultipleAndAllRangeHaveSameColumnAndConsecutiveRows(oldRanges)

      if isMultipleSingleLineRanges(oldRanges)
        oldRanges = @filterNonLeadingWhiteSpaceRange(oldRanges)
        @flash(oldRanges, type: 'undo-redo-multiple-delete')

  filterNonLeadingWhiteSpaceRange: (ranges) ->
    ranges.filter (range) =>
      not isLeadingWhiteSpaceRange(@editor, range)

  # [TODO] Improve further by checking oldText, newText?
  # [Purpose of this is function]
  # Suppress flash when undo/redoing toggle-comment while flashing undo/redo of occurrence operation.
  # This huristic approach never be perfect.
  # Ultimately cannnot distinguish occurrence operation.
  isMultipleAndAllRangeHaveSameColumnAndConsecutiveRows: (ranges) ->
    return false if ranges.length <= 1

    {start: {column: startColumn}, end: {column: endColumn}} = ranges[0]
    previousRow = null
    for range in ranges
      {start, end} = range
      unless ((start.column is startColumn) and (end.column is endColumn))
        return false

      if previousRow? and (previousRow + 1 isnt start.row)
        return false
      previousRow = start.row
    return true

    ranges.every ({start, end}) ->
      (start.column is startColumn) and (end.column is endColumn)

  flash: (flashRanges, options) ->
    options.timeout ?= 500
    @onDidFinishOperation =>
      @vimState.flash(flashRanges, options)

  execute: ->
    {newRanges, oldRanges} = @mutateWithTrackChanges()

    for selection in @editor.getSelections()
      selection.clear()

    if @getConfig('setCursorToStartOfChangeOnUndoRedo')
      strategy = @getConfig('setCursorToStartOfChangeOnUndoRedoStrategy')
      @setCursorPosition({newRanges, oldRanges, strategy})
      @vimState.clearSelections()

    if @getConfig('flashOnUndoRedo')
      @flashChanges({newRanges, oldRanges})

    @activateMode('normal')

  mutate: ->
    @editor.undo()

class Redo extends Undo
  @extend()
  mutate: ->
    @editor.redo()

# zc
class FoldCurrentRow extends MiscCommand
  @extend()
  execute: ->
    for selection in @editor.getSelections()
      {row} = @getCursorPositionForSelection(selection)
      @editor.foldBufferRow(row)

# zo
class UnfoldCurrentRow extends MiscCommand
  @extend()
  execute: ->
    for selection in @editor.getSelections()
      {row} = @getCursorPositionForSelection(selection)
      @editor.unfoldBufferRow(row)

# za
class ToggleFold extends MiscCommand
  @extend()
  execute: ->
    point = @editor.getCursorBufferPosition()
    @editor.toggleFoldAtBufferRow(point.row)

# Base of zC, zO, zA
class FoldCurrentRowRecursivelyBase extends MiscCommand
  @extend(false)

  foldRecursively: (row) ->
    rowRanges = getFoldRowRangesContainedByFoldStartsAtRow(@editor, row)
    if rowRanges?
      startRows = rowRanges.map (rowRange) -> rowRange[0]
      for row in startRows.reverse() when not @editor.isFoldedAtBufferRow(row)
        @editor.foldBufferRow(row)

  unfoldRecursively: (row) ->
    rowRanges = getFoldRowRangesContainedByFoldStartsAtRow(@editor, row)
    if rowRanges?
      startRows = rowRanges.map (rowRange) -> rowRange[0]
      for row in startRows when @editor.isFoldedAtBufferRow(row)
        @editor.unfoldBufferRow(row)

  foldRecursivelyForAllSelections: ->
    for selection in @editor.getSelectionsOrderedByBufferPosition().reverse()
      @foldRecursively(@getCursorPositionForSelection(selection).row)

  unfoldRecursivelyForAllSelections: ->
    for selection in @editor.getSelectionsOrderedByBufferPosition()
      @unfoldRecursively(@getCursorPositionForSelection(selection).row)

# zC
class FoldCurrentRowRecursively extends FoldCurrentRowRecursivelyBase
  @extend()
  execute: ->
    @foldRecursivelyForAllSelections()

# zO
class UnfoldCurrentRowRecursively extends FoldCurrentRowRecursivelyBase
  @extend()
  execute: ->
    @unfoldRecursivelyForAllSelections()

# zA
class ToggleFoldRecursively extends FoldCurrentRowRecursivelyBase
  @extend()
  execute: ->
    row = @getCursorPositionForSelection(@editor.getLastSelection()).row
    if @editor.isFoldedAtBufferRow(row)
      @unfoldRecursivelyForAllSelections()
    else
      @foldRecursivelyForAllSelections()

# zR
class UnfoldAll extends MiscCommand
  @extend()
  execute: ->
    @editor.unfoldAll()

# zM
class FoldAll extends MiscCommand
  @extend()
  execute: ->
    {allFold} = getFoldInfoByKind(@editor)
    if allFold?
      @editor.unfoldAll()
      for {indent, startRow, endRow} in allFold.rowRangesWithIndent
        if indent <= @getConfig('maxFoldableIndentLevel')
          @editor.foldBufferRowRange(startRow, endRow)

# zr
class UnfoldNextIndentLevel extends MiscCommand
  @extend()
  execute: ->
    {folded} = getFoldInfoByKind(@editor)
    if folded?
      {minIndent, rowRangesWithIndent} = folded
      count = limitNumber(@getCount() - 1, min: 0)
      targetIndents = [minIndent..(minIndent + count)]
      for {indent, startRow} in rowRangesWithIndent
        if indent in targetIndents
          @editor.unfoldBufferRow(startRow)

# zm
class FoldNextIndentLevel extends MiscCommand
  @extend()
  execute: ->
    {unfolded, allFold} = getFoldInfoByKind(@editor)
    if unfolded?
      # FIXME: Why I need unfoldAll()? Why can't I just fold non-folded-fold only?
      # Unless unfoldAll() here, @editor.unfoldAll() delete foldMarker but fail
      # to render unfolded rows correctly.
      # I believe this is bug of text-buffer's markerLayer which assume folds are
      # created **in-order** from top-row to bottom-row.
      @editor.unfoldAll()

      maxFoldable = @getConfig('maxFoldableIndentLevel')
      fromLevel = Math.min(unfolded.maxIndent, maxFoldable)
      count = limitNumber(@getCount() - 1, min: 0)
      fromLevel = limitNumber(fromLevel - count, min: 0)
      targetIndents = [fromLevel..maxFoldable]

      for {indent, startRow, endRow} in allFold.rowRangesWithIndent
        if indent in targetIndents
          @editor.foldBufferRowRange(startRow, endRow)

class ReplaceModeBackspace extends MiscCommand
  @commandScope: 'atom-text-editor.vim-mode-plus.insert-mode.replace'
  @extend()
  execute: ->
    for selection in @editor.getSelections()
      # char might be empty.
      char = @vimState.modeManager.getReplacedCharForSelection(selection)
      if char?
        selection.selectLeft()
        unless selection.insertText(char).isEmpty()
          selection.cursor.moveLeft()

class ScrollWithoutChangingCursorPosition extends MiscCommand
  @extend(false)
  scrolloff: 2 # atom default. Better to use editor.getVerticalScrollMargin()?
  cursorPixel: null

  getFirstVisibleScreenRow: ->
    @editorElement.getFirstVisibleScreenRow()

  getLastVisibleScreenRow: ->
    @editorElement.getLastVisibleScreenRow()

  getLastScreenRow: ->
    @editor.getLastScreenRow()

  getCursorPixel: ->
    point = @editor.getCursorScreenPosition()
    @editorElement.pixelPositionForScreenPosition(point)

# ctrl-e scroll lines downwards
class ScrollDown extends ScrollWithoutChangingCursorPosition
  @extend()

  execute: ->
    count = @getCount()
    oldFirstRow = @editor.getFirstVisibleScreenRow()
    @editor.setFirstVisibleScreenRow(oldFirstRow + count)
    newFirstRow = @editor.getFirstVisibleScreenRow()

    offset = 2
    {row, column} = @editor.getCursorScreenPosition()
    if row < (newFirstRow + offset)
      newPoint = [row + count, column]
      @editor.setCursorScreenPosition(newPoint, autoscroll: false)

# ctrl-y scroll lines upwards
class ScrollUp extends ScrollWithoutChangingCursorPosition
  @extend()

  execute: ->
    count = @getCount()
    oldFirstRow = @editor.getFirstVisibleScreenRow()
    @editor.setFirstVisibleScreenRow(oldFirstRow - count)
    newLastRow = @editor.getLastVisibleScreenRow()

    offset = 2
    {row, column} = @editor.getCursorScreenPosition()
    if row >= (newLastRow - offset)
      newPoint = [row - count, column]
      @editor.setCursorScreenPosition(newPoint, autoscroll: false)

# ScrollWithoutChangingCursorPosition without Cursor Position change.
# -------------------------
class ScrollCursor extends ScrollWithoutChangingCursorPosition
  @extend(false)
  execute: ->
    @moveToFirstCharacterOfLine?()
    if @isScrollable()
      @editorElement.setScrollTop @getScrollTop()

  moveToFirstCharacterOfLine: ->
    @editor.moveToFirstCharacterOfLine()

  getOffSetPixelHeight: (lineDelta=0) ->
    @editor.getLineHeightInPixels() * (@scrolloff + lineDelta)

# z enter
class ScrollCursorToTop extends ScrollCursor
  @extend()
  isScrollable: ->
    @getLastVisibleScreenRow() isnt @getLastScreenRow()

  getScrollTop: ->
    @getCursorPixel().top - @getOffSetPixelHeight()

# zt
class ScrollCursorToTopLeave extends ScrollCursorToTop
  @extend()
  moveToFirstCharacterOfLine: null

# z-
class ScrollCursorToBottom extends ScrollCursor
  @extend()
  isScrollable: ->
    @getFirstVisibleScreenRow() isnt 0

  getScrollTop: ->
    @getCursorPixel().top - (@editorElement.getHeight() - @getOffSetPixelHeight(1))

# zb
class ScrollCursorToBottomLeave extends ScrollCursorToBottom
  @extend()
  moveToFirstCharacterOfLine: null

# z.
class ScrollCursorToMiddle extends ScrollCursor
  @extend()
  isScrollable: ->
    true

  getScrollTop: ->
    @getCursorPixel().top - (@editorElement.getHeight() / 2)

# zz
class ScrollCursorToMiddleLeave extends ScrollCursorToMiddle
  @extend()
  moveToFirstCharacterOfLine: null

# Horizontal ScrollWithoutChangingCursorPosition
# -------------------------
# zs
class ScrollCursorToLeft extends ScrollWithoutChangingCursorPosition
  @extend()

  execute: ->
    @editorElement.setScrollLeft(@getCursorPixel().left)

# ze
class ScrollCursorToRight extends ScrollCursorToLeft
  @extend()

  execute: ->
    @editorElement.setScrollRight(@getCursorPixel().left)

# insert-mode specific commands
# -------------------------
class InsertMode extends MiscCommand
  @commandScope: 'atom-text-editor.vim-mode-plus.insert-mode'

class ActivateNormalModeOnce extends InsertMode
  @extend()
  thisCommandName: @getCommandName()

  execute: ->
    cursorsToMoveRight = @editor.getCursors().filter (cursor) -> not cursor.isAtBeginningOfLine()
    @vimState.activate('normal')
    moveCursorRight(cursor) for cursor in cursorsToMoveRight
    disposable = atom.commands.onDidDispatch ({type}) =>
      return if type is @thisCommandName
      disposable.dispose()
      disposable = null
      @vimState.activate('insert')

class InsertRegister extends InsertMode
  @extend()
  requireInput: true

  initialize: ->
    super
    @focusInput()

  execute: ->
    @editor.transact =>
      for selection in @editor.getSelections()
        text = @vimState.register.getText(@input, selection)
        selection.insertText(text)

class InsertLastInserted extends InsertMode
  @extend()
  @description: """
  Insert text inserted in latest insert-mode.
  Equivalent to *i_CTRL-A* of pure Vim
  """
  execute: ->
    text = @vimState.register.getText('.')
    @editor.insertText(text)

class CopyFromLineAbove extends InsertMode
  @extend()
  @description: """
  Insert character of same-column of above line.
  Equivalent to *i_CTRL-Y* of pure Vim
  """
  rowDelta: -1

  execute: ->
    translation = [@rowDelta, 0]
    @editor.transact =>
      for selection in @editor.getSelections()
        point = selection.cursor.getBufferPosition().translate(translation)
        continue if point.row < 0
        range = Range.fromPointWithDelta(point, 0, 1)
        if text = @editor.getTextInBufferRange(range)
          selection.insertText(text)

class CopyFromLineBelow extends CopyFromLineAbove
  @extend()
  @description: """
  Insert character of same-column of above line.
  Equivalent to *i_CTRL-E* of pure Vim
  """
  rowDelta: +1

class NextTab extends MiscCommand
  @extend()
  defaultCount: 0
  execute: ->
    count = @getCount()
    pane = atom.workspace.paneForItem(@editor)
    if count
      pane.activateItemAtIndex(count - 1)
    else
      pane.activateNextItem()

class PreviousTab extends MiscCommand
  @extend()
  execute: ->
    pane = atom.workspace.paneForItem(@editor)
    pane.activatePreviousItem()
