{getVimState} = require './spec-helper'

describe "Scrolling", ->
  [set, ensure, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure} = vim
      jasmine.attachToDOM(editorElement)

  describe "scrolling keybindings", ->
    beforeEach ->
      {component} = editor
      component.element.style.height = component.getLineHeight() * 5 + 'px'
      editorElement.measureDimensions()
      initialRowRange = [0, 5]

      set
        textC: """
          100
          200
          30|0
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
        ensure 'ctrl-e', cursor: [3, 2]
        expect(editor.getFirstVisibleScreenRow()).toBe 1
        expect(editor.getLastVisibleScreenRow()).toBe 6

        ensure '2 ctrl-e', cursor: [5, 2]
        expect(editor.getFirstVisibleScreenRow()).toBe 3
        expect(editor.getLastVisibleScreenRow()).toBe 8

        ensure '2 ctrl-y', cursor: [4, 2]
        expect(editor.getFirstVisibleScreenRow()).toBe 1
        expect(editor.getLastVisibleScreenRow()).toBe 6

  describe "redraw-cursor-line keybindings", ->
    _ensure = (keystroke, {scrollTop, moveToFirstChar}) ->
      ensure(keystroke)
      expect(editorElement.setScrollTop).toHaveBeenCalledWith(scrollTop)
      if moveToFirstChar
        expect(editor.moveToFirstCharacterOfLine).toHaveBeenCalled()
      else
        expect(editor.moveToFirstCharacterOfLine).not.toHaveBeenCalled()

    beforeEach ->
      editor.setText [1..200].join("\n")
      editorElement.style.lineHeight = "20px"

      editorElement.setHeight(20 * 10)
      editorElement.measureDimensions()

      spyOn(editor, 'moveToFirstCharacterOfLine')
      spyOn(editorElement, 'setScrollTop')
      spyOn(editor, 'getFirstVisibleScreenRow').andReturn(90)
      spyOn(editor, 'getLastVisibleScreenRow').andReturn(110)
      spyOn(editorElement, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

    describe "at top", ->
      it "without move cursor", ->   _ensure 'z t',     scrollTop: 960, moveToFirstChar: false
      it "with move to 1st char", -> _ensure 'z enter', scrollTop: 960, moveToFirstChar: true
    describe "at upper-middle", ->
      it "without move cursor", ->   _ensure 'z u',     scrollTop: 950, moveToFirstChar: false
      it "with move to 1st char", -> _ensure 'z space', scrollTop: 950, moveToFirstChar: true
    describe "at middle", ->
      it "without move cursor", ->   _ensure 'z z',     scrollTop: 900, moveToFirstChar: false
      it "with move to 1st char", -> _ensure 'z .',     scrollTop: 900, moveToFirstChar: true
    describe "at bottom", ->
      it "without move cursor", ->   _ensure 'z b',     scrollTop: 860, moveToFirstChar: false
      it "with move to 1st char", -> _ensure 'z -',     scrollTop: 860, moveToFirstChar: true

  describe "horizontal scroll cursor keybindings", ->
    beforeEach ->
      editorElement.setWidth(600)
      editorElement.setHeight(600)
      editorElement.style.lineHeight = "10px"
      editorElement.style.font = "16px monospace"
      editorElement.measureDimensions()

      text = ""
      for i in [100..199]
        text += "#{i} "
      editor.setText(text)
      editor.setCursorBufferPosition([0, 0])

    describe "the zs keybinding", ->
      startPosition = null

      zsPos = (pos) ->
        editor.setCursorBufferPosition([0, pos])
        ensure 'z s'
        editorElement.getScrollLeft()

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
        ensure 'z e'
        editorElement.getScrollLeft()

      startPosition = null

      beforeEach ->
        startPosition = editorElement.getScrollLeft()

      it "does nothing near the start of the line", ->
        expect(zePos(1)).toEqual(startPosition)
        expect(zePos(40)).toEqual(startPosition)

      it "moves the cursor the nearest it can to the right edge of the editor", ->
        pos110 = zePos(110)
        expect(pos110).toBeGreaterThan(startPosition)
        expect(pos110 - zePos(109)).toEqual(10)

      # FIXME description is no longer appropriate
      it "does nothing when very near the end of the line", ->
        posEnd = zePos(399)
        expect(zePos(397)).toBeLessThan(posEnd)
        pos380 = zePos(380)
        expect(pos380).toBeLessThan(posEnd)
        expect(zePos(382) - pos380).toEqual(19)

      it "does nothing if all lines are short", ->
        editor.setText('short')
        startPosition = editorElement.getScrollLeft()
        expect(zePos(1)).toEqual(startPosition)
        expect(zePos(10)).toEqual(startPosition)
