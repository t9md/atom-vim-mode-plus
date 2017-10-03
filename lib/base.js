"use babel"

const settings = require("./settings")

let CSON, path, selectList, OperationAbortedError, __plus
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
  static operationKind = null // For demo-mode pkg integration
  static getEditorState = null // set through init()

  requireTarget = false
  requireInput = false
  recordable = false
  repeated = false
  target = null // Set in Operator
  operator = null

  // Count
  // -------------------------
  count = null
  defaultCount = 1
  input = null

  constructor(vimState, properties) {
    this.vimState = vimState
    this.name = this.constructor.name

    if (properties) {
      if (this.getConfig("debug")) {
        console.warn(properties)
      }
      // throw new Error("don't pass 2nd args to Base constructor")
      Object.assign(this, properties)
    }
  }

  // To override
  initialize() {
    return this
  }

  // Called both on cancel and success
  resetState() {}

  // Operation processor execute only when isComplete() return true.
  // If false, operation processor postpone its execution.
  isComplete() {
    if (this.requireInput && this.input == null) {
      return false
    } else if (this.requireTarget) {
      // When this function is called in Base::constructor
      // tagert is still string like `MoveToRight`, in this case isComplete
      // is not available.
      return !!this.target && this.target.isComplete()
    } else {
      return true // Set in operator's target( Motion or TextObject )
    }
  }

  isAsTargetExceptSelectInVisualMode() {
    return this.operator != null && !this.operator.instanceof("SelectInVisualMode")
  }

  abort() {
    if (!OperationAbortedError) OperationAbortedError = require("./errors")
    throw new OperationAbortedError("aborted")
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

  isDefaultCount() {
    return this.count === this.defaultCount
  }

  // Misc
  // -------------------------
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

  // Currently used in repeat-search and repeat-find("n", "N", ";", ",").
  bindVimState(vimState) {
    this.vimState = vimState
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
    if (!options.onCancel) {
      options.onCancel = () => this.cancelOperation()
    }
    if (!options.onChange) {
      options.onChange = input => this.vimState.hover.set(input)
    }
    this.vimState.focusInput(options)
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

  getVimEofBufferPosition() {
    return this.utils.getVimEofBufferPosition(this.editor)
  }

  getVimLastBufferRow() {
    return this.utils.getVimLastBufferRow(this.editor)
  }

  getVimLastScreenRow() {
    return this.utils.getVimLastScreenRow(this.editor)
  }

  getWordBufferRangeAndKindAtBufferPosition(point, options) {
    return this.utils.getWordBufferRangeAndKindAtBufferPosition(this.editor, point, options)
  }

  getFirstCharacterPositionForBufferRow(row) {
    return this.utils.getFirstCharacterPositionForBufferRow(this.editor, row)
  }

  getBufferRangeForRowRange(rowRange) {
    return this.utils.getBufferRangeForRowRange(this.editor, rowRange)
  }

  getIndentLevelForBufferRow(row) {
    return this.utils.getIndentLevelForBufferRow(this.editor, row)
  }

  scanForward(...args) {
    return this.utils.scanEditorInDirection(this.editor, "forward", ...args)
  }

  scanBackward(...args) {
    return this.utils.scanEditorInDirection(this.editor, "backward", ...args)
  }

  getFoldEndRowForRow(...args) {
    return this.utils.getFoldEndRowForRow(this.editor, ...args)
  }

  instanceof(klassName) {
    return this instanceof Base.getClass(klassName)
  }

  is(klassName) {
    return this.constructor === Base.getClass(klassName)
  }

  isOperator() {
    return this.constructor.operationKind === "operator"
  }

  isMotion() {
    return this.constructor.operationKind === "motion"
  }

  isTextObject() {
    return this.constructor.operationKind === "text-object"
  }

  getCursorBufferPosition() {
    return this.mode === "visual"
      ? this.getCursorPositionForSelection(this.editor.getLastSelection())
      : this.editor.getCursorBufferPosition()
  }

  getCursorBufferPositions() {
    return this.mode === "visual"
      ? this.editor.getSelections().map(this.getCursorPositionForSelection.bind(this))
      : this.editor.getCursorBufferPositions()
  }

  getBufferPositionForCursor(cursor) {
    return this.mode === "visual" ? this.getCursorPositionForSelection(cursor.selection) : cursor.getBufferPosition()
  }

  getCursorPositionForSelection(selection) {
    return this.swrap(selection).getBufferPositionFor("head", {from: ["property", "selection"]})
  }

  toString() {
    if (this.target) {
      return `${this.name}, target=${this.target.name}, target.wise=${this.target.wise} `
    } else if (this.operator) {
      return `${this.name}, wise=${this.wise} , operator=${this.operator.name}`
    } else {
      return this.name
    }
  }

  getCommandName() {
    return this.constructor.getCommandName()
  }

  getCommandNameWithoutPrefix() {
    return this.constructor.getCommandNameWithoutPrefix()
  }

  // Class methods
  // -------------------------

  static writeCommandTableOnDisk() {
    const commandTable = this.generateCommandTableByEagerLoad()
    const _ = _plus()
    if (_.isEqual(this.commandTable, commandTable)) {
      atom.notifications.addInfo("No changes in commandTable", {dismissable: true})
      return
    }

    if (!CSON) CSON = require("season")
    if (!path) path = require("path")

    let loadableCSONText = "# This file is auto generated by `vim-mode-plus:write-command-table-on-disk` command.\n"
    loadableCSONText += "# DONT edit manually.\n"
    loadableCSONText += CSON.stringify(commandTable) + "\n"

    const commandTablePath = path.join(__dirname, "command-table.coffee")
    atom.workspace.open(commandTablePath).then(editor => {
      editor.setText(loadableCSONText)
      editor.save()
      atom.notifications.addInfo("Updated commandTable", {dismissable: true})
    })
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
        commandTable[klass.name] = klass.isCommand()
          ? {file: klass.file, commandName: klass.getCommandName(), commandScope: klass.getCommandScope()}
          : {file: klass.file}
      }
    }
    return commandTable
  }

  static init(getEditorState) {
    this.getEditorState = getEditorState

    this.commandTable = require("./command-table")
    const subscriptions = []
    for (const name in this.commandTable) {
      const spec = this.commandTable[name]
      if (spec.commandName) {
        subscriptions.push(this.registerCommandFromSpec(name, spec))
      }
    }
    return subscriptions
  }

  static initClass(command = true) {
    this.command = command
    this.file = VMP_LOADING_FILE
    if (this.name in CLASS_REGISTRY) {
      console.warn(`Duplicate constructor ${this.name}`)
    }
    CLASS_REGISTRY[this.name] = this
  }

  static extend(...args) {
    console.error("calling deprecated Base.extend(), use Base.initClass instead!")
    this.initClass(...args)
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

  static getInstance(vimState, klassOrName, properties) {
    const klass = typeof klassOrName === "function" ? klassOrName : Base.getClass(klassOrName)
    const instance = new klass(vimState)
    if (properties) {
      console.log(properties.target);
      Object.assign(instance, properties)
    }
    return instance.initialize() // initialize must return instance.
  }

  static getClassRegistry() {
    return CLASS_REGISTRY
  }

  static isCommand() {
    return this.command
  }

  static getCommandName() {
    return this.commandPrefix + ":" + _plus().dasherize(this.name)
  }

  static getCommandNameWithoutPrefix() {
    return _plus().dasherize(this.name)
  }

  static getCommandScope() {
    return this.commandScope
  }

  static registerCommand() {
    const klass = this
    const getEditorState = this.getEditorState

    return atom.commands.add(this.getCommandScope(), this.getCommandName(), function(event) {
      const vimState = getEditorState(this.getModel()) || getEditorState(atom.workspace.getActiveTextEditor())
      if (vimState) vimState.operationStack.run(klass) // Possibly undefined See #85
      event.stopPropagation()
    })
  }

  static registerCommandFromSpec(name, spec) {
    let {commandScope = "atom-text-editor", commandPrefix = "vim-mode-plus", commandName, getClass} = spec
    if (!commandName) commandName = commandPrefix + ":" + _plus().dasherize(name)

    const getEditorState = this.getEditorState
    return atom.commands.add(commandScope, commandName, function(event) {
      const vimState = getEditorState(this.getModel()) || getEditorState(atom.workspace.getActiveTextEditor())
      if (vimState) vimState.operationStack.run((getClass && getClass(name)) || name) // Possibly undefined See #85
      event.stopPropagation()
    })
  }

  static getKindForCommandName(command) {
    const commandWithoutPrefix = command.replace(/^vim-mode-plus:/, "")
    const commandClassName = _plus().capitalize(_plus().camelize(commandWithoutPrefix))
    if (commandClassName in CLASS_REGISTRY) {
      return CLASS_REGISTRY[commandClassName].operationKind
    }
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
  onDidSetOperatorModifier(...args) { return this.vimState.onDidSetOperatorModifier(...args) } // prettier-ignore
  onWillActivateMode(...args) { return this.vimState.onWillActivateMode(...args) } // prettier-ignore
  onDidActivateMode(...args) { return this.vimState.onDidActivateMode(...args) } // prettier-ignore
  preemptWillDeactivateMode(...args) { return this.vimState.preemptWillDeactivateMode(...args) } // prettier-ignore
  onWillDeactivateMode(...args) { return this.vimState.onWillDeactivateMode(...args) } // prettier-ignore
  onDidDeactivateMode(...args) { return this.vimState.onDidDeactivateMode(...args) } // prettier-ignore
  onDidCancelSelectList(...args) { return this.vimState.onDidCancelSelectList(...args) } // prettier-ignore
  subscribe(...args) { return this.vimState.subscribe(...args) } // prettier-ignore
  isMode(...args) { return this.vimState.isMode(...args) } // prettier-ignore
  getBlockwiseSelections(...args) { return this.vimState.getBlockwiseSelections(...args) } // prettier-ignore
  getLastBlockwiseSelection(...args) { return this.vimState.getLastBlockwiseSelection(...args) } // prettier-ignore
  addToClassList(...args) { return this.vimState.addToClassList(...args) } // prettier-ignore
  getConfig(...args) { return this.vimState.getConfig(...args) } // prettier-ignore
}
Base.initClass(false)

module.exports = Base
