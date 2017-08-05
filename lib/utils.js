let fs = null
const settings = require("./settings")
const {Disposable, Range, Point} = require("atom")
const _ = require("underscore-plus")

function assertWithException(condition, message, fn) {
  atom.assert(condition, message, error => {
    throw new Error(error.message)
  })
}

function getAncestors(current) {
  const ancestors = []
  while (true) {
    ancestors.push(current)
    if (current.__super__ != null) current = current.__super__.constructor
    else break
  }
  return ancestors
}

function getKeyBindingForCommand(command, {packageName}) {
  let keymaps = atom.keymaps.getKeyBindings()
  if (packageName) {
    const keymapPath = atom.packages.getActivePackage(packageName).getKeymapPaths().pop()
    keymaps = keymaps.filter(({source}) => source === keymapPath)
  }
  const results = keymaps.filter(keymap => keymap.command === command).map(keymap => ({
    keystrokes: keymap.keystrokes.replace(/shift-/, ""),
    selector: keymap.selector,
  }))
  return results.length ? results : null
}

function debug(...messages) {
  if (!settings.get("debug")) return

  switch (settings.get("debugOutput")) {
    case "console":
      console.log(...messages)
      return
    case "file":
      if (!fs) fs = require("fs-plus")
      const filePath = fs.normalize(settings.get("debugOutputFilePath"))
      if (fs.existsSync(filePath)) fs.appendFileSync(filePath, messages + "\n")
      return
  }
}

// Return function to restore editor's scrollTop and fold state.
function saveEditorState(editor) {
  const editorElement = editor.element
  const scrollTop = editorElement.getScrollTop()

  const foldStartRows = editor.displayLayer.foldsMarkerLayer.findMarkers({}).map(m => m.getStartPosition().row)
  return function() {
    for (const row of foldStartRows.reverse()) {
      if (!editor.isFoldedAtBufferRow(row)) {
        editor.foldBufferRow(row)
      }
    }
    editorElement.setScrollTop(scrollTop)
  }
}

function isLinewiseRange({start, end}) {
  return start.row !== end.row && (start.column === end.column && end.column === 0)
}

function isEndsWithNewLineForBufferRow(editor, row) {
  const {start, end} = editor.bufferRangeForBufferRow(row, {includeNewline: true})
  return start.row !== end.row
}

function sortRanges(collection) {
  return collection.sort((a, b) => a.compare(b))
}

// Return adjusted index fit whitin given list's length
// return -1 if list is empty.
function getIndex(index, list) {
  if (!list.length) return -1
  index = index % list.length
  return index >= 0 ? index : list.length + index
}

// NOTE: endRow become undefined if @editorElement is not yet attached.
// e.g. Beging called immediately after open file.
function getVisibleBufferRange(editor) {
  let [startRow, endRow] = Array.from(editor.element.getVisibleRowRange())
  if (startRow == null || endRow == null) {
    return null
  }
  startRow = editor.bufferRowForScreenRow(startRow)
  endRow = editor.bufferRowForScreenRow(endRow)
  return new Range([startRow, 0], [endRow, Infinity])
}

function getVisibleEditors() {
  // (editor for pane in atom.workspace.getPanes() when editor = pane.getActiveEditor())
  return atom.workspace.getPanes().map(pane => pane.getActiveEditor()).filter(editor => editor)
}

function getEndOfLineForBufferRow(editor, row) {
  return editor.bufferRangeForBufferRow(row).end
}

// Point util
// -------------------------
function pointIsAtEndOfLine(editor, point) {
  point = Point.fromObject(point)
  return getEndOfLineForBufferRow(editor, point.row).isEqual(point)
}

function pointIsOnWhiteSpace(editor, point) {
  const char = getRightCharacterForBufferPosition(editor, point)
  return !/\S/.test(char)
}

function pointIsAtEndOfLineAtNonEmptyRow(editor, point) {
  point = Point.fromObject(point)
  return point.column > 0 && pointIsAtEndOfLine(editor, point)
}

function pointIsAtVimEndOfFile(editor, point) {
  return getVimEofBufferPosition(editor).isEqual(point)
}

function isEmptyRow(editor, row) {
  return editor.bufferRangeForBufferRow(row).isEmpty()
}

function getRightCharacterForBufferPosition(editor, point, amount = 1) {
  return editor.getTextInBufferRange(Range.fromPointWithDelta(point, 0, amount))
}

function getLeftCharacterForBufferPosition(editor, point, amount = 1) {
  return editor.getTextInBufferRange(Range.fromPointWithDelta(point, 0, -amount))
}

