"use babel"

const _ = require("underscore-plus")
const {Range} = require("atom")

const {moveCursorLeft, moveCursorRight, limitNumber, isEmptyRow, setBufferRow} = require("./utils")
const Operator = require("./base").getClass("Operator")

// Operator which start 'insert-mode'
// -------------------------
// [NOTE]
// Rule: Don't make any text mutation before calling `@selectTarget()`.
class ActivateInsertMode extends Operator {
  requireTarget = false
  flashTarget = false
  finalSubmode = null
  supportInsertionCount = true

  observeWillDeactivateMode() {
    let disposable = this.vimState.modeManager.preemptWillDeactivateMode(({mode}) => {
      if (mode !== "insert") return
      disposable.dispose()

      this.vimState.mark.set("^", this.editor.getCursorBufferPosition()) // Last insert-mode position
      let textByUserInput = ""
      const change = this.getChangeSinceCheckpoint("insert")
      if (change) {
        this.lastChange = change
        this.setMarkForChange(new Range(change.start, change.start.traverse(change.newExtent)))
        textByUserInput = change.newText
      }
      this.vimState.register.set(".", {text: textByUserInput}) // Last inserted text

      _.times(this.getInsertionCount(), () => {
        const textToInsert = this.textByOperator + textByUserInput
        for (const selection of this.editor.getSelections()) {
          selection.insertText(textToInsert, {autoIndent: true})
        }
      })

      // This cursor state is restored on undo.
      // So cursor state has to be updated before next groupChangesSinceCheckpoint()
      if (this.getConfig("clearMultipleCursorsOnEscapeInsertMode")) {
        this.vimState.clearSelections()
      }

      // grouping changes for undo checkpoint need to come last
      if (this.getConfig("groupChangesWhenLeavingInsertMode")) {
        return this.groupChangesSinceBufferCheckpoint("undo")
      }
    })
  }

  // When each mutaion's extent is not intersecting, muitiple changes are recorded
  // e.g
  //  - Multicursors edit
  //  - Cursor moved in insert-mode(e.g ctrl-f, ctrl-b)
  // But I don't care multiple changes just because I'm lazy(so not perfect implementation).
  // I only take care of one change happened at earliest(topCursor's change) position.
  // Thats' why I save topCursor's position to @topCursorPositionAtInsertionStart to compare traversal to deletionStart
  // Why I use topCursor's change? Just because it's easy to use first change returned by getChangeSinceCheckpoint().
  getChangeSinceCheckpoint(purpose) {
    const checkpoint = this.getBufferCheckpoint(purpose)
    return this.editor.buffer.getChangesSinceCheckpoint(checkpoint)[0]
  }

  // [BUG-BUT-OK] Replaying text-deletion-operation is not compatible to pure Vim.
  // Pure Vim record all operation in insert-mode as keystroke level and can distinguish
  // character deleted by `Delete` or by `ctrl-u`.
  // But I can not and don't trying to minic this level of compatibility.
  // So basically deletion-done-in-one is expected to work well.
  replayLastChange(selection) {
    let textToInsert
    if (this.lastChange != null) {
      const {start, newExtent, oldExtent, newText} = this.lastChange
      if (!oldExtent.isZero()) {
        const traversalToStartOfDelete = start.traversalFrom(this.topCursorPositionAtInsertionStart)
        const deletionStart = selection.cursor.getBufferPosition().traverse(traversalToStartOfDelete)
        const deletionEnd = deletionStart.traverse(oldExtent)
        selection.setBufferRange([deletionStart, deletionEnd])
      }
      textToInsert = newText
    } else {
      textToInsert = ""
    }
    selection.insertText(textToInsert, {autoIndent: true})
  }

  // called when repeated
  // [FIXME] to use replayLastChange in repeatInsert overriding subclasss.
  repeatInsert(selection, text) {
    this.replayLastChange(selection)
  }

  getInsertionCount() {
    if (this.insertionCount == null) {
      this.insertionCount = this.supportInsertionCount ? this.getCount(-1) : 0
    }
    // Avoid freezing by acccidental big count(e.g. `5555555555555i`), See #560, #596
    return limitNumber(this.insertionCount, {max: 100})
  }

  execute() {
    if (this.repeated) {
      this.flashTarget = this.trackChange = true

      this.startMutation(() => {
        if (this.target) this.selectTarget()
        if (this.mutateText) this.mutateText()

        for (const selection of this.editor.getSelections()) {
          const textToInsert = (this.lastChange && this.lastChange.newText) || ""
          this.repeatInsert(selection, textToInsert)
          moveCursorLeft(selection.cursor)
        }
        this.mutationManager.setCheckpoint("did-finish")
      })

      if (this.getConfig("clearMultipleCursorsOnEscapeInsertMode")) this.vimState.clearSelections()
    } else {
      this.normalizeSelectionsIfNecessary()
      this.createBufferCheckpoint("undo")
      if (this.target) this.selectTarget()
      this.observeWillDeactivateMode()
      if (this.mutateText) this.mutateText()

      if (this.getInsertionCount() > 0) {
        const change = this.getChangeSinceCheckpoint("undo")
        this.textByOperator = (change && change.newText) || ""
      }

      this.createBufferCheckpoint("insert")
      const topCursor = this.editor.getCursorsOrderedByBufferPosition()[0]
      this.topCursorPositionAtInsertionStart = topCursor.getBufferPosition()

      // Skip normalization of blockwiseSelection.
      // Since want to keep multi-cursor and it's position in when shift to insert-mode.
      for (const blockwiseSelection of this.getBlockwiseSelections()) {
        blockwiseSelection.skipNormalization()
      }
      this.activateMode("insert", this.finalSubmode)
    }
  }
}
ActivateInsertMode.register()

