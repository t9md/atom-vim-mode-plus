const _ = require("underscore-plus")
const {BufferedProcess, Range} = require("atom")

const {
  isSingleLineText,
  isLinewiseRange,
  limitNumber,
  toggleCaseForCharacter,
  splitTextByNewLine,
  splitArguments,
  getIndentLevelForBufferRow,
  adjustIndentWithKeepingLayout,
} = require("./utils")
const Base = require("./base")
const Operator = Base.getClass("Operator")

// TransformString
// ================================
class TransformString extends Operator {
  static initClass(isCommand) {
    this.extend(isCommand)
    this.prototype.trackChange = true
    this.prototype.stayOptionName = "stayOnTransformString"
    this.prototype.autoIndent = false
    this.prototype.autoIndentNewline = false
    this.prototype.autoIndentAfterInsertText = false
    this.stringTransformers = []
  }

  static registerToSelectList() {
    this.stringTransformers.push(this)
  }

  mutateSelection(selection) {
    const text = this.getNewText(selection.getText(), selection)
    if (text) {
      let startRowIndentLevel
      if (this.autoIndentAfterInsertText) {
        const startRow = selection.getBufferRange().start.row
        startRowIndentLevel = getIndentLevelForBufferRow(this.editor, startRow)
      }
      let range = selection.insertText(text, {autoIndent: this.autoIndent, autoIndentNewline: this.autoIndentNewline})

      if (this.autoIndentAfterInsertText) {
        // Currently used by SplitArguments and Surround( linewise target only )
        if (this.target.isLinewise()) {
          range = range.translate([0, 0], [-1, 0])
        }
        this.editor.setIndentationForBufferRow(range.start.row, startRowIndentLevel)
        this.editor.setIndentationForBufferRow(range.end.row, startRowIndentLevel)
        // Adjust inner range, end.row is already( if needed ) translated so no need to re-translate.
        adjustIndentWithKeepingLayout(this.editor, range.translate([1, 0], [0, 0]))
      }
    }
  }
}
TransformString.initClass(false)

class ToggleCase extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.displayName = "Toggle ~"
  }

  getNewText(text) {
    return text.replace(/./g, toggleCaseForCharacter)
  }
}
ToggleCase.initClass()

class ToggleCaseAndMoveRight extends ToggleCase {
  static initClass() {
    this.extend()
    this.prototype.flashTarget = false
    this.prototype.restorePositions = false
    this.prototype.target = "MoveRight"
  }
}
ToggleCaseAndMoveRight.initClass()

class UpperCase extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.displayName = "Upper"
  }
  getNewText(text) {
    return text.toUpperCase()
  }
}
UpperCase.initClass()

class LowerCase extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.displayName = "Lower"
  }
  getNewText(text) {
    return text.toLowerCase()
  }
}
LowerCase.initClass()

// Replace
// -------------------------
class Replace extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.prototype.flashCheckpoint = "did-select-occurrence"
    this.prototype.input = null
    this.prototype.requireInput = true
    this.prototype.autoIndentNewline = true
    this.prototype.supportEarlySelect = true
  }

  constructor(...args) {
    super(...args)
    this.onDidSelectTarget(() => this.focusInput({hideCursor: true}))
  }

  getNewText(text) {
    if (this.target.is("MoveRightBufferColumn") && text.length !== this.getCount()) {
      return
    }

    const input = this.input || "\n"
    if (input === "\n") {
      this.restorePositions = false
    }
    return text.replace(/./g, input)
  }
}
Replace.initClass()

class ReplaceCharacter extends Replace {
  static initClass() {
    this.extend()
    this.prototype.target = "MoveRightBufferColumn"
  }
}
ReplaceCharacter.initClass()

// -------------------------
// DUP meaning with SplitString need consolidate.
class SplitByCharacter extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
  }
  getNewText(text) {
    return text.split("").join(" ")
  }
}
SplitByCharacter.initClass()

