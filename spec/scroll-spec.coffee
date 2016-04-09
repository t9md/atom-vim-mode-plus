{getVimState} = require './spec-helper'

describe "Scrolling", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim
      jasmine.attachToDOM(editorElement)

  afterEach ->
    vimState.resetNormalMode()

  describe "scrolling keybindings", ->
    beforeEach ->
      editor.setText("1\n2\n3\n4\n5\n6\n7\n8\n9\n10")
      spyOn(editorElement, 'getFirstVisibleScreenRow').andReturn(2)
      spyOn(editorElement, 'getLastVisibleScreenRow').andReturn(8)
      spyOn(editor, 'getLineHeightInPixels').andReturn(10)
      spyOn(editorElement, 'getScrollTop').andReturn(100)
      spyOn(editorElement, 'setScrollTop')
      spyOn(editor, 'setCursorScreenPosition')

    describe "the ctrl-e keybinding", ->
      beforeEach ->
        spyOn(editor, 'getCursorScreenPosition').andReturn({row: 3, column: 0})

      it "moves the screen down by one and keeps cursor onscreen", ->
        keystroke {ctrl: 'e'}
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(110)
        expect(editor.setCursorScreenPosition).toHaveBeenCalledWith([4, 0])

    describe "the ctrl-y keybinding", ->
      beforeEach ->
        spyOn(editor, 'getCursorScreenPosition').andReturn({row: 6, column: 0})

      it "moves the screen up by one and keeps the cursor onscreen", ->
        keystroke {ctrl: 'y'}
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(90)
        expect(editor.setCursorScreenPosition).toHaveBeenCalledWith([5, 0])

  describe "scroll cursor keybindings", ->
    beforeEach ->
      editor.setText [1..200].join("\n")
      editorElement.style.lineHeight = "20px"
      editorElement.component.sampleFontStyling()
      editorElement.setHeight(20 * 10)
      spyOn(editor, 'moveToFirstCharacterOfLine')
      spyOn(editorElement, 'setScrollTop')
      spyOn(editorElement, 'getFirstVisibleScreenRow').andReturn(90)
      spyOn(editorElement, 'getLastVisibleScreenRow').andReturn(110)
      spyOn(editorElement, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

    describe "the z<CR> keybinding", ->
      keydownCodeForEnter = '\r'

      it "moves the screen to position cursor at the top of the window and moves cursor to first non-blank in the line", ->
        keystroke ['z', keydownCodeForEnter]
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(960)
        expect(editor.moveToFirstCharacterOfLine).toHaveBeenCalled()

    describe "the zt keybinding", ->
      it "moves the screen to position cursor at the top of the window and leave cursor in the same column", ->
        keystroke 'zt'
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(960)
        expect(editor.moveToFirstCharacterOfLine).not.toHaveBeenCalled()

    describe "the z. keybinding", ->
      it "moves the screen to position cursor at the center of the window and moves cursor to first non-blank in the line", ->
        keystroke 'z.'
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(900)
        expect(editor.moveToFirstCharacterOfLine).toHaveBeenCalled()

    describe "the zz keybinding", ->
      it "moves the screen to position cursor at the center of the window and leave cursor in the same column", ->
        keystroke 'zz'
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(900)
        expect(editor.moveToFirstCharacterOfLine).not.toHaveBeenCalled()

    describe "the z- keybinding", ->
      it "moves the screen to position cursor at the bottom of the window and moves cursor to first non-blank in the line", ->
        keystroke 'z-'
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(860)
        expect(editor.moveToFirstCharacterOfLine).toHaveBeenCalled()

    describe "the zb keybinding", ->
      it "moves the screen to position cursor at the bottom of the window and leave cursor in the same column", ->
        keystroke 'zb'
        expect(editorElement.setScrollTop).toHaveBeenCalledWith(860)
        expect(editor.moveToFirstCharacterOfLine).not.toHaveBeenCalled()

  describe "horizontal scroll cursor keybindings", ->
    beforeEach ->
      editorElement.setWidth(600)
      editorElement.setHeight(600)
      editorElement.style.lineHeight = "10px"
      editorElement.style.font = "16px monospace"
      atom.views.performDocumentPoll()
      text = ""
      for i in [100..199]
        text += "#{i} "
      editor.setText(text)
      editor.setCursorBufferPosition([0, 0])

    describe "the zs keybinding", ->
      zsPos = (pos) ->
        editor.setCursorBufferPosition([0, pos])
        keystroke 'zs'
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
        keystroke 'ze'
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
