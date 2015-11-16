# Refactoring status: 100%
_ = require 'underscore-plus'
{Disposable, CompositeDisposable} = require 'atom'
settings = require './settings'

packageScope = 'vim-mode-plus'
getEditorState = null # set in Base.int()
subscriptions = null

addCommand = (name, fn) ->
  atom.commands.add('atom-text-editor', "#{packageScope}:#{name}", fn)

class Base
  complete: false
  recodable: false
  defaultCount: 1
  requireInput: false

  constructor: (@vimState, properties) ->
    {@editor, @editorElement} = @vimState
    if settings.get('showHoverOnOperate')
      @vimState.hover.setPoint() if @hoverText?
      hover =
        switch settings.get('showHoverOnOperateIcon')
          when 'emoji' then @hoverText if @hoverText?
          when 'icon'  then @hoverIcon if @hoverIcon?
          else null
      @vimState.hover.add hover if hover?
    _.extend(this, properties)
    @initialize?()

  # Operation processor execute only when isComplete() return true.
  # If false, operation processor postpone its execution.
  isComplete: ->
    return false if (@requireInput and not @input)
    if @target?
      @target.isComplete()
    else
      @complete

  isRecordable: ->
    @recodable

  abort: ->
    throw new OperationAbortedError('Aborted')

  getCount: ->
    # Setting count as instance variable allows operation repeatable with same count.
    @count ?= @vimState?.count.get() ? @defaultCount
    @count

  new: (klassName, properties={}) ->
    klass = Base.getClass(klassName)
    new klass(@vimState, properties)

  readInput: ({charsMax}={}) ->
    charsMax ?= 1
    @vimState.input.readInput {charsMax},
      onConfirm: (input) =>
        @input = input
        @complete = true
        @vimState.operationStack.process()
      onCancel: =>
        @vimState.operationStack.cancel()

  instanceof: (klassName) ->
    this instanceof Base.getClass(klassName)

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
    for key, klass of registory when klass.isCommand()
      klass.registerCommands()

    new Disposable ->
      subscriptions.dispose()
      subscriptions = null

  # Expected to be called by child class.
  operationKinds = [
    "TextObject", "Misc", "InsertMode", "Motion", "Operator", "Scroll", "VisualBlockwise"
  ]
  registory = {Base}
  @extend: (@command) ->
    if @name of registory
      console.warn "Duplicate constructor #{@name}"
    registory[@name] = this
    # Used to determine klass is TextObject in @registerCommands()
    this.kind = @name if @name in operationKinds

  @getRegistory: ->
    registory

  @isCommand: ->
    @command ? true

  @getCommandName: ->
    _.dasherize(@name)

  # Return Array of commands bound to that class.
  @getCommands: ->
    commands = {}
    vim = packageScope
    cmd = @getCommandName()
    if @kind is 'TextObject'
      commands["#{vim}:a-#{cmd}"] = => @run()
      commands["#{vim}:inner-#{cmd}"] = => @run({inner: true})
    else
      commands["#{vim}:#{cmd}"] = => @run()
    commands

  @registerCommands: ->
    subscriptions.add atom.commands.add('atom-text-editor', @getCommands())

  @run: (properties={}) ->
    vimState = getEditorState(atom.workspace.getActiveTextEditor())
    vimState.operationStack.run(this, properties)

  @getClass: (klassName) ->
    registory[klassName]

  @getAncestors: ->
    ancestors = []
    ancestors.push (current=this)
    while current = current.getParent()
      ancestors.push current
    ancestors

  @getParent: ->
    this.__super__?.constructor

class OperationAbortedError extends Base
  @extend(false)
  constructor: (@message) ->
    @name = 'OperationAborted Error'

module.exports = Base
