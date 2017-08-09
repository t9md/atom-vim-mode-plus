const {Disposable, CompositeDisposable} = require("atom")
const Base = require("./base")
let OperationAbortedError, Select, MoveToRelativeLine

// opration life in operationStack
// 1. run
//    instantiated by new.
//    compliment implicit Operator.Select operator if necessary.
//    push operation to stack.
// 2. process
//    reduce stack by, popping top of stack then set it as target of new top.
//    check if remaining top of stack is executable by calling isComplete()
//    if executable, then pop stack then execute(poppedOperation)
//    if not executable, enter "operator-pending-mode"
module.exports = class OperationStack {
  get mode() {
    return this.modeManager.mode
  }
  get submode() {
    return this.modeManager.submode
  }

  constructor(vimState) {
    this.vimState = vimState
    this.editor = vimState.editor
    this.editorElement = vimState.editorElement
    this.modeManager = vimState.modeManager
    this.swrap = vimState.swrap

    this.vimState.onDidDestroy(() => this.destroy())

    this.reset()
  }

  // Return handler
  subscribe(handler) {
    this.operationSubscriptions.add(handler)
    return handler // DONT REMOVE
  }

  reset() {
    this.resetCount()
    this.stack = []
    this.processing = false

    // this has to be BEFORE this.operationSubscriptions.dispose()
    this.vimState.emitDidResetOperationStack()

    if (this.operationSubscriptions) this.operationSubscriptions.dispose()
    this.operationSubscriptions = new CompositeDisposable()
  }

  destroy() {
    if (this.operationSubscriptions) this.operationSubscriptions.dispose()
    this.stack = this.operationSubscriptions = null
  }

  peekTop() {
    return this.stack[this.stack.length - 1]
  }

  isEmpty() {
    return this.stack.length === 0
  }

  newMoveToRelativeLine() {
    if (!MoveToRelativeLine) MoveToRelativeLine = Base.getClass("MoveToRelativeLine")
    return new MoveToRelativeLine(this.vimState)
  }

  newSelectWithTarget(target) {
    if (!Select) Select = Base.getClass("Select")
    return new Select(this.vimState).setTarget(target)
  }

  // Main
  // -------------------------
  run(klass, properties) {
    if (this.mode === "visual") {
      for (const $selection of this.swrap.getSelections(this.editor)) {
        if (!$selection.hasProperties()) $selection.saveProperties()
      }
    }

    try {
      if (this.isEmpty()) this.vimState.init()
      const type = typeof klass

      let operation
      if (type === "object") {
        // . repeat case we can execute as-it-is.
        operation = klass
      } else {
        if (type === "string") klass = Base.getClass(klass)

        const stackTop = this.peekTop()
        if (stackTop && stackTop.constructor === klass) {
          // Replace operator when identical one repeated, e.g. `dd`, `cc`, `gUgU`
          operation = this.newMoveToRelativeLine()
        } else {
          operation = new klass(this.vimState, properties)
        }
      }

      if (this.isEmpty()) {
        if ((this.mode === "visual" && operation.isMotion()) || operation.isTextObject()) {
          operation = this.newSelectWithTarget(operation)
        }
        this.stack.push(operation)
        this.process()
      } else if (this.peekTop().isOperator() && (operation.isMotion() || operation.isTextObject())) {
        this.stack.push(operation)
        this.process()
      } else {
        this.vimState.emitDidFailToPushToOperationStack()
        this.vimState.resetNormalMode()
      }
    } catch (error) {
      this.handleError(error)
    }
  }

  runRecorded() {
    if (!this.recordedOperation) return

    const operation = this.recordedOperation
    operation.repeated = true
    if (this.hasCount()) {
      const count = this.getCount()
      operation.count = count

      // Why gurad? some opeartor have no target like ctrl-a(increase).
      if (operation.target) operation.target.count = count
    }

    operation.subscribeResetOccurrencePatternIfNeeded()
    this.run(operation)
  }

  runRecordedMotion(key, {reverse} = {}) {
    const recoded = this.vimState.globalState.get(key)
    if (!recoded) return

    const operation = recoded.clone(this.vimState)
    operation.repeated = true
    operation.resetCount()
    if (reverse) operation.backwards = !operation.backwards
    this.run(operation)
  }

  runCurrentFind(options) {
    this.runRecordedMotion("currentFind", options)
  }

  runCurrentSearch(options) {
    this.runRecordedMotion("currentSearch", options)
  }

  handleError(error) {
    this.vimState.reset()
    if (!OperationAbortedError) OperationAbortedError = require("./errors")
    if (!(error instanceof OperationAbortedError)) throw error
  }

  isProcessing() {
    return this.processing
  }

  process() {
    this.processing = true
    if (this.stack.length === 2) {
      // [FIXME ideally]
      // If target is not complete, we postpone composing target with operator to keep situation simple.
      // So that we can assume when target is set to operator it's complete.
      // e.g. `y s t a'(surround for range from here to till a)
      if (!this.peekTop().isComplete()) return

      const operation = this.stack.pop()
      this.peekTop().setTarget(operation)
    }

    const top = this.peekTop()

    if (!top.isComplete()) {
      if (this.mode === "normal" && top.isOperator()) {
        this.modeManager.activate("operator-pending")
      }
      this.addOperatorSpecificPendingScope(top)
    } else {
      this.execute(this.stack.pop())
    }
  }

  addOperatorSpecificPendingScope(operation) {
    // Temporary set while command is running
    const commandName =
      typeof operation.constructor.getCommandNameWithoutPrefix === "function"
        ? operation.constructor.getCommandNameWithoutPrefix()
        : undefined
    if (commandName) {
      this.addToClassList(commandName + "-pending")
    }
  }

  execute(operation) {
    // Intentionally avoild wrapping by Promise.resolve() to make test easy.
    // Since almost all command don't return promise, finish synchronously.
    const execution = operation.execute()
    if (execution instanceof Promise) {
      execution.then(() => this.finish(operation)).catch(() => this.handleError())
    } else {
      this.finish(operation)
    }
  }

  cancel() {
    if (!["visual", "insert"].includes(this.mode)) {
      this.vimState.resetNormalMode()
      this.vimState.restoreOriginalCursorPosition()
    }
    this.finish()
  }

  finish(operation) {
    if (operation && operation.recordable) this.recordedOperation = operation

    this.vimState.emitDidFinishOperation()
    if (operation && operation.isOperator()) operation.resetState()

    if (this.mode === "normal") {
      this.ensureAllSelectionsAreEmpty(operation)
      this.ensureAllCursorsAreNotAtEndOfLine()
    } else if (this.mode === "visual") {
      this.modeManager.updateNarrowedState()
      this.vimState.updatePreviousSelection()
    }

    this.vimState.cursorStyleManager.refresh()
    this.vimState.reset()
  }

  ensureAllSelectionsAreEmpty(operation) {
    // When @vimState.selectBlockwise() is called in non-visual-mode.
    // e.g. `.` repeat of operation targeted blockwise `CurrentSelection`.
    // We need to manually clear blockwiseSelection.
    // See #647
    this.vimState.clearBlockwiseSelections() // FIXME, should be removed
    if (this.vimState.haveSomeNonEmptySelection()) {
      if (this.vimState.getConfig("strictAssertion")) {
        const message = `Have some non-empty selection in normal-mode: ${operation.toString()}`
        this.vimState.utils.assertWithException(false, message)
      }
      this.vimState.clearSelections()
    }
  }

  ensureAllCursorsAreNotAtEndOfLine() {
    this.editor
      .getCursors()
      .filter(cursor => cursor.isAtEndOfLine())
      .map(cursor => this.vimState.utils.moveCursorLeft(cursor, {preserveGoalColumn: true}))
  }

  addToClassList(className) {
    this.editorElement.classList.add(className)
    this.subscribe(new Disposable(() => this.editorElement.classList.remove(className)))
  }

  // Count
  // -------------------------
  // keystroke `3d2w` delete 6(3*2) words.
  //  2nd number(2 in this case) is always enterd in operator-pending-mode.
  //  So count have two timing to be entered. that's why here we manage counter by mode.
  hasCount() {
    return this.count["normal"] != null || this.count["operator-pending"] != null
  }

  getCount() {
    if (this.hasCount()) {
      return (
        (this.count["normal"] != null ? this.count["normal"] : 1) *
        (this.count["operator-pending"] != null ? this.count["operator-pending"] : 1)
      )
    } else {
      return null
    }
  }

  setCount(number) {
    const mode = this.mode === "operator-pending" ? this.mode : "normal"
    if (this.count[mode] == null) this.count[mode] = 0
    this.count[mode] = this.count[mode] * 10 + number
    this.vimState.hover.set(this.buildCountString())
    this.editorElement.classList.toggle("with-count", true)
  }

  buildCountString() {
    return [this.count["normal"], this.count["operator-pending"]].filter(n => n != null).join("x")
  }

  resetCount() {
    this.count = {}
    this.editorElement.classList.remove("with-count")
  }
}
