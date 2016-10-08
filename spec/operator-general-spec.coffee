{getVimState, dispatch, TextData} = require './spec-helper'
settings = require '../lib/settings'

describe "Operator general", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim

  afterEach ->
    vimState.resetNormalMode()

  describe "cancelling operations", ->
    it "clear pending operation", ->
      keystroke '/'
      expect(vimState.operationStack.isEmpty()).toBe false
      vimState.searchInput.cancel()
      expect(vimState.operationStack.isEmpty()).toBe true
      expect(-> vimState.searchInput.cancel()).not.toThrow()

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
          ensure '2 x', text: 'abc\n0123\n\nxyz', cursor: [1, 3], register: '"': text: '45'
          set cursor: [0, 1]
          ensure '3 x',
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
          ensure '2 x', text: 'abc\n0123\n\nxyz', cursor: [1, 3], register: '"': text: '45'
          set cursor: [0, 1]
          ensure '3 x', text: 'a0123\n\nxyz', cursor: [0, 1], register: '"': text: 'bc\n'
          ensure '7 x', text: 'ayz', cursor: [0, 1], register: '"': text: '0123\n\nx'

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

  describe "the d keybinding", ->
    beforeEach ->
      set
        text: """
          12345
          abcde

          ABCDE\n
          """
        cursor: [1, 1]

    it "enters operator-pending mode", ->
      ensure 'd', mode: 'operator-pending'

    describe "when followed by a d", ->
      it "deletes the current line and exits operator-pending mode", ->
        set cursor: [1, 1]
        ensure 'd d',
          text: """
            12345

            ABCDE\n
            """
          cursor: [1, 0]
          register: '"': text: "abcde\n"
          mode: 'normal'

      it "deletes the last line and always make non-blank-line last line", ->
        set cursor: [2, 0]
        ensure '2 d d',
          text: """
            12345
            abcde\n
            """,
          cursor: [1, 0]

      it "leaves the cursor on the first nonblank character", ->
        set
          text: """
          12345
            abcde\n
          """
          cursor: [0, 4]
        ensure 'd d',
          text: "  abcde\n"
          cursor: [0, 2]

    describe "undo behavior", ->
      originalText = "12345\nabcde\nABCDE\nQWERT"
      beforeEach ->
        set text: originalText, cursor: [1, 1]

      it "undoes both lines", ->
        ensure 'd 2 d u', text: originalText, selectedText: ''

      describe "with multiple cursors", ->
        beforeEach ->
          set cursor: [[1, 1], [0, 0]]

        describe "setCursorToStartOfChangeOnUndoRedo is true(default)", ->
          # [FIXME] Should keep cursor?. so guranularity is not perfect in multi-cursors
          # And ensure set position to start.
          it "is undone as one operation and clear cursors", ->
            ensure 'd l u',
              text: originalText
              selectedText: ['']
              numCursors: 1

        describe "setCursorToStartOfChangeOnUndoRedo is false", ->
          beforeEach ->
            settings.set('setCursorToStartOfChangeOnUndoRedo', false)

          it "is undone as one operation", ->
            ensure 'd l u',
              text: originalText
              selectedText: ['', '']
              numCursors: 2

    describe "when followed by a w", ->
      it "deletes the next word until the end of the line and exits operator-pending mode", ->
        set text: 'abcd efg\nabc', cursor: [0, 5]
        ensure 'd w',
          text: "abcd \nabc"
          cursor: [0, 4]
          mode: 'normal'

      it "deletes to the beginning of the next word", ->
        set text: 'abcd efg', cursor: [0, 2]
        ensure 'd w', text: 'abefg', cursor: [0, 2]
        set text: 'one two three four', cursor: [0, 0]
        ensure 'd 3 w', text: 'four', cursor: [0, 0]

    describe "when followed by an iw", ->
      it "deletes the containing word", ->
        set text: "12345 abcde ABCDE", cursor: [0, 9]

        ensure 'd',
          mode: 'operator-pending'

        ensure 'i w',
          text: "12345  ABCDE"
          cursor: [0, 6]
          register: '"': text: 'abcde'
          mode: 'normal'

    describe "when followed by a j", ->
      originalText = """
        12345
        abcde
        ABCDE\n
        """

      beforeEach ->
        set text: originalText

      describe "on the beginning of the file", ->
        it "deletes the next two lines", ->
          set cursor: [0, 0]
          ensure 'd j', text: 'ABCDE\n'

      describe "on the middle of second line", ->
        it "deletes the last two lines", ->
          set cursor: [1, 2]
          ensure 'd j', text: '12345\n'

      describe "when cursor is on blank line", ->
        beforeEach ->
          set
            text: """
              a


              b\n
              """
            cursor: [1, 0]
        it "deletes both lines", ->
          ensure 'd j', text: "a\nb\n", cursor: [1, 0]

    describe "when followed by an k", ->
      originalText = """
        12345
        abcde
        ABCDE
        """

      beforeEach ->
        set text: originalText

      describe "on the end of the file", ->
        it "deletes the bottom two lines", ->
          set cursor: [2, 4]
          ensure 'd k', text: '12345\n'

      describe "on the beginning of the file", ->
        xit "deletes nothing", ->
          set cursor: [0, 0]
          ensure 'd k', text: originalText

      describe "when on the middle of second line", ->
        it "deletes the first two lines", ->
          set cursor: [1, 2]
          ensure 'd k', text: 'ABCDE'

      describe "when cursor is on blank line", ->
        beforeEach ->
          set
            text: """
              a


              b\n
              """
            cursor: [2, 0]
        it "deletes both lines", ->
          ensure 'd k', text: "a\nb\n", cursor: [1, 0]

      # [TODO] write more generic operator test. #119
      # This is general behavior of all operator.
      # When it cant move, its target selection should be empty so nothing happen.
      xdescribe "when it can't move", ->
        textOriginal = "a\nb\n"
        cursorOriginal = [0, 0]
        it "deletes delete nothing", ->
          set text: textOriginal, cursor: cursorOriginal
          ensure 'd k', text: textOriginal, cursor: cursorOriginal

    describe "when followed by a G", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE"
        set text: originalText

      describe "on the beginning of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 0]
          ensure 'd G', text: '12345\n'

      describe "on the middle of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 2]
          ensure 'd G', text: '12345\n'

    describe "when followed by a goto line G", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE"
        set text: originalText

      describe "on the beginning of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 0]
          ensure 'd 2 G', text: '12345\nABCDE'

      describe "on the middle of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 2]
          ensure 'd 2 G', text: '12345\nABCDE'

    describe "when followed by a t)", ->
      describe "with the entire line yanked before", ->
        beforeEach ->
          set text: "test (xyz)", cursor: [0, 6]

        it "deletes until the closing parenthesis", ->
          ensure ['y y d t', input: ')'],
            text: 'test ()'
            cursor: [0, 6]

    describe "with multiple cursors", ->
      it "deletes each selection", ->
        set
          text: """
            abcd
            1234
            ABCD\n
            """
          cursorBuffer: [[0, 1], [1, 2], [2, 3]]

        ensure 'd e',
          text: "a\n12\nABC"
          cursorBuffer: [[0, 0], [1, 1], [2, 2]]

      it "doesn't delete empty selections", ->
        set
          text: "abcd\nabc\nabd"
          cursorBuffer: [[0, 0], [1, 0], [2, 0]]

        ensure ['d t', input: 'd'],
          text: "d\nabc\nd"
          cursorBuffer: [[0, 0], [1, 0], [2, 0]]

    describe "stayOnDelete setting", ->
      beforeEach ->
        settings.set('stayOnDelete', true)
        set
          text_: """
          ___3333
          __2222
          _1111
          __2222
          ___3333\n
          """
          cursor: [0, 3]
          # "___3333\n__2222\n1111\n__2222\n___3333"

      describe "target range is linewise range", ->
        it "keep original column after delete", ->
          ensure "d d", cursor: [0, 3], text_: "__2222\n_1111\n__2222\n___3333\n"
          ensure ".", cursor: [0, 3], text_: "_1111\n__2222\n___3333\n"
          ensure ".", cursor: [0, 3], text_: "__2222\n___3333\n"
          ensure ".", cursor: [0, 3], text_: "___3333\n"

        it "v_D also keep original column after delete", ->
          ensure "v 2 j D", cursor: [0, 3], text_: "__2222\n___3333\n"

      describe "target range is text object", ->
        describe "target is indent", ->
          indentText = """
          0000000000000000
            22222222222222
            22222222222222
            22222222222222
          0000000000000000\n
          """
          textData = new TextData(indentText)
          beforeEach ->
            set
              text: textData.getRaw()

          it "[from top] keep column", ->
            set cursor: [1, 10]
            ensure 'd i i', cursor: [1, 10], text: textData.getLines([0, 4])
          it "[from middle] keep column", ->
            set cursor: [2, 10]
            ensure 'd i i', cursor: [1, 10], text: textData.getLines([0, 4])
          it "[from bottom] keep column", ->
            set cursor: [3, 10]
            ensure 'd i i', cursor: [1, 10], text: textData.getLines([0, 4])

        describe "target is paragraph", ->
          paragraphText = """
            p1---------------
            p1---------------
            p1---------------

            p2---------------
            p2---------------
            p2---------------

            p3---------------
            p3---------------
            p3---------------\n
            """

          textData = new TextData(paragraphText)
          P1 = [0, 1, 2]
          B1 = 3
          P2 = [4, 5, 6]
          B2 = 7
          P3 = [8, 9, 10]
          B3 = 11

          beforeEach ->
            set
              text: textData.getRaw()

          it "set cursor to start of deletion after delete [from bottom of paragraph]", ->
            set cursor: [0, 0]
            ensure 'd i p', cursor: [0, 0], text: textData.getLines([B1..B3], chomp: true)
            ensure 'j .', cursor: [1, 0], text: textData.getLines([B1, B2, P3..., B3], chomp: true)
            ensure 'j .', cursor: [1, 0], text: textData.getLines([B1, B2, B3], chomp: true)
          it "set cursor to start of deletion after delete [from middle of paragraph]", ->
            set cursor: [1, 0]
            ensure 'd i p', cursor: [0, 0], text: textData.getLines([B1..B3], chomp: true)
            ensure '2 j .', cursor: [1, 0], text: textData.getLines([B1, B2, P3..., B3], chomp: true)
            ensure '2 j .', cursor: [1, 0], text: textData.getLines([B1, B2, B3], chomp: true)
          it "set cursor to start of deletion after delete [from bottom of paragraph]", ->
            set cursor: [1, 0]
            ensure 'd i p', cursor: [0, 0], text: textData.getLines([B1..B3], chomp: true)
            ensure '3 j .', cursor: [1, 0], text: textData.getLines([B1, B2, P3..., B3], chomp: true)
            ensure '3 j .', cursor: [1, 0], text: textData.getLines([B1, B2, B3], chomp: true)


  describe "the D keybinding", ->
    beforeEach ->
      set
        text: """
        0000
        1111
        2222
        3333
        """
        cursor: [0, 1]

    it "deletes the contents until the end of the line", ->
      ensure 'D', text: "0\n1111\n2222\n3333"

    it "in visual-mode, it delete whole line", ->
      ensure 'v D', text: "1111\n2222\n3333"
      ensure "v j D", text: "3333"

  describe "the y keybinding", ->
    beforeEach ->
      set text: "012 345\nabc\n", cursor: [0, 4]

    describe "when selected lines in visual linewise mode", ->
      beforeEach ->
        keystroke 'V j y'

      it "is in linewise motion", ->
        ensure register: '"': type: 'linewise'

      it "saves the lines to the default register", ->
        ensure register: '"': text: "012 345\nabc\n"

      it "places the cursor at the beginning of the selection", ->
        ensure cursorBuffer: [0, 0]

    describe "when followed by a second y ", ->
      beforeEach ->
        keystroke 'y y'

      it "saves the line to the default register", ->
        ensure register: '"': text: "012 345\n"

      it "leaves the cursor at the starting position", ->
        ensure cursor: [0, 4]

    describe "when useClipboardAsDefaultRegister enabled", ->
      it "writes to clipboard", ->
        settings.set 'useClipboardAsDefaultRegister', true
        keystroke 'y y'
        expect(atom.clipboard.read()).toBe '012 345\n'

    describe "when followed with a repeated y", ->
      beforeEach ->
        keystroke 'y 2 y'

      it "copies n lines, starting from the current", ->
        ensure register: '"': text: "012 345\nabc\n"

      it "leaves the cursor at the starting position", ->
        ensure cursor: [0, 4]

    describe "with a register", ->
      beforeEach ->
        keystroke ['"', input: 'a', 'y y']

      it "saves the line to the a register", ->
        ensure register: a: text: "012 345\n"

      it "appends the line to the A register", ->
        ensure ['"', input: 'A', 'y y'],
          register: a: text: "012 345\n012 345\n"

    describe "with a forward motion", ->
      beforeEach ->
        keystroke 'y e'

      it "saves the selected text to the default register", ->
        ensure register: '"': text: '345'

      it "leaves the cursor at the starting position", ->
        ensure cursor: [0, 4]

      it "does not yank when motion fails", ->
        ensure ['y t', input: 'x'],
          register: '"': text: '345'

    describe "with a text object", ->
      it "moves the cursor to the beginning of the text object", ->
        set cursorBuffer: [0, 5]
        ensure 'y i w', cursorBuffer: [0, 4]

    describe "with a left motion", ->
      beforeEach ->
        keystroke 'y h'

      it "saves the left letter to the default register", ->
        ensure register: '"': text: ' '

      it "moves the cursor position to the left", ->
        ensure cursor: [0, 3]

    describe "with a down motion", ->
      beforeEach ->
        keystroke 'y j'

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
          ensure 'y G P', text: '12345\nabcde\nABCDE\nabcde\nABCDE'

      describe "on the middle of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 2]
          ensure 'y G P', text: '12345\nabcde\nABCDE\nabcde\nABCDE'

    describe "when followed by a goto line G", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE"
        set text: originalText

      describe "on the beginning of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 0]
          ensure 'y 2 G P', text: '12345\nabcde\nabcde\nABCDE'

      describe "on the middle of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 2]
          ensure 'y 2 G P', text: '12345\nabcde\nabcde\nABCDE'

    describe "with multiple cursors", ->
      it "moves each cursor and copies the last selection's text", ->
        set
          text: "  abcd\n  1234"
          cursorBuffer: [[0, 0], [1, 5]]
        ensure 'y ^',
          register: '"': text: '123'
          cursorBuffer: [[0, 0], [1, 2]]

    describe "stayOnYank setting", ->
      text = null
      beforeEach ->
        settings.set('stayOnYank', true)

        text = new TextData """
          0_234567
          1_234567
          2_234567

          4_234567\n
          """
        set text: text.getRaw(), cursor: [1, 2]

      it "don't move cursor after yank from normal-mode", ->
        ensure "y i p", cursorBuffer: [1, 2], register: '"': text: text.getLines([0..2])
        ensure "j y y", cursorBuffer: [2, 2], register: '"': text: text.getLines([2])
        ensure "k .", cursorBuffer: [1, 2], register: '"': text: text.getLines([1])

      it "don't move cursor after yank from visual-linewise", ->
        ensure "V y", cursorBuffer: [1, 2], register: '"': text: text.getLines([1])
        ensure "V j y", cursorBuffer: [2, 2], register: '"': text: text.getLines([1..2])

      it "don't move cursor after yank from visual-characterwise", ->
        ensure "v l l y", cursorBuffer: [1, 4], register: '"': text: "234"
        ensure "v h h y", cursorBuffer: [1, 2], register: '"': text: "234"
        ensure "v j y", cursorBuffer: [2, 2], register: '"': text: "234567\n2_2"
        ensure "v 2 k y", cursorBuffer: [0, 2], register: '"': text: "234567\n1_234567\n2_2"

  describe "the yy keybinding", ->
    describe "on a single line file", ->
      beforeEach ->
        set text: "exclamation!\n", cursor: [0, 0]

      it "copies the entire line and pastes it correctly", ->
        ensure 'y y p',
          register: '"': text: "exclamation!\n"
          text: "exclamation!\nexclamation!\n"

    describe "on a single line file with no newline", ->
      beforeEach ->
        set text: "no newline!", cursor: [0, 0]

      it "copies the entire line and pastes it correctly", ->
        ensure 'y y p',
          register: '"': text: "no newline!\n"
          text: "no newline!\nno newline!"

      it "copies the entire line and pastes it respecting count and new lines", ->
        ensure 'y y 2 p',
          register: '"': text: "no newline!\n"
          text: "no newline!\nno newline!\nno newline!"

  describe "the Y keybinding", ->
    text = """
    012 345
    abc\n
    """
    beforeEach ->
      set
        text: text
        cursor: [0, 4]

    it "saves the line to the default register", ->
      ensure 'Y', cursor: [0, 4], register: '"': text: "012 345\n"

    it "yank the whole lines to the default register", ->
      ensure 'v j Y', cursor: [0, 0], register: '"': text: text

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

      describe "paste to empty line", ->
        it "paste content to that empty line", ->
          set
            text: """
            1st

            3rd
            """
            cursor: [1, 0]
            register: '"': text: '2nd'
          ensure 'p',
            text: """
            1st
            2nd
            3rd
            """

      describe "when useClipboardAsDefaultRegister enabled", ->
        it "inserts contents from clipboard", ->
          settings.set 'useClipboardAsDefaultRegister', true
          ensure 'p', text: "0clip12\n"

      describe "from a specified register", ->
        beforeEach ->
          keystroke ['"', input: 'a', 'p']

        it "inserts the contents of the 'a' register", ->
          ensure text: "0a12\n", cursor: [0, 1]

      describe "at the end of a line", ->
        it "inserts before the current line's newline", ->
          set text: "abcde\none two three", cursor: [1, 4]
          ensure 'd $ k $ p', text: "abcdetwo three\none "

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
          ensure 'v p',
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
        keystroke '2 p'

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
          text: '012\n'
          cursor: [0, 1]
      describe "with characterwise selection", ->
        it "replaces selection with charwise content", ->
          set register: '"': text: "345"
          ensure 'v p', text: "03452\n", cursor: [0, 3]
        it "replaces selection with linewise content", ->
          set register: '"': text: "345\n"
          ensure 'v p', text: "0\n345\n2\n", cursor: [1, 0]

      describe "with linewise selection", ->
        it "replaces selection with charwise content", ->
          set text: "012\nabc", cursor: [0, 1]
          set register: '"': text: "345"
          ensure 'V p', text: "345\nabc", cursor: [0, 0]
        it "replaces selection with linewise content", ->
          set register: '"': text: "345\n"
          ensure 'V p', text: "345\n", cursor: [0, 0]

  describe "the P keybinding", ->
    describe "with character contents", ->
      beforeEach ->
        set text: "012\n", cursor: [0, 0]
        set register: '"': text: '345'
        set register: a: text: 'a'
        keystroke 'P'

      it "inserts the contents of the default register above", ->
        ensure text: "345012\n", cursor: [0, 2]

  describe "PutAfterAndSelect and PutBeforeAndSelect", ->
    beforeEach ->
      atom.keymaps.add "text",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          'g p': 'vim-mode-plus:put-after-and-select'
          'g P': 'vim-mode-plus:put-before-and-select'
      set
        text: """
          111
          222
          333

          """
        cursor: [1, 0]
    describe "in visual-mode", ->
      describe "linewise register", ->
        beforeEach ->
          set register: '"': text: "AAA\n"
        it "paste and select: [selection:linewise]", ->
          ensure 'V g p', text: "111\nAAA\n333\n", selectedText: "AAA\n", mode: ['visual', 'linewise']
        it "paste and select: [selection:charwise, register:linewise]", ->
          ensure 'v g P', text: "111\n\nAAA\n22\n333\n", selectedText: "AAA\n", mode: ['visual', 'linewise']

      describe "characterwise register", ->
        beforeEach ->
          set register: '"': text: "AAA"
        it "paste and select: [selection:linewise, register:charwise]", ->
          ensure 'V g p', text: "111\nAAA\n333\n", selectedText: "AAA\n", mode: ['visual', 'linewise']
        it "paste and select: [selection:charwise, register:charwise]", ->
          ensure 'v g P', text: "111\nAAA22\n333\n", selectedText: "AAA", mode: ['visual', 'characterwise']

    describe "in normal", ->
      describe "linewise register", ->
        beforeEach ->
          set register: '"': text: "AAA\n"
        it "putAfter and select", ->
          ensure 'g p', text: "111\n222\nAAA\n333\n", selectedText: "AAA\n", mode: ['visual', 'linewise']
        it "putBefore and select", ->
          ensure 'g P', text: "111\nAAA\n222\n333\n", selectedText: "AAA\n", mode: ['visual', 'linewise']
      describe "characterwise register", ->
        beforeEach ->
          set register: '"': text: "AAA"
        it "putAfter and select", ->
          ensure 'g p', text: "111\n2AAA22\n333\n", selectedText: "AAA", mode: ['visual', 'characterwise']
        it "putAfter and select", ->
          ensure 'g P', text: "111\nAAA222\n333\n", selectedText: "AAA", mode: ['visual', 'characterwise']

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
        keystroke '2 J'

      describe "undo behavior", ->
        beforeEach -> keystroke 'u'

        it "handles repeats", ->
          ensure text: "12345\nabcde\nABCDE\nQWERT"

  describe "the . keybinding", ->
    beforeEach ->
      set text: "12\n34\n56\n78", cursor: [0, 0]

    it "repeats the last operation", ->
      ensure '2 d d .', text: ""

    it "composes with motions", ->
      ensure 'd d 2 .', text: "78"

  describe "the r keybinding", ->
    beforeEach ->
      set
        text: """
        12
        34
        \n
        """
        cursorBuffer: [[0, 0], [1, 0]]

    it "replaces a single character", ->
      ensure ['r', input: 'x'], text: 'x2\nx4\n\n'

    it "does nothing when cancelled", ->
      ensure 'r',
        mode: 'operator-pending'
      vimState.input.cancel()
      ensure
        text: '12\n34\n\n'
        mode: 'normal'

    it "remain visual-mode when cancelled", ->
      keystroke 'v r'
      vimState.input.cancel()
      ensure
        text: '12\n34\n\n'
        mode: ['visual', 'characterwise']

    it "replaces a single character with a line break", ->
      inputEditorElement = vimState.input.editorElement
      keystroke 'r'
      dispatch(inputEditorElement, 'core:confirm')
      ensure
        text: '\n2\n\n4\n\n'
        cursorBuffer: [[1, 0], [3, 0]]

    it "composes properly with motions", ->
      ensure ['2 r', input: 'x'], text: 'xx\nxx\n\n'

    it "does nothing on an empty line", ->
      set cursorBuffer: [2, 0]
      ensure ['r', input: 'x'], text: '12\n34\n\n'

    it "does nothing if asked to replace more characters than there are on a line", ->
      ensure ['3 r', input: 'x'], text: '12\n34\n\n'

    describe "when in visual mode", ->
      beforeEach ->
        keystroke 'v e'

      it "replaces the entire selection with the given character", ->
        ensure ['r', input: 'x'], text: 'xx\nxx\n\n'

      it "leaves the cursor at the beginning of the selection", ->
        ensure ['r', input: 'x' ], cursorBuffer: [[0, 0], [1, 0]]

    describe "when in visual-block mode", ->
      textOriginal = """
        0:2345
        1: o11o
        2: o22o
        3: o33o
        4: o44o\n
        """
      textReplaced = """
        0:2345
        1: oxxo
        2: oxxo
        3: oxxo
        4: oxxo\n
        """
      textRepeated = """
        0:2345
        xx oxxo
        xx oxxo
        xx oxxo
        xx oxxo\n
        """

      beforeEach ->
        set text: textOriginal, cursor: [1, 4]
        ensure 'ctrl-v l 3 j',
          mode: ['visual', 'blockwise']
          selectedTextOrdered: ['11', '22', '33', '44'],

      # [FIXME]
      xit "replaces each selection and put cursor on start of top selection", ->
        ensure ['r', input: 'x'],
          mode: 'normal'
          text: textReplaced
          cursor: [1, 4]
        set cursor: [1, 0]
        ensure '.',
          mode: 'normal'
          text: textRepeated
          cursor: [1, 0]

  describe 'the m keybinding', ->
    beforeEach ->
      set text: '12\n34\n56\n', cursorBuffer: [0, 1]

    it 'marks a position', ->
      keystroke 'm a'
      expect(vimState.mark.get('a')).toEqual [0, 1]

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

      ensure 'backspace', text: "12fooa45\n67890"
      editor.insertText "c"
      ensure text: "12fooac5\n67890"
      ensure 'backspace backspace',
        text: "12foo345\n67890"
        selectedText: ''

      ensure 'backspace',
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
      keystroke 'backspace'
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
        ensure 'backspace',
          text: """
            0a
            b
            34
            56789
            """
          cursor: [2, 0]
        ensure 'backspace',
          text: """
            0a
            b34
            56789
            """
          cursor: [1, 1]
        ensure 'backspace',
          text: """
            0a
            234
            56789
            """
          cursor: [1, 0]
        ensure 'backspace',
          text: """
            0a234
            56789
            """
          cursor: [0, 2]
        ensure 'backspace',
          text: """
            01234
            56789
            """
          cursor: [0, 1]
        ensure 'backspace', # do nothing
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
      it "repeate multiline text case-1", ->
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
        ensure 'j .',
          text: """
            abc
            def
            56abc
            def
            """
          cursor: [3, 2]
          mode: 'normal'
      it "repeate multiline text case-2", ->
        ensure 'R', mode: ['insert', 'replace']
        editor.insertText "abc\nd"
        ensure
          text: """
            abc
            d4
            56789
            """
          cursor: [1, 1]
        ensure 'escape', cursor: [1, 0], mode: 'normal'
        ensure 'j .',
          text: """
          abc
          d4
          abc
          d9
          """
          cursor: [3, 0]
          mode: 'normal'
