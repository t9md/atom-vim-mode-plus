# Refactoring status: 80%
{getVimState} = require './spec-helper'

describe "Insert mode commands", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (_vimState, vim) ->
      vimState = _vimState
      {editor, editorElement} = _vimState
      {set, ensure, keystroke} = vim

  afterEach ->
    vimState.activate('reset')

  describe "Copy from line above/below", ->
    beforeEach ->
      set
        text: """
          12345

          abcd
          efghi
          """
        cursorBuffer: [[1, 0], [3, 0]]
      keystroke 'i'

    describe "the ctrl-y command", ->
      it "copies from the line above", ->
        ensure {ctrl: 'y'},
          text: """
            12345
            1
            abcd
            aefghi
            """
        editor.insertText ' '
        ensure {ctrl: 'y'},
          text: """
            12345
            1 3
            abcd
            a cefghi
            """

      it "does nothing if there's nothing above the cursor", ->
        editor.insertText 'fill'
        ensure {ctrl: 'y'},
          text: """
            12345
            fill5
            abcd
            fillefghi
            """
        ensure {ctrl: 'y'},
          text: """
            12345
            fill5
            abcd
            fillefghi
            """

      it "does nothing on the first line", ->
        set
          cursorBuffer: [[0, 2], [3, 2]]
        editor.insertText 'a'
        ensure
          text: """
            12a345

            abcd
            efaghi
            """
        ensure {ctrl: 'y'},
          text: """
            12a345

            abcd
            efadghi
            """

    describe "the ctrl-e command", ->
      beforeEach ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus.insert-mode':
            'ctrl-e': 'vim-mode-plus:copy-from-line-below'

      it "copies from the line below", ->
        ensure {ctrl: 'e'},
          text: """
            12345
            a
            abcd
            efghi
            """
        editor.insertText ' '
        ensure {ctrl: 'e'},
          text: """
            12345
            a c
            abcd
             efghi
            """

      it "does nothing if there's nothing below the cursor", ->
        editor.insertText 'foo'
        ensure {ctrl: 'e'},
          text: """
            12345
            food
            abcd
            fooefghi
            """
        ensure {ctrl: 'e'},
          text: """
            12345
            food
            abcd
            fooefghi
            """
