## OperatorError < Base

## Operator < Base
- ::vimState
- ::target
- ::complete
- ::isComplete
- ::isRecordable
- ::compose
- ::canComposeWith
- ::setTextRegister

## OperatorWithInput < Operator
- ::canComposeWith
- ::compose

## Select < Operator
- ::execute

## Delete < Operator
- ::register
- ::execute

## ToggleCase < Operator
- ::execute

## UpperCase < Operator
- ::execute

## LowerCase < Operator
- ::execute

## Yank < Operator
- ::register
- ::execute

## Join < Operator
- ::execute

## Repeat < Operator
- ::isRecordable
- ::execute

## Mark < OperatorWithInput
- ::execute

## Increase < Operator
- ::step
- ::execute
- ::increaseNumber

## Decrease < Increase
- ::step

## AdjustIndentation < Operator
- ::execute

## Indent < AdjustIndentation
- ::indent

## Outdent < AdjustIndentation
- ::indent

## Autoindent < AdjustIndentation
- ::indent

## Put < Operator
- ::register
- ::execute
- ::onLastRow
- ::onLastColumn

## Replace < OperatorWithInput
- ::execute

## MotionError < Base

## Motion < Base
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

## MotionWithInput < Motion
- ::isComplete
- ::canComposeWith
- ::compose

## MoveLeft < Motion
- ::operatesInclusively
- ::moveCursor

## MoveRight < Motion
- ::operatesInclusively
- ::moveCursor

## MoveUp < Motion
- ::operatesLinewise
- ::moveCursor

## MoveDown < Motion
- ::operatesLinewise
- ::moveCursor

## MoveToPreviousWord < Motion
- ::operatesInclusively
- ::moveCursor

## MoveToPreviousWholeWord < Motion
- ::operatesInclusively
- ::moveCursor
- ::isWholeWord
- ::isBeginningOfFile

## MoveToNextWord < Motion
- ::wordRegex
- ::operatesInclusively
- ::moveCursor
- ::isEndOfFile

## MoveToNextWholeWord < MoveToNextWord
- ::wordRegex

## MoveToEndOfWord < Motion
- ::wordRegex
- ::moveCursor

## MoveToEndOfWholeWord < MoveToEndOfWord
- ::wordRegex

## MoveToNextParagraph < Motion
- ::operatesInclusively
- ::moveCursor

## MoveToPreviousParagraph < Motion
- ::moveCursor

## MoveToLine < Motion
- ::operatesLinewise
- ::getDestinationRow

## MoveToAbsoluteLine < MoveToLine
- ::moveCursor

## MoveToRelativeLine < MoveToLine
- ::operatesLinewise
- ::moveCursor

## MoveToScreenLine < MoveToLine
- ::moveCursor

## MoveToBeginningOfLine < Motion
- ::operatesInclusively
- ::moveCursor

## MoveToFirstCharacterOfLine < Motion
- ::operatesInclusively
- ::moveCursor

## MoveToFirstCharacterOfLineAndDown < Motion
- ::operatesLinewise
- ::operatesInclusively
- ::moveCursor

## MoveToLastCharacterOfLine < Motion
- ::operatesInclusively
- ::moveCursor

## MoveToLastNonblankCharacterOfLineAndDown < Motion
- ::operatesInclusively
- ::skipTrailingWhitespace
- ::moveCursor

## MoveToFirstCharacterOfLineUp < Motion
- ::operatesLinewise
- ::operatesInclusively
- ::moveCursor

## MoveToFirstCharacterOfLineDown < Motion
- ::operatesLinewise
- ::moveCursor

## MoveToStartOfFile < MoveToLine
- ::moveCursor

## MoveToTopOfScreen < MoveToScreenLine
- ::getDestinationRow

## MoveToBottomOfScreen < MoveToScreenLine
- ::getDestinationRow

## MoveToMiddleOfScreen < MoveToScreenLine
- ::getDestinationRow

