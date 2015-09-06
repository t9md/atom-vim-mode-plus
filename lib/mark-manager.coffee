# Refactoring status: 100%
module.exports =
class MarkManager
  marks: null

  constructor: (@vimState) ->
    {@editor} = @vimState
    @marks = {}

  get: (name) ->
    @marks[name]?.getStartBufferPosition()

  # [FIXME] Need to support Global mark with capital name [A-Z]
  set: (name, point) ->
    # check to make sure name is in [a-z] or is `
    if (charCode = name.charCodeAt(0)) >= 96 and charCode <= 122
      @marks[name] = @editor.markBufferPosition point,
        invalidate: 'never',
        persistent: false
