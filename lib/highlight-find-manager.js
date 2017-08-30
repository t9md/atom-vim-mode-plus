module.exports = class HighlightFind {
  constructor(vimState) {
    this.vimState = vimState
    const {editor} = vimState
    vimState.onDidDestroy(() => this.destroy())

    this.markerLayer = editor.addMarkerLayer()
    this.decorationLayer = editor.decorateMarkerLayer(this.markerLayer, {
      type: "highlight",
      class: "vim-mode-plus-find-char",
    })
  }

  updateEditorElement() {
    this.vimState.editorElement.classList.toggle("has-highlight-find", this.hasMarkers())
  }

  destroy() {
    this.decorationLayer.destroy()
    this.markerLayer.destroy()
  }

  hasMarkers() {
    return this.markerLayer.getMarkerCount() > 0
  }

  getMarkers() {
    return this.markerLayer.getMarkers()
  }

  clearMarkers() {
    this.markerLayer.clear()
    this.updateEditorElement()
  }

  highlightRanges(ranges) {
    for (const range of ranges) {
      this.markerLayer.markBufferRange(range)
    }
    this.updateEditorElement()
  }
}
