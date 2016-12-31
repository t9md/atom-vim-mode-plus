{Range, Point} = require 'atom'
_ = require 'underscore-plus'
settings = require './settings'

# [TODO] Need overhaul
#  - [ ] must have getRange(selection) ->
#  - [ ] Remove selectTextObject?
#  - [ ] Make expandable by selection.getBufferRange().union(@getRange(selection))
#  - [ ] Count support(priority low)?
Base = require './base'
swrap = require './selection-wrapper'
{
  getLineTextToBufferPosition
  getIndentLevelForBufferRow
  getCodeFoldRowRangesContainesForRow
  getBufferRangeForRowRange
  isIncludeFunctionScopeForRow
  expandRangeToWhiteSpaces
  getVisibleBufferRange
  translatePointAndClip
  getBufferRows
  getValidVimBufferRow
  trimRange
} = require './utils'

class TextObject extends Base
  @extend(false)
  wise: null
  supportCount: false # FIXME #472, #66

  constructor: ->
    @constructor::inner = @getName().startsWith('Inner')
    super
    @initialize()

  isInner: ->
    @inner

  isA: ->
    not @isInner()

  isSuportCount: ->
    @supportCount

  getWise: ->
    if @wise? and @getOperator().isOccurrence()
      'characterwise'
    else
      @wise

  isCharacterwise: ->
    @getWise() is 'characterwise'

  isLinewise: ->
    @getWise() is 'linewise'

  isBlockwise: ->
    @getWise() is 'blockwise'

  getNormalizedHeadBufferPosition: (selection) ->
    head = selection.getHeadBufferPosition()
    if @isMode('visual') and not selection.isReversed()
      head = translatePointAndClip(@editor, head, 'backward')
    head

  getNormalizedHeadScreenPosition: (selection) ->
    bufferPosition = @getNormalizedHeadBufferPosition(selection)
    @editor.screenPositionForBufferPosition(bufferPosition)

  needToKeepColumn: ->
    @wise is 'linewise' and
      settings.get('keepColumnOnSelectTextObject') and
      @getOperator().instanceof('Select')

  execute: ->
    # Whennever TextObject is executed, it has @operator
    # Called from Operator::selectTarget()
    #  - `v i p`, is `Select` operator with @target = `InnerParagraph`.
    #  - `d i p`, is `Delete` operator with @target = `InnerParagraph`.
    if @hasOperator()
      @select()
    else
      throw new Error('in TextObject: Must not happen')

  select: ->
    selectResults = []
    @countTimes @getCount(), ({stop}) =>
      @stopSelection = stop

      for selection in @editor.getSelections()
        selectResults.push(@selectTextObject(selection))
        unless @isSuportCount()
          @stopSelection() # FIXME: quick-fix for #560


    if @needToKeepColumn()
      for selection in @editor.getSelections()
        swrap(selection).clipPropertiesTillEndOfLine()

    @editor.mergeIntersectingSelections()
    if @isMode('visual') and @wise is 'characterwise'
      @updateSelectionProperties()

    if selectResults.some((value) -> value)
      @wise ?= swrap.detectVisualModeSubmode(@editor)
    else
      @wise = null

  selectTextObject: (selection) ->
    if range = @getRange(selection)
      oldRange = selection.getBufferRange()

      needToKeepColumn = @needToKeepColumn()
      if needToKeepColumn and not @isMode('visual', 'linewise')
        @vimState.modeManager.activate('visual', 'linewise')

      # Prevent autoscroll to closing char on `change-surround-any-pair`.
      options = {
        autoscroll: selection.isLastSelection() and not @getOperator().supportEarlySelect
        keepGoalColumn: needToKeepColumn
      }
      swrap(selection).setBufferRangeSafely(range, options)

      newRange = selection.getBufferRange()
      if newRange.isEqual(oldRange)
        @stopSelection() # FIXME: quick-fix for #560

      true
    else
      @stopSelection() # FIXME: quick-fix for #560
      false

  getRange: ->
    # I want to
    # throw new Error('text-object must respond to range by getRange()!')

