# Refactoring status: 70%
{getVimState, dispatch, TextData} = require './spec-helper'
settings = require '../lib/settings'
globalState = require '../lib/global-state'

describe "Motion general", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, _vim) ->
      vimState = state # to refer as vimState later.
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = _vim

  afterEach ->
    vimState.activate('reset')

  describe "simple motions", ->
    text = null
    beforeEach ->
      text = new TextData """
        12345
        abcd
        ABCDE\n
        """

      set
        text: text.getRaw()
        cursor: [1, 1]

    describe "the h keybinding", ->
      describe "as a motion", ->
        it "moves the cursor left, but not to the previous line", ->
          ensure 'h', cursor: [1, 0]
          ensure 'h', cursor: [1, 0]

        it "moves the cursor to the previous line if wrapLeftRightMotion is true", ->
          settings.set('wrapLeftRightMotion', true)
          ensure 'hh', cursor: [0, 4]

      describe "as a selection", ->
        it "selects the character to the left", ->
          ensure 'yh',
            cursor: [1, 0]
            register: '"': text: 'a'

    describe "the j keybinding", ->
      it "moves the cursor down, but not to the end of the last line", ->
        ensure 'j', cursor: [2, 1]
        ensure 'j', cursor: [2, 1]

      it "moves the cursor to the end of the line, not past it", ->
        set cursor: [0, 4]
        ensure 'j', cursor: [1, 3]

      it "remembers the column it was in after moving to shorter line", ->
        set cursor: [0, 4]
        ensure 'j', cursor: [1, 3]
        ensure 'j', cursor: [2, 4]

      it "never go past last newline", ->
        ensure '10j', cursor: [2, 1]

      describe "when visual mode", ->
        beforeEach ->
          ensure 'v', cursor: [1, 2], selectedText: 'b'

        it "moves the cursor down", ->
          ensure 'j', cursor: [2, 2], selectedText: "bcd\nAB"

        it "doesn't go over after the last line", ->
          ensure 'j', cursor: [2, 2], selectedText: "bcd\nAB"

        it "keep same column(goalColumn) even after across the empty line", ->
          keystroke 'escape'
          set
            text: """
              abcdefg

              abcdefg
              """
            cursor: [0, 3]
          ensure 'v', cursor: [0, 4]
          ensure 'jj', cursor: [2, 4], selectedText: "defg\n\nabcd"

        # [FIXME] the place of this spec is not appropriate.
        it "original visual line remains when jk across orignal selection", ->
          text = new TextData """
            line0
            line1
            line2\n
            """
          set
            text: text.getRaw()
            cursor: [1, 1]

          ensure 'V', selectedText: text.getLines([1])
          ensure 'j', selectedText: text.getLines([1, 2])
          ensure 'k', selectedText: text.getLines([1])
          ensure 'k', selectedText: text.getLines([0, 1])
          ensure 'j', selectedText: text.getLines([1])
          ensure 'j', selectedText: text.getLines([1, 2])

    describe "the k keybinding", ->
      beforeEach ->
        set cursor: [2, 1]

      it "moves the cursor up", ->
        ensure 'k', cursor: [1, 1]

      it "moves the cursor up and remember column it was in", ->
        set cursor: [2, 4]
        ensure 'k', cursor: [1, 3]
        ensure 'k', cursor: [0, 4]

      it "moves the cursor up, but not to the beginning of the first line", ->
        ensure '10k', cursor: [0, 1]

      describe "when visual mode", ->
        it "keep same column(goalColumn) even after across the empty line", ->
          set
            text: """
              abcdefg

              abcdefg
              """
            cursor: [2, 3]
          ensure 'v', cursor: [2, 4], selectedText: 'd'
          ensure 'kk', cursor: [0, 3], selectedText: "defg\n\nabcd"

    describe "jk in softwrap", ->
      [text] = []

      beforeEach ->
        editor.setSoftWrapped(true)
        editor.setEditorWidthInChars(10)
        editor.setDefaultCharWidth(1)
        text = new TextData """
          1st line of buffer
          2nd line of buffer, Very long line
          3rd line of buffer

          5th line of buffer\n
          """
        set text: text.getRaw(), cursor: [0, 0]

      describe "selection is not reversed", ->
        it "screen position and buffer position is different", ->
          ensure 'j', cursor: [1, 0], cursorBuffer: [0, 9]
          ensure 'j', cursor: [2, 0], cursorBuffer: [1, 0]
          ensure 'j', cursor: [3, 0], cursorBuffer: [1, 9]
          ensure 'j', cursor: [4, 0], cursorBuffer: [1, 20]

        it "jk move selection buffer-line wise", ->
          ensure 'V', selectedText: text.getLines([0..0])
          ensure 'j', selectedText: text.getLines([0..1])
          ensure 'j', selectedText: text.getLines([0..2])
          ensure 'j', selectedText: text.getLines([0..3])
          ensure 'j', selectedText: text.getLines([0..4])
          ensure 'k', selectedText: text.getLines([0..3])
          ensure 'k', selectedText: text.getLines([0..2])
          ensure 'k', selectedText: text.getLines([0..1])
          ensure 'k', selectedText: text.getLines([0..0])
          ensure 'k', selectedText: text.getLines([0..0]) # do nothing

      describe "selection is reversed", ->
        it "screen position and buffer position is different", ->
          ensure 'j', cursor: [1, 0], cursorBuffer: [0, 9]
          ensure 'j', cursor: [2, 0], cursorBuffer: [1, 0]
          ensure 'j', cursor: [3, 0], cursorBuffer: [1, 9]
          ensure 'j', cursor: [4, 0], cursorBuffer: [1, 20]

        it "jk move selection buffer-line wise", ->
          set cursorBuffer: [4, 0]
          ensure 'V', selectedText: text.getLines([4..4])
          ensure 'k', selectedText: text.getLines([3..4])
          ensure 'k', selectedText: text.getLines([2..4])
          ensure 'k', selectedText: text.getLines([1..4])
          ensure 'k', selectedText: text.getLines([0..4])
          ensure 'j', selectedText: text.getLines([1..4])
          ensure 'j', selectedText: text.getLines([2..4])
          ensure 'j', selectedText: text.getLines([3..4])
          ensure 'j', selectedText: text.getLines([4..4])
          ensure 'j', selectedText: text.getLines([4..4]) # do nothing

    describe "the l keybinding", ->
      beforeEach ->
        set cursor: [1, 2]

      it "moves the cursor right, but not to the next line", ->
        ensure 'l', cursor: [1, 3]
        ensure 'l', cursor: [1, 3]

      it "moves the cursor to the next line if wrapLeftRightMotion is true", ->
        settings.set('wrapLeftRightMotion', true)
        ensure 'll', cursor: [2, 0]

      describe "on a blank line", ->
        it "doesn't move the cursor", ->
          set text: "\n\n\n", cursor: [1, 0]
          ensure 'l', cursor: [1, 0]

    describe "move-(up/down)-to-non-blank", ->
      text = null
      beforeEach ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'g k': 'vim-mode-plus:move-up-to-non-blank'
            'g j': 'vim-mode-plus:move-down-to-non-blank'

        text = new TextData """
          0:        01234567890123456789
          1: 345678901234567890123456789
          2:                  0123456789
          3:                  0123456789
          4: 34567890         0123456789
          5:                  0123456789
          6: 34567890         0123456789
          7:                  0123456789\n
          """
        set text: text.getRaw()

      describe "move-up-to-non-blank", ->
        beforeEach ->
          set cursor: [6, 3]
        it "move up to first instance of non-blank-char of same column", ->
          ensure 'gk', cursor: [4, 3]
          ensure 'gk', cursor: [1, 3]
        it "support count", ->
          ensure '2gk', cursor: [1, 3]
        it "won't move up if all upper row is blank", ->
          ensure '10gk', cursor: [1, 3]
        it "operate on linewise when composed with operator", ->
          ensure 'dgk', text: text.getLines([0, 1, 2, 3, 7])
        it "motion is not different from `k` when upper row is non-blank", ->
          set cursor: [6, 20]
          ensure 'gk', cursor: [5, 20]
          ensure 'gk', cursor: [4, 20]
          ensure 'gk', cursor: [3, 20]
          ensure 'gk', cursor: [2, 20]
          ensure 'gk', cursor: [1, 20]

      describe "move-down-to-non-blank", ->
        beforeEach ->
          set cursor: [1, 3]
        it "move down to first instance of non-blank-char of same column", ->
          ensure 'gj', cursor: [4, 3]
          ensure 'gj', cursor: [6, 3]
        it "support count", ->
          ensure '2gj', cursor: [6, 3]
        it "won't move down if all lower row is blank", ->
          ensure '10gj', cursor: [6, 3]
        it "operate on linewise when composed with operator", ->
          ensure 'dgj', text: text.getLines([0, 5, 6, 7])
        it "motion is not different from `j` when lower row is non-blank", ->
          set cursor: [0, 20]
          ensure 'gj', cursor: [1, 20]
          ensure 'gj', cursor: [2, 20]
          ensure 'gj', cursor: [3, 20]
          ensure 'gj', cursor: [4, 20]

  describe "the w keybinding", ->
    beforeEach ->
      set
        text: """
          ab cde1+-
           xyz

          zip
          """

    describe "as a motion", ->
      beforeEach ->
        set cursor: [0, 0]

      it "moves the cursor to the beginning of the next word", ->
        ensure 'w', cursor: [0, 3]
        ensure 'w', cursor: [0, 7]
        ensure 'w', cursor: [1, 1]
        ensure 'w', cursor: [2, 0]
        ensure 'w', cursor: [3, 0]
        ensure 'w', cursor: [3, 2]
        # When the cursor gets to the EOF, it should stay there.
        ensure 'w', cursor: [3, 2]

      it "moves the cursor to the end of the word if last word in file", ->
        set text: 'abc', cursor: [0, 0]
        ensure 'w', cursor: [0, 2]

      it "moves the cursor to beginning of the next word of next line when all remaining text is white space.", ->
        set text: "012   \n  234", cursor: [0, 3]
        ensure 'w', cursor: [1, 2]

      it "moves the cursor to beginning of the next word of next line when cursor is at EOL.", ->
        set text: "\n  234", cursor: [0, 0]
        ensure 'w', cursor: [1, 2]

    describe "when used by Change operator", ->
      beforeEach ->
        set text: "  var1 = 1\n  var2 = 2\n"

      describe "when cursor is on word", ->
        it "not eat whitespace", ->
          set cursor: [0, 3]
          ensure 'cw', text: "  v = 1\n  var2 = 2\n", cursor: [0, 3]

      describe "when cursor is on white space", ->
        it "only eat white space", ->
          set cursor: [0, 0]
          ensure 'cw', text: "var1 = 1\n  var2 = 2\n", cursor: [0, 0]

      describe "when text to EOL is all white space", ->
        it "wont eat new line character", ->
          set text: "abc  \ndef\n", cursor: [0, 3]
          ensure 'cw', text: "abc\ndef\n", cursor: [0, 3]

        it "cant eat new line when count is specified", ->
          set text: "\n\n\n\n\nline6\n", cursor: [0, 0]
          ensure '5cw', text: "\nline6\n", cursor: [0, 0]

    describe "as a selection", ->
      describe "within a word", ->
        it "selects to the end of the word", ->
          set cursor: [0, 0]
          ensure 'yw', register: '"': text: 'ab '

      describe "between words", ->
        it "selects the whitespace", ->
          set cursor: [0, 2]
          ensure 'yw', register: '"': text: ' '

  describe "the W keybinding", ->
    beforeEach ->
      set text: "cde1+- ab \n xyz\n\nzip"

    describe "as a motion", ->
      beforeEach ->
        set cursor: [0, 0]

      it "moves the cursor to the beginning of the next word", ->
        ensure 'W', cursor: [0, 7]
        ensure 'W', cursor: [1, 1]
        ensure 'W', cursor: [2, 0]
        ensure 'W', cursor: [3, 0]

      it "moves the cursor to beginning of the next word of next line when all remaining text is white space.", ->
        set text: "012   \n  234", cursor: [0, 3]
        ensure 'W', cursor: [1, 2]

      it "moves the cursor to beginning of the next word of next line when cursor is at EOL.", ->
        set text: "\n  234", cursor: [0, 0]
        ensure 'W', cursor: [1, 2]

    # This spec is redundant since W(MoveToNextWholeWord) is child of w(MoveToNextWord).
    describe "when used by Change operator", ->
      beforeEach ->
        set text: "  var1 = 1\n  var2 = 2\n"

      describe "when cursor is on word", ->
        it "not eat whitespace", ->
          set cursor: [0, 3]
          ensure 'cW', text: "  v = 1\n  var2 = 2\n", cursor: [0, 3]

      describe "when cursor is on white space", ->
        it "only eat white space", ->
          set cursor: [0, 0]
          ensure 'cW', text: "var1 = 1\n  var2 = 2\n", cursor: [0, 0]

      describe "when text to EOL is all white space", ->
        it "wont eat new line character", ->
          set text: "abc  \ndef\n", cursor: [0, 3]
          ensure 'cW', text: "abc\ndef\n", cursor: [0, 3]

        it "cant eat new line when count is specified", ->
          set text: "\n\n\n\n\nline6\n", cursor: [0, 0]
          ensure '5cW', text: "\nline6\n", cursor: [0, 0]

    describe "as a selection", ->
      describe "within a word", ->
        it "selects to the end of the whole word", ->
          set cursor: [0, 0]
          ensure 'yW', register: '"': text: 'cde1+- '

      it "continues past blank lines", ->
        set cursor: [2, 0]
        ensure 'dW',
          text: "cde1+- ab \n xyz\nzip"
          register: '"': text: "\n"

      it "doesn't go past the end of the file", ->
        set cursor: [3, 0]
        ensure 'dW',
          text: "cde1+- ab \n xyz\n\n"
          register: '"': text: 'zip'

  describe "the e keybinding", ->
    beforeEach ->
      set text: "ab cde1+- \n xyz\n\nzip"

    describe "as a motion", ->
      beforeEach ->
        set cursor: [0, 0]

      it "moves the cursor to the end of the current word", ->
        ensure 'e', cursor: [0, 1]
        ensure 'e', cursor: [0, 6]
        ensure 'e', cursor: [0, 8]
        ensure 'e', cursor: [1, 3]
        ensure 'e', cursor: [3, 2]

    describe "as selection", ->
      describe "within a word", ->
        it "selects to the end of the current word", ->
          set cursor: [0, 0]
          ensure 'ye', register: '"': text: 'ab'

      describe "between words", ->
        it "selects to the end of the next word", ->
          set cursor: [0, 2]
          ensure 'ye', register: '"': text: ' cde1'

  describe "the E keybinding", ->
    beforeEach ->
      set text: "ab  cde1+- \n xyz \n\nzip\n"

    describe "as a motion", ->
      beforeEach ->
        set cursor: [0, 0]

      it "moves the cursor to the end of the current word", ->
        ensure 'E', cursor: [0, 1]
        ensure 'E', cursor: [0, 9]
        ensure 'E', cursor: [1, 3]
        ensure 'E', cursor: [3, 2]
        ensure 'E', cursor: [3, 2]

    describe "as selection", ->
      describe "within a word", ->
        it "selects to the end of the current word", ->
          set cursor: [0, 0]
          ensure 'yE', register: '"': text: 'ab'

      describe "between words", ->
        it "selects to the end of the next word", ->
          set cursor: [0, 2]
          ensure 'yE', register: '"': text: '  cde1+-'

      describe "press more than once", ->
        it "selects to the end of the current word", ->
          set cursor: [0, 0]
          ensure 'vEEy', register: '"': text: 'ab  cde1+-'

  describe "the } keybinding", ->
    beforeEach ->
      set
        text: "abcde\n\nfghij\nhijk\n  xyz  \n\nzip\n\n  \nthe end"
        cursor: [0, 0]

    describe "as a motion", ->
      it "moves the cursor to the end of the paragraph", ->
        ensure '}', cursor: [1, 0]
        ensure '}', cursor: [5, 0]
        ensure '}', cursor: [7, 0]
        ensure '}', cursor: [9, 6]

    describe "as a selection", ->
      it 'selects to the end of the current paragraph', ->
        ensure 'y}', register: '"': text: "abcde\n"

  describe "the { keybinding", ->
    beforeEach ->
      set
        text: "abcde\n\nfghij\nhijk\n  xyz  \n\nzip\n\n  \nthe end"
        cursor: [9, 0]

    describe "as a motion", ->
      it "moves the cursor to the beginning of the paragraph", ->
        ensure '{', cursor: [7, 0]
        ensure '{', cursor: [5, 0]
        ensure '{', cursor: [1, 0]
        ensure '{', cursor: [0, 0]

    describe "as a selection", ->
      it 'selects to the beginning of the current paragraph', ->
        set cursor: [7, 0]
        ensure 'y{', register: '"': text: "\nzip\n"

  describe "the b keybinding", ->
    beforeEach ->
      set text: " ab cde1+- \n xyz\n\nzip }\n last"

    describe "as a motion", ->
      beforeEach ->
        set cursor: [4, 1]

      it "moves the cursor to the beginning of the previous word", ->
        ensure 'b', cursor: [3, 4]
        ensure 'b', cursor: [3, 0]
        ensure 'b', cursor: [2, 0]
        ensure 'b', cursor: [1, 1]
        ensure 'b', cursor: [0, 8]
        ensure 'b', cursor: [0, 4]
        ensure 'b', cursor: [0, 1]

        # Go to start of the file, after moving past the first word
        ensure 'b', cursor: [0, 0]
        # Stay at the start of the file
        ensure 'b', cursor: [0, 0]

    describe "as a selection", ->
      describe "within a word", ->
        it "selects to the beginning of the current word", ->
          set cursor: [0, 2]
          ensure 'yb', cursor: [0, 1], register: '"': text: 'a'

      describe "between words", ->
        it "selects to the beginning of the last word", ->
          set cursor: [0, 4]
          ensure 'yb', cursor: [0, 1], register: '"': text: 'ab '

  describe "the B keybinding", ->
    beforeEach ->
      set
        text: """
          cde1+- ab
          \t xyz-123

           zip
          """

    describe "as a motion", ->
      beforeEach ->
        set cursor: [4, 1]

      it "moves the cursor to the beginning of the previous word", ->
        ensure 'B', cursor: [3, 1]
        ensure 'B', cursor: [2, 0]
        ensure 'B', cursor: [1, 3]
        ensure 'B', cursor: [0, 7]
        ensure 'B', cursor: [0, 0]

    describe "as a selection", ->
      it "selects to the beginning of the whole word", ->
        set cursor: [1, 9]
        ensure 'yB', register: '"': text: 'xyz-12' # because cursor is on the `3`

      it "doesn't go past the beginning of the file", ->
        set cursor: [0, 0], register: '"': text: 'abc'
        ensure 'yB', register: '"': text: 'abc'

  describe "the ^ keybinding", ->
    beforeEach ->
      set text: "  abcde"

    describe "from the beginning of the line", ->
      beforeEach ->
        set cursor: [0, 0]

      describe "as a motion", ->
        it "moves the cursor to the first character of the line", ->
          ensure '^', cursor: [0, 2]

      describe "as a selection", ->
        it 'selects to the first character of the line', ->
          ensure 'd^', text: 'abcde', cursor: [0, 0]

    describe "from the first character of the line", ->
      beforeEach ->
        set cursor: [0, 2]

      describe "as a motion", ->
        it "stays put", ->
          ensure '^', cursor: [0, 2]

      describe "as a selection", ->
        it "does nothing", ->
          ensure 'd^', text: '  abcde', cursor: [0, 2]

    describe "from the middle of a word", ->
      beforeEach ->
        set cursor: [0, 4]

      describe "as a motion", ->
        it "moves the cursor to the first character of the line", ->
          ensure '^', cursor: [0, 2]

      describe "as a selection", ->
        it 'selects to the first character of the line', ->
          ensure 'd^', text: '  cde', cursor: [0, 2],

  describe "the 0 keybinding", ->
    beforeEach ->
      set text: "  abcde", cursor: [0, 4]

    describe "as a motion", ->
      it "moves the cursor to the first column", ->
        ensure '0', cursor: [0, 0]

    describe "as a selection", ->
      it 'selects to the first column of the line', ->
        ensure 'd0', text: 'cde', cursor: [0, 0]

  describe "the $ keybinding", ->
    beforeEach ->
      set
        text: "  abcde\n\n1234567890"
        cursor: [0, 4]

    describe "as a motion from empty line", ->
      it "moves the cursor to the end of the line", ->
        set cursor: [1, 0]
        ensure '$', cursor: [1, 0]

    describe "as a motion", ->
      beforeEach -> keystroke '$'

      # FIXME: See atom/vim-mode#2
      it "moves the cursor to the end of the line", ->
        ensure '$', cursor: [0, 6]

      it "should remain in the last column when moving down", ->
        ensure '$j', cursor: [1, 0]
        ensure 'j', cursor: [2, 9]

    describe "as a selection", ->
      it "selects to the beginning of the lines", ->
        ensure 'd$',
          text: "  ab\n\n1234567890"
          cursor: [0, 3]

  describe "the 0 keybinding", ->
    beforeEach ->
      set text: "  a\n", cursor: [0, 2],

    describe "as a motion", ->
      it "moves the cursor to the beginning of the line", ->
        ensure '0', cursor: [0, 0]

  describe "the - keybinding", ->
    beforeEach ->
      set text: """
        abcdefg
          abc
          abc\n
        """

    describe "from the middle of a line", ->
      beforeEach ->
        set cursor: [1, 3]

      describe "as a motion", ->
        it "moves the cursor to the last character of the previous line", ->
          ensure '-', cursor: [0, 0]

      describe "as a selection", ->
        it "deletes the current and previous line", ->
          ensure 'd-', text: "  abc\n", cursor: [0, 2]

    describe "from the first character of a line indented the same as the previous one", ->
      beforeEach ->
        set cursor: [2, 2]

      describe "as a motion", ->
        it "moves to the first character of the previous line (directly above)", ->
          ensure '-', cursor: [1, 2]

      describe "as a selection", ->
        it "selects to the first character of the previous line (directly above)", ->
          ensure 'd-', text: "abcdefg\n"
          # commented out because the column is wrong due to a bug in `k`; re-enable when `k` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    describe "from the beginning of a line preceded by an indented line", ->
      beforeEach ->
        set cursor: [2, 0]

      describe "as a motion", ->
        it "moves the cursor to the first character of the previous line", ->
          ensure '-', cursor: [1, 2]

      describe "as a selection", ->
        it "selects to the first character of the previous line", ->
          ensure 'd-', text: "abcdefg\n"
          # commented out because the column is wrong due to a bug in `k`; re-enable when `k` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    describe "with a count", ->
      beforeEach ->
        set
          text: "1\n2\n3\n4\n5\n6\n"
          cursor: [4, 0]

      describe "as a motion", ->
        it "moves the cursor to the first character of that many lines previous", ->
          ensure '3-', cursor: [1, 0]

      describe "as a selection", ->
        it "deletes the current line plus that many previous lines", ->
          ensure 'd3-',
            text: "1\n6\n",
            cursor: [1, 0],

  describe "the + keybinding", ->
    beforeEach ->
      set text: "  abc\n  abc\nabcdefg\n"

    describe "from the middle of a line", ->
      beforeEach ->
        set cursor: [1, 3]

      describe "as a motion", ->
        it "moves the cursor to the first character of the next line", ->
          ensure '+', cursor: [2, 0]

      describe "as a selection", ->
        it "deletes the current and next line", ->
          ensure 'd+', text: "  abc\n"
          # commented out because the column is wrong due to a bug in `j`; re-enable when `j` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [0, 3]

    describe "from the first character of a line indented the same as the next one", ->
      beforeEach -> set cursor: [0, 2]

      describe "as a motion", ->
        it "moves to the first character of the next line (directly below)", ->
          ensure '+', cursor: [1, 2]

      describe "as a selection", ->
        it "selects to the first character of the next line (directly below)", ->
          ensure 'd+', text: "abcdefg\n"
          # commented out because the column is wrong due to a bug in `j`; re-enable when `j` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    describe "from the beginning of a line followed by an indented line", ->
      beforeEach -> set cursor: [0, 0]

      describe "as a motion", ->
        it "moves the cursor to the first character of the next line", ->
          ensure '+', cursor: [1, 2]

      describe "as a selection", ->
        it "selects to the first character of the next line", ->
          ensure 'd+',
            text: "abcdefg\n"
            cursor: [0, 0]

    describe "with a count", ->
      beforeEach ->
        set
          text: "1\n2\n3\n4\n5\n6\n"
          cursor: [1, 0]

      describe "as a motion", ->
        it "moves the cursor to the first character of that many lines following", ->
          ensure '3+', cursor: [4, 0]

      describe "as a selection", ->
        it "deletes the current line plus that many following lines", ->
          ensure 'd3+',
            text: "1\n6\n"
            cursor: [1, 0]

  describe "the _ keybinding", ->
    beforeEach ->
      set text: "  abc\n  abc\nabcdefg\n"

    describe "from the middle of a line", ->
      beforeEach -> set cursor: [1, 3]

      describe "as a motion", ->
        it "moves the cursor to the first character of the current line", ->
          ensure '_', cursor: [1, 2]

      describe "as a selection", ->
        it "deletes the current line", ->
          ensure 'd_',
            text: "  abc\nabcdefg\n"
            cursor: [1, 0]

    describe "with a count", ->
      beforeEach ->
        set
          text: "1\n2\n3\n4\n5\n6\n"
          cursor: [1, 0]

      describe "as a motion", ->
        it "moves the cursor to the first character of that many lines following", ->
          ensure '3_', cursor: [3, 0]

      describe "as a selection", ->
        it "deletes the current line plus that many following lines", ->
          ensure 'd3_',
            text: "1\n5\n6\n"
            cursor: [1, 0]

  describe "the enter keybinding", ->
    # [FIXME] Dirty test, whats this!?
    keydownCodeForEnter = '\r' # 'enter' does not work
    startingText = "  abc\n  abc\nabcdefg\n"

    describe "from the middle of a line", ->
      startingCursorPosition = [1, 3]

      describe "as a motion", ->
        it "acts the same as the + keybinding", ->
          # do it with + and save the results
          set
            text: startingText
            cursor: startingCursorPosition
          keystroke '+'
          referenceCursorPosition = editor.getCursorScreenPosition()
          set
            text: startingText
            cursor: startingCursorPosition
          ensure keydownCodeForEnter,
            cursor: referenceCursorPosition

      describe "as a selection", ->
        it "acts the same as the + keybinding", ->
          # do it with + and save the results
          set
            text: startingText
            cursor: startingCursorPosition

          keystroke 'd+'
          referenceText = editor.getText()
          referenceCursorPosition = editor.getCursorScreenPosition()

          set
            text: startingText
            cursor: startingCursorPosition
          ensure ['d', keydownCodeForEnter],
            text: referenceText
            cursor: referenceCursorPosition

  describe "the gg keybinding", ->
    beforeEach ->
      set
        text: """
           1abc
           2
          3\n
          """
        cursor: [0, 2]

    describe "as a motion", ->
      describe "in normal mode", ->
        it "moves the cursor to the beginning of the first line", ->
          set cursor: [2, 0]
          ensure 'gg', cursor: [0, 1]

        it "move to same position if its on first line and first char", ->
          ensure 'gg', cursor: [0, 1]

      describe "in linewise visual mode", ->
        it "selects to the first line in the file", ->
          set cursor: [1, 0]
          ensure 'Vgg',
            selectedText: " 1abc\n 2\n"
            cursor: [0, 0]

      describe "in characterwise visual mode", ->
        beforeEach ->
          set cursor: [1, 1]
        it "selects to the first line in the file", ->
          ensure 'vgg',
            selectedText: "1abc\n 2"
            cursor: [0, 1]

    describe "when count specified", ->
      describe "in normal mode", ->
        it "moves the cursor to first char of a specified line", ->
          ensure '2gg', cursor: [1, 1]

      describe "in linewise visual motion", ->
        it "selects to a specified line", ->
          set cursor: [2, 0]
          ensure 'V2gg',
            selectedText: " 2\n3\n"
            cursor: [1, 0]

      describe "in characterwise visual motion", ->
        it "selects to a first character of specified line", ->
          set cursor: [2, 0]
          ensure 'v2gg',
            selectedText: "2\n3"
            cursor: [1, 1]

  describe "the g_ keybinding", ->
    beforeEach ->
      set text: "1  \n    2  \n 3abc\n "

    describe "as a motion", ->
      it "moves the cursor to the last nonblank character", ->
        set cursor: [1, 0]
        ensure 'g_', cursor: [1, 4]

      it "will move the cursor to the beginning of the line if necessary", ->
        set cursor: [0, 2]
        ensure 'g_', cursor: [0, 0]

    describe "as a repeated motion", ->
      it "moves the cursor downward and outward", ->
        set cursor: [0, 0]
        ensure '2g_', cursor: [1, 4]

    describe "as a selection", ->
      it "selects the current line excluding whitespace", ->
        set cursor: [1, 2]
        ensure 'v2g_',
          selectedText: "  2  \n 3abc"

  describe "the G keybinding", ->
    beforeEach ->
      set
        text: "1\n    2\n 3abc\n "
        cursor: [0, 2]

    describe "as a motion", ->
      it "moves the cursor to the last line after whitespace", ->
        ensure 'G', cursor: [3, 0]

    describe "as a repeated motion", ->
      it "moves the cursor to a specified line", ->
        ensure '2G', cursor: [1, 4]

    describe "as a selection", ->
      it "selects to the last line in the file", ->
        set cursor: [1, 0]
        ensure 'vG',
          selectedText: "    2\n 3abc\n "
          cursor: [3, 1]

  describe "the N% keybinding", ->
    beforeEach ->
      set
        text: [0..99].join("\n")
        cursor: [0, 0]

    describe "put cursor on line specified by percent", ->
      it "50%", -> ensure '50%', cursor: [49, 0]
      it "30%", -> ensure '30%', cursor: [29, 0]
      it "100%", -> ensure '100%', cursor: [99, 0]
      it "120%", -> ensure '120%', cursor: [99, 0]

  describe "the H, M, L keybinding", ->
    [eel] = []
    beforeEach ->
      eel = editorElement
      set
        text: """
            1
          2
          3
          4
            5
          6
          7
          8
          9
            10
          """
        cursor: [8, 0]

    describe "the H keybinding", ->
      it "moves the cursor to the non-blank-char on first row if visible", ->
        spyOn(eel, 'getFirstVisibleScreenRow').andReturn(0)
        ensure 'H', cursor: [0, 2]

      it "moves the cursor to the non-blank-char on first visible row plus scroll offset", ->
        spyOn(eel, 'getFirstVisibleScreenRow').andReturn(2)
        ensure 'H', cursor: [4, 2]

      it "respects counts", ->
        spyOn(eel, 'getFirstVisibleScreenRow').andReturn(0)
        ensure '4H', cursor: [3, 0]

    describe "the L keybinding", ->
      it "moves the cursor to non-blank-char on last row if visible", ->
        spyOn(eel, 'getLastVisibleScreenRow').andReturn(9)
        ensure 'L', cursor: [9, 2]

      it "moves the cursor to the first visible row plus offset", ->
        spyOn(eel, 'getLastVisibleScreenRow').andReturn(6)
        ensure 'L', cursor: [4, 2]

      it "respects counts", ->
        spyOn(eel, 'getLastVisibleScreenRow').andReturn(9)
        ensure '3L', cursor: [7, 0]

    describe "the M keybinding", ->
      beforeEach ->
        spyOn(eel, 'getFirstVisibleScreenRow').andReturn(0)
        spyOn(editor, 'getRowsPerPage').andReturn(10)

      it "moves the cursor to the non-blank-char of middle of screen", ->
        ensure 'M', cursor: [4, 2]

  describe 'the mark keybindings', ->
    beforeEach ->
      set
        text: '  12\n    34\n56\n'
        cursor: [0, 1]

    it 'moves to the beginning of the line of a mark', ->
      set cursor: [1, 1]
      keystroke ['m', char: 'a']
      set cursor: [0, 0]
      ensure ["'", char: 'a'], cursor: [1, 4]

    it 'moves literally to a mark', ->
      set cursorBuffer: [1, 1]
      keystroke ['m', char: 'a']
      set cursorBuffer: [0, 0]
      ensure ['`', char: 'a'], cursorBuffer: [1, 1]

    it 'deletes to a mark by line', ->
      set cursorBuffer: [1, 5]
      keystroke ['m', char: 'a']
      set cursorBuffer: [0, 0]
      ensure ["d'", char: 'a'], text: '56\n'

    it 'deletes before to a mark literally', ->
      set cursorBuffer: [1, 5]
      keystroke ['m', char: 'a']
      set cursorBuffer: [0, 1]
      ensure ['d`', char: 'a'], text: ' 4\n56\n'

    it 'deletes after to a mark literally', ->
      set cursorBuffer: [1, 5]
      keystroke ['m', char: 'a']
      set cursorBuffer: [2, 1]
      ensure ['d`', char: 'a'], text: '  12\n    36\n'

    it 'moves back to previous', ->
      set cursorBuffer: [1, 5]
      keystroke ['`', char: '`']
      set cursorBuffer: [2, 1]
      ensure ['`', char: '`'], cursorBuffer: [1, 5]

  describe 'the V keybinding', ->
    [text] = []
    beforeEach ->
      text = new TextData """
        01
        002
        0003
        00004
        000005\n
        """
      set
        text: text.getRaw()
        cursor: [1, 1]

    it "selects down a line", ->
      ensure 'Vjj', selectedText: text.getLines([1..3])

    it "selects up a line", ->
      ensure 'Vk', selectedText: text.getLines([0..1])

  describe 'MoveTo(Previous|Next)Fold(Start|End)', ->
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-coffee-script')
      getVimState 'sample.coffee', (state, vim) ->
        {editor, editorElement} = state
        {set, ensure, keystroke} = vim

      runs ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            '[ [': 'vim-mode-plus:move-to-previous-fold-start'
            '] [': 'vim-mode-plus:move-to-next-fold-start'
            '[ ]': 'vim-mode-plus:move-to-previous-fold-end'
            '] ]': 'vim-mode-plus:move-to-next-fold-end'

    afterEach ->
      atom.packages.deactivatePackage('language-coffee-script')

    describe "MoveToPreviousFoldStart", ->
      beforeEach ->
        set cursor: [30, 0]
      it "move to first char of previous fold start row", ->
        ensure '[[', cursor: [22, 6]
        ensure '[[', cursor: [20, 6]
        ensure '[[', cursor: [18, 4]
        ensure '[[', cursor: [9, 2]
        ensure '[[', cursor: [8, 0]

    describe "MoveToNextFoldStart", ->
      beforeEach ->
        set cursor: [0, 0]
      it "move to first char of next fold start row", ->
        ensure '][', cursor: [8, 0]
        ensure '][', cursor: [9, 2]
        ensure '][', cursor: [18, 4]
        ensure '][', cursor: [20, 6]
        ensure '][', cursor: [22, 6]

    describe "MoveToPrevisFoldEnd", ->
      beforeEach ->
        set cursor: [30, 0]
      it "move to first char of previous fold end row", ->
        ensure '[]', cursor: [28, 2]
        ensure '[]', cursor: [25, 4]
        ensure '[]', cursor: [23, 8]
        ensure '[]', cursor: [21, 8]

    describe "MoveToNextFoldEnd", ->
      beforeEach ->
        set cursor: [0, 0]
      it "move to first char of next fold end row", ->
        ensure ']]', cursor: [21, 8]
        ensure ']]', cursor: [23, 8]
        ensure ']]', cursor: [25, 4]
        ensure ']]', cursor: [28, 2]
