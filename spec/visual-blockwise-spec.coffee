{getVimState, TextData} = require './spec-helper'
swrap = require '../lib/selection-wrapper'

describe "Visual Blockwise", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []
  textInitial = """
    01234567890123456789
    1-------------------
    2----A---------B----
    3----***********----
    4----+++++++++++----
    5----C---------D----
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
    ensure ['v3j10l', {ctrl: 'v'}],
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

    for s in others
      expect(bs.getHeadSelection()).not.toBe s
      expect(bs.getTailSelection()).not.toBe s
    if o.reversed?
      for s in selections
        expect(s.isReversed()).toBe o.reversed

  beforeEach ->
    getVimState (state, vimEditor) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vimEditor

    runs ->
      set text: textInitial

  afterEach ->
    vimState.resetNormalMode()

  describe "j", ->
    beforeEach ->
      set cursor: [3, 5]
      ensure ['v10l', {ctrl: 'v'}],
        selectedText: blockTexts[3]
        mode: ['visual', 'blockwise']

    it "add selection to down direction", ->
      ensure 'j', selectedText: blockTexts[3..4]
      ensure 'j', selectedText: blockTexts[3..5]

    it "delete selection when blocwise is reversed", ->
      ensure '3k', selectedTextOrdered: blockTexts[0..3]
      ensure 'j', selectedTextOrdered: blockTexts[1..3]
      ensure '2j', selectedTextOrdered: blockTexts[3]

    it "keep tail row when reversed status changed", ->
      ensure 'j', selectedText: blockTexts[3..4]
      ensure '2k', selectedTextOrdered: blockTexts[2..3]

  describe "k", ->
    beforeEach ->
      set cursor: [3, 5]
      ensure ['v10l', {ctrl: 'v'}],
        selectedText: blockTexts[3]
        mode: ['visual', 'blockwise']

    it "add selection to up direction", ->
      ensure 'k', selectedTextOrdered: blockTexts[2..3]
      ensure 'k', selectedTextOrdered: blockTexts[1..3]

    it "delete selection when blocwise is reversed", ->
      ensure '3j', selectedTextOrdered: blockTexts[3..6]
      ensure 'k', selectedTextOrdered: blockTexts[3..5]
      ensure '2k', selectedTextOrdered: blockTexts[3]

  describe "C", ->
    beforeEach ->
      selectBlockwise()
    it "change-to-last-character-of-line for each selection", ->
      ensure 'C',
        mode: 'insert'
        cursor: [[2, 5], [3, 5], [4, 5], [5, 5] ]
        text: textAfterDeleted

      editor.insertText("!!!")
      ensure
        mode: 'insert'
        cursor: [[2, 8], [3, 8], [4, 8], [5, 8]]
        text: """
          01234567890123456789
          1-------------------
          2----!!!
          3----!!!
          4----!!!
          5----!!!
          6-------------------
          """

  describe "D", ->
    beforeEach ->
      selectBlockwise()
    it "delete-to-last-character-of-line for each selection", ->
      ensure 'D',
        text: textAfterDeleted
        cursor: [2, 4]
        mode: 'normal'

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
          3----!!!***********----
          4----!!!+++++++++++----
          5----!!!C---------D----
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
          3----***********!!!----
          4----+++++++++++!!!----
          5----C---------D!!!----
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
        ensureBlockwiseSelection head: 'top', tail: 'bottom', reversed: true

        keystroke 'o'
        ensureBlockwiseSelection head: 'bottom', tail: 'top', reversed: false
    describe 'capital O', ->
      it "reverse each selection", ->
        keystroke 'O'
        ensureBlockwiseSelection head: 'bottom', tail: 'top', reversed: true
        keystroke 'O'
        ensureBlockwiseSelection head: 'bottom', tail: 'top', reversed: false

  describe "shift from characterwise to blockwise", ->
    describe "when selection is not reversed", ->
      beforeEach ->
        set cursor: [2, 5]
        ensure 'v',
          selectedText: 'A'
          mode: ['visual', 'characterwise']

      it 'case-1', ->
        ensure ['3j', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            'A'
            '*'
            '+'
            'C'
          ]
        ensureBlockwiseSelection head: 'bottom', tail: 'top', reversed: false

      it 'case-2', ->
        ensure ['h3j', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            '-A'
            '-*'
            '-+'
            '-C'
          ]
        ensureBlockwiseSelection head: 'bottom', tail: 'top', reversed: true

      it 'case-3', ->
        ensure ['2h3j', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            '--A'
            '--*'
            '--+'
            '--C'
          ]
        ensureBlockwiseSelection head: 'bottom', tail: 'top', reversed: true

      it 'case-4', ->
        ensure ['l3j', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            'A-'
            '**'
            '++'
            'C-'
          ]
        ensureBlockwiseSelection head: 'bottom', tail: 'top', reversed: false
      it 'case-5', ->
        ensure ['2l3j', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            'A--'
            '***'
            '+++'
            'C--'
          ]
        ensureBlockwiseSelection head: 'bottom', tail: 'top', reversed: false

    describe "when selection is reversed", ->
      beforeEach ->
        set cursor: [5, 5]
        ensure 'v',
          selectedText: 'C'
          mode: ['visual', 'characterwise']

      it 'case-1', ->
        ensure ['3k', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            'A'
            '*'
            '+'
            'C'
          ]
        ensureBlockwiseSelection head: 'top', tail: 'bottom', reversed: true

      it 'case-2', ->
        ensure ['h3k', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            '-A'
            '-*'
            '-+'
            '-C'
          ]
        ensureBlockwiseSelection head: 'top', tail: 'bottom', reversed: true

      it 'case-3', ->
        ensure ['2h3k', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            '--A'
            '--*'
            '--+'
            '--C'
          ]
        ensureBlockwiseSelection head: 'top', tail: 'bottom', reversed: true

      it 'case-4', ->
        ensure ['l3k', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            'A-'
            '**'
            '++'
            'C-'
          ]
        ensureBlockwiseSelection head: 'top', tail: 'bottom', reversed: false

      it 'case-5', ->
        ensure ['2l3k', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrdered: [
            'A--'
            '***'
            '+++'
            'C--'
          ]
        ensureBlockwiseSelection head: 'top', tail: 'bottom', reversed: false

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
      ensure {ctrl: 'v'}, mode: ['visual', 'blockwise']
      ensure 'v', characterwiseState

    describe "when selection is not reversed", ->
      beforeEach ->
        set cursor: [2, 5]
      it 'case-1', -> ensureCharacterwiseWasRestored('v')
      it 'case-2', -> ensureCharacterwiseWasRestored('v3j')
      it 'case-3', -> ensureCharacterwiseWasRestored('vh3j')
      it 'case-4', -> ensureCharacterwiseWasRestored('v2h3j')
      it 'case-5', -> ensureCharacterwiseWasRestored('vl3j')
      it 'case-6', -> ensureCharacterwiseWasRestored('v2l3j')
    describe "when selection is reversed", ->
      beforeEach ->
        set cursor: [5, 5]
      it 'case-1', -> ensureCharacterwiseWasRestored('v')
      it 'case-2', -> ensureCharacterwiseWasRestored('v3k')
      it 'case-3', -> ensureCharacterwiseWasRestored('vh3k')
      it 'case-4', -> ensureCharacterwiseWasRestored('v2h3k')
      it 'case-5', -> ensureCharacterwiseWasRestored('vl3k')
      it 'case-6', -> ensureCharacterwiseWasRestored('v2l3k')

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
      ensure ['escape', 'jj'], mode: 'normal', selectedText: ''
      ensure 'gv', preserved

    describe "linewise selection", ->
      beforeEach ->
        set cursor: [2, 0]
      describe "selection is not reversed", ->
        it 'restore previous selection', ->
          ensureRestored 'Vj',
            selectedText: textData.getLines([2, 3])
            mode: ['visual', 'linewise']
      describe "selection is reversed", ->
        it 'restore previous selection', ->
          ensureRestored 'Vk',
            selectedText: textData.getLines([1, 2])
            mode: ['visual', 'linewise']

    describe "characterwise selection", ->
      beforeEach ->
        set cursor: [2, 0]
      describe "selection is not reversed", ->
        it 'restore previous selection', ->
          ensureRestored 'vj',
            selectedText: """
            2----A---------B----
            3
            """
            mode: ['visual', 'characterwise']
      describe "selection is reversed", ->
        it 'restore previous selection', ->
          ensureRestored 'vk',
            selectedText: """
            1-------------------
            2
            """
            mode: ['visual', 'characterwise']

    describe "blockwise selection", ->
      describe "selection is not reversed", ->
        it 'restore previous selection case-1', ->
          set cursor: [2, 5]
          keystroke [{ctrl: 'v'}, '10l']
          ensureRestored '3j',
            selectedText: blockTexts[2..5]
            mode: ['visual', 'blockwise']
        it 'restore previous selection case-2', ->
          set cursor: [5, 5]
          keystroke [{ctrl: 'v'}, '10l']
          ensureRestored '3k',
            selectedTextOrdered: blockTexts[2..5]
            mode: ['visual', 'blockwise']
      describe "selection is reversed", ->
        it 'restore previous selection case-1', ->
          set cursor: [2, 15]
          keystroke [{ctrl: 'v'}, '10h']
          ensureRestored '3j',
            selectedText: blockTexts[2..5]
            mode: ['visual', 'blockwise']
        it 'restore previous selection case-2', ->
          set cursor: [5, 15]
          keystroke [{ctrl: 'v'}, '10h']
          ensureRestored '3k',
            selectedTextOrdered: blockTexts[2..5]
            mode: ['visual', 'blockwise']
