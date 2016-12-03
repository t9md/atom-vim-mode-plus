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

    decorationOptions =
      type: 'highlight'
      class: 'vim-mode-plus-highlight-search'
    @decorationLayer = @editor.decorateMarkerLayer(@markerLayer, decorationOptions)

    @disposables.add @vimState.onDidDestroy(@destroy.bind(this))

    # Refresh highlight based on globalState.highlightSearchPattern changes.
    # -------------------------
    @disposables = @globalState.onDidChange ({name, newValue}) =>
      if name is 'highlightSearchPattern'
        if newValue
          @refresh()
        else
          @clearMarkers()

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

    return unless settings.get('highlightSearch')
    return unless @vimState.isVisible()
    return unless pattern = @globalState.get('highlightSearchPattern')
    return if matchScopes(@editorElement, settings.get('highlightSearchExcludeScopes'))

    for range in scanEditor(@editor, pattern)
      @markerLayer.markBufferRange(range, invalidate: 'inside')
