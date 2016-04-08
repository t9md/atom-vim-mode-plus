- We selectRight on `v`
- So when escape from `v` mode, we have to selectLeft unless selection is reversed or empty.

# visual-mode Normalization

When we modify selection with motion, we have to **normalize** `v` mode cursor position.
This normalization allow us all Motion work properly in `v` mode without special care for `v` mode.

Normalization procedure is..
  - Transform selected range from `vL`, `vB` to `vC` if not already in `vC`
  - Move end position of selection's bufferRange to left.(Since we selectRighted in `v`))

After modification of selection finished, we revert selection's `wise` to original one(`blockwise`, `linewise`).

### `vL` to `vC` transformation

`vC` range to transform is preliminarily preserved on shift from `vC` to `vL` as selection's marker's property.
We use this information when transform range.
We can get this info via `swrap(selection).getProperties()`

### `vB` to `vC` transformation

`vB` mode is achieved by multi-selection. one blockwise selection is set of characterwise multi-selection.
So we can't use selection property to transform `vB` to `vC`.
So we let blockwise transform itself to characterwise.
We can do it via `BlockwiseSelection::restoreCharacterwise()`.

# Experiment

If we enhance selection property to have following information, we can get code more simpler.
- noralized cursor position
- blockwised range
- linewised range

When we modify selection with motion, we have to **normalize** `v` mode cursor position.
This normalization allow us all Motion work properly in `v` mode without special care for `v` mode.

Normalization procedure is..
  - Transform selected range from `vL`, `vB` to `vC` if not already in `vC`
  - Move end position of selection's bufferRange to left.(Since we selectRighted in `v`))

After modification of selection finished, we revert selection's `wise` to original one(`blockwise`, `linewise`).
------------------------------------------

prevent moveRight from moving across EOL in visual-mode,
its very inconsitent.
- I'm ok to if mouse click can put cursor at EOL, its out-of-scoep of vim-mode-plus.
- Just check mouse is not at EOL at the beginning of processing. cursor should never put on EOL in any vim-mode-plus operation.

## Old memo

# Whats this?

This is refactoring experiment for vim-mode.  

