{getVimState} = require './spec-helper'

describe "Insert mode commands", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (_vimState, vim) ->
      vimState = _vimState
      {editor, editorElement} = _vimState
      {set, ensure, keystroke} = vim

  describe "Copy from line above/below", ->
    beforeEach ->
      set
        text: """
          12345

          abcd
          efghi
          """
        cursor: [[1, 0], [3, 0]]
      keystroke 'i'

    describe "the ctrl-y command", ->
      it "copies from the line above", ->
        ensure 'ctrl-y',
          text: """
            12345
            1
            abcd
            aefghi
            """
        editor.insertText ' '
        ensure 'ctrl-y',
          text: """
            12345
            1 3
            abcd
            a cefghi
            """

      it "does nothing if there's nothing above the cursor", ->
        editor.insertText 'fill'
        ensure 'ctrl-y',
          text: """
            12345
            fill5
            abcd
            fillefghi
            """
        ensure 'ctrl-y',
          text: """
            12345
            fill5
            abcd
            fillefghi
            """

      it "does nothing on the first line", ->
        set
          textC: """
          12|345

          abcd
          ef!ghi
          """

        editor.insertText 'a'
        ensure
          textC: """
            12a|345

            abcd
            efa!ghi
            """
        ensure 'ctrl-y',
          textC: """
            12a|345

            abcd
            efad!ghi
            """

    describe "the ctrl-e command", ->
      beforeEach ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus.insert-mode':
            'ctrl-e': 'vim-mode-plus:copy-from-line-below'

      it "copies from the line below", ->
        ensure 'ctrl-e',
          text: """
            12345
            a
            abcd
            efghi
            """
        editor.insertText ' '
        ensure 'ctrl-e',
          text: """
            12345
            a c
            abcd
             efghi
            """

      it "does nothing if there's nothing below the cursor", ->
        editor.insertText 'foo'
        ensure 'ctrl-e',
          text: """
            12345
            food
            abcd
            fooefghi
            """
        ensure 'ctrl-e',
          text: """
            12345
            food
            abcd
            fooefghi
            """

    describe "InsertLastInserted", ->
      ensureInsertLastInserted = (key, options) ->
        {insert, text, finalText} = options
        keystroke key
        editor.insertText(insert)
        ensure "escape", text: text
        ensure "G I ctrl-a", text: finalText

      beforeEach ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus.insert-mode':
            'ctrl-a': 'vim-mode-plus:insert-last-inserted'

        initialText = """
          abc
          def\n
          """
        set text: "", cursor: [0, 0]
        keystroke 'i'
        editor.insertText(initialText)
        ensure "escape g g",
          text: initialText
          cursor: [0, 0]

      it "case-i: single-line", ->
        ensureInsertLastInserted 'i',
          insert: 'xxx'
          text: "xxxabc\ndef\n"
          finalText: "xxxabc\nxxxdef\n"
      it "case-o: single-line", ->
        ensureInsertLastInserted 'o',
          insert: 'xxx'
          text: "abc\nxxx\ndef\n"
          finalText: "abc\nxxx\nxxxdef\n"
      it "case-O: single-line", ->
        ensureInsertLastInserted 'O',
          insert: 'xxx'
          text: "xxx\nabc\ndef\n"
          finalText: "xxx\nabc\nxxxdef\n"

      it "case-i: multi-line", ->
        ensureInsertLastInserted 'i',
          insert: 'xxx\nyyy\n'
          text: "xxx\nyyy\nabc\ndef\n"
          finalText: "xxx\nyyy\nabc\nxxx\nyyy\ndef\n"
      it "case-o: multi-line", ->
        ensureInsertLastInserted 'o',
          insert: 'xxx\nyyy\n'
          text: "abc\nxxx\nyyy\n\ndef\n"
          finalText: "abc\nxxx\nyyy\n\nxxx\nyyy\ndef\n"
      it "case-O: multi-line", ->
        ensureInsertLastInserted 'O',
          insert: 'xxx\nyyy\n'
          text: "xxx\nyyy\n\nabc\ndef\n"
          finalText: "xxx\nyyy\n\nabc\nxxx\nyyy\ndef\n"
