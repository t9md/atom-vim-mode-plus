"use babel"

const _ = require("underscore-plus")
const {
  isEmptyRow,
  getWordPatternAtBufferPosition,
  getSubwordPatternAtBufferPosition,
  insertTextAtBufferPosition,
  setBufferRow,
  moveCursorToFirstCharacterAtRow,
  ensureEndsWithNewLineForBufferRow,
  adjustIndentWithKeepingLayout,
  isSingleLineText,
} = require("./utils")
const Base = require("./base")

class Operator extends Base {
  static operationKind = "operator"
  requireTarget = true
  recordable = true

  wise = null
  occurrence = false
  occurrenceType = "base"

  flashTarget = true
  flashCheckpoint = "did-finish"
  flashType = "operator"
  flashTypeForOccurrence = "operator-occurrence"
  trackChange = false

  patternForOccurrence = null
  stayAtSamePosition = null
  stayOptionName = null
  stayByMarker = false
  restorePositions = true
  setToFirstCharacterOnLinewise = false

  acceptPresetOccurrence = true
  acceptPersistentSelection = true

  bufferCheckpointByPurpose = null
  mutateSelectionOrderd = false

  // Experimentaly allow selectTarget before input Complete
  // -------------------------
  supportEarlySelect = false
  targetSelected = null

  canEarlySelect() {
    return this.supportEarlySelect && !this.repeated
  }
  // -------------------------

  // Called when operation finished
  // This is essentially to reset state for `.` repeat.
  resetState() {
    this.targetSelected = null
    this.occurrenceSelected = false
  }

  // Two checkpoint for different purpose
  // - one for undo(handled by modeManager)
  // - one for preserve last inserted text
  createBufferCheckpoint(purpose) {
    if (!this.bufferCheckpointByPurpose) this.bufferCheckpointByPurpose = {}
    this.bufferCheckpointByPurpose[purpose] = this.editor.createCheckpoint()
  }

  getBufferCheckpoint(purpose) {
    if (this.bufferCheckpointByPurpose) {
      return this.bufferCheckpointByPurpose[purpose]
    }
  }

  deleteBufferCheckpoint(purpose) {
    if (this.bufferCheckpointByPurpose) {
      delete this.bufferCheckpointByPurpose[purpose]
    }
  }

  groupChangesSinceBufferCheckpoint(purpose) {
    const checkpoint = this.getBufferCheckpoint(purpose)
    if (checkpoint) {
      this.editor.groupChangesSinceCheckpoint(checkpoint)
      this.deleteBufferCheckpoint(purpose)
    }
  }

  setMarkForChange(range) {
    this.vimState.mark.set("[", range.start)
    this.vimState.mark.set("]", range.end)
  }

  needFlash() {
    return (
      this.flashTarget &&
      this.getConfig("flashOnOperate") &&
      !this.getConfig("flashOnOperateBlacklist").includes(this.name) &&
      (this.mode !== "visual" || this.submode !== this.target.wise) // e.g. Y in vC
    )
  }

  flashIfNecessary(ranges) {
    if (this.needFlash()) {
      this.vimState.flash(ranges, {type: this.getFlashType()})
    }
  }

  flashChangeIfNecessary() {
    if (this.needFlash()) {
      this.onDidFinishOperation(() => {
        const ranges = this.mutationManager.getSelectedBufferRangesForCheckpoint(this.flashCheckpoint)
        this.vimState.flash(ranges, {type: this.getFlashType()})
      })
    }
  }

  getFlashType() {
    return this.occurrenceSelected ? this.flashTypeForOccurrence : this.flashType
  }

  trackChangeIfNecessary() {
    if (!this.trackChange) return
    this.onDidFinishOperation(() => {
      const range = this.mutationManager.getMutatedBufferRangeForSelection(this.editor.getLastSelection())
      if (range) this.setMarkForChange(range)
    })
  }

