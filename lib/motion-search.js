const _ = require("underscore-plus")

const {saveEditorState, getNonWordCharactersForCursor, searchByProjectFind} = require("./utils")
const SearchModel = require("./search-model")
const Motion = require("./base").getClass("Motion")

class SearchBase extends Motion {
  static initClass() {
    this.extend(false)
    this.prototype.jump = true
    this.prototype.backwards = false
    this.prototype.useRegexp = true
    this.prototype.caseSensitivityKind = null
    this.prototype.landingPoint = null // ['start' or 'end']
    this.prototype.defaultLandingPoint = "start" // ['start' or 'end']
    this.prototype.relativeIndex = null
    this.prototype.updatelastSearchPattern = true
  }

  isBackwards() {
    return this.backwards
  }

  isIncrementalSearch() {
    return this.instanceof("Search") && !this.repeated && this.getConfig("incrementalSearch")
  }

  constructor(...args) {
    super(...args)
    this.onDidFinishOperation(() => this.finish())
  }

  getCount(...args) {
    return super.getCount(...args) * (this.isBackwards() ? -1 : 1)
  }

  finish() {
    if (this.isIncrementalSearch() && this.getConfig("showHoverSearchCounter")) {
      this.vimState.hoverSearchCounter.reset()
    }
    this.relativeIndex = null
    if (this.searchModel != null) {
      this.searchModel.destroy()
    }
    return (this.searchModel = null)
  }

  getLandingPoint() {
    return this.landingPoint != null ? this.landingPoint : (this.landingPoint = this.defaultLandingPoint)
  }

  getPoint(cursor) {
    let point, range
    if (this.searchModel != null) {
      this.relativeIndex = this.getCount() + this.searchModel.getRelativeIndex()
    } else {
      if (this.relativeIndex == null) {
        this.relativeIndex = this.getCount()
      }
    }

    if ((range = this.search(cursor, this.input, this.relativeIndex))) {
      point = range[this.getLandingPoint()]
    }

    this.searchModel.destroy()
    this.searchModel = null

    return point
  }

  moveCursor(cursor) {
    let point
    const {input} = this
    if (!input) {
      return
    }

    if ((point = this.getPoint(cursor))) {
      cursor.setBufferPosition(point, {autoscroll: false})
    }

    if (!this.repeated) {
      this.globalState.set("currentSearch", this)
      this.vimState.searchHistory.save(input)
    }

    if (this.updatelastSearchPattern) {
      return this.globalState.set("lastSearchPattern", this.getPattern(input))
    }
  }

  getSearchModel() {
    return this.searchModel != null
      ? this.searchModel
      : (this.searchModel = new SearchModel(this.vimState, {incrementalSearch: this.isIncrementalSearch()}))
  }

  search(cursor, input, relativeIndex) {
    const searchModel = this.getSearchModel()
    if (input) {
      const fromPoint = this.getBufferPositionForCursor(cursor)
      return searchModel.search(fromPoint, this.getPattern(input), relativeIndex)
    } else {
      this.vimState.hoverSearchCounter.reset()
      return searchModel.clearMarkers()
    }
  }
}
SearchBase.initClass()

// /, ?
// -------------------------
class Search extends SearchBase {
  constructor(...args) {
    super(...args)

    if (!this.isComplete()) {
      if (this.isIncrementalSearch()) {
        this.restoreEditorState = saveEditorState(this.editor)
        this.onDidCommandSearch(this.handleCommandEvent.bind(this))
      }

      this.onDidConfirmSearch(this.handleConfirmSearch.bind(this))
      this.onDidCancelSearch(this.handleCancelSearch.bind(this))
      this.onDidChangeSearch(this.handleChangeSearch.bind(this))

      this.focusSearchInputEditor()
    }
  }

  static initClass() {
    this.extend()
    this.prototype.caseSensitivityKind = "Search"
    this.prototype.requireInput = true
  }

  focusSearchInputEditor() {
    const classList = []
    if (this.backwards) {
      classList.push("backwards")
    }
    return this.vimState.searchInput.focus({classList})
  }

