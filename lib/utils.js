let fs, semver, Diff
const settings = require('./settings')
const {Range, Point} = require('atom')
const NEWLINE_REG_EXP = /\n/g

// [Borrowed from underscore/underscore-plus
function escapeRegExp (s) {
  return s ? s.replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&') : ''
}

function getLast (list) {
  return list ? list[list.length - 1] : undefined
}

function assertWithException (condition, message) {
  atom.assert(condition, message, error => {
    throw new Error(error.message)
  })
}

function getKeyBindingForCommand (command, {packageName}) {
  let keymaps = atom.keymaps.getKeyBindings()
  if (packageName) {
    const keymapPath = atom.packages
      .getActivePackage(packageName)
      .getKeymapPaths()
      .pop()
    keymaps = keymaps.filter(({source}) => source === keymapPath)
  }
  const results = keymaps.filter(keymap => keymap.command === command).map(keymap => ({
    keystrokes: keymap.keystrokes.replace(/shift-/, ''),
    selector: keymap.selector
  }))
  return results.length ? results : null
}

function debug (...messages) {
  if (!settings.get('debug')) return

  switch (settings.get('debugOutput')) {
    case 'console':
      console.log(...messages)
      return
    case 'file':
      if (!fs) fs = require('fs-plus')
      const filePath = fs.normalize(settings.get('debugOutputFilePath'))
      if (fs.existsSync(filePath)) fs.appendFileSync(filePath, messages + '\n')
  }
}

// Return function to restore editor's scrollTop and fold state.
function saveEditorState (editor) {
  const store = {scrollTop: editor.element.getScrollTop()}

  const foldRowRanges = editor.displayLayer.foldsMarkerLayer.findMarkers({}).map(marker => {
    const {start, end} = marker.getRange()
    return [start.row, end.row]
  })

  return function restoreEditorState ({anchorPosition, skipRow = null} = {}) {
    if (anchorPosition) {
      store.anchorScreenRow = this.editor.screenPositionForBufferPosition(anchorPosition).row
      store.anchorFirstVisibileScreenRow = editor.getFirstVisibleScreenRow()
    }

    for (const [startRow, endRow] of foldRowRanges.reverse()) {
      if (skipRow >= startRow && skipRow <= endRow) continue
      if (!editor.isFoldedAtBufferRow(startRow)) {
        editor.foldBufferRow(startRow)
      }
    }

    if (anchorPosition) {
      const {anchorScreenRow, anchorFirstVisibileScreenRow} = store
      const shrinkedRows = anchorScreenRow - this.editor.screenPositionForBufferPosition(anchorPosition).row
      this.editor.setFirstVisibleScreenRow(anchorFirstVisibileScreenRow - shrinkedRows)
    } else {
      editor.element.setScrollTop(store.scrollTop)
    }
  }
}

function isLinewiseRange ({start, end}) {
  return start.row !== end.row && (start.column === 0 && end.column === 0)
}

function isEndsWithNewLineForBufferRow (editor, row) {
  const {start, end} = editor.bufferRangeForBufferRow(row, {includeNewline: true})
  return start.row !== end.row
}

function sortComparables (comparables) {
  return comparables.sort((a, b) => a.compare(b))
}

// This is just clarify intention, adds no value in fucntionalities.
const [sortRanges, sortCursors, sortPoints] = [sortComparables, sortComparables, sortComparables]

// Return adjusted index fit whitin given list's length
// return -1 if list is empty.
function getIndex (index, list) {
  if (!list.length) return -1
  index = index % list.length
  return index >= 0 ? index : list.length + index
}

// NOTE: endRow become undefined if @editorElement is not yet attached.
// e.g. Beging called immediately after open file.
function getVisibleBufferRange (editor) {
  let [startRow, endRow] = editor.getVisibleRowRange()

  // When editor is not attached or imediately after attached timing,
  // `editor.element.getVisibleRowRange()` return NaN.
  // As my undestanding, in vmp usage, we hit this situation only in test-spec, not in real usage.
  if (Number.isInteger(startRow) && Number.isInteger(endRow)) {
    return new Range([editor.bufferRowForScreenRow(startRow), 0], [editor.bufferRowForScreenRow(endRow), Infinity])
  }
}

function getVisibleEditors () {
  return atom.workspace
    .getPanes()
    .map(pane => pane.getActiveEditor())
    .filter(editor => editor)
}

function getEndOfLineForBufferRow (editor, row) {
  return editor.bufferRangeForBufferRow(row).end
}

// Buffer Point util
// -------------------------
function pointIsAtEndOfLine (editor, point) {
  point = Point.fromObject(point)
  return getEndOfLineForBufferRow(editor, point.row).isEqual(point)
}

function pointIsAtWhiteSpace (editor, point) {
  const char = getRightCharacterForBufferPosition(editor, point)
  return !/\S/.test(char)
}

function pointIsAtNonWhiteSpace (editor, point) {
  const char = getRightCharacterForBufferPosition(editor, point)
  return char != null && /\S/.test(char)
}

function pointIsAtEndOfLineAtNonEmptyRow (editor, point) {
  point = Point.fromObject(point)
  return point.column > 0 && pointIsAtEndOfLine(editor, point)
}

function pointIsAtVimEndOfFile (editor, point) {
  return getVimEofBufferPosition(editor).isEqual(point)
}

function isEmptyRow (editor, row) {
  return editor.bufferRangeForBufferRow(row).isEmpty()
}

function getRightCharacterForBufferPosition (editor, point, amount = 1) {
  return editor.getTextInBufferRange(Range.fromPointWithDelta(point, 0, amount))
}

function getLeftCharacterForBufferPosition (editor, point, amount = 1) {
  return editor.getTextInBufferRange(Range.fromPointWithDelta(point, 0, -amount))
}

function getTextInScreenRange (editor, screenRange) {
  return editor.getTextInBufferRange(editor.bufferRangeForScreenRange(screenRange))
}

