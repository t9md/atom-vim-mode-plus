{Point, Disposable, CompositeDisposable} = require 'atom'
Delegato = require 'delegato'
swrap = require './selection-wrapper'

# Display cursor in visual-mode
# ----------------------------------
class CursorStyleManager
  lineHeight: null

  Delegato.includeInto(this)
  @delegatesProperty('mode', 'submode', toProperty: 'vimState')

  constructor: (@vimState) ->
    {@editorElement, @editor} = @vimState
    @disposable = atom.config.observe 'editor.lineHeight', (newValue) =>
      @lineHeight = newValue
      @refresh()

  destroy: ->
    @styleDisposables?.dispose()
    @disposable.dispose()

  refresh: ->
    # Intentionally skip in spec mode, since not all spec have DOM attached( and don't want to ).
    return if atom.inSpecMode()

    @styleDisposables?.dispose()
    return unless (@mode is 'visual' and @vimState.getConfig('showCursorInVisualMode'))

    @styleDisposables = new CompositeDisposable
    if @submode is 'blockwise'
      cursorsToShow = @vimState.getBlockwiseSelections().map (bs) -> bs.getHeadSelection().cursor
    else
      cursorsToShow = @editor.getCursors()

    # In blockwise, show only blockwise-head cursor
    for cursor in @editor.getCursors()
      cursor.setVisible(cursor in cursorsToShow)

    # [NOTE] When activating visual-blockwise-mode multiple slections are added in bulk.
    # But corresponding cursorsComponent(HTML element) is added asynchronously.
    # We need to make sure that corresponding cursor's domNode is available to modify it's style.
    if @submode is 'blockwise'
      @editorElement.component.updateSync()

    # [NOTE] Using non-public API
    cursorNodesById = @editorElement.component.linesComponent.cursorsComponent.cursorNodesById
    for cursor in cursorsToShow when cursorNode = cursorNodesById[cursor.id]
      @styleDisposables.add @modifyStyle(cursor, cursorNode)

  # Apply selection property's traversal from actual cursor to cursorNode's style
  modifyStyle: (cursor, domNode) ->
    selection = cursor.selection
    {row, column} = switch @submode
      when 'linewise'
        if selection.editor.isSoftWrapped()
          swrap(selection).getCursorTraversalFromPropertyInScreenPosition(true)
        else
          swrap(selection).getCursorTraversalFromPropertyInBufferPosition(true)
      else
        swrap(selection).getCursorTraversalFromPropertyInBufferPosition()

    style = domNode.style
    style.setProperty('top', "#{row * @lineHeight}em") if row
    style.setProperty('left', "#{column}ch") if column
    new Disposable ->
      style.removeProperty('top')
      style.removeProperty('left')

module.exports = CursorStyleManager
