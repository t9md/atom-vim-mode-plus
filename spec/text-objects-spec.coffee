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

  describe "the 'iw' text object", ->
    beforeEach ->
      text "12345 abcde ABCDE"
      cursor [0, 9]

    it "applies operators inside the current word in operator-pending mode", ->
      keystroke 'diw'

      text().toBe "12345  ABCDE"
      cursor().toEqual [0, 6]
      register('"').toBe 'abcde'
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "selects inside the current word in visual mode", ->
      keystroke 'viw'
      selectedScreenRange().toEqual [[0, 6], [0, 11]]

    it "works with multiple cursors", ->
      addCursor [0, 1]
      keystroke 'viw'
      selectedBufferRanges().toEqual [
        [[0, 6], [0, 11]]
        [[0, 0], [0, 5]]
      ]

  describe "the 'iW' text object", ->
    beforeEach ->
      text "12(45 ab'de ABCDE"
      cursor [0, 9]

    it "applies operators inside the current whole word in operator-pending mode", ->
      keystroke 'diW'

      text().toBe "12(45  ABCDE"
      cursor().toEqual [0, 6]
      register('"').toBe "ab'de"
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "selects inside the current whole word in visual mode", ->
      keystroke 'viW'
      selectedScreenRange().toEqual [[0, 6], [0, 11]]

  describe "the 'i(' text object", ->
    beforeEach ->
      text "( something in here and in (here) )"
      cursor [0, 9]

    it "applies operators inside the current word in operator-pending mode", ->
      keystroke 'di('
      text().toBe "()"
      cursor().toEqual [0, 1]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      cursor [0, 29]
      keystroke 'di('
      text().toBe "( something in here and in () )"
      cursor().toEqual [0, 28]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "works with multiple cursors", ->
      text "( a b ) cde ( f g h ) ijk"
      cursorBuffer [0, 2]
      addCursor [0, 18]
      keystroke 'vi('
      selectedBufferRanges().toEqual [
        [[0, 1],  [0, 6]]
        [[0, 13], [0, 20]]
      ]

  describe "the 'i{' text object", ->
    beforeEach ->
      text "{ something in here and in {here} }"
      cursor [0, 9]

    it "applies operators inside the current word in operator-pending mode", ->
      keystroke 'di{'
      text().toBe "{}"
      cursor().toEqual [0, 1]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      cursor [0, 29]
      keystroke 'di{'
      text().toBe "{ something in here and in {} }"
      cursor().toEqual [0, 28]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

  describe "the 'i<' text object", ->
    beforeEach ->
      text "< something in here and in <here> >"
      cursor [0, 9]

    it "applies operators inside the current word in operator-pending mode", ->
      keystroke 'di<'
      text().toBe "<>"
      cursor().toEqual [0, 1]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      cursor [0, 29]
      keystroke 'di<'
      text().toBe "< something in here and in <> >"
      cursor().toEqual [0, 28]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

  describe "the 'it' text object", ->
    beforeEach ->
      text "<something>here</something><again>"
      cursor [0, 5]

    it "applies only if in the value of a tag", ->
      keystroke 'dit'
      text().toBe "<something></something><again>"
      cursor().toEqual [0, 11]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "applies operators inside the current word in operator-pending mode", ->
      cursor [0, 13]
      keystroke 'dit'
      text().toBe "<something></something><again>"
      cursor().toEqual [0, 11]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

  describe "the 'ip' text object", ->
    beforeEach ->
      text "\nParagraph-1\nParagraph-1\nParagraph-1\n\n"
      cursor [2, 2]

    it "applies operators inside the current paragraph in operator-pending mode", ->
      keystroke 'yip'
      text().toBe "\nParagraph-1\nParagraph-1\nParagraph-1\n\n"
      cursor().toEqual [1, 0]
      register('"').toBe "Paragraph-1\nParagraph-1\nParagraph-1\n"
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "selects inside the current paragraph in visual mode", ->
      keystroke 'vip'
      selectedScreenRange().toEqual [[1, 0], [4, 0]]

  describe "the 'ap' text object", ->
    beforeEach ->
      text "text\n\nParagraph-1\nParagraph-1\nParagraph-1\n\nmoretext"
      cursor [3, 2]

    it "applies operators around the current paragraph in operator-pending mode", ->
      keystroke 'yap'
      text().toBe "text\n\nParagraph-1\nParagraph-1\nParagraph-1\n\nmoretext"
      cursor().toEqual [2, 0]
      register('"').toBe "Paragraph-1\nParagraph-1\nParagraph-1\n\n"
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "selects around the current paragraph in visual mode", ->
      keystroke 'vap'
      selectedScreenRange().toEqual [[2, 0], [6, 0]]

  describe "the 'i[' text object", ->
    beforeEach ->
      text "[ something in here and in [here] ]"
      cursor [0, 9]

    it "applies operators inside the current word in operator-pending mode", ->
      keystroke 'di['
      text().toBe "[]"
      cursor().toEqual [0, 1]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "applies operators inside the current word in operator-pending mode (second test)", ->
      cursor [0, 29]
      keystroke 'di['
      text().toBe "[ something in here and in [] ]"
      cursor().toEqual [0, 28]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

  describe "the 'i\'' text object", ->
    beforeEach ->
      text "' something in here and in 'here' ' and over here"
      cursor [0, 9]

    it "applies operators inside the current string in operator-pending mode", ->
      keystroke "di'"
      text().toBe "''here' ' and over here"
      cursor().toEqual [0, 1]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    # I don't like old behavior, that was not in Vim and furthermore, this is counter intuitive.
    # Simply selecting area between quote is that normal user expects.
    # it "applies operators inside the next string in operator-pending mode (if not in a string)", ->
    it "[Changed behavior] applies operators inside area between quote", ->
      cursor [0, 29]
      keystroke "di'"
      text().toBe "' something in here and in '' ' and over here"
      cursor().toEqual [0, 28]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "makes no change if past the last string on a line", ->
      cursor [0, 39]
      keystroke "di'"
      text().toBe "' something in here and in 'here' ' and over here"
      cursor().toEqual [0, 39]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

  describe "the 'i\"' text object", ->
    beforeEach ->
      text '" something in here and in "here" " and over here'
      cursor [0, 9]

    it "applies operators inside the current string in operator-pending mode", ->
      keystroke 'di"'
      text().toBe '""here" " and over here'
      cursor().toEqual [0, 1]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "[Changed behavior] applies operators inside area between quote", ->
      cursor [0, 29]
      keystroke 'di"'
      text().toBe '" something in here and in "" " and over here'
      cursor().toEqual [0, 28]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "makes no change if past the last string on a line", ->
      cursor [0, 39]
      keystroke 'di"'
      text().toBe '" something in here and in "here" " and over here'
      cursor().toEqual [0, 39]
      classListContains('operator-pending-mode').toBe(false)

  describe "the 'aw' text object", ->
    beforeEach ->
      text "12345 abcde ABCDE"
      cursor [0, 9]

    it "applies operators from the start of the current word to the start of the next word in operator-pending mode", ->
      keystroke 'daw'
      text().toBe "12345 ABCDE"
      cursor().toEqual [0, 6]
      register('"').toBe "abcde "
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "selects from the start of the current word to the start of the next word in visual mode", ->
      keystroke 'vaw'
      selectedScreenRange().toEqual [[0, 6], [0, 12]]

    it "doesn't span newlines", ->
      text "12345\nabcde ABCDE"
      cursor [0, 3]
      keystroke 'vaw'
      selectedBufferRange().toEqual [[0, 0], [0, 5]]

    it "doesn't span special characters", ->
      text "1(345\nabcde ABCDE"
      cursor [0, 3]
      keystroke 'vaw'
      selectedBufferRange().toEqual [[0, 2], [0, 5]]

  describe "the 'aW' text object", ->
    beforeEach ->
      text "12(45 ab'de ABCDE"
      cursor [0, 9]

    it "applies operators from the start of the current whole word to the start of the next whole word in operator-pending mode", ->
      keystroke 'daW'
      text().toBe "12(45 ABCDE"
      cursor().toEqual [0, 6]
      register('"').toBe "ab'de "
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "selects from the start of the current whole word to the start of the next whole word in visual mode", ->
      keystroke 'vaW'
      selectedScreenRange().toEqual [[0, 6], [0, 12]]

    it "doesn't span newlines", ->
      text "12(45\nab'de ABCDE"
      cursor [0, 4]
      keystroke 'vaW'
      selectedBufferRange().toEqual [[0, 0], [0, 5]]

  describe "the 'a(' text object", ->
    beforeEach ->
      text "( something in here and in (here) )"
      cursor [0, 9]

    it "applies operators around the current parentheses in operator-pending mode", ->
      keystroke 'da('
      text().toBe ""
      cursor().toEqual [0, 0]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "applies operators around the current parentheses in operator-pending mode (second test)", ->
      cursor [0, 29]
      keystroke 'da('
      text().toBe "( something in here and in  )"
      cursor().toEqual [0, 27]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

  describe "the 'a{' text object", ->
    beforeEach ->
      text "{ something in here and in {here} }"
      cursor [0, 9]

    it "applies operators around the current curly brackets in operator-pending mode", ->
      keystroke 'da{'
      text().toBe ""
      cursor().toEqual [0, 0]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "applies operators around the current curly brackets in operator-pending mode (second test)", ->
      cursor [0, 29]
      keystroke 'da{'
      text().toBe "{ something in here and in  }"
      cursor().toEqual [0, 27]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

  describe "the 'a<' text object", ->
    beforeEach ->
      text "< something in here and in <here> >"
      cursor [0, 9]

    it "applies operators around the current angle brackets in operator-pending mode", ->
      keystroke 'da<'
      text().toBe ""
      cursor().toEqual [0, 0]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "applies operators around the current angle brackets in operator-pending mode (second test)", ->
      cursor [0, 29]
      keystroke 'da<'
      text().toBe "< something in here and in  >"
      cursor().toEqual [0, 27]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

  describe "the 'a[' text object", ->
    beforeEach ->
      text "[ something in here and in [here] ]"
      cursor [0, 9]

    it "applies operators around the current square brackets in operator-pending mode", ->
      keystroke 'da['
      text().toBe ""
      cursor().toEqual [0, 0]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "applies operators around the current square brackets in operator-pending mode (second test)", ->
      cursor [0, 29]
      keystroke 'da['
      text().toBe "[ something in here and in  ]"
      cursor().toEqual [0, 27]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

  describe "the 'a\'' text object", ->
    beforeEach ->
      text "' something in here and in 'here' '"
      cursor [0, 9]

    it "applies operators around the current single quotes in operator-pending mode", ->
      keystroke "da'"
      text().toBe "here' '"
      cursor().toEqual [0, 0]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "applies operators around the current single quotes in operator-pending mode (second test)", ->
      cursor [0, 29]
      keystroke "da'"
      text().toBe "' something in here and in  '"
      cursor().toEqual [0, 27]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

  describe "the 'a\"' text object", ->
    beforeEach ->
      text '" something in here and in "here" "'
      cursor [0, 9]

    it "applies operators around the current double quotes in operator-pending mode", ->
      keystroke 'da"'
      text().toBe 'here" "'
      cursor().toEqual [0, 0]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)

    it "applies operators around the current double quotes in operator-pending mode (second test)", ->
      cursor [0, 29]
      keystroke 'da"'
      text().toBe '" something in here and in  "'
      cursor().toEqual [0, 27]
      classListContains('operator-pending-mode').toBe(false)
      classListContains('normal-mode').toBe(true)
