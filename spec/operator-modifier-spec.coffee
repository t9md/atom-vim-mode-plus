{getVimState, dispatch, TextData, getView, withMockPlatform, rawKeystroke} = require './spec-helper'
settings = require '../lib/settings'

describe "Operator modifier", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim

    runs ->
      jasmine.attachToDOM(editorElement)

  describe "operator-modifier to force wise", ->
    beforeEach ->
      set
        text: """
        012345 789
        ABCDEF EFG
        """
    describe "operator-modifier-characterwise", ->
      describe "when target is linewise", ->
        it "operate characterwisely and exclusively", ->
          set cursor: [0, 1]
          ensure "d v j",
            text: """
            0BCDEF EFG
            """
      describe "when target is characterwise", ->
        it "operate inclusively for exclusive target", ->
          set cursor: [0, 9]
          ensure "d v b",
            cursor: [0, 6]
            text_: """
            012345_
            ABCDEF EFG
            """
        it "operate exclusively for inclusive target", ->
          set cursor: [0, 0]
          ensure "d v e",
            cursor: [0, 0]
            text: """
            5 789
            ABCDEF EFG
            """
    describe "operator-modifier-linewise", ->
      it "operate linewisely for characterwise target", ->
        set cursor: [0, 1]
        ensure ['d V /', search: 'DEF'],
          cursor: [0, 0]
          text: ""
