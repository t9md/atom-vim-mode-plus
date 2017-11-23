{getVimState, dispatch} = require './spec-helper'
settings = require '../lib/settings'

describe "Operator TransformString", ->
  [set, ensure, ensureWait, bindEnsureOption, bindEnsureWaitOption] = []
  [editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, ensureWait, bindEnsureOption, bindEnsureWaitOption} = vim

  describe 'the ~ keybinding', ->
    beforeEach ->
      set
        textC: """
        |aBc
        |XyZ
        """

    it 'toggles the case and moves right', ->
      ensure '~',
        textC: """
        A|Bc
        x|yZ
        """
      ensure '~',
        textC: """
        Ab|c
        xY|Z
        """

      ensure  '~',
        textC: """
        Ab|C
        xY|z
        """

    it 'takes a count', ->
      ensure '4 ~',
        textC: """
        Ab|C
        xY|z
        """

    describe "in visual mode", ->
      it "toggles the case of the selected text", ->
        set cursor: [0, 0]
        ensure 'V ~', text: 'AbC\nXyZ'

    describe "with g and motion", ->
      it "toggles the case of text, won't move cursor", ->
        set textC: "|aBc\nXyZ"
        ensure 'g ~ 2 l', textC: '|Abc\nXyZ'

      it "g~~ toggles the line of text, won't move cursor", ->
        set textC: "a|Bc\nXyZ"
        ensure 'g ~ ~', textC: 'A|bC\nXyZ'

      it "g~g~ toggles the line of text, won't move cursor", ->
        set textC: "a|Bc\nXyZ"
        ensure 'g ~ g ~', textC: 'A|bC\nXyZ'

  describe 'the U keybinding', ->
    beforeEach ->
      set
        text: 'aBc\nXyZ'
        cursor: [0, 0]

    it "makes text uppercase with g and motion, and won't move cursor", ->
      ensure 'g U l', text: 'ABc\nXyZ', cursor: [0, 0]
      ensure 'g U e', text: 'ABC\nXyZ', cursor: [0, 0]
      set cursor: [1, 0]
      ensure 'g U $', text: 'ABC\nXYZ', cursor: [1, 0]

    it "makes the selected text uppercase in visual mode", ->
      ensure 'V U', text: 'ABC\nXyZ'

    it "gUU upcase the line of text, won't move cursor", ->
      set cursor: [0, 1]
      ensure 'g U U', text: 'ABC\nXyZ', cursor: [0, 1]

    it "gUgU upcase the line of text, won't move cursor", ->
      set cursor: [0, 1]
      ensure 'g U g U', text: 'ABC\nXyZ', cursor: [0, 1]

  describe 'the u keybinding', ->
    beforeEach ->
      set text: 'aBc\nXyZ', cursor: [0, 0]

    it "makes text lowercase with g and motion, and won't move cursor", ->
      ensure 'g u $', text: 'abc\nXyZ', cursor: [0, 0]

    it "makes the selected text lowercase in visual mode", ->
      ensure 'V u', text: 'abc\nXyZ'

    it "guu downcase the line of text, won't move cursor", ->
      set cursor: [0, 1]
      ensure 'g u u', text: 'abc\nXyZ', cursor: [0, 1]

    it "gugu downcase the line of text, won't move cursor", ->
      set cursor: [0, 1]
      ensure 'g u g u', text: 'abc\nXyZ', cursor: [0, 1]

  describe "the > keybinding", ->
    beforeEach ->
      set text: """
        12345
        abcde
        ABCDE
        """

    describe "> >", ->
      describe "from first line", ->
        it "indents the current line", ->
          set cursor: [0, 0]
          ensure '> >',
            textC: """
              |12345
            abcde
            ABCDE
            """
        it "count means N line indents and undoable, repeatable", ->
          set cursor: [0, 0]
          ensure '3 > >',
            textC_: """
            __|12345
            __abcde
            __ABCDE
            """

          ensure 'u',
            textC: """
            |12345
            abcde
            ABCDE
            """

          ensure '. .',
            textC_: """
            ____|12345
            ____abcde
            ____ABCDE
            """

      describe "from last line", ->
        it "indents the current line", ->
          set cursor: [2, 0]
          ensure '> >',
            textC: """
            12345
            abcde
              |ABCDE
            """

    describe "in visual mode", ->
      beforeEach ->
        set cursor: [0, 0]

      it "[vC] indent selected lines", ->
        ensure "v j >",
          mode: 'normal'
          textC_: """
          __|12345
          __abcde
          ABCDE
          """
      it "[vL] indent selected lines", ->
        ensure "V >",
          mode: 'normal'
          textC_: """
          __|12345
          abcde
          ABCDE
          """
        ensure '.',
          textC_: """
          ____|12345
          abcde
          ABCDE
          """
      it "[vL] count means N times indent", ->
        ensure "V 3 >",
          mode: 'normal'
          textC_: """
          ______|12345
          abcde
          ABCDE
          """
        ensure '.',
          textC_: """
          ____________|12345
          abcde
          ABCDE
          """

    describe "in visual mode and stayOnTransformString enabled", ->
      beforeEach ->
        settings.set('stayOnTransformString', true)
        set cursor: [0, 0]

      it "indents the current selection and exits visual mode", ->
        ensure 'v j >',
          mode: 'normal'
          textC: """
            12345
            |abcde
          ABCDE
          """
      it "when repeated, operate on same range when cursor was not moved", ->
        ensure 'v j >',
          mode: 'normal'
          textC: """
            12345
            |abcde
          ABCDE
          """
        ensure '.',
          mode: 'normal'
          textC: """
              12345
              |abcde
          ABCDE
          """
      it "when repeated, operate on relative range from cursor position with same extent when cursor was moved", ->
        ensure 'v j >',
          mode: 'normal'
          textC: """
            12345
            |abcde
          ABCDE
          """
        ensure 'l .',
          mode: 'normal'
          textC_: """
          __12345
          ____a|bcde
          __ABCDE
          """

  describe "the < keybinding", ->
    beforeEach ->
      set
        textC_: """
        |__12345
        __abcde
        ABCDE
        """

    describe "when followed by a <", ->
      it "indents the current line", ->
        ensure '< <',
          textC_: """
          |12345
          __abcde
          ABCDE
          """

    describe "when followed by a repeating <", ->
      it "indents multiple lines at once and undoable", ->
        ensure '2 < <',
          textC_: """
          |12345
          abcde
          ABCDE
          """
        ensure 'u',
          textC_: """
          |__12345
          __abcde
          ABCDE
          """

    describe "in visual mode", ->
      beforeEach ->
        set
          textC_: """
          |______12345
          ______abcde
          ABCDE
          """

      it "count means N times outdent", ->
        ensure 'V j 2 <',
          textC_: """
          __|12345
          __abcde
          ABCDE
          """
        # This is not ideal cursor position, but current limitation.
        # Since indent depending on Atom's selection.indentSelectedRows()
        # Implementing it vmp independently solve issue, but I have another idea and want to use Atom's one now.
        ensure 'u',
          textC_: """
          ______12345
          |______abcde
          ABCDE
          """

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
          ensure '= ='

        it "indents the current line", ->
          expect(editor.indentationForBufferRow(1)).toBe 0

      describe "when followed by a repeating =", ->
        beforeEach ->
          ensure '2 = ='

        it "autoindents multiple lines at once", ->
          ensure null, text: "foo\nbar\nbaz", cursor: [1, 0]

        describe "undo behavior", ->
          it "indents both lines", ->
            ensure 'u', text: "foo\n  bar\n  baz"

  describe 'CamelCase', ->
    beforeEach ->
      set
        text: 'vim-mode\natom-text-editor\n'
        cursor: [0, 0]

    it "transform text by motion and repeatable", ->
      ensure 'g C $', text: 'vimMode\natom-text-editor\n', cursor: [0, 0]
      ensure 'j .', text: 'vimMode\natomTextEditor\n', cursor: [1, 0]

    it "transform selection", ->
      ensure 'V j g C', text: 'vimMode\natomTextEditor\n', cursor: [0, 0]

    it "repeating twice works on current-line and won't move cursor", ->
      ensure 'l g C g C', text: 'vimMode\natom-text-editor\n', cursor: [0, 1]

  describe 'PascalCase', ->
    beforeEach ->
      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          'g C': 'vim-mode-plus:pascal-case'

      set
        text: 'vim-mode\natom-text-editor\n'
        cursor: [0, 0]

    it "transform text by motion and repeatable", ->
      ensure 'g C $', text: 'VimMode\natom-text-editor\n', cursor: [0, 0]
      ensure 'j .', text: 'VimMode\nAtomTextEditor\n', cursor: [1, 0]

    it "transform selection", ->
      ensure 'V j g C', text: 'VimMode\nAtomTextEditor\n', cursor: [0, 0]

    it "repeating twice works on current-line and won't move cursor", ->
      ensure 'l g C g C', text: 'VimMode\natom-text-editor\n', cursor: [0, 1]

  describe 'SnakeCase', ->
    beforeEach ->
      set
        text: 'vim-mode\natom-text-editor\n'
        cursor: [0, 0]
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
        cursor: [0, 0]

    it "transform text by motion and repeatable", ->
      ensure 'g - $', text: 'vim-mode\natom_text_editor\n', cursor: [0, 0]
      ensure 'j .', text: 'vim-mode\natom-text-editor\n', cursor: [1, 0]

    it "transform selection", ->
      ensure 'V j g -', text: 'vim-mode\natom-text-editor\n', cursor: [0, 0]

    it "repeating twice works on current-line and won't move cursor", ->
      ensure 'l g - g -', text: 'vim-mode\natom_text_editor\n', cursor: [0, 1]

  describe 'ConvertToSoftTab', ->
    beforeEach ->
      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          'g tab': 'vim-mode-plus:convert-to-soft-tab'

    describe "basic behavior", ->
      it "convert tabs to spaces", ->
        expect(editor.getTabLength()).toBe(2)
        set
          text: "\tvar10 =\t\t0;"
          cursor: [0, 0]
        ensure 'g tab $',
          text: "  var10 =   0;"

  describe 'ConvertToHardTab', ->
    beforeEach ->
      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          'g shift-tab': 'vim-mode-plus:convert-to-hard-tab'

    describe "basic behavior", ->
      it "convert spaces to tabs", ->
        expect(editor.getTabLength()).toBe(2)
        set
          text: "  var10 =    0;"
          cursor: [0, 0]
        ensure 'g shift-tab $',
          text: "\tvar10\t=\t\t 0;"

  describe 'CompactSpaces', ->
    beforeEach ->
      set
        cursor: [0, 0]

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

  describe 'AlignOccurrence family', ->
    beforeEach ->
      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          'g |': 'vim-mode-plus:align-occurrence'

    describe "AlignOccurrence", ->
      it "align by =", ->
        set
          textC: """

          a |= 100
          bcd = 1
          ijklm = 1000

          """
        ensure "g | p",
          textC: """

          a |    = 100
          bcd   = 1
          ijklm = 1000

          """
      it "align by comma", ->
        set
          textC: """

          a|, 100, 30
          b, 30000, 50
          200000, 1

          """
        ensure "g | p",
          textC: """

          a|,      100,   30
          b,      30000, 50
          200000, 1

          """
      it "align by non-word-char-ending", ->
        set
          textC: """

          abc|: 10
          defgh: 20
          ij: 30

          """
        ensure "g | p",
          textC: """

          abc|:   10
          defgh: 20
          ij:    30

          """
      it "align by normal word", ->
        set
          textC: """

          xxx fir|stName: "Hello", lastName: "World"
          yyyyyyyy firstName: "Good Bye", lastName: "World"

          """
        ensure "g | p",
          textC: """

          xxx    |  firstName: "Hello", lastName: "World"
          yyyyyyyy firstName: "Good Bye", lastName: "World"

          """
      it "align by `|` table-like text", ->
        set
          text: """

          +--------+------------------+---------+
          | where | move to 1st char | no move |
          +--------+------------------+---------+
          | top | `z enter` | `z t` |
          | middle | `z .` | `z z` |
          | bottom | `z -` | `z b` |
          +--------+------------------+---------+

          """
          cursor: [2, 0]
        ensure "g | p",
          text: """

          +--------+------------------+---------+
          | where  | move to 1st char | no move |
          +--------+------------------+---------+
          | top    | `z enter`        | `z t`   |
          | middle | `z .`            | `z z`   |
          | bottom | `z -`            | `z b`   |
          +--------+------------------+---------+

          """
          cursor: [2, 0]

  describe 'TrimString', ->
    beforeEach ->
      set
        text: " text = @getNewText( selection.getText(), selection )  "
        cursor: [0, 42]

    describe "basic behavior", ->
      it "trim string for a-line text object", ->
        set
          text_: """
          ___abc___
          ___def___
          """
          cursor: [0, 0]
        ensure 'g | a l',
          text_: """
          abc
          ___def___
          """
        ensure 'j .',
          text_: """
          abc
          def
          """
      it "trim string for inner-parenthesis text object", ->
        set
          text_: """
          (  abc  )
          (  def  )
          """
          cursor: [0, 0]
        ensure 'g | i (',
          text_: """
          (abc)
          (  def  )
          """
        ensure 'j .',
          text_: """
          (abc)
          (def)
          """
      it "trim string for inner-any-pair text object", ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode':
            'i ;':  'vim-mode-plus:inner-any-pair'

        set text_: "( [ {  abc  } ] )", cursor: [0, 8]
        ensure 'g | i ;', text_: "( [ {abc} ] )"
        ensure '2 h .', text_: "( [{abc}] )"
        ensure '2 h .', text_: "([{abc}])"

  describe 'surround family', ->
    beforeEach ->
      keymapsForSurround = {
        'atom-text-editor.vim-mode-plus.normal-mode':
          'y s': 'vim-mode-plus:surround'
          'd s': 'vim-mode-plus:delete-surround-any-pair'
          'd S': 'vim-mode-plus:delete-surround'
          'c s': 'vim-mode-plus:change-surround-any-pair'
          'c S': 'vim-mode-plus:change-surround'

        'atom-text-editor.vim-mode-plus.operator-pending-mode.surround-pending':
          's': 'vim-mode-plus:inner-current-line'

        'atom-text-editor.vim-mode-plus.visual-mode':
          'S': 'vim-mode-plus:surround'
      }

      atom.keymaps.add("keymaps-for-surround", keymapsForSurround)

      set
        textC: """
          |apple
          pairs: [brackets]
          pairs: [brackets]
          ( multi
            line )
          """

    describe 'cancellation', ->
      beforeEach ->
        set
          textC: """
          (a|bc) def
          (g!hi) jkl
          (m|no) pqr\n
          """

      describe 'surround cancellation', ->
        it "[normal] keep multpcursor on surround cancel", ->
          ensure "y s escape",
            textC: """
            (a|bc) def
            (g!hi) jkl
            (m|no) pqr\n
            """
            mode: "normal"

        it "[visual] keep multpcursor on surround cancel", ->
          ensure "v",
            mode: ["visual", "characterwise"]
            textC: """
            (ab|c) def
            (gh!i) jkl
            (mn|o) pqr\n
            """
            selectedTextOrdered: ["b", "h", "n"]
          ensureWait "S escape",
            mode: ["visual", "characterwise"]
            textC: """
            (ab|c) def
            (gh!i) jkl
            (mn|o) pqr\n
            """
            selectedTextOrdered: ["b", "h", "n"]

      describe 'delete-surround cancellation', ->
        it "[from normal] keep multpcursor on cancel", ->
          ensure "d S escape",
            mode: "normal"
            textC: """
            (a|bc) def
            (g!hi) jkl
            (m|no) pqr\n
            """

      describe 'change-surround cancellation', ->
        it "[from normal] keep multpcursor on cancel of 1st input", ->
          ensure "c S escape", # On choosing deleting pair-char
            mode: "normal"
            textC: """
            (a|bc) def
            (g!hi) jkl
            (m|no) pqr\n
            """
        it "[from normal] keep multpcursor on cancel of 2nd input", ->
          ensure "c S (",
            selectedTextOrdered: ["(abc)", "(ghi)", "(mno)"] # early select(for better UX) effect.

          ensureWait "escape", # On choosing deleting pair-char
            mode: "normal"
            textC: """
            (a|bc) def
            (g!hi) jkl
            (m|no) pqr\n
            """

      describe 'surround-word cancellation', ->
        beforeEach ->
          atom.keymaps.add "surround-test",
            'atom-text-editor.vim-mode-plus.normal-mode':
              'y s w': 'vim-mode-plus:surround-word'

        it "[from normal] keep multi cursor on cancel", ->
          ensure "y s w", selectedTextOrdered: ["abc", "ghi", "mno"] # select target immediately
          ensureWait "escape",
            mode: "normal"
            textC: """
            (a|bc) def
            (g!hi) jkl
            (m|no) pqr\n
            """

    describe 'alias keymap for surround, change-surround, delete-surround', ->
      describe "surround by aliased char", ->
        it "c1", -> set textC: "|abc"; ensureWait 'y s i w b', text: "(abc)"
        it "c2", -> set textC: "|abc"; ensureWait 'y s i w B', text: "{abc}"
        it "c3", -> set textC: "|abc"; ensureWait 'y s i w r', text: "[abc]"
        it "c4", -> set textC: "|abc"; ensureWait 'y s i w a', text: "<abc>"
      describe "delete surround by aliased char", ->
        it "c1", -> set textC: "|(abc)"; ensure 'd S b', text: "abc"
        it "c2", -> set textC: "|{abc}"; ensure 'd S B', text: "abc"
        it "c3", -> set textC: "|[abc]"; ensure 'd S r', text: "abc"
        it "c4", -> set textC: "|<abc>"; ensure 'd S a', text: "abc"
      describe "change surround by aliased char", ->
        it "c1", -> set textC: "|(abc)"; ensureWait 'c S b B', text: "{abc}"
        it "c2", -> set textC: "|(abc)"; ensureWait 'c S b r', text: "[abc]"
        it "c3", -> set textC: "|(abc)"; ensureWait 'c S b a', text: "<abc>"

        it "c4", -> set textC: "|{abc}"; ensureWait 'c S B b', text: "(abc)"
        it "c5", -> set textC: "|{abc}"; ensureWait 'c S B r', text: "[abc]"
        it "c6", -> set textC: "|{abc}"; ensureWait 'c S B a', text: "<abc>"

        it "c7", -> set textC: "|[abc]"; ensureWait 'c S r b', text: "(abc)"
        it "c8", -> set textC: "|[abc]"; ensureWait 'c S r B', text: "{abc}"
        it "c9", -> set textC: "|[abc]"; ensureWait 'c S r a', text: "<abc>"

        it "c10", -> set textC: "|<abc>"; ensureWait 'c S a b', text: "(abc)"
        it "c11", -> set textC: "|<abc>"; ensureWait 'c S a B', text: "{abc}"
        it "c12", -> set textC: "|<abc>"; ensureWait 'c S a r', text: "[abc]"

    describe 'surround', ->
      describe 'basic behavior', ->
        it "surround text object with ( and repeatable", ->
          ensureWait 'y s i w (', textC: "|(apple)\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          ensureWait 'j .',       textC: "(apple)\n|(pairs): [brackets]\npairs: [brackets]\n( multi\n  line )"
        it "surround text object with { and repeatable", ->
          ensureWait 'y s i w {', textC: "|{apple}\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          ensureWait 'j .',       textC: "{apple}\n|{pairs}: [brackets]\npairs: [brackets]\n( multi\n  line )"
        it "surround current-line", ->
          ensureWait 'y s s {', textC: "|{apple}\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
          ensureWait 'j .',     textC: "{apple}\n|{pairs: [brackets]}\npairs: [brackets]\n( multi\n  line )"

      describe 'adjustIndentation when surround linewise target', ->
        beforeEach ->
          waitsForPromise ->
            atom.packages.activatePackage('language-javascript')
          runs ->
            set
              textC: """
                function hello() {
                  if true {
                  |  console.log('hello');
                  }
                }
                """
              grammar: 'source.js'

        it "adjustIndentation surrounded text ", ->
          ensureWait 'y s i f {',
            textC: """
              function hello() {
              |  {
                  if true {
                    console.log('hello');
                  }
                }
              }
              """

      describe 'with motion which takes user-input', ->
        beforeEach ->
          set text: "s _____ e", cursor: [0, 0]
        describe "with 'f' motion", ->
          it "surround with 'f' motion", ->
            ensureWait 'y s f e (', text: "(s _____ e)", cursor: [0, 0]

        describe "with '`' motion", ->
          beforeEach ->
            runs ->
              set cursor: [0, 8] # start at `e` char
              ensureWait 'm a', mark: 'a': [0, 8]
            runs ->
              set cursor: [0, 0]

          it "surround with '`' motion", ->
            ensureWait 'y s ` a (', text: "(s _____ )e", cursor: [0, 0]

      describe 'charactersToAddSpaceOnSurround setting', ->
        beforeEach ->
          settings.set('charactersToAddSpaceOnSurround', ['(', '{', '['])
          set
            textC: "|apple\norange\nlemmon"

        describe "char is in charactersToAddSpaceOnSurround", ->
          it "add additional space inside pair char when surround", ->
            ensureWait 'y s i w (',   text: "( apple )\norange\nlemmon"
            ensureWait 'j y s i w {', text: "( apple )\n{ orange }\nlemmon"
            ensureWait 'j y s i w [', text: "( apple )\n{ orange }\n[ lemmon ]"

        describe "char is not in charactersToAddSpaceOnSurround", ->
          it "add additional space inside pair char when surround", ->
            ensureWait 'y s i w )',   text: "(apple)\norange\nlemmon"
            ensureWait 'j y s i w }', text: "(apple)\n{orange}\nlemmon"
            ensureWait 'j y s i w ]', text: "(apple)\n{orange}\n[lemmon]"

        describe "it distinctively handle aliased keymap", ->
          beforeEach -> set textC: "|abc"
          describe "normal pair-chars are set to add space", ->
            beforeEach -> settings.set('charactersToAddSpaceOnSurround', ['(', '{', '[', '<'])
            it "c1", -> ensureWait 'y s i w (', text: "( abc )"
            it "c2", -> ensureWait 'y s i w b', text: "(abc)"
            it "c3", -> ensureWait 'y s i w {', text: "{ abc }"
            it "c4", -> ensureWait 'y s i w B', text: "{abc}"
            it "c5", -> ensureWait 'y s i w [', text: "[ abc ]"
            it "c6", -> ensureWait 'y s i w r', text: "[abc]"
            it "c7", -> ensureWait 'y s i w <', text: "< abc >"
            it "c8", -> ensureWait 'y s i w a', text: "<abc>"
          describe "aliased pair-chars are set to add space", ->
            beforeEach -> settings.set('charactersToAddSpaceOnSurround', ['b', 'B', 'r', 'a'])
            it "c1", -> ensureWait 'y s i w (', text: "(abc)"
            it "c2", -> ensureWait 'y s i w b', text: "( abc )"
            it "c3", -> ensureWait 'y s i w {', text: "{abc}"
            it "c4", -> ensureWait 'y s i w B', text: "{ abc }"
            it "c5", -> ensureWait 'y s i w [', text: "[abc]"
            it "c6", -> ensureWait 'y s i w r', text: "[ abc ]"
            it "c7", -> ensureWait 'y s i w <', text: "<abc>"
            it "c8", -> ensureWait 'y s i w a', text: "< abc >"

    describe 'map-surround', ->
      beforeEach ->
        jasmine.attachToDOM(editorElement)

        set
          textC: """

            |apple
            pairs tomato
            orange
            milk

            """

        atom.keymaps.add "ms",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'm s': 'vim-mode-plus:map-surround'
          'atom-text-editor.vim-mode-plus.visual-mode':
            'm s':  'vim-mode-plus:map-surround'

      it "surround text for each word in target case-1", ->
        ensureWait 'm s i p (',
          text: """

          (apple)
          (pairs) (tomato)
          (orange)
          (milk)

          """
      it "surround text for each word in target case-2", ->
        set cursor: [2, 1]
        ensureWait 'm s i l <',
          textC: """

          apple
          <|pairs> <tomato>
          orange
          milk

          """
      it "surround text for each word in visual selection", ->
        settings.set("stayOnSelectTextObject", true)
        ensureWait 'v i p m s "',
          textC: """

          "apple"
          "pairs" "tomato"
          "orange"
          |"milk"

          """

    describe 'delete surround', ->
      beforeEach ->
        set cursor: [1, 8]

      it "delete surrounded chars and repeatable", ->
        ensure 'd S [',
          text: "apple\npairs: brackets\npairs: [brackets]\n( multi\n  line )"
        ensure 'j l .',
          text: "apple\npairs: brackets\npairs: brackets\n( multi\n  line )"
      it "delete surrounded chars expanded to multi-line", ->
        set cursor: [3, 1]
        ensure 'd S (',
          text: "apple\npairs: [brackets]\npairs: [brackets]\n multi\n  line "
      it "delete surrounded chars and trim padding spaces for non-identical pair-char", ->
        set
          text: """
            ( apple )
            {  orange   }\n
            """
          cursor: [0, 0]
        ensure 'd S (', text: "apple\n{  orange   }\n"
        ensure 'j d S {', text: "apple\norange\n"
      it "delete surrounded chars and NOT trim padding spaces for identical pair-char", ->
        set
          text: """
            ` apple `
            "  orange   "\n
            """
          cursor: [0, 0]
        ensure 'd S `', text_: '_apple_\n"__orange___"\n'
        ensure 'j d S "', text_: "_apple_\n__orange___\n"
      it "delete surrounded for multi-line but dont affect code layout", ->
        set
          cursor: [0, 34]
          text: """
            highlightRanges @editor, range, {
              timeout: timeout
              hello: world
            }
            """
        ensure 'd S {',
          text: [
              "highlightRanges @editor, range, "
              "  timeout: timeout"
              "  hello: world"
              ""
            ].join("\n")

    describe 'change surround', ->
      beforeEach ->
        set
          text: """
            (apple)
            (grape)
            <lemmon>
            {orange}
            """
          cursor: [0, 1]
      it "change surrounded chars and repeatable", ->
        ensureWait 'c S ( [',
          text: """
            [apple]
            (grape)
            <lemmon>
            {orange}
            """
        ensureWait 'j l .',
          text: """
            [apple]
            [grape]
            <lemmon>
            {orange}
            """
      it "change surrounded chars", ->
        ensureWait 'j j c S < "',
          text: """
            (apple)
            (grape)
            "lemmon"
            {orange}
            """
        ensureWait 'j l c S { !',
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
        ensureWait 'c S { (',
          text: """
            highlightRanges @editor, range, (
              timeout: timeout
              hello: world
            )
            """

      describe 'charactersToAddSpaceOnSurround setting', ->
        beforeEach ->
          settings.set('charactersToAddSpaceOnSurround', ['(', '{', '['])

        describe 'when input char is in charactersToAddSpaceOnSurround', ->
          describe '[single line text] add single space around pair regardless of exsiting inner text', ->
            it "case1", -> set textC: "|(apple)";     ensureWait 'c S ( {', text: "{ apple }"
            it "case2", -> set textC: "|( apple )";   ensureWait 'c S ( {', text: "{ apple }"
            it "case3", -> set textC: "|(  apple  )"; ensureWait 'c S ( {', text: "{ apple }"

          describe "[multi line text] don't add single space around pair", ->
            it "don't add single space around pair", ->
              set textC: "|(\napple\n)"; ensureWait "c S ( {", text: "{\napple\n}"

        describe 'when first input char is not in charactersToAddSpaceOnSurround', ->
          describe "remove surrounding space of inner text for identical pair-char", ->
            it "case1", -> set textC: "|(apple)";     ensureWait "c S ( }", text: "{apple}"
            it "case2", -> set textC: "|( apple )";   ensureWait "c S ( }", text: "{apple}"
            it "case3", -> set textC: "|(  apple  )"; ensureWait "c S ( }", text: "{apple}"
          describe "doesn't remove surrounding space of inner text for non-identical pair-char", ->
            it "case1", -> set textC: '|"apple"';     ensureWait 'c S " `', text: "`apple`"
            it "case2", -> set textC: '|"  apple  "'; ensureWait 'c S " `', text: "`  apple  `"
            it "case3", -> set textC: '|"  apple  "'; ensureWait 'c S " \'', text: "'  apple  '"

    describe 'surround-word', ->
      beforeEach ->
        atom.keymaps.add "surround-test",
          'atom-text-editor.vim-mode-plus.normal-mode':
            'y s w': 'vim-mode-plus:surround-word'

      it "surround a word with ( and repeatable", ->
        ensureWait 'y s w (', textC: "|(apple)\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
        ensureWait 'j .',     textC: "(apple)\n|(pairs): [brackets]\npairs: [brackets]\n( multi\n  line )"
      it "surround a word with { and repeatable", ->
        ensureWait 'y s w {', textC: "|{apple}\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
        ensureWait 'j .',     textC: "{apple}\n|{pairs}: [brackets]\npairs: [brackets]\n( multi\n  line )"

    describe 'delete-surround-any-pair', ->
      beforeEach ->
        set
          textC: """
            apple
            (pairs: [|brackets])
            {pairs "s" [brackets]}
            ( multi
              line )
            """

      it "delete surrounded any pair found and repeatable", ->
        ensure 'd s', text: 'apple\n(pairs: brackets)\n{pairs "s" [brackets]}\n( multi\n  line )'
        ensure '.',   text: 'apple\npairs: brackets\n{pairs "s" [brackets]}\n( multi\n  line )'

      it "delete surrounded any pair found with skip pair out of cursor and repeatable", ->
        set cursor: [2, 14]
        ensure 'd s', text: 'apple\n(pairs: [brackets])\n{pairs "s" brackets}\n( multi\n  line )'
        ensure '.',   text: 'apple\n(pairs: [brackets])\npairs "s" brackets\n( multi\n  line )'
        ensure '.',   text: 'apple\n(pairs: [brackets])\npairs "s" brackets\n( multi\n  line )' # do nothing any more

      it "delete surrounded chars expanded to multi-line", ->
        set cursor: [3, 1]
        ensure 'd s', text: 'apple\n(pairs: [brackets])\n{pairs "s" [brackets]}\n multi\n  line '

    describe 'delete-surround-any-pair-allow-forwarding', ->
      beforeEach ->
        atom.keymaps.add "keymaps-for-surround",
          'atom-text-editor.vim-mode-plus.normal-mode':
            'd s': 'vim-mode-plus:delete-surround-any-pair-allow-forwarding'

        settings.set('stayOnTransformString', true)

      it "[1] single line", ->
        set
          textC: """
          |___(inner)
          ___(inner)
          """
        ensure 'd s',
          textC: """
          |___inner
          ___(inner)
          """
        ensure 'j .',
          textC: """
          ___inner
          |___inner
          """

    describe 'change-surround-any-pair', ->
      beforeEach ->
        set
          textC: """
            (|apple)
            (grape)
            <lemmon>
            {orange}
            """

      it "change any surrounded pair found and repeatable", ->
        ensureWait 'c s <', textC: "|<apple>\n(grape)\n<lemmon>\n{orange}"
        ensureWait 'j .',   textC: "<apple>\n|<grape>\n<lemmon>\n{orange}"
        ensureWait '2 j .', textC: "<apple>\n<grape>\n<lemmon>\n|<orange>"

    describe 'change-surround-any-pair-allow-forwarding', ->
      beforeEach ->
        atom.keymaps.add "keymaps-for-surround",
          'atom-text-editor.vim-mode-plus.normal-mode':
            'c s': 'vim-mode-plus:change-surround-any-pair-allow-forwarding'
        settings.set('stayOnTransformString', true)
      it "[1] single line", ->
        set
          textC: """
          |___(inner)
          ___(inner)
          """
        ensureWait 'c s <',
          textC: """
          |___<inner>
          ___(inner)
          """
        ensureWait 'j .',
          textC: """
          ___<inner>
          |___<inner>
          """

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

      set register: '"': text: 'default register', type: 'characterwise'
      set register: 'a': text: 'A register', type: 'characterwise'

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
      ensure '" a _ i (',
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

      set register: '"': text: 'default register', type: 'characterwise'
      set register: 'a': text: 'A register', type: 'characterwise'

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
      ensure '" a g p i (',
        mode: 'normal'
        text: originalText.replace('111', 'A register')
        register: 'a': text: '111'

  describe "Join and it's family", ->
    beforeEach ->
      set
        textC_: """
        __0|12
        __345
        __678
        __9ab\n
        """

    describe "Join", ->
      it "joins lines with triming leading whitespace", ->
        ensure 'J',
          textC_: """
          __012| 345
          __678
          __9ab\n
          """
        ensure '.',
          textC_: """
          __012 345| 678
          __9ab\n
          """
        ensure '.',
          textC_: """
          __012 345 678| 9ab\n
          """

        ensure 'u',
          textC_: """
          __012 345| 678
          __9ab\n
          """
        ensure 'u',
          textC_: """
          __012| 345
          __678
          __9ab\n
          """
        ensure 'u',
          textC_: """
          __0|12
          __345
          __678
          __9ab\n
          """

      it "joins do nothing when it cannot join any more", ->
        # FIXME: "\n" remain it's inconsistent with multi-time J
        ensure '1 0 0 J', textC_: "  012 345 678 9a|b\n"

      it "joins do nothing when it cannot join any more", ->
        ensure 'J J J', textC_: "  012 345 678| 9ab\n"
        ensure 'J', textC_: "  012 345 678 9a|b"
        ensure 'J', textC_: "  012 345 678 9a|b"

    describe "JoinWithKeepingSpace", ->
      beforeEach ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'g J': 'vim-mode-plus:join-with-keeping-space'

      it "joins lines without triming leading whitespace", ->
        ensure 'g J',
          textC_: """
          __0|12__345
          __678
          __9ab\n
          """
        ensure '.',
          textC_: """
          __0|12__345__678
          __9ab\n
          """
        ensure 'u u',
          textC_: """
          __0|12
          __345
          __678
          __9ab\n
          """
        ensure '4 g J',
          textC_: """
          __0|12__345__678__9ab\n
          """

    describe "JoinByInput", ->
      beforeEach ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'g J': 'vim-mode-plus:join-by-input'

      it "joins lines by char from user with triming leading whitespace", ->
        ensureWait 'g J : : enter',
          textC_: """
          __0|12::345
          __678
          __9ab\n
          """
        ensureWait '.',
          textC_: """
          __0|12::345::678
          __9ab\n
          """
        ensureWait 'u u',
          textC_: """
          __0|12
          __345
          __678
          __9ab\n
          """
        ensureWait '4 g J : : enter',
          textC_: """
          __0|12::345::678::9ab\n
          """

      it "keep multi-cursors on cancel", ->
        set                        textC: "  0|12\n  345\n  6!78\n  9ab\n  c|de\n  fgh\n"
        ensureWait "g J : escape", textC: "  0|12\n  345\n  6!78\n  9ab\n  c|de\n  fgh\n"

    describe "JoinByInputWithKeepingSpace", ->
      beforeEach ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'g J': 'vim-mode-plus:join-by-input-with-keeping-space'

      it "joins lines by char from user without triming leading whitespace", ->
        ensureWait 'g J : : enter',
          textC_: """
          __0|12::__345
          __678
          __9ab\n
          """
        ensureWait '.',
          textC_: """
          __0|12::__345::__678
          __9ab\n
          """
        ensureWait 'u u',
          textC_: """
          __0|12
          __345
          __678
          __9ab\n
          """
        ensureWait '4 g J : : enter',
          textC_: """
          __0|12::__345::__678::__9ab\n
          """

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

  describe "SplitString, SplitStringWithKeepingSplitter", ->
    beforeEach ->
      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          'g /': 'vim-mode-plus:split-string'
          'g ?': 'vim-mode-plus:split-string-with-keeping-splitter'
      set
        textC: """
        |a:b:c
        d:e:f\n
        """
    describe "SplitString", ->
      it "split string into lines", ->
        ensureWait "g / : enter",
          textC: """
          |a
          b
          c
          d:e:f\n
          """
        ensureWait "G .",
          textC: """
          a
          b
          c
          |d
          e
          f\n
          """
      it "[from normal] keep multi-cursors on cancel", ->
        set                        textC_: "  0|12  345  6!78  9ab  c|de  fgh"
        ensureWait "g / : escape", textC_: "  0|12  345  6!78  9ab  c|de  fgh"
      it "[from visual] keep multi-cursors on cancel", ->
        set                      textC: "  0|12  345  6!78  9ab  c|de  fgh"
        ensure "v",              textC: "  01|2  345  67!8  9ab  cd|e  fgh", selectedTextOrdered: ["1", "7", "d"], mode: ["visual", "characterwise"]
        ensureWait "g / escape", textC: "  01|2  345  67!8  9ab  cd|e  fgh", selectedTextOrdered: ["1", "7", "d"], mode: ["visual", "characterwise"]

    describe "SplitStringWithKeepingSplitter", ->
      it "split string into lines without removing spliter char", ->
        ensureWait "g ? : enter",
          textC: """
          |a:
          b:
          c
          d:e:f\n
          """
        ensureWait "G .",
          textC: """
          a:
          b:
          c
          |d:
          e:
          f\n
          """
      it "keep multi-cursors on cancel", ->
        set                        textC_: "  0|12  345  6!78  9ab  c|de  fgh"
        ensureWait "g ? : escape", textC_: "  0|12  345  6!78  9ab  c|de  fgh"
      it "[from visual] keep multi-cursors on cancel", ->
        set                      textC: "  0|12  345  6!78  9ab  c|de  fgh"
        ensure "v",              textC: "  01|2  345  67!8  9ab  cd|e  fgh", selectedTextOrdered: ["1", "7", "d"], mode: ["visual", "characterwise"]
        ensureWait "g ? escape", textC: "  01|2  345  67!8  9ab  cd|e  fgh", selectedTextOrdered: ["1", "7", "d"], mode: ["visual", "characterwise"]

  describe "SplitArguments, SplitArgumentsWithRemoveSeparator", ->
    beforeEach ->
      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          'g ,': 'vim-mode-plus:split-arguments'
          'g !': 'vim-mode-plus:split-arguments-with-remove-separator'

      waitsForPromise ->
        atom.packages.activatePackage('language-javascript')
      runs ->
        set
          grammar: 'source.js'
          text: """
            hello = () => {
              {f1, f2, f3} = require('hello')
              f1(f2(1, "a, b, c"), 2, (arg) => console.log(arg))
              s = `abc def hij`
            }
            """

    describe "SplitArguments", ->
      it "split by commma with adjust indent", ->
        set cursor: [1, 3]
        ensure 'g , i {',
          textC: """
            hello = () => {
              |{
                f1,
                f2,
                f3
              } = require('hello')
              f1(f2(1, "a, b, c"), 2, (arg) => console.log(arg))
              s = `abc def hij`
            }
            """
      it "split by commma with adjust indent", ->
        set cursor: [2, 5]
        ensure 'g , i (',
          textC: """
            hello = () => {
              {f1, f2, f3} = require('hello')
              f1|(
                f2(1, "a, b, c"),
                2,
                (arg) => console.log(arg)
              )
              s = `abc def hij`
            }
            """
        ensure 'j w'
        ensure 'g , i (',
          textC: """
            hello = () => {
              {f1, f2, f3} = require('hello')
              f1(
                f2|(
                  1,
                  "a, b, c"
                ),
                2,
                (arg) => console.log(arg)
              )
              s = `abc def hij`
            }
            """
      it "split by white-space with adjust indent", ->
        set cursor: [3, 10]
        ensure 'g , i `',
          textC: """
            hello = () => {
              {f1, f2, f3} = require('hello')
              f1(f2(1, "a, b, c"), 2, (arg) => console.log(arg))
              s = |`
              abc
              def
              hij
              `
            }
            """

    describe "SplitByArgumentsWithRemoveSeparator", ->
      beforeEach ->
      it "remove splitter when split", ->
        set cursor: [1, 3]
        ensure 'g ! i {',
          textC: """
          hello = () => {
            |{
              f1
              f2
              f3
            } = require('hello')
            f1(f2(1, "a, b, c"), 2, (arg) => console.log(arg))
            s = `abc def hij`
          }
          """

  describe "Change Order faimliy: Reverse, Sort, SortCaseInsensitively, SortByNumber", ->
    beforeEach ->
      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          'g r': 'vim-mode-plus:reverse'
          'g s': 'vim-mode-plus:sort'
          'g S': 'vim-mode-plus:sort-by-number'
    describe "characterwise target", ->
      describe "Reverse", ->
        it "[comma separated] reverse text", ->
          set textC: "   ( dog, ca|t, fish, rabbit, duck, gopher, squid )"
          ensure 'g r i (', textC_: "   (| squid, gopher, duck, rabbit, fish, cat, dog )"
        it "[comma sparated] reverse text", ->
          set textC: "   ( 'dog ca|t', 'fish rabbit', 'duck gopher squid' )"
          ensure 'g r i (', textC_: "   (| 'duck gopher squid', 'fish rabbit', 'dog cat' )"
        it "[space sparated] reverse text", ->
          set textC: "   ( dog ca|t fish rabbit duck gopher squid )"
          ensure 'g r i (', textC_: "   (| squid gopher duck rabbit fish cat dog )"
        it "[comma sparated multi-line] reverse text", ->
          set textC: """
            {
              |1, 2, 3, 4,
              5, 6,
              7,
              8, 9
            }
            """
          ensure 'g r i {',
            textC: """
            {
            |  9, 8, 7, 6,
              5, 4,
              3,
              2, 1
            }
            """
        it "[comma sparated multi-line] keep comma followed to last entry", ->
          set textC: """
            [
              |1, 2, 3, 4,
              5, 6,
            ]
            """
          ensure 'g r i [',
            textC: """
            [
            |  6, 5, 4, 3,
              2, 1,
            ]
            """
        it "[comma sparated multi-line] aware of nexted pair and quotes and escaped quote", ->
          set textC: """
            (
              |"(a, b, c)", "[( d e f", test(g, h, i),
              "\\"j, k, l",
              '\\'m, n', test(o, p),
            )
            """
          ensure 'g r i (',
            textC: """
            (
            |  test(o, p), '\\'m, n', "\\"j, k, l",
              test(g, h, i),
              "[( d e f", "(a, b, c)",
            )
            """
        it "[space sparated multi-line] aware of nexted pair and quotes and escaped quote", ->
          set textC_: """
            (
              |"(a, b, c)" "[( d e f"      test(g, h, i)
              "\\"j, k, l"___
              '\\'m, n'    test(o, p)
            )
            """
          ensure 'g r i (',
            textC_: """
            (
            |  test(o, p) '\\'m, n'      "\\"j, k, l"
              test(g, h, i)___
              "[( d e f"    "(a, b, c)"
            )
            """
      describe "Sort", ->
        it "[comma separated] sort text", ->
          set textC: "   ( dog, ca|t, fish, rabbit, duck, gopher, squid )"
          ensure 'g s i (', textC: "   (| cat, dog, duck, fish, gopher, rabbit, squid )"
      describe "SortByNumber", ->
        it "[comma separated] sort by number", ->
          set textC_: "___(9, 1, |10, 5)"
          ensure 'g S i (', textC_: "___(|1, 5, 9, 10)"

    describe "linewise target", ->
      beforeEach ->
        set
          textC: """
          |z

          10a
          b
          a

          5
          1\n
          """
      describe "Reverse", ->
        it "reverse rows", ->
          ensure 'g r G',
            textC: """
            |1
            5

            a
            b
            10a

            z\n
            """
      describe "Sort", ->
        it "sort rows", ->
          ensure 'g s G',
            textC: """
            |

            1
            10a
            5
            a
            b
            z\n
            """
      describe "SortByNumber", ->
        it "sort rows numerically", ->
          ensure "g S G",
            textC: """
            |1
            5
            10a
            z

            b
            a
            \n
            """
      describe "SortCaseInsensitively", ->
        beforeEach ->
          atom.keymaps.add "test",
            'atom-text-editor.vim-mode-plus:not(.insert-mode)':
              'g s': 'vim-mode-plus:sort-case-insensitively'
        it "Sort rows case-insensitively", ->
          set
            textC: """
            |apple
            Beef
            APPLE
            DOG
            beef
            Apple
            BEEF
            Dog
            dog\n
            """

          ensure "g s G",
            text: """
            apple
            Apple
            APPLE
            beef
            Beef
            BEEF
            dog
            Dog
            DOG\n
            """

  describe "NumberingLines", ->
    ensureNumbering = (args...) ->
      dispatch(editor.element, 'vim-mode-plus:numbering-lines')
      ensure args...

    beforeEach -> set textC: "|a\nb\nc\n\n"
    it "numbering by motion", ->     ensureNumbering "j", textC: "|1: a\n2: b\nc\n\n"
    it "numbering by text-object", -> ensureNumbering "p", textC: "|1: a\n2: b\n3: c\n\n"

  describe "DuplicateWithCommentOutOriginal", ->
    beforeEach ->
      set
        textC: """

        1: |Pen
        2: Pineapple

        4: Apple
        5: Pen\n
        """

    it "dup-and-commentout", ->
      waitsForPromise ->
        atom.packages.activatePackage('language-javascript').then ->
          set grammar: "source.js"
          dispatch(editor.element, 'vim-mode-plus:duplicate-with-comment-out-original')
          ensure "i p",
            textC: """

            // 1: Pen
            // 2: Pineapple
            1: |Pen
            2: Pineapple

            4: Apple
            5: Pen\n
            """
      runs ->
        ensure ".",
          textC: """

          // // 1: Pen
          // // 2: Pineapple
          // 1: Pen
          // 2: Pineapple
          // 1: Pen
          // 2: Pineapple
          1: |Pen
          2: Pineapple

          4: Apple
          5: Pen\n
          """
    it "dup-and-commentout", ->
      waitsForPromise ->
        atom.packages.activatePackage('language-ruby').then ->
          set grammar: "source.ruby"
          dispatch(editor.element, 'vim-mode-plus:duplicate-with-comment-out-original')
          ensure "i p",
            textC: """

            # 1: Pen
            # 2: Pineapple
            1: |Pen
            2: Pineapple

            4: Apple
            5: Pen\n
            """
      runs ->
        ensure ".",
          textC: """

          # # 1: Pen
          # # 2: Pineapple
          # 1: Pen
          # 2: Pineapple
          # 1: Pen
          # 2: Pineapple
          1: |Pen
          2: Pineapple

          4: Apple
          5: Pen\n
          """
