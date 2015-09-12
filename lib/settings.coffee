# Refactoring status: 100%
class ScopedConfig
  constructor: (@scope, @config) ->

  get: (param) ->
    if param is 'defaultRegister'
      if @get('useClipboardAsDefaultRegister') then '*' else '"'
    else
      atom.config.get "#{@scope}.#{param}"

  set: (param, value) ->
    atom.config.set "#{@scope}.#{param}", value

module.exports = new ScopedConfig 'vim-mode',
  startInInsertMode:
    order: 1
    type: 'boolean'
    default: false
  useSmartcaseForSearch:
    order: 2
    type: 'boolean'
    default: false
  wrapLeftRightMotion:
    order: 3
    type: 'boolean'
    default: false
  useClipboardAsDefaultRegister:
    order: 5
    type: 'boolean'
    default: false
  numberRegex:
    order: 6
    type: 'string'
    default: '-?[0-9]+'
    description: 'Use this to control how Ctrl-A/Ctrl-X finds numbers; use "(?:\\B-)?[0-9]+" to treat numbers as positive if the minus is preceded by a character, e.g. in "identifier-1".'
  showCursorInVisualMode:
    order: 7
    type: 'boolean'
    default: true
  flashOnOperate:
    order: 8
    type: 'boolean'
    default: true
  flashOnOperateDurationMilliSeconds:
    order: 9
    type: 'integer'
    default: 100
    description: "Duration for flash"
  stayOnTransformString:
    order: 10
    type: 'boolean'
    default: false
    description: "Dont move cursor when Toggle, Surround, etc"
  enableHoverIndicator:
    order: 11
    type: 'boolean'
    default: false
  enableHoverIcon:
    order: 12
    type: 'boolean'
    default: false
  hoverStyle:
    order: 13
    type: 'string'
    default: 'emoji'
    enum: ['emoji', 'icon']
  debug:
    order: 100
    type: 'boolean'
    default: false
  debugOutput:
    order: 102
    type: 'string'
    default: 'console'
    enum: ['console', 'file']
