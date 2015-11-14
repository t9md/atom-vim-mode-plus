# Refactoring status: 100%
_ = require 'underscore-plus'
{Disposable, CompositeDisposable} = require 'atom'
{getAncestors, getParent} = require './introspection'
{kls2cmd} = require './utils'
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

  # TODO: remove in near future
  getKind: ->
    @constructor.name

  getCount: ->
    # Setting count as instance variable allows operation repeatable with same count.
    @count ?= @vimState?.count.get() ? @defaultCount
    @count

  new: (klassName, properties={}) ->
    klass = Base.getConstructor(klassName)
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

  # Class methods
  # -------------------------
  @init: (service) ->
    {getEditorState} = service
    subscriptions = new CompositeDisposable
    new Disposable ->
      subscriptions.dispose()
      subscriptions = null

  # Expected to be called by child class.
  # It automatically create typecheck function like
  #
  # e.g.
  #   class Operator extends base
  #     @extends()
  #
  # Above code automatically define following function.
  #
  # Base::isOperator: ->
  #   this instanceof Operator
  #
  operationKinds = [
    "TextObject",
    "Misc",
    "InsertMode",
    "Motion",
    "Operator",
    "Scroll",
    "VisualBlockwise"
  ]
  children = Object.create(null)
  @extend: ->
    klass = this
    if @name of children
      console.warn "Duplicate constructor #{@name}"
    children[@name] = klass
    Base::["is#{@name}"] = ->
      this instanceof klass
    # Used to determine klass is TextObject in @registerCommand()
    klass.kind = @name if @name in operationKinds

  @getCommandName: ->
    kls2cmd(@name)

  @run: (properties={}) ->
    vimState = getEditorState(atom.workspace.getActiveTextEditor())
    vimState.operationStack.run(this, properties)

  @registerCommand: ->
    name = @getCommandName()
    subs = subscriptions
    if @kind is 'TextObject'
      subs.add addCommand("a-#{name}", => @run())
      subs.add addCommand("inner-#{name}", => @run({inner: true}))
    else
      subs.add addCommand(name, => @run())

  @getConstructor: (klassName) ->
    children[klassName]

  @getAncestors: ->
    getAncestors(this)

  @getParent: ->
    getParent(this)

class OperationAbortedError extends Base
  @extend()
  constructor: (@message) ->
    @name = 'OperationAborted Error'

module.exports = Base
