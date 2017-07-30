const _ = require("underscore-plus")

module.exports = class SearchHistoryManager {
  constructor(vimState) {
    this.vimState = vimState
    this.globalState = vimState.globalState

    this.reset()
    vimState.onDidDestroy(() => this.destroy())
  }

  get(direction) {
    const {limitNumber} = this.vimState.utils

    switch (direction) {
      case "prev":
        this.index = limitNumber(this.index + 1, {max: this.getSize() - 1})
        break
      case "next":
        this.index = limitNumber(this.index - 1, {min: -1})
        break
    }
    const entry = this.globalState.get("searchHistory")[this.index]
    return entry != null ? entry : ""
  }

  save(entry) {
    if (_.isEmpty(entry)) return

    let entries = this.vimState.globalState.get("searchHistory").slice()
    entries.unshift(entry)
    entries = _.uniq(entries)
    if (this.getSize() > this.vimState.getConfig("historySize")) {
      entries.splice(this.vimState.getConfig("historySize"))
    }
    this.globalState.set("searchHistory", entries)
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
