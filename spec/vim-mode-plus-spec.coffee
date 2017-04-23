{getVimState, getView} = require './spec-helper'

packageName = 'vim-mode-plus'
describe "vim-mode-plus", ->
  [set, ensure, keystroke, editor, editorElement, vimState, workspaceElement] = []

  beforeEach ->
    getVimState (_vimState, vim) ->
      vimState = _vimState
      {editor, editorElement} = _vimState
      {set, ensure, keystroke} = vim

    workspaceElement = getView(atom.workspace)

    waitsForPromise ->
      atom.packages.activatePackage('status-bar')

  describe ".activate", ->
    it "puts the editor in normal-mode initially by default", ->
      ensure mode: 'normal'

    it "shows the current vim mode in the status bar", ->
      statusBarTile = null

      waitsFor ->
        statusBarTile = workspaceElement.querySelector("#status-bar-vim-mode-plus")

      runs ->
        expect(statusBarTile.textContent).toBe("N")
        ensure 'i', mode: 'insert'
        expect(statusBarTile.textContent).toBe("I")

  describe ".deactivate", ->
    it "removes the vim classes from the editor", ->
      atom.packages.deactivatePackage(packageName)
      expect(editorElement.classList.contains("vim-mode-plus")).toBe(false)
      expect(editorElement.classList.contains("normal-mode")).toBe(false)

    it "removes the vim commands from the editor element", ->
      vimCommands = ->
        atom.commands.findCommands(target: editorElement).filter (cmd) ->
          cmd.name.startsWith("vim-mode-plus:")

      expect(vimCommands().length).toBeGreaterThan(0)
      atom.packages.deactivatePackage(packageName)
      expect(vimCommands().length).toBe(0)
