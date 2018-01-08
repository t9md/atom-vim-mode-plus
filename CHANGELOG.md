# 1.25.1:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.25.0...v1.25.1)
- Improve: Avoid centering editor-in-editor on `vim-mode-plus:maximize-pane` #1014
  - No longer centering text-editor which is rendered within normal text-editor using block decoration
  - This editor-in-editor is created by pkg `git-diff-details` or `inline-git-diff`(my fork of `git-diff-details`)

# 1.25.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.24.4...v1.25.0)
- Fix: Hide bottom gutter on `maximize-pane`
- New: Motion, TextObjet, Operator for work with `diff` buffer. #1009
  - Operator: `yank-diff-hunk`
    - Yank diff-hunk under cursor with auto-removing leading `+` or `-` char
  - Motion: `move-to-next-diff-hunk` and `move-to-previous-diff-hunk`
    - Move to next diff-hunk which starts with `+` or `-` char
  - TextObject: `a-diff-hunk` and `inner-diff-hunk`(No behavior differences in these two text-object)
    - Just for used by `yank-diff-hunk` operator
  - Intending to be used in diff output text buffer(e.g. output of `git diff`).
  - No keymaps are provided, set as you like in your `keymap.cson`, here is example.

    ```coffeescript
    # "source diff" is provided by language-diff package
    'atom-text-editor.vim-mode-plus.normal-mode[data-grammar="source diff"]':
      'tab': "vim-mode-plus:move-to-next-diff-hunk"
      'shift-tab': "vim-mode-plus:move-to-previous-diff-hunk"
    ```

- New: `vim-mode-plus:resolve-git-conflict` operator. #1011
  - Detail: https://github.com/t9md/atom-vim-mode-plus/pull/1011
  - Quickly replace git-conflict's hunk with `ours` or `theirs` based on cursor position when you execute this command.
  - No keymap provided. Keymap example is here

    ```coffeescript
    'atom-text-editor.vim-mode-plus.normal-mode':
      'space g c': 'vim-mode-plus:resolve-git-conflict'
    ```

# 1.24.4:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.24.3...v1.24.4)
- Fix: `j`, `k` threw exception on folded row which is also soft-wrapped, but no longer. #1003

# 1.24.3:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.24.2...v1.24.3)
- Fix: Remove no longer necessary temporal imperfect workaround of Atom-v1.24.0-beta0 issue. #998
  - After Atom-v1.24.0-beta1, no need to workaround beta0 issue since it's fixed.
  - Detailed information is here https://github.com/atom/atom/pull/16294.

# 1.24.2:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.24.1...v1.24.2)
- Fix: All code fold related features were broken in Atom-v1.24.0-beta0, but no longer. #1002
  - Since `editor.tokenizedBuffer.getFoldableRanges(N)` now seems require explicit indentLevel(`N`).
- Fix: `vim-mode-plus:reload` and `vim-mode-plus:reload-with-dependencies` which are used for faster dev cycle. #1002

# 1.24.1:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.24.0...v1.24.1)
- Fix: quick fix for cursor become invisible in Atom-v1.24.0-beta0.

# 1.24.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.23.0...v1.24.0)
- New, Breaking: `a-fold` now select "conjoined" fold #996
  - Old: `a-fold` just select current fold only.
  - New: `a-fold` select all conjoined fold range.
    - select previous fold if previous fold end at startRow of current fold.
    - select next fold if next fold start at endRow of current fold.
  - So you can do
    - delete(`d z`) or yank(`y z`) whole `if/else-if/else` clause by just two keystrokes.
    - delete(`d z`) or yank(`y z`) whole `try/catch/finally` clause by just two keystrokes.
- Fix: `j` and `k` no longer stuck at row when screenRow contains multiple fold. #994, #995
  - e.g. fold `else if`-fold, then `if`-fold, then try to cross row by `j` or `k` but couldn't.

# 1.23.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.22.1...v1.23.0)
- Doc: add youtube movie link on README.md
- Performance: Now `base.js` is not loaded on startup. So we got extra performance boost. #993.
  - Now in my MacBook Pro Late 2016. it score under 30ms(27ms is fastest record) activation time.
- Support: Now deprecate use of `service.Base` provided by `provideVimModePlus()` service, warn to use `service.getClass` instead.
  - new `service.getClass`: since I decided to not expose bare `Base` class as it was.
  - new `service.registerCommandsFromSpec`: for adding multiple commands which load body lazily
- Internal:
  - Move `command-table.json`, `file-table.json` to under directly `lib/json`. #990
  - Keep `command-table-pretty.json`, `file-table-pretty.json` for human read. #990
- Improve: Smooth scroll now no longer depends on jQuery, use `window.requestAnimationFrame()` instead #991
- Improve: `TransformStringBySelectList` now use `atom-select-list` instead of `space-pen-view`'s `SelectListView`
  - As a result, vmp no remove dependency to `space-pen-view`

# 1.22.1:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.22.0...v1.22.1)
- Fix: Allow `numpad0` to be used when entering a number before a command #989 by @sunjay
  - Now: Can set number `1 0` by `numpad1 numpad0`.
  - Old: `numpad0` incorrectly moved cursor to head of line by incorrect keymap.

# 1.22.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.21.0...v1.22.0)
- Improve: Now `Function` TextObject(`i f`, `a f`) can detect **more** function. #984
  - Previously vmp can detect only function which parameter-list and body forms single fold.
  - Now vmp can detect function if parameter-list and body form different fold.
- Fix: No longer editor freeze when big count was set for `MoveToRelativeLine` targeted operation. #985
  - E.g. `1 0 0 0 0 0 0 0 0 0 d d`, `1 0 0 0 0 0 0 0 0 0 y y`

