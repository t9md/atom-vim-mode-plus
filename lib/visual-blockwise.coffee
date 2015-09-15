Base = require './base'
_ = require 'underscore-plus'

# FIXME Currently initally multi selected situation not supported.
class VisualBlockwise extends Base
  @extend()
  complete: true
  recodable: false

  clearTail: ->
    for s in @editor.getSelections()
      s.marker.setProperties(vimModeBlockwiseTail: false)

  getTop: ->
    _.first @editor.getSelectionsOrderedByBufferPosition()

  getBottom: ->
    _.last @editor.getSelectionsOrderedByBufferPosition()

  isReversed: ->
    if @isSingle()
      false
    else
      @getTail().marker.isEqual @getBottom().marker

  isSingle: ->
    @editor.getSelections().length is 1

  getHead: ->
    if @isReversed()
      @getTop()
    else
      @getBottom()

  getTail: ->
    _.detect @editor.getSelections(), (s) ->
      s.marker.getProperties().vimModeBlockwiseTail

  setTail: (newTail) ->
    @clearTail()
    newTail.marker.setProperties(vimModeBlockwiseTail: true)

  constructor: ->
    super
    if @isSingle()
      @clearTail()

  dump: (header) ->
    console.log "--#{header}-"
    for s in @editor.getSelections()
      range = s.marker.getBufferRange().toString()
      isTail = s.marker.getProperties().vimModeBlockwiseTail
      console.log "#{range} #{isTail}"
    console.log "---"

  reverse: ->
    newTail = if @isReversed() then @getTop() else @getBottom()
    @setTail newTail

class BlockwiseOtherEnd extends VisualBlockwise
  @extend()
  execute: ->
    unless @isSingle()
      @reverse()
    @vimState.reverseSelections()

class BlockwiseMoveDown extends VisualBlockwise
  @extend()
  direction: 'Below'

  isForward: ->
    not @isReversed()

  execute: ->
    if @isSingle()
      @setTail @getTop()

    if @isForward()
      @editor["addSelection#{@direction}"]()
      @vimState.syncSelectionsReversedSate(@getTail().isReversed())
    else
      @getHead().destroy()

class BlockwiseMoveUp extends BlockwiseMoveDown
  @extend()
  direction: 'Above'
  isForward: ->
    @isSingle() or @isReversed()

class BlockwiseDeleteToLastCharacterOfLine extends VisualBlockwise
  @extend()
  delegateTo: 'DeleteToLastCharacterOfLine'
  execute: ->
    @vimState.activateNormalMode()
    point = @getTop().cursor.getBufferPosition()
    @new(@delegateTo).execute()
    @editor.clearSelections()
    @editor.setCursorBufferPosition(point)

class BlockwiseChangeToLastCharacterOfLine extends BlockwiseDeleteToLastCharacterOfLine
  @extend()
  delegateTo: 'ChangeToLastCharacterOfLine'

class BlockwiseInsertAtBeginningOfLine extends VisualBlockwise
  @extend()
  command: 'I'
  execute: ->
    cursorsAdjusted = []

    adjustCursor = (selection) =>
      {start, end} = selection.getBufferRange()
      pointEndOfLine = @editor.bufferRangeForBufferRow(start.row).end
      pointTarget    = {'I': start, 'A': end}[@command]
      {cursor}       = selection

      if pointTarget.isGreaterThanOrEqual(pointEndOfLine)
        pointTarget = pointEndOfLine
        cursorsAdjusted.push cursor
      cursor.setBufferPosition(pointTarget)

    for selection in @editor.getSelections()
      adjustCursor(selection)
    @vimState.activateNormalMode()
    @vimState.activateInsertMode()

    if @command is 'A' and  cursorsAdjusted.length
      cursor.moveRight() for cursor in cursorsAdjusted

class BlockwiseInsertAfterEndOfLine extends BlockwiseInsertAtBeginningOfLine
  @extend()
  command: 'A'

class BlockwiseEscape extends VisualBlockwise
  @extend()
  execute: ->
    @clearTail()
    @vimState.activateNormalMode()
    @editor.clearSelections()

module.exports = {
  VisualBlockwise,
  BlockwiseOtherEnd,
  BlockwiseMoveDown,
  BlockwiseMoveUp,
  BlockwiseDeleteToLastCharacterOfLine,
  BlockwiseChangeToLastCharacterOfLine,
  BlockwiseInsertAtBeginningOfLine,
  BlockwiseInsertAfterEndOfLine,
  BlockwiseEscape,
}
