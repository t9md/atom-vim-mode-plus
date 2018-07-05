'use babel'

const changeCase = require('change-case')
let selectList

const {BufferedProcess} = require('atom')
const {Operator} = require('./operator')

// TransformString
// ================================
class TransformString extends Operator {
  static command = false
  static stringTransformers = []
  trackChange = true
  stayOptionName = 'stayOnTransformString'
  autoIndent = false
  autoIndentNewline = false
  replaceByDiff = false

  static registerToSelectList () {
    this.stringTransformers.push(this)
  }

  mutateSelection (selection) {
    const text = this.getNewText(selection.getText(), selection)
    if (text) {
      if (this.replaceByDiff) {
        this.replaceTextInRangeViaDiff(selection.getBufferRange(), text)
      } else {
        selection.insertText(text, {autoIndent: this.autoIndent, autoIndentNewline: this.autoIndentNewline})
      }
    }
  }
}

class ChangeCase extends TransformString {
  static command = false
  getNewText (text) {
    const functionName = this.functionName || changeCase.lowerCaseFirst(this.name)
    // HACK: Pure Vim's `~` is too aggressive(e.g. remove punctuation, remove white spaces...).
    // Here intentionally making changeCase less aggressive by narrowing target charset.
    const charset = '[\u00C0-\u02AF\u0386-\u0587\\w]'
    const regex = new RegExp(`${charset}+(:?[-./]?${charset}+)*`, 'g')
    return text.replace(regex, match => changeCase[functionName](match))
  }
}

class NoCase extends ChangeCase {}
class DotCase extends ChangeCase {
  static displayNameSuffix = '.'
}
class SwapCase extends ChangeCase {
  static displayNameSuffix = '~'
}
class PathCase extends ChangeCase {
  static displayNameSuffix = '/'
}
class UpperCase extends ChangeCase {}
class LowerCase extends ChangeCase {}
class CamelCase extends ChangeCase {}
class SnakeCase extends ChangeCase {
  static displayNameSuffix = '_'
}
class TitleCase extends ChangeCase {}
class ParamCase extends ChangeCase {
  static displayNameSuffix = '-'
}
class HeaderCase extends ChangeCase {}
class PascalCase extends ChangeCase {}
class ConstantCase extends ChangeCase {}
class SentenceCase extends ChangeCase {}
class UpperCaseFirst extends ChangeCase {}
class LowerCaseFirst extends ChangeCase {}

class DashCase extends ChangeCase {
  static displayNameSuffix = '-'
  functionName = 'paramCase'
}
class ToggleCase extends ChangeCase {
  static displayNameSuffix = '~'
  functionName = 'swapCase'
}

class ToggleCaseAndMoveRight extends ChangeCase {
  functionName = 'swapCase'
  flashTarget = false
  restorePositions = false
  target = 'MoveRight'
}

// Replace
// -------------------------
class Replace extends TransformString {
  flashCheckpoint = 'did-select-occurrence'
  autoIndentNewline = true
  readInputAfterSelect = true

  getNewText (text) {
    if (this.target.name === 'MoveRightBufferColumn' && text.length !== this.getCount()) {
      return
    }

    const input = this.input || '\n'
    if (input === '\n') {
      this.restorePositions = false
    }
    return text.replace(/./g, input)
  }
}

class ReplaceCharacter extends Replace {
  target = 'MoveRightBufferColumn'
}

// -------------------------
// DUP meaning with SplitString need consolidate.
class SplitByCharacter extends TransformString {
  getNewText (text) {
    return text.split('').join(' ')
  }
}

class EncodeUriComponent extends TransformString {
  static displayNameSuffix = '%'
  getNewText (text) {
    return encodeURIComponent(text)
  }
}

class DecodeUriComponent extends TransformString {
  static displayNameSuffix = '%%'
  getNewText (text) {
    return decodeURIComponent(text)
  }
}

class TrimString extends TransformString {
  stayByMarker = true
  replaceByDiff = true

  getNewText (text) {
    return text.trim()
  }
}

class CompactSpaces extends TransformString {
  getNewText (text) {
    if (text.match(/^[ ]+$/)) {
      return ' '
    } else {
      // Don't compact for leading and trailing white spaces.
      const regex = /^(\s*)(.*?)(\s*)$/gm
      return text.replace(regex, (m, leading, middle, trailing) => {
        return leading + middle.split(/[ \t]+/).join(' ') + trailing
      })
    }
  }
}

class AlignOccurrence extends TransformString {
  occurrence = true
  whichToPad = 'auto'

