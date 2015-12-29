{Disposable, CompositeDisposable} = require 'atom'

settings = require './settings'
swrap = require './selection-wrapper'

RowHeightInEm = 1.5

getDomNode = (editorElement, cursor) ->
  cursorsComponent = editorElement.component.linesComponent.cursorsComponent
  cursorsComponent.cursorNodesById[cursor.id]

# Return cursor style top, left offset for **sowft-wrapped** line
# -------------------------
getOffset = (submode, selection) ->
  {top, left} = {}
  switch submode
    when 'characterwise', 'blockwise'
      unless selection.isReversed()
        if selection.cursor.isAtBeginningOfLine()
          top = -RowHeightInEm
        else
          left = -1
    when 'linewise'
      {editor} = selection
      bufferPoint = swrap(selection).getCharacterwiseHeadPosition()
      if editor.isSoftWrapped()
        screenPoint = editor.screenPositionForBufferPosition(bufferPoint)
        bufferRange = editor.bufferRangeForBufferRow(bufferPoint.row)
        screenRows = editor.screenRangeForBufferRange(bufferRange).getRows()
        rows = if selection.isReversed()
          screenRows.indexOf(screenPoint.row)
        else
          -(screenRows.reverse().indexOf(screenPoint.row) + 1)
        top = rows * RowHeightInEm
        left = screenPoint.column
      else
        top = -RowHeightInEm unless selection.isReversed()
        left = bufferPoint.column
  {top, left}

setStyleOffset = (cursor, {submode, editor, editorElement}) ->
  domNode = getDomNode(editorElement, cursor)
  # This guard is for test spec, not all spec have dom attached.
  return (new Disposable) unless domNode

  {style} = domNode
  {left, top} = getOffset(submode, cursor.selection)
  style.setProperty('top', "#{top}em") if top?
  style.setProperty('left', "#{left}ch") if left?

  new Disposable ->
    style.removeProperty('top')
    style.removeProperty('left')


# Display cursor in visual mode.
# ----------------------------------
class CursorStyleManager
  constructor: (@vimState) ->
    {@editorElement, @editor} = @vimState
    @subscriptions = new CompositeDisposable

  destroy: ->
    @subscriptions.dispose()
    {@subscriptions} = {}

  refresh: ->
    @subscriptions.dispose()
    @subscriptions = new CompositeDisposable
    return unless (@vimState.isMode('visual') and settings.get('showCursorInVisualMode'))

    cursors = @editor.getCursors()
    {submode} = @vimState
    cursorsToShow = if submode is 'blockwise'
      (cursor for cursor in cursors when swrap(cursor.selection).isBlockwiseHead())
    else
      cursors

    for cursor in cursors
      if cursor in cursorsToShow
        cursor.setVisible(true) unless cursor.isVisible()
      else
        cursor.setVisible(false) if cursor.isVisible()

    # [NOTE] In BlockwiseSelect we add selections(and corresponding cursors) in bluk.
    # But corresponding cursorsComponent(HTML element) is added in sync.
    # So to modify style of cursorsComponent, we have to make sure corresponding cursorsComponent
    # is available by component in sync to model.
    @editorElement.component.updateSync()

    for cursor in cursorsToShow
      @subscriptions.add setStyleOffset(cursor, {submode, @editor, @editorElement})

module.exports = CursorStyleManager
