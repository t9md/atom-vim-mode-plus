const settings = require("./settings")

const LongModeStringTable = {
  normal: "Normal",
  "operator-pending": "Operator Pending",
  "visual.characterwise": "Visual Characterwise",
  "visual.blockwise": "Visual Blockwise",
  "visual.linewise": "Visual Linewise",
  insert: "Insert",
  "insert.replace": "Insert Replace",
}

const ScopePrefix = "status-bar-vim-mode-plus"

module.exports = class StatusBarManager {
  constructor() {
    this.container = document.createElement("div")
    this.container.id = `${ScopePrefix}-container`
    this.container.className = "inline-block"

    this.element = document.createElement("div")
    this.container.id = ScopePrefix
    this.container.appendChild(this.element)
  }

  initialize(statusBar) {
    this.statusBar = statusBar
  }

  clear() {
    this.element.className = ""
    this.element.textContent = ""
  }

  update(mode, submode) {
    const {element} = this
    element.className = `${ScopePrefix}-${mode}`
    switch (settings.get("statusBarModeStringStyle")) {
      case "short":
        element.textContent = (mode[0] + (submode ? submode[0] : "")).toUpperCase()
        return
      case "long":
        element.textContent = LongModeStringTable[mode + (submode ? `.${submode}` : "")]
        return
    }
  }

  attach() {
    this.tile = this.statusBar.addRightTile({item: this.container, priority: 20})
  }

  detach() {
    this.tile.destroy()
  }
}
