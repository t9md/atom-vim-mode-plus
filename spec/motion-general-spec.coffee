{Point} = require 'atom'
{getVimState, dispatch, TextData, getView} = require './spec-helper'
settings = require '../lib/settings'

setEditorWidthInCharacters = (editor, widthInCharacters) ->
  editor.setDefaultCharWidth(1)
  component = editor.component
  component.element.style.width =
    component.getGutterContainerWidth() + widthInCharacters * component.measurements.baseCharacterWidth + "px"
  return component.getNextUpdatePromise()

describe "Motion general", ->
  [set, ensure, ensureWait, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, _vim) ->
      vimState = state # to refer as vimState later.
      {editor, editorElement} = vimState
      {set, ensure, ensureWait} = _vim

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
          ensure 'escape'
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

      it "by `j`",   -> ensureBigCountMotion 'j',   cursor: [2, 2]
      it "by `k`",   -> ensureBigCountMotion 'k',   cursor: [0, 2]
      it "by `h`",   -> ensureBigCountMotion 'h',   cursor: [1, 0]
      it "by `l`",   -> ensureBigCountMotion 'l',   cursor: [1, 3]
      it "by `[`",   -> ensureBigCountMotion '[',   cursor: [0, 2]
      it "by `]`",   -> ensureBigCountMotion ']',   cursor: [2, 2]
      it "by `w`",   -> ensureBigCountMotion 'w',   cursor: [2, 3]
      it "by `W`",   -> ensureBigCountMotion 'W',   cursor: [2, 3]
      it "by `b`",   -> ensureBigCountMotion 'b',   cursor: [0, 0]
      it "by `B`",   -> ensureBigCountMotion 'B',   cursor: [0, 0]
      it "by `e`",   -> ensureBigCountMotion 'e',   cursor: [2, 3]
      it "by `(`",   -> ensureBigCountMotion '(',   cursor: [0, 0]
      it "by `)`",   -> ensureBigCountMotion ')',   cursor: [2, 3]
      it "by `{`",   -> ensureBigCountMotion '{',   cursor: [0, 0]
      it "by `}`",   -> ensureBigCountMotion '}',   cursor: [2, 3]
      it "by `-`",   -> ensureBigCountMotion '-',   cursor: [0, 0]
      it "by `_`",   -> ensureBigCountMotion '_',   cursor: [2, 0]
      it "by `g {`", -> ensureBigCountMotion 'g {', cursor: [1, 2] # No fold no move but won't freeze.
      it "by `g }`", -> ensureBigCountMotion 'g }', cursor: [1, 2] # No fold no move but won't freeze.
      it "by `, N`", -> ensureBigCountMotion ', N', cursor: [1, 2] # No grammar, no move but won't freeze.
      it "by `, n`", -> ensureBigCountMotion ', n', cursor: [1, 2] # No grammar, no move but won't freeze.
      it "by `y y`", -> ensureBigCountMotion 'y y', cursor: [1, 2]

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
        set
          textC: """
          0: aaaa
          1: bbbb
          2: cccc

          4:\n
          """
        set cursor: [1, 2]

      describe "when wrapLeftRightMotion = false(=default)", ->
        it "[normal] move to right, count support, but not wrap to next-line", ->
          set cursor: [0, 0]
          ensure 'l', cursor: [0, 1]
          ensure 'l', cursor: [0, 2]
          ensure '2 l', cursor: [0, 4]
          ensure '5 l', cursor: [0, 6]
          ensure 'l', cursor: [0, 6] # no wrap
        it "[normal: at-blank-row] not wrap to next line", ->
          set cursor: [3, 0]
          ensure 'l', cursor: [3, 0], mode: "normal"
        it "[visual: at-last-char] can select newline but not wrap to next-line", ->
          set cursor: [0, 6]
          ensure "v", selectedText: "a", mode: ['visual', 'characterwise'], cursor: [0, 7]
          expect(editor.getLastCursor().isAtEndOfLine()).toBe(true)
          ensure "l", selectedText: "a\n", mode: ['visual', 'characterwise'], cursor: [1, 0]
          ensure "l", selectedText: "a\n", mode: ['visual', 'characterwise'], cursor: [1, 0]
        it "[visual: at-blank-row] can select newline but not wrap to next-line", ->
          set cursor: [3, 0]
          ensure "v", selectedText: "\n", mode: ['visual', 'characterwise'], cursor: [4, 0]
          ensure "l", selectedText: "\n", mode: ['visual', 'characterwise'], cursor: [4, 0]

      describe "when wrapLeftRightMotion = true", ->
        beforeEach ->
          settings.set('wrapLeftRightMotion', true)

        it "[normal: at-last-char] moves the cursor to the next line", ->
          set cursor: [0, 6]
          ensure 'l', cursor: [1, 0], mode: "normal"
        it "[normal: at-blank-row] wrap to next line", ->
          set cursor: [3, 0]
          ensure 'l', cursor: [4, 0], mode: "normal"
        it "[visual: at-last-char] select newline then move to next-line", ->
          set cursor: [0, 6]
          ensure "v", selectedText: "a", mode: ['visual', 'characterwise'], cursor: [0, 7]
          expect(editor.getLastCursor().isAtEndOfLine()).toBe(true)
          ensure "l", selectedText: "a\n", mode: ['visual', 'characterwise'], cursor: [1, 0]
          ensure "l", selectedText: "a\n1", mode: ['visual', 'characterwise'], cursor: [1, 1]
        it "[visual: at-blank-row] move to next-line", ->
          set cursor: [3, 0]
          ensure "v", selectedText: "\n", mode: ['visual', 'characterwise'], cursor: [4, 0]
          ensure "l", selectedText: "\n4", mode: ['visual', 'characterwise'], cursor: [4, 1]

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
          it "move cursor if it's stoppable", ->
            ensure '[', cursor: [0, 2]
            ensure ']', cursor: [4, 2]

          it "doesn't move cursor if it's NOT stoppable", ->
            set
              text_: """
              __
              ____this is text of line 1
              ____this is text of line 2
              ______hello line 3
              ______hello line 4
              __
              """
              cursor: [2, 2]
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
            {set, ensure} = vimEditor

          runs ->
            set cursorScreen: [8, 2]
            # In hardTab indent bufferPosition is not same as screenPosition
            ensure null, cursor: [8, 1]

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
      ensure null, register: {'"': text: undefined}

    describe "moveSuccessOnLinewise=false motion", ->
      describe "when it can move", ->
        beforeEach -> set cursor: [1, 0]
        it "delete by j", -> ensure "d j", text: "000\n", mode: 'normal'
        it "yank by j", ->   ensure "y j", text: originalText, register: {'"': text: "111\n222\n"}, mode: 'normal'
        it "change by j", -> ensure "c j", textC: "000\n|\n", register: {'"': text: "111\n222\n"}, mode: 'insert'

        it "delete by k", -> ensure "d k", text: "222\n", mode: 'normal'
        it "yank by k", ->   ensure "y k", text: originalText, register: {'"': text: "000\n111\n"}, mode: 'normal'
        it "change by k", -> ensure "c k", textC: "|\n222\n", register: {'"': text: "000\n111\n"}, mode: 'insert'

      describe "when it can not move-up", ->
        beforeEach -> set cursor: [0, 0]
        it "delete by dk", -> ensure "d k", text: originalText, mode: 'normal'
        it "yank by yk", ->   ensure "y k", text: originalText, register: {'"': text: undefined}, mode: 'normal'
        it "change by ck", -> ensure "c k", textC: "|000\n111\n222\n", register: {'"': text: undefined}, mode: 'normal'

      describe "when it can not move-down", ->
        beforeEach -> set cursor: [2, 0]
        it "delete by dj", -> ensure "d j", text: originalText, mode: 'normal'
        it "yank by yj", ->   ensure "y j", text: originalText, register: {'"': text: undefined}, mode: 'normal'
        it "change by cj", -> ensure "c j", textC: "000\n111\n|222\n", register: {'"': text: undefined}, mode: 'normal'

    describe "moveSuccessOnLinewise=true motion", ->
      describe "when it can move", ->
        beforeEach -> set cursor: [1, 0]
        it "delete by G", -> ensure "d G", text: "000\n", mode: 'normal'
        it "yank by G", ->   ensure "y G", text: originalText, register: {'"': text: "111\n222\n"}, mode: 'normal'
        it "change by G", -> ensure "c G", textC: "000\n|\n", register: {'"': text: "111\n222\n"}, mode: 'insert'

        it "delete by gg", -> ensure "d g g", text: "222\n", mode: 'normal'
        it "yank by gg", ->   ensure "y g g", text: originalText, register: {'"': text: "000\n111\n"}, mode: 'normal'
        it "change by gg", -> ensure "c g g", textC: "|\n222\n", register: {'"': text: "000\n111\n"}, mode: 'insert'

      describe "when it can not move-up", ->
        beforeEach -> set cursor: [0, 0]
        it "delete by gg", -> ensure "d g g", text: "111\n222\n", mode: 'normal'
        it "yank by gg", ->   ensure "y g g", text: originalText, register: {'"': text: "000\n"}, mode: 'normal'
        it "change by gg", -> ensure "c g g", textC: "|\n111\n222\n", register: {'"': text: "000\n"}, mode: 'insert'
      describe "when it can not move-down", ->
        beforeEach -> set cursor: [2, 0]
        it "delete by G", ->  ensure "d G", text: "000\n111\n", mode: 'normal'
        it "yank by G", ->    ensure "y G", text: originalText, register: {'"': text: "222\n"}, mode: 'normal'
        it "change by G", ->  ensure "c G", textC: "000\n111\n|\n", register: {'"': text: "222\n"}, mode: 'insert'

  describe "the w keybinding", ->
    describe "as a motion", ->
      it "moves the cursor to the beginning of the next word", ->
        set         textC: "|ab cde1+-\n xyz\n\nzip"
        ensure "w", textC: "ab |cde1+-\n xyz\n\nzip"
        ensure "w", textC: "ab cde1|+-\n xyz\n\nzip"
        ensure "w", textC: "ab cde1+-\n |xyz\n\nzip"
        ensure "w", textC: "ab cde1+-\n xyz\n|\nzip"
        ensure "w", textC: "ab cde1+-\n xyz\n\n|zip"
        ensure "w", textC: "ab cde1+-\n xyz\n\nzi|p"
        ensure "w", textC: "ab cde1+-\n xyz\n\nzi|p" # Do nothing at vimEOF

      it "[CRLF] moves the cursor to the beginning of the next word", ->
        set         textC: "|ab cde1+-\r\n xyz\r\n\r\nzip"
        ensure "w", textC: "ab |cde1+-\r\n xyz\r\n\r\nzip"
        ensure "w", textC: "ab cde1|+-\r\n xyz\r\n\r\nzip"
        ensure "w", textC: "ab cde1+-\r\n |xyz\r\n\r\nzip"
        ensure "w", textC: "ab cde1+-\r\n xyz\r\n|\r\nzip"
        ensure "w", textC: "ab cde1+-\r\n xyz\r\n\r\n|zip"
        ensure "w", textC: "ab cde1+-\r\n xyz\r\n\r\nzi|p"
        ensure "w", textC: "ab cde1+-\r\n xyz\r\n\r\nzi|p" # Do nothing at vimEOF

      it "move to next word by skipping trailing white spaces", ->
        set         textC: "012|   \n  234"
        ensure "w", textC: "012   \n  |234"

      it "move to next word from EOL", ->
        set         textC: "|\n  234"
        ensure "w", textC: "\n  |234"

    describe "used as change TARGET", ->
      it "[at-word] not eat whitespace", ->
        set           textC: "v|ar1 = 1"
        ensure 'c w', textC: "v = 1"

      it "[at white-space] only eat white space", ->
        set           textC: "|  var1 = 1"
        ensure 'c w', textC: "var1 = 1"

      it "[at trailing whitespace] doesnt eat new line character", ->
        set           textC: "abc|  \ndef"
        ensure 'c w', textC: "abc|\ndef"

      it "[at trailing whitespace] eat new line when count is specified", ->
        set             textC: "|\n\n\n\n\nline6\n"
        ensure '5 c w', textC: "|\nline6\n"

    describe "as a selection", ->
      it "[within-word] selects to the end of the word", ->
        set textC: "|ab cd"
        ensure 'y w', register: '"': text: 'ab '

      it "[between-word] selects the whitespace", ->
        set textC: "ab| cd"
        ensure 'y w', register: '"': text: ' '

  describe "the W keybinding", ->
    describe "as a motion", ->
      it "moves the cursor to the beginning of the next word", ->
        set         textC: "|cde1+- ab \n xyz\n\nzip"
        ensure "W", textC: "cde1+- |ab \n xyz\n\nzip"
        ensure "W", textC: "cde1+- ab \n |xyz\n\nzip"
        ensure "W", textC: "cde1+- ab \n xyz\n|\nzip"
        ensure "W", textC: "cde1+- ab \n xyz\n\n|zip"
        ensure "W", textC: "cde1+- ab \n xyz\n\nzi|p"
        ensure "W", textC: "cde1+- ab \n xyz\n\nzi|p" # Do nothing at vimEOF

      it "[at-trailing-WS] moves the cursor to beginning of the next word at next line", ->
        set         textC: "012|   \n  234"
        ensure 'W', textC: "012   \n  |234"

      it "moves the cursor to beginning of the next word of next line when cursor is at EOL.", ->
        set         textC: "|\n  234"
        ensure 'W', textC: "\n  |234"

    # This spec is redundant since W(MoveToNextWholeWord) is child of w(MoveToNextWord).
    describe "used as change TARGET", ->
      it "[at-word] not eat whitespace", ->
        set           textC: "v|ar1 = 1"
        ensure 'c W', textC: "v| = 1"

      it "[at-WS] only eat white space", ->
        set           textC: "|  var1 = 1"
        ensure 'c W', textC: "var1 = 1"

      it "[at-trailing-WS] doesn't eat new line character", ->
        set           textC: "abc|  \ndef\n"
        ensure 'c W', textC: "abc|\ndef\n"

      it "can eat new line when count is specified", ->
        set             textC: "|\n\n\n\n\nline6\n"
        ensure '5 c W', textC: "|\nline6\n"

    describe "as a TARGET", ->
      it "[at-word] yank", ->
        set textC: "|cde1+- ab"
        ensure 'y W', register: '"': text: 'cde1+- '

      it "delete new line", ->
        set           textC: "cde1+- ab \n xyz\n|\nzip"
        ensure 'd W', textC: "cde1+- ab \n xyz\n|zip", register: {'"': text: "\n"}

      it "delete last word in buffer and adjut cursor row to not past vimLastRow", ->
        set           textC: "cde1+- ab \n xyz\n\n|zip"
        ensure 'd W', textC: "cde1+- ab \n xyz\n|\n", register: {'"': text: "zip"}

  describe "the e keybinding", ->
    describe "as a motion", ->
      it "moves the cursor to the end of the current word", ->
        set         textC_: "|ab cde1+-_\n_xyz\n\nzip"
        ensure 'e', textC_: "a|b cde1+-_\n_xyz\n\nzip"
        ensure 'e', textC_: "ab cde|1+-_\n_xyz\n\nzip"
        ensure 'e', textC_: "ab cde1+|-_\n_xyz\n\nzip"
        ensure 'e', textC_: "ab cde1+-_\n_xy|z\n\nzip"
        ensure 'e', textC_: "ab cde1+-_\n_xyz\n\nzi|p"

      it "skips whitespace until EOF", ->
        set         textC: "|012\n\n\n012\n\n"
        ensure 'e', textC: "01|2\n\n\n012\n\n"
        ensure 'e', textC: "012\n\n\n01|2\n\n"
        ensure 'e', textC: "012\n\n\n012\n|\n"

    describe "as selection", ->
      it "[in-word] selects to the end of the current word", ->
        set textC_: "|ab cde1+-_"
        ensure 'y e', register: '"': text: 'ab'

      it "[between-word] selects to the end of the next word", ->
        set textC_: "ab| cde1+-_"
        ensure 'y e', register: '"': text: ' cde1'

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

  describe "the ge keybinding", ->
    describe "as a motion", ->
      it "moves the cursor to the end of the previous word", ->
        set           textC: "1234 5678 wordwo|rd"
        ensure "g e", textC: "1234 567|8 wordword"
        ensure "g e", textC: "123|4 5678 wordword"
        ensure "g e", textC: "|1234 5678 wordword"
        ensure "g e", textC: "|1234 5678 wordword"

      it "moves corrently when starting between words", ->
        set           textC: "1 leading   |  end"
        ensure 'g e', textC: "1 leadin|g     end"

      it "takes a count", ->
        set             textC: "vim mode plus is getting the|re"
        ensure '5 g e', textC: "vi|m mode plus is getting there"

      it "handles non-words inside words like vim", ->
        set           textC: "1234 5678 word-wor|d"
        ensure 'g e', textC: "1234 5678 word|-word"
        ensure 'g e', textC: "1234 5678 wor|d-word"
        ensure 'g e', textC: "1234 567|8 word-word"

      it "handles newlines like vim", ->
        set           textC: "1234\n\n\n\n56|78"
        ensure "g e", textC: "1234\n\n\n|\n5678"
        ensure "g e", textC: "1234\n\n|\n\n5678"
        ensure "g e", textC: "1234\n|\n\n\n5678"
        ensure "g e", textC: "123|4\n\n\n\n5678"
        ensure "g e", textC: "|1234\n\n\n\n5678"

    describe "when used by Change operator", ->
      it "changes word fragments", ->
        set text: "cet document", cursor: [0, 7]
        ensure 'c g e', cursor: [0, 2], text: "cement", mode: 'insert'
        # TODO: I'm not sure how to check the register after checking the document
        # ensure null, register: '"', text: 't docu'

      it "changes whitespace properly", ->
        set text: "ce    doc", cursor: [0, 4]
        ensure 'c g e', cursor: [0, 1], text: "c doc", mode: 'insert'

    describe "in characterwise visual mode", ->
      it "selects word fragments", ->
        set text: "cet document", cursor: [0, 7]
        ensure 'v g e', cursor: [0, 2], selectedText: "t docu"

  describe "the gE keybinding", ->
    describe "as a motion", ->
      it "moves the cursor to the end of the previous word", ->
        set textC: "12.4 5~7- word-w|ord"
        ensure 'g E', textC: "12.4 5~7|- word-word"
        ensure 'g E', textC: "12.|4 5~7- word-word"
        ensure 'g E', textC: "|12.4 5~7- word-word"
        ensure 'g E', textC: "|12.4 5~7- word-word"

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
        set         cursor: [4, 15]
        ensure '(', cursor: [4, 3]

      it "supports a count", ->
        set           cursor: [0, 0]
        ensure '3 )', cursor: [1, 7]
        ensure '3 (', cursor: [0, 0]

      it "can move start of buffer or end of buffer at maximum", ->
        set             cursor: [0, 0]
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
        set         cursor: [0, 0]
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
        set         cursor: [0, 0]
        ensure '}', cursor: [5, 0]
        ensure '}', cursor: [9, 0]
        ensure '}', cursor: [14, 0]
        ensure '{', cursor: [11, 0]
        ensure '{', cursor: [7, 0]
        ensure '{', cursor: [2, 0]

      it "support count", ->
        set           cursor: [0, 0]
        ensure '3 }', cursor: [14, 0]
        ensure '3 {', cursor: [2, 0]

      it "can move start of buffer or end of buffer at maximum", ->
        set             cursor: [0, 0]
        ensure '1 0 }', cursor: [16, 14]
        ensure '1 0 {', cursor: [0, 0]

    describe "as a selection", ->
      it 'selects to the end of the current paragraph', ->
        set cursor: [3, 3]
        ensure 'y }', register: '"': text: "paragraph-1\n4: paragraph-1\n"
      it 'selects to the end of the current paragraph', ->
        set cursor: [4, 3]
        ensure 'y {', register: '"': text: "\n3: paragraph-1\n4: "

  describe "MoveToNextDiffHunk, MoveToPreviousDiffHunk", ->
    beforeEach ->
      set
        text: """
        --- file        2017-12-24 15:11:33.000000000 +0900
        +++ file-new    2017-12-24 15:15:09.000000000 +0900
        @@ -1,9 +1,9 @@
         line 0
        +line 0-1
         line 1
        -line 2
        +line 1-1
         line 3
        -line 4
         line 5
        -line 6
        -line 7
        +line 7-1
        +line 7-2
         line 8\n
        """
        cursor: [0, 0]

      runs ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            ']': 'vim-mode-plus:move-to-next-diff-hunk'
            '[': 'vim-mode-plus:move-to-previous-diff-hunk'

    it "move to next and previous hunk", ->
      ensure ']', cursor: [1, 0]
      ensure ']', cursor: [4, 0]
      ensure ']', cursor: [6, 0]
      ensure ']', cursor: [7, 0]
      ensure ']', cursor: [9, 0]
      ensure ']', cursor: [11, 0]
      ensure ']', cursor: [13, 0]
      ensure ']', cursor: [13, 0]

      ensure '[', cursor: [11, 0]
      ensure '[', cursor: [9, 0]
      ensure '[', cursor: [7, 0]
      ensure '[', cursor: [6, 0]
      ensure '[', cursor: [4, 0]
      ensure '[', cursor: [1, 0]
      ensure '[', cursor: [0, 0]
      ensure '[', cursor: [0, 0]

  describe "the b keybinding", ->
    beforeEach ->
      set
        textC_: """
        _ab cde1+-_
        _xyz

        zip }
        _|last
        """

    describe "as a motion", ->
      it "moves the cursor to the beginning of the previous word", ->
        ensure 'b', textC: " ab cde1+- \n xyz\n\nzip |}\n last"
        ensure 'b', textC: " ab cde1+- \n xyz\n\n|zip }\n last"
        ensure 'b', textC: " ab cde1+- \n xyz\n|\nzip }\n last"
        ensure 'b', textC: " ab cde1+- \n |xyz\n\nzip }\n last"
        ensure 'b', textC: " ab cde1|+- \n xyz\n\nzip }\n last"
        ensure 'b', textC: " ab |cde1+- \n xyz\n\nzip }\n last"
        ensure 'b', textC: " |ab cde1+- \n xyz\n\nzip }\n last"

        # Go to start of the file, after moving past the first word
        ensure 'b', textC: "| ab cde1+- \n xyz\n\nzip }\n last"
        # Do nothing
        ensure 'b', textC: "| ab cde1+- \n xyz\n\nzip }\n last"

    describe "as a selection", ->
      describe "within a word", ->
        it "selects to the beginning of the current word", ->
          set textC: " a|b cd"; ensure 'y b', textC: " |ab cd", register: '"': text: 'a'

      describe "between words", ->
        it "selects to the beginning of the last word", ->
          set textC: " ab |cd"; ensure 'y b', textC: " |ab cd", register: '"': text: 'ab '

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
          ensure 'd ^', text: 'abcde', cursor: [0, 0]
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
      set textC: "  ab|cde"

    describe "as a motion", ->
      it "moves the cursor to the first column", ->
        ensure '0', cursor: [0, 0]

    describe "as a selection", ->
      it 'selects to the first column of the line', ->
        ensure 'd 0', text: 'cde', cursor: [0, 0]

  describe "g 0, g ^ and g $", ->
    enableSoftWrapAndEnsure = ->
      editor.setSoftWrapped(true)
      expect(editor.lineTextForScreenRow(0)).toBe(" 1234567")
      expect(editor.lineTextForScreenRow(1)).toBe(" 89B1234") # first space is softwrap indentation
      expect(editor.lineTextForScreenRow(2)).toBe(" 56789C1") # first space is softwrap indentation
      expect(editor.lineTextForScreenRow(3)).toBe(" 2345678") # first space is softwrap indentation
      expect(editor.lineTextForScreenRow(4)).toBe(" 9") # first space is softwrap indentation

    beforeEach ->
      # Force scrollbars to be visible regardless of local system configuration
      scrollbarStyle = document.createElement('style')
      scrollbarStyle.textContent = '::-webkit-scrollbar { -webkit-appearance: none }'
      jasmine.attachToDOM(scrollbarStyle)


      set text_: """
      _123456789B123456789C123456789
      """
      jasmine.attachToDOM(getView(atom.workspace))
      waitsForPromise ->
        setEditorWidthInCharacters(editor, 10)

    describe "the g 0 keybinding", ->
      describe "allowMoveToOffScreenColumnOnScreenLineMotion = true(default)", ->
        beforeEach -> settings.set('allowMoveToOffScreenColumnOnScreenLineMotion', true)

        describe "softwrap = false, firstColumnIsVisible = true", ->
          beforeEach -> set cursor: [0, 3]
          it "move to column 0 of screen line", -> ensure "g 0", cursor: [0, 0]

        describe "softwrap = false, firstColumnIsVisible = false", ->
          beforeEach -> set cursor: [0, 15]; editor.setFirstVisibleScreenColumn(10)
          it "move to column 0 of screen line", -> ensure "g 0", cursor: [0, 0]

        describe "softwrap = true", ->
          beforeEach -> enableSoftWrapAndEnsure()
          it "move to column 0 of screen line", ->
            set cursorScreen: [0, 3]; ensure "g 0", cursorScreen: [0, 0]
            set cursorScreen: [1, 3]; ensure "g 0", cursorScreen: [1, 1] # skip softwrap indentation.

      describe "allowMoveToOffScreenColumnOnScreenLineMotion = false", ->
        beforeEach -> settings.set('allowMoveToOffScreenColumnOnScreenLineMotion', false)

        describe "softwrap = false, firstColumnIsVisible = true", ->
          beforeEach -> set cursor: [0, 3]
          it "move to column 0 of screen line", -> ensure "g 0", cursor: [0, 0]

        describe "softwrap = false, firstColumnIsVisible = false", ->
          beforeEach -> set cursor: [0, 15]; editor.setFirstVisibleScreenColumn(10)
          it "move to first visible colum of screen line", -> ensure "g 0", cursor: [0, 10]

        describe "softwrap = true", ->
          beforeEach -> enableSoftWrapAndEnsure()
          it "move to column 0 of screen line", ->
            set cursorScreen: [0, 3]; ensure "g 0", cursorScreen: [0, 0]
            set cursorScreen: [1, 3]; ensure "g 0", cursorScreen: [1, 1] # skip softwrap indentation.

    describe "the g ^ keybinding", ->
      describe "allowMoveToOffScreenColumnOnScreenLineMotion = true(default)", ->
        beforeEach -> settings.set('allowMoveToOffScreenColumnOnScreenLineMotion', true)

        describe "softwrap = false, firstColumnIsVisible = true", ->
          beforeEach -> set cursor: [0, 3]
          it "move to first-char of screen line", -> ensure "g ^", cursor: [0, 1]

        describe "softwrap = false, firstColumnIsVisible = false", ->
          beforeEach -> set cursor: [0, 15]; editor.setFirstVisibleScreenColumn(10)
          it "move to first-char of screen line", -> ensure "g ^", cursor: [0, 1]

        describe "softwrap = true", ->
          beforeEach -> enableSoftWrapAndEnsure()
          it "move to first-char of screen line", ->
            set cursorScreen: [0, 3]; ensure "g ^", cursorScreen: [0, 1]
            set cursorScreen: [1, 3]; ensure "g ^", cursorScreen: [1, 1] # skip softwrap indentation.

      describe "allowMoveToOffScreenColumnOnScreenLineMotion = false", ->
        beforeEach -> settings.set('allowMoveToOffScreenColumnOnScreenLineMotion', false)

        describe "softwrap = false, firstColumnIsVisible = true", ->
          beforeEach -> set cursor: [0, 3]
          it "move to first-char of screen line", -> ensure "g ^", cursor: [0, 1]

        describe "softwrap = false, firstColumnIsVisible = false", ->
          beforeEach -> set cursor: [0, 15]; editor.setFirstVisibleScreenColumn(10)
          it "move to first-char of screen line", -> ensure "g ^", cursor: [0, 10]

        describe "softwrap = true", ->
          beforeEach -> enableSoftWrapAndEnsure()
          it "move to first-char of screen line", ->
            set cursorScreen: [0, 3]; ensure "g ^", cursorScreen: [0, 1]
            set cursorScreen: [1, 3]; ensure "g ^", cursorScreen: [1, 1] # skip softwrap indentation.

    describe "the g $ keybinding", ->
      describe "allowMoveToOffScreenColumnOnScreenLineMotion = true(default)", ->
        beforeEach -> settings.set('allowMoveToOffScreenColumnOnScreenLineMotion', true)

        describe "softwrap = false, lastColumnIsVisible = true", ->
          beforeEach -> set cursor: [0, 27]
          it "move to last-char of screen line", -> ensure "g $", cursor: [0, 29]

        describe "softwrap = false, lastColumnIsVisible = false", ->
          beforeEach -> set cursor: [0, 15]; editor.setFirstVisibleScreenColumn(10)
          it "move to last-char of screen line", -> ensure "g $", cursor: [0, 29]

        describe "softwrap = true", ->
          beforeEach -> enableSoftWrapAndEnsure()
          it "move to last-char of screen line", ->
            set cursorScreen: [0, 3]; ensure "g $", cursorScreen: [0, 7]
            set cursorScreen: [1, 3]; ensure "g $", cursorScreen: [1, 7]

      describe "allowMoveToOffScreenColumnOnScreenLineMotion = false", ->
        beforeEach -> settings.set('allowMoveToOffScreenColumnOnScreenLineMotion', false)

        describe "softwrap = false, lastColumnIsVisible = true", ->
          beforeEach -> set cursor: [0, 27]
          it "move to last-char of screen line", -> ensure "g $", cursor: [0, 29]

        describe "softwrap = false, lastColumnIsVisible = false", ->
          beforeEach -> set cursor: [0, 15]; editor.setFirstVisibleScreenColumn(10)
          it "move to last-char in visible screen line", -> ensure "g $", cursor: [0, 18]

        describe "softwrap = true", ->
          beforeEach -> enableSoftWrapAndEnsure()
          it "move to last-char of screen line", ->
            set cursorScreen: [0, 3]; ensure "g $", cursorScreen: [0, 7]
            set cursorScreen: [1, 3]; ensure "g $", cursorScreen: [1, 7]

  describe "the | keybinding", ->
    beforeEach ->
      set text: "  abcde", cursor: [0, 4]

    describe "as a motion", ->
      it "moves the cursor to the number column", ->
        ensure '|',   cursor: [0, 0]
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
        set         cursor: [1, 0]
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
        ensure 'j',   cursor: [2, 9]

      it "support count", ->
        ensure '3 $', cursor: [2, 9]

    describe "as a selection", ->
      it "selects to the end of the lines", ->
        ensure 'd $',
          text: "  ab\n\n1234567890"
          cursor: [0, 3]

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
          # FIXME commented out because the column is wrong due to a bug in `k`; re-enable when `k` is fixed
          # ensure null, cursor: [0, 2]

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
          ensure '+'
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

          ensure 'd +'
          referenceText = editor.getText()
          referenceCursorPosition = editor.getCursorScreenPosition()

          set
            text: startingText
            cursor: startingCursorPosition
          ensure 'd enter',
            text: referenceText
            cursor: referenceCursorPosition

  describe "the gg keybinding with stayOnVerticalMotion = false", ->
    beforeEach ->
      settings.set('stayOnVerticalMotion', false)
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
          set           cursor: [2, 0]
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
        set           cursor: [1, 0]
        ensure 'g _', cursor: [1, 4]

      it "will move the cursor to the beginning of the line if necessary", ->
        set           cursor: [0, 2]
        ensure 'g _', cursor: [0, 0]

    describe "as a repeated motion", ->
      it "moves the cursor downward and outward", ->
        set             cursor: [0, 0]
        ensure '2 g _', cursor: [1, 4]

    describe "as a selection", ->
      it "selects the current line excluding whitespace", ->
        set cursor: [1, 2]
        ensure 'v 2 g _',
          selectedText: "  2  \n 3abc"

  describe "the G keybinding (stayOnVerticalMotion = false)", ->
    beforeEach ->
      settings.set('stayOnVerticalMotion', false)
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
      it "50%", ->  ensure '5 0 %',   cursor: [499, 0]
      it "30%", ->  ensure '3 0 %',   cursor: [299, 0]
      it "100%", -> ensure '1 0 0 %', cursor: [999, 0]
      it "120%", -> ensure '1 2 0 %', cursor: [999, 0]

  describe "the H, M, L keybinding( stayOnVerticalMotio = false )", ->
    beforeEach ->
      settings.set('stayOnVerticalMotion', false)

      set
        textC: """
            1
          2
          3
          4
            5
          6
          7
          8
          |9
            10
          """

    describe "the H keybinding", ->
      beforeEach ->
        spyOn(editor, 'getLastVisibleScreenRow').andReturn(9)

      it "moves the cursor to the non-blank-char on first row if visible", ->
        spyOn(editor, 'getFirstVisibleScreenRow').andReturn(0)
        ensure 'H', cursor: [0, 2]

      it "moves the cursor to the non-blank-char on first visible row plus scroll offset", ->
        spyOn(editor, 'getFirstVisibleScreenRow').andReturn(2)
        ensure 'H', cursor: [4, 2]

      it "respects counts", ->
        spyOn(editor, 'getFirstVisibleScreenRow').andReturn(0)
        ensure '4 H', cursor: [3, 0]

    describe "the L keybinding", ->
      beforeEach ->
        spyOn(editor, 'getFirstVisibleScreenRow').andReturn(0)

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
        spyOn(editor, 'getFirstVisibleScreenRow').andReturn(0)
        spyOn(editor, 'getLastVisibleScreenRow').andReturn(9)

      it "moves the cursor to the non-blank-char of middle of screen", ->
        ensure 'M', cursor: [4, 2]

  describe "stayOnVerticalMotion setting", ->
    beforeEach ->
      settings.set('stayOnVerticalMotion', true)
      set
        text: """
          0 000000000000
          1 111111111111
        2 222222222222\n
        """
        cursor: [2, 10]

    describe "gg, G, N%", ->
      it "go to row with keep column and respect cursor.goalColum", ->
        ensure 'g g',     cursor: [0, 10]
        ensure '$',       cursor: [0, 15]
        ensure 'G',       cursor: [2, 13]
        expect(editor.getLastCursor().goalColumn).toBe(Infinity)
        ensure '1 %',     cursor: [0, 15]
        expect(editor.getLastCursor().goalColumn).toBe(Infinity)
        ensure '1 0 h',   cursor: [0, 5]
        ensure '5 0 %',   cursor: [1, 5]
        ensure '1 0 0 %', cursor: [2, 5]

    describe "H, M, L", ->
      beforeEach ->
        spyOn(editor, 'getFirstVisibleScreenRow').andReturn(0)
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
      runs -> set cursor: [1, 1]; ensureWait 'm a'
      runs -> set cursor: [0, 0]; ensure "' a", cursor: [1, 4]

    it 'moves literally to a mark', ->
      runs -> set cursor: [1, 2]; ensureWait 'm a'
      runs -> set cursor: [0, 0]; ensure '` a', cursor: [1, 2]

    it 'deletes to a mark by line', ->
      runs -> set cursor: [1, 5]; ensureWait 'm a'
      runs -> set cursor: [0, 0]; ensure "d ' a", text: '56\n'

    it 'deletes before to a mark literally', ->
      runs -> set cursor: [1, 5]; ensureWait 'm a'
      runs -> set cursor: [0, 2]; ensure 'd ` a', text: '  4\n56\n'

    it 'deletes after to a mark literally', ->
      runs -> set cursor: [1, 5]; ensureWait 'm a'
      runs -> set cursor: [2, 1]; ensure 'd ` a', text: '  12\n    36\n'

    it 'moves back to previous', ->
      set cursor: [1, 5]
      ensure '` `'
      set cursor: [2, 1]
      ensure '` `', cursor: [1, 5]

  describe "jump command update ` and ' mark", ->
    ensureJumpMark = (value) ->
      ensure null, mark: "`": value
      ensure null, mark: "'": value

    ensureJumpAndBack = (keystroke, option) ->
      afterMove = option.cursor
      beforeMove = editor.getCursorBufferPosition()

      ensure keystroke, cursor: afterMove
      ensureJumpMark(beforeMove)

      expect(beforeMove.isEqual(afterMove)).toBe(false)

      ensure "` `", cursor: beforeMove
      ensureJumpMark(afterMove)

    ensureJumpAndBackLinewise = (keystroke, option) ->
      afterMove = option.cursor
      beforeMove = editor.getCursorBufferPosition()

      expect(beforeMove.column).not.toBe(0)

      ensure keystroke, cursor: afterMove
      ensureJumpMark(beforeMove)

      expect(beforeMove.isEqual(afterMove)).toBe(false)

      ensure "' '", cursor: [beforeMove.row, 0]
      ensureJumpMark(afterMove)

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
        ensure null, mark: "'": [0, 0]
        ensure null, mark: "`": [0, 0]

    describe "jump motion in normal-mode", ->
      initial = [3, 3]
      beforeEach ->
        jasmine.attachToDOM(getView(atom.workspace)) # for L, M, H

        # TODO: remove when 1.19 become stable
        if editorElement.measureDimensions?
          {component} = editor
          component.element.style.height = component.getLineHeight() * editor.getLineCount() + 'px'
          editorElement.measureDimensions()

        ensure null, mark: "'": [0, 0]
        ensure null, mark: "`": [0, 0]
        set cursor: initial

      it "G jump&back", -> ensureJumpAndBack 'G', cursor: [5, 3]
      it "g g jump&back", -> ensureJumpAndBack "g g", cursor: [0, 3]
      it "100 % jump&back", -> ensureJumpAndBack "1 0 0 %", cursor: [5, 3]
      it ") jump&back", -> ensureJumpAndBack ")", cursor: [5, 6]
      it "( jump&back", -> ensureJumpAndBack "(", cursor: [0, 0]
      it "] jump&back", -> ensureJumpAndBack "]", cursor: [5, 3]
      it "[ jump&back", -> ensureJumpAndBack "[", cursor: [0, 3]
      it "} jump&back", -> ensureJumpAndBack "}", cursor: [5, 6]
      it "{ jump&back", -> ensureJumpAndBack "{", cursor: [0, 0]
      it "L jump&back", -> ensureJumpAndBack "L", cursor: [5, 3]
      it "H jump&back", -> ensureJumpAndBack "H", cursor: [0, 3]
      it "M jump&back", -> ensureJumpAndBack "M", cursor: [2, 3]
      it "* jump&back", -> ensureJumpAndBack "*", cursor: [5, 3]

      # [BUG] Strange bug of jasmine or atom's jasmine enhancment?
      # Using subject "# jump & back" skips spec.
      # Note at Atom v1.11.2
      it "Sharp(#) jump&back", -> ensureJumpAndBack('#', cursor: [0, 3])

      it "/ jump&back", -> ensureJumpAndBack '/ oo enter', cursor: [5, 3]
      it "? jump&back", -> ensureJumpAndBack '? oo enter', cursor: [0, 3]

      it "n jump&back", ->
        set cursor: [0, 0]
        ensure '/ oo enter', cursor: [0, 3]
        ensureJumpAndBack "n", cursor: [3, 3]
        ensureJumpAndBack "N", cursor: [5, 3]

      it "N jump&back", ->
        set cursor: [0, 0]
        ensure '? oo enter', cursor: [5, 3]
        ensureJumpAndBack "n", cursor: [3, 3]
        ensureJumpAndBack "N", cursor: [0, 3]

      it "G jump&back linewise", -> ensureJumpAndBackLinewise 'G', cursor: [5, 3]
      it "g g jump&back linewise", -> ensureJumpAndBackLinewise "g g", cursor: [0, 3]
      it "100 % jump&back linewise", -> ensureJumpAndBackLinewise "1 0 0 %", cursor: [5, 3]
      it ") jump&back linewise", -> ensureJumpAndBackLinewise ")", cursor: [5, 6]
      it "( jump&back linewise", -> ensureJumpAndBackLinewise "(", cursor: [0, 0]
      it "] jump&back linewise", -> ensureJumpAndBackLinewise "]", cursor: [5, 3]
      it "[ jump&back linewise", -> ensureJumpAndBackLinewise "[", cursor: [0, 3]
      it "} jump&back linewise", -> ensureJumpAndBackLinewise "}", cursor: [5, 6]
      it "{ jump&back linewise", -> ensureJumpAndBackLinewise "{", cursor: [0, 0]
      it "L jump&back linewise", -> ensureJumpAndBackLinewise "L", cursor: [5, 3]
      it "H jump&back linewise", -> ensureJumpAndBackLinewise "H", cursor: [0, 3]
      it "M jump&back linewise", -> ensureJumpAndBackLinewise "M", cursor: [2, 3]
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
        {set, ensure} = vim

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
          {set, ensure} = vimEditor

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
