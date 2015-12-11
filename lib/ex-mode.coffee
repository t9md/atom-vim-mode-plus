_ = require 'underscore-plus'
{SelectListView, $, $$} = require 'atom-space-pen-views'
{match} = require 'fuzzaldrin'
{filter} = require('fuzzaldrin')

prefix = "ex-command"

trimPrefix = (name) ->
  name.replace(///^.*?:///, '')

getEditor = ->
  atom.workspace.getActiveTextEditor()

MAX_ITEMS = 5
class ExMode extends SelectListView
  @toggle: (vimState) ->
    view = new ExMode
    view.toggle(vimState)

  initialize: ->
    @setMaxItems(MAX_ITEMS)
    super
    @addClass('vim-mode-plus.ex-mode')

  getFilterKey: ->
    'displayName'

  cancelled: ->
    @hide()

  toggle: (@vimState) ->
    if @panel?.isVisible()
      @cancel()
    else
      {@editorElement, @editor} = @vimState
      @show()

  show: ->
    @storeFocusedElement()
    @panel ?= atom.workspace.addModalPanel({item: this})
    @panel.show()
    # commands = _.sortBy(commands, 'displayName')
    @setItems(@getCommands())
    @focusFilterEditor()

  vimCommands = [
    "camel-case"
    "dash-case"
    "split"
    "join-by-input"
  ].map (e) -> "vim-mode-plus:#{e}"
  getCommands: ->
    commands = atom.commands.findCommands(target: @editorElement).filter ({name}) ->
      name.startsWith('ex-command:') or (name.startsWith('vim-mode-plus:') and name in vimCommands)

    commands.map ({name}) -> {name, displayName: trimPrefix(name)}

  hide: ->
    @panel?.hide()

  populateList: ->
    super
    query = @getFilterQuery()
    if query.length
      if matched = query.match(/(\d+)(%)?$/)
        [number, percent] = matched[1..2]
        @count = Number(number)
        item = if number? and not percent?
          {name: 'move-to-line', displayName: 'move-to-line'}
        else if number? and percent?
          {name: 'move-to-line-by-percent', displayName: 'move-to-line-by-percent'}
        @setError(null)
        itemView = $(@viewForItem(item))
        itemView.data('select-list-item', item)
        @list.append(itemView)
        @selectItemView(@list.find('li:first'))

  viewForItem: ({name, displayName}) ->
    # Style matched characters in search results
    filterQuery = @getFilterQuery()
    matches = match(displayName, filterQuery)
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
        @span title: name, -> highlighter(displayName, matches, 0)

  confirmed: ({name}) ->
    @cancel()
    switch name
      when 'move-to-line'
        @vimState.count.set(@count)
        @vimState.operationStack.run('MoveToFirstLine')
      when 'move-to-line-by-percent'
        @vimState.count.set(@count)
        @vimState.operationStack.run('MoveToLineByPercent')
      else
        @editorElement.dispatchEvent(new CustomEvent(name, bubbles: true, cancelable: true))

module.exports = ExMode
