const {Point} = require("atom")

module.exports = class MutationManager {
  constructor(vimState) {
    this.vimState = vimState
    this.editor = vimState.editor
    this.swrap = this.vimState.swrap
    this.vimState.onDidDestroy(() => this.destroy())

    this.markerLayer = this.editor.addMarkerLayer()
    this.mutationsBySelection = new Map()
  }

  destroy() {
    this.markerLayer.destroy()
    this.mutationsBySelection.clear()
  }

  init({stayByMarker}) {
    this.stayByMarker = stayByMarker
    this.reset()
  }

  reset() {
    this.markerLayer.clear()
    this.mutationsBySelection.clear()
  }

  setCheckpoint(checkpoint) {
    for (let selection of this.editor.getSelections()) {
      this.setCheckpointForSelection(selection, checkpoint)
    }
  }

  setCheckpointForSelection(selection, checkpoint) {
    let resetMarker = false

    if (this.mutationsBySelection.has(selection)) {
      // Current non-empty selection is prioritized over existing marker's range.
      // We invalidate old marker to re-track from current selection.
      resetMarker = !selection.getBufferRange().isEmpty()
    } else {
      resetMarker = true

      let initialPointMarker
      const initialPoint = this.swrap(selection).getBufferPositionFor("head", {from: ["property", "selection"]})
      if (this.stayByMarker) {
        initialPointMarker = this.markerLayer.markBufferPosition(initialPoint, {invalidate: "never"})
      }
      const options = {selection, initialPoint, initialPointMarker, checkpoint, swrap: this.swrap}
      this.mutationsBySelection.set(selection, new Mutation(options))
    }

    const marker = resetMarker
      ? this.markerLayer.markBufferRange(selection.getBufferRange(), {invalidate: "never"})
      : undefined
    this.mutationsBySelection.get(selection).update(checkpoint, marker, this.vimState.mode)
  }

  migrateMutation(oldSelection, newSelection) {
    const mutation = this.mutationsBySelection.get(oldSelection)
    this.mutationsBySelection.delete(oldSelection)
    mutation.selection = newSelection
    this.mutationsBySelection.set(newSelection, mutation)
  }

  getMutatedBufferRangeForSelection(selection) {
    if (this.mutationsBySelection.has(selection)) {
      return this.mutationsBySelection.get(selection).marker.getBufferRange()
    }
  }

  getSelectedBufferRangesForCheckpoint(checkpoint) {
    return Array.from(this.mutationsBySelection.values())
      .map(mutation => mutation.bufferRangeByCheckpoint[checkpoint])
      .filter(range => range)
  }

  restoreCursorPositions({stay, wise, setToFirstCharacterOnLinewise}) {
    if (wise === "blockwise") {
      for (const blockwiseSelection of this.vimState.getBlockwiseSelections()) {
        const {head, tail} = blockwiseSelection.getProperties()
        blockwiseSelection.setHeadBufferPosition(stay ? head : Point.min(head, tail))
        blockwiseSelection.skipNormalization()
      }
    } else {
      // Make sure destroying all temporal selection BEFORE starting to set cursors to final position.
      // This is important to avoid destroy order dependent bugs.
      for (const selection of this.editor.getSelections()) {
        const mutation = this.mutationsBySelection.get(selection)
        if (mutation && mutation.createdAt !== "will-select") {
          selection.destroy()
        }
      }

      for (const selection of this.editor.getSelections()) {
        const mutation = this.mutationsBySelection.get(selection)
        if (!mutation) continue

        let point
        if (stay) {
          point = this.clipPoint(mutation.getStayPosition(wise))
        } else {
          point = this.clipPoint(mutation.startPositionOnDidSelect)
          if (setToFirstCharacterOnLinewise && wise === "linewise") {
            point = this.vimState.utils.getFirstCharacterPositionForBufferRow(this.editor, point.row)
          }
        }
        selection.cursor.setBufferPosition(point)
      }
    }
  }

  clipPoint(point) {
    point.row = Math.min(this.vimState.utils.getVimLastBufferRow(this.editor), point.row)
    return this.editor.clipBufferPosition(point)
  }
}

// Mutation information is created even if selection.isEmpty()
// So that we can filter selection by when it was created.
//  e.g. Some selection is created at 'will-select' checkpoint, others at 'did-select' or 'did-select-occurrence'
class Mutation {
  constructor(options) {
    this.selection = options.selection
    this.initialPoint = options.initialPoint
    this.initialPointMarker = options.initialPointMarker
    this.swrap = options.swrap
    this.createdAt = options.checkpoint

    this.bufferRangeByCheckpoint = {}
    this.marker = null
    this.startPositionOnDidSelect = null
  }

  update(checkpoint, marker, mode) {
    if (marker) {
      if (this.marker) this.marker.destroy()
      this.marker = marker
    }
    this.bufferRangeByCheckpoint[checkpoint] = this.marker.getBufferRange()
    // NOTE: stupidly respect pure-Vim's behavior which is inconsistent.
    // Maybe I'll remove this blindly-following-to-pure-Vim code.
    //  - `V k y`: don't move cursor
    //  - `V j y`: move curor to start of selected line.(Inconsistent!)
    if (checkpoint === "did-select") {
      const from = mode === "visual" && !this.selection.isReversed() ? ["selection"] : ["property", "selection"]
      this.startPositionOnDidSelect = this.swrap(this.selection).getBufferPositionFor("start", {from})
    }
  }

  getStayPosition(wise) {
    const point = (this.initialPointMarker && this.initialPointMarker.getHeadBufferPosition()) || this.initialPoint
    const selectedRange =
      this.bufferRangeByCheckpoint["did-select-occurrence"] || this.bufferRangeByCheckpoint["did-select"]
    // Check if need Clip
    if (selectedRange.isEqual(this.marker.getBufferRange())) {
      return point
    } else {
      let {start, end} = this.marker.getBufferRange()
      end = Point.max(start, end.translate([0, -1]))
      if (wise === "linewise") {
        point.row = Math.min(end.row, point.row)
        return point
      } else {
        return Point.min(end, point)
      }
    }
  }
}
