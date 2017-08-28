const {Disposable} = require("atom")

function inferType(value) {
  if (Number.isInteger(value)) return "integer"
  if (Array.isArray(value)) return "array"
  if (typeof value === "boolean") return "boolean"
  if (typeof value === "string") return "string"
}

const DEPRECATED_PARAMS = ["showCursorInVisualMode"]
const RENAMED_PARAMS = [
  {oldName: "keepColumnOnSelectTextObject", newName: "stayOnSelectTextObject"},
  {oldName: "moveToFirstCharacterOnVerticalMotion", newName: "stayOnVerticalMotion", invertValue: true},
]

class Settings {
  notifyDeprecatedParams() {
    const actualConfig = atom.config.get(this.scope)
    const deprecatedParams = DEPRECATED_PARAMS.filter(param => param in actualConfig)
    if (!deprecatedParams.length) return

    const message = `${this.scope}: Config options deprecated.  \nRemove from your \`connfig.cson\` now?  `
    for (const param of deprecatedParams) {
      message += `\n- \`${param}\``
    }

    const notification = atom.notifications.addWarning(message, {
      dismissable: true,
      buttons: [
        {
          text: "Remove All",
          onDidClick: () => {
            deprecatedParams.forEach(param => this.delete(param))
            notification.dismiss()
          },
        },
      ],
    })
  }

  migrateRenamedParams() {
    const messages = []

    for (const {oldName, newName, invertValue} of RENAMED_PARAMS) {
      const oldValue = this.get(oldName)
      if (oldValue != null) {
        const newValue = invertValue ? !oldValue : oldValue

        // Set only if newValue isnt default.
        if (this.get(newName) !== newValue) this.set(newName, newValue)
        this.delete(oldName)

        let s = `- |${oldName}| was renamed to |${newName}|`.replace(/\|/g, "`")
        if (invertValue) s += " with meaning **inverted**"
        messages.push(s)
      }
    }

    if (!messages.length) return

    const message = `${this.scope}: Config params are **renamed** and **auto-migrated**.\n${messages.join("\n")}`
    atom.notifications.addInfo(message, {dismissable: true})
  }

  constructor(scope, config) {
    // complement `type` field by inferring it from default value.
    // Also translate direct `boolean` value to {default: `boolean`} object
    this.scope = scope
    this.config = config

    const configNames = Object.keys(this.config)
    for (let i = 0; i < configNames.length; i++) {
      const name = configNames[i]
      let value = this.config[name]

      // Translate direct boolean to { defaultr: boolean } form
      if (typeof value === "boolean") {
        this.config[name] = value = {default: value}
      }

      if (!value.type) value.type = inferType(value.default)

      // Inject order to appear at setting-view in ordered.
      value.order = i
    }
  }

  delete(param) {
    return this.set(param, undefined)
  }

  get(param) {
    return atom.config.get(`${this.scope}.${param}`)
  }

  set(param, value) {
    return atom.config.set(`${this.scope}.${param}`, value)
  }

  toggle(param) {
    return this.set(param, !this.get(param))
  }

  observe(param, fn) {
    return atom.config.observe(`${this.scope}.${param}`, fn)
  }

  observeConditionalKeymaps() {
    const conditionalKeymaps = {
      keymapYToYankToLastCharacterOfLine: {
        "atom-text-editor.vim-mode-plus:not(.insert-mode)": {
          Y: "vim-mode-plus:yank-to-last-character-of-line",
        },
      },
      keymapUnderscoreToReplaceWithRegister: {
        "atom-text-editor.vim-mode-plus:not(.insert-mode)": {
          _: "vim-mode-plus:replace-with-register",
        },
      },
      keymapPToPutWithAutoIndent: {
        "atom-text-editor.vim-mode-plus:not(.insert-mode):not(.operator-pending-mode)": {
          P: "vim-mode-plus:put-before-with-auto-indent",
          p: "vim-mode-plus:put-after-with-auto-indent",
        },
      },
      keymapCCToChangeInnerSmartWord: {
        "atom-text-editor.vim-mode-plus.operator-pending-mode.change-pending": {
          c: "vim-mode-plus:inner-smart-word",
        },
      },
      keymapSemicolonToInnerAnyPairInOperatorPendingMode: {
        "atom-text-editor.vim-mode-plus.operator-pending-mode": {
          ";": "vim-mode-plus:inner-any-pair",
        },
      },
      keymapSemicolonToInnerAnyPairInVisualMode: {
        "atom-text-editor.vim-mode-plus.visual-mode": {
          ";": "vim-mode-plus:inner-any-pair",
        },
      },
      keymapBackslashToInnerCommentOrParagraphWhenToggleLineCommentsIsPending: {
        "atom-text-editor.vim-mode-plus.operator-pending-mode.toggle-line-comments-pending": {
          "/": "vim-mode-plus:inner-comment-or-paragraph",
        },
      },
    }

    const observeConditionalKeymap = param => {
      const keymapSource = `vim-mode-plus-conditional-keymap:${param}`
      const disposable = this.observe(param, function(newValue) {
        if (newValue) {
          return atom.keymaps.add(keymapSource, conditionalKeymaps[param])
        } else {
          return atom.keymaps.removeBindingsFromSource(keymapSource)
        }
      })

      return new Disposable(function() {
        disposable.dispose()
        atom.keymaps.removeBindingsFromSource(keymapSource)
      })
    }

    // Return disposalbes to dispose config observation and conditional keymap.
    return Object.keys(conditionalKeymaps).map(observeConditionalKeymap)
  }
}

