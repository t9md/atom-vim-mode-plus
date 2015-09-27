# Refactoring status: 0%
packageName = 'vim-mode-plus'
describe "VimModePlus", ->
  [editor, editorElement, workspaceElement] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

    waitsForPromise ->
      atom.workspace.open()

    waitsForPromise ->
      atom.packages.activatePackage(packageName)

    waitsForPromise ->
      atom.packages.activatePackage('status-bar')

    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)

  describe ".activate", ->
    it "puts the editor in normal-mode initially by default", ->
      expect(editorElement.classList.contains('vim-mode-plus')).toBe(true)
      expect(editorElement.classList.contains('normal-mode')).toBe(true)

    it "shows the current vim mode in the status bar", ->
      statusBarTile = null

      waitsFor ->
        statusBarTile = workspaceElement.querySelector("#status-bar-vim-mode-plus")

      runs ->
        expect(statusBarTile.textContent).toBe("Normal")
        atom.commands.dispatch(editorElement, "vim-mode-plus:activate-insert-mode")
        expect(statusBarTile.textContent).toBe("Insert")

    it "doesn't register duplicate command listeners for editors", ->
      editor.setText("12345")
      editor.setCursorBufferPosition([0, 0])

      pane = atom.workspace.getActivePane()
      newPane = pane.splitRight()
      pane.removeItem(editor)
      newPane.addItem(editor)

      atom.commands.dispatch(editorElement, "vim-mode-plus:move-right")
      expect(editor.getCursorBufferPosition()).toEqual([0, 1])

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
