editor = atom.workspace.getActiveTextEditor()
path = require 'path'
file = path.join(path.dirname(editor.getPath()), './dev-utils')
{requirePackageFile} = require file
_ = require 'underscore-plus'
{Range} = require 'atom'
# -------------------------

class DevMotion
  getTailRange: (selection) ->
    point = selection.getTailBufferPosition()
    columnDelta = if selection.isReversed() then -1 else +1
    Range.fromPointWithDelta(point, 0, columnDelta)

  selectInclusive: (selection, options) ->
    if selection.isEmpty()
      selection.selectRight()
    @selectVisual(selection, options)

    # unless selection.isEmpty()
    #   return

    # selection.modifySelection =>
    #   {cursor} = selection
    #   @moveCursor(selection.cursor, options)
    #   return if selection.isEmpty()
    #
    #   if selection.isReversed()
    #     newRange = selection.getBufferRange().translate([0, 0], [0, 1])
    #     selection.setBufferRange(newRange)
    #   else
    #     selection.cursor.moveRight()

  selectVisual: (selection, options) ->
    {cursor} = selection
    tailRange = @getTailRange(selection)
    pointTail = selection.getTailBufferPosition()
    pointHead = selection.getHeadBufferPosition()
    unless selection.isReversed()
      cursor.moveLeft()
    selection.clear()
    @moveCursor(cursor, options)
    pointDst = cursor.getBufferPosition()
    if pointTail.isLessThanOrEqual(pointDst)
      reversed = false
      cursor.moveRight()
      pointDst = cursor.getBufferPosition()
      range = new Range(pointTail, pointDst)
    else
      reversed = true
      range = new Range(pointDst, pointTail)
    selection.setBufferRange(range.union(tailRange), {reversed})

Base = requirePackageFile('vim-mode', 'base')
_ = require 'underscore-plus'
Motion =  Base.findClass 'Motion'
# console.log Motion
# selectVisualOrg = null
# selectVisualOrg ?= Motion::selectVisual
_.extend(Motion::, DevMotion::)
# Motion::selectVisual = selectVisualOrg
