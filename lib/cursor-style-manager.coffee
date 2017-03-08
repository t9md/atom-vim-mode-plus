{Point, Disposable, CompositeDisposable} = require 'atom'

swrap = require './selection-wrapper'
isSpecMode = atom.inSpecMode()
lineHeight = null

getCursorNode = (editorElement, cursor) ->
  cursorsComponent = editorElement.component.linesComponent.cursorsComponent
  cursorsComponent.cursorNodesById[cursor.id]

# Return cursor style offset(top, left)
# ---------------------------------------
getOffset = (submode, cursor) ->
  {selection} = cursor
  switch submode
    when 'characterwise'
      return if selection.isReversed()
      if cursor.isAtBeginningOfLine()
        new Point(-1, 0)
      else
        new Point(0, -1)

    when 'blockwise'
      return if cursor.isAtBeginningOfLine() or selection.isReversed()
      new Point(0, -1)

    when 'linewise'
      bufferPoint = swrap(selection).getBufferPositionFor('head', from: ['property'])
      editor = cursor.editor

      if editor.isSoftWrapped()
        screenPoint = editor.screenPositionForBufferPosition(bufferPoint)
        offset = screenPoint.traversalFrom(cursor.getScreenPosition())
      else
        offset = bufferPoint.traversalFrom(cursor.getBufferPosition())
      if not selection.isReversed() and cursor.isAtBeginningOfLine()
        offset.row = -1
      offset

setStyle = (style, {row, column}) ->
  style.setProperty('top', "#{row * lineHeight}em") unless row is 0
  style.setProperty('left', "#{column}ch") unless column is 0
  new Disposable ->
    style.removeProperty('top')
    style.removeProperty('left')

# Display cursor in visual mode.
# ----------------------------------
class CursorStyleManager
  constructor: (@vimState) ->
    {@editorElement, @editor} = @vimState
    @lineHeightObserver = atom.config.observe 'editor.lineHeight', (newValue) =>
      lineHeight = newValue
      @refresh()

  destroy: ->
    @styleDisporser?.dispose()
    @lineHeightObserver.dispose()
    {@styleDisporser, @lineHeightObserver} = {}

  refresh: ->
    {mode, submode} = @vimState
    @styleDisporser?.dispose()
    @styleDisporser = new CompositeDisposable
    return unless mode is 'visual' and @vimState.getConfig('showCursorInVisualMode')

    cursors = cursorsToShow = @editor.getCursors()
    if submode is 'blockwise'
      cursorsToShow = @vimState.getBlockwiseSelections().map (bs) -> bs.getHeadSelection().cursor

    # update visibility
    for cursor in cursors
      if cursor in cursorsToShow
        cursor.setVisible(true) unless cursor.isVisible()
      else
        cursor.setVisible(false) if cursor.isVisible()

    # [FIXME] In spec mode, we skip here since not all spec have dom attached.
    return if isSpecMode

    # [NOTE] In BlockwiseSelect we add selections(and corresponding cursors) in bluk.
    # But corresponding cursorsComponent(HTML element) is added in sync.
    # So to modify style of cursorsComponent, we have to make sure corresponding cursorsComponent
    # is available by component in sync to model.
    # [FIXME]
    # When ctrl-f, b, d, u in vL mode, I had to call updateSync to show cursor correctly
    # But it wasn't necessary before I iintroduce `moveToFirstCharacterOnVerticalMotion` for `ctrl-f`
    @editorElement.component.updateSync()

    for cursor in cursorsToShow when offset = getOffset(submode, cursor)
      if cursorNode = getCursorNode(@editorElement, cursor)
        @styleDisporser.add setStyle(cursorNode.style, offset)

module.exports = CursorStyleManager
