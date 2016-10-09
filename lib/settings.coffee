class Settings
  constructor: (@scope, @config) ->
    # Inject order props to display orderd in setting-view
    for name, i in Object.keys(@config)
      @config[name].order = i

  get: (param) ->
    if param is 'defaultRegister'
      if @get('useClipboardAsDefaultRegister') then '*' else '"'
    else
      atom.config.get "#{@scope}.#{param}"

  set: (param, value) ->
    atom.config.set "#{@scope}.#{param}", value

  toggle: (param) ->
    @set(param, not @get(param))

  observe: (param, fn) ->
    atom.config.observe "#{@scope}.#{param}", fn

module.exports = new Settings 'vim-mode-plus',
  setCursorToStartOfChangeOnUndoRedo:
    type: 'boolean'
    default: true
  groupChangesWhenLeavingInsertMode:
    type: 'boolean'
    default: true
  useClipboardAsDefaultRegister:
    type: 'boolean'
    default: false
  startInInsertMode:
    type: 'boolean'
    default: false
  startInInsertModeScopes:
    type: 'array'
    items: type: 'string'
    default: []
    description: 'Start in insert-mode whan editorElement matches scope'
  clearMultipleCursorsOnEscapeInsertMode:
    type: 'boolean'
    default: false
  autoSelectPersistentSelectionOnOperate:
    type: 'boolean'
    default: true
  wrapLeftRightMotion:
    type: 'boolean'
    default: false
  numberRegex:
    type: 'string'
    default: '-?[0-9]+'
    description: 'Used to find number in ctrl-a/ctrl-x. To ignore "-"(minus) char in string like "identifier-1" use "(?:\\B-)?[0-9]+"'
  clearHighlightSearchOnResetNormalMode:
    type: 'boolean'
    default: false
    description: 'Clear highlightSearch on `escape` in normal-mode'
  clearPersistentSelectionOnResetNormalMode:
    type: 'boolean'
    default: false
    description: 'Clear persistentSelection on `escape` in normal-mode'
  charactersToAddSpaceOnSurround:
    type: 'array'
    items: type: 'string'
    default: []
    description: 'Comma separated list of character, which add additional space inside when surround.'
  showCursorInVisualMode:
    type: 'boolean'
    default: true
  ignoreCaseForSearch:
    type: 'boolean'
    default: false
    description: 'For `/` and `?`'
  useSmartcaseForSearch:
    type: 'boolean'
    default: false
    description: 'For `/` and `?`. Override `ignoreCaseForSearch`'
  ignoreCaseForSearchCurrentWord:
    type: 'boolean'
    default: false
    description: 'For `*` and `#`.'
  useSmartcaseForSearchCurrentWord:
    type: 'boolean'
    default: false
    description: 'For `*` and `#`. Override `ignoreCaseForSearchCurrentWord`'
  highlightSearch:
    type: 'boolean'
    default: false
  highlightSearchExcludeScopes:
    type: 'array'
    items: type: 'string'
    default: []
    description: 'Suppress highlightSearch when any of these classes are present in the editor'
  incrementalSearch:
    type: 'boolean'
    default: false
  incrementalSearchVisitDirection:
    type: 'string'
    default: 'absolute'
    enum: ['absolute', 'relative']
    description: "Whether 'visit-next'(tab) and 'visit-prev'(shift-tab) depends on search direction('/' or '?')"
  stayOnTransformString:
    type: 'boolean'
    default: false
    description: "Don't move cursor after TransformString e.g Toggle, Surround"
  # stayOnIncrease:
  #   type: 'boolean'
  #   default: false
  #   description: "Don't move cursor after Increase/Decrease `ctrl-a` or `ctrl-x`"
  stayOnYank:
    type: 'boolean'
    default: false
    description: "Don't move cursor after Yank"
  stayOnDelete:
    type: 'boolean'
    default: false
    description: "Don't move cursor after Delete"
  flashOnUndoRedo:
    type: 'boolean'
    default: true
  flashOnUndoRedoDuration:
    type: 'integer'
    default: 100
    description: "Duration(msec) for flash"
  flashOnOperate:
    type: 'boolean'
    default: true
  flashOnOperateDuration:
    type: 'integer'
    default: 100
    description: "Duration(msec) for flash"
  flashOnOperateBlacklist:
    type: 'array'
    items: type: 'string'
    default: []
    description: 'comma separated list of operator class name to disable flash e.g. "Yank, AutoIndent"'
  flashOnSearch:
    type: 'boolean'
    default: true
  flashOnSearchDuration:
    type: 'integer'
    default: 300
    description: "Duration(msec) for search flash"
  flashScreenOnSearchHasNoMatch:
    type: 'boolean'
    default: true
  showHoverOnOperate:
    type: 'boolean'
    default: false
    description: "Show count, register and optional icon on hover overlay"
  showHoverOnOperateIcon:
    type: 'string'
    default: 'icon'
    enum: ['none', 'icon', 'emoji']
  showHoverSearchCounter:
    type: 'boolean'
    default: false
  showHoverSearchCounterDuration:
    type: 'integer'
    default: 700
    description: "Duration(msec) for hover search counter"
  hideTabBarOnMaximizePane:
    type: 'boolean'
    default: true
  smoothScrollOnFullScrollMotion:
    type: 'boolean'
    default: false
    description: "For `ctrl-f` and `ctrl-b`"
  smoothScrollOnFullScrollMotionDuration:
    type: 'integer'
    default: 500
    description: "For `ctrl-f` and `ctrl-b`"
  smoothScrollOnHalfScrollMotion:
    type: 'boolean'
    default: false
    description: "For `ctrl-d` and `ctrl-u`"
  smoothScrollOnHalfScrollMotionDuration:
    type: 'integer'
    default: 500
    description: "For `ctrl-d` and `ctrl-u`"
  throwErrorOnNonEmptySelectionInNormalMode:
    type: 'boolean'
    default: false
    description: "[Dev use] Throw error when non-empty selection was remained in normal-mode at the timing of operation finished"