class ActivateReplaceMode extends ActivateInsertMode {
  finalSubmode = "replace"

  repeatInsert(selection, text) {
    for (const char of text) {
      if (char === "\n") continue
      if (selection.cursor.isAtEndOfLine()) break
      selection.selectRight()
    }
    selection.insertText(text, {autoIndent: false})
  }
}
ActivateReplaceMode.register()

class InsertAfter extends ActivateInsertMode {
  execute() {
    for (const cursor of this.editor.getCursors()) {
      moveCursorRight(cursor)
    }
    super.execute()
  }
}
InsertAfter.register()

// key: 'g I' in all mode
class InsertAtBeginningOfLine extends ActivateInsertMode {
  execute() {
    if (this.mode === "visual" && this.submode !== "blockwise") {
      this.editor.splitSelectionsIntoLines()
    }
    this.editor.moveToBeginningOfLine()
    super.execute()
  }
}
InsertAtBeginningOfLine.register()

// key: normal 'A'
class InsertAfterEndOfLine extends ActivateInsertMode {
  execute() {
    this.editor.moveToEndOfLine()
    super.execute()
  }
}
InsertAfterEndOfLine.register()

// key: normal 'I'
class InsertAtFirstCharacterOfLine extends ActivateInsertMode {
  execute() {
    this.editor.moveToBeginningOfLine()
    this.editor.moveToFirstCharacterOfLine()
    super.execute()
  }
}
InsertAtFirstCharacterOfLine.register()

class InsertAtLastInsert extends ActivateInsertMode {
  execute() {
    const point = this.vimState.mark.get("^")
    if (point) {
      this.editor.setCursorBufferPosition(point)
      this.editor.scrollToCursorPosition({center: true})
    }
    super.execute()
  }
}
InsertAtLastInsert.register()

class InsertAboveWithNewline extends ActivateInsertMode {
  initialize() {
    if (this.getConfig("groupChangesWhenLeavingInsertMode")) {
      this.originalCursorPositionMarker = this.editor.markBufferPosition(this.editor.getCursorBufferPosition())
    }
    return super.initialize()
  }

  // This is for `o` and `O` operator.
  // On undo/redo put cursor at original point where user type `o` or `O`.
  groupChangesSinceBufferCheckpoint(purpose) {
    const lastCursor = this.editor.getLastCursor()
    const cursorPosition = lastCursor.getBufferPosition()
    lastCursor.setBufferPosition(this.originalCursorPositionMarker.getHeadBufferPosition())
    this.originalCursorPositionMarker.destroy()

    super.groupChangesSinceBufferCheckpoint(purpose)

    lastCursor.setBufferPosition(cursorPosition)
  }

  autoIndentEmptyRows() {
    for (const cursor of this.editor.getCursors()) {
      const row = cursor.getBufferRow()
      if (isEmptyRow(this.editor, row)) {
        this.editor.autoIndentBufferRow(row)
      }
    }
  }

  mutateText() {
    this.editor.insertNewlineAbove()
    if (this.editor.autoIndent) {
      this.autoIndentEmptyRows()
    }
  }

  repeatInsert(selection, text) {
    selection.insertText(text.trimLeft(), {autoIndent: true})
  }
}
InsertAboveWithNewline.register()

class InsertBelowWithNewline extends InsertAboveWithNewline {
  mutateText() {
    for (const cursor of this.editor.getCursors()) {
      setBufferRow(cursor, this.getFoldEndRowForRow(cursor.getBufferRow()))
    }

    this.editor.insertNewlineBelow()
    if (this.editor.autoIndent) this.autoIndentEmptyRows()
  }
}
InsertBelowWithNewline.register()

// Advanced Insertion
// -------------------------
class InsertByTarget extends ActivateInsertMode {
  requireTarget = true
  which = null // one of ['start', 'end', 'head', 'tail']

  initialize() {
    // HACK
    // When g i is mapped to `insert-at-start-of-target`.
    // `g i 3 l` start insert at 3 column right position.
    // In this case, we don't want repeat insertion 3 times.
    // This @getCount() call cache number at the timing BEFORE '3' is specified.
    this.getCount()
    return super.initialize()
  }