function getTextInScreenRange(editor, screenRange) {
  return editor.getTextInBufferRange(editor.bufferRangeForScreenRange(screenRange))
}

function getNonWordCharactersForCursor(cursor) {
  return cursor.getNonWordCharacters != null
    ? cursor.getNonWordCharacters() // Atom 1.11.0-beta5 have this experimental method.
    : atom.config.get("editor.nonWordCharacters", {scope: cursor.getScopeDescriptor().getScopesArray()})
}

// FIXME: remove this
// return true if moved
function moveCursorToNextNonWhitespace(cursor) {
  const originalPoint = cursor.getBufferPosition()
  const editor = cursor.editor
  const vimEof = getVimEofBufferPosition(editor)

  let point = cursor.getBufferPosition()
  while (pointIsOnWhiteSpace(editor, point) && !point.isGreaterThanOrEqual(vimEof)) {
    cursor.moveRight()
    point = cursor.getBufferPosition()
  }
  return !originalPoint.isEqual(cursor.getBufferPosition())
}

function getBufferRows(editor, {startRow, direction}) {
  switch (direction) {
    case "previous":
      return startRow <= 0 ? [] : getRange(startRow - 1, 0)
    case "next":
      const endRow = getVimLastBufferRow(editor)
      return startRow >= endRow ? [] : getRange(startRow + 1, endRow)
  }
}

// Return Vim's EOF position rather than Atom's EOF position.
// This function change meaning of EOF from native TextEditor::getEofBufferPosition()
// Atom is special(strange) for cursor can past very last newline character.
// Because of this, Atom's EOF position is [actualLastRow+1, 0] provided last-non-blank-row
// ends with newline char.
// But in Vim, curor can NOT past last newline. EOF is next position of very last character.
function getVimEofBufferPosition(editor) {
  const eof = editor.getEofBufferPosition()
  return eof.row === 0 || eof.column > 0 ? eof : getEndOfLineForBufferRow(editor, eof.row - 1)
}

function getVimEofScreenPosition(editor) {
  return editor.screenPositionForBufferPosition(getVimEofBufferPosition(editor))
}

function getVimLastBufferRow(editor) {
  return getVimEofBufferPosition(editor).row
}

function getVimLastScreenRow(editor) {
  return getVimEofScreenPosition(editor).row
}

function getFirstVisibleScreenRow(editor) {
  return editor.element.getFirstVisibleScreenRow()
}

function getLastVisibleScreenRow(editor) {
  return editor.element.getLastVisibleScreenRow()
}

function getFirstCharacterPositionForBufferRow(editor, row) {
  const range = findRangeInBufferRow(editor, /\S/, row)
  return range ? range.start : new Point(row, 0)
}

function trimRange(editor, rangeToTrim) {
  let start, end
  const regex = /\S/
  editor.scanInBufferRange(regex, rangeToTrim, ({range}) => (start = range.start))
  if (start) {
    editor.backwardsScanInBufferRange(regex, rangeToTrim, ({range}) => (end = range.end))
  }
  return start && end ? new Range(start, end) : rangeToTrim
}

// Cursor motion wrapper
// -------------------------
// Set bufferRow with keeping column and goalColumn
function setBufferRow(cursor, row, options) {
  const column = cursor.goalColumn != null ? cursor.goalColumn : cursor.getBufferColumn()
  cursor.setBufferPosition([row, column], options)
  cursor.goalColumn = column
}

function setBufferColumn(cursor, column) {
  return cursor.setBufferPosition([cursor.getBufferRow(), column])
}

function moveCursor(cursor, {preserveGoalColumn}, fn) {
  const {goalColumn} = cursor
  fn(cursor)
  if (preserveGoalColumn && goalColumn != null) {
    cursor.goalColumn = goalColumn
  }
}

// Workaround issue for t9md/vim-mode-plus#226 and atom/atom#3174
// I cannot depend cursor's column since its claim 0 and clipping emmulation don't
// return wrapped line, but It actually wrap, so I need to do very dirty work to
// predict wrap huristically.
function shouldPreventWrapLine(cursor) {
  const {row, column} = cursor.getBufferPosition()
  if (atom.config.get("editor.softTabs")) {
    const tabLength = atom.config.get("editor.tabLength")
    if (0 < column && column < tabLength) {
      const text = cursor.editor.getTextInBufferRange([[row, 0], [row, tabLength]])
      return /^\s+$/.test(text)
    }
  }

  return false
}

