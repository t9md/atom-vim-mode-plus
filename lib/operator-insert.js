'use babel'

const {Range, CompositeDisposable} = require('atom')
const {Operator} = require('./operator')

// Operator which start 'insert-mode'
// -------------------------
// [NOTE]
// Rule: Don't make any text mutation before calling `@selectTarget()`.
class ActivateInsertModeBase extends Operator {
  static command = false
  flashTarget = false
  supportInsertionCount = true

  // When each mutaion's extent is not intersecting, muitiple changes are recorded
  // e.g
  //  - Multicursors edit
  //  - Cursor moved in insert-mode(e.g ctrl-f, ctrl-b)
  // But I don't care multiple changes just because I'm lazy(so not perfect implementation).
  // I only take care of one change happened at earliest(topCursor's change) position.
  // Thats' why I save topCursor's position to @topCursorPositionAtInsertionStart to compare traversal to deletionStart
  // Why I use topCursor's change? Just because it's easy to use first change returned by getChangeSinceCheckpoint().
  getChangeSinceCheckpoint (purpose) {
    const checkpoint = this.getBufferCheckpoint(purpose)
    return this.editor.buffer.getChangesSinceCheckpoint(checkpoint)[0]
  }

  // [BUG-BUT-OK] Replaying text-deletion-operation is not compatible to pure Vim.
  // Pure Vim record all operation in insert-mode as keystroke level and can distinguish
  // character deleted by `Delete` or by `ctrl-u`.
  // But I can not and don't trying to minic this level of compatibility.
  // So basically deletion-done-in-one is expected to work well.
  replayLastChange (selection) {
    let textToInsert
    if (this.lastChange != null) {
      const {start, oldExtent, newText} = this.lastChange
      if (!oldExtent.isZero()) {
        const traversalToStartOfDelete = start.traversalFrom(this.topCursorPositionAtInsertionStart)
        const deletionStart = selection.cursor.getBufferPosition().traverse(traversalToStartOfDelete)
        const deletionEnd = deletionStart.traverse(oldExtent)
        selection.setBufferRange([deletionStart, deletionEnd])
      }
      textToInsert = newText
    } else {
      textToInsert = ''
    }
    selection.insertText(textToInsert, {autoIndent: true})
  }

  // called when repeated
  // [FIXME] to use replayLastChange in repeatInsert overriding subclasss.
  repeatInsert (selection, text) {
    this.replayLastChange(selection)
  }

  disposeReplaceMode () {
    if (this.vimState.replaceModeDisposable) {
      this.vimState.replaceModeDisposable.dispose()
      this.vimState.replaceModeDisposable = null
    }
  }

  initialize () {
    this.disposeReplaceMode()
    super.initialize()
  }

  execute () {
    if (this.repeated) this.flashTarget = this.trackChange = true

    this.preSelect()

    if (this.selectTarget() || this.target.wise !== 'linewise') {
      if (this.mutateText) this.mutateText()

      if (this.repeated) {
        for (const selection of this.editor.getSelections()) {
          const textToInsert = (this.lastChange && this.lastChange.newText) || ''
          this.repeatInsert(selection, textToInsert)
          this.utils.moveCursorLeft(selection.cursor)
        }
        this.mutationManager.setCheckpoint('did-finish')
        this.groupChangesSinceBufferCheckpoint('undo')
        this.emitDidFinishMutation()
        if (this.getConfig('clearMultipleCursorsOnEscapeInsertMode')) this.vimState.clearSelections()
      } else {
        if (this.mode !== 'insert') {
          this.initializeInsertMode()
        }

        if (this.name === 'ActivateReplaceMode') {
          this.activateMode('insert', 'replace')
        } else {
          this.activateMode('insert')
        }
      }
    } else {
      this.activateMode('normal')
    }
  }

