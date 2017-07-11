{getVimState} = require './spec-helper'

describe "Scrolling", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim
      jasmine.attachToDOM(editorElement)

  describe "scrolling keybindings", ->
    beforeEach ->
      if editorElement.measureDimensions?
        # For Atom-v1.19
        {component} = editor
        component.element.style.height = component.getLineHeight() * 5 + 'px'
        editorElement.measureDimensions()
        initialRowRange = [0, 5]

      else # For Atom-v1.18
        # [TODO] Remove when v.1.19 become stable
        editor.setLineHeightInPixels(10)
        editorElement.setHeight(10 * 5)
        atom.views.performDocumentPoll()
        initialRowRange = [0, 4]

      set
        cursor: [1, 2]
        text: """
          100
          200
          300
          400
          500
          600
          700
          800
          900
          1000
        """
      expect(editorElement.getVisibleRowRange()).toEqual(initialRowRange)

    describe "the ctrl-e and ctrl-y keybindings", ->
      it "moves the screen up and down by one and keeps cursor onscreen", ->
        ensure 'ctrl-e', cursor: [2, 2]
        expect(editor.getFirstVisibleScreenRow()).toBe 1
        expect(editor.getLastVisibleScreenRow()).toBe 6

        ensure '2 ctrl-e', cursor: [4, 2]
        expect(editor.getFirstVisibleScreenRow()).toBe 3
        expect(editor.getLastVisibleScreenRow()).toBe 8

        ensure '2 ctrl-y', cursor: [2, 2]
        expect(editor.getFirstVisibleScreenRow()).toBe 1
        expect(editor.getLastVisibleScreenRow()).toBe 6

  describe "scroll cursor keybindings", ->
    beforeEach ->
      editor.setText [1..200].join("\n")
      editorElement.style.lineHeight = "20px"

      editorElement.setHeight(20 * 10)

      if editorElement.measureDimensions?
        # For Atom-v1.19
        editorElement.measureDimensions()
      else # For Atom-v1.18
        # [TODO] Remove when v.1.19 become stable
        editorElement.component.sampleFontStyling()

      spyOn(editor, 'moveToFirstCharacterOfLine')
      spyOn(editorElement, 'setScrollTop')
      spyOn(editorElement, 'getFirstVisibleScreenRow').andReturn(90)
      spyOn(editorElement, 'getLastVisibleScreenRow').andReturn(110)
      spyOn(editorElement, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

    describe "the z<CR> keybinding", ->
      it "moves the screen to position cursor at the top of the window and moves cursor to first non-blank in the line", ->
        keystroke 'z enter'
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(960)
        expect(editor.moveToFirstCharacterOfLine).toHaveBeenCalled()

    describe "the zt keybinding", ->
      it "moves the screen to position cursor at the top of the window and leave cursor in the same column", ->
        keystroke 'z t'
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(960)
        expect(editor.moveToFirstCharacterOfLine).not.toHaveBeenCalled()

    describe "the z. keybinding", ->
      it "moves the screen to position cursor at the center of the window and moves cursor to first non-blank in the line", ->
        keystroke 'z .'
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(900)
        expect(editor.moveToFirstCharacterOfLine).toHaveBeenCalled()

    describe "the zz keybinding", ->
      it "moves the screen to position cursor at the center of the window and leave cursor in the same column", ->
        keystroke 'z z'
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(900)
        expect(editor.moveToFirstCharacterOfLine).not.toHaveBeenCalled()

    describe "the z- keybinding", ->
      it "moves the screen to position cursor at the bottom of the window and moves cursor to first non-blank in the line", ->
        keystroke 'z -'
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(860)
        expect(editor.moveToFirstCharacterOfLine).toHaveBeenCalled()

    describe "the zb keybinding", ->
      it "moves the screen to position cursor at the bottom of the window and leave cursor in the same column", ->
        keystroke 'z b'
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(860)
        expect(editor.moveToFirstCharacterOfLine).not.toHaveBeenCalled()

  describe "horizontal scroll cursor keybindings", ->
    beforeEach ->
      editorElement.setWidth(600)
      editorElement.setHeight(600)
      editorElement.style.lineHeight = "10px"
      editorElement.style.font = "16px monospace"

      if editorElement.measureDimensions?
        # For Atom-v1.19
        editorElement.measureDimensions()
      else # For Atom-v1.18
        # [TODO] Remove when v.1.19 become stable
        atom.views.performDocumentPoll()

      text = ""
      for i in [100..199]
        text += "#{i} "
      editor.setText(text)
      editor.setCursorBufferPosition([0, 0])

    describe "the zs keybinding", ->
      zsPos = (pos) ->
        editor.setCursorBufferPosition([0, pos])
        keystroke 'z s'
        editorElement.getScrollLeft()

      startPosition = NaN
      beforeEach ->
        startPosition = editorElement.getScrollLeft()

      # FIXME: remove in future
      xit "does nothing near the start of the line", ->
        pos1 = zsPos(1)
        expect(pos1).toEqual(startPosition)

      it "moves the cursor the nearest it can to the left edge of the editor", ->
        pos10 = zsPos(10)
        expect(pos10).toBeGreaterThan(startPosition)

        pos11 = zsPos(11)
        expect(pos11 - pos10).toEqual(10)

      it "does nothing near the end of the line", ->
        posEnd = zsPos(399)
        expect(editor.getCursorBufferPosition()).toEqual [0, 399]

        pos390 = zsPos(390)
        expect(pos390).toEqual(posEnd)
        expect(editor.getCursorBufferPosition()).toEqual [0, 390]

        pos340 = zsPos(340)
        expect(pos340).toEqual(posEnd)

      it "does nothing if all lines are short", ->
        editor.setText('short')
        startPosition = editorElement.getScrollLeft()
        pos1 = zsPos(1)
        expect(pos1).toEqual(startPosition)
        expect(editor.getCursorBufferPosition()).toEqual [0, 1]
        pos10 = zsPos(10)
        expect(pos10).toEqual(startPosition)
        expect(editor.getCursorBufferPosition()).toEqual [0, 4]

    describe "the ze keybinding", ->
      zePos = (pos) ->
        editor.setCursorBufferPosition([0, pos])
        keystroke 'z e'
        editorElement.getScrollLeft()

      startPosition = NaN

      beforeEach ->
        startPosition = editorElement.getScrollLeft()

      it "does nothing near the start of the line", ->
        pos1 = zePos(1)
        expect(pos1).toEqual(startPosition)

        pos40 = zePos(40)
        expect(pos40).toEqual(startPosition)

      it "moves the cursor the nearest it can to the right edge of the editor", ->
        pos110 = zePos(110)
        expect(pos110).toBeGreaterThan(startPosition)

        pos109 = zePos(109)
        expect(pos110 - pos109).toEqual(9)

      # FIXME description is no longer appropriate
      it "does nothing when very near the end of the line", ->
        posEnd = zePos(399)
        expect(editor.getCursorBufferPosition()).toEqual [0, 399]

        pos397 = zePos(397)
        expect(pos397).toBeLessThan(posEnd)
        expect(editor.getCursorBufferPosition()).toEqual [0, 397]

        pos380 = zePos(380)
        expect(pos380).toBeLessThan(posEnd)

        pos382 = zePos(382)
        expect(pos382 - pos380).toEqual(19)

      it "does nothing if all lines are short", ->
        editor.setText('short')
        startPosition = editorElement.getScrollLeft()
        pos1 = zePos(1)
        expect(pos1).toEqual(startPosition)
        expect(editor.getCursorBufferPosition()).toEqual [0, 1]
        pos10 = zePos(10)
        expect(pos10).toEqual(startPosition)
        expect(editor.getCursorBufferPosition()).toEqual [0, 4]
