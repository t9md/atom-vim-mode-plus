inferType = (value) ->
  switch
    when Number.isInteger(value) then 'integer'
    when typeof(value) is 'boolean' then 'boolean'
    when typeof(value) is 'string' then 'string'
    when Array.isArray(value) then 'array'

class Settings
  constructor: (@scope, @config) ->
    # Automatically infer and inject `type` of each config parameter.
    # skip if value which aleady have `type` field.
    # Also translate bare `boolean` value to {default: `boolean`} object
    for key in Object.keys(@config)
      if typeof(@config[key]) is 'boolean'
        @config[key] = {default: @config[key]}
      unless (value = @config[key]).type?
        value.type = inferType(value.default)

    # [CAUTION] injecting order propety to set order shown at setting-view MUST-COME-LAST.
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
  setCursorToStartOfChangeOnUndoRedo: true
  setCursorToStartOfChangeOnUndoRedoStrategy:
    default: 'smart'
    enum: ['smart', 'simple']
    description: """
    When you think undo/redo cursor position has BUG, set this to `simple`.<br>
    `smart`: Good accuracy but have cursor-not-updated-on-different-editor limitation<br>
    `simple`: Always work, but accuracy is not as good as `smart`.<br>
    """
  groupChangesWhenLeavingInsertMode: true
  useClipboardAsDefaultRegister: false
  startInInsertMode: false
  startInInsertModeScopes:
    default: []
    items: type: 'string'
    description: 'Start in insert-mode when editorElement matches scope'
  clearMultipleCursorsOnEscapeInsertMode: false
  autoSelectPersistentSelectionOnOperate: true
  automaticallyEscapeInsertModeOnActivePaneItemChange:
    default: false
    description: 'Escape insert-mode on tab switch, pane switch'
  wrapLeftRightMotion: false
  numberRegex:
    default: '-?[0-9]+'
    description: """
      Used to find number in ctrl-a/ctrl-x.<br>
      To ignore "-"(minus) char in string like "identifier-1" use `(?:\\B-)?[0-9]+`
      """
  clearHighlightSearchOnResetNormalMode:
    default: false
    description: 'Clear highlightSearch on `escape` in normal-mode'
  clearPersistentSelectionOnResetNormalMode:
    default: false
    description: 'Clear persistentSelection on `escape` in normal-mode'
  charactersToAddSpaceOnSurround:
    default: []
    items: type: 'string'
    description: """
      Comma separated list of character, which add space around surrounded text.<br>
      For vim-surround compatible behavior, set `(, {, [, <`.
      """
  showCursorInVisualMode: true
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
  highlightSearch: false
  highlightSearchExcludeScopes:
    default: []
    items: type: 'string'
    description: 'Suppress highlightSearch when any of these classes are present in the editor'
  incrementalSearch: false
  incrementalSearchVisitDirection:
    default: 'absolute'
    enum: ['absolute', 'relative']
    description: "When `relative`, `tab`, and `shift-tab` respect search direction('/' or '?')"
  stayOnTransformString:
    default: false
    description: "Don't move cursor after TransformString e.g upper-case, surround"
  stayOnYank:
    default: false
    description: "Don't move cursor after yank"
  stayOnDelete:
    default: false
    description: "Don't move cursor after delete"
  stayOnOccurrence:
    default: true
    description: "Don't move cursor when operator works on occurrences( when `true`, override operator specific `stayOn` options )"
  keepColumnOnSelectTextObject:
    default: false
    description: "Keep column on select TextObject(Paragraph, Indentation, Fold, Function, Edge)"
  moveToFirstCharacterOnVerticalMotion:
    default: true
    description: """
      Almost equivalent to `startofline` pure-Vim option. When true, move cursor to first char.<br>
      Affects to `ctrl-f, b, d, u`, `G`, `H`, `M`, `L`, `gg`<br>
      Unlike pure-Vim, `d`, `<<`, `>>` are not affected by this option, use independent `stayOn` options.
      """
  flashOnUndoRedo: true
  flashOnMoveToOccurrence:
    default: false
    description: "Affects normal-mode's `tab`, `shift-tab`."
  flashOnOperate: true
  flashOnOperateBlacklist:
    default: []
    items: type: 'string'
    description: 'Comma separated list of operator class name to disable flash e.g. "yank, auto-indent"'
  flashOnSearch: true
  flashScreenOnSearchHasNoMatch: true
  showHoverSearchCounter: false
  showHoverSearchCounterDuration:
    default: 700
    description: "Duration(msec) for hover search counter"
  hideTabBarOnMaximizePane:
    default: true
    description: "If set to `false`, tab still visible after maximize-pane( `cmd-enter` )"
  hideStatusBarOnMaximizePane:
    default: true
  smoothScrollOnFullScrollMotion:
    default: false
    description: "For `ctrl-f` and `ctrl-b`"
  smoothScrollOnFullScrollMotionDuration:
    default: 500
    description: "Smooth scroll duration in milliseconds for `ctrl-f` and `ctrl-b`"
  smoothScrollOnHalfScrollMotion:
    default: false
    description: "For `ctrl-d` and `ctrl-u`"
  smoothScrollOnHalfScrollMotionDuration:
    default: 500
    description: "Smooth scroll duration in milliseconds for `ctrl-d` and `ctrl-u`"
  statusBarModeStringStyle:
    default: 'short'
    enum: ['short', 'long']
  devThrowErrorOnNonEmptySelectionInNormalMode:
    default: false
    description: "[Dev use] Throw error when non-empty selection was remained in normal-mode at the timing of operation finished"
  debug:
    default: false
