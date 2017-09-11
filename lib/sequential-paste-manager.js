const {normalizeIndent} = require("./utils")

module.exports = class SequentialPasteManager {
  constructor(vimState) {
    this.vimState = vimState
    vimState.onDidDestroy(() => this.destroy())

    this.pastedRangeBySelection = new Map()
  }

  destroy() {
    this.pastedRangeBySelection.clear()
  }

  savePastedRangeForSelection(selection, range) {
    this.pastedRangeBySelection.set(selection, range)
  }

  getPastedRangeForSelection(selection) {
    return this.pastedRangeBySelection.get(selection)
  }

  isSequentialPaste(operation) {
    return (
      this.vimState.getConfig("enableSequentialPaste") &&
      this.vimState.operationStack.getLastCommandName() === operation.name &&
      this.vimState.flashManager.hasMarkers()
    )
  }

  start(sequentialPaste) {
    const editor = this.vimState.editor
    if (sequentialPaste) {
      this.vimState.onDidFinishOperation(() => editor.groupChangesSinceCheckpoint(this.pasteCheckpoint))
    } else {
      const pasteCheckpoint = editor.createCheckpoint()
      this.pastedRangeBySelection.clear()
      this.vimState.onDidFinishOperation(() => (this.pasteCheckpoint = pasteCheckpoint))
    }
  }

  getRegister(selection) {
    const {text, type} = this.vimState.register.getHistory()
    return {
      text: normalizeIndent(text, selection.editor, selection.getBufferRange()),
      type: type,
    }
  }
}
