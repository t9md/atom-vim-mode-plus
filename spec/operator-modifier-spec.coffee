{getVimState, dispatch, TextData, getView, withMockPlatform, rawKeystroke} = require './spec-helper'
settings = require '../lib/settings'

describe "Operator modifier", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim

  afterEach ->
    vimState.resetNormalMode()

  describe "operator-modifier to force wise", ->
    beforeEach ->
      set
        text: """
        012345 789
        ABCDEF EFG
        """
    describe "operator-modifier-characterwise", ->
      describe "when target is linewise", ->
        it "operate characterwisely and exclusively", ->
          set cursor: [0, 1]
          ensure "d v j",
            text: """
            0BCDEF EFG
            """
      describe "when target is characterwise", ->
        it "operate inclusively for exclusive target", ->
          set cursor: [0, 9]
          ensure "d v b",
            cursor: [0, 6]
            text_: """
            012345_
            ABCDEF EFG
            """
        it "operate exclusively for inclusive target", ->
          set cursor: [0, 0]
          ensure "d v e",
            cursor: [0, 0]
            text: """
            5 789
            ABCDEF EFG
            """
    describe "operator-modifier-linewise", ->
      it "operate linewisely for characterwise target", ->
        set cursor: [0, 1]
        ensure ['d V /', search: 'DEF'],
          cursor: [0, 0]
          text: ""

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

    describe "select-occurrence", ->
      beforeEach ->
        set
          text: """
          ooo: xxx: ooo:

          |||: ooo: xxx: ooo: ooo: oooo:

          xxx: |||: ooo:

          """
      describe "what the cursor-word", ->
        describe "cursor is at normal word [by select-occurrence]", ->
          it "pick word but not pick partially matched one and re-use cached cursor-word on repeat", ->
            set cursor: [0, 0]
            ensure "g cmd-d o i p", selectedText: ['ooo', 'ooo']
            ensure "escape escape 2 j .", selectedText: ['ooo', 'ooo', 'ooo']
            ensure "escape escape 2 j .", selectedText: 'ooo'
        describe "cursor is at nonWordCharacters [by select-occurrence]", ->
          it "select that char only", ->
            set cursor: [0, 3]
            ensure "g cmd-d o i p", selectedText: [':', ':', ':']
            ensure "escape escape 2 j .", -> selectedText: [':', ':', ':', ':', ':']
            ensure "escape escape 2 j .", -> selectedText: [':', ':', ':']
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

    describe "[from visual.characterwise] select-occurrence then uppercase", ->
      it "pick cursor-word from vC range and include word if start position of that word is in selecion", ->
        ensure "v 2 j cmd-d U",
          text: """
          OOO: xxx: OOO:
          |||: OOO: xxx: OOO:
          OOO: xxx: |||: xxx: ooo:
          xxx: |||: ooo: ooo:
          """
          numCursors: 5
    describe "[from visual.linewise] select-occurrence then uppercase", ->
      it "pick cursor-word from vL range", ->
        ensure "5 l V 2 j cmd-d U",
          text: """
          ooo: XXX: ooo:
          |||: ooo: XXX: ooo:
          ooo: XXX: |||: XXX: ooo:
          xxx: |||: ooo: ooo:
          """
          numCursors: 4
    describe "[from visual.blockwise] select-occurrence then uppercase", ->
      it "pick cursor-word from vB range", ->
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

  describe "from incremental search", ->
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
      it "select occurrence by pattern in search-input", ->
        keystroke '/'
        searchEditor.insertText('\\d{3,4}')
        withMockPlatform searchEditorElement, 'platform-darwin' , ->
          rawKeystroke 'cmd-d', document.activeElement
          ensure 'i e',
            selectedText: ['0000', '3333', '444']
            mode: ['visual', 'characterwise']

      it "change occurrence by pattern in search-input", ->
        keystroke '/'
        searchEditor.insertText('^\\w+:')
        withMockPlatform searchEditorElement, 'platform-darwin' , ->
          rawKeystroke 'cmd-c', document.activeElement
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
              1: ooO: 22: OOO:
              ooo: xxx: |||: xxx: 3333:
              444: |||: ooo: ooo:
              """
