# 0.97.2:
- Fix: Clicking find-and-replace's project-find result view throw exception when `projectSearchResultsPaneSplitDirection` set to `none`(default). #830.
  - Because, it opens matched entry on **same pane** and fire `mouseup` only(without preceeding `mousedown` event) on newly opened editor.
  - Now vmp guard wired mouse-event by explicitly manage next expecting mouse-event.

# 0.97.1:
- Fix: When `startInInsertMode` was `true` clicking editor in `insert-mode` throw exception but no longer. #830.

# 0.97.0:
- Maintenance: Rewrite big amount of part from CoffeScript to JavaScript.
  - Spec files are not re-written yet(and no plan at this point).
  - Now files under lib/ directory are 29(JavaScript) vs 9(CoffeScript).
  - Rewritten is done in following processare
    - 1. Translate by decaffeinate command provided by decaffeinate project(thanks!).
    - 2. Manual cleanup.
  - Sorry If I create some regression.
- Improve: Hide mode-string in status-bar while non-editor-item become active item(e.g. settings-view).
- Breaking: Rename and change behavior of `vim-mode-plus:clear-persistent-selection` to `vim-mode-plus:clear-persistent-selections`.
  - How?
    - Old: clear persistent selections for all editors in workspace.
    - New: clear persistent selections for current active editor.
  - Why I changed
    - Old behavior is inconsistent with other similar command.
    - I couldn't imagine practical scenario where old behavior shines.
- Improve: `maximize-pane` #828, #829
  - New: Config option `centerPaneOnMaximizePane` ( default `true` ). by @dcalhoun
    - Old behavior: Text in editor is always centered.
    - New behavior: Text in editor is centered if `centerPaneOnMaximizePane` is `true`.
  - New: Command `vim-mode-plus:maximize-pane-without-center`(default keymap: `ctrl-w Z`).
  - Confusing?
    - If you never need centering effect, set `centerPaneOnMaximizePane` to `false` and use `vim-mode-plus:maximize-pane` command.
    - If you sometime want to centering, but sometime don't want centering
      - Leave `centerPaneOnMaximizePane` to `true`( default )
      - Use `maximize-pane`(`cmd-enter` or `ctrl-w z`) and `maximize-pane-without-center`(`ctrl-w Z`) command respectively."
- Internal, Dev, Breaking: Remove introspection report generating command, which was important in early phase of vmp, but no longer.
- Dev: `write-command-table` no longer throw exception on first use after restart.
- Tweak: Change normal operator flash duration from 0.3s to 0.5s.
- Improve: Mouse #826
  - Fix: click in `visual.blockwise` mode no longer move cursor to first line of editor.
  - Now mouse action appropriately modify selection and enter `visual-mode` if necessary.
    - `shift-click`
    - `click`(mousedown -> mouseup)
    - `drag`(mousedown -> mousemove -> mouseup).
    - double click: Atom select clicked word, vmp update visual-mode.
    - triple click: Atom select clicked row, vmp update visual-mode.

# 0.96.2:
- Improve: #819 TextObject function for `language-rust` now also works on Windows platform.

- Fix: `g q q` now work again. `g w w` also work now.
# 0.96.1:
- Fix: `g q q` now work again. `g w w` also work now.

# 0.96.0:
- New, Breaking: Operator `reflow-with-stay`. #818
  - `reflow-with-stay` is `g q` equivalent feature. but unlike `g q`, `g w` keep cursor at same position.
  - It auto-format each lines to fit with `editor.preferredLineLength`.
  - Breaking: Existing command for `g q` was `auto-flow`, but renamed to `reflow` at this timing.
  - If you enabled, `stayOnTransformString` config, `g q` and `g w` behave exactly same way.
- Improve: #819 TextObject function now work for both `language-rust` and `atom-language-rust`.

# 0.95.0:
- New: Pane manipulation commands `ctrl-w H`, `ctrl-w J`, `ctrl-w K`, `ctrl-w L`.
  - These feature are merged from my `paner` package.
  - Following keymaps are provided in `atom-workspace` scope.
    - `ctrl-w ctrl-x` or `ctrl-w x`: `vim-mode-plus:exchange-pane`
    - `ctrl-w K`: `vim-mode-plus:move-pane-to-very-top`
    - `ctrl-w J`: `vim-mode-plus:move-pane-to-very-bottom`
    - `ctrl-w H`: `vim-mode-plus:move-pane-to-very-left`
    - `ctrl-w L`: `vim-mode-plus:move-pane-to-very-right`
- Fix: No longer throw exception when accessing unsupported register via `insert-mode`'s `ctrl-r`(`insert-mode`) #812.
- Support: set minimum engines to `1.18.0`.

# 0.94.0:
- Improve: Improve Fold handling in several operations. #809.
  - `y y`, `d d` now yank/delete whole fold.
  - `o` now start insertion from *next* line of end-of-fold(OLD-ver was next line of start-of-fold).
  - `V` on folded row select whole fold, so `V d` delete multiple lines which was folded.
    - No longer show cursor at incorrect row when `V` on folded row(long lived cosmetic issue now FIXED).
  - `p` on folded row paste *next* line of end-of-fold(OLD-ver was next line of start-of-fold).
- New: Add several Fold manipulation commands. #807
  - Commands:
    - `z c`: `fold-current-row`
    - `z C`: `fold-current-row-recursively`
    - `z o`: `unfold-current-row`
    - `z O`: `unfold-current-row-recursively`
    - `z a`: `toggle-fold`
    - `z A`: `toggle-fold-recursively`
  - Previously `z c`, `z o` was mapped to following Atom's native fold commands. But now replaced with `vmp`'s one.
  - Why? for consistency, and vmp's one is multi-cursor aware, linewise selection aware(not manipulate next line of selected row).
    - `z c`: `editor:fold-current-row`
    - `z o`: `editor:unfold-current-row`
- Improve, Experimental: Hide, left/right dock when `maximized-pane`.
- Improve: Disable `maximized-pane` keymap(`cmd-enter`) in `tree-view` scope.
- Keymap, Breaking: Remove default `ctrl-v` keymap in search-mini-editor to avoid conflicts. #791
  - Previous version have following keymap(was experimental, you can recover this by set manually).
    - scope: `atom-text-editor.vim-mode-plus-search`
    - keystroke: `ctrl-v` to `vim-mode-plus:search-activate-literal-mode`
- Fix: Protect from `p` throw exception in some uncertain situation `p` #802.
- Fix: [Atom-v1.19-beta] Smooth scroll now work again.
  - This issue is introduced by the big change in editor-rendering rewrite in v1.19.
- Fix: [Atom-v1.19-beta], `ctrl-y` on first line of editor incorrectly mutate that row(do nothing is correct behavior) #808
- Fix: [Atom-v1.19-beta] `ctrl-y`, `ctrl-e` now correctly use 2 lines offset.
- Keymap: Make numpad0-9 behave same way as normal 0-9 key #806
- Improve?, Breaking: Remove angle-bracket(<,>) matching for `%` motion. refs #700
  - Still work in progress to improve behavior.
- Spec: Fix spec failure in v1.19.0-beta.

# 0.93.0:
- New: `count` support for `g t` to activate Nth pane item(= tab).
  - `3 g t` activate 3rd pane item.
  - `7 g t` activate 7th pane item.
  - `g t` just activate next pane items as previous version.
  - When specified pane items was not exist, do nothing.
  - Limitation: vim-mode-plus's command only works on normal text-editor.
    - You can not do `g t` on non editor pane Item such as `setting-view`.
- Fix: #766 executing `maximize-pane` on single-pane workspace make screen blank.
  - This was happening only when pane have not yet split once after atom launch.
- Fix: #777 `J` at last buffer row no longer clear text.
- Doc: mention ex-mode link on README.md since it's now support vim-mode-plus.

# 0.92.1:
- Improve: #782 Skip creating marker/decoration for empty range in hlsearch and incsearch.
  - E.g.
    - When user searched `()` literally, it matches empty-range between each char.
    - In previous release, invisible hlsearch/incsearch marker/decoration was created.
    - By skipping this empty range highlight, improve responsiveness when user repeat `n` or `N` for that search.

# 0.92.0:
- Fix: blockwise-selection was not cleared correctly in some situation(but I noticed via code review)
- Fix: #780 No longer throw exception when close editor in the middle of smooth scrolling.
- New: #770, #774 Add fold manipulation commands based on PR by @weihanglo.
  - Commands: Put non-NEW commands here for thoroughness.
    - `z a`: `toggle-fold`, toggle( fold or unfold ) cursor's fold.( NEW )
    - `z r`: `unfold-next-indent-level`, unfold deepest folded fold. support count.( NEW )
    - `z m`: `fold-next-indent-level`, fold deepest unfolded fold. support count.( NEW )
    - `z M`: `fold-all`, unfold all fold.( not NEW )
    - `z R`: `unfold-all`, fold all fold.( not NEW )
  - Setting: `maxFoldableIndentLevel`( default `20` )
    - Folds which startRow exceeds this level are not folded on `zm` and `zM`
    - e.g.
      - If you have 3 folds in editor, each fold starts following indentLevel.
        - `fold-a: 0`
        - `fold-b: 1`
        - `fold-c: 2`
      - `maxFoldableIndentLevel = 20`:
        - `z M` fold all
        - `z m` fold `fold-c`, `fold-b`, `fold-a` on each time.
      - `maxFoldableIndentLevel = 1`:
        - `z M` fold `fold-a`
        - `z m` fold `fold-b`, `fold-a` on each time.
      - `maxFoldableIndentLevel = 0`:
        - `z M` fold `fold-a` only.
        - `z m` fold `fold-a`.
  - Implementation is NOT exactly same as pure-Vim.
    - Pure-vim: explicitly manage `foldlevel` value and `zm`, `zr` is done based on `foldlevel` kept.
    - vmp: Does not manage `foldlevel` explicitly, instead it detect fold state from editor.
      - This approach gives better compatibility for Atom's native fold commands like `cmd-k cmd-1`
- Improve: Don't auto-load `vimState.highlightSearch` when nothing to highlight.
- Internal: #768 Support upcoming new decoration `type: 'cursor'` for cursor visibility in visual-mode.
- Internal: #763 add spec for ensure minimum required file on vmp startup.

# 0.91.0:
- Improve, Performance: Reduce amount of IO( number of files to read ) on startup further. #760
  - Avoid require on initial package activation. Especially following widely-used libs is not longer `require`d on startup.
    - `lib/selection-wrapper.coffee`
    - `lib/utils.coffee`
    - `underscore-plus`
  - Now `swrap` and `utils` are accessible via lazy-prop( `vimState.utils` and `vimState.swrap` ).
- Developer: When `debug` setting was set to `true`, log lazy-require info when atom `inDevMode`.

# 0.90.2:
- Fix: For `search` on initial active-editor after startup, `highlightSearch` did not happened.
  - This is regression introduced as part of lazy instantiation of `HighlightSearchManager`.

# 0.90.1:
- Fix: Sorry, removed leftover `console.log` in atom running in dev mode.