class CamelCase extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.displayName = "Camelize"
  }
  getNewText(text) {
    return _.camelize(text)
  }
}
CamelCase.initClass()

class SnakeCase extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.displayName = "Underscore _"
  }
  getNewText(text) {
    return _.underscore(text)
  }
}
SnakeCase.initClass()

class PascalCase extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.displayName = "Pascalize"
  }
  getNewText(text) {
    return _.capitalize(_.camelize(text))
  }
}
PascalCase.initClass()

class DashCase extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.displayName = "Dasherize -"
  }
  getNewText(text) {
    return _.dasherize(text)
  }
}
DashCase.initClass()

class TitleCase extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.displayName = "Titlize"
  }
  getNewText(text) {
    return _.humanizeEventName(_.dasherize(text))
  }
}
TitleCase.initClass()

class EncodeUriComponent extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.displayName = "Encode URI Component %"
  }
  getNewText(text) {
    return encodeURIComponent(text)
  }
}
EncodeUriComponent.initClass()

class DecodeUriComponent extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.displayName = "Decode URI Component %%"
  }
  getNewText(text) {
    return decodeURIComponent(text)
  }
}
DecodeUriComponent.initClass()

class TrimString extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.displayName = "Trim string"
  }
  getNewText(text) {
    return text.trim()
  }
}
TrimString.initClass()

class CompactSpaces extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.displayName = "Compact space"
  }
  getNewText(text) {
    if (text.match(/^[ ]+$/)) {
      return " "
    } else {
      // Don't compact for leading and trailing white spaces.
      const regex = /^(\s*)(.*?)(\s*)$/gm
      return text.replace(regex, (m, leading, middle, trailing) => {
        return leading + middle.split(/[ \t]+/).join(" ") + trailing
      })
    }
  }
}
CompactSpaces.initClass()

class RemoveLeadingWhiteSpaces extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.prototype.wise = "linewise"
  }
  getNewText(text, selection) {
    const trimLeft = text => text.trimLeft()
    return (
      splitTextByNewLine(text)
        .map(trimLeft)
        .join("\n") + "\n"
    )
  }
}
RemoveLeadingWhiteSpaces.initClass()

class ConvertToSoftTab extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.displayName = "Soft Tab"
    this.prototype.wise = "linewise"
  }

  mutateSelection(selection) {
    return this.scanForward(/\t/g, {scanRange: selection.getBufferRange()}, ({range, replace}) => {
      // Replace \t to spaces which length is vary depending on tabStop and tabLenght
      // So we directly consult it's screen representing length.
      const length = this.editor.screenRangeForBufferRange(range).getExtent().column
      return replace(" ".repeat(length))
    })
  }
}
ConvertToSoftTab.initClass()

class ConvertToHardTab extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.displayName = "Hard Tab"
  }

  mutateSelection(selection) {
    const tabLength = this.editor.getTabLength()
    this.scanForward(/[ \t]+/g, {scanRange: selection.getBufferRange()}, ({range, replace}) => {
      const {start, end} = this.editor.screenRangeForBufferRange(range)
      let startColumn = start.column
      const endColumn = end.column

      // We can't naively replace spaces to tab, we have to consider valid tabStop column
      // If nextTabStop column exceeds replacable range, we pad with spaces.
      let newText = ""
      while (true) {
        const remainder = startColumn % tabLength
        const nextTabStop = startColumn + (remainder === 0 ? tabLength : remainder)
        if (nextTabStop > endColumn) {
          newText += " ".repeat(endColumn - startColumn)
        } else {
          newText += "\t"
        }
        startColumn = nextTabStop
        if (startColumn >= endColumn) {
          break
        }
      }

      replace(newText)
    })
  }
}
ConvertToHardTab.initClass()

// -------------------------
class TransformStringByExternalCommand extends TransformString {
  static initClass() {
    this.extend(false)
    this.prototype.autoIndent = true
    this.prototype.command = "" // e.g. command: 'sort'
    this.prototype.args = [] // e.g args: ['-rn']
    this.prototype.stdoutBySelection = null
  }

