# Refactoring status: 80%
{Disposable, CompositeDisposable} = require 'atom'
{ElementBuilder} = require './utils'

ContentsByMode =
  'insert': ["insert", "Insert"]
  'insert.replace': ["insert", "Replace"]
  'normal': ["normal", "Normal"]
  'visual': ["visual", "Visual"]
  'visual.characterwise': ["visual", "Visual Char"]
  'visual.linewise': ["visual", "Visual Line"]
  'visual.blockwise': ["visual", "Visual Block"]

module.exports =
class StatusBarManager
  ElementBuilder.includeInto(this)
  prefix: 'status-bar-vim-mode-plus'

  constructor: ->
    (@container = @div(id: "#{@prefix}-container", classList: ['inline-block']))
    .appendChild(@element = @div(id: @prefix))

  initialize: (@statusBar) ->

  update: (mode, submode) ->
    modeString = mode
    modeString += "." + submode if submode?
    if newContents = ContentsByMode[modeString]
      [className, text] = newContents
      @element.className = "#{@prefix}-#{className}"
      @element.textContent = text

  # Private
  attach: ->
    @tile = @statusBar.addRightTile(item: @container, priority: 20)

  detach: ->
    @tile.destroy()