  getSelectionTaker () {
    const selectionsByRow = {}
    for (const selection of this.editor.getSelectionsOrderedByBufferPosition()) {
      const row = selection.getBufferRange().start.row
      if (!(row in selectionsByRow)) selectionsByRow[row] = []
      selectionsByRow[row].push(selection)
    }
    const allRows = Object.keys(selectionsByRow)
    return () => allRows.map(row => selectionsByRow[row].shift()).filter(s => s)
  }

  getWichToPadForText (text) {
    if (this.whichToPad !== 'auto') return this.whichToPad

    if (/^\s*[=|]\s*$/.test(text)) {
      // Asignment(=) and `|`(markdown-table separator)
      return 'start'
    } else if (/^\s*,\s*$/.test(text)) {
      // Arguments
      return 'end'
    } else if (/\W$/.test(text)) {
      // ends with non-word-char
      return 'end'
    } else {
      return 'start'
    }
  }

  calculatePadding () {
    const totalAmountOfPaddingByRow = {}
    const columnForSelection = selection => {
      const which = this.getWichToPadForText(selection.getText())
      const point = selection.getBufferRange()[which]
      return point.column + (totalAmountOfPaddingByRow[point.row] || 0)
    }

    const takeSelections = this.getSelectionTaker()
    while (true) {
      const selections = takeSelections()
      if (!selections.length) return
      const maxColumn = selections.map(columnForSelection).reduce((max, cur) => (cur > max ? cur : max))
      for (const selection of selections) {
        const row = selection.getBufferRange().start.row
        const amountOfPadding = maxColumn - columnForSelection(selection)
        totalAmountOfPaddingByRow[row] = (totalAmountOfPaddingByRow[row] || 0) + amountOfPadding
        this.amountOfPaddingBySelection.set(selection, amountOfPadding)
      }
    }
  }

  execute () {
    this.amountOfPaddingBySelection = new Map()
    this.onDidSelectTarget(() => {
      this.calculatePadding()
    })
    super.execute()
  }

  getNewText (text, selection) {
    const padding = ' '.repeat(this.amountOfPaddingBySelection.get(selection))
    const whichToPad = this.getWichToPadForText(selection.getText())
    return whichToPad === 'start' ? padding + text : text + padding
  }
}

class AlignOccurrenceByPadLeft extends AlignOccurrence {
  whichToPad = 'start'
}

class AlignOccurrenceByPadRight extends AlignOccurrence {
  whichToPad = 'end'
}

class RemoveLeadingWhiteSpaces extends TransformString {
  wise = 'linewise'
  getNewText (text, selection) {
    const trimLeft = text => text.trimLeft()
    return (
      this.utils
        .splitTextByNewLine(text)
        .map(trimLeft)
        .join('\n') + '\n'
    )
  }
}

class ConvertToSoftTab extends TransformString {
  static displayName = 'Soft Tab'
  wise = 'linewise'

  mutateSelection (selection) {
    this.scanEditor('forward', /\t/g, {scanRange: selection.getBufferRange()}, ({range, replace}) => {
      // Replace \t to spaces which length is vary depending on tabStop and tabLenght
      // So we directly consult it's screen representing length.
      const length = this.editor.screenRangeForBufferRange(range).getExtent().column
      replace(' '.repeat(length))
    })
  }
}

class ConvertToHardTab extends TransformString {
  static displayName = 'Hard Tab'

