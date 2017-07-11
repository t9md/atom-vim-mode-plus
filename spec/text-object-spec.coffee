{getVimState, dispatch, TextData} = require './spec-helper'
settings = require '../lib/settings'

describe "TextObject", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  getCheckFunctionFor = (textObject) ->
    (initialPoint, keystroke, options) ->
      set cursor: initialPoint
      ensure "#{keystroke} #{textObject}", options

  beforeEach ->
    getVimState (state, vimEditor) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vimEditor

  describe "TextObject", ->
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-coffee-script')
      getVimState 'sample.coffee', (state, vimEditor) ->
        {editor, editorElement} = state
        {set, ensure, keystroke} = vimEditor
    afterEach ->
      atom.packages.deactivatePackage('language-coffee-script')

    describe "when TextObject is excuted directly", ->
      it "select that TextObject", ->
        set cursor: [8, 7]
        dispatch(editorElement, 'vim-mode-plus:inner-word')
        ensure selectedText: 'QuickSort'

  describe "Word", ->
    describe "inner-word", ->
      beforeEach ->
        set
          text: "12345 abcde ABCDE"
          cursor: [0, 9]

      it "applies operators inside the current word in operator-pending mode", ->
        ensure 'd i w',
          text:     "12345  ABCDE"
          cursor:   [0, 6]
          register: '"': text: 'abcde'
          mode: 'normal'

      it "selects inside the current word in visual mode", ->
        ensure 'v i w',
          selectedScreenRange: [[0, 6], [0, 11]]

      it "works with multiple cursors", ->
        set addCursor: [0, 1]
        ensure 'v i w',
          selectedBufferRange: [
            [[0, 6], [0, 11]]
            [[0, 0], [0, 5]]
          ]

      describe "cursor is on next to NonWordCharacter", ->
        beforeEach ->
          set
            text: "abc(def)"
            cursor: [0, 4]

        it "change inside word", ->
          ensure 'c i w', text: "abc()", mode: "insert"

        it "delete inside word", ->
          ensure 'd i w', text: "abc()", mode: "normal"

      describe "cursor's next char is NonWordCharacter", ->
        beforeEach ->
          set
            text: "abc(def)"
            cursor: [0, 6]

        it "change inside word", ->
          ensure 'c i w', text: "abc()", mode: "insert"

        it "delete inside word", ->
          ensure 'd i w', text: "abc()", mode: "normal"

    describe "a-word", ->
      beforeEach ->
        set text: "12345 abcde ABCDE", cursor: [0, 9]

      it "select current-word and trailing white space", ->
        ensure 'd a w',
          text: "12345 ABCDE"
          cursor: [0, 6]
          register: '"': text: "abcde "

      it "select current-word and leading white space in case trailing white space wasn't there", ->
        set cursor: [0, 15]
        ensure 'd a w',
          text: "12345 abcde"
          cursor: [0, 10]
          register: '"': text: " ABCDE"

      it "selects from the start of the current word to the start of the next word in visual mode", ->
        ensure 'v a w', selectedScreenRange: [[0, 6], [0, 12]]

      it "doesn't span newlines", ->
        set text: "12345\nabcde ABCDE", cursor: [0, 3]
        ensure 'v a w', selectedBufferRange: [[0, 0], [0, 5]]

      it "doesn't span special characters", ->
        set text: "1(345\nabcde ABCDE", cursor: [0, 3]
        ensure 'v a w', selectedBufferRange: [[0, 2], [0, 5]]

  describe "WholeWord", ->
    describe "inner-whole-word", ->
      beforeEach ->
        set text: "12(45 ab'de ABCDE", cursor: [0, 9]

      it "applies operators inside the current whole word in operator-pending mode", ->
        ensure 'd i W', text: "12(45  ABCDE", cursor: [0, 6], register: '"': text: "ab'de"

      it "selects inside the current whole word in visual mode", ->
        ensure 'v i W', selectedScreenRange: [[0, 6], [0, 11]]
    describe "a-whole-word", ->
      beforeEach ->
        set text: "12(45 ab'de ABCDE", cursor: [0, 9]

      it "select whole-word and trailing white space", ->
        ensure 'd a W',
          text: "12(45 ABCDE"
          cursor: [0, 6]
          register: '"': text: "ab'de "
          mode: 'normal'

      it "select whole-word and leading white space in case trailing white space wasn't there", ->
        set cursor: [0, 15]
        ensure 'd a w',
          text: "12(45 ab'de"
          cursor: [0, 10]
          register: '"': text: " ABCDE"

      it "selects from the start of the current whole word to the start of the next whole word in visual mode", ->
        ensure 'v a W', selectedScreenRange: [[0, 6], [0, 12]]

      it "doesn't span newlines", ->
        set text: "12(45\nab'de ABCDE", cursor: [0, 4]
        ensure 'v a W', selectedBufferRange: [[0, 0], [0, 5]]

  describe "Subword", ->
    escape = -> keystroke('escape')
    beforeEach ->
      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode':
          'a q': 'vim-mode-plus:a-subword'
          'i q': 'vim-mode-plus:inner-subword'

    describe "inner-subword", ->
      it "select subword", ->
        set textC: "cam|elCase"; ensure "v i q", selectedText: "camel"; escape()
        set textC: "came|lCase"; ensure "v i q", selectedText: "camel"; escape()
        set textC: "camel|Case"; ensure "v i q", selectedText: "Case"; escape()
        set textC: "camelCas|e"; ensure "v i q", selectedText: "Case"; escape()

        set textC: "|_snake__case_"; ensure "v i q", selectedText: "_snake"; escape()
        set textC: "_snak|e__case_"; ensure "v i q", selectedText: "_snake"; escape()
        set textC: "_snake|__case_"; ensure "v i q", selectedText: "__case"; escape()
        set textC: "_snake_|_case_"; ensure "v i q", selectedText: "__case"; escape()
        set textC: "_snake__cas|e_"; ensure "v i q", selectedText: "__case"; escape()
        set textC: "_snake__case|_"; ensure "v i q", selectedText: "_"; escape()

    describe "a-subword", ->
      it "select subword and spaces", ->
        set textC: "camelCa|se  NextCamel"; ensure "v a q", selectedText: "Case  "; escape()
        set textC: "camelCase  Ne|xtCamel"; ensure "v a q", selectedText: "  Next"; escape()
        set textC: "snake_c|ase  next_snake"; ensure "v a q", selectedText: "_case  "; escape()
        set textC: "snake_case  ne|xt_snake"; ensure "v a q", selectedText: "  next"; escape()

  describe "AnyPair", ->
    {simpleText, complexText} = {}
    beforeEach ->
      simpleText = """
        .... "abc" ....
        .... 'abc' ....
        .... `abc` ....
        .... {abc} ....
        .... <abc> ....
        .... [abc] ....
        .... (abc) ....
        """
      complexText = """
        [4s
        --{3s
        ----"2s(1s-1e)2e"
        ---3e}-4e
        ]
        """
      set
        text: simpleText
        cursor: [0, 7]
    describe "inner-any-pair", ->
      it "applies operators any inner-pair and repeatable", ->
        ensure 'd i s',
          text: """
            .... "" ....
            .... 'abc' ....
            .... `abc` ....
            .... {abc} ....
            .... <abc> ....
            .... [abc] ....
            .... (abc) ....
            """
        ensure 'j . j . j . j . j . j . j .',
          text: """
            .... "" ....
            .... '' ....
            .... `` ....
            .... {} ....
            .... <> ....
            .... [] ....
            .... () ....
            """
      it "can expand selection", ->
        set text: complexText, cursor: [2, 8]
        keystroke 'v'
        ensure 'i s', selectedText: """1s-1e"""
        ensure 'i s', selectedText: """2s(1s-1e)2e"""
        ensure 'i s', selectedText: """3s\n----"2s(1s-1e)2e"\n---3e"""
        ensure 'i s', selectedText: """4s\n--{3s\n----"2s(1s-1e)2e"\n---3e}-4e"""
    describe "a-any-pair", ->
      it "applies operators any a-pair and repeatable", ->
        ensure 'd a s',
          text: """
            ....  ....
            .... 'abc' ....
            .... `abc` ....
            .... {abc} ....
            .... <abc> ....
            .... [abc] ....
            .... (abc) ....
            """
        ensure 'j . j . j . j . j . j . j .',
          text: """
            ....  ....
            ....  ....
            ....  ....
            ....  ....
            ....  ....
            ....  ....
            ....  ....
            """
      it "can expand selection", ->
        set text: complexText, cursor: [2, 8]
        keystroke 'v'
        ensure 'a s', selectedText: """(1s-1e)"""
        ensure 'a s', selectedText: """\"2s(1s-1e)2e\""""
        ensure 'a s', selectedText: """{3s\n----"2s(1s-1e)2e"\n---3e}"""
        ensure 'a s', selectedText: """[4s\n--{3s\n----"2s(1s-1e)2e"\n---3e}-4e\n]"""

  describe "AnyQuote", ->
    beforeEach ->
      set
        text: """
        --"abc" `def`  'efg'--
        """
        cursor: [0, 0]
    describe "inner-any-quote", ->
      it "applies operators any inner-pair and repeatable", ->
        ensure 'd i q', text: """--"" `def`  'efg'--"""
        ensure '.', text: """--"" ``  'efg'--"""
        ensure '.', text: """--"" ``  ''--"""
      it "can select next quote", ->
        keystroke 'v'
        ensure 'i q', selectedText: 'abc'
        ensure 'i q', selectedText: 'def'
        ensure 'i q', selectedText: 'efg'
    describe "a-any-quote", ->
      it "applies operators any a-quote and repeatable", ->
        ensure 'd a q', text: """-- `def`  'efg'--"""
        ensure '.'  , text: """--   'efg'--"""
        ensure '.'  , text: """--   --"""
      it "can select next quote", ->
        keystroke 'v'
        ensure 'a q', selectedText: '"abc"'
        ensure 'a q', selectedText: '`def`'
        ensure 'a q', selectedText: "'efg'"

  describe "DoubleQuote", ->
    describe "issue-635 new behavior of inner-double-quote", ->
      beforeEach ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'g r': 'vim-mode-plus:replace'

      describe "quote is un-balanced", ->
        it "case1", ->
          set                 textC_: '_|_"____"____"'
          ensure 'g r i " +', textC_: '__"|++++"____"'
        it "case2", ->
          set                 textC_: '__"__|__"____"'
          ensure 'g r i " +', textC_: '__"|++++"____"'
        it "case3", ->
          set                 textC_: '__"____"__|__"'
          ensure 'g r i " +', textC_: '__"____"|++++"'
        it "case4", ->
          set                 textC_: '__|"____"____"'
          ensure 'g r i " +', textC_: '__"|++++"____"'
        it "case5", ->
          set                 textC_: '__"____|"____"'
          ensure 'g r i " +', textC_: '__"|++++"____"'
        it "case6", ->
          set                 textC_: '__"____"____|"'
          ensure 'g r i " +', textC_: '__"____"|++++"'

      describe "quote is balanced", ->
        it "case1", ->
          set                 textC_: '_|_"===="____"==="'
          ensure 'g r i " +', textC_: '__"|++++"____"==="'
        it "case2", ->
          set                 textC_: '__"==|=="____"==="'
          ensure 'g r i " +', textC_: '__"|++++"____"==="'
        it "case3", ->
          set                 textC_: '__"===="__|__"==="'
          ensure 'g r i " +', textC_: '__"===="|++++"==="'
        it "case4", ->
          set                 textC_: '__"===="____"=|=="'
          ensure 'g r i " +', textC_: '__"===="____"|+++"'
        it "case5", ->
          set                 textC_: '__|"===="____"==="'
          ensure 'g r i " +', textC_: '__"|++++"____"==="'
        it "case6", ->
          set                 textC_: '__"====|"____"==="'
          ensure 'g r i " +', textC_: '__"|++++"____"==="'
        it "case7", ->
          set                 textC_: '__"===="____|"==="'
          ensure 'g r i " +', textC_: '__"===="____"|+++"'

    describe "inner-double-quote", ->
      beforeEach ->
        set
          text: '" something in here and in "here" " and over here'
          cursor: [0, 9]

      it "applies operators inside the current string in operator-pending mode", ->
        ensure 'd i "',
          text: '""here" " and over here'
          cursor: [0, 1]

      it "applies operators inside the current string in operator-pending mode", ->
        set cursor: [0, 29]
        ensure 'd i "',
          text: '" something in here and in "" " and over here'
          cursor: [0, 28]

      it "makes no change if past the last string on a line", ->
        set cursor: [0, 39]
        ensure 'd i "',
          text: '" something in here and in "here" " and over here'
          cursor: [0, 39]

      describe "cursor is on the pair char", ->
        check = getCheckFunctionFor('i "')
        text = '-"+"-'
        textFinal = '-""-'
        selectedText = '+'
        open = [0, 1]
        close = [0, 3]
        beforeEach ->
          set {text}
        it "case-1 normal", -> check open, 'd', text: textFinal, cursor: [0, 2]
        it "case-2 normal", -> check close, 'd', text: textFinal, cursor: [0, 2]
        it "case-3 visual", -> check open, 'v', {selectedText}
        it "case-4 visual", -> check close, 'v', {selectedText}
    describe "a-double-quote", ->
      originalText = '" something in here and in "here" "'
      beforeEach ->
        set text: originalText, cursor: [0, 9]

      it "applies operators around the current double quotes in operator-pending mode", ->
        ensure 'd a "',
          text: 'here" "'
          cursor: [0, 0]
          mode: 'normal'

      it "delete a-double-quote", ->
        set cursor: [0, 29]
        ensure 'd a "',
          text: '" something in here and in  "'
          cursor: [0, 27]
          mode: 'normal'
      describe "cursor is on the pair char", ->
        check = getCheckFunctionFor('a "')
        text = '-"+"-'
        textFinal = '--'
        selectedText = '"+"'
        open = [0, 1]
        close = [0, 3]
        beforeEach ->
          set {text}
        it "case-1 normal", -> check open, 'd', text: textFinal, cursor: [0, 1]
        it "case-2 normal", -> check close, 'd', text: textFinal, cursor: [0, 1]
        it "case-3 visual", -> check open, 'v', {selectedText}
        it "case-4 visual", -> check close, 'v', {selectedText}
  describe "SingleQuote", ->
    describe "inner-single-quote", ->
      beforeEach ->
        set
          text: "' something in here and in 'here' ' and over here"
          cursor: [0, 9]

      describe "don't treat literal backslash(double backslash) as escape char", ->
        beforeEach ->
          set
            text: "'some-key-here\\\\': 'here-is-the-val'"
        it "case-1", ->
          set cursor: [0, 2]
          ensure "d i '",
            text: "'': 'here-is-the-val'"
            cursor: [0, 1]

        it "case-2", ->
          set cursor: [0, 19]
          ensure "d i '",
            text: "'some-key-here\\\\': ''"
            cursor: [0, 20]

      describe "treat backslash(single backslash) as escape char", ->
        beforeEach ->
          set
            text: "'some-key-here\\'': 'here-is-the-val'"

        it "case-1", ->
          set cursor: [0, 2]
          ensure "d i '",
            text: "'': 'here-is-the-val'"
            cursor: [0, 1]
        it "case-2", ->
          set cursor: [0, 17]
          ensure "d i '",
            text: "'some-key-here\\'''here-is-the-val'"
            cursor: [0, 17]

      it "applies operators inside the current string in operator-pending mode", ->
        ensure "d i '",
          text: "''here' ' and over here"
          cursor: [0, 1]

      # [NOTE]
      # I don't like original behavior, this is counter intuitive.
      # Simply selecting area between quote is that normal user expects.
      # it "applies operators inside the next string in operator-pending mode (if not in a string)", ->
      # => Reverted to original behavior, but need careful consideration what is best.

      # it "[Changed behavior] applies operators inside area between quote", ->
      it "applies operators inside the next string in operator-pending mode (if not in a string)", ->
        set cursor: [0, 26]
        ensure "d i '",
          text: "''here' ' and over here"
          cursor: [0, 1]

      it "makes no change if past the last string on a line", ->
        set cursor: [0, 39]
        ensure "d i '",
          text: "' something in here and in 'here' ' and over here"
          cursor: [0, 39]
      describe "cursor is on the pair char", ->
        check = getCheckFunctionFor("i '")
        text = "-'+'-"
        textFinal = "-''-"
        selectedText = '+'
        open = [0, 1]
        close = [0, 3]
        beforeEach ->
          set {text}
        it "case-1 normal", -> check open, 'd', text: textFinal, cursor: [0, 2]
        it "case-2 normal", -> check close, 'd', text: textFinal, cursor: [0, 2]
        it "case-3 visual", -> check open, 'v', {selectedText}
        it "case-4 visual", -> check close, 'v', {selectedText}
    describe "a-single-quote", ->
      originalText = "' something in here and in 'here' '"
      beforeEach ->
        set text: originalText, cursor: [0, 9]

      it "applies operators around the current single quotes in operator-pending mode", ->
        ensure "d a '",
          text: "here' '"
          cursor: [0, 0]
          mode: 'normal'

      it "applies operators inside the next string in operator-pending mode (if not in a string)", ->
        set cursor: [0, 29]
        ensure "d a '",
          text: "' something in here and in  '"
          cursor: [0, 27]
          mode: 'normal'
      describe "cursor is on the pair char", ->
        check = getCheckFunctionFor("a '")
        text = "-'+'-"
        textFinal = "--"
        selectedText = "'+'"
        open = [0, 1]
        close = [0, 3]
        beforeEach ->
          set {text}
        it "case-1 normal", -> check open, 'd', text: textFinal, cursor: [0, 1]
        it "case-2 normal", -> check close, 'd', text: textFinal, cursor: [0, 1]
        it "case-3 visual", -> check open, 'v', {selectedText}
        it "case-4 visual", -> check close, 'v', {selectedText}
  describe "BackTick", ->
    originalText = "this is `sample` text."
    beforeEach ->
      set text: originalText, cursor: [0, 9]

    describe "inner-back-tick", ->
      it "applies operators inner-area", ->
        ensure "d i `", text: "this is `` text.", cursor: [0, 9]

      it "do nothing when pair range is not under cursor", ->
        set cursor: [0, 16]
        ensure "d i `", text: originalText, cursor: [0, 16]
      describe "cursor is on the pair char", ->
        check = getCheckFunctionFor('i `')
        text = '-`+`-'
        textFinal = '-``-'
        selectedText = '+'
        open = [0, 1]
        close = [0, 3]
        beforeEach ->
          set {text}
        it "case-1 normal", -> check open, 'd', text: textFinal, cursor: [0, 2]
        it "case-2 normal", -> check close, 'd', text: textFinal, cursor: [0, 2]
        it "case-3 visual", -> check open, 'v', {selectedText}
        it "case-4 visual", -> check close, 'v', {selectedText}
    describe "a-back-tick", ->
      it "applies operators inner-area", ->
        ensure "d a `", text: "this is  text.", cursor: [0, 8]

      it "do nothing when pair range is not under cursor", ->
        set cursor: [0, 16]
        ensure "d a `", text: originalText, cursor: [0, 16]
      describe "cursor is on the pair char", ->
        check = getCheckFunctionFor("a `")
        text = "-`+`-"
        textFinal = "--"
        selectedText = "`+`"
        open = [0, 1]
        close = [0, 3]
        beforeEach ->
          set {text}
        it "case-1 normal", -> check open, 'd', text: textFinal, cursor: [0, 1]
        it "case-2 normal", -> check close, 'd', text: textFinal, cursor: [0, 1]
        it "case-3 visual", -> check open, 'v', {selectedText}
        it "case-4 visual", -> check close, 'v', {selectedText}
  describe "CurlyBracket", ->
    describe "scope awareness of bracket", ->
      it "[search from outside of double-quote] skips bracket in within-line-balanced-double-quotes", ->
        set
          textC: """
          { | "hello {" }
          """
        ensure "v a {",
          selectedText: """
          {  "hello {" }
          """

      it "Not ignore bracket in within-line-not-balanced-double-quotes", ->
        set
          textC: """
          {  "hello {" | '"' }
          """
        ensure "v a {",
          selectedText: """
          {"  '"' }
          """
      it "[search from inside of double-quote] skips bracket in within-line-balanced-double-quotes", ->
        set
          textC: """
          {  "h|ello {" }
          """
        ensure "v a {",
          selectedText: """
          {  "hello {" }
          """

      beforeEach ->
        set
          textC_: """

          """
    describe "inner-curly-bracket", ->
      beforeEach ->
        set
          text: "{ something in here and in {here} }"
          cursor: [0, 9]

      it "applies operators to inner-area in operator-pending mode", ->
        ensure 'd i {',
          text: "{}"
          cursor: [0, 1]

      it "applies operators to inner-area in operator-pending mode (second test)", ->
        set
          cursor: [0, 29]
        ensure 'd i {',
          text: "{ something in here and in {} }"
          cursor: [0, 28]

      describe "cursor is on the pair char", ->
        check = getCheckFunctionFor('i {')
        text = '-{+}-'
        textFinal = '-{}-'
        selectedText = '+'
        open = [0, 1]
        close = [0, 3]
        beforeEach ->
          set {text}
        it "case-1 normal", -> check open, 'd', text: textFinal, cursor: [0, 2]
        it "case-2 normal", -> check close, 'd', text: textFinal, cursor: [0, 2]
        it "case-3 visual", -> check open, 'v', {selectedText}
        it "case-4 visual", -> check close, 'v', {selectedText}

      describe "change mode to characterwise", ->
        # FIXME last "\n" should not be selected
        textSelected = """
        __1,
        __2,
        __3
        """.replace(/_/g, ' ')


        beforeEach ->
          set
            textC: """
            {
              |1,
              2,
              3
            }
            """
          ensure mode: 'normal'

        it "from vC, final-mode is 'characterwise'", ->
          ensure 'v',
            selectedText: ['1']
            mode: ['visual', 'characterwise']
          ensure 'i B',
            selectedText: textSelected
            mode: ['visual', 'characterwise']

        it "from vL, final-mode is 'characterwise'", ->
          ensure 'V',
            selectedText: ["  1,\n"]
            mode: ['visual', 'linewise']
          ensure 'i B',
            selectedText: textSelected
            mode: ['visual', 'characterwise']

        it "from vB, final-mode is 'characterwise'", ->
          ensure 'ctrl-v',
            selectedText: ["1"]
            mode: ['visual', 'blockwise']
          ensure 'i B',
            selectedText: textSelected
            mode: ['visual', 'characterwise']

        describe "as operator target", ->
          it "change inner-pair", ->
            ensure "c i B",
              textC: """
              {
              |
              }
              """
              mode: 'insert'
          it "delete inner-pair", ->
            ensure "d i B",
              textC: """
              {
              |}
              """
              mode: 'normal'

    describe "a-curly-bracket", ->
      beforeEach ->
        set
          text: "{ something in here and in {here} }"
          cursor: [0, 9]

      it "applies operators to a-area in operator-pending mode", ->
        ensure 'd a {',
          text: ''
          cursor: [0, 0]
          mode: 'normal'

      it "applies operators to a-area in operator-pending mode (second test)", ->
        set cursor: [0, 29]
        ensure 'd a {',
          text: "{ something in here and in  }"
          cursor: [0, 27]
          mode: 'normal'
      describe "cursor is on the pair char", ->
        check = getCheckFunctionFor("a {")
        text = "-{+}-"
        textFinal = "--"
        selectedText = "{+}"
        open = [0, 1]
        close = [0, 3]
        beforeEach ->
          set {text}
        it "case-1 normal", -> check open, 'd', text: textFinal, cursor: [0, 1]
        it "case-2 normal", -> check close, 'd', text: textFinal, cursor: [0, 1]
        it "case-3 visual", -> check open, 'v', {selectedText}
        it "case-4 visual", -> check close, 'v', {selectedText}

      describe "change mode to characterwise", ->
        textSelected = """
          {
            1,
            2,
            3
          }
          """
        beforeEach ->
          set
            textC: """
            {
              |1,
              2,
              3
            }

            hello
            """
          ensure mode: 'normal'

        it "from vC, final-mode is 'characterwise'", ->
          ensure 'v',
            selectedText: ['1']
            mode: ['visual', 'characterwise']
          ensure 'a B',
            selectedText: textSelected
            mode: ['visual', 'characterwise']

        it "from vL, final-mode is 'characterwise'", ->
          ensure 'V',
            selectedText: ["  1,\n"]
            mode: ['visual', 'linewise']
          ensure 'a B',
            selectedText: textSelected
            mode: ['visual', 'characterwise']

        it "from vB, final-mode is 'characterwise'", ->
          ensure 'ctrl-v',
            selectedText: ["1"]
            mode: ['visual', 'blockwise']
          ensure 'a B',
            selectedText: textSelected
            mode: ['visual', 'characterwise']

        describe "as operator target", ->
          it "change inner-pair", ->
            ensure "c a B",
              textC: """
              |

              hello
              """
              mode: 'insert'
          it "delete inner-pair", ->
            ensure "d a B",
              textC: """
              |

              hello
              """
              mode: 'normal'


  describe "AngleBracket", ->
    describe "inner-angle-bracket", ->
      beforeEach ->
        set
          text: "< something in here and in <here> >"
          cursor: [0, 9]

      it "applies operators inside the current word in operator-pending mode", ->
        ensure 'd i <',
          text: "<>"
          cursor: [0, 1]

      it "applies operators inside the current word in operator-pending mode (second test)", ->
        set cursor: [0, 29]
        ensure 'd i <',
          text: "< something in here and in <> >"
          cursor: [0, 28]
      describe "cursor is on the pair char", ->
        check = getCheckFunctionFor('i <')
        text = '-<+>-'
        textFinal = '-<>-'
        selectedText = '+'
        open = [0, 1]
        close = [0, 3]
        beforeEach ->
          set {text}
        it "case-1 normal", -> check open, 'd', text: textFinal, cursor: [0, 2]
        it "case-2 normal", -> check close, 'd', text: textFinal, cursor: [0, 2]
        it "case-3 visual", -> check open, 'v', {selectedText}
        it "case-4 visual", -> check close, 'v', {selectedText}
    describe "a-angle-bracket", ->
      beforeEach ->
        set
          text: "< something in here and in <here> >"
          cursor: [0, 9]

      it "applies operators around the current angle brackets in operator-pending mode", ->
        ensure 'd a <',
          text: ''
          cursor: [0, 0]
          mode: 'normal'

      it "applies operators around the current angle brackets in operator-pending mode (second test)", ->
        set cursor: [0, 29]
        ensure 'd a <',
          text: "< something in here and in  >"
          cursor: [0, 27]
          mode: 'normal'
      describe "cursor is on the pair char", ->
        check = getCheckFunctionFor("a <")
        text = "-<+>-"
        textFinal = "--"
        selectedText = "<+>"
        open = [0, 1]
        close = [0, 3]
        beforeEach ->
          set {text}
        it "case-1 normal", -> check open, 'd', text: textFinal, cursor: [0, 1]
        it "case-2 normal", -> check close, 'd', text: textFinal, cursor: [0, 1]
        it "case-3 visual", -> check open, 'v', {selectedText}
        it "case-4 visual", -> check close, 'v', {selectedText}

  describe "AllowForwarding family", ->
    beforeEach ->
      atom.keymaps.add "test",
        'atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode':
          'i }':  'vim-mode-plus:inner-curly-bracket-allow-forwarding'
          'i >':  'vim-mode-plus:inner-angle-bracket-allow-forwarding'
          'i ]':  'vim-mode-plus:inner-square-bracket-allow-forwarding'
          'i )':  'vim-mode-plus:inner-parenthesis-allow-forwarding'

          'a }':  'vim-mode-plus:a-curly-bracket-allow-forwarding'
          'a >':  'vim-mode-plus:a-angle-bracket-allow-forwarding'
          'a ]':  'vim-mode-plus:a-square-bracket-allow-forwarding'
          'a )':  'vim-mode-plus:a-parenthesis-allow-forwarding'

      set
        text: """
        __{000}__
        __<111>__
        __[222]__
        __(333)__
        """
    describe "inner", ->
      it "select forwarding range", ->
        set cursor: [0, 0]; ensure 'escape v i }', selectedText: "000"
        set cursor: [1, 0]; ensure 'escape v i >', selectedText: "111"
        set cursor: [2, 0]; ensure 'escape v i ]', selectedText: "222"
        set cursor: [3, 0]; ensure 'escape v i )', selectedText: "333"
    describe "a", ->
      it "select forwarding range", ->
        set cursor: [0, 0]; ensure 'escape v a }', selectedText: "{000}"
        set cursor: [1, 0]; ensure 'escape v a >', selectedText: "<111>"
        set cursor: [2, 0]; ensure 'escape v a ]', selectedText: "[222]"
        set cursor: [3, 0]; ensure 'escape v a )', selectedText: "(333)"
    describe "multi line text", ->
      [textOneInner, textOneA] = []
      beforeEach ->
        set
          text: """
          000
          000{11
          111{22}
          111
          111}
          """
        textOneInner = """
          11
          111{22}
          111
          111
          """
        textOneA = """
          {11
          111{22}
          111
          111}
          """
      describe "forwarding inner", ->
        it "select forwarding range", ->
          set cursor: [1, 0]; ensure "v i }", selectedText: textOneInner
        it "select forwarding range", ->
          set cursor: [2, 0]; ensure "v i }", selectedText: "22"
        it "[case-1] no forwarding open pair, fail to find", ->
          set cursor: [0, 0]; ensure "v i }", selectedText: '0', cursor: [0, 1]
        it "[case-2] no forwarding open pair, select enclosed", ->
          set cursor: [1, 4]; ensure "v i }", selectedText: textOneInner
        it "[case-3] no forwarding open pair, select enclosed", ->
          set cursor: [3, 0]; ensure "v i }", selectedText: textOneInner
        it "[case-3] no forwarding open pair, select enclosed", ->
          set cursor: [4, 0]; ensure "v i }", selectedText: textOneInner
      describe "forwarding a", ->
        it "select forwarding range", ->
          set cursor: [1, 0]; ensure "v a }", selectedText: textOneA
        it "select forwarding range", ->
          set cursor: [2, 0]; ensure "v a }", selectedText: "{22}"
        it "[case-1] no forwarding open pair, fail to find", ->
          set cursor: [0, 0]; ensure "v a }", selectedText: '0', cursor: [0, 1]
        it "[case-2] no forwarding open pair, select enclosed", ->
          set cursor: [1, 4]; ensure "v a }", selectedText: textOneA
        it "[case-3] no forwarding open pair, select enclosed", ->
          set cursor: [3, 0]; ensure "v a }", selectedText: textOneA
        it "[case-3] no forwarding open pair, select enclosed", ->
          set cursor: [4, 0]; ensure "v a }", selectedText: textOneA

  describe "AnyPairAllowForwarding", ->
    beforeEach ->
      atom.keymaps.add "text",
        'atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode':
          ";": 'vim-mode-plus:inner-any-pair-allow-forwarding'
          ":": 'vim-mode-plus:a-any-pair-allow-forwarding'

      set text: """
        00
        00[11
        11"222"11{333}11(
        444()444
        )
        111]00{555}
        """
    describe "inner", ->
      it "select forwarding range within enclosed range(if exists)", ->
        set cursor: [2, 0]
        keystroke 'v'
        ensure ';', selectedText: "222"
        ensure ';', selectedText: "333"
        ensure ';', selectedText: "444()444"
    describe "a", ->
      it "select forwarding range within enclosed range(if exists)", ->
        set cursor: [2, 0]
        keystroke 'v'
        ensure ':', selectedText: '"222"'
        ensure ':', selectedText: "{333}"
        ensure ':', selectedText: "(\n444()444\n)"
        ensure ':', selectedText: """
        [11
        11"222"11{333}11(
        444()444
        )
        111]
        """

  describe "Tag", ->
    [ensureSelectedText] = []
    ensureSelectedText = (start, keystroke, selectedText) ->
      set cursor: start
      ensure keystroke, {selectedText}

    describe "inner-tag", ->
      describe "precisely select inner", ->
        check = getCheckFunctionFor('i t')
        text = """
          <abc>
            <title>TITLE</title>
          </abc>
          """
        selectedText = "TITLE"
        innerABC = "\n  <title>TITLE</title>\n"
        textAfterDeleted = """
          <abc>
            <title></title>
          </abc>
          """

        beforeEach ->
          set {text}

        # Select
        it "[1] forwarding", -> check [1, 0], 'v', {selectedText}
        it "[2] openTag leftmost", -> check [1, 2], 'v', {selectedText}
        it "[3] openTag rightmost", -> check [1, 8], 'v', {selectedText}
        it "[4] Inner text", -> check [1, 10], 'v', {selectedText}
        it "[5] closeTag leftmost", -> check [1, 14], 'v', {selectedText}
        it "[6] closeTag rightmost", -> check [1, 21], 'v', {selectedText}
        it "[7] right of closeTag", -> check [2, 0], 'v', {selectedText: innerABC}

        # Delete
        it "[8] forwarding", -> check [1, 0], 'd', {text: textAfterDeleted}
        it "[9] openTag leftmost", -> check [1, 2], 'd', {text: textAfterDeleted}
        it "[10] openTag rightmost", -> check [1, 8], 'd', {text: textAfterDeleted}
        it "[11] Inner text", -> check [1, 10], 'd', {text: textAfterDeleted}
        it "[12] closeTag leftmost", -> check [1, 14], 'd', {text: textAfterDeleted}
        it "[13] closeTag rightmost", -> check [1, 21], 'd', {text: textAfterDeleted}
        it "[14] right of closeTag", -> check [2, 0], 'd', {text: "<abc></abc>"}

      describe "expansion and deletion", ->
        beforeEach ->
          # [NOTE] Intentionally omit `!` prefix of DOCTYPE since it represent last cursor in textC.
          htmlLikeText = """
          <DOCTYPE html>
          <html lang="en">
          <head>
          __<meta charset="UTF-8" />
          __<title>Document</title>
          </head>
          <body>
          __<div>
          ____<div>
          |______<div>
          ________<p><a>
          ______</div>
          ____</div>
          __</div>
          </body>
          </html>\n
          """
          set textC_: htmlLikeText

        it "can expand selection when repeated", ->
          ensure 'v i t', selectedText_: """
            \n________<p><a>
            ______
            """
          ensure 'i t', selectedText_: """
            \n______<div>
            ________<p><a>
            ______</div>
            ____
            """
          ensure 'i t', selectedText_: """
            \n____<div>
            ______<div>
            ________<p><a>
            ______</div>
            ____</div>
            __
            """
          ensure 'i t', selectedText_: """
            \n__<div>
            ____<div>
            ______<div>
            ________<p><a>
            ______</div>
            ____</div>
            __</div>\n
            """
          ensure 'i t', selectedText_: """
            \n<head>
            __<meta charset="UTF-8" />
            __<title>Document</title>
            </head>
            <body>
            __<div>
            ____<div>
            ______<div>
            ________<p><a>
            ______</div>
            ____</div>
            __</div>
            </body>\n
            """
        it 'delete inner-tag and repatable', ->
          set cursor: [9, 0]
          ensure "d i t", text_: """
            <DOCTYPE html>
            <html lang="en">
            <head>
            __<meta charset="UTF-8" />
            __<title>Document</title>
            </head>
            <body>
            __<div>
            ____<div>
            ______<div></div>
            ____</div>
            __</div>
            </body>
            </html>\n
            """
          ensure "3 .", text_: """
            <DOCTYPE html>
            <html lang="en">
            <head>
            __<meta charset="UTF-8" />
            __<title>Document</title>
            </head>
            <body></body>
            </html>\n
            """
          ensure ".", text_: """
            <DOCTYPE html>
            <html lang="en"></html>\n
            """

      describe "tag's IN-tag/Off-tag recognition", ->
        describe "When tagStart's row contains NO NON-whitespaece till tagStart", ->
          it "[multi-line] select forwarding tag", ->
            set textC: """
              <span>
                |  <span>inner</span>
              </span>
              """
            ensure "d i t", text: """
              <span>
                  <span></span>
              </span>
              """

        describe "When tagStart's row contains SOME NON-whitespaece till tagStart", ->
          it "[multi-line] select enclosing tag", ->
            set textC: """
            <span>
            hello | <span>inner</span>
            </span>
            """
            ensure "d i t", text: "<span></span>"

          it "[one-line-1] select enclosing tag", ->
            set textC: """
              <span> | <span>inner</span></span>
              """

            ensure "d i t", text: "<span></span>"

          it "[one-line-2] select enclosing tag", ->
            set textC: """
              <span>h|ello<span>inner</span></span>
              """

            ensure "d i t", text: "<span></span>"

    describe "a-tag", ->
      describe "precisely select a", ->
        check = getCheckFunctionFor('a t')
        text = """
          <abc>
            <title>TITLE</title>
          </abc>
          """
        selectedText = "<title>TITLE</title>"
        aABC = text
        textAfterDeleted = """
          <abc>
          __
          </abc>
          """.replace(/_/g, ' ')

        beforeEach ->
          set {text}

        # Select
        it "[1] forwarding", -> check [1, 0], 'v', {selectedText}
        it "[2] openTag leftmost", -> check [1, 2], 'v', {selectedText}
        it "[3] openTag rightmost", -> check [1, 8], 'v', {selectedText}
        it "[4] Inner text", -> check [1, 10], 'v', {selectedText}
        it "[5] closeTag leftmost", -> check [1, 14], 'v', {selectedText}
        it "[6] closeTag rightmost", -> check [1, 21], 'v', {selectedText}
        it "[7] right of closeTag", -> check [2, 0], 'v', {selectedText: aABC}

        # Delete
        it "[8] forwarding", -> check [1, 0], 'd', {text: textAfterDeleted}
        it "[9] openTag leftmost", -> check [1, 2], 'd', {text: textAfterDeleted}
        it "[10] openTag rightmost", -> check [1, 8], 'd', {text: textAfterDeleted}
        it "[11] Inner text", -> check [1, 10], 'd', {text: textAfterDeleted}
        it "[12] closeTag leftmost", -> check [1, 14], 'd', {text: textAfterDeleted}
        it "[13] closeTag rightmost", -> check [1, 21], 'd', {text: textAfterDeleted}
        it "[14] right of closeTag", -> check [2, 0], 'd', {text: ""}

  describe "SquareBracket", ->
    describe "inner-square-bracket", ->
      beforeEach ->
        set
          text: "[ something in here and in [here] ]"
          cursor: [0, 9]

      it "applies operators inside the current word in operator-pending mode", ->
        ensure 'd i [',
          text: "[]"
          cursor: [0, 1]

      it "applies operators inside the current word in operator-pending mode (second test)", ->
        set
          cursor: [0, 29]
        ensure 'd i [',
          text: "[ something in here and in [] ]"
          cursor: [0, 28]
    describe "a-square-bracket", ->
      beforeEach ->
        set
          text: "[ something in here and in [here] ]"
          cursor: [0, 9]

      it "applies operators around the current square brackets in operator-pending mode", ->
        ensure 'd a [',
          text: ''
          cursor: [0, 0]
          mode: 'normal'

      it "applies operators around the current square brackets in operator-pending mode (second test)", ->
        set cursor: [0, 29]
        ensure 'd a [',
          text: "[ something in here and in  ]"
          cursor: [0, 27]
          mode: 'normal'
      describe "cursor is on the pair char", ->
        check = getCheckFunctionFor('i [')
        text = '-[+]-'
        textFinal = '-[]-'
        selectedText = '+'
        open = [0, 1]
        close = [0, 3]
        beforeEach ->
          set {text}
        it "case-1 normal", -> check open, 'd', text: textFinal, cursor: [0, 2]
        it "case-2 normal", -> check close, 'd', text: textFinal, cursor: [0, 2]
        it "case-3 visual", -> check open, 'v', {selectedText}
        it "case-4 visual", -> check close, 'v', {selectedText}
      describe "cursor is on the pair char", ->
        check = getCheckFunctionFor('a [')
        text = '-[+]-'
        textFinal = '--'
        selectedText = '[+]'
        open = [0, 1]
        close = [0, 3]
        beforeEach ->
          set {text}
        it "case-1 normal", -> check open, 'd', text: textFinal, cursor: [0, 1]
        it "case-2 normal", -> check close, 'd', text: textFinal, cursor: [0, 1]
        it "case-3 visual", -> check open, 'v', {selectedText}
        it "case-4 visual", -> check close, 'v', {selectedText}
  describe "Parenthesis", ->
    describe "inner-parenthesis", ->
      beforeEach ->
        set
          text: "( something in here and in (here) )"
          cursor: [0, 9]

      it "applies operators inside the current word in operator-pending mode", ->
        ensure 'd i (',
          text: "()"
          cursor: [0, 1]

      it "applies operators inside the current word in operator-pending mode (second test)", ->
        set cursor: [0, 29]
        ensure 'd i (',
          text: "( something in here and in () )"
          cursor: [0, 28]

      it "select inner () by skipping nesting pair", ->
        set
          text: 'expect(editor.getScrollTop())'
          cursor: [0, 7]
        ensure 'v i (', selectedText: 'editor.getScrollTop()'

      it "skip escaped pair case-1", ->
        set text: 'expect(editor.g\\(etScrollTp())', cursor: [0, 20]
        ensure 'v i (', selectedText: 'editor.g\\(etScrollTp()'

      it "dont skip literal backslash", ->
        set text: 'expect(editor.g\\\\(etScrollTp())', cursor: [0, 20]
        ensure 'v i (', selectedText: 'etScrollTp()'

      it "skip escaped pair case-2", ->
        set text: 'expect(editor.getSc\\)rollTp())', cursor: [0, 7]
        ensure 'v i (', selectedText: 'editor.getSc\\)rollTp()'

      it "skip escaped pair case-3", ->
        set text: 'expect(editor.ge\\(tSc\\)rollTp())', cursor: [0, 7]
        ensure 'v i (', selectedText: 'editor.ge\\(tSc\\)rollTp()'

      it "works with multiple cursors", ->
        set
          text: "( a b ) cde ( f g h ) ijk"
          cursor: [[0, 2], [0, 18]]
        ensure 'v i (',
          selectedBufferRange: [
            [[0, 1],  [0, 6]]
            [[0, 13], [0, 20]]
          ]
      describe "cursor is on the pair char", ->
        check = getCheckFunctionFor('i (')
        text = '-(+)-'
        textFinal = '-()-'
        selectedText = '+'
        open = [0, 1]
        close = [0, 3]
        beforeEach ->
          set {text}
        it "case-1 normal", -> check open, 'd', text: textFinal, cursor: [0, 2]
        it "case-2 normal", -> check close, 'd', text: textFinal, cursor: [0, 2]
        it "case-3 visual", -> check open, 'v', {selectedText}
        it "case-4 visual", -> check close, 'v', {selectedText}

    describe "a-parenthesis", ->
      beforeEach ->
        set
          text: "( something in here and in (here) )"
          cursor: [0, 9]

      it "applies operators around the current parentheses in operator-pending mode", ->
        ensure 'd a (',
          text: ''
          cursor: [0, 0]
          mode: 'normal'

      it "applies operators around the current parentheses in operator-pending mode (second test)", ->
        set cursor: [0, 29]
        ensure 'd a (',
          text: "( something in here and in  )"
          cursor: [0, 27]
      describe "cursor is on the pair char", ->
        check = getCheckFunctionFor('a (')
        text = '-(+)-'
        textFinal = '--'
        selectedText = '(+)'
        open = [0, 1]
        close = [0, 3]
        beforeEach ->
          set {text}
        it "case-1 normal", -> check open, 'd', text: textFinal, cursor: [0, 1]
        it "case-2 normal", -> check close, 'd', text: textFinal, cursor: [0, 1]
        it "case-3 visual", -> check open, 'v', {selectedText}
        it "case-4 visual", -> check close, 'v', {selectedText}

  describe "Paragraph", ->
    text = null
    ensureParagraph = (keystroke, options) ->
      unless options.setCursor
        throw new Errow("no setCursor provided")
      set cursor: options.setCursor
      delete options.setCursor
      ensure(keystroke, options)
      ensure('escape', mode: 'normal')

    beforeEach ->
      text = new TextData """

        1: P-1

        3: P-2
        4: P-2


        7: P-3
        8: P-3
        9: P-3


        """
      set
        cursor: [1, 0]
        text: text.getRaw()

    describe "inner-paragraph", ->
      it "select consequtive blank rows", ->
        ensureParagraph 'v i p', setCursor: [0, 0], selectedText: text.getLines([0])
        ensureParagraph 'v i p', setCursor: [2, 0], selectedText: text.getLines([2])
        ensureParagraph 'v i p', setCursor: [5, 0], selectedText: text.getLines([5..6])
      it "select consequtive non-blank rows", ->
        ensureParagraph 'v i p', setCursor: [1, 0], selectedText: text.getLines([1])
        ensureParagraph 'v i p', setCursor: [3, 0], selectedText: text.getLines([3..4])
        ensureParagraph 'v i p', setCursor: [7, 0], selectedText: text.getLines([7..9])
      it "operate on inner paragraph", ->
        ensureParagraph 'y i p', setCursor: [7, 0], register: '"': text: text.getLines([7, 8, 9])

    describe "a-paragraph", ->
      it "select two paragraph as one operation", ->
        ensureParagraph 'v a p', setCursor: [0, 0], selectedText: text.getLines([0, 1])
        ensureParagraph 'v a p', setCursor: [2, 0], selectedText: text.getLines([2..4])
        ensureParagraph 'v a p', setCursor: [5, 0], selectedText: text.getLines([5..9])
      it "select two paragraph as one operation", ->
        ensureParagraph 'v a p', setCursor: [1, 0], selectedText: text.getLines([1..2])
        ensureParagraph 'v a p', setCursor: [3, 0], selectedText: text.getLines([3..6])
        ensureParagraph 'v a p', setCursor: [7, 0], selectedText: text.getLines([7..10])
      it "operate on a paragraph", ->
        ensureParagraph 'y a p', setCursor: [3, 0], register: '"': text: text.getLines([3..6])

  describe 'Comment', ->
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-coffee-script')
      runs ->
        set
          grammar: 'source.coffee'
          text: """
          ###
          multiline comment
          ###

          # One line comment

          # Comment
          # border
          class QuickSort
          """
    afterEach ->
      atom.packages.deactivatePackage('language-coffee-script')

    describe 'inner-comment', ->
      it 'select inner comment block', ->
        set cursor: [0, 0]
        ensure 'v i /',
          selectedText: '###\nmultiline comment\n###\n'
          selectedBufferRange: [[0, 0], [3, 0]]

      it 'select one line comment', ->
        set cursor: [4, 0]
        ensure 'v i /',
          selectedText: '# One line comment\n'
          selectedBufferRange: [[4, 0], [5, 0]]

      it 'not select non-comment line', ->
        set cursor: [6, 0]
        ensure 'v i /',
          selectedText: '# Comment\n# border\n'
          selectedBufferRange: [[6, 0], [8, 0]]

  describe 'Indentation', ->
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-coffee-script')
      getVimState 'sample.coffee', (vimState, vim) ->
        {editor, editorElement} = vimState
        {set, ensure, keystroke} = vim
    afterEach ->
      atom.packages.deactivatePackage('language-coffee-script')

    describe 'inner-indentation', ->
      it 'select lines with deeper indent-level', ->
        set cursor: [12, 0]
        ensure 'v i i',
          selectedBufferRange: [[12, 0], [15, 0]]
    describe 'a-indentation', ->
      it 'wont stop on blank line when selecting indent', ->
        set cursor: [12, 0]
        ensure 'v a i',
          selectedBufferRange: [[10, 0], [27, 0]]

  describe 'Fold', ->
    rangeForRows = (startRow, endRow) ->
      [[startRow, 0], [endRow + 1, 0]]

    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-coffee-script')
      getVimState 'sample.coffee', (vimState, vim) ->
        {editor, editorElement} = vimState
        {set, ensure, keystroke} = vim
    afterEach ->
      atom.packages.deactivatePackage('language-coffee-script')

    describe 'inner-fold', ->
      it "select inner range of fold", ->
        set cursor: [13, 0]
        ensure 'v i z', selectedBufferRange: rangeForRows(10, 25)

      it "select inner range of fold", ->
        set cursor: [19, 0]
        ensure 'v i z', selectedBufferRange: rangeForRows(19, 23)

      it "can expand selection", ->
        set cursor: [23, 0]
        keystroke 'v'
        ensure 'i z', selectedBufferRange: rangeForRows(23, 23)
        ensure 'i z', selectedBufferRange: rangeForRows(19, 23)
        ensure 'i z', selectedBufferRange: rangeForRows(10, 25)
        ensure 'i z', selectedBufferRange: rangeForRows(9, 28)

      describe "when startRow of selection is on fold startRow", ->
        it 'select inner fold', ->
          set cursor: [20, 7]
          ensure 'v i z', selectedBufferRange: rangeForRows(21, 21)

      describe "when containing fold are not found", ->
        it "do nothing", ->
          set cursor: [20, 0]
          ensure 'V G', selectedBufferRange: rangeForRows(20, 30)
          ensure 'i z', selectedBufferRange: rangeForRows(20, 30)

      describe "when indent level of fold startRow and endRow is same", ->
        beforeEach ->
          waitsForPromise ->
            atom.packages.activatePackage('language-javascript')
          getVimState 'sample.js', (state, vimEditor) ->
            {editor, editorElement} = state
            {set, ensure, keystroke} = vimEditor
        afterEach ->
          atom.packages.deactivatePackage('language-javascript')

        it "doesn't select fold endRow", ->
          set cursor: [5, 0]
          ensure 'v i z', selectedBufferRange: rangeForRows(5, 6)
          ensure 'a z', selectedBufferRange: rangeForRows(4, 7)

    describe 'a-fold', ->
      it 'select fold row range', ->
        set cursor: [13, 0]
        ensure 'v a z', selectedBufferRange: rangeForRows(9, 25)

      it 'select fold row range', ->
        set cursor: [19, 0]
        ensure 'v a z', selectedBufferRange: rangeForRows(18, 23)

      it 'can expand selection', ->
        set cursor: [23, 0]
        keystroke 'v'
        ensure 'a z', selectedBufferRange: rangeForRows(22, 23)
        ensure 'a z', selectedBufferRange: rangeForRows(18, 23)
        ensure 'a z', selectedBufferRange: rangeForRows(9, 25)
        ensure 'a z', selectedBufferRange: rangeForRows(8, 28)

      describe "when startRow of selection is on fold startRow", ->
        it 'select fold starting from current row', ->
          set cursor: [20, 7]
          ensure 'v a z', selectedBufferRange: rangeForRows(20, 21)

      describe "when containing fold are not found", ->
        it "do nothing", ->
          set cursor: [20, 0]
          ensure 'V G', selectedBufferRange: rangeForRows(20, 30)
          ensure 'a z', selectedBufferRange: rangeForRows(20, 30)

  # Although following test picks specific language, other langauages are alsoe supported.
  describe 'Function', ->
    describe 'coffee', ->
      pack = 'language-coffee-script'
      scope = 'source.coffee'
      beforeEach ->
        waitsForPromise ->
          atom.packages.activatePackage(pack)

        set
          text: """
            # Commment

            hello = ->
              a = 1
              b = 2
              c = 3

            # Commment
            """
          cursor: [3, 0]

        runs ->
          grammar = atom.grammars.grammarForScopeName(scope)
          editor.setGrammar(grammar)
      afterEach ->
        atom.packages.deactivatePackage(pack)

      describe 'inner-function for coffee', ->
        it 'select except start row', ->
          ensure 'v i f', selectedBufferRange: [[3, 0], [6, 0]]

      describe 'a-function for coffee', ->
        it 'select function', ->
          ensure 'v a f', selectedBufferRange: [[2, 0], [6, 0]]

    describe 'ruby', ->
      pack = 'language-ruby'
      scope = 'source.ruby'
      beforeEach ->
        waitsForPromise ->
          atom.packages.activatePackage(pack)
        set
          text: """
            # Commment

            def hello
              a = 1
              b = 2
              c = 3
            end

            # Commment
            """
          cursor: [3, 0]
        runs ->
          grammar = atom.grammars.grammarForScopeName(scope)
          editor.setGrammar(grammar)
      afterEach ->
        atom.packages.deactivatePackage(pack)

      describe 'inner-function for ruby', ->
        it 'select except start row', ->
          ensure 'v i f', selectedBufferRange: [[3, 0], [6, 0]]
      describe 'a-function for ruby', ->
        it 'select function', ->
          ensure 'v a f', selectedBufferRange: [[2, 0], [7, 0]]

    describe 'go', ->
      pack = 'language-go'
      scope = 'source.go'
      beforeEach ->
        waitsForPromise ->
          atom.packages.activatePackage(pack)
        set
          text: """
            // Commment

            func main() {
              a := 1
              b := 2
              c := 3
            }

            // Commment
            """
          cursor: [3, 0]
        runs ->
          grammar = atom.grammars.grammarForScopeName(scope)
          editor.setGrammar(grammar)
      afterEach ->
        atom.packages.deactivatePackage(pack)

      describe 'inner-function for go', ->
        it 'select except start row', ->
          ensure 'v i f', selectedBufferRange: [[3, 0], [6, 0]]

      describe 'a-function for go', ->
        it 'select function', ->
          ensure 'v a f', selectedBufferRange: [[2, 0], [7, 0]]

  describe 'CurrentLine', ->
    beforeEach ->
      set
        text: """
          This is
            multi line
          text
          """

    describe 'inner-current-line', ->
      it 'select current line without including last newline', ->
        set cursor: [0, 0]
        ensure 'v i l', selectedText: 'This is'
      it 'also skip leading white space', ->
        set cursor: [1, 0]
        ensure 'v i l', selectedText: 'multi line'
    describe 'a-current-line', ->
      it 'select current line without including last newline as like `vil`', ->
        set cursor: [0, 0]
        ensure 'v a l', selectedText: 'This is'
      it 'wont skip leading white space not like `vil`', ->
        set cursor: [1, 0]
        ensure 'v a l', selectedText: '  multi line'

  describe 'Arguments', ->
    describe 'auto-detect inner-pair target', ->
      describe 'inner-pair is comma separated', ->
        it "target inner-paren by auto-detect", ->
          set textC: "(1|st, 2nd)"; ensure 'd i ,', textC: "(|, 2nd)"
          set textC: "(1|st, 2nd)"; ensure 'd a ,', textC: "(|2nd)"
          set textC: "(1st, 2|nd)"; ensure 'd i ,', textC: "(1st, |)"
          set textC: "(1st, 2|nd)"; ensure 'd a ,', textC: "(1st|)"
        it "target inner-curly-bracket by auto-detect", ->
          set textC: "{1|st, 2nd}"; ensure 'd i ,', textC: "{|, 2nd}"
          set textC: "{1|st, 2nd}"; ensure 'd a ,', textC: "{|2nd}"
          set textC: "{1st, 2|nd}"; ensure 'd i ,', textC: "{1st, |}"
          set textC: "{1st, 2|nd}"; ensure 'd a ,', textC: "{1st|}"
        it "target inner-square-bracket by auto-detect", ->
          set textC: "[1|st, 2nd]"; ensure 'd i ,', textC: "[|, 2nd]"
          set textC: "[1|st, 2nd]"; ensure 'd a ,', textC: "[|2nd]"
          set textC: "[1st, 2|nd]"; ensure 'd i ,', textC: "[1st, |]"
          set textC: "[1st, 2|nd]"; ensure 'd a ,', textC: "[1st|]"
      describe 'inner-pair is space separated', ->
        it "target inner-paren by auto-detect", ->
          set textC: "(1|st 2nd)"; ensure 'd i ,', textC: "(| 2nd)"
          set textC: "(1|st 2nd)"; ensure 'd a ,', textC: "(|2nd)"
          set textC: "(1st 2|nd)"; ensure 'd i ,', textC: "(1st |)"
          set textC: "(1st 2|nd)"; ensure 'd a ,', textC: "(1st|)"
        it "target inner-curly-bracket by auto-detect", ->
          set textC: "{1|st 2nd}"; ensure 'd i ,', textC: "{| 2nd}"
          set textC: "{1|st 2nd}"; ensure 'd a ,', textC: "{|2nd}"
          set textC: "{1st 2|nd}"; ensure 'd i ,', textC: "{1st |}"
          set textC: "{1st 2|nd}"; ensure 'd a ,', textC: "{1st|}"
        it "target inner-square-bracket by auto-detect", ->
          set textC: "[1|st 2nd]"; ensure 'd i ,', textC: "[| 2nd]"
          set textC: "[1|st 2nd]"; ensure 'd a ,', textC: "[|2nd]"
          set textC: "[1st 2|nd]"; ensure 'd i ,', textC: "[1st |]"
          set textC: "[1st 2|nd]"; ensure 'd a ,', textC: "[1st|]"
    describe "[fallback] when auto-detect failed, target current-line", ->
      beforeEach ->
        set
          text: """
          if hello(world) and good(bye) {
            1st;
            2nd;
          }
          """

      it "delete 1st elem of inner-curly-bracket when auto-detect succeeded", ->
        set cursor: [1, 3]
        ensure 'd a ,',
          textC: """
          if hello(world) and good(bye) {
            |2nd;
          }
          """
      it "delete 2st elem of inner-curly-bracket when auto-detect succeeded", ->
        set cursor: [2, 3]
        ensure 'd a ,',
          textC: """
          if hello(world) and good(bye) {
            1st|;
          }
          """
      it "delete 1st elem of current-line when auto-detect failed", ->
        set cursor: [0, 0]
        ensure 'd a ,',
          textC: """
          |hello(world) and good(bye) {
            1st;
            2nd;
          }
          """
      it "delete 2nd elem of current-line when auto-detect failed", ->
        set cursor: [0, 3]
        ensure 'd a ,',
          textC: """
          if |and good(bye) {
            1st;
            2nd;
          }
          """
      it "delete 3rd elem of current-line when auto-detect failed", ->
        set cursor: [0, 16]
        ensure 'd a ,',
          textC: """
          if hello(world) |good(bye) {
            1st;
            2nd;
          }
          """
      it "delete 4th elem of current-line when auto-detect failed", ->
        set cursor: [0, 20]
        ensure 'd a ,',
          textC: """
          if hello(world) and |{
            1st;
            2nd;
          }
          """

    describe 'slingle line comma separated text', ->
      describe "change 1st arg", ->
        beforeEach ->               set textC: "var a = func(f|irst(1, 2, 3), second(), 3)"
        it 'change', -> ensure 'c i ,', textC: "var a = func(|, second(), 3)"
        it 'change', -> ensure 'c a ,', textC: "var a = func(|second(), 3)"

      describe 'change 2nd arg', ->
        beforeEach ->               set textC: "var a = func(first(1, 2, 3),| second(), 3)"
        it 'change', -> ensure 'c i ,', textC: "var a = func(first(1, 2, 3), |, 3)"
        it 'change', -> ensure 'c a ,', textC: "var a = func(first(1, 2, 3), |3)"

      describe 'change 3rd arg', ->
        beforeEach ->               set textC: "var a = func(first(1, 2, 3), second(),| 3)"
        it 'change', -> ensure 'c i ,', textC: "var a = func(first(1, 2, 3), second(), |)"
        it 'change', -> ensure 'c a ,', textC: "var a = func(first(1, 2, 3), second()|)"

      describe 'when cursor is on-comma-separator, it affects preceeding arg', ->
        beforeEach ->                   set textC: "var a = func(first(1, 2, 3)|, second(), 3)"
        it 'change 1st', -> ensure 'c i ,', textC: "var a = func(|, second(), 3)"
        it 'change 1st', -> ensure 'c a ,', textC: "var a = func(|second(), 3)"

      describe 'cursor-is-on-white-space, it affects followed arg', ->
        beforeEach ->                   set textC: "var a = func(first(1, 2, 3),| second(), 3)"
        it 'change 2nd', -> ensure 'c i ,', textC: "var a = func(first(1, 2, 3), |, 3)"
        it 'change 2nd', -> ensure 'c a ,', textC: "var a = func(first(1, 2, 3), |3)"

      describe "cursor-is-on-parehthesis, it wont target inner-parent", ->
        it 'change 1st of outer-paren', ->
          set textC: "var a = func(first|(1, 2, 3), second(), 3)"
          ensure 'c i ,', textC: "var a = func(|, second(), 3)"
        it 'change 3rd of outer-paren', ->
          set textC: "var a = func(first(1, 2, 3|), second(), 3)"
          ensure 'c i ,', textC: "var a = func(|, second(), 3)"

      describe "cursor-is-next-or-before parehthesis, it target inner-parent", ->
        it 'change 1st of inner-paren', ->
          set textC: "var a = func(first(|1, 2, 3), second(), 3)"
          ensure 'c i ,', textC: "var a = func(first(|, 2, 3), second(), 3)"
        it 'change 3rd of inner-paren', ->
          set textC: "var a = func(first(1, 2, |3), second(), 3)"
          ensure 'c i ,', textC: "var a = func(first(1, 2, |), second(), 3)"

    describe 'slingle line space separated text', ->
      describe "change 1st arg", ->
        beforeEach ->               set textC: "%w(|1st 2nd 3rd)"
        it 'change', -> ensure 'c i ,', textC: "%w(| 2nd 3rd)"
        it 'change', -> ensure 'c a ,', textC: "%w(|2nd 3rd)"
      describe "change 2nd arg", ->
        beforeEach ->               set textC: "%w(1st |2nd 3rd)"
        it 'change', -> ensure 'c i ,', textC: "%w(1st | 3rd)"
        it 'change', -> ensure 'c a ,', textC: "%w(1st |3rd)"
      describe "change 2nd arg", ->
        beforeEach ->               set textC: "%w(1st 2nd |3rd)"
        it 'change', -> ensure 'c i ,', textC: "%w(1st 2nd |)"
        it 'change', -> ensure 'c a ,', textC: "%w(1st 2nd|)"

    describe 'multi line comma separated text', ->
      beforeEach ->
        set
          textC_: """
          [
            "1st elem is string",
            () => hello('2nd elm is function'),
            3rdElmHasTrailingComma,
          ]
          """
      describe "change 1st arg", ->
        it 'change 1st inner-arg', ->
          set cursor: [1, 0]
          ensure 'c i ,',
            textC: """
            [
              |,
              () => hello('2nd elm is function'),
              3rdElmHasTrailingComma,
            ]
            """
        it 'change 1st a-arg', ->
          set cursor: [1, 0]
          ensure 'c a ,',
            textC: """
            [
              |() => hello('2nd elm is function'),
              3rdElmHasTrailingComma,
            ]
            """
        it 'change 2nd inner-arg', ->
          set cursor: [2, 0]
          ensure 'c i ,',
            textC: """
            [
              "1st elem is string",
              |,
              3rdElmHasTrailingComma,
            ]
            """
        it 'change 2nd a-arg', ->
          set cursor: [2, 0]
          ensure 'c a ,',
            textC: """
            [
              "1st elem is string",
              |3rdElmHasTrailingComma,
            ]
            """
        it 'change 3rd inner-arg', ->
          set cursor: [3, 0]
          ensure 'c i ,',
            textC: """
            [
              "1st elem is string",
              () => hello('2nd elm is function'),
              |,
            ]
            """
        it 'change 3rd a-arg', ->
          set cursor: [3, 0]
          ensure 'c a ,',
            textC: """
            [
              "1st elem is string",
              () => hello('2nd elm is function')|,
            ]
            """

    describe 'when it coudnt find inner-pair from cursor it target current-line', ->
      beforeEach ->
        set
          textC_: """
          if |isMorning(time, of, the, day) {
            helllo("world");
          }
          """
      it "change inner-arg", ->
        ensure "c i ,",
          textC_: """
          if | {
            helllo("world");
          }
          """
      it "change a-arg", ->
        ensure "c a ,",
          textC_: """
          if |{
            helllo("world");
          }
          """

  describe 'Entire', ->
    text = """
      This is
        multi line
      text
      """
    beforeEach ->
      set text: text, cursor: [0, 0]
    describe 'inner-entire', ->
      it 'select entire buffer', ->
        ensure 'escape', selectedText: ''
        ensure 'v i e', selectedText: text
        ensure 'escape', selectedText: ''
        ensure 'j j v i e', selectedText: text
    describe 'a-entire', ->
      it 'select entire buffer', ->
        ensure 'escape', selectedText: ''
        ensure 'v a e', selectedText: text
        ensure 'escape', selectedText: ''
        ensure 'j j v a e', selectedText: text

  describe 'SearchMatchForward, SearchBackwards', ->
    text = """
      0 xxx
      1 abc xxx
      2   xxx yyy
      3 xxx abc
      4 abc\n
      """
    beforeEach ->
      jasmine.attachToDOM(atom.views.getView(atom.workspace))

      set text: text, cursor: [0, 0]
      ensure ['/', search: 'abc'], cursor: [1, 2], mode: 'normal'
      expect(vimState.globalState.get('lastSearchPattern')).toEqual /abc/g

    describe 'gn from normal mode', ->
      it 'select ranges matches to last search pattern and extend selection', ->
        ensure 'g n',
          cursor: [1, 5]
          mode: ['visual', 'characterwise']
          selectionIsReversed: false
          selectedText: 'abc'
        ensure 'g n',
          selectionIsReversed: false
          mode: ['visual', 'characterwise']
          selectedText: """
            abc xxx
            2   xxx yyy
            3 xxx abc
            """
        ensure 'g n',
          selectionIsReversed: false
          mode: ['visual', 'characterwise']
          selectedText: """
            abc xxx
            2   xxx yyy
            3 xxx abc
            4 abc
            """
        ensure 'g n', # Do nothing
          selectionIsReversed: false
          mode: ['visual', 'characterwise']
          selectedText: """
            abc xxx
            2   xxx yyy
            3 xxx abc
            4 abc
            """
    describe 'gN from normal mode', ->
      beforeEach ->
        set cursor: [4, 3]
      it 'select ranges matches to last search pattern and extend selection', ->
        ensure 'g N',
          cursor: [4, 2]
          mode: ['visual', 'characterwise']
          selectionIsReversed: true
          selectedText: 'abc'
        ensure 'g N',
          selectionIsReversed: true
          mode: ['visual', 'characterwise']
          selectedText: """
            abc
            4 abc
            """
        ensure 'g N',
          selectionIsReversed: true
          mode: ['visual', 'characterwise']
          selectedText: """
            abc xxx
            2   xxx yyy
            3 xxx abc
            4 abc
            """
        ensure 'g N', # Do nothing
          selectionIsReversed: true
          mode: ['visual', 'characterwise']
          selectedText: """
            abc xxx
            2   xxx yyy
            3 xxx abc
            4 abc
            """
    describe 'as operator target', ->
      it 'delete next occurrence of last search pattern', ->
        ensure 'd g n',
          cursor: [1, 2]
          mode: 'normal'
          text: """
            0 xxx
            1  xxx
            2   xxx yyy
            3 xxx abc
            4 abc\n
            """
        ensure '.',
          cursor: [3, 5]
          mode: 'normal'
          text_: """
            0 xxx
            1  xxx
            2   xxx yyy
            3 xxx_
            4 abc\n
            """
        ensure '.',
          cursor: [4, 1]
          mode: 'normal'
          text_: """
            0 xxx
            1  xxx
            2   xxx yyy
            3 xxx_
            4 \n
            """
      it 'change next occurrence of last search pattern', ->
        ensure 'c g n',
          cursor: [1, 2]
          mode: 'insert'
          text: """
            0 xxx
            1  xxx
            2   xxx yyy
            3 xxx abc
            4 abc\n
            """
        keystroke 'escape'
        set cursor: [4, 0]
        ensure 'c g N',
          cursor: [3, 6]
          mode: 'insert'
          text_: """
            0 xxx
            1  xxx
            2   xxx yyy
            3 xxx_
            4 abc\n
            """
