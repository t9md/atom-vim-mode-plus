# TOM report detail
### OperatorError

### Operator
- ::vimState: `null`
- ::target: `null`
- ::complete: `null`
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`
- ::compose: `[Function]`
- ::canComposeWith: `[Function]`
- ::setTextRegister: `[Function]`

### OperatorWithInput < Operator
- ::canComposeWith: `[Function]`
- ::compose: `[Function]`

### Select < Operator
- ::execute: `[Function]`

### Delete < Operator
- ::register: `null`
- ::execute: `[Function]`

### ToggleCase < Operator
- ::execute: `[Function]`

### UpperCase < Operator
- ::execute: `[Function]`

### LowerCase < Operator
- ::execute: `[Function]`

### Yank < Operator
- ::register: `null`
- ::execute: `[Function]`

### Join < Operator
- ::execute: `[Function]`

### Repeat < Operator
- ::isRecordable: `[Function]`
- ::execute: `[Function]`

### Mark < OperatorWithInput < Operator
- ::execute: `[Function]`

### Increase < Operator
- ::step: `1`
- ::execute: `[Function]`
- ::increaseNumber: `[Function]`

### Decrease < Increase < Operator
- ::step: `-1`

### AdjustIndentation < Operator
- ::execute: `[Function]`

### Indent < AdjustIndentation < Operator
- ::indent: `[Function]`

### Outdent < AdjustIndentation < Operator
- ::indent: `[Function]`

### Autoindent < AdjustIndentation < Operator
- ::indent: `[Function]`

### Put < Operator
- ::register: `null`
- ::execute: `[Function]`
- ::onLastRow: `[Function]`
- ::onLastColumn: `[Function]`

### Replace < OperatorWithInput < Operator
- ::execute: `[Function]`

### MotionError

### Motion
- ::operatesInclusively: `true`
- ::operatesLinewise: `false`
- ::select: `[Function]`
- ::execute: `[Function]`
- ::moveSelectionLinewise: `[Function]`
- ::moveSelectionInclusively: `[Function]`
- ::moveSelection: `[Function]`
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`
- ::isLinewise: `[Function]`
- ::isInclusive: `[Function]`

### MotionWithInput < Motion
- ::isComplete: `[Function]`
- ::canComposeWith: `[Function]`
- ::compose: `[Function]`

### MoveLeft < Motion
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

### MoveRight < Motion
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

### MoveUp < Motion
- ::operatesLinewise: `true`
- ::moveCursor: `[Function]`

### MoveDown < Motion
- ::operatesLinewise: `true`
- ::moveCursor: `[Function]`

### MoveToPreviousWord < Motion
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

### MoveToPreviousWholeWord < Motion
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`
- ::isWholeWord: `[Function]`
- ::isBeginningOfFile: `[Function]`

### MoveToNextWord < Motion
- ::wordRegex: `null`
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`
- ::isEndOfFile: `[Function]`

### MoveToNextWholeWord < MoveToNextWord < Motion
- ::wordRegex: `/^\s*$|\S+/`

### MoveToEndOfWord < Motion
- ::wordRegex: `null`
- ::moveCursor: `[Function]`

### MoveToEndOfWholeWord < MoveToEndOfWord < Motion
- ::wordRegex: `/\S+/`

### MoveToNextParagraph < Motion
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

### MoveToPreviousParagraph < Motion
- ::moveCursor: `[Function]`

### MoveToLine < Motion
- ::operatesLinewise: `true`
- ::getDestinationRow: `[Function]`

### MoveToAbsoluteLine < MoveToLine < Motion
- ::moveCursor: `[Function]`

### MoveToRelativeLine < MoveToLine < Motion
- ::operatesLinewise: `true`
- ::moveCursor: `[Function]`

### MoveToScreenLine < MoveToLine < Motion
- ::moveCursor: `[Function]`

### MoveToBeginningOfLine < Motion
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

### MoveToFirstCharacterOfLine < Motion
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

### MoveToFirstCharacterOfLineAndDown < Motion
- ::operatesLinewise: `true`
- ::operatesInclusively: `true`
- ::moveCursor: `[Function]`

### MoveToLastCharacterOfLine < Motion
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

### MoveToLastNonblankCharacterOfLineAndDown < Motion
- ::operatesInclusively: `true`
- ::skipTrailingWhitespace: `[Function]`
- ::moveCursor: `[Function]`

### MoveToFirstCharacterOfLineUp < Motion
- ::operatesLinewise: `true`
- ::operatesInclusively: `true`
- ::moveCursor: `[Function]`

### MoveToFirstCharacterOfLineDown < Motion
- ::operatesLinewise: `true`
- ::moveCursor: `[Function]`

### MoveToStartOfFile < MoveToLine < Motion
- ::moveCursor: `[Function]`

### MoveToTopOfScreen < MoveToScreenLine < MoveToLine < Motion
- ::getDestinationRow: `[Function]`

### MoveToBottomOfScreen < MoveToScreenLine < MoveToLine < Motion
- ::getDestinationRow: `[Function]`

### MoveToMiddleOfScreen < MoveToScreenLine < MoveToLine < Motion
- ::getDestinationRow: `[Function]`

### ScrollKeepingCursor < MoveToLine < Motion
- ::previousFirstScreenRow: `0`
- ::currentFirstScreenRow: `0`
- ::select: `[Function]`
- ::execute: `[Function]`
- ::moveCursor: `[Function]`
- ::getDestinationRow: `[Function]`
- ::scrollScreen: `[Function]`

