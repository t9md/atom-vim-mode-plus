{Range} = require 'atom'
_    = require 'underscore-plus'
Base = require './base'

AllWhitespace = /^\s$/
WholeWordRegex = /\S+/

class TextObject extends Base
  @extend()
  vimState: null
  complete: true
  recodable: false

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState

class CurrentSelection extends TextObject
  @extend()
  select: ->
    _.times(@getCount(1), -> true)

# Word
# -------------------------
class SelectInsideWord extends TextObject
  @extend()
  select: ->
    @editor.selectWordsContainingCursors()
    [true]

class SelectAWord extends TextObject
  @extend()
  select: ->
    for selection in @editor.getSelections()
      selection.selectWord()
      loop
        endPoint = selection.getBufferRange().end
        char = @editor.getTextInRange(Range.fromPointWithDelta(endPoint, 0, 1))
        break unless AllWhitespace.test(char)
        selection.selectRight()
      true

# WholeWord
# -------------------------
class SelectInsideWholeWord extends TextObject
  @extend()
  select: ->
    for selection in @editor.getSelections()
      range = selection.cursor.getCurrentWordBufferRange({wordRegex: WholeWordRegex})
      selection.setBufferRange(range)
      true

class SelectAWholeWord extends TextObject
  @extend()
  select: ->
    for selection in @editor.getSelections()
      range = selection.cursor.getCurrentWordBufferRange({wordRegex: WholeWordRegex})
      selection.setBufferRange(range)
      loop
        endPoint = selection.getBufferRange().end
        char = @editor.getTextInRange(Range.fromPointWithDelta(endPoint, 0, 1))
        break unless AllWhitespace.test(char)
        selection.selectRight()
      true

# SelectInsideQuotes and the next class defined (SelectInsideBrackets) are
# almost-but-not-quite-repeated code. They are different because of the depth
# checks in the bracket matcher.
class SelectInsideQuotes extends TextObject
  @extend()
  char: null
  includeQuotes: false

  findOpeningQuote: (pos) ->
    start = pos.copy()
    pos = pos.copy()
    while pos.row >= 0
      line = @editor.lineTextForBufferRow(pos.row)
      pos.column = line.length - 1 if pos.column is -1
      while pos.column >= 0
        if line[pos.column] is @char
          if pos.column is 0 or line[pos.column - 1] isnt '\\'
            if @isStartQuote(pos)
              return pos
            else
              return @lookForwardOnLine(start)
        -- pos.column
      pos.column = -1
      -- pos.row
    @lookForwardOnLine(start)

  isStartQuote: (end) ->
    line = @editor.lineTextForBufferRow(end.row)
    numQuotes = line.substring(0, end.column + 1).replace( "'#{@char}", '').split(@char).length - 1
    numQuotes % 2

  lookForwardOnLine: (pos) ->
    line = @editor.lineTextForBufferRow(pos.row)

    index = line.substring(pos.column).indexOf(@char)
    if index >= 0
      pos.column += index
      return pos
    null

  findClosingQuote: (start) ->
    end = start.copy()
    escaping = false

    while end.row < @editor.getLineCount()
      endLine = @editor.lineTextForBufferRow(end.row)
      while end.column < endLine.length
        if endLine[end.column] is '\\'
          ++ end.column
        else if endLine[end.column] is @char
          -- start.column if @includeQuotes
          ++ end.column if @includeQuotes
          return end
        ++ end.column
      end.column = 0
      ++ end.row
    return

  select: ->
    for selection in @editor.getSelections()
      start = @findOpeningQuote(selection.cursor.getBufferPosition())
      if start?
        ++ start.column # skip the opening quote
        end = @findClosingQuote(start)
        if end?
          selection.setBufferRange([start, end])
      not selection.isEmpty()

class SelectInsideDoubleQuotes extends SelectInsideQuotes
  @extend()
  char: '"'
class SelectAroundDoubleQuotes extends SelectInsideDoubleQuotes
  @extend()
  includeQuotes: true

class SelectInsideSingleQuotes extends SelectInsideQuotes
  @extend()
  char: '\''
class SelectAroundSingleQuotes extends SelectInsideSingleQuotes
  @extend()
  includeQuotes: true

class SelectInsideBackTicks extends SelectInsideQuotes
  @extend()
  char: '`'
