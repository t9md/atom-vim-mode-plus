{getVimState, dispatch, TextData, getView, withMockPlatform, rawKeystroke} = require './spec-helper'
settings = require '../lib/settings'

fdescribe "min DSL used in vim-mode-plus's spec", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim

    runs ->
      jasmine.attachToDOM(editorElement)

  afterEach ->
    vimState.resetNormalMode()

  describe "old exisisting spec options", ->
    beforeEach ->
      set text: "abc", cursor: [0, 0]

    it "toggle and move right", ->
      ensure "~", text: "Abc", cursor: [0, 1]

  describe "new 'textC' spec options with explanatory ensure", ->
    beforeEach ->
      set textC: "|abc"
      ensure text: "abc", cursor: [0, 0] # explanatory purpose

    it "toggle and move right", ->
      ensure "~", textC: "A|bc"
      ensure text: "Abc", cursor: [0, 1] # explanatory purpose

  describe "multi-low, multi-cursor case", ->
    beforeEach ->
      set
        textC: """
        |ab|cde|fg
        hi|jklmn
        opqrstu\n
        """

      ensure
        text: """
        abcdefg
        hijklmn
        opqrstu\n
        """
        cursor: [[0, 0], [0, 2], [0, 5], [1, 2]]

    it "toggle and move right", ->
      ensure '~',
        textC: """
        A|bC|deF|g
        hiJ|klmn
        opqrstu\n
        """

      ensure
        text: """
        AbCdeFg
        hiJklmn
        opqrstu\n
        """
        cursor: [[0, 1], [0, 3], [0, 6], [1, 3]]