function getNonWordCharactersForCursor (cursor) {
  if (settings.get('useLanguageIndependentNonWordCharacters')) {
    return settings.get('languageIndependentNonWordCharacters')
  }

  return cursor.getNonWordCharacters != null
    ? cursor.getNonWordCharacters() // Atom 1.11.0-beta5 have this experimental method.
    : atom.config.get('editor.nonWordCharacters', {scope: cursor.getScopeDescriptor().getScopesArray()})
}

function getRows (editor, bufferOrScreen, {startRow, direction}) {
  switch (direction) {
    case 'previous':
      return startRow <= 0 ? [] : getList(startRow - 1, 0)
    case 'next':
      const endRow = bufferOrScreen === 'buffer' ? getVimLastBufferRow(editor) : getVimLastScreenRow(editor)
      return startRow >= endRow ? [] : getList(startRow + 1, endRow)
  }
}

// Return Vim's EOF position rather than Atom's EOF position.
// This function change meaning of EOF from native TextEditor::getEofBufferPosition()
// Atom is special(strange) for cursor can past very last newline character.
// Because of this, Atom's EOF position is [actualLastRow+1, 0] provided last-non-blank-row
// ends with newline char.
// But in Vim, curor can NOT past last newline. EOF is next position of very last character.
function getVimEofBufferPosition (editor) {
  const eof = editor.getEofBufferPosition()
  return eof.row === 0 || eof.column > 0 ? eof : getEndOfLineForBufferRow(editor, eof.row - 1)
}

function getVimEofScreenPosition (editor) {
  return editor.screenPositionForBufferPosition(getVimEofBufferPosition(editor))
}

function getVimLastBufferRow (editor) {
  return getVimEofBufferPosition(editor).row
}

function getVimLastScreenRow (editor) {
  return getVimEofScreenPosition(editor).row
}

function getFirstCharacterPositionForBufferRow (editor, row) {
  const scanRange = editor.bufferRangeForBufferRow(row)
  return findInEditor(editor, 'forward', /^[ \t]*/, {scanRange}, event => event.range.end)
}

function getScreenPositionForScreenRow (editor, row, which, {allowOffScreenPosition = false} = {}) {
  if (which === 'beginning') {
    const column = allowOffScreenPosition ? 0 : editor.getFirstVisibleScreenColumn()
    return new Point(row, column)
  } else if (which === 'last-character') {
    const column = allowOffScreenPosition
      ? Infinity
      : editor.getFirstVisibleScreenColumn() + editor.getEditorWidthInChars()
    return new Point(row, column)
  } else if (which === 'first-character') {
    const column = allowOffScreenPosition
      ? editor.clipScreenPosition([row, 0], {skipSoftWrapIndentation: true}).column
      : editor.getFirstVisibleScreenColumn()

    const scanRange = editor.bufferRangeForScreenRange([[row, column], [row, Infinity]])
    const point = findInEditor(editor, 'forward', /\S/, {scanRange}, event => event.range.start)
    if (point) return editor.screenPositionForBufferPosition(point)
  }
}

function trimBufferRange (editor, range) {
  const newRange = range.copy()
  editor.scanInBufferRange(/\S/, range, event => (newRange.start = event.range.start))
  editor.backwardsScanInBufferRange(/\S/, range, event => (newRange.end = event.range.end))
  return newRange
}

// Cursor motion wrapper
// -------------------------
// Set bufferRow with keeping column and goalColumn
function setBufferRow (cursor, row, options) {
  const editor = cursor.editor
  if (editor.softTabs) {
    const column = cursor.goalColumn != null ? cursor.goalColumn : cursor.getBufferColumn()
    cursor.setBufferPosition([row, column], options)
    cursor.goalColumn = column
  } else {
    const column =
      cursor.goalColumn != null
        ? cursor.goalColumn
        : translateColumnOnHardTabEditor(editor, cursor.getBufferRow(), cursor.getBufferColumn(), true)

    cursor.setBufferPosition([row, translateColumnOnHardTabEditor(editor, row, column, false)], options)
    cursor.goalColumn = column
  }
}

function translateColumnOnHardTabEditor (editor, row, column, expandTab) {
  const chars = editor.lineTextForBufferRow(row).slice(0, column)

  if (column === 0 || column === Infinity || !chars.includes('\t')) {
    return column
  }

  let newColumn = 0
  const tabLength = editor.getTabLength()
  const charLength = char => (char === '\t' ? tabLength : 1)
  if (expandTab) {
    for (const char of chars) {
      newColumn += charLength(char)
    }
  } else {
    let traversedColumn = 0
    for (const char of chars) {
      newColumn++
      traversedColumn += charLength(char)
      if (traversedColumn >= column) {
        if (traversedColumn > column) newColumn--
        break
      }
    }
  }
  return newColumn
}

function setBufferColumn (cursor, column) {
  return cursor.setBufferPosition([cursor.getBufferRow(), column])
}

function moveCursor (cursor, keepGoalColumn, fn) {
  const goalColumn = keepGoalColumn ? cursor.goalColumn : undefined
  fn(cursor)
  if (goalColumn != null) {
    cursor.goalColumn = goalColumn
  }
}

function moveCursorLeft (cursor, {allowWrap, preventIncorrectWrap, keepGoalColumn} = {}) {
  // See t9md/vim-mode-plus#226
  // On atomicSoftTabs enabled editor, there is situation where
  // (bufferColumn >  0 && screenColumn === 0) become true.
  // So we cannot believe bufferColumn, check screenColumn to prevent wrap.
  if (preventIncorrectWrap && cursor.getScreenColumn() === 0) {
    return
  }

  if (!cursor.isAtBeginningOfLine() || allowWrap) {
    moveCursor(cursor, keepGoalColumn, cursor => cursor.moveLeft())
  }
}

function moveCursorRight (cursor, {allowWrap, keepGoalColumn} = {}) {
  if (!cursor.isAtEndOfLine() || allowWrap) {
    moveCursor(cursor, keepGoalColumn, cursor => cursor.moveRight())
  }
}

function moveCursorUpScreen (cursor, {keepGoalColumn} = {}) {
  if (cursor.getScreenRow() > 0) {
    moveCursor(cursor, keepGoalColumn, cursor => cursor.moveUp())
  }
}

