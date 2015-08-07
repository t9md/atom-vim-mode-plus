
settings =
  config:
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
      order: 4
      type: 'boolean'
      default: false
    numberRegex:
      order: 5
      type: 'string'
      default: '-?[0-9]+'
      description: 'Use this to control how Ctrl-A/Ctrl-X finds numbers; use "(?:\\B-)?[0-9]+" to treat numbers as positive if the minus is preceded by a character, e.g. in "identifier-1".'
    debug:
      order: 6
      type: 'boolean'
      default: false
    debugOutput:
      order: 7
      type: 'string'
      default: 'console'
      enum: ['console', 'file']

Object.keys(settings.config).forEach (k) ->
  settings[k] = ->
    atom.config.get('vim-mode.'+k)

settings.defaultRegister = ->
  if settings.useClipboardAsDefaultRegister() then '*' else '"'

module.exports = settings
