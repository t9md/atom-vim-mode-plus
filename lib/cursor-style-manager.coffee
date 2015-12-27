{Disposable, CompositeDisposable} = require 'atom'

settings = require './settings'
swrap = require './selection-wrapper'

RowHeightInEm = 1.5

getDomNode = (editorElement, cursor) ->
  cursorsComponent = editorElement.component.linesComponent.cursorsComponent
  cursorsComponent.cursorNodesById[cursor.id]

# Return cursor style top, left offset for **sowft-wrapped** line
# -------------------------
getOffsetForSelection = (selection) ->
  {editor} = selection
  bufferPoint = swrap(selection).getCharacterwiseHeadPosition()
  screenPoint = editor.screenPositionForBufferPosition(bufferPoint)
  bufferRange = editor.bufferRangeForBufferRow(bufferPoint.row)
  screenRows = editor.screenRangeForBufferRange(bufferRange).getRows()
  rows = if selection.isReversed()
    screenRows.indexOf(screenPoint.row)
  else
    -(screenRows.reverse().indexOf(screenPoint.row) + 1)
  {top: rows * RowHeightInEm, left: screenPoint.column}

setStyleOffset = (cursor, {submode, editor, editorElement}) ->
  domNode = getDomNode(editorElement, cursor)

  # This guard is for test spec, not all spec have dom attached.
  return (new Disposable) unless domNode

  {selection} = cursor
  {style} = domNode
  switch submode
    when 'linewise'
      if editor.isSoftWrapped()
        {left, top} = getOffsetForSelection(selection)
        style.setProperty('left', "#{left}ch") if left
        style.setProperty('top', "#{top}em") if top
      else
        {column} = swrap(selection).getCharacterwiseHeadPosition()
        style.setProperty('left', "#{column}ch")
        style.setProperty('top', "-#{RowHeightInEm}em") unless selection.isReversed()
    when 'characterwise', 'blockwise'
      unless selection.isReversed()
        if cursor.isAtBeginningOfLine()
          style.setProperty('top', "-#{RowHeightInEm}em")
        else
          style.setProperty('left', '-1ch')

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
    cursorsToShow = if @vimState.submode is 'blockwise'
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

    {submode} = @vimState
    for cursor in cursorsToShow
      @subscriptions.add setStyleOffset(cursor, {submode, @editor, @editorElement})

module.exports = CursorStyleManager
