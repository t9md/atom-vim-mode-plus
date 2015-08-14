module.exports =
class MarkManager
  marks: null

  constructor: (@vimState) ->
    {@editor, @globalVimState} = @vimState
    @marks = {}

  # Private: Fetches the value of a given mark.
  #
  # name - The name of the mark to fetch.
  #
  # Returns the value of the given mark or undefined if it hasn't
  # been set.
  get: (name) ->
    @marks[name]?.getStartBufferPosition()
    
  # Private: Sets the value of a given mark.
  #
  # name  - The name of the mark to fetch.
  # pos {Point} - The value to set the mark to.
  #
  # Returns nothing.
  set: (name, pos) ->
    # check to make sure name is in [a-z] or is `
    if (charCode = name.charCodeAt(0)) >= 96 and charCode <= 122
      marker = @editor.markBufferPosition(pos, {invalidate: 'never', persistent: false})
      console.log marker.getBufferRange()
      @marks[name] = marker
