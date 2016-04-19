{Point, Disposable, CompositeDisposable} = require 'atom'

settings = require './settings'
swrap = require './selection-wrapper'
isSpecMode = atom.inSpecMode()
lineHeight = null

getCursorNode = (editorElement, cursor) ->
  cursorsComponent = editorElement.component.linesComponent.cursorsComponent
  cursorsComponent.cursorNodesById[cursor.id]

# Return cursor style offset(top, left)
# ---------------------------------------
getOffset = (submode, cursor, isSoftWrapped) ->
  {selection, editor} = cursor
  traversal = new Point(0, 0)
  switch submode
    when 'characterwise', 'blockwise'
      if not selection.isReversed() and not cursor.isAtBeginningOfLine()
        traversal.column -= 1
    when 'linewise'
      bufferPoint = swrap(selection).getCharacterwiseHeadPosition()
      # FIXME need to update original getCharacterwiseHeadPosition?
      # to reflect outer vmp command modify linewise selection?
      [startRow, endRow] = selection.getBufferRowRange()
      if selection.isReversed()
        bufferPoint.row = startRow

      traversal = if isSoftWrapped
        screenPoint = editor.screenPositionForBufferPosition(bufferPoint)
        screenPoint.traversalFrom(cursor.getScreenPosition())
      else
        bufferPoint.traversalFrom(cursor.getBufferPosition())
  if not selection.isReversed() and cursor.isAtBeginningOfLine() and submode isnt 'blockwise'
    traversal.row = -1
  traversal

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
    @subscriptions?.dispose()
    @lineHeightObserver.dispose()
    {@subscriptions, @lineHeightObserver} = {}

  refresh: ->
    {submode} = @vimState
    @subscriptions?.dispose()
    @subscriptions = new CompositeDisposable
    return unless (@vimState.isMode('visual') and settings.get('showCursorInVisualMode'))

    cursors = cursorsToShow = @editor.getCursors()
    if submode is 'blockwise'
      cursorsToShow = @vimState.getBlockwiseSelections().map (bs) -> bs.getHeadSelection().cursor

    # update visibility
    for cursor in cursors
      if cursor in cursorsToShow
        cursor.setVisible(true) unless cursor.isVisible()
      else
        cursor.setVisible(false) if cursor.isVisible()

    # [NOTE] In BlockwiseSelect we add selections(and corresponding cursors) in bluk.
    # But corresponding cursorsComponent(HTML element) is added in sync.
    # So to modify style of cursorsComponent, we have to make sure corresponding cursorsComponent
    # is available by component in sync to model.
    @editorElement.component.updateSync() if submode in ['characterwise', 'blockwise']

    # [FIXME] In spec mode, we skip here since not all spec have dom attached.
    return if isSpecMode
    isSoftWrapped = @editor.isSoftWrapped()
    for cursor in cursorsToShow when cursorNode = getCursorNode(@editorElement, cursor)
      @subscriptions.add setStyle(cursorNode.style, getOffset(submode, cursor, isSoftWrapped))

module.exports = CursorStyleManager
