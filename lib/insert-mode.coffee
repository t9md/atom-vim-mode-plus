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
  @description: """
  Insert text inserted in latest insert-mode.
  Equivalent to *i_CTRL-A* of pure Vim
  """
  execute: ->
    text = @vimState.register.getText('.')
    @editor.insertText(text)

class CopyFromLineAbove extends InsertMode
  @extend()
  @description: """
  Insert character of same-column of above line.
  Equivalent to *i_CTRL-Y* of pure Vim
  """
  rowDelta: -1

  execute: ->
    translation = [@rowDelta, 0]
    @editor.transact =>
      for selection in @editor.getSelections()
        point = selection.cursor.getBufferPosition().translate(translation)
        range = Range.fromPointWithDelta(point, 0, 1)
        if text = @editor.getTextInBufferRange(range)
          selection.insertText(text)

class CopyFromLineBelow extends CopyFromLineAbove
  @extend()
  @description: """
  Insert character of same-column of above line.
  Equivalent to *i_CTRL-E* of pure Vim
  """
  rowDelta: +1
