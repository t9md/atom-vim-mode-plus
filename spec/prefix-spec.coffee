{getVimState} = require './spec-helper'
settings = require '../lib/settings'

describe "Prefixes", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim

  describe "Repeat", ->
    describe "with operations", ->
      beforeEach ->
        set text: "123456789abc", cursor: [0, 0]

      it "repeats N times", ->
        ensure '3 x', text: '456789abc'

      it "repeats NN times", ->
        ensure '1 0 x', text: 'bc'

    describe "with motions", ->
      beforeEach ->
        set text: 'one two three', cursor: [0, 0]

      it "repeats N times", ->
        ensure 'd 2 w', text: 'three'

    describe "in visual mode", ->
      beforeEach ->
        set text: 'one two three', cursor: [0, 0]

      it "repeats movements in visual mode", ->
        ensure 'v 2 w', cursor: [0, 9]

  describe "Register", ->
    beforeEach ->
      vimState.globalState.reset('register')

    describe "the a register", ->
      it "saves a value for future reading", ->
        set    register: a: text: 'new content'
        ensure register: a: text: 'new content'

      it "overwrites a value previously in the register", ->
        set    register: a: text: 'content'
        set    register: a: text: 'new content'
        ensure register: a: text: 'new content'

    describe "with yank command", ->
      beforeEach ->
        set
          cursor: [0, 0]
          text: """
          aaa bbb ccc
          """
      it "save to pre specified register", ->
        ensure '" a y i w', register: a: text: 'aaa'
        ensure 'w " b y i w', register: b: text: 'bbb'
        ensure 'w " c y i w', register: c: text: 'ccc'

      it "work with motion which also require input such as 't'", ->
        ensure ['" a y t', {input: 'c'}], register: a: text: 'aaa bbb '

    describe "With p command", ->
      beforeEach ->
        vimState.globalState.reset('register')
        set register: a: text: 'new content'
        set
          text: """
          abc
          def
          """
          cursor: [0, 0]

      describe "when specified register have no text", ->
        it "can paste from a register", ->
          ensure mode: "normal"
          ensure ['"', input: 'a', 'p'],
            text: """
            anew contentbc
            def
            """
            cursor: [0, 11]

        it "but do nothing for z register", ->
          ensure ['"', input: 'z', 'p'],
            text: """
            abc
            def
            """
            cursor: [0, 0]

      describe "blockwise-mode paste just use register have no text", ->
        it "paste from a register to each selction", ->
          ensure ['ctrl-v j "', input: 'a', 'p'],
            textC: """
            !new contentbc
            new contentef
            """

    describe "the B register", ->
      it "saves a value for future reading", ->
        set    register: B: text: 'new content'
        ensure register: b: text: 'new content'
        ensure register: B: text: 'new content'

      it "appends to a value previously in the register", ->
        set    register: b: text: 'content'
        set    register: B: text: 'new content'
        ensure register: b: text: 'contentnew content'

      it "appends linewise to a linewise value previously in the register", ->
        set    register: b: text: 'content\n', type: 'linewise'
        set    register: B: text: 'new content'
        ensure register: b: text: 'content\nnew content\n'

      it "appends linewise to a character value previously in the register", ->
        set    register: b: text: 'content'
        set    register: B: text: 'new content\n', type: 'linewise'
        ensure register: b: text: 'content\nnew content\n'

    describe "the * register", ->
      describe "reading", ->
        it "is the same the system clipboard", ->
          ensure register: '*': text: 'initial clipboard content', type: 'characterwise'

      describe "writing", ->
        beforeEach ->
          set register: '*': text: 'new content'

        it "overwrites the contents of the system clipboard", ->
          expect(atom.clipboard.read()).toEqual 'new content'

    # FIXME: once linux support comes out, this needs to read from
    # the correct clipboard. For now it behaves just like the * register
    # See :help x11-cut-buffer and :help registers for more details on how these
    # registers work on an X11 based system.
    describe "the + register", ->
      describe "reading", ->
        it "is the same the system clipboard", ->
          ensure register:
            '*': text: 'initial clipboard content', type: 'characterwise'

      describe "writing", ->
        beforeEach ->
          set register: '*': text: 'new content'

        it "overwrites the contents of the system clipboard", ->
          expect(atom.clipboard.read()).toEqual 'new content'

    describe "the _ register", ->
      describe "reading", ->
        it "is always the empty string", ->
          ensure register: '_': text: ''

      describe "writing", ->
        it "throws away anything written to it", ->
          set register:    '_': text: 'new content'
          ensure register: '_': text: ''

    describe "the % register", ->
      beforeEach ->
        spyOn(editor, 'getURI').andReturn '/Users/atom/known_value.txt'

      describe "reading", ->
        it "returns the filename of the current editor", ->
          ensure register: '%': text: '/Users/atom/known_value.txt'

      describe "writing", ->
        it "throws away anything written to it", ->
          set    register: '%': text: 'new content'
          ensure register: '%': text: '/Users/atom/known_value.txt'

    describe "the ctrl-r command in insert mode", ->
      beforeEach ->
        set register: '"': text: '345'
        set register: 'a': text: 'abc'
        set register: '*': text: 'abc'
        atom.clipboard.write "clip"
        set text: "012\n", cursor: [0, 2]
        ensure 'i', mode: 'insert'

      describe "useClipboardAsDefaultRegister = true", ->
        beforeEach ->
          settings.set 'useClipboardAsDefaultRegister', true
          set register: '"': text: '345'
          atom.clipboard.write "clip"

        it "inserts contents from clipboard with \"", ->
          ensure ['ctrl-r', input: '"'], text: '01clip2\n'

      describe "useClipboardAsDefaultRegister = false", ->
        beforeEach ->
          settings.set 'useClipboardAsDefaultRegister', false
          set register: '"': text: '345'
          atom.clipboard.write "clip"

        it "inserts contents from \" with \"", ->
          ensure ['ctrl-r', input: '"'], text: '013452\n'

      it "inserts contents of the 'a' register", ->
        ensure ['ctrl-r', input: 'a'], text: '01abc2\n'

      it "is cancelled with the escape key", ->
        ensure 'ctrl-r escape',
          text: '012\n'
          mode: 'insert'
          cursor: [0, 2]

    describe "per selection clipboard", ->
      ensurePerSelectionRegister = (texts...) ->
        for selection, i in editor.getSelections()
          ensure register: '*': {text: texts[i], selection: selection}

      beforeEach ->
        settings.set 'useClipboardAsDefaultRegister', true
        set
          text: """
            012:
            abc:
            def:\n
            """
          cursor: [[0, 1], [1, 1], [2, 1]]

      describe "on selection destroye", ->
        it "remove corresponding subscriptin and clipboard entry", ->
          {clipboardBySelection, subscriptionBySelection} = vimState.register
          expect(clipboardBySelection.size).toBe(0)
          expect(subscriptionBySelection.size).toBe(0)

          keystroke "y i w"
          ensurePerSelectionRegister('012', 'abc', 'def')

          expect(clipboardBySelection.size).toBe(3)
          expect(subscriptionBySelection.size).toBe(3)
          selection.destroy() for selection in editor.getSelections()
          expect(clipboardBySelection.size).toBe(0)
          expect(subscriptionBySelection.size).toBe(0)

      describe "Yank", ->
        it "save text to per selection register", ->
          keystroke "y i w"
          ensurePerSelectionRegister('012', 'abc', 'def')

      describe "Delete family", ->
        it "d", ->
          ensure "d i w", text: ":\n:\n:\n"
          ensurePerSelectionRegister('012', 'abc', 'def')
        it "x", ->
          ensure "x", text: "02:\nac:\ndf:\n"
          ensurePerSelectionRegister('1', 'b', 'e')
        it "X", ->
          ensure "X", text: "12:\nbc:\nef:\n"
          ensurePerSelectionRegister('0', 'a', 'd')
        it "D", ->
          ensure "D", text: "0\na\nd\n"
          ensurePerSelectionRegister('12:', 'bc:', 'ef:')

      describe "Put family", ->
        it "p paste text from per selection register", ->
          ensure "y i w $ p",
            text: """
              012:012
              abc:abc
              def:def\n
              """
        it "P paste text from per selection register", ->
          ensure "y i w $ P",
            text: """
              012012:
              abcabc:
              defdef:\n
              """
      describe "ctrl-r in insert mode", ->
        it "insert from per selection registe", ->
          ensure "d i w", text: ":\n:\n:\n"
          ensure 'a', mode: 'insert'
          ensure ['ctrl-r', input: '"'],
            text: """
              :012
              :abc
              :def\n
              """

  describe "Count modifier", ->
    beforeEach ->
      set
        text: "000 111 222 333 444 555 666 777 888 999"
        cursor: [0, 0]

    it "repeat operator", ->
      ensure '3 d w', text: "333 444 555 666 777 888 999"
    it "repeat motion", ->
      ensure 'd 2 w', text: "222 333 444 555 666 777 888 999"
    it "repeat operator and motion respectively", ->
      ensure '3 d 2 w', text: "666 777 888 999"
