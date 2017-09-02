const DecorationTypes = {
  "pre-confirm": {
    decorationProps: {
      type: "highlight",
      class: "vim-mode-plus-find-char pre-confirm",
    },
  },
  "pre-confirm single-match": {
    decorationProps: {
      type: "highlight",
      class: "vim-mode-plus-find-char pre-confirm single-match",
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

  highlightRanges(ranges, decorationType) {
    if (this.clearMarkerTimeoutID) {
      clearTimeout(this.clearMarkerTimeoutID)
      this.clearMarkerTimeoutID = null
    }

    this.clearMarkers()
    // We need to force update here to restart(re-trigger) keyframe animation.
    this.vimState.editor.component.updateSync()

    for (const range of ranges) {
      this.markerLayer.markBufferRange(range)
    }

    const {timeout, decorationProps} = DecorationTypes[decorationType]
    this.decorationLayer.setProperties(decorationProps)
    if (timeout) {
      this.clearMarkerTimeoutID = setTimeout(() => this.clearMarkers(), timeout)
    }
  }
}
