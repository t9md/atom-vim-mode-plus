{CompositeDisposable} = require 'atom'
{scanEditor, matchScopes} = require './utils'
settings = require './settings'

# General purpose utility class to make Atom's marker management easier.
module.exports =
class HighlightSearchManager
  constructor: (@vimState) ->
    {@editor, @editorElement, @globalState} = @vimState
    @disposables = new CompositeDisposable
    
    @markerLayer = @editor.addMarkerLayer()
    options =
      type: 'highlight'
      invalidate: 'inside'
      class: 'vim-mode-plus-highlight-search'
    @decorationLayer = @editor.decorateMarkerLayer(@markerLayer, options)

    @disposables.add @vimState.onDidDestroy(@destroy.bind(this))

    # Refresh highlight based on globalState.highlightSearchPattern changes.
    # -------------------------
    @disposables = @globalState.onDidChange ({name, newValue}) =>
      @refresh() if name is 'highlightSearchPattern'

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

    unless settings.get('highlightSearch')
      return

    if pattern = @globalState.get('highlightSearchPattern')
      for range in scanEditor(@editor, pattern)
        @markerLayer.markBufferRange(range)