  initializeInsertMode () {
    // Avoid freezing by acccidental big count(e.g. `5555555555555i`), See #560, #596
    let insertionCount = this.supportInsertionCount ? this.limitNumber(this.getCount() - 1, {max: 100}) : 0

    let textByOperator = ''
    if (insertionCount > 0) {
      const change = this.getChangeSinceCheckpoint('undo')
      textByOperator = (change && change.newText) || ''
    }

    this.createBufferCheckpoint('insert')
    const topCursor = this.editor.getCursorsOrderedByBufferPosition()[0]
    this.topCursorPositionAtInsertionStart = topCursor.getBufferPosition()

    // Skip normalization of blockwiseSelection.
    // Since want to keep multi-cursor and it's position in when shift to insert-mode.
    for (const blockwiseSelection of this.getBlockwiseSelections()) {
      blockwiseSelection.skipNormalization()
    }

    const insertModeDisposable = this.vimState.preemptWillDeactivateMode(({mode}) => {
      if (mode !== 'insert') {
        return
      }
      insertModeDisposable.dispose()
      this.disposeReplaceMode()

      this.vimState.mark.set('^', this.editor.getCursorBufferPosition()) // Last insert-mode position
      let textByUserInput = ''
      const change = this.getChangeSinceCheckpoint('insert')
      if (change) {
        this.lastChange = change
        this.setMarkForChange(new Range(change.start, change.start.traverse(change.newExtent)))
        textByUserInput = change.newText
      }
      this.vimState.register.set('.', {text: textByUserInput}) // Last inserted text

      while (insertionCount) {
        insertionCount--
        for (const selection of this.editor.getSelections()) {
          selection.insertText(textByOperator + textByUserInput, {autoIndent: true})
        }
      }

      // This cursor state is restored on undo.
      // So cursor state has to be updated before next groupChangesSinceCheckpoint()
      if (this.getConfig('clearMultipleCursorsOnEscapeInsertMode')) this.vimState.clearSelections()

      // grouping changes for undo checkpoint need to come last
      this.groupChangesSinceBufferCheckpoint('undo')

      const preventIncorrectWrap = this.editor.hasAtomicSoftTabs()
      for (const cursor of this.editor.getCursors()) {
        this.utils.moveCursorLeft(cursor, {preventIncorrectWrap})
      }
    })
  }
}

class ActivateInsertMode extends ActivateInsertModeBase {
  target = 'Empty'
  acceptPresetOccurrence = false
  acceptPersistentSelection = false
}

class ActivateReplaceMode extends ActivateInsertMode {
  initialize () {
    super.initialize()

    const replacedCharsBySelection = new WeakMap()
    this.vimState.replaceModeDisposable = new CompositeDisposable(
      this.editor.onWillInsertText(({text = '', cancel}) => {
        cancel()
        for (const selection of this.editor.getSelections()) {
          for (const char of text.split('')) {
            if (char !== '\n' && !selection.cursor.isAtEndOfLine()) selection.selectRight()
            if (!replacedCharsBySelection.has(selection)) replacedCharsBySelection.set(selection, [])
            replacedCharsBySelection.get(selection).push(selection.getText())
            selection.insertText(char)
          }
        }
      }),

      atom.commands.add(this.editorElement, 'core:backspace', event => {
        event.stopImmediatePropagation()
        for (const selection of this.editor.getSelections()) {
          const chars = replacedCharsBySelection.get(selection)
          if (chars && chars.length) {
            selection.selectLeft()
            if (!selection.insertText(chars.pop()).isEmpty()) selection.cursor.moveLeft()
          }
        }
      })
    )
  }

  repeatInsert (selection, text) {
    for (const char of text) {
      if (char === '\n') continue
      if (selection.cursor.isAtEndOfLine()) break
      selection.selectRight()
    }
    selection.insertText(text, {autoIndent: false})
  }
}

class InsertAfter extends ActivateInsertMode {
  execute () {
    for (const cursor of this.editor.getCursors()) {
      this.utils.moveCursorRight(cursor)
    }
    super.execute()
  }
}

// key: 'g I' in all mode
class InsertAtBeginningOfLine extends ActivateInsertMode {
  execute () {
    if (this.mode === 'visual' && this.submode !== 'blockwise') {
      this.editor.splitSelectionsIntoLines()
    }
    for (const blockwiseSelection of this.getBlockwiseSelections()) {
      blockwiseSelection.skipNormalization()
    }
    this.editor.moveToBeginningOfLine()
    super.execute()
  }
}

