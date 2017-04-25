{Point, Disposable, CompositeDisposable} = require 'atom'
Delegato = require 'delegato'
SupportCursorSetVisible = null

# Display cursor in visual-mode
# ----------------------------------
class CursorStyleManager
  lineHeight: null

  Delegato.includeInto(this)
  @delegatesProperty('mode', 'submode', toProperty: 'vimState')

  constructor: (@vimState) ->
    {@editorElement, @editor} = @vimState
    @disposables = new CompositeDisposable
    @disposables.add atom.config.observe('editor.lineHeight', @refresh)
    @disposables.add atom.config.observe('editor.fontSize', @refresh)
    @vimState.onDidDestroy(@destroy)

  destroy: =>
    @styleDisposables?.dispose()
    @disposables.dispose()

  refresh: =>
    # Intentionally skip in spec mode, since not all spec have DOM attached( and don't want to ).
    return if atom.inSpecMode()
    @lineHeight = @editor.getLineHeightInPixels()

    # We must dispose previous style modification for non-visual-mode
    @styleDisposables?.dispose()
    return unless @mode is 'visual'

    @styleDisposables = new CompositeDisposable
    if @submode is 'blockwise'
      cursorsToShow = @vimState.getBlockwiseSelections().map (bs) -> bs.getHeadSelection().cursor
    else
      cursorsToShow = @editor.getCursors()

    SupportCursorSetVisible ?= @editor.getLastCursor().setVisible?

    if SupportCursorSetVisible
      # FIXME: In visual-mode or in occurrence operation, cursor are added during operation but selection is added asynchronously.
      # We have to make sure that corresponding cursor's domNode is available at this point to directly modify it's style.
      @editorElement.component.updateSync()

    for cursor in @editor.getCursors()
      # In blockwise, show only blockwise-head cursor
      cursorIsVisible = cursor in cursorsToShow
      if SupportCursorSetVisible
        cursor.setVisible(cursor, cursorIsVisible)
      else
        visibility = if cursorIsVisible then 'visible' else 'hidden'
        @editor.decorateMarker(cursor.getMarker(), type: 'cursor', style: {visibility})
      continue unless cursorIsVisible

      traversal = @getCursorTraversal(cursor)
      cursorStyle = {
        top: @lineHeight * traversal.row + 'px'
        left: traversal.column + 'ch'
      }

      if SupportCursorSetVisible
        # [NOTE] Using non-public API
        cursorNode = @editorElement.component.linesComponent.cursorsComponent.cursorNodesById[cursor.id]
        cursorNode.style.setProperty('top', cursorStyle.top)
        cursorNode.style.setProperty('left', cursorStyle.left)
        @styleDisposables.add new Disposable ->
          cursorNode.style.removeProperty('top')
          cursorNode.style.removeProperty('left')
      else
        # @editorElement.component.getNextUpdatePromise().then =>
        #   for cursorNode in @editorElement.querySelectorAll('.cursor')
        #     console.log [cursorNode.style.top, cursorNode.style.left]
        cursorMarker = cursor.getMarker()
        @editor.decorateMarker(cursorMarker, type: 'cursor', style: cursorStyle)
        @styleDisposables.add new Disposable =>
          @editor.decorateMarker(cursorMarker, type: 'cursor', style: {top: '0px', left: '0ch'})

  getCursorBufferPositionToDisplay: (selection) ->
    bufferPosition = @vimState.swrap(selection).getBufferPositionFor('head', from: ['property'])
    if @editor.hasAtomicSoftTabs() and not selection.isReversed()
      screenPosition = @editor.screenPositionForBufferPosition(bufferPosition.translate([0, +1]), clipDirection: 'forward')
      bufferPositionToDisplay = @editor.bufferPositionForScreenPosition(screenPosition).translate([0, -1])
      if bufferPositionToDisplay.isGreaterThan(bufferPosition)
        bufferPosition = bufferPositionToDisplay

    @editor.clipBufferPosition(bufferPosition)

  getCursorTraversal: (cursor) ->
    selection = cursor.selection
    bufferPosition = @getCursorBufferPositionToDisplay(selection)

    if @submode is 'linewise' and @editor.isSoftWrapped()
      screenPosition = @editor.screenPositionForBufferPosition(bufferPosition)
      screenPosition.traversalFrom(cursor.getScreenPosition())
    else
      bufferPosition.traversalFrom(cursor.getBufferPosition())

module.exports = CursorStyleManager