function moveCursorDownScreen (cursor, {keepGoalColumn} = {}) {
  if (cursor.getScreenRow() < getVimLastScreenRow(cursor.editor)) {
    moveCursor(cursor, keepGoalColumn, cursor => cursor.moveDown())
  }
}

function moveCursorToFirstCharacterAtRow (cursor, row) {
  cursor.setBufferPosition([row, 0])
  cursor.moveToFirstCharacterOfLine()
}

function getValidVimBufferRow (editor, row) {
  return limitNumber(row, {min: 0, max: getVimLastBufferRow(editor)})
}

function getValidVimScreenRow (editor, row) {
  return limitNumber(row, {min: 0, max: getVimLastScreenRow(editor)})
}

// By default not include column
function getLineTextToBufferPosition (editor, {row, column}, {exclusive = true} = {}) {
  return editor.lineTextForBufferRow(row).slice(0, exclusive ? column : column + 1)
}

function getCodeFoldRanges ({tokenizedBuffer}) {
  return tokenizedBuffer.getFoldableRanges(1).filter(range => !tokenizedBuffer.isRowCommented(range.start.row))
}

// Used in vmp-jasmine-increase-focus
function getCodeFoldRangesContainesRow (editor, bufferRow) {
  return getCodeFoldRanges(editor).filter(range => range.start.row <= bufferRow && bufferRow <= range.end.row)
}

function getClosestFoldRangeContainsRow (editor, bufferRow) {
  const ranges = getCodeFoldRanges(editor).filter(range => range.start.row <= bufferRow && bufferRow <= range.end.row)
  return getLast(ranges)
}

function getFoldInfoByKind (editor) {
  const foldInfoByKind = {}

  function updateFoldInfo (kind, rangeAndIndent) {
    if (!foldInfoByKind[kind]) {
      foldInfoByKind[kind] = {listOfRangeAndIndent: []}
    }
    const foldInfo = foldInfoByKind[kind]
    foldInfo.listOfRangeAndIndent.push(rangeAndIndent)
    const {indent} = rangeAndIndent
    foldInfo.minIndent = Math.min(foldInfo.minIndent != null ? foldInfo.minIndent : indent, indent)
    foldInfo.maxIndent = Math.max(foldInfo.maxIndent != null ? foldInfo.maxIndent : indent, indent)
  }

  for (const range of getCodeFoldRanges(editor)) {
    const rangeAndIndent = {
      range: range,
      indent: editor.indentationForBufferRow(range.start.row)
    }
    updateFoldInfo('allFold', rangeAndIndent)
    const kind = editor.isFoldedAtBufferRow(range.start.row) ? 'folded' : 'unfolded'
    updateFoldInfo(kind, rangeAndIndent)
  }
  return foldInfoByKind
}

function getBufferRangeForRowRange (editor, [startRow, endRow]) {
  return new Range([startRow, 0], [startRow, 0]).union(editor.bufferRangeForBufferRow(endRow, {includeNewline: true}))
}

function getTokenizedLineForRow (editor, row) {
  return editor.tokenizedBuffer.tokenizedLineForRow(row)
}

function getScopesForTokenizedLine (line) {
  return line.tags.filter(tag => tag < 0 && tag % 2 === -1).map(tag => atom.grammars.scopeForId(tag))
}

function scanForScopeStart (editor, fromPoint, direction, fn) {
  fromPoint = Point.fromObject(fromPoint)

  let scanRows, isValidToken
  if (direction === 'forward') {
    scanRows = getList(fromPoint.row, editor.getLastBufferRow())
    isValidToken = ({position}) => position.isGreaterThan(fromPoint)
  } else if (direction === 'backward') {
    scanRows = getList(fromPoint.row, 0)
    isValidToken = ({position}) => position.isLessThan(fromPoint)
  }

  for (const row of scanRows) {
    const tokenizedLine = getTokenizedLineForRow(editor, row)
    if (!tokenizedLine) return
    let column = 0
    let results = []

    const tokenIterator = tokenizedLine.getTokenIterator()
    for (const tag of tokenizedLine.tags) {
      tokenIterator.next()
      if (tag >= 0) {
        // Positive: tag is char length
        column += tag
        continue
      }

      // Negative: start/stop token
      if (tag % 2 !== 0) {
        // Odd = scope start (Even = scope stop)
        results.push({
          scope: atom.grammars.scopeForId(tag),
          position: new Point(row, column)
        })
      }
    }

    results = results.filter(isValidToken)
    if (direction === 'backward') results.reverse()

    let continueScan = true
    const stop = () => (continueScan = false)
    for (const result of results) {
      fn(result, stop)
      if (!continueScan) return
    }
    if (!continueScan) return
  }
}

function detectScopeStartPositionForScope (editor, fromPoint, direction, scopeToSearch) {
  let point = null
  scanForScopeStart(editor, fromPoint, direction, ({scope, position}, stop) => {
    if (scope.search(scopeToSearch) >= 0) {
      point = position
      stop()
    }
  })
  return point
}

function isIncludeFunctionScopeForRow (editor, row) {
  // [FIXME] Bug of upstream?
  // Sometime tokenizedLines length is less than last buffer row.
  // So tokenizedLine is not accessible even if valid row.
  // In that case I simply return empty Array.
  const tokenizedLine = getTokenizedLineForRow(editor, row)
  return tokenizedLine && getScopesForTokenizedLine(tokenizedLine).some(scope => isFunctionScope(editor, scope))
}

// [FIXME] very rough state, need improvement.
function isFunctionScope (editor, scope) {
  const match = (scope, ...scopes) => new RegExp('^' + scopes.map(escapeRegExp).join('|')).test(scope)

  switch (editor.getGrammar().scopeName) {
    case 'source.go':
    case 'source.elixir':
    case 'source.rust':
      return match(scope, 'entity.name.function')
    case 'source.ruby':
      return match(scope, 'meta.function.', 'meta.class.', 'meta.module.')
    case 'source.ts':
      return match(scope, 'meta.function.ts', 'meta.method.declaration.ts', 'meta.interface.ts', 'meta.class.ts')
    case 'source.js':
    case 'source.js.jsx':
      // excluding "meta.function.arrow.js"
      return match(scope, 'meta.function.js', 'meta.function.method.', 'meta.class.js')
    default:
      return match(scope, 'meta.function.', 'meta.class.')
  }
}

