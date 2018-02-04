'use babel'

const {Range} = require('atom')
const Base = require('./base')

class Operator extends Base {
  static operationKind = 'operator'
  static command = false
  recordable = true

  wise = null
  target = null
  occurrence = false
  occurrenceType = 'base'

  flashTarget = true
  flashCheckpoint = 'did-finish'
  flashType = 'operator'
  flashTypeForOccurrence = 'operator-occurrence'
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

  targetSelected = null
  input = null
  readInputAfterSelect = false
  bufferCheckpointByPurpose = {}

  isReady () {
    return this.target && this.target.isReady()
  }

  // Called when operation finished
  // This is essentially to reset state for `.` repeat.
  resetState () {
    this.targetSelected = null
    this.occurrenceSelected = false
  }

  // Two checkpoint for different purpose
  // - one for undo
  // - one for preserve last inserted text
  createBufferCheckpoint (purpose) {
    this.bufferCheckpointByPurpose[purpose] = this.editor.createCheckpoint()
  }

  getBufferCheckpoint (purpose) {
    return this.bufferCheckpointByPurpose[purpose]
  }

  groupChangesSinceBufferCheckpoint (purpose) {
    const checkpoint = this.getBufferCheckpoint(purpose)
    if (checkpoint) {
      this.editor.groupChangesSinceCheckpoint(checkpoint)
      delete this.bufferCheckpointByPurpose[purpose]
    }
  }

  setMarkForChange (range) {
    this.vimState.mark.set('[', range.start)
    this.vimState.mark.set(']', range.end)
  }

  needFlash () {
    return (
      this.flashTarget &&
      this.getConfig('flashOnOperate') &&
      !this.getConfig('flashOnOperateBlacklist').includes(this.name) &&
      (this.mode !== 'visual' || this.submode !== this.target.wise) // e.g. Y in vC
    )
  }

  flashIfNecessary (ranges) {
    if (this.needFlash()) {
      this.vimState.flash(ranges, {type: this.getFlashType()})
    }
  }

  flashChangeIfNecessary () {
    if (this.needFlash()) {
      this.onDidFinishOperation(() => {
        const ranges = this.mutationManager.getSelectedBufferRangesForCheckpoint(this.flashCheckpoint)
        this.vimState.flash(ranges, {type: this.getFlashType()})
      })
    }
  }

  getFlashType () {
    return this.occurrenceSelected ? this.flashTypeForOccurrence : this.flashType
  }

  trackChangeIfNecessary () {
    if (!this.trackChange) return
    this.onDidFinishOperation(() => {
      const range = this.mutationManager.getMutatedBufferRangeForSelection(this.editor.getLastSelection())
      if (range) this.setMarkForChange(range)
    })
  }

  initialize () {
    this.subscribeResetOccurrencePatternIfNeeded()

    // When preset-occurrence was exists, operate on occurrence-wise
    if (this.acceptPresetOccurrence && this.occurrenceManager.hasMarkers()) {
      this.occurrence = true
    }

    // [FIXME] ORDER-MATTER
    // To pick cursor-word to find occurrence base pattern.
    // This has to be done BEFORE converting persistent-selection into real-selection.
    // Since when persistent-selection is actually selected, it change cursor position.
    if (this.occurrence && !this.occurrenceManager.hasMarkers()) {
      const regex = this.patternForOccurrence || this.getPatternForOccurrenceType(this.occurrenceType)
      this.occurrenceManager.addPattern(regex)
    }

    // This change cursor position.
    if (this.selectPersistentSelectionIfNecessary()) {
      // [FIXME] selection-wise is not synched if it already visual-mode
      if (this.mode !== 'visual') {
        this.vimState.activate('visual', this.swrap.detectWise(this.editor))
      }
    }

    if (this.mode === 'visual') {
      this.target = 'CurrentSelection'
    }
    if (typeof this.target === 'string') {
      this.setTarget(this.getInstance(this.target))
    }

    super.initialize()
  }

  subscribeResetOccurrencePatternIfNeeded () {
    // [CAUTION]
    // This method has to be called in PROPER timing.
    // If occurrence is true but no preset-occurrence
    // Treat that `occurrence` is BOUNDED to operator itself, so cleanp at finished.
    if (this.occurrence && !this.occurrenceManager.hasMarkers()) {
      this.onDidResetOperationStack(() => this.occurrenceManager.resetPatterns())
    }
  }

