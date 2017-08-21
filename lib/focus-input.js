module.exports = function focusInput(vimState, {charsMax = 1, hideCursor, onChange, onCancel, onConfirm} = {}) {
  vimState.editorElement.classList.add("vim-mode-plus-input-focused")
  if (hideCursor) vimState.editorElement.classList.add("hide-cursor")

  const editor = atom.workspace.buildTextEditor({mini: true})

  vimState.inputEditor = editor // set ref for test
  editor.element.classList.add("vim-mode-plus-input")
  editor.element.setAttribute("mini", "")

  if (atom.inSpecMode()) atom.workspace.getElement().appendChild(editor.element) // I can skip jasmine.attachToDOM.
  else vimState.editorElement.parentNode.appendChild(editor.element)

  const unfocus = () => {
    vimState.editorElement.focus() // focus
    vimState.inputEditor = null // unset ref for test
    vimState.editorElement.classList.remove("vim-mode-plus-input-focused", "hide-cursor")
    editor.element.remove()
    editor.destroy()
  }

  const confirm = text => {
    unfocus()
    onConfirm(text)
  }
  const cancel = () => {
    unfocus()
    onCancel()
  }

  vimState.onDidFailToPushToOperationStack(cancel)

  if (charsMax === 1) editor.onDidChange(() => confirm(editor.getText()))
  else if (onChange) editor.onDidChange(() => onChange(editor.getText()))

  atom.commands.add(editor.element, {
    "core:cancel": event => {
      event.stopImmediatePropagation()
      cancel()
    },
    "core:confirm": event => {
      event.stopImmediatePropagation()
      confirm(editor.getText())
    },
  })
  editor.element.focus()
}
