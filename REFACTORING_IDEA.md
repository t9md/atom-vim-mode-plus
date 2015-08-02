- vim-state: vim of vimState is redundant, state is enough.
- ~~OpStack is not stack actually, calling it OpQueue is well fit to concept~~.
 - Its queue shifted from front in FIFO manner.
 - Enqueue multiple operations and dequeue and process it.
- Motion.CurrentSelection should be TextObject.CurrentSelection or TextObject.Selection

- Motion and TextObject is very resemble, but ideally it should be distinguished by name not by TextObject.XXX like prefix.

- Currently vim-mode's TextObject is not really object, its TextObject like command, it mixes operation with TextObject this limit flexibility.

- Operator can take motion and textobject as target of operation although current argumenet name is motion, but it actually can be TextObject.

Operator's @target variable name is not appropriate since it can take TextObject so @target should be better.
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

# Naming

- `vimState::pushSearchHistory` -> `vimState::saveSearchHistory`