  initialize() {
    this.subscribeResetOccurrencePatternIfNeeded()
    this.onDidSetOperatorModifier(options => this.setModifier(options))

    // When preset-occurrence was exists, operate on occurrence-wise
    if (this.acceptPresetOccurrence && this.occurrenceManager.hasMarkers()) {
      this.occurrence = true
    }

    // [FIXME] ORDER-MATTER
    // To pick cursor-word to find occurrence base pattern.
    // This has to be done BEFORE converting persistent-selection into real-selection.
    // Since when persistent-selection is actuall selected, it change cursor position.
    if (this.occurrence && !this.occurrenceManager.hasMarkers()) {
      const regex = this.patternForOccurrence || this.getPatternForOccurrenceType(this.occurrenceType)
      this.occurrenceManager.addPattern(regex)
    }

    // This change cursor position.
    if (this.selectPersistentSelectionIfNecessary()) {
      // [FIXME] selection-wise is not synched if it already visual-mode
      if (this.mode !== "visual") {
        this.vimState.modeManager.activate("visual", this.swrap.detectWise(this.editor))
      }
    }

    if (this.mode === "visual" && this.requireTarget) {
      this.target = "CurrentSelection"
    }
    if (_.isString(this.target)) {
      this.setTarget(this.getInstance(this.target))
    }

    return super.initialize()
  }

  subscribeResetOccurrencePatternIfNeeded() {
    // [CAUTION]
    // This method has to be called in PROPER timing.
    // If occurrence is true but no preset-occurrence
    // Treat that `occurrence` is BOUNDED to operator itself, so cleanp at finished.
    if (this.occurrence && !this.occurrenceManager.hasMarkers()) {
      this.onDidResetOperationStack(() => this.occurrenceManager.resetPatterns())
    }
  }

  setModifier({wise, occurrence, occurrenceType}) {
    if (wise) {
      this.wise = wise
    } else if (occurrence) {
      this.occurrence = occurrence
      this.occurrenceType = occurrenceType
      // This is o modifier case(e.g. `c o p`, `d O f`)
      // We RESET existing occurence-marker when `o` or `O` modifier is typed by user.
      const regex = this.getPatternForOccurrenceType(occurrenceType)
      this.occurrenceManager.addPattern(regex, {reset: true, occurrenceType})
      this.onDidResetOperationStack(() => this.occurrenceManager.resetPatterns())
    }
  }

  // return true/false to indicate success
  selectPersistentSelectionIfNecessary() {
    if (
      this.acceptPersistentSelection &&
      this.getConfig("autoSelectPersistentSelectionOnOperate") &&
      !this.persistentSelection.isEmpty()
    ) {
      this.persistentSelection.select()
      this.editor.mergeIntersectingSelections()
      for (const $selection of this.swrap.getSelections(this.editor)) {
        if (!$selection.hasProperties()) $selection.saveProperties()
      }

      return true
    } else {
      return false
    }
  }

  getPatternForOccurrenceType(occurrenceType) {
    if (occurrenceType === "base") {
      return getWordPatternAtBufferPosition(this.editor, this.getCursorBufferPosition())
    } else if (occurrenceType === "subword") {
      return getSubwordPatternAtBufferPosition(this.editor, this.getCursorBufferPosition())
    }
  }

  // target is TextObject or Motion to operate on.
  setTarget(target) {
    this.target = target
    this.target.operator = this
    this.emitDidSetTarget(this)

    if (this.canEarlySelect()) {
      this.normalizeSelectionsIfNecessary()
      this.createBufferCheckpoint("undo")
      this.selectTarget()
    }
    return this
  }

  setTextToRegisterForSelection(selection) {
    this.setTextToRegister(selection.getText(), selection)
  }

  setTextToRegister(text, selection) {
    if (this.vimState.register.isUnnamed() && this.isBlackholeRegisteredOperator()) {
      return
    }

    if (this.target.isLinewise() && !text.endsWith("\n")) {
      text += "\n"
    }

    if (text) {
      this.vimState.register.set(null, {text, selection})

      if (this.vimState.register.isUnnamed()) {
        if (this.instanceof("Delete") || this.instanceof("Change")) {
          if (!this.needSaveToNumberedRegister(this.target) && isSingleLineText(text)) {
            this.vimState.register.set("-", {text, selection}) // small-change
          } else {
            this.vimState.register.set("1", {text, selection})
          }
        } else if (this.instanceof("Yank")) {
          this.vimState.register.set("0", {text, selection})
        }
      }
    }
  }

  isBlackholeRegisteredOperator() {
    const operators = this.getConfig("blackholeRegisteredOperators")
    const wildCardOperators = operators.filter(name => name.endsWith("*"))
    const commandName = this.getCommandNameWithoutPrefix()
    return (
      wildCardOperators.some(name => new RegExp("^" + name.replace("*", ".*")).test(commandName)) ||
      operators.includes(commandName)
    )
  }

