const {Disposable, CompositeDisposable} = require('atom')
const Base = require('./base')

// opration life in operationStack
// 1. run
//    instantiated by new.
//    complement implicit Operator.VisualModeSelect operator if necessary.
//    push operation to stack.
// 2. process
//    reduce stack by, popping top of stack then set it as target of new top.
//    check if remaining top of stack is executable by calling isReady()
//    if executable, then pop stack then execute(poppedOperation)
//    if not executable, enter "operator-pending-mode"
module.exports = class OperationStack {
  get mode () { return this.vimState.mode } // prettier-ignore
  get submode () { return this.vimState.submode } // prettier-ignore

  constructor (vimState) {
    this.vimState = vimState
    this.editor = vimState.editor
    this.editorElement = vimState.editorElement
    this.operationToRunNext = null

    this.vimState.onDidDestroy(() => this.destroy())
    this.reset()
  }

  // Return handler
  subscribe (handler) {
    this.operationSubscriptions.add(handler)
    return handler // DONT REMOVE
  }

  getLastCommandName () {
    return this.lastCommandName
  }

  reset () {
    this.resetCount()
    this.stack = []
    this.running = false

    // this has to be BEFORE this.operationSubscriptions.dispose()
    this.vimState.emitDidResetOperationStack()

    if (this.operationSubscriptions) this.operationSubscriptions.dispose()
    this.operationSubscriptions = new CompositeDisposable()

    if (this.operationToRunNext) {
      const args = this.operationToRunNext
      this.operationToRunNext = null
      this.run(...args)
    }
  }

  destroy () {
    if (this.operationSubscriptions) this.operationSubscriptions.dispose()
    this.stack = this.operationSubscriptions = null
  }

  peekTop () {
    return this.stack[this.stack.length - 1]
  }

  isEmpty () {
    return this.stack.length === 0
  }

  // Main
  // -------------------------
  run (klass, properties) {
    this.running = true

    if (this.mode === 'visual') {
      this.vimState.swrap.saveProperties(this.editor)
    }

    try {
      const type = typeof klass

      let operation
      if (type === 'object') {
        // . repeat case we can execute as-it-is.
        operation = klass
      } else {
        if (type === 'string') {
          klass = Base.getClass(klass)
        }

        const stackTop = this.peekTop()
        if (stackTop && stackTop.constructor === klass) {
          // Replace operator when identical one repeated, e.g. `dd`, `cc`, `gUgU`
          klass = 'MoveToRelativeLine'
        }
        operation = Base.getInstance(this.vimState, klass, properties)
      }

      if (this.isEmpty()) {
        if ((this.mode === 'visual' && operation.isMotion()) || operation.isTextObject()) {
          const target = operation
          operation = Base.getInstance(this.vimState, 'VisualModeSelect')
          operation.setTarget(target)
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

  runNext (...args) {
    this.operationToRunNext = args
  }

  runRecorded () {
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

  // Currently used in repeat-search and repeat-find("n", "N", ";", ",").
  runRecordedMotion (key, {reverse = false} = {}) {
    const recorded = this.vimState.globalState.get(key)
    if (!recorded) return

    recorded.vimState = this.vimState
    recorded.repeated = true
    recorded.operator = null
    recorded.resetCount()

    if (reverse) recorded.backwards = !recorded.backwards
    this.run(recorded)
    if (reverse) recorded.backwards = !recorded.backwards
  }

  runCurrentFind (options) {
    this.runRecordedMotion('currentFind', options)
  }

  runCurrentSearch (options) {
    this.runRecordedMotion('currentSearch', options)
  }

  handleError (error) {
    this.vimState.reset()
    throw error
  }

  isRunning () {
    return this.running
  }

  process () {
    if (this.stack.length === 2) {
      // [FIXME ideally]
      // When motion was targeted and its not complete like `y s t a`.
      // We won't compose target till target become ready.
      // So that we can assume when target is set, it' target is also ready.
      // e.g. `y s t a'(surround for range from here to till a)
      if (!this.peekTop().isReady()) return

      const operation = this.stack.pop()
      this.peekTop().setTarget(operation)
    }

    const top = this.peekTop()

    if (!top.isReady()) {
      if (this.mode === 'normal' && top.isOperator()) {
        this.vimState.activate('operator-pending')
      }
      // Temporary set while command is running to achieve operation-specific keymap scopes
      this.addToClassList(top.getCommandNameWithoutPrefix() + '-pending')
    } else {
      this.execute(this.stack.pop())
    }
  }

  execute (operation) {
    // Intentionally avoild wrapping by Promise.resolve() to make test easy.
    // Since almost all command don't return promise, finish synchronously.
    const execution = operation.execute()
    if (execution instanceof Promise) {
      execution.then(() => this.finish(operation)).catch(() => {
        this.handleError()
      })
    } else {
      this.finish(operation)
    }
  }

  cancel (operation) {
    if (this.mode === 'operator-pending') {
      this.vimState.mutationManager.restoreCursorsToInitialPosition()
      this.vimState.activate('normal')
    }
    this.finish(operation, true)
  }

  finish (operation, cancelled) {
    this.vimState.emitDidFinishOperation()

    if (!cancelled) {
      if (operation.recordable) {
        this.recordedOperation = operation
      }
      this.lastCommandName = operation.name
      operation.resetState()
    }

    if (this.mode === 'normal') {
      this.clearSelectionsIfNotEmpty(operation)

      // Move cursor left if cursor was at EOL
      const eolCursors = this.editor.getCursors().filter(cursor => cursor.isAtEndOfLine())
      eolCursors.forEach(cursor => this.vimState.utils.moveCursorLeft(cursor, {keepGoalColumn: true}))
    } else if (this.mode === 'visual') {
      this.vimState.updateNarrowedState()
      this.vimState.updatePreviousSelection()
    }

    this.vimState.cursorStyleManager.refresh()
    this.vimState.reset()
  }

  clearSelectionsIfNotEmpty (operation) {
    // When @vimState.selectBlockwise() is called in non-visual-mode.
    // e.g. `.` repeat of operation targeted blockwise `CurrentSelection`.
    // We need to manually clear blockwiseSelection.
    // See #647
    this.vimState.clearBlockwiseSelections() // FIXME, should be removed
    if (this.vimState.haveSomeNonEmptySelection()) {
      if (this.vimState.getConfig('strictAssertion')) {
        const message = `Have some non-empty selection in normal-mode: ${operation.toString()}`
        this.vimState.utils.assertWithException(false, message)
      }
      this.vimState.clearSelections()
    }
  }

  addToClassList (className) {
    this.editorElement.classList.add(className)
    this.subscribe(new Disposable(() => this.editorElement.classList.remove(className)))
  }

  setOperatorModifier (...args) {
    const top = this.peekTop()
    if (top && top.isOperator()) {
      top.setModifier(...args)
    }
  }

  // Count
  // -------------------------
  // keystroke `3d2w` delete 6(3*2) words.
  //  2nd number(2 in this case) is always enterd in operator-pending-mode.
  //  So count have two timing to be entered. that's why here we manage counter by mode.
  hasCount () {
    return this.count['normal'] != null || this.count['operator-pending'] != null
  }

  getCount () {
    if (this.hasCount()) {
      return (
        (this.count['normal'] != null ? this.count['normal'] : 1) *
        (this.count['operator-pending'] != null ? this.count['operator-pending'] : 1)
      )
    } else {
      return null
    }
  }

  setCount (number) {
    const mode = this.mode === 'operator-pending' ? this.mode : 'normal'
    if (this.count[mode] == null) this.count[mode] = 0
    this.count[mode] = this.count[mode] * 10 + number
    this.vimState.hover.set(this.buildCountString())
    this.editorElement.classList.toggle('with-count', true)
  }

  buildCountString () {
    return [this.count['normal'], this.count['operator-pending']].filter(n => n != null).join('x')
  }

  resetCount () {
    this.count = {}
    this.editorElement.classList.remove('with-count')
  }
}
