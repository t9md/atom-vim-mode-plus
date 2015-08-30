# Refactoring status: 70%
{Point, Range} = require 'atom'
_    = require 'underscore-plus'
Base = require './base'

class TextObject extends Base
  @extend()
  complete: true
  recodable: false

  rangeToBeginningOfFile: (point) ->
    new Range(Point.ZERO, point)

  rangeToEndOfFile: (point) ->
    new Range(point, Point.INFINITY)

# class CurrentSelection extends TextObject
#   @extend()
#   select: ->
#     _.times @getCount(1), ->
#       true

# Word
# -------------------------
# [FIXME] Need to be extendable.
class SelectWord extends TextObject
  @extend()
  select: ->
    for selection in @editor.getSelections()
      wordRegex = @wordRegExp ? selection.cursor.wordRegExp()
      @selectExclusive(selection, wordRegex)
      @selectInclusive(selection) if @inclusive
      not selection.isEmpty()

  selectExclusive: (selection, wordRegex) ->
    range = selection.cursor.getCurrentWordBufferRange({wordRegex})
    selection.setBufferRange(range)

  selectInclusive: (selection) ->
    scanRange = selection.cursor.getCurrentLineBufferRange()
    headPoint = selection.getHeadBufferPosition()
    scanRange.start = headPoint
    @editor.scanInBufferRange /\s+/, scanRange, ({range, stop}) ->
      if headPoint.isEqual(range.start)
        selection.selectToBufferPosition range.end
        stop()

class SelectInsideWord extends SelectWord
  @extend()

class SelectAWord extends SelectInsideWord
  @extend()
  inclusive: true

class SelectInsideWholeWord extends SelectWord
  @extend()
  wordRegExp: /\S+/

class SelectAWholeWord extends SelectInsideWholeWord
  @extend()
  inclusive: true

# Pair
# -------------------------
class SelectInsidePair extends TextObject
  @extend()
  inclusive: false
  pair: null

  findPair: (fromPoint, pair, backward=false) ->
    [search, searchPair] = pair
    pairRegexp = pair.map(_.escapeRegExp).join('|')
    pattern   = ///(?:#{pairRegexp})///g

    [scanFunc, scanRange] =
      if backward
        ['backwardsScanInBufferRange', @rangeToBeginningOfFile(fromPoint)]
      else
        ['scanInBufferRange', @rangeToEndOfFile(fromPoint)]

    nest = 0
    point = null
    @editor[scanFunc] pattern, scanRange, ({matchText, range, stop}) =>
      charPre = @editor.getTextInBufferRange(range.traverse([0, -1], [0, -1]))
      return if charPre is '\\' # Skip escaped char with '\'
      if search is searchPair
        point = range.end
      else
        lastChar = matchText[matchText.length-1]
        switch lastChar
          when search
            if (nest is 0) then point = range.end else nest--
          when searchPair
            nest++
      stop() if point
    point

  select: ->
    pair = @pair.split('')
    pairReversed = pair.slice().reverse()
    for selection in @editor.getSelections()
      point  = selection.getHeadBufferPosition()
      start  = @findPair(point, pair, true)
      start ?= @findPair(point, pair)
      if start? and (end = @findPair(start, pairReversed)?.traverse([0, -1]))
        range = new Range(start, end)
        range = range.translate([0, -1], [0, 1]) if @inclusive
        selection.setBufferRange(range)
      not selection.isEmpty()

class SelectInsideDoubleQuotes extends SelectInsidePair
  @extend()
  pair: '""'
class SelectAroundDoubleQuotes extends SelectInsideDoubleQuotes
  @extend()
  inclusive: true

class SelectInsideSingleQuotes extends SelectInsidePair
  @extend()
  pair: "''"
class SelectAroundSingleQuotes extends SelectInsideSingleQuotes
  @extend()
  inclusive: true

class SelectInsideBackTicks extends SelectInsidePair
  @extend()
  pair: '``'
class SelectAroundBackTicks extends SelectInsideBackTicks
  @extend()
  inclusive: true

class SelectInsideCurlyBrackets extends SelectInsidePair
  @extend()
  pair: '{}'
class SelectAroundCurlyBrackets extends SelectInsideCurlyBrackets
  @extend()
  inclusive: true

class SelectInsideAngleBrackets extends SelectInsidePair
  @extend()
  pair: '<>'
class SelectAroundAngleBrackets extends SelectInsideAngleBrackets
  @extend()
  inclusive: true

# [FIXME] See #795
class SelectInsideTags extends SelectInsidePair
  @extend()
  pair: '><'
