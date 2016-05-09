{getVimState, dispatch} = require './spec-helper'
settings = require '../lib/settings'

describe "Operator Increase", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim

  afterEach ->
    vimState.resetNormalMode()

  describe "the ctrl-a/ctrl-x keybindings", ->
    beforeEach ->
      set
        text: '123\nab45\ncd-67ef\nab-5\na-bcdef'
        cursorBuffer: [[0, 0], [1, 0], [2, 0], [3, 3], [4, 0]]

    describe "increasing numbers", ->
      describe "normal-mode", ->
        it "increases the next number", ->
          ensure 'ctrl-a',
            text: '124\nab46\ncd-66ef\nab-4\na-bcdef'
            cursorBuffer: [[0, 2], [1, 3], [2, 4], [3, 3], [4, 0]]

        it "repeats with .", ->
          ensure 'ctrl-a .',
            text: '125\nab47\ncd-65ef\nab-3\na-bcdef'
            cursorBuffer: [[0, 2], [1, 3], [2, 4], [3, 3], [4, 0]]

        it "can have a count", ->
          ensure '5 ctrl-a',
            cursorBuffer: [[0, 2], [1, 3], [2, 4], [3, 2], [4, 0]]
            text: '128\nab50\ncd-62ef\nab0\na-bcdef'

        it "can make a negative number positive, change number of digits", ->
          ensure '9 9 ctrl-a',
            text: '222\nab144\ncd32ef\nab94\na-bcdef'
            cursorBuffer: [[0, 2], [1, 4], [2, 3], [3, 3], [4, 0]]

        it "does nothing when cursor is after the number", ->
          set cursorBuffer: [2, 5]
          ensure 'ctrl-a',
            text: '123\nab45\ncd-67ef\nab-5\na-bcdef'
            cursorBuffer: [[2, 5]]

        it "does nothing on an empty line", ->
          set
            text: '\n'
            cursorBuffer: [[0, 0], [1, 0]]
          ensure 'ctrl-a',
            text: '\n'
            cursorBuffer: [[0, 0], [1, 0]]

        it "honours the vim-mode-plus.numberRegex setting", ->
          set
            text: '123\nab45\ncd -67ef\nab-5\na-bcdef'
            cursorBuffer: [[0, 0], [1, 0], [2, 0], [3, 3], [4, 0]]
          settings.set('numberRegex', '(?:\\B-)?[0-9]+')
          ensure 'ctrl-a',
            cursorBuffer: [[0, 2], [1, 3], [2, 5], [3, 3], [4, 0]]
            text: '124\nab46\ncd -66ef\nab-6\na-bcdef'
      describe "visual-mode", ->
        beforeEach ->
          set
            text: """
              1 2 3
              1 2 3
              1 2 3
              1 2 3
              """
        it "increase number in characterwise selected range", ->
          set cursor: [0, 2]
          ensure 'v 2 j ctrl-a',
            text: """
              1 3 4
              2 3 4
              2 3 3
              1 2 3
              """
            selectedText: "3 4\n2 3 4\n2 3"
            cursor: [2, 3]
        it "increase number in characterwise selected range when multiple cursors", ->
          set cursor: [0, 2], addCursor: [2, 2]
          ensure 'v 1 0 ctrl-a',
            text: """
              1 12 3
              1 2 3
              1 12 3
              1 2 3
              """
            selectedTextOrdered: ["12", "12"]
            selectedBufferRangeOrdered: [
                [[0, 2], [0, 4]]
                [[2, 2], [2, 4]]
              ]
        it "increase number in linewise selected range", ->
          set cursor: [0, 0]
          ensure 'V 2 j ctrl-a',
            text: """
              2 3 4
              2 3 4
              2 3 4
              1 2 3
              """
            selectedText: "2 3 4\n2 3 4\n2 3 4\n"
            cursor: [3, 0]
        it "increase number in blockwise selected range", ->
          set cursor: [1, 2]
          ensure 'ctrl-v 2 l 2 j ctrl-a',
            text: """
              1 2 3
              1 3 4
              1 3 4
              1 3 4
              """
            selectedTextOrdered: ["3 4", "3 4", "3 4"]
            selectedBufferRangeOrdered: [
                [[1, 2], [1, 5]],
                [[2, 2], [2, 5]],
                [[3, 2], [3, 5]],
              ]
    describe "decreasing numbers", ->
      describe "normal-mode", ->
        it "decreases the next number", ->
          ensure 'ctrl-x',
            text: '122\nab44\ncd-68ef\nab-6\na-bcdef'
            cursorBuffer: [[0, 2], [1, 3], [2, 4], [3, 3], [4, 0]]

        it "repeats with .", ->
          ensure 'ctrl-x .',
            text: '121\nab43\ncd-69ef\nab-7\na-bcdef'
            cursorBuffer: [[0, 2], [1, 3], [2, 4], [3, 3], [4, 0]]

        it "can have a count", ->
          ensure '5 ctrl-x',
            text: '118\nab40\ncd-72ef\nab-10\na-bcdef'
            cursorBuffer: [[0, 2], [1, 3], [2, 4], [3, 4], [4, 0]]

        it "can make a positive number negative, change number of digits", ->
          ensure '9 9 ctrl-x',
            text: '24\nab-54\ncd-166ef\nab-104\na-bcdef'
            cursorBuffer: [[0, 1], [1, 4], [2, 5], [3, 5], [4, 0]]

        it "does nothing when cursor is after the number", ->
          set cursorBuffer: [2, 5]
          ensure 'ctrl-x',
            text: '123\nab45\ncd-67ef\nab-5\na-bcdef'
            cursorBuffer: [[2, 5]]

        it "does nothing on an empty line", ->
          set
            text: '\n'
            cursorBuffer: [[0, 0], [1, 0]]
          ensure 'ctrl-x',
            text: '\n'
            cursorBuffer: [[0, 0], [1, 0]],

        it "honours the vim-mode-plus.numberRegex setting", ->
          set
            text: '123\nab45\ncd -67ef\nab-5\na-bcdef'
            cursorBuffer: [[0, 0], [1, 0], [2, 0], [3, 3], [4, 0]]
          settings.set('numberRegex', '(?:\\B-)?[0-9]+')
          ensure 'ctrl-x',
            text: '122\nab44\ncd -68ef\nab-4\na-bcdef'
            cursorBuffer: [[0, 2], [1, 3], [2, 5], [3, 3], [4, 0]]
      describe "visual-mode", ->
        beforeEach ->
          set
            text: """
              1 2 3
              1 2 3
              1 2 3
              1 2 3
              """
        it "decrease number in characterwise selected range", ->
          set cursor: [0, 2]
          ensure 'v 2 j ctrl-x',
            text: """
              1 1 2
              0 1 2
              0 1 3
              1 2 3
              """
            selectedText: "1 2\n0 1 2\n0 1"
            cursor: [2, 3]
        it "decrease number in characterwise selected range when multiple cursors", ->
          set cursor: [0, 2], addCursor: [2, 2]
          ensure 'v 5 ctrl-x',
            text: """
              1 -3 3
              1 2 3
              1 -3 3
              1 2 3
              """
            selectedTextOrdered: ["-3", "-3"]
            selectedBufferRangeOrdered: [
                [[0, 2], [0, 4]]
                [[2, 2], [2, 4]]
              ]
        it "decrease number in linewise selected range", ->
          set cursor: [0, 0]
          ensure 'V 2 j ctrl-x',
            text: """
              0 1 2
              0 1 2
              0 1 2
              1 2 3
              """
            selectedText: "0 1 2\n0 1 2\n0 1 2\n"
            cursor: [3, 0]
        it "decrease number in blockwise selected rage", ->
          set cursor: [1, 2]
          ensure 'ctrl-v 2 l 2 j ctrl-x',
            text: """
              1 2 3
              1 1 2
              1 1 2
              1 1 2
              """
            selectedTextOrdered: ["1 2", "1 2", "1 2"]
            selectedBufferRangeOrdered: [
                [[1, 2], [1, 5]],
                [[2, 2], [2, 5]],
                [[3, 2], [3, 5]],
              ]

  describe "the 'g ctrl-a', 'g ctrl-x' increment-number, decrement-number", ->
    describe "increment", ->
      beforeEach ->
        set
          text: """
            1 10 0
            0 7 0
            0 0 3
            """
          cursor: [0, 0]
      it "use first number as base number case-1", ->
        set text: "1 1 1", cursor: [0, 0]
        ensure 'g ctrl-a $', text: "1 2 3", mode: 'normal', cursor: [0, 0]
      it "use first number as base number case-2", ->
        set text: "99 1 1", cursor: [0, 0]
        ensure 'g ctrl-a $', text: "99 100 101", mode: 'normal', cursor: [0, 0]
      it "can take count, and used as step to each increment", ->
        set text: "5 0 0", cursor: [0, 0]
        ensure '5 g ctrl-a $', text: "5 10 15", mode: 'normal', cursor: [0, 0]
      it "only increment number in target range", ->
        set cursor: [1, 2]
        ensure 'g ctrl-a j',
          text: """
            1 10 0
            0 1 2
            3 4 5
            """
          mode: 'normal'
      it "works in characterwise visual-mode", ->
        set cursor: [1, 2]
        ensure 'v j g ctrl-a',
          text: """
            1 10 0
            0 7 8
            9 10 3
            """
          mode: 'normal'
      it "works in blockwise visual-mode", ->
        set cursor: [0, 2]
        ensure 'ctrl-v 2 j $ g ctrl-a',
          text: """
            1 10 11
            0 12 13
            0 14 15
            """
          mode: 'normal'
      describe "point when finished and repeatable", ->
        beforeEach ->
          set text: "1 0 0 0 0", cursor: [0, 0]
          ensure "v $", selectedText: '1 0 0 0 0'
        it "put cursor on start position when finished and repeatable (case: selection is not reversed)", ->
          ensure selectionIsReversed: false
          ensure 'g ctrl-a', text: "1 2 3 4 5", cursor: [0, 0], mode: 'normal'
          ensure '.', text: "6 7 8 9 10" , cursor: [0, 0]
        it "put cursor on start position when finished and repeatable (case: selection is reversed)", ->
          ensure 'o', selectionIsReversed: true
          ensure 'g ctrl-a', text: "1 2 3 4 5", cursor: [0, 0], mode: 'normal'
          ensure '.', text: "6 7 8 9 10" , cursor: [0, 0]
    describe "decrement", ->
      beforeEach ->
        set
          text: """
            14 23 13
            10 20 13
            13 13 16
            """
          cursor: [0, 0]
      it "use first number as base number case-1", ->
        set text: "10 1 1"
        ensure 'g ctrl-x $', text: "10 9 8", mode: 'normal', cursor: [0, 0]
      it "use first number as base number case-2", ->
        set text: "99 1 1"
        ensure 'g ctrl-x $', text: "99 98 97", mode: 'normal', cursor: [0, 0]
      it "can take count, and used as step to each increment", ->
        set text: "5 0 0", cursor: [0, 0]
        ensure '5 g ctrl-x $', text: "5 0 -5", mode: 'normal', cursor: [0, 0]
      it "only decrement number in target range", ->
        set cursor: [1, 3]
        ensure 'g ctrl-x j',
          text: """
            14 23 13
            10 9 8
            7 6 5
            """
          mode: 'normal'
      it "works in characterwise visual-mode", ->
        set cursor: [1, 3]
        ensure 'v j l g ctrl-x',
          text: """
            14 23 13
            10 20 19
            18 17 16
            """
          mode: 'normal'
      it "works in blockwise visual-mode", ->
        set cursor: [0, 3]
        ensure 'ctrl-v 2 j l g ctrl-x',
          text: """
            14 23 13
            10 22 13
            13 21 16
            """
          mode: 'normal'