# 1.21.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.20.0...v1.21.0)
- Support: No longer warning when user enabled `vim-mode`.
  - In old days, I frequently got report who enabled both `vim-mode` and `vim-mode-plus`.
  - But now `vim-mode` is obviously unmaintained, and I think less chance to confuse user.
- New, Breaking: Use [change-case](https://github.com/blakeembrey/change-case) npm in TransformString operator.
  - As a result, added new operators, also non-listed exiting operator improve translate-ability between different case.
  - `SwapCase`: Same as existing ToggleCase but add to reflect original change-case's function name.
  - `ParamCase`: Same as existing DashCase but add to reflect original change-case's function name.
  - `PathCase`: New transform `a_b_c` to `a/b/c`, `camelCase` to `camel/case`.
  - `HeaderCase`: New, transform `HeaderCase` to `Header-Case`, `header_case` to `Header-Case`.
  - `ConstantCase`: New, transform `ConstantCase` to `CONSTANT_CASE`, `constant-case` to `CONSTANT_CASE`.
  - `SentenceCase`: New, transform `SentenceCase` to `Sentence case`, `sentence_case` to `Sentence case`.
  - `UpperCaseFirst`: New, transform `upperCaseFirst` to `UpperCaseFirst`, `abc def` to `Abc Def`.
  - `LowerCaseFirst`: New, transform `LowerCaseFirst` to `lowerCaseFirst`, `ABC DEF` to `aBC dEF`.
- Breaking: Now `transform-string-by-select-list` just simply shows "Title Case"-ed operator class name.
  - No longer display different name like it didsplayed `Underscore _` for `SnakeCase` operator. Now it just show `Snake Case`.
  - Which might confuse you if you've been familier with old names. Sorry, but I think it was unnecessary.
- Performance: Delay loading underscore-plus in operator.
- Internal: Move commandTable generation logic to developer.js

# 1.20.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.19.0...v1.20.0)
- Fix: No longer throw exception on keystroke `o escape .` when `groupChangesWhenLeavingInsertMode` have enabled #966
- Performance: Reduce IOs at package activation further for faster startup #965
  - Separate `file-table.json` from `command-table.json`.
  - Optimize command-table data format to reduce file size.
  - Now in my MacBook Pro Late 2016. it score around 40ms(38ms-45ms) activation time(measured by package cop).
  - This is **NOT BAD** when considering vmp adds 300+ commands on activation.
  - 2017-11-06:    40ms (vmp-v1.20.0 + Atom-v1.23.0-beta1) Now!
  - 2017-04-17: 60-80ms (vmp-v0.90.0 + Atom-v1.16.0)
  - 2017-01-04:   150ms (vmp-v0.78.0 + Atom-v1.13.0-beta10)
- Improve: Longer search-flash duration from 0.5s to 1.0s to more easy to spot found word.
- Support, Doc: No longer warn that CoffeeScript based extension is no longer supported on pkg activation.
  - Instead it is now explained in README.md with english correction PR made by @filipewl
  - Why I remove now is I noticed that  warning was made on newly installed case(bad), it's been a month from this warning was added.
- Support: Update issue template so that issue opener will see TODOs without jumping to link.

# 1.19.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.18.2...v1.19.0)
- Improve: Scroll motions `ctrl-f`, `ctrl-b`... now works more correctly in editor having block decoration by @jdanbrown.
  - Previously amount of scroll was based on screen rows, which doesn't block-decoration take into account.
  - Now scroll pixel based, so accurate even if editor have block decoration inline image.
- Improve: Smoother scroll in sequential scroll motion execution.
  - Previously when multiple scroll request was made in very short time-gap, it immediately finalize previous request.
  - This means user see non-smooth scrollTop change although user enabled smooth scroll feature.
  - Now previous request is just cancelled and calculate new scrollTop based on previously requested value.
  - So in UX-wise, user no longer see sudden scrollTop change, always see smoooooth scroll congrats!!

# 1.18.2:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.18.1...v1.18.2)
- Change mind:
  - Update all vmp-plugins which affect changes in v1.18.0.
  - Remove `registerCommandFromSpec` migration code.
  - Why? migration for passed `spec` was not perfect, just confusing.
  - So I decided to simply let user update to latest, thats works.

# 1.18.1:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.18.0...v1.18.1)
- Fix: user's custom command in `init.js` throw exception when calling `registerCommand()`.
  - Regression introduced in v1.18.0 sorry!

# 1.18.0: BIG overhaul in different aspect
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.17.0...v1.18.0)
- Performance: Small activation performance gain by `Base.js` refactoring and JSON form of command-table.
- Fix: Fix broken word motion family from Atom v1.23.0-beta0. #946, #953.
  - `w`, `b`, `e`, `g e` and it's variant have been broken after v1.23.0-beta0 was out.
  - This is because vmp depends Atom's cursor's method to find word.
  - But this dependency also make vmp's word motion vulnerable to changes in atom-core.
  - So this time, did overhaul these word-motion to not use cursors's method
- Internal:
  - Changes in how vmp commands are loaded.
    - Previously, each operation class need to calll `register()` in it's own file.
      - e.g. call `MoveDown.register()` in `./motion.js`.
      - This mechanism was once useful, especially as executable-class-body when vmp was written in coffee-script.
    - Now all operations class are jus `requre`-ed by `/base.js` and manually registerd.
      - So less magic, more explicit, easy to understand.
  - Use JSON format for command-table for faster activation. #958
    - This involve changes in field name of command spec.
    - So also updated vmp plugins which use `registerCommandFromSpec` function provided as vmp service.
  - Introduce `findInEditor` utility and cleanup lot of boilerplate code by using this new utility.

# 1.17.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.16.0...v1.17.0)
- Improve: Hide some vmp commands from command-palette #943
  - Hide only super-basic small num of commands only whic is defined in `main.js`
  - I evaluated hide **all** vmp commands in #943 but reverted
  - I was expected hiding all vmp commands improve command-palette's responsiveness but it was not.
  - So I took benefit to invoke all vmp command from palette as of now.
