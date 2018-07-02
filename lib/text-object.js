'use babel'

const {Range, Point} = require('atom')

// [TODO] Need overhaul
//  - [ ] Make expandable by selection.getBufferRange().union(this.getRange(selection))
//  - [ ] Count support(priority low)?
const Base = require('./base')
const PairFinder = require('./pair-finder')

class TextObject extends Base {
  static operationKind = 'text-object'
  static command = false

  operator = null
  wise = 'characterwise'
  supportCount = false // FIXME #472, #66
  selectOnce = false
  selectSucceeded = false

  static deriveClass (innerAndA, innerAndAForAllowForwarding) {
    this.command = false // HACK: klass to derive child class is not command
    const store = {}
    if (innerAndA) {
      const klassA = this.generateClass(false)
      const klassI = this.generateClass(true)
      store[klassA.name] = klassA
      store[klassI.name] = klassI
    }
    if (innerAndAForAllowForwarding) {
      const klassA = this.generateClass(false, true)
      const klassI = this.generateClass(true, true)
      store[klassA.name] = klassA
      store[klassI.name] = klassI
    }
    return store
  }

  static generateClass (inner, allowForwarding) {
    let name = (inner ? 'Inner' : 'A') + this.name
    if (allowForwarding) {
      name += 'AllowForwarding'
    }

    return class extends this {
      static name = name
      constructor (vimState) {
        super(vimState)
        this.inner = inner
        if (allowForwarding != null) {
          this.allowForwarding = allowForwarding
        }
      }
    }
  }

  isInner () {
    return this.inner
  }

  isA () {
    return !this.inner
  }

  isLinewise () {
    return this.wise === 'linewise'
  }

  isBlockwise () {
    return this.wise === 'blockwise'
  }

  forceWise (wise) {
    return (this.wise = wise) // FIXME currently not well supported
  }

  resetState () {
    this.selectSucceeded = false
  }

  // execute: Called from Operator::selectTarget()
  //  - `v i p`, is `VisualModeSelect` operator with @target = `InnerParagraph`.
  //  - `d i p`, is `Delete` operator with @target = `InnerParagraph`.
  execute () {
    // Whennever TextObject is executed, it has @operator
    if (!this.operator) throw new Error('in TextObject: Must not happen')
    this.select()
  }

  select () {
    if (this.isMode('visual', 'blockwise')) {
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

    if (this.operator.instanceof('SelectBase')) {
      if (this.selectSucceeded) {
        if (this.wise === 'characterwise') {
          this.swrap.saveProperties(this.editor, {force: true})
        } else if (this.wise === 'linewise') {
          // When target is persistent-selection, new selection is added after selectTextObject.
          // So we have to assure all selection have selction property.
          // Maybe this logic can be moved to operation stack.
          for (const $selection of this.swrap.getSelections(this.editor)) {
            if (this.getConfig('stayOnSelectTextObject')) {
              if (!$selection.hasProperties()) {
                $selection.saveProperties()
              }
            } else {
              $selection.saveProperties()
            }
            $selection.fixPropertyRowToRowRange()
          }
        }
      }

      if (this.submode === 'blockwise') {
        for (const $selection of this.swrap.getSelections(this.editor)) {
          $selection.normalize()
          $selection.applyWise('blockwise')
        }
      }
    }
  }

  // Return true or false
  selectTextObject (selection) {
    const range = this.getRange(selection)
    if (range) {
      this.swrap(selection).setBufferRange(range)
      return true
    } else {
      return false
    }
  }

  // to override
  getRange (selection) {}
}

// Section: Word
// =========================
class Word extends TextObject {
  getRange (selection) {
    const point = this.getCursorPositionForSelection(selection)
    const {range} = this.getWordBufferRangeAndKindAtBufferPosition(point, {wordRegex: this.wordRegex})
    return this.isA() ? this.utils.expandRangeToWhiteSpaces(this.editor, range) : range
  }
}

class WholeWord extends Word {
  wordRegex = /\S+/
}

// Just include _, -
class SmartWord extends Word {
  wordRegex = /[\w-]+/
}

// Just include _, -
class Subword extends Word {
  getRange (selection) {
    this.wordRegex = selection.cursor.subwordRegExp()
    return super.getRange(selection)
  }
}

// Section: Pair
// =========================
class Pair extends TextObject {
  static command = false
  supportCount = true
  allowNextLine = null
  adjustInnerRange = true
  pair = null
  inclusive = true

