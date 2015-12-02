# The commands defined in this file is processed by operationStack.
# The commands which is not well fit to one of Motion, TextObject, Operator
#  goes here.
{Range} = require 'atom'
Base = require './base'
swrap = require './selection-wrapper'
settings = require './settings'
_ = require 'underscore-plus'

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
  flash: (markers, klass, timeout) ->
    options =
      type: 'highlight'
      class: "vim-mode-plus-flash #{klass}"

    for m in markers
      @editor.decorateMarker(m, options)
    setTimeout  ->
      m.destroy() for m in markers
    , timeout

  saveRangeAsMarker: (markers, range) ->
    if _.all(markers, (m) -> not m.getBufferRange().intersectsWith(range))
      markers.push @editor.markBufferRange(range)

  mutateWithTrackingChanges: (fn) ->
    range = null
    markersAdded = []
    markersRemoved = []
    timeout = settings.get('flashOnUndoRedoDuration')
    disposable = @editor.getBuffer().onDidChange ({oldRange, newRange}) =>
      range ?= newRange
      range = range.union(newRange) if range.intersectsWith(newRange)

      if settings.get('flashOnUndoRedo')
        @saveRangeAsMarker(markersAdded, newRange) unless newRange.isEmpty()
        @saveRangeAsMarker(markersRemoved, oldRange) unless oldRange.isEmpty()
    @mutate()
    if settings.get('flashOnUndoRedo')
      @flash(markersRemoved, 'removed', timeout)
      @flash(markersAdded, 'added', timeout)
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