- Improve: `c j`, `c k` at first or last buffer row no longer enter insert-mode.
- Fix: In v1.23.0-beta0, some TextObject(e.g `fold`, `comment`) did not work.
- Support: set minimum engines to `1.22.0`
- Internal, Breaking: Remove `ModeManager` class and re-blend it to `VimState`.
  - In original vim-mode, mode handling was done in `VimState`.
  - I extracted mode handling as `ModeManager`.
  - But now ModeManager’s task now get very small, I’m OK to re-blend it again.
  - Add deprecation warning when calling old `ModeManager`'s event API.
- Internal: `insert-mode`'s task done in `ModeManager` is now handled in `ActivateInsertMode` operation class.
  - Remove `replace-mode-backspace` command
    - This was mapped from `backspace` in `insert.replace` mode.
    - But now achieve same functionality by overriding `core:backspace`.
    - So, this intermediate command is no longer necessary.

# 1.16.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.15.0...v1.16.0)
- New: Motion to scroll to function and redraw at uppper middle.
  - Following two commands are defined(no keymap by default)
    - `move-to-previous-function-and-redraw-cursor-line-at-upper-middle`
    - `move-to-next-function-and-redraw-cursor-line-at-upper-middle`
  - I created this command to use in vmp-demo at vimConf2017.
- Internal: Refacotoring.
- Fix: Amount of scroll rows was not symmetric in `ctrl-d` and `ctrl-u`, but now fixed.
- Improve: Use TextBuffer's new `onDidChangeText` event to flash for undo/redo. #941.

