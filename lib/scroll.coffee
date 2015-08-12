Base = require './base'
class Scroll extends Base
  @extend()
  isComplete: ->
    true
  isRecordable: ->
    false

  getPixelCursor: (which) ->
    # which is `top` or `left`
    point = @editor.getCursorScreenPosition()
    @editorElement.pixelPositionForScreenPosition(point)[which]

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
    @getPixelCursor('top') - @getOffSetPixelHeight()

class ScrollCursorToBottom extends ScrollCursor
  @extend()
  isScrollable: ->
    not (@rows.first is 0)

  getScrollTop: ->
    @getPixelCursor('top') - (@editor.getHeight() - @getOffSetPixelHeight(1))

class ScrollCursorToMiddle extends ScrollCursor
  @extend()
  isScrollable: ->
    true

  getScrollTop: ->
    @getPixelCursor('top') - (@editor.getHeight() / 2)

class ScrollCursorToTopLeave extends ScrollCursorToTop
  @extend()
  keepCursor: true

class ScrollCursorToBottomLeave extends ScrollCursorToBottom
  @extend()
  keepCursor: true

class ScrollCursorToMiddleLeave extends ScrollCursorToMiddle
  @extend()
  keepCursor: true

# Horizontal Scroll
# -------------------------
class ScrollHorizontal extends Scroll
  @extend()
  putCursorOnScreen: ->
    @editor.scrollToCursorPosition({center: false})

class ScrollCursorToLeft extends ScrollHorizontal
  @extend()
  execute: ->
    @editor.setScrollLeft(@getPixelCursor('left'))
    @putCursorOnScreen()

class ScrollCursorToRight extends ScrollHorizontal
  @extend()
  execute: ->
    @editor.setScrollRight(@getPixelCursor('left'))
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