// Scroll to bufferPosition with minimum amount to keep original visible area.
// If target position won't fit within onePageUp or onePageDown, it center target point.
function smartScrollToBufferPosition (editor, point) {
  const editorElement = editor.element
  const editorAreaHeight = editor.getLineHeightInPixels() * (editor.getRowsPerPage() - 1)
  const onePageUp = editorElement.getScrollTop() - editorAreaHeight // No need to limit to min=0
  const onePageDown = editorElement.getScrollBottom() + editorAreaHeight
  const target = editorElement.pixelPositionForBufferPosition(point).top

  const exceedOnePage = onePageDown < target || target < onePageUp
  editor.scrollToBufferPosition(point, {center: exceedOnePage})
}

function matchScopes ({classList}, scopes = []) {
  return scopes.some(scope => scope.split('.').every(name => classList.contains(name)))
}

function isSingleLineText (text) {
  return text.split(/\n|\r\n/).length === 1
}

// Return bufferRange and kind ['white-space', 'non-word', 'word']
//
// This function modify wordRegex so that it feel NATURAL in Vim's normal mode.
// In normal-mode, cursor is ractangle(not pipe(|) char).
// Cursor is like ON word rather than BETWEEN word.
// The modification is tailord like this
//   - ON white-space: Includs only white-spaces.
//   - ON non-word: Includs only non word char(=excludes normal word char).
//
// Valid options
//  - wordRegex: instance of RegExp
//  - nonWordCharacters: string
function getWordBufferRangeAndKindAtBufferPosition (editor, point, options = {}) {
  let kind
  let {singleNonWordChar = true, wordRegex, nonWordCharacters, cursor} = options
  if (!wordRegex || !nonWordCharacters) {
    // Complement from cursor
    if (!cursor) cursor = editor.getLastCursor()
    const complemented = Object.assign(options, buildWordPatternByCursor(cursor, wordRegex))
    wordRegex = complemented.wordRegex
    nonWordCharacters = complemented.nonWordCharacters
  }

  const characterAtPoint = getRightCharacterForBufferPosition(editor, point)
  const nonWordRegex = new RegExp(`[${escapeRegExp(nonWordCharacters)}]+`)

  if (/\s/.test(characterAtPoint)) {
    kind = 'white-space'
    wordRegex = new RegExp('[\\t ]+')
  } else if (nonWordRegex.test(characterAtPoint) && !wordRegex.test(characterAtPoint)) {
    kind = 'non-word'
    if (singleNonWordChar) {
      wordRegex = new RegExp(escapeRegExp(characterAtPoint))
    } else {
      wordRegex = nonWordRegex
    }
  } else {
    kind = 'word'
  }

  const range = getWordBufferRangeAtBufferPosition(editor, point, wordRegex)
  return {kind, range}
}

function getWordPatternAtBufferPosition (editor, point, options = {}) {
  const {boundarizeForWord = true} = options
  delete options.boundarizeForWord
  const {range, kind} = getWordBufferRangeAndKindAtBufferPosition(editor, point, options)
  const text = editor.getTextInBufferRange(range)
  let pattern = escapeRegExp(text)

  if (kind === 'word' && boundarizeForWord) {
    // Set word-boundary( \b ) anchor only when it's effective #689
    const startBoundary = /^\w/.test(text) ? '\\b' : ''
    const endBoundary = /\w$/.test(text) ? '\\b' : ''
    pattern = startBoundary + pattern + endBoundary
  }
  return new RegExp(pattern, 'g')
}

function getSubwordPatternAtBufferPosition (editor, point, options = {}) {
  return getWordPatternAtBufferPosition(editor, point, {
    wordRegex: editor.getLastCursor().subwordRegExp(),
    boundarizeForWord: false
  })
}

// Return options used for getWordBufferRangeAtBufferPosition
function buildWordPatternByCursor (cursor, wordRegex) {
  const nonWordCharacters = getNonWordCharactersForCursor(cursor)
  if (wordRegex == null) wordRegex = new RegExp(`^[\t ]*$|[^\\s${escapeRegExp(nonWordCharacters)}]+`)
  return {wordRegex, nonWordCharacters}
}

function getWordBufferRangeAtBufferPosition (editor, from, regex) {
  const options = {from, allowNextLine: false, contains: true}
  const end = findInEditor(editor, 'forward', regex, options, event => event.range.end) || options.from
  options.from = end
  const start = findInEditor(editor, 'backward', regex, options, event => event.range.start) || options.from

  return new Range(start, end)
}

// When range is linewise range, range end have column 0 of NEXT row.
// This function adjust range.end to EOL of selected line.
function shrinkRangeEndToBeforeNewLine (range) {
  return range.end.column === 0
    ? new Range(range.start, [limitNumber(range.end.row - 1, {min: range.start.row}), Infinity])
    : range
}

function collectRangeByScan (editor, regex, options) {
  const result = []
  const collect = event => result.push(event.range)

  if (!options) {
    editor.scan(regex, collect)
  } else {
    const scanRange = options.scanRange || editor.bufferRangeForBufferRow(options.row)
    editor.scanInBufferRange(regex, scanRange, collect)
  }
  return result
}

// take bufferPosition
function translatePointAndClip (editor, point, direction) {
  point = Point.fromObject(point)

  let dontClip = false
  switch (direction) {
    case 'forward':
      point = point.translate([0, +1])
      const eol = editor.bufferRangeForBufferRow(point.row).end

      if (point.isGreaterThanOrEqual(eol)) {
        dontClip = true // FIXME I think it's not necessary need re-think
        if (point.isGreaterThan(eol)) {
          point = point.traverse([1, 0]) // move to start of next row.
        }
      }
      point = Point.min(point, editor.getEofBufferPosition())
      break

    case 'backward':
      point = point.translate([0, -1])

      if (point.column < 0) {
        dontClip = true
        const newRow = point.row - 1
        point = new Point(newRow, editor.bufferRangeForBufferRow(newRow).end.column)
      }

      point = Point.max(point, Point.ZERO)
      break
  }

  return dontClip
    ? point
    : editor.bufferPositionForScreenPosition(editor.screenPositionForBufferPosition(point, {clipDirection: direction}))
}

