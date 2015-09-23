# Refactoring status: 100%
_ = require 'underscore-plus'
{getAncestors, getParent} = require './introspection'
settings = require './settings'

class Base
  complete: null
  recodable: null
  requireInput: false
  canceled: false

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    if settings.get('enableHoverIcon')
      hover =
        switch settings.get('hoverStyle')
          when 'emoji' then @hoverText if @hoverText?
          when 'icon'  then @hoverIcon if @hoverIcon?
      @vimState.hover.add hover if hover?

  # Operation processor execute only when isComplete() return true.
  # If false, operation processor postpone its execution.
  isComplete: ->
    if @isCanceled()
      return true

    if @requireInput and not @input
      return false

    if @target?
      @target.isComplete()
    else
      @complete

  isRecordable: ->
    @recodable

  abort: ->
    throw new OperationAbortedError('Aborted')

  getKind: ->
    @constructor.name

  getCount: (defaultCount=null) ->
    # Setting count as instance variable make operation repeatable with same count.
    @count ?= @vimState?.count.get() ? defaultCount
    @count

  new: (klassName, properties={}) ->
    obj = new (Base.findClass(klassName))(@vimState)
    _.extend(obj, properties)

  readInput: (options={}) ->
    _.defaults(options, defaultInput: '', charsMax: 1)

    @vimState.input.readInput options,
      onDidConfirm: (input) =>
        @input = input
        @complete = true
        @vimState.operationStack.process()
      onDidCancel: =>
        # FIXME
        # Cancelation currently depending on operationStack to call cancel()
        # Should be better to observe cancel event on operationStack side.
        @canceled = true
        @vimState.operationStack.process()

  isCanceled: ->
    @canceled

  cancel: ->
    unless @vimState.isMode('visual') or @vimState.isMode('insert')
      @vimState.activate('reset')

  flash: ({range, klass, timeout}, fn=null) ->
    marker = @editor.markBufferRange range,
      invalidate: 'never',
      persistent: false
    fn?()
    @editor.decorateMarker marker,
      type: 'highlight'
      class: klass

    setTimeout  ->
      marker.destroy()
    , timeout

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
  children = []
  @extend: ->
    klass = this
    Base::["is#{klass.name}"] = ->
      this instanceof klass
    children.push klass

  @findClass: (klassName) ->
    # [FIXME] currently not care acncesstor's chain.
    # Not accurate if there is different class with same.
    _.detect children, (child) ->
      child.name is klassName

  @getAncestors: ->
    getAncestors(this)

  @getParent: ->
    getParent(this)

class OperationAbortedError extends Base
  @extend()
  constructor: (@message) ->
    @name = 'OperationAborted Error'

module.exports = Base
