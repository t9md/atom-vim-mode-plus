const _ = require("underscore-plus")

const {sortRanges, assertWithException, trimRange, getRange} = require("./utils")
const settings = require("./settings")
const blockwiseSelectionsByEditor = new Map()

let __swrap
function swrap(...args) {
  if (__swrap == null) __swrap = require("./selection-wrapper")
  return __swrap(...args)
}

module.exports = class BlockwiseSelection {
  static clearSelections(editor) {
    blockwiseSelectionsByEditor.delete(editor)
  }

  static has(editor) {
    return blockwiseSelectionsByEditor.has(editor)
  }

  static getSelections(editor) {
    return blockwiseSelectionsByEditor.get(editor) || []
  }

  static getSelectionsOrderedByBufferPosition(editor) {
    return this.getSelections(editor).sort((a, b) => a.getStartSelection().compare(b.getStartSelection()))
  }

  static getLastSelection(editor) {
    return _.last(blockwiseSelectionsByEditor.get(editor))
  }

  static saveSelection(blockwiseSelection) {
    const {editor} = blockwiseSelection
    if (!this.has(editor)) {
      blockwiseSelectionsByEditor.set(editor, [])
    }
    blockwiseSelectionsByEditor.get(editor).push(blockwiseSelection)
  }

  constructor(selection) {
    this.needSkipNormalization = false
    this.properties = {}
    this.editor = selection.editor
    const $selection = swrap(selection)
    if (!$selection.hasProperties()) {
      if (settings.get("strictAssertion")) {
        assertWithException(false, "Trying to instantiate vB from properties-less selection")
      }
      $selection.saveProperties()
    }

    this.goalColumn = selection.cursor.goalColumn
    this.reversed = selection.isReversed()

    const {head: {column: headColumn}, tail: {column: tailColumn}} = $selection.getProperties()
    const start = $selection.getBufferPositionFor("start", {from: ["property"]})
    const end = $selection.getBufferPositionFor("end", {from: ["property"]})

    // Respect goalColumn only when it's value is Infinity and selection's head-column is bigger than tail-column
    if (this.goalColumn === Infinity && headColumn >= tailColumn) {
      if (selection.isReversed()) {
        start.column = this.goalColumn
      } else {
        end.column = this.goalColumn
      }
    }

    {
      let endColumn, reversed, startColumn

      if (start.column > end.column) {
        reversed = !selection.isReversed()
        startColumn = end.column
        endColumn = start.column + 1
      } else {
        reversed = selection.isReversed()
        startColumn = start.column
        endColumn = end.column + 1
      }

      const ranges = getRange(start.row, end.row).map(row => [[row, startColumn], [row, endColumn]])
      selection.setBufferRange(ranges.shift(), {reversed})
      this.selections = [selection, ...ranges.map(range => this.editor.addSelectionForBufferRange(range, {reversed}))]
    }

    this.updateGoalColumn()

    this.getSelections().map(swrap).filter(v => v).forEach($selection => {
      $selection.saveProperties() // TODO#698  remove this?
      $selection.getProperties().head.column = headColumn
      $selection.getProperties().tail.column = tailColumn
    })
    this.constructor.saveSelection(this)
  }

  getSelections() {
    return this.selections
  }

  extendMemberSelectionsToEndOfLine() {
    for (const selection of this.getSelections()) {
      const {start, end} = selection.getBufferRange()
      selection.setBufferRange([start, [end.row, Infinity]])
    }
  }

  expandMemberSelectionsOverLineWithTrimRange() {
    for (const selection of this.getSelections()) {
      const {start} = selection.getBufferRange()
      const range = trimRange(this.editor, this.editor.bufferRangeForBufferRow(start.row))
      selection.setBufferRange(range)
    }
  }

  isReversed() {
    return this.reversed
  }

  reverse() {
    this.reversed = !this.reversed
  }

  getProperties() {
    return {
      head: swrap(this.getHeadSelection()).getProperties().head,
      tail: swrap(this.getTailSelection()).getProperties().tail,
    }
  }

  updateGoalColumn() {
    if (this.goalColumn != null) {
      for (const selection of this.selections) {
        selection.cursor.goalColumn = this.goalColumn
      }
    }
  }

  isSingleRow() {
    return this.selections.length === 1
  }

  getHeight() {
    const [startRow, endRow] = this.getBufferRowRange()
    return endRow - startRow + 1
  }

  getStartSelection() {
    return this.selections[0]
  }

  getEndSelection() {
    return _.last(this.selections)
  }

  getHeadSelection() {
    return this.isReversed() ? this.getStartSelection() : this.getEndSelection()
  }

  getTailSelection() {
    return this.isReversed() ? this.getEndSelection() : this.getStartSelection()
  }

  getBufferRowRange() {
    const startRow = this.getStartSelection().getBufferRowRange()[0]
    const endRow = this.getEndSelection().getBufferRowRange()[0]
    return [startRow, endRow]
  }

  // [NOTE] Used by plugin package vmp:move-selected-text
  setSelectedBufferRanges(ranges, {reversed}) {
    sortRanges(ranges)

    const head = this.getHeadSelection()
    this.removeSelections({except: head})
    const {goalColumn} = head.cursor
    // When reversed state of selection change, goalColumn is cleared.
    // But here for blockwise, I want to keep goalColumn unchanged.
    // This behavior is not compatible with pure-Vim I know.
    // But I believe this is more unnoisy and less confusion while moving
    // cursor in visual-block mode.
    head.setBufferRange(ranges.shift(), {reversed})
    if (goalColumn != null && head.cursor.goalColumn == null) {
      head.cursor.goalColumn = goalColumn
    }

    for (const range of ranges) {
      this.selections.push(this.editor.addSelectionForBufferRange(range, {reversed}))
    }
    this.updateGoalColumn()
  }

  removeSelections({except} = {}) {
    for (const selection of this.selections.slice()) {
      if (selection !== except) {
        swrap(selection).clearProperties()
        _.remove(this.selections, selection)
        selection.destroy()
      }
    }
  }

  setHeadBufferPosition(point) {
    const head = this.getHeadSelection()
    this.removeSelections({except: head})
    head.cursor.setBufferPosition(point)
  }

  skipNormalization() {
    this.needSkipNormalization = true
  }

  normalize() {
    if (this.needSkipNormalization) return

    // CAUTION: Save prop BEFORE removing member selections.
    const properties = this.getProperties()

    const head = this.getHeadSelection()
    this.removeSelections({except: head})

    const {goalColumn} = head.cursor // FIXME this should not be necessary

    const $selection = swrap(head)
    $selection.selectByProperties(properties)
    $selection.saveProperties(true)

    if (goalColumn != null && head.cursor.goalColumn == null) {
      // FIXME this should not be necessary
      head.cursor.goalColumn = goalColumn
    }
  }

  autoscroll() {
    this.getHeadSelection().autoscroll()
  }
}
