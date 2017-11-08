"use babel"

const settings = require("./settings")

let CSON, path, selectList, __plus
const CLASS_REGISTRY = {}

function _plus() {
  return __plus || (__plus = require("underscore-plus"))
}

let VMP_LOADING_FILE
function loadVmpOperationFile(filename) {
  // Call to loadVmpOperationFile can be nested.
  // 1. require("./operator-transform-string")
  // 2. in operator-transform-string.coffee call Base.getClass("Operator") cause operator.coffee required.
  // So we have to save original VMP_LOADING_FILE and restore it after require finished.
  const preserved = VMP_LOADING_FILE
  VMP_LOADING_FILE = filename
  require(filename)
  VMP_LOADING_FILE = preserved
}

class Base {
  static commandTable = null
  static commandPrefix = "vim-mode-plus"
  static commandScope = "atom-text-editor"
  static operationKind = null
  static getEditorState = null // set through init()

  recordable = false
  repeated = false
  count = null
  defaultCount = 1

  get name() {
    return this.constructor.name
  }

  constructor(vimState) {
    this.vimState = vimState
  }

  initialize() {}

  // Called both on cancel and success
  resetState() {}

  // OperationStack postpone execution untill isReady() get true
  // Override if necessary.
  isReady() {
    return true
  }

  // VisualModeSelect is anormal, since it auto complemented in visial mode.
  // In other word, normal-operator is explicit whereas anormal-operator is inplicit.
  isTargetOfNormalOperator() {
    return this.operator && this.operator.name !== "VisualModeSelect"
  }

  getCount(offset = 0) {
    if (this.count == null) {
      this.count = this.vimState.hasCount() ? this.vimState.getCount() : this.defaultCount
    }
    return this.count + offset
  }

  resetCount() {
    this.count = null
  }

  countTimes(last, fn) {
    if (last < 1) return

    let stopped = false
    const stop = () => (stopped = true)
    for (let count = 1; count <= last; count++) {
      fn({count, isFinal: count === last, stop})
      if (stopped) break
    }
  }

  activateMode(mode, submode) {
    this.onDidFinishOperation(() => this.vimState.activate(mode, submode))
  }

  activateModeIfNecessary(mode, submode) {
    if (!this.vimState.isMode(mode, submode)) {
      this.activateMode(mode, submode)
    }
  }

  getInstance(name, properties) {
    return this.constructor.getInstance(this.vimState, name, properties)
  }

  cancelOperation() {
    this.vimState.operationStack.cancel(this)
  }

  processOperation() {
    this.vimState.operationStack.process()
  }

  focusSelectList(options = {}) {
    this.onDidCancelSelectList(() => this.cancelOperation())
    if (!selectList) {
      selectList = new (require("./select-list"))()
    }
    selectList.show(this.vimState, options)
  }

  focusInput(options = {}) {
    if (!options.onConfirm) {
      options.onConfirm = input => {
        this.input = input
        this.processOperation()
      }
    }
    if (!options.onCancel) options.onCancel = () => this.cancelOperation()
    if (!options.onChange) options.onChange = input => this.vimState.hover.set(input)

    this.vimState.focusInput(options)
  }

  // Return promise which resolve with input char or `undefined` when cancelled.
  focusInputPromised(options = {}) {
    return new Promise(resolve => {
      const defaultOptions = {hideCursor: true, onChange: input => this.vimState.hover.set(input)}
      this.vimState.focusInput(Object.assign(defaultOptions, options, {onConfirm: resolve, onCancel: resolve}))
    })
  }

  readChar() {
    this.vimState.readChar({
      onConfirm: input => {
        this.input = input
        this.processOperation()
      },
      onCancel: () => this.cancelOperation(),
    })
  }

  // Return promise which resolve with read char or `undefined` when cancelled.
  readCharPromised() {
    return new Promise(resolve => {
      this.vimState.readChar({onConfirm: resolve, onCancel: resolve})
    })
  }

