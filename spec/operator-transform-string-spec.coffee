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
    vimState.resetNormalMode()

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
      ensure '4 ~',
        text: 'AbC\nxYz'
        cursor: [[0, 2], [1, 2]]

    describe "in visual mode", ->
      it "toggles the case of the selected text", ->
        set cursorBuffer: [0, 0]
        ensure 'V ~', text: 'AbC\nXyZ'

    describe "with g and motion", ->
      it "toggles the case of text, won't move cursor", ->
        set cursorBuffer: [0, 0]
        ensure 'g ~ 2 l', text: 'Abc\nXyZ', cursor: [0, 0]

      it "g~~ toggles the line of text, won't move cursor", ->
        set cursorBuffer: [0, 1]
        ensure 'g ~ ~', text: 'AbC\nXyZ', cursor: [0, 1]

      it "g~g~ toggles the line of text, won't move cursor", ->
        set cursorBuffer: [0, 1]
        ensure 'g ~ g ~', text: 'AbC\nXyZ', cursor: [0, 1]

  describe 'the U keybinding', ->
    beforeEach ->
      set
        text: 'aBc\nXyZ'
        cursorBuffer: [0, 0]

    it "makes text uppercase with g and motion, and won't move cursor", ->
      ensure 'g U l', text: 'ABc\nXyZ', cursor: [0, 0]
      ensure 'g U e', text: 'ABC\nXyZ', cursor: [0, 0]
      set cursorBuffer: [1, 0]
      ensure 'g U $', text: 'ABC\nXYZ', cursor: [1, 0]

    it "makes the selected text uppercase in visual mode", ->
      ensure 'V U', text: 'ABC\nXyZ'

    it "gUU upcase the line of text, won't move cursor", ->
      set cursorBuffer: [0, 1]
      ensure 'g U U', text: 'ABC\nXyZ', cursor: [0, 1]

    it "gUgU upcase the line of text, won't move cursor", ->
      set cursorBuffer: [0, 1]
      ensure 'g U g U', text: 'ABC\nXyZ', cursor: [0, 1]

  describe 'the u keybinding', ->
    beforeEach ->
      set text: 'aBc\nXyZ', cursorBuffer: [0, 0]

    it "makes text lowercase with g and motion, and won't move cursor", ->
      ensure 'g u $', text: 'abc\nXyZ', cursor: [0, 0]

    it "makes the selected text lowercase in visual mode", ->
      ensure 'V u', text: 'abc\nXyZ'

    it "guu downcase the line of text, won't move cursor", ->
      set cursorBuffer: [0, 1]
      ensure 'g u u', text: 'abc\nXyZ', cursor: [0, 1]

    it "gugu downcase the line of text, won't move cursor", ->
      set cursorBuffer: [0, 1]
      ensure 'g u g u', text: 'abc\nXyZ', cursor: [0, 1]

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
          ensure '> >',
            text: "12345\nabcde\n  ABCDE"
            cursor: [2, 2]

    describe "on the first line", ->
      beforeEach ->
        set cursor: [0, 0]

      describe "when followed by a >", ->
        it "indents the current line", ->
          ensure '> >',
            text: "  12345\nabcde\nABCDE"
            cursor: [0, 2]

      describe "when followed by a repeating >", ->
        beforeEach ->
          keystroke '3 > >'

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
        keystroke 'V >'

      it "indents the current line and exits visual mode", ->
        ensure
          mode: 'normal'
          text: "  12345\nabcde\nABCDE"
          selectedBufferRange: [[0, 2], [0, 2]]

      it "allows repeating the operation", ->
        ensure '.', text: "    12345\nabcde\nABCDE"

    describe "in visual mode and stayOnTransformString enabled", ->
      beforeEach ->
        settings.set('stayOnTransformString', true)
        set cursor: [0, 0]

      it "indents the currrent selection and exits visual mode", ->
        ensure 'v j >',
          mode: 'normal'
          cursor: [1, 0]
          text: """
            12345
            abcde
          ABCDE
          """
      it "when repeated, operate on same range when cursor was not moved", ->
        ensure 'v j >',
          mode: 'normal'
          cursor: [1, 0]
          text: """
            12345
            abcde
          ABCDE
          """
        ensure '.',
          mode: 'normal'
          cursor: [1, 0]
          text: """
              12345
              abcde
          ABCDE
          """
      it "when repeated, operate on relative range from cursor position with same extent when cursor was moved", ->
        ensure 'v j >',
          mode: 'normal'
          cursor: [1, 0]
          text: """
            12345
            abcde
          ABCDE
          """
        ensure 'l .',
          mode: 'normal'
          cursor: [1, 2]
          text: "  12345\n    abcde\n  ABCDE"

  describe "the < keybinding", ->
    beforeEach ->
      set text: "  12345\n  abcde\nABCDE", cursor: [0, 0]

    describe "when followed by a <", ->
      it "indents the current line", ->
        ensure '< <',
          text: "12345\n  abcde\nABCDE"
          cursor: [0, 0]

    describe "when followed by a repeating <", ->
      beforeEach ->
        keystroke '2 < <'

      it "indents multiple lines at once", ->
        ensure
          text: "12345\nabcde\nABCDE"
          cursor: [0, 0]

      describe "undo behavior", ->
        it "indents both lines", ->
          ensure 'u', text: "  12345\n  abcde\nABCDE"

    describe "in visual mode", ->
      it "indents the current line and exits visual mode", ->
        ensure 'V <',
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
          keystroke '= ='

        it "indents the current line", ->
          expect(editor.indentationForBufferRow(1)).toBe 0

      describe "when followed by a repeating =", ->
        beforeEach ->
          keystroke '2 = ='

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

    it "transform text by motion and repeatable", ->
      ensure 'g c $', text: 'vimMode\natom-text-editor\n', cursor: [0, 0]
      ensure 'j .', text: 'vimMode\natomTextEditor\n', cursor: [1, 0]

    it "transform selection", ->
      ensure 'V j g c', text: 'vimMode\natomTextEditor\n', cursor: [0, 0]

    it "repeating twice works on current-line and won't move cursor", ->
      ensure 'l g c g c', text: 'vimMode\natom-text-editor\n', cursor: [0, 1]

  describe 'PascalCase', ->
    beforeEach ->
      set
        text: 'vim-mode\natom-text-editor\n'
        cursorBuffer: [0, 0]

    it "transform text by motion and repeatable", ->
      ensure 'g C $', text: 'VimMode\natom-text-editor\n', cursor: [0, 0]
      ensure 'j .', text: 'VimMode\nAtomTextEditor\n', cursor: [1, 0]

    it "transform selection", ->
      ensure 'V j g C', text: 'VimMode\natomTextEditor\n', cursor: [0, 0]

    it "repeating twice works on current-line and won't move cursor", ->
      ensure 'l g C g C', text: 'VimMode\natom-text-editor\n', cursor: [0, 1]

  describe 'SnakeCase', ->
    beforeEach ->
      set
        text: 'vim-mode\natom-text-editor\n'
        cursorBuffer: [0, 0]
      atom.keymaps.add "g_",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          'g _': 'vim-mode-plus:snake-case'

    it "transform text by motion and repeatable", ->
      ensure 'g _ $', text: 'vim_mode\natom-text-editor\n', cursor: [0, 0]
      ensure 'j .', text: 'vim_mode\natom_text_editor\n', cursor: [1, 0]

    it "transform selection", ->
      ensure 'V j g _', text: 'vim_mode\natom_text_editor\n', cursor: [0, 0]

    it "repeating twice works on current-line and won't move cursor", ->
      ensure 'l g _ g _', text: 'vim_mode\natom-text-editor\n', cursor: [0, 1]

  describe 'DashCase', ->
    beforeEach ->
      set
        text: 'vimMode\natom_text_editor\n'
        cursorBuffer: [0, 0]

    it "transform text by motion and repeatable", ->
      ensure 'g - $', text: 'vim-mode\natom_text_editor\n', cursor: [0, 0]
      ensure 'j .', text: 'vim-mode\natom-text-editor\n', cursor: [1, 0]

    it "transform selection", ->
      ensure 'V j g -', text: 'vim-mode\natom-text-editor\n', cursor: [0, 0]

    it "repeating twice works on current-line and won't move cursor", ->
      ensure 'l g - g -', text: 'vim-mode\natom_text_editor\n', cursor: [0, 1]

  describe 'CompactSpaces', ->
    beforeEach ->
      set
        cursorBuffer: [0, 0]

    describe "basic behavior", ->
      it "compats multiple space into one", ->
        set
          text: 'var0   =   0; var10   =   10'
          cursor: [0, 0]
        ensure 'g space $',
          text: 'var0 = 0; var10 = 10'
      it "don't apply compaction for leading and trailing space", ->
        set
          text_: """
          ___var0   =   0; var10   =   10___
          ___var1   =   1; var11   =   11___
          ___var2   =   2; var12   =   12___

          ___var4   =   4; var14   =   14___
          """
          cursor: [0, 0]
        ensure 'g space i p',
          text_: """
          ___var0 = 0; var10 = 10___
          ___var1 = 1; var11 = 11___
          ___var2 = 2; var12 = 12___

          ___var4   =   4; var14   =   14___
          """
      it "but it compact spaces when target all text is spaces", ->
        set
          text: '01234    90'
          cursor: [0, 5]
        ensure 'g space w',
          text: '01234 90'

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

      it "surround text object with ( and repeatable", ->
        # [FIXME] OLD STYLE
        ensure ['y s i w', input: '('],
          text: "(apple)\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          cursor: [0, 0]
        ensure 'j .',
          text: "(apple)\n(pairs): [brackets]\npairs: [brackets]\n( multi\n  line )"
      it "surround text object with { and repeatable", ->
        ensure ['y s i w', input: '{'],
          text: "{apple}\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          cursor: [0, 0]
        ensure 'j .',
          text: "{apple}\n{pairs}: [brackets]\npairs: [brackets]\n( multi\n  line )"
      it "surround linewise", ->
        ensure ['y s y s', input: '{'],
          text: "{\napple\n}\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          cursor: [0, 0]
        ensure '3 j .',
          text: "{\napple\n}\n{\npairs: [brackets]\n}\npairs: [brackets]\n( multi\n  line )"

      describe 'charactersToAddSpaceOnSurround setting', ->
        beforeEach ->
          set
            text: "apple\norange\nlemmon"
            cursorBuffer: [0, 0]

        it "add additional space inside pair char when surround", ->
          settings.set('charactersToAddSpaceOnSurround', ['(', '{', '['])
          ensure ['y s i w', input: '('], text: "( apple )\norange\nlemmon"
          keystroke 'j'
          ensure ['y s i w', input: '{'], text: "( apple )\n{ orange }\nlemmon"
          keystroke 'j'
          ensure ['y s i w', input: '['], text: "( apple )\n{ orange }\n[ lemmon ]"

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
        ensure ['m s i p', input: '('],
          text: "\n(apple)\n(pairs) (tomato)\n(orange)\n(milk)\n"
          cursor: [1, 0]
      it "surround text for each word in target case-2", ->
        set cursor: [2, 1]
        ensure ['m s i l', input: '<'],
          text: '\napple\n<pairs> <tomato>\norange\nmilk\n'
          cursor: [2, 0]
      it "surround text for each word in visual selection", ->
        ensure ['v i p m s', input: '"'],
          text: '\n"apple"\n"pairs" "tomato"\n"orange"\n"milk"\n'
          cursor: [1, 0]

    describe 'delete surround', ->
      beforeEach ->
        atom.keymaps.add "surround-test",
          'atom-text-editor.vim-mode-plus.normal-mode':
            'd s': 'vim-mode-plus:delete-surround'
        set cursor: [1, 8]

      it "delete surrounded chars and repeatable", ->
        ensure ['d s', input: '['],
          text: "apple\npairs: brackets\npairs: [brackets]\n( multi\n  line )"
        ensure 'j l .',
          text: "apple\npairs: brackets\npairs: brackets\n( multi\n  line )"
      it "delete surrounded chars expanded to multi-line", ->
        set cursor: [3, 1]
        ensure ['d s', input: '('],
          text: "apple\npairs: [brackets]\npairs: [brackets]\n multi\n  line "
      it "delete surrounded chars and trim padding spaces", ->
        set
          text: """
            ( apple )
            {  orange   }\n
            """
          cursor: [0, 0]
        ensure ['d s', input: '('], text: "apple\n{  orange   }\n"
        ensure ['j d s', input: '{'], text: "apple\norange\n"
      it "delete surrounded for multi-line but dont affect code layout", ->
        set
          cursor: [0, 34]
          text: """
            highlightRanges @editor, range, {
              timeout: timeout
              hello: world
            }
            """
        ensure ['d s', input: '{'],
          text: [
              "highlightRanges @editor, range, "
              "  timeout: timeout"
              "  hello: world"
              ""
            ].join("\n")

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
        ensure ['c s', input: '(['],
          text: """
            [apple]
            (grape)
            <lemmon>
            {orange}
            """
        ensure 'j l .',
          text: """
            [apple]
            [grape]
            <lemmon>
            {orange}
            """
      it "change surrounded chars", ->
        ensure ['j j c s', input: '<"'],
          text: """
            (apple)
            (grape)
            "lemmon"
            {orange}
            """
        ensure ['j l c s', input: '{!'],
          text: """
            (apple)
            (grape)
            "lemmon"
            !orange!
            """

      it "change surrounded for multi-line but dont affect code layout", ->
        set
          cursor: [0, 34]
          text: """
            highlightRanges @editor, range, {
              timeout: timeout
              hello: world
            }
            """
        ensure ['c s', input: '{('],
          text: """
            highlightRanges @editor, range, (
              timeout: timeout
              hello: world
            )
            """

    describe 'surround-word', ->
      beforeEach ->
        atom.keymaps.add "surround-test",
          'atom-text-editor.vim-mode-plus.normal-mode':
            'y s w': 'vim-mode-plus:surround-word'

      it "surround a word with ( and repeatable", ->
        ensure ['y s w', input: '('],
          text: "(apple)\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          cursor: [0, 0]
        ensure 'j .',
          text: "(apple)\n(pairs): [brackets]\npairs: [brackets]\n( multi\n  line )"
      it "surround a word with { and repeatable", ->
        ensure ['y s w', input: '{'],
          text: "{apple}\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          cursor: [0, 0]
        ensure 'j .',
          text: "{apple}\n{pairs}: [brackets]\npairs: [brackets]\n( multi\n  line )"

    describe 'delete-surround-any-pair', ->
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
        ensure 'd s',
          text: 'apple\n(pairs: brackets)\n{pairs "s" [brackets]}\n( multi\n  line )'
        ensure '.',
          text: 'apple\npairs: brackets\n{pairs "s" [brackets]}\n( multi\n  line )'

      it "delete surrounded any pair found with skip pair out of cursor and repeatable", ->
        set cursor: [2, 14]
        ensure 'd s',
          text: 'apple\n(pairs: [brackets])\n{pairs "s" brackets}\n( multi\n  line )'
        ensure '.',
          text: 'apple\n(pairs: [brackets])\npairs "s" brackets\n( multi\n  line )'
        ensure '.', # do nothing any more
          text: 'apple\n(pairs: [brackets])\npairs "s" brackets\n( multi\n  line )'

      it "delete surrounded chars expanded to multi-line", ->
        set cursor: [3, 1]
        ensure 'd s',
          text: 'apple\n(pairs: [brackets])\n{pairs "s" [brackets]}\n multi\n  line '

    describe 'delete-surround-any-pair-allow-forwarding', ->
      beforeEach ->
        settings.set('stayOnTransformString', true)
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'd s': 'vim-mode-plus:delete-surround-any-pair-allow-forwarding'
      it "[1] single line", ->
        set
          cursor: [0, 0]
          text: """
          ___(inner)
          ___(inner)
          """
        ensure 'd s',
          text: """
          ___inner
          ___(inner)
          """
          cursor: [0, 0]
        ensure 'j .',
          text: """
          ___inner
          ___inner
          """
          cursor: [1, 0]

    describe 'change-surround-any-pair', ->
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
        ensure ['c s', input: '<'], text: "<apple>\n(grape)\n<lemmon>\n{orange}"
        ensure 'j .', text: "<apple>\n<grape>\n<lemmon>\n{orange}"
        ensure 'j j .', text: "<apple>\n<grape>\n<lemmon>\n<orange>"

    describe 'change-surround-any-pair-allow-forwarding', ->
      beforeEach ->
        settings.set('stayOnTransformString', true)
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'c s': 'vim-mode-plus:change-surround-any-pair-allow-forwarding'
      it "[1] single line", ->
        set
          cursor: [0, 0]
          text: """
          ___(inner)
          ___(inner)
          """
        ensure ['c s', input: '<'],
          text: """
          ___<inner>
          ___(inner)
          """
          cursor: [0, 0]
        ensure 'j .',
          text: """
          ___<inner>
          ___<inner>
          """
          cursor: [1, 0]

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
      ensure 'v i w',
        selectedText: 'aaa'
      ensure '_',
        mode: 'normal'
        text: originalText.replace('aaa', 'default register')

    it "replace text object with regisgter's content", ->
      set cursor: [1, 6]
      ensure '_ i (',
        mode: 'normal'
        text: originalText.replace('parenthesis', 'default register')

    it "can repeat", ->
      set cursor: [1, 6]
      ensure '_ i ( j .',
        mode: 'normal'
        text: originalText.replace(/parenthesis/g, 'default register')

    it "can use specified register to replace with", ->
      set cursor: [1, 6]
      ensure ['"', input: 'a', '_ i ('],
        mode: 'normal'
        text: originalText.replace('parenthesis', 'A register')

  describe 'SwapWithRegister', ->
    originalText = null
    beforeEach ->
      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          'g p': 'vim-mode-plus:swap-with-register'

      originalText = """
      abc def 'aaa'
      here (111)
      here (222)
      """
      set
        text: originalText
        cursor: [0, 9]

      set register: '"': text: 'default register', type: 'character'
      set register: 'a': text: 'A register', type: 'character'

    it "swap selection with regisgter's content", ->
      ensure 'v i w', selectedText: 'aaa'
      ensure 'g p',
        mode: 'normal'
        text: originalText.replace('aaa', 'default register')
        register: '"': text: 'aaa'

    it "swap text object with regisgter's content", ->
      set cursor: [1, 6]
      ensure 'g p i (',
        mode: 'normal'
        text: originalText.replace('111', 'default register')
        register: '"': text: '111'

    it "can repeat", ->
      set cursor: [1, 6]
      updatedText = """
        abc def 'aaa'
        here (default register)
        here (111)
        """
      ensure 'g p i ( j .',
        mode: 'normal'
        text: updatedText
        register: '"': text: '222'

    it "can use specified register to swap with", ->
      set cursor: [1, 6]
      ensure ['"', input: 'a', 'g p i ('],
        mode: 'normal'
        text: originalText.replace('111', 'A register')
        register: 'a': text: '111'

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
      ensure 'g / i i',
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
      ensure 'g / i p',
        text: """
          # class Base
          #   constructor: (args) ->
          #     pivot = items.shift()
          #     left = []
          #     right = []

          console.log "hello"
        """

      ensure '.', text: originalText