  execute() {
    this.normalizeSelectionsIfNecessary()
    if (this.selectTarget()) {
      return new Promise(resolve => this.collect(resolve)).then(() => {
        for (const selection of this.editor.getSelections()) {
          const text = this.getNewText(selection.getText(), selection)
          selection.insertText(text, {autoIndent: this.autoIndent})
        }
        this.restoreCursorPositionsIfNecessary()
        this.activateMode(this.finalMode, this.finalSubmode)
      })
    }
  }

  collect(resolve) {
    this.stdoutBySelection = new Map()
    let processFinished = 0,
      processRunning = 0
    for (const selection of this.editor.getSelections()) {
      const {command, args} = this.getCommand(selection) || {}
      if (command == null || args == null) return

      processRunning++
      // const stdin = this.getStdin(selection)
      // const stdout = output => this.stdoutBySelection.set(selection, output)
      // const exit = code => {
      //   processFinished++
      //   if (processRunning === processFinished) resolve()
      // }
      this.runExternalCommand({
        command: command,
        args: args,
        stdin: this.getStdin(selection),
        stdout: output => this.stdoutBySelection.set(selection, output),
        exit: code => {
          processFinished++
          if (processRunning === processFinished) resolve()
        },
      })
    }
  }

  runExternalCommand(options) {
    const {stdin} = options
    delete options.stdin
    const bufferedProcess = new BufferedProcess(options)
    bufferedProcess.onWillThrowError(({error, handle}) => {
      // Suppress command not found error intentionally.
      if (error.code === "ENOENT" && error.syscall.indexOf("spawn") === 0) {
        const commandName = this.constructor.getCommandName()
        console.log(`${commandName}: Failed to spawn command ${error.path}.`)
        handle()
      }
      this.cancelOperation()
    })

    if (stdin) {
      bufferedProcess.process.stdin.write(stdin)
      bufferedProcess.process.stdin.end()
    }
  }

  getNewText(text, selection) {
    return this.getStdout(selection) || text
  }

  // For easily extend by vmp plugin.
  getCommand(selection) {
    return {command: this.command, args: this.args}
  }
  getStdin(selection) {
    return selection.getText()
  }
  getStdout(selection) {
    return this.stdoutBySelection.get(selection)
  }
}
TransformStringByExternalCommand.initClass()

// -------------------------
class TransformStringBySelectList extends TransformString {
  static initClass() {
    this.extend()
    this.selectListItems = null
    this.prototype.requireInput = true
  }

  static getSelectListItems() {
    if (!this.selectListItems) {
      this.selectListItems = this.stringTransformers.map(klass => ({
        klass: klass,
        displayName: klass.hasOwnProperty("displayName")
          ? klass.displayName
          : _.humanizeEventName(_.dasherize(klass.name)),
      }))
    }
    return this.selectListItems
  }

  getItems() {
    return this.constructor.getSelectListItems()
  }

  constructor(...args) {
    super(...args)

    this.vimState.onDidConfirmSelectList(item => {
      const transformer = item.klass
      if (transformer.prototype.target) {
        this.target = transformer.prototype.target
      }
      this.vimState.reset()
      if (this.target) {
        this.vimState.operationStack.run(transformer, {target: this.target})
      } else {
        this.vimState.operationStack.run(transformer)
      }
    })

    this.focusSelectList({items: this.getItems()})
  }

  execute() {
    // NEVER be executed since operationStack is replaced with selected transformer
    throw new Error(`${this.name} should not be executed`)
  }
}
TransformStringBySelectList.initClass()

class TransformWordBySelectList extends TransformStringBySelectList {
  static initClass() {
    this.extend()
    this.prototype.target = "InnerWord"
  }
}
TransformWordBySelectList.initClass()

