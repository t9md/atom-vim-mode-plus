## OperatorError

## Operator
- ::vimState: `null`
- ::target: `null`
- ::complete: `null`
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`
- ::compose: `[Function]`
- ::canComposeWith: `[Function]`
- ::setTextRegister: `[Function]`

## OperatorWithInput
- ::canComposeWith: `[Function]`
- ::compose: `[Function]`

## Select
- ::execute: `[Function]`

## Delete
- ::register: `null`
- ::execute: `[Function]`

## ToggleCase
- ::execute: `[Function]`

## UpperCase
- ::execute: `[Function]`

## LowerCase
- ::execute: `[Function]`

## Yank
- ::register: `null`
- ::execute: `[Function]`

## Join
- ::execute: `[Function]`

## Repeat
- ::isRecordable: `[Function]`
- ::execute: `[Function]`

## Mark
- ::execute: `[Function]`

## Increase
- ::step: `1`
- ::execute: `[Function]`
- ::increaseNumber: `[Function]`

## Decrease
- ::step: `-1`

## AdjustIndentation
- ::execute: `[Function]`

## Indent
- ::indent: `[Function]`

## Outdent
- ::indent: `[Function]`

## Autoindent
- ::indent: `[Function]`

## Put
- ::register: `null`
- ::execute: `[Function]`
- ::onLastRow: `[Function]`
- ::onLastColumn: `[Function]`

## Replace
- ::execute: `[Function]`

## MotionError

## Motion
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

## MotionWithInput
- ::isComplete: `[Function]`
- ::canComposeWith: `[Function]`
- ::compose: `[Function]`

## MoveLeft
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

## MoveRight
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

## MoveUp
- ::operatesLinewise: `true`
- ::moveCursor: `[Function]`

## MoveDown
- ::operatesLinewise: `true`
- ::moveCursor: `[Function]`

## MoveToPreviousWord
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

## MoveToPreviousWholeWord
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`
- ::isWholeWord: `[Function]`
- ::isBeginningOfFile: `[Function]`

