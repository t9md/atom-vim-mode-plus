"use babel"

const {Range, Point} = require("atom")
const _ = require("underscore-plus")

// [TODO] Need overhaul
//  - [ ] Make expandable by selection.getBufferRange().union(@getRange(selection))
//  - [ ] Count support(priority low)?
const Base = require("./base")
const {
  getLineTextToBufferPosition,
  getCodeFoldRowRangesContainesForRow,
  isIncludeFunctionScopeForRow,
  expandRangeToWhiteSpaces,
  getVisibleBufferRange,
  translatePointAndClip,
  getBufferRows,
  getValidVimBufferRow,
  trimRange,
  sortRanges,
  pointIsAtEndOfLine,
  splitArguments,
  traverseTextFromPoint,
} = require("./utils")
let PairFinder

class TextObject extends Base {
  static operationKind = "text-object"

  wise = "characterwise"
  supportCount = false // FIXME #472, #66
  selectOnce = false
  selectSucceeded = false

  static initClass(isCommand, deriveInnerAndA, deriveInnerAndAForAllowForwarding) {
    super.initClass(isCommand)

    if (deriveInnerAndA) {
      this.generateClass(`A${this.name}`, false)
      this.generateClass(`Inner${this.name}`, true)
    }

    if (deriveInnerAndAForAllowForwarding) {
      this.generateClass(`A${this.name}AllowForwarding`, false, true)
      this.generateClass(`Inner${this.name}AllowForwarding`, true, true)
    }
  }

  static generateClass(klassName, inner, allowForwarding) {
    const klass = class extends this {
      constructor(vimState) {
        super(vimState)
        if (inner != null) this.inner = inner
        if (allowForwarding != null) this.allowForwarding = allowForwarding
      }
    }
    Object.defineProperty(klass, "name", {
      get() {
        return klassName
      },
    })
    klass.initClass()
  }

  isInner() {
    return this.inner
  }

  isA() {
    return !this.inner
  }

  isLinewise() {
    return this.wise === "linewise"
  }

  isBlockwise() {
    return this.wise === "blockwise"
  }

  forceWise(wise) {
    return (this.wise = wise) // FIXME currently not well supported
  }

  resetState() {
    this.selectSucceeded = false
  }

  execute() {
    // Whennever TextObject is executed, it has @operator
    // Called from Operator::selectTarget()
    //  - `v i p`, is `SelectInVisualMode` operator with @target = `InnerParagraph`.
    //  - `d i p`, is `Delete` operator with @target = `InnerParagraph`.
    if (this.operator != null) {
      return this.select()
    } else {
      throw new Error("in TextObject: Must not happen")
    }
  }

  select() {
    if (this.isMode("visual", "blockwise")) {
      this.swrap.normalize(this.editor)
    }

    this.countTimes(this.getCount(), ({stop}) => {
      if (!this.supportCount) stop() // quick-fix for #560

      for (const selection of this.editor.getSelections()) {
        const oldRange = selection.getBufferRange()
        if (this.selectTextObject(selection)) this.selectSucceeded = true
        if (selection.getBufferRange().isEqual(oldRange)) stop()
        if (this.selectOnce) break
      }
    })

    this.editor.mergeIntersectingSelections()
    // Some TextObject's wise is NOT deterministic. It has to be detected from selected range.
    if (this.wise == null) this.wise = this.swrap.detectWise(this.editor)

    if (this.operator.instanceof("SelectBase")) {
      if (this.selectSucceeded) {
        if (this.wise === "characterwise") {
          this.swrap.getSelections(this.editor).forEach($selection => $selection.saveProperties())
          for (const $selection of this.swrap.getSelections(this.editor)) {
            $selection.saveProperties()
          }
        } else if (this.wise === "linewise") {
          // When target is persistent-selection, new selection is added after selectTextObject.
          // So we have to assure all selection have selction property.
          // Maybe this logic can be moved to operation stack.
          for (const $selection of this.swrap.getSelections(this.editor)) {
            if (this.getConfig("stayOnSelectTextObject")) {
              if (!$selection.hasProperties()) $selection.saveProperties()
            } else {
              $selection.saveProperties()
            }
            $selection.fixPropertyRowToRowRange()
          }
        }
      }

      if (this.submode === "blockwise") {
        for (const $selection of this.swrap.getSelections(this.editor)) {
          $selection.normalize()
          $selection.applyWise("blockwise")
        }
      }
    }
  }