function getRangeByTranslatePointAndClip (editor, range, which, direction) {
  const newPoint = translatePointAndClip(editor, range[which], direction)
  switch (which) {
    case 'start':
      return new Range(newPoint, range.end)
    case 'end':
      return new Range(range.start, newPoint)
  }
}

function getPackage (name) {
  return new Promise(resolve => {
    if (atom.packages.isPackageActive(name)) {
      resolve(atom.packages.getActivePackage(name))
    } else {
      const disposable = atom.packages.onDidActivatePackage(pkg => {
        if (pkg.name === name) {
          disposable.dispose()
          resolve(pkg)
        }
      })
    }
  })
}

function searchByProjectFind (editor, text) {
  atom.commands.dispatch(editor.element, 'project-find:show')
  getPackage('find-and-replace').then(pkg => {
    const {projectFindView} = pkg.mainModule
    if (projectFindView) {
      projectFindView.findEditor.setText(text)
      projectFindView.confirm()
    }
  })
}

function limitNumber (number, {max, min} = {}) {
  if (max != null) number = Math.min(number, max)
  if (min != null) number = Math.max(number, min)
  return number
}

function findRangeContainsPoint (ranges, point) {
  return ranges.find(range => range.containsPoint(point))
}

const negateFunction = fn => (...args) => !fn(...args)

const isEmpty = target => target.isEmpty()
const isNotEmpty = negateFunction(isEmpty)

const isSingleLineRange = range => range.isSingleLine()
const isNotSingleLineRange = negateFunction(isSingleLineRange)

const isLeadingWhiteSpaceRange = (editor, range) => {
  return range.start.column === 0 && /^[\t ]*$/.test(editor.getTextInBufferRange(range))
}
const isNotLeadingWhiteSpaceRange = negateFunction(isLeadingWhiteSpaceRange)

function isEscapedCharRange (editor, range) {
  range = Range.fromObject(range)
  const chars = getLeftCharacterForBufferPosition(editor, range.start, 2)
  return chars.endsWith('\\') && !chars.endsWith('\\\\')
}

function insertTextAtBufferPosition (editor, point, text) {
  return editor.setTextInBufferRange([point, point], text)
}

function ensureEndsWithNewLineForBufferRow (editor, row) {
  if (!isEndsWithNewLineForBufferRow(editor, row)) {
    const eol = getEndOfLineForBufferRow(editor, row)
    insertTextAtBufferPosition(editor, eol, '\n')
  }
}

function toggleCaseForCharacter (char) {
  const charLower = char.toLowerCase()
  return charLower === char ? char.toUpperCase() : charLower
}

function splitTextByNewLine (text) {
  return text.endsWith('\n') ? text.trimRight().split(/\r?\n/g) : text.split(/\r?\n/g)
}

function replaceDecorationClassBy (decoration, fn) {
  const props = decoration.getProperties()
  decoration.setProperties(Object.assign(props, {class: fn(props.class)}))
}

// Modify range used for undo/redo flash highlight to make it feel naturally for human.
//  - Trim starting new line("\n")
//     "\nabc" -> "abc"
//  - If range.end is EOL extend range to first column of next line.
//     "abc" -> "abc\n"
// e.g.
// - when 'c' is atEOL: "\nabc" -> "abc\n"
// - when 'c' is NOT atEOL: "\nabc" -> "abc"
//
// So always trim initial "\n" part range because flashing trailing line is counterintuitive.
function humanizeNewLineForBufferRange (editor, range) {
  range = range.copy()
  if (isSingleLineRange(range) || isLinewiseRange(range)) return range

  if (pointIsAtEndOfLine(editor, range.start)) range.start = range.start.traverse([1, 0])
  if (pointIsAtEndOfLine(editor, range.end)) range.end = range.end.traverse([1, 0])
  return range
}

// [TODO] Improve further by checking oldText, newText?
// [Purpose of this function]
// Suppress flash when undo/redoing toggle-comment while flashing undo/redo of occurrence operation.
// This huristic approach never be perfect.
// Ultimately cannnot distinguish occurrence operation.
function isMultipleAndAllRangeHaveSameColumnAndConsecutiveRows (ranges) {
  if (ranges.length <= 1) {
    return false
  }

  const {start: {column: startColumn}, end: {column: endColumn}} = ranges[0]
  let previousRow

  for (const range of ranges) {
    const {start, end} = range
    if (start.column !== startColumn || end.column !== endColumn) return false
    if (previousRow != null && previousRow + 1 !== start.row) return false
    previousRow = start.row
  }
  return true
}

// Expand range to white space
//  1. Expand to forward direction, if suceed return new range.
//  2. Expand to backward direction, if succeed return new range.
//  3. When faild to expand either direction, return original range.
function expandRangeToWhiteSpaces (editor, range) {
  const newEnd = findPoint(editor, 'forward', /\S/, 'start', {from: range.end, allowNextLine: false})
  if (newEnd) return new Range(range.start, newEnd)

  const newStart = findPoint(editor, 'backward', /\S/, 'end', {from: range.start, allowNextLine: false})
  if (newStart) return new Range(newStart, range.end)

  return range // fallback
}

