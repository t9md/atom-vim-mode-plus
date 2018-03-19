const {Disposable} = require('atom')

function inferType (value) {
  if (Number.isInteger(value)) return 'integer'
  if (Array.isArray(value)) return 'array'
  if (typeof value === 'boolean') return 'boolean'
  if (typeof value === 'string') return 'string'
}

const DEPRECATED_PARAMS = []
const FORCE_DELETE_PARAMS = ['showCursorInVisualMode', 'notifiedCoffeeScriptNoLongerSupportedToExtendVMP']

function invertValue (value) {
  return !value
}

const RENAMED_PARAMS = [
  {oldName: 'findByTwoChars', newName: 'findCharsMax', setValueBy: enabled => (enabled ? 2 : undefined)},
  {oldName: 'findByTwoCharsAutoConfirmTimeout', newName: 'findConfirmByTimeout'},
  {oldName: 'keepColumnOnSelectTextObject', newName: 'stayOnSelectTextObject'},
  {oldName: 'moveToFirstCharacterOnVerticalMotion', newName: 'stayOnVerticalMotion', setValueBy: invertValue},
  {oldName: 'keymapSemicolonToConfirmFind', newName: 'keymapSemicolonToConfirmOnFindInput'},
  {
    oldName: 'dontUpdateRegisterOnChangeOrSubstitute',
    newName: 'blackholeRegisteredOperators',
    setValueBy: enabled => (enabled ? ['change*', 'substitute*'] : undefined)
  }
]

class Settings {
  notifyDeprecatedParams () {
    const actualConfig = atom.config.get(this.scope)
    const deprecatedParams = DEPRECATED_PARAMS.filter(param => param in actualConfig)
    if (!deprecatedParams.length) return

    let message = `${this.scope}: Config options deprecated.  \nRemove from your \`connfig.cson\` now?  `
    for (const param of deprecatedParams) {
      message += `\n- \`${param}\``
    }

    const notification = atom.notifications.addWarning(message, {
      dismissable: true,
      buttons: [
        {
          text: 'Remove All',
          onDidClick: () => {
            deprecatedParams.forEach(param => this.delete(param))
            notification.dismiss()
          }
        }
      ]
    })
  }

  silentlyRemoveUnusedParams () {
    for (const param of FORCE_DELETE_PARAMS) {
      this.delete(param)
    }
  }

  migrateRenamedParams () {
    const messages = []

    for (const {oldName, newName, setValueBy} of RENAMED_PARAMS) {
      const oldValue = this.get(oldName)
      if (oldValue != null) {
        const newValue = setValueBy != null ? setValueBy(oldValue) : oldValue

        // Set only if newValue isnt default.
        if (newValue != null && this.get(newName) !== newValue) {
          this.set(newName, newValue)
        }
        this.delete(oldName)

        let s = `- |${oldName}| was renamed to |${newName}|`.replace(/\|/g, '`')
        if (setValueBy === invertValue) s += ' with meaning **inverted**'
        messages.push(s)
      }
    }

    if (!messages.length) return

    const message = `${this.scope}: Config params are **renamed** and **auto-migrated**.\n${messages.join('\n')}`
    atom.notifications.addInfo(message, {dismissable: true})
  }

  constructor (scope, config) {
    // complement `type` field by inferring it from default value.
    // Also translate direct `boolean` value to {default: `boolean`} object
    this.scope = scope
    this.config = config

    const configNames = Object.keys(this.config)
    for (let i = 0; i < configNames.length; i++) {
      const name = configNames[i]
      let value = this.config[name]

      // Translate direct boolean to { defaultr: boolean } form
      if (typeof value === 'boolean') {
        this.config[name] = value = {default: value}
      }

      if (!value.type) value.type = inferType(value.default)

      // Inject order to appear at setting-view in ordered.
      value.order = i
    }
  }

  delete (param) {
    return atom.config.unset(`${this.scope}.${param}`)
  }

  get (param) {
    return atom.config.get(`${this.scope}.${param}`)
  }

  set (param, value) {
    return atom.config.set(`${this.scope}.${param}`, value)
  }

