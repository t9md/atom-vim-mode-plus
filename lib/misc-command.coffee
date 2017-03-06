{Range, Point} = require 'atom'
Base = require './base'
swrap = require './selection-wrapper'
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
} = require './utils'

class MiscCommand extends Base
  @extend(false)
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
    swrap.setReversedState(@editor, not @editor.getLastSelection().isReversed())
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
      return if @isMultipleAndAllRangeHaveSameColumnRanges(newRanges)
      newRanges = newRanges.map (range) => humanizeBufferRange(@editor, range)
      newRanges = @filterNonLeadingWhiteSpaceRange(newRanges)

      if isMultipleSingleLineRanges(newRanges)
        @flash(newRanges, type: 'undo-redo-multiple-changes')
      else
        @flash(newRanges, type: 'undo-redo')
    else
      return if @isMultipleAndAllRangeHaveSameColumnRanges(oldRanges)

      if isMultipleSingleLineRanges(oldRanges)
        oldRanges = @filterNonLeadingWhiteSpaceRange(oldRanges)
        @flash(oldRanges, type: 'undo-redo-multiple-delete')

  filterNonLeadingWhiteSpaceRange: (ranges) ->
    ranges.filter (range) =>
      not isLeadingWhiteSpaceRange(@editor, range)

  isMultipleAndAllRangeHaveSameColumnRanges: (ranges) ->
    return false if ranges.length <= 1

    {start, end} = ranges[0]
    startColumn = start.column
    endColumn = end.column

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

class ToggleFold extends MiscCommand
  @extend()
  execute: ->
    point = @editor.getCursorBufferPosition()
    @editor.toggleFoldAtBufferRow(point.row)

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
