# Refactoring status: 100%
module.exports =
class MarkManager
  marks: null

  constructor: (@vimState) ->
    {@editor, @editorElement} = @vimState
    @marks = {}

  get: (name) ->
    @marks[name]?.getStartBufferPosition()

  # [FIXME] Need to support Global mark with capital name [A-Z]
  set: (name, point) ->
    # check to make sure name is in [a-z] or is `
    if (96 <= name.charCodeAt(0) <= 122)
      @marks[name] = @editor.markBufferPosition point,
        invalidate: 'never',
        persistent: false
