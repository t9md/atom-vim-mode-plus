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
