# vim-mode-plus [![Build Status](https://travis-ci.org/t9md/atom-vim-mode-plus.svg)](https://travis-ci.org/t9md/atom-vim-mode-plus)

vim-mode improved.

# Thanks

My work is greatly owing to former achievement done by original vim-mode developers and many of its contributors.  
As you can see in commit history, this project is originally started by forking official [vim-mode](https://github.com/atom/vim-mode).  
The great design to achieve Vim operation by composing operator with target(motion, text-object) on top of operationStack is still lives in vim-mode-plus now.  
I don't think I can find this idea by myself from nothing.  
Sincerely, I feel I couldn't do anything without original vim-mode.  

# Whats this?

Fork of [vim-mode](https://github.com/atom/vim-mode). Started at 2015.8.1.

- Many bug fixes.
- Refactoring: Rewritten almost every lines of codes.
- Highlight search
- visual-blockwise built-in
- Incremental search by `incrementalSearch` setting(disabled by default).
- Cursor visible in all visual-mode(characterwise, blockwise, linewise).
- Stay same cursor position after operate(e.g `y`, `gU`) by `stayOnYank`, `stayOnOperate` setting.(disabled by default)
- Lots of new motion like `move-up-to-edge`, `move-down-to-edge`.(No keymap by default)
- Surround built-in. Powerful AnyPair family(`change-surround-any-pair` operator, `inner-any-pair` text-object) to detect pair automatically.
- Set cursor position to start of change on undo or redo by enabling `setCursorToStartOfChangeOnUndoRedo`(disabled by default. Atom's default is end of change).
- Allow super granular keymap only effective when specific operation is pending like `yank-pending`, `delete-pending`. [#215](https://github.com/t9md/atom-vim-mode-plus/issues/215)
- And more...

# Important Note

- You need to disable vim-mode first. You can't use both simultaneously.
- Following packages for vim-mode doesn't work in vim-mode-plus. Why? Because service API name is different. It's easy to add support I believe. Please report to each project.
  - [vim-mode-clipboard-plus](https://atom.io/packages/vim-mode-clipboard-plus)
  - [ex-mode](https://atom.io/packages/ex-mode)
  - [vim-surround](https://atom.io/packages/vim-surround): surround feature included vim-mode-plus, so you won't need this.
  - [vim-mode-visual-block](https://atom.io/packages/vim-mode-visual-block): (my package) builtin to vim-mode-plus with better integration.
- Scope for CSS selector and keymap is different from vim-mode, **not compatible**.
- Internal code base is very different. Thus, issue, PRs should be directly sent to vim-mode-plus. **DONT report vim-mode-plus's issue or PRs to official vim-mode.**

# FAQ

### Why fork? why not directly contribute to official vim-mode?

- Changes are [too big](https://github.com/t9md/atom-vim-mode-plus/graphs/contributors).
- I felt many features are too experimental to merge to official vim-mode.

### In visual-block mode, some motion make editor slow, freeze.

Not freezing, its just VERY slow.  
You can workaround by disabling some keymap. See [#214](https://github.com/t9md/atom-vim-mode-plus/issues/214).

### ex-mode?

- Very immature package [vim-mode-plus-ex-mode](https://atom.io/packages/vim-mode-plus-ex-mode) is exists.
- My thought for ex-mode is [here #52](https://github.com/t9md/atom-vim-mode-plus/issues/52).

### Want to suppress autocomplete-plus's auto suggestion except insert-mode.

Set `suppressActivationForEditorClasses` autocomplete-plus's config to following value.

```
vim-mode-plus.normal-mode, vim-mode-plus.visual-mode, vim-mode-plus.operator-pending-mode, vim-mode-plus.insert-mode.replace
```

If you want to directly edit `config.cson`, here it is.

```coffeescript
"autocomplete-plus":
  suppressActivationForEditorClasses: [
    "vim-mode-plus.normal-mode"
    "vim-mode-plus.visual-mode"
    "vim-mode-plus.operator-pending-mode"
    "vim-mode-plus.insert-mode.replace"
  ]
```

# Wiki

- [Commands](https://github.com/t9md/atom-vim-mode-plus/wiki/Commands) summary of vmp's commands with keymap.
- [Operations](https://github.com/t9md/atom-vim-mode-plus/wiki/Operations) includes most of commands with keymap information.
- [GIFs](https://github.com/t9md/atom-vim-mode-plus/wiki/GIFs) demonstrates fancy features.
- [Keymap example](https://github.com/t9md/atom-vim-mode-plus/wiki/Keymap-example).
- [Extend vmp in init file](https://github.com/t9md/atom-vim-mode-plus/wiki/Extend-vmp-in-init-file)
- [Create vmp plugin](https://github.com/t9md/atom-vim-mode-plus/wiki/Create-vmp-plugin)
- [List of vmp plugins](ttps://github.com/t9md/atom-vim-mode-plus/wiki/List-of-vmp-plugins)

## Keymap

Some of the keymap is not set by default, check following link for reference.

- [Commands](https://github.com/t9md/atom-vim-mode-plus/wiki/Commands) summary of vmp's commands with keymap.
- [keymaps](https://github.com/t9md/atom-vim-mode-plus/blob/master/keymaps/vim-mode-plus.cson)
- [Keymap example](https://github.com/t9md/atom-vim-mode-plus/wiki/Keymap-example)
- [Commands which have no default keymap](https://github.com/t9md/atom-vim-mode-plus/wiki/Commands-which-have-no-default-keymap)

# Helper packages

- [List of vmp plugins](ttps://github.com/t9md/atom-vim-mode-plus/wiki/List-of-vmp-plugins)

Below is list of my packages which provide more vim-like experience.  
Why I don't builtin these feature? Because it take more time and some feature is useful for non-vim user.

- [cursor-history](https://atom.io/packages/cursor-history)
provides <kbd>c-i</kbd>, <kbd>c-o</kbd> to go/back cursor position history.
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

# Commit emoji convention

- :memo: Add comment or doc
- :gift: New feature.
- :bug: Bug fix
- :bomb: Breaking compatibility.
- :white_check_mark: Write test.
- :fire: Remove something.
- :beer: I'm happy like reduced code complexity.
