# Refactoring status: 0%
helpers = require './spec-helper'

_ = require 'underscore-plus'

describe "TextObjects", ->
  [editor, editorElement, vimState] = []

  beforeEach ->
    vimMode = atom.packages.loadPackage('vim-mode')
    vimMode.activateResources()

    helpers.getEditorElement (element) ->
      editorElement = element
      editor = editorElement.getModel()
      vimState = editorElement.vimState
      vimState.activateNormalMode()
      vimState.resetNormalMode()

  keydown = (key, options={}) ->
    options.element ?= editorElement
    helpers.keydown(key, options)

  keystroke = (keys) ->
    for key in keys.split('')
      if key.match(/[A-Z]/)
        keydown(key, shift: true)
      else
        keydown(key)

  normalModeInputKeydown = (key, opts = {}) ->
    editor.normalModeInputView.editorElement.getModel().setText(key)

  text = (text=null) ->
    if text
      editor.setText text
    else
      expect editor.getText()

  addCursor = (point) ->
    editor.addCursorAtBufferPosition point

  cursor = (point=null) ->
    if point
      editor.setCursorScreenPosition point
    else
      expect editor.getCursorScreenPosition()

  cursorBuffer = (point=null) ->
    if point
      editor.setCursorBufferPosition point
    else
      expect editor.getCursorBufferPosition()

  selectedScreenRange = ->
    expect editor.getSelectedScreenRange()

  selectedScreenRanges = ->
    expect editor.getSelectedScreenRanges()

  selectedBufferRange = ->
    expect editor.getSelectedBufferRange()

  selectedBufferRanges = ->
    expect editor.getSelectedBufferRanges()

  register = (name, value) ->
    if value
      vimState.register.set(name, value)
    else
      expect vimState.register.get(name).text

  classListContains = (klass) ->
    expect editorElement.classList.contains(klass)

  ensure = (_keystroke, options={}) ->
    keystroke(_keystroke)
    if options.text?
      text().toBe options.text
    if options.cursor?
      cursor().toEqual options.cursor
    if options.register?
      register('"').toBe options.register

    if options.selectedBufferRange?
      selectedBufferRange().toEqual options.selectedBufferRange
    if options.selectedBufferRanges?
      selectedBufferRanges().toEqual options.selectedBufferRanges

    if options.selectedScreenRange?
      selectedScreenRange().toEqual options.selectedScreenRange
    if options.selectedScreenRanges?
      selectedScreenRanges().toEqual options.selectedScreenRanges

    notEnsureNormalMode = [
      options.selectedBufferRange, options.selectedBufferRanges
      options.selectedScreenRange, options.selectedScreenRanges
    ].some((bool) -> bool)
    unless notEnsureNormalMode
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

  set = (options={}) ->
    text(options.text) if options.text?
    cursor(options.cursor) if options.cursor?
    addCursor(options.addCursor) if options.addCursor?

  describe "the 'iw' text object", ->
    beforeEach ->
      set
        text: "12345 abcde ABCDE"
        cursor: [0, 9]

    it "applies operators inside the current word in operator-pending mode", ->
      ensure 'diw',
        text:     "12345  ABCDE"
        cursor:   [0, 6]
        register: 'abcde'

    it "selects inside the current word in visual mode", ->
      ensure 'viw',
        selectedScreenRange: [[0, 6], [0, 11]]

    it "works with multiple cursors", ->
      set
        addCursor: [0, 1]
      ensure 'viw',
        selectedBufferRanges: [
          [[0, 6], [0, 11]]
          [[0, 0], [0, 5]]
        ]

  describe "the 'iW' text object", ->
    beforeEach ->
      set
        text: "12(45 ab'de ABCDE"
        cursor: [0, 9]

    it "applies operators inside the current whole word in operator-pending mode", ->
      ensure 'diW',
        text:     "12(45  ABCDE"
        cursor:   [0, 6]
        register: "ab'de"

    it "selects inside the current whole word in visual mode", ->
      ensure 'viW',
        selectedScreenRange: [[0, 6], [0, 11]]

  describe "the 'i(' text object", ->
    beforeEach ->
      set
        text: "( something in here and in (here) )"
        cursor: [0, 9]

    it "applies operators inside the current word in operator-pending mode", ->
      ensure 'di(',
        text: "()"
        cursor: [0, 1]

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      set
        cursor: [0, 29]
      ensure 'di(',
        text: "( something in here and in () )"
        cursor: [0, 28]

    it "works with multiple cursors", ->
      set
        text: "( a b ) cde ( f g h ) ijk"
        cursor: [0, 2]
        addCursor: [0, 18]
      ensure 'vi(',
        selectedBufferRanges: [
          [[0, 1],  [0, 6]]
          [[0, 13], [0, 20]]
        ]

  describe "the 'i{' text object", ->
    beforeEach ->
      set
        text: "{ something in here and in {here} }"
        cursor: [0, 9]

    it "applies operators inside the current word in operator-pending mode", ->
      ensure 'di{',
        text: "{}"
        cursor: [0, 1]

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      set
        cursor: [0, 29]
      ensure 'di{',
        text: "{ something in here and in {} }"
        cursor: [0, 28]

  describe "the 'i<' text object", ->
    beforeEach ->
      set
        text: "< something in here and in <here> >"
        cursor: [0, 9]

    it "applies operators inside the current word in operator-pending mode", ->
      ensure 'di<',
        text: "<>"
        cursor: [0, 1]

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      set
        cursor: [0, 29]
      ensure 'di<',
        text: "< something in here and in <> >"
        cursor: [0, 28]

  describe "the 'it' text object", ->
    beforeEach ->
      set
        text: "<something>here</something><again>"
        cursor: [0, 5]

    it "applies only if in the value of a tag", ->
      ensure 'dit',
        text: "<something></something><again>"
        cursor: [0, 11]

    it "applies operators inside the current word in operator-pending mode", ->
      set
        cursor: [0, 13]
      ensure 'dit',
        text: "<something></something><again>"
        cursor: [0, 11]

  describe "the 'ip' text object", ->
    beforeEach ->
      set
        text: "\nParagraph-1\nParagraph-1\nParagraph-1\n\n"
        cursor: [2, 2]

    it "applies operators inside the current paragraph in operator-pending mode", ->
      ensure 'yip',
        text: "\nParagraph-1\nParagraph-1\nParagraph-1\n\n"
        cursor: [1, 0]
        register: "Paragraph-1\nParagraph-1\nParagraph-1\n"

    it "selects inside the current paragraph in visual mode", ->
      ensure 'vip',
        selectedScreenRange: [[1, 0], [4, 0]]

  describe "the 'ap' text object", ->
    beforeEach ->
      set
        text: "text\n\nParagraph-1\nParagraph-1\nParagraph-1\n\nmoretext"
        cursor: [3, 2]

    it "applies operators around the current paragraph in operator-pending mode", ->
      ensure 'yap',
        text: "text\n\nParagraph-1\nParagraph-1\nParagraph-1\n\nmoretext"
        cursor: [2, 0]
        register: "Paragraph-1\nParagraph-1\nParagraph-1\n\n"

    it "selects around the current paragraph in visual mode", ->
      ensure 'vap',
        selectedScreenRange: [[2, 0], [6, 0]]

  describe "the 'i[' text object", ->
    beforeEach ->
      set
        text: "[ something in here and in [here] ]"
        cursor: [0, 9]

    it "applies operators inside the current word in operator-pending mode", ->
      ensure 'di[',
        text: "[]"
        cursor: [0, 1]

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      set
        cursor: [0, 29]
      ensure 'di[',
        text: "[ something in here and in [] ]"
        cursor: [0, 28]

  describe "the 'i\'' text object", ->
    beforeEach ->
      set
        text: "' something in here and in 'here' ' and over here"
        cursor: [0, 9]

    it "applies operators inside the current string in operator-pending mode", ->
      ensure "di'",
        text: "''here' ' and over here"
        cursor: [0, 1]

    # I don't like old behavior, that was not in Vim and furthermore, this is counter intuitive.
    # Simply selecting area between quote is that normal user expects.
    # it "applies operators inside the next string in operator-pending mode (if not in a string)", ->
    it "[Changed behavior] applies operators inside area between quote", ->
      set
        cursor: [0, 29]
      ensure "di'",
        text: "' something in here and in '' ' and over here"
        cursor: [0, 28]

    it "makes no change if past the last string on a line", ->
      set
        cursor: [0, 39]
      ensure "di'",
        text: "' something in here and in 'here' ' and over here"
        cursor: [0, 39]

  describe "the 'i\"' text object", ->
    beforeEach ->
      set
        text: '" something in here and in "here" " and over here'
        cursor: [0, 9]

    it "applies operators inside the current string in operator-pending mode", ->
      ensure 'di"',
        text: '""here" " and over here'
        cursor: [0, 1]

    it "[Changed behavior] applies operators inside area between quote", ->
      set
        cursor: [0, 29]
      ensure 'di"',
        text: '" something in here and in "" " and over here'
        cursor: [0, 28]

    it "makes no change if past the last string on a line", ->
      set
        cursor: [0, 39]
      ensure 'di"',
        text: '" something in here and in "here" " and over here'
        cursor: [0, 39]

  describe "the 'aw' text object", ->
    beforeEach ->
      set
        text: "12345 abcde ABCDE"
        cursor: [0, 9]

    it "applies operators from the start of the current word to the start of the next word in operator-pending mode", ->
      ensure 'daw',
        text: "12345 ABCDE"
        cursor: [0, 6]
        register: "abcde "

    it "selects from the start of the current word to the start of the next word in visual mode", ->
      ensure 'vaw',
        selectedScreenRange: [[0, 6], [0, 12]]

    it "doesn't span newlines", ->
      set
        text: "12345\nabcde ABCDE"
        cursor: [0, 3]
      ensure 'vaw',
        selectedBufferRange: [[0, 0], [0, 5]]

    it "doesn't span special characters", ->
      set
        text: "1(345\nabcde ABCDE"
        cursor: [0, 3]
      ensure 'vaw',
        selectedBufferRange: [[0, 2], [0, 5]]

  describe "the 'aW' text object", ->
    beforeEach ->
      set
        text: "12(45 ab'de ABCDE"
        cursor: [0, 9]

    it "applies operators from the start of the current whole word to the start of the next whole word in operator-pending mode", ->
      ensure 'daW',
        text: "12(45 ABCDE"
        cursor: [0, 6]
        register: "ab'de "

    it "selects from the start of the current whole word to the start of the next whole word in visual mode", ->
      ensure 'vaW',
        selectedScreenRange: [[0, 6], [0, 12]]

    it "doesn't span newlines", ->
      set
        text: "12(45\nab'de ABCDE"
        cursor: [0, 4]
      ensure 'vaW',
        selectedBufferRange: [[0, 0], [0, 5]]

  describe "the 'a(' text object", ->
    beforeEach ->
      set
        text: "( something in here and in (here) )"
        cursor: [0, 9]

    it "applies operators around the current parentheses in operator-pending mode", ->
      ensure 'da(',
        text: ''
        cursor: [0, 0]

    it "applies operators around the current parentheses in operator-pending mode (second test)", ->
      set
        cursor: [0, 29]
      ensure 'da(',
        text: "( something in here and in  )"
        cursor: [0, 27]

  describe "the 'a{' text object", ->
    beforeEach ->
      set
        text: "{ something in here and in {here} }"
        cursor: [0, 9]

    it "applies operators around the current curly brackets in operator-pending mode", ->
      ensure 'da{',
        text: ''
        cursor: [0, 0]

    it "applies operators around the current curly brackets in operator-pending mode (second test)", ->
      set
        cursor: [0, 29]
      ensure 'da{',
        text: "{ something in here and in  }"
        cursor: [0, 27]

  describe "the 'a<' text object", ->
    beforeEach ->
      set
        text: "< something in here and in <here> >"
        cursor: [0, 9]

    it "applies operators around the current angle brackets in operator-pending mode", ->
      ensure 'da<',
        text: ''
        cursor: [0, 0]

    it "applies operators around the current angle brackets in operator-pending mode (second test)", ->
      set
        cursor: [0, 29]
      ensure 'da<',
        text: "< something in here and in  >"
        cursor: [0, 27]

  describe "the 'a[' text object", ->
    beforeEach ->
      set
        text: "[ something in here and in [here] ]"
        cursor: [0, 9]

    it "applies operators around the current square brackets in operator-pending mode", ->
      ensure 'da[',
        text: ''
        cursor: [0, 0]

    it "applies operators around the current square brackets in operator-pending mode (second test)", ->
      set
        cursor: [0, 29]
      ensure 'da[',
        text: "[ something in here and in  ]"
        cursor: [0, 27]

  describe "the 'a\'' text object", ->
    beforeEach ->
      set
        text: "' something in here and in 'here' '"
        cursor: [0, 9]

    it "applies operators around the current single quotes in operator-pending mode", ->
      ensure "da'",
        text: "here' '"
        cursor: [0, 0]

    it "applies operators around the current single quotes in operator-pending mode (second test)", ->
      set
        cursor: [0, 29]
      ensure "da'",
        text: "' something in here and in  '"
        cursor: [0, 27]

  describe "the 'a\"' text object", ->
    beforeEach ->
      set
        text: '" something in here and in "here" "'
        cursor: [0, 9]

    it "applies operators around the current double quotes in operator-pending mode", ->
      ensure 'da"',
        text: 'here" "'
        cursor: [0, 0]

    it "applies operators around the current double quotes in operator-pending mode (second test)", ->
      set
        cursor: [0, 29]
      ensure 'da"',
        text: '" something in here and in  "'
        cursor: [0, 27]