# -------------------------
class Word extends TextObject
  @extend(false)

  getRange: (selection) ->
    point = @getNormalizedHeadBufferPosition(selection)
    {range} = @getWordBufferRangeAndKindAtBufferPosition(point, {@wordRegex})
    if @isA()
      expandRangeToWhiteSpaces(@editor, range, ['forward', 'backward'])
    else
      range

class AWord extends Word
  @extend()

class InnerWord extends Word
  @extend()

# -------------------------
class WholeWord extends Word
  @extend(false)
  wordRegex: /\S+/

class AWholeWord extends WholeWord
  @extend()

class InnerWholeWord extends WholeWord
  @extend()

# -------------------------
# Just include _, -
class SmartWord extends Word
  @extend(false)
  wordRegex: /[\w-]+/

class ASmartWord extends SmartWord
  @description: "A word that consists of alphanumeric chars(`/[A-Za-z0-9_]/`) and hyphen `-`"
  @extend()

class InnerSmartWord extends SmartWord
  @description: "Currently No diff from `a-smart-word`"
  @extend()

# -------------------------
# Just include _, -
class Subword extends Word
  @extend(false)
  getRange: (selection) ->
    @wordRegex = selection.cursor.subwordRegExp()
    super

class ASubword extends Subword
  @extend()

class InnerSubword extends Subword
  @extend()

# Paragraph
# -------------------------
# Paragraph is defined as consecutive (non-)blank-line.
class Paragraph extends TextObject
  @extend(false)
  wise: 'linewise'
  supportCount: true

  findRow: (fromRow, direction, fn) ->
    fn.reset?()
    foundRow = fromRow
    for row in getBufferRows(@editor, {startRow: fromRow, direction})
      break unless fn(row, direction)
      foundRow = row

    foundRow

  findRowRangeBy: (fromRow, fn) ->
    startRow = @findRow(fromRow, 'previous', fn)
    endRow = @findRow(fromRow, 'next', fn)
    [startRow, endRow]

  getPredictFunction: (fromRow, selection) ->
    fromRowResult = @editor.isBufferRowBlank(fromRow)

    if @isInner()
      predict = (row, direction) =>
        @editor.isBufferRowBlank(row) is fromRowResult
    else
      if selection.isReversed()
        directionToExtend = 'previous'
      else
        directionToExtend = 'next'

      flip = false
      predict = (row, direction) =>
        result = @editor.isBufferRowBlank(row) is fromRowResult
        if flip
          not result
        else
          if (not result) and (direction is directionToExtend)
            flip = true
            return true
          result

      predict.reset = ->
        flip = false
    predict

  getRange: (selection) ->
    originalRange = selection.getBufferRange()
    fromRow = @getNormalizedHeadBufferPosition(selection).row

    if @isMode('visual', 'linewise')
      if selection.isReversed()
        fromRow--
      else
        fromRow++
      fromRow = getValidVimBufferRow(@editor, fromRow)

    rowRange = @findRowRangeBy(fromRow, @getPredictFunction(fromRow, selection))
    selection.getBufferRange().union(getBufferRangeForRowRange(@editor, rowRange))

class AParagraph extends Paragraph
  @extend()

class InnerParagraph extends Paragraph
  @extend()

# -------------------------
class Indentation extends Paragraph
  @extend(false)

  getRange: (selection) ->
    fromRow = @getNormalizedHeadBufferPosition(selection).row

    baseIndentLevel = getIndentLevelForBufferRow(@editor, fromRow)
    predict = (row) =>
      if @editor.isBufferRowBlank(row)
        @isA()
      else
        getIndentLevelForBufferRow(@editor, row) >= baseIndentLevel

    rowRange = @findRowRangeBy(fromRow, predict)
    getBufferRangeForRowRange(@editor, rowRange)

class AIndentation extends Indentation
  @extend()

class InnerIndentation extends Indentation
  @extend()

# -------------------------
class Comment extends TextObject
  @extend(false)
  wise: 'linewise'

  getRange: (selection) ->
    row = swrap(selection).getStartRow()
    rowRange = @editor.languageMode.rowRangeForCommentAtBufferRow(row)
    rowRange ?= [row, row] if @editor.isBufferRowCommented(row)
    if rowRange
      getBufferRangeForRowRange(selection.editor, rowRange)

