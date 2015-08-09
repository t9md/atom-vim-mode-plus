Base = require './base'
class Scroll extends Base
  @extend()
  isComplete: ->
    true
  isRecordable: ->
    false

  constructor: (@vimState, @options={}) ->
    {@editorElement} = @vimState
    @editor = @editorElement.getModel()

    # better to use editor.getVerticalScrollMargin() ?
    @scrolloff = 2 # atom default
    @rows =
      first: @editorElement.getFirstVisibleScreenRow()
      last: @editorElement.getLastVisibleScreenRow()
      final: @editor.getLastScreenRow()

class ScrollDown extends Scroll
  @extend()
  execute: ->
    @keepCursorOnScreen()
    @scrollUp()

  keepCursorOnScreen: ->
    count = @getCount(1)
    {row, column} = @editor.getCursorScreenPosition()
    firstScreenRow = @rows.first + @scrolloff + 1
    if row - count <= firstScreenRow
      @editor.setCursorScreenPosition([firstScreenRow + count, column])

  scrollUp: ->
    lastScreenRow = @rows.last - @scrolloff
    @editor.scrollToScreenPosition([lastScreenRow + @getCount(1), 0])

class ScrollUp extends Scroll
  @extend()
  execute: ->
    @keepCursorOnScreen()
    @scrollDown()

  keepCursorOnScreen: ->
    count = @getCount(1)
    {row, column} = @editor.getCursorScreenPosition()
    lastScreenRow = @rows.last - @scrolloff - 1
    if row + count >= lastScreenRow
      @editor.setCursorScreenPosition([lastScreenRow - count, column])

  scrollDown: ->
    firstScreenRow = @rows.first + @scrolloff
    @editor.scrollToScreenPosition([firstScreenRow - @getCount(1), 0])

# Scroll without Cursor Position change.
# -------------------------
class ScrollCursor extends Scroll
  keepCursor: false
  @extend()
  constructor: ->
    super
    point = @editor.getCursorScreenPosition()
    @pixelCursorTop = @editorElement.pixelPositionForScreenPosition(point).top

  execute: ->
    @moveToFirstCharacterOfLine() unless @keepCursor
    @editor.setScrollTop @getScrollTop() if @isScrollable()

  moveToFirstCharacterOfLine: ->
    @editor.moveToFirstCharacterOfLine()

  getOffSetPixelHeight: (lineDelta=0) ->
    @editor.getLineHeightInPixels() * (@scrolloff + lineDelta)

class ScrollCursorToTop extends ScrollCursor
  @extend()
  isScrollable: ->
    not (@rows.last is @rows.final)

  getScrollTop: ->
    @pixelCursorTop - @getOffSetPixelHeight()

class ScrollCursorToBottom extends ScrollCursor
  @extend()
  isScrollable: ->
    not (@rows.first is 0)

  getScrollTop: ->
    @pixelCursorTop - (@editor.getHeight() - @getOffSetPixelHeight(1))

class ScrollCursorToMiddle extends ScrollCursor
  @extend()
  isScrollable: ->
    true

  getScrollTop: ->
    @pixelCursorTop - (@editor.getHeight() / 2)

class ScrollCursorToTopLeave extends ScrollCursorToTop
  keepCursor: true

class ScrollCursorToBottomLeave extends ScrollCursorToBottom
  keepCursor: true

class ScrollCursorToMiddleLeave extends ScrollCursorToMiddle
  keepCursor: true

# Horizontal Scroll
# -------------------------
class ScrollHorizontal extends Scroll
  @extend()
  constructor: ->
    super
    cursorPos = @editor.getCursorScreenPosition()
    @pixelCursorTop = @editorElement.pixelPositionForScreenPosition(cursorPos).left

  putCursorOnScreen: ->
    @editor.scrollToCursorPosition({center: false})

class ScrollCursorToLeft extends ScrollHorizontal
  @extend()
  execute: ->
    @editor.setScrollLeft(@pixelCursorTop)
    @putCursorOnScreen()

class ScrollCursorToRight extends ScrollHorizontal
  @extend()
  execute: ->
    @editor.setScrollRight(@pixelCursorTop)
    @putCursorOnScreen()

module.exports = {
  ScrollDown,
  ScrollUp,

  ScrollCursorToTop,
  ScrollCursorToMiddle,
  ScrollCursorToBottom,

  ScrollCursorToTopLeave,
  ScrollCursorToMiddleLeave,
  ScrollCursorToBottomLeave,

  ScrollCursorToLeft,
  ScrollCursorToRight
 }