  instanceof(klassName) {
    return this instanceof Base.getClass(klassName)
  }

  isOperator() {
    // Don't use `instanceof` to postpone require for faster activation.
    return this.constructor.operationKind === "operator"
  }

  isMotion() {
    // Don't use `instanceof` to postpone require for faster activation.
    return this.constructor.operationKind === "motion"
  }

  isTextObject() {
    // Don't use `instanceof` to postpone require for faster activation.
    return this.constructor.operationKind === "text-object"
  }

  getCursorBufferPosition() {
    return this.getBufferPositionForCursor(this.editor.getLastCursor())
  }

  getCursorBufferPositions() {
    return this.editor.getCursors().map(cursor => this.getBufferPositionForCursor(cursor))
  }

  getCursorBufferPositionsOrdered() {
    return this.utils.sortPoints(this.getCursorBufferPositions())
  }

  getBufferPositionForCursor(cursor) {
    return this.mode === "visual" ? this.getCursorPositionForSelection(cursor.selection) : cursor.getBufferPosition()
  }

  getCursorPositionForSelection(selection) {
    return this.swrap(selection).getBufferPositionFor("head", {from: ["property", "selection"]})
  }

  getOperationTypeChar() {
    return {operator: "O", "text-object": "T", motion: "M", "misc-command": "X"}[this.constructor.operationKind]
  }

  toString() {
    const base = `${this.name}<${this.getOperationTypeChar()}>`
    return this.target ? `${base}{target = ${this.target.toString()}}` : base
  }

  getCommandName() {
    return this.constructor.getCommandName()
  }

  getCommandNameWithoutPrefix() {
    return this.constructor.getCommandNameWithoutPrefix()
  }

  static async writeCommandTableOnDisk() {
    const commandTable = this.generateCommandTableByEagerLoad()
    const _ = _plus()
    if (_.isEqual(this.commandTable, commandTable)) {
      atom.notifications.addInfo("No changes in commandTable", {dismissable: true})
      return
    }

    if (!CSON) CSON = require("season")
    if (!path) path = require("path")

    const loadableCSONText =
      [
        "# This file is auto generated by `vim-mode-plus:write-command-table-on-disk` command.",
        "# DONT edit manually.",
        "module.exports =",
        CSON.stringify(commandTable),
      ].join("\n") + "\n"

    const commandTablePath = path.join(__dirname, "command-table.coffee")
    const editor = await atom.workspace.open(commandTablePath, {activatePane: false, activateItem: false})
    editor.setText(loadableCSONText)
    await editor.save()
    atom.notifications.addInfo("Updated commandTable", {dismissable: true})
  }

  static generateCommandTableByEagerLoad() {
    // NOTE: changing order affects output of lib/command-table.coffee
    const filesToLoad = [
      "./operator",
      "./operator-insert",
      "./operator-transform-string",
      "./motion",
      "./motion-search",
      "./text-object",
      "./misc-command",
    ]
    filesToLoad.forEach(loadVmpOperationFile)
    const _ = _plus()
    const klassesGroupedByFile = _.groupBy(_.values(CLASS_REGISTRY), klass => klass.file)

    const commandTable = {}
    for (const file of filesToLoad) {
      for (const klass of klassesGroupedByFile[file]) {
        commandTable[klass.name] = klass.command
          ? {file: klass.file, commandName: klass.getCommandName(), commandScope: klass.commandScope}
          : {file: klass.file}
      }
    }
    return commandTable
  }

  // Return disposables for vmp commands.
  static init(getEditorState) {
    this.getEditorState = getEditorState
    this.commandTable = require("./command-table")

    return Object.keys(this.commandTable)
      .filter(name => this.commandTable[name].commandName)
      .map(name => this.registerCommandFromSpec(name, this.commandTable[name]))
  }

  static register(command = true) {
    this.command = command
    this.file = VMP_LOADING_FILE
    if (this.name in CLASS_REGISTRY) {
      console.warn(`Duplicate constructor ${this.name}`)
    }
    CLASS_REGISTRY[this.name] = this
  }

