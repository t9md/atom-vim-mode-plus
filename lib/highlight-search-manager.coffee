{CompositeDisposable} = require 'atom'
{scanEditor, matchScopes} = require './utils'

decorationOptions =
  type: 'highlight'
  class: 'vim-mode-plus-highlight-search'

# General purpose utility class to make Atom's marker management easier.
module.exports =
class HighlightSearchManager
  constructor: (@vimState) ->
    {@editor, @editorElement, @globalState} = @vimState
    @disposables = new CompositeDisposable
    @markerLayer = @editor.addMarkerLayer()

    @disposables.add @vimState.onDidDestroy(@destroy.bind(this))
    @decorationLayer = @editor.decorateMarkerLayer(@markerLayer, decorationOptions)

    # Refresh highlight based on globalState.highlightSearchPattern changes.
    # -------------------------
    @disposables.add @globalState.onDidChange ({name, newValue}) =>
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
    @markerLayer.clear()

  refresh: ->
    @clearMarkers()

    return unless @vimState.getConfig('highlightSearch')
    return unless @vimState.isVisible()
    return unless pattern = @globalState.get('highlightSearchPattern')
    return if matchScopes(@editorElement, @vimState.getConfig('highlightSearchExcludeScopes'))

    for range in scanEditor(@editor, pattern)
      @markerLayer.markBufferRange(range, invalidate: 'inside')
