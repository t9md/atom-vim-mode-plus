module.exports = function focusInput (
  vimState,
  {charsMax = 1, autoConfirmTimeout, hideCursor, onChange, onCancel, onConfirm, purpose, commands} = {}
) {
  const classListToAdd = ['vim-mode-plus-input-focused']
  if (hideCursor) classListToAdd.push('hide-cursor')
  vimState.editorElement.classList.add(...classListToAdd)

  const editor = atom.workspace.buildTextEditor({mini: true})

  vimState.inputEditor = editor // set ref for test
  editor.element.classList.add('vim-mode-plus-input')
  if (purpose) editor.element.classList.add(purpose)
  editor.element.setAttribute('mini', '')

  // So that I can skip jasmine.attachToDOM in test.
  if (atom.inSpecMode()) atom.workspace.getElement().appendChild(editor.element)
  else vimState.editorElement.parentNode.appendChild(editor.element)

  let autoConfirmTimeoutID
  const clearAutoConfirmTimer = () => {
    if (autoConfirmTimeoutID) clearTimeout(autoConfirmTimeoutID)
    autoConfirmTimeoutID = null
  }

  const unfocus = () => {
    clearAutoConfirmTimer()
    vimState.editorElement.focus() // focus
    vimState.inputEditor = null // unset ref for test
    vimState.editorElement.classList.remove(...classListToAdd)
    editor.element.remove()
    editor.destroy()
  }

  let didChangeTextDisposable

  const confirm = text => {
    if (didChangeTextDisposable) {
      didChangeTextDisposable.dispose()
      didChangeTextDisposable = null
    }
    unfocus()
    onConfirm(text)
  }

  const confirmAfter = (text, timeout) => {
    clearAutoConfirmTimer()
    if (text) autoConfirmTimeoutID = setTimeout(() => confirm(text), timeout)
  }

  const cancel = () => {
    unfocus()
    onCancel()
  }

  vimState.onDidFailToPushToOperationStack(cancel)

  didChangeTextDisposable = editor.buffer.onDidChangeText(() => {
    const text = editor.getText()
    editor.element.classList.toggle('has-text', text.length)
    if (text.length >= charsMax) {
      confirm(text)
    } else {
      if (onChange) onChange(text)
      if (autoConfirmTimeout) confirmAfter(text, autoConfirmTimeout)
    }
  })

  atom.commands.add(editor.element, {
    'core:cancel': event => {
      event.stopImmediatePropagation()
      cancel()
    },
    'core:confirm': event => {
      event.stopImmediatePropagation()
      confirm(editor.getText())
    }
  })
  if (commands) {
    const wrappedCommands = {}
    for (const name of Object.keys(commands)) {
      wrappedCommands[name] = function (event) {
        commands[name].call(editor.element, event)
        if (autoConfirmTimeout) {
          confirmAfter(editor.getText(), autoConfirmTimeout)
        }
      }
    }
    atom.commands.add(editor.element, wrappedCommands)
  }

  editor.element.focus()
}
