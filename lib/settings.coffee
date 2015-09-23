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
  startInInsertMode:
    order: 1
    type: 'boolean'
    default: false
  useSmartcaseForSearch:
    order: 2
    type: 'boolean'
    default: false
  enableIncrementalSearch:
    order: 3
    type: 'boolean'
    default: false
  wrapLeftRightMotion:
    order: 4
    type: 'boolean'
    default: false
  useClipboardAsDefaultRegister:
    order: 6
    type: 'boolean'
    default: false
  numberRegex:
    order: 7
    type: 'string'
    default: '-?[0-9]+'
    description: 'Use this to control how Ctrl-A/Ctrl-X finds numbers; use "(?:\\B-)?[0-9]+" to treat numbers as positive if the minus is preceded by a character, e.g. in "identifier-1".'
  showCursorInVisualMode:
    order: 8
    type: 'boolean'
    default: true
  flashOnOperate:
    order: 9
    type: 'boolean'
    default: true
  flashOnOperateDurationMilliSeconds:
    order: 10
    type: 'integer'
    default: 100
    description: "Duration for flash"
  flashOnSearch:
    order: 11
    type: 'boolean'
    default: true
  flashOnSearchDurationMilliSeconds:
    order: 12
    type: 'integer'
    default: 300
    description: "Duration for flash"
  stayOnTransformString:
    order: 13
    type: 'boolean'
    default: false
    description: "Dont move cursor when Toggle, Surround, etc"
  enableHoverIndicator:
    order: 14
    type: 'boolean'
    default: false
  enableHoverIcon:
    order: 15
    type: 'boolean'
    default: false
  hoverStyle:
    order: 16
    type: 'string'
    default: 'emoji'
    enum: ['emoji', 'icon']
  enableHoverSearchCounter:
    order: 17
    type: 'boolean'
    default: false
  searchCounterHoverDuration:
    order: 18
    type: 'integer'
    default: 500
  debug:
    order: 100
    type: 'boolean'
    default: false
  debugOutput:
    order: 102
    type: 'string'
    default: 'console'
    enum: ['console', 'file']
