{getVimState, dispatch, TextData} = require './spec-helper'
settings = require '../lib/settings'
globalState = require '../lib/global-state'

describe "Motion Scroll", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []
  text = new TextData([0...100].join("\n"))

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
      atom.views.performDocumentPoll()
      editorElement.setScrollTop(40 * 10)
      editor.setCursorBufferPosition([42, 0])

  afterEach ->
    vimState.resetNormalMode()

  describe "the ctrl-u keybinding", ->
    it "moves the screen down by half screen size and keeps cursor onscreen", ->
      ensure 'ctrl-u',
        scrollTop: 300
        cursor: [32, 0]

    it "selects on visual mode", ->
      set cursor: [42, 1]
      ensure 'v ctrl-u',
        selectedText: text.getLines([32..42], chomp: true)

    it "selects on linewise mode", ->
      ensure 'V ctrl-u',
        selectedText: text.getLines([33..42])

  describe "the ctrl-b keybinding", ->
    it "moves screen up one page", ->
      ensure 'ctrl-b',
        scrollTop: 200
        cursor: [22, 0]

    it "selects on visual mode", ->
      set cursor: [42, 1]
      ensure 'v ctrl-b',
        selectedText: text.getLines([22..42], chomp: true)

    it "selects on linewise mode", ->
      ensure 'V ctrl-b',
        selectedText: text.getLines([23..42])

  describe "the ctrl-d keybinding", ->
    it "moves the screen down by half screen size and keeps cursor onscreen", ->
      ensure 'ctrl-d',
        scrollTop: 500
        cursor: [52, 0]

    it "selects on visual mode", ->
      set cursor: [42, 1]
      ensure 'v ctrl-d',
        selectedText: text.getLines([42..52], chomp: true).slice(1, -1)

    it "selects on linewise mode", ->
      ensure 'V ctrl-d',
        selectedText: text.getLines([42..53])

  describe "the ctrl-f keybinding", ->
    it "moves screen down one page", ->
      ensure 'ctrl-f',
        scrollTop: 600
        cursor: [62, 0]

    it "selects on visual mode", ->
      set cursor: [42, 1]
      ensure 'v ctrl-f',
        selectedText: text.getLines([42..62], chomp: true).slice(1, -1)

    it "selects on linewise mode", ->
      ensure 'V ctrl-f',
        selectedText: text.getLines([42..63])
