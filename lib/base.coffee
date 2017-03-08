_ = require 'underscore-plus'
Delegato = require 'delegato'
{CompositeDisposable} = require 'atom'
{
  getVimEofBufferPosition
  getVimLastBufferRow
  getVimLastScreenRow
  getWordBufferRangeAndKindAtBufferPosition
  getFirstCharacterPositionForBufferRow
  scanEditorInDirection
} = require './utils'
swrap = require './selection-wrapper'
Input = require './input'
selectList = null
getEditorState = null # set by Base.init()
{OperationAbortedError} = require './errors'

vimStateMethods = [
  "assert"
  "assertWithException"
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

      "onDidRestoreCursorPositions"
      "emitDidRestoreCursorPositions"
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

  constructor: (@vimState, properties=null) ->
    {@editor, @editorElement, @globalState} = @vimState
    _.extend(this, properties) if properties?

  # To override
  initialize: ->

  # Operation processor execute only when isComplete() return true.
  # If false, operation processor postpone its execution.
  isComplete: ->
    if @isRequireInput() and not @hasInput()
      false
    else if @isRequireTarget()
      # When this function is called in Base::constructor
      # tagert is still string like `MoveToRight`, in this case isComplete
      # is not available.
      @getTarget()?.isComplete?()
    else
      true

  target: null
  hasTarget: -> @target?
  getTarget: -> @target

  requireTarget: false
  isRequireTarget: -> @requireTarget

  requireInput: false
  isRequireInput: -> @requireInput

  recordable: false
  isRecordable: -> @recordable

  repeated: false
  isRepeated: -> @repeated
  setRepeated: -> @repeated = true

  # Intended to be used by TextObject or Motion
  operator: null
  getOperator: -> @operator
  setOperator: (@operator) -> @operator
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
  hasInput: -> @input?
  getInput: -> @input

  focusInput: (charsMax) ->
    inputUI = @newInputUI()
    inputUI.onDidConfirm (@input) =>
      @processOperation()

    if charsMax > 1
      inputUI.onDidChange (input) =>
        @vimState.hover.set(input)

    inputUI.onDidCancel(@cancelOperation.bind(this))
    inputUI.focus(charsMax)

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

  getName: ->
    @constructor.name

  getCursorBufferPosition: ->
    if @isMode('visual')
      @getCursorPositionForSelection(@editor.getLastSelection())
    else
      @editor.getCursorBufferPosition()

  getCursorBufferPositions: ->
    if @isMode('visual')
      @editor.getSelections().map(@getCursorPositionForSelection.bind(this))
    else
      @editor.getCursorBufferPositions()

  getBufferPositionForCursor: (cursor) ->
    if @isMode('visual')
      @getCursorPositionForSelection(cursor.selection)
    else
      cursor.getBufferPosition()

  getCursorPositionForSelection: (selection) ->
    swrap(selection).getBufferPositionFor('head', from: ['property', 'selection'])

  toString: ->
    str = @getName()
    str += ", target=#{@getTarget().toString()}" if @hasTarget()
    str

  # Class methods
  # -------------------------
  @init: (service) ->
    {getEditorState} = service
    @subscriptions = new CompositeDisposable()

    [
      './operator', './operator-insert', './operator-transform-string',
      './motion', './motion-search',
      './text-object',
      './insert-mode', './misc-command'
    ].forEach(require)

    for __, klass of @getRegistries() when klass.isCommand()
      @subscriptions.add(klass.registerCommand())
    @subscriptions

  # For development easiness without reloading vim-mode-plus
  @reset: ->
    @subscriptions.dispose()
    @subscriptions = new CompositeDisposable()
    for __, klass of @getRegistries() when klass.isCommand()
      @subscriptions.add(klass.registerCommand())

  registries = {Base}
  @extend: (@command=true) ->
    if (@name of registries) and (not @suppressWarning)
      console.warn("Duplicate constructor #{@name}")
    registries[@name] = this

  @getClass: (name) ->
    if (klass = registries[name])?
      klass
    else
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
        vimState._event = event
        vimState.operationStack.run(klass)
      event.stopPropagation()

module.exports = Base
