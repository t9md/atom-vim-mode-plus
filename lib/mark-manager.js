const {Point} = require("atom")

const MARKS_REGEX = /[a-z]|[\[\]`'.^(){}<>]/

class MarkManager {
  constructor(vimState) {
    this.vimState = vimState
    vimState.onDidDestroy(() => this.destroy())
    this.marks = {}
    this.markerLayer = vimState.editor.addMarkerLayer()
  }

  destroy() {
    this.markerLayer.destroy()
    this.marks = null
  }

  isValid(name) {
    return MARKS_REGEX.test(name)
  }

  get(name) {
    if (!this.isValid(name)) return

    const mark = this.marks[name]
    if (mark) {
      return mark.getStartBufferPosition()
    } else if (["`", "'"].includes(name)) {
      return Point.ZERO
    }
  }

  // [FIXME] Need to support Global mark with capital name [A-Z]
  set(name, point) {
    if (!this.isValid(name)) return

    const marker = this.marks[name]
    if (marker) marker.destroy()

    const {editor} = this.vimState
    point = editor.clipBufferPosition(point)
    this.marks[name] = this.markerLayer.markBufferPosition(point, {invalidate: "never"})
    this.vimState.emitter.emit("did-set-mark", {name, point, editor})
  }
}

module.exports = MarkManager