  execute() {
    this.onDidSelectTarget(() => {
      // In vC/vL, when occurrence marker was NOT selected,
      // it behave's very specially
      // vC: `I` and `A` behaves as shoft hand of `ctrl-v I` and `ctrl-v A`.
      // vL: `I` and `A` place cursors at each selected lines of start( or end ) of non-white-space char.
      if (!this.occurrenceSelected && this.mode === "visual" && this.submode !== "blockwise") {
        for (const $selection of this.swrap.getSelections(this.editor)) {
          $selection.normalize()
          $selection.applyWise("blockwise")
        }

        if (this.submode === "linewise") {
          for (const blockwiseSelection of this.getBlockwiseSelections()) {
            blockwiseSelection.expandMemberSelectionsOverLineWithTrimRange()
          }
        }
      }

      for (const $selection of this.swrap.getSelections(this.editor)) {
        $selection.setBufferPositionTo(this.which)
      }
    })
    super.execute()
  }
}
InsertByTarget.register(false)

// key: 'I', Used in 'visual-mode.characterwise', visual-mode.blockwise
class InsertAtStartOfTarget extends InsertByTarget {
  which = "start"
}
InsertAtStartOfTarget.register()

// key: 'A', Used in 'visual-mode.characterwise', 'visual-mode.blockwise'
class InsertAtEndOfTarget extends InsertByTarget {
  which = "end"
}
InsertAtEndOfTarget.register()

class InsertAtHeadOfTarget extends InsertByTarget {
  which = "head"
}
InsertAtHeadOfTarget.register()

class InsertAtStartOfOccurrence extends InsertAtStartOfTarget {
  occurrence = true
}
InsertAtStartOfOccurrence.register()

class InsertAtEndOfOccurrence extends InsertAtEndOfTarget {
  occurrence = true
}
InsertAtEndOfOccurrence.register()

class InsertAtHeadOfOccurrence extends InsertAtHeadOfTarget {
  occurrence = true
}
InsertAtHeadOfOccurrence.register()

class InsertAtStartOfSubwordOccurrence extends InsertAtStartOfOccurrence {
  occurrenceType = "subword"
}
InsertAtStartOfSubwordOccurrence.register()

class InsertAtEndOfSubwordOccurrence extends InsertAtEndOfOccurrence {
  occurrenceType = "subword"
}
InsertAtEndOfSubwordOccurrence.register()

class InsertAtHeadOfSubwordOccurrence extends InsertAtHeadOfOccurrence {
  occurrenceType = "subword"
}
InsertAtHeadOfSubwordOccurrence.register()

class InsertAtStartOfSmartWord extends InsertByTarget {
  which = "start"
  target = "MoveToPreviousSmartWord"
}
InsertAtStartOfSmartWord.register()

class InsertAtEndOfSmartWord extends InsertByTarget {
  which = "end"
  target = "MoveToEndOfSmartWord"
}
InsertAtEndOfSmartWord.register()

class InsertAtPreviousFoldStart extends InsertByTarget {
  which = "start"
  target = "MoveToPreviousFoldStart"
}
InsertAtPreviousFoldStart.register()

class InsertAtNextFoldStart extends InsertByTarget {
  which = "end"
  target = "MoveToNextFoldStart"
}
InsertAtNextFoldStart.register()

// -------------------------
class Change extends ActivateInsertMode {
  requireTarget = true
  trackChange = true
  supportInsertionCount = false

  mutateText() {
    // Allways dynamically determine selection wise wthout consulting target.wise
    // Reason: when `c i {`, wise is 'characterwise', but actually selected range is 'linewise'
    //   {
    //     a
    //   }
    const isLinewiseTarget = this.swrap.detectWise(this.editor) === "linewise"
    for (const selection of this.editor.getSelections()) {
      if (!this.getConfig("dontUpdateRegisterOnChangeOrSubstitute")) {
        this.setTextToRegisterForSelection(selection)
      }
      if (isLinewiseTarget) {
        selection.insertText("\n", {autoIndent: true})
        selection.cursor.moveLeft()
      } else {
        selection.insertText("", {autoIndent: true})
      }
    }
  }
}
Change.register()

class ChangeOccurrence extends Change {
  occurrence = true
}
ChangeOccurrence.register()

class Substitute extends Change {
  target = "MoveRight"
}
Substitute.register()

class SubstituteLine extends Change {
  wise = "linewise" // [FIXME] to re-override target.wise in visual-mode
  target = "MoveToRelativeLine"
}
SubstituteLine.register()

// alias
class ChangeLine extends SubstituteLine {}
ChangeLine.register()

class ChangeToLastCharacterOfLine extends Change {
  target = "MoveToLastCharacterOfLine"

  execute() {
    this.onDidSelectTarget(() => {
      if (this.target.wise === "blockwise") {
        for (const blockwiseSelection of this.getBlockwiseSelections()) {
          blockwiseSelection.extendMemberSelectionsToEndOfLine()
        }
      }
    })
    super.execute()
  }
}
ChangeToLastCharacterOfLine.register()
