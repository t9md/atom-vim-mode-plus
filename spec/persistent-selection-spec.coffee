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

  describe "CreatePersistentSelection operator", ->
    textForMarker = (marker) ->
      editor.getTextInBufferRange(marker.getBufferRange())

    ensurePersistentSelection = (args...) ->
      switch args.length
        when 1 then [options] = args
        when 2 then [_keystroke, options] = args

      if _keystroke?
        keystroke(_keystroke)

      markers = vimState.persistentSelection.getMarkers()
      if options.length?
        expect(markers).toHaveLength(options.length)

      if options.text?
        text = markers.map (marker) -> textForMarker(marker)
        expect(text).toEqual(options.text)

      if options.mode?
        ensure mode: options.mode

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
        it "create-persistent-selection", ->
          ensurePersistentSelection 'g m i w',
            length: 1
            text: ['ooo']
          ensurePersistentSelection 'j .',
            length: 2
            text: ['ooo', 'xxx']
        it "create-persistent-selection forr current selection and repeatable by .", ->
          ensurePersistentSelection 'v enter',
            length: 1
            text: ['o']
          ensurePersistentSelection 'j .',
            length: 2
            text: ['o', 'x']

      describe "[No behavior diff currently] inner-persistent-selection and a-persistent-selection", ->
        it "apply operator to across all persistent-selections", ->
          ensurePersistentSelection 'g m i w j . 2 j g m i p',  # Mark 2 inner-word and 1 inner-paragraph
            length: 3
            text: ['ooo', 'xxx', "ooo xxx ooo\nxxx ooo xxx\n"]

          ensure 'g U a r',
            text: """
            OOO xxx ooo
            XXX ooo xxx

            OOO XXX OOO
            XXX OOO XXX

            ooo xxx ooo
            xxx ooo xxx\n
            """

    describe "practical scenario", ->
      describe "persistent-selection is treated in same way as real selection", ->
        beforeEach ->
          set
            textC: """
            |0 ==========
            1 ==========
            2 ==========
            3 ==========
            4 ==========
            5 ==========
            """

          ensurePersistentSelection 'V j enter',
            text: ['0 ==========\n1 ==========\n']

          ensure '2 j V j',
            selectedText: ['3 ==========\n4 ==========\n']
            mode: ['visual', 'linewise']

        it "I in vL-mode with persistent-selection", ->
          ensure 'I',
            mode: 'insert'
            textC: """
            |0 ==========
            |1 ==========
            2 ==========
            |3 ==========
            |4 ==========
            5 ==========
            """
            # cursor: [[3, 0], [4, 0], [0, 0], [1, 0]]

        it "A in vL-mode with persistent-selection", ->
          ensure 'A',
            mode: 'insert'
            textC: """
            0 ==========|
            1 ==========|
            2 ==========
            3 ==========|
            4 ==========|
            5 ==========
            """
            # cursor: [[3, 12], [4, 12], [0, 12], [1, 12]]

    describe "select-occurrence-in-a-persistent-selection", ->
      it "select all instance of cursor word only within marked range", ->
        runs ->
          paragraphText = """
            ooo xxx ooo
            xxx ooo xxx\n
            """
          ensurePersistentSelection 'g m i p } } j .', # Mark 2 inner-word and 1 inner-paragraph
            length: 2
            text: [paragraphText, paragraphText]

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

    describe "clear-persistent-selections command", ->
      it "clear persistentSelections", ->
        ensurePersistentSelection 'g m i w',
          length: 1
          text: ['ooo']

        dispatch(editorElement, 'vim-mode-plus:clear-persistent-selection')
        expect(vimState.persistentSelection.hasMarkers()).toBe(false)

    describe "clearPersistentSelectionOnResetNormalMode", ->
      describe "when disabled", ->
        it "it won't clear persistentSelection", ->
          settings.set('clearPersistentSelectionOnResetNormalMode', false)
          ensurePersistentSelection 'g m i w',
            length: 1
            text: ['ooo']

          ensure "escape", mode: 'normal'
          ensurePersistentSelection length: 1, text: ['ooo']

      describe "when enabled", ->
        it "it clear persistentSelection on reset-normal-mode", ->
          settings.set('clearPersistentSelectionOnResetNormalMode', true)
          ensurePersistentSelection 'g m i w',
            length: 1
            text: ['ooo']
          ensure "escape", mode: 'normal'
          expect(vimState.persistentSelection.hasMarkers()).toBe(false)
