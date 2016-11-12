_ = require 'underscore-plus'
Delegato = require 'delegato'
{CompositeDisposable} = require 'atom'
{
  getVimEofBufferPosition
  getVimLastBufferRow
  getVimLastScreenRow
  getWordBufferRangeAndKindAtBufferPosition
} = require './utils'
swrap = require './selection-wrapper'

settings = require './settings'
selectList = null
getEditorState = null # set by Base.init()
{OperationAbortedError} = require './errors'

vimStateMethods = [
  "onDidChangeInput"
  "onDidConfirmInput"
  "onDidCancelInput"

  "onDidChangeSearch"
  "onDidConfirmSearch"
  "onDidCancelSearch"
  "onDidCommandSearch"

  "onDidSetTarget"
  "onWillSelectTarget"
  "onDidSelectTarget"
  "preemptWillSelectTarget"
  "preemptDidSelectTarget"
  "onDidRestoreCursorPositions"
  "onDidSetOperatorModifier"
  "onDidResetOperationStack"

  "onWillActivateMode"
  "onDidActivateMode"
  "onWillDeactivateMode"
  "preemptWillDeactivateMode"
  "onDidDeactivateMode"

  "onDidFinishOperation"

  "onDidCancelSelectList"
  "subscribe"
  "isMode"
  "getBlockwiseSelections"
  "updateSelectionProperties"
  "addToClassList"
]

class Base
  Delegato.includeInto(this)
  @delegatesMethods(vimStateMethods..., toProperty: 'vimState')

  constructor: (@vimState, properties=null) ->
    {@editor, @editorElement, @globalState} = @vimState
    _.extend(this, properties) if properties?
    if settings.get('showHoverOnOperate')
      hover = @hover?[settings.get('showHoverOnOperateIcon')]
      if hover? and not @isComplete()
        @addHover(hover)

  # Template
  initialize: ->

  # Operation processor execute only when isComplete() return true.
  # If false, operation processor postpone its execution.
  isComplete: ->
    if (@isRequireInput() and not @hasInput())
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
  hasOperator: -> @operator?
  getOperator: -> @operator
  setOperator: (@operator) -> @operator
  isAsOperatorTarget: ->
    @hasOperator() and not @getOperator().instanceof('Select')

  abort: ->
    throw new OperationAbortedError('aborted')

  # Count
  # -------------------------
  count: null
  defaultCount: 1
  getCount: ->
    @count ?= @vimState.getCount() ? @defaultCount

  resetCount: ->
    @count = null

  isDefaultCount: ->
    @count is @defaultCount

  # Register
  # -------------------------
  register: null
  getRegisterName: ->
    @vimState.register.getName()
    text = @vimState.register.getText(@getInput(), selection)

  getRegisterValueAsText: (name=null, selection) ->
    @vimState.register.getText(name, selection)

  isDefaultRegisterName: ->
    @vimState.register.isDefaultName()

  # Misc
  # -------------------------
  countTimes: (fn) ->
    return if (last = @getCount()) < 1

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

  addHover: (text, {replace}={}, point=null) ->
    if replace ? false
      @vimState.hover.replaceLastSection(text, point)
    else
      @vimState.hover.add(text, point)

  new: (name, properties) ->
    klass = Base.getClass(name)
    new klass(@vimState, properties)

  clone: (vimState) ->
    properties = {}
    excludeProperties = ['editor', 'editorElement', 'globalState', 'vimState']
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
    @onDidConfirmInput (input) =>
      # [FIXME REALLY] when both operator and motion take user-input,
      # Currently input UI is unappropreately shared by operator and motion.
      # So without this guard, @input is overwritten by later input.
      unless @input?
        @input = input
        @processOperation()

    # From 2nd addHover, we replace last section of hover
    # to sync content with input mini editor.
    unless charsMax is 1
      replace = false
      @onDidChangeInput (input) =>
        @addHover(input, {replace})
        replace = true

    @onDidCancelInput =>
      @cancelOperation()

    @vimState.input.focus(charsMax)

  getVimEofBufferPosition: ->
    getVimEofBufferPosition(@editor)

  getVimLastBufferRow: ->
    getVimLastBufferRow(@editor)

  getVimLastScreenRow: ->
    getVimLastScreenRow(@editor)

  getWordBufferRangeAndKindAtBufferPosition: (point, options) ->
    getWordBufferRangeAndKindAtBufferPosition(@editor, point, options)

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

  isTarget: ->
    @isMotion() or @isTextObject()

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
    options = {fromProperty: true, allowFallback: true}
    swrap(selection).getBufferPositionFor('head', options)

  toString: ->
    str = @getName()
    str += ", target=#{@getTarget().toString()}" if @hasTarget()
    str

  emitWillSelectTarget: ->
    @vimState.emitter.emit('will-select-target')

  emitDidSelectTarget: ->
    @vimState.emitter.emit('did-select-target')

  emitDidSetTarget: (operator) ->
    @vimState.emitter.emit('did-set-target', operator)

  emitDidRestoreCursorPositions: ->
    @vimState.emitter.emit('did-restore-cursor-positions')

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
    if (name of registries) and (not @suppressWarning)
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
      if vimState?
        # Reason: https://github.com/t9md/atom-vim-mode-plus/issues/85
        vimState.operationStack.run(klass)
      event.stopPropagation()

module.exports = Base
