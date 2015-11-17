{getVimState} = require './spec-helper'
swrap = require '../lib/selection-wrapper'

describe "Visual Blockwise", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

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
      selectedText: [
        'A---------B'
        '***********'
        '+++++++++++'
        'C---------D'
      ]

  ensureBlockwiseSelection = (selections, o) ->
    if selections.length is 1
      first = last = selections[0]
    else
      [first, others..., last] = selections

    head = switch o.head
      when 'top' then first
      when 'bottom' then last
    expect(swrap(head).isBlockwiseHead()).toBe true
    tail = switch o.tail
      when 'top' then first
      when 'bottom' then last
    expect(swrap(tail).isBlockwiseTail()).toBe true

    for s in others
      expect(swrap(s).isBlockwiseHead()).toBe false
      expect(swrap(s).isBlockwiseHead()).toBe false
    if o.reversed?
      for s in selections
        expect(s.isReversed()).toBe o.reversed

  beforeEach ->
    getVimState (state, vimEditor) ->
      vimState = state
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = vimEditor

    runs ->
      set
        text: """
          01234567890123456789
          1-------------------
          2----A---------B----
          3----***********----
          4----+++++++++++----
          5----C---------D----
          6-------------------
          """

  afterEach ->
    vimState.activate('reset')

  describe "j", ->
    beforeEach ->
      set cursor: [3, 5]
      ensure ['v10l', {ctrl: 'v'}],
        selectedText: "***********"
        mode: ['visual', 'blockwise']

    it "add selection to down direction", ->
      ensure 'j',
        selectedText: [
          '***********'
          '+++++++++++'
        ]
      ensure 'j',
        selectedText: [
          '***********'
          '+++++++++++'
          'C---------D'
        ]

    it "delete selection when blocwise is reversed", ->
      ensure '3k',
        selectedTextOrderd: [
          '56789012345'
          '-----------'
          'A---------B'
          '***********'
        ]
      ensure 'j',
        selectedTextOrderd: [
          '-----------'
          'A---------B'
          '***********'
        ]
      ensure '2j',
        selectedTextOrderd: [
          '***********'
        ]
    it "keep tail row when reversed status changed", ->
      ensure 'j',
        selectedText: [
          '***********'
          '+++++++++++'
        ]
      ensure '2k',
        selectedTextOrderd: [
          'A---------B'
          '***********'
        ]

  describe "k", ->
    beforeEach ->
      set cursor: [3, 5]
      ensure ['v10l', {ctrl: 'v'}],
        selectedText: "***********"
        mode: ['visual', 'blockwise']

    it "add selection to up direction", ->
      v = [
        '56789012345'
        '-----------'
        'A---------B'
        '***********'
      ]
      ensure 'k',
        selectedTextOrderd: [
          'A---------B'
          '***********'
        ]
      ensure 'k',
        selectedTextOrderd: [
          '-----------'
          'A---------B'
          '***********'
        ]

    it "delete selection when blocwise is reversed", ->
      ensure '3j',
        selectedTextOrderd: [
          '***********'
          '+++++++++++'
          'C---------D'
          '-----------'
        ]
      ensure 'k',
        selectedTextOrderd: [
          '***********'
          '+++++++++++'
          'C---------D'
        ]
      ensure '2k',
        selectedTextOrderd: [
          '***********'
        ]
  describe "C", ->
    beforeEach ->
      selectBlockwise()
    it "change-to-last-character-of-line for each selection", ->
      ensure 'C',
        text: """
          01234567890123456789
          1-------------------
          2----
          3----
          4----
          5----
          6-------------------
          """
        cursor: [2, 5]
        mode: 'insert'

  describe "D", ->
    beforeEach ->
      selectBlockwise()
    it "delete-to-last-character-of-line for each selection", ->
      ensure 'D',
        text: """
          01234567890123456789
          1-------------------
          2----
          3----
          4----
          5----
          6-------------------
          """
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
        selections = editor.getSelectionsOrderedByBufferPosition()
        keystroke 'o'
        ensureBlockwiseSelection selections,
          head: 'top', tail: 'bottom', reversed: true

        keystroke 'o'
        ensureBlockwiseSelection selections,
          head: 'bottom', tail: 'top', reversed: false
    describe 'capital O', ->
      it "reverse each selection", ->
        selections = editor.getSelectionsOrderedByBufferPosition()
        keystroke 'O'
        ensureBlockwiseSelection selections,
          head: 'bottom', tail: 'top', reversed: true
        keystroke 'O'
        ensureBlockwiseSelection selections,
          head: 'bottom', tail: 'top', reversed: false

  describe "shift from characterwise to blockwise", ->
    beforeEach ->
      set
        text: """
          01234567890123456789
          1-------------------
          2----A---------B----
          3----***********----
          4----+++++++++++----
          5----C---------D----
          6-------------------
          """
    describe "when selection is not reversed", ->
      beforeEach ->
        set cursor: [2, 5]
        ensure 'v',
          selectedText: 'A'
          mode: ['visual', 'characterwise']

      it 'case-1', ->
        ensure ['3j', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrderd: [
            'A'
            '*'
            '+'
            'C'
          ]
        ensureBlockwiseSelection editor.getSelections(),
          head: 'bottom', tail: 'top', reversed: false

      it 'case-2', ->
        ensure ['h3j', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrderd: [
            '-A'
            '-*'
            '-+'
            '-C'
          ]
        ensureBlockwiseSelection editor.getSelections(),
          head: 'bottom', tail: 'top', reversed: true

      it 'case-3', ->
        ensure ['2h3j', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrderd: [
            '--A'
            '--*'
            '--+'
            '--C'
          ]
        ensureBlockwiseSelection editor.getSelections(),
          head: 'bottom', tail: 'top', reversed: true

      it 'case-4', ->
        ensure ['l3j', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrderd: [
            'A-'
            '**'
            '++'
            'C-'
          ]
        ensureBlockwiseSelection editor.getSelections(),
          head: 'bottom', tail: 'top', reversed: false
      it 'case-5', ->
        ensure ['2l3j', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrderd: [
            'A--'
            '***'
            '+++'
            'C--'
          ]
        ensureBlockwiseSelection editor.getSelections(),
          head: 'bottom', tail: 'top', reversed: false

    describe "when selection is reversed", ->
      beforeEach ->
        set cursor: [5, 5]
        ensure 'v',
          selectedText: 'C'
          mode: ['visual', 'characterwise']

      it 'case-1', ->
        ensure ['3k', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrderd: [
            'A'
            '*'
            '+'
            'C'
          ]
        ensureBlockwiseSelection editor.getSelectionsOrderedByBufferPosition(),
          head: 'top', tail: 'bottom', reversed: true

      it 'case-2', ->
        ensure ['h3k', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrderd: [
            '-A'
            '-*'
            '-+'
            '-C'
          ]
        ensureBlockwiseSelection editor.getSelectionsOrderedByBufferPosition(),
          head: 'top', tail: 'bottom', reversed: true

      it 'case-3', ->
        ensure ['2h3k', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrderd: [
            '--A'
            '--*'
            '--+'
            '--C'
          ]
        ensureBlockwiseSelection editor.getSelectionsOrderedByBufferPosition(),
          head: 'top', tail: 'bottom', reversed: true

      it 'case-4', ->
        ensure ['l3k', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrderd: [
            'A-'
            '**'
            '++'
            'C-'
          ]
        ensureBlockwiseSelection editor.getSelectionsOrderedByBufferPosition(),
          head: 'top', tail: 'bottom', reversed: false

      it 'case-5', ->
        ensure ['2l3k', {ctrl: 'v'}],
          mode: ['visual', 'blockwise']
          selectedTextOrderd: [
            'A--'
            '***'
            '+++'
            'C--'
          ]
        ensureBlockwiseSelection editor.getSelectionsOrderedByBufferPosition(),
          head: 'top', tail: 'bottom', reversed: false
