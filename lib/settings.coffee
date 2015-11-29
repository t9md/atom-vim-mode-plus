# Refactoring status: 100%
class Settings
  constructor: (@scope, @config) ->

  get: (param) ->
    if param is 'defaultRegister'
      if @get('useClipboardAsDefaultRegister') then '*' else '"'
    else
      atom.config.get "#{@scope}.#{param}"

  set: (param, value) ->
    atom.config.set "#{@scope}.#{param}", value

module.exports = new Settings 'vim-mode-plus',
  useClipboardAsDefaultRegister:
    order: 1
    type: 'boolean'
    default: false
  startInInsertMode:
    order: 2
    type: 'boolean'
    default: false
  wrapLeftRightMotion:
    order: 3
    type: 'boolean'
    default: false
  numberRegex:
    order: 4
    type: 'string'
    default: '-?[0-9]+'
    description: 'Used to find number in ctrl-a/ctrl-x. To ignore "-"(minus) char in string like "identifier-1" use "(?:\\B-)?[0-9]+"'
  showCursorInVisualMode:
    order: 5
    type: 'boolean'
    default: true
  useSmartcaseForSearch:
    order: 6
    type: 'boolean'
    default: false
  incrementalSearch:
    order: 7
    type: 'boolean'
    default: false
  stayOnTransformString:
    order: 8
    type: 'boolean'
    default: false
    description: "Don't move cursor after TransformString e.g Toggle, Surround"
  stayOnYank:
    order: 9
    type: 'boolean'
    default: false
    description: "Don't move cursor after Yank"
  stayOnIndent:
    order: 10
    type: 'boolean'
    default: false
    description: "Don't move cursor after Indent"
  stayOnReplaceWithRegister:
    order: 11
    type: 'boolean'
    default: false
    description: "Don't move cursor after ReplaceWithRegister"
  stayOnToggleLineComments:
    order: 12
    type: 'boolean'
    default: false
    description: "Don't move cursor after ToggleLineComments"
  flashOnOperate:
    order: 13
    type: 'boolean'
    default: true
  flashOnOperateDuration:
    order: 14
    type: 'integer'
    default: 100
    description: "Duration(msec) for flash"
  flashOnSearch:
    order: 15
    type: 'boolean'
    default: true
  flashOnSearchDuration:
    order: 16
    type: 'integer'
    default: 300
    description: "Duration(msec) for search flash"
  flashScreenOnSearchHasNoMatch:
    order: 17
    type: 'boolean'
    default: true
  showHoverOnOperate:
    order: 18
    type: 'boolean'
    default: false
    description: "Show count, register and optional icon on hover overlay"
  showHoverOnOperateIcon:
    order: 19
    type: 'string'
    default: 'icon'
    enum: ['none', 'icon', 'emoji']
  showHoverSearchCounter:
    order: 20
    type: 'boolean'
    default: false
  showHoverSearchCounterDuration:
    order: 21
    type: 'integer'
    default: 700
    description: "Duration(msec) for hover search counter"
  debug:
    order: 22
    type: 'boolean'
    default: false
    description: "Show operationStack debug log on console"
  debugOutput:
    order: 23
    type: 'string'
    default: 'console'
    enum: ['console', 'file']
  debugOutputFilePath:
    order: 24
    type: 'string'
    default: ''
