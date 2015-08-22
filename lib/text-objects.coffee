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
class SelectWord extends TextObject
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

  findCharForward: (fromPoint, char) ->
    @findChar(fromPoint, char, false)

  findCharBackward: (fromPoint, char) ->
    @findChar(fromPoint, char, true)

  findChar: (fromPoint, char, backward=false) ->
    if backward
      scanRange = @rangeToBeginningOfFile(fromPoint)
      scanFunc = 'backwardsScanInBufferRange'
    else
      scanRange = @rangeToEndOfFile(fromPoint)
      scanFunc = 'scanInBufferRange'
    pattern   = ///(?:[^\\]|^)(?:#{_.escapeRegExp(char)})///
    point = null
    @editor[scanFunc] pattern, scanRange, ({range, stop}) ->
      point = range.end
      stop()
    point

  findPairClosing: (fromPoint, pair, backward=false) ->
    @findPair(fromPoint, 'closing', pair, backward)

  findPairOpening: (fromPoint, pair, backward=false) ->
    @findPair(fromPoint, 'opening', pair, backward)

  # which: opening or closing
  findPair: (fromPoint, which, pair, backward=false) ->
    [charOpening, charClosing] = pair.split('')
    pair = pair.split('').map(_.escapeRegExp).join('|')
    pattern   = ///(?:[^\\]|^)(?:#{pair})///g
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
    @editor[scanFunc] pattern, scanRange, ({matchText, range, stop}) ->
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
  pair: '""'
class SelectAroundDoubleQuotes extends SelectInsideDoubleQuotes
  inclusive: true

class SelectInsideSingleQuotes extends SelectInsidePair
  pair: "''"
class SelectAroundSingleQuotes extends SelectInsideSingleQuotes
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
# In vim world Paragraph is defined as consecutive non-blank-line or consecutive blank-line.
# depending on the start line is blankline or not.
# Should change linewise selection.
# selectExclusive = (selection, wordRegex) ->
# In vim world Paragraph is defined as consecutive non-blank-line or consecutive blank-line.
# depending on the start line is blankline or not.
# Should change linewise selection.
class SelectInsideParagraph extends TextObject
  @extend()

  isWhiteSpaceRow: (row) ->
    /^\s*$/.test @editor.lineTextForBufferRow(row)

  getRange: (point) ->
    pattern = if @isWhiteSpaceRow(point.row) then /^.*\S.*$/ else /^\s*?$/
    start = @findStart(point, pattern)
    end = @findEnd(point, pattern)
    new Range(start, end)

  getNextRange: (point, direction) ->
    rowTraverse = switch direction
      when 'forward'  then +1
      when 'backward' then -1
    @getRange point.traverse([rowTraverse, 0])

  findStart: (fromPoint, pattern) ->
    scanRange = @rangeToBeginningOfFile(fromPoint)
    point = null
    @editor.backwardsScanInBufferRange pattern, scanRange, ({range, stop}) ->
      point = range.start.traverse([+1, 0])
      stop()
    point

  findEnd: (fromPoint, pattern) ->
    scanRange = @rangeToEndOfFile(fromPoint)
    point = null
    @editor.scanInBufferRange pattern, scanRange, ({range, stop}) =>
      point = range.start
      stop()
    point

  selectParagraph: (selection) ->
    [startRow, endRow] = selection.getBufferRowRange()
    selectionEndRow = selection.getBufferRange().end.row
    if startRow is endRow
      range = @getRange(new Point(startRow, 0))
      selection.setBufferRange(range)
    else # have direction
      if selection.isReversed()
        range = @getNextRange(new Point(startRow, 0), "backward")
        selection.selectToBufferPosition(range.start)
      else
        range = @getNextRange(new Point(endRow, 0), "forward")
        selection.selectToBufferPosition(range.end)

  select: ->
    for selection in @editor.getSelections()
      _.times @getCount(1), =>
        @selectParagraph(selection)
        @selectParagraph(selection) if @inclusive
      not selection.isEmpty()

class SelectAroundParagraph extends SelectInsideParagraph
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
