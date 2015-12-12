# Refactoring status: 100%
_ = require 'underscore-plus'
Delegato = require 'delegato'

settings = require './settings'

packageScope = 'vim-mode-plus'
getEditorState = null # set in Base.init()

run = (klass, properties={}) ->
  vimState = getEditorState(atom.workspace.getActiveTextEditor())
  vimState.operationStack.run(klass, properties)

delegatingMethods = [
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
  "onWillSelect"
  "onDidSelect"
  "onDidOperationFinish"
  "subscribe"
  "isMode"
]

class Base
  Delegato.includeInto(this)
  recordable: false
  repeated: false
  defaultCount: 1
  requireInput: false
  requireTarget: false

  @delegatesMethods delegatingMethods..., toProperty: 'vimState'

  constructor: (@vimState, properties) ->
    {@editor, @editorElement} = @vimState
    @vimState.hover.setPoint()
    if hover = @hover?[settings.get('showHoverOnOperateIcon')]
      @addHover(hover)
    _.extend(this, properties)

  # Operation processor execute only when isComplete() return true.
  # If false, operation processor postpone its execution.
  isComplete: ->
    if (@requireInput and not @input)
      return false

    if @requireTarget
      @target?.isComplete()
    else
      true

  isRecordable: ->
    @recordable

  isRepeated: ->
    @repeated

  setRepeated: ->
    @repeated = true

  abort: ->
    throw new OperationAbortedError('Aborted')

  getCount: ->
    # Setting count as instance variable allows operation repeatable with same count.
    @count ?= @vimState.count.get() ? @defaultCount

  activateMode: (mode, submode) ->
    @onDidOperationFinish =>
      @vimState.activate(mode, submode)

  addHover: (text, {replace}={}) ->
    if settings.get('showHoverOnOperate')
      replace ?= false
      if replace
        @vimState.hover.replaceLastSection(text)
      else
        @vimState.hover.add(text)

  new: (klassName, properties={}) ->
    klass = Base.getClass(klassName)
    new klass(@vimState, properties)

  focusInput: (options={}) ->
    options.charsMax ?= 1
    @onDidConfirmInput (@input) =>
      @vimState.operationStack.process()

    # From 2nd addHover, we replace last section of hover
    # to sync content with input mini editor.
    firstInput = true
    @onDidChangeInput (input) =>
      @addHover(input, replace: not firstInput)
      firstInput = false

    @onDidCancelInput =>
      @vimState.operationStack.cancel()
    @vimState.input.focus(options)

  instanceof: (klassName) ->
    this instanceof Base.getClass(klassName)

  emitWillSelect: ->
    @vimState.emitter.emit 'will-select'

  emitDidSelect: ->
    @vimState.emitter.emit 'did-select'

  # Class methods
  # -------------------------
  @init: (service) ->
    {getEditorState, getSubscriptions} = service
    subscriptions = getSubscriptions()

    require(lib) for lib in [
      './operator', './motion', './text-object',
      './insert-mode', './misc-commands', './scroll', './visual-blockwise'
    ]
    for __, klass of @getRegistries() when klass.isCommand()
      subscriptions.add klass.registerCommand()

  registries = {Base}
  @extend: (@command=true) ->
    if @name of registries
      console.warn "Duplicate constructor #{@name}"
    registries[@name] = this

  @getRegistries: ->
    registries

  @isCommand: ->
    @command

  @getCommandName: ->
    packageScope + ':' + _.dasherize(@name)

  @registerCommand: ->
    atom.commands.add('atom-text-editor', @getCommandName(), => run(this))

  @getClass: (klassName) ->
    registries[klassName]

class OperationAbortedError extends Base
  @extend(false)
  constructor: (@message) ->
    @name = 'OperationAborted Error'

module.exports = Base
