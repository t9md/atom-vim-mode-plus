# vim-mode-plus [![Build Status](https://travis-ci.org/t9md/atom-vim-mode-plus.svg)](https://travis-ci.org/t9md/atom-vim-mode-plus)

vim-mode improved.

# Whats this?

Started as fork project at 2015.8.1, originally for doing some refactoring experiment.  
After doing lots of refactoring, I started to add new feature.  
So I decided to release this package to get feedback from broad user.  

# Thanks

My work is greatly owing to former achievement done by original vim-mode developers and many of its contributors.  
As you can see in commit history, this project is originally started by forking official [vim-mode](https://github.com/atom/vim-mode).  

# Important Note

- To use vim-mode-plus, you need to disable vim-mode first. You can't use both simultaneously.
- Following packages for vim-mode won't work in vim-mode-plus. Why? Because service API name is different. It's easy to add support I believe. Please report to each project.
  - [vim-mode-clipboard-plus](https://atom.io/packages/vim-mode-clipboard-plus)
  - [ex-mode](https://atom.io/packages/ex-mode)
  - [vim-surround](https://atom.io/packages/vim-surround): surround feature included vim-mode-plus, so you won't need this.
  - [vim-mode-visual-block](https://atom.io/packages/vim-mode-visual-block): (my package) builtin to vim-mode-plus with better integration.
- Scope for CSS selector and keymap is different from vim-mode, **not compatible**.
- Internal code base is very different. Thus, issue, PRs should be directly sent to vim-mode-plus. **DONT** report vim-mode-plus's issue or PRs to official vim-mode.

# FAQ

### Why fork? why not directly contribute to official vim-mode.

- Changes are too big.
- Some features are too experimental to merge official vim-mode.

# Wiki

- [New Features](https://github.com/t9md/atom-vim-mode-plus/wiki/Features)
- [Introspection report for operations](https://github.com/t9md/atom-vim-mode-plus/wiki/Operations) includes most of commands with keymap information.
- [GIFs](https://github.com/t9md/atom-vim-mode-plus/wiki/GIFs) demostrate fancy features.

# Configuration

## Disable autocomplete-plus's auto suggestion in replace mode

To disable auto suggestion for vim-mode-plus, set following value on autocomplete-plus setting.

### suppressActivationForEditorClasses

```
vim-mode-plus.normal-mode, vim-mode-plus.visual-mode, vim-mode-plus.operator-pending-mode, vim-mode-plus.insert-mode.replace
```

If you want to directly edit `config.cson`, here is how it looks like.

```coffeescript
"autocomplete-plus":
  suppressActivationForEditorClasses: [
    "vim-mode-plus.normal-mode"
    "vim-mode-plus.visual-mode"
    "vim-mode-plus.operator-pending-mode"
    "vim-mode-plus.insert-mode.replace"
  ]
```

## Keymap

Some of the keymap is not set by default, consult [Operations](https://github.com/t9md/atom-vim-mode-plus/wiki/Operations)
, [keymaps](https://github.com/t9md/atom-vim-mode-plus/blob/master/keymaps/vim-mode-plus.cson) for detail.  

Here is my keymap as an example including keymaps for helper packages.

```coffeescript
# Workspace
# -------------------------
# [other package] need to install cursor-history and paner
'atom-workspace:not([mini])':
  'ctrl-i': 'cursor-history:next'
  'ctrl-o': 'cursor-history:prev'
  'ctrl-cmd-i': 'cursor-history:next-within-editor'
  'ctrl-cmd-o': 'cursor-history:prev-within-editor'
  # Paner's split command sync scroll ratio when split vertically, horizontally.
  # So you won't get lost where cursor is?
  'cmd-2': 'paner:split-down'  # I don't use ctrl-w s.
  'cmd-3': 'paner:split-right' # I don't use ctrl-w v.

# All mode except insert
# -------------------------
'atom-text-editor.vim-mode-plus:not(.insert-mode)':
  # overwrite default 'vim-mode-plus:move-to-last-nonblank-character-of-line-and-down' which I never use.
  'g _': 'vim-mode-plus:snake-case'

# Normal, Visual
# -------------------------
'atom-text-editor.vim-mode-plus.normal-mode, atom-text-editor.vim-mode-plus.visual-mode':
  '_': 'vim-mode-plus:replace-with-register'

# Operator pending, Visual
# -------------------------
'atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode':
  # 'is' is mapped to inner-any-pair by default(so you can use `vis`, `cis` etc).
  # By mapping `;` here, I can choose inner-any-pair with like `c;`, `v;`.
  # And more, I can expand selection across any-pair with `vi;;;;` or `va;;;;`.
  ';': 'vim-mode-plus:inner-any-pair'
  # I overwrite vim-mode-plus:inner-single-quote here so that I can select any Quoted pair with single quote.
  "'": 'vim-mode-plus:inner-any-quote'

# Normal
# -------------------------
'atom-text-editor.vim-mode-plus.normal-mode':
  'S': 'vim-mode-plus:surround-word'
  'd s': 'vim-mode-plus:delete-surround-any-pair'
  'c s': 'vim-mode-plus:change-surround-any-pair'

  # [other package] need to install open-this
  'g f': 'open-this:here'
  'ctrl-w f': 'open-this:split-down'
  'ctrl-w F': 'open-this:split-right' # not exists in pure Vim

  # [othe package] To maximize(zen-mode) current pane like ZoomWin vim.
  'cmd-enter': 'paner:maximize'

# cc to change cursor word instead of ciw
'atom-text-editor.vim-mode-plus.operator-pending-mode':
  'c': 'vim-mode-plus:inner-word'

# Other
# -------------------------
# when you want to search `[`, `]`, `;`, input `ctrl-v` following these keys.
'atom-text-editor.vim-mode-plus-search':
  '[': 'vim-mode-plus:search-visit-prev'
  ']': 'vim-mode-plus:search-visit-next'
  ';': 'vim-mode-plus:search-confirm'
  'space': 'vim-mode-plus:search-insert-wild-pattern'
  'ctrl-g': 'vim-mode-plus:search-cancel'

'atom-text-editor.vim-mode-plus-input':
  'ctrl-g': 'vim-mode-plus:input-cancel'
```

# Helper packages

Here is the list of my packages which provide more vim-like experience.  
Why I don't builtin these feature? Its because it take time and some feature is useful for non-vim user.

- [cursor-history](https://atom.io/packages/cursor-history)
provides <kbd>c-i</kbd>, <kbd>c-o</kbd> to go/back cursor position history.
- [paner](https://atom.io/packages/paner)
provides <kbd>C-w x</kbd>, <kbd>C-w J,K,H,L</kbd> to move pane, swap pane item.
- [open-this](https://atom.io/packages/open-this)
provides <kbd>gf</kbd> to open file under cursor.
- [clip-history](https://atom.io/packages/clip-history)
Not exist in pure Vim, provides clip-board history you can pop yanked text until you get result you want.

# References

- Vim official
  - [motion](http://vimhelp.appspot.com/motion.txt.html)
  - [operator](http://vimhelp.appspot.com/motion.txt.html#operator)
  - [text-object](http://vimhelp.appspot.com/motion.txt.html#object-select)
  - [change](http://vimhelp.appspot.com/change.txt.html)
  - [marks](http://vimhelp.appspot.com/motion.txt.html#mark-motions)
  - [scroll](http://vimhelp.appspot.com/scroll.txt.html)
  - [search-commands](http://vimhelp.appspot.com/pattern.txt.html#search-commands)

- Other
  - [operator, the true power of Vim](http://whileimautomaton.net/2008/11/vimm3/operator) by kana.  
  True power of Vim is Operator and TextOjbect.

  - [List of text-object as vim plugin](https://github.com/kana/vim-textobj-user/wiki)  
  vim-mode-plus builtin textobj for function, fold, entire, comment, indent, line, and any-pair(super set of many pair text-obj)

# TODO

See [TODO Priority](https://github.com/t9md/atom-vim-mode-plus/issues/25).

- [ ] Dont't do moveRight and moveLeft to adjust selection in `Motion::selectInclusive()` it complicate other motion. and prevent to stop at EOL in `l`, `$`
- [x] Don't use typeCheck function like `isOperator()`, `isYank()` any more. instead use `instantOf` for being explicit what it meant to.
- [x] Don't depend on `atom.commands.onDidDispatch`, instead simply ensure cursor not put endOfLine **only for vim-mode-plus's command**.
- [ ] Write spec for lots of UI effect. hover, search counter etc.
- [ ] Write tutorial for new Operator, TextObjet.
- [x] Allow quoted-Pair to select quoted string outside of cursor postion within line(I don't like this behavior)?
- [x] Make AnyPair TextObject expandable.
- [x] When hover Icon disabled, icon position is not at original cursor position.
- [x] Make independent showHoverCounter from showHover config parameter.
- [x] Use single scope for custom selection property.
- [x] Change subscription link to use vimState as hub.
- [x] Improve Visual mode: complete cursor visualization and switch between submode.
  - [x] Shift between submode properly restoring column and reversed state.
  - [x] show cursor: characterwise
  - [x] show cursor: linewise(decided to not try to show cursor)
  - [x] show cursor: blockwise
- [x] Improve search and introduce incrementalSearch.
- [x] Cancellation of operation on event subscription.
- [x] Improve visual-block's line end selection and sync range between selections.
- [ ] Spec re-write 2nd round to compact and simple description for each spec.
- [x] Select fold without expanding
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
- [x] Recheck unnecessary count passing function.
