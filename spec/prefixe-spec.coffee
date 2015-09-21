# Refactoring status: 70%
{getVimState} = require './spec-helper'
settings = require '../lib/settings'

describe "Prefixes", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      vimState.setMode('reset')
      {set, ensure, keystroke} = vim

  describe "Repeat", ->
    describe "with operations", ->
      beforeEach ->
        set text: "123456789abc", cursor: [0, 0]

      it "repeats N times", ->
        ensure '3x', text: '456789abc'

      it "repeats NN times", ->
        ensure '10x', text: 'bc'

    describe "with motions", ->
      beforeEach ->
        set text: 'one two three', cursor: [0, 0]

      it "repeats N times", ->
        ensure 'd2w', text: 'three'

    describe "in visual mode", ->
      beforeEach ->
        set text: 'one two three', cursor: [0, 0]

      it "repeats movements in visual mode", ->
        ensure 'v2w', cursor: [0, 9]

  describe "Register", ->
    describe "the a register", ->
      it "saves a value for future reading", ->
        set    register: a: text: 'new content'
        ensure register: a: text: 'new content'

      it "overwrites a value previously in the register", ->
        set    register: a: text: 'content'
        set    register: a: text: 'new content'
        ensure register: a: text: 'new content'

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
          ensure register: '*': text: 'initial clipboard content', type: 'character'

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
            '*': text: 'initial clipboard content', type: 'character'

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
        set
          spy:
            obj: editor, method: 'getURI', return: '/Users/atom/known_value.txt'

      describe "reading", ->
        it "returns the filename of the current editor", ->
          ensure register: '%': text: '/Users/atom/known_value.txt'

      describe "writing", ->
        it "throws away anything written to it", ->
          set    register: '%': text: 'new content'
          ensure register: '%': text: '/Users/atom/known_value.txt'

    describe "the ctrl-r command in insert mode", ->
      beforeEach ->
        set text: "02\n", cursor: [0, 0]
        set register: '"': text: '345'
        set register: 'a': text: 'abc'
        atom.clipboard.write "clip"
        keystroke 'a'
        editor.insertText '1'

      it "inserts contents of the unnamed register with \"", ->
        ensure [{ctrl: 'r'}, {char: '"'}], text: '013452\n'

      describe "when useClipboardAsDefaultRegister enabled", ->
        it "inserts contents from clipboard with \"", ->
          settings.set 'useClipboardAsDefaultRegister', true
          ensure [{ctrl: 'r'}, {char: '"'}], text: '01clip2\n'

      it "inserts contents of the 'a' register", ->
        ensure [{ctrl: 'r'}, {char: 'a'}], text: '01abc2\n'

      it "is cancelled with the escape key", ->
        ensure [{ctrl: 'r'}, {char: 'escape'}],
          text: '012\n'
          mode: 'insert'
          cursor: [0, 2]
