_ = require 'underscore-plus'
settings = require './settings'

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
    modeString = switch settings.get('statusBarModeStringStyle')
      when 'short' then @getShortModeString(mode, submode)
      when 'long' then @getLongModeString(mode, submode)
    @element.textContent = modeString

  getShortModeString: (mode, submode) ->
    (mode[0] + (if submode? then submode[0] else '')).toUpperCase()

  getLongModeString: (mode, submode) ->
    modeString = _.humanizeEventName(mode)
    modeString += " " + _.humanizeEventName(submode) if submode?
    modeString

  attach: ->
    @tile = @statusBar.addRightTile(item: @container, priority: 20)

  detach: ->
    @tile.destroy()
