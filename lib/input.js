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

    // vimState.onDidDestroy(() => this.destroy())

    const editor = atom.workspace.buildTextEditor({mini: true})
    this.editor = editor
    editor.element.classList.add("vim-mode-plus-input")
    editor.element.setAttribute("mini", "")
    atom.workspace.getElement().appendChild(editor.element)

    this.ignoreChange = false
    editor.onDidChange(() => {
      if (this.ignoreChange) return

      if (this.charsMax === 1) {
        this.confirm(editor.getText())
        return
      }
      this.emitter.emit("did-change", editor.getText())
    })

    atom.commands.add(editor.element, {
      "core:cancel": event => {
        event.stopImmediatePropagation()
        this.cancel()
      },
      "core:confirm": event => {
        event.stopImmediatePropagation()
        this.confirm(editor.getText())
      },
    })
  }

  unfocus() {
    this.ignoreChange = true
    this.editor.setText("")
    this.ignoreChange = false

    // Re-focus client main-editor ONLY when this editor has focus.
    // Since next input-b can be focused before previous input-a unfocused.
    // This is essentially for suppport ChangeSurround.
    this.vimState.editorElement.focus()
    this.vimState.inputEditor = null

    this.vimState.editorElement.classList.remove("vim-mode-plus-input-focused", "hide-cursor")
    this.editor.element.remove()
    this.editor.destroy()
  }

  focus({charsMax = 1, onChange, onCancel, onConfirm, hideCursor} = {}) {
    this.vimState.inputEditor = this.editor // for test
    this.vimState.editorElement.classList.add("vim-mode-plus-input-focused")
    if (hideCursor) {
      this.vimState.editorElement.classList.add("hide-cursor")
    }

    this.charsMax = charsMax
    this.focusDisposable = new CompositeDisposable(
      ...[
        onChange && this.onDidChange(onChange),
        onConfirm && this.onDidConfirm(onConfirm),
        onCancel && this.onDidCancel(onCancel),
      ].filter(v => v)
    )
    this.editor.element.focus()
  }

  confirm(text) {
    this.unfocus()
    this.emitter.emit("did-confirm", text)
    this.focusDisposable.dispose()
  }

  cancel() {
    this.unfocus()
    this.emitter.emit("did-cancel")
    this.focusDisposable.dispose()
  }
}
