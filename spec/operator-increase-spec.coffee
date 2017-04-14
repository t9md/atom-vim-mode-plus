{getVimState, dispatch} = require './spec-helper'
settings = require '../lib/settings'

describe "Operator Increase", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, vim) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vim

  describe "the ctrl-a/ctrl-x keybindings", ->
    beforeEach ->
      set
        textC: """
        |123
        |ab45
        |cd-67ef
        ab-|5
        !a-bcdef
        """

    describe "increasing numbers", ->
      describe "normal-mode", ->
        it "increases the next number", ->
          set textC: "|     1 abc"
          ensure 'ctrl-a', textC: '     |2 abc'

        it "increases the next number and repeatable", ->
          ensure 'ctrl-a',
            textC: """
            12|4
            ab4|6
            cd-6|6ef
            ab-|4
            !a-bcdef
            """

          ensure '.',
            textC: """
            12|5
            ab4|7
            cd-6|5ef
            ab-|3
            !a-bcdef
            """

        it "support count", ->
          ensure '5 ctrl-a',
            textC: """
            12|8
            ab5|0
            cd-6|2ef
            ab|0
            !a-bcdef
            """

        it "can make a negative number positive, change number of digits", ->
          ensure '9 9 ctrl-a',
            textC: """
            22|2
            ab14|4
            cd3|2ef
            ab9|4
            |a-bcdef
            """

        it "does nothing when cursor is after the number", ->
          set cursor: [2, 5]
          ensure 'ctrl-a',
            textC: """
            123
            ab45
            cd-67|ef
            ab-5
            a-bcdef
            """

        it "does nothing on an empty line", ->
          set
            textC: """
            |
            !
            """
          ensure 'ctrl-a',
            textC: """
            |
            !
            """

        it "honours the vim-mode-plus.numberRegex setting", ->
          settings.set('numberRegex', '(?:\\B-)?[0-9]+')
          set
            textC:
              """
              |123
              |ab45
              |cd -67ef
              ab-|5
              !a-bcdef
              """
          ensure 'ctrl-a',
            textC:
              """
              12|4
              ab4|6
              cd -6|6ef
              ab-|6
              !a-bcdef
              """
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
            textC: """
              1 |3 4
              2 3 4
              2 3 3
              1 2 3
              """
        it "increase number in characterwise selected range when multiple cursors", ->
          set
            textC: """
              1 |2 3
              1 2 3
              1 !2 3
              1 2 3
              """
          ensure 'v 1 0 ctrl-a',
            textC: """
              1 |12 3
              1 2 3
              1 !12 3
              1 2 3
              """
        it "increase number in linewise selected range", ->
          set cursor: [0, 0]
          ensure 'V 2 j ctrl-a',
            textC: """
              |2 3 4
              2 3 4
              2 3 4
              1 2 3
              """
        it "increase number in blockwise selected range", ->
          set cursor: [1, 2]
          set
            textC: """
              1 2 3
              1 !2 3
              1 2 3
              1 2 3
              """

          ensure 'ctrl-v 2 l 2 j ctrl-a',
            textC: """
              1 2 3
              1 !3 4
              1 3 4
              1 3 4
              """

    describe "decreasing numbers", ->
      describe "normal-mode", ->
        it "decreases the next number and repeatable", ->
          ensure 'ctrl-x',
            textC: """
            12|2
            ab4|4
            cd-6|8ef
            ab-|6
            !a-bcdef
            """

          ensure '.',
            textC: """
            12|1
            ab4|3
            cd-6|9ef
            ab-|7
            !a-bcdef
            """

        it "support count", ->
          ensure '5 ctrl-x',
            textC: """
            11|8
            ab4|0
            cd-7|2ef
            ab-1|0
            !a-bcdef
            """

        it "can make a positive number negative, change number of digits", ->
          ensure '9 9 ctrl-x',
            textC: """
            2|4
            ab-5|4
            cd-16|6ef
            ab-10|4
            !a-bcdef
            """

        it "does nothing when cursor is after the number", ->
          set cursor: [2, 5]
          ensure 'ctrl-x',
            textC: """
            123
            ab45
            cd-67|ef
            ab-5
            a-bcdef
            """

        it "does nothing on an empty line", ->
          set
            textC: """
            |
            !
            """
          ensure 'ctrl-x',
            textC: """
            |
            !
            """

        it "honours the vim-mode-plus.numberRegex setting", ->
          settings.set('numberRegex', '(?:\\B-)?[0-9]+')
          set
            textC: """
            |123
            |ab45
            |cd -67ef
            ab-|5
            !a-bcdef
            """
          ensure 'ctrl-x',
            textC: """
            12|2
            ab4|4
            cd -6|8ef
            ab-|4
            !a-bcdef
            """
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
            textC: """
              1 |1 2
              0 1 2
              0 1 3
              1 2 3
              """
        it "decrease number in characterwise selected range when multiple cursors", ->
          set
            textC: """
              1 |2 3
              1 2 3
              1 !2 3
              1 2 3
              """
          ensure 'v 5 ctrl-x',
            textC: """
              1 |-3 3
              1 2 3
              1 !-3 3
              1 2 3
              """

        it "decrease number in linewise selected range", ->
          set cursor: [0, 0]
          ensure 'V 2 j ctrl-x',
            textC: """
              |0 1 2
              0 1 2
              0 1 2
              1 2 3
              """
        it "decrease number in blockwise selected rage", ->
          set cursor: [1, 2]
          ensure 'ctrl-v 2 l 2 j ctrl-x',
            textC: """
              1 2 3
              1 !1 2
              1 1 2
              1 1 2
              """

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
          textC: """
            1 !10 11
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
