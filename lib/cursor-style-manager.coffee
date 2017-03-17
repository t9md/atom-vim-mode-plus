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
    cursors = cursorsToShow = @editor.getCursors()
    if @submode is 'blockwise'
      cursorsToShow = @vimState.getBlockwiseSelections().map (bs) -> bs.getHeadSelection().cursor

    for cursor in cursors
      if cursor in cursorsToShow
        cursor.setVisible(true) unless cursor.isVisible()
      else
        cursor.setVisible(false) if cursor.isVisible()

    # [NOTE] In BlockwiseSelect we add selections(and corresponding cursors) in bluk.
    # But corresponding cursorsComponent(HTML element) is added in sync.
    # So to modify style of cursorsComponent, we have to make sure corresponding cursorsComponent
    # is available by component in sync to model.
    # [FIXME]
    # When ctrl-f, b, d, u in vL mode, I had to call updateSync to show cursor correctly
    # But it wasn't necessary before I iintroduce `moveToFirstCharacterOnVerticalMotion` for `ctrl-f`
    @editorElement.component.updateSync()

    for cursor in cursorsToShow when @needModifyStyle(cursor.selection) and domNode = @getCursorNode(cursor)
      @styleDisposables.add(@modifyStyle(cursor, domNode))

  needModifyStyle: (selection) ->
    switch @submode
      when 'characterwise'
        not selection.isReversed()
      when 'linewise'
        true
      when 'blockwise'
        not (selection.isReversed() or selection.cursor.isAtBeginningOfLine())

  getCursorNode: (cursor) ->
    @editorElement.component.linesComponent.cursorsComponent.cursorNodesById[cursor.id]

  # Apply selection property's traversal from actual cursor to cursorNode's style
  modifyStyle: (cursor, domNode) ->
    selection = cursor.selection
    {row, column} = switch @submode
      when 'characterwise'
        swrap(selection).getCursorTraversalFromPropertyInBufferPosition()
        # TODO-#698 Enabled this again when performance is important.
        # if cursor.isAtBeginningOfLine()
        #   new Point(-1, 0)
        # else
        #   new Point(0, -1)
      when 'linewise'
        if selection.editor.isSoftWrapped()
          swrap(selection).getCursorTraversalFromPropertyInScreenPosition(true)
        else
          swrap(selection).getCursorTraversalFromPropertyInBufferPosition(true)
      when 'blockwise'
        new Point(0, -1)

    style = domNode.style

    style.setProperty('top', "#{row * @lineHeight}em") if row
    style.setProperty('left', "#{column}ch") if column
    new Disposable ->
      style.removeProperty('top')
      style.removeProperty('left')

module.exports = CursorStyleManager