# 1.15.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.14.1...v1.15.0)
- Breaking: Rename confusing `ScrollXXX`(It easily be confused with scroll motions(`ctrl-f` etc..)
  - `ScrollDown`(`ctrl-e`) to `MiniScrollDown`
  - `ScrollUp`(`ctrl-y`) to `MiniScrollUp`
- New: Smooth scroll option plus more for `MiniScroll`(`ctrl-y`, `ctrl-e`)
  - `smoothScrollOnMiniScroll`: default `false`
  - `smoothScrollOnMiniScrollDuration`: default `200`
  - `defaultScrollRowsOnMiniScroll`: default `1`
- New: Smooth scroll option for `redraw-cursor-line` commands.
  - `redraw-cursor-line` is `z` begging command like `z t`, `z u`, `z z`, `z b` etc..
  - Default disabled, I need this when I do demo. With smooth scroll on `z u`, less chance to leave behind audiences.
  - `smoothScrollOnRedrawCursorLine`: default `false`
  - `smoothScrollOnRedrawCursorLineDuration`: default `300`
- New, Experimental: New scroll motion to scroll 1/4.
  - `ScrollQuarterScreenDown`: keymap `g ctrl-d`
  - `ScrollQuarterScreenUp`: keymap `g ctrl-u`
  - Smooth scroll options are NOT explicitly provided, it use `ScrollHalf`'s config.
- Internal: Rename non-straightforward naming
  - From `SelectInVisualMode` to `VisualModeSelect`
  - From `isAsTargetExceptSelectInVisualMode` to `isTargetOfNormalOperator`

# 1.14.1:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.14.0...v1.14.1)
- Fix: Remove spec for now removed feature.

# 1.14.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.13.0...v1.14.0)
- Fix: `transform-string-by-select-list` throw exception when executed in `visual-mode`.
  - Regression by operator execution model redesign from v1.13.0.
- Internal:
  - Improve how `transform-string-by-external-command` is executed.
  - Remove `OperationAbortedError` which is vmp specific error used to `abort()` operation, but now no longer used.
- New, Experimental: `JoinTarget` operator(wanted to name just `Join` but it's already taken by `J`)

# 1.13.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.12.1...v1.13.0)
- Improve: Better multi cursors support for `toggle-persist-selection`.
- Improve: Refold temporarily opened fold by `/` and `?` when confirmed #931
- New: `z X` family to redraw cursor line at `upper-middle`. #932
  - Keymap and Command
    - `z u`: `redraw-cursor-line-at-upper-middle`
    - `z space`: `redraw-cursor-line-at-upper-middle-and-move-to-first-character-of-line`
  - Conflict: `z u` with pureVim's `spellfile` related command. But OK, vmp have no plan for this feat.
  - Here is summary table of keymap and where to draw
    ```
    | where        | no move | move to 1st char |
    |--------------|---------|------------------|
    | top          | z t     | z enter          |
    | upper-middle | z u     | z space          |
    | middle       | z z     | z .              |
    | bottom       | z b     | z -              |
    ```
- Breaking: rename confusing `ScrollCursorToTop` commands. #932
  - `z enter`: `ScrollCursorToTop` to `RedrawCursorLineAtTopAndMoveToFirstCharacterOfLine`
  - `z t`: `ScrollCursorToTopLeave` to `RedrawCursorLineAtTop`
  - `z .`: `ScrollCursorToMiddle` to `RedrawCursorLineAtMiddleAndMoveToFirstCharacterOfLine`
  - `z z`: `ScrollCursorToMiddleLeave` to `RedrawCursorLineAtMiddle`
  - `z -`: `ScrollCursorToBottom` to `RedrawCursorLineAtBottomAndMoveToFirstCharacterOfLine`
  - `z b`: `ScrollCursorToBottomLeave` to `RedrawCursorLineAtBottom`
- Internal: Remove `Operator.prototype.requireTarget`, now all operator have **target**.
  - Use `target = "Empty"` for old `requireTarget = false` equivalent.
- Internal: Remove casual use of `isComplete` and renamed to `isReady` as prep for upcoming refactoring. #933
  - Now `isReady`(was `isComplete`) is used only in `operationStack`.
  - For input taking `MiscCommand` family command such as `mark`, `insert-register` now executed in async.
  - All operators which take extra input now executed in async(no longer user `requireInput` mechanism).
  - At this point, `requireInput` is used only by Motion, which I cannot make it simply transform to use `async` execution.
  - Since motion is used as Operator's target and Operator has not yet support target executed in async scenario.

# 1.12.1:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.12.0...v1.12.1)
- Improve: `duplicate-with-comment-out-original` flashes correct range(only changed range).

# 1.12.0: Internal redesign of replace and surround(no behavior diff).
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.11.6...v1.12.0)
- New: Operator `duplicate-with-comment-out-original`(idea by @nwaywood) #929
  - Duplicate targeted lines(always works as `linewise`) and comment out original target(selected) text.
  - No keymap by default. But available from `select-list`(`ctrl-s` for macOS user).
  - This is maybe useful when you change code with keeping original code as reference.
    - e.g. If I keymap `g shift-cmd-D` to `vim-mode-plus:duplicate-with-comment-out-original`.
    - `g shift-cmd-D p`: Duplicate paragraph with original paragraph commentout.
    - `g shift-cmd-D z`: Duplicate fold with original fold commentout.
    - `g shift-cmd-D f`: Duplicate function with original function commentout.
- Improve: Remove operator's `supportEarlySelect` flag used by `surround` and `replace` operator #926
  - This option's purpose is to select target immediately after target provided and before reading user's input.
  - Now achieve same UX with more simpler way.
    - Old: Select target before `execute()` and skip `selectTarget` by checking if it's already selected.
    - New: Just execute and `await` user's input(simple and no complex skip `selectTarget` scenario).
  - As result of this re-design, `surround` and `replace` operator now executed in `async`.
    - This should be no diff from UX perspective. Just diff in internal execution model(require spec code change).
- Improve: Respect occurrence wise when updating register
  - When `c o p` update register's content register's type
    - Old: Save with register's type `linewise`, immediate paste(`cmd-v`) in `insert-mode` surprise user.
      - Since replaced text by `c` was `characterwise`, but pasted text add extra newline(`\n`).
    - New: Save with register's type `characterwise`, and immediate paste(`cmd-v`) in `insert-mode` works as expected.
- Improve: Spec helper
  - New: `ensureWait` is like `ensure`, but it **wait** till finish operation for async `execution`
  - Breaking: Remove `ensureByDispatch` since it's non essential, just wrapper. I want manage minimum set of `ensure` family.
  - Breaking: Disallow `keystroke` helper(after confirmed that it's not used by vmp and vmp-plugins).
  - Improve: `ensure` now recognize 1st arg as keystroke(not like keystroke or ensureOption as old `ensure`).
    - This is more clearer and explicit, and allow 2nd ensureOption empty to just dispatch keystroke(as replacement of old `keystroke` helper).

# 1.11.6:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.11.5...v1.11.6)
- Fix: `move-up-to-edge`, `move-down-to-edge` motion did not work correctly in soft-wrapped editor.
  - Regression from v1.11.0.

# 1.11.5:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.11.4...v1.11.5)
- Fix: No `r` with `'` or `"` input properly work on some international keyboard which require TWO keystroke to input these quotes.
  - Fix provided 1.11.4 was just fix issue partially, not perfect.

# 1.11.4:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.11.3...v1.11.4)
- Fix: No `r` with `'` or `"` input properly work on some international keyboard which require TWO keystroke to input these quotes.

# 1.11.3:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.11.2...v1.11.3)
- Fix: No longer throw exception when `change-surround-any-pair` cannot find surround pair.

# 1.11.2:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.11.1...v1.11.2)
- Fix: No longer throw exception when `demo-mode` pkg was activated, regression from v1.11.0.
- Fix `remove-leading-white-spaces` operator work properly again regression from v1.11.0.
- Improve: #701, When `wrapLeftRightMotion` is enabled and `l` in `vC` now can select new-line(can stop at column 0 of next-line).
- Internal: No longer expect `Operator.protoype.setTarget` return instance.
  - This eliminate unessential contract between caller/callee.

# 1.11.1:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.11.0...v1.11.1)
- Fix: `z c` no longer throw exception, this is regression from v1.11.0.
- Fix: `highlightSearch`, fix minor not-highlighted issue where it should be.
  - Fix: Highlight newly opened editor is not highlighted when `mainMoudle.globalState` was not populated.
    - E.g. `pane:split-right`, `pane:split-down` on fuzzy-finder's `select-list`
  - Fix: Now highlight newly opened editor even when it's not initially **activated**.(e.g. open on next pane without activating it).

# 1.11.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.10.0...v1.11.0)
- Fix: `toggle-highlight-search` command now correctly clear/re-highlight when value changed #918
  - This is regression introduced in v1.10.0 sorry!
- Improve: `toggle-fold` now work with multiple cursors.
- Improve, Breaking: How text-object function detect function scopes
  - Improve: function scope detection for `type-script`.
  - Improve, Breaking: `source.js` and `source.jsx`.
    - Ignore arrow function. Use `a-fold`(e.g. `y z`) for arrow-function.
    - Now no longer detect instantiation (`new Class`) call as function text-object.
- Breaking: Rename following align operator since it was confusing.
  - Old: `align-start-of-occurrence`, New: `align-occurrence-by-pad-start`
  - Old: `align-end-of-occurrence`, New: `align-occurrence-by-pad-end`
- Internal: Convention change, return value of `Base.prototype.initialize()` is not used, so no need to return `this`.

# 1.10.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.9.1...v1.10.0)
- New: `numbering-lines` operator, which adds line number to each line.
  - No default keymap, accessible via `transform-string-by-select-list`(`ctrl-s` for macOS user) command.
- Improve: `z t`, `z enter` works properly when last screen row was visible. @dcalhoun #915.
  - `editor.scrollPastEnd` need to be `true` to work these command properly, so show notification if not enabled.
- Fix: `z e` did not scroll until next cursor move is happens, but now scroll immediately.
- Improve, Performance: Lazy load further
- Improve: Improve integration with demo-mode package by making hover and flash highlight fadeout more in-sync.
- Internal: Remove intermediate class `ScrollWithoutChangingCursorPosition` used for misc-scroll commands.

# 1.9.1:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.9.0...v1.9.1)
- Fix: [CRITICAL] No longer throw exception by lack of `semver` dependency. Sorry!

# 1.9.0: Converted to JS, as a result, CoffeeScript based customization is no longer supported.
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.8.2...v1.9.0)
- Maintenance: Convert from CoffeeScript to JavaScript for operator, motion, text-object codes.
  - Now all running code is written in JavaScript.
  - Still test-spec is written in CoffeScript.
  - Through rewriting to JS, introduced lots of refactoring(architectural simplification, minor bug fixes).
- Breaking: CoffeeScript based custom-vmp-operation is no longer supported.
  - From this version, all operations are defined as ES6 class which is NOT extend-able by CoffeeScript.,
  - If you have custom-vmp-operation in your `init.coffee`, require rewrite to JS. See [Wiki](https://github.com/t9md/atom-vim-mode-plus/wiki/ExtendVimModePlusInInitFile).
  - Also all vmp-plugin pkg I'm maintaining is rewritten this time, see [#895](https://github.com/t9md/atom-vim-mode-plus/pull/895) for detail.
- Fix: Broken features broken from Atom-v1.22.0-beta0 now work again.
  - Fold related commands: `a-fold`, `inner-fold`, `move-to-next-fold-start` etc..
  - Comment text-object.
- New: Operator `AlignOccurrence`, `AlignStartOfOccurrence`, `AlignEndOfOccurrence`. #904 #906
  - No default keymap(set it by yourself if necessary).
  - Available from `transform-string-by-select-list`(`ctrl-s` for macOS user) commands.
  - How align operator works.
    - I introduce this operator with great simplicity by intention.
    - It's always add space to start or end of occurrence to align occurrence.
    - Add only, not trim existing spaces, if you want to remove consecutive spaces, use `compact-spaces` operator(`g space` for macOS).
  - For general purpose aligning(such as align lines by `=` assignment), use pkg like [aligner](https://atom.io/packages/aligner).
  - This operator's goodness is explicitness and manual control for pattern to use for align, which make it possible general purpose aligner tools is not good at.
- New: `blackholeRegisteredOperators` to disable register update for selected operator commands. #901, #902
  - Old `dontUpdateRegisterOnChangeOrSubstitute` are deprecated. it's setting is auto-migrated on first startup.
  - Set list of operator commands to `blackholeRegisteredOperators`.
    - E.g. `change, change-to-last-character-of-line, delete-right, delete-left`.
  - `change*`, `substitute*`, `delete*` is special value available to specify ALL same family operators.

# 1.8.2:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.8.1...v1.8.2)
- Fix: `TransformStringByExternalCommand` operator now correctly shift to `normal-mode` after operation finished.
  - This operator is specifically used by `vim-mode-plus-replace-with-execution` pkg(was broken, but recover now).

# 1.8.1:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.8.0...v1.8.1)
- Maintenance: Add `Base.initClass` as alias of `Base.extend` for upcoming vmp changes.

# 1.8.0: Expose select operator as normal command
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.7.0...v1.8.0)
- New: `select` operator just for `select` target.
  - `select` is super essential operator which have been used in every motion in `visual-mode`.
  - But this `select` operator was not available as command.
  - Now vmp expose this as `select` operator with slight modification.
    - Original `Select` operator used in `visual-mode` was renamed to `SelectInVisualMode`.
    - The diff between `Select` and `SelectInVisualMode` is
      - `Select` accept `preset-occurrence` and `persistent-selection` but `SelectInVisualMode` is not so that user can modify selection without being interfered by existing `preset-occurrence` and `persistent-selection`.
- New Config: `keymapSToSelect` conditional keymap. When enabled, `s` behaves as `select` operator.
  - `s p`: select paragraph. Equivalent to `v i p`.
  - `s i i`: select `inner-indentation` Equivalent to `v i i`.
  - `s o p`: select `occurrence` in paragraph.
  - `g o s p`: select `occurrence` in paragraph(use `preset-occurrence` by `g o`).
  - `s o p o escape`: Place cursors to each start position of `occurrence` in paragraph.
  - `s o p I`: insert at start position of `occurrence` in paragraph.
  - `s o p A`: insert at end position of `occurrence` in paragraph.
- Improve: `[`(`move-up-to-edge`) and `]`(`move-down-to-edge`) now motion stops at first and last row again.
  - Now stoppable as long as target column is exist at first row or last row.
  - This behavior is added at #314(v0.49.0) but removed at #481(v0.66.0).
  - Now re-introduced this feature with avoiding edge case reported in #481.
- Improve: Confirm on occurrence operation #888, #894
  - Now ask confirmation before starting to create `occurrence-markers` in `g o`(`preset-occurrence`), or `c o`(using `o` modifier) operation.
  - Allows cancellation to avoid editor become unresponsive while creating tons of markers.
    - e.g. If you `g o` accidentally for single-space and editor have huge matches, no longer freeze editor if you cancel confirmation.
  - New: config `confirmThresholdOnOccurrenceOperation`(default `2000`) control confirmation threshold.
- Keymap: Shorthand keymap for `inner-entire` in `operator-pending-mode` for Linux and Windows.
  - Windows and Linux user can `ctrl-a` as shorthand of `i e`(`inner-entire`).
    - Usage example: `y ctrl-a` to yank all text in buffer.
  - For macOS user `cmd-a` is provided as shorthand of `i e` in older version(v0.88.0).
- New: Operator command `insert-at-head-of-occurrence`, `insert-at-head-of-subword-occurrence`.
  - Previously only `start` and `end` version of this commands are provided.

# 1.7.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.6.0...v1.7.0)
- Fix: `f escape f` no longer throw exception when `reuseFindForRepeatFind` was enabled #883
- New: `insert-at-head-of-target` operator, in the past I removed this operator, but I need this now #881.
- Improve: Cancelling in the middle of operation no longer clear reset multiple-cursors #882, #885
  - Motion: Find family `f`, `F`, `t`, `T`
  - Operator: Replace `r` `surround` family, `split-string` family, `join-by-input` family
- Improve: No longer hide cursor when focus is at mini-editor.
  - `/`, `?`: was hidden in all mode in older version.
  - `f`, `t`: was hidden in `operator-pending-mode` in older version.
- Improve: cleanup CSS in `vim-mode-plus.less`.
- Improve: Respect original selection's reversed state on occurrence-operation operation.
- Doc: Wrote wiki and update README to for `cursor-line` modifying syntax-theme issue #887.
  - See FAQ section of README: "Flash effect not appear on cursor-line..."
- Internal: Add debug code to investigate known issue #875(for cursor jumped unexpectedly).

# 1.6.0: Occurrence respects operator-bound-wise. #879
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.5.0...v1.6.0)
- Improve: `occurrence-operation` now aware of `operator-bound-wise`.
  - Behavior diff: Diff appears in `occurrence-operation`.
    - Old: Always worked as `characterwise`.
    - New: Works as `linewise` when
      - `V` operator-modifier is used.
      - `linewise-bound-operator`(e.g. `g /`, `>` in `normal-mode`, `D`, `Y` in `visual-mode` etc) is used.
  - What is `occurrence-operation` and `operator-bound-wise` ?
    - `occurrence-operation`: Operation with `o` modifier(e.g. `c o f`) or operation with preset-occurrence(e.g. `g o c f`).
    - `operator-bound-wise`: `D`, `C`, `Y` in `visual-mode` and `V` forced operation like `d V p`.
  - Example(See also animation GIF in PR #879)
    - Assume non consecutive `console.log` lines scattered in function and you want to bulk appply operation **linewise-ly**.
    - First place cursor at `console` of `console.log`. Then you can do variety of operation linewise-ly.
    - `g o v i p D`: Mark occurrence(`g o`), select-paragraph(`v i p`), then `delete-line`(`D`).
    - `g / o p`: `toggle-line-comments`(`g /`) for `occurrence`(`o`) in paragraph(`p`).
    - `g U o V p` or `g U V o p`: `upper-case`(`g U`) for `occurrence`(`o`) with force linewise(`V`) in paragraph(`p`).
  - How this works?
    - Most operator doesn't have wise in operator-level, in this case operation's wise is determined by target(motion or text-object).
    - When `V` operator-modifier or `wise-bound-operator` is used, operation's wise is forced to this bound wise.
    - When `occurrence-operation` is forced `linewise`, it total steps is here.
      1. Select target(1)
      2. select occurrences contains in (1)
      3. range > select linwisely and merge selections with immediately adjacent row.
  - Takeout
    - Some operators(e.g. `C`, `Y`, `D`, `g /`, `>`, `<` etc) have pre-bound to `linewise`.
      - When you use these operation with `o` or `g o`, it works as `linewise`.
    - You can force wise to `linewise` by `V` operator-modifier, in this case occurrence-operation also works `linewise`.
    - Also remember you can distinguish [`c` and `C`], [`y` and `Y`], [`d` and `D`] in `visual-linewise` mode.
      - Use lower letter(`c`, `y`, `d`) if you want `characterwise` behavior.
      - Use capital letter(`c`, `y`, `d`) if you want `linewise` behavior.

# 1.5.0: Reconcile visual-mode with outer-vmp command in better way. #878
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.4.0...v1.5.0)
- Summary: This is ambitious and dangerous change.
  - If success, lots of potential issue would be fixed.
  - But dangerous since it use more frequently fired hook(`editor.onDidChangeSelectionRange`).
    - I'm not 100% sure if this change works properly for all other commands provided by atom-core and packages.
- Fix: #874 `cmd-d`(`find-and-replace:select-next`) in `normal-mode` respect `SelectNext#wordSelected` state for `find-and-replace`.
  - Original `cmd-d` select word only(exclude partial matches) if original selection is also created via `cmd-d`.
  - But this useful feature did not work in vmp's `normal-mode`.
  - Because when `cmd-d` is executed in `normal-mode`, vmp modify selection internally, which breaks state `find-and-replace` keep internally.
  - Behavior diff with text `atom atomic atom`.
    - Old: `cmd-d` twice select 1st and 2nd `atom`. Here, `atom` of `atomic` is selected, bad!.
    - New: `cmd-d` twice select 1st and 3rd `atom`.
- Fix: #872 `cmd-f`(`find-and-replace:show`), search word, confirm then `escape` to clear selection no longer reset cursor position to where `cmd-f` was started.
  - This happens when `cmd-f` started with non-empty selection.
- Fix: #873 Now whenever outer-vmp command modify selection, vmp starts `visual-mode` accordingly.
  - How vmp handle temporal selection modification done in single-command?
  - When outer-vmp command select some range(1) and clear(2) in single-command.
  - Vmp start `visual-mode` at (1), then reset to `normal-mode` at (2).
  - This is NOT elegant solution, but there is no other better way.
  - We cannot determine selection is eventually cleared or not within `editor.onDidChangeSelectionRange` event.
  - Delaying, debouncing to minimize useless mode-shift is bad for UX, user see slight delay for cursor updated.

# 1.4.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.3.3...v1.4.0)
- New: Numbered register(`0-9`) and small delete register(`-`). #871
  - When are they updated?
    - `0` is for yank, `1-9` is for `change` and `delete`.
    - `-` is for small `change` and `delete`, what `small` means is "content is less-than-one-line".
  - Currently no command to display register's content
    - Package author can access register by `vimState.register.get(REGISTER_NAME)`.
- Fix: `f`, `r` did not work correctly when user modified `.plain.text` grammar. #869
  - This issue only happens when user set `.plain.text` grammar to have `softWrap` to `true` and `softWrapHangingIndent` to non-zero value.
- New, Experimental: SequentialPaste for `p`, `P` and `replace-with-register`.
  - Unnamed register(`"`) maintain history at maximum `sequentialPasteMaxHistory`.
  - When user execute `p` sequentially, it pop content from older history.
  - Intended to be used as lazy quick escape hatch from very recent unwanted register mutation.
  - New configuration to control this new feature.
    - Config: `sequentialPaste`(default `false`) when enabled, pop history on sequential paste by `p`, `P`, and `replace-with-register`.
    - Config: `sequentialPasteMaxHistory`(default `3`). maintain history specified this value.
- Improve: `f` family related
  - Improve: Restore original scrollTop when `findAcrossLines` enabled and cancelled after scroll.
  - Rename config: `keymapSemicolonToConfirmFind` to `keymapSemicolonToConfirmOnFindInput`(auto-migrate)
  - Improve: Empty confirm no longer move cursor when `findCharsMax` > 1.
  - New: Commands `find-next-pre-confirmed` and `find-previous-pre-confirmed`.
    - Scope: Available when `f` family waiting for input(`atom-text-editor.vim-mode-plus-input.find`).
    - Keymap: `tab`, and `shift-tab` is mapped by default.
    - Why?
      - Allow you to adjust landing target BEFORE confirm to skip un-aimed stop interactively.
      - In most case, using `;` or `,` after `f` finished is OK.
      - But when `f` is used with operator, such as `c t f "` and `"` matched earlier spot than you aimed.
      - This situation is not recoverable/retry-able by `.` repeat, but manually avoid-able by new commands.
  - New, Experimental: Conditional keymap `keymapSemicolonAndCommaToFindPreConfirmedOnFindInput`(default `false`).
    - When enabled, `;` and `,` is mapped to new `find-next-pre-confirmed` and `find-previous-pre-confirmed`.
  - Maintenance: Remove `[EXPERIMENTAL]` tag from description of `findAcrossLines` settings, since we found it useful.
  - Improve: Fix several highlight inconsistencies.
- Fix: Incorrect cursor rendering when `automaticallyEscapeInsertModeOnActivePaneItemChange` is enabled. #855
  - When `automaticallyEscapeInsertModeOnActivePaneItemChange` is set and active-tab change and back.
  - Cursor rendered odd way.
  - This is started from Atom v1.19.0 with new editor-rendering change.
  - To workaround issue, now use more appropriate `onDidStopChangingActivePaneItem` hook.
- New, Experimental: Conditional keymap `keymapIAndAToInsertAtTargetWhenHasOccurrence`(default `false`). #862
  - This is revival of old default keymap which is removed because it was too aggressive, confusing as default-keymap.
  - When enabled and edigtor has `preset-occurrence` marker, `I` and `A` behave as operator which take `target`.
  - e.g. `I p`, `A p` to insert at start or end of `preset-occurrence` in paragraph(`p`).
- Improve: Now `maximize-pane` no longer automatically `de-maximized` on active pane item change(tab-change). #866
  - So user can switch active tab with keep maximized.
  - This was original behavioral design I intended. Noticed it's broken(not sure when, or initially broken), so fixed.
- Improve: `move-to-next-occurrence`, `move-to-previous-occurrence` now visit in ordered by buffer position. #864
  - Following behavioral change is noticeable only when user create multiple `preset-occurrence` for different word.
    - old: `tab`, `shift-tab` visit `preset-occurrence` in created order.
    - new: `tab`, `shift-tab` visit `preset-occurrence` in ordered by buffer position.
- Internal: Cleanup RegisterManager code to reduce my confusion.

# 1.3.3:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.3.2...v1.3.3)
- Improve: highlight-find-char now highlight unconfirmed-current-match differently( with thicker border ).
  - You now visually notified "no extra keytype is required to land this position" while typing.

# 1.3.2:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.3.1...v1.3.2)
- Improve: highlight-find-char now highlight all chars in next lines when `findAcrossLines` was set.
  - This gives important feedback for your keystroke when your eye is needling destination keyword while typing.

# 1.3.1:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.3.0...v1.3.1)
- Fix: Fix confusing description in setting, no behavioral diff.

# 1.3.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.2.0...v1.3.0)
- Breaking, New: `findCharsMax` options to find arbitrary length of chars by `f`.
  - Involves renaming, auto-value-conversion of existing configuration introduced in v1.1.0( yesterday ).
  - New, Rename: `findCharsMax`: default `1`.
    - If `find`'s input reaches this length, confirm without waiting explicit `enter`.
    - So default `f a`(move to `a` char) is behavior when `findCharsMax` is `1`.
    - By setting bigger number(such as `100`) with also enabling `findConfirmByTimeout`, you can expect FIXED timing of confirmation against your input.
      - FIXED-timing-gap for "f > chars-input > wait > land(always by timeout)" flow.
    - Old `findByTwoChars = true` is equals to `findCharsMax = 2`, and migrated on first time activation.
  - Rename: `findByTwoCharsAutoConfirmTimeout` to `findConfirmByTimeout`( generalize naming )

# 1.2.0:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.1.1...v1.2.0)
- New, Experimental: `findAcrossLines`: default `false`
  - When `true`, `f` searches over next lines. Affects `f`, `F`, `t`, `T`.
  - [Collecting feedback] twitter: @t9md or https://github.com/t9md/atom-vim-mode-plus/issues/851
    - Not sure if this is really necessary feature since `/` and `?` is available for multi-line search.
- Breaking: New default: `flashOnMoveToOccurrence` = `true`
  - When preset-occurrence( `g o` ) is exist on editor, you can move between occurrences by `tab` and `shift-tab`
  - When set to `true`, flash occurrence under cursor after move
  - This feature is NOT new, Just "flashing by default" is new change in this release.

# 1.1.1:
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.1.0...v1.1.1)
- Fix: Fix confusing description in setting, no behavioral diff.