  needSaveToNumberedRegister(target) {
    // Used to determine what register to use on change and delete operation.
    // Following motion should save to 1-9 register regerdless of content is small or big.
    const goesToNumberedRegisterMotionNames = [
      "MoveToPair", // %
      "MoveToNextSentence", // (, )
      "Search", // /, ?, n, N
      "MoveToNextParagraph", // {, }
    ]
    return goesToNumberedRegisterMotionNames.some(name => target.instanceof(name))
  }

  normalizeSelectionsIfNecessary() {
    if (this.target && this.target.isMotion() && this.mode === "visual") {
      this.swrap.normalize(this.editor)
    }
  }

  startMutation(fn) {
    if (this.canEarlySelect()) {
      // - Skip selection normalization: already normalized before @selectTarget()
      // - Manual checkpoint grouping: to create checkpoint before @selectTarget()
      fn()
      this.emitWillFinishMutation()
      this.groupChangesSinceBufferCheckpoint("undo")
    } else {
      this.normalizeSelectionsIfNecessary()
      this.editor.transact(() => {
        fn()
        this.emitWillFinishMutation()
      })
    }

    this.emitDidFinishMutation()
  }

  // Main
  execute() {
    this.startMutation(() => {
      if (this.selectTarget()) {
        const selections = this.mutateSelectionOrderd
          ? this.editor.getSelectionsOrderedByBufferPosition()
          : this.editor.getSelections()

        for (const selection of selections) {
          this.mutateSelection(selection)
        }
        this.mutationManager.setCheckpoint("did-finish")
        this.restoreCursorPositionsIfNecessary()
      }
    })

    // Even though we fail to select target and fail to mutate,
    // we have to return to normal-mode from operator-pending or visual
    this.activateMode("normal")
  }

  // Return true unless all selection is empty.
  selectTarget() {
    if (this.targetSelected != null) {
      return this.targetSelected
    }
    this.mutationManager.init({stayByMarker: this.stayByMarker})

    if (this.target.isMotion() && this.mode === "visual") this.target.wise = this.submode
    if (this.wise != null) this.target.forceWise(this.wise)

    this.emitWillSelectTarget()

    // Allow cursor position adjustment 'on-will-select-target' hook.
    // so checkpoint comes AFTER @emitWillSelectTarget()
    this.mutationManager.setCheckpoint("will-select")

    // NOTE
    // Since MoveToNextOccurrence, MoveToPreviousOccurrence motion move by
    //  occurrence-marker, occurrence-marker has to be created BEFORE `@target.execute()`
    // And when repeated, occurrence pattern is already cached at @patternForOccurrence
    if (this.repeated && this.occurrence && !this.occurrenceManager.hasMarkers()) {
      this.occurrenceManager.addPattern(this.patternForOccurrence, {occurrenceType: this.occurrenceType})
    }

    this.target.execute()

    this.mutationManager.setCheckpoint("did-select")
    if (this.occurrence) {
      // To repoeat(`.`) operation where multiple occurrence patterns was set.
      // Here we save patterns which represent unioned regex which @occurrenceManager knows.
      if (!this.patternForOccurrence) {
        this.patternForOccurrence = this.occurrenceManager.buildPattern()
      }

      this.occurrenceWise = this.wise || "characterwise"
      if (this.occurrenceManager.select(this.occurrenceWise)) {
        this.occurrenceSelected = true
        this.mutationManager.setCheckpoint("did-select-occurrence")
      }
    }

    this.targetSelected = this.vimState.haveSomeNonEmptySelection() || this.target.name === "Empty"
    if (this.targetSelected) {
      this.emitDidSelectTarget()
      this.flashChangeIfNecessary()
      this.trackChangeIfNecessary()
    } else {
      this.emitDidFailSelectTarget()
    }

    return this.targetSelected
  }

  restoreCursorPositionsIfNecessary() {
    if (!this.restorePositions) return

    const stay =
      this.stayAtSamePosition != null
        ? this.stayAtSamePosition
        : this.getConfig(this.stayOptionName) || (this.occurrenceSelected && this.getConfig("stayOnOccurrence"))
    const wise = this.occurrenceSelected ? this.occurrenceWise : this.target.wise
    const {setToFirstCharacterOnLinewise} = this
    this.mutationManager.restoreCursorPositions({stay, wise, setToFirstCharacterOnLinewise})
  }
}
Operator.register(false)

class SelectBase extends Operator {
  flashTarget = false
  recordable = false

  execute() {
    this.startMutation(() => this.selectTarget())

    if (this.target.selectSucceeded) {
      if (this.target.isTextObject()) {
        this.editor.scrollToCursorPosition()
      }
      const wise = this.occurrenceSelected ? this.occurrenceWise : this.target.wise
      this.activateModeIfNecessary("visual", wise)
    } else {
      this.cancelOperation()
    }
  }
}
SelectBase.register(false)

