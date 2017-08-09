const {isNotEmpty, replaceDecorationClassBy} = require("./utils")

const flashTypes = {
  operator: {
    allowMultiple: true,
    decorationOptions: {
      type: "highlight",
      class: "vim-mode-plus-flash operator",
    },
  },
  "operator-long": {
    allowMultiple: true,
    decorationOptions: {
      type: "highlight",
      class: "vim-mode-plus-flash operator-long",
    },
  },
  "operator-occurrence": {
    allowMultiple: true,
    decorationOptions: {
      type: "highlight",
      class: "vim-mode-plus-flash operator-occurrence",
    },
  },
  "operator-remove-occurrence": {
    allowMultiple: true,
    decorationOptions: {
      type: "highlight",
      class: "vim-mode-plus-flash operator-remove-occurrence",
    },
  },
  search: {
    allowMultiple: false,
    decorationOptions: {
      type: "highlight",
      class: "vim-mode-plus-flash search",
    },
  },
  screen: {
    allowMultiple: true,
    decorationOptions: {
      type: "highlight",
      class: "vim-mode-plus-flash screen",
    },
  },
  "undo-redo": {
    allowMultiple: true,
    decorationOptions: {
      type: "highlight",
      class: "vim-mode-plus-flash undo-redo",
    },
  },
  "undo-redo-multiple-changes": {
    allowMultiple: true,
    decorationOptions: {
      type: "highlight",
      class: "vim-mode-plus-flash undo-redo-multiple-changes",
    },
  },
  "undo-redo-multiple-delete": {
    allowMultiple: true,
    decorationOptions: {
      type: "highlight",
      class: "vim-mode-plus-flash undo-redo-multiple-delete",
    },
  },
}

function addDemoSuffix(decoration) {
  replaceDecorationClassBy(text => text + "-demo", decoration)
}
function removeDemoSuffix(decoration) {
  replaceDecorationClassBy(text => text.replace(/-demo$/, ""), decoration)
}

module.exports = FlashManager = class FlashManager {
  constructor(vimState) {
    this.vimState = vimState
    this.editor = this.vimState.editor
    this.markersByType = new Map()
    this.vimState.onDidDestroy(this.destroy.bind(this))
    this.postponedDestroyMarkersTasks = []
  }

  destroy() {
    this.markersByType.forEach(markers => markers.map(marker => marker.destroy()))
    this.markersByType.clear()
  }

  destroyDemoModeMarkers() {
    for (const resolve of this.postponedDestroyMarkersTasks) resolve()
    this.postponedDestroyMarkersTasks = []
  }

  destroyMarkersAfter(markers, timeout) {
    setTimeout(() => {
      for (const marker of markers) marker.destroy()
    }, timeout)
  }

  flash(ranges, {type, timeout = 1000}) {
    ranges = (Array.isArray(ranges) ? ranges : [ranges]).filter(isNotEmpty)
    if (!ranges.length) return

    const {allowMultiple, decorationOptions} = flashTypes[type]
    const markerOptions = {invalidate: "touch"}

    const markers = ranges.map(range => this.editor.markBufferRange(range, markerOptions))
    if (!allowMultiple) {
      if (this.markersByType.has(type)) {
        this.markersByType.get(type).forEach(marker => marker.destroy())
      }
      this.markersByType.set(type, markers)
    }

    const decorations = markers.map(marker => this.editor.decorateMarker(marker, decorationOptions))

    if (this.vimState.globalState.get("demoModeIsActive")) {
      decorations.forEach(addDemoSuffix)
      this.postponedDestroyMarkersTasks.push(() => {
        decorations.forEach(removeDemoSuffix)
        this.destroyMarkersAfter(markers, timeout)
      })
    } else {
      this.destroyMarkersAfter(markers, timeout)
    }
  }
}
