{getVimState, dispatch} = require './spec-helper'
settings = require '../lib/settings'

describe "Operator TransformString", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim

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
      ensure 'V j g C', text: 'VimMode\natomTextEditor\n', cursor: [0, 0]

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

  describe 'surround', ->
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

    describe 'alias keymap for surround, change-surround, delete-surround', ->
      it "surround by aliased char", ->
        set textC: "|abc"; ensure ['y s i w', input: 'b'], text: "(abc)"
        set textC: "|abc"; ensure ['y s i w', input: 'B'], text: "{abc}"
        set textC: "|abc"; ensure ['y s i w', input: 'r'], text: "[abc]"
        set textC: "|abc"; ensure ['y s i w', input: 'a'], text: "<abc>"
      it "delete surround by aliased char", ->
        set textC: "|(abc)"; ensure ['d S', input: 'b'], text: "abc"
        set textC: "|{abc}"; ensure ['d S', input: 'B'], text: "abc"
        set textC: "|[abc]"; ensure ['d S', input: 'r'], text: "abc"
        set textC: "|<abc>"; ensure ['d S', input: 'a'], text: "abc"
      it "change surround by aliased char", ->
        set textC: "|(abc)"; ensure ['c S', input: 'bB'], text: "{abc}"
        set textC: "|(abc)"; ensure ['c S', input: 'br'], text: "[abc]"
        set textC: "|(abc)"; ensure ['c S', input: 'ba'], text: "<abc>"

        set textC: "|{abc}"; ensure ['c S', input: 'Bb'], text: "(abc)"
        set textC: "|{abc}"; ensure ['c S', input: 'Br'], text: "[abc]"
        set textC: "|{abc}"; ensure ['c S', input: 'Ba'], text: "<abc>"

        set textC: "|[abc]"; ensure ['c S', input: 'rb'], text: "(abc)"
        set textC: "|[abc]"; ensure ['c S', input: 'rB'], text: "{abc}"
        set textC: "|[abc]"; ensure ['c S', input: 'ra'], text: "<abc>"

        set textC: "|<abc>"; ensure ['c S', input: 'ab'], text: "(abc)"
        set textC: "|<abc>"; ensure ['c S', input: 'aB'], text: "{abc}"
        set textC: "|<abc>"; ensure ['c S', input: 'ar'], text: "[abc]"

    describe 'surround', ->
      it "surround text object with ( and repeatable", ->
        ensure ['y s i w', input: '('],
          textC: "|(apple)\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
        ensure 'j .',
          text: "(apple)\n(pairs): [brackets]\npairs: [brackets]\n( multi\n  line )"
      it "surround text object with { and repeatable", ->
        ensure ['y s i w', input: '{'],
          textC: "|{apple}\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
        ensure 'j .',
          textC: "{apple}\n|{pairs}: [brackets]\npairs: [brackets]\n( multi\n  line )"
      it "surround current-line", ->
        ensure ['y s s', input: '{'],
          textC: "|{apple}\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
        ensure 'j .',
          textC: "{apple}\n|{pairs: [brackets]}\npairs: [brackets]\n( multi\n  line )"

      describe 'adjustIndentation when surround linewise target', ->
        beforeEach ->
          waitsForPromise ->
            atom.packages.activatePackage('language-javascript')
          runs ->
            set
              textC: """
                hello = () => {
                  if true {
                  |  console.log('hello');
                  }
                }
                """
              grammar: 'source.js'

        it "adjustIndentation surrounded text ", ->
          ensure ['y s i f', input: '{'],
            textC: """
              hello = () => {
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
            ensure ['y s f', input: 'e('], text: "(s _____ e)", cursor: [0, 0]

        describe "with '`' motion", ->
          beforeEach ->
            set cursor: [0, 8] # start at `e` char
            ensure 'm a', mark: 'a': [0, 8]
            set cursor: [0, 0]

          it "surround with '`' motion", ->
            ensure ['y s `', input: 'a('], text: "(s _____ )e", cursor: [0, 0]

      describe 'charactersToAddSpaceOnSurround setting', ->
        beforeEach ->
          settings.set('charactersToAddSpaceOnSurround', ['(', '{', '['])
          set
            textC: "|apple\norange\nlemmon"

        describe "char is in charactersToAddSpaceOnSurround", ->
          it "add additional space inside pair char when surround", ->
            ensure ['y s i w', input: '('], text: "( apple )\norange\nlemmon"
            keystroke 'j'
            ensure ['y s i w', input: '{'], text: "( apple )\n{ orange }\nlemmon"
            keystroke 'j'
            ensure ['y s i w', input: '['], text: "( apple )\n{ orange }\n[ lemmon ]"

        describe "char is not in charactersToAddSpaceOnSurround", ->
          it "add additional space inside pair char when surround", ->
            ensure ['y s i w', input: ')'], text: "(apple)\norange\nlemmon"
            keystroke 'j'
            ensure ['y s i w', input: '}'], text: "(apple)\n{orange}\nlemmon"
            keystroke 'j'
            ensure ['y s i w', input: ']'], text: "(apple)\n{orange}\n[lemmon]"

        describe "it distinctively handle aliased keymap", ->
          describe "normal pair-chars are set to add space", ->
            beforeEach ->
              settings.set('charactersToAddSpaceOnSurround', ['(', '{', '[', '<'])
            it "distinctively handle", ->
              set textC: "|abc"; ensure ['y s i w', input: '('], text: "( abc )"
              set textC: "|abc"; ensure ['y s i w', input: 'b'], text: "(abc)"
              set textC: "|abc"; ensure ['y s i w', input: '{'], text: "{ abc }"
              set textC: "|abc"; ensure ['y s i w', input: 'B'], text: "{abc}"
              set textC: "|abc"; ensure ['y s i w', input: '['], text: "[ abc ]"
              set textC: "|abc"; ensure ['y s i w', input: 'r'], text: "[abc]"
              set textC: "|abc"; ensure ['y s i w', input: '<'], text: "< abc >"
              set textC: "|abc"; ensure ['y s i w', input: 'a'], text: "<abc>"
          describe "aliased pair-chars are set to add space", ->
            beforeEach ->
              settings.set('charactersToAddSpaceOnSurround', ['b', 'B', 'r', 'a'])
            it "distinctively handle", ->
              set textC: "|abc"; ensure ['y s i w', input: '('], text: "(abc)"
              set textC: "|abc"; ensure ['y s i w', input: 'b'], text: "( abc )"
              set textC: "|abc"; ensure ['y s i w', input: '{'], text: "{abc}"
              set textC: "|abc"; ensure ['y s i w', input: 'B'], text: "{ abc }"
              set textC: "|abc"; ensure ['y s i w', input: '['], text: "[abc]"
              set textC: "|abc"; ensure ['y s i w', input: 'r'], text: "[ abc ]"
              set textC: "|abc"; ensure ['y s i w', input: '<'], text: "<abc>"
              set textC: "|abc"; ensure ['y s i w', input: 'a'], text: "< abc >"

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
        ensure 'm s i p (',
          textC: """

          |(apple)
          (pairs) (tomato)
          (orange)
          (milk)

          """
      it "surround text for each word in target case-2", ->
        set cursor: [2, 1]
        ensure 'm s i l <',
          textC: """

          apple
          <|pairs> <tomato>
          orange
          milk

          """
      # TODO#698 FIX when finished
      it "surround text for each word in visual selection", ->
        ensure 'v i p m s "',
          textC: """

          "apple"
          "pairs" "tomato"
          "orange"
          "mil|k"

          """

    describe 'delete surround', ->
      beforeEach ->
        set cursor: [1, 8]

      it "delete surrounded chars and repeatable", ->
        ensure ['d S', input: '['],
          text: "apple\npairs: brackets\npairs: [brackets]\n( multi\n  line )"
        ensure 'j l .',
          text: "apple\npairs: brackets\npairs: brackets\n( multi\n  line )"
      it "delete surrounded chars expanded to multi-line", ->
        set cursor: [3, 1]
        ensure ['d S', input: '('],
          text: "apple\npairs: [brackets]\npairs: [brackets]\n multi\n  line "
      it "delete surrounded chars and trim padding spaces for non-identical pair-char", ->
        set
          text: """
            ( apple )
            {  orange   }\n
            """
          cursor: [0, 0]
        ensure ['d S', input: '('], text: "apple\n{  orange   }\n"
        ensure ['j d S', input: '{'], text: "apple\norange\n"
      it "delete surrounded chars and NOT trim padding spaces for identical pair-char", ->
        set
          text: """
            ` apple `
            "  orange   "\n
            """
          cursor: [0, 0]
        ensure ['d S', input: '`'], text_: '_apple_\n"__orange___"\n'
        ensure ['j d S', input: '"'], text_: "_apple_\n__orange___\n"
      it "delete surrounded for multi-line but dont affect code layout", ->
        set
          cursor: [0, 34]
          text: """
            highlightRanges @editor, range, {
              timeout: timeout
              hello: world
            }
            """
        ensure ['d S', input: '{'],
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
        ensure ['c S', input: '(['],
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
        ensure ['j j c S', input: '<"'],
          text: """
            (apple)
            (grape)
            "lemmon"
            {orange}
            """
        ensure ['j l c S', input: '{!'],
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
        ensure ['c S', input: '{('],
          text: """
            highlightRanges @editor, range, (
              timeout: timeout
              hello: world
            )
            """

      describe 'charactersToAddSpaceOnSurround setting', ->
        ensureChangeSurround = (inputKeystrokes, options) ->
          set(text: options.initialText, cursor: [0, 0])
          delete options.initialText
          keystrokes = ['c S'].concat({input: inputKeystrokes})
          ensure(keystrokes, options)

        beforeEach ->
          settings.set('charactersToAddSpaceOnSurround', ['(', '{', '['])

        describe 'when input char is in charactersToAddSpaceOnSurround', ->
          describe 'single line text', ->
            it "add single space around pair regardless of exsiting inner text", ->
              ensureChangeSurround '({', initialText: "(apple)", text: "{ apple }"
              ensureChangeSurround '({', initialText: "( apple )", text: "{ apple }"
              ensureChangeSurround '({', initialText: "(  apple  )", text: "{ apple }"

          describe 'multi line text', ->
            it "don't sadd single space around pair", ->
              ensureChangeSurround '({', initialText: "(\napple\n)", text: "{\napple\n}"

        describe 'when first input char is not in charactersToAddSpaceOnSurround', ->
          it "remove surrounding space of inner text for identical pair-char", ->
            ensureChangeSurround '(}', initialText: "(apple)", text: "{apple}"
            ensureChangeSurround '(}', initialText: "( apple )", text: "{apple}"
            ensureChangeSurround '(}', initialText: "(  apple  )", text: "{apple}"
          it "doesn't remove surrounding space of inner text for non-identical pair-char", ->
            ensureChangeSurround '"`', initialText: '"apple"', text: "`apple`"
            ensureChangeSurround '"`', initialText: '"  apple  "', text: "`  apple  `"
            ensureChangeSurround "\"'", initialText: '"  apple  "', text: "'  apple  '"

    describe 'surround-word', ->
      beforeEach ->
        atom.keymaps.add "surround-test",
          'atom-text-editor.vim-mode-plus.normal-mode':
            'y s w': 'vim-mode-plus:surround-word'

      it "surround a word with ( and repeatable", ->
        ensure ['y s w', input: '('],
          textC: "|(apple)\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
        ensure 'j .',
          textC: "(apple)\n|(pairs): [brackets]\npairs: [brackets]\n( multi\n  line )"
      it "surround a word with { and repeatable", ->
        ensure ['y s w', input: '{'],
          textC: "|{apple}\npairs: [brackets]\npairs: [brackets]\n( multi\n  line )"
        ensure 'j .',
          textC: "{apple}\n|{pairs}: [brackets]\npairs: [brackets]\n( multi\n  line )"

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
        ensure ['c s', input: '<'], textC: "|<apple>\n(grape)\n<lemmon>\n{orange}"
        ensure 'j .', textC: "<apple>\n|<grape>\n<lemmon>\n{orange}"
        ensure 'j j .', textC: "<apple>\n<grape>\n<lemmon>\n|<orange>"

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
        ensure ['c s', input: '<'],
          textC: """
          |___<inner>
          ___(inner)
          """
        ensure 'j .',
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
      ensure ['"', input: 'a', 'g p i ('],
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
        ensure 'g J : : enter',
          textC_: """
          __0|12::345
          __678
          __9ab\n
          """
        ensure '.',
          textC_: """
          __0|12::345::678
          __9ab\n
          """
        ensure 'u u',
          textC_: """
          __0|12
          __345
          __678
          __9ab\n
          """
        ensure '4 g J : : enter',
          textC_: """
          __0|12::345::678::9ab\n
          """

    describe "JoinByInputWithKeepingSpace", ->
      beforeEach ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'g J': 'vim-mode-plus:join-by-input-with-keeping-space'

      it "joins lines by char from user without triming leading whitespace", ->
        ensure 'g J : : enter',
          textC_: """
          __0|12::__345
          __678
          __9ab\n
          """
        ensure '.',
          textC_: """
          __0|12::__345::__678
          __9ab\n
          """
        ensure 'u u',
          textC_: """
          __0|12
          __345
          __678
          __9ab\n
          """
        ensure '4 g J : : enter',
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
        ensure "g / : enter",
          textC: """
          |a
          b
          c
          d:e:f\n
          """
        ensure "G .",
          textC: """
          a
          b
          c
          |d
          e
          f\n
          """
    describe "SplitStringWithKeepingSplitter", ->
      it "split string into lines without removing spliter char", ->
        ensure "g ? : enter",
          textC: """
          |a:
          b:
          c
          d:e:f\n
          """
        ensure "G .",
          textC: """
          a:
          b:
          c
          |d:
          e:
          f\n
          """

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
        keystroke 'j w'
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
