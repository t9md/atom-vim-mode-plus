settings = require './settings'

createDiv = ({id, classList}) ->
  div = document.createElement('div')
  div.id = id if id?
  div.classList.add(classList...) if classList?
  div

LongModeStringTable =
  'normal': "Normal"
  'operator-pending': "Operator Pending"
  'visual.characterwise': "Visual Characterwise"
  'visual.blockwise': "Visual Blockwise"
  'visual.linewise': "Visual Linewise"
  'insert': "Insert"
  'insert.replace': "Insert Replace"

module.exports =
class StatusBarManager
  prefix: 'status-bar-vim-mode-plus'

  constructor: ->
    @container = createDiv(id: "#{@prefix}-container", classList: ['inline-block'])
    @container.appendChild(@element = createDiv(id: @prefix))

  initialize: (@statusBar) ->

  update: (mode, submode) ->
    @element.className = "#{@prefix}-#{mode}"
    @element.textContent =
      switch settings.get('statusBarModeStringStyle')
        when 'short'
          (mode[0] + (if submode? then submode[0] else '')).toUpperCase()
        when 'long'
          LongModeStringTable[mode + (if submode? then '.' + submode else '')]

  attach: ->
    @tile = @statusBar.addRightTile(item: @container, priority: 20)

  detach: ->
    @tile.destroy()
