# Refactoring status: 100%
Base = require './base'
class Scroll extends Base
  @extend()
  complete: true
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
    amountInPixel = @editor.getLineHeightInPixels() * @getCount()
    scrollTop = @editorElement.getScrollTop()
    switch @direction
      when 'down' then scrollTop += amountInPixel
      when 'up'   then scrollTop -= amountInPixel
    @editorElement.setScrollTop scrollTop
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
    # console.log 'top', @getPixelCursor('top')
    @getPixelCursor('top') - @getOffSetPixelHeight()

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
    @getPixelCursor('top') - (@editorElement.getHeight() - @getOffSetPixelHeight(1))

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
    @getPixelCursor('top') - (@editorElement.getHeight() / 2)

# zz
class ScrollCursorToMiddleLeave extends ScrollCursorToMiddle
  @extend()
  moveToFirstCharacterOfLine: null

# Horizontal Scroll
# -------------------------
# zs
class ScrollCursorToLeft extends Scroll
  @extend()
  direction: 'left'

  initialize: ->
    @px = @getPixelCursor('left')

  execute: ->
    @editorElement.setScrollLeft(@px)

# ze
class ScrollCursorToRight extends ScrollCursorToLeft
  @extend()
  direction: 'right'

  execute: ->
    @editorElement.setScrollRight(@px)

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
