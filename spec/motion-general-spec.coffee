{Point} = require 'atom'
{getVimState, dispatch, TextData, getView} = require './spec-helper'
settings = require '../lib/settings'

describe "Motion general", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, _vim) ->
      vimState = state # to refer as vimState later.
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = _vim

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
          ensure 'h h', cursor: [0, 4]

      describe "as a selection", ->
        it "selects the character to the left", ->
          ensure 'y h',
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
        ensure '1 0 j', cursor: [2, 1]

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
          ensure 'j j', cursor: [2, 4], selectedText: "defg\n\nabcd"

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

    describe "move-down-wrap, move-up-wrap", ->
      beforeEach ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'k': 'vim-mode-plus:move-up-wrap'
            'j': 'vim-mode-plus:move-down-wrap'

        set
          text: """
          hello
          hello
          hello
          hello\n
          """
      describe 'move-down-wrap', ->
        beforeEach ->
          set cursor: [3, 1]
        it "move down with wrawp", -> ensure 'j', cursor: [0, 1]
        it "move down with wrawp", -> ensure '2 j', cursor: [1, 1]
        it "move down with wrawp", -> ensure '4 j', cursor: [3, 1]

      describe 'move-up-wrap', ->
        beforeEach ->
          set cursor: [0, 1]

        it "move down with wrawp", -> ensure 'k', cursor: [3, 1]
        it "move down with wrawp", -> ensure '2 k', cursor: [2, 1]
        it "move down with wrawp", -> ensure '4 k', cursor: [0, 1]


    # [NOTE] See #560
    # This spec is intended to be used in local test, not at CI service.
    # Safe to execute if it passes, but freeze editor when it fail.
    # So explicitly disabled because I don't want be banned by CI service.
    # Enable this on demmand when freezing happens again!
    xdescribe "with big count was given", ->
      BIG_NUMBER = Number.MAX_SAFE_INTEGER
      ensureBigCountMotion = (keystrokes, options) ->
        count = String(BIG_NUMBER).split('').join(' ')
        keystrokes = keystrokes.split('').join(' ')
        ensure("#{count} #{keystrokes}", options)

      beforeEach ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'g {': 'vim-mode-plus:move-to-previous-fold-start'
            'g }': 'vim-mode-plus:move-to-next-fold-start'
            ', N': 'vim-mode-plus:move-to-previous-number'
            ', n': 'vim-mode-plus:move-to-next-number'
        set
          text: """
          0000
          1111
          2222\n
          """
          cursor: [1, 2]

      it "by `j`", -> ensureBigCountMotion 'j', cursor: [2, 2]
      it "by `k`", -> ensureBigCountMotion 'k', cursor: [0, 2]
      it "by `h`", -> ensureBigCountMotion 'h', cursor: [1, 0]
      it "by `l`", -> ensureBigCountMotion 'l', cursor: [1, 3]
      it "by `[`", -> ensureBigCountMotion '[', cursor: [0, 2]
      it "by `]`", -> ensureBigCountMotion ']', cursor: [2, 2]
      it "by `w`", -> ensureBigCountMotion 'w', cursor: [2, 3]
      it "by `W`", -> ensureBigCountMotion 'W', cursor: [2, 3]
      it "by `b`", -> ensureBigCountMotion 'b', cursor: [0, 0]
      it "by `B`", -> ensureBigCountMotion 'B', cursor: [0, 0]
      it "by `e`", -> ensureBigCountMotion 'e', cursor: [2, 3]
      it "by `(`", -> ensureBigCountMotion '(', cursor: [0, 0]
      it "by `)`", -> ensureBigCountMotion ')', cursor: [2, 3]
      it "by `{`", -> ensureBigCountMotion '{', cursor: [0, 0]
      it "by `}`", -> ensureBigCountMotion '}', cursor: [2, 3]
      it "by `-`", -> ensureBigCountMotion '-', cursor: [0, 0]
      it "by `_`", -> ensureBigCountMotion '_', cursor: [2, 0]
      it "by `g {`", -> ensureBigCountMotion 'g {', cursor: [1, 2] # No fold no move but won't freeze.
      it "by `g }`", -> ensureBigCountMotion 'g }', cursor: [1, 2] # No fold no move but won't freeze.
      it "by `, N`", -> ensureBigCountMotion ', N', cursor: [1, 2] # No grammar, no move but won't freeze.
      it "by `, n`", -> ensureBigCountMotion ', n', cursor: [1, 2] # No grammar, no move but won't freeze.

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
        ensure '1 0 k', cursor: [0, 1]

      describe "when visual mode", ->
        it "keep same column(goalColumn) even after across the empty line", ->
          set
            text: """
              abcdefg

              abcdefg
              """
            cursor: [2, 3]
          ensure 'v', cursor: [2, 4], selectedText: 'd'
          ensure 'k k', cursor: [0, 3], selectedText: "defg\n\nabcd"

    describe "gj gk in softwrap", ->
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
          ensure 'g j', cursorScreen: [1, 0], cursor: [0, 9]
          ensure 'g j', cursorScreen: [2, 0], cursor: [1, 0]
          ensure 'g j', cursorScreen: [3, 0], cursor: [1, 9]
          ensure 'g j', cursorScreen: [4, 0], cursor: [1, 12]

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
          ensure 'g j', cursorScreen: [1, 0], cursor: [0, 9]
          ensure 'g j', cursorScreen: [2, 0], cursor: [1, 0]
          ensure 'g j', cursorScreen: [3, 0], cursor: [1, 9]
          ensure 'g j', cursorScreen: [4, 0], cursor: [1, 12]

        it "jk move selection buffer-line wise", ->
          set cursor: [4, 0]
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
        ensure 'l l', cursor: [2, 0]

      describe "on a blank line", ->
        it "doesn't move the cursor", ->
          set text: "\n\n\n", cursor: [1, 0]
          ensure 'l', cursor: [1, 0]

    describe "move-(up/down)-to-edge", ->
      text = null
      beforeEach ->
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

      describe "edgeness of first-line and last-line", ->
        beforeEach ->
          set
            text_: """
            ____this is line 0
            ____this is text of line 1
            ____this is text of line 2
            ______hello line 3
            ______hello line 4
            """
            cursor: [2, 2]

        describe "when column is leading spaces", ->
          it "doesn't move cursor", ->
            ensure '[', cursor: [2, 2]
            ensure ']', cursor: [2, 2]

        describe "when column is trailing spaces", ->
          it "doesn't move cursor", ->
            set cursor: [1, 20]
            ensure ']', cursor: [2, 20]
            ensure ']', cursor: [2, 20]
            ensure '[', cursor: [1, 20]
            ensure '[', cursor: [1, 20]

      it "move to non-blank-char on both first and last row", ->
        set cursor: [4, 4]
        ensure '[', cursor: [0, 4]
        ensure ']', cursor: [7, 4]
      it "move to white space char when both side column is non-blank char", ->
        set cursor: [4, 5]
        ensure '[', cursor: [0, 5]
        ensure ']', cursor: [4, 5]
        ensure ']', cursor: [7, 5]
      it "only stops on row one of [first row, last row, up-or-down-row is blank] case-1", ->
        set cursor: [4, 6]
        ensure '[', cursor: [2, 6]
        ensure '[', cursor: [0, 6]
        ensure ']', cursor: [2, 6]
        ensure ']', cursor: [4, 6]
        ensure ']', cursor: [7, 6]
      it "only stops on row one of [first row, last row, up-or-down-row is blank] case-2", ->
        set cursor: [4, 7]
        ensure '[', cursor: [2, 7]
        ensure '[', cursor: [0, 7]
        ensure ']', cursor: [2, 7]
        ensure ']', cursor: [4, 7]
        ensure ']', cursor: [7, 7]
      it "support count", ->
        set cursor: [4, 6]
        ensure '2 [', cursor: [0, 6]
        ensure '3 ]', cursor: [7, 6]

      describe 'editor for hardTab', ->
        pack = 'language-go'
        beforeEach ->
          waitsForPromise ->
            atom.packages.activatePackage(pack)

          getVimState 'sample.go', (state, vimEditor) ->
            {editor, editorElement} = state
            {set, ensure, keystroke} = vimEditor

          runs ->
            set cursorScreen: [8, 2]
            # In hardTab indent bufferPosition is not same as screenPosition
            ensure cursor: [8, 1]

        afterEach ->
          atom.packages.deactivatePackage(pack)

        it "move up/down to next edge of same *screen* column", ->
          ensure '[', cursorScreen: [5, 2]
          ensure '[', cursorScreen: [3, 2]
          ensure '[', cursorScreen: [2, 2]
          ensure '[', cursorScreen: [0, 2]

          ensure ']', cursorScreen: [2, 2]
          ensure ']', cursorScreen: [3, 2]
          ensure ']', cursorScreen: [5, 2]
          ensure ']', cursorScreen: [9, 2]
          ensure ']', cursorScreen: [11, 2]
          ensure ']', cursorScreen: [14, 2]
          ensure ']', cursorScreen: [17, 2]

          ensure '[', cursorScreen: [14, 2]
          ensure '[', cursorScreen: [11, 2]
          ensure '[', cursorScreen: [9, 2]
          ensure '[', cursorScreen: [5, 2]
          ensure '[', cursorScreen: [3, 2]
          ensure '[', cursorScreen: [2, 2]
          ensure '[', cursorScreen: [0, 2]

  describe 'moveSuccessOnLinewise behaviral characteristic', ->
    originalText = null
    beforeEach ->
      settings.set('useClipboardAsDefaultRegister', false)
      set
        text: """
          000
          111
          222\n
          """
      originalText = editor.getText()
      ensure register: {'"': text: undefined}

    describe "moveSuccessOnLinewise=false motion", ->
      describe "when it can move", ->
        beforeEach -> set cursor: [1, 0]
        it "delete by j", -> ensure "d j", text: "000\n", mode: 'normal'
        it "yank by j", -> ensure "y j", text: originalText, register: {'"': text: "111\n222\n"}, mode: 'normal'
        it "change by j", -> ensure "c j", textC: "000\n|\n", register: {'"': text: "111\n222\n"}, mode: 'insert'

        it "delete by k", -> ensure "d k", text: "222\n", mode: 'normal'
        it "yank by k", -> ensure "y k", text: originalText, register: {'"': text: "000\n111\n"}, mode: 'normal'
        it "change by k", -> ensure "c k", textC: "|\n222\n", register: {'"': text: "000\n111\n"}, mode: 'insert'

      describe "when it can not move-up", ->
        beforeEach -> set cursor: [0, 0]
        it "delete by dk", -> ensure "d k", text: originalText, mode: 'normal'
        it "yank by yk", -> ensure "y k", text: originalText, register: {'"': text: undefined}, mode: 'normal'
        it "change by ck", -> ensure "c k", textC: "|000\n111\n222\n", register: {'"': text: "\n"}, mode: 'insert' # FIXME, incompatible: shoud remain in normal.

      describe "when it can not move-down", ->
        beforeEach -> set cursor: [2, 0]
        it "delete by dj", -> ensure "d j", text: originalText, mode: 'normal'
        it "yank by yj", -> ensure "y j", text: originalText, register: {'"': text: undefined}, mode: 'normal'
        it "change by cj", -> ensure "c j", textC: "000\n111\n|222\n", register: {'"': text: "\n"}, mode: 'insert' # FIXME, incompatible: shoud remain in normal.

    describe "moveSuccessOnLinewise=true motion", ->
      describe "when it can move", ->
        beforeEach -> set cursor: [1, 0]
        it "delete by G", -> ensure "d G", text: "000\n", mode: 'normal'
        it "yank by G", -> ensure "y G", text: originalText, register: {'"': text: "111\n222\n"}, mode: 'normal'
        it "change by G", -> ensure "c G", textC: "000\n|\n", register: {'"': text: "111\n222\n"}, mode: 'insert'

        it "delete by gg", -> ensure "d g g", text: "222\n", mode: 'normal'
        it "yank by gg", -> ensure "y g g", text: originalText, register: {'"': text: "000\n111\n"}, mode: 'normal'
        it "change by gg", -> ensure "c g g", textC: "|\n222\n", register: {'"': text: "000\n111\n"}, mode: 'insert'

      describe "when it can not move-up", ->
        beforeEach -> set cursor: [0, 0]
        it "delete by gg", -> ensure "d g g", text: "111\n222\n", mode: 'normal'
        it "yank by gg", -> ensure "y g g", text: originalText, register: {'"': text: "000\n"}, mode: 'normal'
        it "change by gg", -> ensure "c g g", textC: "|\n111\n222\n", register: {'"': text: "000\n"}, mode: 'insert'
      describe "when it can not move-down", ->
        beforeEach -> set cursor: [2, 0]
        it "delete by G", -> ensure "d G", text: "000\n111\n", mode: 'normal'
        it "yank by G", -> ensure "y G", text: originalText, register: {'"': text: "222\n"}, mode: 'normal'
        it "change by G", -> ensure "c G", textC: "000\n111\n|\n", register: {'"': text: "222\n"}, mode: 'insert'

  describe "the w keybinding", ->
    baseText = """
      ab cde1+-
       xyz

      zip
      """
    beforeEach ->
      set text: baseText

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

      it "move to next word by skipping trailing white spaces", ->
        set
          textC_: """
            012|___
              234
            """
        ensure 'w',
          textC_: """
            012___
              |234
            """

      it "move to next word from EOL", ->
        set
          textC_: """
            |
            __234"
            """
        ensure 'w',
          textC_: """

            __|234"
            """

      # [FIXME] improve spec to loop same section with different text
      describe "for CRLF buffer", ->
        beforeEach ->
          set text: baseText.replace(/\n/g, "\r\n")

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

    describe "when used by Change operator", ->
      beforeEach ->
        set
          text_: """
          __var1 = 1
          __var2 = 2\n
          """

      describe "when cursor is on word", ->
        it "not eat whitespace", ->
          set cursor: [0, 3]
          ensure 'c w',
            text_: """
            __v = 1
            __var2 = 2\n
            """
            cursor: [0, 3]

      describe "when cursor is on white space", ->
        it "only eat white space", ->
          set cursor: [0, 0]
          ensure 'c w',
            text_: """
            var1 = 1
            __var2 = 2\n
            """
            cursor: [0, 0]

      describe "when text to EOL is all white space", ->
        it "wont eat new line character", ->
          set
            text_: """
            abc__
            def\n
            """
            cursor: [0, 3]
          ensure 'c w',
            text: """
            abc
            def\n
            """
            cursor: [0, 3]

        it "cant eat new line when count is specified", ->
          set text: "\n\n\n\n\nline6\n", cursor: [0, 0]
          ensure '5 c w', text: "\nline6\n", cursor: [0, 0]

    describe "as a selection", ->
      describe "within a word", ->
        it "selects to the end of the word", ->
          set cursor: [0, 0]
          ensure 'y w', register: '"': text: 'ab '

      describe "between words", ->
        it "selects the whitespace", ->
          set cursor: [0, 2]
          ensure 'y w', register: '"': text: ' '

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
        set
          text_: """
            012___
            __234
            """
          cursor: [0, 3]
        ensure 'W', cursor: [1, 2]

      it "moves the cursor to beginning of the next word of next line when cursor is at EOL.", ->
        set
          text_: """

          __234
          """
          cursor: [0, 0]
        ensure 'W', cursor: [1, 2]

    # This spec is redundant since W(MoveToNextWholeWord) is child of w(MoveToNextWord).
    describe "when used by Change operator", ->
      beforeEach ->
        set
          text_: """
            __var1 = 1
            __var2 = 2\n
            """

      describe "when cursor is on word", ->
        it "not eat whitespace", ->
          set cursor: [0, 3]
          ensure 'c W',
            text_: """
              __v = 1
              __var2 = 2\n
              """
            cursor: [0, 3]

      describe "when cursor is on white space", ->
        it "only eat white space", ->
          set cursor: [0, 0]
          ensure 'c W',
            text_: """
              var1 = 1
              __var2 = 2\n
              """
            cursor: [0, 0]

      describe "when text to EOL is all white space", ->
        it "wont eat new line character", ->
          set text: "abc  \ndef\n", cursor: [0, 3]
          ensure 'c W', text: "abc\ndef\n", cursor: [0, 3]

        it "cant eat new line when count is specified", ->
          set text: "\n\n\n\n\nline6\n", cursor: [0, 0]
          ensure '5 c W', text: "\nline6\n", cursor: [0, 0]

    describe "as a selection", ->
      describe "within a word", ->
        it "selects to the end of the whole word", ->
          set cursor: [0, 0]
          ensure 'y W', register: '"': text: 'cde1+- '

      it "continues past blank lines", ->
        set cursor: [2, 0]
        ensure 'd W',
          text_: """
          cde1+- ab_
          _xyz
          zip
          """
          register: '"': text: "\n"

      it "doesn't go past the end of the file", ->
        set cursor: [3, 0]
        ensure 'd W',
          text_: """
          cde1+- ab_
          _xyz\n\n
          """
          register: '"': text: 'zip'

  describe "the e keybinding", ->
    beforeEach ->
      set text_: """
      ab cde1+-_
      _xyz

      zip
      """

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
          ensure 'y e', register: '"': text: 'ab'

      describe "between words", ->
        it "selects to the end of the next word", ->
          set cursor: [0, 2]
          ensure 'y e', register: '"': text: ' cde1'

  describe "the ge keybinding", ->
    describe "as a motion", ->
      it "moves the cursor to the end of the previous word", ->
        set text: "1234 5678 wordword"
        set cursor: [0, 16]
        ensure 'g e', cursor: [0, 8]
        ensure 'g e', cursor: [0, 3]
        ensure 'g e', cursor: [0, 0]
        ensure 'g e', cursor: [0, 0]

      it "moves corrently when starting between words", ->
        set text: "1 leading     end"
        set cursor: [0, 12]
        ensure 'g e', cursor: [0, 8]

      it "takes a count", ->
        set text: "vim mode plus is getting there"
        set cursor: [0, 28]
        ensure '5 g e', cursor: [0, 2]

      # test will fail until the code is fixed
      xit "handles non-words inside words like vim", ->
        set text: "1234 5678 word-word"
        set cursor: [0, 18]
        ensure 'g e', cursor: [0, 14]
        ensure 'g e', cursor: [0, 13]
        ensure 'g e', cursor: [0, 8]

      # test will fail until the code is fixed
      xit "handles newlines like vim", ->
        set text: "1234\n\n\n\n5678"
        set cursor: [5, 2]
        # vim seems to think an end-of-word is at every blank line
        ensure 'g e', cursor: [4, 0]
        ensure 'g e', cursor: [3, 0]
        ensure 'g e', cursor: [2, 0]
        ensure 'g e', cursor: [1, 0]
        ensure 'g e', cursor: [1, 0]
        ensure 'g e', cursor: [0, 3]
        ensure 'g e', cursor: [0, 0]

    describe "when used by Change operator", ->
      it "changes word fragments", ->
        set text: "cet document"
        set cursor: [0, 7]
        ensure 'c g e', cursor: [0, 2], text: "cement", mode: 'insert'
        # TODO: I'm not sure how to check the register after checking the document
        # ensure register: '"', text: 't docu'

      it "changes whitespace properly", ->
        set text: "ce    doc"
        set cursor: [0, 4]
        ensure 'c g e', cursor: [0, 1], text: "c doc", mode: 'insert'

    describe "in characterwise visual mode", ->
      it "selects word fragments", ->
        set text: "cet document"
        set cursor: [0, 7]
        ensure 'v g e', cursor: [0, 2], selectedText: "t docu"

  describe "the E keybinding", ->
    beforeEach ->
      set text_: """
      ab  cde1+-_
      _xyz_

      zip\n
      """

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
          ensure 'y E', register: '"': text: 'ab'

      describe "between words", ->
        it "selects to the end of the next word", ->
          set cursor: [0, 2]
          ensure 'y E', register: '"': text: '  cde1+-'

      describe "press more than once", ->
        it "selects to the end of the current word", ->
          set cursor: [0, 0]
          ensure 'v E E y', register: '"': text: 'ab  cde1+-'

  describe "the gE keybinding", ->
    describe "as a motion", ->
      it "moves the cursor to the end of the previous word", ->
        set text: "12.4 5~7- word-word"
        set cursor: [0, 16]
        ensure 'g E', cursor: [0, 8]
        ensure 'g E', cursor: [0, 3]
        ensure 'g E', cursor: [0, 0]
        ensure 'g E', cursor: [0, 0]

  describe "the (,) sentence keybinding", ->
    describe "as a motion", ->
      beforeEach ->
        set
          cursor: [0, 0]
          text: """
          sentence one.])'"    sen.tence .two.
          here.  sentence three
          more three

             sentence four


          sentence five.
          more five
          more six

           last sentence
          all done seven
          """

      it "moves the cursor to the end of the sentence", ->
        ensure ')', cursor: [0, 21]
        ensure ')', cursor: [1, 0]
        ensure ')', cursor: [1, 7]
        ensure ')', cursor: [3, 0]
        ensure ')', cursor: [4, 3]
        ensure ')', cursor: [5, 0] # boundary is different by direction
        ensure ')', cursor: [7, 0]
        ensure ')', cursor: [8, 0]
        ensure ')', cursor: [10, 0]
        ensure ')', cursor: [11, 1]

        ensure ')', cursor: [12, 13]
        ensure ')', cursor: [12, 13]

        ensure '(', cursor: [11, 1]
        ensure '(', cursor: [10, 0]
        ensure '(', cursor: [8, 0]
        ensure '(', cursor: [7, 0]
        ensure '(', cursor: [6, 0] # boundary is different by direction
        ensure '(', cursor: [4, 3]
        ensure '(', cursor: [3, 0]
        ensure '(', cursor: [1, 7]
        ensure '(', cursor: [1, 0]
        ensure '(', cursor: [0, 21]

        ensure '(', cursor: [0, 0]
        ensure '(', cursor: [0, 0]

      it "skips to beginning of sentence", ->
        set cursor: [4, 15]
        ensure '(', cursor: [4, 3]

      it "supports a count", ->
        set cursor: [0, 0]
        ensure '3 )', cursor: [1, 7]
        ensure '3 (', cursor: [0, 0]

      it "can move start of buffer or end of buffer at maximum", ->
        set cursor: [0, 0]
        ensure '2 0 )', cursor: [12, 13]
        ensure '2 0 (', cursor: [0, 0]

      describe "sentence motion with skip-blank-row", ->
        beforeEach ->
          atom.keymaps.add "test",
            'atom-text-editor.vim-mode-plus:not(.insert-mode)':
              'g )': 'vim-mode-plus:move-to-next-sentence-skip-blank-row'
              'g (': 'vim-mode-plus:move-to-previous-sentence-skip-blank-row'

        it "moves the cursor to the end of the sentence", ->
          ensure 'g )', cursor: [0, 21]
          ensure 'g )', cursor: [1, 0]
          ensure 'g )', cursor: [1, 7]
          ensure 'g )', cursor: [4, 3]
          ensure 'g )', cursor: [7, 0]
          ensure 'g )', cursor: [8, 0]
          ensure 'g )', cursor: [11, 1]

          ensure 'g )', cursor: [12, 13]
          ensure 'g )', cursor: [12, 13]

          ensure 'g (', cursor: [11, 1]
          ensure 'g (', cursor: [8, 0]
          ensure 'g (', cursor: [7, 0]
          ensure 'g (', cursor: [4, 3]
          ensure 'g (', cursor: [1, 7]
          ensure 'g (', cursor: [1, 0]
          ensure 'g (', cursor: [0, 21]

          ensure 'g (', cursor: [0, 0]
          ensure 'g (', cursor: [0, 0]

    describe "moving inside a blank document", ->
      beforeEach ->
        set
          text_: """
          _____
          _____
          """

      it "moves without crashing", ->
        set cursor: [0, 0]
        ensure ')', cursor: [1, 4]
        ensure ')', cursor: [1, 4]
        ensure '(', cursor: [0, 0]
        ensure '(', cursor: [0, 0]

    describe "as a selection", ->
      beforeEach ->
        set text: "sentence one. sentence two.\n  sentence three."

      it 'selects to the end of the current sentence', ->
        set cursor: [0, 20]
        ensure 'y )', register: '"': text: "ce two.\n  "

      it 'selects to the beginning of the current sentence', ->
        set cursor: [0, 20]
        ensure 'y (', register: '"': text: "senten"

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
        ensure '3 }', cursor: [14, 0]
        ensure '3 {', cursor: [2, 0]

      it "can move start of buffer or end of buffer at maximum", ->
        set cursor: [0, 0]
        ensure '1 0 }', cursor: [16, 14]
        ensure '1 0 {', cursor: [0, 0]

    describe "as a selection", ->
      it 'selects to the end of the current paragraph', ->
        set cursor: [3, 3]
        ensure 'y }', register: '"': text: "paragraph-1\n4: paragraph-1\n"
      it 'selects to the end of the current paragraph', ->
        set cursor: [4, 3]
        ensure 'y {', register: '"': text: "\n3: paragraph-1\n4: "

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
          ensure 'y b', cursor: [0, 1], register: '"': text: 'a'

      describe "between words", ->
        it "selects to the beginning of the last word", ->
          set cursor: [0, 4]
          ensure 'y b', cursor: [0, 1], register: '"': text: 'ab '

  describe "the B keybinding", ->
    beforeEach ->
      set
        text: """
          cde1+- ab
          \t xyz-123

           zip\n
          """

    describe "as a motion", ->
      beforeEach ->
        set cursor: [4, 0]

      it "moves the cursor to the beginning of the previous word", ->
        ensure 'B', cursor: [3, 1]
        ensure 'B', cursor: [2, 0]
        ensure 'B', cursor: [1, 2]
        ensure 'B', cursor: [0, 7]
        ensure 'B', cursor: [0, 0]

    describe "as a selection", ->
      it "selects to the beginning of the whole word", ->
        set cursor: [1, 8]
        ensure 'y B', register: '"': text: 'xyz-12' # because cursor is on the `3`

      it "doesn't go past the beginning of the file", ->
        set cursor: [0, 0], register: '"': text: 'abc'
        ensure 'y B', register: '"': text: 'abc'

  describe "the ^ keybinding", ->
    beforeEach ->
      set textC: "|  abcde"

    describe "from the beginning of the line", ->
      describe "as a motion", ->
        it "moves the cursor to the first character of the line", ->
          ensure '^', cursor: [0, 2]

      describe "as a selection", ->
        it 'selects to the first character of the line', ->
          ensure 'd ^',
            text: 'abcde'
            cursor: [0, 0]
        it 'selects to the first character of the line', ->
          ensure 'd I', text: 'abcde', cursor: [0, 0]

    describe "from the first character of the line", ->
      beforeEach ->
        set cursor: [0, 2]

      describe "as a motion", ->
        it "stays put", ->
          ensure '^', cursor: [0, 2]

      describe "as a selection", ->
        it "does nothing", ->
          ensure 'd ^',
            text: '  abcde'
            cursor: [0, 2]

    describe "from the middle of a word", ->
      beforeEach ->
        set cursor: [0, 4]

      describe "as a motion", ->
        it "moves the cursor to the first character of the line", ->
          ensure '^', cursor: [0, 2]

      describe "as a selection", ->
        it 'selects to the first character of the line', ->
          ensure 'd ^',
            text: '  cde'
            cursor: [0, 2]
        it 'selects to the first character of the line', ->
          ensure 'd I', text: '  cde', cursor: [0, 2],

  describe "the 0 keybinding", ->
    beforeEach ->
      set text: "  abcde", cursor: [0, 4]

    describe "as a motion", ->
      it "moves the cursor to the first column", ->
        ensure '0', cursor: [0, 0]

    describe "as a selection", ->
      it 'selects to the first column of the line', ->
        ensure 'd 0', text: 'cde', cursor: [0, 0]

  describe "the | keybinding", ->
    beforeEach ->
      set text: "  abcde", cursor: [0, 4]

    describe "as a motion", ->
      it "moves the cursor to the number column", ->
        ensure '|', cursor: [0, 0]
        ensure '1 |', cursor: [0, 0]
        ensure '3 |', cursor: [0, 2]
        ensure '4 |', cursor: [0, 3]

    describe "as operator's target", ->
      it 'behave exclusively', ->
        set cursor: [0, 0]
        ensure 'd 4 |', text: 'bcde', cursor: [0, 0]

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
        ensure '$ j', cursor: [1, 0]
        ensure 'j', cursor: [2, 9]

      it "support count", ->
        ensure '3 $', cursor: [2, 9]

    describe "as a selection", ->
      it "selects to the end of the lines", ->
        ensure 'd $',
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
          ensure 'd -', text: "  abc\n", cursor: [0, 2]

    describe "from the first character of a line indented the same as the previous one", ->
      beforeEach ->
        set cursor: [2, 2]

      describe "as a motion", ->
        it "moves to the first character of the previous line (directly above)", ->
          ensure '-', cursor: [1, 2]

      describe "as a selection", ->
        it "selects to the first character of the previous line (directly above)", ->
          ensure 'd -', text: "abcdefg\n"
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
          ensure 'd -', text: "abcdefg\n"

    describe "with a count", ->
      beforeEach ->
        set
          text: "1\n2\n3\n4\n5\n6\n"
          cursor: [4, 0]

      describe "as a motion", ->
        it "moves the cursor to the first character of that many lines previous", ->
          ensure '3 -', cursor: [1, 0]

      describe "as a selection", ->
        it "deletes the current line plus that many previous lines", ->
          ensure 'd 3 -',
            text: "1\n6\n",
            cursor: [1, 0],

  describe "the + keybinding", ->
    beforeEach ->
      set text_: """
      __abc
      __abc
      abcdefg\n
      """

    describe "from the middle of a line", ->
      beforeEach ->
        set cursor: [1, 3]

      describe "as a motion", ->
        it "moves the cursor to the first character of the next line", ->
          ensure '+', cursor: [2, 0]

      describe "as a selection", ->
        it "deletes the current and next line", ->
          ensure 'd +', text: "  abc\n"

    describe "from the first character of a line indented the same as the next one", ->
      beforeEach -> set cursor: [0, 2]

      describe "as a motion", ->
        it "moves to the first character of the next line (directly below)", ->
          ensure '+', cursor: [1, 2]

      describe "as a selection", ->
        it "selects to the first character of the next line (directly below)", ->
          ensure 'd +', text: "abcdefg\n"

    describe "from the beginning of a line followed by an indented line", ->
      beforeEach -> set cursor: [0, 0]

      describe "as a motion", ->
        it "moves the cursor to the first character of the next line", ->
          ensure '+', cursor: [1, 2]

      describe "as a selection", ->
        it "selects to the first character of the next line", ->
          ensure 'd +',
            text: "abcdefg\n"
            cursor: [0, 0]

    describe "with a count", ->
      beforeEach ->
        set
          text: "1\n2\n3\n4\n5\n6\n"
          cursor: [1, 0]

      describe "as a motion", ->
        it "moves the cursor to the first character of that many lines following", ->
          ensure '3 +', cursor: [4, 0]

      describe "as a selection", ->
        it "deletes the current line plus that many following lines", ->
          ensure 'd 3 +',
            text: "1\n6\n"
            cursor: [1, 0]

  describe "the _ keybinding", ->
    beforeEach ->
      set text_: """
        __abc
        __abc
        abcdefg\n
        """

    describe "from the middle of a line", ->
      beforeEach -> set cursor: [1, 3]

      describe "as a motion", ->
        it "moves the cursor to the first character of the current line", ->
          ensure '_', cursor: [1, 2]

      describe "as a selection", ->
        it "deletes the current line", ->
          ensure 'd _',
            text_: """
            __abc
            abcdefg\n
            """
            cursor: [1, 0]

    describe "with a count", ->
      beforeEach ->
        set
          text: "1\n2\n3\n4\n5\n6\n"
          cursor: [1, 0]

      describe "as a motion", ->
        it "moves the cursor to the first character of that many lines following", ->
          ensure '3 _', cursor: [3, 0]

      describe "as a selection", ->
        it "deletes the current line plus that many following lines", ->
          ensure 'd 3 _',
            text: "1\n5\n6\n"
            cursor: [1, 0]

  describe "the enter keybinding", ->
    # [FIXME] Dirty test, whats this!?
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
          ensure 'enter',
            cursor: referenceCursorPosition

      describe "as a selection", ->
        it "acts the same as the + keybinding", ->
          # do it with + and save the results
          set
            text: startingText
            cursor: startingCursorPosition

          keystroke 'd +'
          referenceText = editor.getText()
          referenceCursorPosition = editor.getCursorScreenPosition()

          set
            text: startingText
            cursor: startingCursorPosition
          ensure 'd enter',
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
          ensure 'g g', cursor: [0, 1]

        it "move to same position if its on first line and first char", ->
          ensure 'g g', cursor: [0, 1]

      describe "in linewise visual mode", ->
        it "selects to the first line in the file", ->
          set cursor: [1, 0]
          ensure 'V g g',
            selectedText: " 1abc\n 2\n"
            cursor: [0, 0]

      describe "in characterwise visual mode", ->
        beforeEach ->
          set cursor: [1, 1]
        it "selects to the first line in the file", ->
          ensure 'v g g',
            selectedText: "1abc\n 2"
            cursor: [0, 1]

    describe "when count specified", ->
      describe "in normal mode", ->
        it "moves the cursor to first char of a specified line", ->
          ensure '2 g g', cursor: [1, 1]

      describe "in linewise visual motion", ->
        it "selects to a specified line", ->
          set cursor: [2, 0]
          ensure 'V 2 g g',
            selectedText: " 2\n3\n"
            cursor: [1, 0]

      describe "in characterwise visual motion", ->
        it "selects to a first character of specified line", ->
          set cursor: [2, 0]
          ensure 'v 2 g g',
            selectedText: "2\n3"
            cursor: [1, 1]

  describe "the g_ keybinding", ->
    beforeEach ->
      set text_: """
        1__
            2__
         3abc
        _
        """

    describe "as a motion", ->
      it "moves the cursor to the last nonblank character", ->
        set cursor: [1, 0]
        ensure 'g _', cursor: [1, 4]

      it "will move the cursor to the beginning of the line if necessary", ->
        set cursor: [0, 2]
        ensure 'g _', cursor: [0, 0]

    describe "as a repeated motion", ->
      it "moves the cursor downward and outward", ->
        set cursor: [0, 0]
        ensure '2 g _', cursor: [1, 4]

    describe "as a selection", ->
      it "selects the current line excluding whitespace", ->
        set cursor: [1, 2]
        ensure 'v 2 g _',
          selectedText: "  2  \n 3abc"

  describe "the G keybinding", ->
    beforeEach ->
      set
        text_: """
        1
        ____2
        _3abc
        _
        """
        cursor: [0, 2]

    describe "as a motion", ->
      it "moves the cursor to the last line after whitespace", ->
        ensure 'G', cursor: [3, 0]

    describe "as a repeated motion", ->
      it "moves the cursor to a specified line", ->
        ensure '2 G', cursor: [1, 4]

    describe "as a selection", ->
      it "selects to the last line in the file", ->
        set cursor: [1, 0]
        ensure 'v G',
          selectedText: "    2\n 3abc\n "
          cursor: [3, 1]

  describe "the N% keybinding", ->
    beforeEach ->
      set
        text: [0..999].join("\n")
        cursor: [0, 0]

    describe "put cursor on line specified by percent", ->
      it "50%", -> ensure '5 0 %', cursor: [499, 0]
      it "30%", -> ensure '3 0 %', cursor: [299, 0]
      it "100%", -> ensure '1 0 0 %', cursor: [999, 0]
      it "120%", -> ensure '1 2 0 %', cursor: [999, 0]

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
        ensure '4 H', cursor: [3, 0]

    describe "the L keybinding", ->
      it "moves the cursor to non-blank-char on last row if visible", ->
        spyOn(editor, 'getLastVisibleScreenRow').andReturn(9)
        ensure 'L', cursor: [9, 2]

      it "moves the cursor to the first visible row plus offset", ->
        spyOn(editor, 'getLastVisibleScreenRow').andReturn(7)
        ensure 'L', cursor: [4, 2]

      it "respects counts", ->
        spyOn(editor, 'getLastVisibleScreenRow').andReturn(9)
        ensure '3 L', cursor: [7, 0]

    describe "the M keybinding", ->
      beforeEach ->
        spyOn(eel, 'getFirstVisibleScreenRow').andReturn(0)
        spyOn(editor, 'getLastVisibleScreenRow').andReturn(10)

      it "moves the cursor to the non-blank-char of middle of screen", ->
        ensure 'M', cursor: [4, 2]

  describe "moveToFirstCharacterOnVerticalMotion setting", ->
    beforeEach ->
      settings.set('moveToFirstCharacterOnVerticalMotion', false)
      set
        text: """
          0 000000000000
          1 111111111111
        2 222222222222\n
        """
        cursor: [2, 10]

    describe "gg, G, N%", ->
      it "go to row with keep column and respect cursor.goalColum", ->
        ensure 'g g', cursor: [0, 10]
        ensure '$', cursor: [0, 15]
        ensure 'G', cursor: [2, 13]
        expect(editor.getLastCursor().goalColumn).toBe(Infinity)
        ensure '1 %', cursor: [0, 15]
        expect(editor.getLastCursor().goalColumn).toBe(Infinity)
        ensure '1 0 h', cursor: [0, 5]
        ensure '5 0 %', cursor: [1, 5]
        ensure '1 0 0 %', cursor: [2, 5]

    describe "H, M, L", ->
      beforeEach ->
        spyOn(editorElement, 'getFirstVisibleScreenRow').andReturn(0)
        spyOn(editor, 'getLastVisibleScreenRow').andReturn(3)

      it "go to row with keep column and respect cursor.goalColum", ->
        ensure 'H', cursor: [0, 10]
        ensure 'M', cursor: [1, 10]
        ensure 'L', cursor: [2, 10]
        ensure '$', cursor: [2, 13]
        expect(editor.getLastCursor().goalColumn).toBe(Infinity)
        ensure 'H', cursor: [0, 15]
        ensure 'M', cursor: [1, 15]
        ensure 'L', cursor: [2, 13]
        expect(editor.getLastCursor().goalColumn).toBe(Infinity)

  describe 'the mark keybindings', ->
    beforeEach ->
      set
        text: """
          12
            34
        56\n
        """
        cursor: [0, 1]

    it 'moves to the beginning of the line of a mark', ->
      set cursor: [1, 1]
      keystroke 'm a'
      set cursor: [0, 0]
      ensure "' a", cursor: [1, 4]

    it 'moves literally to a mark', ->
      set cursor: [1, 2]
      keystroke 'm a'
      set cursor: [0, 0]
      ensure '` a', cursor: [1, 2]

    it 'deletes to a mark by line', ->
      set cursor: [1, 5]
      keystroke 'm a'
      set cursor: [0, 0]
      ensure "d ' a", text: '56\n'

    it 'deletes before to a mark literally', ->
      set cursor: [1, 5]
      keystroke 'm a'
      set cursor: [0, 2]
      ensure 'd ` a', text: '  4\n56\n'

    it 'deletes after to a mark literally', ->
      set cursor: [1, 5]
      keystroke 'm a'
      set cursor: [2, 1]
      ensure 'd ` a', text: '  12\n    36\n'

    it 'moves back to previous', ->
      set cursor: [1, 5]
      keystroke '` `'
      set cursor: [2, 1]
      ensure '` `', cursor: [1, 5]

  describe "jump command update ` and ' mark", ->
    ensureMark = (_keystroke, option) ->
      keystroke(_keystroke)
      ensure cursor: option.cursor
      ensure mark: "`": option.mark
      ensure mark: "'": option.mark

    ensureJumpAndBack = (keystroke, option) ->
      initial = editor.getCursorBufferPosition()
      ensureMark keystroke, cursor: option.cursor, mark: initial
      afterMove = editor.getCursorBufferPosition()
      expect(initial.isEqual(afterMove)).toBe(false)
      ensureMark "` `", cursor: initial, mark: option.cursor

    ensureJumpAndBackLinewise = (keystroke, option) ->
      initial = editor.getCursorBufferPosition()
      expect(initial.column).not.toBe(0)
      ensureMark keystroke, cursor: option.cursor, mark: initial
      afterMove = editor.getCursorBufferPosition()
      expect(initial.isEqual(afterMove)).toBe(false)
      ensureMark "' '", cursor: [initial.row, 0], mark: option.cursor

    beforeEach ->
      for mark in "`'"
        vimState.mark.marks[mark]?.destroy()
        vimState.mark.marks[mark] = null

      set
        text: """
        0: oo 0
        1: 1111
        2: 2222
        3: oo 3
        4: 4444
        5: oo 5
        """
        cursor: [1, 0]

    describe "initial state", ->
      it "return [0, 0]", ->
        ensure mark: "'": [0, 0]
        ensure mark: "`": [0, 0]

    describe "jump motion in normal-mode", ->
      initial = [3, 3]
      beforeEach ->
        jasmine.attachToDOM(getView(atom.workspace)) # for L, M, H

        # TODO: remove when 1.19 become stable
        if editorElement.measureDimensions?
          {component} = editor
          component.element.style.height = component.getLineHeight() * editor.getLineCount() + 'px'
          editorElement.measureDimensions()

        ensure mark: "'": [0, 0]
        ensure mark: "`": [0, 0]
        set cursor: initial

      it "G jump&back", -> ensureJumpAndBack 'G', cursor: [5, 0]
      it "g g jump&back", -> ensureJumpAndBack "g g", cursor: [0, 0]
      it "100 % jump&back", -> ensureJumpAndBack "1 0 0 %", cursor: [5, 0]
      it ") jump&back", -> ensureJumpAndBack ")", cursor: [5, 6]
      it "( jump&back", -> ensureJumpAndBack "(", cursor: [0, 0]
      it "] jump&back", -> ensureJumpAndBack "]", cursor: [5, 3]
      it "[ jump&back", -> ensureJumpAndBack "[", cursor: [0, 3]
      it "} jump&back", -> ensureJumpAndBack "}", cursor: [5, 6]
      it "{ jump&back", -> ensureJumpAndBack "{", cursor: [0, 0]
      it "L jump&back", -> ensureJumpAndBack "L", cursor: [5, 0]
      it "H jump&back", -> ensureJumpAndBack "H", cursor: [0, 0]
      it "M jump&back", -> ensureJumpAndBack "M", cursor: [2, 0]
      it "* jump&back", -> ensureJumpAndBack "*", cursor: [5, 3]

      # [BUG] Strange bug of jasmine or atom's jasmine enhancment?
      # Using subject "# jump & back" skips spec.
      # Note at Atom v1.11.2
      it "Sharp(#) jump&back", -> ensureJumpAndBack('#', cursor: [0, 3])

      it "/ jump&back", -> ensureJumpAndBack ["/", search: 'oo'], cursor: [5, 3]
      it "? jump&back", -> ensureJumpAndBack ["?", search: 'oo'], cursor: [0, 3]

      it "n jump&back", ->
        set cursor: [0, 0]
        ensure ['/', search: 'oo'], cursor: [0, 3]
        ensureJumpAndBack "n", cursor: [3, 3]
        ensureJumpAndBack "N", cursor: [5, 3]

      it "N jump&back", ->
        set cursor: [0, 0]
        ensure ['?', search: 'oo'], cursor: [5, 3]
        ensureJumpAndBack "n", cursor: [3, 3]
        ensureJumpAndBack "N", cursor: [0, 3]

      it "G jump&back linewise", -> ensureJumpAndBackLinewise 'G', cursor: [5, 0]
      it "g g jump&back linewise", -> ensureJumpAndBackLinewise "g g", cursor: [0, 0]
      it "100 % jump&back linewise", -> ensureJumpAndBackLinewise "1 0 0 %", cursor: [5, 0]
      it ") jump&back linewise", -> ensureJumpAndBackLinewise ")", cursor: [5, 6]
      it "( jump&back linewise", -> ensureJumpAndBackLinewise "(", cursor: [0, 0]
      it "] jump&back linewise", -> ensureJumpAndBackLinewise "]", cursor: [5, 3]
      it "[ jump&back linewise", -> ensureJumpAndBackLinewise "[", cursor: [0, 3]
      it "} jump&back linewise", -> ensureJumpAndBackLinewise "}", cursor: [5, 6]
      it "{ jump&back linewise", -> ensureJumpAndBackLinewise "{", cursor: [0, 0]
      it "L jump&back linewise", -> ensureJumpAndBackLinewise "L", cursor: [5, 0]
      it "H jump&back linewise", -> ensureJumpAndBackLinewise "H", cursor: [0, 0]
      it "M jump&back linewise", -> ensureJumpAndBackLinewise "M", cursor: [2, 0]
      it "* jump&back linewise", -> ensureJumpAndBackLinewise "*", cursor: [5, 3]

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
      ensure 'V j j', selectedText: text.getLines([1..3])

    it "selects up a line", ->
      ensure 'V k', selectedText: text.getLines([0..1])

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
        ensure '[ [', cursor: [22, 6]
        ensure '[ [', cursor: [20, 6]
        ensure '[ [', cursor: [18, 4]
        ensure '[ [', cursor: [9, 2]
        ensure '[ [', cursor: [8, 0]

    describe "MoveToNextFoldStart", ->
      beforeEach ->
        set cursor: [0, 0]
      it "move to first char of next fold start row", ->
        ensure '] [', cursor: [8, 0]
        ensure '] [', cursor: [9, 2]
        ensure '] [', cursor: [18, 4]
        ensure '] [', cursor: [20, 6]
        ensure '] [', cursor: [22, 6]

    describe "MoveToPrevisFoldEnd", ->
      beforeEach ->
        set cursor: [30, 0]
      it "move to first char of previous fold end row", ->
        ensure '[ ]', cursor: [28, 2]
        ensure '[ ]', cursor: [25, 4]
        ensure '[ ]', cursor: [23, 8]
        ensure '[ ]', cursor: [21, 8]

    describe "MoveToNextFoldEnd", ->
      beforeEach ->
        set cursor: [0, 0]
      it "move to first char of next fold end row", ->
        ensure '] ]', cursor: [21, 8]
        ensure '] ]', cursor: [23, 8]
        ensure '] ]', cursor: [25, 4]
        ensure '] ]', cursor: [28, 2]

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
        ensure 'g s', cursor: [1, 31]
        ensure 'g s', cursor: [2, 2]
        ensure 'g s', cursor: [2, 21]
        ensure 'g s', cursor: [3, 2]
        ensure 'g s', cursor: [3, 23]
      it "move to previous string", ->
        set cursor: [4, 0]
        ensure 'g S', cursor: [3, 23]
        ensure 'g S', cursor: [3, 2]
        ensure 'g S', cursor: [2, 21]
        ensure 'g S', cursor: [2, 2]
        ensure 'g S', cursor: [1, 31]
      it "support count", ->
        set cursor: [0, 0]
        ensure '3 g s', cursor: [2, 21]
        ensure '3 g S', cursor: [1, 31]

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
        set cursorScreen: [0, 0]
        ensure 'g s', cursorScreen: [2, 7]
        ensure 'g s', cursorScreen: [3, 7]
        ensure 'g s', cursorScreen: [8, 8]
        ensure 'g s', cursorScreen: [9, 8]
        ensure 'g s', cursorScreen: [11, 20]
        ensure 'g s', cursorScreen: [12, 15]
        ensure 'g s', cursorScreen: [13, 15]
        ensure 'g s', cursorScreen: [15, 15]
        ensure 'g s', cursorScreen: [16, 15]
      it "move to previous string", ->
        set cursorScreen: [18, 0]
        ensure 'g S', cursorScreen: [16, 15]
        ensure 'g S', cursorScreen: [15, 15]
        ensure 'g S', cursorScreen: [13, 15]
        ensure 'g S', cursorScreen: [12, 15]
        ensure 'g S', cursorScreen: [11, 20]
        ensure 'g S', cursorScreen: [9, 8]
        ensure 'g S', cursorScreen: [8, 8]
        ensure 'g S', cursorScreen: [3, 7]
        ensure 'g S', cursorScreen: [2, 7]

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
      ensure 'g n', cursor: [0, 7]
      ensure 'g n', cursor: [1, 8]
      ensure 'g n', cursor: [1, 11]
      ensure 'g n', cursor: [1, 16]
      ensure 'g n', cursor: [3, 7]
      ensure 'g n', cursor: [4, 9]
      ensure 'g n', cursor: [4, 12]
    it "move to previous number", ->
      set cursor: [5, 0]
      ensure 'g N', cursor: [4, 12]
      ensure 'g N', cursor: [4, 9]
      ensure 'g N', cursor: [3, 7]
      ensure 'g N', cursor: [1, 16]
      ensure 'g N', cursor: [1, 11]
      ensure 'g N', cursor: [1, 8]
      ensure 'g N', cursor: [0, 7]
    it "support count", ->
      set cursor: [0, 0]
      ensure '5 g n', cursor: [3, 7]
      ensure '3 g N', cursor: [1, 8]

  describe 'subword motion', ->
    beforeEach ->
      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          'q': 'vim-mode-plus:move-to-next-subword'
          'Q': 'vim-mode-plus:move-to-previous-subword'
          'ctrl-e': 'vim-mode-plus:move-to-end-of-subword'

    it "move to next/previous subword", ->
      set textC: "|camelCase => (with special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'q', textC: "camel|Case => (with special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'q', textC: "camelCase| => (with special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'q', textC: "camelCase =>| (with special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'q', textC: "camelCase => (|with special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'q', textC: "camelCase => (with |special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'q', textC: "camelCase => (with special|) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'q', textC: "camelCase => (with special) |ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'q', textC: "camelCase => (with special) Cha|RActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'q', textC: "camelCase => (with special) ChaR|ActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'q', textC: "camelCase => (with special) ChaRActer|Rs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'q', textC: "camelCase => (with special) ChaRActerRs\n\n|dash-case\n\nsnake_case_word\n"
      ensure 'q', textC: "camelCase => (with special) ChaRActerRs\n\ndash|-case\n\nsnake_case_word\n"
      ensure 'q', textC: "camelCase => (with special) ChaRActerRs\n\ndash-|case\n\nsnake_case_word\n"
      ensure 'q', textC: "camelCase => (with special) ChaRActerRs\n\ndash-case\n\n|snake_case_word\n"
      ensure 'q', textC: "camelCase => (with special) ChaRActerRs\n\ndash-case\n\nsnake|_case_word\n"
      ensure 'q', textC: "camelCase => (with special) ChaRActerRs\n\ndash-case\n\nsnake_case|_word\n"
      ensure 'q', textC: "camelCase => (with special) ChaRActerRs\n\ndash-case\n\nsnake_case_wor|d\n"
      ensure 'Q', textC: "camelCase => (with special) ChaRActerRs\n\ndash-case\n\nsnake_case|_word\n"
      ensure 'Q', textC: "camelCase => (with special) ChaRActerRs\n\ndash-case\n\nsnake|_case_word\n"
      ensure 'Q', textC: "camelCase => (with special) ChaRActerRs\n\ndash-case\n\n|snake_case_word\n"
      ensure 'Q', textC: "camelCase => (with special) ChaRActerRs\n\ndash-|case\n\nsnake_case_word\n"
      ensure 'Q', textC: "camelCase => (with special) ChaRActerRs\n\ndash|-case\n\nsnake_case_word\n"
      ensure 'Q', textC: "camelCase => (with special) ChaRActerRs\n\n|dash-case\n\nsnake_case_word\n"
      ensure 'Q', textC: "camelCase => (with special) ChaRActer|Rs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'Q', textC: "camelCase => (with special) ChaR|ActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'Q', textC: "camelCase => (with special) Cha|RActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'Q', textC: "camelCase => (with special) |ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'Q', textC: "camelCase => (with special|) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'Q', textC: "camelCase => (with |special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'Q', textC: "camelCase => (|with special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'Q', textC: "camelCase =>| (with special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'Q', textC: "camelCase| => (with special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'Q', textC: "camel|Case => (with special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'Q', textC: "|camelCase => (with special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
    it "move-to-end-of-subword", ->
      set textC: "|camelCase => (with special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'ctrl-e', textC: "came|lCase => (with special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'ctrl-e', textC: "camelCas|e => (with special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'ctrl-e', textC: "camelCase =|> (with special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'ctrl-e', textC: "camelCase => |(with special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'ctrl-e', textC: "camelCase => (wit|h special) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'ctrl-e', textC: "camelCase => (with specia|l) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'ctrl-e', textC: "camelCase => (with special|) ChaRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'ctrl-e', textC: "camelCase => (with special) Ch|aRActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'ctrl-e', textC: "camelCase => (with special) Cha|RActerRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'ctrl-e', textC: "camelCase => (with special) ChaRActe|rRs\n\ndash-case\n\nsnake_case_word\n"
      ensure 'ctrl-e', textC: "camelCase => (with special) ChaRActerR|s\n\ndash-case\n\nsnake_case_word\n"
      ensure 'ctrl-e', textC: "camelCase => (with special) ChaRActerRs\n\ndas|h-case\n\nsnake_case_word\n"
      ensure 'ctrl-e', textC: "camelCase => (with special) ChaRActerRs\n\ndash|-case\n\nsnake_case_word\n"
      ensure 'ctrl-e', textC: "camelCase => (with special) ChaRActerRs\n\ndash-cas|e\n\nsnake_case_word\n"
      ensure 'ctrl-e', textC: "camelCase => (with special) ChaRActerRs\n\ndash-case\n\nsnak|e_case_word\n"
      ensure 'ctrl-e', textC: "camelCase => (with special) ChaRActerRs\n\ndash-case\n\nsnake_cas|e_word\n"
      ensure 'ctrl-e', textC: "camelCase => (with special) ChaRActerRs\n\ndash-case\n\nsnake_case_wor|d\n"
