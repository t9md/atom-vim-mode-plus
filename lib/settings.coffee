class Settings
  constructor: (@scope, @config) ->
    # Inject order props to display orderd in setting-view
    for name, i in Object.keys(@config)
      @config[name].order = i

    # Automatically infer and inject `type` of each config parameter.
    for key, object of @config
      object.type = switch
        when Number.isInteger(object.default) then 'integer'
        when typeof(object.default) is 'boolean' then 'boolean'
        when typeof(object.default) is 'string' then 'string'
        when Array.isArray(object.default) then 'array'

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
    default: true
  groupChangesWhenLeavingInsertMode:
    default: true
  useClipboardAsDefaultRegister:
    default: false
  startInInsertMode:
    default: false
  startInInsertModeScopes:
    default: []
    items: type: 'string'
    description: 'Start in insert-mode whan editorElement matches scope'
  clearMultipleCursorsOnEscapeInsertMode:
    default: false
  autoSelectPersistentSelectionOnOperate:
    default: true
  wrapLeftRightMotion:
    default: false
  numberRegex:
    default: '-?[0-9]+'
    description: 'Used to find number in ctrl-a/ctrl-x. To ignore "-"(minus) char in string like "identifier-1" use "(?:\\B-)?[0-9]+"'
  clearHighlightSearchOnResetNormalMode:
    default: false
    description: 'Clear highlightSearch on `escape` in normal-mode'
  clearPersistentSelectionOnResetNormalMode:
    default: false
    description: 'Clear persistentSelection on `escape` in normal-mode'
  charactersToAddSpaceOnSurround:
    default: []
    items: type: 'string'
    description: 'Comma separated list of character, which add additional space inside when surround.'
  showCursorInVisualMode:
    default: true
  ignoreCaseForSearch:
    default: false
    description: 'For `/` and `?`'
  useSmartcaseForSearch:
    default: false
    description: 'For `/` and `?`. Override `ignoreCaseForSearch`'
  ignoreCaseForSearchCurrentWord:
    default: false
    description: 'For `*` and `#`.'
  useSmartcaseForSearchCurrentWord:
    default: false
    description: 'For `*` and `#`. Override `ignoreCaseForSearchCurrentWord`'
  highlightSearch:
    default: false
  highlightSearchExcludeScopes:
    default: []
    items: type: 'string'
    description: 'Suppress highlightSearch when any of these classes are present in the editor'
  incrementalSearch:
    default: false
  incrementalSearchVisitDirection:
    default: 'absolute'
    enum: ['absolute', 'relative']
    description: "Whether 'visit-next'(tab) and 'visit-prev'(shift-tab) depends on search direction('/' or '?')"
  stayOnTransformString:
    default: false
    description: "Don't move cursor after TransformString e.g Toggle, Surround"
  stayOnYank:
    default: false
    description: "Don't move cursor after Yank"
  stayOnDelete:
    default: false
    description: "Don't move cursor after Delete"
  flashOnUndoRedo:
    default: true
  flashOnUndoRedoDuration:
    default: 100
    description: "Duration(msec) for flash"
  flashOnOperate:
    default: true
  flashOnOperateDuration:
    default: 100
    description: "Duration(msec) for flash"
  flashOnOperateBlacklist:
    default: []
    items: type: 'string'
    description: 'comma separated list of operator class name to disable flash e.g. "Yank, AutoIndent"'
  flashOnSearch:
    default: true
  flashOnSearchDuration:
    default: 300
    description: "Duration(msec) for search flash"
  flashScreenOnSearchHasNoMatch:
    default: true
  showHoverOnOperate:
    default: false
    description: "Show count, register and optional icon on hover overlay"
  showHoverOnOperateIcon:
    default: 'icon'
    enum: ['none', 'icon', 'emoji']
  showHoverSearchCounter:
    default: false
  showHoverSearchCounterDuration:
    default: 700
    description: "Duration(msec) for hover search counter"
  hideTabBarOnMaximizePane:
    default: true
  smoothScrollOnFullScrollMotion:
    default: false
    description: "For `ctrl-f` and `ctrl-b`"
  smoothScrollOnFullScrollMotionDuration:
    default: 500
    description: "For `ctrl-f` and `ctrl-b`"
  smoothScrollOnHalfScrollMotion:
    default: false
    description: "For `ctrl-d` and `ctrl-u`"
  smoothScrollOnHalfScrollMotionDuration:
    default: 500
    description: "For `ctrl-d` and `ctrl-u`"
  statusBarModeStringStyle:
    default: 'short'
    enum: ['short', 'long']
  throwErrorOnNonEmptySelectionInNormalMode:
    default: false
    description: "[Dev use] Throw error when non-empty selection was remained in normal-mode at the timing of operation finished"
