const {Emitter, CompositeDisposable} = require("atom")
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
    const markRange = range => this.markerLayer.markBufferRange(range, {invalidate: "inside"})
    const {editor} = this.vimState
    if (occurrenceType === "subword") {
      const subwordRegex = editor.getLastCursor().subwordRegExp()
      const cache = {}
      editor.scan(pattern, ({range}) => {
        const {row} = range.start
        if (!cache[row]) cache[row] = collectRangeInBufferRow(editor, row, subwordRegex)
        if (cache[row].some(subwordRange => subwordRange.isEqual(range))) markRange(range)
      })
    } else {
      const ranges = []
      editor.scan(pattern, ({range}) => ranges.push(range))
      if (this.canCreateMarkersForLength(ranges.length)) ranges.forEach(markRange)
    }
  }

  canCreateMarkersForLength(length) {
    const threshold = this.vimState.getConfig("confirmThresholdOnOccurrenceOperation")
    if (threshold >= length) {
      return true
    } else {
      const options = {
        message: `Too many(${length}) occurrences. Do you want to continue?`,
        detailedMessage: `If you want increase threshold(current: ${threshold}), change "Confirm Threshold On Create Preset Occurrences" configuration.`,
        buttons: ["Continue", "Cancel"],
      }
      return atom.confirm(options) === 0
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
  select(wise) {
    const closestRangeIndexByOriginalSelection = new Map()
    const rangesToSelect = []
    const markersSelected = []
    const {editor} = this.vimState

    for (const selection of editor.getSelections()) {
      const markers = this.getMarkersIntersectsWithSelection(selection, this.vimState.mode === "visual")
      if (!markers.length) continue

      const ranges = markers.map(marker => marker.getBufferRange())
      markersSelected.push(...markers)
      // [HACK] Find closest occurrence range and move it to last item in ranges array.
      // Purpose of this is to make closest range become **last-selection**.
      // It is important to show autocomplete+ popup at proper position( popup shows up at last-selection ).
      // E.g. `c o f`(change occurrence in a-function) show autocomplete+ popup at closest occurrence.
      const closestRange = this.getClosestRangeForSelection(ranges, selection)
      ranges.splice(ranges.indexOf(closestRange), 1) // remove
      ranges.push(closestRange) // then push to last

      rangesToSelect.push(...ranges)

      const closestRangeIndex = rangesToSelect.indexOf(closestRange)
      // Remember connection between originalSelection and index of closestRange.
      // After select occurrence, selection is re-created, then we have to migrate mutation info using this info.
      closestRangeIndexByOriginalSelection.set(selection, closestRangeIndex)
    }

    if (rangesToSelect.length) {
      const reversed = editor.getLastSelection().isReversed()

      // To avoid selected occurrence ruined by normalization when deactivating blockwise
      if (this.vimState.isMode("visual", "blockwise")) {
        this.vimState.activate("visual", "characterwise")
      }

      editor.setSelectedBufferRanges(rangesToSelect, {reversed})
      const selections = editor.getSelections()
      closestRangeIndexByOriginalSelection.forEach((closestRangeIndex, originalSelection) => {
        this.vimState.mutationManager.migrateMutation(originalSelection, selections[closestRangeIndex])
      })
      this.destroyMarkers(markersSelected)
      this.vimState.swrap.saveProperties(editor, {force: true})

      if (wise === "linewise") {
        // In linewise-occurence operation, what happens is here
        // 1. select linewise by applyWise(linewise)
        // 2. Observe selection.onDidDestroy to remember which selection is detroyed on mergeSelectionsOnSameRows in next step(step3).
        // 3. mergeSelectionsOnSameRows(), it merge selections in adjacent row, as a result, it destroy some selections.
        // 4. For destroyed selection, we migrate mutaion for destroyed selection with new selection info.

        for (const $selection of this.vimState.swrap.getSelections(editor)) {
          $selection.applyWise("linewise")
        }

        const {mutationsBySelection} = this.vimState.mutationManager
        const disposables = new CompositeDisposable()
        const rangeByMutation = new Map()
        const orphanedMutations = []

        for (const [selection, mutation] of mutationsBySelection) {
          // Need preserve range while it's alive.
          rangeByMutation.set(mutation, selection.getBufferRange())
          disposables.add(selection.onDidDestroy(() => orphanedMutations.push(mutation)))
        }
        editor.mergeSelectionsOnSameRows() // This destroy merged selection.
        disposables.dispose()
        this.vimState.swrap.saveProperties(editor, {force: true})

        const selections = editor.getSelections()
        for (const mutation of orphanedMutations) {
          mutationsBySelection.delete(mutation.selection)

          const range = rangeByMutation.get(mutation)
          // Selection contains original mutation range is merger selection we should migrate to.
          const selection = selections.find(selection => selection.getBufferRange().containsRange(range))
          mutation.selection = selection
          mutationsBySelection.set(selection, mutation)
        }
      }

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
