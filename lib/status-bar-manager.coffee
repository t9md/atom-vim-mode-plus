_ = require 'underscore-plus'

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
    modeString = _.humanizeEventName(mode)
    modeString += " " + _.humanizeEventName(submode) if submode?
    @element.className = "#{@prefix}-#{mode}"
    @element.textContent = modeString

  attach: ->
    @tile = @statusBar.addRightTile(item: @container, priority: 20)

  detach: ->
    @tile.destroy()