  setModifier ({wise, occurrence, occurrenceType}) {
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
  selectPersistentSelectionIfNecessary () {
    const canSelect =
      this.acceptPersistentSelection &&
      this.getConfig('autoSelectPersistentSelectionOnOperate') &&
      !this.persistentSelection.isEmpty()

    if (canSelect) {
      this.persistentSelection.select()
      this.editor.mergeIntersectingSelections()
      this.swrap.saveProperties(this.editor)
      return true
    } else {
      return false
    }
  }

  getPatternForOccurrenceType (occurrenceType) {
    if (occurrenceType === 'base') {
      return this.utils.getWordPatternAtBufferPosition(this.editor, this.getCursorBufferPosition())
    } else if (occurrenceType === 'subword') {
      return this.utils.getSubwordPatternAtBufferPosition(this.editor, this.getCursorBufferPosition())
    }
  }

  // target is TextObject or Motion to operate on.
  setTarget (target) {
    this.target = target
    this.target.operator = this
    this.emitDidSetTarget(this)
  }

  setTextToRegister (text, selection) {
    if (this.vimState.register.isUnnamed() && this.isBlackholeRegisteredOperator()) {
      return
    }

    const wise = this.occurrenceSelected ? this.occurrenceWise : this.target.wise
    if (wise === 'linewise' && !text.endsWith('\n')) {
      text += '\n'
    }

    if (text) {
      this.vimState.register.set(null, {text, selection})

      if (this.vimState.register.isUnnamed()) {
        if (this.instanceof('Delete') || this.instanceof('Change')) {
          if (!this.needSaveToNumberedRegister(this.target) && this.utils.isSingleLineText(text)) {
            this.vimState.register.set('-', {text, selection}) // small-change
          } else {
            this.vimState.register.set('1', {text, selection})
          }
        } else if (this.instanceof('Yank')) {
          this.vimState.register.set('0', {text, selection})
        }
      }
    }
  }

  isBlackholeRegisteredOperator () {
    const operators = this.getConfig('blackholeRegisteredOperators')
    const wildCardOperators = operators.filter(name => name.endsWith('*'))
    const commandName = this.getCommandNameWithoutPrefix()
    return (
      wildCardOperators.some(name => new RegExp('^' + name.replace('*', '.*')).test(commandName)) ||
      operators.includes(commandName)
    )
  }

  needSaveToNumberedRegister (target) {
    // Used to determine what register to use on change and delete operation.
    // Following motion should save to 1-9 register regerdless of content is small or big.
    const goesToNumberedRegisterMotionNames = [
      'MoveToPair', // %
      'MoveToNextSentence', // (, )
      'Search', // /, ?, n, N
      'MoveToNextParagraph' // {, }
    ]
    return goesToNumberedRegisterMotionNames.some(name => target.instanceof(name))
  }

  normalizeSelectionsIfNecessary () {
    if (this.mode === 'visual' && this.target && this.target.isMotion()) {
      this.swrap.normalize(this.editor)
    }
  }

  mutateSelections () {
    for (const selection of this.editor.getSelectionsOrderedByBufferPosition()) {
      this.mutateSelection(selection)
    }
    this.mutationManager.setCheckpoint('did-finish')
    this.restoreCursorPositionsIfNecessary()
  }

  preSelect () {
    this.normalizeSelectionsIfNecessary()
    this.createBufferCheckpoint('undo')
  }

  postMutate () {
    this.groupChangesSinceBufferCheckpoint('undo')
    this.emitDidFinishMutation()

    // Even though we fail to select target and fail to mutate,
    // we have to return to normal-mode from operator-pending or visual
    this.activateMode('normal')
  }

  // Main
  execute () {
    this.preSelect()

    if (this.readInputAfterSelect && !this.repeated) {
      return this.executeAsyncToReadInputAfterSelect()
    }

    if (this.selectTarget()) this.mutateSelections()
    this.postMutate()
  }

  async executeAsyncToReadInputAfterSelect () {
    if (this.selectTarget()) {
      this.input = await this.focusInputPromised(this.focusInputOptions)
      if (this.input == null) {
        if (this.mode !== 'visual') {
          this.editor.revertToCheckpoint(this.getBufferCheckpoint('undo'))
          this.activateMode('normal')
        }
        return
      }
      this.mutateSelections()
    }
    this.postMutate()
  }

  // Return true unless all selection is empty.
  selectTarget () {
    if (this.targetSelected != null) {
      return this.targetSelected
    }
    this.mutationManager.init({stayByMarker: this.stayByMarker})

    if (this.target.isMotion() && this.mode === 'visual') this.target.wise = this.submode
    if (this.wise != null) this.target.forceWise(this.wise)

    this.emitWillSelectTarget()

    // Allow cursor position adjustment 'on-will-select-target' hook.
    // so checkpoint comes AFTER @emitWillSelectTarget()
    this.mutationManager.setCheckpoint('will-select')

    // NOTE: When repeated, set occurrence-marker from pattern stored as state.
    if (this.repeated && this.occurrence && !this.occurrenceManager.hasMarkers()) {
      this.occurrenceManager.addPattern(this.patternForOccurrence, {occurrenceType: this.occurrenceType})
    }

    this.target.execute()

    this.mutationManager.setCheckpoint('did-select')
    if (this.occurrence) {
      if (!this.patternForOccurrence) {
        // Preserve occurrencePattern for . repeat.
        this.patternForOccurrence = this.occurrenceManager.buildPattern()
      }

      this.occurrenceWise = this.wise || 'characterwise'
      if (this.occurrenceManager.select(this.occurrenceWise)) {
        this.occurrenceSelected = true
        this.mutationManager.setCheckpoint('did-select-occurrence')
      }
    }

    this.targetSelected = this.vimState.haveSomeNonEmptySelection() || this.target.name === 'Empty'
    if (this.targetSelected) {
      this.emitDidSelectTarget()
      this.flashChangeIfNecessary()
      this.trackChangeIfNecessary()
    } else {
      this.emitDidFailSelectTarget()
    }

    return this.targetSelected
  }

  restoreCursorPositionsIfNecessary () {
    if (!this.restorePositions) return

    const stay =
      this.stayAtSamePosition != null
        ? this.stayAtSamePosition
        : this.getConfig(this.stayOptionName) || (this.occurrenceSelected && this.getConfig('stayOnOccurrence'))
    const wise = this.occurrenceSelected ? this.occurrenceWise : this.target.wise
    const {setToFirstCharacterOnLinewise} = this
    this.mutationManager.restoreCursorPositions({stay, wise, setToFirstCharacterOnLinewise})
  }
}

class SelectBase extends Operator {
  static command = false
  flashTarget = false
  recordable = false

