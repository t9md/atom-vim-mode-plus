{getVimState, dispatch} = require './spec-helper'
settings = require '../lib/settings'
{inspect} = require 'util'

describe "Operator ActivateInsertMode family", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim

  afterEach ->
    vimState.resetNormalMode()

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
      keystroke '3 s'
      editor.insertText 'ab'
      ensure 'escape', text: 'ab345'
      set cursor: [0, 2]
      ensure '.', text: 'abab'

    it "is undoable", ->
      set cursor: [0, 0]
      keystroke '3 s'
      editor.insertText 'ab'
      ensure 'escape', text: 'ab345'
      ensure 'u', text: '012345', selectedText: ''

    describe "in visual mode", ->
      beforeEach ->
        keystroke 'v l s'

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
      ensure '.', text: '12345\nabc\nabc'

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
      ensure 'k S', text: '\n12345'
    # Can't be tested without setting grammar of test buffer
    xit "respects indentation", ->

  describe "the c keybinding", ->
    beforeEach ->
      set text: """
        12345
        abcde
        ABCDE
        """

    describe "when followed by a c", ->
      describe "with autoindent", ->
        beforeEach ->
          set text: "12345\n  abcde\nABCDE\n"
          set cursor: [1, 1]
          spyOn(editor, 'shouldAutoIndent').andReturn(true)
          spyOn(editor, 'autoIndentBufferRow').andCallFake (line) ->
            editor.indent()
          spyOn(editor.languageMode, 'suggestedIndentForLineAtBufferRow').andCallFake -> 1

        it "deletes the current line and enters insert mode", ->
          set cursor: [1, 1]
          ensure 'c c',
            text: "12345\n  \nABCDE\n"
            cursor: [1, 2]
            mode: 'insert'

        it "is repeatable", ->
          keystroke 'c c'
          editor.insertText("abc")
          ensure 'escape', text: "12345\n  abc\nABCDE\n"
          set cursor: [2, 3]
          ensure '.', text: "12345\n  abc\n  abc\n"

        it "is undoable", ->
          keystroke 'c c'
          editor.insertText("abc")
          ensure 'escape', text: "12345\n  abc\nABCDE\n"
          ensure 'u', text: "12345\n  abcde\nABCDE\n", selectedText: ''

      describe "when the cursor is on the last line", ->
        it "deletes the line's content and enters insert mode on the last line", ->
          set cursor: [2, 1]
          ensure 'c c',
            text: "12345\nabcde\n"
            cursor: [2, 0]
            mode: 'insert'

      describe "when the cursor is on the only line", ->
        it "deletes the line's content and enters insert mode", ->
          set text: "12345", cursor: [0, 2]
          ensure 'c c',
            text: ""
            cursor: [0, 0]
            mode: 'insert'

    describe "when followed by i w", ->
      it "undo's and redo's completely", ->
        set cursor: [1, 1]
        ensure 'c i w',
          text: "12345\n\nABCDE"
          cursor: [1, 0]
          mode: 'insert'

        # Just cannot get "typing" to work correctly in test.
        set text: "12345\nfg\nABCDE"
        ensure 'escape',
          text: "12345\nfg\nABCDE"
          mode: 'normal'
        ensure 'u', text: "12345\nabcde\nABCDE"
        ensure 'ctrl-r', text: "12345\nfg\nABCDE"

      it "repeatable", ->
        set cursor: [1, 1]
        ensure 'c i w',
          text: "12345\n\nABCDE"
          cursor: [1, 0]
          mode: 'insert'

        ensure 'escape j .',
          text: "12345\n\n"
          cursor: [2, 0]
          mode: 'normal'

    describe "when followed by a w", ->
      it "changes the word", ->
        set text: "word1 word2 word3", cursorBuffer: [0, 7]
        ensure 'c w escape', text: "word1 w word3"

    describe "when followed by a G", ->
      beforeEach ->
        originalText = "12345\nabcde\nABCDE\n"
        set text: originalText

      describe "on the beginning of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 0]
          ensure 'c G escape', text: '12345\n\n'

      describe "on the middle of the second line", ->
        it "deletes the bottom two lines", ->
          set cursor: [1, 2]
          ensure 'c G escape', text: '12345\n\n'

    describe "when followed by a goto line G", ->
      beforeEach ->
        set text: "12345\nabcde\nABCDE"

      describe "on the beginning of the second line", ->
        it "deletes all the text on the line", ->
          set cursor: [1, 0]
          ensure 'c 2 G escape', text: '12345\n\nABCDE'

      describe "on the middle of the second line", ->
        it "deletes all the text on the line", ->
          set cursor: [1, 2]
          ensure 'c 2 G escape', text: '12345\n\nABCDE'

  describe "the C keybinding", ->
    beforeEach ->
      set
        cursor: [1, 2]
        text: """
        0!!!!!!
        1!!!!!!
        2!!!!!!
        3!!!!!!\n
        """
    describe "in normal-mode", ->
      it "deletes till the EOL then enter insert-mode", ->
        ensure 'C',
          cursor: [1, 2]
          mode: 'insert'
          text: """
            0!!!!!!
            1!
            2!!!!!!
            3!!!!!!\n
            """

    describe "in visual-mode.characterwise", ->
      it "delete whole lines and enter insert-mode", ->
        ensure 'v j C',
          cursor: [1, 0]
          mode: 'insert'
          text: """
            0!!!!!!

            3!!!!!!\n
            """

  describe "the O keybinding", ->
    beforeEach ->
      spyOn(editor, 'shouldAutoIndent').andReturn(true)
      spyOn(editor, 'autoIndentBufferRow').andCallFake (line) ->
        editor.indent()

      set
        textC_: """
        __abc
        _|_012\n
        """

    it "switches to insert and adds a newline above the current one", ->
      keystroke 'O'
      ensure
        textC_: """
        __abc
        __|
        __012\n
        """
        mode: 'insert'

    it "is repeatable", ->
      set
        textC_: """
          __abc
          __|012
          ____4spaces\n
          """
      # set
      #   text: "  abc\n  012\n    4spaces\n", cursor: [1, 1]
      keystroke 'O'
      editor.insertText "def"
      ensure 'escape',
        textC_: """
          __abc
          __de|f
          __012
          ____4spaces\n
          """
      ensure '.',
        textC_: """
        __abc
        __de|f
        __def
        __012
        ____4spaces\n
        """
      set cursor: [4, 0]
      ensure '.',
        textC_: """
        __abc
        __def
        __def
        __012
        ____de|f
        ____4spaces\n
        """

    it "is undoable", ->
      keystroke 'O'
      editor.insertText "def"
      ensure 'escape',
        textC_: """
        __abc
        __def
        __012\n
        """
      ensure 'u',
        textC_: """
        __abc
        __012\n
        """

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
      set
        text_: """
        __0: 3456 890
        1: 3456 890
        __2: 3456 890
        ____3: 3456 890
        """

    describe "in normal-mode", ->
      describe "I", ->
        it "insert at first char of line", ->
          set cursor: [0, 5]
          ensure 'I', cursor: [0, 2], mode: 'insert'
          ensure "escape", mode: 'normal'

          set cursor: [1, 5]
          ensure 'I', cursor: [1, 0], mode: 'insert'
          ensure "escape", mode: 'normal'

          set cursor: [1, 0]
          ensure 'I', cursor: [1, 0], mode: 'insert'
          ensure "escape", mode: 'normal'

      describe "A", ->
        it "insert at end of line", ->
          set cursor: [0, 5]
          ensure 'A', cursor: [0, 13], mode: 'insert'
          ensure "escape", mode: 'normal'

          set cursor: [1, 5]
          ensure 'A', cursor: [1, 11], mode: 'insert'
          ensure "escape", mode: 'normal'

          set cursor: [1, 11]
          ensure 'A', cursor: [1, 11], mode: 'insert'
          ensure "escape", mode: 'normal'

    describe "visual-mode.linewise", ->
      beforeEach ->
        set cursor: [1, 3]
        ensure "V 2 j",
          selectedText: """
          1: 3456 890
            2: 3456 890
              3: 3456 890
          """
          mode: ['visual', 'linewise']

      describe "I", ->
        it "insert at first char of line *of each selected line*", ->
          ensure "I", cursor: [[1, 0], [2, 2], [3, 4]], mode: "insert"
      describe "A", ->
        it "insert at end of line *of each selected line*", ->
          ensure "A", cursor: [[1, 11], [2, 13], [3, 15]], mode: "insert"

    describe "visual-mode.blockwise", ->
      beforeEach ->
        set cursor: [1, 4]
        ensure "ctrl-v 2 j",
          selectedText: ["4", " ", "3"]
          mode: ['visual', 'blockwise']

      describe "I", ->
        it "insert at colum of start of selection for *each selection*", ->
          ensure "I", cursor: [[1, 4], [2, 4], [3, 4]], mode: "insert"

        xit "can repeat after insert", ->
          ensure "escape", mode: 'normal'
          set
            textC: """
            |line0
            line1
            line2
            """

          ensure "ctrl-v j I",
            textC: """
            |line0
            |line1
            line2
            """
            mode: 'insert'

          editor.insertText("ABC")

          ensure "escape",
            textC: """
            AB|Cline0
            AB!Cline1
            line2
            """
            mode: 'normal'

          # This should success
          ensure "l .",
            textC: """
            ABCABC|line0
            ABCABC|line1
            line2
            """
            mode: 'normal'

          # [BUG] But this pass in current implementation
          # ensure "l .",
          #   textC: """
          #   ABCAB|Cline0
          #   ABCAB|Cline1
          #   linAB!Ce2
          #   """
          #   mode: 'normal'

      describe "A", ->
        it "insert at column of end of selection for *each selection*", ->
          ensure "A", cursor: [[1, 5], [2, 5], [3, 5]], mode: "insert"

    describe "visual-mode.characterwise", ->
      beforeEach ->
        set cursor: [1, 4]
        ensure "v 2 j",
          selectedText: """
          456 890
            2: 3456 890
              3
          """
          mode: ['visual', 'characterwise']

      describe "I is short hand of `ctrl-v I`", ->
        it "insert at colum of start of selection for *each selected lines*", ->
          ensure "I", cursor: [[1, 4], [2, 4], [3, 4]], mode: "insert"
      describe "A is short hand of `ctrl-v A`", ->
        it "insert at column of end of selection for *each selected lines*", ->
          ensure "A", cursor: [[1, 5], [2, 5], [3, 5]], mode: "insert"

  describe "the gI keybinding", ->
    beforeEach ->
      set
        text: """
        __this is text
        """

    describe "in normal-mode.", ->
      it "start at insert at column 0 regardless of current column", ->
        set cursor: [0, 5]
        ensure "g I", cursor: [0, 0], mode: 'insert'
        ensure "escape", mode: 'normal'

        set cursor: [0, 0]
        ensure "g I", cursor: [0, 0], mode: 'insert'
        ensure "escape", mode: 'normal'

        set cursor: [0, 13]
        ensure "g I", cursor: [0, 0], mode: 'insert'

    describe "in visual-mode", ->
      beforeEach ->
        set
          text_: """
          __0: 3456 890
          1: 3456 890
          __2: 3456 890
          ____3: 3456 890
          """

      it "[characterwise]", ->
        set cursor: [1, 4]
        ensure "v 2 j",
          selectedText: """
          456 890
            2: 3456 890
              3
          """
          mode: ['visual', 'characterwise']
        ensure "g I",
          cursor: [[1, 0], [2, 0], [3, 0]], mode: "insert"

      it "[linewise]", ->
        set cursor: [1, 3]
        ensure "V 2 j",
          selectedText: """
          1: 3456 890
            2: 3456 890
              3: 3456 890
          """
          mode: ['visual', 'linewise']
        ensure "g I",
          cursor: [[1, 0], [2, 0], [3, 0]], mode: "insert"

      it "[blockwise]", ->
        set cursor: [1, 4]
        ensure "ctrl-v 2 j",
          selectedText: ["4", " ", "3"]
          mode: ['visual', 'blockwise']
        ensure "g I",
          cursor: [[1, 0], [2, 0], [3, 0]], mode: "insert"

  describe "InsertAtPreviousFoldStart and Next", ->
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-coffee-script')
      getVimState 'sample.coffee', (state, vim) ->
        {editor, editorElement} = state
        {set, ensure, keystroke} = vim

      runs ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus.normal-mode':
            'g [': 'vim-mode-plus:insert-at-previous-fold-start'
            'g ]': 'vim-mode-plus:insert-at-next-fold-start'

    afterEach ->
      atom.packages.deactivatePackage('language-coffee-script')

    describe "when cursor is not at fold start row", ->
      beforeEach ->
        set cursor: [16, 0]
      it "insert at previous fold start row", ->
        ensure 'g [', cursor: [9, 2], mode: 'insert'
      it "insert at next fold start row", ->
        ensure 'g ]', cursor: [18, 4], mode: 'insert'

    describe "when cursor is at fold start row", ->
      # Nothing special when cursor is at fold start row,
      # only for test scenario throughness.
      beforeEach ->
        set cursor: [20, 6]
      it "insert at previous fold start row", ->
        ensure 'g [', cursor: [18, 4], mode: 'insert'
      it "insert at next fold start row", ->
        ensure 'g ]', cursor: [22, 6], mode: 'insert'

  describe "the i keybinding", ->
    beforeEach ->
      set
        textC: """
          |123
          |4567
          """

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

  describe 'preserve inserted text', ->
    beforeEach ->
      set
        text: "\n\n"
        cursorBuffer: [0, 0]

    describe "save inserted text to '.' register", ->
      ensureDotRegister = (key, {text}) ->
        keystroke key
        editor.insertText(text)
        ensure "escape", register: '.': text: text
      it "[case-i]", -> ensureDotRegister 'i', text: 'abc'
      it "[case-o]", -> ensureDotRegister 'o', text: 'abc'
      it "[case-c]", -> ensureDotRegister 'c', text: 'abc'
      it "[case-C]", -> ensureDotRegister 'C', text: 'abc'
      it "[case-s]", -> ensureDotRegister 's', text: 'abc'

  describe "repeat backspace/delete happened in insert-mode", ->
    describe "single cursor operation", ->
      beforeEach ->
        set
          cursor: [0, 0]
          text: """
          123
          123
          """

      it "can repeat backspace only mutation: case-i", ->
        set cursor: [0, 1]
        keystroke 'i'
        editor.backspace()
        ensure 'escape', text: "23\n123", cursor: [0, 0]
        ensure 'j .', text: "23\n123" # nothing happen
        ensure 'l .', text: "23\n23"

      it "can repeat backspace only mutation: case-a", ->
        keystroke 'a'
        editor.backspace()
        ensure 'escape', text: "23\n123", cursor: [0, 0]
        ensure '.', text: "3\n123", cursor: [0, 0]
        ensure 'j . .', text: "3\n3"

      it "can repeat delete only mutation: case-i", ->
        keystroke 'i'
        editor.delete()
        ensure 'escape', text: "23\n123"
        ensure 'j .', text: "23\n23"

      it "can repeat delete only mutation: case-a", ->
        keystroke 'a'
        editor.delete()
        ensure 'escape', text: "13\n123"
        ensure 'j .', text: "13\n13"

      it "can repeat backspace and insert mutation: case-i", ->
        set cursor: [0, 1]
        keystroke 'i'
        editor.backspace()
        editor.insertText("!!!")
        ensure 'escape', text: "!!!23\n123"
        set cursor: [1, 1]
        ensure '.', text: "!!!23\n!!!23"

      it "can repeat backspace and insert mutation: case-a", ->
        keystroke 'a'
        editor.backspace()
        editor.insertText("!!!")
        ensure 'escape', text: "!!!23\n123"
        ensure 'j 0 .', text: "!!!23\n!!!23"

      it "can repeat delete and insert mutation: case-i", ->
        keystroke 'i'
        editor.delete()
        editor.insertText("!!!")
        ensure 'escape', text: "!!!23\n123"
        ensure 'j 0 .', text: "!!!23\n!!!23"

      it "can repeat delete and insert mutation: case-a", ->
        keystroke 'a'
        editor.delete()
        editor.insertText("!!!")
        ensure 'escape', text: "1!!!3\n123"
        ensure 'j 0 .', text: "1!!!3\n1!!!3"

    describe "multi-cursors operation", ->
      beforeEach ->
        set
          textC: """
          |123

          |1234

          |12345
          """

      it "can repeat backspace only mutation: case-multi-cursors", ->
        ensure 'A', cursor: [[0, 3], [2, 4], [4, 5]], mode: 'insert'
        editor.backspace()
        ensure 'escape', text: "12\n\n123\n\n1234", cursor: [[0, 1], [2, 2], [4, 3]]
        ensure '.', text: "1\n\n12\n\n123", cursor: [[0, 0], [2, 1], [4, 2]]

      it "can repeat delete only mutation: case-multi-cursors", ->
        ensure 'I', mode: 'insert'
        editor.delete()
        cursors = [[0, 0], [2, 0], [4, 0]]
        ensure 'escape', text: "23\n\n234\n\n2345", cursor: cursors
        ensure '.', text: "3\n\n34\n\n345", cursor: cursors
        ensure '.', text: "\n\n4\n\n45", cursor: cursors
        ensure '.', text: "\n\n\n\n5", cursor: cursors
        ensure '.', text: "\n\n\n\n", cursor: cursors

  describe 'specify insertion count', ->
    ensureInsertionCount = (key, {insert, text, cursor}) ->
      keystroke key
      editor.insertText(insert)
      ensure "escape", text: text, cursor: cursor

    beforeEach ->
      initialText = "*\n*\n"
      set text: "", cursor: [0, 0]
      keystroke 'i'
      editor.insertText(initialText)
      ensure "escape g g", text: initialText, cursor: [0, 0]

    describe "repeat insertion count times", ->
      it "[case-i]", -> ensureInsertionCount '3 i', insert: '=', text: "===*\n*\n", cursor: [0, 2]
      it "[case-o]", -> ensureInsertionCount '3 o', insert: '=', text: "*\n=\n=\n=\n*\n", cursor: [3, 0]
      it "[case-O]", -> ensureInsertionCount '3 O', insert: '=', text: "=\n=\n=\n*\n*\n", cursor: [2, 0]

      describe "children of Change operation won't repeate insertion count times", ->
        beforeEach ->
          set text: "", cursor: [0, 0]
          keystroke 'i'
          editor.insertText('*')
          ensure 'escape g g', text: '*', cursor: [0, 0]

        it "[case-c]", -> ensureInsertionCount '3 c w', insert: '=', text: "=", cursor: [0, 0]
        it "[case-C]", -> ensureInsertionCount '3 C', insert: '=', text: "=", cursor: [0, 0]
        it "[case-s]", -> ensureInsertionCount '3 s', insert: '=', text: "=", cursor: [0, 0]
        it "[case-S]", -> ensureInsertionCount '3 S', insert: '=', text: "=", cursor: [0, 0]