class AComment extends Comment
  @extend()

class InnerComment extends Comment
  @extend()

# -------------------------
class Fold extends TextObject
  @extend(false)
  wise: 'linewise'

  adjustRowRange: (rowRange) ->
    return rowRange unless @isInner()

    [startRow, endRow] = rowRange
    startRowIndentLevel = getIndentLevelForBufferRow(@editor, startRow)
    endRowIndentLevel = getIndentLevelForBufferRow(@editor, endRow)
    endRow -= 1 if (startRowIndentLevel is endRowIndentLevel)
    startRow += 1
    [startRow, endRow]

  getFoldRowRangesContainsForRow: (row) ->
    getCodeFoldRowRangesContainesForRow(@editor, row, includeStartRow: @isA()).reverse()

  getRange: (selection) ->
    rowRanges = @getFoldRowRangesContainsForRow(swrap(selection).getStartRow())
    return unless rowRanges.length

    range = getBufferRangeForRowRange(@editor, @adjustRowRange(rowRanges.shift()))
    if rowRanges.length and range.isEqual(selection.getBufferRange())
      range = getBufferRangeForRowRange(@editor, @adjustRowRange(rowRanges.shift()))
    range

class AFold extends Fold
  @extend()

class InnerFold extends Fold
  @extend()

# -------------------------
# NOTE: Function range determination is depending on fold.
class Function extends Fold
  @extend(false)

  # Some language don't include closing `}` into fold.
  scopeNamesOmittingEndRow: ['source.go', 'source.elixir']

  getFoldRowRangesContainsForRow: (row) ->
    rowRanges = getCodeFoldRowRangesContainesForRow(@editor, row)?.reverse()
    rowRanges?.filter (rowRange) =>
      isIncludeFunctionScopeForRow(@editor, rowRange[0])

  adjustRowRange: (rowRange) ->
    [startRow, endRow] = super
    if @isA() and @editor.getGrammar().scopeName in @scopeNamesOmittingEndRow
      endRow += 1
    [startRow, endRow]

class AFunction extends Function
  @extend()

class InnerFunction extends Function
  @extend()

# -------------------------
class CurrentLine extends TextObject
  @extend(false)
  getRange: (selection) ->
    row = @getNormalizedHeadBufferPosition(selection).row
    range = @editor.bufferRangeForBufferRow(row)
    if @isA()
      range
    else
      trimRange(@editor, range)

class ACurrentLine extends CurrentLine
  @extend()

class InnerCurrentLine extends CurrentLine
  @extend()

# -------------------------
class Entire extends TextObject
  @extend(false)

  getRange: (selection) ->
    @stopSelection()
    @editor.buffer.getRange()

class AEntire extends Entire
  @extend()

class InnerEntire extends Entire
  @extend()

# Alias as accessible name
class All extends Entire
  @extend(false)

# -------------------------
class Empty extends TextObject
  @extend(false)

# -------------------------
class LatestChange extends TextObject
  @extend(false)
  getRange: ->
    @stopSelection()
    @vimState.mark.getRange('[', ']')

class ALatestChange extends LatestChange
  @extend()

# No diff from ALatestChange
class InnerLatestChange extends LatestChange
  @extend()

# -------------------------
class SearchMatchForward extends TextObject
  @extend()
  backward: false

  findMatch: (fromPoint, pattern) ->
    fromPoint = translatePointAndClip(@editor, fromPoint, "forward") if @isMode('visual')
    scanRange = [[fromPoint.row, 0], @getVimEofBufferPosition()]
    found = null
    @editor.scanInBufferRange pattern, scanRange, ({range, stop}) ->
      if range.end.isGreaterThan(fromPoint)
        found = range
        stop()
    {range: found, whichIsHead: 'end'}

  getRange: (selection) ->
    pattern = @globalState.get('lastSearchPattern')
    return unless pattern?

    fromPoint = selection.getHeadBufferPosition()
    {range, whichIsHead} = @findMatch(fromPoint, pattern)
    if range?
      @unionRangeAndDetermineReversedState(selection, range, whichIsHead)

  unionRangeAndDetermineReversedState: (selection, found, whichIsHead) ->
    if selection.isEmpty()
      found
    else
      head = found[whichIsHead]
      tail = selection.getTailBufferPosition()

      if @backward
        head = translatePointAndClip(@editor, head, 'forward') if tail.isLessThan(head)
      else
        head = translatePointAndClip(@editor, head, 'backward') if head.isLessThan(tail)

      @reversed = head.isLessThan(tail)
      new Range(tail, head).union(swrap(selection).getTailBufferRange())

  selectTextObject: (selection) ->
    return unless range = @getRange(selection)
    reversed = @reversed ? @backward
    swrap(selection).setBufferRange(range, {reversed})
    selection.cursor.autoscroll()
    true

