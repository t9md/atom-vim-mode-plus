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
    vimState.onDidFailToPushToOperationStack(() => this.cancel())
    this.emitter = new Emitter()
  }

  destroy() {
    this.vimState = null
  }

  focus({charsMax = 1, hideCursor} = {}) {
    const classNames = ["vim-mode-plus-input-char-waiting", "is-focused"]
    if (hideCursor) classNames.push("hide-cursor")

    const chars = []
    this.disposables = new CompositeDisposable(
      this.vimState.swapClassName(...classNames),
      this.vimState.onDidSetInputChar(char => {
        if (charsMax === 1) {
          this.confirm(char)
        } else {
          chars.push(char)
          const text = chars.join("")
          this.emitter.emit("did-change", text)
          if (chars.length >= charsMax) this.confirm(text)
        }
      }),
      atom.commands.add(this.vimState.editorElement, {
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