  toggle (param) {
    return this.set(param, !this.get(param))
  }

  observe (param, fn) {
    return atom.config.observe(`${this.scope}.${param}`, fn)
  }

  onDidChange (param, fn) {
    return atom.config.onDidChange(`${this.scope}.${param}`, fn)
  }

  observeConditionalKeymaps () {
    const conditionalKeymaps = {
      keymapYToYankToLastCharacterOfLine: {
        'atom-text-editor.vim-mode-plus.normal-mode': {
          Y: 'vim-mode-plus:yank-to-last-character-of-line'
        }
      },
      keymapSToSelect: {
        'atom-text-editor.vim-mode-plus:not(.insert-mode)': {
          s: 'vim-mode-plus:select'
        }
      },
      keymapUnderscoreToReplaceWithRegister: {
        'atom-text-editor.vim-mode-plus:not(.insert-mode)': {
          _: 'vim-mode-plus:replace-with-register'
        }
      },
      keymapPToPutWithAutoIndent: {
        'atom-text-editor.vim-mode-plus:not(.insert-mode):not(.operator-pending-mode)': {
          P: 'vim-mode-plus:put-before-with-auto-indent',
          p: 'vim-mode-plus:put-after-with-auto-indent'
        }
      },
      keymapCCToChangeInnerSmartWord: {
        'atom-text-editor.vim-mode-plus.operator-pending-mode.change-pending': {
          c: 'vim-mode-plus:inner-smart-word'
        }
      },
      keymapSemicolonToInnerAnyPairInOperatorPendingMode: {
        'atom-text-editor.vim-mode-plus.operator-pending-mode': {
          ';': 'vim-mode-plus:inner-any-pair'
        }
      },
      keymapSemicolonToInnerAnyPairInVisualMode: {
        'atom-text-editor.vim-mode-plus.visual-mode': {
          ';': 'vim-mode-plus:inner-any-pair'
        }
      },
      keymapBackslashToInnerCommentOrParagraphWhenToggleLineCommentsIsPending: {
        'atom-text-editor.vim-mode-plus.operator-pending-mode.toggle-line-comments-pending': {
          '/': 'vim-mode-plus:inner-comment-or-paragraph'
        }
      },
      keymapSemicolonToConfirmOnFindInput: {
        'atom-text-editor.vim-mode-plus-input.find': {
          ';': 'core:confirm'
        }
      },
      keymapSemicolonAndCommaToFindPreConfirmedOnFindInput: {
        'atom-text-editor.vim-mode-plus-input.find.has-text': {
          ';': 'vim-mode-plus:find-next-pre-confirmed',
          ',': 'vim-mode-plus:find-previous-pre-confirmed'
        }
      },
      keymapIAndAToInsertAtTargetWhenHasOccurrence: {
        'atom-text-editor.vim-mode-plus.has-occurrence:not(.insert-mode)': {
          I: 'vim-mode-plus:insert-at-start-of-target',
          A: 'vim-mode-plus:insert-at-end-of-target'
        }
      }
    }

    const observeConditionalKeymap = param => {
      const keymapSource = `vim-mode-plus-conditional-keymap:${param}`
      const disposable = this.observe(param, function (newValue) {
        if (newValue) {
          return atom.keymaps.add(keymapSource, conditionalKeymaps[param])
        } else {
          return atom.keymaps.removeBindingsFromSource(keymapSource)
        }
      })

      return new Disposable(function () {
        disposable.dispose()
        atom.keymaps.removeBindingsFromSource(keymapSource)
      })
    }

    // Return disposalbes to dispose config observation and conditional keymap.
    return Object.keys(conditionalKeymaps).map(observeConditionalKeymap)
  }
}

