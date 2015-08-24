# Refactoring status: 0%
helpers = require './spec-helper'

describe "Prefixes", ->
  [editor, editorElement, vimState] = []

  beforeEach ->
    vimMode = atom.packages.loadPackage('vim-mode')
    vimMode.activateResources()

    helpers.getEditorElement (element, init) ->
      editorElement = element
      editor = editorElement.getModel()
      vimState = editorElement.vimState
      vimState.activateNormalMode()
      vimState.resetNormalMode()
      init()

  keydown = (key, options={}) ->
    options.element ?= editorElement
    helpers.keydown(key, options)

  keystroke = (keys, options={}) ->
    options.element ?= editorElement
    for key in keys.split('')
      helpers.keydown(key, options)

  normalModeInputKeydown = (key, opts = {}) ->
    theEditor = opts.editor or editor
    theEditor.normalModeInputView.editorElement.getModel().setText(key)

  text = (text=null) ->
    if text
      editor.setText(text)
    else
      expect(editor.getText())

  cursor = (point=null) ->
    if point
      editor.setCursorScreenPosition(point)
    else
      expect(editor.getCursorScreenPosition())

  register = (name, value) ->
    if value
      vimState.register.set(name, value)
    else
      expect(vimState.register.get(name).text)

  describe "Repeat", ->
    describe "with operations", ->
      beforeEach ->
        text "123456789abc"
        cursor [0, 0]

      it "repeats N times", ->
        keystroke '3x'
        text().toBe '456789abc'

      it "repeats NN times", ->
        keystroke '10x'
        text().toBe 'bc'

    describe "with motions", ->
      beforeEach ->
        text 'one two three'
        cursor [0, 0]

      it "repeats N times", ->
        keystroke 'd2w'
        text().toBe 'three'

    describe "in visual mode", ->
      beforeEach ->
        text 'one two three'
        cursor [0, 0]

      it "repeats movements in visual mode", ->
        keystroke 'v2w'
        cursor().toEqual [0, 9]

  describe "Register", ->
    describe "the a register", ->
      it "saves a value for future reading", ->
        register('a', text: 'new content')
        register('a').toEqual 'new content'

      it "overwrites a value previously in the register", ->
        register('a', text: 'content')
        register('a', text: 'new content')
        register('a').toEqual 'new content'

    describe "the B register", ->
      it "saves a value for future reading", ->
        register('B', text: 'new content')
        register('b').toEqual 'new content'
        register('B').toEqual 'new content'

      it "appends to a value previously in the register", ->
        register('b', text: 'content')
        register('B', text: 'new content')
        register("b").toEqual 'contentnew content'

      it "appends linewise to a linewise value previously in the register", ->
        register('b', {type: 'linewise', text: 'content\n'})
        register('B', text: 'new content')
        register('b').toEqual 'content\nnew content\n'

      it "appends linewise to a character value previously in the register", ->
        register('b', text: 'content')
        register('B', {type: 'linewise', text: 'new content\n'})
        register("b").toEqual 'content\nnew content\n'


    describe "the * register", ->
      describe "reading", ->
        it "is the same the system clipboard", ->
          register('*').toEqual 'initial clipboard content'
          expect(vimState.register.get('*').type).toEqual 'character'

      describe "writing", ->
        beforeEach ->
          register('*', text: 'new content')

        it "overwrites the contents of the system clipboard", ->
          expect(atom.clipboard.read()).toEqual 'new content'

    # FIXME: once linux support comes out, this needs to read from
    # the correct clipboard. For now it behaves just like the * register
    # See :help x11-cut-buffer and :help registers for more details on how these
    # registers work on an X11 based system.
    describe "the + register", ->
      describe "reading", ->
        it "is the same the system clipboard", ->
          register('*').toEqual 'initial clipboard content'
          expect(vimState.register.get('*').type).toEqual 'character'

      describe "writing", ->
        beforeEach ->
          register('*', text: 'new content')

        it "overwrites the contents of the system clipboard", ->
          expect(atom.clipboard.read()).toEqual 'new content'

    describe "the _ register", ->
      describe "reading", ->
        it "is always the empty string", ->
          register('_').toEqual ''

      describe "writing", ->
        it "throws away anything written to it", ->
          register('_', text: 'new content')
          register("_").toEqual ''

    describe "the % register", ->
      beforeEach ->
        spyOn(editor, 'getURI').andReturn('/Users/atom/known_value.txt')

      describe "reading", ->
        it "returns the filename of the current editor", ->
          register('%').toEqual '/Users/atom/known_value.txt'

      describe "writing", ->
        it "throws away anything written to it", ->
          register('%', text: "new content")
          register('%').toEqual '/Users/atom/known_value.txt'

    describe "the ctrl-r command in insert mode", ->
      beforeEach ->
        text "02\n"
        cursor [0, 0]
        register('"', text: '345')
        register('a', text: 'abc')
        atom.clipboard.write "clip"
        keydown 'a'
        editor.insertText '1'

      it "inserts contents of the unnamed register with \"", ->
        keydown 'r', ctrl: true
        normalModeInputKeydown '"'
        text().toBe '013452\n'

      describe "when useClipboardAsDefaultRegister enabled", ->
        it "inserts contents from clipboard with \"", ->
          atom.config.set 'vim-mode.useClipboardAsDefaultRegister', true
          keydown 'r', ctrl: true
          normalModeInputKeydown '"'
          text().toBe '01clip2\n'

      it "inserts contents of the 'a' register", ->
        keydown 'r', ctrl: true
        normalModeInputKeydown 'a'
        text().toBe '01abc2\n'

      it "is cancelled with the escape key", ->
        keydown 'r', ctrl: true
        normalModeInputKeydown 'escape'
        text().toBe '012\n'
        expect(vimState.mode).toBe "insert"
        cursor().toEqual [0, 2]
