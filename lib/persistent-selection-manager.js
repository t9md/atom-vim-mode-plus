module.exports = class PersistentSelectionManager {
  constructor(vimState) {
    this.vimState = vimState
    vimState.onDidDestroy(() => this.destroy())

    this.markerLayer = this.editor.addMarkerLayer()
    this.decorationLayer = this.editor.decorateMarkerLayer(this.markerLayer, {
      type: "highlight",
      class: "vim-mode-plus-persistent-selection",
    })

    // Update css on every marker update.
    this.markerLayer.onDidUpdate(() => {
      this.editor.element.classList.toggle("has-persistent-selection", this.hasMarkers())
    })
  }

  destroy() {
    this.decorationLayer.destroy()
    this.markerLayer.destroy()
  }

  select() {
    for (const range of this.getMarkerBufferRanges()) {
      this.vimState.editor.addSelectionForBufferRange(range)
    }
    this.clearMarkers()
  }

  setSelectedBufferRanges() {
    this.vimState.editor.setSelectedBufferRanges(this.getMarkerBufferRanges())
    this.clearMarkers()
  }

  isEmpty() {
    return this.markerLayer.getMarkerCount() === 0
  }

  // Markers
  // -------------------------
  markBufferRange(range) {
    return this.markerLayer.markBufferRange(range)
  }

  hasMarkers() {
    return this.markerLayer.getMarkerCount() > 0
  }

  getMarkers() {
    return this.markerLayer.getMarkers()
  }

  clearMarkers() {
    this.markerLayer.clear()
  }

  getMarkerBufferRanges() {
    return this.markerLayer.getMarkers().map(marker => marker.getBufferRange())
  }

  getMarkerAtPoint(point) {
    return this.markerLayer.findMarkers({containsBufferPosition: point})[0]
  }
}
