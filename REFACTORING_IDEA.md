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
- selection maybe reversed.
- In atom, when selecting whole single line range become [[0, 0], [1, 0]]
- selection set `selection.linewise = true` when `selection.selectLine(row)`.
- We can't `moveLeft()` when `isAtBeginningOfLine()` unless `wrapLeftRightMotion` is enabled.
- When cursor `isAtEndOfLine()`, then `cursor.moveRight()` put cursor to nextline's column 0. (this mean skip 'newLine' char.)
- When selecting whole line `selection.getBufferRange().isSingleLine()` return `false` since its expand multiple line ([selectedRow, 0], [nextRow, 0]).
- Currently visual-mode not allow de-select first column char its bug, since Vim allow user to de-select first column.
- To allow cursor