class Select extends SelectBase {
  execute() {
    for (const $selection of this.swrap.getSelections(this.editor)) {
      if (!$selection.hasProperties()) $selection.saveProperties()
    }
    super.execute()
  }
}
Select.register()

class SelectLatestChange extends SelectBase {
  target = "ALatestChange"
}
SelectLatestChange.register()

class SelectPreviousSelection extends SelectBase {
  target = "PreviousSelection"
}
SelectPreviousSelection.register()

class SelectPersistentSelection extends SelectBase {
  target = "APersistentSelection"
  acceptPersistentSelection = false
}
SelectPersistentSelection.register()

class SelectOccurrence extends SelectBase {
  occurrence = true
}
SelectOccurrence.register()

// SelectInVisualMode: used in visual-mode
// When text-object is invoked from normal or viusal-mode, operation would be
//  => SelectInVisualMode operator with target=text-object
// When motion is invoked from visual-mode, operation would be
//  => SelectInVisualMode operator with target=motion)
// ================================
// SelectInVisualMode is used in TWO situation.
// - visual-mode operation
//   - e.g: `v l`, `V j`, `v i p`...
// - Directly invoke text-object from normal-mode
//   - e.g: Invoke `Inner Paragraph` from command-palette.
class SelectInVisualMode extends SelectBase {
  acceptPresetOccurrence = false
  acceptPersistentSelection = false
}
SelectInVisualMode.register(false)

// Persistent Selection
// =========================
class CreatePersistentSelection extends Operator {
  flashTarget = false
  stayAtSamePosition = true
  acceptPresetOccurrence = false
  acceptPersistentSelection = false

  mutateSelection(selection) {
    this.persistentSelection.markBufferRange(selection.getBufferRange())
  }
}
CreatePersistentSelection.register()

class TogglePersistentSelection extends CreatePersistentSelection {
  isComplete() {
    const point = this.editor.getCursorBufferPosition()
    this.markerToRemove = this.persistentSelection.getMarkerAtPoint(point)
    return this.markerToRemove || super.isComplete()
  }

  execute() {
    if (this.markerToRemove) {
      this.markerToRemove.destroy()
    } else {
      super.execute()
    }
  }
}
TogglePersistentSelection.register()

// Preset Occurrence
// =========================
class TogglePresetOccurrence extends Operator {
  target = "Empty"
  flashTarget = false
  acceptPresetOccurrence = false
  acceptPersistentSelection = false
  occurrenceType = "base"

  execute() {
    const marker = this.occurrenceManager.getMarkerAtPoint(this.editor.getCursorBufferPosition())
    if (marker) {
      this.occurrenceManager.destroyMarkers([marker])
    } else {
      const isNarrowed = this.vimState.modeManager.isNarrowed()

      let regex
      if (this.mode === "visual" && !isNarrowed) {
        this.occurrenceType = "base"
        regex = new RegExp(_.escapeRegExp(this.editor.getSelectedText()), "g")
      } else {
        regex = this.getPatternForOccurrenceType(this.occurrenceType)
      }

      this.occurrenceManager.addPattern(regex, {occurrenceType: this.occurrenceType})
      this.occurrenceManager.saveLastPattern(this.occurrenceType)

      if (!isNarrowed) this.activateMode("normal")
    }
  }
}
TogglePresetOccurrence.register()

class TogglePresetSubwordOccurrence extends TogglePresetOccurrence {
  occurrenceType = "subword"
}
TogglePresetSubwordOccurrence.register()

// Want to rename RestoreOccurrenceMarker
class AddPresetOccurrenceFromLastOccurrencePattern extends TogglePresetOccurrence {
  execute() {
    this.occurrenceManager.resetPatterns()
    const regex = this.globalState.get("lastOccurrencePattern")
    if (regex) {
      const occurrenceType = this.globalState.get("lastOccurrenceType")
      this.occurrenceManager.addPattern(regex, {occurrenceType})
      this.activateMode("normal")
    }
  }
}
AddPresetOccurrenceFromLastOccurrencePattern.register()

// Delete
// ================================
class Delete extends Operator {
  trackChange = true
  flashCheckpoint = "did-select-occurrence"
  flashTypeForOccurrence = "operator-remove-occurrence"
  stayOptionName = "stayOnDelete"
  setToFirstCharacterOnLinewise = true

