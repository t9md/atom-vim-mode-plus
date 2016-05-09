{getVimState, dispatch, TextData, getView} = require './spec-helper'
settings = require '../lib/settings'
globalState = require '../lib/global-state'

describe "Range Marker", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, _vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = _vim

  afterEach ->
    vimState.resetNormalMode()

  describe "MarkRange operator", ->
    textForMarker = (marker) ->
      editor.getTextInBufferRange(marker.getBufferRange())

    ensureRangeMarker = (options) ->
      markers = vimState.getRangeMarkers()
      if options.length?
        expect(markers).toHaveLength(options.length)

      if options.text?
        text = markers.map (marker) -> textForMarker(marker)
        expect(text).toEqual(options.text)

      if options.mode?
        ensure {mode: options.mode}

    beforeEach ->
      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          'g m': 'vim-mode-plus:mark-range'
      set
        text: """
        ooo xxx ooo
        xxx ooo xxx

        ooo xxx ooo
        xxx ooo xxx

        ooo xxx ooo
        xxx ooo xxx\n
        """
        cursor: [0, 0]
      expect(vimState.hasRangeMarkers()).toBe(false)

    describe "basic behavior", ->
      it "MarkRange add range marker", ->
        keystroke('g m i w')
        ensureRangeMarker length: 1, text: ['ooo']
        keystroke('j .')
        ensureRangeMarker length: 2, text: ['ooo', 'xxx']
      it "marked range can use as target of operator by `i r`", ->
        keystroke('g m i w j . 2 j g m i p') # Mark 2 inner-word and 1 inner-paragraph
        ensureRangeMarker length: 3, text: ['ooo', 'xxx', "ooo xxx ooo\nxxx ooo xxx\n"]
        ensure 'g U i r',
          text: """
          OOO xxx ooo
          XXX ooo xxx

          OOO XXX OOO
          XXX OOO XXX

          ooo xxx ooo
          xxx ooo xxx\n
          """

    describe "select-all-in-range-marker", ->
      it "select all instance of cursor word only within marked range", ->
        keystroke('g m i p } } j .') # Mark 2 inner-word and 1 inner-paragraph
        paragraphText = "ooo xxx ooo\nxxx ooo xxx\n"
        ensureRangeMarker length: 2, text: [paragraphText, paragraphText]
        dispatch(editorElement, 'vim-mode-plus:select-all-in-range-marker')
        expect(editor.getSelections()).toHaveLength(6)
        keystroke 'c'
        editor.insertText '!!!'
        ensure 'g U i r',
          text: """
          !!! xxx !!!
          xxx !!! xxx

          ooo xxx ooo
          xxx ooo xxx

          !!! xxx !!!
          xxx !!! xxx\n
          """

    describe "clearRangeMarkers command", ->
      it "clear rangeMarkers", ->
        keystroke('g m i w')
        ensureRangeMarker length: 1, text: ['ooo']
        dispatch(editorElement, 'vim-mode-plus:clear-range-marker')
        expect(vimState.hasRangeMarkers()).toBe(false)

    describe "clearRangeMarkerOnResetNormalMode", ->
      describe "default setting", ->
        it "it won't clear rangeMarker", ->
          keystroke('g m i w')
          ensureRangeMarker length: 1, text: ['ooo']
          dispatch(editorElement, 'vim-mode-plus:reset-normal-mode')
          ensureRangeMarker length: 1, text: ['ooo']

      describe "when enabled", ->
        it "it clear rangeMarker on reset-normal-mode", ->
          settings.set('clearRangeMarkerOnResetNormalMode', true)
          keystroke('g m i w')
          ensureRangeMarker length: 1, text: ['ooo']
          dispatch(editorElement, 'vim-mode-plus:reset-normal-mode')
          expect(vimState.hasRangeMarkers()).toBe(false)
