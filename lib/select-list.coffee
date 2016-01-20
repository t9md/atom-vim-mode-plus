_ = require 'underscore-plus'
{SelectListView, $, $$} = require 'atom-space-pen-views'
fuzzaldrin = require 'fuzzaldrin'

class SelectList extends SelectListView
  initialize: ->
    super
    @addClass('vim-mode-plus-select-list')

  getFilterKey: ->
    'displayName'

  cancelled: ->
    @vimState.emitter.emit 'did-cancel-select-list'
    @hide()

  show: (@vimState, options) ->
    if options.maxItems?
      @setMaxItems(options.maxItems)
    {@editorElement, @editor} = @vimState
    @storeFocusedElement()
    @panel ?= atom.workspace.addModalPanel({item: this})
    @panel.show()
    @setItems(options.items)
    @focusFilterEditor()

  hide: ->
    @panel?.hide()

  viewForItem: ({name, displayName}) ->
    # Style matched characters in search results
    filterQuery = @getFilterQuery()
    matches = fuzzaldrin.match(displayName, filterQuery)
    $$ ->
      highlighter = (command, matches, offsetIndex) =>
        lastIndex = 0
        matchedChars = [] # Build up a set of matched chars to be more semantic

        for matchIndex in matches
          matchIndex -= offsetIndex
          continue if matchIndex < 0 # If marking up the basename, omit command matches
          unmatched = command.substring(lastIndex, matchIndex)
          if unmatched
            @span matchedChars.join(''), class: 'character-match' if matchedChars.length
            matchedChars = []
            @text unmatched
          matchedChars.push(command[matchIndex])
          lastIndex = matchIndex + 1

        @span matchedChars.join(''), class: 'character-match' if matchedChars.length
        # Remaining characters are plain text
        @text command.substring(lastIndex)

      @li class: 'event', 'data-event-name': name, =>
        @span title: displayName, -> highlighter(displayName, matches, 0)

  confirmed: (item) ->
    @vimState.emitter.emit 'did-confirm-select-list', item
    @cancel()

module.exports = new SelectList
