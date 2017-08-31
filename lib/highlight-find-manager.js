module.exports = class HighlightFind {
  constructor(vimState) {
    this.vimState = vimState
    vimState.onDidDestroy(() => this.destroy())

    this.markerLayer = vimState.editor.addMarkerLayer()
    this.decorationLayer = vimState.editor.decorateMarkerLayer(this.markerLayer, {
      type: "highlight",
      class: "vim-mode-plus-find-char",
    })
  }

  destroy() {
    this.decorationLayer.destroy()
    this.markerLayer.destroy()
  }

  clearMarkers() {
    this.markerLayer.clear()
  }

  highlightRanges(ranges, confirmed) {
    this.clearMarkers()
    for (const range of ranges) {
      this.markerLayer.markBufferRange(range)
    }
  }
}
