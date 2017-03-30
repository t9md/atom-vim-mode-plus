{Point, CompositeDisposable} = require 'atom'

MARKS = /// (
  ?: [a-z]
   | [\[\]`'.^(){}<>]
) ///

class MarkManager
  marks: null

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    @disposables = new CompositeDisposable
    @disposables.add @vimState.onDidDestroy(@destroy.bind(this))

    @marks = {}
    @markerLayer = @editor.addMarkerLayer()

  destroy: ->
    @disposables.dispose()
    @markerLayer.destroy()
    @marks = null

  isValid: (name) ->
    MARKS.test(name)

  get: (name) ->
    return unless @isValid(name)
    point = @marks[name]?.getStartBufferPosition()
    if name in "`'"
      point ? Point.ZERO
    else
      point

  # [FIXME] Need to support Global mark with capital name [A-Z]
  set: (name, point) ->
    return unless @isValid(name)
    if marker = @marks[name]
      marker.destroy()
    bufferPosition = @editor.clipBufferPosition(point)
    @marks[name] = @markerLayer.markBufferPosition(bufferPosition, invalidate: 'never')
    @vimState.emitter.emit('did-set-mark', {name, bufferPosition, @editor})

module.exports = MarkManager
