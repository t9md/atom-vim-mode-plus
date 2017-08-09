const {Emitter} = require("atom")
const {shrinkRangeEndToBeforeNewLine, collectRangeInBufferRow} = require("./utils")

module.exports = class OccurrenceManager {
  constructor(vimState) {
    this.vimState = vimState
    const {editor} = vimState

    vimState.onDidDestroy(() => this.destroy())

    this.emitter = new Emitter()
    this.patterns = []

    this.markerLayer = editor.addMarkerLayer()
    this.decorationLayer = editor.decorateMarkerLayer(this.markerLayer, {
      type: "highlight",
      class: "vim-mode-plus-occurrence-base",
    })

    // All maker create/destroy/css-update is done by reacting patters's change.
    // -------------------------
    this.onDidChangePatterns(({pattern, occurrenceType}) => {
      if (pattern) {
        this.markBufferRangeByPattern(pattern, occurrenceType)
      } else {
        this.clearMarkers()
      }
      this.updateEditorElement()
    })

    this.markerLayer.onDidUpdate(() => {
      this.destroyMarkers(this.getMarkers().filter(marker => !marker.isValid()))
    })
  }

  markBufferRangeByPattern(pattern, occurrenceType) {
    const markRange = ({range}) => this.markerLayer.markBufferRange(range, {invalidate: "inside"})
    const {editor} = this.vimState
    if (occurrenceType === "subword") {
      const subwordRegex = editor.getLastCursor().subwordRegExp()
      const cache = {}
      editor.scan(pattern, ({range}) => {
        const {row} = range.start
        if (!cache[row]) cache[row] = collectRangeInBufferRow(editor, row, subwordRegex)
        if (cache[row].some(subwordRange => subwordRange.isEqual(range))) markRange({range})
      })
    } else {
      editor.scan(pattern, markRange)
    }
  }

  updateEditorElement() {
    this.vimState.editorElement.classList.toggle("has-occurrence", this.hasMarkers())
  }

  // Callback get passed following object
  // - pattern: can be undefined on reset event
  onDidChangePatterns(fn) {
    return this.emitter.on("did-change-patterns", fn)
  }

  destroy() {
    this.decorationLayer.destroy()
    this.markerLayer.destroy()
  }

  // Patterns
  hasPatterns() {
    return this.patterns.length > 0
  }

  resetPatterns() {
    this.patterns = []
    this.emitter.emit("did-change-patterns", {})
  }

  addPattern(pattern = null, {reset, occurrenceType = "base"} = {}) {
    if (reset) this.clearMarkers()

    this.patterns.push(pattern)
    this.emitter.emit("did-change-patterns", {pattern, occurrenceType})
  }

  saveLastPattern(occurrenceType) {
    this.vimState.globalState.set("lastOccurrencePattern", this.buildPattern())
    this.vimState.globalState.set("lastOccurrenceType", occurrenceType)
  }

  // Return regex representing final pattern.
  // Used to cache final pattern to each instance of operator so that we can
  // repeat recorded operation by `.`.
  // Pattern can be added interactively one by one, but we save it as union pattern.
  buildPattern() {
    return new RegExp(this.patterns.map(regex => regex.source).join("|"), "g")
  }

  // Markers
  // -------------------------
  clearMarkers() {
    this.markerLayer.clear()
  }

  destroyMarkers(markers) {
    markers.forEach(marker => marker.destroy())
    // whenerver we destroy marker, we should sync `has-occurrence` scope in marker state..
    this.updateEditorElement()
  }

  hasMarkers() {
    return this.markerLayer.getMarkerCount() > 0
  }

  getMarkers() {
    return this.markerLayer.getMarkers()
  }

  getMarkerBufferRanges() {
    return this.markerLayer.getMarkers().map(marker => marker.getBufferRange())
  }

  getMarkerCount() {
    return this.markerLayer.getMarkerCount()
  }

  // Return occurrence markers intersecting given ranges
  getMarkersIntersectsWithSelection(selection, exclusive = false) {
    // findmarkers()'s intersectsBufferRange param have no exclusive control
    // So need extra check to filter out unwanted marker.
    // But basically I should prefer findMarker since It's fast than iterating
    // whole markers manually.
    const range = shrinkRangeEndToBeforeNewLine(selection.getBufferRange())
    return this.markerLayer
      .findMarkers({intersectsBufferRange: range})
      .filter(marker => range.intersectsWith(marker.getBufferRange(), exclusive))
  }

  getMarkerAtPoint(point) {
    // We have to check all returned marker until found, since we do aditional marker validation.
    // e.g. For text `abc()`, mark for `abc` and `(`. cursor on `(` char return multiple marker
    // and we pick `(` by isGreaterThan check.
    return this.markerLayer
      .findMarkers({containsBufferPosition: point})
      .find(marker => marker.getBufferRange().end.isGreaterThan(point))
  }

  // Select occurrence marker bufferRange intersecting current selections.
  // - Return: true/false to indicate success or fail
  //
  // Do special handling for which occurrence range become lastSelection
  // e.g.
  //  - c(change): So that autocomplete+popup shows at original cursor position or near.
  //  - g U(upper-case): So that undo/redo can respect last cursor position.
  select() {
    const isVisualMode = this.vimState.mode === "visual"
    const indexByOldSelection = new Map()
    const allRanges = []
    const markersSelected = []
    const {editor} = this.vimState

    for (const selection of editor.getSelections()) {
      const markers = this.getMarkersIntersectsWithSelection(selection, isVisualMode)
      if (!markers.length) continue

      const ranges = markers.map(marker => marker.getBufferRange())
      markersSelected.push(...markers)
      // [HACK] Place closest range to last so that final last-selection become closest one.
      // E.g.
      // `c o f`(change occurrence in a-function) show autocomplete+ popup at closest occurrence.( popup shows at last-selection )
      const closestRange = this.getClosestRangeForSelection(ranges, selection)
      ranges.splice(ranges.indexOf(closestRange), 1)
      ranges.push(closestRange)
      allRanges.push(...ranges)
      indexByOldSelection.set(selection, allRanges.indexOf(closestRange))
    }

    if (allRanges.length) {
      if (isVisualMode) {
        // To avoid selected occurrence ruined by normalization when disposing current submode to shift to new submode.
        this.vimState.modeManager.deactivate()
        this.vimState.submode = null
      }

      editor.setSelectedBufferRanges(allRanges)
      const selections = editor.getSelections()
      indexByOldSelection.forEach((index, oldSelection) =>
        this.vimState.mutationManager.migrateMutation(oldSelection, selections[index])
      )

      this.destroyMarkers(markersSelected)
      this.vimState.swrap.getSelections(editor).forEach($selection => $selection.saveProperties())
      return true
    } else {
      return false
    }
  }

  // Which occurrence become lastSelection is determined by following order
  //  1. Occurrence under original cursor position
  //  2. forwarding in same row
  //  3. first occurrence in same row
  //  4. forwarding (wrap-end)
  getClosestRangeForSelection(ranges, selection) {
    const point = this.vimState.mutationManager.mutationsBySelection.get(selection).initialPoint

    const range = ranges.find(range => range.containsPoint(point))
    if (range) return range

    const rangesInSameRow = ranges.filter(range => range.start.row === point.row)
    if (rangesInSameRow.length) ranges = rangesInSameRow
    return ranges.find(range => range.start.isGreaterThan(point)) || ranges[0]
  }
}
