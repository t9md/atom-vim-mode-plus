{CompositeDisposable} = require 'atom'
{scanEditor, matchScopes} = require './utils'
settings = require './settings'

# General purpose utility class to make Atom's marker management easier.
module.exports =
class HighlightSearchManager
  patterns: null

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    @disposables = new CompositeDisposable
    @disposables.add @vimState.onDidDestroy(@destroy.bind(this))
    @patterns = []

    @markerLayer = @editor.addMarkerLayer()
    options =
      type: 'highlight'
      invalidate: 'inside'
      class: 'vim-mode-plus-highlight-search'
    @decorationLayer = @editor.decorateMarkerLayer(@markerLayer, options)

  destroy: ->
    @decorationLayer.destroy()
    @disposables.dispose()
    @markerLayer.destroy()

  # Markers
  # -------------------------
  hasMarkers: ->
    @markerLayer.getMarkerCount() > 0

  getMarkers: ->
    @markerLayer.getMarkers()

  clearMarkers: ->
    marker.destroy() for marker in @markerLayer.getMarkers()

  refresh: ->
    @clearMarkers()
    if matchScopes(@editorElement, settings.get('highlightSearchExcludeScopes'))
      return

    unless settings.get('highlightSearch') and @vimState.main.highlightSearchPattern?
      return

    for range in scanEditor(@editor, @vimState.main.highlightSearchPattern)
      @markerLayer.markBufferRange(range)
