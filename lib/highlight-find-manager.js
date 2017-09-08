const {Point} = require("atom")
const {limitNumber} = require("./utils")

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
    const editor = this.vimState.editor
    const visibleRange = this.vimState.utils.getVisibleBufferRange(editor)
    if (!visibleRange) return

    const scanMethodName = backwards ? "backwardsScanInBufferRange" : "scanInBufferRange"
    const compareMethodName = backwards
      ? isPreConfirm || offset ? "isLessThan" : "isLessThanOrEqual"
      : isPreConfirm || offset ? "isGreaterThan" : "isGreaterThanOrEqual"

    const collectRanges = (regex, scanRange, point) => {
      const ranges = []
      editor[scanMethodName](regex, scanRange, ({range}) => {
        if (range.start[compareMethodName](point)) ranges.push(range)
      })
      return ranges
    }

    const rangesToHighlight = []

    let landingRanges = []
    if (this.vimState.getConfig("findAcrossLines")) {
      const cursorsOrdered = editor.getCursorsOrderedByBufferPosition()

      let scanRange, cursorPosition
      if (backwards) {
        const bottomCursor = cursorsOrdered.slice().pop()
        cursorPosition = bottomCursor.getBufferPosition()
        scanRange = [Point.ZERO, [cursorPosition.row, Infinity]]
      } else {
        const topCursor = cursorsOrdered.slice().shift()
        cursorPosition = topCursor.getBufferPosition()
        scanRange = [[cursorPosition.row, 0], editor.getEofBufferPosition()]
      }
      const ranges = collectRanges(regex, scanRange, cursorPosition)
      rangesToHighlight.push(...ranges.filter(range => visibleRange.containsRange(range)))
      if (isPreConfirm) {
        for (const cursor of cursorsOrdered) {
          const point = cursor.getBufferPosition()
          const index = ranges.findIndex(range => range.start[compareMethodName](point))
          if (index >= 0) {
            const range = ranges[index + currentIndex]
            if (range) {
              landingRanges.push(range)
              if (cursor.isLastCursor()) editor.scrollToBufferPosition(range.start)
            }
          }
        }
      }
      // ranges.filter
    } else {
      const visibleCursors = editor.getCursors().filter(cursor => visibleRange.containsPoint(cursor.getBufferPosition()))
      for (const cursor of visibleCursors) {
        const scanRange = cursor.getCurrentLineBufferRange()
        const ranges = collectRanges(regex, scanRange, cursor.getBufferPosition())
        rangesToHighlight.push(...ranges)

        if (isPreConfirm) {
          if (adjustIndex) currentIndex = limitNumber(currentIndex, {min: 0, max: ranges.length - 1})

          const range = ranges[currentIndex]
          if (range) {
            landingRanges.push(range)
            if (cursor.isLastCursor()) editor.scrollToBufferPosition(range.start)
          }
        }
      }
    }
    if (!rangesToHighlight.length) return

    this.highlightRanges(rangesToHighlight, decorationType, landingRanges)

    return currentIndex
  }

  highlightRanges(ranges, decorationType, landingRanges) {
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

    for (const landingRange of landingRanges) {
      const marker = this.markerLayer.getMarkers().find(marker => marker.getBufferRange().isEqual(landingRange))
      this.decorationLayer.setPropertiesForMarker(marker, {
        type: "highlight",
        class: "vim-mode-plus-find-char pre-confirm current",
      })
    }

    if (timeout) {
      this.clearMarkerTimeoutID = setTimeout(() => this.clearMarkers(), timeout)
    }
  }
}
