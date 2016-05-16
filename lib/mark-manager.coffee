{Range} = require 'atom'

MARKS = /// (
  ?: [a-z]
   | [\[\]`.^(){}<>]
) ///

class MarkManager
  marks: null

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    @marks = {}

  isValid: (name) ->
    MARKS.test(name)

  get: (name) ->
    return unless @isValid(name)
    @marks[name]?.getStartBufferPosition()

  # Return range between marks
  getRange: (startMark, endMark) ->
    start = @get(startMark)
    end = @get(endMark)
    if start? and end?
      new Range(start, end)

  setRange: (startMark, endMark, range) ->
    {start, end} = Range.fromObject(range)
    @set(startMark, start)
    @set(endMark, end)

  # [FIXME] Need to support Global mark with capital name [A-Z]
  set: (name, point) ->
    return unless @isValid(name)

    if @marks[name]
      marker = @marks[name]
      marker.destroy()
      @marks[name] = null

    @marks[name] = @editor.markBufferPosition(@editor.clipBufferPosition(point))
    @decorate(name)

  decorate: (name) ->
    marker = @marks[name]
    @editor.decorateMarker(marker, type: "line-number", class: "vim-mode-plus-marker-gutter")
    @editor.decorateMarker(marker, type: "line-number", class: "vim-mode-plus-marker-gutter-" + name)

module.exports = MarkManager