# 1.1.0: This release is all for better `f` by making it tunable
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v1.0.0...v1.1.0)
- [CAUTION: added at release of v1.3.0]: Config option name changed.
  - I basically don't want update old CHANGELOG, but this is for reducing confusion.
  - Because of short release timing gap with braking config params change.
    - v1.1.0: 2017.9.1
    - v1.3.0: 2017.9.2
  - When you read this below, keep in mind, change in available config params.
    - Parameterized: `findByTwoChars = true` to `findCharsMax = 2`
    - Renamed: `findByTwoCharsAutoConfirmTimeout` to `findConfirmByTimeout`
- New: [Summary] Now `f` is **tunable**. #852.
  - Inspired pure-vim's plugins: `clever-f`, `vim-seek`, `vim-sneak`.
  - Highlighting find-char. It help you to pre-determine consequence of repeat by `;`, `,` and `.`.
  - Aiming to get both benefit of two-char-find(`vim-seek`, `vim-sneak`) and one-char-find( vim's default ).
    - Even after two-char-find was enabled, you can auto-confirm one-char input by specified timeout.
  - Can reuse `f`, `F`, `t`, `T` as `repeat-find` like `clever-f`.
  - Maybe reading test-spec for these feature is clearer than reading following explanation.
    - https://github.com/t9md/atom-vim-mode-plus/blob/396514199f08e0901d2af918782c6d8a28efc9e7/spec/motion-find-spec.coffee#L291-L369
- Config: [Detail] Following configuration option is available to **tune** `f`.
  - `keymapSemicolonToConfirmFind`: default `false`.
    - See explanation for `findByTwoChars`.
  - `ignoreCaseForFind`: default `false`
  - `useSmartcaseForFind`: default `false`
  - `highlightFindChar`: default `true`
    - Highlight find char, fadeout automatically( this auto-disappearing behavior/duration is not configurable ).
      - Fadeout in 2 second when used as motion.
      - Fadeout in 4 second when used as operator-target.
  - `findByTwoChars`: default `false`
    - When enabled, `f` accept TWO chars.
      - Pros. Greatly reduces possible matches, avoid being stopped at earlier spot than where you aimed.
      - Cons. Require explicit **confirmation** by `enter` for single char-input. You might mitigate frustration by.
        - Confirm by `;`, easier to type and well blend to forwarding `repeat-find`( `;` ).
          - Enable "keymap `;` to confirm `find` motion"( `keymapSemicolonToConfirmFind` ) configuration.
          - e.g. `f a ;` to move to `a`( better than `f a enter`?). `f a ; ;` to move to 2nd `a`(well blended to default repeat-find(`;`)).
        - Enable auto confirm by timeout( See. `findByTwoCharsAutoConfirmTimeout` )
  - `findByTwoCharsAutoConfirmTimeout`: default `0`.
    - "When `findByTwoChars` was enabled, automatically confirm single-char input on timeout( msec ).
    - `0` means no timeout.
  - `reuseFindForRepeatFind`: default `false`
    - When `true` you can repeat last-find by `f` and `F`(also `t` and `T`).
    - You still can use `,` and `;`.
    - e.g. `f a f` move cursor to 2nd `a`.
  - My configuration( I'm still in-eval phase, don't take this as recommendation ).
    ```coffeescript
    keymapSemicolonToConfirmFind: true
    findByTwoChars: true # [converted] to `findCharsMax = 2`
    findByTwoCharsAutoConfirmTimeout: 500 # [converted] to `findConfirmByTimeout = 500`
    reuseFindForRepeatFind: true
    useSmartcaseForFind: true
    ```

# 1.0.0: New default `stayOn` all `true`.
- Diff: [here](https://github.com/t9md/atom-vim-mode-plus/compare/v0.99.1...v1.0.0)
- Version: Decided to bump major version.
- Breaking: Default config change/Renamed config name.
  - Summary:
    - Now all `stayOn` prefixed configuration have new default `false`.
    - New default behavior is NOT compatible with pure-Vim.
      - Set all `stayOn` prefixed configuration to `false` to revert to previous behavior.
    - Some configuration parameter name is renamed to have `stayOn` prefix.
      - Automatically migrate existing config on activation of vmp.
    - What is `stayOnXXX` configuration?
      - Respect original cursor position as much as possible after operation( select, move, operate ).
      - It keep both cursor's row and column or column only( if vertical move was necessary ).
  - Config params renamed and changed default value
    - New default: `incrementalSearch` = `true`
    - New default: `stayOnTransformString` = `true`
    - New default: `stayOnYank` = `true`
    - New default: `stayOnDelete` = `true`
    - Renamed/New default: `keepColumnOnSelectTextObject` > `stayOnSelectTextObject` = `true`
    - Renamed/New default: `moveToFirstCharacterOnVerticalMotion` !> `stayOnVerticalMotion` = `true`
      - Renamed with meaning inverted: `!moveToFirstCharacterOnVerticalMotion === stayOnVerticalMotion`
