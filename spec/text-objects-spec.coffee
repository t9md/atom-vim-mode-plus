helpers = require './spec-helper'

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

  ensure = (spec={}) ->
    if spec.text?
      text().toBe spec.text
    if spec.cursor?
      cursor().toEqual spec.cursor
    if spec.register?
      register('"').toBe spec.register

    if spec.selectedBufferRange?
      selectedBufferRange().toEqual spec.selectedBufferRange
    if spec.selectedBufferRanges?
      selectedBufferRanges().toEqual spec.selectedBufferRanges

    if spec.selectedScreenRange?
      selectedScreenRange().toEqual spec.selectedScreenRange
    if spec.selectedScreenRanges?
      selectedScreenRanges().toEqual spec.selectedScreenRanges

    notEnsureNormalMode = [
      spec.selectedBufferRange, spec.selectedBufferRanges
      spec.selectedScreenRange, spec.selectedScreenRanges
    ].some((bool) -> bool)
    unless notEnsureNormalMode
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

  ensureKeystroke = (_keystroke, spec={}) ->
    keystroke(_keystroke)
    ensure(spec)

  describe "the 'iw' text object", ->
    beforeEach ->
      text "12345 abcde ABCDE"
      cursor [0, 9]

    it "applies operators inside the current word in operator-pending mode", ->
      ensureKeystroke 'diw',
        text:     "12345  ABCDE"
        cursor:   [0, 6]
        register: 'abcde'

    it "selects inside the current word in visual mode", ->
      ensureKeystroke 'viw',
        selectedScreenRange: [[0, 6], [0, 11]]

    it "works with multiple cursors", ->
      addCursor [0, 1]
      ensureKeystroke 'viw',
        selectedBufferRanges: [
          [[0, 6], [0, 11]]
          [[0, 0], [0, 5]]
        ]

  describe "the 'iW' text object", ->
    beforeEach ->
      text "12(45 ab'de ABCDE"
      cursor [0, 9]

    it "applies operators inside the current whole word in operator-pending mode", ->
      ensureKeystroke 'diW',
        text:     "12(45  ABCDE"
        cursor:   [0, 6]
        register: "ab'de"

    it "selects inside the current whole word in visual mode", ->
      ensureKeystroke 'viW',
        selectedScreenRange: [[0, 6], [0, 11]]

  describe "the 'i(' text object", ->
    beforeEach ->
      text "( something in here and in (here) )"
      cursor [0, 9]

    it "applies operators inside the current word in operator-pending mode", ->
      ensureKeystroke 'di(',
        text: "()"
        cursor: [0, 1]

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      cursor [0, 29]
      ensureKeystroke 'di(',
        text: "( something in here and in () )"
        cursor: [0, 28]

    it "works with multiple cursors", ->
      text "( a b ) cde ( f g h ) ijk"
      cursorBuffer [0, 2]
      addCursor [0, 18]
      ensureKeystroke 'vi(',
        selectedBufferRanges: [
          [[0, 1],  [0, 6]]
          [[0, 13], [0, 20]]
        ]

  describe "the 'i{' text object", ->
    beforeEach ->
      text "{ something in here and in {here} }"
      cursor [0, 9]

    it "applies operators inside the current word in operator-pending mode", ->
      ensureKeystroke 'di{',
        text: "{}"
        cursor: [0, 1]

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      cursor [0, 29]
      ensureKeystroke 'di{',
        text: "{ something in here and in {} }"
        cursor: [0, 28]

  describe "the 'i<' text object", ->
    beforeEach ->
      text "< something in here and in <here> >"
      cursor [0, 9]

    it "applies operators inside the current word in operator-pending mode", ->
      ensureKeystroke 'di<',
        text: "<>"
        cursor: [0, 1]

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      cursor [0, 29]
      ensureKeystroke 'di<',
        text: "< something in here and in <> >"
        cursor: [0, 28]

  describe "the 'it' text object", ->
    beforeEach ->
      text "<something>here</something><again>"
      cursor [0, 5]

    it "applies only if in the value of a tag", ->
      ensureKeystroke 'dit',
        text: "<something></something><again>"
        cursor: [0, 11]

    it "applies operators inside the current word in operator-pending mode", ->
      cursor [0, 13]
      ensureKeystroke 'dit',
        text: "<something></something><again>"
        cursor: [0, 11]

  describe "the 'ip' text object", ->
    beforeEach ->
      text "\nParagraph-1\nParagraph-1\nParagraph-1\n\n"
      cursor [2, 2]

    it "applies operators inside the current paragraph in operator-pending mode", ->
      ensureKeystroke 'yip',
        text: "\nParagraph-1\nParagraph-1\nParagraph-1\n\n"
        cursor: [1, 0]
        register: "Paragraph-1\nParagraph-1\nParagraph-1\n"

    it "selects inside the current paragraph in visual mode", ->
      ensureKeystroke 'vip',
        selectedScreenRange: [[1, 0], [4, 0]]

  describe "the 'ap' text object", ->
    beforeEach ->
      text "text\n\nParagraph-1\nParagraph-1\nParagraph-1\n\nmoretext"
      cursor [3, 2]

    it "applies operators around the current paragraph in operator-pending mode", ->
      ensureKeystroke 'yap',
        text: "text\n\nParagraph-1\nParagraph-1\nParagraph-1\n\nmoretext"
        cursor: [2, 0]
        register: "Paragraph-1\nParagraph-1\nParagraph-1\n\n"

    it "selects around the current paragraph in visual mode", ->
      ensureKeystroke 'vap',
        selectedScreenRange: [[2, 0], [6, 0]]

  describe "the 'i[' text object", ->
    beforeEach ->
      text "[ something in here and in [here] ]"
      cursor [0, 9]

    it "applies operators inside the current word in operator-pending mode", ->
      ensureKeystroke 'di[',
        text: "[]"
        cursor: [0, 1]

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      cursor [0, 29]
      ensureKeystroke 'di[',
        text: "[ something in here and in [] ]"
        cursor: [0, 28]

  describe "the 'i\'' text object", ->
    beforeEach ->
      text "' something in here and in 'here' ' and over here"
      cursor [0, 9]

    it "applies operators inside the current string in operator-pending mode", ->
      ensureKeystroke "di'",
        text: "''here' ' and over here"
        cursor: [0, 1]

    # I don't like old behavior, that was not in Vim and furthermore, this is counter intuitive.
    # Simply selecting area between quote is that normal user expects.
    # it "applies operators inside the next string in operator-pending mode (if not in a string)", ->
    it "[Changed behavior] applies operators inside area between quote", ->
      cursor [0, 29]
      ensureKeystroke "di'",
        text: "' something in here and in '' ' and over here"
        cursor: [0, 28]

    it "makes no change if past the last string on a line", ->
      cursor [0, 39]
      ensureKeystroke "di'",
        text: "' something in here and in 'here' ' and over here"
        cursor: [0, 39]

  describe "the 'i\"' text object", ->
    beforeEach ->
      text '" something in here and in "here" " and over here'
      cursor [0, 9]

    it "applies operators inside the current string in operator-pending mode", ->
      ensureKeystroke 'di"',
        text: '""here" " and over here'
        cursor: [0, 1]

    it "[Changed behavior] applies operators inside area between quote", ->
      cursor [0, 29]
      ensureKeystroke 'di"',
        text: '" something in here and in "" " and over here'
        cursor: [0, 28]

    it "makes no change if past the last string on a line", ->
      cursor [0, 39]
      ensureKeystroke 'di"',
        text: '" something in here and in "here" " and over here'
        cursor: [0, 39]

  describe "the 'aw' text object", ->
    beforeEach ->
      text "12345 abcde ABCDE"
      cursor [0, 9]

    it "applies operators from the start of the current word to the start of the next word in operator-pending mode", ->
      ensureKeystroke 'daw',
        text: "12345 ABCDE"
        cursor: [0, 6]
        register: "abcde "

    it "selects from the start of the current word to the start of the next word in visual mode", ->
      ensureKeystroke 'vaw',
        selectedScreenRange: [[0, 6], [0, 12]]

    it "doesn't span newlines", ->
      text "12345\nabcde ABCDE"
      cursor [0, 3]
      ensureKeystroke 'vaw',
        selectedBufferRange: [[0, 0], [0, 5]]

    it "doesn't span special characters", ->
      text "1(345\nabcde ABCDE"
      cursor [0, 3]
      ensureKeystroke 'vaw',
        selectedBufferRange: [[0, 2], [0, 5]]

  describe "the 'aW' text object", ->
    beforeEach ->
      text "12(45 ab'de ABCDE"
      cursor [0, 9]

    it "applies operators from the start of the current whole word to the start of the next whole word in operator-pending mode", ->
      ensureKeystroke 'daW',
        text: "12(45 ABCDE"
        cursor: [0, 6]
        register: "ab'de "

    it "selects from the start of the current whole word to the start of the next whole word in visual mode", ->
      ensureKeystroke 'vaW',
        selectedScreenRange: [[0, 6], [0, 12]]

    it "doesn't span newlines", ->
      text "12(45\nab'de ABCDE"
      cursor [0, 4]
      ensureKeystroke 'vaW',
        selectedBufferRange: [[0, 0], [0, 5]]

  describe "the 'a(' text object", ->
    beforeEach ->
      text "( something in here and in (here) )"
      cursor [0, 9]

    it "applies operators around the current parentheses in operator-pending mode", ->
      ensureKeystroke 'da(',
        text: ''
        cursor: [0, 0]

    it "applies operators around the current parentheses in operator-pending mode (second test)", ->
      cursor [0, 29]
      ensureKeystroke 'da(',
        text: "( something in here and in  )"
        cursor: [0, 27]

  describe "the 'a{' text object", ->
    beforeEach ->
      text "{ something in here and in {here} }"
      cursor [0, 9]

    it "applies operators around the current curly brackets in operator-pending mode", ->
      ensureKeystroke 'da{',
        text: ''
        cursor: [0, 0]

    it "applies operators around the current curly brackets in operator-pending mode (second test)", ->
      cursor [0, 29]
      ensureKeystroke 'da{',
        text: "{ something in here and in  }"
        cursor: [0, 27]

  describe "the 'a<' text object", ->
    beforeEach ->
      text "< something in here and in <here> >"
      cursor [0, 9]

    it "applies operators around the current angle brackets in operator-pending mode", ->
      ensureKeystroke 'da<',
        text: ''
        cursor: [0, 0]

    it "applies operators around the current angle brackets in operator-pending mode (second test)", ->
      cursor [0, 29]
      ensureKeystroke 'da<',
        text: "< something in here and in  >"
        cursor: [0, 27]

  describe "the 'a[' text object", ->
    beforeEach ->
      text "[ something in here and in [here] ]"
      cursor [0, 9]

    it "applies operators around the current square brackets in operator-pending mode", ->
      ensureKeystroke 'da[',
        text: ''
        cursor: [0, 0]

    it "applies operators around the current square brackets in operator-pending mode (second test)", ->
      cursor [0, 29]
      ensureKeystroke 'da[',
        text: "[ something in here and in  ]"
        cursor: [0, 27]

  describe "the 'a\'' text object", ->
    beforeEach ->
      text "' something in here and in 'here' '"
      cursor [0, 9]

    it "applies operators around the current single quotes in operator-pending mode", ->
      ensureKeystroke "da'",
        text: "here' '"
        cursor: [0, 0]

    it "applies operators around the current single quotes in operator-pending mode (second test)", ->
      cursor [0, 29]
      ensureKeystroke "da'",
        text: "' something in here and in  '"
        cursor: [0, 27]

  describe "the 'a\"' text object", ->
    beforeEach ->
      text '" something in here and in "here" "'
      cursor [0, 9]

    it "applies operators around the current double quotes in operator-pending mode", ->
      ensureKeystroke 'da"',
        text: 'here" "'
        cursor: [0, 0]

    it "applies operators around the current double quotes in operator-pending mode (second test)", ->
      cursor [0, 29]
      ensureKeystroke 'da"',
        text: '" something in here and in  "'
        cursor: [0, 27]
