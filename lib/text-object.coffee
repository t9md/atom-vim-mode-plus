# Refactoring status: 70%
{Point, Range} = require 'atom'
_    = require 'underscore-plus'
Base = require './base'
{selectLines} = require './utils'

class TextObject extends Base
  @extend()
  complete: true

  isLinewiseRange: (range) ->
    (range.start.column is 0) and (range.end.column is 0) and (not range.isEmpty())

  rangeToBeginningOfFile: (point) ->
    new Range(Point.ZERO, point)

  rangeToEndOfFile: (point) ->
    new Range(point, Point.INFINITY)

  isLinewise: ->
    @editor.getSelections().every (s) =>
      @isLinewiseRange s.getBufferRange()

  eachSelection: (callback) ->
    for s in @editor.getSelections()
      callback s
    if @isLinewise() and not @vimState.isMode('visual', 'linewise')
      @vimState.activate('visual', 'linewise')
    @isIncludeNonEmptySelection()

  isIncludeNonEmptySelection: ->
    @editor.getSelections().some((s) -> not s.isEmpty())

  sortRanges: (ranges) ->
    ranges.sort((a, b) -> a.compare(b))

  setBufferRangeSafely: (selection, range) ->
    if range
      selection.setBufferRange(range)

# Word
# -------------------------
# [FIXME] Need to be extendable.
class Word extends TextObject
  @extend()
  select: ->
    @eachSelection (selection) =>
      wordRegex = @wordRegExp ? selection.cursor.wordRegExp()
      @selectExclusive(selection, wordRegex)
      @selectInclusive(selection) if @inclusive

  selectExclusive: (s, wordRegex) ->
    @setBufferRangeSafely s, s.cursor.getCurrentWordBufferRange({wordRegex})

  selectInclusive: (selection) ->
    scanRange = selection.cursor.getCurrentLineBufferRange()
    headPoint = selection.getHeadBufferPosition()
    scanRange.start = headPoint
    @editor.scanInBufferRange /\s+/, scanRange, ({range, stop}) ->
      if headPoint.isEqual(range.start)
        selection.selectToBufferPosition range.end
        stop()

class WholeWord extends Word
  @extend()
  wordRegExp: /\S+/

# Pair
# -------------------------
class Pair extends TextObject
  @extend()
  inclusive: false
  pair: null

  isStartingPair:(str, char) ->
    pattern = ///[^\\]?#{_.escapeRegExp(char)}///
    count = str.split(pattern).length - 1
    (count % 2) is 1

  needStopSearch: (pair, cursorRow, row) ->
    pair not in ["{}", "[]", "()"] and (cursorRow isnt row)

  findPair: (cursorPoint, fromPoint, pair, backward=false) ->
    pairChars = pair.split('')
    pairChars.reverse() unless backward
    [search, searchPair] = pairChars
    pairRegexp = pairChars.map(_.escapeRegExp).join('|')
    pattern   = ///(?:#{pairRegexp})///g

    [scanFunc, scanRange] =
      if backward
        ['backwardsScanInBufferRange', @rangeToBeginningOfFile(fromPoint)]
      else
        ['scanInBufferRange', @rangeToEndOfFile(fromPoint)]

    nest = 0
    found = null # We will search to fill this var.
    @editor[scanFunc] pattern, scanRange, ({matchText, range, stop}) =>
      charPre = @editor.getTextInBufferRange(range.traverse([0, -1], [0, -1]))
      return if charPre is '\\' # Skip escaped char with '\'
      {end, start} = range

      # don't search across line unless specific pair.
      return stop() if @needStopSearch(pair, cursorPoint.row, start.row)

      if search is searchPair
        if backward
          text = @editor.lineTextForBufferRow(fromPoint.row)
          found = end if @isStartingPair(text[0..end.column], search)
        else # skip for pair not within cursorPoint.
          if end.isLessThan(cursorPoint) then stop() else found = end
      else
        switch matchText[matchText.length-1]
          when search then (if (nest is 0) then found = end else nest--)
          when searchPair then nest++
      stop() if found
    found

  getRange: (selection, pair) ->
    if originallyEmpty = selection.isEmpty()
      selection.selectRight()
    point = selection.getHeadBufferPosition()
    start  = @findPair(point, point, pair, true)
    range = null
    if start? and (end = @findPair(point, start, pair)?.traverse([0, -1]))
      range = new Range(start, end)
      range = range.translate([0, -1], [0, 1]) if @inclusive
    unless range and originallyEmpty
      selection.selectLeft()
    range

  select: ->
    @eachSelection (s) =>
      @setBufferRangeSafely s, @getRange(s, @pair)

class AnyPair extends Pair
  @extend()
  pairs: ['""', "''", "``", "{}", "<>", "><", "[]", "()"]

  getNearestRange: (selection, pairs) ->
    ranges = []
    for pair in pairs when (range = @getRange(selection, pair))
      ranges.push range
    _.last(@sortRanges(ranges)) unless _.isEmpty(ranges)

  select: ->
    @eachSelection (s) =>
      @setBufferRangeSafely s, @getNearestRange(s, @pairs)

