{Disposable} = require 'atom'

inferType = (value) ->
  switch
    when Number.isInteger(value) then 'integer'
    when typeof(value) is 'boolean' then 'boolean'
    when typeof(value) is 'string' then 'string'
    when Array.isArray(value) then 'array'

class Settings
  deprecatedParams: [
    'showCursorInVisualMode'
  ]
  notifyDeprecatedParams: ->
    deprecatedParams = @deprecatedParams.filter((param) => @has(param))
    return if deprecatedParams.length is 0

    content = [
      "#{@scope}: Config options deprecated.  ",
      "Remove from your `connfig.cson` now?  "
    ]
    content.push "- `#{param}`" for param in deprecatedParams

    notification = atom.notifications.addWarning content.join("\n"),
      dismissable: true
      buttons: [
        {
          text: 'Remove All'
          onDidClick: =>
            @delete(param) for param in deprecatedParams
            notification.dismiss()
        }
      ]

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

  has: (param) ->
    param of atom.config.get(@scope)

  delete: (param) ->
    @set(param, undefined)

  get: (param) ->
    atom.config.get("#{@scope}.#{param}")

  set: (param, value) ->
    atom.config.set("#{@scope}.#{param}", value)

  toggle: (param) ->
    @set(param, not @get(param))

  observe: (param, fn) ->
    atom.config.observe("#{@scope}.#{param}", fn)

  observeConditionalKeymaps: ->
    conditionalKeymaps =
      keymapUnderscoreToReplaceWithRegister:
        'atom-text-editor.vim-mode-plus:not(.insert-mode)':
          '_': 'vim-mode-plus:replace-with-register'
      keymapPToPutWithAutoIndent:
        'atom-text-editor.vim-mode-plus:not(.insert-mode):not(.operator-pending-mode)':
          'P': 'vim-mode-plus:put-before-with-auto-indent'
          'p': 'vim-mode-plus:put-after-with-auto-indent'
      keymapCCToChangeInnerSmartWord:
        'atom-text-editor.vim-mode-plus.operator-pending-mode.change-pending':
          'c': 'vim-mode-plus:inner-smart-word'
      keymapSemicolonToInnerAnyPairInOperatorPendingMode:
        'atom-text-editor.vim-mode-plus.operator-pending-mode':
          ';': 'vim-mode-plus:inner-any-pair'
      keymapSemicolonToInnerAnyPairInVisualMode:
        'atom-text-editor.vim-mode-plus.visual-mode':
          ';': 'vim-mode-plus:inner-any-pair'
      keymapBackslashToInnerCommentOrParagraphWhenToggleLineCommentsIsPending:
        'atom-text-editor.vim-mode-plus.operator-pending-mode.toggle-line-comments-pending':
          '/': 'vim-mode-plus:inner-comment-or-paragraph'

    observeConditionalKeymap = (param) =>
      keymapSource = "vim-mode-plus-conditional-keymap:#{param}"
      disposable = @observe param, (newValue) ->
        if newValue
          atom.keymaps.add(keymapSource, conditionalKeymaps[param])
        else
          atom.keymaps.removeBindingsFromSource(keymapSource)

      new Disposable ->
        disposable.dispose()
        atom.keymaps.removeBindingsFromSource(keymapSource)

    # Return disposalbes to dispose config observation and conditional keymap.
    return Object.keys(conditionalKeymaps).map (param) -> observeConditionalKeymap(param)

module.exports = new Settings 'vim-mode-plus',
  keymapUnderscoreToReplaceWithRegister:
    default: false
    description: """
    Can: `_ i (` to replace inner-parenthesis with register's value<br>
    Can: `_ ;` to replace inner-any-pair if you enabled `keymapSemicolonToInnerAnyPairInOperatorPendingMode`<br>
    Conflicts: `_`( `move-to-first-character-of-line-and-down` ) motion. Who use this??
    """
  keymapPToPutWithAutoIndent:
    default: false
    description: """
    Remap `p` and `P` to auto indent version.<br>
    `p` remapped to `put-before-with-auto-indent` from original `put-before`<br>
    `P` remapped to `put-after-with-auto-indent` from original `put-after`<br>
    Conflicts: Original `put-after` and `put-before` become unavailable unless you set different keymap by yourself.
    """
  keymapCCToChangeInnerSmartWord:
    default: false
    description: """
    Can: `c c` to `change inner-smart-word`<br>
    Conflicts: `c c`( change-current-line ) keystroke which is equivalent to `S` or `c i l` etc.
    """
  keymapSemicolonToInnerAnyPairInOperatorPendingMode:
    default: false
    description: """
    Can: `c ;` to `change inner-any-pair`, Conflicts with original `;`( `repeat-find` ) motion.<br>
    Conflicts: `;`( `repeat-find` ).
    """
  keymapSemicolonToInnerAnyPairInVisualMode:
    default: false
    description: """
    Can: `v ;` to `select inner-any-pair`, Conflicts with original `;`( `repeat-find` ) motion.<br>L
    Conflicts: `;`( `repeat-find` ).
    """
  keymapBackslashToInnerCommentOrParagraphWhenToggleLineCommentsIsPending:
    default: false
    description: """
    Can: `g / /` to comment-in already commented region, `g / /` to comment-out paragraph.<br>
    Conflicts: `/`( `search` ) motion only when `g /` is pending. you no longe can `g /` with search.
    """
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
  useClipboardAsDefaultRegister: true
  dontUpdateRegisterOnChangeOrSubstitute:
    default: false
    description: """
    When set to `true` any `change` or `substitute` operation no longer update register content<br>
    Affects `c`, `C`, `s`, `S` operator.
    """
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
    default: true
    description: 'Clear highlightSearch on `escape` in normal-mode'
  clearPersistentSelectionOnResetNormalMode:
    default: true
    description: 'Clear persistentSelection on `escape` in normal-mode'
  charactersToAddSpaceOnSurround:
    default: []
    items: type: 'string'
    description: """
      Comma separated list of character, which add space around surrounded text.<br>
      For vim-surround compatible behavior, set `(, {, [, <`.
      """
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
  highlightSearch: true
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
  maxFoldableIndentLevel:
    default: 20
    minimum: 0
    description: 'Folds which startRow exceed this level are not folded on `zm` and `zM`'
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
  debug:
    default: false
    description: "[Dev use]"
  strictAssertion:
    default: false
    description: "[Dev use] to catche wired state in vmp-dev, enable this if you want help me"
