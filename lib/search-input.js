const {Emitter, Disposable, CompositeDisposable} = require("atom")

module.exports = class SearchInput {
  onDidChange(fn) {
    return this.emitter.on("did-change", fn)
  }
  onDidConfirm(fn) {
    return this.emitter.on("did-confirm", fn)
  }
  onDidCancel(fn) {
    return this.emitter.on("did-cancel", fn)
  }
  onDidCommand(fn) {
    return this.emitter.on("did-command", fn)
  }

  constructor(vimState) {
    this.vimState = vimState
    this.literalModeDeactivator = null
    this.emitter = new Emitter()
    this.vimState.onDidDestroy(() => this.destroy())

    this.container = document.createElement("div")
    this.container.className = "vim-mode-plus-search-container"
    this.container.innerHTML = vimState.utils.removeIndent(`
      <div class='options-container'>
        <span class='inline-block-tight btn btn-primary'>.*</span>
      </div>
      <div class='editor-container'>
      </div>
      `)

    const [optionsContainer, editorContainer] = this.container.getElementsByTagName("div")
    this.regexSearchStatus = optionsContainer.firstElementChild
    const editor = atom.workspace.buildTextEditor({mini: true})
    this.editor = editor
    this.editorElement = editor.element
    this.editorElement.classList.add("vim-mode-plus-search")
    editorContainer.appendChild(this.editorElement)
    editor.onDidChange(() => {
      if (this.finished) return
      this.emitter.emit("did-change", editor.getText())
    })

    this.panel = atom.workspace.addBottomPanel({item: this.container, visible: false})

    this.vimState.onDidFailToPushToOperationStack(() => this.cancel())

    this.registerCommands()
  }

  destroy() {
    this.editor.destroy()
    if (this.panel) this.panel.destroy()
    this.editor = this.panel = this.editorElement = this.vimState = null
  }

  handleEvents() {
    return atom.commands.add(this.editorElement, {
      "core:confirm": () => this.confirm(),
      "core:cancel": () => this.cancel(),
      "core:backspace": () => this.backspace(),
      "vim-mode-plus:input-cancel": () => this.cancel(),
    })
  }

  focus(options = {}) {
    this.options = options
    this.finished = false

    if (this.options.classList != null) {
      this.editorElement.classList.add(...this.options.classList)
    }
    this.panel.show()
    this.editorElement.focus()

    const cancel = this.cancel.bind(this)
    this.vimState.editorElement.addEventListener("click", cancel)

    this.focusSubscriptions = new CompositeDisposable()
    this.focusSubscriptions.add(
      this.handleEvents(),
      new Disposable(() => this.vimState.editorElement.removeEventListener("click", cancel)), // Cancel on mouse click
      atom.workspace.onDidChangeActivePaneItem(cancel) // Cancel on tab switch
    )
  }

  unfocus() {
    this.finished = true
    if (this.options.classList) {
      this.editorElement.classList.remove(...this.options.classList)
    }
    this.regexSearchStatus.classList.add("btn-primary")
    if (this.literalModeDeactivator) this.literalModeDeactivator.dispose()

    if (this.focusSubscriptions) this.focusSubscriptions.dispose()

    atom.workspace.getActivePane().activate()
    this.editor.setText("")
    if (this.panel) this.panel.hide()
  }

  updateOptionSettings({useRegexp} = {}) {
    this.regexSearchStatus.classList.toggle("btn-primary", useRegexp)
  }

  setCursorWord() {
    this.editor.insertText(this.vimState.editor.getWordUnderCursor())
  }

  activateLiteralMode() {
    if (this.literalModeDeactivator) {
      this.literalModeDeactivator.dispose()
    } else {
      this.literalModeDeactivator = new CompositeDisposable()
      this.editorElement.classList.add("literal-mode")

      this.literalModeDeactivator.add(
        new Disposable(() => {
          this.editorElement.classList.remove("literal-mode")
          this.literalModeDeactivator = null
        })
      )
    }
  }

  isVisible() {
    return this.panel && this.panel.isVisible()
  }

  cancel() {
    if (this.finished) return

    this.emitter.emit("did-cancel")
    this.unfocus()
  }

  backspace() {
    if (!this.editor.getText().length) this.cancel()
  }

  confirm(landingPoint = null) {
    this.emitter.emit("did-confirm", {input: this.editor.getText(), landingPoint})
    this.unfocus()
  }

  stopPropagation(oldCommands) {
    const newCommands = {}
    for (let name of Object.keys(oldCommands)) {
      const fn = oldCommands[name]

      if (!name.includes(":")) name = `vim-mode-plus:${name}`

      newCommands[name] = function(event) {
        event.stopImmediatePropagation()
        fn(event)
      }
    }
    return newCommands
  }

  emitDidCommand(name, options = {}) {
    options.name = name
    options.input = this.editor.getText()
    this.emitter.emit("did-command", options)
  }

  registerCommands() {
    return atom.commands.add(
      this.editorElement,
      this.stopPropagation({
        "search-confirm": () => this.confirm(),
        "search-land-to-start": () => this.confirm(),
        "search-land-to-end": () => this.confirm("end"),
        "search-cancel": () => this.cancel(),

        "search-visit-next": () => this.emitDidCommand("visit", {direction: "next"}),
        "search-visit-prev": () => this.emitDidCommand("visit", {direction: "prev"}),

        "select-occurrence-from-search": () => this.emitDidCommand("occurrence", {operation: "SelectOccurrence"}),
        "change-occurrence-from-search": () => this.emitDidCommand("occurrence", {operation: "ChangeOccurrence"}),
        "add-occurrence-pattern-from-search": () => this.emitDidCommand("occurrence"),
        "project-find-from-search": () => this.emitDidCommand("project-find"),

        "search-insert-wild-pattern": () => this.editor.insertText(".*?"),
        "search-activate-literal-mode": () => this.activateLiteralMode(),
        "search-set-cursor-word": () => this.setCursorWord(),
        "core:move-up": () => this.editor.setText(this.vimState.searchHistory.get("prev")),
        "core:move-down": () => this.editor.setText(this.vimState.searchHistory.get("next")),
      })
    )
  }
}
