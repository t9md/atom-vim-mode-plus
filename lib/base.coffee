fs = require 'fs'
_ = require 'underscore-plus'
Delegato = require 'delegato'
CSON = null
{CompositeDisposable} = require 'atom'
{
  getVimEofBufferPosition
  getVimLastBufferRow
  getVimLastScreenRow
  getWordBufferRangeAndKindAtBufferPosition
  getFirstCharacterPositionForBufferRow
  getBufferRangeForRowRange
  getIndentLevelForBufferRow
  scanEditorInDirection
} = require './utils'
swrap = require './selection-wrapper'
settings = require './settings'

[
  Input
  selectList
  getEditorState  # set by Base.init()
  LOADING_FILE
] = []
LazyLoadedLibs = {}
commandTablePath = __dirname + "/command-table.coffee"

requireFile = (filename) ->
  LOADING_FILE = filename
  console.log 'loading', LOADING_FILE
  required = require(filename)
  LOADING_FILE = null
  required

{OperationAbortedError} = require './errors'

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
  @commandTablePath: commandTablePath

  Delegato.includeInto(this)
  @delegatesMethods(vimStateMethods..., toProperty: 'vimState')
  @delegatesProperty('mode', 'submode', toProperty: 'vimState')

  constructor: (@vimState, properties=null) ->
    {@editor, @editorElement, @globalState} = @vimState
    @name = @constructor.name
    _.extend(this, properties) if properties?

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
    getVimEofBufferPosition(@editor)

  getVimLastBufferRow: ->
    getVimLastBufferRow(@editor)

  getVimLastScreenRow: ->
    getVimLastScreenRow(@editor)

  getWordBufferRangeAndKindAtBufferPosition: (point, options) ->
    getWordBufferRangeAndKindAtBufferPosition(@editor, point, options)

  getFirstCharacterPositionForBufferRow: (row) ->
    getFirstCharacterPositionForBufferRow(@editor, row)

  getBufferRangeForRowRange: (rowRange) ->
    getBufferRangeForRowRange(@editor, rowRange)

  getIndentLevelForBufferRow: (row) ->
    getIndentLevelForBufferRow(@editor, row)

  scanForward: (args...) ->
    scanEditorInDirection(@editor, 'forward', args...)

  scanBackward: (args...) ->
    scanEditorInDirection(@editor, 'backward', args...)

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
    swrap(selection).getBufferPositionFor('head', from: ['property', 'selection'])

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
  @registerCommandFromTable: (table) ->
    subscriptions = new CompositeDisposable()
    for name, spec of table when spec.commandName?
      subscriptions.add(@registerCommandFromSpec(name, spec))
    subscriptions

  @writeCommandTableOnDisk: ->
    commandTable = @generateCommandTableByEagerLoad()
    if _.isEqual(@commandTable, commandTable)
      atom.notifications.addInfo("No change commandTable", dismissable: true)
      return

    CSON ?= require 'season'
    loadableCSONText = "module.exports =\n" + CSON.stringify(commandTable) + "\n"
    commandTablePath = @commandTablePath
    # commandTablePath = "/tmp/command-table.coffee"
    atom.workspace.open(commandTablePath, activateItem: false).then (editor) ->
      editor.setText(loadableCSONText)
      editor.save()
      editor.destroy()
      atom.notifications.addInfo("Updated commandTable", dismissable: true)

  @generateCommandTableByEagerLoad: ->
    # NOTE: changing order affects output of lib/command-table.coffee
    filesToLoad = [
      './operator', './operator-insert', './operator-transform-string',
      './motion', './motion-search', './text-object', './misc-command'
    ]
    filesToLoad.forEach(requireFile)
    klasses = _.values(@getRegistries())
    klassesGroupedByFile = _.groupBy(klasses, (klass) -> klass.__vmpFilename)

    commandTable = {}
    for file in filesToLoad
      for klass in klassesGroupedByFile[file]
        commandTable[klass.name] = klass.getSpec()
    commandTable

  @commandTable: null
  @init: (service) ->
    {getEditorState} = service
    @commandTable = require(@commandTablePath)
    return @registerCommandFromTable(@commandTable)

  registries = {Base}
  @extend: (@command=true) ->
    @__vmpFilename = LOADING_FILE
    if @name of registries
      throw new Error("Duplicate constructor #{@name}")
    registries[@name] = this

  @getSpec: ->
    if @isCommand()
      file: @__vmpFilename
      commandName: @getCommandName()
      commandScope: @getCommandScope()
    else
      file: @__vmpFilename

  @getClass: (name) ->
    if (klass = registries[name])?
      return klass

    if spec = @commandTable[name]
      if atom.inDevMode()
        console.log "lazy-require file: #{spec.file} for #{name}"
      LazyLoadedLibs[spec.file] ?= requireFile(spec.file)
      klass = registries[name]
      return klass if klass?

    throw new Error("class '#{name}' not found")

  @getRegistries: ->
    registries

  @isCommand: ->
    @command

  @commandPrefix: 'vim-mode-plus'
  @getCommandName: ->
    @commandPrefix + ':' + _.dasherize(@name)

  @getCommandNameWithoutPrefix: ->
    _.dasherize(@name)

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
    commandName = (commandPrefix ? 'vim-mode-plus') + ':' + _.dasherize(name)
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
    name = _.capitalize(_.camelize(command))
    if name of registries
      registries[name].operationKind

module.exports = Base
