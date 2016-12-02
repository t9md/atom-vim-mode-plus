{getVimState, dispatch, TextData, getView} = require './spec-helper'
settings = require '../lib/settings'

describe "Persistent Selection", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, _vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = _vim
    runs ->
      jasmine.attachToDOM(editorElement)

  afterEach ->
    vimState.resetNormalMode()

  describe "CreatePersistentSelection operator", ->
    textForMarker = (marker) ->
      editor.getTextInBufferRange(marker.getBufferRange())

    ensurePersistentSelection = (options) ->
      markers = vimState.persistentSelection.getMarkers()
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
          'g m': 'vim-mode-plus:create-persistent-selection'
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
      expect(vimState.persistentSelection.hasMarkers()).toBe(false)

    describe "basic behavior", ->
      describe "create-persistent-selection", ->
        it "create-persistent-selection create range marker", ->
          keystroke('g m i w')
          ensurePersistentSelection length: 1, text: ['ooo']
          keystroke('j .')
          ensurePersistentSelection length: 2, text: ['ooo', 'xxx']
      describe "[No behavior diff currently] inner-persistent-selection and a-persistent-selection", ->
        it "apply operator to across all persistent-selections", ->
          keystroke('g m i w j . 2 j g m i p') # Mark 2 inner-word and 1 inner-paragraph
          ensurePersistentSelection length: 3, text: ['ooo', 'xxx', "ooo xxx ooo\nxxx ooo xxx\n"]
          ensure 'g U a r',
            text: """
            OOO xxx ooo
            XXX ooo xxx

            OOO XXX OOO
            XXX OOO XXX

            ooo xxx ooo
            xxx ooo xxx\n
            """

    describe "select-occurrence-in-a-persistent-selection", ->
      [update] = []
      beforeEach ->
        vimState.persistentSelection.markerLayer.onDidUpdate(update = jasmine.createSpy())

      it "select all instance of cursor word only within marked range", ->
        runs ->
          keystroke('g m i p } } j .') # Mark 2 inner-word and 1 inner-paragraph
          paragraphText = "ooo xxx ooo\nxxx ooo xxx\n"
          ensurePersistentSelection length: 2, text: [paragraphText, paragraphText]
        waitsFor ->
          update.callCount is 1
        runs ->
          ensure 'g cmd-d',
            selectedText: ['ooo', 'ooo', 'ooo', 'ooo', 'ooo', 'ooo' ]
          keystroke 'c'
          editor.insertText '!!!'
          ensure
            text: """
            !!! xxx !!!
            xxx !!! xxx

            ooo xxx ooo
            xxx ooo xxx

            !!! xxx !!!
            xxx !!! xxx\n
            """

    describe "clearPersistentSelections command", ->
      it "clear persistentSelections", ->
        keystroke('g m i w')
        ensurePersistentSelection length: 1, text: ['ooo']
        dispatch(editorElement, 'vim-mode-plus:clear-persistent-selection')
        expect(vimState.persistentSelection.hasMarkers()).toBe(false)

    describe "clearPersistentSelectionOnResetNormalMode", ->
      describe "default setting", ->
        it "it won't clear persistentSelection", ->
          keystroke('g m i w')
          ensurePersistentSelection length: 1, text: ['ooo']
          dispatch(editorElement, 'vim-mode-plus:reset-normal-mode')
          ensurePersistentSelection length: 1, text: ['ooo']

      describe "when enabled", ->
        it "it clear persistentSelection on reset-normal-mode", ->
          settings.set('clearPersistentSelectionOnResetNormalMode', true)
          keystroke('g m i w')
          ensurePersistentSelection length: 1, text: ['ooo']
          dispatch(editorElement, 'vim-mode-plus:reset-normal-mode')
          expect(vimState.persistentSelection.hasMarkers()).toBe(false)
