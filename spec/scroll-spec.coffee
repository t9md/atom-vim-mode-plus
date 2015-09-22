# Refactoring status: 5%
{getVimState} = require './spec-helper'

describe "Scrolling", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      vimState.activate('reset')
      {set, ensure, keystroke} = vim

  describe "scrolling keybindings", ->
    beforeEach ->
      editor.setText("1\n2\n3\n4\n5\n6\n7\n8\n9\n10")
      spyOn(editor, 'getFirstVisibleScreenRow').andReturn(2)
      spyOn(editor, 'getLastVisibleScreenRow').andReturn(8)
      spyOn(editor, 'getLineHeightInPixels').andReturn(10)
      spyOn(editor, 'getScrollTop').andReturn(100)
      spyOn(editor, 'setScrollTop')

    describe "the ctrl-e keybinding", ->
      beforeEach ->
        spyOn(editor, 'getCursorScreenPosition').andReturn({row: 3, column: 0})
        spyOn(editor, 'setCursorScreenPosition')

      it "moves the screen down by one and keeps cursor onscreen", ->
        ensure [ctrl: 'e'], called: [
            {func: editor.setScrollTop, with: 110},
            {func: editor.setCursorScreenPosition, with: [4, 0]}
          ]

    describe "the ctrl-y keybinding", ->
      beforeEach ->
        spyOn(editor, 'getCursorScreenPosition').andReturn({row: 6, column: 0})
        spyOn(editor, 'setCursorScreenPosition')

      it "moves the screen up by one and keeps the cursor onscreen", ->
        ensure [ctrl: 'y'], called: [
            {func: editor.setScrollTop, with: 90},
            {func: editor.setCursorScreenPosition, with: [5, 0]}
          ]

  describe "scroll cursor keybindings", ->
    beforeEach ->
      text = ""
      for i in [1..200]
        text += "#{i}\n"
      editor.setText(text)

      spyOn(editor, 'moveToFirstCharacterOfLine')
      spyOn(editor, 'getLineHeightInPixels').andReturn(20)
      spyOn(editor, 'setScrollTop')
      spyOn(editor, 'getHeight').andReturn(200)
      spyOn(editor, 'getFirstVisibleScreenRow').andReturn(90)
      spyOn(editor, 'getLastVisibleScreenRow').andReturn(110)

    describe "the z<CR> keybinding", ->
      keydownCodeForEnter = '\r'

      beforeEach ->
        spyOn(editor, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the top of the window and moves cursor to first non-blank in the line", ->
        keystroke ['z', keydownCodeForEnter]
        expect(editor.setScrollTop).toHaveBeenCalledWith(960)
        expect(editor.moveToFirstCharacterOfLine).toHaveBeenCalled()

    describe "the zt keybinding", ->
      beforeEach ->
        spyOn(editor, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the top of the window and leave cursor in the same column", ->
        keystroke 'zt'
        expect(editor.setScrollTop).toHaveBeenCalledWith(960)
        expect(editor.moveToFirstCharacterOfLine).not.toHaveBeenCalled()

    describe "the z. keybinding", ->
      beforeEach ->
        spyOn(editor, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the center of the window and moves cursor to first non-blank in the line", ->
        keystroke 'z.'
        expect(editor.setScrollTop).toHaveBeenCalledWith(900)
        expect(editor.moveToFirstCharacterOfLine).toHaveBeenCalled()

    describe "the zz keybinding", ->
      beforeEach ->
        spyOn(editor, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the center of the window and leave cursor in the same column", ->
        keystroke 'zz'
        expect(editor.setScrollTop).toHaveBeenCalledWith(900)
        expect(editor.moveToFirstCharacterOfLine).not.toHaveBeenCalled()

    describe "the z- keybinding", ->
      beforeEach ->
        spyOn(editor, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the bottom of the window and moves cursor to first non-blank in the line", ->
        keystroke 'z-'
        expect(editor.setScrollTop).toHaveBeenCalledWith(860)
        expect(editor.moveToFirstCharacterOfLine).toHaveBeenCalled()

    describe "the zb keybinding", ->
      beforeEach ->
        spyOn(editor, 'pixelPositionForScreenPosition').andReturn({top: 1000, left: 0})

      it "moves the screen to position cursor at the bottom of the window and leave cursor in the same column", ->
        keystroke 'zb'
        expect(editor.setScrollTop).toHaveBeenCalledWith(860)
        expect(editor.moveToFirstCharacterOfLine).not.toHaveBeenCalled()

  describe "horizontal scroll cursor keybindings", ->
    beforeEach ->
      editor.setWidth(600)
      editor.setLineHeightInPixels(10)
      editor.setDefaultCharWidth(10)
      text = ""
      for i in [100..199]
        text += "#{i} "
      editor.setText(text)
      editor.setCursorBufferPosition([0, 0])

    describe "the zs keybinding", ->
      zsPos = (pos) ->
        editor.setCursorBufferPosition([0, pos])
        keystroke 'zs'
        editor.getScrollLeft()

      startPosition = NaN

      beforeEach ->
        startPosition = editor.getScrollLeft()

      it "does nothing near the start of the line", ->
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
        expect(pos340).toBeLessThan(posEnd)
        pos342 = zsPos(342)
        expect(pos342 - pos340).toEqual(20)

      it "does nothing if all lines are short", ->
        editor.setText('short')
        startPosition = editor.getScrollLeft()
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
        editor.getScrollLeft()

      startPosition = NaN

      beforeEach ->
        startPosition = editor.getScrollLeft()

      it "does nothing near the start of the line", ->
        pos1 = zePos(1)
        expect(pos1).toEqual(startPosition)

        pos40 = zePos(40)
        expect(pos40).toEqual(startPosition)

      it "moves the cursor the nearest it can to the right edge of the editor", ->
        pos110 = zePos(110)
        expect(pos110).toBeGreaterThan(startPosition)

        pos109 = zePos(109)
        expect(pos110 - pos109).toEqual(10)

      it "does nothing when very near the end of the line", ->
        posEnd = zePos(399)
        expect(editor.getCursorBufferPosition()).toEqual [0, 399]

        pos397 = zePos(397)
        expect(pos397).toEqual(posEnd)
        expect(editor.getCursorBufferPosition()).toEqual [0, 397]

        pos380 = zePos(380)
        expect(pos380).toBeLessThan(posEnd)

        pos382 = zePos(382)
        expect(pos382 - pos380).toEqual(20)

      it "does nothing if all lines are short", ->
        editor.setText('short')
        startPosition = editor.getScrollLeft()
        pos1 = zePos(1)
        expect(pos1).toEqual(startPosition)
        expect(editor.getCursorBufferPosition()).toEqual [0, 1]
        pos10 = zePos(10)
        expect(pos10).toEqual(startPosition)
        expect(editor.getCursorBufferPosition()).toEqual [0, 4]
