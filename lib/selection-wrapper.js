const {Range, Point, Disposable} = require("atom")
const {
  translatePointAndClip,
  getRangeByTranslatePointAndClip,
  getEndOfLineForBufferRow,
  getBufferRangeForRowRange,
  limitNumber,
  isLinewiseRange,
  assertWithException,
  getFoldEndRowForRow,
  getRange,
} = require("./utils")
const settings = require("./settings")
const BlockwiseSelection = require("./blockwise-selection")

const propertyStore = new Map()

class SelectionWrapper {
  constructor(selection) {
    this.selection = selection
  }
  hasProperties() {
    return propertyStore.has(this.selection)
  }
  getProperties() {
    return propertyStore.get(this.selection)
  }
  setProperties(prop) {
    return propertyStore.set(this.selection, prop)
  }
  clearProperties() {
    return propertyStore.delete(this.selection)
  }

  setBufferRangeSafely(range, options) {
    if (range) {
      this.setBufferRange(range, options)
    }
  }

  getBufferRange() {
    return this.selection.getBufferRange()
  }

  getBufferPositionFor(which, {from = ["selection"]} = {}) {
    for (let _from of from) {
      if (_from === "property") {
        if (!this.hasProperties()) continue
        const properties = this.getProperties()

        if (which === "start") return this.selection.isReversed() ? properties.head : properties.tail
        else if (which === "end") return this.selection.isReversed() ? properties.tail : properties.head
        else if (which === "head") return properties.head
        else if (which === "tail") return properties.tail
      } else if (_from === "selection") {
        if (which === "start") return this.selection.getBufferRange().start
        else if (which === "end") return this.selection.getBufferRange().end
        else if (which === "head") return this.selection.getHeadBufferPosition()
        else if (which === "tail") return this.selection.getTailBufferPosition()
      }
    }
  }

  setBufferPositionTo(which) {
    const point = this.getBufferPositionFor(which)
    if (point) this.selection.cursor.setBufferPosition(point)
  }

  setReversedState(isReversed) {
    if (this.selection.isReversed() === isReversed) return

    assertWithException(this.hasProperties(), "trying to reverse selection which is non-empty and property-less")

    const {head, tail} = this.getProperties()
    this.setProperties({head: tail, tail: head})

    this.setBufferRange(this.getBufferRange(), {
      autoscroll: true,
      reversed: isReversed,
      keepGoalColumn: false,
    })
  }

  getRows() {
    const [startRow, endRow] = this.selection.getBufferRowRange()
    return getRange(startRow, endRow)
  }

  getRowCount() {
    return this.getRows().length
  }

  getTailBufferRange() {
    const {editor} = this.selection
    const tailPoint = this.selection.getTailBufferPosition()
    return this.selection.isReversed()
      ? new Range(translatePointAndClip(editor, tailPoint, "backward"), tailPoint)
      : new Range(tailPoint, translatePointAndClip(editor, tailPoint, "forward"))
  }

  saveProperties(isNormalized) {
    const head = this.selection.getHeadBufferPosition()
    const tail = this.selection.getTailBufferPosition()

    if (this.selection.isEmpty() || isNormalized) {
      this.setProperties({head, tail})
    } else {
      // We selectRight-ed in visual-mode, this translation de-effect select-right-effect
      // So that we can activate-visual-mode without special translation after restoreing properties.
      const end = translatePointAndClip(this.selection.editor, this.getBufferRange().end, "backward")
      if (this.selection.isReversed()) {
        this.setProperties({head, tail: end})
      } else {
        this.setProperties({head: end, tail})
      }
    }
  }

  fixPropertyRowToRowRange() {
    const {head, tail} = this.getProperties()
    if (this.selection.isReversed()) {
      ;[head.row, tail.row] = this.selection.getBufferRowRange()
    } else {
      ;[tail.row, head.row] = this.selection.getBufferRowRange()
    }
  }

  // Use this for normalized(non-select-right-ed) selection.
  applyWise(wise) {
    switch (wise) {
      case "characterwise":
        this.translateSelectionEndAndClip("forward") // equivalent to core selection.selectRight but keep goalColumn
        break
      case "linewise":
        // Even if end.column is 0, expand over that end.row( don't use selection.getRowRange() )
        const {start, end} = this.getBufferRange()
        const endRow = getFoldEndRowForRow(this.selection.editor, end.row) // cover folded rowRange
        this.setBufferRange(getBufferRangeForRowRange(this.selection.editor, [start.row, endRow]))
        break
      case "blockwise":
        new BlockwiseSelection(this.selection)
        break
    }
  }

