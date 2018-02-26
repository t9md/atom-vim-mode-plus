const {isNotEmpty, replaceDecorationClassBy} = require('./utils')

// NOTE: following timeout should sync to animation-duration specified in `style.less`.
const timeoutByFlashType = {
  operator: 500,
  'operator-long': 800,
  'operator-occurrence': 800,
  'operator-remove-occurrence': 800,
  search: 1000,
  screen: 300,
  'undo-redo': 500,
  'undo-redo-multiple-changes': 500,
  'undo-redo-multiple-deletes': 500
}

function addDemoSuffix (decoration) {
  replaceDecorationClassBy(decoration, text => text + '-demo')
}

function removeDemoSuffix (decoration) {
  replaceDecorationClassBy(decoration, text => text.replace(/-demo$/, ''))
}

module.exports = class FlashManager {
  constructor (vimState) {
    this.vimState = vimState
    this.editor = this.vimState.editor
    this.markersByType = new Map()
    this.vimState.onDidDestroy(() => this.destroy())
    this.postponedDestroyMarkersTasks = []
  }

  destroy () {
    this.clearAllMarkers()
  }

  destroyDemoModeMarkers () {
    for (const destroyMarkers of this.postponedDestroyMarkersTasks) {
      destroyMarkers()
    }
    this.postponedDestroyMarkersTasks = []
  }

  destroyMarkersAfter (markers, timeout) {
    setTimeout(() => {
      for (const marker of markers) marker.destroy()
      markers.length = 0
    }, timeout)
  }

  destroyPreviousMarkerForTypeIfNecessary (type) {
    if (this.markersByType.has(type)) {
      this.markersByType.get(type).forEach(marker => marker.destroy())
      this.markersByType.delete(type)
      // Reflect to element before adding next css class. Important to **re-start** keyframe animation.
      this.editor.component.updateSync()
    }
  }

  flash (ranges, {type}) {
    ranges = (Array.isArray(ranges) ? ranges : [ranges]).filter(isNotEmpty)
    if (!ranges.length) return

    this.destroyPreviousMarkerForTypeIfNecessary(type)
    const markers = ranges.map(range => this.editor.markBufferRange(range, {invalidate: 'touch'}))
    // hold as state to clear all markers onDidStopChangingActivePaneItem. t9md/vim-mode-plus#846.
    this.markersByType.set(type, markers)

    const decorations = markers.map(marker =>
      this.editor.decorateMarker(marker, {
        type: 'highlight',
        class: 'vim-mode-plus-flash ' + type
      })
    )

    const timeout = timeoutByFlashType[type]
    if (this.vimState.globalState.get('demoModeIsActive')) {
      decorations.forEach(addDemoSuffix)
      this.postponedDestroyMarkersTasks.push(() => {
        decorations.forEach(removeDemoSuffix)
        this.destroyMarkersAfter(markers, timeout)
      })
    } else {
      this.destroyMarkersAfter(markers, timeout)
    }
  }

  clearAllMarkers () {
    this.markersByType.forEach(markers => markers.forEach(marker => marker.destroy()))
    this.markersByType.clear()
  }
}