class TransformSmartWordBySelectList extends TransformStringBySelectList {
  static initClass() {
    this.extend()
    this.prototype.target = "InnerSmartWord"
  }
}
TransformSmartWordBySelectList.initClass()

// -------------------------
class ReplaceWithRegister extends TransformString {
  static initClass() {
    this.extend()
    this.prototype.flashType = "operator-long"
  }

  constructor(...args) {
    super(...args)
    this.vimState.sequentialPasteManager.onInitialize(this)
  }

  execute() {
    this.sequentialPaste = this.vimState.sequentialPasteManager.onExecute(this)

    super.execute()

    for (const selection of this.editor.getSelections()) {
      const range = this.vimState.mutationManager.getMutatedBufferRangeForSelection(selection)
      this.vimState.sequentialPasteManager.savePastedRangeForSelection(selection, range)
    }
  }

  getNewText(text, selection) {
    const value = this.vimState.register.get(null, selection, this.sequentialPaste)
    return value ? value.text : ""
  }
}
ReplaceWithRegister.initClass()

// Save text to register before replace
class SwapWithRegister extends TransformString {
  static initClass() {
    this.extend()
  }
  getNewText(text, selection) {
    const newText = this.vimState.register.getText()
    this.setTextToRegister(text, selection)
    return newText
  }
}
SwapWithRegister.initClass()

// Indent < TransformString
// -------------------------
class Indent extends TransformString {
  static initClass() {
    this.extend()
    this.prototype.stayByMarker = true
    this.prototype.setToFirstCharacterOnLinewise = true
    this.prototype.wise = "linewise"
  }

  mutateSelection(selection) {
    // Need count times indentation in visual-mode and its repeat(`.`).
    if (this.target.is("CurrentSelection")) {
      let oldText
      // limit to 100 to avoid freezing by accidental big number.
      const count = limitNumber(this.getCount(), {max: 100})
      this.countTimes(count, ({stop}) => {
        oldText = selection.getText()
        this.indent(selection)
        if (selection.getText() === oldText) stop()
      })
    } else {
      this.indent(selection)
    }
  }

  indent(selection) {
    selection.indentSelectedRows()
  }
}
Indent.initClass()

class Outdent extends Indent {
  static initClass() {
    this.extend()
  }
  indent(selection) {
    selection.outdentSelectedRows()
  }
}
Outdent.initClass()

class AutoIndent extends Indent {
  static initClass() {
    this.extend()
  }
  indent(selection) {
    selection.autoIndentSelectedRows()
  }
}
AutoIndent.initClass()

class ToggleLineComments extends TransformString {
  static initClass() {
    this.extend()
    this.prototype.flashTarget = false
    this.prototype.stayByMarker = true
    this.prototype.wise = "linewise"
  }

  mutateSelection(selection) {
    selection.toggleLineComments()
  }
}
ToggleLineComments.initClass()

class Reflow extends TransformString {
  static initClass() {
    this.extend()
  }
  mutateSelection(selection) {
    atom.commands.dispatch(this.editorElement, "autoflow:reflow-selection")
  }
}
Reflow.initClass()

class ReflowWithStay extends Reflow {
  static initClass() {
    this.extend()
    this.prototype.stayAtSamePosition = true
  }
}
ReflowWithStay.initClass()

// Surround < TransformString
// -------------------------
class SurroundBase extends TransformString {
  static initClass() {
    this.extend(false)
    this.prototype.pairs = [["(", ")"], ["{", "}"], ["[", "]"], ["<", ">"]]
    this.prototype.pairsByAlias = {
      b: ["(", ")"],
      B: ["{", "}"],
      r: ["[", "]"],
      a: ["<", ">"],
    }

    this.prototype.pairCharsAllowForwarding = "[](){}"
    this.prototype.input = null
    this.prototype.requireInput = true
    this.prototype.supportEarlySelect = true // Experimental
  }

  focusInputForSurroundChar() {
    this.focusInput({hideCursor: true})
  }

