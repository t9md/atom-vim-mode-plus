{Range} = require 'atom'

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
        text = @vimState.register.getText(@getInput(), selection)
        selection.insertText(text)

class InsertLastInserted extends InsertMode
  @extend()
  execute: ->
    text = @vimState.register.getText('.')
    @editor.insertText(text)

class CopyFromLineAbove extends InsertMode
  @extend()
  rowDelta: -1

  getTargetRange: (cursor, translation) ->
    point = cursor.getBufferPosition().translate(translation)
    Range.fromPointWithDelta(point, 0, 1)

  execute: ->
    translation = [@rowDelta, 0]
    @editor.transact =>
      for selection in @editor.getSelections()
        range = @getTargetRange(selection.cursor, translation)
        if text = @editor.getTextInBufferRange(range)
          selection.insertText(text)

class CopyFromLineBelow extends CopyFromLineAbove
  @extend()
  rowDelta: +1
