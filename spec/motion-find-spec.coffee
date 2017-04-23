{getVimState, dispatch, TextData} = require './spec-helper'
settings = require '../lib/settings'

describe "Motion Find", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    settings.set('useExperimentalFasterInput', true)
    getVimState (state, _vim) ->
      vimState = state # to refer as vimState later.
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = _vim

  describe 'the f/F keybindings', ->
    beforeEach ->
      set
        text: "abcabcabcabc\n"
        cursor: [0, 0]

    it 'moves to the first specified character it finds', ->
      ensure ['f', input: 'c'], cursor: [0, 2]

    it 'extends visual selection in visual-mode and repetable', ->
      ensure 'v', mode: ['visual', 'characterwise']
      ensure ['f', input: 'c'], selectedText: 'abc', cursor: [0, 3]
      ensure ';', selectedText: 'abcabc', cursor: [0, 6]
      ensure ',', selectedText: 'abc', cursor: [0, 3]

    it 'moves backwards to the first specified character it finds', ->
      set cursor: [0, 2]
      ensure ['F', input: 'a'], cursor: [0, 0]

    it 'respects count forward', ->
      ensure ['2 f', input: 'a'], cursor: [0, 6]

    it 'respects count backward', ->
      cursor: [0, 6]
      ensure ['2 F', input: 'a'], cursor: [0, 0]

    it "doesn't move if the character specified isn't found", ->
      ensure ['f', input: 'd'], cursor: [0, 0]

    it "doesn't move if there aren't the specified count of the specified character", ->
      ensure ['1 0 f', input: 'a'], cursor: [0, 0]
      # a bug was making this behaviour depend on the count
      ensure ['1 1 f', input: 'a'], cursor: [0, 0]
      # and backwards now
      set cursor: [0, 6]
      ensure ['1 0 F', input: 'a'], cursor: [0, 6]
      ensure ['1 1 F', input: 'a'], cursor: [0, 6]

    it "composes with d", ->
      set cursor: [0, 3]
      ensure ['d 2 f', input: 'a'], text: 'abcbc\n'

    it "F behaves exclusively when composes with operator", ->
      set cursor: [0, 3]
      ensure ['d F', input: 'a'], text: 'abcabcabc\n'

  describe 'the t/T keybindings', ->
    beforeEach ->
      set
        text: "abcabcabcabc\n"
        cursor: [0, 0]

    it 'moves to the character previous to the first specified character it finds', ->
      ensure ['t', input: 'a'], cursor: [0, 2]
      # or stays put when it's already there
      ensure ['t', input: 'a'], cursor: [0, 2]

    it 'moves backwards to the character after the first specified character it finds', ->
      set cursor: [0, 2]
      ensure ['T', input: 'a'], cursor: [0, 1]

    it 'respects count forward', ->
      ensure ['2 t', input: 'a'], cursor: [0, 5]

    it 'respects count backward', ->
      set cursor: [0, 6]
      ensure ['2 T', input: 'a'], cursor: [0, 1]

    it "doesn't move if the character specified isn't found", ->
      ensure ['t', input: 'd'], cursor: [0, 0]

    it "doesn't move if there aren't the specified count of the specified character", ->
      ensure ['1 0 t', input: 'd'], cursor: [0, 0]
      # a bug was making this behaviour depend on the count
      ensure ['1 1 t', input: 'a'], cursor: [0, 0]
      # and backwards now
      set cursor: [0, 6]
      ensure ['1 0 T', input: 'a'], cursor: [0, 6]
      ensure ['1 1 T', input: 'a'], cursor: [0, 6]

    it "composes with d", ->
      set cursor: [0, 3]
      ensure ['d 2 t', input: 'b'],
        text: 'abcbcabc\n'

    it "delete char under cursor even when no movement happens since it's inclusive motion", ->
      set cursor: [0, 0]
      ensure ['d t', input: 'b'],
        text: 'bcabcabcabc\n'
    it "do nothing when inclusiveness inverted by v operator-modifier", ->
      text: "abcabcabcabc\n"
      set cursor: [0, 0]
      ensure ['d v t', input: 'b'],
        text: 'abcabcabcabc\n'

    it "T behaves exclusively when composes with operator", ->
      set cursor: [0, 3]
      ensure ['d T', input: 'b'],
        text: 'ababcabcabc\n'

    it "T don't delete character under cursor even when no movement happens", ->
      set cursor: [0, 3]
      ensure ['d T', input: 'c'],
        text: 'abcabcabcabc\n'

  describe 'the ; and , keybindings', ->
    beforeEach ->
      set
        text: "abcabcabcabc\n"
        cursor: [0, 0]

    it "repeat f in same direction", ->
      ensure ['f', input: 'c'], cursor: [0, 2]
      ensure ';', cursor: [0, 5]
      ensure ';', cursor: [0, 8]

    it "repeat F in same direction", ->
      set cursor: [0, 10]
      ensure ['F', input: 'c'], cursor: [0, 8]
      ensure ';', cursor: [0, 5]
      ensure ';', cursor: [0, 2]

    it "repeat f in opposite direction", ->
      set cursor: [0, 6]
      ensure ['f', input: 'c'], cursor: [0, 8]
      ensure ',', cursor: [0, 5]
      ensure ',', cursor: [0, 2]

    it "repeat F in opposite direction", ->
      set cursor: [0, 4]
      ensure ['F', input: 'c'], cursor: [0, 2]
      ensure ',', cursor: [0, 5]
      ensure ',', cursor: [0, 8]

    it "alternate repeat f in same direction and reverse", ->
      ensure ['f', input: 'c'], cursor: [0, 2]
      ensure ';', cursor: [0, 5]
      ensure ',', cursor: [0, 2]

    it "alternate repeat F in same direction and reverse", ->
      set cursor: [0, 10]
      ensure ['F', input: 'c'], cursor: [0, 8]
      ensure ';', cursor: [0, 5]
      ensure ',', cursor: [0, 8]

    it "repeat t in same direction", ->
      ensure ['t', input: 'c'], cursor: [0, 1]
      ensure ';', cursor: [0, 4]

    it "repeat T in same direction", ->
      set cursor: [0, 10]
      ensure ['T', input: 'c'], cursor: [0, 9]
      ensure ';', cursor: [0, 6]

    it "repeat t in opposite direction first, and then reverse", ->
      set cursor: [0, 3]
      ensure ['t', input: 'c'], cursor: [0, 4]
      ensure ',', cursor: [0, 3]
      ensure ';', cursor: [0, 4]

    it "repeat T in opposite direction first, and then reverse", ->
      set cursor: [0, 4]
      ensure ['T', input: 'c'], cursor: [0, 3]
      ensure ',', cursor: [0, 4]
      ensure ';', cursor: [0, 3]

    it "repeat with count in same direction", ->
      set cursor: [0, 0]
      ensure ['f', input: 'c'], cursor: [0, 2]
      ensure '2 ;', cursor: [0, 8]

    it "repeat with count in reverse direction", ->
      set cursor: [0, 6]
      ensure ['f', input: 'c'], cursor: [0, 8]
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

        pane = atom.workspace.getActivePane()
        pane.activateItem(editor)

    it "shares the most recent find/till command with other editors", ->
      ensure ['f', input: 'b'], cursor: [0, 2]
      other.ensure cursor: [0, 0]

      # replay same find in the other editor
      pane.activateItem(otherEditor)
      other.keystroke ';'
      ensure cursor: [0, 2]
      other.ensure cursor: [0, 4]

      # do a till in the other editor
      other.keystroke ['t', input: 'r']
      ensure cursor: [0, 2]
      other.ensure cursor: [0, 5]

      # and replay in the normal editor
      pane.activateItem(editor)
      ensure ';', cursor: [0, 7]
      other.ensure cursor: [0, 5]

    it "is still repeatable after original editor was destroyed", ->
      ensure ['f', input: 'b'], cursor: [0, 2]
      other.ensure cursor: [0, 0]

      pane.activateItem(otherEditor)
      editor.destroy()
      expect(editor.isAlive()).toBe(false)
      other.ensure ';', cursor: [0, 4]
      other.ensure ';', cursor: [0, 8]
      other.ensure ',', cursor: [0, 4]