// options:
//   allowWrap: to controll allow wrap
//   preserveGoalColumn: preserve original goalColumn
function moveCursorLeft(cursor, options = {}) {
  const {allowWrap, needSpecialCareToPreventWrapLine} = options
  delete options.allowWrap
  delete options.needSpecialCareToPreventWrapLine
  if (needSpecialCareToPreventWrapLine && shouldPreventWrapLine(cursor)) {
    return
  }

  if (!cursor.isAtBeginningOfLine() || allowWrap) {
    moveCursor(cursor, options, cursor => cursor.moveLeft())
  }
}

function moveCursorRight(cursor, options = {}) {
  const {allowWrap} = options
  delete options.allowWrap
  if (!cursor.isAtEndOfLine() || allowWrap) {
    moveCursor(cursor, options, cursor => cursor.moveRight())
  }
}

function moveCursorUpScreen(cursor, options = {}) {
  if (cursor.getScreenRow() > 0) {
    moveCursor(cursor, options, cursor => cursor.moveUp())
  }
}

function moveCursorDownScreen(cursor, options = {}) {
  if (cursor.getScreenRow() < getVimLastScreenRow(cursor.editor)) {
    moveCursor(cursor, options, cursor => cursor.moveDown())
  }
}

function moveCursorToFirstCharacterAtRow(cursor, row) {
  cursor.setBufferPosition([row, 0])
  cursor.moveToFirstCharacterOfLine()
}

function getValidVimBufferRow(editor, row) {
  return limitNumber(row, {min: 0, max: getVimLastBufferRow(editor)})
}

function getValidVimScreenRow(editor, row) {
  return limitNumber(row, {min: 0, max: getVimLastScreenRow(editor)})
}

// By default not include column
function getLineTextToBufferPosition(editor, {row, column}, {exclusive = true} = {}) {
  return editor.lineTextForBufferRow(row).slice(0, exclusive ? column : column + 1)
}

function getIndentLevelForBufferRow(editor, row) {
  return editor.indentLevelForLine(editor.lineTextForBufferRow(row))
}

function getCodeFoldRowRanges(editor) {
  return getRange(0, editor.getLastBufferRow())
    .map(row => editor.languageMode.rowRangeForCodeFoldAtBufferRow(row))
    .filter(rowRange => rowRange != null && rowRange[0] != null && rowRange[1] != null)
}

// Used in vmp-jasmine-increase-focus
function getCodeFoldRowRangesContainesForRow(editor, bufferRow, {includeStartRow = true} = {}) {
  const bufferRowContained = includeStartRow
    ? ([startRow, endRow]) => startRow <= bufferRow && bufferRow <= endRow
    : ([startRow, endRow]) => startRow < bufferRow && bufferRow <= endRow

  return getCodeFoldRowRanges(editor).filter(bufferRowContained)
}

function getFoldRowRangesContainedByFoldStartsAtRow(editor, row) {
  if (!editor.isFoldableAtBufferRow(row)) return null

  const [startRow, endRow] = editor.languageMode.rowRangeForFoldAtBufferRow(row)

  const seen = {}
  return getRange(startRow, endRow)
    .map(row => editor.languageMode.rowRangeForFoldAtBufferRow(row))
    .filter(rowRange => rowRange != null && rowRange[0] != null && rowRange[1] != null)
    .filter(rowRange => (seen[rowRange] ? false : (seen[rowRange] = true)))
}

function getFoldRowRanges(editor) {
  const seen = {}
  return getRange(0, editor.getLastBufferRow())
    .map(row => editor.languageMode.rowRangeForCodeFoldAtBufferRow(row))
    .filter(rowRange => rowRange != null && rowRange[0] != null && rowRange[1] != null)
    .filter(rowRange => (seen[rowRange] ? false : (seen[rowRange] = true)))
}

function getFoldRangesWithIndent(editor) {
  return getFoldRowRanges(editor).map(([startRow, endRow]) => ({
    startRow,
    endRow,
    indent: editor.indentationForBufferRow(startRow),
  }))
}

