module.exports = class SearchHistoryManager {
  constructor (vimState) {
    this.vimState = vimState
    this.globalState = vimState.globalState

    this.reset()
    vimState.onDidDestroy(() => this.destroy())
  }

  get (direction) {
    const index = this.index + (direction === 'prev' ? +1 : -1)
    this.index = this.vimState.utils.limitNumber(index, {min: -1, max: this.getSize() - 1})
    return this.globalState.get('searchHistory')[this.index] || ''
  }

  save (entry) {
    if (!entry) return
    const entries = this.globalState.get('searchHistory').slice()
    entries.unshift(entry)
    const maxHistorySize = this.vimState.getConfig('historySize')
    this.globalState.set('searchHistory', this.vimState._.uniq(entries).splice(maxHistorySize))
  }

  reset () {
    this.index = -1
  }

  clear () {
    this.globalState.reset('searchHistory')
  }

  getSize () {
    return this.globalState.get('searchHistory').length
  }

  destroy () {
    this.index = null
  }
}