module.exports = new Settings("vim-mode-plus", {
  keymapYToYankToLastCharacterOfLine: {
    title: "keymap `Y` to `yank-to-last-character-of-line`",
    default: false,
    description:
      "Can: `Y` behave as `y $` instead of default `y y`, This make `Y` consistent with `C`(works as `c $`) and `D`(works as `d $`).",
  },
  keymapUnderscoreToReplaceWithRegister: {
    title: "keymap `_` to `replace-with-register`",
    default: false,
    description:
      "Can: `_ i (` to replace `inner-parenthesis` with register's value<br>Can: `_ ;` to replace `inner-any-pair` if you enabled `keymapSemicolonToInnerAnyPairInOperatorPendingMode`<br>Conflicts: `_`( `move-to-first-character-of-line-and-down` ) motion(Who use this?).",
  },
  keymapPToPutWithAutoIndent: {
    title: "keymap `p` and `P` to `put-after-with-auto-indent` and `put-before-with-auto-indent`",
    default: false,
    description:
      "Remap `p` and `P` to auto indent version.<br>\n`p` remapped to `put-before-with-auto-indent` from original `put-before`<br>\n`P` remapped to `put-after-with-auto-indent` from original `put-after`<br>\nConflicts: Original `put-after` and `put-before` become unavailable unless you set different keymap by yourself.",
  },
  keymapCCToChangeInnerSmartWord: {
    title: "keymap `c c` to `change inner-smart-word`",
    default: false,
    description:
      "Can: `c c` to `change inner-smart-word`<br>\nConflicts: `c c`( change-current-line ), but you still can use `S` or `c i l` which is equivalent to original `c c`.",
  },
  keymapSemicolonToInnerAnyPairInOperatorPendingMode: {
    title: "keymap `;` to `inner-any-pair` in `operator-pending-mode`",
    default: false,
    description:
      "Can: `c ;` to `change inner-any-pair`.<br>Conflicts: `;`( `repeat-find` ). You cannot `;`( `repeat-find` ) in `operator-pending-mode`",
  },
  keymapSemicolonToInnerAnyPairInVisualMode: {
    title: "keymap `;` to `inner-any-pair` in `visual-mode`",
    default: false,
    description:
      "Can: `v ;` to `select inner-any-pair`.<br>Conflicts: `;`( `repeat-find` ). You cannot `;`(`repeat-find`) in `visual-mode`",
  },
  keymapBackslashToInnerCommentOrParagraphWhenToggleLineCommentsIsPending: {
    title: "keymap `g / /` to `toggle-line-comments for inner-comment-or-paragraph`",
    default: false,
    description:
      "Can: `g / /` to comment-in commented region, `g / /` to comment-out paragraph.<br>\nConflicts: `g / /`( `toggle-line-comments` by `search` motion )",
  },
  setCursorToStartOfChangeOnUndoRedo: true,
  setCursorToStartOfChangeOnUndoRedoStrategy: {
    default: "smart",
    enum: ["smart", "simple"],
    description:
      "When you think undo/redo cursor position has BUG, set this to `simple`.<br>\n`smart`: Good accuracy but have cursor-not-updated-on-different-editor limitation<br>\n`simple`: Always work, but accuracy is not as good as `smart`.<br>",
  },
  groupChangesWhenLeavingInsertMode: true,
  useClipboardAsDefaultRegister: true,
  dontUpdateRegisterOnChangeOrSubstitute: {
    default: false,
    description:
      "When set to `true` any `change` or `substitute` operation no longer update register content<br>\nAffects `c`, `C`, `s`, `S` operator.",
  },
  startInInsertMode: false,
  startInInsertModeScopes: {
    default: [],
    items: {type: "string"},
    description: "Start in insert-mode when editorElement matches scope",
  },
  clearMultipleCursorsOnEscapeInsertMode: false,
  autoSelectPersistentSelectionOnOperate: true,
  automaticallyEscapeInsertModeOnActivePaneItemChange: {
    default: false,
    description: "Escape insert-mode on tab switch, pane switch",
  },
  wrapLeftRightMotion: false,
  numberRegex: {
    default: "-?[0-9]+",
    description:
      "Used to find number in `ctrl-a` and `ctrl-x`.<br>\nTo ignore `-`( minus ) char within string like `identifier-1` use `(?:\\B-)?[0-9]+`",
  },
  clearHighlightSearchOnResetNormalMode: {
    default: true,
    description: "Clear highlight search on `escape` in normal-mode",
  },
  clearPersistentSelectionOnResetNormalMode: {
    default: true,
    description: "Clear persistent selection on `escape` in normal-mode",
  },
  charactersToAddSpaceOnSurround: {
    default: [],
    items: {type: "string"},
    description:
      "Comma separated list of character, which add space around surrounded text.<br>\nFor vim-surround compatible behavior, set `(, {, [, <`.",
  },
  ignoreCaseForSearch: {
    default: false,
    description: "For `/` and `?`",
  },
  useSmartcaseForSearch: {
    default: false,
    description: "For `/` and `?`. Override `ignoreCaseForSearch`",
  },
  ignoreCaseForSearchCurrentWord: {
    default: false,
    description: "For `*` and `#`.",
  },
  useSmartcaseForSearchCurrentWord: {
    default: false,
    description: "For `*` and `#`. Override `ignoreCaseForSearchCurrentWord`",
  },
  highlightSearch: true,
  highlightSearchExcludeScopes: {
    default: [],
    items: {type: "string"},
    description: "Suppress highlightSearch when any of these classes are present in the editor",
  },
  incrementalSearch: true,
  incrementalSearchVisitDirection: {
    default: "absolute",
    enum: ["absolute", "relative"],
    description: "When `relative`, `tab`, and `shift-tab` respect search direction('/' or '?')",
  },
  stayOnTransformString: {
    default: true,
    description: "Don't move cursor after TransformString e.g upper-case, surround",
  },
  stayOnYank: {
    default: true,
    description: "Don't move cursor after yank",
  },
  stayOnDelete: {
    default: true,
    description: "Don't move cursor after delete",
  },
  stayOnOccurrence: {
    default: true,
    description:
      "Don't move cursor when operator works on occurrences( when `true`, override operator specific `stayOn` options )",
  },
  stayOnSelectTextObject: {
    default: true,
    description:
      "Keep column on select TextObject( Paragraph, Indentation, Fold, Function, Edge ).<br>Affects when selecting text-object in `visual-mode` like `v i p`",
  },
  stayOnVerticalMotion: {
    default: true,
    description:
      "Almost equivalent to `startofline` pure-Vim option(but it's meaning is **inverted**). When false, move cursor to first char.<br>\nAffects to `ctrl-f`, `ctrl-b`, `ctrl-d`, `ctrl-u`, `G`, `H`, `M`, `L`, `g g`<br>\nUnlike pure-Vim, `d`, `<<`, `>>` are not affected by this option, use independent `stayOn` options.",
  },
  allowMoveToOffScreenColumnOnScreenLineMotion: {
    default: true,
    description:
      "Affects how `g 0`, `g ^` and `g $` find destination position<br>When a line is wider than the screen width( no-wrapped line )<br> - `false`: move to on-screen( visible ) column( Vim default )<br> - `true`: move to off-screen column of same screen-line",
  },
  flashOnUndoRedo: true,
  flashOnMoveToOccurrence: {
    default: false,
    description: "Affects normal-mode's `tab`, `shift-tab`.",
  },
  flashOnOperate: true,
  flashOnOperateBlacklist: {
    default: [],
    items: {type: "string"},
    description: 'Comma separated list of operator class name to disable flash<br>e.g. "Yank, AutoIndent"',
  },
  flashOnSearch: true,
  flashScreenOnSearchHasNoMatch: true,
  maxFoldableIndentLevel: {
    default: 20,
    minimum: 0,
    description: "Folds which startRow exceed this level are not folded on `z m` and `z M`",
  },
  showHoverSearchCounter: false,
  showHoverSearchCounterDuration: {
    default: 700,
    description: "Duration( msec ) for hover search counter",
  },
  hideTabBarOnMaximizePane: {
    default: true,
    description: "If set to `false`, tab still visible after maximize-pane( `cmd-enter` )",
  },
  hideStatusBarOnMaximizePane: {
    default: true,
  },
  centerPaneOnMaximizePane: {
    default: true,
    description:
      "Set to `false`, if you never need centering effect.<br>If you usually want centering but **occasionally** don't, leave this setting to `true` and use `vim-mode-plus:maximize-pane`( `cmd-enter` or `ctrl-w z` ) and `vim-mode-plus:maximize-pane-without-center`( `ctrl-w Z` ) command respectively.",
  },
  smoothScrollOnFullScrollMotion: {
    default: false,
    description: "For `ctrl-f` and `ctrl-b`",
  },
  smoothScrollOnFullScrollMotionDuration: {
    default: 500,
    description: "Smooth scroll duration( msec ) for `ctrl-f` and `ctrl-b`",
  },
  smoothScrollOnHalfScrollMotion: {
    default: false,
    description: "For `ctrl-d` and `ctrl-u`",
  },
  smoothScrollOnHalfScrollMotionDuration: {
    default: 500,
    description: "Smooth scroll duration( msec ) for `ctrl-d` and `ctrl-u`",
  },
  statusBarModeStringStyle: {
    default: "short",
    enum: ["short", "long"],
  },
  debug: {
    default: false,
    description: "[Dev use]",
  },
  strictAssertion: {
    default: false,
    description: "[Dev use] to catche wired state in vmp-dev, enable this if you want help me",
  },
})