See [REFACTORING_IDEA](REFACTORING_IDEA.md).  
See also [What is Motion, TextObject, Operator](https://github.com/atom/vim-mode/issues/800).  

# What this folk project aiming to?

Currently, each TOM(TextObject, Operator, Motion), do very different things, the behavior and responsibility of each TOM is not consistent.  
This inconsistencies reduce flexibility and readability of codebases, and it also making it difficult to introduce custom TOM.  
By taking over tasks currently handled on TOM by new OperationProcessor, each TOM's implementation could be very simplified and easier to maintain.  
This project aiming to prove above idea by implementing working example.  

# Strategy

1. Improve readability by renaming without causing big internal change.
2. Migrate each old TextObject, Operator, Motion(TOM for short) to new one.
3. Introduce new OperationProcessor to process new-TOM.

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

## memo

- vim-state: vim of vimState is redundant, state is enough.
- ~~OpStack is not stack actually, calling it OpQueue is well fit to concept~~.
 - ~~Its queue shifted from front in FIFO manner.~~
 - ~~Enqueue multiple operations and dequeue and process it.~~
- Motion.CurrentSelection should be TextObject.CurrentSelection or TextObject.Selection

- Motion and TextObject is very resemble, but ideally it should be distinguished by name not by TextObject.XXX like prefix.

- Currently vim-mode's TextObject is not really object, its TextObject like command, it mixes operation with TextObject this limit flexibility.

- Operator can take motion and textobject as target of operation although current argument name is motion, but it actually can be TextObject.

Operator's @motion variable name is not appropriate since it can take TextObject so @target should be better.
But accessed from outer object

@complete should be @executable ?

making saving history like saveHistory(entry) rather than current primitive @history.unshift().

`isComplete()` can be `isWaitingTarget`

- Constructor's argument and super() calling with argument is not necessary, redundant.
- Select prefix for every TextObject like `SelectAParagraph` is not appropriate name for TextObject. simply Paragraph is better.

target.select return array of boolean which is result of `not selection.isEmpty()`

- Can eliminate instanceof check for Operator, Motion, TextObject, checking use duck typing like `_.isFunction(target.select)`.
target.select return array of boolean which is result of not selection.isEmpty()

- Why `Scroll` class is not extended from `Motion`?
 - it extend selection when scrolling, so I believe its make sense to be Motion's child class.

- Eliminate `isComplete`, then use `haveTarget` which check existence of `@target`.

# Repeat/Prefix

Does Repeat and Prefix really need to be indpendent object.
Simply make it globally available and let each object refer these value if they want.

`move-to-beginning-of-line` bound to `@moveOrRepeat`.
Its ambiguous. its actually do two thing, but name don't reflect that.

```
'move-to-beginning-of-line': (e) => @moveOrRepeat(e)
```

## [Experimental] Remove Prefix.Repeat
- vimState::getCount(), vimState::setCount() provide count
- add Base::getCount() which retrieve @vimState.getCount()
- make it repeatable/recordable by setting @count instance variable on object.
- behave like following
 - [x] `2dx`, `d2x`: both delete 2 chars.
 - [x] `10d2x`: delete 2 chars, ignore `10`. Need to reseCount() on non-digit input.
- To provide count information via vimState::getCount() all TOM instance need to be able to access vimState.


* [Done](https://github.com/t9md/vim-mode/commit/9b7d18e6a799304241ce7f168c496b9e6a64bf98)
Maybe something broken but I didn't notice, all spec pass without modification

## Reduce number of argument to TOM, and consistent argument.
Currently arguments passed to each TOM is vary.  
To reduce unnecessary complication for developer, its better to pass same arguments even if it won't be used.  
The argument to be passed to all TOM should be
 - vimState: passing editor and editorElement is not necessary since it could be accessed via vimState.
The name of vimState is redundant simply `state` is enough since its vim-mode's state.

# Spec

- [add keystroke method](https://github.com/t9md/vim-mode/commit/a111105dd8a018425a5a0aff3afbf04c46ca93b2)
- I like [more neat spec](https://github.com/t9md/vim-mode/commit/987077e033b81f913b2503119bb05f3e202f9696).

# TextObject
- Around(or A), Inside could be consolidated by changing behavior with options argument.  
- Scroll Motion can be consolidated by changing behavior with options arguments.

# Naming

- Motions.MoveToLine is very complicated.
  MoveToLine is not directly exposed, and MoveToAbsoluteLine is mapped to move-to-line command.
  So I renamed MoveToLine > MoveToLineBase, and MoveToAbsoluteLine > MoveToLine.
- `vimState::pushSearchHistory` -> `vimState::saveSearchHistory`

`introduce ViewModel.onDidGetInput()` to simplify code.

# NOTE for refactoring motion.coffee

## Preconditions

- In visual-mode, we `selectRight()` when activating visual-mode.
- After deactivating visualmode. we `moveLeft()` cursor.
- selection can be reversed.
- In atom, when selecting whole single line range become [[0, 0], [1, 0]], NOTE end row is not same row as start row.
- selection set `selection.linewise = true` when `selection.selectLine(row)`.
- moveRight, moverLeft wrap line
  - When `moveLeft()` at BOL, cursor moved to EOL of previous line.
  - When `moveRight()` at EOL, cursor moved to BOL of next line.
- We can't `moveLeft()` when `isAtBeginningOfLine()` unless `wrapLeftRightMotion` is enabled.
- When cursor `isAtEndOfLine()`, then `cursor.moveRight()` put cursor to nextline's column 0. (this mean skip 'newLine' char.)
- When selecting whole line `selection.getBufferRange().isSingleLine()` return `false` since its expand multiple line ([selectedRow, 0], [nextRow, 0]).
- Currently visual-mode not allow de-select first column char its bug, since Vim allow user to de-select first column.

Cleanup Mode-shift

main   submode
Normal null
Insert null, replace
Visual characterwise, linewise, blockwise

|fr\to| n | i | ir | vc | vl | vb |
|-----|---|---|----|----|--- |--- |
| n   |   |   |    |    |    |    |
| i   |   |   |    |    |    |    |
| ir  |   |   |    |    |    |    |
| vc  |   |   |    |    |    |    |
| vl  |   |   |    |    |    |    |
| vb  |   |   |    |    |    |    |
