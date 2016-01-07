# Refactoring status: 100%
_ = require 'underscore-plus'
Delegato = require 'delegato'
{CompositeDisposable} = require 'atom'

settings = require './settings'
getEditorState = null # set in Base.init()

run = (klass, properties={}) ->
  if vimState = getEditorState(atom.workspace.getActiveTextEditor())
    # Reason: https://github.com/t9md/atom-vim-mode-plus/issues/85
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
  "onDidSetTarget"
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
  operator: null
  asTarget: false
  @commandPrefix: 'vim-mode-plus'

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
    if (@requireInput and not @input?)
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

  # Intended to be used by TextObject or Motion
  isAsOperatorTarget: ->
    @operator? and this isnt @operator

  abort: ->
    throw new OperationAbortedError('Aborted')

  getCount: ->
    # Setting count as instance variable allows operation repeatable with same count.
    @count ?= @vimState.count.get() ? @defaultCount

  isDefaultCount: ->
    @getCount() is @defaultCount

  isCountSpecified: ->
    @vimState.count.get()?

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

  directInstanceof: (klassName) ->
    this.constructor is Base.getClass(klassName)

  emitWillSelect: ->
    @vimState.emitter.emit 'will-select'

  emitDidSelect: ->
    @vimState.emitter.emit 'did-select'

  emitDidSetTarget: (operator) ->
    @vimState.emitter.emit 'did-set-target', operator

  # Class methods
  # -------------------------
  @init: (service) ->
    {getEditorState} = service
    @subscriptions = new CompositeDisposable()

    require(lib) for lib in [
      './operator', './motion', './text-object',
      './insert-mode', './misc-commands', './scroll', './visual-blockwise'
    ]
    for __, klass of @getRegistries() when klass.isCommand()
      @subscriptions.add klass.registerCommand()
    @subscriptions

  # For development easiness without reloading vim-mode-plus
  @reset: ->
    @subscriptions.dispose()
    @subscriptions = new CompositeDisposable()
    for __, klass of @getRegistries() when klass.isCommand()
      @subscriptions.add klass.registerCommand()

  registries = {Base}
  @extend: (@command=true) ->
    if @name of registries and (not @suppressWarning)
      console.warn "Duplicate constructor #{@name}"
    registries[@name] = this

  @getRegistries: ->
    registries

  @isCommand: ->
    @command

  @getCommandName: ->
    @commandPrefix + ':' + _.dasherize(@name)

  @registerCommand: ->
    atom.commands.add('atom-text-editor', @getCommandName(), => run(this))

  @getClass: (klassName) ->
    registries[klassName]

class OperationAbortedError extends Base
  @extend(false)
  constructor: (@message) ->
    @name = 'OperationAborted Error'

module.exports = Base