module.exports = new Settings('vim-mode-plus', {
  keymapYToYankToLastCharacterOfLine: {
    title: 'keymap `Y` to `yank-to-last-character-of-line`',
    default: false,
    description:
      '[Can]: `Y` behave as `y $` instead of default `y y`, This make `Y` consistent with `C`(works as `c $`) and `D`(works as `d $`).'
  },
  keymapSToSelect: {
    title: 'keymap `s` to `select`',
    default: false,
    description:
      '[Can]: `s p` to select paragraph, `s o p` to select occurrence in paragraph.<br>[Conflicts]: `s`(`substitute`). Use `c l` or `x i` instead'
  },
  keymapUnderscoreToReplaceWithRegister: {
    title: 'keymap `_` to `replace-with-register`',
    default: false,
    description:
      "[Can]: `_ i (` to replace `inner-parenthesis` with register's value<br>[Can]: `_ ;` to replace `inner-any-pair` if you enabled `keymapSemicolonToInnerAnyPairInOperatorPendingMode`<br>[Conflicts]: `_`( `move-to-first-character-of-line-and-down` ) motion(Who use this?)."
  },
  keymapPToPutWithAutoIndent: {
    title: 'keymap `p` and `P` to `put-after-with-auto-indent` and `put-before-with-auto-indent`',
    default: false,
    description:
      'Remap `p` and `P` to auto indent version.<br>`p` remapped to `put-after-with-auto-indent` from original `put-after`<br>`P` remapped to `put-before-with-auto-indent` from original `put-before`<br>[Conflicts]: Original `put-after` and `put-before` become unavailable unless you set different keymap by yourself.'
  },
  keymapCCToChangeInnerSmartWord: {
    title: 'keymap `c c` to `change inner-smart-word`',
    default: false,
    description:
      '[Can]: `c c` to `change inner-smart-word`<br>[Conflicts]: `c c`( change-current-line ), but you still can use `S` or `c i l` which is equivalent to original `c c`.'
  },
  keymapSemicolonToInnerAnyPairInOperatorPendingMode: {
    title: 'keymap `;` to `inner-any-pair` in `operator-pending-mode`',
    default: false,
    description:
      '[Can]: `c ;` to `change inner-any-pair`.<br>[Conflicts]: `;`( `repeat-find` ). You cannot `;`( `repeat-find` ) in `operator-pending-mode`'
  },
  keymapSemicolonToInnerAnyPairInVisualMode: {
    title: 'keymap `;` to `inner-any-pair` in `visual-mode`',
    default: false,
    description:
      '[Can]: `v ;` to `select inner-any-pair`.<br>[Conflicts]: `;`( `repeat-find` ). You cannot `;`(`repeat-find`) in `visual-mode`'
  },
  keymapBackslashToInnerCommentOrParagraphWhenToggleLineCommentsIsPending: {
    title: 'keymap `g / /` to `toggle-line-comments for inner-comment-or-paragraph`',
    default: false,
    description:
      '[Can]: `g / /` to comment-in commented region, `g / /` to comment-out paragraph.<br>[Conflicts]: `g / /`( `toggle-line-comments` by `search` motion )'
  },
  keymapSemicolonToConfirmOnFindInput: {
    title: 'keymap `;` to confirm on `f` input',
    default: false,
    description:
      '[Can]: You can confirm find( `f` ) input by `;`.<br>e.g. `f a ;` instead of `f a enter`.<br>[Conflicts]: You cannot search `;` by `f`, `F`, `t` and `T`.'
  },
  keymapSemicolonAndCommaToFindPreConfirmedOnFindInput: {
    title:
      '[EXPERIMENTAL] keymap `;` and `,` to `find-next-pre-confirmed` and `find-previous-pre-confirmed` on `f` input',
    default: false,
    description:
      "[Can]: `f a ;` to move to 2nd `a`. `f a ; ;` to 3rd `a`. `f a ; ; ,` to 2nd `a`(two next(`;`), one previous(`,`))<br>Especially useful when you use `f` as operator's target such as `c f x`.<br>[Conflicts]: When enabled, `f ; ;` goes to 2nd `;`(not 1st double-semicolon(`;;`)), `f , ,` goes to 2nd single `,`(not 1st double-comma(`,,`))"
  },
  keymapIAndAToInsertAtTargetWhenHasOccurrence: {
    title:
      '[EXPERIMENTAL] keymap `I` and `A` to `insert-at-start-of-target` and `insert-at-end-of-target` when editor has `preset-occurrence` marker.',
    default: false,
    description:
      '[Can]: `I p`, `A p` to insert at start or end of `preset-occurrence` in paragraph(`p`).<br>`I` and `A` is operator which take target, you can combine it with any target like `I f`(`a-function`), `A z`(`a-fold`).<br>[Caution]: `I` and `A` behaves as operator as long as editor has `preset-occurrence`, even if there is no VISIBLE `preset-occurrence` in screen. You might want to `escape` to clear preset-occurrences on editor to make `I` and `A` behave normaly gain.<br>[Conflicts]: You cannot use normal `I` and `A` when `preset-occurrence` marker is exists.'
  },
  hideCommandsFromCommandPalette: {
    default: false,
    description:
      'Hide most commands(such as `j`(`vim-mode-plus:move-down`)) from command-palette. Require restart to make change take effect.'
  },
  autoDisableInputMethodWhenLeavingInsertMode: {
    default: false,
    description: '[Experimental] Automatically disable input method when leaving insert-mode'
  },
  setCursorToStartOfChangeOnUndoRedo: true,
  setCursorToStartOfChangeOnUndoRedoStrategy: {
    default: 'smart',
    enum: ['smart', 'simple'],
    description:
      'When you think undo/redo cursor position has BUG, set this to `simple`.<br>`smart`: Good accuracy but have cursor-not-updated-on-different-editor limitation<br>`simple`: Always work, but accuracy is not as good as `smart`.<br>'
  },
  groupChangesWhenLeavingInsertMode: true,
  useClipboardAsDefaultRegister: true,
  blackholeRegisteredOperators: {
    default: [],
    items: {type: 'string'},
    description:
      'Comma separated list of operator command name to disable register update.<br>e.g. `delete-right, delete-left, delete, substitute`<br>Also you can use special value(`delete*`, `change*`, `substitute*`) to specify all same-family operators.'
  },
  startInInsertMode: false,
  startInInsertModeScopes: {
    default: [],
    items: {type: 'string'},
    description: 'Start in insert-mode when editorElement matches scope'
  },
  clearMultipleCursorsOnEscapeInsertMode: false,
  autoSelectPersistentSelectionOnOperate: true,
  automaticallyEscapeInsertModeOnActivePaneItemChange: {
    default: false,
    description: 'Escape insert-mode on tab switch, pane switch'
  },
  wrapLeftRightMotion: false,
  useLanguageIndependentNonWordCharacters: {
    default: false,
    description:
      'Non word characters is used to detect **word** boundary which is normally based on current language mode(or grammar).<br>If you want to use **static** non word chars enable this.'
  },
  // Default value is copied from `DEFAULT_NON_WORD_CHARACTERS` in `text-editor.js`
  languageIndependentNonWordCharacters: {
    default: '/\\()"\':,.;<>~!@#$%^&*|+=[]{}`?-…',
    description: 'Used only when `useLanguageIndependentNonWordCharacters` was enabled'
  },
  numberRegex: {
    default: '-?[0-9]+',
    description:
      'Used to find number in `ctrl-a` and `ctrl-x`.<br>To ignore `-`( minus ) char within string like `identifier-1` use `(?:\\B-)?[0-9]+`'
  },
  clearHighlightSearchOnResetNormalMode: {
    default: true,
    description: 'Clear highlight search on `escape` in normal-mode'
  },
  clearPersistentSelectionOnResetNormalMode: {
    default: true,
    description: 'Clear persistent selection on `escape` in normal-mode'
  },
  replaceByDiffOnSurround: {
    default: false,
    description:
      '[EXPERIMENTAL] Replace only changed text by comparing old and new text, affects `surround`, `delete-surround`, `change-surround`'
  },
  charactersToAddSpaceOnSurround: {
    default: [],
    items: {type: 'string'},
    description:
      'Comma separated list of character, which add space around surrounded text.<br>For vim-surround compatible behavior, set `(, {, [, <`.'
  },
  sequentialPaste: {
    default: false,
    description:
      'When enabled `put-after`(`p`), `put-before`(`P`), and `replace-with-register` pop older register entry on each sequential execution<br>The sequential execution is activated if next execution is **whithin** 1seconds(flash is not yet disappar).'
  },
  sequentialPasteMaxHistory: {
    default: 3,
    minimum: 1
  },
  findCharsMax: {
    default: 1,
    minimum: 1,
    description:
      'Auto confirm when find( `f` )\'s input reaches this lenth.<br>Increasing this number greatly reduces the possible matches, but you now need confirm( `enter` ) for shorter input.<br><br>[Hint]: Set big number(such as `100`) with also enabling `findConfirmByTimeout`, then you **always** land(confirm) by timeout. Thus you now can expect **FIXED-TIMING-GAP** against your input(in "f > input > timeout > land" flow).<br><br>See also "keymap `;` to confirm `find` motion" configuration to make manual confirmation easy.'
  },
  findConfirmByTimeout: {
    default: 0,
    description:
      'Automatically confirm find( `f` ) when no input change happenend in timeout( msec )<br>Set `0` to disable.'
  },
  ignoreCaseForFind: {
    default: false,
    description: 'For `f`, `F`, `t`, and `T`'
  },
  useSmartcaseForFind: {
    default: false,
    description: 'For `f`, `F`, `t`, and `T`. Override `ignoreCaseForFind`'
  },
  highlightFindChar: {
    default: true,
    description: 'highlight finding char. Affects `f`, `F`, `t`, `T`'
  },
  reuseFindForRepeatFind: {
    default: false,
    description:
      'When enabled, can repeat last-find by `f` and `F`( backwards ), you still can use normal `,` and `;`.<br>e.g. `f a f` move cursor to 2nd `a`.<br>Affects to: `f`, `F`, `t`, `T`.'
  },
  findAcrossLines: {
    default: false,
    description: 'When enabled, `f` searches over next lines.<br>Affects `f`, `F`, `t`, `T`.'
  },
  ignoreCaseForSearch: {
    default: false,
    description: 'For `/` and `?`'
  },
  useSmartcaseForSearch: {
    default: false,
    description: 'For `/` and `?`. Override `ignoreCaseForSearch`'
  },
  ignoreCaseForSearchCurrentWord: {
    default: false,
    description: 'For `*` and `#`.'
  },
  useSmartcaseForSearchCurrentWord: {
    default: false,
    description: 'For `*` and `#`. Override `ignoreCaseForSearchCurrentWord`'
  },
  highlightSearch: true,
  highlightSearchExcludeScopes: {
    default: [],
    items: {type: 'string'},
    description: 'Suppress highlightSearch when any of these classes are present in the editor'
  },
  incrementalSearch: true,
  incrementalSearchVisitDirection: {
    default: 'absolute',
    enum: ['absolute', 'relative'],
    description: "When `relative`, `tab`, and `shift-tab` respect search direction('/' or '?')"
  },
  stayOnTransformString: {
    default: true,
    description: "Don't move cursor after TransformString e.g upper-case, surround"
  },
  stayOnYank: {
    default: true,
    description: "Don't move cursor after yank"
  },
  stayOnDelete: {
    default: true,
    description: "Don't move cursor after delete"
  },
  stayOnOccurrence: {
    default: true,
    description:
      "Don't move cursor when operator works on occurrences<br>When enabled, override operator specific `stayOn` options."
  },
  stayOnSelectTextObject: {
    default: true,
    description:
      'Keep column on select TextObject( Paragraph, Indentation, Fold, Function, Edge ).<br>Affects when selecting text-object in `visual-mode` like `v i p`'
  },
  stayOnVerticalMotion: {
    default: true,
    description:
      "Almost equivalent to `startofline` pure-Vim option(but it's meaning is **inverted**). When false, move cursor to first char.<br>Affects to `ctrl-f`, `ctrl-b`, `ctrl-d`, `ctrl-u`, `G`, `H`, `M`, `L`, `g g`<br>Unlike pure-Vim, `d`, `<<`, `>>` are not affected by this option, use independent `stayOn` options."
  },
  allowMoveToOffScreenColumnOnScreenLineMotion: {
    default: true,
    description:
      'Affects how `g 0`, `g ^` and `g $` find destination position<br>When a line is wider than the screen width( no-wrapped line )<br> - `false`: move to on-screen( visible ) column( Vim default )<br> - `true`: move to off-screen column of same screen-line'
  },
  flashOnUndoRedo: true,
  flashOnMoveToOccurrence: {
    default: true,
    description:
      'When preset-occurrence( `g o` ) is exist on editor, you can move between occurrences by `tab` and `shift-tab`<br>When enabled, flash occurrence under cursor after move'
  },
  flashOnOperate: true,
  flashOnOperateBlacklist: {
    default: [],
    items: {type: 'string'},
    description: 'Comma separated list of operator class name to disable flash<br>e.g. "Yank, AutoIndent"'
  },
  flashOnSearch: true,
  flashScreenOnSearchHasNoMatch: true,
  maxFoldableIndentLevel: {
    default: 20,
    minimum: 0,
    description: 'Folds which startRow exceed this level are not folded on `z m` and `z M`'
  },
  showHoverSearchCounter: false,
  showHoverSearchCounterDuration: {
    default: 700,
    description: 'Duration( msec ) for hover search counter'
  },
  hideTabBarOnMaximizePane: {
    default: true,
    description: 'If set to `false`, tab still visible after maximize-pane( `cmd-enter` )'
  },
  hideStatusBarOnMaximizePane: {
    default: true
  },
  centerPaneOnMaximizePane: {
    default: true,
    description:
      "Set to `false`, if you never need centering effect.<br>If you usually want centering but **occasionally** don't, leave this enabled and use `vim-mode-plus:maximize-pane`( `cmd-enter` or `ctrl-w z` ) and `vim-mode-plus:maximize-pane-without-center`( `ctrl-w Z` ) command respectively."
  },
  smoothScrollOnFullScrollMotion: {
    default: false,
    description: 'For `ctrl-f` and `ctrl-b`'
  },
  smoothScrollOnFullScrollMotionDuration: {
    default: 500,
    description: 'Smooth scroll duration( msec ) for `ctrl-f` and `ctrl-b`'
  },
  smoothScrollOnHalfScrollMotion: {
    default: false,
    description: 'For `ctrl-d` and `ctrl-u`'
  },
  smoothScrollOnHalfScrollMotionDuration: {
    default: 500,
    description: 'Smooth scroll duration( msec ) for `ctrl-d` and `ctrl-u`'
  },
  smoothScrollOnRedrawCursorLine: {
    default: false,
    description: 'For `z t`, `z enter`, `z u`, `z space`, `z z`, `z .`, `z b`, `z - `'
  },
  smoothScrollOnRedrawCursorLineDuration: {
    default: 300,
    description: 'Smooth scroll duration( msec ) for `z` beginning `redraw-cursor-line` command familiy'
  },
  smoothScrollOnMiniScroll: {
    default: false,
    description: 'For `ctrl-e` and `ctrl-y`'
  },
  smoothScrollOnMiniScrollDuration: {
    default: 200,
    description: 'Smooth scroll duration( msec ) for `ctrl-e` and `ctrl-y`'
  },
  defaultScrollRowsOnMiniScroll: {
    default: 1,
    description: 'Default amount of screen rows used in `ctrl-e` and `ctrl-y`'
  },
  statusBarModeStringStyle: {
    default: 'short',
    enum: ['short', 'long']
  },
  confirmThresholdOnOccurrenceOperation: {
    default: 2000,
    description:
      'When attempt to create occurrence-marker exceeding this threshold, vmp asks confirmation to continue<br>This is to prevent editor from freezing while creating tons of markers.<br>Affects: `g o` or `o` modifier(e.g. `c o p`)'
  },
  notifiedCoffeeScriptNoLongerSupportedToExtendVMP: {
    // TODO: Remove in future:(added at v1.19.0 release).
    default: false
  },
  debug: {
    default: false,
    description: '[Dev use]'
  },
  strictAssertion: {
    default: false,
    description: '[Dev use] to catche wired state in vmp-dev, enable this if you want help me'
  }
})
