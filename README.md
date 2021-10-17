# vim-mode-plus [![Build Status](https://travis-ci.org/t9md/atom-vim-mode-plus.svg)](https://travis-ci.org/t9md/atom-vim-mode-plus) [![BountySource](https://api.bountysource.com/badge/team?team_id=116280&style=raised)](https://www.bountysource.com/teams/atom-vim-mode-plus)

vim-mode improved.

<!-- TOC START min:1 max:3 link:true asterisk:true update:true -->
* [vim-mode-plus](#vim-mode-plus)
* [Installation](#installation)
* [Some Features](#some-features)
* [Important](#important)
    * [You must disable vim-mode to use vim-mode-plus](#you-must-disable-vim-mode-to-use-vim-mode-plus)
    * [From v1.9.0 CoffeeScript based vim-mode-plus extension is no longer supported](#from-v190-coffeescript-based-vim-mode-plus-extension-is-no-longer-supported)
* [Thanks](#thanks)
* [Issue report](#issue-report)
* [Whats this?](#whats-this)
* [FAQ](#faq)
    * [Why fork? why not directly contribute to official vim-mode?](#why-fork-why-not-directly-contribute-to-official-vim-mode)
    * [Behavior different from pure Vim?](#behavior-different-from-pure-vim)
    * [In visual-block mode, some motions make the editor slow, freeze.](#in-visual-block-mode-some-motions-make-the-editor-slow-freeze)
    * [ex-mode?](#ex-mode)
    * [Want to suppress autocomplete-plus's auto suggestion except insert-mode.](#want-to-suppress-autocomplete-pluss-auto-suggestion-except-insert-mode)
    * [Flash effect does not appear on cursor-line, occurrence-marker is not displayed on cursor-line either.](#flash-effect-does-not-appear-on-cursor-line-occurrence-marker-is-not-displayed-on-cursor-line-either)
    * [Surround not work](#surround-not-work)
    * [How can I insert single white space when surround?](#how-can-i-insert-single-white-space-when-surround)
    * [I want to automatically disable IME when leaving `insert-mode`.(want `set imdisable` equivalent in pure-Vim).](#i-want-to-automatically-disable-ime-when-leaving-insert-modewant-set-imdisable-equivalent-in-pure-vim)
* [Wiki](#wiki)
* [Keymap](#keymap)
* [Helper packages](#helper-packages)
* [References](#references)
  * [Vim official](#vim-official)
  * [Other](#other)
* [Commit emoji convention](#commit-emoji-convention)
<!-- TOC END -->

# Installation

Install using [Atoms package installer](http://flight-manual.atom.io/using-atom/sections/atom-packages/)

`apm install vim-mode-plus`

# Some Features

These features are very powerful, especially for the power user. Read the following documents to learn how to use them.  

- [Movie on youtube to show power of occurrence](https://www.youtube.com/watch?v=01yHgi59ASg&t=119s)
- [Tweet for quick guide for occurrence](https://twitter.com/t9md/status/928155248283197440)
- [Advanced Topic Tutorial](https://github.com/t9md/atom-vim-mode-plus/wiki/AdvancedTopicTutorial)
- [Occurrence Modifier](https://github.com/t9md/atom-vim-mode-plus/wiki/OccurrenceModifier)
- [CHANGELOG.md](https://github.com/t9md/atom-vim-mode-plus/blob/master/CHANGELOG.md)

# Important

### You must disable vim-mode to use vim-mode-plus

- You don't need the following packages since they're built-in to vim-mode-plus:
  - [vim-surround](https://atom.io/packages/vim-surround): No default keymap. See FAQ section in this doc.
  - [vim-mode-visual-block](https://atom.io/packages/vim-mode-visual-block)
- Scope for CSS selector and keymap is different from vim-mode, **not compatible**.
- Internal code base is very different. Thus, issues and PRs should be directly sent to vim-mode-plus. **DON'T report vim-mode-plus's issues or PRs to the official vim-mode.**

### From v1.9.0 CoffeeScript based vim-mode-plus extension is no longer supported

- Now all operations are defined as ES6 class which is NOT extend-able by CoffeeScript.
  - If you have vmp custom operations in your `init.coffee`, those are no longer working.
  - See [CHANGELOG](https://github.com/t9md/atom-vim-mode-plus/blob/master/CHANGELOG.md) and [Wiki](https://github.com/t9md/atom-vim-mode-plus/wiki/ExtendVimModePlusInInitFile) for detail.

# Thanks

My work is greatly owing to former achievements of the original vim-mode developers and many of its contributors.  
As you can see in the commit history, this project was originally started by forking official [vim-mode](https://github.com/atom/vim-mode).  
The great design to achieve Vim operation by composing operator with target (motion, text-object) on top of operationStack still lives in vim-mode-plus now.  
I don't think I can find this idea by myself from nothing.  
Sincerely, I feel I couldn't do anything without the original vim-mode.  

# Issue report

- Read [ISSUE_TEMPLATE](https://github.com/t9md/atom-vim-mode-plus/blob/master/ISSUE_TEMPLATE.md)

# Whats this?

Fork of [vim-mode](https://github.com/atom/vim-mode). Started on 2015.8.1.

- Many bug fixes.
- Refactoring: Rewritten almost every line of code.
- Highlight search
- visual-blockwise built-in
- Incremental search by `incrementalSearch` setting (disabled by default).
- Cursor visible in all visual-mode (characterwise, blockwise, linewise).
- Maintain the same cursor position after operations (e.g `y`, `gU`) by `stayOnYank`, `stayOnOperate` setting. (disabled by default)
- Lots of new motions like `move-up-to-edge`, `move-down-to-edge`. (Mapped to `[` and `]`, Aggressive decision.)
- Surround built-in. Powerful AnyPair family (`change-surround-any-pair` operator, `inner-any-pair` text-object) to detect pair automatically.
- Set cursor position to start of change on undo or redo by enabling `setCursorToStartOfChangeOnUndoRedo` (enabled by default. Atom's default is end of change).
- Allow super granular keymap which is only effective when specific operation is pending like `yank-pending`, `delete-pending`. [#215](https://github.com/t9md/atom-vim-mode-plus/issues/215)
- And more...

# FAQ

Search [Q&A](https://github.com/t9md/atom-vim-mode-plus/issues?utf8=%E2%9C%93&q=label%3AQ%26A) label on issues.

### Why fork? why not directly contribute to official vim-mode?

- Changes are [too big](https://github.com/t9md/atom-vim-mode-plus/graphs/contributors).
- I felt many features are too experimental to merge to the official vim-mode.

### Behavior different from pure Vim?

Some behaviors are intentionally have different default behaviors.
See [DifferencesFromPureVim](https://github.com/t9md/atom-vim-mode-plus/wiki/DifferencesFromPureVim) for details.

### In visual-block mode, some motions make the editor slow, freeze.

Not freezing, it's just VERY slow.  
You can workaround by disabling some keymap. See [#214](https://github.com/t9md/atom-vim-mode-plus/issues/214).

### ex-mode?

- The [ex-mode](https://atom.io/packages/ex-mode) package has the most complete ex-mode support.
- Very immature package [vim-mode-plus-ex-mode](https://atom.io/packages/vim-mode-plus-ex-mode) exists.
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

### Flash effect does not appear on cursor-line, occurrence-marker is not displayed on cursor-line either.

This is because of the syntax-theme you are using.
See [this tips on Wiki](https://github.com/t9md/atom-vim-mode-plus/wiki/TIPS#flash-effect-not-appear-on-cursor-line-occurrence-marker-is-not-displayed-on-cursor-line-too).

### Surround not work

No default keymaps are provided.
If you want, install [vim-mode-plus-keymaps-for-surround](https://github.com/t9md/atom-vim-mode-plus-keymaps-for-surround)

### How can I insert single white space when surround?

Set `Characters To Add Space On Surround`. from vim-mode-plus's setting.

### I want to automatically disable IME when leaving `insert-mode`.(want `set imdisable` equivalent in pure-Vim).

Now in-eval phase for this experimental feature.  
From vim-mode-plus's settings-view set `autoDisableInputMethodWhenLeavingInsertMode` to `true`(default `false`).

This feature doesn't actually disable IME, its' just set `readonly` attribute to editor's hidden [input][MDN input] element.  
It should work for most IME but some Chinese IME still type multibyte character even in `readonly` input.  
For detail, see this [discussion][discussion].  

[MDN input]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
[discussion]: https://github.com/frapples/vim-mode-plus-patch-switch-ime/issues/1

# Wiki

- [Home](https://github.com/t9md/atom-vim-mode-plus/wiki/Home)

# Keymap

vim-mode-plus has many advanced, experimental features but most of them have no default keymap.  
If you want to use the full power of vim-mode-plus, see and experiment with each keymap, command in following links.  

- [Commands](https://github.com/t9md/atom-vim-mode-plus/wiki/Commands) summary of vmp's commands with keymap.
- [default keymaps](https://github.com/t9md/atom-vim-mode-plus/blob/master/keymaps/vim-mode-plus.cson)
- [my dotfiles](https://github.com/t9md/dotfiles)

# Helper packages

- [ListOfVimModePlusPlugins](https://github.com/t9md/atom-vim-mode-plus/wiki/ListOfVimModePlusPlugins)

Below is list of my packages which provide more vim-like experience.  
Why I don't build in these features? Because it takes more time and some features are useful for non-vim user.

- [no-evil-eol-newline](https://atom.io/packages/no-evil-eol-newline)
Hide the last "empty line", like what Vim is doing.
- [cursor-history](https://atom.io/packages/cursor-history)
provides <kbd>c-i</kbd>, <kbd>c-o</kbd> to go/back in the cursor position history.
- [open-this](https://atom.io/packages/open-this)
provides <kbd>gf</kbd> to open file under cursor.
- [clip-history](https://atom.io/packages/clip-history)
Does not exist in pure Vim, provides clip-board history you can pop yanked text until you get result you want.
- [choose-pane](https://atom.io/packages/choose-pane)
Does not exist in pure Vim, provides keyboard navigation between panes/panels by choosing it by label.
- [keystroke](https://atom.io/packages/keystroke)
Keystrokes to keystroke keyamp in you `keymap.cson`.

# References

## Vim official
- [motion](http://vimhelp.appspot.com/motion.txt.html)
- [operator](http://vimhelp.appspot.com/motion.txt.html#operator)
- [text-object](http://vimhelp.appspot.com/motion.txt.html#object-select)
- [change](http://vimhelp.appspot.com/change.txt.html)
- [marks](http://vimhelp.appspot.com/motion.txt.html#mark-motions)
- [scroll](http://vimhelp.appspot.com/scroll.txt.html)
- [search-commands](http://vimhelp.appspot.com/pattern.txt.html#search-commands)

## Other
- [operator, the true power of Vim](http://whileimautomaton.net/2008/11/vimm3/operator) by kana.  
  True power of Vim is Operator and TextObject.

- [List of text-object as vim plugin](https://github.com/kana/vim-textobj-user/wiki)  
  vim-mode-plus builtin textobj for function, fold, entire, comment, indent, line, and any-pair(super set of many pair text-obj)

# Commit emoji convention

- :memo: Add comment or doc
- :gift: New feature.
- :bug: Bug fix.
- :bomb: Breaking compatibility.
- :white_check_mark: Write test.
- :fire: Remove something.
- :beer: I'm happy like reduced code complexity.
