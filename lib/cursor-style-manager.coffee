{Point, Disposable, CompositeDisposable} = require 'atom'
Delegato = require 'delegato'
SupportCursorSetVisible = null

# Display cursor in visual-mode
# ----------------------------------
module.exports =
class CursorStyleManager
  lineHeight: null

  Delegato.includeInto(this)
  @delegatesProperty('mode', 'submode', toProperty: 'vimState')

  constructor: (@vimState) ->
    {@editorElement, @editor} = @vimState
    SupportCursorSetVisible ?= @editor.getLastCursor().setVisible?
    @disposables = new CompositeDisposable
    @disposables.add atom.config.observe('editor.lineHeight', @refresh)
    @disposables.add atom.config.observe('editor.fontSize', @refresh)
    @vimState.onDidDestroy(@destroy)

  destroy: =>
    @styleDisposables?.dispose()
    @disposables.dispose()

  updateCursorStyleOld: ->
    # We must dispose previous style modification for non-visual-mode
    @styleDisposables?.dispose()
    @styleDisposables = new CompositeDisposable
    return unless @mode is 'visual'

    if @submode is 'blockwise'
      cursorsToShow = @vimState.getBlockwiseSelections().map (bs) -> bs.getHeadSelection().cursor
    else
      cursorsToShow = @editor.getCursors()

    # In visual-mode or in occurrence operation, cursor are added during operation but selection is added asynchronously.
    # We have to make sure that corresponding cursor's domNode is available at this point to directly modify it's style.
    @editorElement.component.updateSync()
    for cursor in @editor.getCursors()
      cursorIsVisible = cursor in cursorsToShow
      cursor.setVisible(cursorIsVisible)
      if cursorIsVisible
        @styleDisposables.add @modifyCursorStyle(cursor, @getCursorStyle(cursor, true))

  modifyCursorStyle: (cursor, cursorStyle) ->
    cursorStyle = @getCursorStyle(cursor, true)
    # [NOTE] Using non-public API
    cursorNode = @editorElement.component.linesComponent.cursorsComponent.cursorNodesById[cursor.id]
    if cursorNode
      cursorNode.style.setProperty('top', cursorStyle.top)
      cursorNode.style.setProperty('left', cursorStyle.left)
      new Disposable ->
        cursorNode.style?.removeProperty('top')
        cursorNode.style?.removeProperty('left')
    else
      new Disposable

  updateCursorStyleNew: ->
    # We must dispose previous style modification for non-visual-mode
    # Intentionally collect all decorations from editor instead of managing
    # decorations we created explicitly.
    # Why? when intersecting multiple selections are auto-merged, it's got wired
    # state where decoration cannot be disposable(not investigated well).
    # And I want to assure ALL cursor style modification done by vmp is cleared.
    for decoration in @editor.getDecorations(type: 'cursor', class: 'vim-mode-plus')
      decoration.destroy()

    return unless @mode is 'visual'

    if @submode is 'blockwise'
      cursorsToShow = @vimState.getBlockwiseSelections().map (bs) -> bs.getHeadSelection().cursor
    else
      cursorsToShow = @editor.getCursors()

    for cursor in @editor.getCursors()
      @editor.decorateMarker cursor.getMarker(),
        type: 'cursor'
        class: 'vim-mode-plus'
        style: @getCursorStyle(cursor, cursor in cursorsToShow)

  refresh: =>
    # Intentionally skip in spec mode, since not all spec have DOM attached( and don't want to ).
    return if atom.inSpecMode()

    @lineHeight = @editor.getLineHeightInPixels()

    if SupportCursorSetVisible
      @updateCursorStyleOld()
    else
      @updateCursorStyleNew()

  getCursorBufferPositionToDisplay: (selection) ->
    bufferPosition = @vimState.swrap(selection).getBufferPositionFor('head', from: ['property'])
    if @editor.hasAtomicSoftTabs() and not selection.isReversed()
      screenPosition = @editor.screenPositionForBufferPosition(bufferPosition.translate([0, +1]), clipDirection: 'forward')
      bufferPositionToDisplay = @editor.bufferPositionForScreenPosition(screenPosition).translate([0, -1])
      if bufferPositionToDisplay.isGreaterThan(bufferPosition)
        bufferPosition = bufferPositionToDisplay

    @editor.clipBufferPosition(bufferPosition)

  getCursorStyle: (cursor, visible) ->
    if visible
      bufferPosition = @getCursorBufferPositionToDisplay(cursor.selection)
      if @submode is 'linewise' and (@editor.isSoftWrapped() or @editor.isFoldedAtBufferRow(bufferPosition.row))
        screenPosition = @editor.screenPositionForBufferPosition(bufferPosition)
        {row, column} = screenPosition.traversalFrom(cursor.getScreenPosition())
      else
        {row, column} = bufferPosition.traversalFrom(cursor.getBufferPosition())

      return {
        top: @lineHeight * row + 'px'
        left: column + 'ch'
        visibility: 'visible'
      }
    else
      return {visibility: 'hidden'}
