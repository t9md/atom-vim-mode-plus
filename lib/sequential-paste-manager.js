const {normalizeIndent} = require("./utils")

module.exports = class SequentialPasteManager {
  constructor(vimState) {
    this.vimState = vimState
    vimState.onDidDestroy(() => this.destroy())

    this.pastedRangesBySelection = new Map()
  }

  destroy() {}

  // setLastPasted
  setLastPastedRangesBySelection(pastedRangesBySelection) {
    this.pastedRangesBySelection = pastedRangesBySelection
  }

  setPastedRangeForSelection(selection, range) {
    this.pastedRangesBySelection.set(selection, range)
  }

  getPastedRangeForSelection(selection) {
    return this.pastedRangesBySelection.get(selection)
  }

  isSequentialPaste(operation) {
    return (
      this.vimState.getConfig("pasteFromHistoryOnSequentialPut") &&
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
      this.pastedRangesBySelection.clear()
      this.vimState.onDidFinishOperation(() => (this.pasteCheckpoint = pasteCheckpoint))
    }
  }

  getRegister(sequentialPaste, selection) {
    if (sequentialPaste) {
      const {text, type} = this.vimState.register.getHistory()
      return {
        text: normalizeIndent(text, selection.editor, selection.getBufferRange()),
        type: type,
      }
    } else {
      this.vimState.register.getHistory() // Just for rotate
      return this.vimState.register.get(null, selection)
    }
  }
}