  execute() {
    this.onDidSelectTarget(() => {
      if (this.occurrenceSelected && this.occurrenceWise === "linewise") {
        this.flashTarget = false
      }
    })

    if (this.target.wise === "blockwise") {
      this.restorePositions = false
    }
    super.execute()
  }

  mutateSelection(selection) {
    this.setTextToRegisterForSelection(selection)
    selection.deleteSelectedText()
  }
}
Delete.register()

class DeleteRight extends Delete {
  target = "MoveRight"
}
DeleteRight.register()

class DeleteLeft extends Delete {
  target = "MoveLeft"
}
DeleteLeft.register()

class DeleteToLastCharacterOfLine extends Delete {
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
DeleteToLastCharacterOfLine.register()

class DeleteLine extends Delete {
  wise = "linewise"
  target = "MoveToRelativeLine"
  flashTarget = false
}
DeleteLine.register()

// Yank
// =========================
class Yank extends Operator {
  trackChange = true
  stayOptionName = "stayOnYank"

  mutateSelection(selection) {
    this.setTextToRegisterForSelection(selection)
  }
}
Yank.register()

class YankLine extends Yank {
  wise = "linewise"
  target = "MoveToRelativeLine"
}
YankLine.register()

class YankToLastCharacterOfLine extends Yank {
  target = "MoveToLastCharacterOfLine"
}
YankToLastCharacterOfLine.register()

// -------------------------
// [ctrl-a]
class Increase extends Operator {
  target = "Empty" // ctrl-a in normal-mode find target number in current line manually
  flashTarget = false // do manually
  restorePositions = false // do manually
  step = 1

  execute() {
    this.newRanges = []
    if (!this.regex) this.regex = new RegExp(`${this.getConfig("numberRegex")}`, "g")

    super.execute()

    if (this.newRanges.length) {
      if (this.getConfig("flashOnOperate") && !this.getConfig("flashOnOperateBlacklist").includes(this.name)) {
        this.vimState.flash(this.newRanges, {type: this.flashTypeForOccurrence})
      }
    }
  }

  replaceNumberInBufferRange(scanRange, fn) {
    const newRanges = []
    this.scanForward(this.regex, {scanRange}, event => {
      if (fn) {
        if (fn(event)) event.stop()
        else return
      }
      const nextNumber = this.getNextNumber(event.matchText)
      newRanges.push(event.replace(String(nextNumber)))
    })
    return newRanges
  }

  mutateSelection(selection) {
    const {cursor} = selection
    if (this.target.is("Empty")) {
      // ctrl-a, ctrl-x in `normal-mode`
      const cursorPosition = cursor.getBufferPosition()
      const scanRange = this.editor.bufferRangeForBufferRow(cursorPosition.row)
      const newRanges = this.replaceNumberInBufferRange(scanRange, event =>
        event.range.end.isGreaterThan(cursorPosition)
      )
      const point = (newRanges.length && newRanges[0].end.translate([0, -1])) || cursorPosition
      cursor.setBufferPosition(point)
    } else {
      const scanRange = selection.getBufferRange()
      this.newRanges.push(...this.replaceNumberInBufferRange(scanRange))
      cursor.setBufferPosition(scanRange.start)
    }
  }

  getNextNumber(numberString) {
    return Number.parseInt(numberString, 10) + this.step * this.getCount()
  }
}
Increase.register()

// [ctrl-x]
class Decrease extends Increase {
  step = -1
}
Decrease.register()

// -------------------------
// [g ctrl-a]
class IncrementNumber extends Increase {
  baseNumber = null
  target = null
  mutateSelectionOrderd = true

  getNextNumber(numberString) {
    if (this.baseNumber != null) {
      this.baseNumber += this.step * this.getCount()
    } else {
      this.baseNumber = Number.parseInt(numberString, 10)
    }
    return this.baseNumber
  }
}
IncrementNumber.register()

// [g ctrl-x]
class DecrementNumber extends IncrementNumber {
  step = -1
}
DecrementNumber.register()

// Put
// -------------------------
// Cursor placement:
// - place at end of mutation: paste non-multiline characterwise text
// - place at start of mutation: non-multiline characterwise text(characterwise, linewise)
class PutBefore extends Operator {
  location = "before"
  target = "Empty"
  flashType = "operator-long"
  restorePositions = false // manage manually
  flashTarget = false // manage manually
  trackChange = false // manage manually

  initialize() {
    this.vimState.sequentialPasteManager.onInitialize(this)
    return super.initialize()
  }

