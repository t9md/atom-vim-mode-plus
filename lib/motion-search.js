'use babel'

const SearchModel = require('./search-model')
const {Motion} = require('./motion')

class SearchBase extends Motion {
  static command = false
  jump = true
  backwards = false
  useRegexp = true
  landingPoint = null // ['start' or 'end']
  defaultLandingPoint = 'start' // ['start' or 'end']
  relativeIndex = null
  updatelastSearchPattern = true

  isBackwards () {
    return this.backwards
  }

  resetState () {
    super.resetState()
    this.relativeIndex = null
  }

  isIncrementalSearch () {
    return this.instanceof('Search') && !this.repeated && this.getConfig('incrementalSearch')
  }

  initialize () {
    this.onDidFinishOperation(() => this.finish())
    super.initialize()
  }

  getCount () {
    return super.getCount() * (this.isBackwards() ? -1 : 1)
  }

  finish () {
    if (this.isIncrementalSearch() && this.getConfig('showHoverSearchCounter')) {
      this.vimState.hoverSearchCounter.reset()
    }
    if (this.searchModel) this.searchModel.destroy()

    this.relativeIndex = null
    this.searchModel = null
  }

  getLandingPoint () {
    if (!this.landingPoint) this.landingPoint = this.defaultLandingPoint
    return this.landingPoint
  }

  getPoint (cursor) {
    if (this.searchModel) {
      this.relativeIndex = this.getCount() + this.searchModel.getRelativeIndex()
    } else if (this.relativeIndex == null) {
      this.relativeIndex = this.getCount()
    }

    const range = this.search(cursor, this.input, this.relativeIndex)

    this.searchModel.destroy()
    this.searchModel = null

    if (range) return range[this.getLandingPoint()]
  }

  moveCursor (cursor) {
    if (!this.input) return
    const point = this.getPoint(cursor)

    if (point) {
      if (this.restoreEditorState) {
        this.restoreEditorState({anchorPosition: point, skipRow: point.row})
        this.restoreEditorState = null // HACK: dont refold on `n`, `N` repeat
      }
      cursor.setBufferPosition(point, {autoscroll: false})
    }

    if (!this.repeated) {
      this.globalState.set('currentSearch', this)
      this.vimState.searchHistory.save(this.input)
    }

    if (this.updatelastSearchPattern) {
      this.globalState.set('lastSearchPattern', this.getPattern(this.input))
    }
  }

  getSearchModel () {
    if (!this.searchModel) {
      this.searchModel = new SearchModel(this.vimState, {incrementalSearch: this.isIncrementalSearch()})
    }
    return this.searchModel
  }

  search (cursor, input, relativeIndex) {
    const searchModel = this.getSearchModel()
    if (input) {
      const fromPoint = this.getBufferPositionForCursor(cursor)
      return searchModel.search(fromPoint, this.getPattern(input), relativeIndex)
    }
    this.vimState.hoverSearchCounter.reset()
    searchModel.clearMarkers()
  }
}

// /, ?
// -------------------------
class Search extends SearchBase {
  caseSensitivityKind = 'Search'
  requireInput = true

  initialize () {
    if (this.isIncrementalSearch()) {
      this.restoreEditorState = this.utils.saveEditorState(this.editor)
      this.onDidCommandSearch(this.handleCommandEvent.bind(this))
    }

    this.onDidConfirmSearch(this.handleConfirmSearch.bind(this))
    this.onDidCancelSearch(this.handleCancelSearch.bind(this))
    this.onDidChangeSearch(this.handleChangeSearch.bind(this))

    this.focusSearchInputEditor()

    super.initialize()
  }

  focusSearchInputEditor () {
    const classList = this.isBackwards() ? ['backwards'] : []
    this.vimState.searchInput.focus({classList})
  }

