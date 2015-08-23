helpers = require './spec-helper'
_ = require 'underscore-plus'

fdescribe "Motions", ->
  [editor, editorElement, vimState] = []

  beforeEach ->
    vimMode = atom.packages.loadPackage('vim-mode')
    vimMode.activateResources()

    helpers.getEditorElement (element) ->
      editorElement = element
      editor = editorElement.getModel()
      vimState = editorElement.vimState
      vimState.activateNormalMode()
      vimState.resetNormalMode()

  keydown = (key, options={}) ->
    options.element ?= editorElement
    helpers.keydown(key, options)

  keystroke = (keys) ->
    for key in keys.split('')
      if key.match(/[A-Z]/)
        keydown(key, shift: true)
      else
        keydown(key)

  normalModeInputKeydown = (key, opts = {}) ->
    theEditor = opts.editor or editor
    theEditor.normalModeInputView.editorElement.getModel().setText(key)

  submitNormalModeInputText = (text) ->
    inputEditor = editor.normalModeInputView.editorElement
    inputEditor.getModel().setText(text)
    atom.commands.dispatch(inputEditor, "core:confirm")

  set = (options={}) ->
    if options.keystroke?
      keystroke(options.keystroke)
    if options.text?
      editor.setText(options.text)
    if options.cursor?
      editor.setCursorScreenPosition options.cursor
    if options.addCursor?
      editor.addCursorAtBufferPosition options.addCursor
    if options.register?
      vimState.register.set '"', text: options.register


  selectedScreenRange = ->
    expect editor.getSelectedScreenRange()
  selectedScreenRanges = ->
    expect editor.getSelectedScreenRanges()
  selectedBufferRange = ->
    expect editor.getSelectedBufferRange()
  selectedBufferRanges = ->
    expect editor.getSelectedBufferRanges()

  ensure = (_keystroke, options={}) ->
    unless _.isEmpty(_keystroke)
      keystroke(_keystroke)
    if options.text?
      expect(editor.getText()).toBe options.text
    if options.cursor?
      expect(editor.getCursorScreenPosition()).toEqual options.cursor
    if options.register?
      expect(vimState.register.get('"').text).toBe options.register
    if options.selectedText?
      expect(editor.getSelectedText()).toBe options.selectedText

    if options.selectedBufferRange?
      selectedBufferRange().toEqual options.selectedBufferRange
    if options.selectedBufferRanges?
      selectedBufferRanges().toEqual options.selectedBufferRanges

    if options.selectedScreenRange?
      selectedScreenRange().toEqual options.selectedScreenRange
    if options.selectedScreenRanges?
      selectedScreenRanges().toEqual options.selectedScreenRanges

  describe "simple motions", ->
    beforeEach ->
      set
        text: "12345\nabcd\nABCDE"
        cursor: [1, 1]

    describe "the h keybinding", ->
      describe "as a motion", ->
        it "moves the cursor left, but not to the previous line", ->
          ensure 'h', cursor: [1, 0]
          ensure 'h', cursor: [1, 0]

        it "moves the cursor to the previous line if wrapLeftRightMotion is true", ->
          atom.config.set('vim-mode.wrapLeftRightMotion', true)
          ensure 'hh', cursor: [0, 4]

      describe "as a selection", ->
        it "selects the character to the left", ->
          ensure 'yh',
            register: 'a'
            cursor: [1, 0]

    describe "the j keybinding", ->
      it "moves the cursor down, but not to the end of the last line", ->
        ensure 'j', cursor: [2, 1]
        ensure 'j', cursor: [2, 1]

      it "moves the cursor to the end of the line, not past it", ->
        set
          cursor: [0, 4]
        ensure 'j',
          cursor: [1, 3]

      it "remembers the position it column it was in after moving to shorter line", ->
        set cursor: [0, 4]
        ensure 'j', cursor: [1, 3]
        ensure 'j', cursor: [2, 4]

      describe "when visual mode", ->
        beforeEach ->
          ensure 'v', cursor: [1, 2]

        it "moves the cursor down", ->
          ensure 'j', cursor: [2, 2]

        it "doesn't go over after the last line", ->
          ensure 'j', cursor: [2, 2]

        it "selects the text while moving", ->
          ensure 'j',
            selectedText: "bcd\nAB"

    describe "the k keybinding", ->
      it "moves the cursor up, but not to the beginning of the first line", ->
        ensure 'k', cursor: [0, 1]
        ensure 'k', cursor: [0, 1]

    describe "the l keybinding", ->
      beforeEach ->
        set cursor: [1, 2]

      it "moves the cursor right, but not to the next line", ->
        ensure 'l', cursor: [1, 3]
        ensure 'l', cursor: [1, 3]

      it "moves the cursor to the next line if wrapLeftRightMotion is true", ->
        atom.config.set('vim-mode.wrapLeftRightMotion', true)
        ensure 'll', cursor: [2, 0]

      describe "on a blank line", ->
        it "doesn't move the cursor", ->
          set
            text: "\n\n\n"
            cursor: [1, 0]
          ensure 'l',
            cursor: [1, 0]

  describe "the w keybinding", ->
    beforeEach ->
      set text: "ab cde1+- \n xyz\n\nzip"

    describe "as a motion", ->
      beforeEach ->
        set cursor: [0, 0]

      it "moves the cursor to the beginning of the next word", ->
        ensure 'w', cursor: [0, 3]
        ensure 'w', cursor: [0, 7]
        ensure 'w', cursor: [1, 1]
        ensure 'w', cursor: [2, 0]
        ensure 'w', cursor: [3, 0]
        ensure 'w', cursor: [3, 2]
        # When the cursor gets to the EOF, it should stay there.
        ensure 'w', cursor: [3, 2]

      it "moves the cursor to the end of the word if last word in file", ->
        set
          text: 'abc'
          cursor: [0, 0]
        ensure 'w',
          cursor: [0, 2]

    describe "as a selection", ->
      describe "within a word", ->
        it "selects to the end of the word", ->
          set
            cursor: [0, 0]
          ensure 'yw',
            register: 'ab '

      describe "between words", ->
        it "selects the whitespace", ->
          set cursor: [0, 2]
          ensure 'yw', register: ' '

  describe "the W keybinding", ->
    beforeEach ->
      set text: "cde1+- ab \n xyz\n\nzip"

    describe "as a motion", ->
      beforeEach ->
        set cursor: [0, 0]

      it "moves the cursor to the beginning of the next word", ->
        ensure 'W', cursor: [0, 7]
        ensure 'W', cursor: [1, 1]
        ensure 'W', cursor: [2, 0]
        ensure 'W', cursor: [3, 0]

    describe "as a selection", ->
      describe "within a word", ->
        it "selects to the end of the whole word", ->
          set cursor: [0, 0]
          ensure 'yW', register: 'cde1+- '

      it "continues past blank lines", ->
        set
          cursor: [2, 0]
        ensure 'dW',
          text: "cde1+- ab \n xyz\nzip"
          register: "\n"

      it "doesn't go past the end of the file", ->
        set
          cursor: [3, 0]
        ensure 'dW',
          text: "cde1+- ab \n xyz\n\n"
          register: 'zip'

  describe "the e keybinding", ->
    beforeEach ->
      set text: "ab cde1+- \n xyz\n\nzip"

    describe "as a motion", ->
      beforeEach ->
        set cursor: [0, 0]

      it "moves the cursor to the end of the current word", ->
        ensure 'e', cursor: [0, 1]
        ensure 'e', cursor: [0, 6]
        ensure 'e', cursor: [0, 8]
        ensure 'e', cursor: [1, 3]
        ensure 'e', cursor: [3, 2]

    describe "as selection", ->
      describe "within a word", ->
        it "selects to the end of the current word", ->
          set cursor: [0, 0]
          ensure 'ye', register: 'ab'

      describe "between words", ->
        it "selects to the end of the next word", ->
          set cursor: [0, 2]
          ensure 'ye', register: ' cde1'

  describe "the E keybinding", ->
    beforeEach ->
      set text: "ab  cde1+- \n xyz \n\nzip\n"

    describe "as a motion", ->
      beforeEach ->
        set cursor: [0, 0]

      it "moves the cursor to the end of the current word", ->
        ensure 'E', cursor: [0, 1]
        ensure 'E', cursor: [0, 9]
        ensure 'E', cursor: [1, 3]
        ensure 'E', cursor: [3, 2]
        ensure 'E', cursor: [4, 0]

    describe "as selection", ->
      describe "within a word", ->
        it "selects to the end of the current word", ->
          set cursor: [0, 0]
          ensure 'yE', register: 'ab'

      describe "between words", ->
        it "selects to the end of the next word", ->
          set cursor: [0, 2]
          ensure 'yE', register: '  cde1+-'

      describe "press more than once", ->
        it "selects to the end of the current word", ->
          set cursor: [0, 0]
          ensure 'vEEy', register: 'ab  cde1+-'

  describe "the } keybinding", ->
    beforeEach ->
      set
        text: "abcde\n\nfghij\nhijk\n  xyz  \n\nzip\n\n  \nthe end"
        cursor: [0, 0]

    describe "as a motion", ->
      it "moves the cursor to the end of the paragraph", ->
        ensure '}', cursor: [1, 0]
        ensure '}', cursor: [5, 0]
        ensure '}', cursor: [7, 0]
        ensure '}', cursor: [9, 6]

    describe "as a selection", ->
      it 'selects to the end of the current paragraph', ->
        ensure 'y}', register: "abcde\n"

  describe "the { keybinding", ->
    beforeEach ->
      set
        text: "abcde\n\nfghij\nhijk\n  xyz  \n\nzip\n\n  \nthe end"
        cursor: [9, 0]

    describe "as a motion", ->
      it "moves the cursor to the beginning of the paragraph", ->
        ensure '{', cursor: [7, 0]
        ensure '{', cursor: [5, 0]
        ensure '{', cursor: [1, 0]
        ensure '{', cursor: [0, 0]

    describe "as a selection", ->
      it 'selects to the beginning of the current paragraph', ->
        set cursor: [7, 0]
        ensure 'y{', register: "\nzip\n"

  describe "the b keybinding", ->
    beforeEach ->
      set text: " ab cde1+- \n xyz\n\nzip }\n last"

    describe "as a motion", ->
      beforeEach ->
        set cursor: [4, 1]

      it "moves the cursor to the beginning of the previous word", ->
        ensure 'b', cursor: [3, 4]
        ensure 'b', cursor: [3, 0]
        ensure 'b', cursor: [2, 0]
        ensure 'b', cursor: [1, 1]
        ensure 'b', cursor: [0, 8]
        ensure 'b', cursor: [0, 4]
        ensure 'b', cursor: [0, 1]

        # Go to start of the file, after moving past the first word
        ensure 'b', cursor: [0, 0]
        # Stay at the start of the file
        ensure 'b', cursor: [0, 0]

    describe "as a selection", ->
      describe "within a word", ->
        it "selects to the beginning of the current word", ->
          set
            cursor: [0, 2]
          ensure 'yb',
            register: 'a'
            cursor: [0, 1]

      describe "between words", ->
        it "selects to the beginning of the last word", ->
          set cursor: [0, 4]
          ensure 'yb',
            register: 'ab '
            cursor: [0, 1]

  describe "the B keybinding", ->
    beforeEach ->
      set text: "cde1+- ab \n\t xyz-123\n\n zip"

    describe "as a motion", ->
      beforeEach ->
        set cursor: [4, 1]

      it "moves the cursor to the beginning of the previous word", ->
        ensure 'B', cursor: [3, 1]
        ensure 'B', cursor: [2, 0]
        ensure 'B', cursor: [1, 3]
        ensure 'B', cursor: [0, 7]
        ensure 'B', cursor: [0, 0]

    describe "as a selection", ->
      it "selects to the beginning of the whole word", ->
        set cursor: [1, 10]
        ensure 'yB', register: 'xyz-12' # because cursor is on the `3`

      it "doesn't go past the beginning of the file", ->
        set
          cursor: [0, 0]
          register: 'abc'
        ensure 'yB',
          register: 'abc'

  describe "the ^ keybinding", ->
    beforeEach ->
      set text: "  abcde"

    describe "from the beginning of the line", ->
      beforeEach ->
        set cursor: [0, 0]

      describe "as a motion", ->
        it "moves the cursor to the first character of the line", ->
          ensure '^', cursor: [0, 2]

      describe "as a selection", ->
        it 'selects to the first character of the line', ->
          ensure 'd^',
            text: 'abcde'
            cursor: [0, 0]

    describe "from the first character of the line", ->
      beforeEach ->
        set cursor: [0, 2]

      describe "as a motion", ->
        it "stays put", ->
          ensure '^', cursor: [0, 2]

      describe "as a selection", ->
        it "does nothing", ->
          ensure 'd^',
            text: '  abcde'
            cursor: [0, 2]

    describe "from the middle of a word", ->
      beforeEach ->
        set cursor: [0, 4]

      describe "as a motion", ->
        it "moves the cursor to the first character of the line", ->
          ensure '^', cursor: [0, 2]

      describe "as a selection", ->
        beforeEach ->
          keydown('d')
          keydown('^')

        it 'selects to the first character of the line', ->
          ensure 'd^',
            text: '  cde'
            cursor: [0, 2]

  describe "the 0 keybinding", ->
    beforeEach ->
      set
        text: "  abcde"
        cursor: [0, 4]

    describe "as a motion", ->
      it "moves the cursor to the first column", ->
        ensure '0', cursor: [0, 0]

    describe "as a selection", ->
      it 'selects to the first column of the line', ->
        ensure 'd0',
          text: 'cde'
          cursor: [0, 0]

  describe "the $ keybinding", ->
    beforeEach ->
      set
        text: "  abcde\n\n1234567890"
        cursor: [0, 4]

    describe "as a motion from empty line", ->
      it "moves the cursor to the end of the line", ->
        set cursor: [1, 0]
        ensure '$', cursor: [1, 0]

    describe "as a motion", ->
      beforeEach -> keydown('$')

      # FIXME: See atom/vim-mode#2
      it "moves the cursor to the end of the line", ->
        ensure '$', cursor: [0, 6]

      it "should remain in the last column when moving down", ->
        ensure '$j', cursor: [1, 0]
        ensure 'j', cursor: [2, 9]

    describe "as a selection", ->
      it "selects to the beginning of the lines", ->
        ensure 'd$',
          text: "  ab\n\n1234567890"
          cursor: [0, 3]

  describe "the 0 keybinding", ->
    beforeEach ->
      set
        text: "  a\n"
        cursor: [0, 2]

    describe "as a motion", ->
      it "moves the cursor to the beginning of the line", ->
        ensure '0', cursor: [0, 0]

  describe "the - keybinding", ->
    beforeEach ->
      set text: "abcdefg\n  abc\n  abc\n"

    describe "from the middle of a line", ->
      beforeEach ->
        set cursor: [1, 3]

      describe "as a motion", ->
        it "moves the cursor to the last character of the previous line", ->
          ensure '-', cursor: [0, 0]

      describe "as a selection", ->
        it "deletes the current and previous line", ->
          ensure 'd-', text: "  abc\n"
          # commented out because the column is wrong due to a bug in `k`; re-enable when `k` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [0, 3]

    describe "from the first character of a line indented the same as the previous one", ->
      beforeEach ->
        set cursor: [2, 2]

      describe "as a motion", ->
        it "moves to the first character of the previous line (directly above)", ->
          ensure '-', cursor: [1, 2]

      describe "as a selection", ->
        it "selects to the first character of the previous line (directly above)", ->
          ensure 'd-', text: "abcdefg\n"
          # commented out because the column is wrong due to a bug in `k`; re-enable when `k` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    describe "from the beginning of a line preceded by an indented line", ->
      beforeEach ->
        set cursor: [2, 0]

      describe "as a motion", ->
        it "moves the cursor to the first character of the previous line", ->
          ensure '-', cursor: [1, 2]

      describe "as a selection", ->
        it "selects to the first character of the previous line", ->
          ensure 'd-', text: "abcdefg\n"
          # commented out because the column is wrong due to a bug in `k`; re-enable when `k` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    describe "with a count", ->
      beforeEach ->
        set
          text: "1\n2\n3\n4\n5\n6\n"
          cursor: [4, 0]

      describe "as a motion", ->
        it "moves the cursor to the first character of that many lines previous", ->
          ensure '3-', cursor: [1, 0]

      describe "as a selection", ->
        it "deletes the current line plus that many previous lines", ->
          ensure 'd3-',
            text: "1\n6\n"
            cursor: [1, 0]

  describe "the + keybinding", ->
    beforeEach ->
      set text: "  abc\n  abc\nabcdefg\n"

    describe "from the middle of a line", ->
      beforeEach ->
        set cursor: [1, 3]

      describe "as a motion", ->
        it "moves the cursor to the first character of the next line", ->
          ensure '+', cursor: [2, 0]

      describe "as a selection", ->
        it "deletes the current and next line", ->
          ensure 'd+', text: "  abc\n"
          # commented out because the column is wrong due to a bug in `j`; re-enable when `j` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [0, 3]

    describe "from the first character of a line indented the same as the next one", ->
      beforeEach -> set cursor: [0, 2]

      describe "as a motion", ->
        it "moves to the first character of the next line (directly below)", ->
          ensure '+', cursor: [1, 2]

      describe "as a selection", ->
        it "selects to the first character of the next line (directly below)", ->
          ensure 'd+', text: "abcdefg\n"
          # commented out because the column is wrong due to a bug in `j`; re-enable when `j` is fixed
          #expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    describe "from the beginning of a line followed by an indented line", ->
      beforeEach -> set cursor: [0, 0]

      describe "as a motion", ->
        it "moves the cursor to the first character of the next line", ->
          ensure '+', cursor: [1, 2]

      describe "as a selection", ->
        it "selects to the first character of the next line", ->
          ensure 'd+',
            text: "abcdefg\n"
            cursor: [0, 0]

    describe "with a count", ->
      beforeEach ->
        set
          text: "1\n2\n3\n4\n5\n6\n"
          cursor: [1, 0]

      describe "as a motion", ->
        it "moves the cursor to the first character of that many lines following", ->
          ensure '3+', cursor: [4, 0]

      describe "as a selection", ->
        it "deletes the current line plus that many following lines", ->
          ensure 'd3+',
            text: "1\n6\n"
            cursor: [1, 0]

  describe "the _ keybinding", ->
    beforeEach ->
      set text: "  abc\n  abc\nabcdefg\n"

    describe "from the middle of a line", ->
      beforeEach -> set cursor: [1, 3]

      describe "as a motion", ->
        it "moves the cursor to the first character of the current line", ->
          ensure '_', cursor: [1, 2]

      describe "as a selection", ->
        it "deletes the current line", ->
          ensure 'd_',
            text: "  abc\nabcdefg\n"
            cursor: [1, 0]

    describe "with a count", ->
      beforeEach ->
        set
          text: "1\n2\n3\n4\n5\n6\n"
          cursor: [1, 0]

      describe "as a motion", ->
        it "moves the cursor to the first character of that many lines following", ->
          ensure '3_', cursor: [3, 0]

      describe "as a selection", ->
        it "deletes the current line plus that many following lines", ->
          ensure 'd3_',
            text: "1\n5\n6\n"
            cursor: [1, 0]

  describe "the enter keybinding", ->
    keydownCodeForEnter = '\r' # 'enter' does not work
    startingText = "  abc\n  abc\nabcdefg\n"

    describe "from the middle of a line", ->
      startingCursorPosition = [1, 3]

      describe "as a motion", ->
        it "acts the same as the + keybinding", ->
          # do it with + and save the results
          editor.setText(startingText)
          editor.setCursorScreenPosition(startingCursorPosition)
          keydown('+')
          referenceCursorPosition = editor.getCursorScreenPosition()
          # do it again with enter and compare the results
          editor.setText(startingText)
          editor.setCursorScreenPosition(startingCursorPosition)
          keydown(keydownCodeForEnter)
          expect(editor.getCursorScreenPosition()).toEqual referenceCursorPosition

      describe "as a selection", ->
        it "acts the same as the + keybinding", ->
          # do it with + and save the results
          editor.setText(startingText)
          editor.setCursorScreenPosition(startingCursorPosition)
          keydown('d')
          keydown('+')
          referenceText = editor.getText()
          referenceCursorPosition = editor.getCursorScreenPosition()
          # do it again with enter and compare the results
          editor.setText(startingText)
          editor.setCursorScreenPosition(startingCursorPosition)
          keydown('d')
          keydown(keydownCodeForEnter)
          expect(editor.getText()).toEqual referenceText
          expect(editor.getCursorScreenPosition()).toEqual referenceCursorPosition

  describe "the gg keybinding", ->
    beforeEach ->
      editor.setText(" 1abc\n 2\n3\n")
      editor.setCursorScreenPosition([0, 2])

    describe "as a motion", ->
      describe "in normal mode", ->
        beforeEach ->
          keydown('g')
          keydown('g')

        it "moves the cursor to the beginning of the first line", ->
          expect(editor.getCursorScreenPosition()).toEqual [0, 0]

      describe "in linewise visual mode", ->
        beforeEach ->
          editor.setCursorScreenPosition([1, 0])
          vimState.activateVisualMode('linewise')
          keydown('g')
          keydown('g')

        it "selects to the first line in the file", ->
          expect(editor.getSelectedText()).toBe " 1abc\n 2\n"

        it "moves the cursor to a specified line", ->
          expect(editor.getCursorScreenPosition()).toEqual [0, 0]

      describe "in characterwise visual mode", ->
        beforeEach ->
          editor.setCursorScreenPosition([1, 1])
          vimState.activateVisualMode()
          keydown('g')
          keydown('g')

        it "selects to the first line in the file", ->
          expect(editor.getSelectedText()).toBe "1abc\n 2"

        it "moves the cursor to a specified line", ->
          expect(editor.getCursorScreenPosition()).toEqual [0, 1]

    describe "as a repeated motion", ->
      describe "in normal mode", ->
        beforeEach ->
          keydown('2')
          keydown('g')
          keydown('g')

        it "moves the cursor to a specified line", ->
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]

      describe "in linewise visual motion", ->
        beforeEach ->
          editor.setCursorScreenPosition([2, 0])
          vimState.activateVisualMode('linewise')
          keydown('2')
          keydown('g')
          keydown('g')

        it "selects to a specified line", ->
          expect(editor.getSelectedText()).toBe " 2\n3\n"

        it "moves the cursor to a specified line", ->
          expect(editor.getCursorScreenPosition()).toEqual [1, 0]

      describe "in characterwise visual motion", ->
        beforeEach ->
          editor.setCursorScreenPosition([2, 0])
          vimState.activateVisualMode()
          keydown('2')
          keydown('g')
          keydown('g')

        it "selects to a first character of specified line", ->
          expect(editor.getSelectedText()).toBe "2\n3"

        it "moves the cursor to a specified line", ->
          expect(editor.getCursorScreenPosition()).toEqual [1, 1]

  describe "the g_ keybinding", ->
    beforeEach ->
      editor.setText("1  \n    2  \n 3abc\n ")

    describe "as a motion", ->
      it "moves the cursor to the last nonblank character", ->
        editor.setCursorScreenPosition([1, 0])
        keydown('g')
        keydown('_')
        expect(editor.getCursorScreenPosition()).toEqual [1, 4]

      it "will move the cursor to the beginning of the line if necessary", ->
        editor.setCursorScreenPosition([0, 2])
        keydown('g')
        keydown('_')
        expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    describe "as a repeated motion", ->
      it "moves the cursor downward and outward", ->
        editor.setCursorScreenPosition([0, 0])
        keydown('2')
        keydown('g')
        keydown('_')
        expect(editor.getCursorScreenPosition()).toEqual [1, 4]

    describe "as a selection", ->
      it "selects the current line excluding whitespace", ->
        editor.setCursorScreenPosition([1, 2])
        vimState.activateVisualMode()
        keydown('2')
        keydown('g')
        keydown('_')
        expect(editor.getSelectedText()).toEqual "  2  \n 3abc"

  describe "the G keybinding", ->
    beforeEach ->
      editor.setText("1\n    2\n 3abc\n ")
      editor.setCursorScreenPosition([0, 2])

    describe "as a motion", ->
      beforeEach -> keydown('G', shift: true)

      it "moves the cursor to the last line after whitespace", ->
        expect(editor.getCursorScreenPosition()).toEqual [3, 0]

    describe "as a repeated motion", ->
      beforeEach ->
        keydown('2')
        keydown('G', shift: true)

      it "moves the cursor to a specified line", ->
        expect(editor.getCursorScreenPosition()).toEqual [1, 4]

    describe "as a selection", ->
      beforeEach ->
        editor.setCursorScreenPosition([1, 0])
        vimState.activateVisualMode()
        keydown('G', shift: true)

      it "selects to the last line in the file", ->
        expect(editor.getSelectedText()).toBe "    2\n 3abc\n "

      it "moves the cursor to the last line after whitespace", ->
        expect(editor.getCursorScreenPosition()).toEqual [3, 1]

  describe "the / keybinding", ->
    pane = null

    beforeEach ->
      pane = {activate: jasmine.createSpy("activate")}
      spyOn(atom.workspace, 'getActivePane').andReturn(pane)

      editor.setText("abc\ndef\nabc\ndef\n")
      editor.setCursorBufferPosition([0, 0])

      # clear search history
      vimState.globalVimState.searchHistory = []
      vimState.globalVimState.currentSearch = {}

    describe "as a motion", ->
      it "moves the cursor to the specified search pattern", ->
        keydown('/')

        submitNormalModeInputText 'def'

        expect(editor.getCursorBufferPosition()).toEqual [1, 0]
        expect(pane.activate).toHaveBeenCalled()

      it "loops back around", ->
        editor.setCursorBufferPosition([3, 0])
        keydown('/')
        submitNormalModeInputText 'def'

        expect(editor.getCursorBufferPosition()).toEqual [1, 0]

      it "uses a valid regex as a regex", ->
        keydown('/')
        # Cycle through the 'abc' on the first line with a character pattern
        submitNormalModeInputText '[abc]'
        expect(editor.getCursorBufferPosition()).toEqual [0, 1]
        keydown('n')
        expect(editor.getCursorBufferPosition()).toEqual [0, 2]

      it "uses an invalid regex as a literal string", ->
        # Go straight to the literal [abc
        editor.setText("abc\n[abc]\n")
        keydown('/')
        submitNormalModeInputText '[abc'
        expect(editor.getCursorBufferPosition()).toEqual [1, 0]
        keydown('n')
        expect(editor.getCursorBufferPosition()).toEqual [1, 0]

      it "uses ? as a literal string", ->
        editor.setText("abc\n[a?c?\n")
        keydown('/')
        submitNormalModeInputText '?'
        expect(editor.getCursorBufferPosition()).toEqual [1, 2]
        keydown('n')
        expect(editor.getCursorBufferPosition()).toEqual [1, 4]

      it 'works with selection in visual mode', ->
        editor.setText('one two three')
        keydown('v')
        keydown('/')
        submitNormalModeInputText 'th'
        expect(editor.getCursorBufferPosition()).toEqual [0, 9]
        keydown('d')
        expect(editor.getText()).toBe 'hree'

      it 'extends selection when repeating search in visual mode', ->
        editor.setText('line1\nline2\nline3')
        keydown('v')
        keydown('/')
        submitNormalModeInputText 'line'
        {start, end} = editor.getSelectedBufferRange()
        expect(start.row).toEqual 0
        expect(end.row).toEqual 1
        keydown('n')
        {start, end} = editor.getSelectedBufferRange()
        expect(start.row).toEqual 0
        expect(end.row).toEqual 2

      describe "case sensitivity", ->
        beforeEach ->
          editor.setText("\nabc\nABC\n")
          editor.setCursorBufferPosition([0, 0])
          keydown('/')

        it "works in case sensitive mode", ->
          submitNormalModeInputText 'ABC'
          expect(editor.getCursorBufferPosition()).toEqual [2, 0]
          keydown('n')
          expect(editor.getCursorBufferPosition()).toEqual [2, 0]

        it "works in case insensitive mode", ->
          submitNormalModeInputText '\\cAbC'
          expect(editor.getCursorBufferPosition()).toEqual [1, 0]
          keydown('n')
          expect(editor.getCursorBufferPosition()).toEqual [2, 0]

        it "works in case insensitive mode wherever \\c is", ->
          submitNormalModeInputText 'AbC\\c'
          expect(editor.getCursorBufferPosition()).toEqual [1, 0]
          keydown('n')
          expect(editor.getCursorBufferPosition()).toEqual [2, 0]

        it "uses case insensitive search if useSmartcaseForSearch is true and searching lowercase", ->
          atom.config.set 'vim-mode.useSmartcaseForSearch', true
          submitNormalModeInputText 'abc'
          expect(editor.getCursorBufferPosition()).toEqual [1, 0]
          keydown('n')
          expect(editor.getCursorBufferPosition()).toEqual [2, 0]

        it "uses case sensitive search if useSmartcaseForSearch is true and searching uppercase", ->
          atom.config.set 'vim-mode.useSmartcaseForSearch', true
          submitNormalModeInputText 'ABC'
          expect(editor.getCursorBufferPosition()).toEqual [2, 0]
          keydown('n')
          expect(editor.getCursorBufferPosition()).toEqual [2, 0]

      describe "repeating", ->
        it "does nothing with no search history", ->
          editor.setCursorBufferPosition([0, 0])
          keydown('n')
          expect(editor.getCursorBufferPosition()).toEqual [0, 0]
          editor.setCursorBufferPosition([1, 1])
          keydown('n')
          expect(editor.getCursorBufferPosition()).toEqual [1, 1]

      describe "repeating with search history", ->
        beforeEach ->
          keydown('/')
          submitNormalModeInputText 'def'

        it "repeats previous search with /<enter>", ->
          keydown('/')
          submitNormalModeInputText('')
          expect(editor.getCursorBufferPosition()).toEqual [3, 0]

        it "repeats previous search with //", ->
          keydown('/')
          submitNormalModeInputText('/')
          expect(editor.getCursorBufferPosition()).toEqual [3, 0]

        describe "the n keybinding", ->
          it "repeats the last search", ->
            keydown('n')
            expect(editor.getCursorBufferPosition()).toEqual [3, 0]

        describe "the N keybinding", ->
          it "repeats the last search backwards", ->
            editor.setCursorBufferPosition([0, 0])
            keydown('N', shift: true)
            expect(editor.getCursorBufferPosition()).toEqual [3, 0]
            keydown('N', shift: true)
            expect(editor.getCursorBufferPosition()).toEqual [1, 0]

      describe "composing", ->
        it "composes with operators", ->
          keydown('d')
          keydown('/')
          submitNormalModeInputText('def')
          expect(editor.getText()).toEqual "def\nabc\ndef\n"

        it "repeats correctly with operators", ->
          keydown('d')
          keydown('/')
          submitNormalModeInputText('def')

          keydown('.')
          expect(editor.getText()).toEqual "def\n"

    describe "when reversed as ?", ->
      it "moves the cursor backwards to the specified search pattern", ->
        keydown('?')
        submitNormalModeInputText('def')
        expect(editor.getCursorBufferPosition()).toEqual [3, 0]

      it "accepts / as a literal search pattern", ->
        editor.setText("abc\nd/f\nabc\nd/f\n")
        editor.setCursorBufferPosition([0, 0])
        keydown('?')
        submitNormalModeInputText('/')
        expect(editor.getCursorBufferPosition()).toEqual [3, 1]
        keydown('?')
        submitNormalModeInputText('/')
        expect(editor.getCursorBufferPosition()).toEqual [1, 1]

      describe "repeating", ->
        beforeEach ->
          keydown('?')
          submitNormalModeInputText('def')

        it "repeats previous search as reversed with ?<enter>", ->
          keydown('?')
          submitNormalModeInputText('')
          expect(editor.getCursorBufferPosition()).toEqual [1, 0]

        it "repeats previous search as reversed with ??", ->
          keydown('?')
          submitNormalModeInputText('?')
          expect(editor.getCursorBufferPosition()).toEqual [1, 0]

        describe 'the n keybinding', ->
          it "repeats the last search backwards", ->
            editor.setCursorBufferPosition([0, 0])
            keydown('n')
            expect(editor.getCursorBufferPosition()).toEqual [3, 0]

        describe 'the N keybinding', ->
          it "repeats the last search forwards", ->
            editor.setCursorBufferPosition([0, 0])
            keydown('N', shift: true)
            expect(editor.getCursorBufferPosition()).toEqual [1, 0]

    describe "using search history", ->
      inputEditor = null

      beforeEach ->
        keydown('/')
        submitNormalModeInputText('def')
        expect(editor.getCursorBufferPosition()).toEqual [1, 0]

        keydown('/')
        submitNormalModeInputText('abc')
        expect(editor.getCursorBufferPosition()).toEqual [2, 0]

        inputEditor = editor.normalModeInputView.editorElement

      it "allows searching history in the search field", ->
        keydown('/')
        atom.commands.dispatch(inputEditor, 'core:move-up')
        expect(inputEditor.getModel().getText()).toEqual('abc')
        atom.commands.dispatch(inputEditor, 'core:move-up')
        expect(inputEditor.getModel().getText()).toEqual('def')
        atom.commands.dispatch(inputEditor, 'core:move-up')
        expect(inputEditor.getModel().getText()).toEqual('def')

      it "resets the search field to empty when scrolling back", ->
        keydown('/')
        atom.commands.dispatch(inputEditor, 'core:move-up')
        expect(inputEditor.getModel().getText()).toEqual('abc')
        atom.commands.dispatch(inputEditor, 'core:move-up')
        expect(inputEditor.getModel().getText()).toEqual('def')
        atom.commands.dispatch(inputEditor, 'core:move-down')
        expect(inputEditor.getModel().getText()).toEqual('abc')
        atom.commands.dispatch(inputEditor, 'core:move-down')
        expect(inputEditor.getModel().getText()).toEqual ''

  describe "the * keybinding", ->
    beforeEach ->
      editor.setText("abd\n@def\nabd\ndef\n")
      editor.setCursorBufferPosition([0, 0])

    describe "as a motion", ->
      it "moves cursor to next occurence of word under cursor", ->
        keydown("*")
        expect(editor.getCursorBufferPosition()).toEqual [2, 0]

      it "repeats with the n key", ->
        keydown("*")
        expect(editor.getCursorBufferPosition()).toEqual [2, 0]
        keydown("n")
        expect(editor.getCursorBufferPosition()).toEqual [0, 0]

      it "doesn't move cursor unless next occurence is the exact word (no partial matches)", ->
        editor.setText("abc\ndef\nghiabc\njkl\nabcdef")
        editor.setCursorBufferPosition([0, 0])
        keydown("*")
        expect(editor.getCursorBufferPosition()).toEqual [0, 0]

      describe "with words that contain 'non-word' characters", ->
        it "moves cursor to next occurence of word under cursor", ->
          editor.setText("abc\n@def\nabc\n@def\n")
          editor.setCursorBufferPosition([1, 0])
          keydown("*")
          expect(editor.getCursorBufferPosition()).toEqual [3, 0]

        it "doesn't move cursor unless next match has exact word ending", ->
          editor.setText("abc\n@def\nabc\n@def1\n")
          editor.setCursorBufferPosition([1, 1])
          keydown("*")
          # this is because of the default isKeyword value of vim-mode that includes @
          expect(editor.getCursorBufferPosition()).toEqual [1, 0]

        # FIXME: This behavior is different from the one found in
        # vim. This is because the word boundary match in Javascript
        # ignores starting 'non-word' characters.
        # e.g.
        # in Vim:        /\<def\>/.test("@def") => false
        # in Javascript: /\bdef\b/.test("@def") => true
        it "moves cursor to the start of valid word char", ->
          editor.setText("abc\ndef\nabc\n@def\n")
          editor.setCursorBufferPosition([1, 0])
          keydown("*")
          expect(editor.getCursorBufferPosition()).toEqual [3, 1]

      describe "when cursor is on non-word char column", ->
        it "matches only the non-word char", ->
          editor.setText("abc\n@def\nabc\n@def\n")
          editor.setCursorBufferPosition([1, 0])
          keydown("*")
          expect(editor.getCursorBufferPosition()).toEqual [3, 0]

      describe "when cursor is not on a word", ->
        it "does a match with the next word", ->
          editor.setText("abc\na  @def\n abc\n @def")
          editor.setCursorBufferPosition([1, 1])
          keydown("*")
          expect(editor.getCursorBufferPosition()).toEqual [3, 1]

      describe "when cursor is at EOF", ->
        it "doesn't try to do any match", ->
          editor.setText("abc\n@def\nabc\n ")
          editor.setCursorBufferPosition([3, 0])
          keydown("*")
          expect(editor.getCursorBufferPosition()).toEqual [3, 0]

  describe "the hash keybinding", ->
    describe "as a motion", ->
      it "moves cursor to previous occurence of word under cursor", ->
        editor.setText("abc\n@def\nabc\ndef\n")
        editor.setCursorBufferPosition([2, 1])
        keydown("#")
        expect(editor.getCursorBufferPosition()).toEqual [0, 0]

      it "repeats with n", ->
        editor.setText("abc\n@def\nabc\ndef\nabc\n")
        editor.setCursorBufferPosition([2, 1])
        keydown("#")
        expect(editor.getCursorBufferPosition()).toEqual [0, 0]
        keydown("n")
        expect(editor.getCursorBufferPosition()).toEqual [4, 0]
        keydown("n")
        expect(editor.getCursorBufferPosition()).toEqual [2, 0]

      it "doesn't move cursor unless next occurence is the exact word (no partial matches)", ->
        editor.setText("abc\ndef\nghiabc\njkl\nabcdef")
        editor.setCursorBufferPosition([0, 0])
        keydown("#")
        expect(editor.getCursorBufferPosition()).toEqual [0, 0]

      describe "with words that containt 'non-word' characters", ->
        it "moves cursor to next occurence of word under cursor", ->
          editor.setText("abc\n@def\nabc\n@def\n")
          editor.setCursorBufferPosition([3, 0])
          keydown("#")
          expect(editor.getCursorBufferPosition()).toEqual [1, 0]

        it "moves cursor to the start of valid word char", ->
          editor.setText("abc\n@def\nabc\ndef\n")
          editor.setCursorBufferPosition([3, 0])
          keydown("#")
          expect(editor.getCursorBufferPosition()).toEqual [1, 1]

      describe "when cursor is on non-word char column", ->
        it "matches only the non-word char", ->
          editor.setText("abc\n@def\nabc\n@def\n")
          editor.setCursorBufferPosition([1, 0])
          keydown("*")
          expect(editor.getCursorBufferPosition()).toEqual [3, 0]

  describe "the H keybinding", ->
    beforeEach ->
      editor.setText("1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n")
      editor.setCursorScreenPosition([8, 0])
      spyOn(editor.getLastCursor(), 'setScreenPosition')

    it "moves the cursor to the first row if visible", ->
      spyOn(editor, 'getFirstVisibleScreenRow').andReturn(0)
      keydown('H', shift: true)
      expect(editor.getLastCursor().setScreenPosition).toHaveBeenCalledWith([0, 0])

    it "moves the cursor to the first visible row plus offset", ->
      spyOn(editor, 'getFirstVisibleScreenRow').andReturn(2)
      keydown('H', shift: true)
      expect(editor.getLastCursor().setScreenPosition).toHaveBeenCalledWith([4, 0])

    it "respects counts", ->
      spyOn(editor, 'getFirstVisibleScreenRow').andReturn(0)
      keydown('3')
      keydown('H', shift: true)
      expect(editor.getLastCursor().setScreenPosition).toHaveBeenCalledWith([2, 0])

  describe "the L keybinding", ->
    beforeEach ->
      editor.setText("1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n")
      editor.setCursorScreenPosition([8, 0])
      spyOn(editor.getLastCursor(), 'setScreenPosition')

    it "moves the cursor to the first row if visible", ->
      spyOn(editor, 'getLastVisibleScreenRow').andReturn(10)
      keydown('L', shift: true)
      expect(editor.getLastCursor().setScreenPosition).toHaveBeenCalledWith([10, 0])

    it "moves the cursor to the first visible row plus offset", ->
      spyOn(editor, 'getLastVisibleScreenRow').andReturn(6)
      keydown('L', shift: true)
      expect(editor.getLastCursor().setScreenPosition).toHaveBeenCalledWith([4, 0])

    it "respects counts", ->
      spyOn(editor, 'getLastVisibleScreenRow').andReturn(10)
      keydown('3')
      keydown('L', shift: true)
      expect(editor.getLastCursor().setScreenPosition).toHaveBeenCalledWith([8, 0])

  describe "the M keybinding", ->
    beforeEach ->
      editor.setText("1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n")
      editor.setCursorScreenPosition([8, 0])
      spyOn(editor.getLastCursor(), 'setScreenPosition')
      spyOn(editor, 'getLastVisibleScreenRow').andReturn(10)
      spyOn(editor, 'getFirstVisibleScreenRow').andReturn(0)

    it "moves the cursor to the first row if visible", ->
      keydown('M', shift: true)
      expect(editor.getLastCursor().setScreenPosition).toHaveBeenCalledWith([5, 0])

  describe 'the mark keybindings', ->
    beforeEach ->
      editor.setText('  12\n    34\n56\n')
      editor.setCursorBufferPosition([0, 1])

    it 'moves to the beginning of the line of a mark', ->
      editor.setCursorBufferPosition([1, 1])
      keydown('m')
      normalModeInputKeydown('a')
      editor.setCursorBufferPosition([0, 0])
      keydown('\'')
      normalModeInputKeydown('a')
      expect(editor.getCursorBufferPosition()).toEqual [1, 4]

    it 'moves literally to a mark', ->
      editor.setCursorBufferPosition([1, 1])
      keydown('m')
      normalModeInputKeydown('a')
      editor.setCursorBufferPosition([0, 0])
      keydown('`')
      normalModeInputKeydown('a')
      expect(editor.getCursorBufferPosition()).toEqual [1, 1]

    it 'deletes to a mark by line', ->
      editor.setCursorBufferPosition([1, 5])
      keydown('m')
      normalModeInputKeydown('a')
      editor.setCursorBufferPosition([0, 0])
      keydown('d')
      keydown('\'')
      normalModeInputKeydown('a')
      expect(editor.getText()).toEqual '56\n'

    it 'deletes before to a mark literally', ->
      editor.setCursorBufferPosition([1, 5])
      keydown('m')
      normalModeInputKeydown('a')
      editor.setCursorBufferPosition([0, 1])
      keydown('d')
      keydown('`')
      normalModeInputKeydown('a')
      expect(editor.getText()).toEqual ' 4\n56\n'

    it 'deletes after to a mark literally', ->
      editor.setCursorBufferPosition([1, 5])
      keydown('m')
      normalModeInputKeydown('a')
      editor.setCursorBufferPosition([2, 1])
      keydown('d')
      keydown('`')
      normalModeInputKeydown('a')
      expect(editor.getText()).toEqual '  12\n    36\n'

    it 'moves back to previous', ->
      editor.setCursorBufferPosition([1, 5])
      keydown('`')
      normalModeInputKeydown('`')
      editor.setCursorBufferPosition([2, 1])
      keydown('`')
      normalModeInputKeydown('`')
      expect(editor.getCursorBufferPosition()).toEqual [1, 5]

  describe 'the f/F keybindings', ->
    beforeEach ->
      editor.setText("abcabcabcabc\n")
      editor.setCursorScreenPosition([0, 0])

    it 'moves to the first specified character it finds', ->
      keydown('f')
      normalModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    it 'moves backwards to the first specified character it finds', ->
      editor.setCursorScreenPosition([0, 2])
      keydown('F', shift: true)
      normalModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    it 'respects count forward', ->
      keydown('2')
      keydown('f')
      normalModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]

    it 'respects count backward', ->
      editor.setCursorScreenPosition([0, 6])
      keydown('2')
      keydown('F', shift: true)
      normalModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    it "doesn't move if the character specified isn't found", ->
      keydown('f')
      normalModeInputKeydown('d')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    it "doesn't move if there aren't the specified count of the specified character", ->
      keydown('1')
      keydown('0')
      keydown('f')
      normalModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]
      # a bug was making this behaviour depend on the count
      keydown('1')
      keydown('1')
      keydown('f')
      normalModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]
      # and backwards now
      editor.setCursorScreenPosition([0, 6])
      keydown('1')
      keydown('0')
      keydown('F', shift: true)
      normalModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]
      keydown('1')
      keydown('1')
      keydown('F', shift: true)
      normalModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]

    it "composes with d", ->
      editor.setCursorScreenPosition([0, 3])
      keydown('d')
      keydown('2')
      keydown('f')
      normalModeInputKeydown('a')
      expect(editor.getText()).toEqual 'abcbc\n'

  describe 'the t/T keybindings', ->
    beforeEach ->
      editor.setText("abcabcabcabc\n")
      editor.setCursorScreenPosition([0, 0])

    it 'moves to the character previous to the first specified character it finds', ->
      keydown('t')
      normalModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]
      # or stays put when it's already there
      keydown('t')
      normalModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    it 'moves backwards to the character after the first specified character it finds', ->
      editor.setCursorScreenPosition([0, 2])
      keydown('T', shift: true)
      normalModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]

    it 'respects count forward', ->
      keydown('2')
      keydown('t')
      normalModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]

    it 'respects count backward', ->
      editor.setCursorScreenPosition([0, 6])
      keydown('2')
      keydown('T', shift: true)
      normalModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]

    it "doesn't move if the character specified isn't found", ->
      keydown('t')
      normalModeInputKeydown('d')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    it "doesn't move if there aren't the specified count of the specified character", ->
      keydown('1')
      keydown('0')
      keydown('t')
      normalModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]
      # a bug was making this behaviour depend on the count
      keydown('1')
      keydown('1')
      keydown('t')
      normalModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]
      # and backwards now
      editor.setCursorScreenPosition([0, 6])
      keydown('1')
      keydown('0')
      keydown('T', shift: true)
      normalModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]
      keydown('1')
      keydown('1')
      keydown('T', shift: true)
      normalModeInputKeydown('a')
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]

    it "composes with d", ->
      editor.setCursorScreenPosition([0, 3])
      keydown('d')
      keydown('2')
      keydown('t')
      normalModeInputKeydown('b')
      expect(editor.getText()).toBe 'abcbcabc\n'

    it "selects character under cursor even when no movement happens", ->
      editor.setCursorBufferPosition([0, 0])
      keydown('d')
      keydown('t')
      normalModeInputKeydown('b')
      expect(editor.getText()).toBe 'bcabcabcabc\n'

  describe 'the V keybinding', ->
    beforeEach ->
      editor.setText("01\n002\n0003\n00004\n000005\n")
      editor.setCursorScreenPosition([1, 1])

    it "selects down a line", ->
      keydown('V', shift: true)
      keydown('j')
      keydown('j')
      expect(editor.getSelectedText()).toBe "002\n0003\n00004\n"

    it "selects up a line", ->
      keydown('V', shift: true)
      keydown('k')
      expect(editor.getSelectedText()).toBe "01\n002\n"

  describe 'the ; and , keybindings', ->
    beforeEach ->
      editor.setText("abcabcabcabc\n")
      editor.setCursorScreenPosition([0, 0])

    it "repeat f in same direction", ->
      keydown('f')
      normalModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]

    it "repeat F in same direction", ->
      editor.setCursorScreenPosition([0, 10])
      keydown('F', shift: true)
      normalModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    it "repeat f in opposite direction", ->
      editor.setCursorScreenPosition([0, 6])
      keydown('f')
      normalModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    it "repeat F in opposite direction", ->
      editor.setCursorScreenPosition([0, 4])
      keydown('F', shift: true)
      normalModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]

    it "alternate repeat f in same direction and reverse", ->
      keydown('f')
      normalModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    it "alternate repeat F in same direction and reverse", ->
      editor.setCursorScreenPosition([0, 10])
      keydown('F', shift: true)
      normalModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 5]
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]

    it "repeat t in same direction", ->
      keydown('t')
      normalModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 1]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 4]

    it "repeat T in same direction", ->
      editor.setCursorScreenPosition([0, 10])
      keydown('T', shift: true)
      normalModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 9]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]

    it "repeat t in opposite direction first, and then reverse", ->
      editor.setCursorScreenPosition([0, 3])
      keydown('t')
      normalModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 4]
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 3]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 4]

    it "repeat T in opposite direction first, and then reverse", ->
      editor.setCursorScreenPosition([0, 4])
      keydown('T', shift: true)
      normalModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 3]
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 4]
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 3]

    it "repeat with count in same direction", ->
      editor.setCursorScreenPosition([0, 0])
      keydown('f')
      normalModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]
      keydown('2')
      keydown(';')
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]

    it "repeat with count in reverse direction", ->
      editor.setCursorScreenPosition([0, 6])
      keydown('f')
      normalModeInputKeydown('c')
      expect(editor.getCursorScreenPosition()).toEqual [0, 8]
      keydown('2')
      keydown(',')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]

    it "shares the most recent find/till command with other editors", ->
      helpers.getEditorElement (otherEditorElement) ->
        otherEditor = otherEditorElement.getModel()

        editor.setText("a baz bar\n")
        editor.setCursorScreenPosition([0, 0])

        otherEditor.setText("foo bar baz")
        otherEditor.setCursorScreenPosition([0, 0])

        # by default keyDown and such go in the usual editor
        keydown('f')
        normalModeInputKeydown('b')
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]
        expect(otherEditor.getCursorScreenPosition()).toEqual [0, 0]

        # replay same find in the other editor
        keydown(';', element: otherEditorElement)
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]
        expect(otherEditor.getCursorScreenPosition()).toEqual [0, 4]

        # do a till in the other editor
        keydown('t', element: otherEditorElement)
        normalModeInputKeydown('r', editor: otherEditor)
        expect(editor.getCursorScreenPosition()).toEqual [0, 2]
        expect(otherEditor.getCursorScreenPosition()).toEqual [0, 5]

        # and replay in the normal editor
        keydown(';')
        expect(editor.getCursorScreenPosition()).toEqual [0, 7]
        expect(otherEditor.getCursorScreenPosition()).toEqual [0, 5]

  describe 'the % motion', ->
    beforeEach ->
      editor.setText("( ( ) )--{ text in here; and a function call(with parameters) }\n")
      editor.setCursorScreenPosition([0, 0])

    it 'matches the correct parenthesis', ->
      keydown('%')
      expect(editor.getCursorScreenPosition()).toEqual [0, 6]

    it 'matches the correct brace', ->
      editor.setCursorScreenPosition([0, 9])
      keydown('%')
      expect(editor.getCursorScreenPosition()).toEqual [0, 62]

    it 'composes correctly with d', ->
      editor.setCursorScreenPosition([0, 9])
      keydown('d')
      keydown('%')
      expect(editor.getText()).toEqual  "( ( ) )--\n"

    it 'moves correctly when composed with v going forward', ->
      keydown('v')
      keydown('h')
      keydown('%')
      expect(editor.getCursorScreenPosition()).toEqual [0, 7]

    it 'moves correctly when composed with v going backward', ->
      editor.setCursorScreenPosition([0, 5])
      keydown('v')
      keydown('%')
      expect(editor.getCursorScreenPosition()).toEqual [0, 0]

    it 'it moves appropriately to find the nearest matching action', ->
      editor.setCursorScreenPosition([0, 3])
      keydown('%')
      expect(editor.getCursorScreenPosition()).toEqual [0, 2]
      expect(editor.getText()).toEqual  "( ( ) )--{ text in here; and a function call(with parameters) }\n"

    it 'it moves appropriately to find the nearest matching action', ->
      editor.setCursorScreenPosition([0, 26])
      keydown('%')
      expect(editor.getCursorScreenPosition()).toEqual [0, 60]
      expect(editor.getText()).toEqual  "( ( ) )--{ text in here; and a function call(with parameters) }\n"

    it "finds matches across multiple lines", ->
      editor.setText("...(\n...)")
      editor.setCursorScreenPosition([0, 0])
      keydown("%")
      expect(editor.getCursorScreenPosition()).toEqual([1, 3])

    it "does not affect search history", ->
      keydown('/')
      submitNormalModeInputText 'func'
      expect(editor.getCursorBufferPosition()).toEqual [0, 31]
      keydown('%')
      expect(editor.getCursorBufferPosition()).toEqual [0, 60]
      keydown('n')
      expect(editor.getCursorBufferPosition()).toEqual [0, 31]

  describe "scrolling screen and keeping cursor in the same screen position", ->
    beforeEach ->
      editor.setText([0...80].join("\n"))
      editor.setHeight(20 * 10)
      editor.setLineHeightInPixels(10)
      editor.setScrollTop(40 * 10)
      editor.setCursorBufferPosition([42, 0])

    describe "the ctrl-u keybinding", ->
      it "moves the screen down by half screen size and keeps cursor onscreen", ->
        keydown('u', ctrl: true)
        expect(editor.getScrollTop()).toEqual 300
        expect(editor.getCursorBufferPosition()).toEqual [32, 0]

      it "selects on visual mode", ->
        editor.setCursorBufferPosition([42, 1])
        vimState.activateVisualMode()
        keydown('u', ctrl: true)
        expect(editor.getSelectedText()).toEqual [32..42].join("\n")

      it "selects on linewise mode", ->
        vimState.activateVisualMode('linewise')
        keydown('u', ctrl: true)
        expect(editor.getSelectedText()).toEqual [32..42].join("\n").concat("\n")

    describe "the ctrl-b keybinding", ->
      it "moves screen up one page", ->
        keydown('b', ctrl: true)
        expect(editor.getScrollTop()).toEqual 200
        expect(editor.getCursorScreenPosition()).toEqual [22, 0]

      it "selects on visual mode", ->
        editor.setCursorBufferPosition([42, 1])
        vimState.activateVisualMode()
        keydown('b', ctrl: true)
        expect(editor.getSelectedText()).toEqual [22..42].join("\n")

      it "selects on linewise mode", ->
        vimState.activateVisualMode('linewise')
        keydown('b', ctrl: true)
        expect(editor.getSelectedText()).toEqual [22..42].join("\n").concat("\n")


    describe "the ctrl-d keybinding", ->
      it "moves the screen down by half screen size and keeps cursor onscreen", ->
        keydown('d', ctrl: true)
        expect(editor.getScrollTop()).toEqual 500
        expect(editor.getCursorBufferPosition()).toEqual [52, 0]

      it "selects on visual mode", ->
        editor.setCursorBufferPosition([42, 1])
        vimState.activateVisualMode()
        keydown('d', ctrl: true)
        expect(editor.getSelectedText()).toEqual [42..52].join("\n").slice(1, -1)

      it "selects on linewise mode", ->
        vimState.activateVisualMode('linewise')
        keydown('d', ctrl: true)
        expect(editor.getSelectedText()).toEqual [42..52].join("\n").concat("\n")

    describe "the ctrl-f keybinding", ->
      it "moves screen down one page", ->
        keydown('f', ctrl: true)
        expect(editor.getScrollTop()).toEqual 600
        expect(editor.getCursorScreenPosition()).toEqual [62, 0]

      it "selects on visual mode", ->
        editor.setCursorBufferPosition([42, 1])
        vimState.activateVisualMode()
        keydown('f', ctrl: true)
        expect(editor.getSelectedText()).toEqual [42..62].join("\n").slice(1, -1)

      it "selects on linewise mode", ->
        vimState.activateVisualMode('linewise')
        keydown('f', ctrl: true)
        expect(editor.getSelectedText()).toEqual [42..62].join("\n").concat("\n")
