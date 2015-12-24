{getVimState, dispatch, TextData} = require './spec-helper'
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
    vimState.activate('reset')

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
      globalState.currentSearch = {}

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

        it "uses case insensitive search if useSmartcaseForSearch is true and searching lowercase", ->
          settings.set 'useSmartcaseForSearch', true
          ensure ['/', search: 'abc'], cursor: [1, 0]
          ensure 'n', cursor: [2, 0]

        it "uses case sensitive search if useSmartcaseForSearch is true and searching uppercase", ->
          settings.set 'useSmartcaseForSearch', true
          ensure ['/', search: 'ABC'], cursor: [2, 0]
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
        inputEditor = vimState.search.view.editorElement

      it "allows searching history in the search field", ->
        _editor = inputEditor.getModel()
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

  describe 'the % motion', ->
    beforeEach ->
      set
        text: "( ( ) )--{ text in here; and a function call(with parameters) }\n"
        cursor: [0, 0]

    it 'matches the correct parenthesis', ->
      ensure '%', cursor: [0, 6]

    it 'matches the correct brace', ->
      set cursor: [0, 9]
      ensure '%', cursor: [0, 62]

    it 'composes correctly with d', ->
      set cursor: [0, 9]
      ensure 'd%',
        text: "( ( ) )--\n"

    it 'moves correctly when composed with v going forward', ->
      ensure 'vh%', cursor: [0, 7]

    it 'moves correctly when composed with v going backward', ->
      set cursor: [0, 5]
      ensure 'v%', cursor: [0, 0]

    it 'it moves appropriately to find the nearest matching action', ->
      set cursor: [0, 3]
      ensure '%',
        cursor: [0, 2]
        text: "( ( ) )--{ text in here; and a function call(with parameters) }\n"

    it 'it moves appropriately to find the nearest matching action', ->
      set cursor: [0, 26]
      ensure '%',
        cursor: [0, 60]
        text: "( ( ) )--{ text in here; and a function call(with parameters) }\n"

    it "finds matches across multiple lines", ->
      set
        text: "...(\n...)"
        cursor: [0, 0]
      ensure '%',
        cursor: [1, 3]

    it "does not affect search history", ->
      ensure ['/', search: 'func'], cursor: [0, 31]
      ensure '%', cursor: [0, 60]
      ensure 'n', cursor: [0, 31]