  focusInputForTargetPairChar() {
    this.focusInput({onConfirm: char => this.onConfirmTargetPairChar(char)})
  }

  getPair(char) {
    let pair
    return char in this.pairsByAlias
      ? this.pairsByAlias[char]
      : [...this.pairs, [char, char]].find(pair => pair.includes(char))
  }

  surround(text, char, {keepLayout = false} = {}) {
    let [open, close] = this.getPair(char)
    if (!keepLayout && text.endsWith("\n")) {
      this.autoIndentAfterInsertText = true
      open += "\n"
      close += "\n"
    }

    if (this.getConfig("charactersToAddSpaceOnSurround").includes(char) && isSingleLineText(text)) {
      text = " " + text + " "
    }

    return open + text + close
  }

  deleteSurround(text) {
    // Assume surrounding char is one-char length.
    const open = text[0]
    const close = text[text.length - 1]
    const innerText = text.slice(1, text.length - 1)
    return isSingleLineText(text) && open !== close ? innerText.trim() : innerText
  }

  onConfirmTargetPairChar(char) {
    this.setTarget(this.new("APair").assign({pair: this.getPair(char)}))
  }
}
SurroundBase.initClass()

class Surround extends SurroundBase {
  static initClass() {
    this.extend()
  }

  constructor(...args) {
    super(...args)
    this.onDidSelectTarget(() => this.focusInputForSurroundChar())
  }

  getNewText(text) {
    return this.surround(text, this.input)
  }
}
Surround.initClass()

class SurroundWord extends Surround {
  static initClass() {
    this.extend()
    this.prototype.target = "InnerWord"
  }
}
SurroundWord.initClass()

class SurroundSmartWord extends Surround {
  static initClass() {
    this.extend()
    this.prototype.target = "InnerSmartWord"
  }
}
SurroundSmartWord.initClass()

class MapSurround extends Surround {
  static initClass() {
    this.extend()
    this.prototype.occurrence = true
    this.prototype.patternForOccurrence = /\w+/g
  }
}
MapSurround.initClass()

// Delete Surround
// -------------------------
class DeleteSurround extends SurroundBase {
  static initClass() {
    this.extend()
  }

  constructor(...args) {
    super(...args)
    if (!this.target) {
      this.focusInputForTargetPairChar()
    }
  }

  onConfirmTargetPairChar(char) {
    super.onConfirmTargetPairChar(char)
    this.input = char
    this.processOperation()
  }

  getNewText(text) {
    return this.deleteSurround(text)
  }
}
DeleteSurround.initClass()

class DeleteSurroundAnyPair extends DeleteSurround {
  static initClass() {
    this.extend()
    this.prototype.target = "AAnyPair"
    this.prototype.requireInput = false
  }
}
DeleteSurroundAnyPair.initClass()

class DeleteSurroundAnyPairAllowForwarding extends DeleteSurroundAnyPair {
  static initClass() {
    this.extend()
    this.prototype.target = "AAnyPairAllowForwarding"
  }
}
DeleteSurroundAnyPairAllowForwarding.initClass()

// Change Surround
// -------------------------
class ChangeSurround extends SurroundBase {
  static initClass() {
    this.extend()
  }

  showDeleteCharOnHover() {
    const hoverPoint = this.vimState.mutationManager.getInitialPointForSelection(this.editor.getLastSelection())
    const char = this.editor.getSelectedText()[0]
    this.vimState.hover.set(char, hoverPoint)
  }

  constructor(...args) {
    super(...args)

    if (this.target) {
      this.onDidFailSelectTarget(() => this.abort())
    } else {
      this.onDidFailSelectTarget(() => this.cancelOperation())
      this.focusInputForTargetPairChar()
    }

    this.onDidSelectTarget(() => {
      this.showDeleteCharOnHover()
      this.focusInputForSurroundChar()
    })
  }