class DoubleQuote extends Pair
  @extend()
  pair: '""'

class SingleQuote extends Pair
  @extend()
  pair: "''"

class BackTick extends Pair
  @extend()
  pair: '``'

class CurlyBracket extends Pair
  @extend()
  pair: '{}'

class AngleBracket extends Pair
  @extend()
  pair: '<>'

# [FIXME] See #795
class Tag extends Pair
  @extend()
  pair: '><'

class SquareBracket extends Pair
  @extend()
  pair: '[]'

class Parenthesis extends Pair
  @extend()
  pair: '()'

# Paragraph
# -------------------------
# In Vim world Paragraph is defined as consecutive (non-)blank-line.
class Paragraph extends TextObject
  @extend()

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
      @setBufferRangeSafely selection, @getRange(startRow)
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
    @eachSelection (selection) =>
      _.times @getCount(), =>
        if @inclusive
          @selectInclusive(selection)
        else
          @selectExclusive(selection)

class Comment extends Paragraph
  @extend()
  selectInclusive: (selection) ->
    @selectParagraph(selection)

  getRange: (startRow) ->
    return unless @editor.isBufferRowCommented(startRow)
    fn = (row) =>
      return if (@inclusive and @editor.isBufferRowBlank(row))
      @editor.isBufferRowCommented(row) in [false, undefined]
    new Range([@getStartRow(startRow, fn), 0], [@getEndRow(startRow, fn), 0])

class Indentation extends Paragraph
  @extend()
  selectInclusive: (selection) ->
    @selectParagraph(selection)

  getRange: (startRow) ->
    return if @editor.isBufferRowBlank(startRow)
    text = @editor.lineTextForBufferRow(startRow)
    baseIndentLevel = @editor.indentLevelForLine(text)
    fn = (row) =>
      if @editor.isBufferRowBlank(row)
        not @inclusive
      else
        text = @editor.lineTextForBufferRow(row)
        @editor.indentLevelForLine(text) < baseIndentLevel
    new Range([@getStartRow(startRow, fn), 0], [@getEndRow(startRow, fn), 0])

# TODO: make it extendable when repeated
class Fold extends TextObject
  @extend()
  getRowRangeForBufferRow: (bufferRow) ->
    for currentRow in [bufferRow..0] by -1
      [startRow, endRow] = @editor.languageMode.rowRangeForCodeFoldAtBufferRow(currentRow) ? []
      continue unless startRow? and startRow <= bufferRow <= endRow
      startRow += 1 unless @inclusive
      return [startRow, endRow]

  select: ->
    @eachSelection (selection) =>
      [startRow, endRow] = selection.getBufferRowRange()
      row = if selection.isReversed() then startRow else endRow
      if rowRange = @getRowRangeForBufferRow(row)
        selectLines(selection, rowRange)

# NOTE: Function range determination is depending on fold.
class Function extends Fold
  @extend()
  indentScopedLanguages: ['python', 'coffee']
  # FIXME: why go dont' fold closing '}' for function? this is dirty workaround.
  omitingClosingCharLanguages: ['go']

  getScopesForRow: (row) ->
    tokenizedLine = @editor.displayBuffer.tokenizedBuffer.tokenizedLineForRow(row)
    for tag in tokenizedLine.tags when tag < 0 and (tag % 2 is -1)
      atom.grammars.scopeForId(tag)

  functionScopeRegexp = /^entity.name.function/
  isIncludeFunctionScopeForRow: (row) ->
    for scope in @getScopesForRow(row) when functionScopeRegexp.test(scope)
      return true
    null

  # Greatly depending on fold, and what range is folded is vary from languages.
  # So we need to adjust endRow based on scope.
  getRowRangeForBufferRow: (bufferRow) ->
    for currentRow in [bufferRow..0] by -1
      [startRow, endRow] = @editor.languageMode.rowRangeForCodeFoldAtBufferRow(currentRow) ? []
      unless startRow? and (startRow <= bufferRow <= endRow) and @isIncludeFunctionScopeForRow(startRow)
        continue
      return @adjustRowRange(startRow, endRow)
    null

  adjustRowRange: (startRow, endRow) ->
    {scopeName} = @editor.getGrammar()
    languageName = scopeName.replace(/^source\./, '')
    unless @inclusive
      startRow += 1
      unless languageName in @indentScopedLanguages
        endRow -= 1
    endRow += 1 if (languageName in @omitingClosingCharLanguages)
    [startRow, endRow]

class CurrentLine extends TextObject
  @extend()
  select: ->
    @eachSelection (selection) =>
      {cursor} = selection
      cursor.moveToBeginningOfLine()
      cursor.moveToFirstCharacterOfLine() unless @inclusive
      selection.selectToEndOfLine()

class Entire extends TextObject
  @extend()
  select: ->
    @editor.selectAll()
    @isIncludeNonEmptySelection()

module.exports = {
  Word, WholeWord,
  DoubleQuote, SingleQuote, BackTick, CurlyBracket , AngleBracket, Tag,
  SquareBracket, Parenthesis,
  AnyPair
  Paragraph, Comment, Indentation,
  Fold, Function,
  CurrentLine, Entire,
}
