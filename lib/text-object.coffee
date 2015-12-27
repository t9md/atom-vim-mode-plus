# Refactoring status: 95%
{Range} = require 'atom'
_ = require 'underscore-plus'

Base = require './base'
swrap = require './selection-wrapper'
{
  rangeToBeginningOfFileFromPoint, rangeToEndOfFileFromPoint
  sortRanges, getLineTextToPoint, characterAtPoint
} = require './utils'

class TextObject extends Base
  @extend(false)

  constructor: ->
    @constructor::inner = @constructor.name.startsWith('Inner')
    super
    @initialize?()

  isInner: ->
    @inner

  isA: ->
    not @isInner()

  isLinewise: ->
    swrap.detectVisualModeSubmode(@editor) is 'linewise'

  eachSelection: (fn) ->
    fn(s) for s in @editor.getSelections()
    @emitDidSelect()

# -------------------------
# [FIXME] Need to be extendable.
class Word extends TextObject
  @extend(false)
  select: ->
    @eachSelection (selection) =>
      wordRegex = @wordRegExp ? selection.cursor.wordRegExp()
      @selectInner(selection, wordRegex)
      @selectA(selection) if @isA()

  selectInner: (selection, wordRegex=null) ->
    selection.selectWord()

  selectA: (selection) ->
    scanRange = selection.cursor.getCurrentLineBufferRange()
    headPoint = selection.getHeadBufferPosition()
    scanRange.start = headPoint
    @editor.scanInBufferRange /\s+/, scanRange, ({range, stop}) ->
      if headPoint.isEqual(range.start)
        selection.selectToBufferPosition range.end
        stop()

class AWord extends Word
  @extend()

class InnerWord extends Word
  @extend()

# -------------------------
class WholeWord extends Word
  @extend(false)
  wordRegExp: /\S+/
  selectInner: (s, wordRegex) ->
    swrap(s).setBufferRangeSafely s.cursor.getCurrentWordBufferRange({wordRegex})

class AWholeWord extends WholeWord
  @extend()

class InnerWholeWord extends WholeWord
  @extend()

# -------------------------
class Pair extends TextObject
  @extend(false)
  allowNextLine: false
  what: 'enclosed'
  pair: null

  # Return 'open' or 'close'
  getPairState: (pair, matchText, point) ->
    [openChar, closeChar] = pair.split('')
    if openChar is closeChar
      text = getLineTextToPoint(@editor, point)
      state = @pairStateInString(text, openChar)
    else
      state = switch pair.indexOf(matchText[matchText.length-1])
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
    switch which
      when 'open'
        scanFunc = 'backwardsScanInBufferRange'
        scanRange = rangeToBeginningOfFileFromPoint(from)
      when 'close'
        scanFunc = 'scanInBufferRange'
        scanRange = rangeToEndOfFileFromPoint(from)
    pairRegexp = pair.split('').map(_.escapeRegExp).join('|')
    pattern = ///#{pairRegexp}///g

    found = null # We will search to fill this var.
    @editor[scanFunc] pattern, scanRange, (arg) =>
      {matchText, range: {start, end}, stop} = arg
      return if @isEscapedCharAtPoint(start)
      return stop() if (not allowNextLine) and (from.row isnt start.row)

      end = end.translate([0, -1]) if which is 'close'

      nest = if @getPairState(pair, matchText, start) is which
        Math.max(nest - 1, 0)
      else
        nest + 1

      unless nest
        found = end
        stop()
    found

  findOpenPair: (pair, options) ->
    options.which = 'open'
    options.allowNextLine ?= @allowNextLine
    @findPair(pair, options)

  findClosePair: (pair, options) ->
    options.which = 'close'
    options.allowNextLine ?= @allowNextLine
    @findPair(pair, options)

  getPairRange: (from, pair, what) ->
    range = null
    switch what
      when 'enclosed'
        open = @findOpenPair pair, {from: from, nest: 1}
        close = @findClosePair pair, {from: open, nest: 1} if open?
      when 'next'
        close = @findClosePair pair, {from: from, nest: 0}
        open = @findOpenPair pair, {from: close, nest: 1} if close?
      when 'previous' # FIXME but currently unused
        open  = @findOpenPair pair, {from: from,  nest: 0}
        close = @findClosePair pair, {from: open, nest: 1} if open?
    if open? and close?
      range = new Range(open, close)
      range = range.translate([0, -1], [0, 1]) if @isA()
    range

  getRange: (selection, what=@what) ->
    rangeOrig = selection.getBufferRange()
    from = selection.getHeadBufferPosition()

    # Be inner, include char under cursor.
    if (not selection.isEmpty() and not selection.isReversed())
      from = from.translate([0, -1])

    # In case cursor is on one of pair char, we adjust `from` point to be inclusive.
    characterAtCursor = characterAtPoint(@editor, from)
    if characterAtCursor in @pair
      from = switch @getPairState(@pair, characterAtCursor, from)
        when 'open' then from.translate([0, +1])
        when 'close' then from.translate([0, -1])

    range  = @getPairRange(from, @pair, what)
    if range?.isEqual(rangeOrig)
      # Since range was same area, retry to expand outer pair.
      from = switch what
        when 'enclosed', 'previous' then range.start.translate([0, -1])
        when 'next' then range.end.translate([0, +1])
      range = @getPairRange(from, @pair, what)
    range

  select: ->
    @eachSelection (s) =>
      swrap(s).setBufferRangeSafely @getRange(s, @what)