class SearchMatchBackward extends SearchMatchForward
  @extend()
  backward: true

  findMatch: (fromPoint, pattern) ->
    fromPoint = translatePointAndClip(@editor, fromPoint, "backward") if @isMode('visual')
    scanRange = [[fromPoint.row, Infinity], [0, 0]]
    found = null
    @editor.backwardsScanInBufferRange pattern, scanRange, ({range, stop}) ->
      if range.start.isLessThan(fromPoint)
        found = range
        stop()
    {range: found, whichIsHead: 'start'}

# [Limitation: won't fix]: Selected range is not submode aware. always characterwise.
# So even if original selection was vL or vB, selected range by this text-object
# is always vC range.
class PreviousSelection extends TextObject
  @extend()

  select: ->
    {properties, submode} = @vimState.previousSelection
    if properties? and submode?
      selection = @editor.getLastSelection()
      swrap(selection).selectByProperties(properties)
      @wise = submode

class PersistentSelection extends TextObject
  @extend(false)

  select: ->
    ranges = @vimState.persistentSelection.getMarkerBufferRanges()
    if ranges.length
      @editor.setSelectedBufferRanges(ranges)
      @vimState.clearPersistentSelections()
      @wise = swrap.detectVisualModeSubmode(@editor)

class APersistentSelection extends PersistentSelection
  @extend()

class InnerPersistentSelection extends PersistentSelection
  @extend()

# -------------------------
class VisibleArea extends TextObject # 822 to 863
  @extend(false)

  getRange: (selection) ->
    @stopSelection()
    # [BUG?] Need translate to shilnk top and bottom to fit actual row.
    # The reason I need -2 at bottom is because of status bar?
    bufferRange = getVisibleBufferRange(@editor)
    if bufferRange.getRows() > @editor.getRowsPerPage()
      bufferRange.translate([+1, 0], [-3, 0])
    else
      bufferRange

class AVisibleArea extends VisibleArea
  @extend()

class InnerVisibleArea extends VisibleArea
  @extend()

# -------------------------
# [FIXME] wise mismatch sceenPosition vs bufferPosition
class Edge extends TextObject
  @extend(false)
  wise: 'linewise'

  getRange: (selection) ->
    fromPoint = @getNormalizedHeadScreenPosition(selection)

    moveUpToEdge = @new('MoveUpToEdge')
    moveDownToEdge = @new('MoveDownToEdge')
    return unless moveUpToEdge.isStoppablePoint(fromPoint)

    startScreenPoint = endScreenPoint = null
    startScreenPoint = endScreenPoint = fromPoint if moveUpToEdge.isEdge(fromPoint)

    if moveUpToEdge.isStoppablePoint(fromPoint.translate([-1, 0]))
      startScreenPoint = moveUpToEdge.getPoint(fromPoint)

    if moveDownToEdge.isStoppablePoint(fromPoint.translate([+1, 0]))
      endScreenPoint = moveDownToEdge.getPoint(fromPoint)

    if startScreenPoint? and endScreenPoint?
      screenRange = new Range(startScreenPoint, endScreenPoint)
      range = @editor.bufferRangeForScreenRange(screenRange)
      getBufferRangeForRowRange(@editor, [range.start.row, range.end.row])

class AEdge extends Edge
  @extend()

class InnerEdge extends Edge
  @extend()
