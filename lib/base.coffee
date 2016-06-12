_ = require 'underscore-plus'
Delegato = require 'delegato'
{CompositeDisposable} = require 'atom'
{
  getVimEofBufferPosition
  getVimLastBufferRow
  getVimLastScreenRow
} = require './utils'

settings = require './settings'
selectList = null
getEditorState = null # set by Base.init()

vimStateMethods = [
  "onDidChangeInput"
  "onDidConfirmInput"
  "onDidCancelInput"
  "onDidUnfocusInput"
  "onDidCommandInput"
  "onDidChangeSearch"
  "onDidConfirmSearch"
  "onDidCancelSearch"
  "onDidUnfocusSearch"
  "onDidCommandSearch"
  "onWillSelectTarget"
  "onDidSelectTarget"
  "onDidSetTarget"
  "onDidFinishOperation"
  "onDidCancelSelectList"
  "subscribe"
  "isMode"
  "hasCount"
  "getBlockwiseSelections"
  "updateSelectionProperties"
  "preserveCount"
]

class Base
  Delegato.includeInto(this)
  @delegatesMethods(vimStateMethods..., toProperty: 'vimState')

  constructor: (@vimState, properties) ->
    {@editor, @editorElement} = @vimState
    @preserveCount()
    _.extend(this, properties)
    if settings.get('showHoverOnOperate')
      hover = @hover?[settings.get('showHoverOnOperateIcon')]
      if hover? and not @isComplete()
        @addHover(hover)

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
    throw new OperationAbortedError()

  # Count
  # -------------------------
  defaultCount: 1
  getDefaultCount: ->
    @defaultCount

  getCount: ->
    @count ?= @vimState.getCount() ? @getDefaultCount()

  isDefaultCount: ->
    @count is @getDefaultCount()

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

  addHover: (text, {replace}={}) ->
    if replace ? false
      @vimState.hover.replaceLastSection(text)
    else
      @vimState.hover.add(text)

  new: (name, properties={}) ->
    klass = Base.getClass(name)
    new klass(@vimState, properties)

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

  focusInput: (options={}) ->
    options.charsMax ?= 1
    @onDidConfirmInput (@input) =>
      @processOperation()

    # From 2nd addHover, we replace last section of hover
    # to sync content with input mini editor.
    replace = false
    @onDidChangeInput (input) =>
      @addHover(input, {replace})
      replace = true

    @onDidCancelInput =>
      @cancelOperation()

    @vimState.input.focus(options)

  getVimEofBufferPosition: ->
    getVimEofBufferPosition(@editor)

  getVimLastBufferRow: ->
    getVimLastBufferRow(@editor)

  getVimLastScreenRow: ->
    getVimLastScreenRow(@editor)

  instanceof: (klassName) ->
    this instanceof Base.getClass(klassName)

  isOperator: ->
    @instanceof('Operator')

  isMotion: ->
    @instanceof('Motion')

  isTextObject: ->
    @instanceof('TextObject')

  getName: ->
    @constructor.name

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

  # Class methods
  # -------------------------
  @init: (service) ->
    {getEditorState} = service
    @subscriptions = new CompositeDisposable()

    [
      './operator', './motion', './text-object',
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
    atom.commands.add(@getCommandScope(), @getCommandName(), (event) => @run(event))

  @run: (event) ->
    if vimState = getEditorState(atom.workspace.getActiveTextEditor())
      vimState.domEvent = event
      # Reason: https://github.com/t9md/atom-vim-mode-plus/issues/85
      vimState.operationStack.run(this)

class OperationAbortedError extends Base
  @extend(false)
  constructor: (@message) ->
    @name = 'OperationAborted Error'

module.exports = Base
