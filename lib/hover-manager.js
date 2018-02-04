module.exports = class HoverManager {
  constructor (vimState) {
    this.vimState = vimState
    this.vimState.onDidDestroy(() => this.destroy())
    this.container = document.createElement('div')
    this.reset()
  }

  getPoint () {
    if (this.vimState.isMode('visual', 'blockwise')) {
      return this.vimState
        .getLastBlockwiseSelection()
        .getHeadSelection()
        .getHeadBufferPosition()
    } else {
      return this.vimState
        .swrap(this.vimState.editor.getLastSelection())
        .getBufferPositionFor('head', {from: ['property', 'selection']})
    }
  }

  set (text, point = this.getPoint(), {classList = []} = {}) {
    if (!this.marker) {
      this.marker = this.vimState.editor.markBufferPosition(point)
      this.vimState.editor.decorateMarker(this.marker, {type: 'overlay', item: this.container})
    }

    if (classList.length) this.container.classList.add(...classList)
    this.container.textContent = text
  }

  reset () {
    this.container.className = 'vim-mode-plus-hover'
    if (this.marker) this.marker.destroy()
    this.marker = null
  }

  destroy () {
    this.container.remove()
    if (this.marker) this.marker.destroy()
    this.marker = null
  }
}