// Return list of argument token.
// Token is object like {text: String, type: String}
// type should be "separator" or "argument"
function splitArguments (text, joinSpaceSeparatedToken = true) {
  const separatorChars = '\t, \r\n'
  const quoteChars = '"\'`'
  const closeCharToOpenChar = {
    ')': '(',
    '}': '{',
    ']': '['
  }
  const closePairChars = Object.keys(closeCharToOpenChar).join('')
  const openPairChars = Object.values(closeCharToOpenChar).join('')
  const escapeChar = '\\'

  let pendingToken = ''
  let inQuote = false
  let isEscaped = false
  let allTokens = []
  let currentSection = null

  // Parse text as list of tokens which is commma separated or white space separated.
  // e.g. 'a, fun1(b, c), d' => ['a', 'fun1(b, c), 'd']
  // Not perfect. but far better than simple string split by regex pattern.
  // let allTokens = []
  // let currentSection

  function settlePending () {
    if (pendingToken) {
      allTokens.push({text: pendingToken, type: currentSection})
      pendingToken = ''
    }
  }

  function changeSection (newSection) {
    if (currentSection !== newSection) {
      if (currentSection) settlePending()
      currentSection = newSection
    }
  }

  const pairStack = []
  for (const char of text) {
    if (pairStack.length === 0 && separatorChars.includes(char)) {
      changeSection('separator')
    } else {
      changeSection('argument')
      if (isEscaped) {
        isEscaped = false
      } else if (char === escapeChar) {
        isEscaped = true
      } else if (inQuote) {
        if (quoteChars.includes(char) && getLast(pairStack) === char) {
          inQuote = false
          pairStack.pop()
        }
      } else if (quoteChars.includes(char)) {
        inQuote = true
        pairStack.push(char)
      } else if (openPairChars.includes(char)) {
        pairStack.push(char)
      } else if (closePairChars.includes(char)) {
        if (getLast(pairStack) === closeCharToOpenChar[char]) pairStack.pop()
      }
    }
    pendingToken += char
  }
  settlePending()

  if (joinSpaceSeparatedToken && allTokens.some(({type, text}) => type === 'separator' && text.includes(','))) {
    // When some separator contains `,` treat white-space separator as just part of token.
    // So we move white-space only sparator into tokens by joining mis-separatoed tokens.
    const newAllTokens = []
    while (allTokens.length) {
      const token = allTokens.shift()
      switch (token.type) {
        case 'argument':
          newAllTokens.push(token)
          break
        case 'separator':
          if (token.text.includes(',')) {
            newAllTokens.push(token)
          } else {
            // 1. Concatnate white-space-separator and next-argument
            // 2. Then join into latest argument
            const lastArg = newAllTokens.length ? newAllTokens.pop() : {text: '', type: 'argument'}
            lastArg.text += token.text + (allTokens.length ? allTokens.shift().text : '') // concat with next-token
            newAllTokens.push(lastArg)
          }
          break
      }
    }
    allTokens = newAllTokens
  }
  return allTokens
}

// Safe translation for point.
// Unless both point and translation was provided, it return passed point.
// So when you pass null as point, just return null.
function safeTranslatePoint (point, translation) {
  return point && translation ? point.translate(translation) : point
}

// Retern copied object without having passed props
function exceptProps (object, props = []) {
  object = Object.assign({}, object) // shallow copy
  for (const prop of props) {
    delete object[prop]
  }
  return object
}

// * Options
//   * contains: {Boolean} default `false`
//   * allowNextLine: {Boolean} defualt `true`
//   * skipEmptyRow: {Boolean} skip completely empty row
//   * skipWhiteSpaceOnlyRow: {Boolean} skip non-empty but white-space contain row
function scanEditor (editor, direction, regex, options, fn) {
  let {from, scanRange} = options
  if (!from && !scanRange) throw new Error("You must 'from' or 'scanRange' options")
  const {contains, allowNextLine = true, skipEmptyRow, skipWhiteSpaceOnlyRow} = options
  if (contains && !from) throw new Error("You must pass 'from' to check 'contains'")

  if (from) from = Point.fromObject(from)
  let scanFunction
  switch (direction) {
    case 'forward':
    case 'next':
      if (!scanRange) scanRange = [from, getVimEofBufferPosition(editor)]
      scanFunction = 'scanInBufferRange'
      break
    case 'backward':
    case 'previous':
      if (!scanRange) scanRange = [[0, 0], from]
      scanFunction = 'backwardsScanInBufferRange'
      break
  }

  editor[scanFunction](regex, scanRange, event => {
    const {range, matchText, stop} = event
    if (!allowNextLine && range.start.row !== from.row) {
      stop()
      return
    }

    // Ignore 'empty line' matches between '\r' and '\n'
    if (matchText === '' && range.start.column !== 0) return

    if (skipEmptyRow && !matchText) return
    if (skipWhiteSpaceOnlyRow && matchText && !/\S+/.test(matchText)) return
    if (contains && !range.containsPoint(from)) return

    fn(event)
  })
}

// Once callback retuned truthy value, it stop scannning, and return returned truthy value.
// Benefit of this function is
//  - No need to call stop()
//  - No need to use temporal variable to extract found var from callback.
//  - Whatever value you can return(range, point, whatever you returned truthy value)
function findInEditor (editor, direction, regex, options, fn) {
  let result
  scanEditor(editor, direction, regex, options, event => {
    result = fn(event)
    if (result) {
      event.stop()
    }
  })
  // This guard avoid return `falthy` value when && or || short circuit expression was used in callback.
  if (result) return result
}

// Find point which matches regex.
//   Returns {Point} bufferPosition of start or end of regex matched range
//
// * Options
//  * from: {Point} BufferPosition to start search from
//  * regex: {RegExp}
//  * preTranslate: {Point} translation against from before start search
//  * postTranslate: {Point} translation against found point.
//  * Plus scan options supported by scanEditor()
function findPoint (editor, direction, regex, which, options) {
  const pointCompareMethod = ['next', 'forward'].includes(direction) ? 'isGreaterThan' : 'isLessThan'
  const {preTranslate, postTranslate} = options
  const from = editor.clipBufferPosition(safeTranslatePoint(options.from, preTranslate))
  const scanOptions = exceptProps(options, ['preTranslate', 'postTranslate'])
  scanOptions.from = from

  const point = findInEditor(editor, direction, regex, scanOptions, event => {
    const pointToCompare = event.range[which]
    return pointToCompare[pointCompareMethod](from) && pointToCompare
  })
  return safeTranslatePoint(point, postTranslate)
}