class SelectAroundTags extends SelectInsideTags
  @extend()
  inclusive: true

class SelectInsideSquareBrackets extends SelectInsidePair
  @extend()
  pair: '[]'
class SelectAroundSquareBrackets extends SelectInsideSquareBrackets
  @extend()
  inclusive: true

class SelectInsideParentheses extends SelectInsidePair
  @extend()
  pair: '()'
class SelectAroundParentheses extends SelectInsideParentheses
  @extend()
  inclusive: true

# Paragraph
# -------------------------
# In Vim world Paragraph is defined as consecutive (non-)blank-line.
class SelectInsideParagraph extends TextObject
  @extend()
  linewise: false

  isLinewise: ->
    @linewise

  getStartRow: (startRow, fn) ->
    for row in [startRow..0] when fn(row)
      return row+1
    0

  getEndRow: (startRow, fn) ->
    lastRow = @editor.getLastBufferRow()
    for row in [startRow..lastRow] when fn(row)
      return row
    lastRow+1

  getRange: (startRow) ->
    startRowIsBlank = @editor.isBufferRowBlank(startRow)
    fn = (row) =>
      @editor.isBufferRowBlank(row) isnt startRowIsBlank
    new Range([@getStartRow(startRow, fn), 0], [@getEndRow(startRow, fn), 0])

  selectParagraph: (selection) ->
    [startRow, endRow] = selection.getBufferRowRange()
    if startRow is endRow
      @linewise = true
      if range = @getRange(startRow)
        selection.setBufferRange(range)
    else # have direction
      if selection.isReversed()
        if range = @getRange(startRow-1)
          selection.selectToBufferPosition range.start
      else
        if range = @getRange(endRow+1)
          selection.selectToBufferPosition range.end

  selectExclusive: (selection) ->
    @selectParagraph(selection)

  selectInclusive: (selection) ->
    @selectParagraph(selection)
    @selectParagraph(selection)

  select: ->
    results = []
    for selection in @editor.getSelections()
      _.times @getCount(1), =>
        if @inclusive
          @selectInclusive(selection)
        else
          @selectExclusive(selection)
      results.push not selection.isEmpty()
    if @isLinewise() and @vimState.isVisualMode() and @vimState.submode isnt 'linewise'
      @vimState.activateVisualMode('linewise')
    results

class SelectAroundParagraph extends SelectInsideParagraph
  @extend()
  inclusive: true

class SelectInsideComment extends SelectInsideParagraph
  @extend()
  selectInclusive: (selection) ->
    @selectParagraph(selection)

  getRange: (startRow) ->
    return unless @editor.isBufferRowCommented(startRow)
    fn = (row) =>
      return if (@inclusive and @editor.isBufferRowBlank(row))
      @editor.isBufferRowCommented(row) in [false, undefined]
    new Range([@getStartRow(startRow, fn), 0], [@getEndRow(startRow, fn), 0])

class SelectAroundComment extends SelectInsideComment
  @extend()
  inclusive: true

class SelectInsideIndent extends SelectInsideParagraph
  @extend()
  selectInclusive: (selection) ->
    @selectParagraph(selection)

  getRange: (startRow) ->
    return if @editor.isBufferRowBlank(startRow)
    text = @editor.lineTextForBufferRow(startRow)
    baseIndentLevel = @editor.indentLevelForLine(text)
    fn = (row) =>
      if @editor.isBufferRowBlank(row)
        if @inclusive then false else true
      else
        text = @editor.lineTextForBufferRow(row)
        @editor.indentLevelForLine(text) < baseIndentLevel
    new Range([@getStartRow(startRow, fn), 0], [@getEndRow(startRow, fn), 0])

class SelectAroundIndent extends SelectInsideIndent
  @extend()
  inclusive: true

module.exports = {
  # CurrentSelection
  SelectInsideWord          , SelectAWord
  SelectInsideWholeWord     , SelectAWholeWord
  SelectInsideDoubleQuotes  , SelectAroundDoubleQuotes
  SelectInsideSingleQuotes  , SelectAroundSingleQuotes
  SelectInsideBackTicks     , SelectAroundBackTicks
  SelectInsideCurlyBrackets , SelectAroundCurlyBrackets
  SelectInsideAngleBrackets , SelectAroundAngleBrackets
  SelectInsideTags          , SelectAroundTags
  SelectInsideSquareBrackets, SelectAroundSquareBrackets
  SelectInsideParentheses   , SelectAroundParentheses
  SelectInsideParagraph     , SelectAroundParagraph
  SelectInsideComment       , SelectAroundComment
  SelectInsideIndent        , SelectAroundIndent
}
