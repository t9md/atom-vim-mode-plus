## OperatorError

## Operator
- ::vimState
- ::target
- ::complete
- ::isComplete
- ::isRecordable
- ::compose
- ::canComposeWith
- ::setTextRegister

## OperatorWithInput
- ::canComposeWith
- ::compose

## Select
- ::execute

## Delete
- ::register
- ::execute

## ToggleCase
- ::execute

## UpperCase
- ::execute

## LowerCase
- ::execute

## Yank
- ::register
- ::execute

## Join
- ::execute

## Repeat
- ::isRecordable
- ::execute

## Mark
- ::execute

## Increase
- ::step
- ::execute
- ::increaseNumber

## Decrease
- ::step

## AdjustIndentation
- ::execute

## Indent
- ::indent

## Outdent
- ::indent

## Autoindent
- ::indent

## Put
- ::register
- ::execute
- ::onLastRow
- ::onLastColumn

## Replace
- ::execute

## MotionError

## Motion
- ::operatesInclusively
- ::operatesLinewise
- ::select
- ::execute
- ::moveSelectionLinewise
- ::moveSelectionInclusively
- ::moveSelection
- ::isComplete
- ::isRecordable
- ::isLinewise
- ::isInclusive

## MotionWithInput
- ::isComplete
- ::canComposeWith
- ::compose

## MoveLeft
- ::operatesInclusively
- ::moveCursor

## MoveRight
- ::operatesInclusively
- ::moveCursor

## MoveUp
- ::operatesLinewise
- ::moveCursor

## MoveDown
- ::operatesLinewise
- ::moveCursor

## MoveToPreviousWord
- ::operatesInclusively
- ::moveCursor

## MoveToPreviousWholeWord
- ::operatesInclusively
- ::moveCursor
- ::isWholeWord
- ::isBeginningOfFile

## MoveToNextWord
- ::wordRegex
- ::operatesInclusively
- ::moveCursor
- ::isEndOfFile

## MoveToNextWholeWord
- ::wordRegex

## MoveToEndOfWord
- ::wordRegex
- ::moveCursor

## MoveToEndOfWholeWord
- ::wordRegex

## MoveToNextParagraph
- ::operatesInclusively
- ::moveCursor

## MoveToPreviousParagraph
- ::moveCursor

## MoveToLine
- ::operatesLinewise
- ::getDestinationRow

## MoveToAbsoluteLine
- ::moveCursor

## MoveToRelativeLine
- ::operatesLinewise
- ::moveCursor

## MoveToScreenLine
- ::moveCursor

## MoveToBeginningOfLine
- ::operatesInclusively
- ::moveCursor

## MoveToFirstCharacterOfLine
- ::operatesInclusively
- ::moveCursor

## MoveToFirstCharacterOfLineAndDown
- ::operatesLinewise
- ::operatesInclusively
- ::moveCursor

## MoveToLastCharacterOfLine
- ::operatesInclusively
- ::moveCursor

## MoveToLastNonblankCharacterOfLineAndDown
- ::operatesInclusively
- ::skipTrailingWhitespace
- ::moveCursor

## MoveToFirstCharacterOfLineUp
- ::operatesLinewise
- ::operatesInclusively
- ::moveCursor

## MoveToFirstCharacterOfLineDown
- ::operatesLinewise
- ::moveCursor

## MoveToStartOfFile
- ::moveCursor

## MoveToTopOfScreen
- ::getDestinationRow

## MoveToBottomOfScreen
- ::getDestinationRow

## MoveToMiddleOfScreen
- ::getDestinationRow

## ScrollKeepingCursor
- ::previousFirstScreenRow
- ::currentFirstScreenRow
- ::select
- ::execute
- ::moveCursor
- ::getDestinationRow
- ::scrollScreen

## ScrollHalfUpKeepCursor
- ::scrollDestination

## ScrollFullUpKeepCursor
- ::scrollDestination

## ScrollHalfDownKeepCursor
- ::scrollDestination

## ScrollFullDownKeepCursor
- ::scrollDestination

## Find
- ::match
- ::reverse
- ::moveCursor

## Till
- ::match
- ::moveSelectionInclusively

## MoveToMark
- ::operatesInclusively
- ::isLinewise
- ::moveCursor

## SearchBase
- ::operatesInclusively
- ::reversed
- ::moveCursor
- ::scan
- ::getSearchTerm
- ::updateCurrentSearch
- ::replicateCurrentSearch

## Search

## SearchCurrentWord
- @keywordRegex
- ::getCurrentWord
- ::cursorIsOnEOF
- ::getCurrentWordMatch
- ::isComplete
- ::execute

## BracketMatchingMotion
- ::operatesInclusively
- ::isComplete
- ::searchForMatch
- ::characterAt
- ::getSearchData
- ::moveCursor

## RepeatSearch
- ::isComplete
- ::reversed

## Insert
- ::standalone
- ::isComplete
- ::confirmChanges
- ::execute
- ::inputOperator

## ReplaceMode
- ::execute
- ::countChars

## InsertAfter
- ::execute

## InsertAfterEndOfLine
- ::execute

## InsertAtBeginningOfLine
- ::execute

## InsertAboveWithNewline
- ::execute

## InsertBelowWithNewline
- ::execute

## Change
- ::standalone
- ::register
- ::execute

## SubstituteLine
- ::standalone
- ::register

## Prefix
- ::complete
- ::composedObject
- ::isComplete
- ::isRecordable
- ::compose
- ::execute
- ::select
- ::isLinewise

## Register
- ::name
- ::compose

## TextObject
- ::isComplete
- ::isRecordable

## CurrentSelection
- ::select

## SelectInsideWord
- ::select

## SelectAWord
- ::select

## SelectInsideWholeWord
- ::select

## SelectAWholeWord
- ::select

## SelectInsideQuotes
- ::findOpeningQuote
- ::isStartQuote
- ::lookForwardOnLine
- ::findClosingQuote
- ::select

## SelectInsideBrackets
- ::findOpeningBracket
- ::findClosingBracket
- ::select

## SelectInsideParagraph
- ::select

## SelectAParagraph
- ::select

## Scroll
- ::isComplete
- ::isRecordable

## ScrollDown
- ::execute
- ::keepCursorOnScreen
- ::scrollUp

## ScrollUp
- ::execute
- ::keepCursorOnScreen
- ::scrollDown

## ScrollCursor

## ScrollCursorToTop
- ::execute
- ::scrollUp
- ::moveToFirstNonBlank

## ScrollCursorToMiddle
- ::execute
- ::scrollMiddle
- ::moveToFirstNonBlank

## ScrollCursorToBottom
- ::execute
- ::scrollDown
- ::moveToFirstNonBlank

## ScrollHorizontal
- ::isComplete
- ::isRecordable
- ::putCursorOnScreen

## ScrollCursorToLeft
- ::execute

## ScrollCursorToRight
- ::execute