function adjustIndentWithKeepingLayout (editor, range) {
  // Adjust indentLevel with keeping original layout of pasting text.
  // Suggested indent level of range.start.row is correct as long as range.start.row have minimum indent level.
  // But when we paste following already indented three line text, we have to adjust indent level
  //  so that `varFortyTwo` line have suggestedIndentLevel.
  //
  //        varOne: value # suggestedIndentLevel is determined by this line
  //   varFortyTwo: value # We need to make final indent level of this row to be suggestedIndentLevel.
  //      varThree: value
  //
  // So what we are doing here is apply suggestedIndentLevel with fixing issue above.
  // 1. Determine minimum indent level among pasted range(= range ) excluding empty row
  // 2. Then update indentLevel of each rows to final indentLevel of minimum-indented row have suggestedIndentLevel.
  const suggestedLevel = editor.suggestedIndentForBufferRow(range.start.row)
  const rowAndActualLevels = []
  let minLevel

  for (const row of getList(range.start.row, range.end.row, false)) {
    if (isEmptyRow(editor, row)) continue
    const actualLevel = editor.indentationForBufferRow(row)
    rowAndActualLevels.push([row, actualLevel])
    minLevel = minLevel == null ? actualLevel : Math.min(minLevel, actualLevel)
  }
  if (minLevel == null) return

  const deltaToSuggestedLevel = suggestedLevel - minLevel
  if (deltaToSuggestedLevel) {
    for (const [row, actualLevel] of rowAndActualLevels) {
      editor.setIndentationForBufferRow(row, actualLevel + deltaToSuggestedLevel)
    }
  }
}

// Check point containment with end position exclusive
function rangeContainsPointWithEndExclusive (range, point) {
  range.start.isLessThanOrEqual(point) && range.end.isGreaterThan(point)
}

function traverseTextFromPoint (point, text) {
  return Point.fromObject(point).traverse(getTraversalForText(text))
}

function getTraversalForText (text) {
  NEWLINE_REG_EXP.lastIndex = 0

  let row = 0
  let lastIndex = 0
  while (NEWLINE_REG_EXP.exec(text)) {
    row++
    lastIndex = NEWLINE_REG_EXP.lastIndex
  }
  return new Point(row, text.length - lastIndex)
}

function getRowAmongFoldedRowIntersectsBufferRow (editor, bufferRow, which) {
  const bufferRange = editor.bufferRangeForBufferRow(bufferRow)
  const markers = editor.displayLayer.foldsMarkerLayer.findMarkers({intersectsRange: bufferRange})
  if (!markers.length) {
    throw new Error('getRowAmongFoldedRowIntersectsBufferRow() called for non-folded bufferRow!')
  }
  const ranges = markers.map(marker => marker.getRange())
  return which === 'min'
    ? Math.min(...ranges.map(range => range.start.row))
    : Math.max(...ranges.map(range => range.end.row))
}

// Return min row among folds intersecting screenRow of bufferRow if bufferRow was folded.
function getFoldStartRowForRow (editor, row) {
  return editor.isFoldedAtBufferRow(row) ? getRowAmongFoldedRowIntersectsBufferRow(editor, row, 'min') : row
}

// Return max row among folds intersecting screenRow of bufferRow if bufferRow was folded.
function getFoldEndRowForRow (editor, row) {
  return editor.isFoldedAtBufferRow(row) ? getRowAmongFoldedRowIntersectsBufferRow(editor, row, 'max') : row
}

function doesRangeStartAndEndWithSameIndentLevel (editor, range) {
  return editor.indentationForBufferRow(range.start.row) === editor.indentationForBufferRow(range.end.row)
}

function getList (start, end, inclusive = true) {
  const range = []
  if (start < end) {
    if (inclusive) for (let i = start; i <= end; i++) range.push(i)
    else for (let i = start; i < end; i++) range.push(i)
  } else {
    if (inclusive) for (let i = start; i >= end; i--) range.push(i)
    else for (let i = start; i > end; i--) range.push(i)
  }
  return range
}

function unindent (text) {
  let indentLength
  const lines = text.split(/\n/)
  const minIndent = lines.reduce((maxIndentLength, line) => {
    indentLength = line === '' ? maxIndentLength : line.match(/^ */)[0].length
    return Math.min(indentLength, maxIndentLength)
  }, Infinity)
  return lines.map(line => line.slice(minIndent)).join('\n')
}

// function convertTabToSpace (text, tabLength) {
//   return text.replace(/^[\t ]+/gm, text => text.replace(/\t/g, ' '.repeat(tabLength)))
// }
//
// function convertSpaceToTab (text, tabLength) {
//   return text.replace(/^ +/gm, s => {
//     const tabs = '\t'.repeat(Math.floor(s.length / tabLength))
//     const spaces = ' '.repeat(s.length % tabLength)
//     return tabs + spaces
//   })
// }

function removeIndent (text, removeFirstAndLastLine = true) {
  let indentLength
  const lines = text.split(/\n/)
  if (removeFirstAndLastLine) {
    lines.shift()
    lines.pop()
  }

  const minIndent = lines.reduce((maxIndentLength, line) => {
    indentLength = line === '' ? maxIndentLength : line.match(/^ */)[0].length
    return Math.min(indentLength, maxIndentLength)
  }, Infinity)

  return lines.map(line => line.slice(minIndent)).join('\n')
}

function detectMinimumIndentLengthInText (text) {
  let indentLength
  const lines = text.split(/\n/)

  const minIndent = lines.reduce((maxIndentLength, line) => {
    indentLength = line === '' ? maxIndentLength : line.match(/^ */)[0].length
    return Math.min(indentLength, maxIndentLength)
  }, Infinity)

  return minIndent === Infinity ? 0 : minIndent
}

// FIXME: really, this is garbage.
function normalizeIndent (text, editor, targetRange) {
  // text = convertTabToSpace(text, editor.getTabLength())
  const mapEachLine = (text, fn) =>
    text
      .split(/\n/)
      .map(fn)
      .join('\n')

  // Remove indent
  const minIndent = detectMinimumIndentLengthInText(text)
  text = mapEachLine(text, line => line.slice(minIndent))

  // Detect indent string from existing range
  const indentString = ' '.repeat(detectMinimumIndentLengthInText(editor.getTextInBufferRange(targetRange)))

  // Add indent
  text = mapEachLine(text, line => (line ? indentString : '') + line)

  // text = text.replace(/^/gm, indentString)

  // console.log(text);
  // text = convertSpaceToTab(text)
  return text
}

