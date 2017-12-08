const {CompositeDisposable, Disposable} = require("atom")

module.exports = function readChar(vimState, {onCancel, onConfirm}) {
  const disposables = new CompositeDisposable(
    vimState.onDidFailToPushToOperationStack(() => {
      disposables.dispose()
      onCancel()
    }),
    swapClassName(vimState, "vim-mode-plus-input-char-waiting", "is-focused"),
    vimState.onDidSetInputChar(char => {
      disposables.dispose()
      onConfirm(char)
    }),
    atom.commands.add(vimState.editorElement, {
      "core:cancel": event => {
        event.stopImmediatePropagation()
        disposables.dispose()
        onCancel()
      },
    })
  )
}

// Other
// -------------------------
// FIXME: I want to remove this dengerious approach, but I couldn't find the better way.
function swapClassName(vimState, ...classNames) {
  const oldMode = vimState.mode
  vimState.editorElement.classList.remove("vim-mode-plus", oldMode + "-mode")
  vimState.editorElement.classList.add(...classNames)

  return new Disposable(() => {
    vimState.editorElement.classList.remove(...classNames)
    const classToAdd = ["vim-mode-plus", "is-focused"]
    if (vimState.mode === oldMode) classToAdd.push(oldMode + "-mode")
    vimState.editorElement.classList.add(...classToAdd)
  })
}
