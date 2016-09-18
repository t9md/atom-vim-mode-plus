swrap = require './selection-wrapper'

module.exports =
class CursorPositionManager
  editor: null
  pointsBySelection: null
  constructor: (@editor) ->
    @pointsBySelection = new Map

  save: (which, options={}) ->
    for selection in @editor.getSelections()
      point = swrap(selection).getBufferPositionFor(which, options)
      @pointsBySelection.set(selection, point)

  updateBy: (fn) ->
    @pointsBySelection.forEach (point, selection) =>
      @pointsBySelection.set(selection, fn(selection, point))

  restore: ({strict}={}) ->
    strict ?= true
    selections = @editor.getSelections()

    # unless occurence-mode we go strict mode.
    # in vB mode, vB range is reselected on @target.selection
    # so selection.id is change in that case we won't restore.
    selectionNotFound = (selection) => not @pointsBySelection.has(selection)
    return if strict and selections.some(selectionNotFound)

    for selection in selections
      if point = @pointsBySelection.get(selection)
        selection.cursor.setBufferPosition(point)
      else
        # only when none-strict mode can reach here
        selection.destroy()

    @destroy()

  destroy: ->
    @pointsBySelection.clear()
    [@pointsBySelection, @editor] = []