# 0.90.0:
- Improve: Reduce activation time of vim-mode-plus to reduce your frustration on Atom startup. #758
  - About 2x faster activation time( Full detail is on #758 ).
  - With Two technique
    - Define all vmp-command from pre-populated command-table and lazy-require necessary command file on execution.
    - Defer instantiation of xxxManager referred by `vimState`.
      - E.g. `vimState.highlightSearch` is instance of `HighlightSearchManager` and it's now set on-demand.
  - [For vmp developer only] If command signature was changed, need update command-table.
    - Command signature it's name and scope(e.g. `vim-mode-plus:move-down` and `atom-text-editor` )
    - [Caution] `write-command-table-on-disk` command is available only when atom running in dev-mode.
    - [Caution] Directly update `lib/command-table.coffee` if populated-table was changed from loaded one.
- New, Breaking: Default keymap update #753
  - macOS user only
    - `ctrl-s` mapped to `transform-string-by-select-list` in `normal-mode` and `visual-mode`
  - All user
    - `z` in `operator-pending` is short hand of `a z`(`a-fold`).
      - You can do `y z` instead of `y a z`. E.g. When you yank foldable whole `if` block.
      - You can do `c z` instead of `c a z`. E.g. When you change foldable whole `if` block.
    - `g r` mapped to `reverse`
    - `g s` mapped to `sort`
    - `g c` mapped to `select-latest-change` which correspond to `g v` ( `select-previous-selection` )
    - `g C` mapped to `camel-case`
  - What was broken?
    Before: `g c` was for `camel-case`, `g C` was for `pascal-case`.
    Now: `g c` is for `select-latest-change`, `g C` is for `camel-case`. No default `pascal-case`.
- New: Target alias for surround #751, #755
  - Now `b`, `B`, `r`, `a` char is aliased to corresponding target.
    - `b` is alias for `(` or `)`
    - `B` is alias for `{` or `}`
    - `r` is alias for `[` or `]`
    - `a` is alias for `<` or `>`( I don't like this, just followed how `surround.vim` is doing ).
  - These alias can be used in `surround`, `delete-surround`, `change-surround`.
    - When have these keymap: `surround`( `y s` ), `delete-surround`( `d s` ), `change-surround`(`c s`)
      - `y s i w b` is equals to `y s i w (`.
      - `y s i w B` is equals to `y s i w {`
      - `y s i w r` is equals to `y s i w [`
      - `y s i w a` is equals to `y s i w <`
- New: InnerPair pre-targeted `rotate` command
  - Commands:
    - `rotate-arguments-of-inner-pair`
    - `rotate-arguments-backwards-of-inner-pair`
  - No keymap by default.
  - E.g.
    - When you map `g >` to `rotate-arguments-of-inner-pair` and `g <` to `backwards`
    - You can rotate arg of parenthesis by `g >` and `.` if necessary, `g <` for backwards.
- Internal: Cleanup `developer.coffee` and remove unused dev commands.

# 0.89.0:
- New: Text-object for arguments
  - Keymap:
    - `i ,`: `inner-arguments`
    - `a ,`: `a-arguments`
    - `,`: `inner-arguments`( shorthand keymap available only in operator-pending-mode )
  - Example:
    - `c i ,`( you can do `c ,`)
    - `d i ,`( you can do `d ,`)
    - `d a ,`
    - `v a ,`
  - From where this text-object find arguments?
    - Auto-detect inner range of `()`, `[]`, `{}` pairs and parse argument and select.
    - When it failed to find inner-pair range, it fallbacks to current-line range.
  - How to determine separator of arguments?
    - Heuristically determine separator from comma `, ` or white-space.
      - When some separator contains comma, it treat comma as separator.
      - When no separator contains comma, it treat white-space as separator.
- New, Setting: #747 Conditional keymap setting `keymapPToPutWithAutoIndent`.
  - When enabled, `p`, and `P` paste with-auto-indent for linewise paste.
  - Why I added this helper setting?
    - You can set keymap by yourself in your `keymap.cson`
      - But you need to be careful to not overwrite `p` in `operator-pending-mode`.
    - In `normal-mode`, `p` is mapped to `put`.
    - In `operator-pending-mode`, `p` is mapped to `inner-paragraph`, as shorthand of `i p`.
    - When set `p` keymap in your `keymap.cson` without breaking predefined shorthand `p`.
    - You need to exclude `operator-pending-mode` scope like this.
      ```coffescript
      'atom-text-editor.vim-mode-plus:not(.insert-mode):not(.operator-pending-mode)':
        'p': 'vim-mode-plus:put-after-with-auto-indent'
      ```
    - But I don't think I can expect normal user to do so. So
- New: `rotate`, `rotate-backwards` operator
  - No keymap by default.
  - ChangeOrder family operator, which rotate line in `linewise`, argument in `charactewise`.
- New: #748 ChangeOrder family( child ) operator now work differently for charactewise-target.
  - Affects: `reverse`, `rotate`, `rotate-backwards`, `sort`, `sort-case-insensitively`, `sort-by-number`
  - [Same]: When `linewise` target, it change order of line.
  - [New]: When `characterwise` target, it auto-detect arguments and change order of arguments within characterwise-range.
- New: Operator `split-arguments` and `split-arguments-with-remove-separator`
  - Commands:
    - `split-arguments`: split arguments into multiple-lines within specified target without removing separator.
    - `split-arguments-with-remove-separator`: behave same as `split-arguments` but it remove separator(sugh as `, `).
  - Keymap `g ,` to `split-arguments` by default( aggressive decision ).
    - Pure-Vim's `g , ` is "move to newer cursor position of change list", but vmp have no `changelist` anyway.
- New: [Experimental] Added `inner-pair` pre-targeted version of `split-arguments` and `reverse` to evaluate it's usefulness.
  - No keymap
  - Commands:
    - `split-arguments-of-inner-any-pair`
    - `reverse-inner-any-pair`
- Breaking: Remove `showCursorInVisualMode` setting
  - Notify and ask confirmation for auto-remove from `config.cson` if it set to non-default value.
- Improve: `r enter` to replace with new-line now correctly auto-indent inserted new-line.
- Improve: When `surround` linewse-target, now auto-indent surrounded lines more accurately than previous release.

# 0.88.0:
- Doc: New wiki page
  - DifferencesFromPureVim
  - VmpUniqueKeymaps
- Keymaps: Normal keymap addition
  - New: Now `subword` text-object have default keymap, you can change subword by `c i d`.
    - `i d`: `inner-subword`
    - `a d`: `a-subword`
  - `cmd-a` is mapped to `inner-entire` in `operator-pending` and `visual-mode` for macOS user.
    - So macOS user can use `cmd-a` as shorthand of `i e`(`inner-entire`).
    - E.g. Change all occurrence in text by `c o cmd-a` instead of `c o i e`
- Keymaps: Shorthand keymaps in `operator-pending` mode
  - Prerequisite
    - In `operator-pending-mode`, next command must be `text-object` or `motion`
    - So all `operator` command in `operator-pending-mode` is INVALID.
    - This mean, we can safely use operator command's keymap in `operator-pending-mode` as shorthand keymap of `text-object` or `motion`.
    - But using these keymap for `motion` is meaningless since motion is single-key, but text-object key is two keystroke(e.g. `i w`).
    - So I pre-defined short-hand keymap for text-object which was work for me.
  - What was defined?
    - `c` as shorthand of `inner-smart-word`, but `c c` is not affected.
      - You can `yank word` by `y c` instead of `y i w`. ( change by `c c` if you enabled it in setting )
      - To make `c c` works for `change inner-smart-word`, set `keymapCCToChangeInnerSmartWord` to `true`( `false` by default )
      - `smart-word` is similar to `word` but it's include `-` char.
    - `C` as shorthand of `inner-whole-word`
      - You can `yank whole-word` by `y C` instead of `y i W`. ( change by `c C` )
    - `d` as shorthand of `inner-subword`, but `d d` is not affected.
      - You can `yank subword` by `y d` instead of `y i d`. ( change by `c d` )
    - `p` as shorthand of `inner-paragraph`
      - You can `yank paragraph` by `y p` instead of `y i p`. ( change by `c p` )
- Keymaps: Conditional keymap enabled by setting.
  - Prerequisite
    - Added several configuration option which is 1-to-1 mapped to keymap.
    - When set to `true`, corresponding keymap is defined.
    - This is just as helper to define complex keymap via checkbox.
    - For me, I enabled all of these setting and I want strongly recommend you to evaluate these setting at least once.
    - These keymaps are picked from my local keymap which was realy work well for a log time.
  - Here is new setting, all `false` by default. Effect(good and bad) of these keymap is explained in vmp's setting-view.
    - `keymapUnderscoreToReplaceWithRegister`
    - `keymapCCToChangeInnerSmartWord`
    - `keymapSemicolonToInnerAnyPairInOperatorPendingMode`
    - `keymapSemicolonToInnerAnyPairInVisualMode`
    - `keymapBackslashToInnerCommentOrParagraphWhenToggleLineCommentsIsPending`
- Breaking: Default setting change:
  - `clearPersistentSelectionOnResetNormalMode`: `true`( `false` in previous version )
  - `clearHighlightSearchOnResetNormalMode`: `true`( `false` in previous version )
  - `highlightSearch`: `true`( `false` in previous version )
  - `useClipboardAsDefaultRegister`: `true`( `false` in previous version )
- New: #743, #739 New config option `dontUpdateRegisterOnChangeOrSubstitute`( default `false` ).
  - When set to `true`, all `c`, `s`, `C`, `S` operation no longer update register content.
  - If you want keep register content unchanged by `c i w`, set this to `false`.
- New: TextObject `comment-or-paragraph` for use of easy comment-in/out when `g /` is pending.
- Fix: For commands `set-register-name-to-*` or `set-register-name-to-_`, now show hover and correctly set `with-register` CSS scope on editorElement.
- Fix, Improve: #744 Make vmp work well with other atom-pkg or atom's native feature.
  - Update selection prop on command dispatch of outer-vmp command
    - Now correctly update cursor visibility and start `visual-mode` after `cmd-e` then `cmd-g`.
  - Update selection prop if editor retake `focus`.
    - Now correctly start `visual-mode` after `cmd-f` result was confirmed by `enter`.
- Improve: Better integration with `demo-mode` package
  - Postpone destroying operator-flash while demo-mode's hover indicator is displayed.
- Improve: When undo/redoing occurrence operation, flash was suppressed when all occurrence start and end with same column, but now flashed.
- Improve: Improve containment check for `togggle-preset-occurrence`
  - When cursor is at right column of non-word char(e.g. closing parenthesis `)`), not longer misunderstand that cursor is on occurrence-marker.
- Internal: #742 Rewrite `RegisterManager`, reduced complex logic which make me really confuse.

# 0.87.0:
- New: #732 Add integration with `demo-mode` package.
  - `demo-mode` is new Atom package I've released recently, it was originally developed as part of vim-mode-plus.
  - When demo-mode is activated via `demo-mode:toggle`, vmp do special integration to
    - Make operator flash duration longer than normal duration
    - Demo-mode hover indicator show `keystorke`, `command` and `kind`(extra info added by vmp) on each keybinding dispatch.
      - kind is one of `operator`, `text-object`, `motion`, `misc-command`
- New: #722 New version of put command which paste content to suggested indent level with keeping pasting text layout.
  - PR by @apazzolini
  - Normal `p`, `P` paste content as-is, so ignores desirable( or suggested ) indent level.
  - Following two command respect suggested indent level on linewise paste( no diff for characterwise paste ).
    - `vim-mode-plus:put-before-with-auto-indent`: Same as `put-before`(`P`) with respect suggested indent level.
    - `vim-mode-plus:put-after-with-auto-indent`:  Same as `put-after`(`p`) with respect suggested indent level.
  - No keymaps provided by default
- Improve: `o`, `O` to adjust IndentLevel when `o`, `O` is executed from empty row #723
  - PR by @apazzolini
  - To provider further pure-Vim compatible behavior.

# 0.86.3
- Improve: #727 Tweak incremental-search match highlight style to not hide covering text in some syntax-theme.

# 0.86.2
- Fix: #725 Now `v`( or `V` or `ctrl-v`) then `escape g v` correctly re-select previously selected range.
- Improve: #726 Relax selection-property assertion.
  - Fix: #716 No longer throw error when confirming color via color-picker then `escape`.

# 0.86.0, 0.86.1(just changelog-typo-fix):
- New: `insert-at-start-of-subword-occurrence` and `insert-at-end-of-subword-occurrence` command.
  - Start insert at start or end of `subword` occurrence.
  - E.g
    - When I map `{`, and `}` to these command in `normal-mode`.
      - `{ f`: start insert at each start of subword-occurrence within function.
      - `} f`: start insert at each end of subword-occurrence within function.
      - `{ p`: start insert at each start of subword-occurrence within paragraph.
- Internal, Breaking: Remove `did-restore-cursor-positions` hook which was used in Operator code but no longer used.
- Internal, Breaking: Remove many of simple accessor method like `getName`, `getOperator`, now just use `@name`, `@operator` to access these values.
- Improve: Hide cursor on early select
   - For `supportEarlySelect = true` operator( `surround`, `replace` ).
   - These operator began to shows cursor on early-select from Atom v1.15, but now hide again for early-select timing.
- Internal, Dev: #719 No longer use `HTMLElement` as search-input for speedy dev by hot-reload vmp.
- Internal, Breaking: Move `InsertMode`(was in `insert-mode.coffee`) operations under `MiscCommands`( in `misc-commands.coffee`)
- Improve: Keep original multi-cursor on occurrence operation by migrating mutation info.
- Improve: Simplify mark manager and destroy all marker on `vimState.onDidDestroy`.
- Improve: Clean up mutationManager.
- Fix, Internal: Now do TYPE check for spec-helper's `ensure` function's argument, some test was silently skipped in previous release.

# 0.85.1:
- Fix, SUPER Critical: #175 Moving cursor in `visual-mode` make Atom editor really slow.
  - vmp's mark is stored as marker and was created limitlessly without destroying previous-marker.
  - As number of marker increased, editor get really slow.
  - This is old Bug from original vim-mode, but impact get really significant from v0.58.0.
    - Since from v0.58.0, to track previousSelection(used for `g v`) `<` and `>` mark is updated on every `visual-mode` movement.

# 0.85.0:
- Fix: When `stayOnYank` was enabled, `y 0`, `y h` no longer move cursor.
- Fix: [Cosmetic but important] Fix very small cursor position jump( cosmetic ) when activating vL ( because of gap between px and em? )
- Fix: Respect `v` operator-modifier for `t`( Till ) motion.
  - e.g. In text "ab" when cursor is at "a"
    - Old: `d t b` delete "a"( Good ), `d v t b` delete "a"( Bad ).
    - New: `d t b` delete "a"( Good ), `d v t b` don't delete "a"( Good ).
- Improve: Now can select line ending new line char in `visual-mode`.
  - E.g. Move right by `l` at end of line select new-line.
- Fix: #699 Lost goalColumn in `visual.blockwise` when move across blank-row.
  - This is regression in v0.84.0.
- Fix: #119 When `j`, `k` is used as operator's target, don't apply operation when failed to move.
  - Now more compatible with pure Vim.
  - Example:
    - `d j` from last line do nothing. ( In previous version, delete last line ).
    - `d k` from first line do nothing. ( In previous version, delete first line ).
- Improve: `g v` after `vL`( visual-linewise ) to restore characterwise `column`.
- Fix: `v i p d` then `.` repeat from different cursor position now works correctly
- Internal:
  - Overhaul: `CursorStyleManager`, `SelectionWrapper`, `TextObject`, `BlockwiseSelection`
  - Rename `characterwiseHead` to `propertyHead` in `spec-helper.coffee`
  - Remove lots of unnecessary `null` guard.
- Breaking: Remove `All` text-obect, it's alias of `Entire` but not used.
- Breaking: Remove `Edge` text-object, it's experimentally added in the past, but not maintained and not as useful as I originally thought.
- Improve: TextObject
  - Improve: No longer iterate `selectTextObject` over each memberSelection of blockwise selection( blockwiseSelection consists of multiple selection ).
  - Improve: `Fold` , `Function` text-object now always expand if possible by checking containment against selected buffer range
  - Improve: `Pair` text-object now always find from cursor position.
  - Improve: Executing text-object from `vL` mode now works as expected in most of text-object.
  - Internal: Set wise explicitly in most of text-obect rather than dynamically determine from selection range.
  - Internal: Auto generate `Inner`, or `A` prefixed classes and `AllowForwarding` suffixed classes( reduced lots of boilerplate code ).
- Improve: visual-blockwise ( `vB`-mode )
  - #699 Fix: Now respect goalColumn in `vB` when move across blank row by `j` or `k`.
    - Regression introduced in v0.84.0.
  - #704 Rewrite vB-mode related code.
    - vB selection is normalized before selecting text-object.
    - So no longer iterate `selectTextObject` over each memberSelection of blockwise selection.
  - Improve: #438 when vB selection respect `goalColumn`
    - Original goalColumn is respected as long as selection-head is right-most column.

# 0.84.1:
- Fix: To fix vim-mode-plus-move-selected-text degradation.

# 0.84.0:
- Fix, Improve: #689 Occurrence was not worked for the word which include non-word char such as `$` and `@`.
  - E.g. `$var` in Perl, PHP.
  - This was because when finding occurrences, it searched by `\bword\b` pattern.
  - But `\b\$var\b` never match `$var`, in this case find by `\$var\b` pattern from this release( auto relax `\b` boundary ).
- Improve: Preserve fold on `g v`
- Internal:
  - Cleanup selection-wrapper code.
  - Remove unused functions from `utils.coffee`

# 0.83.0:
- Support: set minimum engines to `^1.14.0`
- Fix: When `o` was executed in `vL` mode, didn't correctly restore column on shift to `vC` or `normal`.
  - Now correctly restore `characterwise` column after `o` in `linewise` mode.
- Improve: `g .` correctly restore subword-occurrence-marker
  - `g .`( `vim-mode-plus:add-preset-occurrence-from-last-occurrence-pattern` ) is command to restore last cleared preset-occurrence.
  - It is useful when you mistakenly cleared it by `escape` and quickly recover last preset-occurrence marker.
  - Previously `preset-subword-occurrence` was not correctly restored by `g .`, but now fixed.
- Improve: Use faster `displayMarkerLayer::clear()` for hlsearch, occurrence-manager, search-model etc.
- Internal: add `dev` prefix for setting for dev-use.
- Internal: Remove lots of unused function in `utils.coffee`.
- Internal: add `vimState::getConfig` to access package settings.

# 0.82.3:
- Fix: `move-to-previous-subword` stops boundary of white-space unnecessarily( upstream issue auto-fixed)
  - Spec to accommodating wrong behavior removed.
- Fix: `B` moves to beginning of file when invoked from begging of line.
  - Introduced by upstream change in Atom v1.14.0( or v1.14.1?).

# 0.82.2:
- Fix: No longer throw exception when `showHoverSearchCounter` is enabled and editor was closed immediately after hover counter was shown.

# 0.82.1:
- Fix: `p`, `P` in vB-mode no longer throw exception #672
  - This bug was introduced in v0.80.0.

# 0.82.0:
- New: command `move-up-wrap`, `move-down-wrap`, `j`, `k` with line wrap( top-to-bottom/bottom-to-top ).
  - No keymap by default. intended to use from atom-narrow package(now I'm actively developping).

# 0.81.0:
- Improve, Breaking: Remove `fallbackTabAndShiftTabInNormalMode`
  - This was necessary since `tab`, `shift-tab` was mapped to `move-to-next-occurrence` and `move-to-previous-occurrence`.
  - When `true`, fallback `tab`, `shift-tab` to `editor:indent` or `editor:outdent-selected-rows` when no `occurrence-marker` exist.
  - But now, these mapping is defined in `has-occurrence` scope, which means `occurrence-marker` exists on editor.
  - So your `tab`, `shift-tab` is no longer conflict if no `occurrence-marker` exits.

# 0.80.0:
- Breaking: Disable `I`, `A` special keymap in `has-occurrence` scope.
  - To avoid surprising user. Now behave as normal `I` amnd `A`.
  - To insert start/end of each occurrences, use `visual-mode` select then `I` or `A`.
  - Or set keymap in your `keymap.cson` to restore previous verison's keymap.
    ```
    'atom-text-editor.vim-mode-plus.has-occurrence:not(.insert-mode)':
      'I': 'vim-mode-plus:insert-at-start-of-target'
      'A': 'vim-mode-plus:insert-at-end-of-target'
    ```

- Fix: No longer throw exception when specified register has no value(=text) on `p`, `P` operation. #656.
- Fix: Now `selection` properties cleared on each normal-mode operation finish to avoid hover counter is shown at incorrect position.
- Developer: Spec helper `ensureMode` no longer mutate passed array itself.
- Developer: `reload-packages` command now reload depending packages in correct order.

# 0.79.1:
- Fix: #653 Immediately close search-mini-editor when main editorElement was clicked to avoid stale decorations remains on editor.
- Fix: Move to next subword no longer throw error in some ending string pattern.
- Improve: `move-to-next-word` and it's child motion now skip white-space only row(compatible with pure-Vim).

# 0.79.0:
- Fix: #647 Ensure clearing blockwise selection after `.` repeating blockwise operation.
- Fix: #537 When `persistent-selection` is exists, `I` in `visual-blockwise`, make selected range get wired.
- Fix: In atom 1.14-beta, when `IncrementalSearch` was enabled, `/` throw exception #652
- Improve: #646 Improve `TagFinder` to find enclosed range first
- Internal: Extract normalization/denormalization of `linewise`, `characterwise` selection to selection-wrapper
- Internal: Improve spec helper
  - Introduce cursorScreen for spec-helper for explicitness
  - Now `cursor:` is bufferPosition-wise
  - #650 `textC` no longer ensure order of cursors appear

# 0.78.0: Happy New Year 2017!
- New: TransformString Operator `sort-case-insensitively` by @thancock20 #640
- Fix: `v *` then `n` or `N` in different editor no longer throw error #641.
- Improve: Pair text-object
  - Internal: Use new `PairFinder` class to find pair range(extracted from `text-object.coffee`).
  - Improve: Bracket TextObject: `(, )`, `{, }`, `[, ]`, `<, >`
    - Find range by considering syntax-scope. #644.
  - Improve: Quote TextObject: `'`, `"` etc..
    - Simply find quote if cursor is NOT in quote char #173, #638
    - If cursor is ON quote char consider inside/outside of double-quote #556, #642
- Improve: Fold text-object(`i z`, `a z`) no longer ignore fold on cursor's row. #636
- Internal: New `Base::scanForward`, `Base::scanBackward` and use it
- Internal: Lots of internal code cleanup(`utils.coffee`, `text-object.coffee` etc.)

# 0.77.0
- New: Subword support #634
  - Motion: `move-to-next-subword`, `move-to-previous-subword`, `move-to-end-of-subword`'
  - TextObject: `a-subword`, `inner-subword`(no keymaps by default)
  - OperatorModifier: `O` works as like `o`, except `O` works for subword.(e.g. `c O p`)
  - `g O`(`toggle-preset-subword-occurrence`) mark subword, subword-version of `g o`.
- New: TransformString family operator `split-string-with-keeping-splitter`, `sort-by-number`( no keymap )
- New `g q`(`auto-flow`) operator, `g q q` or `g q g q` works for current line #187
  - Implementation-wise, it just dispatch to core autoflow package. So might not be compatible with pure-Vim.
- Improve: `maximize-pane` #633
  - Tweak: Now set `left-margin`(`20%`) when maximized, so that code comes front of your eye.
  - Now hide statusbar.
  - New: option `hideStatusBarOnMaximizePane`(default `true`).
- Tweak: Support #627 earlySelect for operator `replace`
- Improve: Early settle insertion count for insertion operator(`i` `a`) to avoid taking count for motion.
- Fix: Now `v enter` then `.` repeated correctly create 1 column persistent #630
- Fix: `ctrl-v enter .` no longer throw error #630
- Spec: Improve coverage for `TransformString` children(`join` etc..)
- Internal: Rewrite `ctrl-a`, `ctrl-x`,  `g ctrl-a`, `g ctrl-x`
  - Breaking: No longer beep when failed.

# 0.76.0
- Breaking, Cosmetic: Remove `showHoverOnOperate` feature #626
  - Reason:
    - This is fancy feature added at very early phase of vim-mode-plus as experiment.
    - But this feature getting in a way to improve, cleanup vim-mode-plus.
  - Removed Configuration: Following parameters are removed, remove it manually from `config.cson` if necessary.
    - `showHoverOnOperate`
    - `showHoverOnOperateIcon`
- New: [Experimental] `surround` now **select** target immediately then get user input.
  - Better UI feedback, to reduce `what-I-have-to-do-next`, `where-am-I` situation in complex keystroke operation.
  - When `change-surround` fail at first character, it immediately stop execution( No need to input useless next char ).
- Fix: `maximize-pane` now work for many many split pane #623.
- Improve: Hover performance is greatly improved #625
  - Hover shown in `1 0 j`, `" a y y`, `change-surround` is now responsive than before.
  - HoverElement is renamed to HoverManager(no longer HTMLELement).
- Improve: `undo`/`redo` flashing humanization further.
- Improve: Tweak search flashing to win over existing `highlight-search`.
- Internal: Cleanup occurrence-spec, avoid using `editor.element` for mini-editor.

# 0.75.0
- New: `setCursorToStartOfChangeOnUndoRedoStrategy`(default `smart`) #620, #621
- New: `remove-leading-white-spaces`( no defautl keymap ): work always `linewise`.
- New, Breaking: `replace` is now normal operator which enter `operator-pending-mode`, old `replace` command was renamed.
  - OldName: `vim-mode-plus:replace`( mapped from `r` )
  - NewName: `vim-mode-plus:replace-character`( mapped from `r` )
- Fix: `m` command was inappropriately repeatable by `.`
- Fix: No longer throw exception for `V tab` or `V shift-tab` #619
- Improve: Respect operator specific `stayOn` option when `stayOnOccurrence` was `true` and fail to select `occurrence-marker`.
- Improve: `d o p` moves cursor to end of mutation as normal `d` #611
- Improve: `undo/redo`
  - Cursor placement on `undo`/`redo` further.
    - `o` and `O` undo/redo is now behave same as pure-Vim.
  - Flashing is further suppressed to be un-noisy. Also humanize new line(`\n`) change flash to feel naturally.
    - Skip flash for leading white spaces change
    - Skip flash when multiple range start and end with exactly same column(e.g. `toggle-line-comments`).
- Improve: `transform-smart-word-by-select-list` now respect precomposed target of each string transformer.
  - E.g. `SplitString` have precomposed target( = `MoveToRelativeLine` ), respect it over `smart-word` target.
- Internal: Remove manual checkpoint and change grouping management from normal operator as like before(was not necessary).

# 0.74.0
- Improve: More accurate cursor placement after undo/redo. #603
  - IMPORTANT, new approach to restore cursor position after undo/redo.
    - Previous release: Did manual-cursor-position-adjustment after undo/redo
    - From this release: Create text-buffer's checkpoint at correct timing then restore on undo/redo.
    - Checkpoint mechanism was being used for long time for `i`, `a`, `c`, from this release used operator globally.
    - This shift is not completed, will continue gradual improvement.
- Improve: Use different color on `flashOnUndoRedo` #610
  - Single change: subtle color flash with duration `0.3s`(singe delete-only change is no longer flashed).
  - Multi change add: green flash with duration `0.8s`
  - Multi change delete: red flash with duration `0.8s`
- Improve: `p`, `P` #615
  - Improve: Flash color differentiation on `p`, `P`(use longer flash to make it obvious mutation boundary).
  - Breaking: Simplified linewise paste, when line have no ending newline, it add newline automatically
  - Improve: Pasting characterwise register now place cursor at start of pasted text if text was not single-line-text.
- Improve: Now Indent(`>`), Outdent(`<`) indent/outdent count times in `visual-mode` #614
- Improve, Breaking: Improve `insert-at-start/end-of-smart-word`, now no longer stop at whitespace boundary. #613
  - Breaking: Renamed command name(as same as previous release, no default-keymap)
    - `insert-at-start-of-inner-smart-word` -> `insert-at-start-of-smart-word`
    - `insert-at-end-of-inner-smart-word` -> `insert-at-end-of-smart-word`
- FIX: Incorrectly used `occurrence-flash` if `occurrence-marker` exists but not selected by operation.
- Breaking: Remove experimental `put-after-and-select`, `put-before-and-select` command #612
- Internal: When fail to select occurrence `did-select-occurrence` event no longer fired(was fired in previous release).
- Internal: Rename register type name from `character` to `characterwise` for consistency.

# 0.73.2:
- Fix: `C` and `D` in `vB`(visual-block) mode was broken from v0.70.0. #602.
- Fix: `d o tab` then `.` repeat no longer fail #598
- Improve: Simplify flash for undo/redo, red color is used for remove-only-change #601

# 0.73.1:
- Improve, New: fallback for `tab`, `shift-tab` in `normal-mode`.
  - By default in `normal-mode`, `tab` and `shift-tab` is mapped to `move-to-occurrence` and `move-to-previous-occurrence`
  - When no occurrence-marker was exists on editor, it fallbacks to Atom's default `editor:indent`, `editor:outdent-selected-rows`.
  - For user don't want this fallback, set `fallbackTabAndShiftTabInNormalMode` to `false`(default `true`).

# 0.73.0:
- New: Close empty search-mini-editor by `backspace` from @gittyupagain. #567
- New, Breaking: Keep `occurrence-marker` after operation. #572
  - Improve: Destroy `occurrence-marker` remains after invalidated.
  - Breaking: Operate on normal-target when fail to select `occurrence-marker`. #578, #579
  - Improve: Destroy `occurrence-marker` in-sync if possible #592
- New: [experimental] Operator `add-blank-line-below`, `add-blank-line-above`, No defaut keymap. #574
- New, Breaking: `I`, `A` keymap in operator-pending(`d I` for `d ^`, `d A` for `d $`).
- New: Simplify `tab`, `shift-tab`, #581, #594
  - Keymap, Breaking: Mapped in all mode except `insert-mode`, opinionated decision.
    - `tab`: `move-to-next-occurrence`
    - `shift-tab`: `move-to-previous-occurrence`
  - New: Setting `flashOnMoveToOccurrence`, default `false`.
  - Improve: Now correctly skips cleared or invalidated(=invisible) `occurrence-marker`. #594
  - Improve: `.` repeat support for `move-to-occurrence` targeted operation #591
  - Improve: Spec coverage.
- Fix: text-objects function now work properly in language-elixir syntax by @dillonkearns. #585
- Fix: To undo repeat-of-change need `u` twice in v0.72.0.
- Fix: When `has-occurrence`, `I`, `A` was incorrectly keymapped in `insert-mode`.
- Fix: Prevent Atom editor freezes by passing BIG count. #560, #596
  - For Motion(`9999999j`), TextObject: `v9999999ip` and Insert: `9999999i`
- Improve: Flashing
  - Use red flash color for delete operation #573
  - Longer flash for undo/redo(by keyframe tweaking).
  - Improve: Reduce chance to re-flash immediately split after undo by reducing duration(1sec to 500ms).
- Improve: Documentation, description
  - Improve config description
  - Add FAQ for `charactersToAddSpaceOnSurround`
  - Mention `vim-mode-plus-keymaps-for-surround` keymap only package in README.md.
- Internal, Breaking: [experimental] No longer directly call `Motion::select()` from operator #595
- Internal: Spec improved
  - `textC` spec DSL which declare cursor position by `|` and `!`(last-cursor)
  - Rewrite several specs by improving granularity by checking cursor position(was not checked before)
  - Allow `partialMatchTimeout` options for ensure and keystroke spec helper

# 0.72.0:
- New: Command `add-preset-occurrence-from-last-occurrence-pattern` default `g .` keymap.
- New: Command `insert-at-start-of-occurrence`, `insert-at-end-of-occurrence`
- New: Config parameter `stayOnOccurrence` to specify stayOn behavior on occurrence-operation. #569.
- New: unused and unnecessary indirection
- Improve: Efficiency improved for cursorStyleManager. Skip cursor style modification if it can,
- Improve, Breaking: `AngleBracket` now can work with multi-line #552
  - TextObject `Tag` is no longer member of `AnyPair`. Since its conflict with `AngleBracket`
- Improve, Fix: No longer unwanted remaining flash by `flashOnOperate` since now it's invalidate when touched.
- Improve: Flash color is more stand-out when occurrence-operation #566
- Improve: For flashing undo/redo, no longer red/green color blended when whichever is contained other #562
- Improve: Place cursor more accurately for undo/redo when occurrence is involved.
- Improve: Respect last cursor position when multiple cursor is cleared by `escape` in `normal-mode`. #557, #562
- Improve: When occurrence is involved in operation, respect original cursor position after operation finished. #557
- Improve: highlight when highlightSearch changed like on, off, on  
- Fix: `toggle-preset-occurrence` should not accept persistentSelection but it was in previous release.
- Fix: highlightSearch no longer extend highlight marker on appending text on tail #555
- Internal: All vimState instances are managed by VimState class itself.
- Internal: New convention. Ensure `ActivateInsertMode` and it's child call `@selectTarget()` before starting any mutation.

# 0.71.0:
- New: `moveToFirstCharacterOnVerticalMotion` options #550, #549
  - Default: `true`, if you disable, column position is kept after these motion.
  - Similar to `startofline` option in pure-Vim.
  - Affects following motion(Unlike pure-Vim, `d`, `< <`, `> >` is not affected)
    - `G`, `g g`, `H`, `M`, `L`, `ctrl-f`, `ctrl-b`, `ctrl-d`, `ctrl-u`
  - For `d`, `< <`, `> >`, use `stayOnXXX` option if you want to keep column.
- Improve: Don't close search mini-editor on `blur` event. (e.g. app-switch by cmd-tab) #539
- Internal: `Base::getCount()` can take offset.
- Internal Bug: Now properly detect duplicate class Name among operations.
- Internal: Rename `Misc.Scroll` to `ScrollWithoutChangingCursorPosition` for explicitness.

# 0.70.0:
- New: Option `automaticallyEscapeInsertModeOnActivePaneItemChange`  #535
- New: Option `keepColumnOnSelectTextObject` to keep original column in `v i p` etc. #541, #543
- Fix: Cursor no longer become out-of-screen when move upward in `vB` #546
- Fix: `I` and `A` should work on occurrence when has-occurrence #488, #518
- Fix: select-occurrence in `vL` does not correctly select occurrence(spec missed to catch) in previous release.
- Improve: flash-UI feedback when `Y` in `vC` mode.
- Improve: Cleanup and suppress flash for `r` command
- Improve: As general rule selection target can override pre-composed target #531
  - e.g `transform-smart-word-by-select-list` works on selection if selection was not empty.
- Improve: Persistent-selection treated as-if real-selection further #532, #534
- Improve: Tweak what syntax scope is treated as function for TextObject.Function
- Improve: `delete-line` is now available in all mode(visual mode only for default keymap)
- Improve: Now pair text-object change mode to `vC` regardless of current mode. #542
  - Remove internally used `TextObject::allowSubmodeChange` property
- Breaking: Remove experimental but un-used operators and text-objects.
  - Operator `DeleteOccurrenceInAFunctionOrInnerParagraph`, `ChangeOccurrenceInAFunctionOrInnerParagraph`, `ChangeOccurrenceInAPersistentSelection`
  - TextObject `UnionTextObject`, `AFunctionOrInnerParagraph`, `ACurrentSelectionAndAPersistentSelection`, `TextObjectFirstFound`
- Internal: Rename useMakerForStay to stayByMarker and no longer track marker unless needStay()
- Internal: Cleanup mutationManger #530
- Internal, Spec: New `textC` set/ensure option, validate exclusive option. #528, #533

# 0.69.0:
- New: Command `equalize-panes`(`ctrl-w =`) by @mattaschmann
- New, Breaking: `g I` support, breaking because old `I` mapped command was renamed(harmless for most users).
  - Renamed because of naming-bug.
  - Renamed old `insert-at-beginning-of-line` to `insert-at-first-character-of-line`(mapped to `I`).
  - Then now `insert-at-beginning-of-line` is mapped to `g I`.
- New: vim-niceblock compatible behavior #488
  - Now visual-mode's `I`, `A` works differently depending on `vC`, `vB`, `vL` modes.
  - See `YouDontKnowVimModePlus` page on vmp's wiki for detail.
- New: [experimental] `search-occurrence` motion. #519
  - When you can see dotted-underlined-occurrence-marker, `tab`, `shift-tab` can be used as motion.
  - You can use `space` to deselect occurrence-marker while moving next/prev of `occurrence-marker`.
  - [keymap]
    - `tab`: `vim-mode-plus:search-occurrence`
    - `shift-tab`: `vim-mode-plus:search-occurrence-backwards`
- Fix: When yank into named register for input-taking-motion(e.g `" a y f )`), it fail to save to register. #520
- Improve: now `vimState.globalState` is resettable for all or specific field
- Dev: `open-in-vim` now open buffer with at same cursor position.
- Fix: Improve: `y i p` now move to start of paragraph after operator finished. #507
- Fix: Improve: Further compatible resulting cursor position after operator finished. #529
- Fix: Hover used to show count and register was not correctly positioned, really was bad degradation. #406
- Improve: No longer share inputUI across operation, as a result `vimState.input` become unavailable. #525.
- New: `C` in `vC` mode change whole-line #527

# 0.68.0:
- New: `project-find-from-search` command which have being provided as separate package #508.
  - `cmd-enter` is default keymap for macOS user.
- Fix: when `flashScreenOnSearchHasNoMatch` was `false`, throw error when search item was not found #510.

# 0.67.0:
- Support: set minimum engines to `^1.13.0-beta1`.
- Fix: Remove use of `::shadow`. #485
- Fix: `cmd-d` didn't start `visual-mode` suffered by the side-effect of shadowDOM removal #490
- Experimental, Improve: Better flashing effect using keyframe CSS animation
  - Breaking: Removed flashing duration config params.
  - Now flashingDuration is fixed to 1 sec at maximum(duration until marker be destroyed)
  - User can tweak by css within this duration. Refer `styles/vim-mode-plus.less` if you want.
- Fix: Scroll motion failed to put cursor at firstChar of screen line when it’s wrapped.
- Breaking: Remove cursor line flashing effect on smoothScrolling. #502
- UI: Modify style of search match to modern(??) style.
- Fix: No longer remove non-vmp-css-class from editorElement temporarily while waiting-user-input #497.

# 0.66.1:
- Fix: Flash only one instance at a given moment when search `/`, `?`, `#`, `?`. #494
- Fix: % motion now work again #493 by @mattaschmann
- Fix When both operation and target take user input, it didn't work correctly. #491

# 0.66.0:
- New: Following motion commands by @bronson.
  - `move-to-previous-end-of-word`(`g e`)
  - `move-to-previous-end-of-whole-word`(`g E`)
- New: Sugar command `set-register-name-to-*` to use system-clipboard. #272
- Breaking: Rename `set-register-name-to-blackhole` to `set-register-name-to-_` #478, #473, #482
- Breaking: `move-up-to-edge` and `move-down-to-edge` no longer move to first-line and last-line if it's not stoppable.
  - This means, eliminated special handling for first-line and last-line. Just behave same as other line. #481
- Doc: Fix typo and grammar for README.md by @jimt #483.

# 0.65.0:
- Improve: Incremental-search `/ enter` and `? enter`(confirm with blank imput) repeat last-search #474, #464
- New: Update backtick(`` ` ``) and `'` mark on jump-motion #476, #384
  - So keystroke `` ` ` `` and `' '` jump back to previous position.
- New: Support `'` mark.
- New: `set-register-name-to-blackhole` command(no default keymap) to make blackhole-register(`_`) easy-to-use #478, #473

# 0.64.0:
- Fix: cursor-style-manager no longer throw error when executing `find-and-replace:select-next` in wholeline selection. #406
- Fix: No longer destroy first cursor after incremental-search is executeded with multi-cursors #461
- Fix: In visual-blockwise, unnecessary add selection in bottom direction when bottom selection start at column 0 #454
- Fix: `e`(`move-to-end-of-word`) on blank row at the end of file freezes Atom #469

# 0.63.0:
- New: Config option `statusBarModeStringStyle`(default `short`) #451
- New, Improve: Repeate(`.`) command now can repeat `insert-mode`'s delete/backspace operation #322

# 0.62.0:
- Improve: Improve performance for `f`, `F`, `t`, `T`, Surround #448, #435.

# 0.61.0:
- Doc: Simplify README.md
- New: Sentence motion by @bronson
  - `move-to-next-sentence`: default keymap `)`
  - `move-to-previous-sentence`: default keymap `(`
  - `move-to-next-sentence-skip-blank-row`: no default keymap
  - `move-to-previous-sentence-skip-blank-row`: no default keymap
- New: tab to space, space to tab conversion operator by @zhaocai #432, #433
  - `convert-to-soft-tab`: no default keymap
  - `convert-to-hard-tab`: no default keymap
- Improve: No longer actually select to display target range for `change-surround-any-pair`, so cursor position is not changed when canceled.
- Breaking, Improve: Use shorter, minimum length mode indcator string on status-bar #428.
- Improve: More pure-vim-like behavior for `#` and `#`.
- Improve: Cleanup search motion(`/`, `?`). #440.
- Breaking: Remove experimental motion and operator which was intended to replacement of `f`, `F` but was not such useful.
  - `SearchCurrentLine`
  - `SearchCurrentLineBackwards`
  - `InsertAtStartOfSearchCurrentLine`
  - `InsertAtEndOfSearchCurrentLine`
- Fix: Don't pass empty array to `editor.setSelectedBufferRanges`, and collectly restore cursor when occurrence opeation was failed on `.` repeat.

# 0.60.1:
- Fix: `;`, `,` throw error if orignal-find-command-executed-editor was destoyed. #434

# 0.60.0:
- Improve: Fix minor inconsistency for amount of rows to scroll between normal and visual for `ctrl-f, b, d, u`.
- New: Smooth scroll for `ctrl-f, b, d, u`. Disabled by default. New config option to enable and tweak animation duration.
- New, Experimental: TextObject `a-edge` and `inner-edge`(no diff for now), which select from up-edge to down-edge. No keymap by default.

# 0.59.0:
- Breaking: `j`, `k` now always works as bufferRow-wise(screenRow-wise in previous version).
  - Previous `j`, `k` behavior is available as `g k`, `g j` as like pure Vim.
- New: Operator `InsertAtStartOfInnerSmartWord`, `InsertAtEndOfInnerSmartWord` no keymap by default #424
- Fix: `p`, `P` mutation tracked again(was not tracked by degradation) to `select-latest-changes` #426
- Fix: `f` repeat by `;`, `,` clear existing selection where it should extend selection #425
- Improve: `g n` and `g N` works more pure-vim-like.
- Internal: Cleanup cursor position normalization required in `visual-mode`.

# 0.58.5:
- Improve: `delete-surround`, `change-surround` no longer trim spaces when open-pair-char and close-pair-char was same(e.g `'text'`, `"text"`).

# 0.58.4:
- Fix, Degradation: Again guard in case mutation information was unavailable when tracking changes.

# 0.58.3:
- Internal, Improve: `,` and `;` is no longer instance of operator to avoid complexity.
- Fix: Throwing error in `V D` keystroke. #416, #417.

# 0.58.2:
- Fix: Guard in case mutation information was unavailable when tracking changes.

# 0.58.1:
- Improve: Clear multiple-selection when `create-persistent-selection` #414
- Keymap: Remove `cmd-d` in `has-persistent-selection` scope to work well with default `cmd-d` #413
- Keymap: Add `[`, `]` to `vim-mode-plus:move-up-to-edge`, `vim-mode-plus:move-down-to-edge` #412

# 0.58.0:
- New: `preset-occurrence` #395, #396
  - Allow user to set occurrence BEFORE operator.
  - Keymap: In `normal`, `visual`, `g o` to `toggle-preset-occurrence`.
    - It add/remove `preset-occurrence` at cursor position.
    - When removing, it remove one by one, not all.
  - Keymap: In incsearch input, `cmd-o` to `add-occurrence-pattern-from-search`
    - It add `preset-occurrence` by search-pattern.
  - Following two operation do the same thing, but former is `operator-modifier`, later is `preset-occurrence`(`g o`).
    - `c o $`: change cursor-word till end-of-line.
    - `g o c $`: change cursor-word till end-of-line.
- New: PersistentSelection: (former RangeMarker)
  - Allow user to set target BEFORE operator.
  - Used as implicit target of operator. As like selection in `visual-mode` is used as implicit target.
  - Config: `autoSelectPersistentSelectionOnOperate`(default=true) control to disable implicit targeting.
  - Updated style to seem like selection.
  - Keymap: In `visual`, `enter` to `create-persistent-selection`.
  - If you map `c s` to `change-surround`, I recommend you to disable it including other keymap starting with `c`.
  - Following two operation do the same thing, but former target is normal selection, later target is `persistent-selection`.
    - `V j j c`: change two three line.
    - `V j j enter c`: change three line.
  - Common use case is
    - Work on multiple target without using mouse: set multiple target by `persistent-selection` then mutate.
    - Narrow target range to include particular set of `occurrence`.
- New: Highlight occurrence when occurrence modifier(`o`) is typed. #377
- API Breaking, Improve: globalState is no longer simple object, use `get`, `set` method instead. Now observable it's change.
- Breaking, Improve: When `H`, and `L` motion is used as target of operator, ignore scrolloff to mutate till visible-top or bottom row.
- Breaking: `clearMultipleCursorsOnEscapeInsertMode` is now default `false`, this was changed in v0.57.0, but now reverted. #376
- Fix: PreviousSelection(`g v`) was incorrectly shared across editor.
- Fix: No longer use `@syntax-result-marker-color` instead use `@syntax-text-color`.
- Improve: Gradual clearing different kind of marker(persistent-selection, occur, hlsearch).
- Improve, Fix: `stayOnDelete` is now work properly on every situation.
- Improve: Use marker to track original cursor position to stay. #380
- Improve: When `stayOnOperate` family feature are enabled, adjust cursor position to not exceeds end of mutation #380
- Improve: Crean up OperationStack. #400
- Improve: Many TextObject now follow new convention(return range of text-object by `getRange()`).
- Improve: `word` text-object family to select more vim-like range(don't select adjoining non-word-char like Atom's default `selection.selectWord()`).
- Internal: Debug codes and cleanup
- Internal: `OperationStack::subscribe` now return subscribed handler.
- Internal: Split out highlightSearch concerning code as HighlightSearchManager class #398
- Internal: Split out mutation concerning code in operator as MutationTracker class
- Internal: Split out rangeMaker concerning code as PersistentSelectionManager class
- New: VisibleArea text-object. keymap `i v`.
- New: `UnionTextObject` and `AFunctionOrInnerPair`
- Rename: Operator `replace` to `replace-and-move-right` and `replace` is general replace operator.

# 0.57.0:
- Fix: `a-word` and `a-whole-word` now select leading white-space when trailing space was not exist #355
- Fix: Paste(`p`) non-linewise text to empty line now insert text to same line, not next-line like previous version. #359.
- New: When `o` modifier is used in `operator-pending-mode`, `with-occurrence` css scope is set to provide keymap scope.
- New: Now `Operator Pending` status is shown on status-bar.
- Internal, Improve: `Operator.coffee` is split out into three files and overhauled greatly #370.
- New: Stay preference support for `Delete`, and `StayOnDelete` config options control this behavior.
- Breaking: Removed `SetCursorsToStartOfTarget`, `SetCursorsToStartOfRangeMarker` since not used.
- Improve: `.` repeat is no longer depend `Repeat` wrapper operation. Simply replayed recorded operation by operationStack.
- Breaking, New: `clearMultipleCursorsOnEscapeInsertMode` config option with `true` by default.
- Breaking, Experimental, New: Default keymap only available in `o` modifier is specified. #379
  - To change occur in `inner-paragraph`: Can type `c o p`, instead of `c o i p`
  - To change occur in `a-function`: Can type `c o f`, instead of `c o a f`
  - To change occur in `a-range-marker`: Can type `c o r`, instead of `c o a r`
  - To change occur in `inner-current-line`: Can type `c o l`, instead of `c o i l`
  - To change occur in `a-fold`: Can type `c o z`, instead of `c o a z`
  - Off course: you can do with operator other than `c`. e.g. `d o f`, `g U o z`.
- Breaking, Degradation, Improve: To fix stale selection properties, I disabled special support for outer-vmp command which create selection.
  - When outer-vmp command create selection and enter `visual-mode`, original cursor position is no longer preserved. e.g. `cmd-l`.

# 0.56.0:
- New: Operator `insert-at-start-of-occurrence`, `insert-at-end-of-occurrence` to start insert at occurrence.
- New: Operator `sort` #365
- New: Motion `search-current-line`, `search-current-line-backwards` #366
- Fix: `f`, `F`, `t`, `T` was broken, no longer focus input on repeat by `;` or `,` #367

# 0.55.0:
- Internal: Avoid circular referencing for string transformers store.
- Doc: Update doc-string of many operator for better command report for vmp wiki.
- Breaking, Improve: `AddSelection` no longer get word from visual-mode #351
- New: `All` TextObject as alias of `Entire`. #352
- Improve?, Breaking?: Change range-marker style as-if selection #357
- Improve, Rename: Cleanup operator-modifier mechanism. Renamed command #357
  - `v`: `force-operator-characterwise` to `operator-modifier-characterwise`
  - `V`: `force-operator-linewise` to `operator-modifier-linewise`
- New: Occurrence operator-modifier #357
  - `o` in `operator-pending-mode`
  - As like `v` or `V` modifier force the wise of operator.
  - `o` modifier re-select cursor-word from target range.
    - e.g. `g U o i p` upper case all occurrence of cursor-word in paragraph
    - e.g. `c i p` change whole paragraph, `c o i p` change occurrence of cursor word in paragraph.
  - This modifier is available for all operator.
  - `select-occurrence`, `map-surround` is created based on this `occurrence` modifier.
- New: Narrowed selection state #357
  - `is-narrow` state is automatically activated/deactivated when `visual-mode` and last selection is multi-line.
  - Available shortcut in `visual-mode.is-narrow` scope.
    - `ctrl-cmd-c`: `change-occurrence` to change occurrence of cursor word in selection.
    - `cmd-d`: `select-occurrence` to select occurrence of cursor word in selection.
- New: RangeMarker new command.
  - `toggle-range-marker`: remove or add range-marker
  - `toggle-range-marker-on-inner-word`: `inner-word` pre-targeted version
  - `convert-range-marker-to-selection`: add selection on all range-marker and remove range-marker after select.
- New: IncrementalSearch specific `/`, `?` special feature #357
  - Direct command from search-input mini editor.
    - `ctrl-cmd-c`: `change-occurrence-from-search` to change occurrence of search pattern matched.
    - `cmd-d`: `select-occurrence-from-search` to select occurrence of search pattern matched.
    - When above command is applied operator target is automatically set in following priority.
      1. In `visual-mode` use current selection as target.
      2. If there is `range-marker` then use it as target.
      3. None of above match, then enter operator-pending state to get target from user.
- Rename: `add-selection` to `select-occurrence`
- Improve: `reset-normal-mode` clear hlsearch and range-marker more thoughtfully. No longer clear in following situation.
  - Internal invocation of `vimState.resetNormalMode()`.
  - When having multiple cursor.
- Internal: Define `Base::initialize` to be eliminate uncertainty of super call in child class. #361

# 0.54.1:
- Breaking: Revert change introduced in 0.54.0(Was not good). insert-mode escape return to normal-mode regardless os autocomplet popup #339.

# 0.54.0:
- Improve, Breaking: When autocomplete's popup is active, `escape` in `insert-mode` no longer escape insert-mode. #339
- New: `TrimString` operator 'g |' for default keymap. #341
- Improve, Breaking: #342 `TransformStringBySelectList` no longer ask target first. Instead ask target last as in normal operator.
- Internal: Let each operator register itself to select-list
- New, Experimental: `incrementalSearchVisitDirection` config option #343
  - Default `absolute`, if `relative`, `visit-next`(tab) follows to search direction(`/` or `?`).
- Improve: Now user can invoke `add-selection` from `visual` mode #340.
- New: Add default keymap `g cmd-d` to `vim-mode-plus:add-selection`.
- Improve, Breaking: Rename `RangeMarker` family operator, text-object to fix naming inconsistency. #346
  - Operator: `MarkRange` to `CreateRangeMarker`
  - TextObject: `MarkedRange` to `RangeMarker`
- Fix: In case vimState is not available(not sure why), cancel execution of operation. #347
- New: Add keymap to make `I` and `A` is available in all visual submode(was available in `visual-block` only in previous version) #348

# 0.53.0:
- Fix: Command is dispatched to different(incorrect) editor instead of editor which fired original event. #338

# 0.52.0:
- Doc: Update links in README.md
- Improve: Suppress error when motion is pushed to operation stack when previous motion had not finished. #327
- Internal: Consolidate vmp specific error class. Avoid inappropriate class inheritance.
- Improve: Prevent unnecessary propagation of event for all vmp commands.
- Doc: Add ISSUE_TEMPLATE.md.
- New: `Y` in visual-mode yank whole line #330.
- Improve, Breaking: `Surround` and `ChangeSurround` trim() white spaces of inner text before surround #331. by @ypresto
- Improve: `ctrl-f` no longer put cursor to EOF instead of vimEOF.
- Improve: Accuracy improved for the position where hover shows up, so `ChangeSurroundAnyPair` shows hover on original cursor position.
- Improve: Notification warning when user enabled both vim-mode and vim-mode-plus #335.

# 0.51.0:
- New: `groupChangesWhenLeavingInsertMode` setting to control whether bundle changes or not when leaving insert-mode #323.
When disabled, changes are not bundled and user can undo more granular level(smaller steps). Default is `true`(same as pure Vim).
- Mention `paner` in helper packages section of README.md since revived!

# 0.50.0:
- Fix: Deprecation warning introduced by new editor.displayLayer #319.
- Support: set minimum engines to 1.9.0 above.

# 0.49.1:
- Fix: Invoking text-object command directly from insert-mode cause uncaught exception #318.

# 0.49.0:
- Improve, Breaking: #314 Allow `move-up-to-edge` and `move-down-to-edge` stops at first or last row even if it char was blank.

# 0.48.0:
- Improve: New command `vim-mode-plus:force-operator-characterwise`, `vim-mode-plus:force-operator-linewise` to change original wise(linewise/charactewise) and toggle exclusiveness #313

# 0.47.0:
- Fix: TextObject a-paragraph did not select trailing blank rows for one-line non-blank paragraph #309
- Breaking: Simplify TextObject comment. now `a /` and `i /` works identically #311

# 0.46.0:
- cosmetic change, my preference about parenthesis has changed.
- Improve: reversing selection by `o` in visual-mode make reversed state sync to lastSelection in multi-selection situation.
- Fix: `ctrl-f`, `ctrl-b`, `ctrl-d`, `ctrl-u`. Just follow the way of vim-mode's fix. It was better than vmp's.
- Doc: Make "disable vim-mode first" instruction standout since not small amount of user reporting issue by enabling both!

# 0.45.0:
- Fix; `.` repeat collectedly replay vB range. #261
- New: Support `activate-normal-mode-once command` #281 suggested by @wangxiexe

# 0.44.1:
- Fix: `ctrl-y`, `ctrl-e`, throw error, and not worked properly, latent bug of vmp become obvious from Atom 1.9.0-beta0
- Improve: Now `3d2w` delete 6(3x2) words instead of 32 words in previous version. #289

# 0.44.0:
- New: Improve % motion, support HTML Tag, and AngleBracket #285
- Fix: `Uncaught TypeError: history.getChangesSinceCheckpoint is not a function` #288

# 0.43.0:
- Fix: Don't throw error when `vr` in empty buffer by avoiding odd state(=visual-mode but selection is empty) #282
- Improve: Refactoring
- New: Operator.PascalCase by @raroman, default keymap is `gC`. pascase-case works like `pascal-case to PascalCase`.
- Improve: `D` in visual-mode should delete whole line #284

# 0.42.0: Big release not for feature, but because default setting change.
- Change Default: `setCursorToStartOfChangeOnUndoRedo` is now enabled by default.
- Change Default: `flashOnUndoRedo` is now enabled by default.
- Cleanup: Remove `pollyFillsToTextBufferHistory` since supported engine is already `>=1.7.0`.
- Cleanup: Remove workaround for AutoIndent of single "\n" since v1.7.2 Atom-core includes this fix. #231
- New: CompactSpaces operator(`g space` by default). To compacts multiple space to single space, not touch leading, trailing spaces #279.

# 0.41.0:
- New: Add service `observeVimStates`, `onDidAddVimState` and `vimState::onDidSetMark` #276

# 0.40.1:
- Breaking: Rename `split-character` to `split-by-character`.
- Fix: `ctrl-y`, `ctrl-e`. Just follow original vim-mode fix. #275

# 0.40.0:
- Improve: Test spec now support more concise keystroke syntax and all spec rewritten to use new keystroke #270
- New: add experimental `startInInsertModeScopes` configuration to selectively start in `insert-mode` for specified scopes.

# 0.39.0:
- Improve: Now selectAllInRangeMarker can pick word from visual selection.
- Improve: selectAllInRangeMarker can switch regex's word boundary option \b based if in visual-mode.
- New: Motion YankToLastCharacterOfLine for user who don't like default `Y` include newline #265.
- New: New setting option to suppress highlightSearch for certain scopes
- Improve: No longer use custom marker property since it's deprecated in v1.9.0 #242
- Improve: Use display-layer methods #242
- Improve: Use clipDirection instead of clip for screenPosition clipping #242
- Fix: `w` now can move to next line in CRLF file #267

# 0.38.0:
- Improve: #259 `*`, `#` now pick search word under cursor in the same manner where selection.selectWord() pick word.
- Breaking: #259 Remove hidden `vim-mode-plus.iskeyword` configuration option.
- Fix: Make `MoveToMark` executable from command-pallate #252, #254.
- Improve: highlightSearch no longer extend highlight marker even when character inserted at intersecting tail.
- Improve: #262 Now `maximize-pane` can maximize none-editor paneItem such as setting-view, markdown-preview.
- Breaking: #262 `maximize-pane` is mapped from `ctrl-w z`(for all) and `cmd-enter`(for mac) by default.
- New: #262 New config `hideTabBarOnMaximizePane`(enabled by default). Disabling it keep tab-bar when maximized.
- Fix: #258 `f` command occasionally throw error, so I simply revert to former code which use panel to attach hidden mini-editor.

# 0.37.1:
- Fix: #258 `f`, `F` fail after paneItem change then back to original paneItem.

# 0.37.0:
- Fix: #252, #254 No longer use input mini editor for single char input for mark
- Internal: make command event accessible via vimState while running command
- Improve: If hide option is set on Input::focus() it don't add Panel
- Fix: #253 fix `r` in vB

# 0.36.0:
- Internal: Eliminate view/model separation for Hover and HoverElement.
- New: `SearchMatchForward`(`gn`), `SearchMatchBackward`(`gN`) text-object. #241
- Fix: Don't clear maximized state when active item changed in same pane #244
- New: AddSelection operator #245
- Dev: add `npm run watch`
- New: Preserve `<`, `>` mark for visual start and end.
- New: PreviousSelection text-object vB still not supported #246
- New: MarkRange operator and MarkedRange text-object #249
- New: Config option to clear HighlightSearch and RangeMarker on `escape` in normal-mode. #250
- Improve: Support `InsertAtStartOfSelection` from vC mode, no longer need to enter vB only for insert at start of selection.
- Breaking: MoveTo(Previous/Next)FoldStart no longer linewise motion.
- New: General insertion operator `MotionByTarget`
- New Experimental new Operator `SetCursorsToStartOfTarget` and MarkedRange precomposed version.
- Internal: Do editorElement className update manually.

# 0.35.1:
- Fix: Ignore `mouseup` event handling on `insert` mode #240

# 0.35.0:
- Internal: Gradually making motion into pure point calculator #225
- Improve: Operate on same range on `.` repeat even if `stayOnTransformString` was enabled #235
- New: MoveToColumn motion. Default keymap is `|`. #230
- Improve: `dblclick` correctly activate visual mode, simplify mouse event observer. #228
- Improve: Better integration with Atom's native commands(e.g `cmd-l`) #239

# 0.34.0:
- Fix: `gg`, `GG` throw error when destination row was blank line. #233
- Fix: Critical bug TextBuffer.history pollyfilled multiple times because of incorrect guard #229

# 0.33.0:
- Support: set minimum engines to 1.7.0 above.
- Internal: Cleanup blockwise-selection.
- Internal: Now modeManager::activate take only true mode(no longer handle `reset`, `previous` as former version).
- Breaking: Rename `activate-previous-visual-mode` to `select-previous-selection`
- Experiment: Trying to not depend on atom's Selection::selectWord. #225
- Experiment: Trying being independent from atom's imperative cursor motion. #225
- Breaking: #224 remove Move(Up|Down)ToNonBlank
- Fix: Don't move cursor up when inserting single white space at column 0 #226
- Fix: To support Atom v1.7.0, polyfill for TextBuffer::history.getChangesSinceCheckPoint #229
- Fix: `cc`, `S` ignore auto indent on Atom v1.7.0 #231

# 0.32.1:
- Fix: Uncaught error on `y`, `gU` etc.. in `vB` when `stayOnYank`, `stayOnOperator` enabled #221.

# 0.32.0:
- Improve: Further coverage of `gv` support. Not yet complete but much better.
- Improve: Respect `stayOnYank`, `stanOnOperate` on `visual-mode` #221
- Fix: `TransformStringByExternalCommand` throw error on `OperationStack::finish` because of incorrect argument.
- Fix: Correctly unfocus input mini editor when `SurroundAnyPair` can't find(detect) pair chars..
- Internal: Update charactewrise selection properties in `visual-mode` selection modification by Motion, TextObject.
- Improve: Don't flash in `visual-mode` even if `flashOnOperate` have enabled.

# 0.31.0:                   
- Fix: Guard for calling `refreshHighlightSearch` against destroyed editor #196
- Internal: Quit model, view separation for `Input` and `SearchInput`
- Rename: `misc-commands.coffee` to `misc-command.coffee`
- Internal: move `scroll.coffee` code to `misc-command.coffee`
- New: add `SmartWord` based motions(`MoveToNextSmartWord`, `MoveToPreviousSmartWord`, `MoveToEndOfSmartWord`)
- Fix: `goalColumn` incorrectly reset on `vL` mode. #220
- Improve: keep `goalColumn` in `vL` to `vC`, `vC` to `n`.

# 0.30.0
- Fix: No longer necessary to set `editor.useShadowDOM` enabled to use vmp #218
- New: [Experimental] Set `yank-pending`, `delete-pending` scope for granular keymap setting #215.

# 0.29.0
- Improve: cleanup `operation-stack.coffee`
- Internal: New convention. use `Operator::mutateSelection`
- Improve: Reduce complexity for MoveToNextWord #200
- Internal: improve Base::countTimes pass isLast as 2nd arg
- Fix: For `$` motion with count now correctly move to end of line of Nth line blow.
- Improve: Now support all motion in `visual-blockwise` #213
- Internal: Remove many visual-blockwise special code #213

# 0.28.0
- Internal: Each command class can answer its description.
- Internal: Generate summary table for all commands.
- Internal: Remove VisualBlockwise class #210.
- Improve: `c` on visual-blockwise now keep multi-cursors.
- Fix: null guard in case Patch is not yet available for >=Atom v1.7.0-beta0

# 0.27.0
- Internal: Refactoring many parts(Search, MatchList, ModeManager, OperationStack) #200
- Improve: Support upcoming Atom 1.7+ text-buffer change #206, #203
- New: New Motion for alphaNumeric word family #207
  - MoveToNextAlphanumericWord for `w`
  - MoveToPreviousAlphanumericWord for `b`
  - MoveToEndOfAlphanumericWord for `e`
- Fix: Tweak L(MoveToBottomOfScreen) motion don't cause scroll.
- Internal: Reuse Select, CurrentSelection instance, hope improve #162
- Internal: Introduce Sugar methods on Base.prototype for instanceof check

# 0.26.1
- Fix: `n`, `N` in different editor cause `flashScreen` is not function.

# 0.26.0
- Breaking: Remove scroll among search matched feature #201
- Breaking: Literal input mode in Search input field is now achieved by standard selector-specific keymap.
 User who used this feature in older version need to update keymap selector to `atom-text-editor.vim-mode-plus-search:not(.literal-mode)`.
 See example in [wiki/Keymap-example](https://github.com/t9md/atom-vim-mode-plus/wiki/Keymap-example)
- Internal: cleanup `Search`, `SearchCurrentWord`.
- Fix: Use new pane split feature from Atom v1.6.0 #204
- Support: set minimum engines to 1.6.0 above #204
- Breaking: Remove semi-broken `disableInputMethodExceptInsertMode` setting #205
- Fix: `o` after `Vjj` then `cmd-shift-d` display cursor incorrect position(cosmetic). #202

# 0.25.0
- Improve: #192 Keep original visible area as much as possible when scrolling by `n`, `N`, `/`, `?` to avoid mental context switching
- New: delete/change-any-pair-allow-forwarding. More powerful version of existing `change-surround-any-pair` and `delete-surround-any-pair` #194
- Improve: #195 keep code layout when `surround`, `delete-surround`, `change-surround`. former implementation mechanically `trim()` white space of inner string.

# 0.24.0
- Fix: Inconsistency for changed area for `P`, `p`. And respect original newline on EOF.
- New: `PutAfterAndSelect` and `PutBeforeAndSelect` to paste and select #184
- New: allow-forwarding text-object #188
- Spec: Improve test coverage for `%` motion
- Improve: Fix several minor bug for `%` motion.
- Improve: Fix several minor bug for pair text-object.
- Fix: Now `c` can enter insert mode even if target is empty. #189
- Fix: Don't treat double backslash \\ as escape char in TextObject.Pair family #191
- New: `innerTag` and `aTag` text object. #84

# 0.23.0
- Fix: setHover error. Guard when `vimState::getBlockwiseSelections()` is empty.
- Fix: `ctrl-v` then `j` throws error "Cannot read property 'getHead' of undefined" #179
- New: `SwapWithRegister` operator to complement `v_p` and `v_P` in pure Vim #180. keymap is disabled by default.
- Internal: Greatly simplify cursor offset calculation by using `Point::traveralFrom()`
- Fix: visual-blockwise `j`, `k` always work bufferRow-wise and never past BOL and EOL #10.
- New: new config options `ignoreCaseForSearch`, `ignoreCaseForSearchCurrentWord`, `useSmartcaseForSearchCurrentWord` #181

# 0.22.1
- Fix: Quick fix for degradation for issue cursorDOM node is not exits #178

# 0.22.0
- New: Add space when surround if input char is in `charactersToAddSpaceOnSurround`. #171
- Improve: Cancel search when tab was switched in the middle of searching.
- Internal: cmd keystroke support for spec helper
- Improve: Warn user when useShadowDOM disabled #177
- Fix: Prevent ReplaceModeBackspace is invoked except from replace-mode #175

# 0.21.3
- Fix: subscription leak for highlightSearch #158
- Improve: blockwiseSelection, `getHeight()`, `setSelectedBufferRanges()`.
- New: `vimState.getBlockwiseSelections()`
- Fix: Hover place was incorrect when visual-blockwise and its selection is reversed.
- Internal: Avoid mode change within visual-blockwise and remove dirty `operation.isProcessing()` guard in `modeManager::restoreCharacterwise()`
- Fix: `MoveToFirstCharacterOfLineDown` and `Up` shold work as buffer-positoin-wise. #166

# 0.21.2
- Fix: #161 `gv` not re-select last selection after Yank in visual-mode.
- Fix: #163 occasional `Uncaught TypeError: event.target.getModel is not a function` when executing vmp commands.

# 0.21.1
- Internal: cleanup blockwiseSelection.
- Fix: #158 When highlight cleared, it should not highlighted again on refreshing event(scroll, switch pane).
- Fix: #158 Maker default flash color transparent(fadeout 50%) to not hide overlapping text when text color is same as flash color.

# 0.21.0
- Fix: Bump up engines version to atom 1.4.0 above.
- Fix: In visual-linewise, position of hover indicator was incorrect.
- New: highlight last search pattern across all buffer. #158
  - `highlightSearch` config parameter to enable/disable.
  - `vim-mode-plus:toggle-highlight-search`: to toggle `highlightSearch` config value.
  - `vim-mode-plus:clear-highlight-search`: one-time clearing for highlightSearch. equivalent to `:nohlsearch` in pure Vim.
- Fix: Guard for case when editorElement.component is not available #98

# 0.20.0
- Fix: Search flash no longer flash multiple word simultaneously. #153
- Fix: `flashOnSearch` configuration parameter was not checked on flash. - @crshd
- Fix: `dw`, `dW` don't go beyond EOL on last movement in single transaction.  #150
- Fix: Respect and observe `editor.lineHeight` and refresh cursorStyle on change #154. - @crshd, @t9md
- Internal: New dev-mode command `toggle-reload-packages-on-save` to reload vmp on buffer save.
- Internal: New dev-mode command `reload-packages` to reload vmp and vmp plugins
- Internal: Making vmp package hot reload-able to make development easier.
- New: Provide css id for status-bar container so that user can hide status information completely #152
- New: New options to disable Input Method(IME) except insert-mode #148.
- Improve: Full-support for multiple blockwise selections, each blockwise selections are kept in vimState.blockwiseSelections.

# 0.19.1
- Internal: Allow Operation specific command scope #147.
- Internal: New `swrawp::switchToLinewise()` util to switch selection temporarily.
- Internal: Now `countTime()` is Base methods.
- Internal: Remove `toggleClassByCondition()` utils. Instead, use native `classList.toggle()`.
- Internal: `swrap::translate()` function arguments was inconsistent with wrapping `Range::translate()` function.

# 0.19.0
- Breaking: Remove `move-line-up`, `move-line-down`, it is externalized as `move-selected-text` plugin package #145.
- New: `Operator::execute()` now can do asynchronous operation(can return instance of Promise). #146.
- Internal: Consolidate `counter-manager.coffe` into vimState.
- Improve: Several refactoring. spec-helper keystroke now support `waitsForFinish` to wait operationFinish for asynchronous operation.

# 0.18.2
- Bug: `TransformStringBySelectList` fail because of un-registered `SortNumerical` member left by development.

# 0.18.1
- Internal: Fix naming inconsistency
- New: Provide `getCommand`, `getStdin`, `getStdout` as hook for `TranformStringByExternalCommand`
- Improve: Error handling for `TranformStringByExternalCommand`.
- New: `TransformString::getNewText` pass selection as 2nd args.
- New: #143, suspend/unsuspend execution of operation to make async method involved operation repeatable.

# 0.18.0
- New: TranformStringByExternalCommand #140
- Doc: Update old wiki link in Readme
- Improve: Use more accessible displayName for `TransformStringBySelectList`
- Internal: No longer use short variable name like `c` for cursor, `s` for selection .
- Internal: Refactoring. extract restorePoint logic from Operator::eachSelection method.
- Internal: Provide wrapper function `Base.processOperation()`, `Base.cancelOperation()` to controll operationStack.
- New: #142 Support per selection clipboard for `Change`, `Delete`, `Yank` operation.
- Fix: #141, For `Change` operation, if target is TextObject, it auto-detect target's wise(linewise, characterwise)

# 0.17.0
- New: InsertByMotion can insert after move, and repeatable.
- New: Support insert count e.g `10iabc`, `10oabc`.
- Spec: #137 dot register, insertion count,  insert-last-inserted
- New: TextObject.SmartWord which is just include dash(-) char into `\w`
- New: SurroundSmartWord is pre-targeting InnerSmartWord
- New: Operator EncodeUriComponent, DecodeUriComponent
- New: Operator TitleCase
- New: #139 support SelectList UI
- New: #138, #139 Operator TransformStringBySelectList transform string by choice

# 0.16.0
- Fix: Don't change submode from `characterwise` to `linewise` automatically #131.
- Internal: new `TextObject::allowSubmodeChange` property control automatic submode shift from selected range.
- New: Fix: As part of fix from Atom v1.4.0 change, Paragraph motion was completely rewritten, now more compatible behavior to pure Vim.
- New: Configuration parameter `flashOnOperateBlacklist` allow disable flash for specific operation.
- Improve: Now `move-to-blank`, `move-to-edge` works correctly for hardTab language buffer like golang.

# 0.15.0
- Improve, New: TextObjet.Fold can expand when repeated!
- Improve: Spec for TextObject.Fold, Motion.MoveUpToEdge
- New: `insert-at-previous-fold-start`, `insert-at-next-fold-start`
- New: `move-to-position-by-scope` as parent class of every scope based motion.
- New: `move-to-next-string`, `move-to-previous-string`
- New: `move-to-next-number`, `move-to-previous-number`
- Internal: Reporting command in dev-mode which report commands which have no default keymap.
- FIX: Disable strict check of non-empty selection in normal-mode at the timing of operation finished. #123.

# 0.14.1
- Fix: `I` doesn't go to first char if already there. #122.

# 0.14.0
- New: Misc.Maximize-pane command from my `paner` package.
- Fix: Selecting big text object(its range is not fit in one screen) lost cursor marker #109.
- Breaking: BracketMatchingMotion is completely rewritten and renamed to MoveToPair(move-to-pair).
- Internal: TextObject Pair improved(pre-split pairChars, provide more granular range info) #113.
- Improve: Improve error message in OperationStack throw error related to #114.
- Improve: TextObject.Pair don't select first line when its text is opening pair char only #111.
- Internal: New convention all TextObject must implement selectTextObject function.
- New: Move(Up|Down)ToEdge to moveUP/Down only edge row.
- New: MoveTo(Previous|Next)FoldStartWithSameIndent. to skip different indentation row.
- Internal: commands for speedup development.
- FIX: `e`, `E` should skip blank line #117.
- FIX: `w`, `W` moved to endOfWord instead of beginningOfWord when cursor is trailing white space.
- FIX: `dk` not delete blank line if cursor is at blank row #118.
- FIX: `j`, `k` in visual-linewise should not expand folds, but was expanded #120.
- Internal: Refactor `Motion::selectInclusive()` now almost finished!
- New: Base.commandPrefix class variable is used as command name prefix(for user's custom command use).
- New: Operator.Reverse to reverse selected lines.

# 0.13.0
- New: Motion move-(up|down)-to-non-blank to move up/down by skipping blank characters #101.
- New: Motion move-to-(previous|next)-fold-(start|end) to move around code folds #102
- FIX: TextObject Paragraph and its child class get called getRange with negative row number fix #99
- FIX: When last line have no newline("\n") char, cursor marker shown at incorrect place #100
- FIX: Select operator should not be repeatable, but was repeatable(that cause unexpected error).
- FIX: When `r`(replace operator) in visual-blockwise mode cause `Selection is not empty in normal-mode` error #104
- Internal: move ModeManager::replaceModeBackspace to Misc commands
- Internal: Service API no longer expose vim-mode-plus's subscriptions
- Internal: New `Base.reset()` class method to reload all commands to speed up development process.

# 0.12.0
- Internal: cleanup cursor movement in `Motion::selectInclusive()` #87
- Internal: remove flashManager class. move flashManager feature to utils.coffee.
- Internal: spec-helper mini DSL now can check characterwiseHead in `V` scenario. #90
- FIX: Stacktrace is not displayed for OperationStackError.
- FIX: When shift from visual-blockwise to other modes, cursor marker get odd. #71
- Breaking: remove `vim-mode-plus:set-count`, and provide distinct `vim-mode-plus:set-count-1` and alike #63
- Improve: Accuracy improved for cursor movement in visual-linewise for `*`, `#`, `/`, `?` commands. #91
- FIX: TextObject CurrentLine should work on bufferRow instead of screenRow #95
- FIX: goalColumn is not respected in visual-line `j`, `k` on soft-wrapped line #96
- FIX: visual-linewise cursor marker is incorrect in soft-wrapped line. #97
- Internal: visual mode's cursor display functions are separated from vimState into cursorStyleManager #97

# 0.11.0
- FIX: #86 Repeating text-object targeted operation(e.g. `ciw` then `.`) incorrectly activate characterwise visual-mode.
- FIX: Work around issue #85 issue vim-mode-plus with term2 package.
- NEW: support characterwise movement in visual-linewise mode #74, #83.

# 0.10.2
- FIX: When buffer is soft-wrapped and in visual-characterwise mode, moving selection put cursor on incorrect position #81
- FIX: `wrapLeftRightMotion` parameter is not respected in visual-mode and soft-wrapped buffer's normal-mode. #82

# 0.10.1
- FIX: Critical degradation, when selection whole buffer with `cmd-a`, exception thrown.

# 0.10.0 [CAUTION] Surround operation keystroke changed.
- Breaking: Surround take target before reading surround-char #75
  - ex-1: `ys` mapped to `vim-mode-plus:surround`
    - old: `ys(iw`
    - new: `ysiw(`
  - ex-2: `ms` mapped to `vim-mode-plus:map-surround`
    - old: `ms(ip`
    - new: `msip(`
- Breaking: Remove default keymap of surround like `gss`, `gsw`, `gsd`, `gsc`.
- FIX: `gg` and `G` should go to buffer line instead of screen line.
- FIX: SelectLatestChange didn't correctly restore visual submode.
- FIX: Increment, Decrement didn't clear selection on finished.
- FIX: `v` , `escape` on empty-line put cursor one-line down in corner case #70
- FIX: degradation, `G` should use bufferRow than screenRow.
- Improve: `a` check cursor.isAtEndOfLine() for each cursor in multi-cursor.
- Improve: When Surround target is linewise area, it insert line break char #78.
- Internal: Cleanup selection, cursor adjustment for consistent moveCursor behavior in both normal and visual mode #73.
- Internal: Remove debug feature for OperationStack #72
- Internal: Now throw error when selection is not empty in normal-mode at operation finished to strictly catch unexpected operation result.
- Internal: `dd`, `yy`, `gUgU` like sequential operation support now done in OperationStack.
- Improve: Visual characterwise mode keep tailRange correctly when selection is indentation white spaces char. #79
- Internal: Separate big spec files into small topic based spec file.

# 0.9.1
- Further accuracy improve for cursor not past last newline #56.
- BUG: V, escape on empty-line put cursor one-line down than expected row #70

# 0.9.0
- Improve: Tweak default add/change color of undo/redo operation.
- FIX: Cursor visibility in `cmd-d` operation. #55
- FIX: Cursor visibility in visual-line mode on last line of buffer.
- FIX: Change operator wasn't atomic(not in one transaction) in multi-cursor #57.
- FIX: SurroundWord operator eat extra whitespace. #58
- New: MapSurround operator to apply surround operation to each word in targeted area.
- New: ToggleFold misc command to toggle fold at cursor row. Default keymap is `za`
- FIX: F/T should be exclusive(exclude char under cursor) when used as operator's target but was inclusive. #62
- FIX: Add keymap `down`, `up` in visual-block-mode #64
- Internal: Revival of once removed atom.commands.onDidDispatch observation to track selection change.
- Improve: Accuracy improve for behavior when setCursorToStartOfChangeOnUndoRedo is enabled.
- New: LatestChange text-object. Which area is defined between `[` and `]` marker.
- Breaking: Rename `vim-mode-plus:split` to `vim-mode-plus:split-string` to avoid confusion.
- Don't allow cursor past last newline by vim-mode-plus's operation #56.

# 0.8.0
- New: provideVimModePlus service API now provide Base class and subscriptions.
- Internal: Remove dynamic derivation for (a, inner) TextObject for consistency.
- Doc: Most of sections are moved to vim-mode-plus Wiki and remove old documents.
- Improve: Change operator properly update change marker(`[`, `]`)
- Internal: Refine definition for what `isComplete()` is.
- New experiment: Split operator to split selected line by string entered.
- New experiment: Performance effective(in big buffer) version of move-line-up/down operator.
- Internal: Remove direct referencing to settings parameter in hover instance.
- Improve: hover can show input char even in oneChar input operator like Surround.
- Improve: hover sync text when multi-char input text is deleted for operator like ChangeSurround. #42
- New improve: [Experimental] Show cursor position in visual-linewise. #45
- Improve: Change won't enter insert-mode if target object is not found like in case `ci(` failed.
- Improve: All Pair text-object properly select text-object in case char under cursor is closing pair. #48
- FIX: Prevent vim-mode-plus's command become available in mini-editor. #50
- FIX: `p`, `P` insert extra newline when line ending is CRLF #49.
- FIX: `dd`, `dk` remove extra line when its executed last line of buffer. #43

# 0.7.1
- Improve cursor position on Undo/Redo when setCursorToStartOfChangeOnUndoRedo is enabled.

# 0.7.0
- FIX: hover didn't cleared when `;` was repeated without previous find.
- Improve: Flasher.flash do simply flash removed callback args for simplicity.
- New: Introduce onDidSelect, onWillSelect, onDidOperationFinish internal event system.
- Improve: Now most of operation is child of TransformString class
- Breaking: deprecated parameter 'stayOnIndent', 'stayOnReplaceWithRegister', merged to 'stayOnTransformString'
- New: Introduce `g J`  join-with-keeping-space commands
- New: Introduce JoinByInput, JoinByInputWithKeepingSpace(default no keymap) [experimental]
- New: Option to put cursor start of change on Undo/Redo
- New: Option to flash on Undo/Redo(green: addded, red: removed) by option flashOnUndoRedo
- New: Support mark `[`, `]` which is updated on yank and change.
- New: select-latest-change command select range from mark `[`, `]`) command(no keymap by default)
- New: track change when insert-mode repeated.

# 0.6.1
- FIX: Paste fail when flashOnOperate was disabled. #38

# 0.6.0
- FIX: incorrect cursor position when escaped from visual-linewise
- Improve: operator.coffee is now more readable by power of @eachSelection abstracts final cursor position handling.
- New: stayOnReplaceWithRegister, stayOnYank, stayOnIndent to stay same cursor position after operation finished.
- Improve: InsertLastInserted is now accurate by refactoring ActivateInsertMode and its descendants.

# 0.5.0
- FIX: spec bug, revealed by validating spec-helper's mini-DSL options.
- Improve: Lots of test spec refactored.
- Improve: Refactoring TransactionBundler used in ActivateInsertMode.
- New: [Experimental] introduce increment/decrement operation `g ctrl-a`, `g ctrl-x`.
- FIX: incremental-search throw error: findFoldMarkers need explicit filter query object from Atom 1.3.0.
- New: [Experimental] new InsertLastInserted in insert-mode(ctrl-a in pure Vim).
- New: keymap `ctrl-h` in replace-mode.

# 0.4.0
- Add spec for visual-blockwise to visual-characterwise shift
- New: `^` mark which store last insert-mode position.
- New: `gi` to start insert-mode from last-insert position(`^` mark).
- New: when count is specified `with-count` selecter is set on editorElement
- New: when register is specified `with-register` selecter is set on editorElement
- New: `N%` motion N is count. In 100L buffer, `50%` move cursor to 50L.
- New: `gv` support all sumbmode(characterwise, linewise, blockwise).
- New: `increase`, `decrease` support in visual-mode which greatly extends usage of these commands.
- Tweak: don't clear multi-selection when from char-2-block if only selection is single line, this allow `cmd-d`, `ctrl-v`, `I`(or `A`) work.

# 0.3.0
- FIX: #31 RepeatSearch(`n`) commands repeat last search regardless success or not.
- No longer add commands per editorElement, commands are added on activate phase once.
- Now each operations(TextObject, Motion, Operator etc) can registerCommands().
- Base.init() do all necessary initialization.
- Improve BlockwiseSelect when softwrapped.
- Add spec for visual-blockwise mode.

# 0.2.0
- Cleanup: globalState no longer instance of class, and nor property of vimState, since its global. It should be treated as like settings.
- New: #24 now folds kept closed when selection go over folded area. l, h expand folds as like Vim.
- Recorded operation history is no longer extended infinitely, just keeping one lastRecordedOperation is enough.
- Remove old meaningless(anymore) pushSearchHistory, getSearchHistoryItem on vimState.
- Move misc commands(like vimState::reverseSelection) to separate misc-commands.coffee so now processed by operationStack good for consistency.
- Support count for BlockwiseMoveUp and BlockwiseMoveDown.

# 0.1.11
- FIX #26: incorrect cursor position when escaped from visual-blockwise mode.
- FIX #27: Coludn't escape from visual-mode if non-left mouse button is used during drug. Thanks @jackcasey for first PR.
- Refactoring: visual-blockwise and fix corner case bug in shift submode within visual-mode.
- Refactoring: Cleanup mode-manager.coffee, now use Disposable::dispose when deactivating old mode etc...

# 0.1.10
- Now warn to console if duplicate constructor name is used, this is only for safe guard when developer add new TOM.
- Improve accuracy of TextObject.Function for language which have `meta.function` scope.
- Lots of cleanup/refactoring
- Now commands are dispatched via vimState::dispatchCommand which translate command name to klassName with special translation for TextObject

# 0.1.9
- Explicitly {autoscroll: false} when selection modified by `j`, `k` to avoid tail of selection on each movement. #23
- Partially implemented to not expand fold when selection across folded area. folds are expanded by `l`, `h` movement.
- Add keymap for home, end key.

# 0.1.8
- FIX deprecation warning for Atom 1.1.0
- Bump supported engines to >=1.1.0
- FIX zs ze broken
- FIX c-f, c-b, c-u, c-d broken after Atom 1.1.0, Fix in 0.1.7 was quick fix and not appropriate behavior.

# 0.1.7
- New config option to disable 'flashScreenOnSearchHasNoMatch'.
- Don't use atom.commands.onDidDispatch.
- FIX: selectBlockwise select incorrect range in some situation.
- clear hover if ChangeSurroundAnyPair fail to find pair
- FIX: c-f,c-b,c-u,c-d broken after upgrading Atom 1.1.
- FIX: visual block $A operation put cursor on beginning of next line.

# 0.1.6
- FIX:￼ shift from visual-char2block incorrectly add extra selection when rows contain blank row.
- FIX:￼ p and P didn't correct replace text in visual-linewise mode.

# 0.1.5
- FIX: In softwrapped line, moveDown/moveUp fail in visual-linewise mode.

# 0.1.4
- FIX: cursor not when activate visual-blockwise with one clumn selection.
- FIX: move-down, move-up on visual-blockwise throw error when not have tail.
- Revival once disabled text-object quote to select forwarding range.
- New: TextObject.AnyQuote select any next AnyQuote within line.

# 0.1.3
- Now all TextObject Pair can expand selection.
- Fix TextObject AnyPair incorrectly expand selection when it fail to find pair.

# 0.1.2
- Add default keymaps on incremental search element for arrow and tab keys.
- FIX: debug feature was broken
- FIX:#4 select area when TextObject is executed via command-pallate(was throw err).

# 0.1.1
- 1st public release

# 0.1.0
- 2015.9.21 rename vim-mode to vim-mode-plus

# 0.0.0
- 2015.8.1 forked from vim-mode.

---

## 0.57

* Added replace ('R') mode! - @jacekkopecky
* Added the `iW` and `aW` text objects! - @jacekkopecky
* Made the 't' operator behave correctly when the cursor was already on the  
  searched  character - @jacekkopecky
* Fixed the position of the cursor after pasting with 'p' - @jacekkopecky

## 0.56

* Renamed 'command mode' to 'normal mode' - @coolwanglu

## 0.55

* Fixed indentation commands so that they exit visual mode - @bronson
* Implemented horizontal scrolling commands `z s` and `z e` - @jacekkopecky

## 0.54

* Fixed an error where repeating an insertion command would not handle
  characters inserted by packages like autocomplete or bracket-matcher - @jacekkopecky

## 0.53

* Fixed an exception that would occur when using `.` to repeat in certain cases.

## 0.52

* Fixed incorrect cursor motion when exiting visual mode w/ a reversed
  selection - @t9md
* Added setting to configure the regexp used for numbers and the `ctrl-a`
  and `ctrl-x` keybindings - @jacekkopecky

## 0.50

* Fixed cursor position after `dd` command - @bronson
* Implement `ap` text-object differently than `ip` - MarkusSN

## 0.49

* Fixed an issue that caused the cursor to move left incorrectly when near
  the end of a line.

## 0.48

* Fixed usages of deprecated APIs

## 0.47

* Fixed usages of deprecated APIs - @hitsmaxft, @jacekkopecky

## 0.46

* Fixed issues with deleting when there are multiple selections - @jacekkopecky
* Added paragraph text-objects 'ip' and 'ap' - @t9md
* Fixed use of a deprecated method - @akonwi

## 0.45

* Added `ctrl-x` and `ctrl-a` for incrementing and decrementing numbers - @jacekkopecky
* Fixed the behavior of scrolling motions in visual mode - @daniloisr

## 0.44

* Fixed issue where canceling the replace operator would delete text - @jacekkopecky
* Implemented repeat search commands: '//', '??', etc - @jacekkopecky
* Fixed issue where registers' contents were overwritten with the empty string - @jacekkopecky

## 0.43

* Made '%', '\*' and '\#' interact properly with search history @jacekkopecky

## 0.42

* Fixed spurious command bindings on command mode input element - @andischerer

## 0.41

* Added ability to append to register - @jacekkopecky
* Fixed an issue where deactivation would sometimes fail

## 0.40

* Fixed an issue where the search input text was not visible - @tmm1
* Added a different status-bar entry for visual-line mode - @jacekkopecky

## 0.39

* Made repeating insertions work more correctly with multiple cursors
* Fixed bugs in `*` and `#` with cursor between words - @jacekkopecky

## 0.38

* Implemented change case operators: `gU`, `gu` and `g~` - @jacekkopecky
* Fixed behavior of repeating `I` and `A` insertions - @jacekkopecky

## 0.36

* Fixed an issue where `d` and `c` with forward motions would sometimes
  incorrectly delete the character before the cursor - @deiwin

## 0.35

* Implemented basic version of `i t` operator - @neiled
* Made `t` motion repeatable with `;` - @jacekkopecky

## 0.34

* Added a service API so that other packages can extend vim-mode - @lloeki
* Added an insert-mode mapping for ctrl-u - @nicolaiskogheim

## 0.33

* Added a setting for using the system clipboard as the default register - @chrisfarms

## 0.32

* Added setting for allowing traversal of line breaks via `h` and `l` - @jacekkopecky
* Fixed handling of whitespace characters in `B` mapping - @jacekkopecky
* Fixed bugs when using counts with `f`, `F`, `t` and `T` mappings - @jacekkopecky

## 0.31

* Added '_' binding - @ftwillms
* Fixed an issue where the '>', '<', and '=' operators
  would move the cursor incorrectly.

## 0.30

* Make toggle-case operator work with multiple cursors

## 0.29

* Fix regression where '%' stopped working across multiple lines

## 0.28

* Fix some deprecation warnings

## 0.27

* Enter visual mode when selecting text in command mode
* Don't select text after undo
* Always preserve selection of the intially-selected character in visual mode
* Fix bugs in the '%' motion
* Fix bugs in the 'S' operator

## 0.26

* Add o mapping in visual mode, for reversing selections
* Implement toggle-case in visual mode
* Fix bug in 'around word' text object

## 0.25

* Fixed a regression in the handling of the 'cw' command
* Made the replace operator work with multiple cursors

## 0.24

* Fixed the position of the cursor after certain yank operations.
* Fixed an issue where duplicate vim states were created when an editors were
  moved to different panes.

## 0.23

* Made motions, operators and text-objects work properly in the
  presence of multiple cursors.

## 0.22

* Fixed a stylesheet issue that caused visual glitches when vim-mode
  was disabled with the Shadow DOM turned on.

## 0.21

* Fix issue where search panel was not removed properly
* Updated the stylesheet for compatibility with shadow-DOM-enabled editors

## 0.20
* Ctrl-w for delete-to-beginning-of-word in insert mode
* Folding key-bindings
* Remove more deprecated APIs

## 0.19.1
* Fix behavior of ctrl-D, ctrl-U @anvyzhang
* Fix selection when moving up or down in visual line mode @mdp
* Remove deprecated APIs
* Fix interaction with autocomplete

## 0.19
* Properly re-enable editor input after disabling vim-mode

## 0.17
* Fix typo

## 0.16
* Make go-to-line motions work with operators @gittyupagain
* Allow replacing text with newlines using `r` @dcalhoun
* Support smart-case in when searching @isaachess

## 0.14
* Ctrl-c for command mode on mac only @sgtpepper43
* Add css to status bar mode for optional custom styling @e-jigsaw
* Implement `-`, `+`, and `enter` @roryokane
* Fix problem undo'ing in insert mode @bhuga
* Remove use of deprecated APIs

## 0.11.1
* Fix interaction with autocomplete-plus @klorenz

## 0.11.0
* Fix `gg` and `G` in visual mode @cadwallion
* Implement `%` @carlosdcastillo
* Add ctags keybindings @tmm1
* Fix tracking of marks when buffer changes @carlosdcastillo
* Fix off-by-one error for characterwise puts @carlosdcastillo
* Add support for undo and repeat to typing operations @bhuga
* Fix keybindings for some OSes @mcnicholls
* Fix visual `ngg` @tony612
* Implement i{, i(, and i" @carlosdcastillo
* Fix off by one errors while selecting with j and k @fotanus
* Implement 'desired cursor column' behavior @iamjwc

## 0.10.0
* Fix E in visual mode @tony612
* Implement `` @guanlun
* Fix broken behavior when enabling/disabling @cadwallion
* Enable search in visual mode @romankuznietsov
* Fix end-of-line movement @abijr
* Fix behavior of change current line `cc` in various corner cases. @jcurtis
* Fix some corner cases of `w` @abijr
* Don't hide cursor in visual mode @dyross

## 0.9.0 - Lots of new features
* Enable arrow keys in visual mode @fholgado
* Additional bindings for split pane movement @zenhob
* Fix search on invalid regex @bhuga
* Add `s` alias to visual mode @tony612
* Display current mode in the status bar @gblock0
* Add marks (m, `, ') @danzimm
* Add operator-pending mode and a single text object (`iw`) @nathansobo, @jroes
* Add an option to start in insert mode @viveksjain
* Fix weird behavior when pasting at the end of a file @msvbg
* More fixes for corner cases in paste behavior @SKAhack
* Implement * and # @roman
* Implement ~ @badunk
* Implement t and T @udp

## 0.8.1 - Small goodies
* Implement `ctrl-e` and `ctrl-y` @dougblack
* Implement `/`, `?`, `n` and `N` @bhuga
* Registers are now shared between tabs in a single atom window @bhuga
* Show cursor only in focused editor @tony612
* Docs updated with new methods for entering insert mode @tednaleid
* Implement `r` @bhuga
* Fix `w` when on the last word of a file @dougblack
* Implement `=` @ciarand
* Implement `E` motion @tony612
* Implement basic `ctrl-f` and `ctrl-b` support @ciarand
* Added `+`, `*` and `%` registers @cschneid
* Improved `^` movement when already at the first character @zenhob
* Fix off-by-one error for `15gg` @tony612

## 0.8.0 - Keep rocking
* API Fixes for Atom 0.62 @bhuga
* Add `$` and `^` to visual mode @spyc3r
* Add `0` to visual mode @ruedap
* Fix for yanking entire lines @chadkouse
* Add `X` operator @ruedap
* Add `W` and `B` motions @jcurtis
* Prevent cursor left at column 0 when switching to insert mode @adrianolaru
* Add pane switching shortcuts see #104 for details @dougblack
* Add `H`, `L` and `M` motions @dougblack

## 0.7.2 - Full steam ahead
* Leaving insert mode always moves cursor left @joefiorini
* Implemented `I` command @dysfunction
* Restored `0` motion @jroes
* Implemented `}` motion to move to previous paragraph @zenhob
* Implement `gt` and `gT` to cycle through tabs @JosephKu
* Implement visual linewise mode @eoinkelly
* Properly clear selection when return to command mode @chadkouse

## 0.7.1 - User improvements
* `ctrl-[` now activates command mode @ctbarna
* enter now moves down a line in command mode @ctbarna
* Documentation links now work on atom.io @michaeltwofish
* Backspace now moves back a space in command mode @Tarrant
* Fixed an issue where cursors wouldn't appear in the settings view.

## 0.7.0 - Updates for release
* Update contributing guide
* Update package.json
* Require underscore-plus directly

## 0.6.0 - Updates
* Implemented `.` operator, thanks to @bhuga
* Fix putting at the end of lines, thanks to @bhuga
* Compatibility with Atom 0.50.0

## 0.5.0 - Updates
* Switches apm db to buttant from iriscouch

## 0.4.0 - Updates
* Compatibilty with Atom 26

## 0.3.0 - Visual and Collaborative
* Compatiblity with atom 0.21
* Characterwise visual-mode!
* System copy and paste are now linked to the `*`
* Implement `A` operator
* Bugfixes concerning `b` and `P`

## 0.2.3 - Not solo anymore

* Major refactoring/cleanup/test speedup.
* Added `S` command.
* Added `C` operator.
* Proper undo/redo transactions for repeated commands.
* Enhance `G` to take line numbers.
* Added `Y` operator.
* Added `ctrl-c` to enter command mode.

## 0.2.2

* Added `s` command.
* Added `e` motion.
* Fixed `cw` removing trailing whitepsace
* Fixed cursor position for `dd` when deleting blank lines

## 0.2.1

* Added the `c` operator (thanks Yosef!)
* Cursor appears as block in command mode and blinks when inserting (thanks Corey!)
* Delete operations now save deleted text to the default buffer
* Implement `gg` and `G` motions
* Implement `P` operator
* Implement `o` and `O` commands

## 0.2.0

* Added yank and put command with support for registers
* Added `$` and `^` motions
* Fixed repeats for commands and motions, ie `d2d` works as expected.
* Implemented `D` to delete through the end of the line.
* Implemented `>>` and `<<` indent and outdent commands.
* Implemented `J`.
* Implemented `a` to move cursor and enter insert mode.
* Add basic scrolling using `ctrl-u` and `ctrl-d`.
* Add basic undo/redo using `u` and `ctrl-r`. This needs to be improved so it
  understands vim's semantics.

## 0.1.0

* Nothing changed, used this as a test release to understand the
  publishing flow.

## 0.0.1

* Initial release, somewhat functional but missing many things.
