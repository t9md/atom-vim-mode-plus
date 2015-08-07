# Note by t9md
This is refactoring experiment for vim-mode.  

See [REFACTORING_IDEA](REFACTORING_IDEA.md).  
See also [What is Motion, TextObject, Operator](https://github.com/atom/vim-mode/issues/800).  

# Step

1. Improve readability by renaming without causing big internal change.
2. Migrate each old TextObject, Operator, Motion(TOM for short) to new one.
3. Introduce new OperationProcessor to process  new-TOM.


# Terminology

- TOM: TextObject, Operator, Motion

# TOM-report

Done by extending Base class, so each TOM and its instance can report itself.

- [TOM-report](https://github.com/t9md/vim-mode/blob/refactor-experiment/docs/TOM-report.md)

# Status

- [x] Make opeStack independent
- [x] Eliminate Prefix.Repeat object. Count is provided as global to object by inheriting Base.
- [x] TOM can respond to its class(e.g. isTextObject()?)
- [x] Realtime observation of OperatonStack.

# How Operation Stack works.

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
