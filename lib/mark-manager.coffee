{Range, Point, CompositeDisposable} = require 'atom'

MARKS = /// (
  ?: [a-z]
   | [\[\]`'.^(){}<>]
) ///

class MarkManager
  marks: null

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    @marks = {}

    @subscriptions = new CompositeDisposable
    @subscriptions.add @vimState.onDidDestroy(@destroy.bind(this))

  destroy: ->
    @subscriptions.dispose()

  isValid: (name) ->
    MARKS.test(name)

  get: (name) ->
    return unless @isValid(name)
    point = @marks[name]?.getStartBufferPosition()
    if name in "`'"
      point ? Point.ZERO
    else
      point

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
    bufferPosition = @editor.clipBufferPosition(point)
    @marks[name] = @editor.markBufferPosition(bufferPosition)
    event = {name, bufferPosition, @editor}
    @vimState.emitter.emit('did-set-mark', event)

module.exports = MarkManager
