{getVimState, dispatch, TextData} = require './spec-helper'
settings = require '../lib/settings'

describe "Motion Scroll", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []
  lines = (n + " " + 'X'.repeat(10) for n in [0...100]).join("\n")
  text = new TextData(lines)

  beforeEach ->
    getVimState (state, _vim) ->
      vimState = state # to refer as vimState later.
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = _vim

    runs ->
      jasmine.attachToDOM(editorElement)
      set text: text.getRaw()

      editorElement.setHeight(20 * 10)
      editorElement.style.lineHeight = "10px"

      if editorElement.measureDimensions?
        # For Atom-v1.19
        editorElement.measureDimensions()
      else # For Atom-v1.18
        # [TODO] Remove when v.1.19 become stable
        atom.views.performDocumentPoll()

      editorElement.setScrollTop(40 * 10)
      set cursor: [42, 0]

  describe "the ctrl-u keybinding", ->
    it "moves the screen down by half screen size and keeps cursor onscreen", ->
      ensure 'ctrl-u',
        scrollTop: 300
        cursor: [32, 0]

    it "selects on visual mode", ->
      set cursor: [42, 1]
      ensure 'v ctrl-u',
        selectedText: text.getLines([32..41]) + "42"

    it "selects on linewise mode", ->
      ensure 'V ctrl-u',
        selectedText: text.getLines([32..42])

  describe "the ctrl-b keybinding", ->
    it "moves screen up one page", ->
      ensure 'ctrl-b',
        scrollTop: 200
        cursor: [22, 0]

    it "selects on visual mode", ->
      set cursor: [42, 1]
      ensure 'v ctrl-b',
        selectedText: text.getLines([22..41]) + "42"

    it "selects on linewise mode", ->
      ensure 'V ctrl-b',
        selectedText: text.getLines([22..42])

  describe "the ctrl-d keybinding", ->
    it "moves the screen down by half screen size and keeps cursor onscreen", ->
      ensure 'ctrl-d',
        scrollTop: 500
        cursor: [52, 0]

    it "selects on visual mode", ->
      set cursor: [42, 1]
      ensure 'v ctrl-d',
        selectedText: text.getLines([42..51]).slice(1) + "5"

    it "selects on linewise mode", ->
      ensure 'V ctrl-d',
        selectedText: text.getLines([42..52])

  describe "the ctrl-f keybinding", ->
    it "moves screen down one page", ->
      ensure 'ctrl-f',
        scrollTop: 600
        cursor: [62, 0]

    it "selects on visual mode", ->
      set cursor: [42, 1]
      ensure 'v ctrl-f',
        selectedText: text.getLines([42..61]).slice(1) + "6"

    it "selects on linewise mode", ->
      ensure 'V ctrl-f',
        selectedText: text.getLines([42..62])

  describe "ctrl-f, ctrl-b, ctrl-d, ctrl-u", ->
    beforeEach ->
      settings.set('moveToFirstCharacterOnVerticalMotion', false)
      set cursor: [42, 10]
      ensure scrollTop: 400

    it "go to row with keep column and respect cursor.goalColum", ->
      ensure 'ctrl-b', scrollTop: 200, cursor: [22, 10]
      ensure 'ctrl-f', scrollTop: 400, cursor: [42, 10]
      ensure 'ctrl-u', scrollTop: 300, cursor: [32, 10]
      ensure 'ctrl-d', scrollTop: 400, cursor: [42, 10]
      ensure '$', cursor: [42, 12]
      expect(editor.getLastCursor().goalColumn).toBe(Infinity)
      ensure 'ctrl-b', scrollTop: 200, cursor: [22, 12]
      ensure 'ctrl-b', scrollTop:   0, cursor: [ 2, 11]
      ensure 'ctrl-f', scrollTop: 200, cursor: [22, 12]
      ensure 'ctrl-f', scrollTop: 400, cursor: [42, 12]
      ensure 'ctrl-u', scrollTop: 300, cursor: [32, 12]
      ensure 'ctrl-d', scrollTop: 400, cursor: [42, 12]
      expect(editor.getLastCursor().goalColumn).toBe(Infinity)
