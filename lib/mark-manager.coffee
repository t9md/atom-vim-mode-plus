MARKS = /// (
  ?: [a-z]
   | [\[\]`.^(){}<>]
) ///

class MarkManager
  marks: null

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    @marks = {}
    subs = @vimState.subscriptions
    subs.add @vimState.modeManager.onWillDeactivateMode ({mode, submode}) =>
      switch mode
        when 'insert'
          @set('^', @editor.getCursorBufferPosition())

  isValid: (name) ->
    MARKS.test(name)

  get: (name) ->
    return unless @isValid(name)
    @marks[name]?.getStartBufferPosition()

  # [FIXME] Need to support Global mark with capital name [A-Z]
  set: (name, point) ->
    return unless @isValid(name)
    @marks[name] = @editor.markBufferPosition point,
      invalidate: 'never',
      persistent: false

module.exports = MarkManager
