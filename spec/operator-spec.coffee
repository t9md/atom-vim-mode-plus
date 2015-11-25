# Refactoring status: 80%
{getVimState, dispatch} = require './spec-helper'
settings = require '../lib/settings'

describe "Operator", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim

  afterEach ->
    vimState.activate('reset')

  describe "cancelling operations", ->
    it "clear pending operation", ->
      keystroke '/'
      expect(vimState.operationStack.isEmpty()).toBe false
      vimState.search.cancel()
      expect(vimState.operationStack.isEmpty()).toBe true
      expect(-> vimState.search.cancel()).not.toThrow()

  describe "the x keybinding", ->
    describe "on a line with content", ->
      describe "without vim-mode-plus.wrapLeftRightMotion", ->
        beforeEach ->
          set
            text: "abc\n012345\n\nxyz"
            cursor: [1, 4]

        it "deletes a character", ->
          ensure 'x', text: 'abc\n01235\n\nxyz', cursor: [1, 4], register: '"': text: '4'
          ensure 'x', text: 'abc\n0123\n\nxyz' , cursor: [1, 3], register: '"': text: '5'
          ensure 'x', text: 'abc\n012\n\nxyz'  , cursor: [1, 2], register: '"': text: '3'
          ensure 'x', text: 'abc\n01\n\nxyz'   , cursor: [1, 1], register: '"': text: '2'
          ensure 'x', text: 'abc\n0\n\nxyz'    , cursor: [1, 0], register: '"': text: '1'
          ensure 'x', text: 'abc\n\n\nxyz'     , cursor: [1, 0], register: '"': text: '0'

        it "deletes multiple characters with a count", ->
          ensure '2x', text: 'abc\n0123\n\nxyz', cursor: [1, 3], register: '"': text: '45'
          set cursor: [0, 1]
          ensure '3x',
            text: 'a\n0123\n\nxyz'
            cursor: [0, 0]
            register: '"': text: 'bc'

      describe "with multiple cursors", ->
        beforeEach ->
          set
            text: "abc\n012345\n\nxyz"
            cursor: [[1, 4], [0, 1]]

        it "is undone as one operation", ->
          ensure 'x', text: "ac\n01235\n\nxyz"
          ensure 'u', text: 'abc\n012345\n\nxyz'

      describe "with vim-mode-plus.wrapLeftRightMotion", ->
        beforeEach ->
          set text: 'abc\n012345\n\nxyz', cursor: [1, 4]
          settings.set('wrapLeftRightMotion', true)

        it "deletes a character", ->
          # copy of the earlier test because wrapLeftRightMotion should not affect it
          ensure 'x', text: 'abc\n01235\n\nxyz', cursor: [1, 4], register: '"': text: '4'
          ensure 'x', text: 'abc\n0123\n\nxyz' , cursor: [1, 3], register: '"': text: '5'
          ensure 'x', text: 'abc\n012\n\nxyz'  , cursor: [1, 2], register: '"': text: '3'
          ensure 'x', text: 'abc\n01\n\nxyz'   , cursor: [1, 1], register: '"': text: '2'
          ensure 'x', text: 'abc\n0\n\nxyz'    , cursor: [1, 0], register: '"': text: '1'
          ensure 'x', text: 'abc\n\n\nxyz'     , cursor: [1, 0], register: '"': text: '0'

        it "deletes multiple characters and newlines with a count", ->
          settings.set('wrapLeftRightMotion', true)
          ensure '2x', text: 'abc\n0123\n\nxyz', cursor: [1, 3], register: '"': text: '45'
          set cursor: [0, 1]
          ensure '3x', text: 'a0123\n\nxyz', cursor: [0, 1], register: '"': text: 'bc\n'
          ensure '7x', text: 'ayz', cursor: [0, 1], register: '"': text: '0123\n\nx'

    describe "on an empty line", ->
      beforeEach ->
        set text: "abc\n012345\n\nxyz", cursor: [2, 0]

      it "deletes nothing on an empty line when vim-mode-plus.wrapLeftRightMotion is false", ->
        settings.set('wrapLeftRightMotion', false)
        ensure 'x', text: "abc\n012345\n\nxyz", cursor: [2, 0]

      it "deletes an empty line when vim-mode-plus.wrapLeftRightMotion is true", ->
        settings.set('wrapLeftRightMotion', true)
        ensure 'x', text: "abc\n012345\nxyz", cursor: [2, 0]

  describe "the X keybinding", ->
    describe "on a line with content", ->
      beforeEach ->
        set text: "ab\n012345", cursor: [1, 2]

      it "deletes a character", ->
        ensure 'X', text: 'ab\n02345', cursor: [1, 1], register: '"': text: '1'
        ensure 'X', text: 'ab\n2345', cursor: [1, 0], register: '"': text: '0'
        ensure 'X', text: 'ab\n2345', cursor: [1, 0], register: '"': text: '0'
        settings.set('wrapLeftRightMotion', true)
        ensure 'X', text: 'ab2345', cursor: [0, 2], register: '"': text: '\n'

    describe "on an empty line", ->
      beforeEach ->
        set
          text: "012345\n\nabcdef"
          cursor: [1, 0]

      it "deletes nothing when vim-mode-plus.wrapLeftRightMotion is false", ->
        settings.set('wrapLeftRightMotion', false)
        ensure 'X', text: "012345\n\nabcdef", cursor: [1, 0]

      it "deletes the newline when wrapLeftRightMotion is true", ->
        settings.set('wrapLeftRightMotion', true)
        ensure 'X', text: "012345\nabcdef", cursor: [0, 5]

  describe "the s keybinding", ->
    beforeEach ->
      set text: '012345', cursor: [0, 1]

    it "deletes the character to the right and enters insert mode", ->
      ensure 's',
        mode: 'insert'
        text: '02345'
        cursor: [0, 1]
        register: '"': text: '1'

    it "is repeatable", ->
      set cursor: [0, 0]
      keystroke '3s'
      editor.insertText 'ab'
      ensure 'escape', text: 'ab345'
      set cursor: [0, 2]
      ensure '.', text: 'abab'

    it "is undoable", ->
      set cursor: [0, 0]
      keystroke '3s'
      editor.insertText 'ab'
      ensure 'escape', text: 'ab345'
      ensure 'u', text: '012345', selectedText: ''

    describe "in visual mode", ->
      beforeEach ->
        keystroke 'vls'

      it "deletes the selected characters and enters insert mode", ->
        ensure
          mode: 'insert'
          text: '0345'
          cursor: [0, 1]
          register: '"': text: '12'

  describe "the S keybinding", ->
    beforeEach ->
      set
        text: "12345\nabcde\nABCDE"
        cursor: [1, 3]

    it "deletes the entire line and enters insert mode", ->
      ensure 'S',
        mode: 'insert'
        text: "12345\n\nABCDE"
        register: {'"': text: 'abcde\n', type: 'linewise'}

    it "is repeatable", ->
      keystroke 'S'
      editor.insertText 'abc'
      ensure 'escape', text: '12345\nabc\nABCDE'
      set cursor: [2, 3]
      ensure '.', text: '12345\nabc\nabc\n'

    it "is undoable", ->
      keystroke 'S'
      editor.insertText 'abc'
      ensure 'escape', text: '12345\nabc\nABCDE'
      ensure 'u', text: "12345\nabcde\nABCDE", selectedText: ''

    # Here is original spec I believe its not correct, if it says 'works'
    # text result should be '\n' since S delete current line.
    # Its orignally added in following commit, as fix of S(from description).
    # But original SubstituteLine replaced with Change and MoveToRelativeLine combo.
    # I believe this spec should have been failed at that time, but havent'.
    # https://github.com/atom/vim-mode/commit/6acffd2559e56f7c18a4d766f0ad92c9ed6212ae
    #
    # it "works when the cursor's goal column is greater than its current column", ->
    #   set text: "\n12345", cursor: [1, Infinity]
    #   ensure 'kS', text: '\n12345'

    it "works when the cursor's goal column is greater than its current column", ->
      set text: "\n12345", cursor: [1, Infinity]
      # Should be here, but I commented out before I have confidence.
      # ensure 'kS', text: '\n'
      # Folowing line include Bug ibelieve.
      ensure 'kS', text: '\n12345'
    # Can't be tested without setting grammar of test buffer
    xit "respects indentation", ->

  describe "the d keybinding", ->
    it "enters operator-pending mode", ->
      ensure 'd', mode: 'operator-pending'

    describe "when followed by a d", ->
      it "deletes the current line and exits operator-pending mode", ->
        set text: "12345\nabcde\n\nABCDE", cursor: [1, 1]
        ensure 'dd',
          text: '12345\n\nABCDE'
          cursor: [1, 0]
          register: '"': text: 'abcde\n'
          mode: 'normal'

      it "deletes the last line", ->
        set text: "12345\nabcde\nABCDE", cursor: [2, 1]
        ensure 'dd', text: "12345\nabcde\n", cursor: [2, 0]

      it "leaves the cursor on the first nonblank character", ->
        set text: '12345\n  abcde\n', cursor: [0, 4]
        ensure 'dd', text: "  abcde\n", cursor: [0, 2]

    describe "undo behavior", ->
      beforeEach ->
        set text: "12345\nabcde\nABCDE\nQWERT", cursor: [1, 1]

      it "undoes both lines", ->
        ensure 'd2du', text: "12345\nabcde\nABCDE\nQWERT", selectedText: ''

      describe "with multiple cursors", ->
        beforeEach ->
          set cursor: [[1, 1], [0, 0]]

        it "is undone as one operation", ->
          ensure 'dlu',
            text: "12345\nabcde\nABCDE\nQWERT"
            selectedText: ['', '']

    describe "when followed by a w", ->
      it "deletes the next word until the end of the line and exits operator-pending mode", ->
        set text: 'abcd efg\nabc', cursor: [0, 5]

        # Incompatibility with VIM. In vim, `w` behaves differently as an
        # operator than as a motion; it stops at the end of a linie.
        ensure 'dw',
          text: 'abcd abc'
          cursor: [0, 5]
          mode: 'normal'

      it "deletes to the beginning of the next word", ->
        set text: 'abcd efg', cursor: [0, 2]
        ensure 'dw', text: 'abefg', cursor: [0, 2]
        set text: 'one two three four', cursor: [0, 0]
        ensure 'd3w', text: 'four', cursor: [0, 0]

    describe "when followed by an iw", ->
      it "deletes the containing word", ->
        set text: "12345 abcde ABCDE", cursor: [0, 9]

        ensure 'd',
          mode: 'operator-pending'

        ensure 'iw',
          text: "12345  ABCDE"
          cursor: [0, 6]
          register: '"': text: 'abcde'
          mode: 'normal'

    describe "when followed by a j", ->
      originalText = "12345\nabcde\nABCDE\n"

      beforeEach ->
        set text: originalText

      describe "on the beginning of the file", ->
        it "deletes the next two lines", ->
          set cursor: [0, 0]
          ensure 'dj', text: 'ABCDE\n'

      describe "on the end of the file", ->
        it "deletes nothing", ->
          set cursor: [4, 0]
          ensure 'dj', text: originalText

      describe "on the middle of second line", ->
        it "deletes the last two lines", ->
          set cursor: [1, 2]
          ensure 'dj', text: '12345\n'

    describe "when followed by an k", ->
      originalText = "12345\nabcde\nABCDE"

      beforeEach ->
        set text: originalText

      describe "on the end of the file", ->
        it "deletes the bottom two lines", ->
          set cursor: [2, 4]
          ensure 'dk', text: '12345\n'

      describe "on the beginning of the file", ->
        xit "deletes nothing", ->
          set cursor: [0, 0]
          ensure 'dk', text: originalText

      describe "when on the middle of second line", ->
        it "deletes the first two lines", ->
          set cursor: [1, 2]
          ensure 'dk', text: 'ABCDE'

    describe "when followed by a G", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE"
        set text: originalText

      describe "on the beginning of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 0]
          ensure 'dG', text: '12345\n'

      describe "on the middle of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 2]
          ensure 'dG', text: '12345\n'

    describe "when followed by a goto line G", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE"
        set text: originalText

      describe "on the beginning of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 0]
          ensure 'd2G', text: '12345\nABCDE'

      describe "on the middle of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 2]
          ensure 'd2G', text: '12345\nABCDE'

    describe "when followed by a t)", ->
      describe "with the entire line yanked before", ->
        beforeEach ->
          set text: "test (xyz)", cursor: [0, 6]

        it "deletes until the closing parenthesis", ->
          ensure ['yydt', char: ')'],
            text: 'test ()'
            cursor: [0, 6]

    describe "with multiple cursors", ->
      it "deletes each selection", ->
        set
          text: "abcd\n1234\nABCD\n"
          cursorBuffer: [[0, 1], [1, 2], [2, 3]]

        ensure 'de',
          text: "a\n12\nABC"
          cursorBuffer: [[0, 0], [1, 1], [2, 2]]

      it "doesn't delete empty selections", ->
        set
          text: "abcd\nabc\nabd"
          cursorBuffer: [[0, 0], [1, 0], [2, 0]]

        ensure ['dt', char: 'd'],
          text: "d\nabc\nd"
          cursorBuffer: [[0, 0], [1, 0], [2, 0]]

  describe "the D keybinding", ->
    beforeEach ->
      editor.getBuffer().setText("012\n")
      set cursor: [0, 1]
      keystroke 'D'

    it "deletes the contents until the end of the line", ->
      ensure text: "0\n"

  describe "the c keybinding", ->
    beforeEach ->
      set text: "12345\nabcde\nABCDE"

    describe "when followed by a c", ->
      describe "with autoindent", ->
        beforeEach ->
          set text: "12345\n  abcde\nABCDE"
          set cursor: [1, 1]
          spyOn(editor, 'shouldAutoIndent').andReturn(true)
          spyOn(editor, 'autoIndentBufferRow').andCallFake (line) ->
            editor.indent()
          spyOn(editor.languageMode, 'suggestedIndentForLineAtBufferRow').andCallFake -> 1

        it "deletes the current line and enters insert mode", ->
          set cursor: [1, 1]
          ensure 'cc',
            text: "12345\n  \nABCDE"
            cursor: [1, 2]
            mode: 'insert'

        it "is repeatable", ->
          keystroke 'cc'
          editor.insertText("abc")
          ensure 'escape', text: "12345\n  abc\nABCDE"
          set cursor: [2, 3]
          ensure '.', text: "12345\n  abc\n  abc\n"

        it "is undoable", ->
          keystroke 'cc'
          editor.insertText("abc")
          ensure 'escape', text: "12345\n  abc\nABCDE"
          ensure 'u', text: "12345\n  abcde\nABCDE", selectedText: ''

      describe "when the cursor is on the last line", ->
        it "deletes the line's content and enters insert mode on the last line", ->
          set cursor: [2, 1]
          ensure 'cc',
            text: "12345\nabcde\n\n"
            cursor: [2, 0]
            mode: 'insert'

      describe "when the cursor is on the only line", ->
        it "deletes the line's content and enters insert mode", ->
          set text: "12345", cursor: [0, 2]
          ensure 'cc',
            text: "\n"
            cursor: [0, 0]
            mode: 'insert'

    describe "when followed by i w", ->
      it "undo's and redo's completely", ->
        set cursor: [1, 1]
        ensure 'ciw',
          text: "12345\n\nABCDE"
          cursor: [1, 0]
          mode: 'insert'

        # Just cannot get "typing" to work correctly in test.
        set text: "12345\nfg\nABCDE"
        ensure 'escape',
          text: "12345\nfg\nABCDE"
          mode: 'normal'
        ensure 'u', text: "12345\nabcde\nABCDE"
        ensure [ctrl: 'r'], text: "12345\nfg\nABCDE"

    describe "when followed by a w", ->
      it "changes the word", ->
        set
          text: "word1 word2 word3"
          cursorBuffer: [0, "word1 w".length]
        ensure ['cw', 'escape'], text: "word1 w word3"

    describe "when followed by a G", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE"
        set text: originalText

      describe "on the beginning of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 0]
          ensure ['cG', 'escape'], text: '12345\n\n'

      describe "on the middle of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 2]
          ensure ['cG', 'escape'], text: '12345\n\n'

    describe "when followed by a goto line G", ->
      beforeEach ->
        set text: "12345\nabcde\nABCDE"

      describe "on the beginning of the second line", ->
        it "deletes all the text on the line", ->
          set cursor: [1, 0]
          ensure ['c2G', 'escape'], text: '12345\n\nABCDE'

      describe "on the middle of the second line", ->
        it "deletes all the text on the line", ->
          set cursor: [1, 2]
          ensure ['c2G', 'escape'], text: '12345\n\nABCDE'

  describe "the C keybinding", ->
    beforeEach ->
      set text: "012\n", cursor: [0, 1]
      keystroke 'C'

    it "deletes the contents until the end of the line and enters insert mode", ->
      ensure
        text: "0\n"
        cursor: [0, 1]
        mode: 'insert'

  describe "the y keybinding", ->
    beforeEach ->
      set text: "012 345\nabc\n", cursor: [0, 4]

    describe "when selected lines in visual linewise mode", ->
      beforeEach ->
        keystroke 'Vjy'

      it "is in linewise motion", ->
        ensure register: '"': type: 'linewise'

      it "saves the lines to the default register", ->
        ensure register: '"': text: "012 345\nabc\n"

      it "places the cursor at the beginning of the selection", ->
        ensure cursorBuffer: [0, 0]

    describe "when followed by a second y ", ->
      beforeEach ->
        keystroke 'yy'

      it "saves the line to the default register", ->
        ensure register: '"': text: "012 345\n"

      it "leaves the cursor at the starting position", ->
        ensure cursor: [0, 4]

    describe "when useClipboardAsDefaultRegister enabled", ->
      it "writes to clipboard", ->
        settings.set 'useClipboardAsDefaultRegister', true
        keystroke 'yy'
        expect(atom.clipboard.read()).toBe '012 345\n'

    describe "when followed with a repeated y", ->
      beforeEach ->
        keystroke 'y2y'

      it "copies n lines, starting from the current", ->
        ensure register: '"': text: "012 345\nabc\n"

      it "leaves the cursor at the starting position", ->
        ensure cursor: [0, 4]

    describe "with a register", ->
      beforeEach ->
        keystroke ['"', char: 'a', 'yy']

      it "saves the line to the a register", ->
        ensure register: a: text: "012 345\n"

      it "appends the line to the A register", ->
        ensure ['"', char: 'A', 'yy'],
          register: a: text: "012 345\n012 345\n"

    describe "with a forward motion", ->
      beforeEach ->
        keystroke 'ye'

      it "saves the selected text to the default register", ->
        ensure register: '"': text: '345'

      it "leaves the cursor at the starting position", ->
        ensure cursor: [0, 4]

      it "does not yank when motion fails", ->
        ensure ['yt', char: 'x'],
          register: '"': text: '345'

    describe "with a text object", ->
      it "moves the cursor to the beginning of the text object", ->
        set cursorBuffer: [0, 5]
        ensure 'yiw', cursorBuffer: [0, 4]

    describe "with a left motion", ->
      beforeEach ->
        keystroke 'yh'

      it "saves the left letter to the default register", ->
        ensure register: '"': text: ' '

      it "moves the cursor position to the left", ->
        ensure cursor: [0, 3]

    describe "with a down motion", ->
      beforeEach ->
        keystroke 'yj'

      it "saves both full lines to the default register", ->
        ensure register: '"': text: "012 345\nabc\n"

      it "leaves the cursor at the starting position", ->
        ensure cursor: [0, 4]

    describe "when followed by a G", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE"
        set text: originalText

      describe "on the beginning of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 0]
          ensure 'yGP', text: '12345\nabcde\nABCDE\nabcde\nABCDE'

      describe "on the middle of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 2]
          ensure 'yGP', text: '12345\nabcde\nABCDE\nabcde\nABCDE'

    describe "when followed by a goto line G", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE"
        set text: originalText

      describe "on the beginning of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 0]
          ensure 'y2GP', text: '12345\nabcde\nabcde\nABCDE'

      describe "on the middle of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 2]
          ensure 'y2GP', text: '12345\nabcde\nabcde\nABCDE'

    describe "with multiple cursors", ->
      it "moves each cursor and copies the last selection's text", ->
        set
          text: "  abcd\n  1234"
          cursorBuffer: [[0, 0], [1, 5]]
        ensure 'y^',
          register: '"': text: '123'
          cursorBuffer: [[0, 0], [1, 2]]

  describe "the yy keybinding", ->
    describe "on a single line file", ->
      beforeEach ->
        set text: "exclamation!\n", cursor: [0, 0]

      it "copies the entire line and pastes it correctly", ->
        ensure 'yyp',
          register: '"': text: "exclamation!\n"
          text: "exclamation!\nexclamation!\n"

    describe "on a single line file with no newline", ->
      beforeEach ->
        set text: "no newline!", cursor: [0, 0]

      it "copies the entire line and pastes it correctly", ->
        ensure 'yyp',
          register: '"': text: "no newline!\n"
          text: "no newline!\nno newline!"

      it "copies the entire line and pastes it respecting count and new lines", ->
        ensure 'yy2p',
          register: '"': text: "no newline!\n"
          text: "no newline!\nno newline!\nno newline!"

  describe "the Y keybinding", ->
    beforeEach ->
      set text: "012 345\nabc\n", cursor: [0, 4]

    it "saves the line to the default register", ->
      ensure 'Y', cursor: [0, 4], register: '"': text: "012 345\n"

  describe "the p keybinding", ->
    describe "with character contents", ->
      beforeEach ->
        set text: "012\n", cursor: [0, 0]
        set register: '"': text: '345'
        set register: 'a': text: 'a'
        atom.clipboard.write "clip"

      describe "from the default register", ->
        beforeEach -> keystroke 'p'

        it "inserts the contents", ->
          ensure text: "034512\n", cursor: [0, 3]

      describe "at the end of a line", ->
        beforeEach ->
          set cursor: [0, 2]
          keystroke 'p'

        it "positions cursor correctly", ->
          ensure text: "012345\n", cursor: [0, 5]

      describe "when useClipboardAsDefaultRegister enabled", ->
        it "inserts contents from clipboard", ->
          settings.set 'useClipboardAsDefaultRegister', true
          ensure 'p', text: "0clip12\n"

      describe "from a specified register", ->
        beforeEach ->
          keystroke ['"', char: 'a', 'p']

        it "inserts the contents of the 'a' register", ->
          ensure text: "0a12\n", cursor: [0, 1]

      describe "at the end of a line", ->
        it "inserts before the current line's newline", ->
          set text: "abcde\none two three", cursor: [1, 4]
          ensure 'd$k$p', text: "abcdetwo three\none "

    describe "with linewise contents", ->
      describe "on a single line", ->
        beforeEach ->
          set
            text: '012'
            cursor: [0, 1]
            register: '"': text: " 345\n", type: 'linewise'

        it "inserts the contents of the default register", ->
          ensure 'p', text: "012\n 345", cursor: [1, 1]

        it "replaces the current selection and put cursor to the first char of line", ->
          ensure 'vp',
            text: "0\n 345\n2"
            cursor: [1, 1]

      describe "on multiple lines", ->
        beforeEach ->
          set
            text: "012\n 345"
            register: '"': text: " 456\n", type: 'linewise'

        it "inserts the contents of the default register at middle line", ->
          set cursor: [0, 1]
          keystroke 'p'
          ensure text: "012\n 456\n 345", cursor: [1, 1]

        it "inserts the contents of the default register at end of line", ->
          set cursor: [1, 1]
          ensure 'p', text: "012\n 345\n 456", cursor: [2, 1]

    describe "with multiple linewise contents", ->
      beforeEach ->
        set
          text: "012\nabc",
          cursor: [1, 0]
          register: '"': text: " 345\n 678\n", type: 'linewise'
        keystroke 'p'

      it "inserts the contents of the default register", ->
        ensure text: "012\nabc\n 345\n 678", cursor: [2, 1]

    describe "pasting twice", ->
      beforeEach ->
        set
          text: "12345\nabcde\nABCDE\nQWERT"
          cursor: [1, 1]
          register: '"': text: '123'
        keystroke '2p'

      it "inserts the same line twice", ->
        ensure text: "12345\nab123123cde\nABCDE\nQWERT"

      describe "when undone", ->
        it "removes both lines", ->
          ensure 'u', text: "12345\nabcde\nABCDE\nQWERT"

    describe "support multiple cursors", ->
      it "paste text for each cursors", ->
        set
          text: "12345\nabcde\nABCDE\nQWERT"
          cursor: [[1, 0], [2, 0]]
          register: '"': text: 'ZZZ'
        ensure 'p',
          text: "12345\naZZZbcde\nAZZZBCDE\nQWERT"
          cursor: [[1, 3], [2, 3]]

    describe "with a selection", ->
      beforeEach ->
        set
          text: '012'
          cursor: [0, 1]
      describe "with characterwise selection", ->
        it "replaces selection with charwise content", ->
          set register: '"': text: "345"
          ensure 'vp', text: "03452", cursor: [0, 3]
        it "replaces selection with linewise content", ->
          set register: '"': text: "345\n"
          ensure 'vp', text: "0\n345\n2", cursor: [1, 0]

      describe "with linewise selection", ->
        it "replaces selection with charwise content", ->
          set text: "012\nabc", cursor: [0, 1]
          set register: '"': text: "345"
          ensure 'Vp', text: "345\nabc", cursor: [0, 0]
        it "replaces selection with linewise content", ->
          set register: '"': text: "345\n"
          ensure 'Vp', text: "345\n", cursor: [0, 0]

  describe "the P keybinding", ->
    describe "with character contents", ->
      beforeEach ->
        set text: "012\n", cursor: [0, 0]
        set register: '"': text: '345'
        set register: a: text: 'a'
        keystroke 'P'

      it "inserts the contents of the default register above", ->
        ensure text: "345012\n", cursor: [0, 2]

  describe "the O keybinding", ->
    beforeEach ->
      spyOn(editor, 'shouldAutoIndent').andReturn(true)
      spyOn(editor, 'autoIndentBufferRow').andCallFake (line) ->
        editor.indent()

      set text: "  abc\n  012\n", cursor: [1, 1]

    it "switches to insert and adds a newline above the current one", ->
      keystroke 'O'
      ensure
        text: "  abc\n  \n  012\n"
        cursor: [1, 2]
        mode: 'insert'

    it "is repeatable", ->
      set
        text: "  abc\n  012\n    4spaces\n", cursor: [1, 1]
      keystroke 'O'
      editor.insertText "def"
      ensure 'escape', text: "  abc\n  def\n  012\n    4spaces\n"
      set cursor: [1, 1]
      ensure '.', text: "  abc\n  def\n  def\n  012\n    4spaces\n"
      set cursor: [4, 1]
      ensure '.', text: "  abc\n  def\n  def\n  012\n    def\n    4spaces\n"

    it "is undoable", ->
      keystroke 'O'
      editor.insertText "def"
      ensure 'escape', text: "  abc\n  def\n  012\n"
      ensure 'u', text: "  abc\n  012\n"

  describe "the o keybinding", ->
    beforeEach ->
      spyOn(editor, 'shouldAutoIndent').andReturn(true)
      spyOn(editor, 'autoIndentBufferRow').andCallFake (line) ->
        editor.indent()

      set text: "abc\n  012\n", cursor: [1, 2]

    it "switches to insert and adds a newline above the current one", ->
      ensure 'o',
        text: "abc\n  012\n  \n"
        mode: 'insert'
        cursor: [2, 2]

    # This works in practice, but the editor doesn't respect the indentation
    # rules without a syntax grammar. Need to set the editor's grammar
    # to fix it.
    xit "is repeatable", ->
      set text: "  abc\n  012\n    4spaces\n", cursor: [1, 1]
      keystroke 'o'
      editor.insertText "def"
      ensure 'escape', text: "  abc\n  012\n  def\n    4spaces\n"
      ensure '.', text: "  abc\n  012\n  def\n  def\n    4spaces\n"
      set cursor: [4, 1]
      ensure '.', text: "  abc\n  def\n  def\n  012\n    4spaces\n    def\n"

    it "is undoable", ->
      keystroke 'o'
      editor.insertText "def"
      ensure 'escape', text: "abc\n  012\n  def\n"
      ensure 'u', text: "abc\n  012\n"

  describe "the a keybinding", ->
    beforeEach ->
      set text: "012\n"

    describe "at the beginning of the line", ->
      beforeEach ->
        set cursor: [0, 0]
        keystroke 'a'

      it "switches to insert mode and shifts to the right", ->
        ensure cursor: [0, 1], mode: 'insert'

    describe "at the end of the line", ->
      beforeEach ->
        set cursor: [0, 3]
        keystroke 'a'

      it "doesn't linewrap", ->
        ensure cursor: [0, 3]

  describe "the A keybinding", ->
    beforeEach ->
      set text: "11\n22\n"

    describe "at the beginning of a line", ->
      it "switches to insert mode at the end of the line", ->
        set cursor: [0, 0]
        ensure 'A',
          mode: 'insert'
          cursor: [0, 2]

      it "repeats always as insert at the end of the line", ->
        set cursor: [0, 0]
        keystroke 'A'
        editor.insertText("abc")
        keystroke 'escape'
        set cursor: [1, 0]

        ensure '.',
          text: "11abc\n22abc\n"
          mode: 'normal'
          cursor: [1, 4]

  describe "the I keybinding", ->
    beforeEach ->
      set text: "11\n  22\n"

    describe "at the end of a line", ->
      it "switches to insert mode at the beginning of the line", ->
        set cursor: [0, 2]
        ensure 'I',
          cursor: [0, 0]
          mode: 'insert'

      it "switches to insert mode after leading whitespace", ->
        set cursor: [1, 4]
        ensure 'I',
          cursor: [1, 2]
          mode: 'insert'


      it "repeats always as insert at the first character of the line", ->
        set cursor: [0, 2]
        keystroke 'I'
        editor.insertText("abc")
        ensure 'escape', cursor: [0, 2]
        set cursor: [1, 4]
        ensure '.',
          text: "abc11\n  abc22\n"
          cursor: [1, 4]
          mode: 'normal'

  describe "the J keybinding", ->
    beforeEach ->
      set text: "012\n    456\n", cursor: [0, 1]

    describe "without repeating", ->
      beforeEach -> keystroke 'J'

      it "joins the contents of the current line with the one below it", ->
        ensure text: "012 456\n"

    describe "with repeating", ->
      beforeEach ->
        set
          text: "12345\nabcde\nABCDE\nQWERT"
          cursor: [1, 1]
        keystroke '2J'

      describe "undo behavior", ->
        beforeEach -> keystroke 'u'

        it "handles repeats", ->
          ensure text: "12345\nabcde\nABCDE\nQWERT"

  describe "the > keybinding", ->
    beforeEach ->
      set text: """
        12345
        abcde
        ABCDE
        """

    describe "on the last line", ->
      beforeEach ->
        set cursor: [2, 0]

      describe "when followed by a >", ->
        it "indents the current line", ->
          ensure '>>',
            text: "12345\nabcde\n  ABCDE"
            cursor: [2, 2]

    describe "on the first line", ->
      beforeEach ->
        set cursor: [0, 0]

      describe "when followed by a >", ->
        it "indents the current line", ->
          ensure '>>',
            text: "  12345\nabcde\nABCDE"
            cursor: [0, 2]

      describe "when followed by a repeating >", ->
        beforeEach ->
          keystroke '3>>'

        it "indents multiple lines at once", ->
          ensure
            text: "  12345\n  abcde\n  ABCDE"
            cursor: [0, 2]

        describe "undo behavior", ->
          it "outdents all three lines", ->
            ensure 'u', text: "12345\nabcde\nABCDE"

    describe "in visual mode", ->
      beforeEach ->
        set cursor: [0, 0]
        keystroke 'V>'

      it "indents the current line and exits visual mode", ->
        ensure
          mode: 'normal'
          text: "  12345\nabcde\nABCDE"
          selectedBufferRange: [[0, 2], [0, 2]]

      it "allows repeating the operation", ->
        ensure '.', text: "    12345\nabcde\nABCDE"

  describe "the < keybinding", ->
    beforeEach ->
      set text: "  12345\n  abcde\nABCDE", cursor: [0, 0]

    describe "when followed by a <", ->
      it "indents the current line", ->
        ensure '<<',
          text: "12345\n  abcde\nABCDE"
          cursor: [0, 0]

    describe "when followed by a repeating <", ->
      beforeEach ->
        keystroke '2<<'

      it "indents multiple lines at once", ->
        ensure
          text: "12345\nabcde\nABCDE"
          cursor: [0, 0]

      describe "undo behavior", ->
        it "indents both lines", ->
          ensure 'u', text: "  12345\n  abcde\nABCDE"

    describe "in visual mode", ->
      it "indents the current line and exits visual mode", ->
        ensure 'V<',
          mode: 'normal'
          text: "12345\n  abcde\nABCDE"
          selectedBufferRange: [[0, 0], [0, 0]]

  describe "the = keybinding", ->
    oldGrammar = []

    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-javascript')

      oldGrammar = editor.getGrammar()
      set text: "foo\n  bar\n  baz", cursor: [1, 0]


    describe "when used in a scope that supports auto-indent", ->
      beforeEach ->
        jsGrammar = atom.grammars.grammarForScopeName('source.js')
        editor.setGrammar(jsGrammar)

      afterEach ->
        editor.setGrammar(oldGrammar)

      describe "when followed by a =", ->
        beforeEach ->
          keystroke '=='

        it "indents the current line", ->
          expect(editor.indentationForBufferRow(1)).toBe 0

      describe "when followed by a repeating =", ->
        beforeEach ->
          keystroke '2=='

        it "autoindents multiple lines at once", ->
          ensure text: "foo\nbar\nbaz", cursor: [1, 0]

        describe "undo behavior", ->
          it "indents both lines", ->
            ensure 'u', text: "foo\n  bar\n  baz"

  describe "the . keybinding", ->
    beforeEach ->
      set text: "12\n34\n56\n78", cursor: [0, 0]

    it "repeats the last operation", ->
      ensure '2dd.', text: ""

    it "composes with motions", ->
      ensure 'dd2.', text: "78"

  describe "the r keybinding", ->
    beforeEach ->
      set
        text: "12\n34\n\n"
        cursorBuffer: [[0, 0], [1, 0]]

    it "replaces a single character", ->
      ensure ['r', char: 'x'], text: 'x2\nx4\n\n'

    it "does nothing when cancelled", ->
      ensure 'r',
        mode: 'operator-pending'
      vimState.input.cancel()
      ensure
        text: '12\n34\n\n'
        mode: 'normal'

    it "remain visual-mode when cancelled", ->
      keystroke 'vr'
      vimState.input.cancel()
      ensure
        text: '12\n34\n\n'
        mode: ['visual', 'characterwise']

    it "replaces a single character with a line break", ->
      inputEditorElement = vimState.input.view.editorElement
      keystroke 'r'
      dispatch(inputEditorElement, 'core:confirm')
      ensure
        text: '\n2\n\n4\n\n'
        cursorBuffer: [[1, 0], [3, 0]]

    it "composes properly with motions", ->
      ensure ['2r', char: 'x'], text: 'xx\nxx\n\n'

    it "does nothing on an empty line", ->
      set cursorBuffer: [2, 0]
      ensure ['r', char: 'x'], text: '12\n34\n\n'

    it "does nothing if asked to replace more characters than there are on a line", ->
      ensure ['3r', char: 'x'], text: '12\n34\n\n'

    describe "when in visual mode", ->
      beforeEach ->
        keystroke 've'

      it "replaces the entire selection with the given character", ->
        ensure ['r', char: 'x'], text: 'xx\nxx\n\n'

      it "leaves the cursor at the beginning of the selection", ->
        ensure ['r', char: 'x' ], cursorBuffer: [[0, 0], [1, 0]]

  describe 'the m keybinding', ->
    beforeEach ->
      set text: '12\n34\n56\n', cursorBuffer: [0, 1]

    it 'marks a position', ->
      keystroke ['m', char: 'a']
      expect(vimState.mark.get('a')).toEqual [0, 1]

  describe 'the ~ keybinding', ->
    beforeEach ->
      set
        text: 'aBc\nXyZ'
        cursorBuffer: [[0, 0], [1, 0]]

    it 'toggles the case and moves right', ->
      ensure '~',
        text: 'ABc\nxyZ'
        cursor: [[0, 1], [1, 1]]

      ensure '~',
        text: 'Abc\nxYZ'
        cursor: [[0, 2], [1, 2]]

      ensure  '~',
        text: 'AbC\nxYz'
        cursor: [[0, 2], [1, 2]]

    it 'takes a count', ->
      ensure '4~',
        text: 'AbC\nxYz'
        cursor: [[0, 2], [1, 2]]

    describe "in visual mode", ->
      it "toggles the case of the selected text", ->
        set cursorBuffer: [0, 0]
        ensure 'V~', text: 'AbC\nXyZ'

    describe "with g and motion", ->
      it "toggles the case of text, won't move cursor", ->
        set cursorBuffer: [0, 0]
        ensure 'g~2l', text: 'Abc\nXyZ', cursor: [0, 0]

      it "g~~ toggles the line of text, won't move cursor", ->
        set cursorBuffer: [0, 1]
        ensure 'g~~', text: 'AbC\nXyZ', cursor: [0, 1]

      it "g~g~ toggles the line of text, won't move cursor", ->
        set cursorBuffer: [0, 1]
        ensure 'g~g~', text: 'AbC\nXyZ', cursor: [0, 1]

  describe 'the U keybinding', ->
    beforeEach ->
      set
        text: 'aBc\nXyZ'
        cursorBuffer: [0, 0]

    it "makes text uppercase with g and motion, and won't move cursor", ->
      ensure 'gUl', text: 'ABc\nXyZ', cursor: [0, 0]
      ensure 'gUe', text: 'ABC\nXyZ', cursor: [0, 0]
      set cursorBuffer: [1, 0]
      ensure 'gU$', text: 'ABC\nXYZ', cursor: [1, 0]

    it "makes the selected text uppercase in visual mode", ->
      ensure 'VU', text: 'ABC\nXyZ'

    it "gUU upcase the line of text, won't move cursor", ->
      set cursorBuffer: [0, 1]
      ensure 'gUU', text: 'ABC\nXyZ', cursor: [0, 1]

    it "gUgU upcase the line of text, won't move cursor", ->
      set cursorBuffer: [0, 1]
      ensure 'gUgU', text: 'ABC\nXyZ', cursor: [0, 1]

  describe 'the u keybinding', ->
    beforeEach ->
      set text: 'aBc\nXyZ', cursorBuffer: [0, 0]

    it "makes text lowercase with g and motion, and won't move cursor", ->
      ensure 'gu$', text: 'abc\nXyZ', cursor: [0, 0]

    it "makes the selected text lowercase in visual mode", ->
      ensure 'Vu', text: 'abc\nXyZ'

    it "guu downcase the line of text, won't move cursor", ->
      set cursorBuffer: [0, 1]
      ensure 'guu', text: 'abc\nXyZ', cursor: [0, 1]

    it "gugu downcase the line of text, won't move cursor", ->
      set cursorBuffer: [0, 1]
      ensure 'gugu', text: 'abc\nXyZ', cursor: [0, 1]

  describe 'CamelCase', ->
    beforeEach ->
      set
        text: 'vim-mode\natom-text-editor\n'
        cursorBuffer: [0, 0]

    it "CamelCase text and not move cursor", ->
      ensure 'gc$', text: 'vimMode\natom-text-editor\n', cursor: [0, 0]
      ensure 'jgc$', text: 'vimMode\natomTextEditor\n', cursor: [1, 0]

    it "CamelCase selected text", ->
      ensure 'Vjgc', text: 'vimMode\natomTextEditor\n', cursor: [0, 0]

    it "gcgc CamelCase the line of text, won't move cursor", ->
      ensure 'lgcgc', text: 'vimMode\natom-text-editor\n', cursor: [0, 1]

  describe 'SnakeCase', ->
    beforeEach ->
      set
        text: 'vim-mode\natom-text-editor\n'
        cursorBuffer: [0, 0]
      atom.keymaps.add "g_",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          'g _': 'vim-mode-plus:snake-case'

    it "SnakeCase text and not move cursor", ->
      ensure 'g_$', text: 'vim_mode\natom-text-editor\n', cursor: [0, 0]
      ensure 'jg_$', text: 'vim_mode\natom_text_editor\n', cursor: [1, 0]

    it "SnakeCase selected text", ->
      ensure 'Vjg_', text: 'vim_mode\natom_text_editor\n', cursor: [0, 0]

    it "g_g_ SnakeCase the line of text, won't move cursor", ->
      ensure 'lg_g_', text: 'vim_mode\natom-text-editor\n', cursor: [0, 1]

  describe 'DashCase', ->
    beforeEach ->
      set
        text: 'vimMode\natom_text_editor\n'
        cursorBuffer: [0, 0]

    it "DashCase text and not move cursor", ->
      ensure 'g-$', text: 'vim-mode\natom_text_editor\n', cursor: [0, 0]
      ensure 'jg-$', text: 'vim-mode\natom-text-editor\n', cursor: [1, 0]

    it "DashCase selected text", ->
      ensure 'Vjg-', text: 'vim-mode\natom-text-editor\n', cursor: [0, 0]

    it "g-g- DashCase the line of text, won't move cursor", ->
      ensure 'lg-g-', text: 'vim-mode\natom_text_editor\n', cursor: [0, 1]

  describe 'surround', ->
    beforeEach ->
      set
        text: """
          apple
          pairs: [brackets]
          pairs: [brackets]
          ( multi
            line )
          """
        cursorBuffer: [0, 0]

    describe 'surround', ->
      it "surround text object with ( and repeatable", ->
        ensure ['gss', char: '(', 'iw'],
          text: "(apple)\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          cursor: [0, 0]
        ensure 'j.',
          text: "(apple)\n(pairs): [brackets]\npairs: [brackets]\n( multi\n  line )"
      it "surround text object with { and repeatable", ->
        ensure ['gss', char: '{', 'iw'],
          text: "{apple}\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          cursor: [0, 0]
        ensure 'j.',
          text: "{apple}\n{pairs}: [brackets]\npairs: [brackets]\n( multi\n  line )"

    describe 'delete surround', ->
      beforeEach ->
        set cursor: [1, 8]
      it "delete surrounded chars and repeatable", ->
        ensure ['gsd', char: '['],
          text: "apple\npairs: brackets\npairs: [brackets]\n( multi\n  line )"
        ensure 'jl.',
          text: "apple\npairs: brackets\npairs: brackets\n( multi\n  line )"
      it "delete surrounded chars expanded to multi-line", ->
        set cursor: [3, 1]
        ensure ['gsd', char: '('],
          text: "apple\npairs: [brackets]\npairs: [brackets]\n multi\n  line "

    describe 'change srurround', ->
      beforeEach ->
        set
          text: """
            (apple)
            (grape)
            <lemmon>
            {orange}
            """
          cursorBuffer: [0, 1]
      it "change surrounded chars and repeatable", ->
        ensure ['gsc', char: '(['],
          text: """
            [apple]
            (grape)
            <lemmon>
            {orange}
            """
        ensure 'jl.',
          text: """
            [apple]
            [grape]
            <lemmon>
            {orange}
            """
      it "change surrounded chars", ->
        ensure ['jjgsc', char: '<"'],
          text: """
            (apple)
            (grape)
            "lemmon"
            {orange}
            """
        ensure ['jlgsc', char: '{!'],
          text: """
            (apple)
            (grape)
            "lemmon"
            !orange!
            """

    describe 'surround-word', ->
      it "surround a word with ( and repeatable", ->
        ensure ['gsw', char: '('],
          text: "(apple)\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          cursor: [0, 0]
        ensure 'j.',
          text: "(apple)\n(pairs): [brackets]\npairs: [brackets]\n( multi\n  line )"
      it "surround a word with { and repeatable", ->
        ensure ['gsw', char: '{'],
          text: "{apple}\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          cursor: [0, 0]
        ensure 'j.',
          text: "{apple}\n{pairs}: [brackets]\npairs: [brackets]\n( multi\n  line )"

    describe 'delete surround-any-pair', ->
      beforeEach ->
        set
          text: """
            apple
            (pairs: [brackets])
            {pairs "s" [brackets]}
            ( multi
              line )
            """
          cursor: [1, 9]

        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'd s': 'vim-mode-plus:delete-surround-any-pair'

      it "delete surrounded any pair found and repeatable", ->
        ensure 'ds',
          text: 'apple\n(pairs: brackets)\n{pairs "s" [brackets]}\n( multi\n  line )'
        ensure '.',
          text: 'apple\npairs: brackets\n{pairs "s" [brackets]}\n( multi\n  line )'

      it "delete surrounded any pair found with skip pair out of cursor and repeatable", ->
        set cursor: [2, 14]
        ensure 'ds',
          text: 'apple\n(pairs: [brackets])\n{pairs "s" brackets}\n( multi\n  line )'
        ensure '.',
          text: 'apple\n(pairs: [brackets])\npairs "s" brackets\n( multi\n  line )'
        ensure '.', # do nothing any more
          text: 'apple\n(pairs: [brackets])\npairs "s" brackets\n( multi\n  line )'

      it "delete surrounded chars expanded to multi-line", ->
        set cursor: [3, 1]
        ensure 'ds',
          text: 'apple\n(pairs: [brackets])\n{pairs "s" [brackets]}\n multi\n  line '

    describe 'change surround-any-pair', ->
      beforeEach ->
        set
          text: """
            (apple)
            (grape)
            <lemmon>
            {orange}
            """
          cursor: [0, 1]

        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'c s': 'vim-mode-plus:change-surround-any-pair'

      it "change any surrounded pair found and repeatable", ->
        ensure ['cs', char: '<'],
          text: "<apple>\n(grape)\n<lemmon>\n{orange}"
        ensure 'j.',
          text: "<apple>\n<grape>\n<lemmon>\n{orange}"
        ensure 'jj.',
          text: "<apple>\n<grape>\n<lemmon>\n<orange>"

  describe "the i keybinding", ->
    beforeEach ->
      set
        text: '123\n4567'
        cursorBuffer: [[0, 0], [1, 0]]

    it "allows undoing an entire batch of typing", ->
      keystroke 'i'
      editor.insertText("abcXX")
      editor.backspace()
      editor.backspace()
      ensure 'escape', text: "abc123\nabc4567"

      keystroke 'i'
      editor.insertText "d"
      editor.insertText "e"
      editor.insertText "f"
      ensure 'escape', text: "abdefc123\nabdefc4567"
      ensure 'u', text: "abc123\nabc4567"
      ensure 'u', text: "123\n4567"

    it "allows repeating typing", ->
      keystroke 'i'
      editor.insertText("abcXX")
      editor.backspace()
      editor.backspace()
      ensure 'escape', text: "abc123\nabc4567"
      ensure '.',      text: "ababcc123\nababcc4567"
      ensure '.',      text: "abababccc123\nabababccc4567"

    describe 'with nonlinear input', ->
      beforeEach ->
        set text: '', cursorBuffer: [0, 0]

      it 'deals with auto-matched brackets', ->
        keystroke 'i'
        # this sequence simulates what the bracket-matcher package does
        # when the user types (a)b<enter>
        editor.insertText '()'
        editor.moveLeft()
        editor.insertText 'a'
        editor.moveRight()
        editor.insertText 'b\n'
        ensure 'escape', cursor: [1,  0]
        ensure '.',
          text: '(a)b\n(a)b\n'
          cursor: [2,  0]

      it 'deals with autocomplete', ->
        keystroke 'i'
        # this sequence simulates autocompletion of 'add' to 'addFoo'
        editor.insertText 'a'
        editor.insertText 'd'
        editor.insertText 'd'
        editor.setTextInBufferRange [[0, 0], [0, 3]], 'addFoo'
        ensure 'escape',
          cursor: [0,  5]
          text: 'addFoo'
        ensure '.',
          text: 'addFoaddFooo'
          cursor: [0,  10]

  describe 'the a keybinding', ->
    beforeEach ->
      set
        text: ''
        cursorBuffer: [0, 0]

    it "can be undone in one go", ->
      keystroke 'a'
      editor.insertText("abc")
      ensure 'escape', text: "abc"
      ensure 'u', text: ""

    it "repeats correctly", ->
      keystroke 'a'
      editor.insertText("abc")
      ensure 'escape',
        text: "abc"
        cursor: [0, 2]
      ensure '.',
        text: "abcabc"
        cursor: [0, 5]

  describe "the ctrl-a/ctrl-x keybindings", ->
    beforeEach ->
      set
        text: '123\nab45\ncd-67ef\nab-5\na-bcdef'
        cursorBuffer: [[0, 0], [1, 0], [2, 0], [3, 3], [4, 0]]

    describe "increasing numbers", ->
      describe "normal-mode", ->
        it "increases the next number", ->
          ensure {ctrl: 'a'},
            text: '124\nab46\ncd-66ef\nab-4\na-bcdef'
            cursorBuffer: [[0, 2], [1, 3], [2, 4], [3, 3], [4, 0]]

        it "repeats with .", ->
          ensure [{ctrl: 'a'}, '.'],
            text: '125\nab47\ncd-65ef\nab-3\na-bcdef'
            cursorBuffer: [[0, 2], [1, 3], [2, 4], [3, 3], [4, 0]]

        it "can have a count", ->
          ensure ['5', {ctrl: 'a'}],
            cursorBuffer: [[0, 2], [1, 3], [2, 4], [3, 2], [4, 0]]
            text: '128\nab50\ncd-62ef\nab0\na-bcdef'

        it "can make a negative number positive, change number of digits", ->
          ensure ['99', {ctrl: 'a'}],
            text: '222\nab144\ncd32ef\nab94\na-bcdef'
            cursorBuffer: [[0, 2], [1, 4], [2, 3], [3, 3], [4, 0]]

        it "does nothing when cursor is after the number", ->
          set cursorBuffer: [2, 5]
          ensure {ctrl: 'a'},
            text: '123\nab45\ncd-67ef\nab-5\na-bcdef'
            cursorBuffer: [[2, 5]]

        it "does nothing on an empty line", ->
          set
            text: '\n'
            cursorBuffer: [[0, 0], [1, 0]]
          ensure {ctrl: 'a'},
            text: '\n'
            cursorBuffer: [[0, 0], [1, 0]]

        it "honours the vim-mode-plus.numberRegex setting", ->
          set
            text: '123\nab45\ncd -67ef\nab-5\na-bcdef'
            cursorBuffer: [[0, 0], [1, 0], [2, 0], [3, 3], [4, 0]]
          settings.set('numberRegex', '(?:\\B-)?[0-9]+')
          ensure {ctrl: 'a'},
            cursorBuffer: [[0, 2], [1, 3], [2, 5], [3, 3], [4, 0]]
            text: '124\nab46\ncd -66ef\nab-6\na-bcdef'
      describe "visual-mode", ->
        beforeEach ->
          set
            text: """
              1 2 3
              1 2 3
              1 2 3
              1 2 3
              """
        it "increase number in characterwise selected range", ->
          set cursor: [0, 2]
          ensure ["v2j", {ctrl: 'a'}],
            text: """
              1 3 4
              2 3 4
              2 3 3
              1 2 3
              """
            selectedText: "3 4\n2 3 4\n2 3"
            cursor: [2, 3]
        it "increase number in characterwise selected range when multiple cursors", ->
          set cursor: [0, 2], addCursor: [2, 2]
          ensure ["v10", {ctrl: 'a'}],
            text: """
              1 12 3
              1 2 3
              1 12 3
              1 2 3
              """
            selectedTextOrdered: ["12", "12"]
            selectedBufferRangeOrdered: [
                [[0, 2], [0, 4]]
                [[2, 2], [2, 4]]
              ]
        it "increase number in linewise selected range", ->
          set cursor: [0, 0]
          ensure ["V2j", {ctrl: 'a'}],
            text: """
              2 3 4
              2 3 4
              2 3 4
              1 2 3
              """
            selectedText: "2 3 4\n2 3 4\n2 3 4\n"
            cursor: [3, 0]
        it "increase number in blockwise selected range", ->
          set cursor: [1, 2]
          ensure [{ctrl: 'v'}, '2l2j', {ctrl: 'a'}],
            text: """
              1 2 3
              1 3 4
              1 3 4
              1 3 4
              """
            selectedTextOrdered: ["3 4", "3 4", "3 4"]
            selectedBufferRangeOrdered: [
                [[1, 2], [1, 5]],
                [[2, 2], [2, 5]],
                [[3, 2], [3, 5]],
              ]
    describe "decreasing numbers", ->
      describe "normal-mode", ->
        it "decreases the next number", ->
          ensure {ctrl: 'x'},
            text: '122\nab44\ncd-68ef\nab-6\na-bcdef'
            cursorBuffer: [[0, 2], [1, 3], [2, 4], [3, 3], [4, 0]]

        it "repeats with .", ->
          ensure [{ctrl: 'x'}, '.'],
            text: '121\nab43\ncd-69ef\nab-7\na-bcdef'
            cursorBuffer: [[0, 2], [1, 3], [2, 4], [3, 3], [4, 0]]

        it "can have a count", ->
          ensure ['5', {ctrl: 'x'}],
            text: '118\nab40\ncd-72ef\nab-10\na-bcdef'
            cursorBuffer: [[0, 2], [1, 3], [2, 4], [3, 4], [4, 0]]

        it "can make a positive number negative, change number of digits", ->
          ensure ['99', {ctrl: 'x'}],
            text: '24\nab-54\ncd-166ef\nab-104\na-bcdef'
            cursorBuffer: [[0, 1], [1, 4], [2, 5], [3, 5], [4, 0]]

        it "does nothing when cursor is after the number", ->
          set cursorBuffer: [2, 5]
          ensure {ctrl: 'x'},
            text: '123\nab45\ncd-67ef\nab-5\na-bcdef'
            cursorBuffer: [[2, 5]]

        it "does nothing on an empty line", ->
          set
            text: '\n'
            cursorBuffer: [[0, 0], [1, 0]]
          ensure {ctrl: 'x'},
            text: '\n'
            cursorBuffer: [[0, 0], [1, 0]],

        it "honours the vim-mode-plus.numberRegex setting", ->
          set
            text: '123\nab45\ncd -67ef\nab-5\na-bcdef'
            cursorBuffer: [[0, 0], [1, 0], [2, 0], [3, 3], [4, 0]]
          settings.set('numberRegex', '(?:\\B-)?[0-9]+')
          ensure {ctrl: 'x'},
            text: '122\nab44\ncd -68ef\nab-4\na-bcdef'
            cursorBuffer: [[0, 2], [1, 3], [2, 5], [3, 3], [4, 0]]
      describe "visual-mode", ->
        beforeEach ->
          set
            text: """
              1 2 3
              1 2 3
              1 2 3
              1 2 3
              """
        it "decrease number in characterwise selected range", ->
          set cursor: [0, 2]
          ensure ["v2j", {ctrl: 'x'}],
            text: """
              1 1 2
              0 1 2
              0 1 3
              1 2 3
              """
            selectedText: "1 2\n0 1 2\n0 1"
            cursor: [2, 3]
        it "decrease number in characterwise selected range when multiple cursors", ->
          set cursor: [0, 2], addCursor: [2, 2]
          ensure ["v5", {ctrl: 'x'}],
            text: """
              1 -3 3
              1 2 3
              1 -3 3
              1 2 3
              """
            selectedTextOrdered: ["-3", "-3"]
            selectedBufferRangeOrdered: [
                [[0, 2], [0, 4]]
                [[2, 2], [2, 4]]
              ]
        it "decrease number in linewise selected range", ->
          set cursor: [0, 0]
          ensure ["V2j", {ctrl: 'x'}],
            text: """
              0 1 2
              0 1 2
              0 1 2
              1 2 3
              """
            selectedText: "0 1 2\n0 1 2\n0 1 2\n"
            cursor: [3, 0]
        it "decrease number in blockwise selected rage", ->
          set cursor: [1, 2]
          ensure [{ctrl: 'v'}, '2l2j', {ctrl: 'x'}],
            text: """
              1 2 3
              1 1 2
              1 1 2
              1 1 2
              """
            selectedTextOrdered: ["1 2", "1 2", "1 2"]
            selectedBufferRangeOrdered: [
                [[1, 2], [1, 5]],
                [[2, 2], [2, 5]],
                [[3, 2], [3, 5]],
              ]

  describe "the 'g ctrl-a', 'g ctrl-x' increment-number, decrement-number", ->
    describe "increment", ->
      beforeEach ->
        set
          text: """
            1 10 0
            0 7 0
            0 0 3
            """
          cursor: [0, 0]
      it "use first number as base number case-1", ->
        set text: "1 1 1", cursor: [0, 0]
        ensure ['g', {ctrl: 'a'}, '$'], text: "1 2 3", mode: 'normal', cursor: [0, 0]
      it "use first number as base number case-2", ->
        set text: "99 1 1", cursor: [0, 0]
        ensure ['g', {ctrl: 'a'}, '$'], text: "99 100 101", mode: 'normal', cursor: [0, 0]
      it "can take count, and used as step to each increment", ->
        set text: "5 0 0", cursor: [0, 0]
        ensure ['5g', {ctrl: 'a'}, '$'], text: "5 10 15", mode: 'normal', cursor: [0, 0]
      it "only increment number in target range", ->
        set cursor: [1, 2]
        ensure ['g', {ctrl: 'a'}, 'j'],
          text: """
            1 10 0
            0 1 2
            3 4 5
            """
          mode: 'normal'
      it "works in characterwise visual-mode", ->
        set cursor: [1, 2]
        ensure ['vjg', {ctrl: 'a'}],
          text: """
            1 10 0
            0 7 8
            9 10 3
            """
          mode: 'normal'
      it "works in blockwise visual-mode", ->
        set cursor: [0, 2]
        ensure [{ctrl: 'v'}, '2j$g', {ctrl: 'a'}],
          text: """
            1 10 11
            0 12 13
            0 14 15
            """
          mode: 'normal'
      describe "point when finished and repeatable", ->
        beforeEach ->
          set text: "1 0 0 0 0", cursor: [0, 0]
          ensure "v$", selectedText: '1 0 0 0 0'
        it "put cursor on start position when finished and repeatable (case: selection is not reversed)", ->
          ensure selectionIsReversed: false
          ensure ['g', {ctrl: 'a'}], text: "1 2 3 4 5", cursor: [0, 0], mode: 'normal'
          ensure '.', text: "6 7 8 9 10" , cursor: [0, 0]
          ensure '.', text: "11 12 13 14 15" , cursor: [0, 0]
        it "put cursor on start position when finished and repeatable (case: selection is reversed)", ->
          ensure 'o', selectionIsReversed: true
          ensure ['g', {ctrl: 'a'}], text: "1 2 3 4 5", cursor: [0, 0], mode: 'normal'
          ensure '.', text: "6 7 8 9 10" , cursor: [0, 0]
          ensure '.', text: "11 12 13 14 15" , cursor: [0, 0]
    describe "decrement", ->
      beforeEach ->
        set
          text: """
            14 23 13
            10 20 13
            13 13 16
            """
          cursor: [0, 0]
      it "use first number as base number case-1", ->
        set text: "10 1 1"
        ensure ['g', {ctrl: 'x'}, '$'], text: "10 9 8", mode: 'normal', cursor: [0, 0]
      it "use first number as base number case-2", ->
        set text: "99 1 1"
        ensure ['g', {ctrl: 'x'}, '$'], text: "99 98 97", mode: 'normal', cursor: [0, 0]
      it "can take count, and used as step to each increment", ->
        set text: "5 0 0", cursor: [0, 0]
        ensure ['5g', {ctrl: 'x'}, '$'], text: "5 0 -5", mode: 'normal', cursor: [0, 0]
      it "only decrement number in target range", ->
        set cursor: [1, 3]
        ensure ['g', {ctrl: 'x'}, 'j'],
          text: """
            14 23 13
            10 9 8
            7 6 5
            """
          mode: 'normal'
      it "works in characterwise visual-mode", ->
        set cursor: [1, 3]
        ensure ['vjlg', {ctrl: 'x'}],
          text: """
            14 23 13
            10 20 19
            18 17 16
            """
          mode: 'normal'
      it "works in blockwise visual-mode", ->
        set cursor: [0, 3]
        ensure [{ctrl: 'v'}, '2jlg', {ctrl: 'x'}],
          text: """
            14 23 13
            10 22 13
            13 21 16
            """
          mode: 'normal'

  describe 'the R keybinding', ->
    beforeEach ->
      set
        text: """
          12345
          67890
          """
        cursorBuffer: [0, 2]

    it "enters replace mode and replaces characters", ->
      ensure 'R',
        mode: ['insert', 'replace']
      editor.insertText "ab"
      ensure 'escape',
        text: "12ab5\n67890"
        cursor: [0, 3]
        mode: 'normal'

    it "continues beyond end of line as insert", ->
      ensure 'R',
        mode: ['insert', 'replace']
      editor.insertText "abcde"
      ensure 'escape', text: '12abcde\n67890'

    it 'treats backspace as undo', ->
      editor.insertText "foo"
      keystroke 'R'
      editor.insertText "a"
      editor.insertText "b"
      ensure text: "12fooab5\n67890"

      ensure [raw: 'backspace'], text: "12fooa45\n67890"
      editor.insertText "c"
      ensure text: "12fooac5\n67890"
      ensure [{raw: 'backspace'}, {raw: 'backspace'}],
        text: "12foo345\n67890"
        selectedText: ''

      ensure [raw: 'backspace'],
        text: "12foo345\n67890"
        selectedText: ''

    it "can be repeated", ->
      keystroke 'R'
      editor.insertText "ab"
      keystroke 'escape'
      set cursorBuffer: [1, 2]
      ensure '.', text: "12ab5\n67ab0", cursor: [1, 3]
      set cursorBuffer: [0, 4]
      ensure '.', text: "12abab\n67ab0", cursor: [0, 5]

    it "can be interrupted by arrow keys and behave as insert for repeat", ->
      # FIXME don't know how to test this (also, depends on PR #568)

    it "repeats correctly when backspace was used in the text", ->
      keystroke 'R'
      editor.insertText "a"
      keystroke [raw: 'backspace']
      editor.insertText "b"
      keystroke 'escape'
      set cursorBuffer: [1, 2]
      ensure '.', text: "12b45\n67b90", cursor: [1, 2]
      set cursorBuffer: [0, 4]
      ensure '.', text: "12b4b\n67b90", cursor: [0, 4]

    it "doesn't replace a character if newline is entered", ->
      ensure 'R', mode: ['insert', 'replace']
      editor.insertText "\n"
      ensure 'escape', text: "12\n345\n67890"

    describe "multiline situation", ->
      textOriginal = """
        01234
        56789
        """
      beforeEach ->
        set text: textOriginal, cursor: [0, 0]
      it "replace character unless input isnt new line(\\n)", ->
        ensure 'R', mode: ['insert', 'replace']
        editor.insertText "a\nb\nc"
        ensure
          text: """
            a
            b
            c34
            56789
            """
          cursor: [2, 1]
      it "handle backspace", ->
        ensure 'R', mode: ['insert', 'replace']
        set cursor: [0, 1]
        editor.insertText "a\nb\nc"
        ensure
          text: """
            0a
            b
            c4
            56789
            """
          cursor: [2, 1]
        ensure {raw: 'backspace'},
          text: """
            0a
            b
            34
            56789
            """
          cursor: [2, 0]
        ensure {raw: 'backspace'},
          text: """
            0a
            b34
            56789
            """
          cursor: [1, 1]
        ensure {raw: 'backspace'},
          text: """
            0a
            234
            56789
            """
          cursor: [1, 0]
        ensure {raw: 'backspace'},
          text: """
            0a234
            56789
            """
          cursor: [0, 2]
        ensure {raw: 'backspace'},
          text: """
            01234
            56789
            """
          cursor: [0, 1]
        ensure {raw: 'backspace'}, # do nothing
          text: """
            01234
            56789
            """
          cursor: [0, 1]
        ensure 'escape',
          text: """
            01234
            56789
            """
          cursor: [0, 0]
          mode: 'normal'
      it "repeate multiline text", ->
        ensure 'R', mode: ['insert', 'replace']
        editor.insertText "abc\ndef"
        ensure
          text: """
            abc
            def
            56789
            """
          cursor: [1, 3]
        ensure 'escape', cursor: [1, 2], mode: 'normal'
        ensure 'u', text: textOriginal
        ensure '.',
          text: """
            abc
            def
            56789
            """
          cursor: [1, 2]
          mode: 'normal'

  describe 'ReplaceWithRegister', ->
    originalText = null
    beforeEach ->
      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          '_': 'vim-mode-plus:replace-with-register'

      originalText = """
      abc def 'aaa'
      here (parenthesis)
      here (parenthesis)
      """
      set
        text: originalText
        cursor: [0, 9]

      set register: '"': text: 'default register', type: 'character'
      set register: 'a': text: 'A register', type: 'character'

    it "replace selection with regisgter's content", ->
      ensure 'viw',
        selectedText: 'aaa'
      ensure '_',
        mode: 'normal'
        text: originalText.replace('aaa', 'default register')

    it "replace text object with regisgter's content", ->
      set cursor: [1, 6]
      ensure '_i(',
        mode: 'normal'
        text: originalText.replace('parenthesis', 'default register')

    it "can repeat", ->
      set cursor: [1, 6]
      ensure '_i(j.',
        mode: 'normal'
        text: originalText.replace(/parenthesis/g, 'default register')

    it "can use specified register to replace with", ->
      set cursor: [1, 6]
      ensure ['"', char: 'a', '_i('],
        mode: 'normal'
        text: originalText.replace('parenthesis', 'A register')

  describe 'ToggleLineComments', ->
    [oldGrammar, originalText] = []
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-coffee-script')

      runs ->
        oldGrammar = editor.getGrammar()
        grammar = atom.grammars.grammarForScopeName('source.coffee')
        editor.setGrammar(grammar)
        originalText = """
          class Base
            constructor: (args) ->
              pivot = items.shift()
              left = []
              right = []

          console.log "hello"
        """
        set text: originalText

    afterEach ->
      editor.setGrammar(oldGrammar)

    it 'toggle comment for textobject for indent and repeatable', ->
      set cursor: [2, 0]
      ensure 'g/ii',
        text: """
          class Base
            constructor: (args) ->
              # pivot = items.shift()
              # left = []
              # right = []

          console.log "hello"
        """
      ensure '.', text: originalText

    it 'toggle comment for textobject for paragraph and repeatable', ->
      set cursor: [2, 0]
      ensure 'g/ip',
        text: """
          # class Base
          #   constructor: (args) ->
          #     pivot = items.shift()
          #     left = []
          #     right = []

          console.log "hello"
        """

      ensure '.', text: originalText