  execute () {
    this.normalizeSelectionsIfNecessary()
    this.selectTarget()

    if (this.target.selectSucceeded) {
      if (this.target.isTextObject()) {
        this.editor.scrollToCursorPosition()
      }
      const wise = this.occurrenceSelected ? this.occurrenceWise : this.target.wise
      this.activateModeIfNecessary('visual', wise)
    } else {
      this.cancelOperation()
    }
  }
}

class Select extends SelectBase {
  execute () {
    this.swrap.saveProperties(this.editor)
    super.execute()
  }
}

class SelectLatestChange extends SelectBase {
  target = 'ALatestChange'
}

class SelectPreviousSelection extends SelectBase {
  target = 'PreviousSelection'
}

class SelectPersistentSelection extends SelectBase {
  target = 'APersistentSelection'
  acceptPersistentSelection = false
}

class SelectOccurrence extends SelectBase {
  occurrence = true
}

// VisualModeSelect: used in visual-mode
// When text-object is invoked from normal or viusal-mode, operation would be
//  => VisualModeSelect operator with target=text-object
// When motion is invoked from visual-mode, operation would be
//  => VisualModeSelect operator with target=motion)
// ================================
// VisualModeSelect is used in TWO situation.
// - visual-mode operation
//   - e.g: `v l`, `V j`, `v i p`...
// - Directly invoke text-object from normal-mode
//   - e.g: Invoke `Inner Paragraph` from command-palette.
class VisualModeSelect extends SelectBase {
  static command = false
  acceptPresetOccurrence = false
  acceptPersistentSelection = false
}

// Persistent Selection
// =========================
class CreatePersistentSelection extends Operator {
  flashTarget = false
  stayAtSamePosition = true
  acceptPresetOccurrence = false
  acceptPersistentSelection = false

  mutateSelection (selection) {
    this.persistentSelection.markBufferRange(selection.getBufferRange())
  }
}

class TogglePersistentSelection extends CreatePersistentSelection {
  initialize () {
    if (this.mode === 'normal') {
      const point = this.editor.getCursorBufferPosition()
      const marker = this.persistentSelection.getMarkerAtPoint(point)
      if (marker) this.target = 'Empty'
    }
    super.initialize()
  }

