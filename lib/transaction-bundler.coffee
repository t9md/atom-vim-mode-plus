{Range, Point} = require 'atom'
distanceForRange = ({start, end}) ->
  row = end.row - start.row
  column = end.column - start.column
  new Point(row, column)

class TransactionBundler
  constructor: (@changes, @editor) ->

  buildInsertText: ->
    finalRange = null
    for change in @changes when change.newRange?
      {oldRange, oldText, newRange, newText} = change
      unless finalRange?
        finalRange = newRange.copy()  if newText.length
        continue
      # shrink
      if oldText.length and finalRange.containsRange(oldRange)
        amount = oldRange
        diff = distanceForRange(amount)
        diff.column = 0 unless (amount.end.row is finalRange.end.row)
        finalRange.end = finalRange.end.translate(diff.negate())
      # extend
      if newText.length and finalRange.containsPoint(newRange.start)
        amount = newRange
        diff = distanceForRange(amount)
        diff.column = 0 unless (amount.start.row is finalRange.end.row)
        finalRange.end = finalRange.end.translate(diff)

    if finalRange?
      @editor.getTextInBufferRange finalRange
    else
      ""

  # shrink range
  subtractRange: (target, amount) ->
    amount = oldRange
    diff = distanceForRange(amount)
    diff.column = 0 unless (amount.end.row is target.end.row)
    target.translate([0, 0], diff.negate())

  # expand range
  addRange: (target, amount) ->
    diff = distanceForRange(amount)
    diff.column = 0 unless (amount.start.row is target.end.row)
    target.translate([0, 0], diff)

module.exports = TransactionBundler