  execute() {
    this.mutationsBySelection = new Map()
    this.sequentialPaste = this.vimState.sequentialPasteManager.onExecute(this)

    this.onDidFinishMutation(() => {
      if (!this.cancelled) this.adjustCursorPosition()
    })

    super.execute()

    if (this.cancelled) return

    this.onDidFinishOperation(() => {
      // TrackChange
      const newRange = this.mutationsBySelection.get(this.editor.getLastSelection())
      if (newRange) this.setMarkForChange(newRange)

      // Flash
      if (this.getConfig("flashOnOperate") && !this.getConfig("flashOnOperateBlacklist").includes(this.name)) {
        const ranges = this.editor.getSelections().map(selection => this.mutationsBySelection.get(selection))
        this.vimState.flash(ranges, {type: this.getFlashType()})
      }
    })
  }

  adjustCursorPosition() {
    for (const selection of this.editor.getSelections()) {
      if (!this.mutationsBySelection.has(selection)) continue

      const {cursor} = selection
      const newRange = this.mutationsBySelection.get(selection)
      if (this.linewisePaste) {
        moveCursorToFirstCharacterAtRow(cursor, newRange.start.row)
      } else {
        if (newRange.isSingleLine()) {
          cursor.setBufferPosition(newRange.end.translate([0, -1]))
        } else {
          cursor.setBufferPosition(newRange.start)
        }
      }
    }
  }

  mutateSelection(selection) {
    const value = this.vimState.register.get(null, selection, this.sequentialPaste)
    if (!value.text) {
      this.cancelled = true
      return
    }

    const textToPaste = _.multiplyString(value.text, this.getCount())
    this.linewisePaste = value.type === "linewise" || this.isMode("visual", "linewise")
    const newRange = this.paste(selection, textToPaste, {linewisePaste: this.linewisePaste})
    this.mutationsBySelection.set(selection, newRange)
    this.vimState.sequentialPasteManager.savePastedRangeForSelection(selection, newRange)
  }

  // Return pasted range
  paste(selection, text, {linewisePaste}) {
    if (this.sequentialPaste) {
      return this.pasteCharacterwise(selection, text)
    } else if (linewisePaste) {
      return this.pasteLinewise(selection, text)
    } else {
      return this.pasteCharacterwise(selection, text)
    }
  }

  pasteCharacterwise(selection, text) {
    const {cursor} = selection
    if (selection.isEmpty() && this.location === "after" && !isEmptyRow(this.editor, cursor.getBufferRow())) {
      cursor.moveRight()
    }
    return selection.insertText(text)
  }

  // Return newRange
  pasteLinewise(selection, text) {
    const {cursor} = selection
    const cursorRow = cursor.getBufferRow()
    if (!text.endsWith("\n")) {
      text += "\n"
    }
    if (selection.isEmpty()) {
      if (this.location === "before") {
        return insertTextAtBufferPosition(this.editor, [cursorRow, 0], text)
      } else if (this.location === "after") {
        const targetRow = this.getFoldEndRowForRow(cursorRow)
        ensureEndsWithNewLineForBufferRow(this.editor, targetRow)
        return insertTextAtBufferPosition(this.editor, [targetRow + 1, 0], text)
      }
    } else {
      if (!this.isMode("visual", "linewise")) {
        selection.insertText("\n")
      }
      return selection.insertText(text)
    }
  }
}
PutBefore.register()

class PutAfter extends PutBefore {
  location = "after"
}
PutAfter.register()

class PutBeforeWithAutoIndent extends PutBefore {
  pasteLinewise(selection, text) {
    const newRange = super.pasteLinewise(selection, text)
    adjustIndentWithKeepingLayout(this.editor, newRange)
    return newRange
  }
}
PutBeforeWithAutoIndent.register()

class PutAfterWithAutoIndent extends PutBeforeWithAutoIndent {
  location = "after"
}
PutAfterWithAutoIndent.register()

class AddBlankLineBelow extends Operator {
  flashTarget = false
  target = "Empty"
  stayAtSamePosition = true
  stayByMarker = true
  where = "below"

  mutateSelection(selection) {
    const point = selection.getHeadBufferPosition()
    if (this.where === "below") point.row++
    point.column = 0
    this.editor.setTextInBufferRange([point, point], "\n".repeat(this.getCount()))
  }
}
AddBlankLineBelow.register()

class AddBlankLineAbove extends AddBlankLineBelow {
  where = "above"
}
AddBlankLineAbove.register()