  mutateSelection (selection) {
    const point = this.getCursorPositionForSelection(selection)
    const marker = this.persistentSelection.getMarkerAtPoint(point)
    if (marker) {
      marker.destroy()
    } else {
      super.mutateSelection(selection)
    }
  }
}

// Preset Occurrence
// =========================
class TogglePresetOccurrence extends Operator {
  target = 'Empty'
  flashTarget = false
  acceptPresetOccurrence = false
  acceptPersistentSelection = false
  occurrenceType = 'base'

  execute () {
    const marker = this.occurrenceManager.getMarkerAtPoint(this.getCursorBufferPosition())
    if (marker) {
      this.occurrenceManager.destroyMarkers([marker])
    } else {
      const isNarrowed = this.vimState.isNarrowed()

      let regex
      if (this.mode === 'visual' && !isNarrowed) {
        this.occurrenceType = 'base'
        regex = new RegExp(this._.escapeRegExp(this.editor.getSelectedText()), 'g')
      } else {
        regex = this.getPatternForOccurrenceType(this.occurrenceType)
      }

      this.occurrenceManager.addPattern(regex, {occurrenceType: this.occurrenceType})
      this.occurrenceManager.saveLastPattern(this.occurrenceType)

      if (!isNarrowed) this.activateMode('normal')
    }
  }
}

class TogglePresetSubwordOccurrence extends TogglePresetOccurrence {
  occurrenceType = 'subword'
}

// Want to rename RestoreOccurrenceMarker
class AddPresetOccurrenceFromLastOccurrencePattern extends TogglePresetOccurrence {
  execute () {
    this.occurrenceManager.resetPatterns()
    const regex = this.globalState.get('lastOccurrencePattern')
    if (regex) {
      const occurrenceType = this.globalState.get('lastOccurrenceType')
      this.occurrenceManager.addPattern(regex, {occurrenceType})
      this.activateMode('normal')
    }
  }
}

// Delete
// ================================
class Delete extends Operator {
  trackChange = true
  flashCheckpoint = 'did-select-occurrence'
  flashTypeForOccurrence = 'operator-remove-occurrence'
  stayOptionName = 'stayOnDelete'
  setToFirstCharacterOnLinewise = true

  execute () {
    this.onDidSelectTarget(() => {
      if (this.occurrenceSelected && this.occurrenceWise === 'linewise') {
        this.flashTarget = false
      }
    })

    if (this.target.wise === 'blockwise') {
      this.restorePositions = false
    }
    super.execute()
  }

  mutateSelection (selection) {
    this.setTextToRegister(selection.getText(), selection)
    selection.deleteSelectedText()
  }
}

class DeleteRight extends Delete {
  target = 'MoveRight'
}

class DeleteLeft extends Delete {
  target = 'MoveLeft'
}

class DeleteToLastCharacterOfLine extends Delete {
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

class DeleteLine extends Delete {
  wise = 'linewise'
  target = 'MoveToRelativeLine'
  flashTarget = false
}

// Yank
// =========================
class Yank extends Operator {
  trackChange = true
  stayOptionName = 'stayOnYank'

  mutateSelection (selection) {
    this.setTextToRegister(selection.getText(), selection)
  }
}

class YankLine extends Yank {
  wise = 'linewise'
  target = 'MoveToRelativeLine'
}

class YankToLastCharacterOfLine extends Yank {
  target = 'MoveToLastCharacterOfLine'
}

// Yank diff hunk at cursor by removing leading "+" or "-" from each line
class YankDiffHunk extends Yank {
  target = 'InnerDiffHunk'
  mutateSelection (selection) {
    // Remove leading "+" or "-" in diff hunk
    const textToYank = selection.getText().replace(/^./gm, '')
    this.setTextToRegister(textToYank, selection)
  }
}

// -------------------------
// [ctrl-a]
class Increase extends Operator {
  target = 'Empty' // ctrl-a in normal-mode find target number in current line manually
  flashTarget = false // do manually
  restorePositions = false // do manually
  step = 1

  execute () {
    this.newRanges = []
    if (!this.regex) this.regex = new RegExp(`${this.getConfig('numberRegex')}`, 'g')

    super.execute()

    if (this.newRanges.length) {
      if (this.getConfig('flashOnOperate') && !this.getConfig('flashOnOperateBlacklist').includes(this.name)) {
        this.vimState.flash(this.newRanges, {type: this.flashTypeForOccurrence})
      }
    }
  }

