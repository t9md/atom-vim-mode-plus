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
    vimState.resetNormalMode()

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

    describe "move-(up/down)-to-edge", ->
      text = null
      beforeEach ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'g k': 'vim-mode-plus:move-up-to-edge'
            'g j': 'vim-mode-plus:move-down-to-edge'

        text = new TextData """
          0:  4 67  01234567890123456789
          1:         1234567890123456789
          2:    6 890         0123456789
          3:    6 890         0123456789
          4:   56 890         0123456789
          5:                  0123456789
          6:                  0123456789
          7:  4 67            0123456789\n
          """
        set text: text.getRaw(), cursor: [4, 3]

      it "desn't move if it can't find edge", ->
        ensure 'gk', cursor: [4, 3]
        ensure 'gj', cursor: [4, 3]
      it "move to non-blank-char on both first and last row", ->
        set cursor: [4, 4]
        ensure 'gk', cursor: [0, 4]
        ensure 'gj', cursor: [7, 4]
      it "move to white space char when both side column is non-blank char", ->
        set cursor: [4, 5]
        ensure 'gk', cursor: [0, 5]
        ensure 'gj', cursor: [4, 5]
        ensure 'gj', cursor: [7, 5]
      it "only stops on row one of [first row, last row, up-or-down-row is blank] case-1", ->
        set cursor: [4, 6]
        ensure 'gk', cursor: [2, 6]
        ensure 'gk', cursor: [0, 6]
        ensure 'gj', cursor: [2, 6]
        ensure 'gj', cursor: [4, 6]
        ensure 'gj', cursor: [7, 6]
      it "only stops on row one of [first row, last row, up-or-down-row is blank] case-2", ->
        set cursor: [4, 7]
        ensure 'gk', cursor: [2, 7]
        ensure 'gk', cursor: [0, 7]
        ensure 'gj', cursor: [2, 7]
        ensure 'gj', cursor: [4, 7]
        ensure 'gj', cursor: [7, 7]
      it "support count", ->
        set cursor: [4, 6]
        ensure '2gk', cursor: [0, 6]
        ensure '3gj', cursor: [7, 6]

      describe 'editor for hardTab', ->
        pack = 'language-go'
        beforeEach ->
          waitsForPromise ->
            atom.packages.activatePackage(pack)

          getVimState 'sample.go', (state, vimEditor) ->
            {editor, editorElement} = state
            {set, ensure, keystroke} = vimEditor

          runs ->
            set cursor: [8, 2]
            # In hardTab indent bufferPosition is not same as screenPosition
            ensure cursorBuffer: [8, 1]

        afterEach ->
          atom.packages.deactivatePackage(pack)

        it "move up/down to next edge of same *screen* column", ->
          ensure 'gk', cursor: [5, 2]
          ensure 'gk', cursor: [3, 2]
          ensure 'gk', cursor: [2, 2]
          ensure 'gk', cursor: [0, 2]

          ensure 'gj', cursor: [2, 2]
          ensure 'gj', cursor: [3, 2]
          ensure 'gj', cursor: [5, 2]
          ensure 'gj', cursor: [9, 2]
          ensure 'gj', cursor: [11, 2]
          ensure 'gj', cursor: [14, 2]
          ensure 'gj', cursor: [17, 2]

          ensure 'gk', cursor: [14, 2]
          ensure 'gk', cursor: [11, 2]
          ensure 'gk', cursor: [9, 2]
          ensure 'gk', cursor: [5, 2]
          ensure 'gk', cursor: [3, 2]
          ensure 'gk', cursor: [2, 2]
          ensure 'gk', cursor: [0, 2]


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

      it "skips whitespace until EOF", ->
        set
          text: "012\n\n\n012\n\n"
          cursor: [0, 0]
        ensure 'e', cursor: [0, 2]
        ensure 'e', cursor: [3, 2]
        ensure 'e', cursor: [4, 0]

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

  describe "the {,} keybinding", ->
    beforeEach ->
      set
        text: """



        3: paragraph-1
        4: paragraph-1



        8: paragraph-2



        12: paragraph-3
        13: paragraph-3


        16: paragprah-4\n
        """
        cursor: [0, 0]

    describe "as a motion", ->
      it "moves the cursor to the end of the paragraph", ->
        set cursor: [0, 0]
        ensure '}', cursor: [5, 0]
        ensure '}', cursor: [9, 0]
        ensure '}', cursor: [14, 0]
        ensure '{', cursor: [11, 0]
        ensure '{', cursor: [7, 0]
        ensure '{', cursor: [2, 0]

      it "support count", ->
        set cursor: [0, 0]
        ensure '3}', cursor: [14, 0]
        ensure '3{', cursor: [2, 0]

      it "can move start of buffer or end of buffer at maximum", ->
        set cursor: [0, 0]
        ensure '10}', cursor: [16, 14]
        ensure '10{', cursor: [0, 0]

    describe "as a selection", ->
      it 'selects to the end of the current paragraph', ->
        set cursor: [3, 3]
        ensure 'y}', register: '"': text: "paragraph-1\n4: paragraph-1\n"
      it 'selects to the end of the current paragraph', ->
        set cursor: [4, 3]
        ensure 'y{', register: '"': text: "\n3: paragraph-1\n4: "

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

  describe "the | keybinding", ->
    beforeEach ->
      set text: "  abcde", cursor: [0, 4]

    describe "as a motion", ->
      it "moves the cursor to the number column", ->
        ensure '|', cursor: [0, 0]
        ensure '1|', cursor: [0, 0]
        ensure '3|', cursor: [0, 2]
        ensure '4|', cursor: [0, 3]

    describe "as operator's target", ->
      it 'behave exclusively', ->
        set cursor: [0, 0]
        ensure 'd4|', text: 'bcde', cursor: [0, 0]

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
      # FIXME: See atom/vim-mode#2
      it "moves the cursor to the end of the line", ->
        ensure '$', cursor: [0, 6]

      it "set goalColumn Infinity", ->
        expect(editor.getLastCursor().goalColumn).toBe(null)
        ensure '$', cursor: [0, 6]
        expect(editor.getLastCursor().goalColumn).toBe(Infinity)

      it "should remain in the last column when moving down", ->
        ensure '$j', cursor: [1, 0]
        ensure 'j', cursor: [2, 9]

      it "support count", ->
        ensure '3$', cursor: [2, 9]

    describe "as a selection", ->
      it "selects to the end of the lines", ->
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
        spyOn(editor, 'getLastVisibleScreenRow').andReturn(9)
        ensure 'L', cursor: [9, 2]

      it "moves the cursor to the first visible row plus offset", ->
        spyOn(editor, 'getLastVisibleScreenRow').andReturn(7)
        ensure 'L', cursor: [4, 2]

      it "respects counts", ->
        spyOn(editor, 'getLastVisibleScreenRow').andReturn(9)
        ensure '3L', cursor: [7, 0]

    describe "the M keybinding", ->
      beforeEach ->
        spyOn(eel, 'getFirstVisibleScreenRow').andReturn(0)
        spyOn(editor, 'getLastVisibleScreenRow').andReturn(10)

      it "moves the cursor to the non-blank-char of middle of screen", ->
        ensure 'M', cursor: [4, 2]

  describe 'the mark keybindings', ->
    beforeEach ->
      set
        text: '  12\n    34\n56\n'
        cursor: [0, 1]

    it 'moves to the beginning of the line of a mark', ->
      set cursor: [1, 1]
      keystroke 'ma'
      set cursor: [0, 0]
      ensure "'a", cursor: [1, 4]

    it 'moves literally to a mark', ->
      set cursorBuffer: [1, 1]
      keystroke 'ma'
      set cursorBuffer: [0, 0]
      ensure '`a', cursorBuffer: [1, 1]

    it 'deletes to a mark by line', ->
      set cursorBuffer: [1, 5]
      keystroke 'ma'
      set cursorBuffer: [0, 0]
      ensure "d'a", text: '56\n'

    it 'deletes before to a mark literally', ->
      set cursorBuffer: [1, 5]
      keystroke 'ma'
      set cursorBuffer: [0, 1]
      ensure 'd`a', text: ' 4\n56\n'

    it 'deletes after to a mark literally', ->
      set cursorBuffer: [1, 5]
      keystroke 'ma'
      set cursorBuffer: [2, 1]
      ensure 'd`a', text: '  12\n    36\n'

    it 'moves back to previous', ->
      set cursorBuffer: [1, 5]
      keystroke '``'
      set cursorBuffer: [2, 1]
      ensure '``', cursorBuffer: [1, 5]

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

  describe 'MoveTo(Previous|Next)String', ->
    beforeEach ->
      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          'g s': 'vim-mode-plus:move-to-next-string'
          'g S': 'vim-mode-plus:move-to-previous-string'

    describe 'editor for softTab', ->
      pack = 'language-coffee-script'
      beforeEach ->
        waitsForPromise ->
          atom.packages.activatePackage(pack)

        runs ->
          set
            text: """
            disposable?.dispose()
            disposable = atom.commands.add 'atom-workspace',
              'check-up': -> fun('backward')
              'check-down': -> fun('forward')
            \n
            """
            grammar: 'source.coffee'

      afterEach ->
        atom.packages.deactivatePackage(pack)

      it "move to next string", ->
        set cursor: [0, 0]
        ensure 'gs', cursor: [1, 31]
        ensure 'gs', cursor: [2, 2]
        ensure 'gs', cursor: [2, 21]
        ensure 'gs', cursor: [3, 2]
        ensure 'gs', cursor: [3, 23]
      it "move to previous string", ->
        set cursor: [4, 0]
        ensure 'gS', cursor: [3, 23]
        ensure 'gS', cursor: [3, 2]
        ensure 'gS', cursor: [2, 21]
        ensure 'gS', cursor: [2, 2]
        ensure 'gS', cursor: [1, 31]
      it "support count", ->
        set cursor: [0, 0]
        ensure '3gs', cursor: [2, 21]
        ensure '3gS', cursor: [1, 31]

    describe 'editor for hardTab', ->
      pack = 'language-go'
      beforeEach ->
        waitsForPromise ->
          atom.packages.activatePackage(pack)

        getVimState 'sample.go', (state, vimEditor) ->
          {editor, editorElement} = state
          {set, ensure, keystroke} = vimEditor

      afterEach ->
        atom.packages.deactivatePackage(pack)

      it "move to next string", ->
        set cursor: [0, 0]
        ensure 'gs', cursor: [2, 7]
        ensure 'gs', cursor: [3, 7]
        ensure 'gs', cursor: [8, 8]
        ensure 'gs', cursor: [9, 8]
        ensure 'gs', cursor: [11, 20]
        ensure 'gs', cursor: [12, 15]
        ensure 'gs', cursor: [13, 15]
        ensure 'gs', cursor: [15, 15]
        ensure 'gs', cursor: [16, 15]
      it "move to previous string", ->
        set cursor: [18, 0]
        ensure 'gS', cursor: [16, 15]
        ensure 'gS', cursor: [15, 15]
        ensure 'gS', cursor: [13, 15]
        ensure 'gS', cursor: [12, 15]
        ensure 'gS', cursor: [11, 20]
        ensure 'gS', cursor: [9, 8]
        ensure 'gS', cursor: [8, 8]
        ensure 'gS', cursor: [3, 7]
        ensure 'gS', cursor: [2, 7]

  describe 'MoveTo(Previous|Next)Number', ->
    pack = 'language-coffee-script'
    beforeEach ->
      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          'g n': 'vim-mode-plus:move-to-next-number'
          'g N': 'vim-mode-plus:move-to-previous-number'

      waitsForPromise ->
        atom.packages.activatePackage(pack)

      runs ->
        set grammar: 'source.coffee'

      set
        text: """
        num1 = 1
        arr1 = [1, 101, 1001]
        arr2 = ["1", "2", "3"]
        num2 = 2
        fun("1", 2, 3)
        \n
        """

    afterEach ->
      atom.packages.deactivatePackage(pack)

    it "move to next number", ->
      set cursor: [0, 0]
      ensure 'gn', cursor: [0, 7]
      ensure 'gn', cursor: [1, 8]
      ensure 'gn', cursor: [1, 11]
      ensure 'gn', cursor: [1, 16]
      ensure 'gn', cursor: [3, 7]
      ensure 'gn', cursor: [4, 9]
      ensure 'gn', cursor: [4, 12]
    it "move to previous number", ->
      set cursor: [5, 0]
      ensure 'gN', cursor: [4, 12]
      ensure 'gN', cursor: [4, 9]
      ensure 'gN', cursor: [3, 7]
      ensure 'gN', cursor: [1, 16]
      ensure 'gN', cursor: [1, 11]
      ensure 'gN', cursor: [1, 8]
      ensure 'gN', cursor: [0, 7]
    it "support count", ->
      set cursor: [0, 0]
      ensure '5gn', cursor: [3, 7]
      ensure '3gN', cursor: [1, 8]
