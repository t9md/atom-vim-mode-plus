const {Disposable} = require("atom")

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

  addListner() {
    const onKeydown = this.onKeydown.bind(this)
    this.vimState.editorElement.addEventListener("keydown", onKeydown, true)
    return new Disposable(() => {
      console.log('remove listner');
      this.vimState.editorElement.removeEventListener("keydown", onKeydown, true)
    })
  }

  onKeydown(event) {
    const currentFind = this.vimState.globalState.get('currentFind')
    if (currentFind && currentFind.input === atom.keymaps.keystrokeForKeyboardEvent(event)) {
      this.vimState.operationStack.runCurrentFind()
      event.stopImmediatePropagation()
    } else {
      this.listnerDisposable.dispose()
    }
  }

  highlightRanges(ranges) {
    clearTimeout(this.clearMarkersTimeout)
    if (this.listnerDisposable) this.listnerDisposable.dispose()

    for (const range of ranges) {
      this.markerLayer.markBufferRange(range)
    }
    this.listnerDisposable = this.addListner()
    this.updateEditorElement()

    this.clearMarkersTimeout = setTimeout(() => {
      this.clearMarkers()
      this.listnerDisposable.dispose()
    }, 800)
  }
}