  handleCommandEvent(commandEvent) {
    if (!commandEvent.input) {
      return
    }
    switch (commandEvent.name) {
      case "visit":
        let {direction} = commandEvent
        if (this.isBackwards() && this.getConfig("incrementalSearchVisitDirection") === "relative") {
          direction = (() => {
            switch (direction) {
              case "next":
                return "prev"
              case "prev":
                return "next"
            }
          })()
        }

        switch (direction) {
          case "next":
            return this.getSearchModel().visit(+1)
          case "prev":
            return this.getSearchModel().visit(-1)
        }
        break

      case "occurrence":
        let {operation, input} = commandEvent
        this.vimState.occurrenceManager.addPattern(this.getPattern(input), {reset: operation != null})
        this.vimState.occurrenceManager.saveLastPattern()

        this.vimState.searchHistory.save(input)
        this.vimState.searchInput.cancel()

        if (operation != null) {
          return this.vimState.operationStack.run(operation)
        }
        break

      case "project-find":
        ;({input} = commandEvent)
        this.vimState.searchHistory.save(input)
        this.vimState.searchInput.cancel()
        return searchByProjectFind(this.editor, input)
    }
  }

  handleCancelSearch() {
    if (!["visual", "insert"].includes(this.mode)) {
      this.vimState.resetNormalMode()
    }
    if (typeof this.restoreEditorState === "function") {
      this.restoreEditorState()
    }
    this.vimState.reset()
    return this.finish()
  }

  isSearchRepeatCharacter(char) {
    if (this.isIncrementalSearch()) {
      return char === ""
    } else {
      const searchChar = this.isBackwards() ? "?" : "/"
      return ["", searchChar].includes(char)
    }
  }

  handleConfirmSearch({input, landingPoint}) {
    this.input = input
    this.landingPoint = landingPoint
    if (this.isSearchRepeatCharacter(this.input)) {
      this.input = this.vimState.searchHistory.get("prev")
      if (!this.input) {
        atom.beep()
      }
    }
    return this.processOperation()
  }

  handleChangeSearch(input) {
    // If input starts with space, remove first space and disable useRegexp.
    if (input.startsWith(" ")) {
      input = input.replace(/^ /, "")
      this.useRegexp = false
    }
    this.vimState.searchInput.updateOptionSettings({useRegexp: this.useRegexp})

    if (this.isIncrementalSearch()) {
      return this.search(this.editor.getLastCursor(), input, this.getCount())
    }
  }

  getPattern(term) {
    let modifiers = this.isCaseSensitive(term) ? "g" : "gi"
    // FIXME this prevent search \\c itself.
    // DONT thinklessly mimic pure Vim. Instead, provide ignorecase button and shortcut.
    if (term.indexOf("\\c") >= 0) {
      term = term.replace("\\c", "")
      if (!modifiers.includes("i")) {
        modifiers += "i"
      }
    }

    if (this.useRegexp) {
      try {
        return new RegExp(term, modifiers)
      } catch (error) {
        null
      }
    }

    return new RegExp(_.escapeRegExp(term), modifiers)
  }
}
Search.initClass()

class SearchBackwards extends Search {
  static initClass() {
    this.extend()
    this.prototype.backwards = true
  }
}
SearchBackwards.initClass()

// *, #
// -------------------------
class SearchCurrentWord extends SearchBase {
  static initClass() {
    this.extend()
    this.prototype.caseSensitivityKind = "SearchCurrentWord"
  }

  moveCursor(cursor) {
    if (this.input == null) {
      let wordRange
      this.input = ((wordRange = this.getCurrentWordBufferRange()),
      (() => {
        if (wordRange != null) {
          this.editor.setCursorBufferPosition(wordRange.start)
          return this.editor.getTextInBufferRange(wordRange)
        } else {
          return ""
        }
      })())
    }
    return super.moveCursor(...arguments)
  }

  getPattern(term) {
    const modifiers = this.isCaseSensitive(term) ? "g" : "gi"
    const pattern = _.escapeRegExp(term)
    if (/\W/.test(term)) {
      return new RegExp(`${pattern}\\b`, modifiers)
    } else {
      return new RegExp(`\\b${pattern}\\b`, modifiers)
    }
  }

  getCurrentWordBufferRange() {
    const cursor = this.editor.getLastCursor()
    const point = cursor.getBufferPosition()

    const nonWordCharacters = getNonWordCharactersForCursor(cursor)
    const wordRegex = new RegExp(`[^\\s${_.escapeRegExp(nonWordCharacters)}]+`, "g")

    let found = null
    this.scanForward(wordRegex, {from: [point.row, 0], allowNextLine: false}, function({range, stop}) {
      if (range.end.isGreaterThan(point)) {
        found = range
        return stop()
      }
    })
    return found
  }
}
SearchCurrentWord.initClass()

class SearchCurrentWordBackwards extends SearchCurrentWord {
  static initClass() {
    this.extend()
    this.prototype.backwards = true
  }
}
SearchCurrentWordBackwards.initClass()
