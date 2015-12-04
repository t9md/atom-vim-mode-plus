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
    switch
      when (@requireInput and not @input)
        false
      when @target?
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

  focusInput: (options={}) ->
    options.charsMax ?= 1
    @onDidConfirmInput (@input) =>
      @complete = true
      @vimState.operationStack.process()
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
    {getEditorState, subscriptions} = service

    require(lib) for lib in [
      './operator', './motion', './text-object',
      './insert-mode', './misc-commands', './scroll', './visual-blockwise'
    ]

    for __, klass of @getRegistries() when klass.isCommand()
      subscriptions.add klass.registerCommands()

  # Expected to be called by child class.
  operationKinds = [
    "TextObject", "Misc", "InsertMode", "Motion", "Operator", "Scroll", "VisualBlockwise"
  ]
  registries = {Base}
  @extend: (@command=true) ->
    if @name of registries
      console.warn "Duplicate constructor #{@name}"
    registries[@name] = this
    # Used to determine klass is TextObject in @registerCommands()
    @kind = @name if @name in operationKinds

  @getRegistries: ->
    registries

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
    atom.commands.add('atom-text-editor', @getCommands())

  @getClass: (klassName) ->
    registries[klassName]

class OperationAbortedError extends Base
  @extend(false)
  constructor: (@message) ->
    @name = 'OperationAborted Error'

module.exports = Base
