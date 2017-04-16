_ = require 'underscore-plus'
Delegato = require 'delegato'
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

Input = null
selectList = null
getEditorState = null # set by Base.init()
CSON = null

serializeCommandTable = (specByKlass) ->
  CSON ?= require 'season'
  data = CSON.stringify(specByKlass)
  CommandTablePath = require.resolve('./command-table.cson')
  atom.workspace.open(CommandTablePath).then (editor) ->
    editor.setText(data)

{OperationAbortedError} = require './errors'

vimStateMethods = [
  "onDidChangeSearch"
  "onDidConfirmSearch"
  "onDidCancelSearch"
  "onDidCommandSearch"

  # Life cycle
  "onDidSetTarget"
  "emitDidSetTarget"
      "onWillSelectTarget"
      "emitWillSelectTarget"
      "onDidSelectTarget"
      "emitDidSelectTarget"

      "onDidFailSelectTarget"
      "emitDidFailSelectTarget"

    "onWillFinishMutation"
    "emitWillFinishMutation"
    "onDidFinishMutation"
    "emitDidFinishMutation"
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
    @instanceof('Operator')

  isMotion: ->
    @instanceof('Motion')

  isTextObject: ->
    @instanceof('TextObject')

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
  @init: (service, commandTable) ->
    {getEditorState} = service

    registerCommandFromSpec = (spec) ->
      {name, commandScope, commandName} = spec
      atom.commands.add commandScope, commandName, (event) ->
        vimState = getEditorState(@getModel()) ? getEditorState(atom.workspace.getActiveTextEditor())
        if vimState? # Possibly undefined See #85
          vimState.operationStack.run(name)
        event.stopPropagation()

    @subscriptions = new CompositeDisposable()

    @commandTable = require('./command-table')
    # @commandTable = null

    if @commandTable?
      console.log 'lazy strategy'
      for name, spec of @commandTable when spec.isCommand
        @subscriptions.add(registerCommandFromSpec(spec))
      @subscriptions
    else
      console.log 'non lazy strategy'
      files = [
        './operator', './operator-insert', './operator-transform-string',
        './motion', './motion-search', './text-object', './misc-command'
      ]
      @commandTable = {}
      filenameByKlass = {}
      for file in files
        beforeRequire = _.keys(@getRegistries())
        # console.time(file)
        require(file)
        # console.timeEnd(file)
        afterRequire = _.keys(@getRegistries())
        addedKlass = _.difference(afterRequire, beforeRequire)
        for klass in addedKlass
          filenameByKlass[klass] = file

      for __, klass of @getRegistries()# when klass.isCommand()
        @commandTable[klass.name] = spec = {
          name: klass.name
          file: filenameByKlass[klass.name]
          commandName: klass.getCommandName()
          isCommand: klass.isCommand()
          commandScope: klass.getCommandScope()
        }

      # serializeCommandTable(@commandTable)
      for name, spec of @commandTable when spec.isCommand
        @subscriptions.add(registerCommandFromSpec(spec))
      @subscriptions

  registries = {Base}
  @extend: (@command=true) ->
    if (@name of registries) and (not @suppressWarning)
      console.warn("Duplicate constructor #{@name}")
    registries[@name] = this

  @getClass: (name) ->
    if (klass = registries[name])?
      return klass

    if spec = @commandTable[name]
      require(spec.file)
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

  # For demo-mode pkg integration
  @operationKind: null
  @getKindForCommandName: (command) ->
    name = _.capitalize(_.camelize(command))
    if name of registries
      registries[name].operationKind

module.exports = Base
