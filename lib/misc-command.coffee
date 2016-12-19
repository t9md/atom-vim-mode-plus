{Range, Point} = require 'atom'
Base = require './base'
swrap = require './selection-wrapper'
settings = require './settings'
_ = require 'underscore-plus'

{
  moveCursorRight
  isLinewiseRange
  setBufferRow
  pointIsAtEndOfLine
  pointIsAtEndOfLineAtNonEmptyRow
  sortRanges
  findRangeContainsPoint
  mergeIntersectingRanges
  isSingleLineRange
} = require './utils'

class MiscCommand extends Base
  @extend(false)
  constructor: ->
    super
    @initialize()

class ReverseSelections extends MiscCommand
  @extend()
  execute: ->
    # Reverse only selection which reversed state is in-sync to last selection.
    reversed = @editor.getLastSelection().isReversed()
    for selection in @editor.getSelections() when selection.isReversed() is reversed
      swrap(selection).reverse()
    if @isMode('visual', 'blockwise')
      @getLastBlockwiseSelection().autoscrollIfReversed()

class BlockwiseOtherEnd extends ReverseSelections
  @extend()
  execute: ->
    for blockwiseSelection in @getBlockwiseSelections()
      blockwiseSelection.reverse()
    super

class Undo extends MiscCommand
  @extend()

  withTrackingChanges: (fn) ->
    newRanges = []
    oldRanges = []

    # Collect changed range while mutating text-state by fn callback.
    disposable = @editor.getBuffer().onDidChange ({newRange, oldRange}) ->
      if newRange.isEmpty()
        oldRanges.push(oldRange) # Remove only
      else
        newRanges.push(newRange)

    fn()

    disposable.dispose()
    selection.clear() for selection in @editor.getSelections()

    lastCursor = @editor.getLastCursor() # This is restored cursor
    if cursorContainedRange = findRangeContainsPoint(newRanges, lastCursor.getBufferPosition())
      @vimState.mark.setRange('[', ']', cursorContainedRange)
      if settings.get('setCursorToStartOfChangeOnUndoRedo')
        if isLinewiseRange(cursorContainedRange)
          setBufferRow(lastCursor, cursorContainedRange.start.row)
        else
          lastCursor.setBufferPosition(cursorContainedRange.start)

    if settings.get('setCursorToStartOfChangeOnUndoRedo')
      @vimState.clearSelections()

    multipleSingleLineRanges = (ranges) ->
      ranges.length > 1 and ranges.every(isSingleLineRange)

    if settings.get('flashOnUndoRedo')
      if newRanges.length > 0
        newRanges = newRanges.map(@humanizeNewLineForRange.bind(this))
        if multipleSingleLineRanges(newRanges)
          @flash(newRanges, type: 'undo-redo-multiple-changes')
        else
          @flash(newRanges, type: 'undo-redo')
      else
        if multipleSingleLineRanges(oldRanges)
          @flash(oldRanges, type: 'undo-redo-multiple-delete')

  # Modify range used for fash highlight to make it feel naturally for human.
  # - When user inserted '\n abc' from **EOL**.
  #  then modify corresponding range to ' abc\n'.
  # - When user inserted '\n abc' from middle of line text.
  #  then modify corresponding range to ' abc'.
  #
  # So always trim initial "\n" part range because flashing trailing line is counterintuitive.
  humanizeNewLineForRange: (range) ->
    {start, end} = range
    if pointIsAtEndOfLine(@editor, start)
      newStart = new Point(start.row + 1, 0)
    if pointIsAtEndOfLineAtNonEmptyRow(@editor, end)
      newEnd = new Point(end.row + 1, 0)

    if newStart? or newEnd?
      new Range(newStart ? start, newEnd ? end)
    else
      range

  flash: (flashRanges, options) ->
    options.timeout ?= 500
    @onDidFinishOperation =>
      @vimState.flash(flashRanges, options)

  execute: ->
    @withTrackingChanges =>
      @mutate()
    @activateMode('normal')

  mutate: ->
    @editor.undo()

class Redo extends Undo
  @extend()
  mutate: ->
    @editor.redo()

class ToggleFold extends MiscCommand
  @extend()
  execute: ->
    point = @editor.getCursorBufferPosition()
    @editor.toggleFoldAtBufferRow(point.row)

class ReplaceModeBackspace extends MiscCommand
  @commandScope: 'atom-text-editor.vim-mode-plus.insert-mode.replace'
  @extend()
  execute: ->
    @editor.getSelections().forEach (selection) =>
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

    margin = @editor.getVerticalScrollMargin()
    {row, column} = @editor.getCursorScreenPosition()
    if row < (newFirstRow + margin)
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

    margin = @editor.getVerticalScrollMargin()
    {row, column} = @editor.getCursorScreenPosition()
    if row >= (newLastRow - margin)
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

class ActivateNormalModeOnce extends MiscCommand
  @extend()
  @commandScope: 'atom-text-editor.vim-mode-plus.insert-mode'
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
