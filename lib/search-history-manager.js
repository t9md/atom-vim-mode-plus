const _ = require("underscore-plus")

module.exports = class SearchHistoryManager {
  constructor(vimState) {
    this.vimState = vimState
    this.globalState = vimState.globalState

    this.reset()
    vimState.onDidDestroy(() => this.destroy())
  }

  get(direction) {
    const index = this.index + (direction === "prev" ? +1 : -1)
    this.index = this.vimState.utils.limitNumber(index, {min: -1, max: this.getSize() - 1})
    return this.globalState.get("searchHistory")[this.index] || ""
  }

  save(entry) {
    if (_.isEmpty(entry)) return

    const entries = this.globalState.get("searchHistory").slice()
    entries.unshift(entry)
    this.globalState.set("searchHistory", _.uniq(entries).splice(this.vimState.getConfig("historySize")))
  }

  reset() {
    this.index = -1
  }

  clear() {
    this.globalState.reset("searchHistory")
  }

  getSize() {
    return this.globalState.get("searchHistory").length
  }

  destroy() {
    this.index = null
  }
}
