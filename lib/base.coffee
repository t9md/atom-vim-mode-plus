# To avoid loading underscore-plus and depending underscore on startup
__plus = null
_plus = ->
  __plus ?= require 'underscore-plus'

Delegato = require 'delegato'
settings = require './settings'

[
  CSON
  path
  Input
  selectList
  getEditorState  # set by Base.init()
] = [] # set null

VMP_LOADING_FILE = null
VMP_LOADED_FILES = []

loadVmpOperationFile = (filename) ->
  VMP_LOADING_FILE = filename
  loaded = require(filename)
  VMP_LOADING_FILE = null
  VMP_LOADED_FILES.push(filename)
  loaded

OperationAbortedError = null

vimStateMethods = [
  "onDidChangeSearch"
  "onDidConfirmSearch"
  "onDidCancelSearch"
  "onDidCommandSearch"

  # Life cycle of operationStack
  "onDidSetTarget", "emitDidSetTarget"
    "onWillSelectTarget", "emitWillSelectTarget"
    "onDidSelectTarget", "emitDidSelectTarget"
    "onDidFailSelectTarget", "emitDidFailSelectTarget"

    "onWillFinishMutation", "emitWillFinishMutation"
    "onDidFinishMutation", "emitDidFinishMutation"
  "onDidFinishOperation"
  "onDidResetOperationStack"

  "onDidSetOperatorModifier"

  "onWillActivateMode"
  "onDidActivateMode"
  "preemptWillDeactivateMode"
  "onWillDeactivateMode"
  "onDidDeactivateMode"

  "onDidCancelSelectList"
  "subscribe"
  "isMode"
  "getBlockwiseSelections"
  "getLastBlockwiseSelection"
  "addToClassList"
  "getConfig"
]

