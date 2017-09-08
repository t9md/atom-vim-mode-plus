const {Point} = require("atom")
const DecorationTypes = {
  "pre-confirm": {
    decorationProps: {
      type: "highlight",
      class: "vim-mode-plus-find-char pre-confirm",
    },
  },
  "post-confirm": {
    timeout: 2000,
    decorationProps: {
      type: "highlight",
      class: "vim-mode-plus-find-char post-confirm",
    },
  },
  "post-confirm long": {
    timeout: 4000,
    decorationProps: {
      type: "highlight",
      class: "vim-mode-plus-find-char post-confirm long",
    },
  },
}

module.exports = class HighlightFind {
  constructor(vimState) {
    this.vimState = vimState
    vimState.onDidDestroy(() => this.destroy())

    const {editor} = vimState
    this.markerLayer = editor.addMarkerLayer()
    this.decorationLayer = editor.decorateMarkerLayer(this.markerLayer, {})
  }

  destroy() {
    this.decorationLayer.destroy()
    this.markerLayer.destroy()
  }

  clearMarkers() {
    this.markerLayer.clear()
  }

  // Return adjusted currentIndex
  highlightCursorRows(regex, decorationType, backwards, offset, currentIndex, adjustIndex) {
    this.clearMarkers()

    const isPreConfirm = decorationType === "pre-confirm"
    const vimState = this.vimState
    const editor = this.vimState.editor
    const visibleRange = this.vimState.utils.getVisibleBufferRange(editor)
    if (!visibleRange) return

    const collectMethod = backwards
      ? isPreConfirm || offset ? "isLessThan" : "isLessThanOrEqual"
      : isPreConfirm || offset ? "isGreaterThan" : "isGreaterThanOrEqual"

    const collectRanges = (regex, scanRange, backwards, point) => {
      const ranges = []
      const needHighlight = range => range.start[collectMethod](point)
      const collect = ({range}) => needHighlight(range) && ranges.push(range)
      editor.scanInBufferRange(regex, scanRange, collect)
      return ranges
    }

    const ranges = []
    let currentRange
    if (vimState.getConfig("findAcrossLines")) {
      const cursorsOrdered = this.vimState.utils.sortCursors(editor.getCursors())
      const scanRange = visibleRange

      if (backwards) {
        const bottomCursor = cursorsOrdered.pop()
        const cursorPosition = bottomCursor.getBufferPosition()
        scanRange.end = Point.min(scanRange.end, bottomCursor.getCurrentLineBufferRange().end)
        ranges.push(...collectRanges(regex, scanRange, true, cursorPosition))
      } else {
        const topCursor = cursorsOrdered.shift()
        const cursorPosition = topCursor.getBufferPosition()
        scanRange.start = Point.max(scanRange.start, topCursor.getCurrentLineBufferRange().start)
        ranges.push(...collectRanges(regex, scanRange, false, cursorPosition))
      }
      // ranges.filter
    } else {
      const cursors = editor.getCursors().filter(cursor => visibleRange.containsPoint(cursor.getBufferPosition()))
      for (const cursor of cursors) {
        const scanRange = cursor.getCurrentLineBufferRange()
        const _ranges = collectRanges(regex, scanRange, backwards, cursor.getBufferPosition())

        if (cursor.isLastCursor() && isPreConfirm) {
          if (adjustIndex) {
            currentIndex = this.vimState.utils.limitNumber(currentIndex, {min: 0, max: _ranges.length - 1})
          }
          currentRange = _ranges[currentIndex]
          if (currentRange) editor.scrollToBufferPosition(currentRange.start)
        }

        ranges.push(..._ranges)
      }
    }
    if (!ranges.length) return

    this.highlightRanges(ranges, decorationType, currentRange)

    return currentIndex
  }

  highlightRanges(ranges, decorationType, currentRange) {
    if (this.clearMarkerTimeoutID) {
      clearTimeout(this.clearMarkerTimeoutID)
      this.clearMarkerTimeoutID = null
    }

    // We need to force update here to restart(re-trigger) keyframe animation.
    this.vimState.editor.component.updateSync()

    for (const range of ranges) {
      this.markerLayer.markBufferRange(range, {invalidate: "touch"})
    }

    const {timeout, decorationProps} = DecorationTypes[decorationType]
    this.decorationLayer.setProperties(decorationProps)

    if (currentRange) {
      const currentMarker = this.markerLayer.getMarkers().find(marker => marker.getBufferRange().isEqual(currentRange))
      this.decorationLayer.setPropertiesForMarker(currentMarker, {
        type: "highlight",
        class: "vim-mode-plus-find-char pre-confirm current",
      })
    }

    if (timeout) {
      this.clearMarkerTimeoutID = setTimeout(() => this.clearMarkers(), timeout)
    }
  }
}
