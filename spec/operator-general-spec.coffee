{getVimState, dispatch, TextData} = require './spec-helper'
settings = require '../lib/settings'

describe "Operator general", ->
  [set, ensure, ensureWait, bindEnsureOption, bindEnsureWaitOption] = []
  [editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, ensureWait, bindEnsureOption, bindEnsureWaitOption} = vim

  describe "cancelling operations", ->
    it "clear pending operation", ->
      ensure '/'
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
          textC: """
          1234|5
            abcde\n
          """
        ensure 'd d',
          textC: "  |abcde\n"

    describe "undo behavior", ->
      [originalText, initialTextC] = []
      beforeEach ->
        initialTextC = """
          12345
          a|bcde
          ABCDE
          QWERT
          """
        set textC: initialTextC
        originalText = editor.getText()

      it "undoes both lines", ->
        ensure 'd 2 d',
          textC: """
          12345
          |QWERT
          """
        ensure 'u',
          textC: initialTextC
          selectedText: ""

      describe "with multiple cursors", ->
        describe "setCursorToStartOfChangeOnUndoRedo is true(default)", ->
          it "clear multiple cursors and set cursor to start of changes of last cursor", ->
            set
              text: originalText
              cursor: [[0, 0], [1, 1]]

            ensure 'd l',
              textC: """
              |2345
              a|cde
              ABCDE
              QWERT
              """

            ensure 'u',
              textC: """
              12345
              a|bcde
              ABCDE
              QWERT
              """
              selectedText: ''

            ensure 'ctrl-r',
              textC: """
              2345
              a|cde
              ABCDE
              QWERT
              """
              selectedText: ''

          it "clear multiple cursors and set cursor to start of changes of last cursor", ->
            set
              text: originalText
              cursor: [[1, 1], [0, 0]]

            ensure 'd l',
              text: """
              2345
              acde
              ABCDE
              QWERT
              """
              cursor: [[1, 1], [0, 0]]

            ensure 'u',
              textC: """
              |12345
              abcde
              ABCDE
              QWERT
              """
              selectedText: ''

            ensure 'ctrl-r',
              textC: """
              |2345
              acde
              ABCDE
              QWERT
              """
              selectedText: ''

        describe "setCursorToStartOfChangeOnUndoRedo is false", ->
          initialTextC = null

          beforeEach ->
            initialTextC = """
              |12345
              a|bcde
              ABCDE
              QWERT
              """

            settings.set('setCursorToStartOfChangeOnUndoRedo', false)
            set textC: initialTextC
            ensure 'd l',
              textC: """
              |2345
              a|cde
              ABCDE
              QWERT
              """

          it "put cursor to end of change (works in same way of atom's core:undo)", ->
            ensure 'u',
              textC: initialTextC
              selectedText: ['', '']

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

        ensure 'd', mode: 'operator-pending'

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
          ensure 'd t )',
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
          cursor: [[0, 1], [1, 2], [2, 3]]

        ensure 'd e',
          text: "a\n12\nABC"
          cursor: [[0, 0], [1, 1], [2, 2]]

      it "doesn't delete empty selections", ->
        set
          text: "abcd\nabc\nabd"
          cursor: [[0, 0], [1, 0], [2, 0]]

        ensure 'd t d',
          text: "d\nabc\nd"
          cursor: [[0, 0], [1, 0], [2, 0]]

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
      set
        textC: """
        012 |345
        abc\n
        """

    describe "when useClipboardAsDefaultRegister enabled", ->
      beforeEach ->
        settings.set('useClipboardAsDefaultRegister', true)
        atom.clipboard.write('___________')
        ensure null, register: '"': text: '___________'

      describe "read/write to clipboard through register", ->
        it "writes to clipboard with default register", ->
          savedText = '012 345\n'
          ensure 'y y', register: '"': text: savedText
          expect(atom.clipboard.read()).toBe(savedText)

    describe "visual-mode.linewise", ->
      beforeEach ->
        set
          textC: """
            0000|00
            111111
            222222\n
            """

      describe "selection not reversed", ->
        it "saves to register(type=linewise), cursor move to start of target", ->
          ensure "V j y",
            cursor: [0, 0]
            register: '"': text: "000000\n111111\n", type: 'linewise'

      describe "selection is reversed", ->
        it "saves to register(type=linewise), cursor doesn't move", ->
          set cursor: [2, 2]
          ensure "V k y",
            cursor: [1, 2]
            register: '"': text: "111111\n222222\n", type: 'linewise'

    describe "visual-mode.blockwise", ->
      beforeEach ->
        set
          textC_: """
          000000
          1!11111
          222222
          333333
          4|44444
          555555\n
          """
        ensure "ctrl-v l l j",
          selectedTextOrdered: ["111", "222", "444", "555"]
          mode: ['visual', 'blockwise']

      describe "when stayOnYank = false", ->
        it "place cursor at start of block after yank", ->
          ensure "y",
            mode: 'normal'
            textC_: """
              000000
              1!11111
              222222
              333333
              4|44444
              555555\n
              """
      describe "when stayOnYank = true", ->
        beforeEach ->
          settings.set('stayOnYank', true)
        it "place cursor at head of block after yank", ->
          ensure "y",
            mode: 'normal'
            textC_: """
              000000
              111111
              222!222
              333333
              444444
              555|555\n
              """

    describe "y y", ->
      it "saves to register(type=linewise), cursor stay at same position", ->
        ensure 'y y',
          cursor: [0, 4]
          register: '"': text: "012 345\n", type: 'linewise'
      it "[N y y] yank N line, starting from the current", ->
        ensure 'y 2 y',
          cursor: [0, 4]
          register: '"': text: "012 345\nabc\n"
      it "[y N y] yank N line, starting from the current", ->
        ensure '2 y y',
          cursor: [0, 4]
          register: '"': text: "012 345\nabc\n"

    describe "with a register", ->
      it "saves the line to the a register", ->
        ensure '" a y y',
          register: a: text: "012 345\n"

    describe "with A register", ->
      it "append to existing value of lowercase-named register", ->
        ensure '" a y y', register: a: text: "012 345\n"
        ensure '" A y y', register: a: text: "012 345\n012 345\n"

    describe "with a motion", ->
      beforeEach ->
        settings.set('useClipboardAsDefaultRegister', false)

      it "yank from here to destnation of motion", ->
        ensure 'y e', cursor: [0, 4], register: {'"': text: '345'}

      it "does not yank when motion failed", ->
        ensure 'y t x', register: {'"': text: undefined}

      it "yank and move cursor to start of target", ->
        ensure 'y h',
          cursor: [0, 3]
          register: '"': text: ' '

      it "[with linewise motion] yank and desn't move cursor", ->
        ensure 'y j',
          cursor: [0, 4]
          register: {'"': text: "012 345\nabc\n", type: 'linewise'}

    describe "with a text-obj", ->
      beforeEach ->
        set
          cursor: [2, 8]
          text: """

          1st paragraph
          1st paragraph

          2n paragraph
          2n paragraph\n
          """
      it "inner-word and move cursor to start of target", ->
        ensure 'y i w',
          register: '"': text: "paragraph"
          cursor: [2, 4]

      it "yank text-object inner-paragraph and move cursor to start of target", ->
        ensure 'y i p',
          cursor: [1, 0]
          register: '"': text: "1st paragraph\n1st paragraph\n"

    describe "when followed by a G", ->
      beforeEach ->
        originalText = """
        12345
        abcde
        ABCDE\n
        """
        set text: originalText

      it "yank and doesn't move cursor", ->
        set cursor: [1, 0]
        ensure 'y G',
          register: {'"': text: "abcde\nABCDE\n", type: 'linewise'}
          cursor: [1, 0]

      it "yank and doesn't move cursor", ->
        set cursor: [1, 2]
        ensure 'y G',
          register: {'"': text: "abcde\nABCDE\n", type: 'linewise'}
          cursor: [1, 2]

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
          cursor: [[0, 0], [1, 5]]
        ensure 'y ^',
          register: '"': text: '123'
          cursor: [[0, 0], [1, 2]]

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
        ensure "y i p", cursor: [1, 2], register: '"': text: text.getLines([0..2])
        ensure "j y y", cursor: [2, 2], register: '"': text: text.getLines([2])
        ensure "k .", cursor: [1, 2], register: '"': text: text.getLines([1])
        ensure "y h", cursor: [1, 2], register: '"': text: "_"
        ensure "y b", cursor: [1, 2], register: '"': text: "1_"

      it "don't move cursor after yank from visual-linewise", ->
        ensure "V y", cursor: [1, 2], register: '"': text: text.getLines([1])
        ensure "V j y", cursor: [2, 2], register: '"': text: text.getLines([1..2])

      it "don't move cursor after yank from visual-characterwise", ->
        ensure "v l l y", cursor: [1, 4], register: '"': text: "234"
        ensure "v h h y", cursor: [1, 2], register: '"': text: "234"
        ensure "v j y", cursor: [2, 2], register: '"': text: "234567\n2_2"
        ensure "v 2 k y", cursor: [0, 2], register: '"': text: "234567\n1_234567\n2_2"

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
          text: "no newline!\nno newline!\n"

      it "copies the entire line and pastes it respecting count and new lines", ->
        ensure 'y y 2 p',
          register: '"': text: "no newline!\n"
          text: "no newline!\nno newline!\nno newline!\n"

  describe "the Y keybinding", ->
    text = null
    beforeEach ->
      text = """
      012 345
      abc\n
      """
      set text: text, cursor: [0, 4]

    it "saves the line to the default register", ->
      ensure 'Y', cursor: [0, 4], register: '"': text: "012 345\n"

    it "yank the whole lines to the default register", ->
      ensure 'v j Y', cursor: [0, 0], register: '"': text: text

  describe "the p keybinding", ->
    describe "with single line character contents", ->
      beforeEach ->
        settings.set('useClipboardAsDefaultRegister', false)

        set textC: "|012\n"
        set register: '"': text: '345'
        set register: 'a': text: 'a'
        atom.clipboard.write("clip")

      describe "from the default register", ->
        it "inserts the contents", ->
          ensure "p", textC: "034|512\n"

      describe "at the end of a line", ->
        beforeEach ->
          set textC: "01|2\n"
        it "positions cursor correctly", ->
          ensure "p", textC: "01234|5\n"

      describe "paste to empty line", ->
        it "paste content to that empty line", ->
          set
            textC: """
            1st
            |
            3rd
            """
            register: '"': text: '2nd'

          ensure 'p',
            textC: """
            1st
            2n|d
            3rd
            """

      describe "when useClipboardAsDefaultRegister enabled", ->
        it "inserts contents from clipboard", ->
          settings.set('useClipboardAsDefaultRegister', true)
          ensure 'p', textC: "0cli|p12\n"

      describe "from a specified register", ->
        it "inserts the contents of the 'a' register", ->
          ensure '" a p', textC: "0|a12\n",

      describe "at the end of a line", ->
        it "inserts before the current line's newline", ->
          set
            textC: """
            abcde
            one |two three
            """
          ensure 'd $ k $ p',
            textC_: """
            abcdetwo thre|e
            one_
            """

    describe "with multiline character contents", ->
      beforeEach ->
        set textC: "|012\n"
        set register: '"': text: '345\n678'

      it "p place cursor at start of mutation", -> ensure "p", textC: "0|345\n67812\n"
      it "P place cursor at start of mutation", -> ensure "P", textC: "|345\n678012\n"

    describe "with linewise contents", ->
      describe "on a single line", ->
        beforeEach ->
          set
            textC: '0|12'
            register: '"': {text: " 345\n", type: 'linewise'}

        it "inserts the contents of the default register", ->
          ensure 'p',
            textC_: """
            012
            _|345\n
            """

        it "replaces the current selection and put cursor to the first char of line", ->
          ensure 'v p', # '1' was replaced
            textC_: """
            0
            _|345
            2
            """

      describe "on multiple lines", ->
        beforeEach ->
          set
            text: """
            012
             345
            """
            register: '"': {text: " 456\n", type: 'linewise'}

        it "inserts the contents of the default register at middle line", ->
          set cursor: [0, 1]
          ensure "p",
            textC: """
            012
             |456
             345
            """

        it "inserts the contents of the default register at end of line", ->
          set cursor: [1, 1]
          ensure 'p',
            textC: """
            012
             345
             |456\n
            """

    describe "with multiple linewise contents", ->
      beforeEach ->
        set
          textC: """
          012
          |abc
          """
          register: '"': {text: " 345\n 678\n", type: 'linewise'}

      it "inserts the contents of the default register", ->
        ensure 'p',
          textC: """
          012
          abc
           |345
           678\n
          """

    ffdescribe "put-after-with-auto-indent command", ->
      ensurePutAfterWithAutoIndent = (options) ->
        dispatch(editor.element, 'vim-mode-plus:put-after-with-auto-indent')
        ensure(null, options)

      beforeEach ->
        waitsForPromise ->
          settings.set('useClipboardAsDefaultRegister', false)
          atom.packages.activatePackage('language-javascript').then ->
            set grammar: 'source.js'

      describe "paste with auto-indent", ->
        it "inserts the contents of the default register", ->
          set
            register: '"':
              type: 'linewise'
              text: " 345\n",
            textC_: """
              if| () {
              }
              """
          ensurePutAfterWithAutoIndent
            textC_: """
              if () {
                |345
              }
              """
        it "multi-line register contents with auto indent", ->
          set
            register: '"':
              type: 'linewise'
              text: """
                if(3) {
                  if(4) {}
                }
                """
            textC: """
              if (1) {
                |if (2) {
                }
              }
              """
          ensurePutAfterWithAutoIndent
            textC: """
            if (1) {
              if (2) {
                |if(3) {
                  if(4) {}
                }
              }
            }
            """

      describe "when pasting already indented multi-lines register content", ->
        beforeEach ->
          set
            textC: """
            if (1) {
              |if (2) {
              }
            }
            """

        it "keep original layout", ->
          set register: '"':
            type: 'linewise'
            text: """
               a: 123,
            bbbb: 456,
            """
          ensurePutAfterWithAutoIndent
            textC: """
            if (1) {
              if (2) {
                   |a: 123,
                bbbb: 456,
              }
            }
            """

        it "keep original layout [register content have blank row]", ->
          set register: '"':
            type: 'linewise'
            text: """
              if(3) {
              __abc

              __def
              }
              """.replace(/_/g, ' ')
          ensurePutAfterWithAutoIndent
            textC_: """
              if (1) {
                if (2) {
                  |if(3) {
                    abc

                    def
                  }
                }
              }
              """
