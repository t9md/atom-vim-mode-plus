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

class CurrentSelection extends TextObject
  @extend()
  select: ->
    _.times @getCount(1), ->
      true

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

  findPairClosing: (fromPoint, pair, backward=false) ->
    @findPair(fromPoint, 'closing', pair, backward)

  findPairOpening: (fromPoint, pair, backward=false) ->
    @findPair(fromPoint, 'opening', pair, backward)

  # which: opening or closing
  findPair: (fromPoint, which, pair, backward=false) ->
    [charOpening, charClosing] = pair.split('')
    pairRegexp = pair.split('').map(_.escapeRegExp).join('|')
    pattern   = ///(?:#{pairRegexp})///g
    if backward
      scanRange = @rangeToBeginningOfFile(fromPoint)
      scanFunc = 'backwardsScanInBufferRange'
    else
      scanRange = @rangeToEndOfFile(fromPoint)
      scanFunc = 'scanInBufferRange'

    switch which
      when 'opening' then [searching, searchingPair] = [charOpening, charClosing]
      when 'closing' then [searching, searchingPair] = [charClosing, charOpening]

    nested = 0
    point = null
    @editor[scanFunc] pattern, scanRange, ({matchText, range, stop}) =>
      charPre = @editor.getTextInBufferRange(range.traverse([0, -1], [0, -1]))
      # Skip escaped char with '\'
      return if charPre is '\\'

      if charOpening is charClosing
        point = range.end
      else
        lastChar = matchText[matchText.length-1]
        switch lastChar
          when searching
            if nested is 0
              point = range.end
            else
              nested--
          when searchingPair
            nested++
      stop() if point
    point

  select: ->
    [charOpening, charClosing] = @pair.split('')
    r = []
    for selection in @editor.getSelections()
      point = selection.getHeadBufferPosition()
      start = @findPairOpening(point, @pair, true)
      start ?= @findPairOpening(point, @pair)
      unless start?
        r.push false
        continue

      end = @findPairClosing(start, @pair)?.traverse([0, -1])
      if start? and end?
        if @inclusive
          start = start.traverse([0, -1])
          end   = end.traverse([0, +1])
        selection.setBufferRange([start, end])
      r.push not selection.isEmpty()
    r

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

  getStartRow: (startRow) ->
    startRowIsBlank = @editor.isBufferRowBlank(startRow)
    for row in [startRow..0]
      return row+1 if (@editor.isBufferRowBlank(row) isnt startRowIsBlank)
    0

  getEndRow: (startRow) ->
    startRowIsBlank = @editor.isBufferRowBlank(startRow)
    lastRow = @editor.getLastBufferRow()
    for row in [startRow..lastRow]
      return row if (@editor.isBufferRowBlank(row) isnt startRowIsBlank)
    lastRow

  getRange: (startRow) ->
    new Range([@getStartRow(startRow), 0], [@getEndRow(startRow), 0])

  selectParagraph: (selection) ->
    [startRow, endRow] = selection.getBufferRowRange()
    if startRow is endRow
      selection.setBufferRange(@getRange(startRow))
    else # have direction
      if selection.isReversed()
        range = @getRange(startRow-1)
        selection.selectToBufferPosition range.start
      else
        range = @getRange(endRow+1)
        selection.selectToBufferPosition range.end

  select: ->
    for selection in @editor.getSelections()
      _.times @getCount(1), =>
        @selectParagraph(selection)
        @selectParagraph(selection) if @inclusive
        not selection.isEmpty()

class SelectAroundParagraph extends SelectInsideParagraph
  @extend()
  inclusive: true

module.exports = {
  CurrentSelection
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
}