  // Return true or false
  selectTextObject(selection) {
    const range = this.getRange(selection)
    if (range) {
      this.swrap(selection).setBufferRange(range)
      return true
    } else {
      return false
    }
  }

  // to override
  getRange(selection) {}
}
TextObject.initClass(false)

// Section: Word
// =========================
class Word extends TextObject {
  getRange(selection) {
    const point = this.getCursorPositionForSelection(selection)
    const {range} = this.getWordBufferRangeAndKindAtBufferPosition(point, {wordRegex: this.wordRegex})
    return this.isA() ? expandRangeToWhiteSpaces(this.editor, range) : range
  }
}
Word.initClass(false, true)

class WholeWord extends Word {
  wordRegex = /\S+/
}
WholeWord.initClass(false, true)

// Just include _, -
class SmartWord extends Word {
  wordRegex = /[\w-]+/
}
SmartWord.initClass(false, true)

// Just include _, -
class Subword extends Word {
  getRange(selection) {
    this.wordRegex = selection.cursor.subwordRegExp()
    return super.getRange(selection)
  }
}
Subword.initClass(false, true)

// Section: Pair
// =========================
class Pair extends TextObject {
  supportCount = true
  allowNextLine = null
  adjustInnerRange = true
  pair = null
  inclusive = true

  constructor(...args) {
    super(...args)
    if (!PairFinder) PairFinder = require("./pair-finder")
  }

  isAllowNextLine() {
    return this.allowNextLine != null ? this.allowNextLine : this.pair != null && this.pair[0] !== this.pair[1]
  }

  adjustRange({start, end}) {
    // Dirty work to feel natural for human, to behave compatible with pure Vim.
    // Where this adjustment appear is in following situation.
    // op-1: `ci{` replace only 2nd line
    // op-2: `di{` delete only 2nd line.
    // text:
    //  {
    //    aaa
    //  }
    if (pointIsAtEndOfLine(this.editor, start)) {
      start = start.traverse([1, 0])
    }

    if (getLineTextToBufferPosition(this.editor, end).match(/^\s*$/)) {
      if (this.mode === "visual") {
        // This is slightly innconsistent with regular Vim
        // - regular Vim: select new line after EOL
        // - vim-mode-plus: select to EOL(before new line)
        // This is intentional since to make submode `characterwise` when auto-detect submode
        // innerEnd = new Point(innerEnd.row - 1, Infinity)
        end = new Point(end.row - 1, Infinity)
      } else {
        end = new Point(end.row, 0)
      }
    }
    return new Range(start, end)
  }

  getFinder() {
    const finderName = this.pair[0] === this.pair[1] ? "QuoteFinder" : "BracketFinder"
    return new PairFinder[finderName](this.editor, {
      allowNextLine: this.isAllowNextLine(),
      allowForwarding: this.allowForwarding,
      pair: this.pair,
      inclusive: this.inclusive,
    })
  }

  getPairInfo(from) {
    const pairInfo = this.getFinder().find(from)
    if (pairInfo) {
      if (this.adjustInnerRange) pairInfo.innerRange = this.adjustRange(pairInfo.innerRange)
      pairInfo.targetRange = this.isInner() ? pairInfo.innerRange : pairInfo.aRange
      return pairInfo
    }
  }

  getRange(selection) {
    const originalRange = selection.getBufferRange()
    let pairInfo = this.getPairInfo(this.getCursorPositionForSelection(selection))
    // When range was same, try to expand range
    if (pairInfo && pairInfo.targetRange.isEqual(originalRange)) {
      pairInfo = this.getPairInfo(pairInfo.aRange.end)
    }
    if (pairInfo) return pairInfo.targetRange
  }
}
Pair.initClass(false)

