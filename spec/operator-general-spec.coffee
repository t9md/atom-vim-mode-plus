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
        ensure '" a y y', register: a: text: "012 345\n"

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

  describe "YankDiffHunk", ->
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

      settings.set('useClipboardAsDefaultRegister', true)
      atom.clipboard.write('___________')
      ensure null, register: '"': text: '___________'

    it "yank diff-hunk under cursor", ->
      ensureYankedText = (row, text) ->
        set cursor: [row, 0]
        dispatch(editor.element, 'vim-mode-plus:yank-diff-hunk')
        ensure null, register: '"': text: text

      ensureYankedText 2, "___________" # do nothing
      ensureYankedText 4, "line 0-1\n"
      ensureYankedText 6, "line 2\n"
      ensureYankedText 7, "line 1-1\n"
      ensureYankedText 9, "line 4\n"
      ensureYankedText 11, "line 6\nline 7\n"
      ensureYankedText 12, "line 6\nline 7\n"
      ensureYankedText 13, "line 7-1\nline 7-2\n"
      ensureYankedText 14, "line 7-1\nline 7-2\n"

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

    describe "put-after-with-auto-indent command", ->
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

    describe "pasting twice", ->
      beforeEach ->
        set
          text: "12345\nabcde\nABCDE\nQWERT"
          cursor: [1, 1]
          register: '"': text: '123'
        ensure '2 p'

      it "inserts the same line twice", ->
        ensure null, text: "12345\nab123123cde\nABCDE\nQWERT"

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
        ensure 'P'

      it "inserts the contents of the default register above", ->
        ensure null, text: "345012\n", cursor: [0, 2]

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
        cursor: [[0, 0], [1, 0]]

    it "replaces a single character", ->
      ensureWait 'r x', text: 'x2\nx4\n\n'

    it "remain visual-mode when cancelled", ->
      ensureWait 'v r escape',
        text: '12\n34\n\n'
        mode: ['visual', 'characterwise']

    it "replaces a single character with a line break", ->
      ensureWait 'r enter',
        text: '\n2\n\n4\n\n'
        cursor: [[1, 0], [3, 0]]

    it "auto indent when replaced with singe new line", ->
      set
        textC_: """
        __a|bc
        """
      ensureWait 'r enter',
        textC_: """
        __a
        __|c
        """

    it "composes properly with motions", ->
      ensureWait '2 r x', text: 'xx\nxx\n\n'

    it "does nothing on an empty line", ->
      set cursor: [2, 0]
      ensureWait 'r x', text: '12\n34\n\n'

    it "does nothing if asked to replace more characters than there are on a line", ->
      ensureWait '3 r x', text: '12\n34\n\n'

    describe "cancellation", ->
      it "does nothing when cancelled", ->
        ensureWait 'r escape', text: '12\n34\n\n', mode: 'normal'

      it "keep multi-cursor on cancelled", ->
        set                textC: "|    a\n!    a\n|    a\n"
        ensureWait "r escape", textC: "|    a\n!    a\n|    a\n", mode: "normal"

      it "keep multi-cursor on cancelled", ->
        set                textC: "|**a\n!**a\n|**a\n"
        ensureWait "v l",      textC: "**|a\n**!a\n**|a\n", selectedText: ["**", "**", "**"], mode: ["visual", "characterwise"]
        ensureWait "r escape", textC: "**|a\n**!a\n**|a\n", selectedText: ["**", "**", "**"], mode: ["visual", "characterwise"]

    describe "when in visual mode", ->
      beforeEach ->
        ensure 'v e'

      it "replaces the entire selection with the given character", ->
        ensureWait 'r x', text: 'xx\nxx\n\n'

      it "leaves the cursor at the beginning of the selection", ->
        ensureWait 'r x', cursor: [[0, 0], [1, 0]]

    describe "when in visual-block mode", ->
      beforeEach ->
        set
          cursor: [1, 4]
          text: """
            0:2345
            1: o11o
            2: o22o
            3: o33o
            4: o44o\n
            """
        ensure 'ctrl-v l 3 j',
          mode: ['visual', 'blockwise']
          selectedTextOrdered: ['11', '22', '33', '44'],

      it "replaces each selection and put cursor on start of top selection", ->
        runs ->
          ensureWait 'r x',
            mode: 'normal'
            cursor: [1, 4]
            text: """
              0:2345
              1: oxxo
              2: oxxo
              3: oxxo
              4: oxxo\n
              """

        runs ->
          set cursor: [1, 0]

        runs ->
          ensureWait '.',
            mode: 'normal'
            cursor: [1, 0]
            text: """
              0:2345
              xx oxxo
              xx oxxo
              xx oxxo
              xx oxxo\n
              """

  describe 'the m keybinding', ->
    ensureMarkByMode = (mode) ->
      _ensure = bindEnsureWaitOption({mode})
      _ensure "m a", mark: "a": [0, 2]
      _ensure "l m a", mark: "a": [0, 3]
      _ensure "j m a", mark: "a": [1, 3]
      _ensure "j m b", mark: "a": [1, 3], "b": [2, 3]
      _ensure "l m c", mark: "a": [1, 3], "b": [2, 3], "c": [2, 4]

    beforeEach ->
      set
        textC: """
        0:| 12
        1: 34
        2: 56
        """

    it "[normal] can mark multiple positon", ->
      ensureMarkByMode("normal")
    it "[vC] can mark", ->
      ensure "v"
      ensureMarkByMode(["visual", "characterwise"])
    it "[vL] can mark", ->
      ensure "V"
      ensureMarkByMode(["visual", "linewise"])

  describe 'the R keybinding', ->
    beforeEach ->
      set
        text: """
          12345
          67890
          """
        cursor: [0, 2]

    it "enters replace mode and replaces characters", ->
      ensure 'R',
        mode: ['insert', 'replace']
      editor.insertText "ab"
      ensure 'escape',
        text: "12ab5\n67890"
        cursor: [0, 3]
        mode: 'normal'

    it "continues beyond end of line as insert", ->
      ensure 'R', mode: ['insert', 'replace']
      editor.insertText "abcde"
      ensure 'escape', text: '12abcde\n67890'

    it 'treats backspace as undo', ->
      editor.insertText "foo"
      ensure 'R'
      editor.insertText "a"
      editor.insertText "b"
      ensure null, text: "12fooab5\n67890"

      dispatch(editorElement, 'core:backspace')
      ensure null, text: "12fooa45\n67890"

      editor.insertText "c"
      ensure null, text: "12fooac5\n67890"

      dispatch(editor.element, 'core:backspace')
      dispatch(editor.element, 'core:backspace')
      ensure null, text: "12foo345\n67890", selectedText: ''

      dispatch(editor.element, 'core:backspace')
      ensure null, text: "12foo345\n67890", selectedText: ''

    it "can be repeated", ->
      ensure 'R'
      editor.insertText "ab"
      ensure 'escape'
      set cursor: [1, 2]
      ensure '.', text: "12ab5\n67ab0", cursor: [1, 3]
      set cursor: [0, 4]
      ensure '.', text: "12abab\n67ab0", cursor: [0, 5]

    it "can be interrupted by arrow keys and behave as insert for repeat", ->
      # FIXME don't know how to test this (also, depends on PR #568)

    it "repeats correctly when backspace was used in the text", ->
      ensure 'R'
      editor.insertText "a"
      dispatch(editor.element, 'core:backspace')
      editor.insertText "b"
      ensure 'escape'
      set cursor: [1, 2]
      ensure '.', text: "12b45\n67b90", cursor: [1, 2]
      set cursor: [0, 4]
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
        ensure null,
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
        ensure null,
          text: """
            0a
            b
            c4
            56789
            """
          cursor: [2, 1]

        dispatch(editor.element, 'core:backspace')
        ensure null,
          text: """
            0a
            b
            34
            56789
            """
          cursor: [2, 0]

        dispatch(editor.element, 'core:backspace')
        ensure null,
          text: """
            0a
            b34
            56789
            """
          cursor: [1, 1]

        dispatch(editor.element, 'core:backspace')
        ensure null,
          text: """
            0a
            234
            56789
            """
          cursor: [1, 0]

        dispatch(editor.element, 'core:backspace')
        ensure null,
          text: """
            0a234
            56789
            """
          cursor: [0, 2]

        dispatch(editor.element, 'core:backspace')
        ensure null,
          text: """
            01234
            56789
            """
          cursor: [0, 1]

        dispatch(editor.element, 'core:backspace') # do nothing
        ensure null,
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
        ensure null,
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
        ensure null,
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

  describe 'AddBlankLineBelow, AddBlankLineAbove', ->
    beforeEach ->
      set
        textC: """
        line0
        li|ne1
        line2
        line3
        """

      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus.normal-mode':
          'enter': 'vim-mode-plus:add-blank-line-below'
          'shift-enter': 'vim-mode-plus:add-blank-line-above'

    it "insert blank line below/above", ->
      ensure "enter",
        textC: """
        line0
        li|ne1

        line2
        line3
        """
      ensure "shift-enter",
        textC: """
        line0

        li|ne1

        line2
        line3
        """

    it "[with-count] insert blank line below/above", ->
      ensure "2 enter",
        textC: """
        line0
        li|ne1


        line2
        line3
        """
      ensure "2 shift-enter",
        textC: """
        line0


        li|ne1


        line2
        line3
        """

  describe 'Select as operator', ->
    beforeEach ->
      settings.set('keymapSToSelect', true)
      jasmine.attachToDOM(editorElement)

    describe "select by target", ->
      beforeEach ->
        set
          textC: """
          0 |ooo xxx ***
          1 xxx *** ooo

          3 ooo xxx ***
          4 xxx *** ooo\n
          """

      it "select text-object", ->
        ensure "s p", # p is `i p` shorthand.
          mode: ["visual", "linewise"]
          selectedText: "0 ooo xxx ***\n1 xxx *** ooo\n"
          propertyHead: [1, 13]

      it "select by motion j with stayOnSelectTextObject", ->
        settings.set("stayOnSelectTextObject", true)
        ensure "s i p",
          mode: ["visual", "linewise"]
          selectedText: "0 ooo xxx ***\n1 xxx *** ooo\n"
          propertyHead: [1, 2]

      it "select occurrence in text-object with occurrence-modifier", ->
        ensure "s o p", # p is `i p` shorthand.
          mode: ["visual", "characterwise"]
          selectedText: ["ooo", "ooo"]
          selectedBufferRangeOrdered: [
            [[0, 2], [0, 5]]
            [[1, 10], [1, 13]]
          ]

      it "select occurrence in text-object with preset-occurrence", ->
        ensure "g o s p", # p is `i p` shorthand.
          mode: ["visual", "characterwise"]
          selectedText: ["ooo", "ooo"]
          selectedBufferRangeOrdered: [
            [[0, 2], [0, 5]]
            [[1, 10], [1, 13]]
          ]

      it "convert presistent-selection into normal selection", ->
        ensure "v j enter",
          mode: "normal"
          persistentSelectionCount: 1
          persistentSelectionBufferRange: [
            [[0, 2], [1, 3]]
          ]

        ensure "j j v j",
          persistentSelectionCount: 1
          persistentSelectionBufferRange: [
            [[0, 2], [1, 3]]
          ]
          mode: ["visual", "characterwise"]
          selectedText: "ooo xxx ***\n4 x"

        # Now it's show time, to convert persistent selection into normal selection
        # by only `s`.
        ensure "s",
          mode: ["visual", "characterwise"]
          persistentSelectionCount: 0
          selectedTextOrdered: ["ooo xxx ***\n1 x", "ooo xxx ***\n4 x"]

      it "select preset-occurrence in presistent-selection and normal selection", ->
        ensure "g o",
          occurrenceText: ['ooo', 'ooo', 'ooo', 'ooo']

        ensure "V j enter G V",
          persistentSelectionCount: 1
          mode: ["visual", "linewise"]
          selectedText: "4 xxx *** ooo\n"

        ensure "s", # Notice `ooo` in row 3 is EXCLUDED.
          persistentSelectionCount: 0
          mode: ["visual", "characterwise"]
          selectedText: ["ooo", "ooo", "ooo"]
          selectedBufferRangeOrdered: [
            [[0, 2], [0, 5]]
            [[1, 10], [1, 13]]
            [[4, 10], [4, 13]]
          ]

      it "select by motion $", ->
        ensure "s $",
          mode: ["visual", "characterwise"]
          selectedText: "ooo xxx ***\n"

      it "select by motion j", ->
        ensure "s j",
          mode: ["visual", "linewise"]
          selectedText: "0 ooo xxx ***\n1 xxx *** ooo\n"

      it "select by motion j v-modifier", ->
        ensure "s v j",
          mode: ["visual", "characterwise"]
          selectedText: "ooo xxx ***\n1 x"

      it "select occurrence by motion G", ->
        ensure "s o G",
          mode: ["visual", "characterwise"]
          selectedText: ["ooo", "ooo", "ooo", "ooo"]
          selectedBufferRangeOrdered: [
            [[0, 2], [0, 5]]
            [[1, 10], [1, 13]]
            [[3, 2], [3, 5]]
            [[4, 10], [4, 13]]
          ]

      it "select occurrence by motion G with explicit V-modifier", ->
        ensure "s o V G",
          mode: ["visual", "linewise"]
          selectedTextOrdered: [
            "0 ooo xxx ***\n1 xxx *** ooo\n"
            "3 ooo xxx ***\n4 xxx *** ooo\n"
          ]

      it "return to normal-mode when fail to select", ->
        # attempt to select inner-function but there is no function.
        ensure "s i f",
          mode: "normal"
          cursor: [0, 2]

        # attempt to find 'z' but no "z".
        ensure "s f z",
          mode: "normal"
          cursor: [0, 2]

      describe "complex scenario", ->
        beforeEach ->
          waitsForPromise ->
            atom.packages.activatePackage('language-javascript')

          runs ->
            set
              grammar: 'source.js'
              textC: """
              const result = []
              for (const !member of members) {
                let member2 = member + member
                let member3 = member + member + member
                result.push(member2, member3)
              }\n
              """

        it "select occurrence in a-fold ,reverse(o) then escape to normal-mode", ->
          ensure "s o z o escape",
            mode: "normal"
            textC: """
            const result = []
            for (const |member of members) {
              let member2 = |member + |member
              let member3 = |member + |member + |member
              result.push(member2, member3)
            }\n
            """

  describe 'ResolveGitConflict', ->
    resolveConflictAtRowThenEnsure = (row, text) ->
      set cursor: [row, 0]
      dispatch(editor.element, 'vim-mode-plus:resolve-git-conflict')
      ensure null, {text}

    texts =
      original: """

        <<<<<<< HEAD
        ours 1
        ours 2
        ours 3
        =======
        theirs 1
        theirs 2
        theirs 3
        >>>>>>> bob
        \n
        """
      ours: """

        ours 1
        ours 2
        ours 3
        \n
        """
      theirs: """

        theirs 1
        theirs 2
        theirs 3
        \n
        """


    beforeEach ->
      set text: texts.original

    it "row 0", -> resolveConflictAtRowThenEnsure 0, texts.original
    it "row 1", -> resolveConflictAtRowThenEnsure 1, texts.ours
    it "row 2", -> resolveConflictAtRowThenEnsure 2, texts.ours
    it "row 3", -> resolveConflictAtRowThenEnsure 3, texts.ours
    it "row 4", -> resolveConflictAtRowThenEnsure 4, texts.ours
    it "row 5", -> resolveConflictAtRowThenEnsure 5, texts.original
    it "row 6", -> resolveConflictAtRowThenEnsure 6, texts.theirs
    it "row 7", -> resolveConflictAtRowThenEnsure 7, texts.theirs
    it "row 8", -> resolveConflictAtRowThenEnsure 8, texts.theirs
    it "row 9", -> resolveConflictAtRowThenEnsure 9, texts.theirs
    it "row 10", -> resolveConflictAtRowThenEnsure 10, texts.original