  replaceNumberInBufferRange (scanRange, fn) {
    const newRanges = []
    this.scanEditor('forward', this.regex, {scanRange}, event => {
      if (fn) {
        if (fn(event)) event.stop()
        else return
      }
      const nextNumber = this.getNextNumber(event.matchText)
      newRanges.push(event.replace(String(nextNumber)))
    })
    return newRanges
  }

  mutateSelection (selection) {
    const {cursor} = selection
    if (this.target.name === 'Empty') {
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

  getNextNumber (numberString) {
    return Number.parseInt(numberString, 10) + this.step * this.getCount()
  }
}

// [ctrl-x]
class Decrease extends Increase {
  step = -1
}

// -------------------------
// [g ctrl-a]
class IncrementNumber extends Increase {
  baseNumber = null
  target = null

  getNextNumber (numberString) {
    if (this.baseNumber != null) {
      this.baseNumber += this.step * this.getCount()
    } else {
      this.baseNumber = Number.parseInt(numberString, 10)
    }
    return this.baseNumber
  }
}

// [g ctrl-x]
class DecrementNumber extends IncrementNumber {
  step = -1
}

// Put
// -------------------------
// Cursor placement:
// - place at end of mutation: paste non-multiline characterwise text
// - place at start of mutation: non-multiline characterwise text(characterwise, linewise)
class PutBefore extends Operator {
  location = 'before'
  target = 'Empty'
  flashType = 'operator-long'
  restorePositions = false // manage manually
  flashTarget = false // manage manually
  trackChange = false // manage manually

  initialize () {
    this.vimState.sequentialPasteManager.onInitialize(this)
    super.initialize()
  }

  execute () {
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
      if (this.getConfig('flashOnOperate') && !this.getConfig('flashOnOperateBlacklist').includes(this.name)) {
        const ranges = this.editor.getSelections().map(selection => this.mutationsBySelection.get(selection))
        this.vimState.flash(ranges, {type: this.getFlashType()})
      }
    })
  }

  adjustCursorPosition () {
    for (const selection of this.editor.getSelections()) {
      if (!this.mutationsBySelection.has(selection)) continue

      const {cursor} = selection
      const newRange = this.mutationsBySelection.get(selection)
      if (this.linewisePaste) {
        this.utils.moveCursorToFirstCharacterAtRow(cursor, newRange.start.row)
      } else {
        if (newRange.isSingleLine()) {
          cursor.setBufferPosition(newRange.end.translate([0, -1]))
        } else {
          cursor.setBufferPosition(newRange.start)
        }
      }
    }
  }

  mutateSelection (selection) {
    const value = this.vimState.register.get(null, selection, this.sequentialPaste)
    if (!value.text) {
      this.cancelled = true
      return
    }

    const textToPaste = value.text.repeat(this.getCount())
    this.linewisePaste = value.type === 'linewise' || this.isMode('visual', 'linewise')
    const newRange = this.paste(selection, textToPaste, {linewisePaste: this.linewisePaste})
    this.mutationsBySelection.set(selection, newRange)
    this.vimState.sequentialPasteManager.savePastedRangeForSelection(selection, newRange)
  }

  // Return pasted range
  paste (selection, text, {linewisePaste}) {
    if (this.sequentialPaste) {
      return this.pasteCharacterwise(selection, text)
    } else if (linewisePaste) {
      return this.pasteLinewise(selection, text)
    } else {
      return this.pasteCharacterwise(selection, text)
    }
  }

  pasteCharacterwise (selection, text) {
    const {cursor} = selection
    if (selection.isEmpty() && this.location === 'after' && !this.isEmptyRow(cursor.getBufferRow())) {
      cursor.moveRight()
    }
    return selection.insertText(text)
  }

  // Return newRange
  pasteLinewise (selection, text) {
    const {cursor} = selection
    const cursorRow = cursor.getBufferRow()
    if (!text.endsWith('\n')) {
      text += '\n'
    }
    if (selection.isEmpty()) {
      if (this.location === 'before') {
        return this.utils.insertTextAtBufferPosition(this.editor, [cursorRow, 0], text)
      } else if (this.location === 'after') {
        const targetRow = this.getFoldEndRowForRow(cursorRow)
        this.utils.ensureEndsWithNewLineForBufferRow(this.editor, targetRow)
        return this.utils.insertTextAtBufferPosition(this.editor, [targetRow + 1, 0], text)
      }
    } else {
      if (!this.isMode('visual', 'linewise')) {
        selection.insertText('\n')
      }
      return selection.insertText(text)
    }
  }
}

class PutAfter extends PutBefore {
  location = 'after'
}

class PutBeforeWithAutoIndent extends PutBefore {
  pasteLinewise (selection, text) {
    const newRange = super.pasteLinewise(selection, text)
    this.utils.adjustIndentWithKeepingLayout(this.editor, newRange)
    return newRange
  }
}

class PutAfterWithAutoIndent extends PutBeforeWithAutoIndent {
  location = 'after'
}

class AddBlankLineBelow extends Operator {
  flashTarget = false
  target = 'Empty'
  stayAtSamePosition = true
  stayByMarker = true
  where = 'below'

