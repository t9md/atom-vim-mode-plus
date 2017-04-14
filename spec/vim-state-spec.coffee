_ = require 'underscore-plus'
{getVimState, TextData, withMockPlatform} = require './spec-helper'
settings = require '../lib/settings'

describe "VimState", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim

  describe "initialization", ->
    it "puts the editor in normal-mode initially by default", ->
      ensure mode: 'normal'

    it "puts the editor in insert-mode if startInInsertMode is true", ->
      settings.set 'startInInsertMode', true
      getVimState (state, vim) ->
        vim.ensure mode: 'insert'

  describe "::destroy", ->
    it "re-enables text input on the editor", ->
      expect(editorElement.component.isInputEnabled()).toBeFalsy()
      vimState.destroy()
      expect(editorElement.component.isInputEnabled()).toBeTruthy()

    it "removes the mode classes from the editor", ->
      ensure mode: 'normal'
      vimState.destroy()
      expect(editorElement.classList.contains("normal-mode")).toBeFalsy()

    it "is a noop when the editor is already destroyed", ->
      editorElement.getModel().destroy()
      vimState.destroy()

  describe "normal-mode", ->
    describe "when entering an insertable character", ->
      beforeEach ->
        keystroke '\\'

      it "stops propagation", ->
        ensure text: ''

    describe "when entering an operator", ->
      beforeEach ->
        keystroke 'd'

      describe "with an operator that can't be composed", ->
        beforeEach ->
          keystroke 'x'

        it "clears the operator stack", ->
          expect(vimState.operationStack.isEmpty()).toBe(true)

      describe "the escape keybinding", ->
        beforeEach ->
          keystroke 'escape'

        it "clears the operator stack", ->
          expect(vimState.operationStack.isEmpty()).toBe(true)

      describe "the ctrl-c keybinding", ->
        beforeEach ->
          keystroke 'ctrl-c'

        it "clears the operator stack", ->
          expect(vimState.operationStack.isEmpty()).toBe(true)

    describe "the escape keybinding", ->
      it "clears any extra cursors", ->
        set
          text: "one-two-three"
          addCursor: [0, 3]
        ensure numCursors: 2
        ensure 'escape', numCursors: 1

    describe "the v keybinding", ->
      beforeEach ->
        set
          text: """
            abc
            """
          cursor: [0, 0]
        keystroke 'v'

      it "puts the editor into visual characterwise mode", ->
        ensure
          mode: ['visual', 'characterwise']

    describe "the V keybinding", ->
      beforeEach ->
        set
          text: "012345\nabcdef"
          cursor: [0, 0]

      it "puts the editor into visual linewise mode", ->
        ensure 'V', mode: ['visual', 'linewise']

      it "selects the current line", ->
        ensure 'V',
          selectedText: '012345\n'

    describe "the ctrl-v keybinding", ->
      it "puts the editor into visual blockwise mode", ->
        set text: "012345\n\nabcdef", cursor: [0, 0]
        ensure 'ctrl-v', mode: ['visual', 'blockwise']

    describe "selecting text", ->
      beforeEach ->
        spyOn(_._, "now").andCallFake -> window.now
        set text: "abc def", cursor: [0, 0]

      it "puts the editor into visual mode", ->
        ensure mode: 'normal'

        advanceClock(200)
        atom.commands.dispatch(editorElement, "core:select-right")
        ensure
          mode: ['visual', 'characterwise']
          selectedBufferRange: [[0, 0], [0, 1]]

      it "handles the editor being destroyed shortly after selecting text", ->
        set selectedBufferRange: [[0, 0], [0, 3]]
        editor.destroy()
        vimState.destroy()
        advanceClock(100)

      it 'handles native selection such as core:select-all', ->
        atom.commands.dispatch(editorElement, 'core:select-all')
        ensure selectedBufferRange: [[0, 0], [0, 7]]

    describe "the i keybinding", ->
      it "puts the editor into insert mode", ->
        ensure 'i', mode: 'insert'

    describe "the R keybinding", ->
      it "puts the editor into replace mode", ->
        ensure 'R', mode: ['insert', 'replace']

    describe "with content", ->
      beforeEach ->
        set text: "012345\n\nabcdef", cursor: [0, 0]

      describe "on a line with content", ->
        it "[Changed] won't adjust cursor position if outer command place the cursor on end of line('\\n') character", ->
          ensure mode: 'normal'
          atom.commands.dispatch(editorElement, "editor:move-to-end-of-line")
          ensure cursor: [0, 6]

      describe "on an empty line", ->
        it "allows the cursor to be placed on the \n character", ->
          set cursor: [1, 0]
          ensure cursor: [1, 0]

    describe 'with character-input operations', ->
      beforeEach ->
        set text: '012345\nabcdef'

      it 'properly clears the operations', ->

        ensure 'd', mode: 'operator-pending'
        expect(vimState.operationStack.isEmpty()).toBe(false)
        ensure 'r', mode: 'normal'
        expect(vimState.operationStack.isEmpty()).toBe(true)

        ensure 'd', mode: 'operator-pending'
        expect(vimState.operationStack.isEmpty()).toBe(false)
        ensure 'escape', mode: 'normal', text: '012345\nabcdef'
        expect(vimState.operationStack.isEmpty()).toBe(true)

  describe "activate-normal-mode-once command", ->
    beforeEach ->
      set
        text: """
        0 23456
        1 23456
        """
        cursor: [0, 2]
      ensure 'i', mode: 'insert', cursor: [0, 2]

    it "activate normal mode without moving cursors left, then back to insert-mode once some command executed", ->
      ensure 'ctrl-o', cursor: [0, 2], mode: 'normal'
      ensure 'l', cursor: [0, 3], mode: 'insert'

  describe "insert-mode", ->
    beforeEach -> keystroke 'i'

    describe "with content", ->
      beforeEach ->
        set text: "012345\n\nabcdef"

      describe "when cursor is in the middle of the line", ->
        it "moves the cursor to the left when exiting insert mode", ->
          set cursor: [0, 3]
          ensure 'escape', cursor: [0, 2]

      describe "when cursor is at the beginning of line", ->
        it "leaves the cursor at the beginning of line", ->
          set cursor: [1, 0]
          ensure 'escape', cursor: [1, 0]

      describe "on a line with content", ->
        it "allows the cursor to be placed on the \n character", ->
          set cursor: [0, 6]
          ensure cursor: [0, 6]

    it "puts the editor into normal mode when <escape> is pressed", ->
      escape 'escape',
        mode: 'normal'

    it "puts the editor into normal mode when <ctrl-c> is pressed", ->
      withMockPlatform editorElement, 'platform-darwin' , ->
        ensure 'ctrl-c', mode: 'normal'

    describe "clearMultipleCursorsOnEscapeInsertMode setting", ->
      beforeEach ->
        set
          text: 'abc'
          cursor: [[0, 1], [0, 2]]

      describe "when enabled, clear multiple cursors on escaping insert-mode", ->
        beforeEach ->
          settings.set('clearMultipleCursorsOnEscapeInsertMode', true)
        it "clear multiple cursors by respecting last cursor's position", ->
          ensure 'escape', mode: 'normal', numCursors: 1, cursor: [0, 1]

        it "clear multiple cursors by respecting last cursor's position", ->
          set cursor: [[0, 2], [0, 1]]
          ensure 'escape', mode: 'normal', numCursors: 1, cursor: [0, 0]

      describe "when disabled", ->
        beforeEach ->
          settings.set('clearMultipleCursorsOnEscapeInsertMode', false)
        it "keep multiple cursors", ->
          ensure 'escape', mode: 'normal', numCursors: 2, cursor: [[0, 0], [0, 1]]

    describe "automaticallyEscapeInsertModeOnActivePaneItemChange setting", ->
      [otherVim, otherEditor, pane] = []

      beforeEach ->
        getVimState (otherVimState, _other) ->
          otherVim = _other
          otherEditor = otherVimState.editor

        runs ->
          pane = atom.workspace.getActivePane()
          pane.activateItem(editor)

          set textC: "|editor-1"
          otherVim.set textC: "|editor-2"

          ensure 'i', mode: 'insert'
          otherVim.ensure 'i', mode: 'insert'
          expect(pane.getActiveItem()).toBe(editor)

      describe "default behavior", ->
        it "remain in insert-mode on paneItem change by default", ->

          pane.activateItem(otherEditor)
          expect(pane.getActiveItem()).toBe(otherEditor)

          ensure mode: 'insert'
          otherVim.ensure mode: 'insert'

      describe "automaticallyEscapeInsertModeOnActivePaneItemChange = true", ->
        beforeEach ->
          settings.set('automaticallyEscapeInsertModeOnActivePaneItemChange', true)

        it "return to escape mode for all vimEditors", ->
          pane.activateItem(otherEditor)
          expect(pane.getActiveItem()).toBe(otherEditor)
          ensure mode: 'normal'
          otherVim.ensure mode: 'normal'

  describe "replace-mode", ->
    describe "with content", ->
      beforeEach -> set text: "012345\n\nabcdef"

      describe "when cursor is in the middle of the line", ->
        it "moves the cursor to the left when exiting replace mode", ->
          set cursor: [0, 3]
          ensure 'R escape', cursor: [0, 2]

      describe "when cursor is at the beginning of line", ->
        beforeEach ->

        it "leaves the cursor at the beginning of line", ->
          set cursor: [1, 0]
          ensure 'R escape', cursor: [1, 0]

      describe "on a line with content", ->
        it "allows the cursor to be placed on the \n character", ->
          keystroke 'R'
          set cursor: [0, 6]
          ensure cursor: [0, 6]

    it "puts the editor into normal mode when <escape> is pressed", ->
      ensure 'R escape',
        mode: 'normal'

    it "puts the editor into normal mode when <ctrl-c> is pressed", ->
      withMockPlatform editorElement, 'platform-darwin' , ->
        ensure 'R ctrl-c', mode: 'normal'

  describe "visual-mode", ->
    beforeEach ->
      set
        text: """
        one two three
        """
        cursor: [0, 4]
      keystroke 'v'

    it "selects the character under the cursor", ->
      ensure
        selectedBufferRange: [[0, 4], [0, 5]]
        selectedText: 't'

    it "puts the editor into normal mode when <escape> is pressed", ->
      ensure 'escape',
        cursor: [0, 4]
        mode: 'normal'

    it "puts the editor into normal mode when <escape> is pressed on selection is reversed", ->
      ensure selectedText: 't'
      ensure 'h h',
        selectedText: 'e t'
        selectionIsReversed: true
      ensure 'escape',
        mode: 'normal'
        cursor: [0, 2]

    describe "motions", ->
      it "transforms the selection", ->
        ensure 'w', selectedText: 'two t'

      it "always leaves the initially selected character selected", ->
        ensure 'h', selectedText: ' t'
        ensure 'l', selectedText: 't'
        ensure 'l', selectedText: 'tw'

    describe "operators", ->
      it "operate on the current selection", ->
        set
          text: "012345\n\nabcdef"
          cursor: [0, 0]
        ensure 'V d', text: "\nabcdef"

    describe "returning to normal-mode", ->
      it "operate on the current selection", ->
        set text: "012345\n\nabcdef"
        ensure 'V escape', selectedText: ''

    describe "the o keybinding", ->
      it "reversed each selection", ->
        set addCursor: [0, 12]
        ensure 'i w',
          selectedText: ["two", "three"]
          selectionIsReversed: false
        ensure 'o',
          selectionIsReversed: true

      xit "harmonizes selection directions", ->
        set cursor: [0, 0]
        keystroke 'e e'
        set addCursor: [0, Infinity]
        ensure 'h h',
          selectedBufferRange: [
            [[0, 0], [0, 5]],
            [[0, 11], [0, 13]]
          ]
          cursor: [
            [0, 5]
            [0, 11]
          ]

        ensure 'o',
          selectedBufferRange: [
            [[0, 0], [0, 5]],
            [[0, 11], [0, 13]]
          ]
          cursor: [
            [0, 5]
            [0, 13]
          ]

    describe "activate visualmode within visualmode", ->
      cursorPosition = null
      beforeEach ->
        cursorPosition = [0, 4]
        set
          text: """
            line one
            line two
            line three\n
            """
          cursor: cursorPosition

        ensure 'escape', mode: 'normal'

      describe "restore characterwise from linewise", ->
        beforeEach ->
          ensure 'v', mode: ['visual', 'characterwise']
          ensure '2 j V',
            selectedText: """
              line one
              line two
              line three\n
              """
            mode: ['visual', 'linewise']
            selectionIsReversed: false
          ensure 'o',
            selectedText: """
              line one
              line two
              line three\n
              """
            mode: ['visual', 'linewise']
            selectionIsReversed: true

        it "v after o", ->
          ensure 'v',
            selectedText: " one\nline two\nline "
            mode: ['visual', 'characterwise']
            selectionIsReversed: true
        it "escape after o", ->
          ensure 'escape',
            cursor: [0, 4]
            mode: 'normal'

      describe "activateVisualMode with same type puts the editor into normal mode", ->
        describe "characterwise: vv", ->
          it "activating twice make editor return to normal mode ", ->
            ensure 'v', mode: ['visual', 'characterwise']
            ensure 'v', mode: 'normal', cursor: cursorPosition

        describe "linewise: VV", ->
          it "activating twice make editor return to normal mode ", ->
            ensure 'V', mode: ['visual', 'linewise']
            ensure 'V', mode: 'normal', cursor: cursorPosition

        describe "blockwise: ctrl-v twice", ->
          it "activating twice make editor return to normal mode ", ->
            ensure 'ctrl-v', mode: ['visual', 'blockwise']
            ensure 'ctrl-v', mode: 'normal', cursor: cursorPosition

      describe "change submode within visualmode", ->
        beforeEach ->
          set
            text: "line one\nline two\nline three\n"
            cursor: [[0, 5], [2, 5]]

        it "can change submode within visual mode", ->
          ensure 'v'        , mode: ['visual', 'characterwise']
          ensure 'V'        , mode: ['visual', 'linewise']
          ensure 'ctrl-v', mode: ['visual', 'blockwise']
          ensure 'v'        , mode: ['visual', 'characterwise']

        it "recover original range when shift from linewise to characterwise", ->
          ensure 'v i w', selectedText: ['one', 'three']
          ensure 'V', selectedText: ["line one\n", "line three\n"]
          ensure 'v', selectedText: ["one", "three"]

      describe "keep goalColum when submode change in visual-mode", ->
        text = null
        beforeEach ->
          text = new TextData """
          0_34567890ABCDEF
          1_34567890
          2_34567
          3_34567890A
          4_34567890ABCDEF\n
          """
          set
            text: text.getRaw()
            cursor: [0, 0]

        it "keep goalColumn when shift linewise to characterwise", ->
          ensure 'V', selectedText: text.getLines([0]), propertyHead: [0, 0], mode: ['visual', 'linewise']
          ensure '$', selectedText: text.getLines([0]), propertyHead: [0, 16], mode: ['visual', 'linewise']
          ensure 'j', selectedText: text.getLines([0, 1]), propertyHead: [1, 10], mode: ['visual', 'linewise']
          ensure 'j', selectedText: text.getLines([0..2]), propertyHead: [2, 7], mode: ['visual', 'linewise']
          ensure 'v', selectedText: text.getLines([0..2]), propertyHead: [2, 7], mode: ['visual', 'characterwise']
          ensure 'j', selectedText: text.getLines([0..3]), propertyHead: [3, 11], mode: ['visual', 'characterwise']
          ensure 'v', cursor: [3, 10], mode: 'normal'
          ensure 'j', cursor: [4, 15], mode: 'normal'

    describe "deactivating visual mode", ->
      beforeEach ->
        ensure 'escape', mode: 'normal'
        set
          text: """
            line one
            line two
            line three\n
            """
          cursor: [0, 7]
      it "can put cursor at in visual char mode", ->
        ensure 'v', mode: ['visual', 'characterwise'], cursor: [0, 8]
      it "adjust cursor position 1 column left when deactivated", ->
        ensure 'v escape', mode: 'normal', cursor: [0, 7]
      it "can select new line in visual mode", ->
        ensure 'v', cursor: [0, 8], propertyHead: [0, 7]
        ensure 'l', cursor: [1, 0], propertyHead: [0, 8]
        ensure 'escape', mode: 'normal', cursor: [0, 7]

    describe "deactivating visual mode on blank line", ->
      beforeEach ->
        ensure 'escape', mode: 'normal'
        set
          text: """
            0: abc

            2: abc
            """
          cursor: [1, 0]
      it "v case-1", ->
        ensure 'v', mode: ['visual', 'characterwise'], cursor: [2, 0]
        ensure 'escape', mode: 'normal', cursor: [1, 0]
      it "v case-2 selection head is blank line", ->
        set cursor: [0, 1]
        ensure 'v j', mode: ['visual', 'characterwise'], cursor: [2, 0], selectedText: ": abc\n\n"
        ensure 'escape', mode: 'normal', cursor: [1, 0]
      it "V case-1", ->
        ensure 'V', mode: ['visual', 'linewise'], cursor: [2, 0]
        ensure 'escape', mode: 'normal', cursor: [1, 0]
      it "V case-2 selection head is blank line", ->
        set cursor: [0, 1]
        ensure 'V j', mode: ['visual', 'linewise'], cursor: [2, 0], selectedText: "0: abc\n\n"
        ensure 'escape', mode: 'normal', cursor: [1, 0]
      it "ctrl-v", ->
        ensure 'ctrl-v', mode: ['visual', 'blockwise'], selectedBufferRange: [[1, 0], [1, 0]]
        ensure 'escape', mode: 'normal', cursor: [1, 0]
      it "ctrl-v and move over empty line", ->
        ensure 'ctrl-v', mode: ['visual', 'blockwise'], selectedBufferRangeOrdered: [[1, 0], [1, 0]]
        ensure 'k', mode: ['visual', 'blockwise'], selectedBufferRangeOrdered: [[[0, 0], [0, 1]], [[1, 0], [1, 0]]]
        ensure 'j', mode: ['visual', 'blockwise'], selectedBufferRangeOrdered: [[1, 0], [1, 0]]
        ensure 'j', mode: ['visual', 'blockwise'], selectedBufferRangeOrdered: [[[1, 0], [1, 0]], [[2, 0], [2, 1]]]

  describe "marks", ->
    beforeEach -> set text: "text in line 1\ntext in line 2\ntext in line 3"

    it "basic marking functionality", ->
      set cursor: [1, 1]
      keystroke 'm t'
      set cursor: [2, 2]
      ensure '` t', cursor: [1, 1]

    it "real (tracking) marking functionality", ->
      set cursor: [2, 2]
      keystroke 'm q'
      set cursor: [1, 2]
      ensure 'o escape ` q', cursor: [3, 2]

    it "real (tracking) marking functionality", ->
      set cursor: [2, 2]
      keystroke 'm q'
      set cursor: [1, 2]
      ensure 'd d escape ` q', cursor: [1, 2]

  describe "is-narrowed attribute", ->
    ensureNormalModeState = ->
      ensure "escape",
        mode: 'normal'
        selectedText: ''
        selectionIsNarrowed: false
    beforeEach ->
      set
        text: """
        1:-----
        2:-----
        3:-----
        4:-----
        """
        cursor: [0, 0]

    describe "normal-mode", ->
      it "is not narrowed", ->
        ensure
          mode: ['normal']
          selectionIsNarrowed: false
    describe "visual-mode.characterwise", ->
      it "[single row] is narrowed", ->
        ensure 'v $',
          selectedText: '1:-----\n'
          mode: ['visual', 'characterwise']
          selectionIsNarrowed: false
        ensureNormalModeState()
      it "[multi-row] is narrowed", ->
        ensure 'v j',
          selectedText: """
          1:-----
          2
          """
          mode: ['visual', 'characterwise']
          selectionIsNarrowed: true
        ensureNormalModeState()
    describe "visual-mode.linewise", ->
      it "[single row] is narrowed", ->
        ensure 'V',
          selectedText: "1:-----\n"
          mode: ['visual', 'linewise']
          selectionIsNarrowed: false
        ensureNormalModeState()
      it "[multi-row] is narrowed", ->
        ensure 'V j',
          selectedText: """
          1:-----
          2:-----\n
          """
          mode: ['visual', 'linewise']
          selectionIsNarrowed: true
        ensureNormalModeState()
    describe "visual-mode.blockwise", ->
      it "[single row] is narrowed", ->
        ensure 'ctrl-v l',
          selectedText: "1:"
          mode: ['visual', 'blockwise']
          selectionIsNarrowed: false
        ensureNormalModeState()
      it "[multi-row] is narrowed", ->
        ensure 'ctrl-v l j',
          selectedText: ["1:", "2:"]
          mode: ['visual', 'blockwise']
          selectionIsNarrowed: true
        ensureNormalModeState()