  isAllowNextLine () {
    if (this.allowNextLine != null) {
      return this.allowNextLine
    } else {
      return this.pair && this.pair[0] !== this.pair[1]
    }
  }

  adjustRange ({start, end}) {
    // Dirty work to feel natural for human, to behave compatible with pure Vim.
    // Where this adjustment appear is in following situation.
    // op-1: `ci{` replace only 2nd line
    // op-2: `di{` delete only 2nd line.
    // text:
    //  {
    //    aaa
    //  }
    if (this.utils.pointIsAtEndOfLine(this.editor, start)) {
      start = start.traverse([1, 0])
    }

    if (this.utils.getLineTextToBufferPosition(this.editor, end).match(/^\s*$/)) {
      if (this.mode === 'visual') {
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

  getFinder () {
    const finderName = this.pair[0] === this.pair[1] ? 'QuoteFinder' : 'BracketFinder'
    return new PairFinder[finderName](this.editor, {
      allowNextLine: this.isAllowNextLine(),
      allowForwarding: this.allowForwarding,
      pair: this.pair,
      inclusive: this.inclusive
    })
  }

  getPairInfo (from) {
    const pairInfo = this.getFinder().find(from)
    if (pairInfo) {
      if (this.adjustInnerRange) {
        pairInfo.innerRange = this.adjustRange(pairInfo.innerRange)
      }
      pairInfo.targetRange = this.isInner() ? pairInfo.innerRange : pairInfo.aRange
      return pairInfo
    }
  }

  getRange (selection) {
    const originalRange = selection.getBufferRange()
    let pairInfo = this.getPairInfo(this.getCursorPositionForSelection(selection))
    // When range was same, try to expand range
    if (pairInfo && pairInfo.targetRange.isEqual(originalRange)) {
      pairInfo = this.getPairInfo(pairInfo.aRange.end)
    }
    if (pairInfo) {
      return pairInfo.targetRange
    }
  }
}

// Used by DeleteSurround
class APair extends Pair {
  static command = false
}

class AnyPair extends Pair {
  allowForwarding = false
  member = ['DoubleQuote', 'SingleQuote', 'BackTick', 'CurlyBracket', 'AngleBracket', 'SquareBracket', 'Parenthesis']

  getRanges (selection) {
    const options = {
      inner: this.inner,
      allowForwarding: this.allowForwarding,
      inclusive: this.inclusive
    }
    const getRangeByMember = member => this.getInstance(member, options).getRange(selection)
    return this.member.map(getRangeByMember).filter(v => v)
  }

  getRange (selection) {
    return this.utils.sortRanges(this.getRanges(selection)).pop()
  }
}

class AnyPairAllowForwarding extends AnyPair {
  allowForwarding = true

  getRange (selection) {
    const ranges = this.getRanges(selection)
    const from = selection.cursor.getBufferPosition()
    let [forwardingRanges, enclosingRanges] = this._.partition(ranges, range => range.start.isGreaterThanOrEqual(from))
    const enclosingRange = this.utils.sortRanges(enclosingRanges).pop()
    forwardingRanges = this.utils.sortRanges(forwardingRanges)

    // When enclosingRange is exists,
    // We don't go across enclosingRange.end.
    // So choose from ranges contained in enclosingRange.
    if (enclosingRange) {
      forwardingRanges = forwardingRanges.filter(range => enclosingRange.containsRange(range))
    }

    return forwardingRanges[0] || enclosingRange
  }
}

class AnyQuote extends AnyPair {
  allowForwarding = true
  member = ['DoubleQuote', 'SingleQuote', 'BackTick']

  getRange (selection) {
    // Pick range which end.colum is leftmost(mean, closed first)
    return this.getRanges(selection).sort((a, b) => a.end.column - b.end.column)[0]
  }
}

class Quote extends Pair {
  static command = false
  allowForwarding = true
}

class DoubleQuote extends Quote {
  pair = ['"', '"']
}

class SingleQuote extends Quote {
  pair = ["'", "'"]
}

class BackTick extends Quote {
  pair = ['`', '`']
}

class CurlyBracket extends Pair {
  pair = ['{', '}']
}

class SquareBracket extends Pair {
  pair = ['[', ']']
}

class Parenthesis extends Pair {
  pair = ['(', ')']
}

class AngleBracket extends Pair {
  pair = ['<', '>']
}

class Tag extends Pair {
  allowNextLine = true
  allowForwarding = true
  adjustInnerRange = false

  getTagStartPoint (from) {
    const regex = PairFinder.TagFinder.pattern
    const options = {from: [from.row, 0]}
    return this.findInEditor('forward', regex, options, ({range}) => range.containsPoint(from, true) && range.start)
  }

  getFinder () {
    return new PairFinder.TagFinder(this.editor, {
      allowNextLine: this.isAllowNextLine(),
      allowForwarding: this.allowForwarding,
      inclusive: this.inclusive
    })
  }

  getPairInfo (from) {
    return super.getPairInfo(this.getTagStartPoint(from) || from)
  }
}

// Section: Paragraph
// =========================
// Paragraph is defined as consecutive (non-)blank-line.
class Paragraph extends TextObject {
  wise = 'linewise'
  supportCount = true

  findRow (fromRow, direction, fn) {
    if (fn.reset) fn.reset()
    let foundRow = fromRow
    for (const row of this.getBufferRows({startRow: fromRow, direction})) {
      if (!fn(row, direction)) break
      foundRow = row
    }
    return foundRow
  }

  findRowRangeBy (fromRow, fn) {
    const startRow = this.findRow(fromRow, 'previous', fn)
    const endRow = this.findRow(fromRow, 'next', fn)
    return [startRow, endRow]
  }

  getPredictFunction (fromRow, selection) {
    const fromRowResult = this.editor.isBufferRowBlank(fromRow)

    if (this.isInner()) {
      return (row, direction) => this.editor.isBufferRowBlank(row) === fromRowResult
    } else {
      const directionToExtend = selection.isReversed() ? 'previous' : 'next'

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

  getRange (selection) {
    let fromRow = this.getCursorPositionForSelection(selection).row
    if (this.isMode('visual', 'linewise')) {
      if (selection.isReversed()) fromRow--
      else fromRow++
      fromRow = this.getValidVimBufferRow(fromRow)
    }
    const rowRange = this.findRowRangeBy(fromRow, this.getPredictFunction(fromRow, selection))
    return selection.getBufferRange().union(this.getBufferRangeForRowRange(rowRange))
  }
}

class Indentation extends Paragraph {
  getRange (selection) {
    const fromRow = this.getCursorPositionForSelection(selection).row
    const baseIndentLevel = this.editor.indentationForBufferRow(fromRow)
    const rowRange = this.findRowRangeBy(fromRow, row => {
      if (this.editor.isBufferRowBlank(row)) {
        return this.isA()
      } else {
        return this.editor.indentationForBufferRow(row) >= baseIndentLevel
      }
    })
    return this.getBufferRangeForRowRange(rowRange)
  }
}

// Section: Comment
// =========================
class Comment extends TextObject {
  wise = 'linewise'

  getRange (selection) {
    const {row} = this.getCursorPositionForSelection(selection)
    const rowRange = this.utils.getRowRangeForCommentAtBufferRow(this.editor, row)
    if (rowRange) {
      return this.getBufferRangeForRowRange(rowRange)
    }
  }
}

class BlockComment extends TextObject {
  wise = 'characterwise'

  getRange (selection) {
    // Following one-column-right translation is necessary when cursor is "on" `/` char of beginning `/*`.
    const from = this.editor.clipBufferPosition(this.getCursorPositionForSelection(selection).translate([0, 1]))

    const range = this.getBlockCommentRangeForPoint(from)
    if (range) {
      range.start = this.getStartOfBlockComment(range.start)
      range.end = this.getEndOfBlockComment(range.end)
      const scanRange = range

      if (this.isInner()) {
        this.scanEditor('forward', /\s+/, {scanRange}, event => {
          range.start = event.range.end
          event.stop()
        })
        this.scanEditor('backward', /\s+/, {scanRange}, event => {
          range.end = event.range.start
          event.stop()
        })
      }
      return range
    }
  }

  getStartOfBlockComment (start) {
    while (start.column === 0) {
      const range = this.getBlockCommentRangeForPoint(start.translate([-1, Infinity]))
      if (!range) break
      start = range.start
    }
    return start
  }

  getEndOfBlockComment (end) {
    while (this.utils.pointIsAtEndOfLine(this.editor, end)) {
      const range = this.getBlockCommentRangeForPoint([end.row + 1, 0])
      if (!range) break
      end = range.end
    }
    return end
  }

  getBlockCommentRangeForPoint (point) {
    const scope = 'comment.block'
    return this.editor.bufferRangeForScopeAtPosition(scope, point)
  }
}

class CommentOrParagraph extends TextObject {
  wise = 'linewise'

  getRange (selection) {
    const {inner} = this
    for (const klass of ['Comment', 'Paragraph']) {
      const range = this.getInstance(klass, {inner}).getRange(selection)
      if (range) {
        return range
      }
    }
  }
}

// Section: Fold
// =========================
class Fold extends TextObject {
  wise = 'linewise'

  getRange (selection) {
    const {row} = this.getCursorPositionForSelection(selection)
    const selectedRange = selection.getBufferRange()

    const foldRanges = this.utils.getCodeFoldRanges(this.editor)
    const foldRangesContainsCursorRow = foldRanges.filter(range => range.start.row <= row && row <= range.end.row)

    for (let foldRange of foldRangesContainsCursorRow.reverse()) {
      if (this.isA()) {
        let conjoined
        while ((conjoined = foldRanges.find(range => range.end.row === foldRange.start.row))) {
          foldRange = foldRange.union(conjoined)
        }
        while ((conjoined = foldRanges.find(range => range.start.row === foldRange.end.row))) {
          foldRange = foldRange.union(conjoined)
        }
      } else {
        if (this.utils.doesRangeStartAndEndWithSameIndentLevel(this.editor, foldRange)) {
          foldRange.end.row -= 1
        }
        foldRange.start.row += 1
      }
      foldRange = this.getBufferRangeForRowRange([foldRange.start.row, foldRange.end.row])
      if (!selectedRange.containsRange(foldRange)) {
        return foldRange
      }
    }
  }
}

class Function extends TextObject {
  wise = 'linewise'
  scopeNamesOmittingClosingBrace = ['source.go', 'source.elixir'] // language doesn't include closing `}` into fold.

  getFunctionBodyStartRegex ({scopeName}) {
    if (scopeName === 'source.python') {
      return /:$/
    } else if (scopeName === 'source.coffee') {
      return /-|=>$/
    } else {
      return /{$/
    }
  }

  isMultiLineParameterFunctionRange (parameterRange, bodyRange, bodyStartRegex) {
    const isBodyStartRow = row => bodyStartRegex.test(this.editor.lineTextForBufferRow(row))
    if (isBodyStartRow(parameterRange.start.row)) return false
    if (isBodyStartRow(parameterRange.end.row)) return parameterRange.end.row === bodyRange.start.row
    if (isBodyStartRow(parameterRange.end.row + 1)) return parameterRange.end.row + 1 === bodyRange.start.row
    return false
  }

  getRange (selection) {
    const editor = this.editor
    const cursorRow = this.getCursorPositionForSelection(selection).row
    const bodyStartRegex = this.getFunctionBodyStartRegex(editor.getGrammar())
    const isIncludeFunctionScopeForRow = row => this.utils.isIncludeFunctionScopeForRow(editor, row)

    const functionRanges = []
    const saveFunctionRange = ({aRange, innerRange}) => {
      functionRanges.push({
        aRange: this.buildARange(aRange),
        innerRange: this.buildInnerRange(innerRange)
      })
    }

    const foldRanges = this.utils.getCodeFoldRanges(editor)
    while (foldRanges.length) {
      const range = foldRanges.shift()
      if (isIncludeFunctionScopeForRow(range.start.row)) {
        const nextRange = foldRanges[0]
        const nextFoldIsConnected = nextRange && nextRange.start.row <= range.end.row + 1
        const maybeAFunctionRange = nextFoldIsConnected ? range.union(nextRange) : range
        if (!maybeAFunctionRange.containsPoint([cursorRow, Infinity])) continue // skip to avoid heavy computation
        if (nextFoldIsConnected && this.isMultiLineParameterFunctionRange(range, nextRange, bodyStartRegex)) {
          const bodyRange = foldRanges.shift()
          saveFunctionRange({aRange: range.union(bodyRange), innerRange: bodyRange})
        } else {
          saveFunctionRange({aRange: range, innerRange: range})
        }
      } else {
        const previousRow = range.start.row - 1
        if (previousRow < 0) continue
        if (editor.isFoldableAtBufferRow(previousRow)) continue
        const maybeAFunctionRange = range.union(editor.bufferRangeForBufferRow(previousRow))
        if (!maybeAFunctionRange.containsPoint([cursorRow, Infinity])) continue // skip to avoid heavy computation

        const isBodyStartOnlyRow = row =>
          new RegExp('^\\s*' + bodyStartRegex.source).test(editor.lineTextForBufferRow(row))
        if (isBodyStartOnlyRow(range.start.row) && isIncludeFunctionScopeForRow(previousRow)) {
          saveFunctionRange({aRange: maybeAFunctionRange, innerRange: range})
        }
      }
    }

    for (const functionRange of functionRanges.reverse()) {
      const {start, end} = this.isA() ? functionRange.aRange : functionRange.innerRange
      const range = this.getBufferRangeForRowRange([start.row, end.row])
      if (!selection.getBufferRange().containsRange(range)) return range
    }
  }

  buildInnerRange (range) {
    const endRowTranslation = this.utils.doesRangeStartAndEndWithSameIndentLevel(this.editor, range) ? -1 : 0
    return range.translate([1, 0], [endRowTranslation, 0])
  }

  buildARange (range) {
    // NOTE: This adjustment shoud not be necessary if language-syntax is properly defined.
    const endRowTranslation = this.isGrammarDoesNotFoldClosingRow() ? +1 : 0
    return range.translate([0, 0], [endRowTranslation, 0])
  }

  isGrammarDoesNotFoldClosingRow () {
    const {scopeName, packageName} = this.editor.getGrammar()
    if (this.scopeNamesOmittingClosingBrace.includes(scopeName)) {
      return true
    } else {
      // HACK: Rust have two package `language-rust` and `atom-language-rust`
      // language-rust don't fold ending `}`, but atom-language-rust does.
      return scopeName === 'source.rust' && packageName === 'language-rust'
    }
  }
}

// Section: Other
// =========================
class Arguments extends TextObject {
  newArgInfo (argStart, arg, separator) {
    const argEnd = this.utils.traverseTextFromPoint(argStart, arg)
    const argRange = new Range(argStart, argEnd)

    const separatorEnd = this.utils.traverseTextFromPoint(argEnd, separator != null ? separator : '')
    const separatorRange = new Range(argEnd, separatorEnd)

    const innerRange = argRange
    const aRange = argRange.union(separatorRange)
    return {argRange, separatorRange, innerRange, aRange}
  }

  getArgumentsRangeForSelection (selection) {
    const options = {
      member: ['CurlyBracket', 'SquareBracket', 'Parenthesis'],
      inclusive: false
    }
    return this.getInstance('InnerAnyPair', options).getRange(selection)
  }

  getRange (selection) {
    const {splitArguments, traverseTextFromPoint, getLast} = this.utils
    let range = this.getArgumentsRangeForSelection(selection)
    const pairRangeFound = range != null

    range = range || this.getInstance('InnerCurrentLine').getRange(selection) // fallback
    if (!range) return

    range = this.trimBufferRange(range)

    const text = this.editor.getTextInBufferRange(range)
    const allTokens = splitArguments(text, pairRangeFound)

    const argInfos = []
    let argStart = range.start

    // Skip starting separator
    if (allTokens.length && allTokens[0].type === 'separator') {
      const token = allTokens.shift()
      argStart = traverseTextFromPoint(argStart, token.text)
    }

    while (allTokens.length) {
      const token = allTokens.shift()
      if (token.type === 'argument') {
        const nextToken = allTokens.shift()
        const separator = nextToken ? nextToken.text : undefined
        const argInfo = this.newArgInfo(argStart, token.text, separator)

        if (allTokens.length === 0 && argInfos.length) {
          argInfo.aRange = argInfo.argRange.union(getLast(argInfos).separatorRange)
        }

        argStart = argInfo.aRange.end
        argInfos.push(argInfo)
      } else {
        throw new Error('must not happen')
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

class CurrentLine extends TextObject {
  getRange (selection) {
    const {row} = this.getCursorPositionForSelection(selection)
    const range = this.editor.bufferRangeForBufferRow(row)
    return this.isA() ? range : this.trimBufferRange(range)
  }
}

class Entire extends TextObject {
  wise = 'linewise'
  selectOnce = true

  getRange (selection) {
    return this.editor.buffer.getRange()
  }
}

class Empty extends TextObject {
  static command = false
  selectOnce = true
}

class LatestChange extends TextObject {
  wise = null
  selectOnce = true
  getRange (selection) {
    const start = this.vimState.mark.get('[')
    const end = this.vimState.mark.get(']')
    if (start && end) {
      return new Range(start, end)
    }
  }
}

class SearchMatchForward extends TextObject {
  backward = false

  findMatch (from, regex) {
    if (this.backward) {
      if (this.mode === 'visual') {
        from = this.utils.translatePointAndClip(this.editor, from, 'backward')
      }

      const options = {from: [from.row, Infinity]}
      return {
        range: this.findInEditor('backward', regex, options, ({range}) => range.start.isLessThan(from) && range),
        whichIsHead: 'start'
      }
    } else {
      if (this.mode === 'visual') {
        from = this.utils.translatePointAndClip(this.editor, from, 'forward')
      }

      const options = {from: [from.row, 0]}
      return {
        range: this.findInEditor('forward', regex, options, ({range}) => range.end.isGreaterThan(from) && range),
        whichIsHead: 'end'
      }
    }
  }

  getRange (selection) {
    const pattern = this.globalState.get('lastSearchPattern')
    if (!pattern) return

    const fromPoint = selection.getHeadBufferPosition()
    const {range, whichIsHead} = this.findMatch(fromPoint, pattern)
    if (range) {
      return this.unionRangeAndDetermineReversedState(selection, range, whichIsHead)
    }
  }

  unionRangeAndDetermineReversedState (selection, range, whichIsHead) {
    if (selection.isEmpty()) return range

    let head = range[whichIsHead]
    const tail = selection.getTailBufferPosition()

    if (this.backward) {
      if (tail.isLessThan(head)) head = this.utils.translatePointAndClip(this.editor, head, 'forward')
    } else {
      if (head.isLessThan(tail)) head = this.utils.translatePointAndClip(this.editor, head, 'backward')
    }

    this.reversed = head.isLessThan(tail)
    return new Range(tail, head).union(this.swrap(selection).getTailBufferRange())
  }

  selectTextObject (selection) {
    const range = this.getRange(selection)
    if (range) {
      this.swrap(selection).setBufferRange(range, {reversed: this.reversed != null ? this.reversed : this.backward})
      return true
    }
  }
}

class SearchMatchBackward extends SearchMatchForward {
  backward = true
}

// [Limitation: won't fix]: Selected range is not submode aware. always characterwise.
// So even if original selection was vL or vB, selected range by this text-object
// is always vC range.
class PreviousSelection extends TextObject {
  wise = null
  selectOnce = true

  selectTextObject (selection) {
    const {properties, submode} = this.vimState.previousSelection
    if (properties && submode) {
      this.wise = submode
      this.swrap(this.editor.getLastSelection()).selectByProperties(properties)
      return true
    }
  }
}

class PersistentSelection extends TextObject {
  wise = null
  selectOnce = true

  selectTextObject (selection) {
    if (this.vimState.hasPersistentSelections()) {
      this.persistentSelection.setSelectedBufferRanges()
      return true
    }
  }
}

// Used only by ReplaceWithRegister and PutBefore and its' children.
class LastPastedRange extends TextObject {
  static command = false
  wise = null
  selectOnce = true

  selectTextObject (selection) {
    for (selection of this.editor.getSelections()) {
      const range = this.vimState.sequentialPasteManager.getPastedRangeForSelection(selection)
      selection.setBufferRange(range)
    }
    return true
  }
}

class VisibleArea extends TextObject {
  selectOnce = true

  getRange (selection) {
    const [startRow, endRow] = this.editor.getVisibleRowRange()
    return this.editor.bufferRangeForScreenRange([[startRow, 0], [endRow, Infinity]])
  }
}

class DiffHunk extends TextObject {
  wise = 'linewise'
  selectOnce = true
  getRange (selection) {
    const row = this.getCursorPositionForSelection(selection).row
    return this.utils.getHunkRangeAtBufferRow(this.editor, row)
  }
}

module.exports = Object.assign(
  {
    TextObject,
    Word,
    WholeWord,
    SmartWord,
    Subword,
    Pair,
    APair,
    AnyPair,
    AnyPairAllowForwarding,
    AnyQuote,
    Quote,
    DoubleQuote,
    SingleQuote,
    BackTick,
    CurlyBracket,
    SquareBracket,
    Parenthesis,
    AngleBracket,
    Tag,
    Paragraph,
    Indentation,
    Comment,
    CommentOrParagraph,
    Fold,
    Function,
    Arguments,
    CurrentLine,
    Entire,
    Empty,
    LatestChange,
    SearchMatchForward,
    SearchMatchBackward,
    PreviousSelection,
    PersistentSelection,
    LastPastedRange,
    VisibleArea
  },
  Word.deriveClass(true),
  WholeWord.deriveClass(true),
  SmartWord.deriveClass(true),
  Subword.deriveClass(true),
  AnyPair.deriveClass(true),
  AnyPairAllowForwarding.deriveClass(true),
  AnyQuote.deriveClass(true),
  DoubleQuote.deriveClass(true),
  SingleQuote.deriveClass(true),
  BackTick.deriveClass(true),
  CurlyBracket.deriveClass(true, true),
  SquareBracket.deriveClass(true, true),
  Parenthesis.deriveClass(true, true),
  AngleBracket.deriveClass(true, true),
  Tag.deriveClass(true),
  Paragraph.deriveClass(true),
  Indentation.deriveClass(true),
  Comment.deriveClass(true),
  BlockComment.deriveClass(true),
  CommentOrParagraph.deriveClass(true),
  Fold.deriveClass(true),
  Function.deriveClass(true),
  Arguments.deriveClass(true),
  CurrentLine.deriveClass(true),
  Entire.deriveClass(true),
  LatestChange.deriveClass(true),
  PersistentSelection.deriveClass(true),
  VisibleArea.deriveClass(true),
  DiffHunk.deriveClass(true)
)
