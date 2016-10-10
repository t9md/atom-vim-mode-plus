createDiv = ({id, classList}) ->
  div = document.createElement('div')
  div.id = id if id?
  div.classList.add(classList...) if classList?
  div

module.exports =
class StatusBarManager
  prefix: 'status-bar-vim-mode-plus'

  constructor: ->
    @container = createDiv(id: "#{@prefix}-container", classList: ['inline-block'])
    @container.appendChild(@element = createDiv(id: @prefix))

  initialize: (@statusBar) ->

  update: (mode, submode) ->
    @element.className = "#{@prefix}-#{mode}"
    submodeChar = if submode? then submode[0] else ''
    @element.textContent = (mode[0] + submodeChar).toUpperCase()

  attach: ->
    @tile = @statusBar.addRightTile(item: @container, priority: 20)

  detach: ->
    @tile.destroy()
