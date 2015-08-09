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

class ScrollCursor extends Scroll
  @extend()
  constructor: ->
    super
    cursor = @editor.getCursorScreenPosition()
    @pixel = @editorElement.pixelPositionForScreenPosition(cursor).top

  execute: ->
    @moveToFirstCharacterOfLine() unless @options.leaveCursor

  moveToFirstCharacterOfLine: ->
    @editor.moveToFirstCharacterOfLine()

class ScrollCursorToTop extends ScrollCursor
  @extend()
  execute: ->
    super
    @scrollUp()

  scrollUp: ->
    return if @rows.last is @rows.final
    @pixel -= (@editor.getLineHeightInPixels() * @scrolloff)
    @editor.setScrollTop(@pixel)

class ScrollCursorToMiddle extends ScrollCursor
  @extend()
  execute: ->
    super
    @scrollMiddle()

  scrollMiddle: ->
    @pixel -= (@editor.getHeight() / 2)
    @editor.setScrollTop(@pixel)

class ScrollCursorToBottom extends ScrollCursor
  @extend()
  execute: ->
    super
    @scrollDown()

  scrollDown: ->
    return if @rows.first is 0
    offset = (@editor.getLineHeightInPixels() * (@scrolloff + 1))
    @pixel -= (@editor.getHeight() - offset)
    @editor.setScrollTop(@pixel)

class ScrollHorizontal extends Scroll
  @extend()
  constructor: ->
    super
    cursorPos = @editor.getCursorScreenPosition()
    @pixel = @editorElement.pixelPositionForScreenPosition(cursorPos).left

  putCursorOnScreen: ->
    @editor.scrollToCursorPosition({center: false})

class ScrollCursorToLeft extends ScrollHorizontal
  @extend()
  execute: ->
    @editor.setScrollLeft(@pixel)
    @putCursorOnScreen()

class ScrollCursorToRight extends ScrollHorizontal
  @extend()
  execute: ->
    @editor.setScrollRight(@pixel)
    @putCursorOnScreen()

module.exports = {ScrollDown, ScrollUp, ScrollCursorToTop, ScrollCursorToMiddle,
  ScrollCursorToBottom, ScrollCursorToLeft, ScrollCursorToRight}