  handleCommandEvent (event) {
    if (!event.input) return

    if (event.name === 'visit') {
      let {direction} = event
      if (this.isBackwards() && this.getConfig('incrementalSearchVisitDirection') === 'relative') {
        direction = direction === 'next' ? 'prev' : 'next'
      }
      this.getSearchModel().visit(direction === 'next' ? +1 : -1)
    } else if (event.name === 'occurrence') {
      const {operation, input} = event
      this.occurrenceManager.addPattern(this.getPattern(input), {reset: operation != null})
      this.occurrenceManager.saveLastPattern()

      this.vimState.searchHistory.save(input)
      this.vimState.searchInput.cancel()
      if (operation != null) this.vimState.operationStack.run(operation)
    } else if (event.name === 'project-find') {
      this.vimState.searchHistory.save(event.input)
      this.vimState.searchInput.cancel()
      this.utils.searchByProjectFind(this.editor, event.input)
    }
  }

  handleCancelSearch () {
    if (!['visual', 'insert'].includes(this.mode)) this.vimState.resetNormalMode()

    if (this.restoreEditorState) this.restoreEditorState()
    this.vimState.reset()
    this.finish()
  }

  isSearchRepeatCharacter (char) {
    return this.isIncrementalSearch() ? char === '' : ['', this.isBackwards() ? '?' : '/'].includes(char) // empty confirm or invoking-char
  }

  handleConfirmSearch ({input, landingPoint}) {
    this.input = input
    this.landingPoint = landingPoint
    if (this.isSearchRepeatCharacter(this.input)) {
      this.input = this.vimState.searchHistory.get('prev')
      if (!this.input) atom.beep()
    }
    this.processOperation()
  }

  handleChangeSearch (input) {
    // If input starts with space, remove first space and disable useRegexp.
    if (input.startsWith(' ')) {
      // FIXME: Sould I remove this unknown hack and implement visible button to togle regexp?
      input = input.replace(/^ /, '')
      this.useRegexp = false
    }
    this.vimState.searchInput.updateOptionSettings({useRegexp: this.useRegexp})

    if (this.isIncrementalSearch()) {
      this.search(this.editor.getLastCursor(), input, this.getCount())
    }
  }

  getPattern (term) {
    let modifiers = this.isCaseSensitive(term) ? 'g' : 'gi'
    // FIXME this prevent search \\c itself.
    // DONT thinklessly mimic pure Vim. Instead, provide ignorecase button and shortcut.
    if (term.indexOf('\\c') >= 0) {
      term = term.replace('\\c', '')
      if (!modifiers.includes('i')) modifiers += 'i'
    }

    if (this.useRegexp) {
      try {
        return new RegExp(term, modifiers)
      } catch (error) {}
    }
    return new RegExp(this._.escapeRegExp(term), modifiers)
  }
}

class SearchBackwards extends Search {
  backwards = true
}

// *, #
// -------------------------
class SearchCurrentWord extends SearchBase {
  caseSensitivityKind = 'SearchCurrentWord'

  moveCursor (cursor) {
    if (this.input == null) {
      const wordRange = this.getCurrentWordBufferRange()
      if (wordRange) {
        this.editor.setCursorBufferPosition(wordRange.start)
        this.input = this.editor.getTextInBufferRange(wordRange)
      } else {
        this.input = ''
      }
    }

    super.moveCursor(cursor)
  }

  getPattern (term) {
    const escaped = this._.escapeRegExp(term)
    const source = /\W/.test(term) ? `${escaped}\\b` : `\\b${escaped}\\b`
    return new RegExp(source, this.isCaseSensitive(term) ? 'g' : 'gi')
  }

  getCurrentWordBufferRange () {
    const cursor = this.editor.getLastCursor()
    const point = cursor.getBufferPosition()

    const nonWordCharacters = this.utils.getNonWordCharactersForCursor(cursor)
    const regex = new RegExp(`[^\\s${this._.escapeRegExp(nonWordCharacters)}]+`, 'g')
    const options = {from: [point.row, 0], allowNextLine: false}
    return this.findInEditor('forward', regex, options, ({range}) => range.end.isGreaterThan(point) && range)
  }
}

class SearchCurrentWordBackwards extends SearchCurrentWord {
  backwards = true
}

module.exports = {
  SearchBase,
  Search,
  SearchBackwards,
  SearchCurrentWord,
  SearchCurrentWordBackwards
}
