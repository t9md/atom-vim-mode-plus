const {Emitter} = require("atom")

class GlobalState {
  constructor(state) {
    this.state = state
    this.emitter = new Emitter()

    this.onDidChange(({name, newValue}) => {
      // auto sync value, but highlightSearchPattern is solely cleared to clear hlsearch.
      if (name === "lastSearchPattern") {
        this.set("highlightSearchPattern", newValue)
      }
    })
  }

  get(name) {
    return this.state[name]
  }

  set(name, newValue) {
    const oldValue = this.get(name)
    this.state[name] = newValue
    this.emitDidChange({name, oldValue, newValue})
  }

  onDidChange(fn) {
    return this.emitter.on("did-change", fn)
  }

  emitDidChange(event) {
    this.emitter.emit("did-change", event)
  }

  reset(name) {
    const initialState = getInitialState()
    if (name != null) {
      this.set(name, initialState[name])
    } else {
      this.state = initialState
    }
  }
}

function getInitialState() {
  return {
    searchHistory: [],
    currentSearch: null,
    lastSearchPattern: null,
    lastOccurrencePattern: null,
    lastOccurrenceType: null,
    highlightSearchPattern: null,
    currentFind: null,
    register: {},
    demoModeIsActive: false,
  }
}

module.exports = new GlobalState(getInitialState())
