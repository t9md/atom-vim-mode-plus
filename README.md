# vim-mode-plus [![Build Status](https://travis-ci.org/t9md/atom-vim-mode-plus.svg)](https://travis-ci.org/t9md/atom-vim-mode-plus)

vim-mode improved.

# Development state

Beta

# Whats this?

Started as fork project from 2015.8.1, originally for doing some refactoring experiment.  
After doing lots of refactoring, I started to add new feature.  
So I decided to release this to get feedback from user.

# Thanks

My work is greatly owing to former achievement done by original vim-mode developer and many of its contributors.  
As you can see in commit history, this project is originally started by forking official [vim-mode](https://github.com/atom/vim-mode).

# Important Note

- You need to disable vim-mode to use vim-mode-plus, it can't work simultaneously.
- vim-mode's If you use following pakages it won't work or unnecessary. why not work? since service API name is different.
  - [vim-mode-clipboard-plus](https://atom.io/packages/vim-mode-clipboard-plus)
  - [ex-mode](https://atom.io/packages/ex-mode)
  - [vim-surround](https://atom.io/packages/vim-surround): surround feature included vim-mode-plus.
  - [vim-mode-visual-block](https://atom.io/packages/vim-mode-visual-block): (this is my package) visual-block included in vim-mode-plus.
- CSS selector scope, and keymap scope is different from vim-mode, **Not compatible**.
- Internal code base is very different, Issue, PR should be directly sent to vim-mode-plus, DONT create issue, PR to vim-mode for vim-mode-plus's.

# New Features

- Operator
  - Surround
    - Surround, DeleteSurround, ChangeSurround. Instead of vim-surround atom package, its repeatable(very improtant) with `.`.
    - SurroundWord pre-targeted to iner-word
    - DeleteSurroundAnyPair: Delete surrounding pair of AnyPair TextObject. You don't have to specify what pair you want to delete.
    - ChangeSurroundAnyPair: Change surrounding pair of AnyPair TextObject. You don't have to specify what pair you want to change.
  - Common string transformation which includes SnakeCase, CamelCase, DashCase.
  - ToggleLineComments which toggle comment of target-area(selected by motion or text-objects).
  - ReplaceWithRegister which replace target-area(selected by text-object or motion) with register's text. Very useful since its repeatable.
  - All target require operator behave as linwise alias when repeated, means `gugu`, `guu` `gUgU`, `gUU` support which is yet supported in vim-mode.
- TextObject
  - Indent which select consecutive deeper indented lines
  - Entire buffer.
  - CurrentLine. Useful when you do surround line.
  - Fold
  - Comment. which select consecutive commented lines.
  - AnyPair. it select nearest pair(surround) from one of following pair.
    - `'""', "''", "``", "{}", "<>", "><", "[]", "()"`.
  - Function. it select inner-function(body) or a-function.
  - SelectInsideBrackets family skip backslash escaped pair character.
- Motion
  - Coming soon.
- Instant UI feedback
  - Showing icon/emoji representing operation.
  - Show active counter to hover indicator like `10` when you do `10yy`.
  - Show active register to hover indicator like `"a` when you do `"ayy`
  - Flashing(highlighting) operation affected area(range) for yank, paste, toggle etc..
  - Flashing found entry on Search and SearchCurrentWord.
  - Show current/total hover counter on Search and SearchCurrentWord.
- Incremental search.
  - Auto scroll next matching entry as you type.
  - [Experimental] disable default RegExp search by using space starting seach word 1st space removed on search.
  - `search-visit-prev` and `vim-mode-plus:search-visit-next` allow you quickly visit match.
  - `ctrl-v` on search editor start literal input mode, next single char you input is skip keybinding on search editor(useful when you keymap normal key like `;` to `confirm()`).
  - [Experimental] Scroll next/prev "page" of matching entry, "page" is not actual page, so scroll only match found area, useful to quick skim for match out of screen.
- VisualMode improve
  - Show cursor in visual-mode except linewise submode.
  - Include visual-block-mode except yank, and paste.
  - Allow complete submode shift between char-block, block-line, line-char etc.., original column restored correctly.
- Other
  - Expose visual-mode's submode to text-editor-element's css class to be used as selector.
  - [Disabled temporarily] Show cursor(by using decoration) while waiting user input (e.g `m`, `"`).
  - Developer friendly introspection report and real-time opration-stack monitoring(logged on console).
  - Spec is more easy to read by using mini DSL provided by spec helper.
  - Lots of minor bug fix which is not fixed in official vim-mode.

# TOM-report

- [TOM-report](https://github.com/t9md/atom-vim-mode-plus/blob/master/docs/TOM-report.md)

Done by extending Base class, so each TOM and its instance can report itself.
TOM: TextObject, Operator, Motion

# Configuration

# Disable autocomplete-plus's auto suggestion in replace mode

To disable auto suggestion for vim-mode-plus, set following value on autocomplete-plus setting.

* suppressActivationForEditorClasses
`vim-mode.normal-mode, vim-mode.visual-mode, vim-mode.operator-pending-mode, vim-mode.insert-mode.replace`

## Keymap

Some of the keymap is not set by default, conslut [TOM-report](https://github.com/t9md/atom-vim-mode-plus/blob/master/docs/TOM-report.md), [keymaps](https://github.com/t9md/atom-vim-mode-plus/blob/master/keymaps/vim-mode-plus.cson) for detail.  

Here is my keymap as an example.

```coffeescript
'atom-text-editor.vim-mode-plus:not(.insert-mode)':
  # overwrite default 'vim-mode-plus:move-to-last-nonblank-character-of-line-and-down' which I never use.
  'g _': 'vim-mode-plus:snake-case'

'atom-text-editor.vim-mode-plus.normal-mode, atom-text-editor.vim-mode-plus.visual-mode':
  '_': 'vim-mode-plus:replace-with-register'

'atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode':
  # 'i s' is mapped to inner-any-pair by default. I can chose inner-any-pair with like `c;`, `v;`.
  ';':  'vim-mode-plus:inner-any-pair'

'atom-text-editor.vim-mode-plus.normal-mode':
  'S':   'vim-mode-plus:surround-word'
  'd s': 'vim-mode-plus:delete-surround-any-pair'
  'c s': 'vim-mode-plus:change-surround-any-pair'

# when you want to search `[`, `]`, `;`, input `ctrl-v` following these keys.
'atom-text-editor.vim-mode-plus-search':
  '[': 'vim-mode-plus:search-visit-prev'
  ']': 'vim-mode-plus:search-visit-next'
  ';': 'vim-mode-plus:search-confirm'
  'ctrl-f': 'vim-mode-plus:search-scroll-next'
  'ctrl-b': 'vim-mode-plus:search-scroll-prev'
  'ctrl-g': 'vim-mode-plus:search-cancel'

'atom-text-editor.vim-mode-plus-input':
  'ctrl-g': 'vim-mode-plus:input-cancel'
```

# References

- [operator, the true power of Vim](http://whileimautomaton.net/2008/11/vimm3/operator) by kana.  
True power of Vim is Operator and TextOjbect.

- [List of text-object as vim plugin](https://github.com/kana/vim-textobj-user/wiki)  
vim-mod-plus builtin textobj for function, fold, entire, comment, indent, line, and any-pair(super set of many pair text-obj)

# GIFs

## Incremental search

![gif](https://raw.githubusercontent.com/t9md/t9md/59ce4757d9d11c8d913efc972b58c18345fdbf06/img/vim-mode-plus/incremental-search.gif)

## Surround builtin.

![gif](https://raw.githubusercontent.com/t9md/t9md/59ce4757d9d11c8d913efc972b58c18345fdbf06/img/vim-mode-plus/surround.gif)

## Visual block mode builtin.

![gif](https://raw.githubusercontent.com/t9md/t9md/59ce4757d9d11c8d913efc972b58c18345fdbf06/img/vim-mode-plus/visual-blockwise-cursor.gif)

## Flash on operate

![gif](https://raw.githubusercontent.com/t9md/t9md/59ce4757d9d11c8d913efc972b58c18345fdbf06/img/vim-mode-plus/flashing-range.gif)

##  Hover icon

![gif](https://raw.githubusercontent.com/t9md/t9md/59ce4757d9d11c8d913efc972b58c18345fdbf06/img/vim-mode-plus/hover-icon.gif)

## Hover emoji

![gif](https://raw.githubusercontent.com/t9md/t9md/59ce4757d9d11c8d913efc972b58c18345fdbf06/img/vim-mode-plus/hover-emoji.gif)

## Pre-select affected surround pair before confirm available in ChangeSurroundAnyPair operator.

![gif](https://raw.githubusercontent.com/t9md/t9md/59ce4757d9d11c8d913efc972b58c18345fdbf06/img/vim-mode-plus/preselect-changed-surround.gif)

## Flash matched word on search and show current/total in hover indicator.

![gif](https://raw.githubusercontent.com/t9md/t9md/59ce4757d9d11c8d913efc972b58c18345fdbf06/img/vim-mode-plus/search-flash-and-counter.gif)

## Complete submode shift in visual-mode.

![gif](https://raw.githubusercontent.com/t9md/t9md/59ce4757d9d11c8d913efc972b58c18345fdbf06/img/vim-mode-plus/visualmode-submod-shift.gif)

## Cursor properly shown in visual-mode.

![gif](https://raw.githubusercontent.com/t9md/t9md/59ce4757d9d11c8d913efc972b58c18345fdbf06/img/vim-mode-plus/visualmode-submod-shift.gif)

# TODO

- [ ] Write spec for lots of UI effect. hover, search counter etc.
- [ ] Write tutorial for new Operator, TextObjet.
- [x] When hover Icon disabled, icon position is not at original cursor position.
- [x] Make independent showHoverCounter from showHover config parameter.
- [x] Use single scope for custom selection property.
- [ ] Change subscription link to use vimState as hub.
  - [ ] Chang link from TOM-to-Input to vimState-to-Input and let vimState actively call TOM's function to inform event.
- [x] Improve Visual mode: complete cursor visualization and switch between submode.
  - [x] Shift between submode properly restoring column and reversed state.
  - [x] show cursor: characterwise
  - [x] show cursor: linewise(decided to not try to show cursor)
  - [x] show cursor: blockwise
- [ ] Incorporate [paner](https://github.com/t9md/atom-paner) which improve, `ctrl-w`+`HJKLsv` actions. - [ ] Introduce new scope based motion by incorporating with [goto-scope](https://github.com/t9md/atom-goto-scope).
- [ ] Improve search and introduce incrementalSearch.
- [ ] Cancellation of operation on event subscription.
- [ ] Improve visual-block's line end selection and sync range between selections.
- [ ] Spec re-write 2nd round to compact and simple description for each spec.
- [ ] Select fold without expanding
- [x] Show cursor in visual-mode(now characterwise only) without hacking `Cursor.prototype`.
- [x] Support visual-block by incorporating with [vim-mode-visual-block](https://github.com/t9md/atom-vim-mode-visual-block).
- [x] Support web-font(?) font-awesome etc. to show on overlay hover.
- [x] `0` is accessible position than `^` so provide config option to behave `0` like `^`(I want single `0` behave as `^`). Removed this feature after evaluation, I don' need this.
- [x] Show emoji that representing current operation.
- [x] Get user's input with consistent manner via `@vimState.input`.
- [x] Flash(highlight) region for yanked, pasted, indented for giving instant feedback to user, beneficial especially used as operator like `yip`, `=ip`.
- [x] Don't change cursor position after yank, indent, toggle(break compatibility to Vim, but I thinks this is bettter).
- [x] New Operator for Surround, DeleteSurround, ChangeSurround.
- [x] Show current Register, Mark, Count as overlay decoration to giving instant feedback to user.
- [x] New Operator for ToggleLineComments, Camelize, Dasherize, Underscore.
- [x] New TextObject for Comment, Indent.
- [x] Rewrite spec to be able to write test intuitively.
- [x] Support new TextObject for Indent, and Comment.
- [x] Support new Operator ReplaceWithRegister.
- [x] Make opStack independent
- [x] Eliminate Prefix.Repeat object. Count is provided as global to object by inheriting Base.
- [x] TOM can respond to its class(e.g. isTextObject()?)
- [x] Realtime observation of OperatonStack.
- [x] Eliminate `vimState.linewiseAliasedOperator()` [done](https://github.com/t9md/vim-mode/commit/9fc615e968ad08a5633490c71defeb4008cabc65)
- [x] Readability improve for `registerOperationCommands`. Partially, experimentally done.
- [x] Operation really need to be List(`[]`) of Operation? Explicitly define operation is more neat and descriptive. done, :fire: operator with list form.
- [x] Consolidate files, remove subdirectories, all files are located directly under lib.(for easiness of refactoring, faster startup time.)
- [x] Consolidate arguments passed to each TOM. vimState should be available to all TOM. editor and editorElement should be removed since its available via vimState. This consistency will reduce developer's confusion while working on multiple TOMs.
- [x] Remove MotionWithInput, it'd be OK by providing getInput() methods on Base class. it will remove some complexity. [done](https://github.com/t9md/vim-mode/commit/0c7a4185ff4974ffe316459d8a98d2764057198d).
- [x] Remove OperatorWithInput, it'd be OK by providing getInput() methods on Base class. it will remove some complexity.
- [x] Eliminate Prefix.Register. make it available via vimState.
- [x] By eliminating Prefix.Register and Prefix.Repeat, remove Prefix class itself. [done](https://github.com/t9md/vim-mode/commit/5ac09c41beea779dd157ae76230d4c76b99989d4)
- [x] `introduce ViewModel.onDidGetInput(callback)` for operation which need user input.
- [x] Eliminate Input class, its just proxying user-input. [done](https://github.com/t9md/vim-mode/commit/b18f7f74f549e76e103335790f9af2cbf2599ac4)
- [x] Slim vim-state.coffee
  - [x] Auto mapping from command-name to corresponding class.
  - [x] Separate mode handling to ModeManager
- [x] improve introspection report to describe keymap to corresponding class(by consulting `atom.keymap`).
- [ ] Recheck unnecessary count passing function.