// Used by DeleteSurround
class APair extends Pair {}
APair.initClass(false)

class AnyPair extends Pair {
  allowForwarding = false
  member = ["DoubleQuote", "SingleQuote", "BackTick", "CurlyBracket", "AngleBracket", "SquareBracket", "Parenthesis"]

  getRanges(selection) {
    const options = {inner: this.inner, allowForwarding: this.allowForwarding, inclusive: this.inclusive}
    return this.member.map(member => this.getInstance(member, options).getRange(selection)).filter(range => range)
  }

  getRange(selection) {
    return _.last(sortRanges(this.getRanges(selection)))
  }
}
AnyPair.initClass(false, true)

class AnyPairAllowForwarding extends AnyPair {
  allowForwarding = true

  getRange(selection) {
    const ranges = this.getRanges(selection)
    const from = selection.cursor.getBufferPosition()
    let [forwardingRanges, enclosingRanges] = _.partition(ranges, range => range.start.isGreaterThanOrEqual(from))
    const enclosingRange = _.last(sortRanges(enclosingRanges))
    forwardingRanges = sortRanges(forwardingRanges)

    // When enclosingRange is exists,
    // We don't go across enclosingRange.end.
    // So choose from ranges contained in enclosingRange.
    if (enclosingRange) {
      forwardingRanges = forwardingRanges.filter(range => enclosingRange.containsRange(range))
    }

    return forwardingRanges[0] || enclosingRange
  }
}
AnyPairAllowForwarding.initClass(false, true)

class AnyQuote extends AnyPair {
  allowForwarding = true
  member = ["DoubleQuote", "SingleQuote", "BackTick"]

  getRange(selection) {
    const ranges = this.getRanges(selection)
    // Pick range which end.colum is leftmost(mean, closed first)
    if (ranges.length) return _.first(_.sortBy(ranges, r => r.end.column))
  }
}
AnyQuote.initClass(false, true)

class Quote extends Pair {
  allowForwarding = true
}
Quote.initClass(false)

class DoubleQuote extends Quote {
  pair = ['"', '"']
}
DoubleQuote.initClass(false, true)

class SingleQuote extends Quote {
  pair = ["'", "'"]
}
SingleQuote.initClass(false, true)

class BackTick extends Quote {
  pair = ["`", "`"]
}
BackTick.initClass(false, true)

class CurlyBracket extends Pair {
  pair = ["{", "}"]
}
CurlyBracket.initClass(false, true, true)

class SquareBracket extends Pair {
  pair = ["[", "]"]
}
SquareBracket.initClass(false, true, true)

class Parenthesis extends Pair {
  pair = ["(", ")"]
}
Parenthesis.initClass(false, true, true)

class AngleBracket extends Pair {
  pair = ["<", ">"]
}
AngleBracket.initClass(false, true, true)

class Tag extends Pair {
  allowNextLine = true
  allowForwarding = true
  adjustInnerRange = false

  getTagStartPoint(from) {
    let tagRange
    const {pattern} = PairFinder.TagFinder
    this.scanForward(pattern, {from: [from.row, 0]}, ({range, stop}) => {
      if (range.containsPoint(from, true)) {
        tagRange = range
        stop()
      }
    })
    if (tagRange) return tagRange.start
  }

  getFinder() {
    return new PairFinder.TagFinder(this.editor, {
      allowNextLine: this.isAllowNextLine(),
      allowForwarding: this.allowForwarding,
      inclusive: this.inclusive,
    })
  }

  getPairInfo(from) {
    return super.getPairInfo(this.getTagStartPoint(from) || from)
  }
}
Tag.initClass(false, true)

// Section: Paragraph
// =========================
// Paragraph is defined as consecutive (non-)blank-line.
class Paragraph extends TextObject {
  wise = "linewise"
  supportCount = true

  findRow(fromRow, direction, fn) {
    if (fn.reset) fn.reset()
    let foundRow = fromRow
    for (const row of getBufferRows(this.editor, {startRow: fromRow, direction})) {
      if (!fn(row, direction)) break
      foundRow = row
    }
    return foundRow
  }

