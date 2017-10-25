const {Emitter} = require("atom")
const VimState = require("./vim-state")

class GlobalState {
  constructor(state) {
    this.state = state
    this.emitter = new Emitter()

    this.onDidChange(({name, newValue}) => {
      if (name === "lastSearchPattern") {
        // auto sync value, but highlightSearchPattern is solely cleared to clear hlsearch.
        this.set("highlightSearchPattern", newValue)
      } else if (name === "highlightSearchPattern") {
        // Refresh highlight based on globalState.highlightSearchPattern changes.
        if (newValue) {
          VimState.forEach(vimState => vimState.highlightSearch.refresh())
        } else {
          // avoid populate prop unnecessarily on vimState.reset on startup
          VimState.forEach(vimState => vimState.__highlightSearch && vimState.highlightSearch.clearMarkers())
        }
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
    clipboardHistory: [],
  }
}

module.exports = new GlobalState(getInitialState())
