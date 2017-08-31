const DecorationProps = {
  initial: {
    type: "highlight",
    class: "vim-mode-plus-find-char",
  },
  confirmed: {
    type: "highlight",
    class: "vim-mode-plus-find-char confirmed",
  },
}

module.exports = class HighlightFind {
  constructor(vimState) {
    this.vimState = vimState
    vimState.onDidDestroy(() => this.destroy())

    this.markerLayer = vimState.editor.addMarkerLayer()
    this.decorationLayer = vimState.editor.decorateMarkerLayer(this.markerLayer, DecorationProps.initial)
  }

  destroy() {
    this.decorationLayer.destroy()
    this.markerLayer.destroy()
  }

  highlightRanges(ranges, confirmed) {
    if (this.clearMarkerTimeoutID) {
      clearTimeout(this.clearMarkerTimeoutID)
      this.clearMarkerTimeoutID = null
    }

    this.markerLayer.clear()
    this.decorationLayer.setProperties(DecorationProps.initial)
    // We need to force update here to reflect decoration props.confirmed being reset.
    this.vimState.editor.component.updateSync()

    for (const range of ranges) {
      this.markerLayer.markBufferRange(range)
    }

    if (confirmed) {
      this.decorationLayer.setProperties(DecorationProps.confirmed)
      this.clearMarkerTimeoutID = setTimeout(() => this.markerLayer.clear(), 2000)
    }
  }
}
