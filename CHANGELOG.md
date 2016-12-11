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
