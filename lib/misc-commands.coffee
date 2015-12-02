# The commands defined in this file is processed by operationStack.
# The commands which is not well fit to one of Motion, TextObject, Operator
#  goes here.
{Range} = require 'atom'
Base = require './base'
swrap = require './selection-wrapper'
settings = require './settings'

{isLinewiseRange} = require './utils'

class Misc extends Base
  @extend(false)
  complete: true

  constructor: ->
    super
    @initialize?()

class ReverseSelections extends Misc
  @extend()
  execute: ->
    lastSelection = @editor.getLastSelection()
    swrap(lastSelection).reverse()
    reversed = lastSelection.isReversed()
    for s in @editor.getSelections() when not s.isLastSelection()
      swrap(s).setReversedState(reversed)

class SelectLatestChange extends Misc
  @extend()
  complete: true

  execute: ->
    start = @vimState.mark.get('[')
    end = @vimState.mark.get(']')
    if start? and end?
      range = new Range(start, end)
      @editor.setSelectedBufferRange(range)
      submode = if isLinewiseRange(range) then 'linewise' else 'characterwise'
      @vimState.activate('visual', submode)

class Undo extends Misc
  @extend()

  flash: (range, klass) ->
    @vimState.flasher.flash range,
      class: "vim-mode-plus-flash #{klass}"
      timeout: settings.get('flashOnUndoRedoDuration')

  mutateWithTrackingChanges: (fn) ->
    range = null
    disposable = @editor.getBuffer().onDidChange ({oldRange, newRange}) =>
      range ?= newRange
      range = range.union(newRange) if range.intersectsWith(newRange)

      if settings.get('flashOnUndoRedo')
        if not newRange.isEmpty()
          @flash(newRange, 'added')
        else if not oldRange.isEmpty()
          range = Range.fromPointWithDelta(oldRange.start, 0, 1)
          @flash(range, 'removed')
    @mutate()
    disposable.dispose()
    fn(range) if range

  execute: ->
    @mutateWithTrackingChanges ({start, end}) =>
      @vimState.mark.set('[', start)
      @vimState.mark.set(']', end)
      if settings.get('setCursorToStartOfChangeOnUndoRedo')
        @editor.setCursorBufferPosition(start)

    for s in @editor.getSelections()
      s.clear()
    @vimState.activate('normal')

  mutate: ->
    @editor.undo()

class Redo extends Undo
  @extend()
  mutate: ->
    @editor.redo()
