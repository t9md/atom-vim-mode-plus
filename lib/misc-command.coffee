{Range} = require 'atom'
Base = require './base'
swrap = require './selection-wrapper'
settings = require './settings'
_ = require 'underscore-plus'
{moveCursorRight} = require './utils'

{
  pointIsAtEndOfLine
  sortRanges
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

  # Trim starting new-line-corresponding range if it transformed range become linewise range.
  # this is special accomodation for flashing intuitively for human when `y y p` then `undo`, `redo`
  trimStartingNewLine: (range) ->
    {start, end} = range
    if (end.column is 0) and (start.row + 1 isnt end.row) and pointIsAtEndOfLine(@editor, start)
      new Range([start.row + 1, 0], end)
    else
      range

  withTrackingChanges: (fn) ->
    newRanges = []
    oldRanges = []

    disposable = @editor.getBuffer().onDidChange ({oldRange, newRange}) ->
      if newRange.containsRange(oldRange)
        newRanges.push(newRange)
        return

      if oldRange.containsRange(newRange)
        oldRanges.push(oldRange)
        return

      oldRanges.push(oldRange) unless oldRange.isEmpty()
      newRanges.push(newRange) unless newRange.isEmpty()

    fn()

    disposable.dispose()
    selection.clear() for selection in @editor.getSelections()

    trimStartingNewLine = @trimStartingNewLine.bind(this)
    newRanges = newRanges.map(trimStartingNewLine)
    oldRanges = oldRanges.map(trimStartingNewLine)

    allRanges = sortRanges(newRanges.concat(oldRanges))

    if @editor.hasMultipleCursors()
      point = @editor.getCursorBufferPosition()
      allRanges = allRanges.filter (range) -> range.containsPoint(point)

    if changedRange = allRanges[0]
      @vimState.mark.setRange('[', ']', changedRange)
      if settings.get('setCursorToStartOfChangeOnUndoRedo')
        @editor.setCursorBufferPosition(changedRange.start)

    if settings.get('flashOnUndoRedo')
      @onDidFinishOperation =>
        @vimState.flash(newRanges, type: 'added', timeout: 500)
        @vimState.flash(oldRanges, type: 'removed', timeout: 500)

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
