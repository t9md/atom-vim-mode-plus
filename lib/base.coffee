# Refactoring status: 100%
_ = require 'underscore-plus'
Delegato = require 'delegato'
{CompositeDisposable} = require 'atom'

settings = require './settings'

packageScope = 'vim-mode-plus'
getEditorState = null # set in Base.init()
subscriptions = null

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
  "onDidChange"
  "onDidOperationFinish"
  "subscribe"
]

class Base
  Delegato.includeInto(this)
  complete: false
  recordable: false
  defaultCount: 1
  requireInput: false
  repeated: false

  @delegatesMethods delegatingMethods..., toProperty: 'vimState'

  constructor: (@vimState, properties) ->
    {@editor, @editorElement} = @vimState
    if settings.get('showHoverOnOperate')
      if @hover?
        @vimState.hover.setPoint()
        if hover = @hover[settings.get('showHoverOnOperateIcon')]
          @vimState.hover.add(hover)
    _.extend(this, properties)

  # Operation processor execute only when isComplete() return true.
  # If false, operation processor postpone its execution.
  isComplete: ->
    if (@requireInput and not @input)
      false
    else if @target?
      @target.isComplete()
    else
      @complete

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
    @count ?= @vimState?.count.get() ? @defaultCount
    @count

  new: (klassName, properties={}) ->
    klass = Base.getClass(klassName)
    new klass(@vimState, properties)

  focusInput: ({charsMax}={}) ->
    charsMax ?= 1
    @onDidConfirmInput (@input) =>
      @complete = true
      @vimState.operationStack.process()
    @onDidCancelInput =>
      @vimState.operationStack.cancel()
    @vimState.input.focus({charsMax})

  instanceof: (klassName) ->
    this instanceof Base.getClass(klassName)

  emitWillSelect: ->
    @vimState.emitter.emit 'will-select'

  emitDidSelect: ->
    @vimState.emitter.emit 'did-select'

  # Class methods
  # -------------------------
  @init: (service) ->
    {getEditorState} = service

    operations = [
      './operator', './motion', './text-object',
      './insert-mode', './misc-commands', './scroll', './visual-blockwise'
    ]
    require(lib) for lib in operations

    subscriptions = new CompositeDisposable
    for __, klass of @getRegistory() when klass.isCommand()
      klass.registerCommands()
    subscriptions

  # Expected to be called by child class.
  operationKinds = [
    "TextObject", "Misc", "InsertMode", "Motion", "Operator", "Scroll", "VisualBlockwise"
  ]
  registory = {Base}
  @extend: (@command=true) ->
    if @name of registory
      console.warn "Duplicate constructor #{@name}"
    registory[@name] = this
    # Used to determine klass is TextObject in @registerCommands()
    this.kind = @name if @name in operationKinds

  @getRegistory: ->
    registory

  @isCommand: ->
    @command

  @getCommandName: ->
    _.dasherize(@name)

  @getCommands: ->
    commands = {}
    vim = packageScope
    cmd = @getCommandName()
    if @kind is 'TextObject'
      commands["#{vim}:a-#{cmd}"] = => run(this)
      commands["#{vim}:inner-#{cmd}"] = => run(this, {inner: true})
    else
      commands["#{vim}:#{cmd}"] = => run(this)
    commands

  @registerCommands: ->
    subscriptions.add atom.commands.add('atom-text-editor', @getCommands())

  @getClass: (klassName) ->
    registory[klassName]

class OperationAbortedError extends Base
  @extend(false)
  constructor: (@message) ->
    @name = 'OperationAborted Error'

module.exports = Base
