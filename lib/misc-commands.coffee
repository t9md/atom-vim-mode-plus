# The commands defined in this file is processed by operationStack.
# The commands which is not well fit to one of Motion, TextObject, Operator
#  goes here.
{Range} = require 'atom'
Base = require './base'
swrap = require './selection-wrapper'
settings = require './settings'
_ = require 'underscore-plus'

{isLinewiseRange, pointIsAtEndOfLine, mergeIntersectingRanges} = require './utils'

class Misc extends Base
  @extend(false)
  constructor: ->
    super
    @initialize?()

  activate: (mode, submode) ->
    @onDidOperationFinish =>
      @vimState.activate(mode, submode)

class ReverseSelections extends Misc
  @extend()
  execute: ->
    # FIXME? need to care
    # not all selection reversed state is in-sync?
    # In that case make it sync in operationStack::process.
    swrap.reverse(@editor.getSelections())

class Undo extends Misc
  @extend()

  flash: (ranges, klass, timeout) ->
    options =
      type: 'highlight'
      class: "vim-mode-plus-flash #{klass}"

    markers = ranges.map (r) => @editor.markBufferRange(r)
    @editor.decorateMarker(m, options) for m in markers
    setTimeout  ->
      m.destroy() for m in markers
    , timeout

  saveRangeAsMarker: (markers, range) ->
    if _.all(markers, (m) -> not m.getBufferRange().intersectsWith(range))
      markers.push @editor.markBufferRange(range)

  trimEndOfLineRange: (range) ->
    {start} = range
    if (start.column isnt 0) and pointIsAtEndOfLine(@editor, start)
      range.traverse([+1, 0], [0, 0])
    else
      range

  mapToChangedRanges: (list, fn) ->
    ranges = list.map (e) -> fn(e)
    mergeIntersectingRanges(ranges).map (r) =>
      @trimEndOfLineRange(r)

  mutateWithTrackingChanges: (fn) ->
    markersAdded = []
    rangesRemoved = []

    disposable = @editor.getBuffer().onDidChange ({oldRange, newRange}) =>
      # To highlight(decorate) removed range, I don't want marker's auto-tracking-range-change feature.
      # So here I simply use range for removal
      rangesRemoved.push(oldRange) unless oldRange.isEmpty()
      # For added range I want marker's auto-tracking-range-change feature.
      @saveRangeAsMarker(markersAdded, newRange) unless newRange.isEmpty()
    @mutate()
    disposable.dispose()

    # FIXME: this is still not completely accurate and heavy approach.
    # To accurately track range updated, need to add/remove manually.
    rangesAdded = @mapToChangedRanges markersAdded, (m) -> m.getBufferRange()
    markersAdded.forEach (m) -> m.destroy()
    rangesRemoved = @mapToChangedRanges rangesRemoved, (r) -> r

    firstAdded = rangesAdded[0]
    lastRemoved = _.last(rangesRemoved)
    range =
      if firstAdded? and lastRemoved?
        if firstAdded.start.isLessThan(lastRemoved.start)
          firstAdded
        else
          lastRemoved
      else
        firstAdded or lastRemoved

    fn(range) if range?
    if settings.get('flashOnUndoRedo')
      @onDidOperationFinish =>
        timeout = settings.get('flashOnUndoRedoDuration')
        @flash(rangesRemoved, 'removed', timeout)
        @flash(rangesAdded, 'added', timeout)

  execute: ->
    @mutateWithTrackingChanges ({start, end}) =>
      @vimState.mark.set('[', start)
      @vimState.mark.set(']', end)
      if settings.get('setCursorToStartOfChangeOnUndoRedo')
        @editor.setCursorBufferPosition(start)

    for s in @editor.getSelections()
      s.clear()
    @activate('normal')

  mutate: ->
    @editor.undo()

class Redo extends Undo
  @extend()
  mutate: ->
    @editor.redo()

class ToggleFold extends Misc
  @extend()
  execute: ->
    row = @editor.getCursorBufferPosition().row
    @editor.toggleFoldAtBufferRow row
