{Range} = require 'atom'
Base = require './base'
swrap = require './selection-wrapper'
settings = require './settings'
_ = require 'underscore-plus'

{
  isLinewiseRange
  pointIsAtEndOfLine
  mergeIntersectingRanges
  highlightRanges
} = require './utils'

class MiscCommand extends Base
  @extend(false)
  constructor: ->
    super
    @initialize?()

class ReverseSelections extends MiscCommand
  @extend()
  execute: ->
    # FIXME? need to care
    # not all selection reversed state is in-sync?
    # In that case make it sync in operationStack::process.
    swrap.reverse(@editor)

class BlockwiseOtherEnd extends ReverseSelections
  @extend()
  execute: ->
    for bs in @vimState.getBlockwiseSelections() when not bs.isSingleLine()
      bs.reverse()
    super

class Undo extends MiscCommand
  @extend()

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
      @onDidFinishOperation =>
        timeout = settings.get('flashOnUndoRedoDuration')
        highlightRanges @editor, rangesRemoved,
          class: "vim-mode-plus-flash removed"
          timeout: timeout

        highlightRanges @editor, rangesAdded,
          class: "vim-mode-plus-flash added"
          timeout: timeout

  execute: ->
    @mutateWithTrackingChanges ({start, end}) =>
      @vimState.mark.set('[', start)
      @vimState.mark.set(']', end)
      if settings.get('setCursorToStartOfChangeOnUndoRedo')
        @editor.setCursorBufferPosition(start)

    for selection in @editor.getSelections()
      selection.clear()
    @activateMode('normal')

  mutate: ->
    @editor.undo()

class Redo extends Undo
  @extend()
  mutate: ->
    @editor.redo()

class ToggleFold extends MiscCommand
  @extend()
  execute: ->
    point = @editor.getCursorBufferPosition()
    @editor.toggleFoldAtBufferRow(point.row)

class ReplaceModeBackspace extends MiscCommand
  @commandScope: 'atom-text-editor.vim-mode-plus.insert-mode.replace'
  @extend()
  execute: ->
    @editor.getSelections().forEach (selection) =>
      # char might be empty.
      char = @vimState.modeManager.getReplacedCharForSelection(selection)
      if char?
        selection.selectLeft()
        unless selection.insertText(char).isEmpty()
          selection.cursor.moveLeft()

class MaximizePane extends MiscCommand
  @extend()
  execute: ->
    selector = 'vim-mode-plus-pane-maximized'
    workspaceElement = atom.views.getView(atom.workspace)
    workspaceElement.classList.toggle(selector)
