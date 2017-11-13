{getVimState, dispatch, TextData} = require './spec-helper'
settings = require '../lib/settings'

describe "Motion Find", ->
  [set, ensure, editor, editorElement, vimState] = []

  beforeEach ->
    settings.set('useExperimentalFasterInput', true)
    # jasmine.attachToDOM(atom.workspace.getElement())

    getVimState (state, _vim) ->
      vimState = state # to refer as vimState later.
      {editor, editorElement} = vimState
      {set, ensure} = _vim

  xdescribe 'the f performance', ->
    timesToExecute = 500
    # timesToExecute = 1
    measureWithTimeEnd = (fn) ->
      console.time(fn.name)
      fn()
      # console.log "[time-end]"
      console.timeEnd(fn.name)

    measureWithPerformanceNow = (fn) ->
      t0 = performance.now()
      fn()
      t1 = performance.now()
      console.log "[performance.now] took #{t1 - t0} msec"

    beforeEach ->
      set
        text: "  " + "l".repeat(timesToExecute)
        cursor: [0, 0]

    describe 'the f read-char-via-keybinding performance', ->
      beforeEach ->
        vimState.useMiniEditor = false

      it '[with keybind] moves to l char', ->
        testPerformanceOfKeybind = ->
          ensure("f l") for n in [1..timesToExecute]
          ensure null, cursor: [0, timesToExecute + 1]

        console.log "== keybind"
        ensure "f l", cursor: [0, 2]
        set cursor: [0, 0]
        measureWithTimeEnd(testPerformanceOfKeybind)
        # set cursor: [0, 0]
        # measureWithPerformanceNow(testPerformanceOfKeybind)

    xdescribe '[with hidden-input] moves to l char', ->
      it '[with hidden-input] moves to l char', ->
        testPerformanceOfHiddenInput = ->
          ensure('f l') for n in [1..timesToExecute]
          ensure null, cursor: [0, timesToExecute + 1]

        console.log "== hidden"
        ensure 'f l', cursor: [0, 2]

        set cursor: [0, 0]
        measureWithTimeEnd(testPerformanceOfHiddenInput)
        # set cursor: [0, 0]
        # measureWithPerformanceNow(testPerformanceOfHiddenInput)

  describe 'the f/F keybindings', ->
    beforeEach ->
      set
        text: "abcabcabcabc\n"
        cursor: [0, 0]

    it 'moves to the first specified character it finds', ->
      ensure 'f c', cursor: [0, 2]

    it 'extends visual selection in visual-mode and repetable', ->
      ensure 'v',   mode: ['visual', 'characterwise']
      ensure 'f c', selectedText: 'abc',    cursor: [0, 3]
      ensure ';',   selectedText: 'abcabc', cursor: [0, 6]
      ensure ',',   selectedText: 'abc',    cursor: [0, 3]

    it 'moves backwards to the first specified character it finds', ->
      set           cursor: [0, 2]
      ensure 'F a', cursor: [0, 0]

    it 'respects count forward', ->
      ensure '2 f a', cursor: [0, 6]

    it 'respects count backward', ->
      set             cursor: [0, 6]
      ensure '2 F a', cursor: [0, 0]

    it "doesn't move if the character specified isn't found", ->
      ensure 'f d', cursor: [0, 0]

    it "doesn't move if there aren't the specified count of the specified character", ->
      ensure '1 0 f a', cursor: [0, 0]
      # a bug was making this behaviour depend on the count
      ensure '1 1 f a', cursor: [0, 0]
      # and backwards now
      set               cursor: [0, 6]
      ensure '1 0 F a', cursor: [0, 6]
      ensure '1 1 F a', cursor: [0, 6]

    it "composes with d", ->
      set cursor: [0, 3]
      ensure 'd 2 f a', text: 'abcbc\n'

    it "F behaves exclusively when composes with operator", ->
      set cursor: [0, 3]
      ensure 'd F a', text: 'abcabcabc\n'

  describe "[regression guard] repeat(; or ,) after used as operator target", ->
    it "repeat after d f", ->
      set             textC: "a1    |a2    a3    a4"
      ensure "d f a", textC: "a1    |3    a4", mode: "normal", selectedText: ""
      ensure ";",     textC: "a1    3    |a4", mode: "normal", selectedText: ""
      ensure ",",     textC: "|a1    3    a4", mode: "normal", selectedText: ""
    it "repeat after d t", ->
      set             textC: "|a1    a2    a3    a4"
      ensure "d t a", textC: "|a2    a3    a4", mode: "normal", selectedText: ""
      ensure ";",     textC: "a2   | a3    a4", mode: "normal", selectedText: ""
      ensure ",",     textC: "a|2    a3    a4", mode: "normal", selectedText: ""
    it "repeat after d F", ->
      set             textC: "a1    a2    a3    |a4"
      ensure "d F a", textC: "a1    a2    |a4", mode: "normal", selectedText: ""
      ensure ";",     textC: "a1    |a2    a4", mode: "normal", selectedText: ""
      ensure ",",     textC: "a1    a2    |a4", mode: "normal", selectedText: ""
    it "repeat after d T", ->
      set             textC: "a1    a2    a3    |a4"
      set             textC: "a1    a2    a|a4"
      ensure "d T a", textC: "a1    a2    a|a4", mode: "normal", selectedText: ""
      ensure ";",     textC: "a1    a|2    aa4", mode: "normal", selectedText: ""
      ensure ",",     textC: "a1    a2   | aa4", mode: "normal", selectedText: ""

  describe "cancellation", ->
    it "keeps multiple-cursors when cancelled", ->
      set                 textC: "|   a\n!   a\n|   a\n"
      ensure "f escape",  textC: "|   a\n!   a\n|   a\n"

  describe 'the t/T keybindings', ->
    beforeEach ->
      set
        text: "abcabcabcabc\n"
        cursor: [0, 0]

    it 'moves to the character previous to the first specified character it finds', ->
      ensure 't a', cursor: [0, 2]
      # or stays put when it's already there
      ensure 't a', cursor: [0, 2]

    it 'moves backwards to the character after the first specified character it finds', ->
      set cursor: [0, 2]
      ensure 'T a', cursor: [0, 1]

    it 'respects count forward', ->
      ensure '2 t a', cursor: [0, 5]

    it 'respects count backward', ->
      set cursor: [0, 6]
      ensure '2 T a', cursor: [0, 1]

    it "doesn't move if the character specified isn't found", ->
      ensure 't d', cursor: [0, 0]

    it "doesn't move if there aren't the specified count of the specified character", ->
      ensure '1 0 t d', cursor: [0, 0]
      # a bug was making this behaviour depend on the count
      ensure '1 1 t a', cursor: [0, 0]
      # and backwards now
      set cursor: [0, 6]
      ensure '1 0 T a', cursor: [0, 6]
      ensure '1 1 T a', cursor: [0, 6]

    it "composes with d", ->
      set cursor: [0, 3]
      ensure 'd 2 t b',
        text: 'abcbcabc\n'

    it "delete char under cursor even when no movement happens since it's inclusive motion", ->
      set cursor: [0, 0]
      ensure 'd t b',
        text: 'bcabcabcabc\n'
    it "do nothing when inclusiveness inverted by v operator-modifier", ->
      text: "abcabcabcabc\n"
      set cursor: [0, 0]
      ensure 'd v t b',
        text: 'abcabcabcabc\n'

    it "T behaves exclusively when composes with operator", ->
      set cursor: [0, 3]
      ensure 'd T b',
        text: 'ababcabcabc\n'

    it "T don't delete character under cursor even when no movement happens", ->
      set cursor: [0, 3]
      ensure 'd T c',
        text: 'abcabcabcabc\n'

  describe 'the ; and , keybindings', ->
    beforeEach ->
      set
        text: "abcabcabcabc\n"
        cursor: [0, 0]

    it "repeat f in same direction", ->
      ensure 'f c', cursor: [0, 2]
      ensure ';',   cursor: [0, 5]
      ensure ';',   cursor: [0, 8]

    it "repeat F in same direction", ->
      set           cursor: [0, 10]
      ensure 'F c', cursor: [0, 8]
      ensure ';',   cursor: [0, 5]
      ensure ';',   cursor: [0, 2]

    it "repeat f in opposite direction", ->
      set           cursor: [0, 6]
      ensure 'f c', cursor: [0, 8]
      ensure ',',   cursor: [0, 5]
      ensure ',',   cursor: [0, 2]

    it "repeat F in opposite direction", ->
      set           cursor: [0, 4]
      ensure 'F c', cursor: [0, 2]
      ensure ',',   cursor: [0, 5]
      ensure ',',   cursor: [0, 8]

    it "alternate repeat f in same direction and reverse", ->
      ensure 'f c', cursor: [0, 2]
      ensure ';',   cursor: [0, 5]
      ensure ',',   cursor: [0, 2]

    it "alternate repeat F in same direction and reverse", ->
      set           cursor: [0, 10]
      ensure 'F c', cursor: [0, 8]
      ensure ';',   cursor: [0, 5]
      ensure ',',   cursor: [0, 8]

    it "repeat t in same direction", ->
      ensure 't c', cursor: [0, 1]
      ensure ';',   cursor: [0, 4]

    it "repeat T in same direction", ->
      set           cursor: [0, 10]
      ensure 'T c', cursor: [0, 9]
      ensure ';',   cursor: [0, 6]

    it "repeat t in opposite direction first, and then reverse", ->
      set           cursor: [0, 3]
      ensure 't c', cursor: [0, 4]
      ensure ',',   cursor: [0, 3]
      ensure ';',   cursor: [0, 4]

    it "repeat T in opposite direction first, and then reverse", ->
      set           cursor: [0, 4]
      ensure 'T c', cursor: [0, 3]
      ensure ',',   cursor: [0, 4]
      ensure ';',   cursor: [0, 3]

    it "repeat with count in same direction", ->
      set           cursor: [0, 0]
      ensure 'f c', cursor: [0, 2]
      ensure '2 ;', cursor: [0, 8]

    it "repeat with count in reverse direction", ->
      set           cursor: [0, 6]
      ensure 'f c', cursor: [0, 8]
      ensure '2 ,', cursor: [0, 2]

  describe "last find/till is repeatable on other editor", ->
    [other, otherEditor, pane] = []
    beforeEach ->
      getVimState (otherVimState, _other) ->
        set
          text: "a baz bar\n"
          cursor: [0, 0]

        other = _other
        other.set
          text: "foo bar baz",
          cursor: [0, 0]
        otherEditor = otherVimState.editor
        # jasmine.attachToDOM(otherEditor.element)

        pane = atom.workspace.getActivePane()
        pane.activateItem(editor)

    it "shares the most recent find/till command with other editors", ->
      ensure 'f b', cursor: [0, 2]
      other.ensure null, cursor: [0, 0]

      # replay same find in the other editor
      pane.activateItem(otherEditor)
      other.ensure ';'
      ensure null, cursor: [0, 2]
      other.ensure null, cursor: [0, 4]

      # do a till in the other editor
      other.ensure 't r'
      ensure null, cursor: [0, 2]
      other.ensure null, cursor: [0, 5]

      # and replay in the normal editor
      pane.activateItem(editor)
      ensure ';', cursor: [0, 7]
      other.ensure null, cursor: [0, 5]

    it "is still repeatable after original editor was destroyed", ->
      ensure 'f b', cursor: [0, 2]
      other.ensure null, cursor: [0, 0]

      pane.activateItem(otherEditor)
      editor.destroy()
      expect(editor.isAlive()).toBe(false)
      other.ensure ';', cursor: [0, 4]
      other.ensure ';', cursor: [0, 8]
      other.ensure ',', cursor: [0, 4]

  describe "vmp unique feature of `f` family", ->
    describe "ignoreCaseForFind", ->
      beforeEach ->
        settings.set("ignoreCaseForFind", true)

      it "ignore case to find", ->
        set           textC: "|    A    ab    a    Ab    a"
        ensure "f a", textC: "    |A    ab    a    Ab    a"
        ensure ";",   textC: "    A    |ab    a    Ab    a"
        ensure ";",   textC: "    A    ab    |a    Ab    a"
        ensure ";",   textC: "    A    ab    a    |Ab    a"

    describe "useSmartcaseForFind", ->
      beforeEach ->
        settings.set("useSmartcaseForFind", true)

      it "ignore case when input is lower char", ->
        set           textC: "|    A    ab    a    Ab    a"
        ensure "f a", textC: "    |A    ab    a    Ab    a"
        ensure ";",   textC: "    A    |ab    a    Ab    a"
        ensure ";",   textC: "    A    ab    |a    Ab    a"
        ensure ";",   textC: "    A    ab    a    |Ab    a"

      it "find case-sensitively when input is lager char", ->
        set           textC: "|    A    ab    a    Ab    a"
        ensure "f A", textC: "    |A    ab    a    Ab    a"
        ensure "f A", textC: "    A    ab    a    |Ab    a"
        ensure ",",   textC: "    |A    ab    a    Ab    a"
        ensure ";",   textC: "    A    ab    a    |Ab    a"

    describe "reuseFindForRepeatFind", ->
      beforeEach ->
        settings.set("reuseFindForRepeatFind", true)

      it "can reuse f and t as ;, F and T as ',' respectively", ->
        set textC: "|    A    ab    a    Ab    a"
        ensure "f a", textC: "    A    |ab    a    Ab    a"
        ensure "f", textC: "    A    ab    |a    Ab    a"
        ensure "f", textC: "    A    ab    a    Ab    |a"
        ensure "F", textC: "    A    ab    |a    Ab    a"
        ensure "F", textC: "    A    |ab    a    Ab    a"
        ensure "t", textC: "    A    ab   | a    Ab    a"
        ensure "t", textC: "    A    ab    a    Ab   | a"
        ensure "T", textC: "    A    ab    a|    Ab    a"
        ensure "T", textC: "    A    a|b    a    Ab    a"

      it "behave as normal f if no successful previous find was exists", ->
        set                textC: "  |  A    ab    a    Ab    a"
        ensure "f escape", textC: "  |  A    ab    a    Ab    a"
        expect(vimState.globalState.get("currentFind")).toBeNull()
        ensure "f a",      textC: "    A    |ab    a    Ab    a"
        expect(vimState.globalState.get("currentFind")).toBeTruthy()

    describe "findAcrossLines", ->
      beforeEach ->
        settings.set("findAcrossLines", true)

      it "searches across multiple lines", ->
        set           textC: "|0:    a    a\n1:    a    a\n2:    a    a\n"
        ensure "f a", textC: "0:    |a    a\n1:    a    a\n2:    a    a\n"
        ensure ";",   textC: "0:    a    |a\n1:    a    a\n2:    a    a\n"
        ensure ";",   textC: "0:    a    a\n1:    |a    a\n2:    a    a\n"
        ensure ";",   textC: "0:    a    a\n1:    a    |a\n2:    a    a\n"
        ensure ";",   textC: "0:    a    a\n1:    a    a\n2:    |a    a\n"
        ensure "F a", textC: "0:    a    a\n1:    a    |a\n2:    a    a\n"
        ensure "t a", textC: "0:    a    a\n1:    a    a\n2:   | a    a\n"
        ensure "T a", textC: "0:    a    a\n1:    a    |a\n2:    a    a\n"
        ensure "T a", textC: "0:    a    a\n1:    a|    a\n2:    a    a\n"

    describe "find-next/previous-pre-confirmed", ->
      beforeEach ->
        settings.set("findCharsMax", 10)
        # To pass hlFind logic it require "visible" screen range.
        jasmine.attachToDOM(atom.workspace.getElement())

      describe "can find one or two char", ->
        it "adjust to next-pre-confirmed", ->
          set                 textC: "|    a    ab    a    cd    a"
          ensure "f a"
          element = vimState.inputEditor.element
          dispatch(element, "vim-mode-plus:find-next-pre-confirmed")
          dispatch(element, "vim-mode-plus:find-next-pre-confirmed")
          ensure "enter",     textC: "    a    ab    |a    cd    a"

        it "adjust to previous-pre-confirmed", ->
          set                   textC: "|    a    ab    a    cd    a"
          ensure "3 f a enter", textC: "    a    ab    |a    cd    a"
          set                   textC: "|    a    ab    a    cd    a"
          ensure "3 f a"
          element = vimState.inputEditor.element
          dispatch(element, "vim-mode-plus:find-previous-pre-confirmed")
          dispatch(element, "vim-mode-plus:find-previous-pre-confirmed")
          ensure "enter",     textC: "    |a    ab    a    cd    a"

        it "is useful to skip earlier spot interactivelly", ->
          set  textC: 'text = "this is |\"example\" of use case"'
          ensure 'c t "'
          element = vimState.inputEditor.element
          dispatch(element, "vim-mode-plus:find-next-pre-confirmed") # tab
          dispatch(element, "vim-mode-plus:find-next-pre-confirmed") # tab
          ensure "enter", textC: 'text = "this is |"', mode: "insert"

    describe "findCharsMax", ->
      beforeEach ->
        # To pass hlFind logic it require "visible" screen range.
        jasmine.attachToDOM(atom.workspace.getElement())

      describe "with 2 length", ->
        beforeEach ->
          settings.set("findCharsMax", 2)

        describe "can find one or two char", ->
          it "can find by two char", ->
            set             textC: "|    a    ab    a    cd    a"
            ensure "f a b", textC: "    a    |ab    a    cd    a"
            ensure "f c d", textC: "    a    ab    a    |cd    a"

          it "can find by one-char by confirming explicitly", ->
            set                 textC: "|    a    ab    a    cd    a"
            ensure "f a enter", textC: "    |a    ab    a    cd    a"
            ensure "f c enter", textC: "    a    ab    a    |cd    a"

      describe "with 3 length", ->
        beforeEach ->
          settings.set("findCharsMax", 3)

        describe "can find 3 at maximum", ->
          it "can find by one or two or three char", ->
            set                   textC: "|    a    ab    a    cd    efg"
            ensure "f a b enter", textC: "    a    |ab    a    cd    efg"
            ensure "f a enter",   textC: "    a    ab    |a    cd    efg"
            ensure "f c d enter", textC: "    a    ab    a    |cd    efg"
            ensure "f e f g",     textC: "    a    ab    a    cd    |efg"

      describe "autoConfirmTimeout", ->
        beforeEach ->
          settings.set("findCharsMax", 2)
          settings.set("findConfirmByTimeout", 500)

        it "auto-confirm single-char input on timeout", ->
          set             textC: "|    a    ab    a    cd    a"

          ensure "f a",   textC: "|    a    ab    a    cd    a"
          advanceClock(500)
          ensure null,    textC: "    |a    ab    a    cd    a"

          ensure "f c d", textC: "    a    ab    a    |cd    a"

          ensure "f a",   textC: "    a    ab    a    |cd    a"
          advanceClock(500)
          ensure null,    textC: "    a    ab    a    cd    |a"

          ensure "F b",   textC: "    a    ab    a    cd    |a"
          advanceClock(500)
          ensure null,    textC: "    a    a|b    a    cd    a"