# -------------------------
class AnyPair extends Pair
  @extend(false)
  what: 'enclosed'
  member: [
    'DoubleQuote', 'SingleQuote', 'BackTick',
    'CurlyBracket', 'AngleBracket', 'Tag', 'SquareBracket', 'Parenthesis'
  ]

  getRangeBy: (klass, selection) ->
    # overwite default @what
    @new(klass, {@inner}).getRange(selection, @what)

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
      swrap(s).setBufferRangeSafely @getNearestRange(s)

class AAnyPair extends AnyPair
  @extend()

class InnerAnyPair extends AnyPair
  @extend()

# -------------------------
class AnyQuote extends AnyPair
  @extend(false)
  what: 'next'
  member: ['DoubleQuote', 'SingleQuote', 'BackTick']
  getNearestRange: (selection) ->
    ranges = @getRanges(selection)
    # Pick range which end.colum is leftmost(mean, closed first)
    _.first(_.sortBy(ranges, (r) -> r.end.column)) if ranges.length

class AAnyQuote extends AnyQuote
  @extend()

class InnerAnyQuote extends AnyQuote
  @extend()

# -------------------------
class DoubleQuote extends Pair
  @extend(false)
  pair: '""'
  what: 'next'

class ADoubleQuote extends DoubleQuote
  @extend()

class InnerDoubleQuote extends DoubleQuote
  @extend()

# -------------------------
class SingleQuote extends Pair
  @extend(false)
  pair: "''"
  what: 'next'

class ASingleQuote extends SingleQuote
  @extend()

class InnerSingleQuote extends SingleQuote
  @extend()

# -------------------------
class BackTick extends Pair
  @extend(false)
  pair: '``'
  what: 'next'

class ABackTick extends BackTick
  @extend()

class InnerBackTick extends BackTick
  @extend()

# -------------------------
class CurlyBracket extends Pair
  @extend(false)
  pair: '{}'
  allowNextLine: true

class ACurlyBracket extends CurlyBracket
  @extend()

class InnerCurlyBracket extends CurlyBracket
  @extend()

# -------------------------
class SquareBracket extends Pair
  @extend(false)
  pair: '[]'
  allowNextLine: true

class ASquareBracket extends SquareBracket
  @extend()

class InnerSquareBracket extends SquareBracket
  @extend()

# -------------------------
class Parenthesis extends Pair
  @extend(false)
  pair: '()'
  allowNextLine: true

class AParenthesis extends Parenthesis
  @extend()

class InnerParenthesis extends Parenthesis
  @extend()

# -------------------------
class AngleBracket extends Pair
  @extend(false)
  pair: '<>'

class AAngleBracket extends AngleBracket
  @extend()

class InnerAngleBracket extends AngleBracket
  @extend()

# -------------------------
# [FIXME] See vim-mode#795
class Tag extends Pair
  @extend(false)
  pair: '><'

class ATag extends Tag
  @extend()

class InnerTag extends Tag
  @extend()

# Paragraph
# -------------------------
# In Vim world Paragraph is defined as consecutive (non-)blank-line.
class Paragraph extends TextObject
  @extend(false)

  getStartRow: (startRow, fn) ->
    for row in [startRow..0] when fn(row)
      return row + 1
    0

  getEndRow: (startRow, fn) ->
    lastRow = @editor.getLastBufferRow()
    for row in [startRow..lastRow] when fn(row)
      return row - 1
    lastRow

  getRange: (startRow) ->
    startRowIsBlank = @editor.isBufferRowBlank(startRow)
    fn = (row) =>
      @editor.isBufferRowBlank(row) isnt startRowIsBlank
    new Range([@getStartRow(startRow, fn), 0], [@getEndRow(startRow, fn) + 1, 0])

  selectParagraph: (selection) ->
    [startRow, endRow] = selection.getBufferRowRange()
    if swrap(selection).isSingleRow()
      swrap(selection).setBufferRangeSafely @getRange(startRow)
    else
      point = if selection.isReversed()
        @getRange(startRow - 1)?.start
      else
        @getRange(endRow + 1)?.end
      selection.selectToBufferPosition point if point?

  select: ->
    @eachSelection (selection) =>
      _.times @getCount(), =>
        @selectParagraph(selection)
        @selectParagraph(selection) if @instanceof('AParagraph')

class AParagraph extends Paragraph
  @extend()

class InnerParagraph extends Paragraph
  @extend()

