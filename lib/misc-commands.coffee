# The commands defined in this file is processed by operationStack.
# The commands which is not well fit to one of Motion, TextObject, Operator
#  goes here.
{Range} = require 'atom'
Base = require './base'
swrap = require './selection-wrapper'
settings = require './settings'

{isLinewiseRange, mergeIntersectingRanges} = require './utils'

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
  flash: (range, options) ->
    @vimState.flasher.flash range,
      class: options.class
      timeout: settings.get('flashOnUndoRedoDuration')

  withTrackChange: (fn) ->
    ranges = []
    disposable = @editor.getBuffer().onDidChange ({newRange}) ->
      ranges.push(newRange)
    fn()
    disposable.dispose()
    mergeIntersectingRanges(ranges)

  execute: ->
    ranges = @withTrackChange =>
      @mutate()
    if settings.get('flashOnUndoRedo')
      for range in ranges
        if range.isEmpty()
          range = range.translate([0, 0], [0, 1])
          unless @editor.getTextInBufferRange(range).match /\S+/
            range = @editor.bufferRangeForBufferRow(range.start.row, includeNewline: true)
          klass = 'vim-mode-plus-flash deleted'
        else
          klass = 'vim-mode-plus-flash'
        @flash(range, class: klass)

    if range = ranges[0]
      @vimState.mark.set('[', range.start)
      @vimState.mark.set(']', range.end)
      if settings.get('setCursorToStartOfChangeOnUndoRedo')
        @editor.setCursorBufferPosition(range.start)

    for s in @editor.getSelections()
      s.clear()
    @vimState.activate('normal')

  mutate: ->
    @editor.undo()

class Redo extends Undo
  @extend()
  mutate: ->
    @editor.redo()
