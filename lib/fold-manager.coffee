{CompositeDisposable} = require 'atom'

# A manager for memorizing fold level.
module.exports =
class FoldManager
  constructor: (@vimState) ->
    {@editor} = @vimState
    {@buffer, @languageMode} = @editor

    @disposables = new CompositeDisposable
    @disposables.add @vimState.onDidDestroy(@destroy.bind(this))

    @foldLevel = @getFoldNestMax()

  destroy: ->
    @disposables.dispose()

  getFoldNestMax: ->
    @vimState.getConfig('maximumNestingOfFolds')

  unfoldAll: ->
    @editor.displayLayer.destroyAllFolds()
    @foldLevel = @getFoldNestMax()

  foldAll: ->
    if @getFoldNestMax() > 0
      @editor.foldAll()
    @foldLevel = 0

  # Internal use
  foldAllAtIndentLevel: (indentLevel) ->
    @editor.unfoldAll()
    if indentLevel >= @getFoldNestMax()
      @foldLevel = @getFoldNestMax()
      return

    foldedRowRanges = {}
    folded = false

    maxBufferIndentLevel = 0

    for currentRow in [0..@buffer.getLastRow()] by 1
      rowRange = [startRow, endRow] = @languageMode.rowRangeForFoldAtBufferRow(currentRow) ? []
      continue unless startRow?
      continue if foldedRowRanges[rowRange]

      # assumption: startRow will always be the min indent level for the entire range
      currentIndentLevel = @editor.indentationForBufferRow(startRow + 1)
      if currentIndentLevel >= indentLevel + 1
        @editor.foldBufferRowRange(startRow, endRow)
        foldedRowRanges[rowRange] = true
        @foldLevel = indentLevel
        folded = true

      # Store maximum of indent level in current buffer
      maxBufferIndentLevel = Math.max(maxBufferIndentLevel, currentIndentLevel)

    # Set foldLevel to maximum indent level
    if not folded
      @foldLevel = maxBufferIndentLevel
      # automatically fold one level if not folded
      if indentLevel is @getFoldNestMax() - 1
        @foldAllAtIndentLevel(Math.max(@foldLevel - 1, 0))

  unfoldAllByOneIndentLevel: ->
    @foldAllAtIndentLevel(@foldLevel + 1)

  foldAllByOneIndentLevel: ->
    @foldAllAtIndentLevel(Math.max(@foldLevel - 1, 0))
