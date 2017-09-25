module.exports = class HoverManager {
  constructor(vimState) {
    this.vimState = vimState
    this.container = document.createElement("div")
    this.vimState.onDidDestroy(() => this.destroy())
    this.reset()
  }

  getPoint() {
    const {vimState} = this
    return vimState.isMode("visual", "blockwise")
      ? vimState
          .getLastBlockwiseSelection()
          .getHeadSelection()
          .getHeadBufferPosition()
      : vimState
          .swrap(this.vimState.editor.getLastSelection())
          .getBufferPositionFor("head", {from: ["property", "selection"]})
  }

  set(text, point = this.getPoint(), {classList = []} = {}) {
    if (!this.marker) {
      this.marker = this.vimState.editor.markBufferPosition(point)
      this.vimState.editor.decorateMarker(this.marker, {type: "overlay", item: this.container})
    }

    if (classList.length) this.container.classList.add(...classList)
    this.container.textContent = text
  }

  reset() {
    this.container.className = "vim-mode-plus-hover"
    if (this.marker) this.marker.destroy()
    this.marker = null
  }

  destroy() {
    this.container.remove()
    if (this.marker) this.marker.destroy()
    this.marker = null
  }
}
