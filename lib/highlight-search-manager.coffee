{CompositeDisposable} = require 'atom'

# General purpose utility class to make Atom's marker management easier.
module.exports =
class HighlightSearchManager
  constructor: (@vimState) ->
    {@editor, @editorElement, @globalState} = @vimState
    @disposables = new CompositeDisposable

    @disposables.add @vimState.onDidDestroy(@destroy)
    @disposables.add @editor.onDidStopChanging => @refresh()

    @markerLayer = @editor.addMarkerLayer()
    decorationOptions = {type: 'highlight', class: 'vim-mode-plus-highlight-search'}
    @decorationLayer = @editor.decorateMarkerLayer(@markerLayer, decorationOptions)

  destroy: =>
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
    return if @vimState.utils.matchScopes(@editorElement, @vimState.getConfig('highlightSearchExcludeScopes'))

    for range in @vimState.utils.scanEditor(@editor, pattern) when not range.isEmpty()
      @markerLayer.markBufferRange(range, invalidate: 'inside')
