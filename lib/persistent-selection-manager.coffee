_ = require 'underscore-plus'
{CompositeDisposable} = require 'atom'

decorationOptions = {type: 'highlight', class: 'vim-mode-plus-persistent-selection'}

module.exports =
class PersistentSelectionManager
  patterns: null

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    @disposables = new CompositeDisposable
    @disposables.add @vimState.onDidDestroy(@destroy.bind(this))

    @markerLayer = @editor.addMarkerLayer()
    @decorationLayer = @editor.decorateMarkerLayer(@markerLayer, decorationOptions)

    # Update css on every marker update.
    @markerLayer.onDidUpdate =>
      @editorElement.classList.toggle("has-persistent-selection", @hasMarkers())

  destroy: ->
    @decorationLayer.destroy()
    @disposables.dispose()
    @markerLayer.destroy()

  select: ->
    for range in @getMarkerBufferRanges()
      @editor.addSelectionForBufferRange(range)
    @clear()

  setSelectedBufferRanges: ->
    @editor.setSelectedBufferRanges(@getMarkerBufferRanges())
    @clear()

  clear: ->
    @clearMarkers()

  isEmpty: ->
    @markerLayer.getMarkerCount() is 0

  # Markers
  # -------------------------
  markBufferRange: (range) ->
    @markerLayer.markBufferRange(range)

  hasMarkers: ->
    @markerLayer.getMarkerCount() > 0

  getMarkers: ->
    @markerLayer.getMarkers()

  getMarkerCount: ->
    @markerLayer.getMarkerCount()

  clearMarkers: ->
    @markerLayer.clear()

  getMarkerBufferRanges: ->
    @markerLayer.getMarkers().map (marker) ->
      marker.getBufferRange()

  getMarkerAtPoint: (point) ->
    @markerLayer.findMarkers(containsBufferPosition: point)[0]
