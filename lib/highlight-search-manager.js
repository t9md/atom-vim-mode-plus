const {CompositeDisposable} = require("atom")

module.exports = class HighlightSearchManager {
  constructor(vimState) {
    this.vimState = vimState
    const {editor} = vimState
    this.disposables = new CompositeDisposable()

    this.disposables.add(vimState.onDidDestroy(() => this.destroy()))
    this.disposables.add(editor.onDidStopChanging(() => this.refresh()))

    this.markerLayer = editor.addMarkerLayer()
    this.decorationLayer = editor.decorateMarkerLayer(this.markerLayer, {
      type: "highlight",
      class: "vim-mode-plus-highlight-search",
    })
  }

  destroy() {
    this.decorationLayer.destroy()
    this.disposables.dispose()
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
  }

  refresh() {
    this.clearMarkers()
    const vimState = this.vimState

    if (!vimState.getConfig("highlightSearch") || !vimState.isVisible()) return
    const regex = vimState.globalState.get("highlightSearchPattern")
    if (!regex) return
    if (vimState.matchScopes(vimState.getConfig("highlightSearchExcludeScopes"))) return

    const ranges = []
    vimState.editor.scan(regex, ({range}) => ranges.push(range))

    for (const range of ranges.filter(range => !range.isEmpty())) {
      this.markerLayer.markBufferRange(range, {invalidate: "inside"})
    }
  }
}
