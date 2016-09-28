{getVimState, dispatch, TextData, getView, withMockPlatform, rawKeystroke} = require './spec-helper'
settings = require '../lib/settings'

describe "Occurrence", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim

    runs ->
      jasmine.attachToDOM(editorElement)

  afterEach ->
    vimState.resetNormalMode()

  describe "operator-modifier-occurrence", ->
    beforeEach ->
      set
        text: """

        ooo: xxx: ooo:
        |||: ooo: xxx: ooo:
        ooo: xxx: |||: xxx: ooo:
        xxx: |||: ooo: ooo:

        ooo: xxx: ooo:
        |||: ooo: xxx: ooo:
        ooo: xxx: |||: xxx: ooo:
        xxx: |||: ooo: ooo:

        """

    describe "operator-modifier-characterwise", ->
      it "change occurrence of cursor word in inner-paragraph", ->
        set cursor: [1, 0]
        ensure "c o i p",
          mode: 'insert'
          numCursors: 8
          text: """

          : xxx: :
          |||: : xxx: :
          : xxx: |||: xxx: :
          xxx: |||: : :

          ooo: xxx: ooo:
          |||: ooo: xxx: ooo:
          ooo: xxx: |||: xxx: ooo:
          xxx: |||: ooo: ooo:

          """
        editor.insertText('!!!')
        ensure "escape",
          mode: 'normal'
          numCursors: 8
          text: """

          !!!: xxx: !!!:
          |||: !!!: xxx: !!!:
          !!!: xxx: |||: xxx: !!!:
          xxx: |||: !!!: !!!:

          ooo: xxx: ooo:
          |||: ooo: xxx: ooo:
          ooo: xxx: |||: xxx: ooo:
          xxx: |||: ooo: ooo:

          """
        ensure "} j .",
          mode: 'normal'
          numCursors: 8
          text: """

          !!!: xxx: !!!:
          |||: !!!: xxx: !!!:
          !!!: xxx: |||: xxx: !!!:
          xxx: |||: !!!: !!!:

          !!!: xxx: !!!:
          |||: !!!: xxx: !!!:
          !!!: xxx: |||: xxx: !!!:
          xxx: |||: !!!: !!!:

          """

    describe "apply various operator to occurrence in various target", ->
      beforeEach ->
        set
          text: """
          ooo: xxx: ooo:
          |||: ooo: xxx: ooo:
          ooo: xxx: |||: xxx: ooo:
          xxx: |||: ooo: ooo:
          """
      it "upper case inner-word", ->
        set cursor: [0, 11]
        ensure "g U o i l", ->
          text: """
          OOO: xxx: OOO:
          |||: ooo: xxx: ooo:
          ooo: xxx: |||: xxx: ooo:
          xxx: |||: ooo: ooo:
          """
          cursor: [0, 0]
        ensure "2 j .", ->
          text: """
          OOO: xxx: OOO:
          |||: ooo: xxx: ooo:
          OOO: xxx: |||: xxx: OOO:
          xxx: |||: ooo: ooo:
          """
          cursor: [2, 0]
        ensure "j .", ->
          text: """
          OOO: xxx: OOO:
          |||: ooo: xxx: ooo:
          OOO: xxx: |||: xxx: OOO:
          xxx: |||: OOO: OOO:
          """
          cursor: [2, 0]
      it "lower case with motion", ->
        set
          text: """
          OOO: XXX: OOO:
          |||: OOO: XXX: OOO:
          OOO: XXX: |||: XXX: OOO:
          XXX: |||: OOO: OOO:
          """
          cursor: [0, 6]
        ensure "g u o 2 j", # lowercase xxx only
          text: """
          OOO: xxx: OOO:
          |||: OOO: xxx: OOO:
          OOO: xxx: |||: xxx: OOO:
          XXX: |||: OOO: OOO:
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

  describe "from visual-mode.is-narrowed", ->
    beforeEach ->
      set
        text: """
        ooo: xxx: ooo:
        |||: ooo: xxx: ooo:
        ooo: xxx: |||: xxx: ooo:
        xxx: |||: ooo: ooo:
        """
        cursor: [0, 0]

    describe "[vC] select-occurrence", ->
      it "select cursor-word which intersecting selection then apply upper-case", ->
        ensure "v 2 j cmd-d U",
          text: """
          OOO: xxx: OOO:
          |||: OOO: xxx: OOO:
          OOO: xxx: |||: xxx: ooo:
          xxx: |||: ooo: ooo:
          """
          numCursors: 5

    describe "[vL] select-occurrence", ->
      it "select cursor-word which intersecting selection then apply upper-case", ->
        ensure "5 l V 2 j cmd-d U",
          text: """
          ooo: XXX: ooo:
          |||: ooo: XXX: ooo:
          ooo: XXX: |||: XXX: ooo:
          xxx: |||: ooo: ooo:
          """
          numCursors: 4

    describe "[vB] select-occurrence", ->
      it "select cursor-word which intersecting selection then apply upper-case", ->
        ensure "W ctrl-v 2 j $ h cmd-d U",
          text: """
          ooo: xxx: OOO:
          |||: OOO: xxx: OOO:
          ooo: xxx: |||: xxx: OOO:
          xxx: |||: ooo: ooo:
          """
          numCursors: 4

      it "pick cursor-word from vB range", ->
        ensure "ctrl-v 7 l 2 j o cmd-d U",
          text: """
          OOO: xxx: ooo:
          |||: OOO: xxx: ooo:
          OOO: xxx: |||: xxx: ooo:
          xxx: |||: ooo: ooo:
          """
          numCursors: 3

  describe "incremental search integration: change-occurrence-from-search, select-occurrence-from-search", ->
    [searchEditor, searchEditorElement] = []

    beforeEach ->
      searchEditor = vimState.searchInput.editor
      searchEditorElement = searchEditor.element
      jasmine.attachToDOM(getView(atom.workspace))
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
        searchEditor.insertText('\\d{3,4}')
        withMockPlatform searchEditorElement, 'platform-darwin' , ->
          rawKeystroke 'cmd-d', document.activeElement
          ensure 'i e',
            selectedText: ['0000', '3333', '444']
            mode: ['visual', 'characterwise']

      it "change occurrence by pattern match", ->
        keystroke '/'
        searchEditor.insertText('^\\w+:')
        withMockPlatform searchEditorElement, 'platform-darwin' , ->
          rawKeystroke 'ctrl-cmd-c', document.activeElement
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
          searchEditor.insertText('o+')
          withMockPlatform searchEditorElement, 'platform-darwin' , ->
            rawKeystroke 'cmd-d', document.activeElement
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
          searchEditor.insertText('o+')
          withMockPlatform searchEditorElement, 'platform-darwin' , ->
            rawKeystroke 'cmd-d', document.activeElement
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
          searchEditor.insertText('o+')

          withMockPlatform searchEditorElement, 'platform-darwin' , ->
            rawKeystroke 'cmd-d', document.activeElement
            ensure 'U',
              text: """
              ooo: xxx: OOO: 0000
              1: OOO: 22: OOO:
              ooo: xxx: |||: xxx: 3333:
              444: |||: ooo: ooo:
              """

    describe "persistent-selection is exists", ->
      persistentSelectionBufferRange = null
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

        persistentSelectionBufferRange = [
          [[0, 0], [2, 0]]
          [[3, 0], [4, 0]]
        ]
        ensure 'V j m G m m',
          persistentSelectionBufferRange: persistentSelectionBufferRange

      describe "when no selection is exists", ->
        it "select occurrence in all persistent-selection", ->
          set cursor: [0, 0]
          keystroke '/'
          searchEditor.insertText('xxx')
          withMockPlatform searchEditorElement, 'platform-darwin' , ->
            rawKeystroke 'cmd-d', document.activeElement
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
          searchEditor.insertText('xxx')
          withMockPlatform searchEditorElement, 'platform-darwin' , ->
            rawKeystroke 'cmd-d', document.activeElement
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
          withMockPlatform searchEditorElement, 'platform-darwin' , ->
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
          editorElement.classList.contains('has-persistent-selection')

        runs ->
          withMockPlatform searchEditorElement, 'platform-darwin' , ->
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
      jasmine.attachToDOM(getView(atom.workspace))
      set
        text: """
        This text have 3 instance of 'text' in the whole text
        """
        cursor: [0, 0]

    describe "toggle-preset-occurrence commands", ->
      describe "in normal-mode", ->
        describe "add preset occurrence", ->
          it 'set cursor-ward as preset occurrence marker and not move cursor', ->
            ensure 'g o', occurrenceCount: 1, occurrenceText: 'This', cursor: [0, 0]
            ensure 'w', cursor: [0, 5]
            ensure 'g o', occurrenceCount: 4, occurrenceText: ['This', 'text', 'text', 'text'], cursor: [0, 5]

        describe "remove preset occurrence", ->
          it 'removes occurrence one by one separately', ->
            ensure 'g o', occurrenceCount: 1, occurrenceText: 'This', cursor: [0, 0]
            ensure 'w', cursor: [0, 5]
            ensure 'g o', occurrenceCount: 4, occurrenceText: ['This', 'text', 'text', 'text'], cursor: [0, 5]
            ensure 'g o', occurrenceCount: 3, occurrenceText: ['This', 'text', 'text'], cursor: [0, 5]
            ensure 'b g o', occurrenceCount: 2, occurrenceText: ['text', 'text'], cursor: [0, 0]
          it 'removes all occurrence in this editor by escape', ->
            ensure 'g o', occurrenceCount: 1, occurrenceText: 'This', cursor: [0, 0]
            ensure 'w', cursor: [0, 5]
            ensure 'g o', occurrenceCount: 4, occurrenceText: ['This', 'text', 'text', 'text'], cursor: [0, 5]
            ensure 'escape', occurrenceCount: 0

        describe "css class has-occurrence", ->
          [classList, update] = []
          beforeEach ->
            vimState.occurrenceManager.markerLayer.onDidUpdate(update = jasmine.createSpy())
          it 'is auto-set/unset wheter at least one preset-occurrence was exists or not', ->
            runs ->
              expect(editorElement.classList.contains('has-occurrence')).toBe(false)
              ensure 'g o', occurrenceCount: 1, occurrenceText: 'This', cursor: [0, 0]
            waitsFor ->
              update.callCount is 1
            runs ->
              expect(editorElement.classList.contains('has-occurrence')).toBe(true)
              ensure 'g o', occurrenceCount: 0, cursor: [0, 0]
            waitsFor ->
              update.callCount is 2
            runs ->
              expect(editorElement.classList.contains('has-occurrence')).toBe(false)

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
            # swrap(editor.getLastSelection()).clearProperties()
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
        [searchEditor, searchEditorElement] = []
        beforeEach ->
          searchEditor = vimState.searchInput.editor
          searchEditorElement = searchEditor.element
          jasmine.attachToDOM(getView(atom.workspace))
          settings.set('incrementalSearch', true)

        describe "add-occurrence-pattern-from-search", ->
          it 'mark as occurrence which matches regex entered in search-ui', ->
            keystroke '/'
            searchEditor.insertText('\\bt\\w+')
            withMockPlatform searchEditorElement, 'platform-darwin' , ->
              rawKeystroke 'cmd-o', document.activeElement
              ensure
                occurrenceText: ['text', 'text', 'the', 'text']

    describe "mutate preset occurence", ->
      beforeEach ->
        set text: """
        ooo: xxx: ooo xxx: ooo:
        !!!: ooo: xxx: ooo xxx: ooo:
        """
        cursor: [0, 0]
        jasmine.attachToDOM(getView(atom.workspace))

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
              text: """
              Vim is editor I used before
              Vim is editor I used before
              Vim is editor I used before
              Vim is editor I used before
              """

          it '[insert-at-start] apply operation to preset-marker intersecting selected target', ->
            set cursor: [1, 1]
            runs ->
              ensure 'g o', occurrenceText: ['Vim', 'Vim', 'Vim', 'Vim']
            waitsFor ->
              editorElement.classList.contains('has-occurrence')
            runs ->
              ensure 'I k',
                mode: 'insert'
                numCursors: 2
              editor.insertText("pure-")
              ensure 'escape',
                mode: 'normal'
                text: """
                pure-Vim is editor I used before
                pure-Vim is editor I used before
                Vim is editor I used before
                Vim is editor I used before
                """
          it '[insert-after-start] apply operation to preset-marker intersecting selected target', ->
            set cursor: [1, 1]
            runs ->
              ensure 'g o', occurrenceText: ['Vim', 'Vim', 'Vim', 'Vim']
            waitsFor ->
              editorElement.classList.contains('has-occurrence')
            runs ->
              ensure 'A j',
                mode: 'insert'
                numCursors: 2
              editor.insertText(" and Emacs")
              ensure 'escape',
                mode: 'normal'
                text: """
                Vim is editor I used before
                Vim and Emacs is editor I used before
                Vim and Emacs is editor I used before
                Vim is editor I used before
                """

      describe "visual-mode", ->
        it '[upcase] apply to preset-marker as long as it intersects selection', ->
          set
            cursor: [0, 6]
            text: """
            ooo: xxx: ooo xxx: ooo:
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

    describe "explict operator-modifier o and preset-marker", ->
      beforeEach ->
        set
          text: """
          ooo: xxx: ooo xxx: ooo:
          !!!: ooo: xxx: ooo xxx: ooo:
          """
          cursor: [0, 0]
          jasmine.attachToDOM(getView(atom.workspace))

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
            !!!: ooo: : ooo : ooo:
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
