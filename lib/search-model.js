const {Emitter, CompositeDisposable} = require("atom")
const {getVisibleBufferRange, smartScrollToBufferPosition, getIndex, replaceDecorationClassBy} = require("./utils")

let hoverCounterTimeoutID

function removeCurrentClassForDecoration(decoration) {
  replaceDecorationClassBy(text => text.replace(/\s+current(\s+)?$/, "$1"), decoration)
}
function addCurrentClassForDecoration(decoration) {
  replaceDecorationClassBy(text => text.replace(/\s+current(\s+)?$/, "$1") + " current", decoration)
}

module.exports = class SearchModel {
  onDidChangeCurrentMatch(fn) {
    return this.emitter.on("did-change-current-match", fn)
  }

  constructor(vimState, options) {
    this.relativeIndex = 0
    this.lastRelativeIndex = null

    this.vimState = vimState
    this.editor = vimState.editor
    this.editorElement = vimState.editorElement
    this.options = options
    this.emitter = new Emitter()

    this.disposables = new CompositeDisposable()
    this.disposables.add(
      this.editorElement.onDidChangeScrollTop(() => this.refreshMarkers()),
      this.editorElement.onDidChangeScrollLeft(() => this.refreshMarkers())
    )
    this.markerLayer = this.editor.addMarkerLayer()
    this.decoationByRange = {}

    this.onDidChangeCurrentMatch(() => {
      this.vimState.hoverSearchCounter.reset()
      if (!this.currentMatch) {
        if (this.vimState.getConfig("flashScreenOnSearchHasNoMatch")) {
          this.vimState.flash(getVisibleBufferRange(this.editor), {type: "screen"})
          atom.beep()
        }
        return
      }

      if (this.vimState.getConfig("showHoverSearchCounter")) {
        const text = String(this.currentMatchIndex + 1) + "/" + this.matches.length
        const point = this.currentMatch.start
        const classList = this.classNamesForRange(this.currentMatch)

        this.resetHover()
        this.vimState.hoverSearchCounter.set(text, point, {classList})

        if (!this.options.incrementalSearch) {
          hoverCounterTimeoutID = setTimeout(
            () => this.resetHover(),
            this.vimState.getConfig("showHoverSearchCounterDuration")
          )
        }
      }

      this.editor.unfoldBufferRow(this.currentMatch.start.row)
      smartScrollToBufferPosition(this.editor, this.currentMatch.start)

      if (this.vimState.getConfig("flashOnSearch")) {
        this.vimState.flash(this.currentMatch, {type: "search"})
      }
    })
  }

  resetHover() {
    if (hoverCounterTimeoutID) {
      clearTimeout(hoverCounterTimeoutID)
      hoverCounterTimeoutID = null
    }
    // See #674
    // This method called with setTimeout
    // hoverSearchCounter might not be available when editor destroyed.
    if (this.vimState.hoverSearchCounter) this.vimState.hoverSearchCounter.reset()
  }

  destroy() {
    this.markerLayer.destroy()
    this.disposables.dispose()
    this.decoationByRange = null
  }

  clearMarkers() {
    this.markerLayer.clear()
    this.decoationByRange = {}
  }

  classNamesForRange(range) {
    const classNames = []
    if (range === this.firstMatch) classNames.push("first")
    else if (range === this.lastMatch) classNames.push("last")

    if (range === this.currentMatch) classNames.push("current")
    return classNames
  }

  refreshMarkers() {
    this.clearMarkers()
    for (const range of this.getVisibleMatchRanges()) {
      if (!range.isEmpty()) {
        this.decoationByRange[range.toString()] = this.decorateRange(range)
      }
    }
  }

  getVisibleMatchRanges() {
    const visibleRange = getVisibleBufferRange(this.editor)
    return this.matches.filter(range => range.intersectsWith(visibleRange))
  }

  decorateRange(range) {
    return this.editor.decorateMarker(this.markerLayer.markBufferRange(range), {
      type: "highlight",
      class: ["vim-mode-plus-search-match", ...this.classNamesForRange(range)].join(" "),
    })
  }

  search(fromPoint, pattern, relativeIndex) {
    this.pattern = pattern
    this.matches = []
    this.editor.scan(this.pattern, ({range}) => this.matches.push(range))

    this.firstMatch = this.matches[0]
    this.lastMatch = this.matches[this.matches.length - 1]

    let currentMatch
    const matches = this.matches.slice()
    if (relativeIndex >= 0) {
      currentMatch = matches.find(range => range.start.isGreaterThan(fromPoint)) || this.firstMatch
      relativeIndex--
    } else {
      currentMatch = matches.reverse().find(range => range.start.isLessThan(fromPoint)) || this.lastMatch
      relativeIndex++
    }

    this.currentMatchIndex = this.matches.indexOf(currentMatch)
    this.updateCurrentMatch(relativeIndex)
    if (this.options.incrementalSearch) this.refreshMarkers()
    this.initialCurrentMatchIndex = this.currentMatchIndex
    return this.currentMatch
  }

  updateCurrentMatch(relativeIndex) {
    this.currentMatchIndex = getIndex(this.currentMatchIndex + relativeIndex, this.matches)
    this.currentMatch = this.matches[this.currentMatchIndex]
    this.emitter.emit("did-change-current-match")
  }

  visit(relativeIndex) {
    if (relativeIndex != null) {
      this.lastRelativeIndex = relativeIndex
    } else {
      relativeIndex = this.lastRelativeIndex != null ? this.lastRelativeIndex : +1
    }

    if (!this.matches.length) return

    const oldDecoration = this.decoationByRange[this.currentMatch.toString()]
    this.updateCurrentMatch(relativeIndex)
    const newDecoration = this.decoationByRange[this.currentMatch.toString()]
    if (oldDecoration) removeCurrentClassForDecoration(oldDecoration)
    if (newDecoration) addCurrentClassForDecoration(newDecoration)
  }

  getRelativeIndex() {
    return this.currentMatchIndex - this.initialCurrentMatchIndex
  }
}
