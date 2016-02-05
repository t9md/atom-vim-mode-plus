_ = require 'underscore-plus'
{Range} = require 'atom'

Base = require './base'
swrap = require './selection-wrapper'
{
  sortComparable
  getFirstSelectionOrderedByBufferPosition
  getLastSelectionOrderedByBufferPosition
} = require './utils'

class BlockwiseSelection
  constructor: (@selections) ->
    unless @hasTail()
      @setProperties {head: @getBottom(), tail: @getTop()}

  eachSelection: (fn) ->
    for selection in @selections
      fn(selection)

  updateProperties: ({head, tail}={}) ->
    head ?= @getHead()
    tail ?= @getTail()
    @setProperties {head, tail}

  setProperties: ({head, tail}) ->
    @eachSelection (selection) ->
      prop = {}
      prop.head = (selection is head) if head?
      prop.tail = (selection is tail) if tail?
      swrap(selection).setProperties(blockwise: prop)

  isSingleLine: ->
    @selections.length is 1

  getTop: ->
    sortComparable(@selections)[0]

  getBottom: ->
    _.last(sortComparable(@selections))

  isReversed: ->
    (not @isSingleLine()) and @getTail() is @getBottom()

  getHead: ->
    if @isReversed() then @getTop() else @getBottom()

  getTail: ->
    _.detect @selections, (selection) ->
      swrap(selection).isBlockwiseTail()

  hasTail: ->
    @getTail()?

  otherEnd: ->
    @setProperties {head: @getTail(), tail: @getHead()}

  getBufferRowRange: ->
    startRow = @getTop().getBufferRowRange()[0]
    endRow = @getBottom().getBufferRowRange()[0]
    [startRow, endRow]

  setBufferPosition: (point) ->
    head = @getHead()
    for selection in @selections.slice() when selection isnt head
      @removeSelection(selection)
    head.cursor.setBufferPosition(point)

  modifySelection: (direction) ->
    isExpanding = =>
      return true if @isSingleLine()
      switch direction
        when 'down' then not @isReversed()
        when 'up' then @isReversed()

    if isExpanding()
      @addSelection(direction)
    else
      @removeSelection(@getHead())

    @updateProperties()

  addSelection: (direction) ->
    switch direction
      when 'up' then @addSelectionAbove()
      when 'down' then @addSelectionBelow()
    {editor} = @selections[0]
    @selections.push(editor.getLastSelection())

    tailSelection = @getTail()
    swrap.setReversedState(tailSelection.editor, tailSelection.isReversed())

  removeSelection: (selection) ->
    _.remove(@selections, selection)
    selection.destroy()

  getLastSelection: ->
    @selections[0].editor.getLastSelection()

  addSelectionBelow: ->
    @getBottom().addSelectionBelow()
    @getLastSelection()

  addSelectionAbove: ->
    @getTop().addSelectionAbove()
    @getLastSelection()

  restoreCharacterwise: ->
    reversed = @isReversed()
    head = @getHead()
    headIsReversed = head.isReversed()
    [startRow, endRow] = @getBufferRowRange()
    {start: {column: startColumn}, end: {column: endColumn}} = head.getBufferRange()
    if reversed isnt headIsReversed
      [startColumn, endColumn] = [endColumn, startColumn]
      startColumn -= 1
      endColumn += 1
    range = [[startRow, startColumn], [endRow, endColumn]]

    {editor} =  @selections[0]
    editor.setSelectedBufferRange(range, {reversed})

class VisualBlockwise extends Base
  eachBlockwiseSelection: (fn) ->
    selections = @editor.getSelections()
    blockwiseSelection = new BlockwiseSelection(selections)
    fn(blockwiseSelection)

class BlockwiseOtherEnd extends VisualBlockwise
  @extend()
  execute: ->
    @eachBlockwiseSelection (blockwiseSelection) ->
      unless blockwiseSelection.isSingleLine()
        blockwiseSelection.otherEnd()
    @new('ReverseSelections').execute()

class BlockwiseMoveDown extends VisualBlockwise
  @extend()
  direction: 'down'

  execute: ->
    @eachBlockwiseSelection (blockwiseSelection) =>
      @countTimes =>
        blockwiseSelection.modifySelection(@direction)

class BlockwiseMoveUp extends BlockwiseMoveDown
  @extend()
  direction: 'up'

class BlockwiseDeleteToLastCharacterOfLine extends VisualBlockwise
  @extend()
  delegateTo: 'DeleteToLastCharacterOfLine'
  recordable: true

  execute: ->
    pointByBlockwiseSelection = new Map

    @eachBlockwiseSelection (blockwiseSelection) ->
      blockwiseSelection.eachSelection (selection) ->
        {start} = selection.getBufferRange()
        selection.cursor.setBufferPosition(start)

      point = blockwiseSelection.getTop().getHeadBufferPosition()
      pointByBlockwiseSelection.set(blockwiseSelection, point)

    @new(@delegateTo).execute()

    pointByBlockwiseSelection.forEach (point, blockwiseSelection) ->
      blockwiseSelection.setBufferPosition(point)

class BlockwiseChangeToLastCharacterOfLine extends BlockwiseDeleteToLastCharacterOfLine
  @extend()
  delegateTo: 'ChangeToLastCharacterOfLine'

class BlockwiseInsertAtBeginningOfLine extends VisualBlockwise
  @extend()
  delegateTo: 'ActivateInsertMode'
  recordable: true
  whichSide: 'start'

  execute: ->
    for selection in @editor.getSelections()
      point = selection.getBufferRange()[@whichSide]
      selection.cursor.setBufferPosition(point)
    @new(@delegateTo).execute()

class BlockwiseInsertAfterEndOfLine extends BlockwiseInsertAtBeginningOfLine
  @extend()
  whichSide: 'end'

class BlockwiseRestoreCharacterwise extends VisualBlockwise
  @extend(false)
  execute: ->
    @eachBlockwiseSelection (blockwiseSelection) ->
      blockwiseSelection.restoreCharacterwise()