# -------------------------
class Comment extends Paragraph
  @extend(false)

  getRange: (startRow) ->
    return unless @editor.isBufferRowCommented(startRow)
    fn = (row) =>
      return if (not @isInner() and @editor.isBufferRowBlank(row))
      @editor.isBufferRowCommented(row) in [false, undefined]
    new Range([@getStartRow(startRow, fn), 0], [@getEndRow(startRow, fn) + 1, 0])

class AComment extends Comment
  @extend()

class InnerComment extends Comment
  @extend()

# -------------------------
class Indentation extends Paragraph
  @extend(false)

  getRange: (startRow) ->
    return if @editor.isBufferRowBlank(startRow)
    text = @editor.lineTextForBufferRow(startRow)
    baseIndentLevel = @editor.indentLevelForLine(text)
    fn = (row) =>
      if @editor.isBufferRowBlank(row)
        @isInner()
      else
        text = @editor.lineTextForBufferRow(row)
        @editor.indentLevelForLine(text) < baseIndentLevel
    new Range([@getStartRow(startRow, fn), 0], [@getEndRow(startRow, fn) + 1, 0])

class AIndentation extends Indentation
  @extend()

class InnerIndentation extends Indentation
  @extend()

# -------------------------
# TODO: make it extendable when repeated
class Fold extends TextObject
  @extend(false)
  getFoldRowRangeForBufferRow: (bufferRow) ->
    for currentRow in [bufferRow..0] by -1
      [startRow, endRow] = @editor.languageMode.rowRangeForCodeFoldAtBufferRow(currentRow) ? []
      if startRow? and (startRow <= bufferRow <= endRow)
        startRow += 1 if @isInner()
        return [startRow, endRow]

  select: ->
    @eachSelection (selection) =>
      [startRow, endRow] = selection.getBufferRowRange()
      row = if selection.isReversed() then startRow else endRow
      if rowRange = @getFoldRowRangeForBufferRow(row)
        swrap(selection).selectRowRange(rowRange)

class AFold extends Fold
  @extend()

class InnerFold extends Fold
  @extend()

# -------------------------
# NOTE: Function range determination is depending on fold.
class Function extends Fold
  @extend(false)

  indentScopedLanguages: ['python', 'coffee']
  # FIXME: why go dont' fold closing '}' for function? this is dirty workaround.
  omittingClosingCharLanguages: ['go']

  initialize: ->
    @language = @editor.getGrammar().scopeName.replace(/^source\./, '')

  getScopesForRow: (row) ->
    tokenizedLine = @editor.displayBuffer.tokenizedBuffer.tokenizedLineForRow(row)
    for tag in tokenizedLine.tags when tag < 0 and (tag % 2 is -1)
      atom.grammars.scopeForId(tag)

  isFunctionScope: (scope) ->
    regex = if @language in ['go']
      /^entity.name.function/
    else
      /^meta.function/
    regex.test(scope)

  isIncludeFunctionScopeForRow: (row) ->
    for scope in @getScopesForRow(row) when @isFunctionScope(scope)
      return true
    null

  # Greatly depending on fold, and what range is folded is vary from languages.
  # So we need to adjust endRow based on scope.
  getFoldRowRangeForBufferRow: (bufferRow) ->
    for currentRow in [bufferRow..0] by -1
      [startRow, endRow] = @editor.languageMode.rowRangeForCodeFoldAtBufferRow(currentRow) ? []
      unless startRow? and (startRow <= bufferRow <= endRow) and @isIncludeFunctionScopeForRow(startRow)
        continue
      return @adjustRowRange(startRow, endRow)
    null

  adjustRowRange: (startRow, endRow) ->
    if @isInner()
      startRow += 1
      endRow -= 1 unless @language in @indentScopedLanguages
    endRow += 1 if (@language in @omittingClosingCharLanguages)
    [startRow, endRow]

class AFunction extends Function
  @extend()

class InnerFunction extends Function
  @extend()

# -------------------------
class CurrentLine extends TextObject
  @extend(false)
  select: ->
    @eachSelection (selection) =>
      {cursor} = selection
      cursor.moveToBeginningOfLine()
      cursor.moveToFirstCharacterOfLine() if @isInner()
      selection.selectToEndOfBufferLine()

class ACurrentLine extends CurrentLine
  @extend()

class InnerCurrentLine extends CurrentLine
  @extend()

# -------------------------
class Entire extends TextObject
  @extend(false)
  select: ->
    @eachSelection (selection) =>
      @editor.selectAll()

class AEntire extends Entire
  @extend()

class InnerEntire extends Entire
  @extend()

# -------------------------
class LatestChange extends TextObject
  @extend(false)
  getRange: ->
    @vimState.mark.getRange('[', ']')

  select: ->
    @eachSelection (selection) =>
      swrap(selection).setBufferRangeSafely @getRange()

class ALatestChange extends LatestChange
  @extend()

class InnerLatestChange extends LatestChange
  @extend()
