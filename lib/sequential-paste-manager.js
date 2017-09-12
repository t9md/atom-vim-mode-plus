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

  isSequentialPaste(operator) {
    return (
      this.vimState.getConfig("sequentialPaste") && this.vimState.operationStack.getLastCommandName() === operator.name
    )
  }

  onInitialize(operator) {
    if (this.isSequentialPaste(operator)) {
      operator.target = "LastPastedRange"
    } else {
      operator.onDidSetTarget(({target}) => (this.originalTarget = target))
    }
  }

  onExecute(operator) {
    const sequentialPaste = this.isSequentialPaste(operator)

    if (operator.repeated) {
      operator.setTarget(sequentialPaste ? operator.new("LastPastedRange") : this.originalTarget)
    }

    if (sequentialPaste) {
      this.vimState.onDidFinishOperation(() => this.vimState.editor.groupChangesSinceCheckpoint(this.pasteCheckpoint))
    } else {
      this.pastedRangeBySelection.clear()
      const pasteCheckpoint = this.vimState.editor.createCheckpoint()
      this.vimState.onDidFinishOperation(() => (this.pasteCheckpoint = pasteCheckpoint))
    }
    return sequentialPaste
  }
}
