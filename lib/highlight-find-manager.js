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

  highlightCursorRows(regex, decorationType, backwards, currentIndex) {
    this.clearMarkers()

    const vimState = this.vimState
    const editor = this.vimState.editor
    const visibleRange = this.vimState.utils.getVisibleBufferRange(editor)
    if (!visibleRange) return

    const cursors = editor.getCursors().filter(cursor => visibleRange.containsPoint(cursor.getBufferPosition()))
    if (!cursors.length) return

    let scanRanges
    if (vimState.getConfig("findAcrossLines")) {
      const cursorsOrdered = this.vimState.utils.sortCursors(cursors)
      scanRanges = backwards
        ? [[visibleRange.start, cursorsOrdered.pop().getBufferPosition()]]
        : [[cursorsOrdered.shift().getBufferPosition(), visibleRange.end]]
    } else {
      scanRanges = backwards
        ? cursors.map(cursor => [cursor.getCurrentLineBufferRange().start, cursor.getBufferPosition()])
        : cursors.map(cursor => [cursor.getBufferPosition(), cursor.getCurrentLineBufferRange().end])
    }

    const ranges = []
    for (const scanRange of scanRanges) {
      editor.scanInBufferRange(regex, scanRange, ({range}) => ranges.push(range))
    }
    if (!ranges.length) return

    let currentRange
    if (decorationType === "pre-confirm") {
      const cursorPosition = editor.getCursorBufferPosition()
      const candidates = backwards
        ? ranges.slice().reverse().filter(range => range.start.isLessThan(cursorPosition))
        : ranges.filter(range => range.start.isGreaterThan(cursorPosition))
      currentRange = candidates[currentIndex]
    }
    this.highlightRanges(ranges, decorationType, currentRange)
  }

  highlightRanges(ranges, decorationType, currentRange) {
    if (this.clearMarkerTimeoutID) {
      clearTimeout(this.clearMarkerTimeoutID)
      this.clearMarkerTimeoutID = null
    }

    // We need to force update here to restart(re-trigger) keyframe animation.
    this.vimState.editor.component.updateSync()

    for (const range of ranges) {
      this.markerLayer.markBufferRange(range)
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
