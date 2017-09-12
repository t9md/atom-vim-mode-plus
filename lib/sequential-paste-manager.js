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
      this.vimState.getConfig("sequentialPaste") &&
      this.vimState.operationStack.getLastCommandName() === operation.name
    )
  }

  startSequentialPaste(operation) {
    if (operation.repeated) {
      operation.setTarget(operation.new("LastPastedRange"))
    }
    this.vimState.onDidFinishOperation(() => this.vimState.editor.groupChangesSinceCheckpoint(this.pasteCheckpoint))
  }

  startNormalPaste(operation) {
    this.pastedRangeBySelection.clear()
    if (operation.repeated) {
      operation.setTarget(this.originalTarget)
    } else {
      this.originalTarget = operation.target
    }

    const pasteCheckpoint = this.vimState.editor.createCheckpoint()
    this.vimState.onDidFinishOperation(() => (this.pasteCheckpoint = pasteCheckpoint))
  }

  start(operation) {
    if (operation.sequentialPaste) {
      this.startSequentialPaste(operation)
    } else {
      this.startNormalPaste(operation)
    }
  }
}