class SelectAroundBackTicks extends SelectInsideBackTicks
  @extend()
  includeQuotes: true


# SelectInsideBrackets and the previous class defined (SelectInsideQuotes) are
# almost-but-not-quite-repeated code. They are different because of the depth
# checks in the bracket matcher.

class SelectInsideBrackets extends TextObject
  @extend()
  beginChar: null
  endChar: null
  includeBrackets: false
  # constructor: (@vimState, @beginChar, @endChar, @includeBrackets) ->
  #   super(@vimState)

  findOpeningBracket: (pos) ->
    pos = pos.copy()
    depth = 0
    while pos.row >= 0
      line = @editor.lineTextForBufferRow(pos.row)
      pos.column = line.length - 1 if pos.column is -1
      while pos.column >= 0
        switch line[pos.column]
          when @endChar then ++ depth
          when @beginChar
            return pos if -- depth < 0
        -- pos.column
      pos.column = -1
      -- pos.row

  findClosingBracket: (start) ->
    end = start.copy()
    depth = 0
    while end.row < @editor.getLineCount()
      endLine = @editor.lineTextForBufferRow(end.row)
      while end.column < endLine.length
        switch endLine[end.column]
          when @beginChar then ++ depth
          when @endChar
            if -- depth < 0
              -- start.column if @includeBrackets
              ++ end.column if @includeBrackets
              return end
        ++ end.column
      end.column = 0
      ++ end.row
    return

  select: ->
    for selection in @editor.getSelections()
      start = @findOpeningBracket(selection.cursor.getBufferPosition())
      if start?
        ++ start.column # skip the opening quote
        end = @findClosingBracket(start)
        if end?
          selection.setBufferRange([start, end])
      not selection.isEmpty()

class SelectInsideCurlyBrackets extends SelectInsideBrackets
  @extend()
  beginChar: '{'
  endChar: '}'
class SelectAroundCurlyBrackets extends SelectInsideCurlyBrackets
  @extend()
  includeBrackets: true

class SelectInsideAngleBrackets extends SelectInsideBrackets
  @extend()
  beginChar: '<'
  endChar: '>'
class SelectAroundAngleBrackets extends SelectInsideAngleBrackets
  @extend()
  includeBrackets: true

class SelectInsideTags extends SelectInsideBrackets
  @extend()
  beginChar: '>'
  endChar: '<'
class SelectAroundTags extends SelectInsideTags
  @extend()
  includeBrackets: true

class SelectInsideSquareBrackets extends SelectInsideBrackets
  @extend()
  beginChar: '['
  endChar: ']'
class SelectAroundSquareBrackets extends SelectInsideSquareBrackets
  @extend()
  includeBrackets: true

class SelectInsideParentheses extends SelectInsideBrackets
  @extend()
  beginChar: '('
  endChar: ')'
class SelectAroundParentheses extends SelectInsideParentheses
  @extend()
  includeBrackets: true

# Paragraph
# -------------------------
class SelectInsideParagraph extends TextObject
  @extend()
  select: ->
    for selection in @editor.getSelections()
      range = selection.cursor.getCurrentParagraphBufferRange()
      if range?
        selection.setBufferRange(range)
        selection.selectToBeginningOfNextParagraph()
      true

class SelectAroundParagraph extends TextObject
  @extend()
  select: ->
    for selection in @editor.getSelections()
      range = selection.cursor.getCurrentParagraphBufferRange()
      if range?
        selection.setBufferRange(range)
        selection.selectToBeginningOfNextParagraph()
        selection.selectDown()
      true

module.exports = {
  TextObject,
  CurrentSelection,

  SelectInsideDoubleQuotes
  SelectAroundDoubleQuotes

  SelectInsideSingleQuotes
  SelectAroundSingleQuotes

  SelectInsideBackTicks
  SelectAroundBackTicks

  SelectInsideCurlyBrackets
  SelectAroundCurlyBrackets

  SelectInsideAngleBrackets
  SelectAroundAngleBrackets

  SelectInsideTags
  SelectAroundTags

  SelectInsideSquareBrackets
  SelectAroundSquareBrackets

  SelectInsideParentheses
  SelectAroundParentheses

  SelectInsideWord, SelectAWord,
  SelectInsideWholeWord, SelectAWholeWord,
  SelectInsideQuotes, SelectInsideBrackets,
  SelectInsideParagraph, SelectAroundParagraph
}
