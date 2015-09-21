# Refactoring status: 80%
{getVimState} = require './spec-helper'

describe "Insert mode commands", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (vimState, vim) ->
      {editor, editorElement} = vimState
      vimState.activateNormalMode()
      vimState.resetNormalMode()
      {set, ensure, keystroke} = vim

  describe "Copy from line above/below", ->
    beforeEach ->
      set
        text: """
        12345

        abcd
        efghi
        """
        cursorBuffer: [1, 0]
        addCursor: [3, 0]
      keystroke 'i'

    describe "the ctrl-y command", ->
      it "copies from the line above", ->
        ensure [ctrl: 'y'], text: """
        12345
        1
        abcd
        aefghi
        """
        editor.insertText ' '
        ensure [ctrl: 'y'], text: """
        12345
        1 3
        abcd
        a cefghi
        """

      it "does nothing if there's nothing above the cursor", ->
        editor.insertText 'fill'
        ensure [ctrl: 'y'], text: '12345\nfill5\nabcd\nfillefghi'
        ensure [ctrl: 'y'], text: '12345\nfill5\nabcd\nfillefghi'

      it "does nothing on the first line", ->
        set
          cursorBuffer: [0, 2]
          addCursor: [3, 2]
        editor.insertText 'a'
        ensure text: '12a345\n\nabcd\nefaghi'
        ensure [ctrl: 'y'], text: '12a345\n\nabcd\nefadghi'

    describe "the ctrl-e command", ->
      beforeEach ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode.insert-mode':
            'ctrl-e': 'vim-mode:copy-from-line-below'

      it "copies from the line below", ->
        ensure [ctrl: 'e'], text: '12345\na\nabcd\nefghi'
        editor.insertText ' '
        ensure [ctrl: 'e'], text: '12345\na c\nabcd\n efghi'

      it "does nothing if there's nothing below the cursor", ->
        editor.insertText 'foo'
        ensure [ctrl: 'e'], text: '12345\nfood\nabcd\nfooefghi'
        ensure [ctrl: 'e'], text: '12345\nfood\nabcd\nfooefghi'
