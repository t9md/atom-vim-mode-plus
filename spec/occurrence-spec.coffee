{getVimState, dispatch, TextData, getView} = require './spec-helper'
settings = require '../lib/settings'

describe "Occurrence", ->
  [set, ensure, keystroke, editor, editorElement, vimState, classList] = []
  [searchEditor, searchEditorElement] = []
  inputSearchText = (text) ->
    searchEditor.insertText(text)
  dispatchSearchCommand = (name) ->
    dispatch(searchEditorElement, name)

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim
      classList = editorElement.classList
      searchEditor = vimState.searchInput.editor
      searchEditorElement = vimState.searchInput.editorElement

    runs ->
      jasmine.attachToDOM(editorElement)

  describe "operator-modifier-occurrence", ->
    beforeEach ->
      set
        text: """

        ooo: xxx: ooo:
        ---: ooo: xxx: ooo:
        ooo: xxx: ---: xxx: ooo:
        xxx: ---: ooo: ooo:

        ooo: xxx: ooo:
        ---: ooo: xxx: ooo:
        ooo: xxx: ---: xxx: ooo:
        xxx: ---: ooo: ooo:

        """

    describe "o modifier", ->
      it "change occurrence of cursor word in inner-paragraph", ->
        set cursor: [1, 0]
        ensure "c o i p",
          mode: 'insert'
          textC: """

          !: xxx: |:
          ---: |: xxx: |:
          |: xxx: ---: xxx: |:
          xxx: ---: |: |:

          ooo: xxx: ooo:
          ---: ooo: xxx: ooo:
          ooo: xxx: ---: xxx: ooo:
          xxx: ---: ooo: ooo:

          """
        editor.insertText('===')
        ensure "escape",
          mode: 'normal'
          textC: """

          ==!=: xxx: ==|=:
          ---: ==|=: xxx: ==|=:
          ==|=: xxx: ---: xxx: ==|=:
          xxx: ---: ==|=: ==|=:

          ooo: xxx: ooo:
          ---: ooo: xxx: ooo:
          ooo: xxx: ---: xxx: ooo:
          xxx: ---: ooo: ooo:

          """

        ensure "} j .",
          mode: 'normal'
          textC: """

          ===: xxx: ===:
          ---: ===: xxx: ===:
          ===: xxx: ---: xxx: ===:
          xxx: ---: ===: ===:

          ==!=: xxx: ==|=:
          ---: ==|=: xxx: ==|=:
          ==|=: xxx: ---: xxx: ==|=:
          xxx: ---: ==|=: ==|=:

          """

    describe "O modifier", ->
      beforeEach ->
        set
          textC: """

          camelCa|se Cases
          "CaseStudy" SnakeCase
          UP_CASE

          other ParagraphCase
          """
      it "delete subword-occurrence in paragraph and repeatable", ->
        ensure "d O p",
          textC: """

          camel| Cases
          "Study" Snake
          UP_CASE

          other ParagraphCase
          """
        ensure "G .",
          textC: """

          camel Cases
          "Study" Snake
          UP_CASE

          |other Paragraph
          """

    describe "apply various operator to occurrence in various target", ->
      beforeEach ->
        set
          textC: """
          ooo: xxx: o!oo:
          ===: ooo: xxx: ooo:
          ooo: xxx: ===: xxx: ooo:
          xxx: ===: ooo: ooo:
          """
      it "upper case inner-word", ->
        ensure "g U o i l",
          textC: """
          OOO: xxx: O!OO:
          ===: ooo: xxx: ooo:
          ooo: xxx: ===: xxx: ooo:
          xxx: ===: ooo: ooo:
          """
        ensure "2 j .",
          textC: """
          OOO: xxx: OOO:
          ===: ooo: xxx: ooo:
          OOO: xxx: =!==: xxx: OOO:
          xxx: ===: ooo: ooo:
          """
        ensure "j .",
          textC: """
          OOO: xxx: OOO:
          ===: ooo: xxx: ooo:
          OOO: xxx: ===: xxx: OOO:
          xxx: ===: O!OO: OOO:
          """

      describe "clip to mutation end behavior", ->
        beforeEach ->
          set
            textC: """

            oo|o:xxx:ooo:
            xxx:ooo:xxx
            \n
            """
        it "[d o p] delete occurrence and cursor is at mutation end", ->
          ensure "d o p",
            textC: """

            |:xxx::
            xxx::xxx
            \n
            """
        it "[d o j] delete occurrence and cursor is at mutation end", ->
          ensure "d o j",
            textC: """

            |:xxx::
            xxx::xxx
            \n
            """
        it "not clip if original cursor not intersects any occurence-marker", ->
          ensure 'g o', occurrenceText: ['ooo', 'ooo', 'ooo'], cursor: [1, 2]
          keystroke 'j', cursor: [2, 2]
          ensure "d p",
            textC: """

            :xxx::
            xx|x::xxx
            \n
            """

    describe "auto extend target range to include occurrence", ->
      textOriginal = "This text have 3 instance of 'text' in the whole text.\n"
      textFinal = textOriginal.replace(/text/g, '')

      beforeEach ->
        set text: textOriginal

      it "[from start of 1st]", -> set cursor: [0, 5]; ensure 'd o $', text: textFinal
      it "[from middle of 1st]", -> set cursor: [0, 7]; ensure 'd o $', text: textFinal
      it "[from end of last]", -> set cursor: [0, 52]; ensure 'd o 0', text: textFinal
      it "[from middle of last]", -> set cursor: [0, 51]; ensure 'd o 0', text: textFinal

    describe "select-occurrence", ->
      beforeEach ->
        set
          text: """
          vim-mode-plus vim-mode-plus
          """
      describe "what the cursor-word", ->
        ensureCursorWord = (initialPoint, {selectedText}) ->
          set cursor: initialPoint
          ensure "g cmd-d i p",
            selectedText: selectedText
            mode: ['visual', 'characterwise']
          ensure "escape", mode: "normal"

        describe "cursor is on normal word", ->
          it "pick word but not pick partially matched one [by select]", ->
            ensureCursorWord([0, 0], selectedText: ['vim', 'vim'])
            ensureCursorWord([0, 3], selectedText: ['-', '-', '-', '-'])
            ensureCursorWord([0, 4], selectedText: ['mode', 'mode'])
            ensureCursorWord([0, 9], selectedText: ['plus', 'plus'])

        describe "cursor is at single white space [by delete]", ->
          it "pick single white space only", ->
            set
              text: """
              ooo ooo ooo
               ooo ooo ooo
              """
              cursor: [0, 3]
            ensure "d o i p",
              text: """
              ooooooooo
              ooooooooo
              """

        describe "cursor is at sequnce of space [by delete]", ->
          it "select sequnce of white spaces including partially mached one", ->
            set
              cursor: [0, 3]
              text_: """
              ooo___ooo ooo
               ooo ooo____ooo________ooo
              """
            ensure "d o i p",
              text_: """
              oooooo ooo
               ooo ooo ooo  ooo
              """

  describe "stayOnOccurrence settings", ->
    beforeEach ->
      set
        textC: """

        aaa, bbb, ccc
        bbb, a|aa, aaa

        """

    describe "when true (= default)", ->
      it "keep cursor position after operation finished", ->
        ensure 'g U o p',
          textC: """

          AAA, bbb, ccc
          bbb, A|AA, AAA

          """

    describe "when false", ->
      beforeEach ->
        settings.set('stayOnOccurrence', false)

      it "move cursor to start of target as like non-ocurrence operator", ->
        ensure 'g U o p',
          textC: """

          |AAA, bbb, ccc
          bbb, AAA, AAA

          """


  describe "from visual-mode.is-narrowed", ->
    beforeEach ->
      set
        text: """
        ooo: xxx: ooo
        |||: ooo: xxx: ooo
        ooo: xxx: |||: xxx: ooo
        xxx: |||: ooo: ooo
        """
        cursor: [0, 0]

    describe "[vC] select-occurrence", ->
      it "select cursor-word which intersecting selection then apply upper-case", ->
        ensure "v 2 j cmd-d",
          selectedText: ['ooo', 'ooo', 'ooo', 'ooo', 'ooo']
          mode: ['visual', 'characterwise']

        ensure "U",
          text: """
          OOO: xxx: OOO
          |||: OOO: xxx: OOO
          OOO: xxx: |||: xxx: ooo
          xxx: |||: ooo: ooo
          """
          numCursors: 5
          mode: 'normal'

    describe "[vL] select-occurrence", ->
      it "select cursor-word which intersecting selection then apply upper-case", ->
        ensure "5 l V 2 j cmd-d",
          selectedText: ['xxx', 'xxx', 'xxx', 'xxx']
          mode: ['visual', 'characterwise']

        ensure "U",
          text: """
          ooo: XXX: ooo
          |||: ooo: XXX: ooo
          ooo: XXX: |||: XXX: ooo
          xxx: |||: ooo: ooo
          """
          numCursors: 4
          mode: 'normal'

    describe "[vB] select-occurrence", ->
      it "select cursor-word which intersecting selection then apply upper-case", ->
        ensure "W ctrl-v 2 j $ h cmd-d U",
          text: """
          ooo: xxx: OOO
          |||: OOO: xxx: OOO
          ooo: xxx: |||: xxx: OOO
          xxx: |||: ooo: ooo
          """
          numCursors: 4

      it "pick cursor-word from vB range", ->
        ensure "ctrl-v 7 l 2 j o cmd-d U",
          text: """
          OOO: xxx: ooo
          |||: OOO: xxx: ooo
          OOO: xxx: |||: xxx: ooo
          xxx: |||: ooo: ooo
          """
          numCursors: 3

  describe "incremental search integration: change-occurrence-from-search, select-occurrence-from-search", ->
    beforeEach ->
      settings.set('incrementalSearch', true)
      set
        text: """
        ooo: xxx: ooo: 0000
        1: ooo: 22: ooo:
        ooo: xxx: |||: xxx: 3333:
        444: |||: ooo: ooo:
        """
        cursor: [0, 0]

    describe "from normal mode", ->
      it "select occurrence by pattern match", ->
        keystroke '/'
        inputSearchText('\\d{3,4}')
        dispatchSearchCommand('vim-mode-plus:select-occurrence-from-search')
        ensure 'i e',
          selectedText: ['3333', '444', '0000'] # Why '0000' comes last is '0000' become last selection.
          mode: ['visual', 'characterwise']

      it "change occurrence by pattern match", ->
        keystroke '/'
        inputSearchText('^\\w+:')
        dispatchSearchCommand('vim-mode-plus:change-occurrence-from-search')
        ensure 'i e', mode: 'insert'
        editor.insertText('hello')
        ensure
          text: """
          hello xxx: ooo: 0000
          hello ooo: 22: ooo:
          hello xxx: |||: xxx: 3333:
          hello |||: ooo: ooo:
          """

    describe "from visual mode", ->
      describe "visual characterwise", ->
        it "change occurrence in narrowed selection", ->
          keystroke 'v j /'
          inputSearchText('o+')
          dispatchSearchCommand('vim-mode-plus:select-occurrence-from-search')
          ensure 'U',
            text: """
            OOO: xxx: OOO: 0000
            1: ooo: 22: ooo:
            ooo: xxx: |||: xxx: 3333:
            444: |||: ooo: ooo:
            """

      describe "visual linewise", ->
        it "change occurrence in narrowed selection", ->
          keystroke 'V j /'
          inputSearchText('o+')
          dispatchSearchCommand('vim-mode-plus:select-occurrence-from-search')
          ensure 'U',
            text: """
            OOO: xxx: OOO: 0000
            1: OOO: 22: OOO:
            ooo: xxx: |||: xxx: 3333:
            444: |||: ooo: ooo:
            """

      describe "visual blockwise", ->
        it "change occurrence in narrowed selection", ->
          set cursor: [0, 5]
          keystroke 'ctrl-v 2 j 1 0 l /'
          inputSearchText('o+')
          dispatchSearchCommand('vim-mode-plus:select-occurrence-from-search')
          ensure 'U',
            text: """
            ooo: xxx: OOO: 0000
            1: OOO: 22: OOO:
            ooo: xxx: |||: xxx: 3333:
            444: |||: ooo: ooo:
            """

    describe "persistent-selection is exists", ->
      beforeEach ->
        atom.keymaps.add "create-persistent-selection",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'm': 'vim-mode-plus:create-persistent-selection'

        set
          text: """
          ooo: xxx: ooo:
          |||: ooo: xxx: ooo:
          ooo: xxx: |||: xxx: ooo:
          xxx: |||: ooo: ooo:\n
          """
          cursor: [0, 0]

        ensure 'V j m G m m',
          persistentSelectionBufferRange: [
            [[0, 0], [2, 0]]
            [[3, 0], [4, 0]]
          ]

      describe "when no selection is exists", ->
        it "select occurrence in all persistent-selection", ->
          set cursor: [0, 0]
          keystroke '/'
          inputSearchText('xxx')
          dispatchSearchCommand('vim-mode-plus:select-occurrence-from-search')
          ensure 'U',
            text: """
            ooo: XXX: ooo:
            |||: ooo: XXX: ooo:
            ooo: xxx: |||: xxx: ooo:
            XXX: |||: ooo: ooo:\n
            """
            persistentSelectionCount: 0

      describe "when both exits, operator applied to both", ->
        it "select all occurrence in selection", ->
          set cursor: [0, 0]
          keystroke 'V 2 j /'
          inputSearchText('xxx')
          dispatchSearchCommand('vim-mode-plus:select-occurrence-from-search')
          ensure 'U',
            text: """
            ooo: XXX: ooo:
            |||: ooo: XXX: ooo:
            ooo: XXX: |||: XXX: ooo:
            XXX: |||: ooo: ooo:\n
            """
            persistentSelectionCount: 0

    describe "demonstrate persistent-selection's practical scenario", ->
      [oldGrammar] = []
      afterEach ->
        editor.setGrammar(oldGrammar)

      beforeEach ->
        atom.keymaps.add "create-persistent-selection",
          'atom-text-editor.vim-mode-plus:not(.insert-mode)':
            'm': 'vim-mode-plus:toggle-persistent-selection'

        waitsForPromise ->
          atom.packages.activatePackage('language-coffee-script')

        runs ->
          oldGrammar = editor.getGrammar()
          editor.setGrammar(atom.grammars.grammarForScopeName('source.coffee'))

        set text: """
            constructor: (@main, @editor, @statusBarManager) ->
              @editorElement = @editor.element
              @emitter = new Emitter
              @subscriptions = new CompositeDisposable
              @modeManager = new ModeManager(this)
              @mark = new MarkManager(this)
              @register = new RegisterManager(this)
              @persistentSelections = []

              @highlightSearchSubscription = @editorElement.onDidChangeScrollTop =>
                @refreshHighlightSearch()

              @operationStack = new OperationStack(this)
              @cursorStyleManager = new CursorStyleManager(this)

            anotherFunc: ->
              @hello = []
            """

      it 'change all assignment("=") of current-function to "?="', ->
        set cursor: [0, 0]
        ensure ['j f', input: '='], cursor: [1, 17]

        runs ->
          keystroke [
            'g cmd-d' # select-occurrence
            'i f'     # inner-function-text-object
            'm'       # toggle-persistent-selection
          ].join(" ")

          textsInBufferRange = vimState.persistentSelection.getMarkerBufferRanges().map (range) ->
            editor.getTextInBufferRange(range)
          textsInBufferRangeIsAllEqualChar = textsInBufferRange.every((text) -> text is '=')
          expect(textsInBufferRangeIsAllEqualChar).toBe(true)
          expect(vimState.persistentSelection.getMarkers()).toHaveLength(11)

          keystroke '2 l' # to move to out-side of range-mrker
          ensure ['/', search: '=>'], cursor: [9, 69]
          keystroke "m" # clear persistentSelection at cursor which is = sign part of fat arrow.
          expect(vimState.persistentSelection.getMarkers()).toHaveLength(10)

        waitsFor ->
          classList.contains('has-persistent-selection')

        runs ->
          keystroke [
            'ctrl-cmd-g' # select-persistent-selection
            'I'          # Insert at start of selection
          ]
          editor.insertText('?')
          ensure 'escape',
            text: """
            constructor: (@main, @editor, @statusBarManager) ->
              @editorElement ?= @editor.element
              @emitter ?= new Emitter
              @subscriptions ?= new CompositeDisposable
              @modeManager ?= new ModeManager(this)
              @mark ?= new MarkManager(this)
              @register ?= new RegisterManager(this)
              @persistentSelections ?= []

              @highlightSearchSubscription ?= @editorElement.onDidChangeScrollTop =>
                @refreshHighlightSearch()

              @operationStack ?= new OperationStack(this)
              @cursorStyleManager ?= new CursorStyleManager(this)

            anotherFunc: ->
              @hello = []
            """

  describe "preset occurrence marker", ->
    beforeEach ->
      set
        text: """
        This text have 3 instance of 'text' in the whole text
        """
        cursor: [0, 0]

    describe "toggle-preset-occurrence commands", ->
      describe "in normal-mode", ->
        describe "add preset occurrence", ->
          it 'set cursor-ward as preset occurrence marker and not move cursor', ->
            ensure 'g o', occurrenceText: 'This', cursor: [0, 0]
            ensure 'w', cursor: [0, 5]
            ensure 'g o', occurrenceText: ['This', 'text', 'text', 'text'], cursor: [0, 5]

        describe "remove preset occurrence", ->
          it 'removes occurrence one by one separately', ->
            ensure 'g o', occurrenceText: 'This', cursor: [0, 0]
            ensure 'w', cursor: [0, 5]
            ensure 'g o', occurrenceText: ['This', 'text', 'text', 'text'], cursor: [0, 5]
            ensure 'g o', occurrenceText: ['This', 'text', 'text'], cursor: [0, 5]
            ensure 'b g o', occurrenceText: ['text', 'text'], cursor: [0, 0]
          it 'removes all occurrence in this editor by escape', ->
            ensure 'g o', occurrenceText: 'This', cursor: [0, 0]
            ensure 'w', cursor: [0, 5]
            ensure 'g o', occurrenceText: ['This', 'text', 'text', 'text'], cursor: [0, 5]
            ensure 'escape', occurrenceCount: 0

          it 'can recall previously set occurence pattern by `g .`', ->
            ensure 'w v l g o', occurrenceText: ['te', 'te', 'te'], cursor: [0, 6]
            ensure 'escape', occurrenceCount: 0
            expect(vimState.globalState.get('lastOccurrencePattern')).toEqual(/te/g)

            ensure 'w', cursor: [0, 10] # to move cursor to text `have`
            ensure 'g .', occurrenceText: ['te', 'te', 'te'], cursor: [0, 10]

            # But operator modifier not update lastOccurrencePattern
            ensure 'g U o $', textC: "This text |HAVE 3 instance of 'text' in the whole text"
            expect(vimState.globalState.get('lastOccurrencePattern')).toEqual(/te/g)

        describe "restore last occurrence marker by add-preset-occurrence-from-last-occurrence-pattern", ->
          beforeEach ->
            set
              textC: """
              camel
              camelCase
              camels
              camel
              """
          it "can restore occurrence-marker added by `g o` in normal-mode", ->
            set cursor: [0, 0]
            ensure "g o", occurrenceText: ['camel', 'camel']
            ensure 'escape', occurrenceCount: 0
            ensure "g .", occurrenceText: ['camel', 'camel']

          it "can restore occurrence-marker added by `g o` in visual-mode", ->
            set cursor: [0, 0]
            ensure "v i w", selectedText: "camel"
            ensure "g o", occurrenceText: ['camel', 'camel', 'camel', 'camel']
            ensure 'escape', occurrenceCount: 0
            ensure "g .", occurrenceText: ['camel', 'camel', 'camel', 'camel']

          it "can restore occurrence-marker added by `g O` in normal-mode", ->
            set cursor: [0, 0]
            ensure "g O", occurrenceText: ['camel', 'camel', 'camel']
            ensure 'escape', occurrenceCount: 0
            ensure "g .", occurrenceText: ['camel', 'camel', 'camel']

        describe "css class has-occurrence", ->
          describe "manually toggle by toggle-preset-occurrence command", ->
            it 'is auto-set/unset wheter at least one preset-occurrence was exists or not', ->
              expect(classList.contains('has-occurrence')).toBe(false)
              ensure 'g o', occurrenceText: 'This', cursor: [0, 0]
              expect(classList.contains('has-occurrence')).toBe(true)
              ensure 'g o', occurrenceCount: 0, cursor: [0, 0]
              expect(classList.contains('has-occurrence')).toBe(false)

          describe "change 'INSIDE' of marker", ->
            markerLayerUpdated = null
            beforeEach ->
              markerLayerUpdated = false

            it 'destroy marker and reflect to "has-occurrence" CSS', ->
              runs ->
                expect(classList.contains('has-occurrence')).toBe(false)
                ensure 'g o', occurrenceText: 'This', cursor: [0, 0]
                expect(classList.contains('has-occurrence')).toBe(true)

                ensure 'l i', mode: 'insert'
                vimState.occurrenceManager.markerLayer.onDidUpdate ->
                  markerLayerUpdated = true

                editor.insertText('--')
                ensure "escape",
                  textC: "T-|-his text have 3 instance of 'text' in the whole text"
                  mode: 'normal'

              waitsFor ->
                markerLayerUpdated

              runs ->
                ensure occurrenceCount: 0
                expect(classList.contains('has-occurrence')).toBe(false)

      describe "in visual-mode", ->
        describe "add preset occurrence", ->
          it 'set selected-text as preset occurrence marker and not move cursor', ->
            ensure 'w v l', mode: ['visual', 'characterwise'], selectedText: 'te'
            ensure 'g o', mode: 'normal', occurrenceText: ['te', 'te', 'te']
        describe "is-narrowed selection", ->
          [textOriginal] = []
          beforeEach ->
            textOriginal = """
              This text have 3 instance of 'text' in the whole text
              This text have 3 instance of 'text' in the whole text\n
              """
            set
              cursor: [0, 0]
              text: textOriginal
          it "pick ocurrence-word from cursor position and continue visual-mode", ->
            ensure 'w V j', mode: ['visual', 'linewise'], selectedText: textOriginal
            ensure 'g o',
              mode: ['visual', 'linewise']
              selectedText: textOriginal
              occurrenceText: ['text', 'text', 'text', 'text', 'text', 'text']
            ensure ['r', input: '!'],
              mode: 'normal'
              text: """
              This !!!! have 3 instance of '!!!!' in the whole !!!!
              This !!!! have 3 instance of '!!!!' in the whole !!!!\n
              """

      describe "in incremental-search", ->
        beforeEach ->
          settings.set('incrementalSearch', true)

        describe "add-occurrence-pattern-from-search", ->
          it 'mark as occurrence which matches regex entered in search-ui', ->
            keystroke '/'
            inputSearchText('\\bt\\w+')
            dispatchSearchCommand('vim-mode-plus:add-occurrence-pattern-from-search')
            ensure
              occurrenceText: ['text', 'text', 'the', 'text']

    describe "mutate preset occurrence", ->
      beforeEach ->
        set text: """
        ooo: xxx: ooo xxx: ooo:
        !!!: ooo: xxx: ooo xxx: ooo:
        """
        cursor: [0, 0]

      describe "normal-mode", ->
        it '[delete] apply operation to preset-marker intersecting selected target', ->
          ensure 'l g o D',
            text: """
            : xxx:  xxx: :
            !!!: ooo: xxx: ooo xxx: ooo:
            """
        it '[upcase] apply operation to preset-marker intersecting selected target', ->
          set cursor: [0, 6]
          ensure 'l g o g U j',
            text: """
            ooo: XXX: ooo XXX: ooo:
            !!!: ooo: XXX: ooo XXX: ooo:
            """
        it '[upcase exclude] won\'t mutate removed marker', ->
          set cursor: [0, 0]
          ensure 'g o', occurrenceCount: 6
          ensure 'g o', occurrenceCount: 5
          ensure 'g U j',
            text: """
            ooo: xxx: OOO xxx: OOO:
            !!!: OOO: xxx: OOO xxx: OOO:
            """
        it '[delete] apply operation to preset-marker intersecting selected target', ->
          set cursor: [0, 10]
          ensure 'g o g U $',
            text: """
            ooo: xxx: OOO xxx: OOO:
            !!!: ooo: xxx: ooo xxx: ooo:
            """
        it '[change] apply operation to preset-marker intersecting selected target', ->
          ensure 'l g o C',
            mode: 'insert'
            text: """
            : xxx:  xxx: :
            !!!: ooo: xxx: ooo xxx: ooo:
            """
          editor.insertText('YYY')
          ensure 'l g o C',
            mode: 'insert'
            text: """
            YYY: xxx: YYY xxx: YYY:
            !!!: ooo: xxx: ooo xxx: ooo:
            """
            numCursors: 3
        describe "predefined keymap on when has-occurrence", ->
          beforeEach ->
            set
              textC: """
              Vim is editor I used before
              V|im is editor I used before
              Vim is editor I used before
              Vim is editor I used before
              """

          it '[insert-at-start] apply operation to preset-marker intersecting selected target', ->
            ensure 'g o', occurrenceText: ['Vim', 'Vim', 'Vim', 'Vim']
            classList.contains('has-occurrence')
            ensure 'v k I', mode: 'insert', numCursors: 2
            editor.insertText("pure-")
            ensure 'escape',
              mode: 'normal'
              textC: """
              pure!-Vim is editor I used before
              pure|-Vim is editor I used before
              Vim is editor I used before
              Vim is editor I used before
              """

          it '[insert-after-start] apply operation to preset-marker intersecting selected target', ->
            set cursor: [1, 1]
            ensure 'g o', occurrenceText: ['Vim', 'Vim', 'Vim', 'Vim']
            classList.contains('has-occurrence')
            ensure 'v j A', mode: 'insert', numCursors: 2
            editor.insertText(" and Emacs")
            ensure 'escape',
              mode: 'normal'
              textC: """
              Vim is editor I used before
              Vim and Emac|s is editor I used before
              Vim and Emac!s is editor I used before
              Vim is editor I used before
              """

      describe "visual-mode", ->
        it '[upcase] apply to preset-marker as long as it intersects selection', ->
          set
            textC: """
            ooo: x|xx: ooo xxx: ooo:
            xxx: ooo: xxx: ooo xxx: ooo:
            """
          ensure 'g o', occurrenceCount: 5
          ensure 'v j U',
            text: """
            ooo: XXX: ooo XXX: ooo:
            XXX: ooo: xxx: ooo xxx: ooo:
            """

      describe "visual-linewise-mode", ->
        it '[upcase] apply to preset-marker as long as it intersects selection', ->
          set
            cursor: [0, 6]
            text: """
            ooo: xxx: ooo xxx: ooo:
            xxx: ooo: xxx: ooo xxx: ooo:
            """
          ensure 'g o', occurrenceCount: 5
          ensure 'V U',
            text: """
            ooo: XXX: ooo XXX: ooo:
            xxx: ooo: xxx: ooo xxx: ooo:
            """

      describe "visual-blockwise-mode", ->
        it '[upcase] apply to preset-marker as long as it intersects selection', ->
          set
            cursor: [0, 6]
            text: """
            ooo: xxx: ooo xxx: ooo:
            xxx: ooo: xxx: ooo xxx: ooo:
            """
          ensure 'g o', occurrenceCount: 5
          ensure 'ctrl-v j 2 w U',
            text: """
            ooo: XXX: ooo xxx: ooo:
            xxx: ooo: XXX: ooo xxx: ooo:
            """

    describe "MoveToNextOccurrence, MoveToPreviousOccurrence", ->
      beforeEach ->
        set
          textC: """
          |ooo: xxx: ooo
          ___: ooo: xxx:
          ooo: xxx: ooo:
          """

        ensure 'g o',
          occurrenceText: ['ooo', 'ooo', 'ooo', 'ooo', 'ooo']


      describe "tab, shift-tab", ->
        describe "cursor is at start of occurrence", ->
          it "search next/previous occurrence marker", ->
            ensure 'tab tab', cursor: [1, 5]
            ensure '2 tab', cursor: [2, 10]
            ensure '2 shift-tab', cursor: [1, 5]
            ensure '2 shift-tab', cursor: [0, 0]

        describe "when cursor is inside of occurrence", ->
          beforeEach ->
            ensure "escape", occurrenceCount: 0
            set textC: "oooo oo|oo oooo"
            ensure 'g o', occurrenceCount: 3

          describe "tab", ->
            it "move to next occurrence", ->
              ensure 'tab', textC: 'oooo oooo |oooo'

          describe "shift-tab", ->
            it "move to previous occurrence", ->
              ensure 'shift-tab', textC: '|oooo oooo oooo'

      describe "as operator's target", ->
        describe "tab", ->
          it "operate on next occurrence and repeatable", ->
            ensure "g U tab",
              text: """
              OOO: xxx: OOO
              ___: ooo: xxx:
              ooo: xxx: ooo:
              """
              occurrenceCount: 3
            ensure ".",
              text: """
              OOO: xxx: OOO
              ___: OOO: xxx:
              ooo: xxx: ooo:
              """
              occurrenceCount: 2
            ensure "2 .",
              text: """
              OOO: xxx: OOO
              ___: OOO: xxx:
              OOO: xxx: OOO:
              """
              occurrenceCount: 0
            expect(classList.contains('has-occurrence')).toBe(false)

          it "[o-modifier] operate on next occurrence and repeatable", ->
            ensure "escape",
              mode: 'normal'
              occurrenceCount: 0

            ensure "g U o tab",
              text: """
              OOO: xxx: OOO
              ___: ooo: xxx:
              ooo: xxx: ooo:
              """
              occurrenceCount: 0

            ensure ".",
              text: """
              OOO: xxx: OOO
              ___: OOO: xxx:
              ooo: xxx: ooo:
              """
              occurrenceCount: 0

            ensure "2 .",
              text: """
              OOO: xxx: OOO
              ___: OOO: xxx:
              OOO: xxx: OOO:
              """
              occurrenceCount: 0

        describe "shift-tab", ->
          it "operate on next previous and repeatable", ->
            set cursor: [2, 10]
            ensure "g U shift-tab",
              text: """
              ooo: xxx: ooo
              ___: ooo: xxx:
              OOO: xxx: OOO:
              """
              occurrenceCount: 3
            ensure ".",
              text: """
              ooo: xxx: ooo
              ___: OOO: xxx:
              OOO: xxx: OOO:
              """
              occurrenceCount: 2
            ensure "2 .",
              text: """
              OOO: xxx: OOO
              ___: OOO: xxx:
              OOO: xxx: OOO:
              """
              occurrenceCount: 0
            expect(classList.contains('has-occurrence')).toBe(false)

      describe "excude particular occurence by `.` repeat", ->
        it "clear preset-occurrence and move to next", ->
          ensure '2 tab . g U i p',
            textC: """
            OOO: xxx: OOO
            ___: |ooo: xxx:
            OOO: xxx: OOO:
            """

        it "clear preset-occurrence and move to previous", ->
          ensure '2 shift-tab . g U i p',
            textC: """
            OOO: xxx: OOO
            ___: OOO: xxx:
            |ooo: xxx: OOO:
            """

    describe "explict operator-modifier o and preset-marker", ->
      beforeEach ->
        set
          textC: """
          |ooo: xxx: ooo xxx: ooo:
          ___: ooo: xxx: ooo xxx: ooo:
          """

      describe "'o' modifier when preset occurrence already exists", ->
        it "'o' always pick cursor-word and overwrite existing preset marker)", ->
          ensure "g o",
            occurrenceText: ["ooo", "ooo", "ooo", "ooo", "ooo", "ooo"]
          ensure "2 w d o",
            occurrenceText: ["xxx", "xxx", "xxx", "xxx"]
            mode: 'operator-pending'
          ensure "j",
            text: """
            ooo: : ooo : ooo:
            ___: ooo: : ooo : ooo:
            """
            mode: 'normal'

      describe "occurrence bound operator don't overwite pre-existing preset marker", ->
        it "'o' always pick cursor-word and clear existing preset marker", ->
          ensure "g o",
            occurrenceText: ["ooo", "ooo", "ooo", "ooo", "ooo", "ooo"]
          ensure "2 w g cmd-d",
            occurrenceText: ["ooo", "ooo", "ooo", "ooo", "ooo", "ooo"]
            mode: 'operator-pending'
          ensure "j",
           selectedText: ["ooo", "ooo", "ooo", "ooo", "ooo", "ooo"]

    describe "toggle-preset-subword-occurrence commands", ->
      beforeEach ->
        set
          textC: """

          camelCa|se Cases
          "CaseStudy" SnakeCase
          UP_CASE

          other ParagraphCase
          """

      describe "add preset subword-occurrence", ->
        it "mark subword under cursor", ->
          ensure 'g O', occurrenceText: ['Case', 'Case', 'Case', 'Case']
