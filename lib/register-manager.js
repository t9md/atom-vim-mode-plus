const {normalizeIndent} = require("./utils")

const REGISTERS_REGEX = /[a-zA-Z*+%_".]/

// TODO: Vim support following registers.
// x: complete, -: partially
//  [x] 1. The unnamed register ""
//  [ ] 2. 10 numbered registers "0 to "9
//  [ ] 3. The small delete register "-
//  [x] 4. 26 named registers "a to "z or "A to "Z
//  [-] 5. three read-only registers ":, "., "%
//  [ ] 6. alternate buffer register "#
//  [ ] 7. the expression register "=
//  [ ] 8. The selection and drop registers "*, "+ and "~
//  [x] 9. The black hole register "_
//  [ ] 10. Last search pattern register "/

module.exports = class RegisterManager {
  constructor(vimState) {
    this.vimState = vimState
    this.editorElement = vimState.editorElement

    this.data = this.vimState.globalState.get("register")
    this.subscriptionBySelection = new Map()
    this.clipboardBySelection = new Map()
    this.historyIndex = 0

    this.vimState.onDidDestroy(() => this.destroy())
  }

  get history() {
    return this.vimState.globalState.get("clipboardHistory")
  }

  set history(value) {
    return this.vimState.globalState.set("clipboardHistory", value)
  }

  reset() {
    this.name = null
    this.editorElement.classList.toggle("with-register", false)
  }

  destroy() {
    this.subscriptionBySelection.forEach(disposable => disposable.dispose())
    this.subscriptionBySelection.clear()
    this.clipboardBySelection.clear()
  }

  isValidName(name) {
    return REGISTERS_REGEX.test(name)
  }

  getText(name, selection) {
    const value = this.get(name, selection)
    return value && value.text != null ? value.text : ""
  }

  readClipboard(selection) {
    if (selection && selection.editor.hasMultipleCursors() && this.clipboardBySelection.has(selection)) {
      return this.clipboardBySelection.get(selection)
    } else {
      return atom.clipboard.read()
    }
  }

  writeClipboard(selection, text) {
    if (selection && selection.editor.hasMultipleCursors() && !this.clipboardBySelection.has(selection)) {
      this.subscriptionBySelection.set(
        selection,
        selection.onDidDestroy(() => {
          this.subscriptionBySelection.delete(selection)
          this.clipboardBySelection.delete(selection)
        })
      )
    }

    if (!selection || selection.isLastSelection()) {
      atom.clipboard.write(text)
    }

    if (selection) {
      this.clipboardBySelection.set(selection, text)
    }
  }

  getNextHistory() {
    this.historyIndex = (this.historyIndex + 1) % this.history.length
    return this.history[this.historyIndex]
  }

  saveHistory(value) {
    this.history.unshift(value)

    // Uniq
    this.history = this.history.reduce((total, current) => {
      return total.some(member => member.value === current.value && member.text === current.text)
        ? total
        : total.concat(current)
    }, [])

    this.history.splice(this.vimState.getConfig("sequentialPasteMaxHistory"))
  }

  get(name, selection, fromHistory) {
    let text, type
    if (name != null && !this.isValidName(name)) return null

    name = name || this.name || '"'
    const wasUnnamed = name === '"'

    // FIXME: This get function is not pure have side-effect when wasUnnamed
    if (wasUnnamed) {
      if (fromHistory) {
        if (!this.history.length && this.vimState.getConfig("useClipboardAsDefaultRegister")) {
          const text = atom.clipboard.read()
          this.saveHistory({text: text, type: this.getCopyType(text)})
        }

        const {text, type} = this.getNextHistory()
        return {
          text: normalizeIndent(text, selection.editor, selection.getBufferRange()),
          type: type,
        }
      } else {
        this.historyIndex = 0
      }
    }

    if (wasUnnamed && this.vimState.getConfig("useClipboardAsDefaultRegister")) name = "*"

    const buildValue = ({text, type = this.getCopyType(text)} = {}) => {
      return {text, type}
    }

    // There is no diff between "*" and "+"(pure vim distinguish it only if X11 systems, but vmp not).
    switch (name) {
      case "*":
      case "+":
        return buildValue({text: this.readClipboard(selection)})
      case "%":
        return buildValue({text: this.vimState.editor.getURI()})
      case "_":
        return buildValue({text: ""}) // Blackhole always returns nothing
      default:
        return buildValue(this.data[name.toLowerCase()])
    }
  }

  // Private: Sets the value of a given register.
  //
  // name  - The name of the register to fetch.
  // value - The value to set the register to, with following properties.
  //  text: text to save to register.
  //  type: (optional) if ommited automatically set from text.
  //
  // Returns nothing.
  set(name, value) {
    if (name != null && !this.isValidName(name)) return null
    name = name || this.name || '"'

    const wasUnnamed = name === '"'
    if (wasUnnamed && this.vimState.getConfig("useClipboardAsDefaultRegister")) name = "*"

    if (!value.type) value.type = this.getCopyType(value.text)

    const {selection} = value
    delete value.selection

    if (["_", "%"].includes(name)) {
      return
    }

    if (wasUnnamed && this.vimState.getConfig("sequentialPaste")) {
      this.saveHistory(value)
    }

    if (["*", "+"].includes(name)) {
      this.writeClipboard(selection, value.text)
      return
    }

    if (/^[A-Z]$/.test(name)) {
      name = name.toLowerCase()
      if (this.data[name] != null) {
        this.append(name, value)
        return
      }
    }
    this.data[name] = value
  }

  append(name, value) {
    const register = this.data[name]
    if (register.type === "linewise" || value.type === "linewise") {
      if (register.type !== "linewise") {
        register.type = "linewise"
        register.text += "\n"
      }
      if (value.type !== "linewise") {
        value.text += "\n"
      }
    }
    register.text += value.text
  }

  setName(name) {
    if (name != null) {
      this.name = name
      this.editorElement.classList.toggle("with-register", true)
      this.vimState.hover.set(`"${this.name}`)
    } else {
      this.vimState.readChar({
        onConfirm: name => {
          if (this.isValidName(name)) this.setName(name)
          else this.vimState.hover.reset()
        },
        onCancel: () => this.vimState.hover.reset(),
      })
      this.vimState.hover.set('"')
    }
  }

  getCopyType(text = "") {
    return text.endsWith("\n") || text.endsWith("\r") ? "linewise" : "characterwise"
  }
}