  mutateSelection (selection) {
    const tabLength = this.editor.getTabLength()
    this.scanEditor('forward', /[ \t]+/g, {scanRange: selection.getBufferRange()}, ({range, replace}) => {
      const {start, end} = this.editor.screenRangeForBufferRange(range)
      let startColumn = start.column
      const endColumn = end.column

      // We can't naively replace spaces to tab, we have to consider valid tabStop column
      // If nextTabStop column exceeds replacable range, we pad with spaces.
      let newText = ''
      while (true) {
        const remainder = startColumn % tabLength
        const nextTabStop = startColumn + (remainder === 0 ? tabLength : remainder)
        if (nextTabStop > endColumn) {
          newText += ' '.repeat(endColumn - startColumn)
        } else {
          newText += '\t'
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

// -------------------------
class TransformStringByExternalCommand extends TransformString {
  static command = false
  autoIndent = true
  command = '' // e.g. command: 'sort'
  args = [] // e.g args: ['-rn']

  // NOTE: Unlike other class, first arg is `stdout` of external commands.
  getNewText (text, selection) {
    return text || selection.getText()
  }
  getCommand (selection) {
    return {command: this.command, args: this.args}
  }
  getStdin (selection) {
    return selection.getText()
  }

  async execute () {
    this.preSelect()

    if (this.selectTarget()) {
      for (const selection of this.editor.getSelections()) {
        const {command, args} = this.getCommand(selection) || {}
        if (command == null || args == null) continue

        const stdout = await this.runExternalCommand({command, args, stdin: this.getStdin(selection)})
        selection.insertText(this.getNewText(stdout, selection), {autoIndent: this.autoIndent})
      }
      this.mutationManager.setCheckpoint('did-finish')
      this.restoreCursorPositionsIfNecessary()
    }
    this.postMutate()
  }

  runExternalCommand (options) {
    let output = ''
    options.stdout = data => (output += data)
    const exitPromise = new Promise(resolve => {
      options.exit = () => resolve(output)
    })
    const {stdin} = options
    delete options.stdin
    const bufferedProcess = new BufferedProcess(options)
    bufferedProcess.onWillThrowError(({error, handle}) => {
      // Suppress command not found error intentionally.
      if (error.code === 'ENOENT' && error.syscall.indexOf('spawn') === 0) {
        console.log(`${this.getCommandName()}: Failed to spawn command ${error.path}.`)
        handle()
      }
      this.cancelOperation()
    })

    if (stdin) {
      bufferedProcess.process.stdin.write(stdin)
      bufferedProcess.process.stdin.end()
    }
    return exitPromise
  }
}

// -------------------------
class TransformStringBySelectList extends TransformString {
  target = 'Empty'
  recordable = false

  static getSelectListItems () {
    if (!this.selectListItems) {
      this.selectListItems = this.stringTransformers.map(klass => {
        const suffix = klass.hasOwnProperty('displayNameSuffix') ? ' ' + klass.displayNameSuffix : ''

        return {
          klass: klass,
          displayName: klass.hasOwnProperty('displayName')
            ? klass.displayName + suffix
            : this._.humanizeEventName(this._.dasherize(klass.name)) + suffix
        }
      })
    }
    return this.selectListItems
  }

  selectItems () {
    if (!selectList) {
      const SelectList = require('./select-list')
      selectList = new SelectList()
    }
    return selectList.selectFromItems(this.constructor.getSelectListItems())
  }

  async execute () {
    const item = await this.selectItems()
    if (item) {
      this.vimState.operationStack.runNext(item.klass, {target: this.nextTarget})
    }
  }
}

class TransformWordBySelectList extends TransformStringBySelectList {
  nextTarget = 'InnerWord'
}

class TransformSmartWordBySelectList extends TransformStringBySelectList {
  nextTarget = 'InnerSmartWord'
}

// -------------------------
class ReplaceWithRegister extends TransformString {
  flashType = 'operator-long'

  initialize () {
    this.vimState.sequentialPasteManager.onInitialize(this)
    super.initialize()
  }

  execute () {
    this.sequentialPaste = this.vimState.sequentialPasteManager.onExecute(this)

    super.execute()

    for (const selection of this.editor.getSelections()) {
      const range = this.mutationManager.getMutatedBufferRangeForSelection(selection)
      this.vimState.sequentialPasteManager.savePastedRangeForSelection(selection, range)
    }
  }

  getNewText (text, selection) {
    const value = this.vimState.register.get(null, selection, this.sequentialPaste)
    return value ? value.text : ''
  }
}

class ReplaceOccurrenceWithRegister extends ReplaceWithRegister {
  occurrence = true
}

// Save text to register before replace
class SwapWithRegister extends TransformString {
  getNewText (text, selection) {
    const newText = this.vimState.register.getText()
    this.setTextToRegister(text, selection)
    return newText
  }
}

// Indent < TransformString
// -------------------------
class Indent extends TransformString {
  stayByMarker = true
  setToFirstCharacterOnLinewise = true
  wise = 'linewise'

  mutateSelection (selection) {
    // Need count times indentation in visual-mode and its repeat(`.`).
    if (this.target.name === 'CurrentSelection') {
      let oldText
      // limit to 100 to avoid freezing by accidental big number.
      this.countTimes(this.limitNumber(this.getCount(), {max: 100}), ({stop}) => {
        oldText = selection.getText()
        this.indent(selection)
        if (selection.getText() === oldText) stop()
      })
    } else {
      this.indent(selection)
    }
  }

  indent (selection) {
    selection.indentSelectedRows()
  }
}

class Outdent extends Indent {
  indent (selection) {
    selection.outdentSelectedRows()
  }
}

class AutoIndent extends Indent {
  indent (selection) {
    selection.autoIndentSelectedRows()
  }
}

class ToggleLineComments extends TransformString {
  flashTarget = false
  stayByMarker = true
  stayAtSamePosition = true
  wise = 'linewise'

  mutateSelection (selection) {
    selection.toggleLineComments()
  }
}

class Reflow extends TransformString {
  mutateSelection (selection) {
    atom.commands.dispatch(this.editorElement, 'autoflow:reflow-selection')
  }
}

class ReflowWithStay extends Reflow {
  stayAtSamePosition = true
}

// Surround < TransformString
// -------------------------
class SurroundBase extends TransformString {
  static command = false
  surroundAction = null
  pairs = [['(', ')'], ['{', '}'], ['[', ']'], ['<', '>']]
  pairsByAlias = {
    b: ['(', ')'],
    B: ['{', '}'],
    r: ['[', ']'],
    a: ['<', '>']
  }

  initialize () {
    this.replaceByDiff = this.getConfig('replaceByDiffOnSurround')
    this.stayByMarker = this.replaceByDiff
    super.initialize()
  }

  getPair (char) {
    return char in this.pairsByAlias
      ? this.pairsByAlias[char]
      : [...this.pairs, [char, char]].find(pair => pair.includes(char))
  }

  surround (text, char, {keepLayout = false, selection} = {}) {
    let [open, close] = this.getPair(char)
    if (!keepLayout && text.endsWith('\n')) {
      const baseIndentLevel = this.editor.indentationForBufferRow(selection.getBufferRange().start.row)
      const indentTextStartRow = this.editor.buildIndentString(baseIndentLevel)
      const indentTextOneLevel = this.editor.buildIndentString(1)

      open = indentTextStartRow + open + '\n'
      text = text.replace(/^(.+)$/gm, m => indentTextOneLevel + m)
      close = indentTextStartRow + close + '\n'
    }

    if (this.getConfig('charactersToAddSpaceOnSurround').includes(char) && this.utils.isSingleLineText(text)) {
      text = ' ' + text + ' '
    }

    return open + text + close
  }

  deleteSurround (text) {
    // Assume surrounding char is one-char length.
    const open = text[0]
    const close = text[text.length - 1]
    const innerText = text.slice(1, text.length - 1)
    return this.utils.isSingleLineText(text) && open !== close ? innerText.trim() : innerText
  }

  getNewText (text, selection) {
    if (this.surroundAction === 'surround') {
      return this.surround(text, this.input, {selection})
    } else if (this.surroundAction === 'delete-surround') {
      return this.deleteSurround(text)
    } else if (this.surroundAction === 'change-surround') {
      return this.surround(this.deleteSurround(text), this.input, {keepLayout: true})
    }
  }
}

class Surround extends SurroundBase {
  surroundAction = 'surround'
  readInputAfterSelect = true
}

class SurroundWord extends Surround {
  target = 'InnerWord'
}

class SurroundSmartWord extends Surround {
  target = 'InnerSmartWord'
}

class MapSurround extends Surround {
  occurrence = true
  patternForOccurrence = /\w+/g
}

// Delete Surround
// -------------------------
class DeleteSurround extends SurroundBase {
  surroundAction = 'delete-surround'
  initialize () {
    if (!this.target) {
      this.focusInput({
        onConfirm: char => {
          this.setTarget(this.getInstance('APair', {pair: this.getPair(char)}))
          this.processOperation()
        }
      })
    }
    super.initialize()
  }
}

class DeleteSurroundAnyPair extends DeleteSurround {
  target = 'AAnyPair'
}

class DeleteSurroundAnyPairAllowForwarding extends DeleteSurroundAnyPair {
  target = 'AAnyPairAllowForwarding'
}

// Change Surround
// -------------------------
class ChangeSurround extends DeleteSurround {
  surroundAction = 'change-surround'
  readInputAfterSelect = true

  // Override to show changing char on hover
  async focusInputPromised (...args) {
    const hoverPoint = this.mutationManager.getInitialPointForSelection(this.editor.getLastSelection())
    this.vimState.hover.set(this.editor.getSelectedText()[0], hoverPoint)
    return super.focusInputPromised(...args)
  }
}

class ChangeSurroundAnyPair extends ChangeSurround {
  target = 'AAnyPair'
}

class ChangeSurroundAnyPairAllowForwarding extends ChangeSurroundAnyPair {
  target = 'AAnyPairAllowForwarding'
}

// -------------------------
// FIXME
// Currently native editor.joinLines() is better for cursor position setting
// So I use native methods for a meanwhile.
class JoinTarget extends TransformString {
  flashTarget = false
  restorePositions = false

  mutateSelection (selection) {
    const range = selection.getBufferRange()

    // When cursor is at last BUFFER row, it select last-buffer-row, then
    // joinning result in "clear last-buffer-row text".
    // I believe this is BUG of upstream atom-core. guard this situation here
    if (!range.isSingleLine() || range.end.row !== this.editor.getLastBufferRow()) {
      if (this.utils.isLinewiseRange(range)) {
        selection.setBufferRange(range.translate([0, 0], [-1, Infinity]))
      }
      selection.joinLines()
    }
    const point = selection.getBufferRange().end.translate([0, -1])
    return selection.cursor.setBufferPosition(point)
  }
}

class Join extends JoinTarget {
  target = 'MoveToRelativeLine'
}

class JoinBase extends TransformString {
  static command = false
  wise = 'linewise'
  trim = false
  target = 'MoveToRelativeLineMinimumTwo'

  getNewText (text) {
    const regex = this.trim ? /\r?\n[ \t]*/g : /\r?\n/g
    return text.trimRight().replace(regex, this.input) + '\n'
  }
}

class JoinWithKeepingSpace extends JoinBase {
  input = ''
}

class JoinByInput extends JoinBase {
  readInputAfterSelect = true
  focusInputOptions = {charsMax: 10}
  trim = true
}

class JoinByInputWithKeepingSpace extends JoinByInput {
  trim = false
}

// -------------------------
// String suffix in name is to avoid confusion with 'split' window.
class SplitString extends TransformString {
  target = 'MoveToRelativeLine'
  keepSplitter = false
  readInputAfterSelect = true
  focusInputOptions = {charsMax: 10}

  getNewText (text) {
    const regex = new RegExp(this._.escapeRegExp(this.input || '\\n'), 'g')
    const lineSeparator = (this.keepSplitter ? this.input : '') + '\n'
    return text.replace(regex, lineSeparator)
  }
}

class SplitStringWithKeepingSplitter extends SplitString {
  keepSplitter = true
}

class SplitArguments extends TransformString {
  keepSeparator = true

  getNewText (text, selection) {
    const allTokens = this.utils.splitArguments(text.trim())
    let newText = ''

    const baseIndentLevel = this.editor.indentationForBufferRow(selection.getBufferRange().start.row)
    const indentTextStartRow = this.editor.buildIndentString(baseIndentLevel)
    const indentTextInnerRows = this.editor.buildIndentString(baseIndentLevel + 1)

    while (allTokens.length) {
      const {text, type} = allTokens.shift()
      newText += type === 'separator' ? (this.keepSeparator ? text.trim() : '') + '\n' : indentTextInnerRows + text
    }
    return `\n${newText}\n${indentTextStartRow}`
  }
}

class SplitArgumentsWithRemoveSeparator extends SplitArguments {
  keepSeparator = false
}

class SplitArgumentsOfInnerAnyPair extends SplitArguments {
  target = 'InnerAnyPair'
}

class ChangeOrder extends TransformString {
  static command = false
  action = null
  sortBy = null

  getNewText (text) {
    return this.target.isLinewise()
      ? this.getNewList(this.utils.splitTextByNewLine(text)).join('\n') + '\n'
      : this.sortArgumentsInTextBy(text, args => this.getNewList(args))
  }

  getNewList (rows) {
    if (rows.length === 1) {
      return [this.utils.changeCharOrder(rows[0], this.action, this.sortBy)]
    } else {
      return this.utils.changeArrayOrder(rows, this.action, this.sortBy)
    }
  }

  sortArgumentsInTextBy (text, fn) {
    const start = text.search(/\S/)
    const end = text.search(/\s*$/)
    const leadingSpaces = start !== -1 ? text.slice(0, start) : ''
    const trailingSpaces = end !== -1 ? text.slice(end) : ''
    const allTokens = this.utils.splitArguments(text.slice(start, end))
    const args = allTokens.filter(token => token.type === 'argument').map(token => token.text)
    const newArgs = fn(args)

    let newText = ''
    while (allTokens.length) {
      const token = allTokens.shift()
      // token.type is "separator" or "argument"
      newText += token.type === 'separator' ? token.text : newArgs.shift()
    }
    return leadingSpaces + newText + trailingSpaces
  }
}

class Reverse extends ChangeOrder {
  action = 'reverse'
}

class ReverseInnerAnyPair extends Reverse {
  target = 'InnerAnyPair'
}

class Rotate extends ChangeOrder {
  action = 'rotate-left'
}

class RotateBackwards extends ChangeOrder {
  action = 'rotate-right'
}

class RotateArgumentsOfInnerPair extends Rotate {
  target = 'InnerAnyPair'
}

class RotateArgumentsBackwardsOfInnerPair extends RotateBackwards {
  target = 'InnerAnyPair'
}

class Sort extends ChangeOrder {
  action = 'sort'
}

class SortCaseInsensitively extends Sort {
  sortBy = (rowA, rowB) => rowA.localeCompare(rowB, {sensitivity: 'base'})
}

class SortByNumber extends Sort {
  sortBy = (rowA, rowB) => (Number.parseInt(rowA) || Infinity) - (Number.parseInt(rowB) || Infinity)
}

class NumberingLines extends TransformString {
  wise = 'linewise'

  getNewText (text) {
    const rows = this.utils.splitTextByNewLine(text)
    const lastRowWidth = String(rows.length).length

    const newRows = rows.map((rowText, i) => {
      i++ // fix 0 start index to 1 start.
      const amountOfPadding = this.limitNumber(lastRowWidth - String(i).length, {min: 0})
      return ' '.repeat(amountOfPadding) + i + ': ' + rowText
    })
    return newRows.join('\n') + '\n'
  }
}

class DuplicateWithCommentOutOriginal extends TransformString {
  wise = 'linewise'
  stayByMarker = true
  stayAtSamePosition = true
  mutateSelection (selection) {
    const [startRow, endRow] = selection.getBufferRowRange()
    selection.setBufferRange(this.utils.insertTextAtBufferPosition(this.editor, [startRow, 0], selection.getText()))
    this.editor.toggleLineCommentsForBufferRows(startRow, endRow)
  }
}

module.exports = {
  TransformString,

  NoCase,
  DotCase,
  SwapCase,
  PathCase,
  UpperCase,
  LowerCase,
  CamelCase,
  SnakeCase,
  TitleCase,
  ParamCase,
  HeaderCase,
  PascalCase,
  ConstantCase,
  SentenceCase,
  UpperCaseFirst,
  LowerCaseFirst,
  DashCase,
  ToggleCase,
  ToggleCaseAndMoveRight,

  Replace,
  ReplaceCharacter,
  SplitByCharacter,
  EncodeUriComponent,
  DecodeUriComponent,
  TrimString,
  CompactSpaces,
  AlignOccurrence,
  AlignOccurrenceByPadLeft,
  AlignOccurrenceByPadRight,
  RemoveLeadingWhiteSpaces,
  ConvertToSoftTab,
  ConvertToHardTab,
  TransformStringByExternalCommand,
  TransformStringBySelectList,
  TransformWordBySelectList,
  TransformSmartWordBySelectList,
  ReplaceWithRegister,
  ReplaceOccurrenceWithRegister,
  SwapWithRegister,
  Indent,
  Outdent,
  AutoIndent,
  ToggleLineComments,
  Reflow,
  ReflowWithStay,
  SurroundBase,
  Surround,
  SurroundWord,
  SurroundSmartWord,
  MapSurround,
  DeleteSurround,
  DeleteSurroundAnyPair,
  DeleteSurroundAnyPairAllowForwarding,
  ChangeSurround,
  ChangeSurroundAnyPair,
  ChangeSurroundAnyPairAllowForwarding,
  JoinTarget,
  Join,
  JoinBase,
  JoinWithKeepingSpace,
  JoinByInput,
  JoinByInputWithKeepingSpace,
  SplitString,
  SplitStringWithKeepingSplitter,
  SplitArguments,
  SplitArgumentsWithRemoveSeparator,
  SplitArgumentsOfInnerAnyPair,
  ChangeOrder,
  Reverse,
  ReverseInnerAnyPair,
  Rotate,
  RotateBackwards,
  RotateArgumentsOfInnerPair,
  RotateArgumentsBackwardsOfInnerPair,
  Sort,
  SortCaseInsensitively,
  SortByNumber,
  NumberingLines,
  DuplicateWithCommentOutOriginal
}
for (const klass of Object.values(module.exports)) {
  if (klass.isCommand()) klass.registerToSelectList()
}
