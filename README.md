# Note by t9md
This is refactoring experiment for vim-mode.  

See [REFACTORING_IDEA](REFACTORING_IDEA.md).  
See also [What is Motion, TextObject, Operator](https://github.com/atom/vim-mode/issues/800).  

# What this folk project aiming to?

Currently, each TOM(TextObject, Operator, Motion), do very different things, the behavior and responsibility of each TOM is not consistent.  
This inconsistencies reduce flexibility and readablity of codebases, and it also making it difficult to introduce custom TOM.  
By taking over tasks currently handled on TOM by new OperationProcessor, each TOM's implementation could be very simplified and easier to maintain.  
This project aiming to prove above idea by implementing working example.  

# Strategy

1. Improve readability by renaming without causing big internal change.
2. Migrate each old TextObject, Operator, Motion(TOM for short) to new one.
3. Introduce new OperationProcessor to process  new-TOM.

# New Features

This project started at August 1st 2015 as folk of vim-mode.  
After 1 month of refactoring, I'm getting tired for long long refactoring marathon.  
My current(2015.9.6.) 1st prioritized TODO is refactor `motion.coffee`, I know it.  
But I need some pastime, refresher, So I added following new features which is not included Vim and vim-mode as pastime.  

- New Operator
  - Surround, DeleteSurround, ChangeSurround. Instead of vim-surround atom package, its repeatable(very improtant) with `.`.
  - Common string transformation includes SnakeCase, CamelCase, DashCase.
  - ToggleLineComments which toggle comment of target-area(selected by motion or text-objects).
  - ReplaceWithRegister which replace target-area(selected by text-object or motion) with register's text. Very useful since its repeatable.
- TextObject
  - Indent which select consecutive deeper indented lines
  - Entire buffer.
  - CurrentLine. Useful when you do surround line.
  - Comment. which select consecutive commented lines.
- Motion
  - `0` is accessible position than `^` so provide config option to behave `0` like `^`(I want single `0` behave as `^` without losing setting count 0 ability).
- Instant feedback of your operation. Count/Register/Operation you typed is displayed as hover(overlay) element.
 - Showing emoji that representing operation.
- Flashing(highlighting) operation affected area(range) for yank, paste, toggle etc..
- Developer friendly introspection report and real-time opration-stack monitoring(logged on console).
- `gugu`, `guu` `gUgU`, `gUU` support which is yet supported in vim-mode.
- SelectInsideBrackets family skip backslash escaped pair character.
- Show cursor(by using decoration) while waiting user input (e.g `m`, `"`). Cursor disappear in official vim-mode.
- Support visual-block-mode except blockwise yank, and paste.
- Show cursor in visual-mode characterwise.
- Expose visual-mode's submode to text-editor-element's css class to be used as selector.

# Terminology

- TOM: TextObject, Operator, Motion
- Kind: Class Name of each TOM.
- oTOM: old TOM, TOM of current vim-mode.
- pTOM: pure TOM, TOM which do very minimal things which responsibility is only return Point or Range.
- OperationProcessor

# OperationProcessor
- Handle multi cursor situation
- Handle count(how much each operation should be repated).
- Composing operation with target.

# Spec

Work in progress, may change depending on how was it useful after implement and evaluation of each spec.  

- each TOM can respond to `getKind()` which return name of Class.
- each TOM can respond to `is#{Klass}()` function, which return result of `this instanceof klass`.
- Be consistent, dont' vary argument list passed to TOM, instead define explicit TOM.
- TOM take only one argument, its vimState.

# TOM-report

Done by extending Base class, so each TOM and its instance can report itself.

- [TOM-report](https://github.com/t9md/vim-mode/blob/refactor-experiment/docs/TOM-report.md)

# TODO

- [ ] Incorporate [paner](https://github.com/t9md/atom-paner) which improve, `ctrl-w`+`HJKLsv` actions. - [ ] Introduce new scope based motion by incorporating with [goto-scope](https://github.com/t9md/atom-goto-scope).
- [ ] Improve search and introduce incrementalSearch.
- [ ] Spec re-write 2nd round to compact and simple description for each spec.
- [x] Show cursor in visual-mode(now characterwise only) without hacking `Cursor.prototype`.
- [x] Support visual-block by incorporating with [vim-mode-visual-block](https://github.com/t9md/atom-vim-mode-visual-block).
- [x] Support web-font(?) font-awesome etc. to show on overlay hover.
- [x] `0` is accessible position than `^` so provide config option to behave `0` like `^`(I want single `0` behave as `^`).
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

# How Operation Stack works(for current official vim-mode).

Expalaining how [OperationStack](https://github.com/t9md/vim-mode/blob/refactor-experiment/lib/operation-stack.coffee) works.  
By using `yip`(Yank, inside paragraph) operation as example.  
Below is what happens on each processing step and corresponding debug output of operation-stack.  

1. `y` cause instantiate new `Operators.Yank`. and then `push()` this new instance to OperationStack.
2. After pushing `Yank` Operator, then `process`, if operation is not `isComplete()`, activating operator-pending-mode, then return from process function.
3. Then user type `ip`, this cause instantiate new `TextObjects.SelectInsideParagraph`, then `push()` it to OperationStack.
4. Then `process()` it. now `SelectInsideParagraph` is top of stack and it `isComplete()`, so in this time we don't enter operator-pending-mode.
5. Then processor `pop()` top operation, and it have still operations on stack, processor try to `compose()` `pop()`ed operation(here `SelectInsideParagraph`) to newTop operation(here `Yank`).
Repeat this pop-and-compose(by calling `process()` recursively) until stack get emptied.
6. When stack got emptied, its time to execute, calling `opration.execute()` operates on `@target`(here `SelectInsideParagraph`) of operation, which target is object composed in process 6.

```
#=== Start at 2015-08-07T06:03:24.797Z
-> @process(): start
  [@stack] size: 1
  <idx: 0>
  ## [object Object]: Yank < Operator
  - @editor: `<TextEditor 2404>`
  - @register: `'*'`

  ### Yank < Operator
  - ::register: `null`
  - ::execute: `[Function]`

-> @process(): return. activate: operator-pending-mode
-> @process(): start
  [@stack] size: 2
  <idx: 0>
  ## [object Object]: Yank < Operator
  - @editor: `<TextEditor 2404>`
  - @register: `'*'`

  ### Yank < Operator
  - ::register: `null`
  - ::execute: `[Function]`

  <idx: 1>
  ## [object Object]: SelectInsideParagraph < TextObject
  - @editor: `<TextEditor 2404>`
  - @inclusive: `false`

  ### SelectInsideParagraph < TextObject
  - ::select: `[Function]`

-> @pop()
  - popped = <SelectInsideParagraph>
  - newTop = <Yank>
-> <Yank>.compose(<SelectInsideParagraph>)
-> @process(): recursive
-> @process(): start
  [@stack] size: 1
  <idx: 0>
  ## [object Object]: Yank < Operator
  - @editor: `<TextEditor 2404>`
  - @register: `'*'`
  - @target:
    ## [object Object]: SelectInsideParagraph < TextObject
    - @editor: `<TextEditor 2404>`
    - @inclusive: `false`

    ### SelectInsideParagraph < TextObject
    - ::select: `[Function]`

  - @complete: `true`

  ### Yank < Operator
  - ::register: `null`
  - ::execute: `[Function]`

-> @pop()
  - popped = <Yank>
  - newTop = <undefined>
 -> <Yank>.execute()
#=== Finish at 2015-08-07T06:03:25.157Z
```

# END Note by t9md

## Vim Mode package [![Build Status](https://travis-ci.org/atom/vim-mode.svg?branch=master)](https://travis-ci.org/atom/vim-mode)

Provides vim modal control for Atom, ideally blending the best of vim
and Atom.

### Installing

Use the Atom package manager, which can be found in the Settings view or
run `apm install vim-mode` from the command line.

### Current Status

Sizable portions of Vim's normal mode work as you'd expect, including
many complex combinations. Even so, this package is far from finished (Vim
wasn't built in a day).

If you want the vim ex line (for `:w`, `:s`, etc.), you can try [ex-mode](https://atom.io/packages/ex-mode)
which works in conjuction with this plugin.

Currently, vim-mode has some issues with international keyboard layouts.

If there's a feature of Vim you're missing, it might just be that you use it
more often than other developers. Adding a feature can be quick and easy. Check
out the [closed pull requests](https://github.com/atom/vim-mode/pulls?direction=desc&page=1&sort=created&state=closed)
to see examples of community contributions. We're looking forward to yours, too.

### Documentation

* [Overview](https://github.com/atom/vim-mode/blob/master/docs/overview.md)
* [Motions and Text Objects](https://github.com/atom/vim-mode/blob/master/docs/motions.md)
* [Operators](https://github.com/atom/vim-mode/blob/master/docs/operators.md)
* [Windows](https://github.com/atom/vim-mode/blob/master/docs/windows.md)
* [Scrolling](https://github.com/atom/vim-mode/blob/master/docs/scrolling.md)

### Development

* Create a branch with your feature/fix.
* Add a spec (take inspiration from the ones that are already there).
* If you're adding a command be sure to update the appropriate file in
  `docs/`
* Create a PR.

When in doubt, open a PR earlier rather than later so that you can receive
feedback from the community. We want to get your fix or feature included as much
as you do.

See [the contribution guide](https://github.com/atom/vim-mode/blob/master/CONTRIBUTING.md).
