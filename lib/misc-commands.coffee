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
  flash: (range) ->
    @vimState.flasher.flash range,
      class: 'vim-mode-plus-flash'
      timeout: settings.get('flashOnUndoRedoDuration')

  withFlash: (fn) ->
    needFlash = settings.get('flashOnUndoRedo')
    setToStart = settings.get('setCursorToStartOfChangeOnUndoRedo')
    unless (needFlash or setToStart)
      fn()
      return

    [start, end] = []
    disposable = @editor.getBuffer().onDidChange ({newRange}) ->
      start ?= newRange.start
      end = newRange.end
    fn()
    disposable.dispose()
    if start and end
      range = new Range(start, end)
      @editor.setCursorBufferPosition(range.start) if setToStart
      @flash(range) if needFlash

  execute: ->
    @withFlash =>
      @editor.undo()
    @finish()

  finish: ->
    s.clear() for s in @editor.getSelections()
    @vimState.activate('normal')

class Redo extends Undo
  @extend()
  execute: ->
    @withFlash =>
      @editor.redo()
    @finish()