  getNewText(text) {
    const innerText = this.deleteSurround(text)
    return this.surround(innerText, this.input, {keepLayout: true})
  }
}
ChangeSurround.initClass()

class ChangeSurroundAnyPair extends ChangeSurround {
  static initClass() {
    this.extend()
    this.prototype.target = "AAnyPair"
  }
}
ChangeSurroundAnyPair.initClass()

class ChangeSurroundAnyPairAllowForwarding extends ChangeSurroundAnyPair {
  static initClass() {
    this.extend()
    this.prototype.target = "AAnyPairAllowForwarding"
  }
}
ChangeSurroundAnyPairAllowForwarding.initClass()

// -------------------------
// FIXME
// Currently native editor.joinLines() is better for cursor position setting
// So I use native methods for a meanwhile.
class Join extends TransformString {
  static initClass() {
    this.extend()
    this.prototype.target = "MoveToRelativeLine"
    this.prototype.flashTarget = false
    this.prototype.restorePositions = false
  }

  mutateSelection(selection) {
    const range = selection.getBufferRange()

    // When cursor is at last BUFFER row, it select last-buffer-row, then
    // joinning result in "clear last-buffer-row text".
    // I believe this is BUG of upstream atom-core. guard this situation here
    if (!range.isSingleLine() || range.end.row !== this.editor.getLastBufferRow()) {
      if (isLinewiseRange(range)) {
        selection.setBufferRange(range.translate([0, 0], [-1, Infinity]))
      }
      selection.joinLines()
    }
    const {end} = selection.getBufferRange()
    return selection.cursor.setBufferPosition(end.translate([0, -1]))
  }
}
Join.initClass()

class JoinBase extends TransformString {
  static initClass() {
    this.extend(false)
    this.prototype.wise = "linewise"
    this.prototype.trim = false
    this.prototype.target = "MoveToRelativeLineMinimumOne"
  }

  constructor(...args) {
    super(...args)
    if (this.requireInput) {
      this.focusInput({charsMax: 10})
    }
  }

  getNewText(text) {
    let pattern
    if (this.trim) {
      pattern = /\r?\n[ \t]*/g
    } else {
      pattern = /\r?\n/g
    }
    return text.trimRight().replace(pattern, this.input) + "\n"
  }
}
JoinBase.initClass()

class JoinWithKeepingSpace extends JoinBase {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.prototype.input = ""
  }
}
JoinWithKeepingSpace.initClass()

class JoinByInput extends JoinBase {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.prototype.requireInput = true
    this.prototype.trim = true
  }
}
JoinByInput.initClass()

class JoinByInputWithKeepingSpace extends JoinByInput {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.prototype.trim = false
  }
}
JoinByInputWithKeepingSpace.initClass()

// -------------------------
// String suffix in name is to avoid confusion with 'split' window.
class SplitString extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.prototype.requireInput = true
    this.prototype.input = null
    this.prototype.target = "MoveToRelativeLine"
    this.prototype.keepSplitter = false
  }

  constructor(...args) {
    super(...args)
    this.onDidSetTarget(() => {
      this.focusInput({charsMax: 10})
    })
  }

  getNewText(text) {
    const input = this.input || "\\n"
    const regex = new RegExp(`${_.escapeRegExp(input)}`, "g")
    const lineSeparator = (this.keepSplitter ? this.input : "") + "\n"
    return text.replace(regex, lineSeparator)
  }
}
SplitString.initClass()

class SplitStringWithKeepingSplitter extends SplitString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.prototype.keepSplitter = true
  }
}
SplitStringWithKeepingSplitter.initClass()

class SplitArguments extends TransformString {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.prototype.keepSeparator = true
    this.prototype.autoIndentAfterInsertText = true
  }

  getNewText(text) {
    const allTokens = splitArguments(text.trim())
    let newText = ""
    while (allTokens.length) {
      var type
      ;({text, type} = allTokens.shift())
      if (type === "separator") {
        if (this.keepSeparator) {
          text = text.trim() + "\n"
        } else {
          text = "\n"
        }
      }
      newText += text
    }
    return `\n${newText}\n`
  }
}
SplitArguments.initClass()

