{getVimState, dispatch, TextData, getView, withMockPlatform, rawKeystroke} = require './spec-helper'
settings = require '../lib/settings'

describe "min DSL used in vim-mode-plus's spec", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim

    runs ->
      jasmine.attachToDOM(editorElement)

  describe "old exisisting spec options", ->
    beforeEach ->
      set text: "abc", cursor: [0, 0]

    it "toggle and move right", ->
      ensure "~", text: "Abc", cursor: [0, 1]

  describe "new 'textC' spec options with explanatory ensure", ->
    describe "| represent cursor", ->
      beforeEach ->
        set textC: "|abc"
        ensure text: "abc", cursor: [0, 0] # explanatory purpose

      it "toggle and move right", ->
        ensure "~", textC: "A|bc"
        ensure text: "Abc", cursor: [0, 1] # explanatory purpose

    describe "! represent cursor", ->
      beforeEach ->
        set textC: "!abc"
        ensure text: "abc", cursor: [0, 0] # explanatory purpose

      it "toggle and move right", ->
        ensure "~", textC: "A!bc"
        ensure text: "Abc", cursor: [0, 1] # explanatory purpose

    describe "| and ! is exchangable", ->
      it "both are OK", ->
        set textC: "|abc"
        ensure "~", textC: "A!bc"

        set textC: "a!bc"
        ensure "~", textC: "aB!c"

  describe "multi-low, multi-cursor case", ->
    describe "without ! cursor", ->
      it "last cursor become last one", ->
        set
          textC: """
          |0: line0
          |1: line1
          """

        ensure cursor: [[0, 0], [1, 0]]
        expect(editor.getLastCursor().getBufferPosition()).toEqual([1, 0])

    describe "with ! cursor", ->
      it "last cursor become ! one", ->
        set textC: "|012|345|678"
        ensure textC: "|012|345|678"
        ensure cursor: [[0, 0], [0, 3], [0, 6]]
        expect(editor.getLastCursor().getBufferPosition()).toEqual([0, 6])

        set textC: "!012|345|678"
        ensure textC: "!012|345|678"
        ensure cursor: [[0, 3], [0, 6], [0, 0]]
        expect(editor.getLastCursor().getBufferPosition()).toEqual([0, 0])

        set textC: "|012!345|678"
        ensure textC: "|012!345|678"
        ensure cursor: [[0, 0], [0, 6], [0, 3]]
        expect(editor.getLastCursor().getBufferPosition()).toEqual([0, 3])

        set textC: "|012|345!678"
        ensure textC: "|012|345!678"
        ensure cursor: [[0, 0], [0, 3], [0, 6]]
        expect(editor.getLastCursor().getBufferPosition()).toEqual([0, 6])

    describe "without ! cursor", ->
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