## MoveToNextWord
- ::wordRegex: `null`
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`
- ::isEndOfFile: `[Function]`

## MoveToNextWholeWord
- ::wordRegex: `/^\s*$|\S+/`

## MoveToEndOfWord
- ::wordRegex: `null`
- ::moveCursor: `[Function]`

## MoveToEndOfWholeWord
- ::wordRegex: `/\S+/`

## MoveToNextParagraph
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

## MoveToPreviousParagraph
- ::moveCursor: `[Function]`

## MoveToLine
- ::operatesLinewise: `true`
- ::getDestinationRow: `[Function]`

## MoveToAbsoluteLine
- ::moveCursor: `[Function]`

## MoveToRelativeLine
- ::operatesLinewise: `true`
- ::moveCursor: `[Function]`

## MoveToScreenLine
- ::moveCursor: `[Function]`

## MoveToBeginningOfLine
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

## MoveToFirstCharacterOfLine
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

## MoveToFirstCharacterOfLineAndDown
- ::operatesLinewise: `true`
- ::operatesInclusively: `true`
- ::moveCursor: `[Function]`

## MoveToLastCharacterOfLine
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

## MoveToLastNonblankCharacterOfLineAndDown
- ::operatesInclusively: `true`
- ::skipTrailingWhitespace: `[Function]`
- ::moveCursor: `[Function]`

## MoveToFirstCharacterOfLineUp
- ::operatesLinewise: `true`
- ::operatesInclusively: `true`
- ::moveCursor: `[Function]`

## MoveToFirstCharacterOfLineDown
- ::operatesLinewise: `true`
- ::moveCursor: `[Function]`

## MoveToStartOfFile
- ::moveCursor: `[Function]`

## MoveToTopOfScreen
- ::getDestinationRow: `[Function]`

## MoveToBottomOfScreen
- ::getDestinationRow: `[Function]`

## MoveToMiddleOfScreen
- ::getDestinationRow: `[Function]`

## ScrollKeepingCursor
- ::previousFirstScreenRow: `0`
- ::currentFirstScreenRow: `0`
- ::select: `[Function]`
- ::execute: `[Function]`
- ::moveCursor: `[Function]`
- ::getDestinationRow: `[Function]`
- ::scrollScreen: `[Function]`

## ScrollHalfUpKeepCursor
- ::scrollDestination: `[Function]`

## ScrollFullUpKeepCursor
- ::scrollDestination: `[Function]`

## ScrollHalfDownKeepCursor
- ::scrollDestination: `[Function]`

## ScrollFullDownKeepCursor
- ::scrollDestination: `[Function]`

## Find
- ::match: `[Function]`
- ::reverse: `[Function]`
- ::moveCursor: `[Function]`

## Till
- ::match: `[Function]`
- ::moveSelectionInclusively: `[Function]`

## MoveToMark
- ::operatesInclusively: `false`
- ::isLinewise: `[Function]`
- ::moveCursor: `[Function]`

## SearchBase
- ::operatesInclusively: `false`
- ::reversed: `[Function]`
- ::moveCursor: `[Function]`
- ::scan: `[Function]`
- ::getSearchTerm: `[Function]`
- ::updateCurrentSearch: `[Function]`
- ::replicateCurrentSearch: `[Function]`

## Search

## SearchCurrentWord
- @keywordRegex: `null`
- ::getCurrentWord: `[Function]`
- ::cursorIsOnEOF: `[Function]`
- ::getCurrentWordMatch: `[Function]`
- ::isComplete: `[Function]`
- ::execute: `[Function]`

## BracketMatchingMotion
- ::operatesInclusively: `true`
- ::isComplete: `[Function]`
- ::searchForMatch: `[Function]`
- ::characterAt: `[Function]`
- ::getSearchData: `[Function]`
- ::moveCursor: `[Function]`

## RepeatSearch
- ::isComplete: `[Function]`
- ::reversed: `[Function]`

## Insert
- ::standalone: `true`
- ::isComplete: `[Function]`
- ::confirmChanges: `[Function]`
- ::execute: `[Function]`
- ::inputOperator: `[Function]`

## ReplaceMode
- ::execute: `[Function]`
- ::countChars: `[Function]`

## InsertAfter
- ::execute: `[Function]`

## InsertAfterEndOfLine
- ::execute: `[Function]`

## InsertAtBeginningOfLine
- ::execute: `[Function]`

## InsertAboveWithNewline
- ::execute: `[Function]`

## InsertBelowWithNewline
- ::execute: `[Function]`

## Change
- ::standalone: `false`
- ::register: `null`
- ::execute: `[Function]`

## SubstituteLine
- ::standalone: `true`
- ::register: `null`

## Prefix
- ::complete: `null`
- ::composedObject: `null`
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`
- ::compose: `[Function]`
- ::execute: `[Function]`
- ::select: `[Function]`
- ::isLinewise: `[Function]`

## Register
- ::name: `null`
- ::compose: `[Function]`

## TextObject
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`

## CurrentSelection
- ::select: `[Function]`

## SelectInsideWord
- ::select: `[Function]`

## SelectAWord
- ::select: `[Function]`

## SelectInsideWholeWord
- ::select: `[Function]`

## SelectAWholeWord
- ::select: `[Function]`

## SelectInsideQuotes
- ::findOpeningQuote: `[Function]`
- ::isStartQuote: `[Function]`
- ::lookForwardOnLine: `[Function]`
- ::findClosingQuote: `[Function]`
- ::select: `[Function]`

## SelectInsideBrackets
- ::findOpeningBracket: `[Function]`
- ::findClosingBracket: `[Function]`
- ::select: `[Function]`

## SelectInsideParagraph
- ::select: `[Function]`

## SelectAParagraph
- ::select: `[Function]`

## Scroll
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`

## ScrollDown
- ::execute: `[Function]`
- ::keepCursorOnScreen: `[Function]`
- ::scrollUp: `[Function]`

## ScrollUp
- ::execute: `[Function]`
- ::keepCursorOnScreen: `[Function]`
- ::scrollDown: `[Function]`

## ScrollCursor

## ScrollCursorToTop
- ::execute: `[Function]`
- ::scrollUp: `[Function]`
- ::moveToFirstNonBlank: `[Function]`

## ScrollCursorToMiddle
- ::execute: `[Function]`
- ::scrollMiddle: `[Function]`
- ::moveToFirstNonBlank: `[Function]`

## ScrollCursorToBottom
- ::execute: `[Function]`
- ::scrollDown: `[Function]`
- ::moveToFirstNonBlank: `[Function]`

## ScrollHorizontal
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`
- ::putCursorOnScreen: `[Function]`

## ScrollCursorToLeft
- ::execute: `[Function]`

## ScrollCursorToRight
- ::execute: `[Function]`