// key: normal 'A'
class InsertAfterEndOfLine extends ActivateInsertMode {
  execute () {
    this.editor.moveToEndOfLine()
    super.execute()
  }
}

// key: normal 'I'
class InsertAtFirstCharacterOfLine extends ActivateInsertMode {
  execute () {
    for (const cursor of this.editor.getCursors()) {
      this.utils.moveCursorToFirstCharacterAtRow(cursor, cursor.getBufferRow())
    }
    super.execute()
  }
}

class InsertAtLastInsert extends ActivateInsertMode {
  execute () {
    const point = this.vimState.mark.get('^')
    if (point) {
      this.editor.setCursorBufferPosition(point)
      this.editor.scrollToCursorPosition({center: true})
    }
    super.execute()
  }
}

class InsertAboveWithNewline extends ActivateInsertMode {
  initialize () {
    this.originalCursorPositionMarker = this.editor.markBufferPosition(this.editor.getCursorBufferPosition())
    super.initialize()
  }

  // This is for `o` and `O` operator.
  // On undo/redo put cursor at original point where user type `o` or `O`.
  groupChangesSinceBufferCheckpoint (purpose) {
    if (this.repeated) {
      super.groupChangesSinceBufferCheckpoint(purpose)
      return
    }

    const lastCursor = this.editor.getLastCursor()
    const cursorPosition = lastCursor.getBufferPosition()
    lastCursor.setBufferPosition(this.originalCursorPositionMarker.getHeadBufferPosition())
    this.originalCursorPositionMarker.destroy()
    this.originalCursorPositionMarker = null

    if (this.getConfig('groupChangesWhenLeavingInsertMode')) {
      super.groupChangesSinceBufferCheckpoint(purpose)
    }
    lastCursor.setBufferPosition(cursorPosition)
  }

  autoIndentEmptyRows () {
    for (const cursor of this.editor.getCursors()) {
      const row = cursor.getBufferRow()
      if (this.isEmptyRow(row)) this.editor.autoIndentBufferRow(row)
    }
  }

  mutateText () {
    this.editor.insertNewlineAbove()
    if (this.editor.autoIndent) this.autoIndentEmptyRows()
  }

  repeatInsert (selection, text) {
    selection.insertText(text.trimLeft(), {autoIndent: true})
  }
}

class InsertBelowWithNewline extends InsertAboveWithNewline {
  mutateText () {
    for (const cursor of this.editor.getCursors()) {
      this.utils.setBufferRow(cursor, this.getFoldEndRowForRow(cursor.getBufferRow()))
    }

    this.editor.insertNewlineBelow()
    if (this.editor.autoIndent) this.autoIndentEmptyRows()
  }
}

// Advanced Insertion
// -------------------------
class InsertByTarget extends ActivateInsertModeBase {
  static command = false
  which = null // one of ['start', 'end', 'head', 'tail']

  initialize () {
    // HACK
    // When g i is mapped to `insert-at-start-of-target`.
    // `g i 3 l` start insert at 3 column right position.
    // In this case, we don't want repeat insertion 3 times.
    // This @getCount() call cache number at the timing BEFORE '3' is specified.
    this.getCount()
    super.initialize()
  }

