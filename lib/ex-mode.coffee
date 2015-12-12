_ = require 'underscore-plus'
{SelectListView, $, $$} = require 'atom-space-pen-views'
fuzzaldrin = require 'fuzzaldrin'

MAX_ITEMS = 5
class ExMode extends SelectListView
  @toggle: (vimState) ->
    view = new ExMode
    view.toggle(vimState)

  @registerCommand: (name, fn) ->
    @commands[name] = fn

  @registerCommands: (commands) ->
    @registerCommand(name, fn) for name, fn of commands

  @init: ->
    @commands = {}
    @registerCommands
      'w': ({editor}) ->
        editor.save()
      'wq': ({editor}) ->
        editor.save()
        atom.workspace.destroyActivePaneItemOrEmptyPane()
      'move-to-line': (vimState, count) ->
        vimState.count.set(count)
        vimState.operationStack.run('MoveToFirstLine')
      'move-to-line-by-percent': (vimState, count) ->
        vimState.count.set(count)
        vimState.operationStack.run('MoveToLineByPercent')

  initialize: ->
    @setMaxItems(MAX_ITEMS)
    super
    @addClass('vim-mode-plus.ex-mode')

  getFilterKey: ->
    'name'

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

  hiddenCommands = ['move-to-line', 'move-to-line-by-percent']
  getCommands: ->
    _.keys(@constructor.commands)
      .filter (e) -> e not in hiddenCommands
      .sort()
      .map (e) -> {name: e}

  executeCommand: (name) ->
    action = @constructor.commands[name]
    action(@vimState, @count)

  hide: ->
    @panel?.hide()

  # Use as command missing hook.
  getEmptyMessage: (itemCount, filteredItemCount) ->
    matched = @getFilterQuery().match(/(\d+)(%)?$/)
    return unless matched

    [number, percent] = matched[1..2]
    @count = Number(number)
    name = switch
      when number? and percent? then 'move-to-line-by-percent'
      when number? then 'move-to-line'
    item = {name}

    @setError(null)
    itemView = $(@viewForItem(item))
    itemView.data('select-list-item', item)
    @list.append(itemView)
    @selectItemView(@list.find('li:first'))

  viewForItem: ({name}) ->
    # Style matched characters in search results
    filterQuery = @getFilterQuery()
    matches = fuzzaldrin.match(name, filterQuery)
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
        @span title: name, -> highlighter(name, matches, 0)

  confirmed: ({name}) ->
    @cancel()
    @executeCommand(name)

ExMode.init()
module.exports = ExMode
