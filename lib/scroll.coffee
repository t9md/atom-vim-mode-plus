# Refactoring status: 100%
Base = require './base'
class Scroll extends Base
  @extend()
  complete: true
  recodable: false
  scrolloff: 2 # atom default. Better to use editor.getVerticalScrollMargin()?

  getFirstVisibleScreenRow: ->
    @editorElement.getFirstVisibleScreenRow()

  getLastVisibleScreenRow: ->
    @editorElement.getLastVisibleScreenRow()

  getLastScreenRow: ->
    @editor.getLastScreenRow()

  getPixelCursor: (which) -> # which is `top` or `left`
    point = @editor.getCursorScreenPosition()
    @editorElement.pixelPositionForScreenPosition(point)[which]

# ctrl-e scroll lines downwards
class ScrollDown extends Scroll
  @extend()
  direction: 'down'

  execute: ->
    amountInPixel = @editor.getLineHeightInPixels() * @getCount(1)
    scrollTop = @editor.getScrollTop()
    switch @direction
      when 'down' then scrollTop += amountInPixel
      when 'up'   then scrollTop -= amountInPixel
    @editor.setScrollTop scrollTop
    @keepCursorOnScreen?()

  keepCursorOnScreen: ->
    {row, column} = @editor.getCursorScreenPosition()
    newRow =
      if row < (rowMin = @getFirstVisibleScreenRow() + @scrolloff)
        rowMin
      else if row > (rowMax = @getLastVisibleScreenRow() - (@scrolloff + 1))
        rowMax
    @editor.setCursorScreenPosition [newRow, column] if newRow?

# ctrl-y scroll lines upwards
class ScrollUp extends ScrollDown
  @extend()
  direction: 'up'

# Scroll without Cursor Position change.
# -------------------------
class ScrollCursor extends Scroll
  @extend()
  execute: ->
    @moveToFirstCharacterOfLine?()
    if @isScrollable()
      @editor.setScrollTop @getScrollTop()

  moveToFirstCharacterOfLine: ->
    @editor.moveToFirstCharacterOfLine()

  getOffSetPixelHeight: (lineDelta=0) ->
    @editor.getLineHeightInPixels() * (@scrolloff + lineDelta)

class ScrollCursorToTop extends ScrollCursor
  @extend()
  isScrollable: ->
    @getLastVisibleScreenRow() isnt @getLastScreenRow()

  getScrollTop: ->
    @getPixelCursor('top') - @getOffSetPixelHeight()

class ScrollCursorToBottom extends ScrollCursor
  @extend()
  isScrollable: ->
    @getFirstVisibleScreenRow() isnt 0

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
  moveToFirstCharacterOfLine: null

class ScrollCursorToBottomLeave extends ScrollCursorToBottom
  @extend()
  moveToFirstCharacterOfLine: null

class ScrollCursorToMiddleLeave extends ScrollCursorToMiddle
  @extend()
  moveToFirstCharacterOfLine: null

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
