# The commands defined in this file is processed by operationStack.
# The commands which is not well fit to one of Motion, TextObject, Operator
#  goes here.
Base = require './base'
swrap = require './selection-wrapper'

class Misc extends Base
  @extend()
  complete: true

class ReverseSelections extends Misc
  @extend()
  execute: ->
    lastSelection = @editor.getLastSelection()
    swrap(lastSelection).reverse()
    reversed = lastSelection.isReversed()
    for s in @editor.getSelections() when not s.isLastSelection()
      swrap(s).setReversedState(reversed)

class Undo extends Misc
  @extend()
  execute: ->
    @editor.undo()
    @finish()

  finish: ->
    s.clear() for s in @editor.getSelections()
    @vimState.activate('normal')

class Redo extends Undo
  @extend()
  execute: ->
    @editor.redo()
    @finish()

module.exports = {
  ReverseSelections
  Undo, Redo
}
