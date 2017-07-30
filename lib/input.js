const {Emitter, CompositeDisposable} = require("atom")

module.exports = class Input {
  onDidChange(fn) {
    return this.emitter.on("did-change", fn)
  }
  onDidConfirm(fn) {
    return this.emitter.on("did-confirm", fn)
  }
  onDidCancel(fn) {
    return this.emitter.on("did-cancel", fn)
  }

  constructor(vimState) {
    this.vimState = vimState
    this.editorElement = vimState.editorElement
    this.vimState.onDidFailToPushToOperationStack(() => this.cancel())
    this.emitter = new Emitter()
  }

  destroy() {
    this.vimState = null
  }

  focus({charsMax = 1, hideCursor} = {}) {
    const chars = []

    this.disposables = new CompositeDisposable()
    const classNames = ["vim-mode-plus-input-char-waiting", "is-focused"]
    if (hideCursor) classNames.push("hide-cursor")

    this.disposables.add(this.vimState.swapClassName(...classNames))
    this.disposables.add(
      this.vimState.onDidSetInputChar(char => {
        if (charsMax === 1) {
          this.confirm(char)
        } else {
          chars.push(char)
          const text = chars.join("")
          this.emitter.emit("did-change", text)
          if (chars.length >= charsMax) this.confirm(text)
        }
      })
    )

    this.disposables.add(
      atom.commands.add(this.editorElement, {
        "core:cancel": event => {
          event.stopImmediatePropagation()
          this.cancel()
        },
        "core:confirm": event => {
          event.stopImmediatePropagation()
          this.confirm(chars.join(""))
        },
      })
    )
  }

  confirm(char) {
    if (this.disposables) this.disposables.dispose()
    this.emitter.emit("did-confirm", char)
  }

  cancel() {
    if (this.disposables) this.disposables.dispose()
    this.emitter.emit("did-cancel")
  }
}
