{getVimState, dispatch, TextData, getView} = require './spec-helper'
settings = require '../lib/settings'
globalState = require '../lib/global-state'

describe "Motion Search", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, _vim) ->
      vimState = state # to refer as vimState later.
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = _vim

  afterEach ->
    vimState.resetNormalMode()

  describe "the / keybinding", ->
    pane = null

    beforeEach ->
      pane = {activate: jasmine.createSpy("activate")}
      set
        text: """
            abc
            def
            abc
            def\n
          """
        cursor: [0, 0]
      spyOn(atom.workspace, 'getActivePane').andReturn(pane)

      # clear search history
      vimState.searchHistory.clear()
      globalState.currentSearch = null

    describe "as a motion", ->
      it "moves the cursor to the specified search pattern", ->
        ensure ['/', search: 'def'],
          cursor: [1, 0]
        expect(pane.activate).toHaveBeenCalled()

      it "loops back around", ->
        set cursor: [3, 0]
        ensure ['/', search: 'def'], cursor: [1, 0]

      it "uses a valid regex as a regex", ->
        # Cycle through the 'abc' on the first line with a character pattern
        ensure ['/', search: '[abc]'], cursor: [0, 1]
        ensure 'n', cursor: [0, 2]

      it "uses an invalid regex as a literal string", ->
        # Go straight to the literal [abc
        set text: "abc\n[abc]\n"
        ensure ['/', search: '[abc'], cursor: [1, 0]
        ensure 'n', cursor: [1, 0]

      it "uses ? as a literal string", ->
        set text: "abc\n[a?c?\n"
        ensure ['/', search: '?'], cursor: [1, 2]
        ensure 'n', cursor: [1, 4]

      it 'works with selection in visual mode', ->
        set text: 'one two three'
        ensure ['v/', search: 'th'], cursor: [0, 9]
        ensure 'd', text: 'hree'

      it 'extends selection when repeating search in visual mode', ->
        set text: """
          line1
          line2
          line3
          """

        ensure ['v/', {search: 'line'}],
          selectedBufferRange: [[0, 0], [1, 1]]
        ensure 'n',
          selectedBufferRange: [[0, 0], [2, 1]]

      it 'searches to the correct column in visual linewise mode', ->
        ensure ['V/', {search: 'ef'}],
          selectedText: "abc\ndef\n",
          characterwiseHead: [1, 1]
          cursor: [2, 0]
          mode: ['visual', 'linewise']

      it 'not extend linwise selection if search matches on same line', ->
        # settings.set 'incrementalSearch', true
        set text: """
          abc def
          def\n
          """
        ensure ['V/', {search: 'ef'}],
          selectedText: "abc def\n",

      describe "case sensitivity", ->
        beforeEach ->
          set
            text: "\nabc\nABC\n"
            cursor: [0, 0]

        it "works in case sensitive mode", ->
          ensure ['/', search: 'ABC'], cursor: [2, 0]
          ensure 'n', cursor: [2, 0]

        it "works in case insensitive mode", ->
          ensure ['/', search: '\\cAbC'], cursor: [1, 0]
          ensure 'n', cursor: [2, 0]

        it "works in case insensitive mode wherever \\c is", ->
          ensure ['/', search: 'AbC\\c'], cursor: [1, 0]
          ensure 'n', cursor: [2, 0]

        describe "when ignoreCaseForSearch is enabled", ->
          beforeEach ->
            settings.set 'ignoreCaseForSearch', true

          it "ignore case when search [case-1]", ->
            ensure ['/', search: 'abc'], cursor: [1, 0]
            ensure 'n', cursor: [2, 0]

          it "ignore case when search [case-2]", ->
            ensure ['/', search: 'ABC'], cursor: [1, 0]
            ensure 'n', cursor: [2, 0]

        describe "when useSmartcaseForSearch is enabled", ->
          beforeEach ->
            settings.set 'useSmartcaseForSearch', true

          it "ignore case when searh term includes A-Z", ->
            ensure ['/', search: 'ABC'], cursor: [2, 0]
            ensure 'n', cursor: [2, 0]

          it "ignore case when searh term NOT includes A-Z regardress of `ignoreCaseForSearch`", ->
            settings.set 'ignoreCaseForSearch', false # default
            ensure ['/', search: 'abc'], cursor: [1, 0]
            ensure 'n', cursor: [2, 0]

          it "ignore case when searh term NOT includes A-Z regardress of `ignoreCaseForSearch`", ->
            settings.set 'ignoreCaseForSearch', true # default
            ensure ['/', search: 'abc'], cursor: [1, 0]
            ensure 'n', cursor: [2, 0]

      describe "repeating", ->
        it "does nothing with no search history", ->
          set cursor: [0, 0]
          ensure 'n', cursor: [0, 0]
          set cursor: [1, 1]
          ensure 'n', cursor: [1, 1]

      describe "repeating with search history", ->
        beforeEach ->
          keystroke ['/', search: 'def']

        it "repeats previous search with /<enter>", ->
          ensure ['/', search: ''], cursor: [3, 0]

        it "repeats previous search with //", ->
          ensure ['/', search: '/'], cursor: [3, 0]

        describe "the n keybinding", ->
          it "repeats the last search", ->
            ensure 'n', cursor: [3, 0]

        describe "the N keybinding", ->
          it "repeats the last search backwards", ->
            set cursor: [0, 0]
            ensure 'N', cursor: [3, 0]
            ensure 'N', cursor: [1, 0]

      describe "composing", ->
        it "composes with operators", ->
          ensure ['d/', search: 'def'], text: "def\nabc\ndef\n"

        it "repeats correctly with operators", ->
          ensure ['d/', search: 'def', '.'],
            text: "def\n"

    describe "when reversed as ?", ->
      it "moves the cursor backwards to the specified search pattern", ->
        ensure ['?', search: 'def'], cursor: [3, 0]

      it "accepts / as a literal search pattern", ->
        set
          text: "abc\nd/f\nabc\nd/f\n"
          cursor: [0, 0]
        ensure ['?', search: '/'], cursor: [3, 1]
        ensure ['?', search: '/'], cursor: [1, 1]

      describe "repeating", ->
        beforeEach ->
          keystroke ['?', search: 'def']

        it "repeats previous search as reversed with ?<enter>", ->
          ensure ['?', search: ''], cursor: [1, 0]

        it "repeats previous search as reversed with ??", ->
          ensure ['?', search: '?'], cursor: [1, 0]

        describe 'the n keybinding', ->
          it "repeats the last search backwards", ->
            set cursor: [0, 0]
            ensure 'n', cursor: [3, 0]

        describe 'the N keybinding', ->
          it "repeats the last search forwards", ->
            set cursor: [0, 0]
            ensure 'N', cursor: [1, 0]

    describe "using search history", ->
      inputEditor = null
      ensureInputEditor = (command, {text}) ->
        dispatch(inputEditor, command)
        expect(inputEditor.getModel().getText()).toEqual(text)

      beforeEach ->
        ensure ['/', search: 'def'], cursor: [1, 0]
        ensure ['/', search: 'abc'], cursor: [2, 0]
        inputEditor = vimState.searchInput.editorElement

      it "allows searching history in the search field", ->
        keystroke '/'
        ensureInputEditor 'core:move-up', text: 'abc'
        ensureInputEditor 'core:move-up', text: 'def'
        ensureInputEditor 'core:move-up', text: 'def'

      it "resets the search field to empty when scrolling back", ->
        keystroke '/'
        ensureInputEditor 'core:move-up', text: 'abc'
        ensureInputEditor 'core:move-up', text: 'def'
        ensureInputEditor 'core:move-down', text: 'abc'
        ensureInputEditor 'core:move-down', text: ''

    describe "highlightSearch", ->
      textForMarker = (marker) ->
        editor.getTextInBufferRange(marker.getBufferRange())

      ensureHightlightSearch = (options) ->
        markers = vimState.getHighlightSearch()
        if options.length?
          expect(markers).toHaveLength(options.length)

        if options.text?
          text = markers.map (marker) -> textForMarker(marker)
          expect(text).toEqual(options.text)

        if options.mode?
          ensure {mode: options.mode}

      beforeEach ->
        jasmine.attachToDOM(getView(atom.workspace))
        settings.set('highlightSearch', true)
        expect(vimState.hasHighlightSearch()).toBe(false)
        ensure ['/', search: 'def'], cursor: [1, 0]

      describe "clearHighlightSearch command", ->
        it "clear highlightSearch marker", ->
          ensureHightlightSearch length: 2, text: ["def", "def"], mode: 'normal'
          dispatch(editorElement, 'vim-mode-plus:clear-highlight-search')
          expect(vimState.hasHighlightSearch()).toBe(false)

      describe "clearHighlightSearchOnResetNormalMode", ->
        describe "default setting", ->
          it "it won't clear highlightSearch", ->
            ensureHightlightSearch length: 2, text: ["def", "def"], mode: 'normal'
            dispatch(editorElement, 'vim-mode-plus:reset-normal-mode')
            ensureHightlightSearch length: 2, text: ["def", "def"], mode: 'normal'

        describe "when enabled", ->
          it "it clear highlightSearch on reset-normal-mode", ->
            settings.set('clearHighlightSearchOnResetNormalMode', true)
            ensureHightlightSearch length: 2, text: ["def", "def"], mode: 'normal'
            dispatch(editorElement, 'vim-mode-plus:reset-normal-mode')
            expect(vimState.hasHighlightSearch()).toBe(false)
            ensure mode: 'normal'

  describe "the * keybinding", ->
    beforeEach ->
      set
        text: "abd\n@def\nabd\ndef\n"
        cursorBuffer: [0, 0]

    describe "as a motion", ->
      it "moves cursor to next occurence of word under cursor", ->
        ensure '*', cursorBuffer: [2, 0]

      it "repeats with the n key", ->
        ensure '*', cursorBuffer: [2, 0]
        ensure 'n', cursorBuffer: [0, 0]

      it "doesn't move cursor unless next occurence is the exact word (no partial matches)", ->
        set
          text: "abc\ndef\nghiabc\njkl\nabcdef"
          cursorBuffer: [0, 0]
        ensure '*', cursorBuffer: [0, 0]

      describe "with words that contain 'non-word' characters", ->
        it "moves cursor to next occurence of word under cursor", ->
          set
            text: "abc\n@def\nabc\n@def\n"
            cursorBuffer: [1, 0]
          ensure '*', cursorBuffer: [3, 0]

        it "doesn't move cursor unless next match has exact word ending", ->
          set
            text: "abc\n@def\nabc\n@def1\n"
            cursorBuffer: [1, 1]
          # this is because of the default isKeyword value of vim-mode-plus that includes @
          ensure '*', cursorBuffer: [1, 0]

        # FIXME: This behavior is different from the one found in
        # vim. This is because the word boundary match in Javascript
        # ignores starting 'non-word' characters.
        # e.g.
        # in Vim:        /\<def\>/.test("@def") => false
        # in Javascript: /\bdef\b/.test("@def") => true
        it "moves cursor to the start of valid word char", ->
          set
            text: "abc\ndef\nabc\n@def\n"
            cursorBuffer: [1, 0]
          ensure '*', cursorBuffer: [3, 1]

      describe "when cursor is on non-word char column", ->
        it "matches only the non-word char", ->
          set
            text: "abc\n@def\nabc\n@def\n"
            cursorBuffer: [1, 0]
          ensure '*', cursorBuffer: [3, 0]

      describe "when cursor is not on a word", ->
        it "does a match with the next word", ->
          set
            text: "abc\na  @def\n abc\n @def"
            cursorBuffer: [1, 1]
          ensure '*', cursorBuffer: [3, 1]

      describe "when cursor is at EOF", ->
        it "doesn't try to do any match", ->
          set
            text: "abc\n@def\nabc\n "
            cursorBuffer: [3, 0]
          ensure '*', cursorBuffer: [3, 0]

    describe "caseSensitivity setting", ->
      beforeEach ->
        set
          text: """
          abc
          ABC
          abC
          abc
          ABC
          """
          cursor: [0, 0]

      it "search case sensitively when `ignoreCaseForSearchCurrentWord` is false(=default)", ->
        expect(settings.get('ignoreCaseForSearchCurrentWord')).toBe(false)
        ensure '*', cursorBuffer: [3, 0]
        ensure 'n', cursorBuffer: [0, 0]

      it "search case insensitively when `ignoreCaseForSearchCurrentWord` true", ->
        settings.set 'ignoreCaseForSearchCurrentWord', true
        ensure '*', cursorBuffer: [1, 0]
        ensure 'n', cursorBuffer: [2, 0]
        ensure 'n', cursorBuffer: [3, 0]
        ensure 'n', cursorBuffer: [4, 0]

      describe "useSmartcaseForSearchCurrentWord is enabled", ->
        beforeEach ->
          settings.set 'useSmartcaseForSearchCurrentWord', true

        it "search case sensitively when enable and search term includes uppercase", ->
          set cursor: [1, 0]
          ensure '*', cursorBuffer: [4, 0]
          ensure 'n', cursorBuffer: [1, 0]

        it "search case insensitively when enable and search term NOT includes uppercase", ->
          set cursor: [0, 0]
          ensure '*', cursorBuffer: [1, 0]
          ensure 'n', cursorBuffer: [2, 0]
          ensure 'n', cursorBuffer: [3, 0]
          ensure 'n', cursorBuffer: [4, 0]

  describe "the hash keybinding", ->
    describe "as a motion", ->
      it "moves cursor to previous occurence of word under cursor", ->
        set
          text: "abc\n@def\nabc\ndef\n"
          cursorBuffer: [2, 1]
        ensure '#', cursorBuffer: [0, 0]

      it "repeats with n", ->
        set
          text: "abc\n@def\nabc\ndef\nabc\n"
          cursorBuffer: [2, 1]
        ensure '#', cursorBuffer: [0, 0]
        ensure 'n', cursorBuffer: [4, 0]
        ensure 'n', cursorBuffer: [2, 0]

      it "doesn't move cursor unless next occurence is the exact word (no partial matches)", ->
        set
          text: "abc\ndef\nghiabc\njkl\nabcdef"
          cursorBuffer: [0, 0]
        ensure '#', cursorBuffer: [0, 0]

      describe "with words that containt 'non-word' characters", ->
        it "moves cursor to next occurence of word under cursor", ->
          set
            text: "abc\n@def\nabc\n@def\n"
            cursorBuffer: [3, 0]
          ensure '#', cursorBuffer: [1, 0]

        it "moves cursor to the start of valid word char", ->
          set
            text: "abc\n@def\nabc\ndef\n"
            cursorBuffer: [3, 0]
          ensure '#', cursorBuffer: [1, 1]

      describe "when cursor is on non-word char column", ->
        it "matches only the non-word char", ->
          set
            text: "abc\n@def\nabc\n@def\n"
            cursorBuffer: [1, 0]
          ensure '*', cursorBuffer: [3, 0]

    describe "caseSensitivity setting", ->
      beforeEach ->
        set
          text: """
          abc
          ABC
          abC
          abc
          ABC
          """
          cursor: [4, 0]

      it "search case sensitively when `ignoreCaseForSearchCurrentWord` is false(=default)", ->
        expect(settings.get('ignoreCaseForSearchCurrentWord')).toBe(false)
        ensure '#', cursorBuffer: [1, 0]
        ensure 'n', cursorBuffer: [4, 0]

      it "search case insensitively when `ignoreCaseForSearchCurrentWord` true", ->
        settings.set 'ignoreCaseForSearchCurrentWord', true
        ensure '#', cursorBuffer: [3, 0]
        ensure 'n', cursorBuffer: [2, 0]
        ensure 'n', cursorBuffer: [1, 0]
        ensure 'n', cursorBuffer: [0, 0]

      describe "useSmartcaseForSearchCurrentWord is enabled", ->
        beforeEach ->
          settings.set 'useSmartcaseForSearchCurrentWord', true

        it "search case sensitively when enable and search term includes uppercase", ->
          set cursor: [4, 0]
          ensure '#', cursorBuffer: [1, 0]
          ensure 'n', cursorBuffer: [4, 0]

        it "search case insensitively when enable and search term NOT includes uppercase", ->
          set cursor: [0, 0]
          ensure '#', cursorBuffer: [4, 0]
          ensure 'n', cursorBuffer: [3, 0]
          ensure 'n', cursorBuffer: [2, 0]
          ensure 'n', cursorBuffer: [1, 0]
          ensure 'n', cursorBuffer: [0, 0]

  # FIXME: No longer child of search so move to motion-general-spec.coffe?
  describe 'the % motion', ->
    describe "Parenthesis", ->
      beforeEach ->
        set text: "(___)"
      describe "as operator target", ->
        beforeEach ->
          set text: "(_(_)_)"
        it 'behave inclusively when is at open pair', ->
          set cursor: [0, 2]
          ensure 'd%', text: "(__)"
        it 'behave inclusively when is at open pair', ->
          set cursor: [0, 4]
          ensure 'd%', text: "(__)"
      describe "cursor is at pair char", ->
        it "cursor is at open pair, it move to closing pair", ->
          set cursor: [0, 0]
          ensure '%', cursor: [0, 4]
          ensure '%', cursor: [0, 0]
        it "cursor is at close pair, it move to open pair", ->
          set cursor: [0, 4]
          ensure '%', cursor: [0, 0]
          ensure '%', cursor: [0, 4]
      describe "cursor is enclosed by pair", ->
        beforeEach ->
          set
            text: "(___)",
            cursor: [0, 2]
        it "move to open pair", ->
          ensure '%', cursor: [0, 0]
      describe "cursor is bofore open pair", ->
        beforeEach ->
          set
            text: "__(___)",
            cursor: [0, 0]
        it "move to open pair", ->
          ensure '%', cursor: [0, 6]
      describe "cursor is after close pair", ->
        beforeEach ->
          set
            text: "__(___)__",
            cursor: [0, 7]
        it "fail to move", ->
          ensure '%', cursor: [0, 7]
      describe "multi line", ->
        beforeEach ->
          set
            text: """
            ___
            ___(__
            ___
            ___)
            """
        describe "when open and close pair is not at cursor line", ->
          it "fail to move", ->
            set cursor: [0, 0]
            ensure '%', cursor: [0, 0]
          it "fail to move", ->
            set cursor: [2, 0]
            ensure '%', cursor: [2, 0]
        describe "when open pair is forwarding to cursor in same row", ->
          it "move to closing pair", ->
            set cursor: [1, 0]
            ensure '%', cursor: [3, 3]
        describe "when cursor position is greater than open pair", ->
          it "fail to move", ->
            set cursor: [1, 4]
            ensure '%', cursor: [1, 4]
        describe "when close pair is forwarding to cursor in same row", ->
          it "move to closing pair", ->
            set cursor: [3, 0]
            ensure '%', cursor: [1, 3]

    describe "CurlyBracket", ->
      beforeEach ->
        set text: "{___}"
      it "cursor is at open pair, it move to closing pair", ->
        set cursor: [0, 0]
        ensure '%', cursor: [0, 4]
        ensure '%', cursor: [0, 0]
      it "cursor is at close pair, it move to open pair", ->
        set cursor: [0, 4]
        ensure '%', cursor: [0, 0]
        ensure '%', cursor: [0, 4]

    describe "SquareBracket", ->
      beforeEach ->
        set text: "[___]"
      it "cursor is at open pair, it move to closing pair", ->
        set cursor: [0, 0]
        ensure '%', cursor: [0, 4]
        ensure '%', cursor: [0, 0]
      it "cursor is at close pair, it move to open pair", ->
        set cursor: [0, 4]
        ensure '%', cursor: [0, 0]
        ensure '%', cursor: [0, 4]

    describe "complex situation", ->
      beforeEach ->
        set
          text: """
          (_____)__{__[___]__}
          _
          """
      it 'move to closing pair which open pair come first', ->
        set cursor: [0, 7]
        ensure '%', cursor: [0, 19]
        set cursor: [0, 10]
        ensure '%', cursor: [0, 16]
      it 'enclosing pair is prioritized over forwarding range', ->
        set cursor: [0, 2]
        ensure '%', cursor: [0, 0]
