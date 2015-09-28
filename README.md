# vim-mode-plus [![Build Status](https://travis-ci.org/t9md/atom-vim-mode-plus.svg)](https://travis-ci.org/t9md/atom-vim-mode-plus)

vim-mode improved.

# Development state

Beta

# Whats this?

Started as fork project at 2015.8.1, originally for doing some refactoring experiment.  
After doing lots of refactoring, I started to add new feature.  
So I decided to release this package to get feedback from broad user.  

# Thanks

My work is greatly owing to former achievement done by original vim-mode developer and many of its contributors.  
As you can see in commit history, this project is originally started by forking official [vim-mode](https://github.com/atom/vim-mode).  

# Important Note

- You need to disable vim-mode to use vim-mode-plus, it can't work simultaneously.
- Following pakages for official vim-mode won't work for vim-mode-plus. Why not work? Because service API name is different. It's easy to add support I believe. Please report to each project.
  - [vim-mode-clipboard-plus](https://atom.io/packages/vim-mode-clipboard-plus)
  - [ex-mode](https://atom.io/packages/ex-mode)
  - [vim-surround](https://atom.io/packages/vim-surround): surround feature included vim-mode-plus.
  - [vim-mode-visual-block](https://atom.io/packages/vim-mode-visual-block): (this is my package) visual-block included in vim-mode-plus.
- Scope for CSS selector and keymap is different from vim-mode, **not compatible**.
- Internal code base is very different. Thus, issue, PRs should be directly sent to vim-mode-plus. **DONT** report vim-mode-plus's issue or PRs to official vim-mode.

# FAQ

### Why fork? why not directly contribute to official vim-mode.

- Changes are too big.
- Some features are too experimental to merge official vim-mode.

# New Features

- Operator
  - [Surround][Surround]:
    - Surround, DeleteSurround, ChangeSurround. It's repeatable with `.`.
    - SurroundWord pre-targeted to inner-word.
    - DeleteSurroundAnyPair: Delete surrounding pair of AnyPair TextObject. Auto-find surround char to delete.
    - ChangeSurroundAnyPair: Change surrounding pair of AnyPair TextObject. Auto-find surround char to change.
  - Common string transformation: [SnakeCase][SnakeCase], [CamelCase][CamelCase], [DashCase][DashCase].
  - ToggleLineComments: Toggle comment for lines.
  - ReplaceWithRegister: Replace with content of specified register.
  - All target-requiring operator behave as linewise alias when repeated, e.g. `gugu`, `guu` `gUgU`, `gUU` and others.
  - Options to keep cursor position in string transformation. e.g. Not move cursor in `gUU`, surround etc.
- TextObject
  - Indentation: Select consecutive lines with deeper indent level than current line's indent level.
  - Entire: Entire buffer.
  - CurrentLine: Useful when you do surround line.
  - Fold:
  - Comment: Consecutive commented lines.
  - AnyPair. it select nearest pair(surround) from one of following pair.
    - `'""', "''", "``", "{}", "<>", "><", "[]", "()"`.
  - Function: Select inner-function(body) or a-function.
  - Pair family skip backslash escaped pair character.
- Instant UI feedback
  - Showing icon/emoji which represent current operation e.g. show :camel: in CamelCase operation.
  - Show active counter on hover indicator like `10` when you do `10yy`.
  - Show active register on hover indicator like `"a` when you do `"ayy`
  - Flashing(highlighting) operation affected area(range) for yank, paste, toggle etc..
  - Flashing found entry on Search and SearchCurrentWord.
  - Show current/total hover counter on Search and SearchCurrentWord.
- Incremental search.
  - Auto scroll next matching entry as you type.
  - `search-visit-next` and `vim-mode-plus:search-visit-prev` allow you quickly visit match. Mapped to `tab`, `right` and `shift-tab`, `left`.
  - `ctrl-v` on search editor start literal input mode, next single char you input is skip keybinding on search editor(useful when you keymap normal key like `;` to `confirm()`).
  - [Experimental] Disable default RegExp search by using space starting seach word 1st space removed on search.
  - [Experimental] Scroll next/prev "page" of matching entry, "page" is not actual page, so scroll only match found area, useful to quick skim for match out of screen.  
    Mapped to `up` and `down`.
- VisualMode improve
  - Show cursor in visual-mode except linewise submode.
  - Visual block mode except yank and paste.
  - Columns are correctly remembered and restored when shift between submode: char-to-block, block-to-line, line-to-char etc.
- Other
  - Expose visual-mode's submode to text-editor-element's css class to be used as selector.
  - [Disabled temporarily] Show cursor(by using decoration) while waiting user input (e.g `m`, `"`).
  - Developer friendly introspection report and real-time opration-stack monitoring(logged on console).
  - Spec is more easy to read by using mini DSL provided by spec helper.
  - Lots of minor bug fix which is not fixed in official vim-mode.

[Surround]:https://github.com/t9md/atom-vim-mode-plus/blob/master/docs/TOM-report.md#surround--transformstring
[SnakeCase]:https://github.com/t9md/atom-vim-mode-plus/blob/master/docs/TOM-report.md#snakecase--transformstring
[CamelCase]:https://github.com/t9md/atom-vim-mode-plus/blob/master/docs/TOM-report.md#camelcase--transformstring
[DashCase]:https://github.com/t9md/atom-vim-mode-plus/blob/master/docs/TOM-report.md#dashcase--transformstring

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

Some of the keymap is not set by default, consult [TOM-report](https://github.com/t9md/atom-vim-mode-plus/blob/master/docs/TOM-report.md), [keymaps](https://github.com/t9md/atom-vim-mode-plus/blob/master/keymaps/vim-mode-plus.cson) for detail.  

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
vim-mode-plus builtin textobj for function, fold, entire, comment, indent, line, and any-pair(super set of many pair text-obj)

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

- [ ] Don't use typeCheck function like `isOperator()`, `isYank()` any more. instead use `instantOf` for being explicit what it meant to.
- [ ] Make AnyPair TextObject expandable.
- [ ] Don't depend on `atom.commands.onDidDispatch`, instead simply ensure cursor not put endOfLine **only for vim-mode-plus's command**.
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