  findRowRangeBy(fromRow, fn) {
    const startRow = this.findRow(fromRow, "previous", fn)
    const endRow = this.findRow(fromRow, "next", fn)
    return [startRow, endRow]
  }

  getPredictFunction(fromRow, selection) {
    const fromRowResult = this.editor.isBufferRowBlank(fromRow)

    if (this.isInner()) {
      return (row, direction) => this.editor.isBufferRowBlank(row) === fromRowResult
    } else {
      const directionToExtend = selection.isReversed() ? "previous" : "next"

      let flip = false
      const predict = (row, direction) => {
        const result = this.editor.isBufferRowBlank(row) === fromRowResult
        if (flip) {
          return !result
        } else {
          if (!result && direction === directionToExtend) {
            return (flip = true)
          }
          return result
        }
      }
      predict.reset = () => (flip = false)
      return predict
    }
  }

  getRange(selection) {
    const originalRange = selection.getBufferRange()
    let fromRow = this.getCursorPositionForSelection(selection).row
    if (this.isMode("visual", "linewise")) {
      if (selection.isReversed()) fromRow--
      else fromRow++
      fromRow = getValidVimBufferRow(this.editor, fromRow)
    }
    const rowRange = this.findRowRangeBy(fromRow, this.getPredictFunction(fromRow, selection))
    return selection.getBufferRange().union(this.getBufferRangeForRowRange(rowRange))
  }
}
Paragraph.initClass(false, true)

class Indentation extends Paragraph {
  getRange(selection) {
    const fromRow = this.getCursorPositionForSelection(selection).row
    const baseIndentLevel = this.getIndentLevelForBufferRow(fromRow)
    const rowRange = this.findRowRangeBy(fromRow, row => {
      return this.editor.isBufferRowBlank(row) ? this.isA() : this.getIndentLevelForBufferRow(row) >= baseIndentLevel
    })
    return this.getBufferRangeForRowRange(rowRange)
  }
}
Indentation.initClass(false, true)

// Section: Comment
// =========================
class Comment extends TextObject {
  wise = "linewise"

  getRange(selection) {
    const {row} = this.getCursorPositionForSelection(selection)
    let rowRange = this.editor.languageMode.rowRangeForCommentAtBufferRow(row)
    if (this.editor.isBufferRowCommented(row) && !rowRange) rowRange = [row, row]
    if (rowRange) return this.getBufferRangeForRowRange(rowRange)
  }
}
Comment.initClass(false, true)

class CommentOrParagraph extends TextObject {
  wise = "linewise"

  getRange(selection) {
    const {inner} = this
    for (const klass of ["Comment", "Paragraph"]) {
      const range = this.getInstance(klass, {inner}).getRange(selection)
      if (range) return range
    }
  }
}
CommentOrParagraph.initClass(false, true)

// Section: Fold
// =========================
class Fold extends TextObject {
  wise = "linewise"

  adjustRowRange(rowRange) {
    if (this.isA()) return rowRange

    let [startRow, endRow] = rowRange
    if (this.getIndentLevelForBufferRow(startRow) === this.getIndentLevelForBufferRow(endRow)) {
      endRow -= 1
    }
    startRow += 1
    return [startRow, endRow]
  }

  getFoldRowRangesContainsForRow(row) {
    return getCodeFoldRowRangesContainesForRow(this.editor, row).reverse()
  }

  getRange(selection) {
    const {row} = this.getCursorPositionForSelection(selection)
    const selectedRange = selection.getBufferRange()
    for (const rowRange of this.getFoldRowRangesContainsForRow(row)) {
      const range = this.getBufferRangeForRowRange(this.adjustRowRange(rowRange))

      // Don't change to `if range.containsRange(selectedRange, true)`
      // There is behavior diff when cursor is at beginning of line( column 0 ).
      if (!selectedRange.containsRange(range)) return range
    }
  }
}
Fold.initClass(false, true)

// NOTE: Function range determination is depending on fold.
class Function extends Fold {
  // Some language don't include closing `}` into fold.
  scopeNamesOmittingEndRow = ["source.go", "source.elixir"]

