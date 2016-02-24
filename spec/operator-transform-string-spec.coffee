# Refactoring status: 80%
{getVimState, dispatch} = require './spec-helper'
settings = require '../lib/settings'

describe "Operator TransformString", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim

  afterEach ->
    vimState.activate('reset')

  describe 'the ~ keybinding', ->
    beforeEach ->
      set
        text: 'aBc\nXyZ'
        cursorBuffer: [[0, 0], [1, 0]]

    it 'toggles the case and moves right', ->
      ensure '~',
        text: 'ABc\nxyZ'
        cursor: [[0, 1], [1, 1]]

      ensure '~',
        text: 'Abc\nxYZ'
        cursor: [[0, 2], [1, 2]]

      ensure  '~',
        text: 'AbC\nxYz'
        cursor: [[0, 2], [1, 2]]

    it 'takes a count', ->
      ensure '4~',
        text: 'AbC\nxYz'
        cursor: [[0, 2], [1, 2]]

    describe "in visual mode", ->
      it "toggles the case of the selected text", ->
        set cursorBuffer: [0, 0]
        ensure 'V~', text: 'AbC\nXyZ'

    describe "with g and motion", ->
      it "toggles the case of text, won't move cursor", ->
        set cursorBuffer: [0, 0]
        ensure 'g~2l', text: 'Abc\nXyZ', cursor: [0, 0]

      it "g~~ toggles the line of text, won't move cursor", ->
        set cursorBuffer: [0, 1]
        ensure 'g~~', text: 'AbC\nXyZ', cursor: [0, 1]

      it "g~g~ toggles the line of text, won't move cursor", ->
        set cursorBuffer: [0, 1]
        ensure 'g~g~', text: 'AbC\nXyZ', cursor: [0, 1]

  describe 'the U keybinding', ->
    beforeEach ->
      set
        text: 'aBc\nXyZ'
        cursorBuffer: [0, 0]

    it "makes text uppercase with g and motion, and won't move cursor", ->
      ensure 'gUl', text: 'ABc\nXyZ', cursor: [0, 0]
      ensure 'gUe', text: 'ABC\nXyZ', cursor: [0, 0]
      set cursorBuffer: [1, 0]
      ensure 'gU$', text: 'ABC\nXYZ', cursor: [1, 0]

    it "makes the selected text uppercase in visual mode", ->
      ensure 'VU', text: 'ABC\nXyZ'

    it "gUU upcase the line of text, won't move cursor", ->
      set cursorBuffer: [0, 1]
      ensure 'gUU', text: 'ABC\nXyZ', cursor: [0, 1]

    it "gUgU upcase the line of text, won't move cursor", ->
      set cursorBuffer: [0, 1]
      ensure 'gUgU', text: 'ABC\nXyZ', cursor: [0, 1]

  describe 'the u keybinding', ->
    beforeEach ->
      set text: 'aBc\nXyZ', cursorBuffer: [0, 0]

    it "makes text lowercase with g and motion, and won't move cursor", ->
      ensure 'gu$', text: 'abc\nXyZ', cursor: [0, 0]

    it "makes the selected text lowercase in visual mode", ->
      ensure 'Vu', text: 'abc\nXyZ'

    it "guu downcase the line of text, won't move cursor", ->
      set cursorBuffer: [0, 1]
      ensure 'guu', text: 'abc\nXyZ', cursor: [0, 1]

    it "gugu downcase the line of text, won't move cursor", ->
      set cursorBuffer: [0, 1]
      ensure 'gugu', text: 'abc\nXyZ', cursor: [0, 1]

  describe "the > keybinding", ->
    beforeEach ->
      set text: """
        12345
        abcde
        ABCDE
        """

    describe "on the last line", ->
      beforeEach ->
        set cursor: [2, 0]

      describe "when followed by a >", ->
        it "indents the current line", ->
          ensure '>>',
            text: "12345\nabcde\n  ABCDE"
            cursor: [2, 2]

    describe "on the first line", ->
      beforeEach ->
        set cursor: [0, 0]

      describe "when followed by a >", ->
        it "indents the current line", ->
          ensure '>>',
            text: "  12345\nabcde\nABCDE"
            cursor: [0, 2]

      describe "when followed by a repeating >", ->
        beforeEach ->
          keystroke '3>>'

        it "indents multiple lines at once", ->
          ensure
            text: "  12345\n  abcde\n  ABCDE"
            cursor: [0, 2]

        describe "undo behavior", ->
          it "outdents all three lines", ->
            ensure 'u', text: "12345\nabcde\nABCDE"

    describe "in visual mode", ->
      beforeEach ->
        set cursor: [0, 0]
        keystroke 'V>'

      it "indents the current line and exits visual mode", ->
        ensure
          mode: 'normal'
          text: "  12345\nabcde\nABCDE"
          selectedBufferRange: [[0, 2], [0, 2]]

      it "allows repeating the operation", ->
        ensure '.', text: "    12345\nabcde\nABCDE"

  describe "the < keybinding", ->
    beforeEach ->
      set text: "  12345\n  abcde\nABCDE", cursor: [0, 0]

    describe "when followed by a <", ->
      it "indents the current line", ->
        ensure '<<',
          text: "12345\n  abcde\nABCDE"
          cursor: [0, 0]

    describe "when followed by a repeating <", ->
      beforeEach ->
        keystroke '2<<'

      it "indents multiple lines at once", ->
        ensure
          text: "12345\nabcde\nABCDE"
          cursor: [0, 0]

      describe "undo behavior", ->
        it "indents both lines", ->
          ensure 'u', text: "  12345\n  abcde\nABCDE"

    describe "in visual mode", ->
      it "indents the current line and exits visual mode", ->
        ensure 'V<',
          mode: 'normal'
          text: "12345\n  abcde\nABCDE"
          selectedBufferRange: [[0, 0], [0, 0]]

  describe "the = keybinding", ->
    oldGrammar = []

    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-javascript')

      oldGrammar = editor.getGrammar()
      set text: "foo\n  bar\n  baz", cursor: [1, 0]


    describe "when used in a scope that supports auto-indent", ->
      beforeEach ->
        jsGrammar = atom.grammars.grammarForScopeName('source.js')
        editor.setGrammar(jsGrammar)

      afterEach ->
        editor.setGrammar(oldGrammar)

      describe "when followed by a =", ->
        beforeEach ->
          keystroke '=='

        it "indents the current line", ->
          expect(editor.indentationForBufferRow(1)).toBe 0

      describe "when followed by a repeating =", ->
        beforeEach ->
          keystroke '2=='

        it "autoindents multiple lines at once", ->
          ensure text: "foo\nbar\nbaz", cursor: [1, 0]

        describe "undo behavior", ->
          it "indents both lines", ->
            ensure 'u', text: "foo\n  bar\n  baz"

  describe 'CamelCase', ->
    beforeEach ->
      set
        text: 'vim-mode\natom-text-editor\n'
        cursorBuffer: [0, 0]

    it "CamelCase text and not move cursor", ->
      ensure 'gc$', text: 'vimMode\natom-text-editor\n', cursor: [0, 0]
      ensure 'jgc$', text: 'vimMode\natomTextEditor\n', cursor: [1, 0]

    it "CamelCase selected text", ->
      ensure 'Vjgc', text: 'vimMode\natomTextEditor\n', cursor: [0, 0]

    it "gcgc CamelCase the line of text, won't move cursor", ->
      ensure 'lgcgc', text: 'vimMode\natom-text-editor\n', cursor: [0, 1]

  describe 'SnakeCase', ->
    beforeEach ->
      set
        text: 'vim-mode\natom-text-editor\n'
        cursorBuffer: [0, 0]
      atom.keymaps.add "g_",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          'g _': 'vim-mode-plus:snake-case'

    it "SnakeCase text and not move cursor", ->
      ensure 'g_$', text: 'vim_mode\natom-text-editor\n', cursor: [0, 0]
      ensure 'jg_$', text: 'vim_mode\natom_text_editor\n', cursor: [1, 0]

    it "SnakeCase selected text", ->
      ensure 'Vjg_', text: 'vim_mode\natom_text_editor\n', cursor: [0, 0]

    it "g_g_ SnakeCase the line of text, won't move cursor", ->
      ensure 'lg_g_', text: 'vim_mode\natom-text-editor\n', cursor: [0, 1]

  describe 'DashCase', ->
    beforeEach ->
      set
        text: 'vimMode\natom_text_editor\n'
        cursorBuffer: [0, 0]

    it "DashCase text and not move cursor", ->
      ensure 'g-$', text: 'vim-mode\natom_text_editor\n', cursor: [0, 0]
      ensure 'jg-$', text: 'vim-mode\natom-text-editor\n', cursor: [1, 0]

    it "DashCase selected text", ->
      ensure 'Vjg-', text: 'vim-mode\natom-text-editor\n', cursor: [0, 0]

    it "g-g- DashCase the line of text, won't move cursor", ->
      ensure 'lg-g-', text: 'vim-mode\natom_text_editor\n', cursor: [0, 1]

  describe 'surround', ->
    beforeEach ->
      set
        text: """
          apple
          pairs: [brackets]
          pairs: [brackets]
          ( multi
            line )
          """
        cursorBuffer: [0, 0]

    describe 'surround', ->
      beforeEach ->
        atom.keymaps.add "surround-test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'y s': 'vim-mode-plus:surround'
          , 100

      it "surround text object with ) and repeatable", ->
        ensure ['ysiw', char: ')'],
          text: "(apple)\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          cursor: [0, 0]
        ensure 'j.',
          text: "(apple)\n(pairs): [brackets]\npairs: [brackets]\n( multi\n  line )"
      it "surround text object with } and repeatable", ->
        ensure ['ysiw', char: '}'],
          text: "{apple}\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          cursor: [0, 0]
        ensure 'j.',
          text: "{apple}\n{pairs}: [brackets]\npairs: [brackets]\n( multi\n  line )"
      it "surround linewise", ->
        ensure ['ysys', char: '}'],
          text: "{\napple\n}\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          cursor: [0, 0]
        ensure '3j.',
          text: "{\napple\n}\n{\npairs: [brackets]\n}\npairs: [brackets]\n( multi\n  line )"
      it "surround text object with ( and space", ->
        ensure ['ysiw', char: '('],
          text: "( apple )\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          cursor: [0, 0]

    describe 'map-surround', ->
      beforeEach ->
        set
          text: """

            apple
            pairs tomato
            orange
            milk

            """
          cursorBuffer: [1, 0]

        atom.keymaps.add "ms",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'm s': 'vim-mode-plus:map-surround'
          'atom-text-editor.vim-mode-plus.visual-mode':
            'm s':  'vim-mode-plus:map-surround'
      it "surround text for each word in target case-1", ->
        ensure ['msip', char: ')'],
          text: "\n(apple)\n(pairs) (tomato)\n(orange)\n(milk)\n"
          cursor: [1, 0]
      it "surround text for each word in target case-2", ->
        set cursor: [2, 1]
        ensure ['msil', char: '>'],
          text: '\napple\n<pairs> <tomato>\norange\nmilk\n'
          cursor: [2, 0]
      it "surround text for each word in visual selection", ->
        ensure ['vipms', char: '"'],
          text: '\n"apple"\n"pairs" "tomato"\n"orange"\n"milk"\n'
          cursor: [1, 0]

    describe 'delete surround', ->
      beforeEach ->
        atom.keymaps.add "surround-test",
          'atom-text-editor.vim-mode-plus.normal-mode':
            'd s': 'vim-mode-plus:delete-surround'
        set cursor: [1, 8]

      it "delete surrounded chars and repeatable", ->
        ensure ['ds', char: ']'],
          text: "apple\npairs: brackets\npairs: [brackets]\n( multi\n  line )"
        ensure 'jl.',
          text: "apple\npairs: brackets\npairs: brackets\n( multi\n  line )"
      it "delete surrounded chars expanded to multi-line", ->
        set cursor: [3, 1]
        ensure ['ds', char: ')'],
          text: "apple\npairs: [brackets]\npairs: [brackets]\nmulti\n line "
      it "delete surrounded chars and spaces", ->
        set
          text: """
            apple
            pairs: [   brackets   ]
            pairs: [   brackets   ]
            ( multi
              line )
            """
          cursor: [1, 8]
        ensure ['ds', char: '['],
          text: "apple\npairs: brackets\npairs: [   brackets   ]\n( multi\n  line )"

    describe 'change srurround', ->
      beforeEach ->
        atom.keymaps.add "surround-test",
          'atom-text-editor.vim-mode-plus.normal-mode':
            'c s': 'vim-mode-plus:change-surround'

        set
          text: """
            (apple)
            (grape)
            <lemmon>
            {orange}
            """
          cursorBuffer: [0, 1]
      it "change surrounded chars and repeatable", ->
        ensure ['cs', char: ')]'],
          text: """
            [apple]
            (grape)
            <lemmon>
            {orange}
            """
        ensure 'jl.',
          text: """
            [apple]
            [grape]
            <lemmon>
            {orange}
            """
      it "change surrounded chars", ->
        ensure ['jjcs', char: '>"'],
          text: """
            (apple)
            (grape)
            "lemmon"
            {orange}
            """
        ensure ['jlcs', char: '}!'],
          text: """
            (apple)
            (grape)
            "lemmon"
            !orange!
            """
      it "change surrounded chars and add space", ->
        ensure ['cs', char: ')['],
          text: """
            [ apple ]
            (grape)
            <lemmon>
            {orange}
            """
      it "remove surrounded space", ->
        set
          text: """
            (   apple   )
            (grape)
            <lemmon>
            {orange}
            """
          cursorBuffer: [0, 1]
        ensure ['cs', char: '()'],
          text: """
            (apple)
            (grape)
            <lemmon>
            {orange}
            """

    describe 'surround-word', ->
      beforeEach ->
        atom.keymaps.add "surround-test",
          'atom-text-editor.vim-mode-plus.normal-mode':
            'y s w': 'vim-mode-plus:surround-word'

      it "surround a word with ) and repeatable", ->
        ensure ['ysw', char: ')'],
          text: "(apple)\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          cursor: [0, 0]
        ensure 'j.',
          text: "(apple)\n(pairs): [brackets]\npairs: [brackets]\n( multi\n  line )"
      it "surround a word with } and repeatable", ->
        ensure ['ysw', char: '}'],
          text: "{apple}\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          cursor: [0, 0]
        ensure 'j.',
          text: "{apple}\n{pairs}: [brackets]\npairs: [brackets]\n( multi\n  line )"

    describe 'delete surround-any-pair', ->
      beforeEach ->
        set
          text: """
            apple
            (pairs: [brackets])
            {pairs "s" [brackets]}
            ( multi
              line )
            """
          cursor: [1, 9]

        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'd s': 'vim-mode-plus:delete-surround-any-pair'

      it "delete surrounded any pair found and repeatable", ->
        ensure 'ds',
          text: 'apple\n(pairs: brackets)\n{pairs "s" [brackets]}\n( multi\n  line )'
        ensure '.',
          text: 'apple\npairs: brackets\n{pairs "s" [brackets]}\n( multi\n  line )'

      it "delete surrounded any pair found with skip pair out of cursor and repeatable", ->
        set cursor: [2, 14]
        ensure 'ds',
          text: 'apple\n(pairs: [brackets])\n{pairs "s" brackets}\n( multi\n  line )'
        ensure '.',
          text: 'apple\n(pairs: [brackets])\npairs "s" brackets\n( multi\n  line )'
        ensure '.', # do nothing any more
          text: 'apple\n(pairs: [brackets])\npairs "s" brackets\n( multi\n  line )'

      it "delete surrounded chars expanded to multi-line", ->
        set cursor: [3, 1]
        ensure 'ds',
          text: 'apple\n(pairs: [brackets])\n{pairs "s" [brackets]}\nmulti\n line '

      it "delete surrounded any pair found and spaces", ->
        set
          text: """
            apple
            (pairs: [   brackets   ])
            {pairs "s" [   brackets   ]}
            ( multi
              line )
            """
          cursor: [1, 9]
        ensure 'ds',
          text: 'apple\n(pairs:    brackets   )\n{pairs "s" [   brackets   ]}\n( multi\n  line )'

    describe 'change surround-any-pair', ->
      beforeEach ->
        set
          text: """
            (apple)
            (grape)
            <lemmon>
            {orange}
            """
          cursor: [0, 1]

        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'c s': 'vim-mode-plus:change-surround-any-pair'

      it "change any surrounded pair found and repeatable", ->
        ensure ['cs', char: '>'],
          text: "<apple>\n(grape)\n<lemmon>\n{orange}"
        ensure 'j.',
          text: "<apple>\n<grape>\n<lemmon>\n{orange}"
        ensure 'jj.',
          text: "<apple>\n<grape>\n<lemmon>\n<orange>"
      it "change any surrounded pair found and space", ->
        ensure ['cs', char: '<'],
          text: "< apple >\n(grape)\n<lemmon>\n{orange}"

  describe 'ReplaceWithRegister', ->
    originalText = null
    beforeEach ->
      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          '_': 'vim-mode-plus:replace-with-register'

      originalText = """
      abc def 'aaa'
      here (parenthesis)
      here (parenthesis)
      """
      set
        text: originalText
        cursor: [0, 9]

      set register: '"': text: 'default register', type: 'character'
      set register: 'a': text: 'A register', type: 'character'

    it "replace selection with regisgter's content", ->
      ensure 'viw',
        selectedText: 'aaa'
      ensure '_',
        mode: 'normal'
        text: originalText.replace('aaa', 'default register')

    it "replace text object with regisgter's content", ->
      set cursor: [1, 6]
      ensure '_i(',
        mode: 'normal'
        text: originalText.replace('parenthesis', 'default register')

    it "can repeat", ->
      set cursor: [1, 6]
      ensure '_i(j.',
        mode: 'normal'
        text: originalText.replace(/parenthesis/g, 'default register')

    it "can use specified register to replace with", ->
      set cursor: [1, 6]
      ensure ['"', char: 'a', '_i('],
        mode: 'normal'
        text: originalText.replace('parenthesis', 'A register')

  describe 'ToggleLineComments', ->
    [oldGrammar, originalText] = []
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-coffee-script')

      runs ->
        oldGrammar = editor.getGrammar()
        grammar = atom.grammars.grammarForScopeName('source.coffee')
        editor.setGrammar(grammar)
        originalText = """
          class Base
            constructor: (args) ->
              pivot = items.shift()
              left = []
              right = []

          console.log "hello"
        """
        set text: originalText

    afterEach ->
      editor.setGrammar(oldGrammar)

    it 'toggle comment for textobject for indent and repeatable', ->
      set cursor: [2, 0]
      ensure 'g/ii',
        text: """
          class Base
            constructor: (args) ->
              # pivot = items.shift()
              # left = []
              # right = []

          console.log "hello"
        """
      ensure '.', text: originalText

    it 'toggle comment for textobject for paragraph and repeatable', ->
      set cursor: [2, 0]
      ensure 'g/ip',
        text: """
          # class Base
          #   constructor: (args) ->
          #     pivot = items.shift()
          #     left = []
          #     right = []

          console.log "hello"
        """

      ensure '.', text: originalText