## ScrollKeepingCursor < MoveToLine
- ::previousFirstScreenRow
- ::currentFirstScreenRow
- ::select
- ::execute
- ::moveCursor
- ::getDestinationRow
- ::scrollScreen

## ScrollHalfUpKeepCursor < ScrollKeepingCursor
- ::scrollDestination

## ScrollFullUpKeepCursor < ScrollKeepingCursor
- ::scrollDestination

## ScrollHalfDownKeepCursor < ScrollKeepingCursor
- ::scrollDestination

## ScrollFullDownKeepCursor < ScrollKeepingCursor
- ::scrollDestination

## Find < MotionWithInput
- ::match
- ::reverse
- ::moveCursor

## Till < Find
- ::match
- ::moveSelectionInclusively

## MoveToMark < MotionWithInput
- ::operatesInclusively
- ::isLinewise
- ::moveCursor

## SearchBase < MotionWithInput
- ::operatesInclusively
- ::reversed
- ::moveCursor
- ::scan
- ::getSearchTerm
- ::updateCurrentSearch
- ::replicateCurrentSearch

## Search < SearchBase

## SearchCurrentWord < SearchBase
- @keywordRegex
- ::getCurrentWord
- ::cursorIsOnEOF
- ::getCurrentWordMatch
- ::isComplete
- ::execute

## BracketMatchingMotion < SearchBase
- ::operatesInclusively
- ::isComplete
- ::searchForMatch
- ::characterAt
- ::getSearchData
- ::moveCursor

## RepeatSearch < SearchBase
- ::isComplete
- ::reversed

## Insert < Operator
- ::standalone
- ::isComplete
- ::confirmChanges
- ::execute
- ::inputOperator

## ReplaceMode < Insert
- ::execute
- ::countChars

## InsertAfter < Insert
- ::execute

## InsertAfterEndOfLine < Insert
- ::execute

## InsertAtBeginningOfLine < Insert
- ::execute

## InsertAboveWithNewline < Insert
- ::execute

## InsertBelowWithNewline < Insert
- ::execute

## Change < Insert
- ::standalone
- ::register
- ::execute

## SubstituteLine < Change
- ::standalone
- ::register

## Prefix < Base
- ::complete
- ::composedObject
- ::isComplete
- ::isRecordable
- ::compose
- ::execute
- ::select
- ::isLinewise

## Register < Prefix
- ::name
- ::compose

## TextObject < Base
- ::isComplete
- ::isRecordable

## CurrentSelection < TextObject
- ::select

## SelectInsideWord < TextObject
- ::select

## SelectAWord < TextObject
- ::select

## SelectInsideWholeWord < TextObject
- ::select

## SelectAWholeWord < TextObject
- ::select

## SelectInsideQuotes < TextObject
- ::findOpeningQuote
- ::isStartQuote
- ::lookForwardOnLine
- ::findClosingQuote
- ::select

## SelectInsideBrackets < TextObject
- ::findOpeningBracket
- ::findClosingBracket
- ::select

## SelectInsideParagraph < TextObject
- ::select

## SelectAParagraph < TextObject
- ::select

## Scroll < Base
- ::isComplete
- ::isRecordable

## ScrollDown < Scroll
- ::execute
- ::keepCursorOnScreen
- ::scrollUp

## ScrollUp < Scroll
- ::execute
- ::keepCursorOnScreen
- ::scrollDown

## ScrollCursor < Scroll

## ScrollCursorToTop < ScrollCursor
- ::execute
- ::scrollUp
- ::moveToFirstNonBlank

## ScrollCursorToMiddle < ScrollCursor
- ::execute
- ::scrollMiddle
- ::moveToFirstNonBlank

## ScrollCursorToBottom < ScrollCursor
- ::execute
- ::scrollDown
- ::moveToFirstNonBlank

## ScrollHorizontal < Base
- ::isComplete
- ::isRecordable
- ::putCursorOnScreen

## ScrollCursorToLeft < ScrollHorizontal
- ::execute

## ScrollCursorToRight < ScrollHorizontal
- ::execute
