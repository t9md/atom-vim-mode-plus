{getVimState, dispatch, TextData} = require './spec-helper'
settings = require '../lib/settings'
globalState = require '../lib/global-state'

describe "Motion Find", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, _vim) ->
      vimState = state # to refer as vimState later.
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = _vim

  afterEach ->
    vimState.resetNormalMode()

  describe 'the f/F keybindings', ->
    beforeEach ->
      set
        text: "abcabcabcabc\n"
        cursor: [0, 0]

    it 'moves to the first specified character it finds', ->
      ensure ['f', char: 'c'], cursor: [0, 2]

    it 'moves backwards to the first specified character it finds', ->
      set cursor: [0, 2]
      ensure ['F', char: 'a'], cursor: [0, 0]

    it 'respects count forward', ->
      ensure ['2f', char: 'a'], cursor: [0, 6]

    it 'respects count backward', ->
      cursor: [0, 6]
      ensure ['2F', char: 'a'], cursor: [0, 0]

    it "doesn't move if the character specified isn't found", ->
      ensure ['f', char: 'd'], cursor: [0, 0]

    it "doesn't move if there aren't the specified count of the specified character", ->
      ensure ['10f', char: 'a'], cursor: [0, 0]
      # a bug was making this behaviour depend on the count
      ensure ['11f', char: 'a'], cursor: [0, 0]
      # and backwards now
      set cursor: [0, 6]
      ensure ['10F', char: 'a'], cursor: [0, 6]
      ensure ['11F', char: 'a'], cursor: [0, 6]

    it "composes with d", ->
      set cursor: [0, 3]
      ensure ['d2f', char: 'a'], text: 'abcbc\n'

    it "F behaves exclusively when composes with operator", ->
      set cursor: [0, 3]
      ensure ['dF', char: 'a'], text: 'abcabcabc\n'

  describe 'the t/T keybindings', ->
    beforeEach ->
      set
        text: "abcabcabcabc\n"
        cursor: [0, 0]

    it 'moves to the character previous to the first specified character it finds', ->
      ensure ['t', char: 'a'], cursor: [0, 2]
      # or stays put when it's already there
      ensure ['t', char: 'a'], cursor: [0, 2]

    it 'moves backwards to the character after the first specified character it finds', ->
      set cursor: [0, 2]
      ensure ['T', char: 'a'], cursor: [0, 1]

    it 'respects count forward', ->
      ensure ['2t', char: 'a'], cursor: [0, 5]

    it 'respects count backward', ->
      set cursor: [0, 6]
      ensure ['2T', char: 'a'], cursor: [0, 1]

    it "doesn't move if the character specified isn't found", ->
      ensure ['t', char: 'd'], cursor: [0, 0]

    it "doesn't move if there aren't the specified count of the specified character", ->
      ensure ['10t', char: 'd'], cursor: [0, 0]
      # a bug was making this behaviour depend on the count
      ensure ['11t', char: 'a'], cursor: [0, 0]
      # and backwards now
      set cursor: [0, 6]
      ensure ['10T', char: 'a'], cursor: [0, 6]
      ensure ['11T', char: 'a'], cursor: [0, 6]

    it "composes with d", ->
      set cursor: [0, 3]
      ensure ['d2t', char: 'b'],
        text: 'abcbcabc\n'

    it "selects character under cursor even when no movement happens", ->
      set cursor: [0, 0]
      ensure ['dt', char: 'b'],
        text: 'bcabcabcabc\n'

    it "T behaves exclusively when composes with operator", ->
      set cursor: [0, 3]
      ensure ['dT', char: 'b'],
        text: 'ababcabcabc\n'

    it "T don't delete character under cursor even when no movement happens", ->
      set cursor: [0, 3]
      ensure ['dT', char: 'c'],
        text: 'abcabcabcabc\n'

  describe 'the ; and , keybindings', ->
    beforeEach ->
      set
        text: "abcabcabcabc\n"
        cursor: [0, 0]

    it "repeat f in same direction", ->
      ensure ['f', char: 'c'], cursor: [0, 2]
      ensure ';', cursor: [0, 5]
      ensure ';', cursor: [0, 8]

    it "repeat F in same direction", ->
      set cursor: [0, 10]
      ensure ['F', char: 'c'], cursor: [0, 8]
      ensure ';', cursor: [0, 5]
      ensure ';', cursor: [0, 2]

    it "repeat f in opposite direction", ->
      set cursor: [0, 6]
      ensure ['f', char: 'c'], cursor: [0, 8]
      ensure ',', cursor: [0, 5]
      ensure ',', cursor: [0, 2]

    it "repeat F in opposite direction", ->
      set cursor: [0, 4]
      ensure ['F', char: 'c'], cursor: [0, 2]
      ensure ',', cursor: [0, 5]
      ensure ',', cursor: [0, 8]

    it "alternate repeat f in same direction and reverse", ->
      ensure ['f', char: 'c'], cursor: [0, 2]
      ensure ';', cursor: [0, 5]
      ensure ',', cursor: [0, 2]

    it "alternate repeat F in same direction and reverse", ->
      set cursor: [0, 10]
      ensure ['F', char: 'c'], cursor: [0, 8]
      ensure ';', cursor: [0, 5]
      ensure ',', cursor: [0, 8]

    it "repeat t in same direction", ->
      ensure ['t', char: 'c'], cursor: [0, 1]
      ensure ';', cursor: [0, 4]

    it "repeat T in same direction", ->
      set cursor: [0, 10]
      ensure ['T', char: 'c'], cursor: [0, 9]
      ensure ';', cursor: [0, 6]

    it "repeat t in opposite direction first, and then reverse", ->
      set cursor: [0, 3]
      ensure ['t', char: 'c'], cursor: [0, 4]
      ensure ',', cursor: [0, 3]
      ensure ';', cursor: [0, 4]

    it "repeat T in opposite direction first, and then reverse", ->
      set cursor: [0, 4]
      ensure ['T', char: 'c'], cursor: [0, 3]
      ensure ',', cursor: [0, 4]
      ensure ';', cursor: [0, 3]

    it "repeat with count in same direction", ->
      set cursor: [0, 0]
      ensure ['f', char: 'c'], cursor: [0, 2]
      ensure '2;', cursor: [0, 8]

    it "repeat with count in reverse direction", ->
      set cursor: [0, 6]
      ensure ['f', char: 'c'], cursor: [0, 8]
      ensure '2,', cursor: [0, 2]

    it "shares the most recent find/till command with other editors", ->
      getVimState (otherVimState, other) ->
        set
          text: "a baz bar\n"
          cursor: [0, 0]

        other.set
          text: "foo bar baz",
          cursor: [0, 0]
        otherEditor = otherVimState.editor

        pane = atom.workspace.getActivePane()
        pane.activateItem(editor)

        # by default keyDown and such go in the usual editor
        ensure ['f', char: 'b'], cursor: [0, 2]
        other.ensure cursor: [0, 0]

        # replay same find in the other editor
        pane.activateItem(otherEditor)
        other.keystroke ';'
        ensure cursor: [0, 2]
        other.ensure cursor: [0, 4]

        # do a till in the other editor
        other.keystroke ['t', char: 'r']
        ensure cursor: [0, 2]
        other.ensure cursor: [0, 5]

        # and replay in the normal editor
        pane.activateItem(editor)
        ensure ';', cursor: [0, 7]
        other.ensure cursor: [0, 5]
