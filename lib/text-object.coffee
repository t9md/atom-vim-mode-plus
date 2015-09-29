# Refactoring status: 95%
{Range} = require 'atom'
_    = require 'underscore-plus'
Base = require './base'
{
  selectLines
  isLinewiseRange
  rangeToBeginningOfFileFromPoint
  rangeToEndOfFileFromPoint
  isIncludeNonEmptySelection
  sortRanges
  setSelectionBufferRangeSafely
} = require './utils'

class TextObject extends Base
  @extend()
  complete: true

  isLinewise: ->
    @editor.getSelections().every (s) ->
      isLinewiseRange s.getBufferRange()

  eachSelection: (fn) ->
    fn(s) for s in @editor.getSelections()
    if @isLinewise() and not @vimState.isMode('visual', 'linewise')
      @vimState.activate('visual', 'linewise')
    @status()

  status: ->
    isIncludeNonEmptySelection @editor.getSelections()

  execute: ->
    @select()

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
    setSelectionBufferRangeSafely s, s.cursor.getCurrentWordBufferRange({wordRegex})

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
  searchForwardingRange: false
  pair: null

  isInclusive: ->
    @inclusive

  # Return 'open' or 'close'
  getPairState: (pair, {matchText, range}) ->
    [openChar, closeChar] = pair.split('')
    {start, end} = range
    if openChar is closeChar
      text = @editor.lineTextForBufferRow(start.row)
      state = @pairStateInString(text[0..end.column], openChar)
    else
      state =
        switch pair.indexOf(matchText[matchText.length-1])
          when 0 then 'open'
          when 1 then 'close'
    state

  pairStateInString: (str, char) ->
    pattern = ///[^\\]?#{_.escapeRegExp(char)}///
    count = str.split(pattern).length - 1
    switch count % 2
      when 1 then 'open'
      when 0 then 'close'

  # Take start point of matched range.
  escapeChar = '\\'
  isEscapedCharAtPoint: (point) ->
    range = Range.fromPointWithDelta(point, 0, -1)
    @editor.getTextInBufferRange(range) is escapeChar

  findPair: (pair, options) ->
    {from, which, allowNextLine, nest} = options
    [scanFunc, scanRange] =
      switch which
        when 'open' then ['backwardsScanInBufferRange', rangeToBeginningOfFileFromPoint(from)]
        when 'close' then ['scanInBufferRange', rangeToEndOfFileFromPoint(from)]
    pairRegexp = pair.split('').map(_.escapeRegExp).join('|')
    pattern = ///#{pairRegexp}///g
    found = null # We will search to fill this var.
    @editor[scanFunc] pattern, scanRange, (arg) =>
      {matchText, range: {start, end}, stop} = arg
      return if @isEscapedCharAtPoint(start)
      return stop() if (not allowNextLine) and (from.row isnt start.row)

      if @getPairState(pair, arg) is which then nest-- else nest++
      if nest is 0
        found = end
        found = found.translate([0, -1]) if which is 'close'
        stop()
    found

  # 1. Search opening point by searching backward from given cursor point
  # 2. Search closing point by searching forwrad from opening point found in step-1.
  getRangeUnderCursor: (from, pair) ->
    range = null
    nest = 1
    allowNextLine = (pair in ["{}", "[]", "()"])
    if open = @findPair pair, {from, allowNextLine, nest, which: 'open'}
      close = @findPair pair, {from: open, allowNextLine, nest, which: 'close'}
    if open and close
      range = new Range(open, close)
      range = range.translate([0, -1], [0, 1]) if @isInclusive()
    range

  # 1. Search closing point by searching forward from given cursor point
  # 2. Search opening point by searching backward from closing point found in step-1.
  getForwardingRange: (from, pair) ->
    range = null
    allowNextLine = (pair in ["{}", "[]", "()"])
    # By setting initial nest level to 0, we can pick first found opening pair.
    if close = @findPair pair, {from, allowNextLine, nest: 0, which: 'close'}
      open = @findPair pair, {from: close, allowNextLine, nest: 1, which: 'open'}
    if open and close
      range = new Range(open, close)
      range = range.translate([0, -1], [0, 1]) if @isInclusive()
    range

  canSearchForwardingRange: ->
    @searchForwardingRange

  getRange: (selection) ->
    selection.selectRight() if wasEmpty = selection.isEmpty()
    rangeOrig = selection.getBufferRange()
    from = selection.getHeadBufferPosition()

    range  = @getRangeUnderCursor(from, @pair)
    range ?= @getForwardingRange(from, @pair) if @canSearchForwardingRange()
    if range?.isEqual(rangeOrig)
      # Since range is same area, retry to expand outer pair.
      from = range.start.translate([0, -1])
      range = @getRangeUnderCursor(from, @pair)
    selection.selectLeft() if (not range) and wasEmpty
    range

  select: ->
    @eachSelection (s) =>
      setSelectionBufferRangeSafely s, @getRange(s)

class Quote extends Pair
  @extend()
  searchForwardingRange: true
  # getRange: (selection) ->
  #   selection.selectRight() if wasEmpty = selection.isEmpty()
  #   rangeOrig = selection.getBufferRange()
  #   from = selection.getHeadBufferPosition()
  #
  #   range = @getForwardingRange(from, @pair)
  #   if range?.isEqual(rangeOrig)
  #     console.log "RETRY"
  #     # Since range is same area, retry to expand outer pair.
  #     from = range.end.translate([0, +1])
  #     range = @getForwardingRange(from, @pair)
  #   selection.selectLeft() if (not range) and wasEmpty
  #   range

class DoubleQuote extends Quote
  @extend()
  pair: '""'

class SingleQuote extends Quote
  @extend()
  pair: "''"

class BackTick extends Quote
  @extend()
  pair: '``'

class AnyPair extends Pair
  @extend()
  member: [
    'DoubleQuote', 'SingleQuote', 'BackTick',
    'CurlyBracket', 'AngleBracket', 'Tag', 'SquareBracket', 'Parenthesis'
  ]

  getRangeBy: (klass, selection) ->
    @new(klass, {@inclusive, @searchForwardingRange}).getRange(selection)

  getRanges: (selection) ->
    ranges = []
    for klass in @member when (range = @getRangeBy(klass, selection))
      ranges.push range
    ranges

  getNearestRange: (selection) ->
    ranges = @getRanges(selection)
    _.last(sortRanges(ranges)) if ranges.length

  select: ->
    @eachSelection (s) =>
      setSelectionBufferRangeSafely s, @getNearestRange(s)

class AnyQuote extends AnyPair
  @extend()
  member: ['DoubleQuote', 'SingleQuote', 'BackTick']
  getRangeBy: (klass, selection) ->
    @new(klass, {@inclusive}).getRange(selection)

  getNearestRange: (selection) ->
    ranges = @getRanges(selection)
    _.first(sortRanges(ranges)) if ranges.length

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
      setSelectionBufferRangeSafely selection, @getRange(startRow)
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
    @status()

module.exports = {
  Word, WholeWord,
  DoubleQuote, SingleQuote, BackTick, CurlyBracket , AngleBracket, Tag,
  SquareBracket, Parenthesis,
  AnyPair, AnyQuote
  Paragraph, Comment, Indentation,
  Fold, Function,
  CurrentLine, Entire,
}