  static getClass(name) {
    if (name in CLASS_REGISTRY) return CLASS_REGISTRY[name]

    const fileToLoad = this.commandTable[name].file
    if (atom.inDevMode() && settings.get("debug")) {
      console.log(`lazy-require: ${fileToLoad} for ${name}`)
    }
    loadVmpOperationFile(fileToLoad)
    if (name in CLASS_REGISTRY) return CLASS_REGISTRY[name]

    throw new Error(`class '${name}' not found`)
  }

  static getInstance(vimState, klass, properties) {
    klass = typeof klass === "function" ? klass : Base.getClass(klass)
    const object = new klass(vimState)
    if (properties) Object.assign(object, properties)
    object.initialize()
    return object
  }

  static getClassRegistry() {
    return CLASS_REGISTRY
  }

  static getCommandName() {
    return this.commandPrefix + ":" + _plus().dasherize(this.name)
  }

  static getCommandNameWithoutPrefix() {
    return _plus().dasherize(this.name)
  }

  static registerCommand() {
    return this.registerCommandFromSpec(this.name, {
      commandScope: this.commandScope,
      commandName: this.getCommandName(),
      getClass: () => this,
    })
  }

  static registerCommandFromSpec(name, spec) {
    let {commandScope = "atom-text-editor", commandPrefix = "vim-mode-plus", commandName, getClass} = spec
    if (!commandName) commandName = commandPrefix + ":" + _plus().dasherize(name)
    if (!getClass) getClass = name => this.getClass(name)

    const getEditorState = this.getEditorState
    return atom.commands.add(commandScope, commandName, function(event) {
      const vimState = getEditorState(this.getModel()) || getEditorState(atom.workspace.getActiveTextEditor())
      if (vimState) vimState.operationStack.run(getClass(name)) // vimState possibly be undefined See #85
      event.stopPropagation()
    })
  }

  static getKindForCommandName(command) {
    const commandWithoutPrefix = command.replace(/^vim-mode-plus:/, "")
    const {capitalize, camelize} = _plus()
    const commandClassName = capitalize(camelize(commandWithoutPrefix))
    if (commandClassName in CLASS_REGISTRY) {
      return CLASS_REGISTRY[commandClassName].operationKind
    }
  }

  getSmoothScrollDuation(kind) {
    const base = "smoothScrollOn" + kind
    return this.getConfig(base) ? this.getConfig(base + "Duration") : 0
  }

  // Proxy propperties and methods
  //===========================================================================
  get mode() { return this.vimState.mode } // prettier-ignore
  get submode() { return this.vimState.submode } // prettier-ignore
  get swrap() { return this.vimState.swrap } // prettier-ignore
  get utils() { return this.vimState.utils } // prettier-ignore
  get editor() { return this.vimState.editor } // prettier-ignore
  get editorElement() { return this.vimState.editorElement } // prettier-ignore
  get globalState() { return this.vimState.globalState } // prettier-ignore
  get mutationManager() { return this.vimState.mutationManager } // prettier-ignore
  get occurrenceManager() { return this.vimState.occurrenceManager } // prettier-ignore
  get persistentSelection() { return this.vimState.persistentSelection } // prettier-ignore

