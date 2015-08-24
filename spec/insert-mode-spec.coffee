# Refactoring status: 80%
helpers = require './spec-helper'
{set, ensure, keystroke} = helpers
_ = require 'underscore-plus'

describe "Insert mode commands", ->
  [editor, editorElement, vimState] = []

  beforeEach ->
    pack = atom.packages.loadPackage('vim-mode')
    pack.activateResources()

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

  describe "Copy from line above/below", ->
    beforeEach ->
      set
        text: "12345\n\nabcd\nefghi"
        cursorBuffer: [1, 0]
        addCursor: [3, 0]
      keystroke 'i'

    describe "the ctrl-y command", ->
      it "copies from the line above", ->
        ensure [ctrl: 'y'], text: '12345\n1\nabcd\naefghi'
        editor.insertText ' '
        ensure [ctrl: 'y'], text: '12345\n1 3\nabcd\na cefghi'

      it "does nothing if there's nothing above the cursor", ->
        editor.insertText 'fill'
        ensure [ctrl: 'y'], text: '12345\nfill5\nabcd\nfillefghi'
        ensure [ctrl: 'y'], text: '12345\nfill5\nabcd\nfillefghi'

      it "does nothing on the first line", ->
        set
          cursorBuffer: [0, 2]
          addCursor: [3, 2]
        editor.insertText 'a'
        ensure text: '12a345\n\nabcd\nefaghi'
        ensure [ctrl: 'y'], text: '12a345\n\nabcd\nefadghi'

    describe "the ctrl-e command", ->
      beforeEach ->
        atom.keymaps.add "test",
          'atom-text-editor.vim-mode.insert-mode':
            'ctrl-e': 'vim-mode:copy-from-line-below'

      it "copies from the line below", ->
        ensure [ctrl: 'e'], text: '12345\na\nabcd\nefghi'
        editor.insertText ' '
        ensure [ctrl: 'e'], text: '12345\na c\nabcd\n efghi'

      it "does nothing if there's nothing below the cursor", ->
        editor.insertText 'foo'
        ensure [ctrl: 'e'], text: '12345\nfood\nabcd\nfooefghi'
        ensure [ctrl: 'e'], text: '12345\nfood\nabcd\nfooefghi'
