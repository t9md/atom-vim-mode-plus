# Refactoring status: 100%
Base = require './base'

class InsertMode extends Base
  @extend(false)
  constructor: ->
    super
    @initialize?()

class InsertRegister extends InsertMode
  @extend()
  hover: icon: '"', emoji: '"'
  requireInput: true

  initialize: ->
    @focusInput()

  execute: ->
    @editor.transact =>
      for selection in @editor.getSelections()
        text = @vimState.register.getText(@input, selection)
        selection.insertText text

class InsertLastInserted extends InsertMode
  @extend()
  execute: ->
    @editor.insertText @vimState.register.getText('.')

class CopyFromLineAbove extends InsertMode
  @extend()
  rowTranslation: -1

  getTextInScreenRange: (range) ->
    bufferRange = @editor.bufferRangeForScreenRange(range)
    @editor.getTextInBufferRange(bufferRange)

  execute: ->
    lastRow = @editor.getLastBufferRow()
    @editor.transact =>
      for cursor in @editor.getCursors()
        {row, column} = cursor.getScreenPosition()
        row += @rowTranslation
        continue unless (0 <= row <= lastRow)
        range = [[row, column], [row, column+1]]
        cursor.selection.insertText @getTextInScreenRange(range)

class CopyFromLineBelow extends CopyFromLineAbove
  @extend()
  rowTranslation: +1