function atomVersionSatisfies (condition) {
  if (!semver) semver = require('semver')
  return semver.satisfies(atom.appVersion, condition)
}

function getRowRangeForCommentAtBufferRow (editor, row) {
  const isRowCommented = row => editor.tokenizedBuffer.isRowCommented(row)
  if (!isRowCommented(row)) return

  let startRow = row
  let endRow = row

  while (isRowCommented(startRow - 1)) startRow--
  while (isRowCommented(endRow + 1)) endRow++

  return [startRow, endRow]
}

function getHunkRangeAtBufferRow (editor, row) {
  const hunkChar = editor.lineTextForBufferRow(row)[0]
  if (hunkChar && (hunkChar === '+' || hunkChar === '-')) {
    const isHunkRow = row => {
      const lineText = editor.lineTextForBufferRow(row)
      return lineText && lineText[0] === hunkChar
    }

    let [startRow, endRow] = [row, row]

    while (isHunkRow(startRow - 1)) startRow--
    while (isHunkRow(endRow + 1)) endRow++

    return new Range([startRow, 0], [endRow, Infinity])
  }
}

// Replace given text by character based diff
// Purpose: to minimize amount of range to be replaced, which lead cleaner flash highlight
// On undo/redo highlight
function replaceTextInRangeViaDiff (editor, range, newText) {
  if (!Diff) Diff = require('diff')

  let row = range.start.row
  let column = range.start.column
  const point = [0, 0]

  const oldText = editor.getTextInBufferRange(range)
  const changes = Diff.diffChars(oldText, newText)
  editor.transact(() => {
    for (const change of changes) {
      point[0] = row
      point[1] = column

      if (change.added) {
        const newPoint = editor.setTextInBufferRange([point, point], change.value).end
        row = newPoint.row
        column = newPoint.column
      } else if (change.removed) {
        editor.setTextInBufferRange([point, [row, column + change.count]], '')
      } else {
        const newPoint = traverseTextFromPoint(point, change.value)
        row = newPoint.row
        column = newPoint.column
      }
    }
  })
}

function changeArrayOrder (array, action, sortBy) {
  if (array.length < 2) {
    return array
  }

  switch (action) {
    case 'reverse':
      return array.slice().reverse()
    case 'sort':
      return array.slice().sort(sortBy)
    case 'rotate-right':
      return array.slice(1).concat(array[0])
    case 'rotate-left':
      return array.slice(-1).concat(array.slice(0, -1))
  }
}

function changeCharOrder (text, action) {
  return changeArrayOrder(text.split(''), action).join('')
}

module.exports = {
  assertWithException,
  getLast,
  getKeyBindingForCommand,
  debug,
  saveEditorState,
  isLinewiseRange,
  sortRanges,
  sortCursors,
  sortPoints,
  getIndex,
  getVisibleBufferRange,
  getVisibleEditors,
  pointIsAtEndOfLine,
  pointIsAtWhiteSpace,
  pointIsAtNonWhiteSpace,
  pointIsAtEndOfLineAtNonEmptyRow,
  pointIsAtVimEndOfFile,
  getVimEofBufferPosition,
  getVimEofScreenPosition,
  getVimLastBufferRow,
  getVimLastScreenRow,
  setBufferRow,
  translateColumnOnHardTabEditor,
  setBufferColumn,
  moveCursorLeft,
  moveCursorRight,
  moveCursorUpScreen,
  moveCursorDownScreen,
  getEndOfLineForBufferRow,
  getValidVimBufferRow,
  getValidVimScreenRow,
  moveCursorToFirstCharacterAtRow,
  getLineTextToBufferPosition,
  getTextInScreenRange,
  isEmptyRow,
  getCodeFoldRanges,
  getCodeFoldRangesContainesRow,
  getClosestFoldRangeContainsRow,
  getFoldInfoByKind,
  getBufferRangeForRowRange,
  trimBufferRange,
  getFirstCharacterPositionForBufferRow,
  getScreenPositionForScreenRow,
  isIncludeFunctionScopeForRow,
  detectScopeStartPositionForScope,
  getRows,
  smartScrollToBufferPosition,
  matchScopes,
  isSingleLineText,
  getWordBufferRangeAtBufferPosition,
  getWordBufferRangeAndKindAtBufferPosition,
  getWordPatternAtBufferPosition,
  getSubwordPatternAtBufferPosition,
  getNonWordCharactersForCursor,
  shrinkRangeEndToBeforeNewLine,
  collectRangeByScan,
  translatePointAndClip,
  getRangeByTranslatePointAndClip,
  getPackage,
  searchByProjectFind,
  limitNumber,
  findRangeContainsPoint,

  isEmpty,
  isNotEmpty,
  isSingleLineRange,
  isNotSingleLineRange,

  insertTextAtBufferPosition,
  ensureEndsWithNewLineForBufferRow,
  isLeadingWhiteSpaceRange,
  isNotLeadingWhiteSpaceRange,
  isEscapedCharRange,

  toggleCaseForCharacter,
  splitTextByNewLine,
  replaceDecorationClassBy,
  humanizeNewLineForBufferRange,
  isMultipleAndAllRangeHaveSameColumnAndConsecutiveRows,
  expandRangeToWhiteSpaces,
  splitArguments,
  safeTranslatePoint,
  exceptProps,
  scanEditor,
  findInEditor,
  findPoint,
  adjustIndentWithKeepingLayout,
  rangeContainsPointWithEndExclusive,
  traverseTextFromPoint,
  getFoldStartRowForRow,
  getFoldEndRowForRow,
  doesRangeStartAndEndWithSameIndentLevel,
  getList,
  unindent,
  removeIndent,
  normalizeIndent,
  atomVersionSatisfies,
  getRowRangeForCommentAtBufferRow,
  getHunkRangeAtBufferRow,
  replaceTextInRangeViaDiff,
  changeCharOrder,
  changeArrayOrder
}