  execute () {
    this.onDidSelectTarget(() => {
      // In vC/vL, when occurrence marker was NOT selected,
      // it behave's very specially
      // vC: `I` and `A` behaves as shoft hand of `ctrl-v I` and `ctrl-v A`.
      // vL: `I` and `A` place cursors at each selected lines of start( or end ) of non-white-space char.
      if (!this.occurrenceSelected && this.mode === 'visual' && this.submode !== 'blockwise') {
        for (const $selection of this.swrap.getSelections(this.editor)) {
          $selection.normalize()
          $selection.applyWise('blockwise')
        }

        if (this.submode === 'linewise') {
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

// key: 'I', Used in 'visual-mode.characterwise', visual-mode.blockwise
class InsertAtStartOfTarget extends InsertByTarget {
  which = 'start'
}

// key: 'A', Used in 'visual-mode.characterwise', 'visual-mode.blockwise'
class InsertAtEndOfTarget extends InsertByTarget {
  which = 'end'
}

class InsertAtHeadOfTarget extends InsertByTarget {
  which = 'head'
}

class InsertAtStartOfOccurrence extends InsertAtStartOfTarget {
  occurrence = true
}

class InsertAtEndOfOccurrence extends InsertAtEndOfTarget {
  occurrence = true
}

class InsertAtHeadOfOccurrence extends InsertAtHeadOfTarget {
  occurrence = true
}

class InsertAtStartOfSubwordOccurrence extends InsertAtStartOfOccurrence {
  occurrenceType = 'subword'
}

class InsertAtEndOfSubwordOccurrence extends InsertAtEndOfOccurrence {
  occurrenceType = 'subword'
}

class InsertAtHeadOfSubwordOccurrence extends InsertAtHeadOfOccurrence {
  occurrenceType = 'subword'
}

class InsertAtStartOfSmartWord extends InsertByTarget {
  which = 'start'
  target = 'MoveToPreviousSmartWord'
}

class InsertAtEndOfSmartWord extends InsertByTarget {
  which = 'end'
  target = 'MoveToEndOfSmartWord'
}

class InsertAtPreviousFoldStart extends InsertByTarget {
  which = 'start'
  target = 'MoveToPreviousFoldStart'
}

class InsertAtNextFoldStart extends InsertByTarget {
  which = 'end'
  target = 'MoveToNextFoldStart'
}

// -------------------------
class Change extends ActivateInsertModeBase {
  trackChange = true
  supportInsertionCount = false

  mutateText () {
    // Allways dynamically determine selection wise wthout consulting target.wise
    // Reason: when `c i {`, wise is 'characterwise', but actually selected range is 'linewise'
    //   {
    //     a
    //   }
    const isLinewiseTarget = this.swrap.detectWise(this.editor) === 'linewise'
    for (const selection of this.editor.getSelections()) {
      if (!this.getConfig('dontUpdateRegisterOnChangeOrSubstitute')) {
        this.setTextToRegister(selection.getText(), selection)
      }
      if (isLinewiseTarget) {
        selection.insertText('\n', {autoIndent: true})
        // selection.insertText("", {autoIndent: true})
        selection.cursor.moveLeft()
      } else {
        selection.insertText('', {autoIndent: true})
      }
    }
  }
}

class ChangeOccurrence extends Change {
  occurrence = true
}

class ChangeSubwordOccurrence extends ChangeOccurrence {
  occurrenceType = 'subword'
}

class Substitute extends Change {
  target = 'MoveRight'
}

class SubstituteLine extends Change {
  wise = 'linewise' // [FIXME] to re-override target.wise in visual-mode
  target = 'MoveToRelativeLine'
}

// alias
class ChangeLine extends SubstituteLine {}

class ChangeToLastCharacterOfLine extends Change {
  target = 'MoveToLastCharacterOfLine'

  execute () {
    this.onDidSelectTarget(() => {
      if (this.target.wise === 'blockwise') {
        for (const blockwiseSelection of this.getBlockwiseSelections()) {
          blockwiseSelection.extendMemberSelectionsToEndOfLine()
        }
      }
    })
    super.execute()
  }
}

module.exports = {
  ActivateInsertModeBase,
  ActivateInsertMode,
  ActivateReplaceMode,
  InsertAfter,
  InsertAtBeginningOfLine,
  InsertAfterEndOfLine,
  InsertAtFirstCharacterOfLine,
  InsertAtLastInsert,
  InsertAboveWithNewline,
  InsertBelowWithNewline,
  InsertByTarget,
  InsertAtStartOfTarget,
  InsertAtEndOfTarget,
  InsertAtHeadOfTarget,
  InsertAtStartOfOccurrence,
  InsertAtEndOfOccurrence,
  InsertAtHeadOfOccurrence,
  InsertAtStartOfSubwordOccurrence,
  InsertAtEndOfSubwordOccurrence,
  InsertAtHeadOfSubwordOccurrence,
  InsertAtStartOfSmartWord,
  InsertAtEndOfSmartWord,
  InsertAtPreviousFoldStart,
  InsertAtNextFoldStart,
  Change,
  ChangeOccurrence,
  ChangeSubwordOccurrence,
  Substitute,
  SubstituteLine,
  ChangeLine,
  ChangeToLastCharacterOfLine
}
