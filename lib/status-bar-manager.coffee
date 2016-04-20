{ElementBuilder} = require './utils'

modeToContent =
  "normal": "Normal"
  'insert': "Insert"
  'insert.replace': "Replace"
  'visual': "Visual"
  "visual.characterwise": "Visual Char"
  "visual.linewise": "Visual Line"
  "visual.blockwise": "Visual Block"

module.exports =
class StatusBarManager
  ElementBuilder.includeInto(this)
  prefix: 'status-bar-vim-mode-plus'

  constructor: ->
    @container = @div(id: "#{@prefix}-container", classList: ['inline-block'])
    @container.appendChild(@element = @div(id: @prefix))

  initialize: (@statusBar) ->

  update: (mode, submode) ->
    modeString = mode
    modeString += "." + submode if submode?
    @element.className = "#{@prefix}-#{mode}"
    @element.textContent = modeToContent[modeString]

  attach: ->
    @tile = @statusBar.addRightTile(item: @container, priority: 20)

  detach: ->
    @tile.destroy()