### ScrollHalfUpKeepCursor < ScrollKeepingCursor < MoveToLine < Motion
- ::scrollDestination: `[Function]`

### ScrollFullUpKeepCursor < ScrollKeepingCursor < MoveToLine < Motion
- ::scrollDestination: `[Function]`

### ScrollHalfDownKeepCursor < ScrollKeepingCursor < MoveToLine < Motion
- ::scrollDestination: `[Function]`

### ScrollFullDownKeepCursor < ScrollKeepingCursor < MoveToLine < Motion
- ::scrollDestination: `[Function]`

### Find < MotionWithInput < Motion
- ::match: `[Function]`
- ::reverse: `[Function]`
- ::moveCursor: `[Function]`

### Till < Find < MotionWithInput < Motion
- ::match: `[Function]`
- ::moveSelectionInclusively: `[Function]`

### MoveToMark < MotionWithInput < Motion
- ::operatesInclusively: `false`
- ::isLinewise: `[Function]`
- ::moveCursor: `[Function]`

### SearchBase < MotionWithInput < Motion
- ::operatesInclusively: `false`
- ::reversed: `[Function]`
- ::moveCursor: `[Function]`
- ::scan: `[Function]`
- ::getSearchTerm: `[Function]`
- ::updateCurrentSearch: `[Function]`
- ::replicateCurrentSearch: `[Function]`

### Search < SearchBase < MotionWithInput < Motion

### SearchCurrentWord < SearchBase < MotionWithInput < Motion
- @keywordRegex: `null`
- ::getCurrentWord: `[Function]`
- ::cursorIsOnEOF: `[Function]`
- ::getCurrentWordMatch: `[Function]`
- ::isComplete: `[Function]`
- ::execute: `[Function]`

### BracketMatchingMotion < SearchBase < MotionWithInput < Motion
- ::operatesInclusively: `true`
- ::isComplete: `[Function]`
- ::searchForMatch: `[Function]`
- ::characterAt: `[Function]`
- ::getSearchData: `[Function]`
- ::moveCursor: `[Function]`

### RepeatSearch < SearchBase < MotionWithInput < Motion
- ::isComplete: `[Function]`
- ::reversed: `[Function]`

### Insert < Operator
- ::standalone: `true`
- ::isComplete: `[Function]`
- ::confirmChanges: `[Function]`
- ::execute: `[Function]`
- ::inputOperator: `[Function]`

### ReplaceMode < Insert < Operator
- ::execute: `[Function]`
- ::countChars: `[Function]`

### InsertAfter < Insert < Operator
- ::execute: `[Function]`

### InsertAfterEndOfLine < Insert < Operator
- ::execute: `[Function]`

### InsertAtBeginningOfLine < Insert < Operator
- ::execute: `[Function]`

### InsertAboveWithNewline < Insert < Operator
- ::execute: `[Function]`

### InsertBelowWithNewline < Insert < Operator
- ::execute: `[Function]`

### Change < Insert < Operator
- ::standalone: `false`
- ::register: `null`
- ::execute: `[Function]`

### SubstituteLine < Change < Insert < Operator
- ::standalone: `true`
- ::register: `null`

### Prefix
- ::complete: `null`
- ::composedObject: `null`
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`
- ::compose: `[Function]`
- ::execute: `[Function]`
- ::select: `[Function]`
- ::isLinewise: `[Function]`

### Register < Prefix
- ::name: `null`
- ::compose: `[Function]`

### TextObject
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`

### CurrentSelection < TextObject
- ::select: `[Function]`

### SelectInsideWord < TextObject
- ::select: `[Function]`

### SelectAWord < TextObject
- ::select: `[Function]`

### SelectInsideWholeWord < TextObject
- ::select: `[Function]`

### SelectAWholeWord < TextObject
- ::select: `[Function]`

### SelectInsideQuotes < TextObject
- ::findOpeningQuote: `[Function]`
- ::isStartQuote: `[Function]`
- ::lookForwardOnLine: `[Function]`
- ::findClosingQuote: `[Function]`
- ::select: `[Function]`

### SelectInsideBrackets < TextObject
- ::findOpeningBracket: `[Function]`
- ::findClosingBracket: `[Function]`
- ::select: `[Function]`

### SelectInsideParagraph < TextObject
- ::select: `[Function]`

### SelectAParagraph < TextObject
- ::select: `[Function]`

### Scroll
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`

### ScrollDown < Scroll
- ::execute: `[Function]`
- ::keepCursorOnScreen: `[Function]`
- ::scrollUp: `[Function]`

### ScrollUp < Scroll
- ::execute: `[Function]`
- ::keepCursorOnScreen: `[Function]`
- ::scrollDown: `[Function]`

### ScrollCursor < Scroll

### ScrollCursorToTop < ScrollCursor < Scroll
- ::execute: `[Function]`
- ::scrollUp: `[Function]`
- ::moveToFirstNonBlank: `[Function]`

### ScrollCursorToMiddle < ScrollCursor < Scroll
- ::execute: `[Function]`
- ::scrollMiddle: `[Function]`
- ::moveToFirstNonBlank: `[Function]`

### ScrollCursorToBottom < ScrollCursor < Scroll
- ::execute: `[Function]`
- ::scrollDown: `[Function]`
- ::moveToFirstNonBlank: `[Function]`

### ScrollHorizontal
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`
- ::putCursorOnScreen: `[Function]`

### ScrollCursorToLeft < ScrollHorizontal
- ::execute: `[Function]`

### ScrollCursorToRight < ScrollHorizontal
- ::execute: `[Function]`
