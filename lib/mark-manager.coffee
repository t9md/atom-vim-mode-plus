# Refactoring status: 100%
module.exports =
class MarkManager
  marks: null

  constructor: (@vimState) ->
    {@editor} = @vimState
    @marks = {}

  # Private: Fetches the value of a given mark.
  #
  # name - The name of the mark to fetch.
  #
  # Returns {Point} or underfined
  get: (name) ->
    @marks[name]?.getStartBufferPosition()

  # Private: Sets the value of a given mark.
  #
  # name  - The name of the mark to fetch.
  # pos {Point} - The value to set the mark to.
  #
  # Returns nothing.
  # [FIXME] Need to support Global mark with capital name [A-Z]
  set: (name, point) ->
    # check to make sure name is in [a-z] or is `
    if (charCode = name.charCodeAt(0)) >= 96 and charCode <= 122
      @marks[name] = @editor.markBufferPosition point,
        invalidate: 'never',
        persistent: false