  selectByProperties({head, tail}) {
    // No problem if head is greater than tail, Range constructor swap start/end.
    this.setBufferRange([tail, head], {
      autoscroll: true,
      reversed: head.isLessThan(tail),
      keepGoalColumn: false,
    })
  }

  // set selections bufferRange with default option {autoscroll: false, preserveFolds: true}
  setBufferRange(range, options = {}) {
    const {keepGoalColumn = true} = options
    const goalColumn = keepGoalColumn ? this.selection.cursor.goalColumn : undefined
    delete options.keepGoalColumn
    this.selection.setBufferRange(range, Object.assign({autoscroll: false, preserveFolds: true}, options))
    if (goalColumn != null) this.selection.cursor.goalColumn = goalColumn
  }

  isSingleRow() {
    const [startRow, endRow] = this.selection.getBufferRowRange()
    return startRow === endRow
  }

  isLinewiseRange() {
    return isLinewiseRange(this.getBufferRange())
  }

  detectWise() {
    return this.isLinewiseRange() ? "linewise" : "characterwise"
  }

  // direction must be one of ['forward', 'backward']
  translateSelectionEndAndClip(direction) {
    const newRange = getRangeByTranslatePointAndClip(this.selection.editor, this.getBufferRange(), "end", direction)
    this.setBufferRange(newRange)
  }

  // Return selection extent to replay blockwise selection on `.` repeating.
  getBlockwiseSelectionExtent() {
    const head = this.selection.getHeadBufferPosition()
    const tail = this.selection.getTailBufferPosition()
    return new Point(head.row - tail.row, head.column - tail.column)
  }

  // What's the normalize?
  // Normalization is restore selection range from property.
  // As a result it range became range where end of selection moved to left.
  // This end-move-to-left de-efect of end-mode-to-right effect( this is visual-mode orientation )
  normalize() {
    // empty selection IS already 'normalized'
    if (this.selection.isEmpty()) return

    if (!this.hasProperties()) {
      if (settings.get("strictAssertion")) {
        assertWithException(false, "attempted to normalize but no properties to restore")
      }
      this.saveProperties()
    }
    const {head, tail} = this.getProperties()
    this.setBufferRange([tail, head])
  }
}

const swrap = selection => new SelectionWrapper(selection)

// BlockwiseSelection proxy
swrap.getBlockwiseSelections = editor => BlockwiseSelection.getSelections(editor)
swrap.getLastBlockwiseSelections = editor => BlockwiseSelection.getLastSelection(editor)

swrap.getBlockwiseSelectionsOrderedByBufferPosition = editor =>
  BlockwiseSelection.getSelectionsOrderedByBufferPosition(editor)

swrap.clearBlockwiseSelections = editor => BlockwiseSelection.clearSelections(editor)

swrap.getSelections = editor => editor.getSelections(editor).map(swrap)

swrap.setReversedState = function(editor, reversed) {
  this.getSelections(editor).map($selection => $selection.setReversedState(reversed))
}

swrap.detectWise = function(editor) {
  return this.getSelections(editor).every($selection => $selection.detectWise() === "linewise")
    ? "linewise"
    : "characterwise"
}

swrap.clearProperties = function(editor) {
  this.getSelections(editor).map($selection => $selection.clearProperties())
}

swrap.dumpProperties = function(editor) {
  const {inspect} = require("util")
  this.getSelections(editor)
    .filter($selection => $selection.hasProperties())
    .map($selection => console.log(inspect($selection.getProperties())))
}

swrap.normalize = function(editor) {
  if (BlockwiseSelection.has(editor)) {
    for (const blockwiseSelection of BlockwiseSelection.getSelections(editor)) {
      blockwiseSelection.normalize()
    }
    BlockwiseSelection.clearSelections(editor)
  } else {
    this.getSelections(editor).map($selection => $selection.normalize())
  }
}

swrap.hasProperties = function(editor) {
  return this.getSelections(editor).every($selection => $selection.hasProperties())
}

// Return function to restore
// Used in vmp-move-selected-text
swrap.switchToLinewise = function(editor) {
  for (const $selection of swrap.getSelections(editor)) {
    $selection.saveProperties()
    $selection.applyWise("linewise")
  }
  return new Disposable(function() {
    for (const $selection of swrap.getSelections(editor)) {
      $selection.normalize()
      $selection.applyWise("characterwise")
    }
  })
}

swrap.getPropertyStore = () => propertyStore

module.exports = swrap