class SplitArgumentsWithRemoveSeparator extends SplitArguments {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.prototype.keepSeparator = false
  }
}
SplitArgumentsWithRemoveSeparator.initClass()

class SplitArgumentsOfInnerAnyPair extends SplitArguments {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.prototype.target = "InnerAnyPair"
  }
}
SplitArgumentsOfInnerAnyPair.initClass()

class ChangeOrder extends TransformString {
  static initClass() {
    this.extend(false)
  }
  getNewText(text) {
    if (this.target.isLinewise()) {
      return this.getNewList(splitTextByNewLine(text)).join("\n") + "\n"
    } else {
      return this.sortArgumentsInTextBy(text, args => this.getNewList(args))
    }
  }

  sortArgumentsInTextBy(text, fn) {
    let trailingSpaces
    let leadingSpaces = (trailingSpaces = "")
    const start = text.search(/\S/)
    const end = text.search(/\s*$/)
    leadingSpaces = trailingSpaces = ""
    if (start !== -1) {
      leadingSpaces = text.slice(0, start)
    }
    if (end !== -1) {
      trailingSpaces = text.slice(end)
    }
    text = text.slice(start, end)

    const allTokens = splitArguments(text)
    const args = allTokens.filter(token => token.type === "argument").map(token => token.text)
    const newArgs = fn(args)

    let newText = ""
    while (allTokens.length) {
      var type
      ;({text, type} = allTokens.shift())
      newText += (() => {
        switch (type) {
          case "separator":
            return text
          case "argument":
            return newArgs.shift()
        }
      })()
    }
    return leadingSpaces + newText + trailingSpaces
  }
}
ChangeOrder.initClass()

class Reverse extends ChangeOrder {
  static initClass() {
    this.extend()
    this.registerToSelectList()
  }
  getNewList(rows) {
    return rows.reverse()
  }
}
Reverse.initClass()

class ReverseInnerAnyPair extends Reverse {
  static initClass() {
    this.extend()
    this.prototype.target = "InnerAnyPair"
  }
}
ReverseInnerAnyPair.initClass()

class Rotate extends ChangeOrder {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.prototype.backwards = false
  }
  getNewList(rows) {
    if (this.backwards) {
      rows.push(rows.shift())
    } else {
      rows.unshift(rows.pop())
    }
    return rows
  }
}
Rotate.initClass()

class RotateBackwards extends ChangeOrder {
  static initClass() {
    this.extend()
    this.registerToSelectList()
    this.prototype.backwards = true
  }
}
RotateBackwards.initClass()

class RotateArgumentsOfInnerPair extends Rotate {
  static initClass() {
    this.extend()
    this.prototype.target = "InnerAnyPair"
  }
}
RotateArgumentsOfInnerPair.initClass()

class RotateArgumentsBackwardsOfInnerPair extends RotateArgumentsOfInnerPair {
  static initClass() {
    this.extend()
    this.prototype.backwards = true
  }
}
RotateArgumentsBackwardsOfInnerPair.initClass()

class Sort extends ChangeOrder {
  static initClass() {
    this.extend()
    this.registerToSelectList()
  }
  getNewList(rows) {
    return rows.sort()
  }
}
Sort.initClass()

class SortCaseInsensitively extends ChangeOrder {
  static initClass() {
    this.extend()
    this.registerToSelectList()
  }
  getNewList(rows) {
    return rows.sort((rowA, rowB) => rowA.localeCompare(rowB, {sensitivity: "base"}))
  }
}
SortCaseInsensitively.initClass()

class SortByNumber extends ChangeOrder {
  static initClass() {
    this.extend()
    this.registerToSelectList()
  }
  getNewList(rows) {
    return _.sortBy(rows, row => Number.parseInt(row) || Infinity)
  }
}
SortByNumber.initClass()