function getFoldInfoByKind(editor) {
  const foldInfoByKind = {}

  function updateFoldInfo(kind, rowRangeWithIndent) {
    if (!foldInfoByKind[kind]) {
      foldInfoByKind[kind] = {rowRangesWithIndent: []}
    }
    const foldInfo = foldInfoByKind[kind]
    foldInfo.rowRangesWithIndent.push(rowRangeWithIndent)
    const {indent} = rowRangeWithIndent
    foldInfo.minIndent = Math.min(foldInfo.minIndent != null ? foldInfo.minIndent : indent, indent)
    foldInfo.maxIndent = Math.max(foldInfo.maxIndent != null ? foldInfo.maxIndent : indent, indent)
  }

  for (const rowRangeWithIndent of getFoldRangesWithIndent(editor)) {
    updateFoldInfo("allFold", rowRangeWithIndent)
    const folded = editor.isFoldedAtBufferRow(rowRangeWithIndent.startRow)
    if (editor.isFoldedAtBufferRow(rowRangeWithIndent.startRow)) {
      updateFoldInfo("folded", rowRangeWithIndent)
    } else {
      updateFoldInfo("unfolded", rowRangeWithIndent)
    }
  }
  return foldInfoByKind
}

function getBufferRangeForRowRange(editor, [startRow, endRow]) {
  const startRange = editor.bufferRangeForBufferRow(startRow, {includeNewline: true})
  const endRange = editor.bufferRangeForBufferRow(endRow, {includeNewline: true})
  return startRange.union(endRange)
}

function getTokenizedLineForRow(editor, row) {
  return editor.tokenizedBuffer.tokenizedLineForRow(row)
}

function getScopesForTokenizedLine(line) {
  return line.tags.filter(tag => tag < 0 && tag % 2 === -1).map(tag => atom.grammars.scopeForId(tag))
}

function scanForScopeStart(editor, fromPoint, direction, fn) {
  fromPoint = Point.fromObject(fromPoint)

  let scanRows, isValidToken
  if (direction === "forward") {
    scanRows = getRange(fromPoint.row, editor.getLastBufferRow())
    isValidToken = ({position}) => position.isGreaterThan(fromPoint)
  } else if (direction === "backward") {
    scanRows = getRange(fromPoint.row, 0)
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
          position: new Point(row, column),
        })
      }
    }

    results = results.filter(isValidToken)
    if (direction === "backward") results.reverse()

    let continueScan = true
    const stop = () => (continueScan = false)
    for (const result of results) {
      fn(result, stop)
      if (!continueScan) return
    }
    if (!continueScan) return
  }
}

function detectScopeStartPositionForScope(editor, fromPoint, direction, scopeToSearch) {
  let point = null
  scanForScopeStart(editor, fromPoint, direction, ({scope, position}, stop) => {
    if (scope.search(scopeToSearch) >= 0) {
      point = position
      stop()
    }
  })
  return point
}

function isIncludeFunctionScopeForRow(editor, row) {
  // [FIXME] Bug of upstream?
  // Sometime tokenizedLines length is less than last buffer row.
  // So tokenizedLine is not accessible even if valid row.
  // In that case I simply return empty Array.
  const tokenizedLine = getTokenizedLineForRow(editor, row)
  return tokenizedLine && getScopesForTokenizedLine(tokenizedLine).some(scope => isFunctionScope(editor, scope))
}

// [FIXME] very rough state, need improvement.
function isFunctionScope(editor, scope) {
  const match = (scope, ...scopes) => new RegExp("^" + scopes.map(_.escapeRegExp).join("|")).test(scope)

  switch (editor.getGrammar().scopeName) {
    case "source.go":
    case "source.elixir":
    case "source.rust":
      return match(scope, "entity.name.function")
    case "source.ruby":
      return match(scope, "meta.function.", "meta.class.", "meta.module.")
    default:
      return match(scope, "meta.function.", "meta.class.")
  }
}

// Scroll to bufferPosition with minimum amount to keep original visible area.
// If target position won't fit within onePageUp or onePageDown, it center target point.
function smartScrollToBufferPosition(editor, point) {
  const editorElement = editor.element
  const editorAreaHeight = editor.getLineHeightInPixels() * (editor.getRowsPerPage() - 1)
  const onePageUp = editorElement.getScrollTop() - editorAreaHeight // No need to limit to min=0
  const onePageDown = editorElement.getScrollBottom() + editorAreaHeight
  const target = editorElement.pixelPositionForBufferPosition(point).top

  const exceedOnePage = onePageDown < target || target < onePageUp
  editor.scrollToBufferPosition(point, {center: exceedOnePage})
}

function matchScopes({classList}, scopes = []) {
  return scopes.some(scope => scope.split(".").every(name => classList.contains(name)))
}