  isGrammarNotFoldEndRow() {
    const {scopeName, packageName} = this.editor.getGrammar()
    if (this.scopeNamesOmittingEndRow.includes(scopeName)) {
      return true
    } else {
      // HACK: Rust have two package `language-rust` and `atom-language-rust`
      // language-rust don't fold ending `}`, but atom-language-rust does.
      return scopeName === "source.rust" && packageName === "language-rust"
    }
  }

  getFoldRowRangesContainsForRow(row) {
    return super.getFoldRowRangesContainsForRow(row).filter(rowRange => {
      return isIncludeFunctionScopeForRow(this.editor, rowRange[0])
    })
  }

  adjustRowRange(rowRange) {
    let [startRow, endRow] = super.adjustRowRange(rowRange)
    // NOTE: This adjustment shoud not be necessary if language-syntax is properly defined.
    if (this.isA() && this.isGrammarNotFoldEndRow()) endRow += 1
    return [startRow, endRow]
  }
}
Function.initClass(false, true)

// Section: Other
// =========================
class Arguments extends TextObject {
  newArgInfo(argStart, arg, separator) {
    const argEnd = traverseTextFromPoint(argStart, arg)
    const argRange = new Range(argStart, argEnd)

    const separatorEnd = traverseTextFromPoint(argEnd, separator != null ? separator : "")
    const separatorRange = new Range(argEnd, separatorEnd)

    const innerRange = argRange
    const aRange = argRange.union(separatorRange)
    return {argRange, separatorRange, innerRange, aRange}
  }

  getArgumentsRangeForSelection(selection) {
    const options = {
      member: ["CurlyBracket", "SquareBracket", "Parenthesis"],
      inclusive: false,
    }
    return this.getInstance("InnerAnyPair", options).getRange(selection)
  }

  getRange(selection) {
    let range = this.getArgumentsRangeForSelection(selection)
    const pairRangeFound = range != null

    range = range || this.getInstance("InnerCurrentLine").getRange(selection) // fallback
    if (!range) return

    range = trimRange(this.editor, range)

    const text = this.editor.getTextInBufferRange(range)
    const allTokens = splitArguments(text, pairRangeFound)

    const argInfos = []
    let argStart = range.start

    // Skip starting separator
    if (allTokens.length && allTokens[0].type === "separator") {
      const token = allTokens.shift()
      argStart = traverseTextFromPoint(argStart, token.text)
    }

    while (allTokens.length) {
      const token = allTokens.shift()
      if (token.type === "argument") {
        const nextToken = allTokens.shift()
        const separator = nextToken ? nextToken.text : undefined
        const argInfo = this.newArgInfo(argStart, token.text, separator)

        if (allTokens.length === 0 && argInfos.length) {
          argInfo.aRange = argInfo.argRange.union(_.last(argInfos).separatorRange)
        }

        argStart = argInfo.aRange.end
        argInfos.push(argInfo)
      } else {
        throw new Error("must not happen")
      }
    }

    const point = this.getCursorPositionForSelection(selection)
    for (const {innerRange, aRange} of argInfos) {
      if (innerRange.end.isGreaterThanOrEqual(point)) {
        return this.isInner() ? innerRange : aRange
      }
    }
  }
}
Arguments.initClass(false, true)

class CurrentLine extends TextObject {
  getRange(selection) {
    const {row} = this.getCursorPositionForSelection(selection)
    const range = this.editor.bufferRangeForBufferRow(row)
    return this.isA() ? range : trimRange(this.editor, range)
  }
}
CurrentLine.initClass(false, true)

class Entire extends TextObject {
  wise = "linewise"
  selectOnce = true

  getRange(selection) {
    return this.editor.buffer.getRange()
  }
}
Entire.initClass(false, true)

class Empty extends TextObject {
  selectOnce = true
}
Empty.initClass(false)

class LatestChange extends TextObject {
  wise = null
  selectOnce = true
  getRange(selection) {
    const start = this.vimState.mark.get("[")
    const end = this.vimState.mark.get("]")
    if (start && end) {
      return new Range(start, end)
    }
  }
}
LatestChange.initClass(false, true)