  onDidChangeSearch(...args) { return this.vimState.onDidChangeSearch(...args) } // prettier-ignore
  onDidConfirmSearch(...args) { return this.vimState.onDidConfirmSearch(...args) } // prettier-ignore
  onDidCancelSearch(...args) { return this.vimState.onDidCancelSearch(...args) } // prettier-ignore
  onDidCommandSearch(...args) { return this.vimState.onDidCommandSearch(...args) } // prettier-ignore
  onDidSetTarget(...args) { return this.vimState.onDidSetTarget(...args) } // prettier-ignore
  emitDidSetTarget(...args) { return this.vimState.emitDidSetTarget(...args) } // prettier-ignore
  onWillSelectTarget(...args) { return this.vimState.onWillSelectTarget(...args) } // prettier-ignore
  emitWillSelectTarget(...args) { return this.vimState.emitWillSelectTarget(...args) } // prettier-ignore
  onDidSelectTarget(...args) { return this.vimState.onDidSelectTarget(...args) } // prettier-ignore
  emitDidSelectTarget(...args) { return this.vimState.emitDidSelectTarget(...args) } // prettier-ignore
  onDidFailSelectTarget(...args) { return this.vimState.onDidFailSelectTarget(...args) } // prettier-ignore
  emitDidFailSelectTarget(...args) { return this.vimState.emitDidFailSelectTarget(...args) } // prettier-ignore
  onWillFinishMutation(...args) { return this.vimState.onWillFinishMutation(...args) } // prettier-ignore
  emitWillFinishMutation(...args) { return this.vimState.emitWillFinishMutation(...args) } // prettier-ignore
  onDidFinishMutation(...args) { return this.vimState.onDidFinishMutation(...args) } // prettier-ignore
  emitDidFinishMutation(...args) { return this.vimState.emitDidFinishMutation(...args) } // prettier-ignore
  onDidFinishOperation(...args) { return this.vimState.onDidFinishOperation(...args) } // prettier-ignore
  onDidResetOperationStack(...args) { return this.vimState.onDidResetOperationStack(...args) } // prettier-ignore
  onDidCancelSelectList(...args) { return this.vimState.onDidCancelSelectList(...args) } // prettier-ignore
  subscribe(...args) { return this.vimState.subscribe(...args) } // prettier-ignore
  isMode(...args) { return this.vimState.isMode(...args) } // prettier-ignore
  getBlockwiseSelections(...args) { return this.vimState.getBlockwiseSelections(...args) } // prettier-ignore
  getLastBlockwiseSelection(...args) { return this.vimState.getLastBlockwiseSelection(...args) } // prettier-ignore
  addToClassList(...args) { return this.vimState.addToClassList(...args) } // prettier-ignore
  getConfig(...args) { return this.vimState.getConfig(...args) } // prettier-ignore

  // Wrapper for this.utils
  //===========================================================================
  getVimEofBufferPosition() { return this.utils.getVimEofBufferPosition(this.editor) } // prettier-ignore
  getVimLastBufferRow() { return this.utils.getVimLastBufferRow(this.editor) } // prettier-ignore
  getVimLastScreenRow() { return this.utils.getVimLastScreenRow(this.editor) } // prettier-ignore
  getValidVimBufferRow(row) { return this.utils.getValidVimBufferRow(this.editor, row) } // prettier-ignore
  getValidVimScreenRow(row) { return this.utils.getValidVimScreenRow(this.editor, row) } // prettier-ignore
  getWordBufferRangeAndKindAtBufferPosition(...args) { return this.utils.getWordBufferRangeAndKindAtBufferPosition(this.editor, ...args) } // prettier-ignore
  getFirstCharacterPositionForBufferRow(row) { return this.utils.getFirstCharacterPositionForBufferRow(this.editor, row) } // prettier-ignore
  getBufferRangeForRowRange(rowRange) { return this.utils.getBufferRangeForRowRange(this.editor, rowRange) } // prettier-ignore
  scanForward(...args) { return this.utils.scanEditor(this.editor, "forward", ...args) } // prettier-ignore
  scanBackward(...args) { return this.utils.scanEditor(this.editor, "backward", ...args) } // prettier-ignore
  getFoldStartRowForRow(...args) { return this.utils.getFoldStartRowForRow(this.editor, ...args) } // prettier-ignore
  getFoldEndRowForRow(...args) { return this.utils.getFoldEndRowForRow(this.editor, ...args) } // prettier-ignore
  getBufferRows(...args) { return this.utils.getRows(this.editor, "buffer", ...args) } // prettier-ignore
  getScreenRows(...args) { return this.utils.getRows(this.editor, "screen", ...args) } // prettier-ignore
}
Base.register(false)

module.exports = Base