class Base
  Delegato.includeInto(this)
  @delegatesMethods(vimStateMethods..., toProperty: 'vimState')
  @delegatesProperty('mode', 'submode', 'swrap', 'utils', toProperty: 'vimState')

  constructor: (@vimState, properties=null) ->
    {@editor, @editorElement, @globalState, @swrap} = @vimState
    @name = @constructor.name
    Object.assign(this, properties) if properties?

  # To override
  initialize: ->

  # Operation processor execute only when isComplete() return true.
  # If false, operation processor postpone its execution.
  isComplete: ->
    if @requireInput and not @input?
      false
    else if @requireTarget
      # When this function is called in Base::constructor
      # tagert is still string like `MoveToRight`, in this case isComplete
      # is not available.
      @target?.isComplete?()
    else
      true

  requireTarget: false
  requireInput: false
  recordable: false
  repeated: false
  target: null # Set in Operator
  operator: null # Set in operator's target( Motion or TextObject )
  isAsTargetExceptSelect: ->
    @operator? and not @operator.instanceof('Select')

  abort: ->
    OperationAbortedError ?= require './errors'
    throw new OperationAbortedError('aborted')

  # Count
  # -------------------------
  count: null
  defaultCount: 1
  getCount: (offset=0) ->
    @count ?= @vimState.getCount() ? @defaultCount
    @count + offset

  resetCount: ->
    @count = null

  isDefaultCount: ->
    @count is @defaultCount

  # Misc
  # -------------------------
  countTimes: (last, fn) ->
    return if last < 1

    stopped = false
    stop = -> stopped = true
    for count in [1..last]
      isFinal = count is last
      fn({count, isFinal, stop})
      break if stopped

  activateMode: (mode, submode) ->
    @onDidFinishOperation =>
      @vimState.activate(mode, submode)

  activateModeIfNecessary: (mode, submode) ->
    unless @vimState.isMode(mode, submode)
      @activateMode(mode, submode)

  new: (name, properties) ->
    klass = Base.getClass(name)
    new klass(@vimState, properties)

  newInputUI: ->
    Input ?= require './input'
    new Input(@vimState)

  # FIXME: This is used to clone Motion::Search to support `n` and `N`
  # But manual reseting and overriding property is bug prone.
  # Should extract as search spec object and use it by
  # creating clean instance of Search.
  clone: (vimState) ->
    properties = {}
    excludeProperties = ['editor', 'editorElement', 'globalState', 'vimState', 'operator']
    for own key, value of this when key not in excludeProperties
      properties[key] = value
    klass = this.constructor
    new klass(vimState, properties)

  cancelOperation: ->
    @vimState.operationStack.cancel()

  processOperation: ->
    @vimState.operationStack.process()

  focusSelectList: (options={}) ->
    @onDidCancelSelectList =>
      @cancelOperation()
    selectList ?= require './select-list'
    selectList.show(@vimState, options)

  input: null
  focusInput: (options) ->
    inputUI = @newInputUI()
    inputUI.onDidConfirm (input) =>
      @input = input
      @processOperation()

    if options?.charsMax > 1
      inputUI.onDidChange (input) =>
        @vimState.hover.set(input)

    inputUI.onDidCancel(@cancelOperation.bind(this))
    inputUI.focus(options)

  getVimEofBufferPosition: ->
    @utils.getVimEofBufferPosition(@editor)

  getVimLastBufferRow: ->
    @utils.getVimLastBufferRow(@editor)

  getVimLastScreenRow: ->
    @utils.getVimLastScreenRow(@editor)

  getWordBufferRangeAndKindAtBufferPosition: (point, options) ->
    @utils.getWordBufferRangeAndKindAtBufferPosition(@editor, point, options)

  getFirstCharacterPositionForBufferRow: (row) ->
    @utils.getFirstCharacterPositionForBufferRow(@editor, row)

  getBufferRangeForRowRange: (rowRange) ->
    @utils.getBufferRangeForRowRange(@editor, rowRange)

  getIndentLevelForBufferRow: (row) ->
    @utils.getIndentLevelForBufferRow(@editor, row)

  scanForward: (args...) ->
    @utils.scanEditorInDirection(@editor, 'forward', args...)

  scanBackward: (args...) ->
    @utils.scanEditorInDirection(@editor, 'backward', args...)

  getFoldEndRowForRow: (args...) ->
    @utils.getFoldEndRowForRow(@editor, args...)

  instanceof: (klassName) ->
    this instanceof Base.getClass(klassName)

  is: (klassName) ->
    this.constructor is Base.getClass(klassName)

  isOperator: ->
    @constructor.operationKind is 'operator'

  isMotion: ->
    @constructor.operationKind is 'motion'

  isTextObject: ->
    @constructor.operationKind is 'text-object'

  getCursorBufferPosition: ->
    if @mode is 'visual'
      @getCursorPositionForSelection(@editor.getLastSelection())
    else
      @editor.getCursorBufferPosition()

  getCursorBufferPositions: ->
    if @mode is 'visual'
      @editor.getSelections().map(@getCursorPositionForSelection.bind(this))
    else
      @editor.getCursorBufferPositions()

  getBufferPositionForCursor: (cursor) ->
    if @mode is 'visual'
      @getCursorPositionForSelection(cursor.selection)
    else
      cursor.getBufferPosition()

  getCursorPositionForSelection: (selection) ->
    @swrap(selection).getBufferPositionFor('head', from: ['property', 'selection'])

  toString: ->
    str = @name
    if @target?
      str += ", target=#{@target.name}, target.wise=#{@target.wise} "
    else if @operator?
      str += ", wise=#{@wise} , operator=#{@operator.name}"
    else
      str

  # Class methods
  # -------------------------
  @writeCommandTableOnDisk: ->
    commandTable = @generateCommandTableByEagerLoad()
    _ = _plus()
    if _.isEqual(@commandTable, commandTable)
      atom.notifications.addInfo("No change commandTable", dismissable: true)
      return

    CSON ?= require 'season'
    path ?= require('path')

    loadableCSONText = """
      # This file is auto generated by `vim-mode-plus:write-command-table-on-disk` command.
      # DONT edit manually.
      module.exports =
      #{CSON.stringify(commandTable)}\n
      """
    commandTablePath = path.join(__dirname, "command-table.coffee")
    atom.workspace.open(commandTablePath).then (editor) ->
      editor.setText(loadableCSONText)
      editor.save()
      atom.notifications.addInfo("Updated commandTable", dismissable: true)

  @generateCommandTableByEagerLoad: ->
    # NOTE: changing order affects output of lib/command-table.coffee
    filesToLoad = [
      './operator', './operator-insert', './operator-transform-string',
      './motion', './motion-search', './text-object', './misc-command'
    ]
    filesToLoad.forEach(loadVmpOperationFile)
    _ = _plus()
    klasses = _.values(@getClassRegistry())
    klassesGroupedByFile = _.groupBy(klasses, (klass) -> klass.VMP_LOADING_FILE)

    commandTable = {}
    for file in filesToLoad
      for klass in klassesGroupedByFile[file]
        commandTable[klass.name] = klass.getSpec()
    commandTable

  @commandTable: null
  @init: (_getEditorState) ->
    getEditorState = _getEditorState
    @commandTable = require('./command-table')
    subscriptions = []
    for name, spec of @commandTable when spec.commandName?
      subscriptions.push(@registerCommandFromSpec(name, spec))
    return subscriptions

  classRegistry = {Base}
  @extend: (@command=true) ->
    @VMP_LOADING_FILE = VMP_LOADING_FILE
    if @name of classRegistry
      console.warn("Duplicate constructor #{@name}")
    classRegistry[@name] = this

  @getSpec: ->
    if @isCommand()
      file: @VMP_LOADING_FILE
      commandName: @getCommandName()
      commandScope: @getCommandScope()
    else
      file: @VMP_LOADING_FILE

  @getClass: (name) ->
    return klass if (klass = classRegistry[name])

    fileToLoad = @commandTable[name].file
    if fileToLoad not in VMP_LOADED_FILES
      if atom.inDevMode() and settings.get('debug')
        console.log "lazy-require: #{fileToLoad} for #{name}"
      loadVmpOperationFile(fileToLoad)
      return klass if (klass = classRegistry[name])

    throw new Error("class '#{name}' not found")

  @getClassRegistry: ->
    classRegistry

  @isCommand: ->
    @command

  @commandPrefix: 'vim-mode-plus'
  @getCommandName: ->
    @commandPrefix + ':' + _plus().dasherize(@name)

  @getCommandNameWithoutPrefix: ->
    _plus().dasherize(@name)

  @commandScope: 'atom-text-editor'
  @getCommandScope: ->
    @commandScope

  @getDesctiption: ->
    if @hasOwnProperty("description")
      @description
    else
      null

  @registerCommand: ->
    klass = this
    atom.commands.add @getCommandScope(), @getCommandName(), (event) ->
      vimState = getEditorState(@getModel()) ? getEditorState(atom.workspace.getActiveTextEditor())
      if vimState? # Possibly undefined See #85
        vimState.operationStack.run(klass)
      event.stopPropagation()

  @registerCommandFromSpec: (name, spec) ->
    {commandScope, commandPrefix, commandName, getClass} = spec
    commandScope ?= 'atom-text-editor'
    commandName ?= (commandPrefix ? 'vim-mode-plus') + ':' + _plus().dasherize(name)
    atom.commands.add commandScope, commandName, (event) ->
      vimState = getEditorState(@getModel()) ? getEditorState(atom.workspace.getActiveTextEditor())
      if vimState? # Possibly undefined See #85
        if getClass?
          vimState.operationStack.run(getClass(name))
        else
          vimState.operationStack.run(name)
      event.stopPropagation()

  # For demo-mode pkg integration
  @operationKind: null
  @getKindForCommandName: (command) ->
    _ = _plus()
    name = _.capitalize(_.camelize(command))
    if name of classRegistry
      classRegistry[name].operationKind

module.exports = Base
