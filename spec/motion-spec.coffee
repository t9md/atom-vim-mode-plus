# Refactoring status: 70%
{getVimState, dispatch, TextData} = require './spec-helper'
settings = require '../lib/settings'
globalState = require '../lib/global-state'

describe "Motion", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, _vim) ->
      vimState = state # to refer as vimState later.
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = _vim

  afterEach ->
    vimState.activate('reset')

  describe "simple motions", ->
    beforeEach ->
      set
        text: """
          12345
          abcd
          ABCDE
          """
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

      describe "when visual mode", ->
        beforeEach ->
          ensure 'v', cursor: [1, 2]

        it "moves the cursor down", ->
          ensure 'j', cursor: [2, 2]

        it "doesn't go over after the last line", ->
          ensure 'j', cursor: [2, 2]

        it "selects the text while moving", ->
          ensure 'j', selectedText: "bcd\nAB"

        it "keep same column(goalColumn) even after across the empty line", ->
          keystroke 'escape'
          set
            text: """
              abcdefg

              abcdefg
              """
            cursor: [0, 3]
          ensure 'v', cursor: [0, 4]
          ensure 'jj',
            cursor: [2, 4]
            selectedText: "defg\n\nabcd"

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
      it "moves the cursor up, but not to the beginning of the first line", ->
        ensure 'k', cursor: [0, 1]
        ensure 'k', cursor: [0, 1]

      describe "when visual mode", ->
        # If selection is initially reversed and not re-reversed, we wont adjust
        # cursor's side position (left/right) within select() methods,
        # So maintaining gloalColumn is not our job, it handled by atom's native way.
        # But I put spec to be correspond to `j` motion.
        it "keep same column(goalColumn) even after across the empty line", ->
          set
            text: """
              abcdefg

              abcdefg
              """
            cursor: [2, 3]
          ensure 'v', cursor: [2, 4]
          ensure 'kk',
            cursor: [0, 3]
            selectedText: "defg\n\nabcd"

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
          ensure 'gg', cursor: [0, 0]

        it "moves to same position if its on first line and first char", ->
          ensure 'gg', cursor: [0, 2]

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
            selectedText: " 2\n3"
            cursor: [1, 0]

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
        ensure 'v2g_', selectedText: "  2  \n 3abc"

  describe "the G keybinding", ->
    beforeEach ->
      set
        text: "123\n    2\n 3abc\n"
        cursor: [0, 1]

    describe "as a motion", ->
      it "moves the cursor to the last line after whitespace", ->
        ensure 'G', cursor: [2, 1]

      it "moves the cursor to the end of the line", ->
        set text: "12345\nab\n", cursor: [0, 4]
        ensure 'G', cursor: [1, 1]

    describe "as a repeated motion", ->
      it "moves the cursor to a specified line", ->
        ensure '3G', cursor: [2, 1]

      it "moves the cursor to a specified line with whitespace", ->
        # atom forces the cursor to the start of the fake tabstop
        ensure '2G', cursor: [1, 0]

    describe "as a selection", ->
      it "selects to the last line in the file", ->
        set cursor: [1, 2]
        ensure 'vG',
          selectedText: "  2\n 3a"
          cursor: [2, 3]

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

  describe "the / keybinding", ->
    pane = null

    beforeEach ->
      pane = {activate: jasmine.createSpy("activate")}
      set
        text: """
            abc
            def
            abc
            def\n
          """
        cursor: [0, 0]
      spyOn(atom.workspace, 'getActivePane').andReturn(pane)

      # clear search history
      vimState.searchHistory.clear()
      globalState.currentSearch = {}

    describe "as a motion", ->
      it "moves the cursor to the specified search pattern", ->
        ensure ['/', search: 'def'],
          cursor: [1, 0]
        expect(pane.activate).toHaveBeenCalled()

      it "loops back around", ->
        set cursor: [3, 0]
        ensure ['/', search: 'def'], cursor: [1, 0]

      it "uses a valid regex as a regex", ->
        # Cycle through the 'abc' on the first line with a character pattern
        ensure ['/', search: '[abc]'], cursor: [0, 1]
        ensure 'n', cursor: [0, 2]

      it "uses an invalid regex as a literal string", ->
        # Go straight to the literal [abc
        set text: "abc\n[abc]\n"
        ensure ['/', search: '[abc'], cursor: [1, 0]
        ensure 'n', cursor: [1, 0]

      it "uses ? as a literal string", ->
        set text: "abc\n[a?c?\n"
        ensure ['/', search: '?'], cursor: [1, 2]
        ensure 'n', cursor: [1, 4]

      it 'works with selection in visual mode', ->
        set text: 'one two three'
        ensure ['v/', search: 'th'], cursor: [0, 9]
        ensure 'd', text: 'hree'

      it 'extends selection when repeating search in visual mode', ->
        set text: """
          line1
          line2
          line3
          """

        ensure ['v/', {search: 'line'}],
          selectedBufferRange: [[0, 0], [1, 1]]
        ensure 'n',
          selectedBufferRange: [[0, 0], [2, 1]]

      describe "case sensitivity", ->
        beforeEach ->
          set
            text: "\nabc\nABC\n"
            cursor: [0, 0]

        it "works in case sensitive mode", ->
          ensure ['/', search: 'ABC'], cursor: [2, 0]
          ensure 'n', cursor: [2, 0]

        it "works in case insensitive mode", ->
          ensure ['/', search: '\\cAbC'], cursor: [1, 0]
          ensure 'n', cursor: [2, 0]

        it "works in case insensitive mode wherever \\c is", ->
          ensure ['/', search: 'AbC\\c'], cursor: [1, 0]
          ensure 'n', cursor: [2, 0]

        it "uses case insensitive search if useSmartcaseForSearch is true and searching lowercase", ->
          settings.set 'useSmartcaseForSearch', true
          ensure ['/', search: 'abc'], cursor: [1, 0]
          ensure 'n', cursor: [2, 0]

        it "uses case sensitive search if useSmartcaseForSearch is true and searching uppercase", ->
          settings.set 'useSmartcaseForSearch', true
          ensure ['/', search: 'ABC'], cursor: [2, 0]
          ensure 'n', cursor: [2, 0]

      describe "repeating", ->
        it "does nothing with no search history", ->
          set cursor: [0, 0]
          ensure 'n', cursor: [0, 0]
          set cursor: [1, 1]
          ensure 'n', cursor: [1, 1]

      describe "repeating with search history", ->
        beforeEach ->
          keystroke ['/', search: 'def']

        it "repeats previous search with /<enter>", ->
          ensure ['/', search: ''], cursor: [3, 0]

        it "repeats previous search with //", ->
          ensure ['/', search: '/'], cursor: [3, 0]

        describe "the n keybinding", ->
          it "repeats the last search", ->
            ensure 'n', cursor: [3, 0]

        describe "the N keybinding", ->
          it "repeats the last search backwards", ->
            set cursor: [0, 0]
            ensure 'N', cursor: [3, 0]
            ensure 'N', cursor: [1, 0]

      describe "composing", ->
        it "composes with operators", ->
          ensure ['d/', search: 'def'], text: "def\nabc\ndef\n"

        it "repeats correctly with operators", ->
          ensure ['d/', search: 'def', '.'],
            text: "def\n"

    describe "when reversed as ?", ->
      it "moves the cursor backwards to the specified search pattern", ->
        ensure ['?', search: 'def'], cursor: [3, 0]

      it "accepts / as a literal search pattern", ->
        set
          text: "abc\nd/f\nabc\nd/f\n"
          cursor: [0, 0]
        ensure ['?', search: '/'], cursor: [3, 1]
        ensure ['?', search: '/'], cursor: [1, 1]

      describe "repeating", ->
        beforeEach ->
          keystroke ['?', search: 'def']

        it "repeats previous search as reversed with ?<enter>", ->
          ensure ['?', search: ''], cursor: [1, 0]

        it "repeats previous search as reversed with ??", ->
          ensure ['?', search: '?'], cursor: [1, 0]

        describe 'the n keybinding', ->
          it "repeats the last search backwards", ->
            set cursor: [0, 0]
            ensure 'n', cursor: [3, 0]

        describe 'the N keybinding', ->
          it "repeats the last search forwards", ->
            set cursor: [0, 0]
            ensure 'N', cursor: [1, 0]

    describe "using search history", ->
      inputEditor = null
      ensureInputEditor = (command, {text}) ->
        dispatch(inputEditor, command)
        expect(inputEditor.getModel().getText()).toEqual(text)

      beforeEach ->
        ensure ['/', search: 'def'], cursor: [1, 0]
        ensure ['/', search: 'abc'], cursor: [2, 0]
        inputEditor = vimState.search.view.editorElement

      it "allows searching history in the search field", ->
        _editor = inputEditor.getModel()
        keystroke '/'
        ensureInputEditor 'core:move-up', text: 'abc'
        ensureInputEditor 'core:move-up', text: 'def'
        ensureInputEditor 'core:move-up', text: 'def'

      it "resets the search field to empty when scrolling back", ->
        keystroke '/'
        ensureInputEditor 'core:move-up', text: 'abc'
        ensureInputEditor 'core:move-up', text: 'def'
        ensureInputEditor 'core:move-down', text: 'abc'
        ensureInputEditor 'core:move-down', text: ''

  describe "the * keybinding", ->
    beforeEach ->
      set
        text: "abd\n@def\nabd\ndef\n"
        cursorBuffer: [0, 0]

    describe "as a motion", ->
      it "moves cursor to next occurence of word under cursor", ->
        ensure '*', cursorBuffer: [2, 0]

      it "repeats with the n key", ->
        ensure '*', cursorBuffer: [2, 0]
        ensure 'n', cursorBuffer: [0, 0]

      it "doesn't move cursor unless next occurence is the exact word (no partial matches)", ->
        set
          text: "abc\ndef\nghiabc\njkl\nabcdef"
          cursorBuffer: [0, 0]
        ensure '*', cursorBuffer: [0, 0]

      describe "with words that contain 'non-word' characters", ->
        it "moves cursor to next occurence of word under cursor", ->
          set
            text: "abc\n@def\nabc\n@def\n"
            cursorBuffer: [1, 0]
          ensure '*', cursorBuffer: [3, 0]

        it "doesn't move cursor unless next match has exact word ending", ->
          set
            text: "abc\n@def\nabc\n@def1\n"
            cursorBuffer: [1, 1]
          # this is because of the default isKeyword value of vim-mode-plus that includes @
          ensure '*', cursorBuffer: [1, 0]

        # FIXME: This behavior is different from the one found in
        # vim. This is because the word boundary match in Javascript
        # ignores starting 'non-word' characters.
        # e.g.
        # in Vim:        /\<def\>/.test("@def") => false
        # in Javascript: /\bdef\b/.test("@def") => true
        it "moves cursor to the start of valid word char", ->
          set
            text: "abc\ndef\nabc\n@def\n"
            cursorBuffer: [1, 0]
          ensure '*', cursorBuffer: [3, 1]

      describe "when cursor is on non-word char column", ->
        it "matches only the non-word char", ->
          set
            text: "abc\n@def\nabc\n@def\n"
            cursorBuffer: [1, 0]
          ensure '*', cursorBuffer: [3, 0]

      describe "when cursor is not on a word", ->
        it "does a match with the next word", ->
          set
            text: "abc\na  @def\n abc\n @def"
            cursorBuffer: [1, 1]
          ensure '*', cursorBuffer: [3, 1]

      describe "when cursor is at EOF", ->
        it "doesn't try to do any match", ->
          set
            text: "abc\n@def\nabc\n "
            cursorBuffer: [3, 0]
          ensure '*', cursorBuffer: [3, 0]

  describe "the hash keybinding", ->
    describe "as a motion", ->
      it "moves cursor to previous occurence of word under cursor", ->
        set
          text: "abc\n@def\nabc\ndef\n"
          cursorBuffer: [2, 1]
        ensure '#', cursorBuffer: [0, 0]

      it "repeats with n", ->
        set
          text: "abc\n@def\nabc\ndef\nabc\n"
          cursorBuffer: [2, 1]
        ensure '#', cursorBuffer: [0, 0]
        ensure 'n', cursorBuffer: [4, 0]
        ensure 'n', cursorBuffer: [2, 0]

      it "doesn't move cursor unless next occurence is the exact word (no partial matches)", ->
        set
          text: "abc\ndef\nghiabc\njkl\nabcdef"
          cursorBuffer: [0, 0]
        ensure '#', cursorBuffer: [0, 0]

      describe "with words that containt 'non-word' characters", ->
        it "moves cursor to next occurence of word under cursor", ->
          set
            text: "abc\n@def\nabc\n@def\n"
            cursorBuffer: [3, 0]
          ensure '#', cursorBuffer: [1, 0]

        it "moves cursor to the start of valid word char", ->
          set
            text: "abc\n@def\nabc\ndef\n"
            cursorBuffer: [3, 0]
          ensure '#', cursorBuffer: [1, 1]

      describe "when cursor is on non-word char column", ->
        it "matches only the non-word char", ->
          set
            text: "abc\n@def\nabc\n@def\n"
            cursorBuffer: [1, 0]
          ensure '*', cursorBuffer: [3, 0]

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

  describe 'the f/F keybindings', ->
    beforeEach ->
      set
        text: "abcabcabcabc\n"
        cursor: [0, 0]

    it 'moves to the first specified character it finds', ->
      ensure ['f', char: 'c'], cursor: [0, 2]

    it 'moves backwards to the first specified character it finds', ->
      set cursor: [0, 2]
      ensure ['F', char: 'a'], cursor: [0, 0]

    it 'respects count forward', ->
      ensure ['2f', char: 'a'], cursor: [0, 6]

    it 'respects count backward', ->
      cursor: [0, 6]
      ensure ['2F', char: 'a'], cursor: [0, 0]

    it "doesn't move if the character specified isn't found", ->
      ensure ['f', char: 'd'], cursor: [0, 0]

    it "doesn't move if there aren't the specified count of the specified character", ->
      ensure ['10f', char: 'a'], cursor: [0, 0]
      # a bug was making this behaviour depend on the count
      ensure ['11f', char: 'a'], cursor: [0, 0]
      # and backwards now
      set cursor: [0, 6]
      ensure ['10F', char: 'a'], cursor: [0, 6]
      ensure ['11F', char: 'a'], cursor: [0, 6]

    it "composes with d", ->
      set cursor: [0, 3]
      ensure ['d2f', char: 'a'], text: 'abcbc\n'

    it "F behaves exclusively when composes with operator", ->
      set cursor: [0, 3]
      ensure ['dF', char: 'a'], text: 'abcabcabc\n'

  describe 'the t/T keybindings', ->
    beforeEach ->
      set
        text: "abcabcabcabc\n"
        cursor: [0, 0]

    it 'moves to the character previous to the first specified character it finds', ->
      ensure ['t', char: 'a'], cursor: [0, 2]
      # or stays put when it's already there
      ensure ['t', char: 'a'], cursor: [0, 2]

    it 'moves backwards to the character after the first specified character it finds', ->
      set cursor: [0, 2]
      ensure ['T', char: 'a'], cursor: [0, 1]

    it 'respects count forward', ->
      ensure ['2t', char: 'a'], cursor: [0, 5]

    it 'respects count backward', ->
      set cursor: [0, 6]
      ensure ['2T', char: 'a'], cursor: [0, 1]

    it "doesn't move if the character specified isn't found", ->
      ensure ['t', char: 'd'], cursor: [0, 0]

    it "doesn't move if there aren't the specified count of the specified character", ->
      ensure ['10t', char: 'd'], cursor: [0, 0]
      # a bug was making this behaviour depend on the count
      ensure ['11t', char: 'a'], cursor: [0, 0]
      # and backwards now
      set cursor: [0, 6]
      ensure ['10T', char: 'a'], cursor: [0, 6]
      ensure ['11T', char: 'a'], cursor: [0, 6]

    it "composes with d", ->
      set cursor: [0, 3]
      ensure ['d2t', char: 'b'],
        text: 'abcbcabc\n'

    it "selects character under cursor even when no movement happens", ->
      set cursor: [0, 0]
      ensure ['dt', char: 'b'],
        text: 'bcabcabcabc\n'

    it "T behaves exclusively when composes with operator", ->
      set cursor: [0, 3]
      ensure ['dT', char: 'b'],
        text: 'ababcabcabc\n'

    it "T don't delete character under cursor even when no movement happens", ->
      set cursor: [0, 3]
      ensure ['dT', char: 'c'],
        text: 'abcabcabcabc\n'

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

  describe 'the ; and , keybindings', ->
    beforeEach ->
      set
        text: "abcabcabcabc\n"
        cursor: [0, 0]

    it "repeat f in same direction", ->
      ensure ['f', char: 'c'], cursor: [0, 2]
      ensure ';', cursor: [0, 5]
      ensure ';', cursor: [0, 8]

    it "repeat F in same direction", ->
      set cursor: [0, 10]
      ensure ['F', char: 'c'], cursor: [0, 8]
      ensure ';', cursor: [0, 5]
      ensure ';', cursor: [0, 2]

    it "repeat f in opposite direction", ->
      set cursor: [0, 6]
      ensure ['f', char: 'c'], cursor: [0, 8]
      ensure ',', cursor: [0, 5]
      ensure ',', cursor: [0, 2]

    it "repeat F in opposite direction", ->
      set cursor: [0, 4]
      ensure ['F', char: 'c'], cursor: [0, 2]
      ensure ',', cursor: [0, 5]
      ensure ',', cursor: [0, 8]

    it "alternate repeat f in same direction and reverse", ->
      ensure ['f', char: 'c'], cursor: [0, 2]
      ensure ';', cursor: [0, 5]
      ensure ',', cursor: [0, 2]

    it "alternate repeat F in same direction and reverse", ->
      set cursor: [0, 10]
      ensure ['F', char: 'c'], cursor: [0, 8]
      ensure ';', cursor: [0, 5]
      ensure ',', cursor: [0, 8]

    it "repeat t in same direction", ->
      ensure ['t', char: 'c'], cursor: [0, 1]
      ensure ';', cursor: [0, 4]

    it "repeat T in same direction", ->
      set cursor: [0, 10]
      ensure ['T', char: 'c'], cursor: [0, 9]
      ensure ';', cursor: [0, 6]

    it "repeat t in opposite direction first, and then reverse", ->
      set cursor: [0, 3]
      ensure ['t', char: 'c'], cursor: [0, 4]
      ensure ',', cursor: [0, 3]
      ensure ';', cursor: [0, 4]

    it "repeat T in opposite direction first, and then reverse", ->
      set cursor: [0, 4]
      ensure ['T', char: 'c'], cursor: [0, 3]
      ensure ',', cursor: [0, 4]
      ensure ';', cursor: [0, 3]

    it "repeat with count in same direction", ->
      set cursor: [0, 0]
      ensure ['f', char: 'c'], cursor: [0, 2]
      ensure '2;', cursor: [0, 8]

    it "repeat with count in reverse direction", ->
      set cursor: [0, 6]
      ensure ['f', char: 'c'], cursor: [0, 8]
      ensure '2,', cursor: [0, 2]

    it "shares the most recent find/till command with other editors", ->
      getVimState (otherVimState, other) ->
        set
          text: "a baz bar\n"
          cursor: [0, 0]

        other.set
          text: "foo bar baz",
          cursor: [0, 0]
        otherEditor = otherVimState.editor

        pane = atom.workspace.getActivePane()
        pane.activateItem(editor)

        # by default keyDown and such go in the usual editor
        ensure ['f', char: 'b'], cursor: [0, 2]
        other.ensure cursor: [0, 0]

        # replay same find in the other editor
        pane.activateItem(otherEditor)
        other.keystroke ';'
        ensure cursor: [0, 2]
        other.ensure cursor: [0, 4]

        # do a till in the other editor
        other.keystroke ['t', char: 'r']
        ensure cursor: [0, 2]
        other.ensure cursor: [0, 5]

        # and replay in the normal editor
        pane.activateItem(editor)
        ensure ';', cursor: [0, 7]
        other.ensure cursor: [0, 5]

  describe 'the % motion', ->
    beforeEach ->
      set
        text: "( ( ) )--{ text in here; and a function call(with parameters) }\n"
        cursor: [0, 0]

    it 'matches the correct parenthesis', ->
      ensure '%', cursor: [0, 6]

    it 'matches the correct brace', ->
      set cursor: [0, 9]
      ensure '%', cursor: [0, 62]

    it 'composes correctly with d', ->
      set cursor: [0, 9]
      ensure 'd%',
        text: "( ( ) )--\n"

    it 'moves correctly when composed with v going forward', ->
      ensure 'vh%', cursor: [0, 7]

    it 'moves correctly when composed with v going backward', ->
      set cursor: [0, 5]
      ensure 'v%', cursor: [0, 0]

    it 'it moves appropriately to find the nearest matching action', ->
      set cursor: [0, 3]
      ensure '%',
        cursor: [0, 2]
        text: "( ( ) )--{ text in here; and a function call(with parameters) }\n"

    it 'it moves appropriately to find the nearest matching action', ->
      set cursor: [0, 26]
      ensure '%',
        cursor: [0, 60]
        text: "( ( ) )--{ text in here; and a function call(with parameters) }\n"

    it "finds matches across multiple lines", ->
      set
        text: "...(\n...)"
        cursor: [0, 0]
      ensure '%',
        cursor: [1, 3]

    it "does not affect search history", ->
      ensure ['/', search: 'func'], cursor: [0, 31]
      ensure '%', cursor: [0, 60]
      ensure 'n', cursor: [0, 31]

  describe "scrolling screen and keeping cursor in the same screen position", ->
    text = new TextData([0...80].join("\n"))
    beforeEach ->
      set text: text.getRaw()
      editorElement.setHeight(20 * 10)
      editorElement.style.lineHeight = "10px"
      atom.views.performDocumentPoll()
      editorElement.setScrollTop(40 * 10)
      editor.setCursorBufferPosition([42, 0])
      jasmine.attachToDOM(editorElement)

    describe "the ctrl-u keybinding", ->
      it "moves the screen down by half screen size and keeps cursor onscreen", ->
        ensure [ctrl: 'u'],
          scrollTop: 300
          cursor: [32, 0]

      it "selects on visual mode", ->
        set cursor: [42, 1]
        ensure ['v', ctrl: 'u'],
          selectedText: text.getLines([32..42], chomp: true)

      it "selects on linewise mode", ->
        ensure ['V', ctrl: 'u'],
          selectedText: text.getLines([32..42])

    describe "the ctrl-b keybinding", ->
      it "moves screen up one page", ->
        ensure {ctrl: 'b'},
          scrollTop: 200
          cursor: [22, 0]

      it "selects on visual mode", ->
        set cursor: [42, 1]
        ensure ['v', {ctrl: 'b'}],
          selectedText: text.getLines([22..42], chomp: true)

      it "selects on linewise mode", ->
        ensure ['V', {ctrl: 'b'}],
          selectedText: text.getLines([22..42])

    describe "the ctrl-d keybinding", ->
      it "moves the screen down by half screen size and keeps cursor onscreen", ->
        ensure [ctrl: 'd'],
          scrollTop: 500
          cursor: [52, 0]

      it "selects on visual mode", ->
        set cursor: [42, 1]
        ensure ['v', ctrl: 'd'],
          selectedText: text.getLines([42..52], chomp: true).slice(1, -1)

      it "selects on linewise mode", ->
        ensure ['V', ctrl: 'd'],
          selectedText: text.getLines([42..52])

    describe "the ctrl-f keybinding", ->
      it "moves screen down one page", ->
        ensure [ctrl: 'f'],
          scrollTop: 600
          cursor: [62, 0]

      it "selects on visual mode", ->
        set cursor: [42, 1]
        ensure ['v', ctrl: 'f'],
          selectedText: text.getLines([42..62], chomp: true).slice(1, -1)

      it "selects on linewise mode", ->
        ensure ['V', ctrl: 'f'],
          selectedText: text.getLines([42..62])