function isSingleLineText(text) {
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
function getWordBufferRangeAndKindAtBufferPosition(editor, point, options = {}) {
  let kind, source
  let {singleNonWordChar = true, wordRegex, nonWordCharacters, cursor} = options
  if (!wordRegex || !nonWordCharacters) {
    // Complement from cursor
    if (!cursor) cursor = editor.getLastCursor()
    ;({wordRegex, nonWordCharacters} = _.extend(options, buildWordPatternByCursor(cursor, wordRegex)))
  }

  const characterAtPoint = getRightCharacterForBufferPosition(editor, point)
  const nonWordRegex = new RegExp(`[${_.escapeRegExp(nonWordCharacters)}]+`)

  if (/\s/.test(characterAtPoint)) {
    kind = "white-space"
    wordRegex = new RegExp("[\t ]+")
  } else if (nonWordRegex.test(characterAtPoint) && !wordRegex.test(characterAtPoint)) {
    kind = "non-word"
    if (singleNonWordChar) {
      wordRegex = new RegExp(_.escapeRegExp(characterAtPoint))
    } else {
      wordRegex = nonWordRegex
    }
  } else {
    kind = "word"
  }

  const range = getWordBufferRangeAtBufferPosition(editor, point, {wordRegex})
  return {kind, range}
}

function getWordPatternAtBufferPosition(editor, point, options = {}) {
  const {boundarizeForWord = true} = options
  delete options.boundarizeForWord
  const {range, kind} = getWordBufferRangeAndKindAtBufferPosition(editor, point, options)
  const text = editor.getTextInBufferRange(range)
  let pattern = _.escapeRegExp(text)

  if (kind === "word" && boundarizeForWord) {
    // Set word-boundary( \b ) anchor only when it's effective #689
    const startBoundary = /^\w/.test(text) ? "\\b" : ""
    const endBoundary = /\w$/.test(text) ? "\\b" : ""
    pattern = startBoundary + pattern + endBoundary
  }
  return new RegExp(pattern, "g")
}

function getSubwordPatternAtBufferPosition(editor, point, options = {}) {
  return getWordPatternAtBufferPosition(editor, point, {
    wordRegex: editor.getLastCursor().subwordRegExp(),
    boundarizeForWord: false,
  })
}

// Return options used for getWordBufferRangeAtBufferPosition
function buildWordPatternByCursor(cursor, wordRegex) {
  const nonWordCharacters = getNonWordCharactersForCursor(cursor)
  if (wordRegex == null) wordRegex = new RegExp(`^[\t ]*$|[^\\s${_.escapeRegExp(nonWordCharacters)}]+`)
  return {wordRegex, nonWordCharacters}
}

function getBeginningOfWordBufferPosition(editor, point, {wordRegex} = {}) {
  let found

  const scanRange = [[point.row, 0], point]
  editor.backwardsScanInBufferRange(wordRegex, scanRange, ({range, matchText, stop}) => {
    if (matchText === "" && range.start.column !== 0) return

    if (range.start.isLessThan(point)) {
      if (range.end.isGreaterThanOrEqual(point)) {
        found = range.start
      }
      stop()
    }
  })
  return found || point
}

function getEndOfWordBufferPosition(editor, point, {wordRegex} = {}) {
  let found

  const scanRange = [point, [point.row, Infinity]]
  editor.scanInBufferRange(wordRegex, scanRange, function({range, matchText, stop}) {
    if (matchText === "" && range.start.column !== 0) return

    if (range.end.isGreaterThan(point)) {
      if (range.start.isLessThanOrEqual(point)) {
        found = range.end
      }
      stop()
    }
  })
  return found || point
}

function getWordBufferRangeAtBufferPosition(editor, position, options = {}) {
  const end = getEndOfWordBufferPosition(editor, position, options)
  const start = getBeginningOfWordBufferPosition(editor, end, options)
  return new Range(start, end)
}

// When range is linewise range, range end have column 0 of NEXT row.
// This function adjust range.end to EOL of selected line.
function shrinkRangeEndToBeforeNewLine(range) {
  return range.end.column === 0
    ? new Range(range.start, [limitNumber(range.end.row - 1, {min: range.start.row}), Infinity])
    : range
}

function collectRangeInBufferRow(editor, row, regex) {
  const ranges = []
  const scanRange = editor.bufferRangeForBufferRow(row)
  editor.scanInBufferRange(regex, scanRange, ({range}) => ranges.push(range))
  return ranges
}

function findRangeInBufferRow(editor, regex, row, {direction} = {}) {
  let range
  const scanRange = editor.bufferRangeForBufferRow(row)
  const scanFunctionName = direction === "backward" ? "backwardsScanInBufferRange" : "scanInBufferRange"
  editor[scanFunctionName](regex, scanRange, event => (range = event.range))
  return range
}

function getLargestFoldRangeContainsBufferRow(editor, row) {
  const markers = editor.displayLayer.foldsMarkerLayer.findMarkers({intersectsRow: row})
  if (markers && markers.length) {
    return markers
      .map(marker => marker.getRange())
      .reduce((range, largest) => (range.start.isLessThan(largest.start) ? range : largest))
  }
}

// take bufferPosition
function translatePointAndClip(editor, point, direction) {
  point = Point.fromObject(point)

  let dontClip = false
  switch (direction) {
    case "forward":
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

    case "backward":
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

function getRangeByTranslatePointAndClip(editor, range, which, direction) {
  const newPoint = translatePointAndClip(editor, range[which], direction)
  switch (which) {
    case "start":
      return new Range(newPoint, range.end)
    case "end":
      return new Range(range.start, newPoint)
  }
}

function getPackage(name) {
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

function searchByProjectFind(editor, text) {
  atom.commands.dispatch(editor.element, "project-find:show")
  getPackage("find-and-replace").then(pkg => {
    const {projectFindView} = pkg.mainModule
    if (projectFindView) {
      projectFindView.findEditor.setText(text)
      projectFindView.confirm()
    }
  })
}

function limitNumber(number, {max, min} = {}) {
  if (max != null) number = Math.min(number, max)
  if (min != null) number = Math.max(number, min)
  return number
}

function findRangeContainsPoint(ranges, point) {
  return ranges.find(range => range.containsPoint(point))
}

const negateFunction = fn => (...args) => !fn(...args)

const isEmpty = target => target.isEmpty()
const isNotEmpty = negateFunction(isEmpty)

const isSingleLineRange = range => range.isSingleLine()
const isNotSingleLineRange = negateFunction(isSingleLineRange)

const isLeadingWhiteSpaceRange = (editor, range) => /^[\t ]*$/.test(editor.getTextInBufferRange(range))
const isNotLeadingWhiteSpaceRange = negateFunction(isLeadingWhiteSpaceRange)

function isEscapedCharRange(editor, range) {
  range = Range.fromObject(range)
  const chars = getLeftCharacterForBufferPosition(editor, range.start, 2)
  return chars.endsWith("\\") && !chars.endsWith("\\\\")
}

function insertTextAtBufferPosition(editor, point, text) {
  return editor.setTextInBufferRange([point, point], text)
}

function ensureEndsWithNewLineForBufferRow(editor, row) {
  if (!isEndsWithNewLineForBufferRow(editor, row)) {
    const eol = getEndOfLineForBufferRow(editor, row)
    insertTextAtBufferPosition(editor, eol, "\n")
  }
}

function toggleCaseForCharacter(char) {
  const charLower = char.toLowerCase()
  return charLower === char ? char.toUpperCase() : charLower
}

function splitTextByNewLine(text) {
  return text.endsWith("\n") ? text.trimRight().split(/\r?\n/g) : text.split(/\r?\n/g)
}

function replaceDecorationClassBy(fn, decoration) {
  const props = decoration.getProperties()
  decoration.setProperties(_.defaults({class: fn(props.class)}, props))
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
function humanizeBufferRange(editor, range) {
  range = range.copy()
  if (isSingleLineRange(range) || isLinewiseRange(range)) return range

  if (pointIsAtEndOfLine(editor, range.start)) range.start = range.start.traverse([1, 0])
  if (pointIsAtEndOfLine(editor, range.end)) range.end = range.end.traverse([1, 0])
  return range
}

// Expand range to white space
//  1. Expand to forward direction, if suceed return new range.
//  2. Expand to backward direction, if succeed return new range.
//  3. When faild to expand either direction, return original range.
function expandRangeToWhiteSpaces(editor, range) {
  const {start, end} = range

  let newEnd
  const rangeForward = [end, getEndOfLineForBufferRow(editor, end.row)]
  editor.scanInBufferRange(/\S/, rangeForward, ({range}) => {
    if (range.start.isGreaterThan(end)) newEnd = range.start
  })
  if (newEnd) return new Range(start, newEnd)

  let newStart
  const rangeBackward = [[start.row, 0], range.start]
  editor.backwardsScanInBufferRange(/\S/, rangeBackward, ({range}) => {
    if (range.end.isLessThan(start)) newStart = range.end
  })
  if (newStart) return new Range(newStart, end)

  return range // fallback
}

// Split then mutate by fn() then join again with keep original separator unchanged.
//
// 0. Trim leading and trainling white spaces and remember
// 1. Split text with given pattern and remember original separators.
// 2. Change order by callback
// 3. Join with original spearator and concat with remembered leading and trainling white spaces.
//
function splitAndJoinBy(text, regex, fn) {
  const start = text.search(/\S/)
  const end = text.search(/\s*$/)
  const leadingSpaces = start !== -1 ? text.slice(0, start) : ""
  const trailingSpaces = end !== -1 ? text.slice(end) : ""
  text = text.slice(start, end)

  // e.g.
  // When text = "a, b, c", regex = /,?\s+/
  //   items = ['a', 'b', 'c'], spearators = [', ', ', ']
  // When text = "a b\n c", regex = /,?\s+/
  //   items = ['a', 'b', 'c'], spearators = [' ', '\n ']
  const items = []
  const separators = []
  const regexp = new RegExp(`(${regex.source})`, regex.ignoreCase ? "gi" : "g")
  text.split(regexp).forEach((segment, i) => {
    if (i % 2 === 0) items.push(segment)
    else separators.push(segment)
  })
  separators.push("")
  const newItems = fn(items)
  const newText = _.zip(newItems, separators).reduce(([item, separator], text) => text + item + separator, "")
  return leadingSpaces + newText + trailingSpaces
}

function splitArguments(text, joinSpaceSeparatedToken = true) {
  const separatorChars = "\t, \r\n"
  const quoteChars = "\"'`"
  const closeCharToOpenChar = {
    ")": "(",
    "}": "{",
    "]": "[",
  }
  const closePairChars = _.keys(closeCharToOpenChar).join("")
  const openPairChars = _.values(closeCharToOpenChar).join("")
  const escapeChar = "\\"

  let pendingToken = "",
    inQuote = false,
    isEscaped = false,
    allTokens = [],
    currentSection = null

  // Parse text as list of tokens which is commma separated or white space separated.
  // e.g. 'a, fun1(b, c), d' => ['a', 'fun1(b, c), 'd']
  // Not perfect. but far better than simple string split by regex pattern.
  // let allTokens = []
  // let currentSection

  function settlePending() {
    if (pendingToken) {
      allTokens.push({text: pendingToken, type: currentSection})
      pendingToken = ""
    }
  }

  function changeSection(newSection) {
    if (currentSection !== newSection) {
      if (currentSection) settlePending()
      currentSection = newSection
    }
  }

  const pairStack = []
  for (const char of text) {
    if (pairStack.length === 0 && separatorChars.includes(char)) {
      changeSection("separator")
    } else {
      changeSection("argument")
      if (isEscaped) {
        isEscaped = false
      } else if (char === escapeChar) {
        isEscaped = true
      } else if (inQuote) {
        if (quoteChars.includes(char) && _.last(pairStack) === char) {
          inQuote = false
          pairStack.pop()
        }
      } else if (quoteChars.includes(char)) {
        inQuote = true
        pairStack.push(char)
      } else if (openPairChars.includes(char)) {
        pairStack.push(char)
      } else if (closePairChars.includes(char)) {
        if (_.last(pairStack) === closeCharToOpenChar[char]) pairStack.pop()
      }
    }
    pendingToken += char
  }
  settlePending()

  if (joinSpaceSeparatedToken && allTokens.some(({type, text}) => type === "separator" && text.includes(","))) {
    // When some separator contains `,` treat white-space separator as just part of token.
    // So we move white-space only sparator into tokens by joining mis-separatoed tokens.
    const newAllTokens = []
    while (allTokens.length) {
      const token = allTokens.shift()
      switch (token.type) {
        case "argument":
          newAllTokens.push(token)
          break
        case "separator":
          if (token.text.includes(",")) {
            newAllTokens.push(token)
          } else {
            // 1. Concatnate white-space-separator and next-argument
            // 2. Then join into latest argument
            const lastArg = newAllTokens.length ? newAllTokens.pop() : {text: "", type: "argument"}
            lastArg.text += token.text + (allTokens.length ? allTokens.shift().text : "") // concat with next-token
            newAllTokens.push(lastArg)
          }
          break
      }
    }
    allTokens = newAllTokens
  }
  return allTokens
}

function scanEditorInDirection(editor, direction, regex, {allowNextLine, from, scanRange}, fn) {
  if (!from && !scanRange) throw new Error("You must 'from' or 'scanRange' options")
  if (scanRange || allowNextLine == null) allowNextLine = true

  if (from) from = Point.fromObject(from)
  let scanFunction
  switch (direction) {
    case "forward":
      if (!scanRange) scanRange = new Range(from, getVimEofBufferPosition(editor))
      scanFunction = "scanInBufferRange"
      break
    case "backward":
      if (!scanRange) scanRange = new Range([0, 0], from)
      scanFunction = "backwardsScanInBufferRange"
      break
  }

  editor[scanFunction](regex, scanRange, event => {
    if (!allowNextLine && event.range.start.row !== from.row) event.stop()
    else fn(event)
  })
}

function adjustIndentWithKeepingLayout(editor, range) {
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

  for (const row of getRange(range.start.row, range.end.row, false)) {
    if (isEmptyRow(editor, row)) continue
    const actualLevel = getIndentLevelForBufferRow(editor, row)
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
function rangeContainsPointWithEndExclusive(range, point) {
  range.start.isLessThanOrEqual(point) && range.end.isGreaterThan(point)
}

function traverseTextFromPoint(point, text) {
  return point.traverse(getTraversalForText(text))
}

function getTraversalForText(text) {
  let row = 0,
    column = 0
  for (const char of text) {
    if (char === "\n") {
      row++
      column = 0
    } else {
      column++
    }
  }
  return new Point(row, column)
}

// Return endRow of fold if row was folded or just return passed row.
function getFoldEndRowForRow(editor, row) {
  return editor.isFoldedAtBufferRow(row) ? getLargestFoldRangeContainsBufferRow(editor, row).end.row : row
}

function getRange(start, end, inclusive = true) {
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

function unindent(strings, ...values) {
  let result = ""
  for (const rawString of strings.raw) {
    result += rawString.replace(/\\{2}/g, "\\") + (values.length ? values.shift() : "")
  }

  const lines = result.split(/\n/)
  lines.shift()
  lines.pop()

  const minIndent = lines.reduce((i, l) => Math.min(l.match(/ */)[0].length || i, i), Infinity)
  return lines.map(line => line.slice(minIndent)).join("\n")
}

function removeIndent(str) {
  const lines = str.split(/\n/)
  lines.shift()
  lines.pop()

  const minIndent = lines.reduce((i, l) => Math.min(l.match(/ */)[0].length || i, i), Infinity)
  return lines.map(line => line.slice(minIndent)).join("\n")
}

module.exports = {
  assertWithException,
  getAncestors,
  getKeyBindingForCommand,
  debug,
  saveEditorState,
  isLinewiseRange,
  sortRanges,
  getIndex,
  getVisibleBufferRange,
  getVisibleEditors,
  pointIsAtEndOfLine,
  pointIsOnWhiteSpace,
  pointIsAtEndOfLineAtNonEmptyRow,
  pointIsAtVimEndOfFile,
  getVimEofBufferPosition,
  getVimEofScreenPosition,
  getVimLastBufferRow,
  getVimLastScreenRow,
  setBufferRow,
  setBufferColumn,
  moveCursorLeft,
  moveCursorRight,
  moveCursorUpScreen,
  moveCursorDownScreen,
  getEndOfLineForBufferRow,
  getFirstVisibleScreenRow,
  getLastVisibleScreenRow,
  getValidVimBufferRow,
  getValidVimScreenRow,
  moveCursorToFirstCharacterAtRow,
  getLineTextToBufferPosition,
  getIndentLevelForBufferRow,
  getTextInScreenRange,
  moveCursorToNextNonWhitespace,
  isEmptyRow,
  getCodeFoldRowRanges,
  getCodeFoldRowRangesContainesForRow,
  getFoldRowRangesContainedByFoldStartsAtRow,
  getFoldRowRanges,
  getFoldRangesWithIndent,
  getFoldInfoByKind,
  getBufferRangeForRowRange,
  trimRange,
  getFirstCharacterPositionForBufferRow,
  isIncludeFunctionScopeForRow,
  detectScopeStartPositionForScope,
  getBufferRows,
  smartScrollToBufferPosition,
  matchScopes,
  isSingleLineText,
  getWordBufferRangeAtBufferPosition,
  getWordBufferRangeAndKindAtBufferPosition,
  getWordPatternAtBufferPosition,
  getSubwordPatternAtBufferPosition,
  getNonWordCharactersForCursor,
  shrinkRangeEndToBeforeNewLine,
  collectRangeInBufferRow,
  findRangeInBufferRow,
  getLargestFoldRangeContainsBufferRow,
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
  humanizeBufferRange,
  expandRangeToWhiteSpaces,
  splitAndJoinBy,
  splitArguments,
  scanEditorInDirection,
  adjustIndentWithKeepingLayout,
  rangeContainsPointWithEndExclusive,
  traverseTextFromPoint,
  getFoldEndRowForRow,
  getRange,
  unindent,
  removeIndent,
}