class SearchMatchForward extends TextObject {
  backward = false

  findMatch(fromPoint, pattern) {
    if (this.mode === "visual") {
      fromPoint = translatePointAndClip(this.editor, fromPoint, "forward")
    }
    let foundRange
    this.scanForward(pattern, {from: [fromPoint.row, 0]}, ({range, stop}) => {
      if (range.end.isGreaterThan(fromPoint)) {
        foundRange = range
        stop()
      }
    })
    return {range: foundRange, whichIsHead: "end"}
  }

  getRange(selection) {
    const pattern = this.globalState.get("lastSearchPattern")
    if (!pattern) return

    const fromPoint = selection.getHeadBufferPosition()
    const {range, whichIsHead} = this.findMatch(fromPoint, pattern)
    if (range) {
      return this.unionRangeAndDetermineReversedState(selection, range, whichIsHead)
    }
  }

  unionRangeAndDetermineReversedState(selection, range, whichIsHead) {
    if (selection.isEmpty()) return range

    let head = range[whichIsHead]
    const tail = selection.getTailBufferPosition()

    if (this.backward) {
      if (tail.isLessThan(head)) head = translatePointAndClip(this.editor, head, "forward")
    } else {
      if (head.isLessThan(tail)) head = translatePointAndClip(this.editor, head, "backward")
    }

    this.reversed = head.isLessThan(tail)
    return new Range(tail, head).union(this.swrap(selection).getTailBufferRange())
  }

  selectTextObject(selection) {
    const range = this.getRange(selection)
    if (range) {
      this.swrap(selection).setBufferRange(range, {reversed: this.reversed != null ? this.reversed : this.backward})
      return true
    }
  }
}
SearchMatchForward.initClass()

class SearchMatchBackward extends SearchMatchForward {
  backward = true

  findMatch(fromPoint, pattern) {
    if (this.mode === "visual") {
      fromPoint = translatePointAndClip(this.editor, fromPoint, "backward")
    }
    let foundRange
    this.scanBackward(pattern, {from: [fromPoint.row, Infinity]}, ({range, stop}) => {
      if (range.start.isLessThan(fromPoint)) {
        foundRange = range
        stop()
      }
    })
    return {range: foundRange, whichIsHead: "start"}
  }
}
SearchMatchBackward.initClass()

// [Limitation: won't fix]: Selected range is not submode aware. always characterwise.
// So even if original selection was vL or vB, selected range by this text-object
// is always vC range.
class PreviousSelection extends TextObject {
  wise = null
  selectOnce = true

  selectTextObject(selection) {
    const {properties, submode} = this.vimState.previousSelection
    if (properties && submode) {
      this.wise = submode
      this.swrap(this.editor.getLastSelection()).selectByProperties(properties)
      return true
    }
  }
}
PreviousSelection.initClass()

class PersistentSelection extends TextObject {
  wise = null
  selectOnce = true

  selectTextObject(selection) {
    if (this.vimState.hasPersistentSelections()) {
      this.persistentSelection.setSelectedBufferRanges()
      return true
    }
  }
}
PersistentSelection.initClass(false, true)

// Used only by ReplaceWithRegister and PutBefore and its' children.
class LastPastedRange extends TextObject {
  wise = null
  selectOnce = true

  selectTextObject(selection) {
    for (selection of this.editor.getSelections()) {
      const range = this.vimState.sequentialPasteManager.getPastedRangeForSelection(selection)
      selection.setBufferRange(range)
    }
    return true
  }
}
LastPastedRange.initClass(false)

class VisibleArea extends TextObject {
  selectOnce = true

  getRange(selection) {
    // [BUG?] Need translate to shilnk top and bottom to fit actual row.
    // The reason I need -2 at bottom is because of status bar?
    const range = getVisibleBufferRange(this.editor)
    return range.getRows() > this.editor.getRowsPerPage() ? range.translate([+1, 0], [-3, 0]) : range
  }
}
VisibleArea.initClass(false, true)
