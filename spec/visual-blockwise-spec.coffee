{getVimState, TextData} = require './spec-helper'

describe "Visual Blockwise", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []
  textInitial = """
    01234567890123456789
    1-------------------
    2----A---------B----
    3----***********---
    4----+++++++++++--
    5----C---------D-
    6-------------------
    """

  textAfterDeleted = """
    01234567890123456789
    1-------------------
    2----
    3----
    4----
    5----
    6-------------------
    """

  textAfterInserted = """
    01234567890123456789
    1-------------------
    2----!!!
    3----!!!
    4----!!!
    5----!!!
    6-------------------
    """

  blockTexts = [
    '56789012345' # 0
    '-----------' # 1
    'A---------B' # 2
    '***********' # 3
    '+++++++++++' # 4
    'C---------D' # 5
    '-----------' # 6
  ]

  textData = new TextData(textInitial)

  selectBlockwise = ->
    set cursor: [2, 5]
    ensure 'v 3 j 1 0 l ctrl-v',
      mode: ['visual', 'blockwise']
      selectedBufferRange: [
        [[2, 5], [2, 16]]
        [[3, 5], [3, 16]]
        [[4, 5], [4, 16]]
        [[5, 5], [5, 16]]
      ]
      selectedText: blockTexts[2..5]

  selectBlockwiseReversely = ->
    set cursor: [2, 15]
    ensure 'v 3 j 1 0 h ctrl-v',
      mode: ['visual', 'blockwise']
      selectedBufferRange: [
        [[2, 5], [2, 16]]
        [[3, 5], [3, 16]]
        [[4, 5], [4, 16]]
        [[5, 5], [5, 16]]
      ]
      selectedText: blockTexts[2..5]

  ensureBlockwiseSelection = (o) ->
    selections = editor.getSelectionsOrderedByBufferPosition()
    if selections.length is 1
      first = last = selections[0]
    else
      [first, others..., last] = selections

    head = switch o.head
      when 'top' then first
      when 'bottom' then last
    bs = vimState.getLastBlockwiseSelection()

    expect(bs.getHeadSelection()).toBe head
    tail = switch o.tail
      when 'top' then first
      when 'bottom' then last
    expect(bs.getTailSelection()).toBe tail

    for s in others ? []
      expect(bs.getHeadSelection()).not.toBe s
      expect(bs.getTailSelection()).not.toBe s

    if o.reversed?
      expect(bs.isReversed()).toBe o.reversed

    if o.headReversed?
      for s in selections
        expect(s.isReversed()).toBe o.headReversed

  beforeEach ->
    getVimState (state, vimEditor) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vimEditor

    runs ->
      set text: textInitial

  describe "j", ->
    beforeEach ->
      set cursor: [3, 5]
      ensure 'v 1 0 l ctrl-v',
        selectedText: blockTexts[3]
        mode: ['visual', 'blockwise']

    it "add selection to down direction", ->
      ensure 'j', selectedText: blockTexts[3..4]
      ensure 'j', selectedText: blockTexts[3..5]

    it "delete selection when blocwise is reversed", ->
      ensure '3 k', selectedTextOrdered: blockTexts[0..3]
      ensure 'j', selectedTextOrdered: blockTexts[1..3]
      ensure '2 j', selectedTextOrdered: blockTexts[3]

    it "keep tail row when reversed status changed", ->
      ensure 'j', selectedText: blockTexts[3..4]
      ensure '2 k', selectedTextOrdered: blockTexts[2..3]

  describe "k", ->
    beforeEach ->
      set cursor: [3, 5]
      ensure 'v 1 0 l ctrl-v',
        selectedText: blockTexts[3]
        mode: ['visual', 'blockwise']

    it "add selection to up direction", ->
      ensure 'k', selectedTextOrdered: blockTexts[2..3]
      ensure 'k', selectedTextOrdered: blockTexts[1..3]

    it "delete selection when blocwise is reversed", ->
      ensure '3 j', selectedTextOrdered: blockTexts[3..6]
      ensure 'k', selectedTextOrdered: blockTexts[3..5]
      ensure '2 k', selectedTextOrdered: blockTexts[3]

  # FIXME add C, D spec for selectBlockwiseReversely() situation
  describe "C", ->
    ensureChange = ->
      ensure 'C',
        mode: 'insert'
        cursor: [[2, 5], [3, 5], [4, 5], [5, 5] ]
        text: textAfterDeleted
      editor.insertText("!!!")
      ensure
        mode: 'insert'
        cursor: [[2, 8], [3, 8], [4, 8], [5, 8]]
        text: textAfterInserted

    it "change-to-last-character-of-line for each selection", ->
      selectBlockwise()
      ensureChange()

    it "[selection reversed] change-to-last-character-of-line for each selection", ->
      selectBlockwiseReversely()
      ensureChange()

  describe "D", ->
    ensureDelete = ->
      ensure 'D',
        text: textAfterDeleted
        cursor: [2, 4]
        mode: 'normal'

    it "delete-to-last-character-of-line for each selection", ->
      selectBlockwise()
      ensureDelete()
    it "[selection reversed] delete-to-last-character-of-line for each selection", ->
      selectBlockwiseReversely()
      ensureDelete()

  describe "I", ->
    beforeEach ->
      selectBlockwise()
    it "enter insert mode with each cursors position set to start of selection", ->
      keystroke 'I'
      editor.insertText "!!!"
      ensure
        text: """
          01234567890123456789
          1-------------------
          2----!!!A---------B----
          3----!!!***********---
          4----!!!+++++++++++--
          5----!!!C---------D-
          6-------------------
          """
        cursor: [
            [2, 8],
            [3, 8],
            [4, 8],
            [5, 8],
          ]
        mode: 'insert'

  describe "A", ->
    beforeEach ->
      selectBlockwise()
    it "enter insert mode with each cursors position set to end of selection", ->
      keystroke 'A'
      editor.insertText "!!!"
      ensure
        text: """
          01234567890123456789
          1-------------------
          2----A---------B!!!----
          3----***********!!!---
          4----+++++++++++!!!--
          5----C---------D!!!-
          6-------------------
          """
        cursor: [
            [2, 19],
            [3, 19],
            [4, 19],
            [5, 19],
          ]

  describe "o and O keybinding", ->
    beforeEach ->
      selectBlockwise()

    describe 'o', ->
      it "change blockwiseHead to opposite side and reverse selection", ->
        keystroke 'o'
        ensureBlockwiseSelection head: 'top', tail: 'bottom', headReversed: true

        keystroke 'o'
        ensureBlockwiseSelection head: 'bottom', tail: 'top', headReversed: false
    describe 'capital O', ->
      it "reverse each selection", ->
        keystroke 'O'
        ensureBlockwiseSelection head: 'bottom', tail: 'top', headReversed: true
        keystroke 'O'
        ensureBlockwiseSelection head: 'bottom', tail: 'top', headReversed: false

  describe "shift from characterwise to blockwise", ->
    describe "when selection is not reversed", ->
      beforeEach ->
        set cursor: [2, 5]
        ensure 'v',
          selectedText: 'A'
          mode: ['visual', 'characterwise']

      it 'case-1', ->
        ensure '3 j ctrl-v',
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            'A'
            '*'
            '+'
            'C'
          ]
        ensureBlockwiseSelection head: 'bottom', tail: 'top', headReversed: false

      it 'case-2', ->
        ensure 'h 3 j ctrl-v',
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            '-A'
            '-*'
            '-+'
            '-C'
          ]
        ensureBlockwiseSelection head: 'bottom', tail: 'top', headReversed: true

      it 'case-3', ->
        ensure '2 h 3 j ctrl-v',
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            '--A'
            '--*'
            '--+'
            '--C'
          ]
        ensureBlockwiseSelection head: 'bottom', tail: 'top', headReversed: true

      it 'case-4', ->
        ensure 'l 3 j ctrl-v',
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            'A-'
            '**'
            '++'
            'C-'
          ]
        ensureBlockwiseSelection head: 'bottom', tail: 'top', headReversed: false
      it 'case-5', ->
        ensure '2 l 3 j ctrl-v',
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            'A--'
            '***'
            '+++'
            'C--'
          ]
        ensureBlockwiseSelection head: 'bottom', tail: 'top', headReversed: false

    describe "when selection is reversed", ->
      beforeEach ->
        set cursor: [5, 5]
        ensure 'v',
          selectedText: 'C'
          mode: ['visual', 'characterwise']

      it 'case-1', ->
        ensure '3 k ctrl-v',
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            'A'
            '*'
            '+'
            'C'
          ]
        ensureBlockwiseSelection head: 'top', tail: 'bottom', headReversed: true

      it 'case-2', ->
        ensure 'h 3 k ctrl-v',
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            '-A'
            '-*'
            '-+'
            '-C'
          ]
        ensureBlockwiseSelection head: 'top', tail: 'bottom', headReversed: true

      it 'case-3', ->
        ensure '2 h 3 k ctrl-v',
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            '--A'
            '--*'
            '--+'
            '--C'
          ]
        ensureBlockwiseSelection head: 'top', tail: 'bottom', headReversed: true

      it 'case-4', ->
        ensure 'l 3 k ctrl-v',
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            'A-'
            '**'
            '++'
            'C-'
          ]
        ensureBlockwiseSelection head: 'top', tail: 'bottom', headReversed: false

      it 'case-5', ->
        ensure '2 l 3 k ctrl-v',
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            'A--'
            '***'
            '+++'
            'C--'
          ]
        ensureBlockwiseSelection head: 'top', tail: 'bottom', headReversed: false

  describe "shift from blockwise to characterwise", ->
    preserveSelection = ->
      selectedText = editor.getSelectedText()
      selectedBufferRange = editor.getSelectedBufferRange()
      cursor = editor.getCursorBufferPosition()
      mode = [vimState.mode, vimState.submode]
      {selectedText, selectedBufferRange, cursor, mode}

    ensureCharacterwiseWasRestored = (keystroke) ->
      ensure keystroke, mode: ['visual', 'characterwise']
      characterwiseState = preserveSelection()
      ensure 'ctrl-v', mode: ['visual', 'blockwise']
      ensure 'v', characterwiseState

    describe "when selection is not reversed", ->
      beforeEach ->
        set cursor: [2, 5]
      it 'case-1', -> ensureCharacterwiseWasRestored('v')
      it 'case-2', -> ensureCharacterwiseWasRestored('v 3 j')
      it 'case-3', -> ensureCharacterwiseWasRestored('v h 3 j')
      it 'case-4', -> ensureCharacterwiseWasRestored('v 2 h 3 j')
      it 'case-5', -> ensureCharacterwiseWasRestored('v l 3 j')
      it 'case-6', -> ensureCharacterwiseWasRestored('v 2 l 3 j')
    describe "when selection is reversed", ->
      beforeEach ->
        set cursor: [5, 5]
      it 'case-1', -> ensureCharacterwiseWasRestored('v')
      it 'case-2', -> ensureCharacterwiseWasRestored('v 3 k')
      it 'case-3', -> ensureCharacterwiseWasRestored('v h 3 k')
      it 'case-4', -> ensureCharacterwiseWasRestored('v 2 h 3 k')
      it 'case-5', -> ensureCharacterwiseWasRestored('v l 3 k')
      it 'case-6', -> ensureCharacterwiseWasRestored('v 2 l 3 k')
      it 'case-7', -> set cursor: [5, 0]; ensureCharacterwiseWasRestored('v 5 l 3 k')

  describe "keep goalColumn", ->
    describe "when passing through blank row", ->
      beforeEach ->
        set
          text: """
          012345678

          ABCDEFGHI\n
          """

      it "when [reversed = false, headReversed = false]", ->
        set cursor: [0, 3]
        ensure "ctrl-v l l l", cursor: [[0, 7]], selectedTextOrdered: ["3456"]
        ensureBlockwiseSelection head: 'bottom', tail: 'top', reversed: false, headReversed: false

        ensure "j", cursor: [[0, 0], [1, 0]], selectedTextOrdered: ["0123", ""]
        ensureBlockwiseSelection head: 'bottom', tail: 'top', reversed: false, headReversed: true

        ensure "j", cursor: [[0, 7], [1, 0], [2, 7]], selectedTextOrdered: ["3456", "", "DEFG"]
        ensureBlockwiseSelection head: 'bottom', tail: 'top', reversed: false, headReversed: false

      it "when [reversed = true, headReversed = true]", ->
        set cursor: [2, 6]
        ensure "ctrl-v h h h", cursor: [[2, 3]], selectedTextOrdered: ["DEFG"]
        ensureBlockwiseSelection head: 'top', tail: 'bottom', reversed: true, headReversed: true

        ensure "k", cursor: [[1, 0], [2, 0]], selectedTextOrdered: ["", "ABCDEFG"]
        ensureBlockwiseSelection head: 'top', tail: 'bottom', reversed: true, headReversed: true

        ensure "k", cursor: [[0, 3], [1, 0], [2, 3]], selectedTextOrdered: ["3456", "", "DEFG"]
        ensureBlockwiseSelection head: 'top', tail: 'bottom', reversed: true, headReversed: true

      it "when [reversed = false, headReversed = true]", ->
        set cursor: [0, 6]
        ensure "ctrl-v h h h", cursor: [[0, 3]], selectedTextOrdered: ["3456"]
        ensureBlockwiseSelection head: 'bottom', tail: 'top', reversed: true, headReversed: true

        ensure "j", cursor: [[0, 0], [1, 0]], selectedTextOrdered: ["0123456", ""]
        ensureBlockwiseSelection head: 'bottom', tail: 'top', reversed: false, headReversed: true

        ensure "j", cursor: [[0, 3], [1, 0], [2, 3]], selectedTextOrdered: ["3456", "", "DEFG"]
        ensureBlockwiseSelection head: 'bottom', tail: 'top', reversed: false, headReversed: true

      it "when [reversed = true, headReversed = false]", ->
        set cursor: [2, 3]
        ensure "ctrl-v l l l", cursor: [[2, 7]], selectedTextOrdered: ["DEFG"]
        ensureBlockwiseSelection head: 'top', tail: 'bottom', reversed: false, headReversed: false

        ensure "k", cursor: [[1, 0], [2, 0]], selectedTextOrdered: ["", "ABCD"]
        ensureBlockwiseSelection head: 'top', tail: 'bottom', reversed: true, headReversed: true

        ensure "k", cursor: [[0, 7], [1, 0], [2, 7]], selectedTextOrdered:  ["3456", "", "DEFG"]
        ensureBlockwiseSelection head: 'top', tail: 'bottom', reversed: true, headReversed: false

    describe "when head cursor position is less than original goal column", ->
      beforeEach ->
        set
          text: """
          012345678901234567890123
                 xxx01234
          012345678901234567890123\n
          """

      describe "[tailColumn < headColum], goalColumn isnt Infinity", ->
        it "shrinks block till head column by keeping goalColumn", ->
          set cursor: [0, 10] # j, k motion keep goalColumn so starting `10` column means goalColumn is 10.
          ensure "ctrl-v 1 0 l", selectedTextOrdered: ["01234567890"], cursor: [[0, 21]]
          ensure "j", selectedTextOrdered: ["012345", "01234"], cursor: [[0, 16], [1, 15]]
          ensure "j", selectedTextOrdered: ["01234567890", "01234", "01234567890"], cursor: [[0, 21], [1, 15], [2, 21]]
        it "shrinks block till head column by keeping goalColumn", ->
          set cursor: [2, 10]
          ensure "ctrl-v 1 0 l", selectedTextOrdered: ["01234567890"], cursor: [[2, 21]]
          ensure "k", selectedTextOrdered: ["01234", "012345"], cursor: [[1, 15], [2, 16]]
          ensure "k", selectedTextOrdered: ["01234567890", "01234", "01234567890"], cursor: [[0, 21], [1, 15], [2, 21]]
      describe "[tailColumn < headColum], goalColumn is Infinity", ->
        it "keep each member selection selected till end-of-line( No shrink )", ->
          set cursor: [0, 10] # $ motion set goalColumn to Infinity
          ensure "ctrl-v $", selectedTextOrdered: ["01234567890123"], cursor: [[0, 24]]
          ensure "j", selectedTextOrdered: ["01234567890123", "01234"], cursor: [[0, 24], [1, 15]]
          ensure "j", selectedTextOrdered: ["01234567890123", "01234", "01234567890123"], cursor: [[0, 24], [1, 15], [2, 24]]
        it "keep each member selection selected till end-of-line( No shrink )", ->
          set cursor: [2, 10]
          ensure "ctrl-v $", selectedTextOrdered: ["01234567890123"], cursor: [[2, 24]]
          ensure "k", selectedTextOrdered: ["01234", "01234567890123"], cursor: [[1, 15], [2, 24]]
          ensure "k", selectedTextOrdered: ["01234567890123", "01234", "01234567890123"], cursor: [[0, 24], [1, 15], [2, 24]]
      describe "[tailColumn > headColum], goalColumn isnt Infinity", ->
        it "Respect actual head column over goalColumn", ->
          set cursor: [0, 20] # j, k motion keep goalColumn so starting `10` column means goalColumn is 10.
          ensure "ctrl-v l l", selectedTextOrdered: ["012"], cursor: [[0, 23]]
          ensure "j", selectedTextOrdered: ["567890", ""], cursor: [[0, 15], [1, 15]]
          ensure "j", selectedTextOrdered: ["012", "", "012"], cursor: [[0, 23], [1, 15], [2, 23]]
        it "Respect actual head column over goalColumn", ->
          set cursor: [2, 20] # j, k motion keep goalColumn so starting `10` column means goalColumn is 10.
          ensure "ctrl-v l l", selectedTextOrdered: ["012"], cursor: [[2, 23]]
          ensure "k", selectedTextOrdered: ["", "567890"], cursor: [[1, 15], [2, 15]]
          ensure "k", selectedTextOrdered: ["012", "", "012"], cursor: [[0, 23], [1, 15], [2, 23]]
      describe "[tailColumn > headColum], goalColumn is Infinity", ->
        it "Respect actual head column over goalColumn", ->
          set cursor: [0, 20] # j, k motion keep goalColumn so starting `10` column means goalColumn is 10.
          ensure "ctrl-v $", selectedTextOrdered: ["0123"], cursor: [[0, 24]]
          ensure "j", selectedTextOrdered: ["567890", ""], cursor: [[0, 15], [1, 15]]
          ensure "j", selectedTextOrdered: ["0123", "", "0123"], cursor: [[0, 24], [1, 15], [2, 24]]
        it "Respect actual head column over goalColumn", ->
          set cursor: [2, 20] # j, k motion keep goalColumn so starting `10` column means goalColumn is 10.
          ensure "ctrl-v $", selectedTextOrdered: ["0123"], cursor: [[2, 24]]
          ensure "k", selectedTextOrdered: ["", "567890"], cursor: [[1, 15], [2, 15]]
          ensure "k", selectedTextOrdered: ["0123", "", "0123"], cursor: [[0, 24], [1, 15], [2, 24]]

  # [FIXME] not appropriate put here, re-consider all spec file layout later.
  describe "gv feature", ->
    preserveSelection = ->
      selections = editor.getSelectionsOrderedByBufferPosition()
      selectedTextOrdered = (s.getText() for s in selections)
      selectedBufferRangeOrdered = (s.getBufferRange() for s in selections)
      cursor = (s.getHeadScreenPosition() for s in selections)
      mode = [vimState.mode, vimState.submode]
      {selectedTextOrdered, selectedBufferRangeOrdered, cursor, mode}

    ensureRestored = (keystroke, spec) ->
      ensure keystroke, spec
      preserved = preserveSelection()
      ensure 'escape j j', mode: 'normal', selectedText: ''
      ensure 'g v', preserved

    describe "linewise selection", ->
      beforeEach ->
        set cursor: [2, 0]
      describe "immediately after V", ->
        it 'restore previous selection', ->
          ensureRestored 'V',
            selectedText: textData.getLines([2])
            mode: ['visual', 'linewise']
      describe "selection is not reversed", ->
        it 'restore previous selection', ->
          ensureRestored 'V j',
            selectedText: textData.getLines([2, 3])
            mode: ['visual', 'linewise']
      describe "selection is reversed", ->
        it 'restore previous selection', ->
          ensureRestored 'V k',
            selectedText: textData.getLines([1, 2])
            mode: ['visual', 'linewise']

    describe "characterwise selection", ->
      beforeEach ->
        set cursor: [2, 0]
      describe "immediately after v", ->
        it 'restore previous selection', ->
          ensureRestored 'v',
            selectedText: "2"
            mode: ['visual', 'characterwise']
      describe "selection is not reversed", ->
        it 'restore previous selection', ->
          ensureRestored 'v j',
            selectedText: """
            2----A---------B----
            3
            """
            mode: ['visual', 'characterwise']
      describe "selection is reversed", ->
        it 'restore previous selection', ->
          ensureRestored 'v k',
            selectedText: """
            1-------------------
            2
            """
            mode: ['visual', 'characterwise']

    describe "blockwise selection", ->
      describe "immediately after ctrl-v", ->
        beforeEach ->
          set cursor: [2, 0]
        it 'restore previous selection', ->
          ensureRestored 'ctrl-v',
            selectedText: "2"
            mode: ['visual', 'blockwise']
      describe "selection is not reversed", ->
        it 'restore previous selection case-1', ->
          set cursor: [2, 5]
          keystroke 'ctrl-v 1 0 l'
          ensureRestored '3 j',
            selectedText: blockTexts[2..5]
            mode: ['visual', 'blockwise']
        it 'restore previous selection case-2', ->
          set cursor: [5, 5]
          keystroke 'ctrl-v 1 0 l'
          ensureRestored '3 k',
            selectedTextOrdered: blockTexts[2..5]
            mode: ['visual', 'blockwise']
      describe "selection is reversed", ->
        it 'restore previous selection case-1', ->
          set cursor: [2, 15]
          keystroke 'ctrl-v 1 0 h'
          ensureRestored '3 j',
            selectedText: blockTexts[2..5]
            mode: ['visual', 'blockwise']
        it 'restore previous selection case-2', ->
          set cursor: [5, 15]
          keystroke 'ctrl-v 1 0 h'
          ensureRestored '3 k',
            selectedTextOrdered: blockTexts[2..5]
            mode: ['visual', 'blockwise']
