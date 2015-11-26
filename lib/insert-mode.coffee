# Refactoring status: 100%
Base = require './base'

class InsertMode extends Base
  @extend(false)

class InsertRegister extends InsertMode
  @extend()
  hover: icon: '"', emoji: '"'
  requireInput: true
  initialize: ->
    @focusInput()

  execute: ->
    if text = @vimState.register.get(@input).text
      @editor.insertText(text)

class InsertLastInserted extends InsertMode
  @extend()
  complete: true
  execute: ->
    if text = @vimState.register.get('.').text
      @editor.insertText(text)

class CopyFromLineAbove extends InsertMode
  @extend()
  complete: true
  rowTranslation: -1

  getTextInScreenRange: (range) ->
    bufferRange = @editor.bufferRangeForScreenRange(range)
    @editor.getTextInBufferRange(bufferRange)

  execute: ->
    @editor.transact =>
      for cursor in @editor.getCursors()
        {row, column} = cursor.getScreenPosition()
        row += @rowTranslation
        continue if row < 0 # No line to copy from.
        range = [[row, column], [row, column+1]]
        cursor.selection.insertText @getTextInScreenRange(range)

class CopyFromLineBelow extends CopyFromLineAbove
  @extend()
  rowTranslation: +1