  mutateSelection (selection) {
    const point = selection.getHeadBufferPosition()
    if (this.where === 'below') point.row++
    point.column = 0
    this.editor.setTextInBufferRange([point, point], '\n'.repeat(this.getCount()))
  }
}

class AddBlankLineAbove extends AddBlankLineBelow {
  where = 'above'
}

class ResolveGitConflict extends Operator {
  target = 'Empty'
  restorePositions = false // do manually

  mutateSelection (selection) {
    const point = this.getCursorPositionForSelection(selection)
    const rangeInfo = this.getConflictingRangeInfo(point.row)

    if (rangeInfo) {
      const {whole, sectionOurs, sectionTheirs, bodyOurs, bodyTheirs} = rangeInfo
      const resolveConflict = range => {
        const text = this.editor.getTextInBufferRange(range)
        const dstRange = this.getBufferRangeForRowRange([whole.start.row, whole.end.row])
        const newRange = this.editor.setTextInBufferRange(dstRange, text ? text + '\n' : '')
        selection.cursor.setBufferPosition(newRange.start)
      }
      // NOTE: When cursor is at separator row '=======', no replace happens because it's ambiguous.
      if (sectionOurs.containsPoint(point)) {
        resolveConflict(bodyOurs)
      } else if (sectionTheirs.containsPoint(point)) {
        resolveConflict(bodyTheirs)
      }
    }
  }

  getConflictingRangeInfo (row) {
    const from = [row, Infinity]
    const conflictStart = this.findInEditor('backward', /^<<<<<<< .+$/, {from}, event => event.range.start)

    if (conflictStart) {
      const startRow = conflictStart.row
      let separatorRow, endRow
      const from = [startRow + 1, 0]
      const regex = /(^<<<<<<< .+$)|(^=======$)|(^>>>>>>> .+$)/g
      this.scanEditor('forward', regex, {from}, ({match, range, stop}) => {
        if (match[1]) {
          // incomplete conflict hunk, we saw next conflict startRow wihout seeing endRow
          stop()
        } else if (match[2]) {
          separatorRow = range.start.row
        } else if (match[3]) {
          endRow = range.start.row
          stop()
        }
      })
      if (!endRow) return
      const whole = new Range([startRow, 0], [endRow, Infinity])
      const sectionOurs = new Range(whole.start, [(separatorRow || endRow) - 1, Infinity])
      const sectionTheirs = new Range([(separatorRow || startRow) + 1, 0], whole.end)

      const bodyOursStart = sectionOurs.start.translate([1, 0])
      const bodyOurs =
        sectionOurs.getRowCount() === 1
          ? new Range(bodyOursStart, bodyOursStart)
          : new Range(bodyOursStart, sectionOurs.end)

      const bodyTheirs =
        sectionTheirs.getRowCount() === 1
          ? new Range(sectionTheirs.start, sectionTheirs.start)
          : sectionTheirs.translate([0, 0], [-1, 0])
      return {whole, sectionOurs, sectionTheirs, bodyOurs, bodyTheirs}
    }
  }
}

module.exports = {
  Operator,
  SelectBase,
  Select,
  SelectLatestChange,
  SelectPreviousSelection,
  SelectPersistentSelection,
  SelectOccurrence,
  VisualModeSelect,
  CreatePersistentSelection,
  TogglePersistentSelection,
  TogglePresetOccurrence,
  TogglePresetSubwordOccurrence,
  AddPresetOccurrenceFromLastOccurrencePattern,
  Delete,
  DeleteRight,
  DeleteLeft,
  DeleteToLastCharacterOfLine,
  DeleteLine,
  Yank,
  YankLine,
  YankToLastCharacterOfLine,
  YankDiffHunk,
  Increase,
  Decrease,
  IncrementNumber,
  DecrementNumber,
  PutBefore,
  PutAfter,
  PutBeforeWithAutoIndent,
  PutAfterWithAutoIndent,
  AddBlankLineBelow,
  AddBlankLineAbove,
  ResolveGitConflict
}
