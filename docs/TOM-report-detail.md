## OperatorError < Base

## Operator < Base
- ::vimState: `null`
- ::target: `null`
- ::complete: `null`
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`
- ::compose: `[Function]`
- ::canComposeWith: `[Function]`
- ::setTextRegister: `[Function]`

## OperatorWithInput < Operator
- ::canComposeWith: `[Function]`
- ::compose: `[Function]`

## Select < Operator
- ::execute: `[Function]`

## Delete < Operator
- ::register: `null`
- ::execute: `[Function]`

## ToggleCase < Operator
- ::execute: `[Function]`

## UpperCase < Operator
- ::execute: `[Function]`

## LowerCase < Operator
- ::execute: `[Function]`

## Yank < Operator
- ::register: `null`
- ::execute: `[Function]`

## Join < Operator
- ::execute: `[Function]`

## Repeat < Operator
- ::isRecordable: `[Function]`
- ::execute: `[Function]`

## Mark < OperatorWithInput
- ::execute: `[Function]`

## Increase < Operator
- ::step: `1`
- ::execute: `[Function]`
- ::increaseNumber: `[Function]`

## Decrease < Increase
- ::step: `-1`

## AdjustIndentation < Operator
- ::execute: `[Function]`

## Indent < AdjustIndentation
- ::indent: `[Function]`

## Outdent < AdjustIndentation
- ::indent: `[Function]`

## Autoindent < AdjustIndentation
- ::indent: `[Function]`

## Put < Operator
- ::register: `null`
- ::execute: `[Function]`
- ::onLastRow: `[Function]`
- ::onLastColumn: `[Function]`

## Replace < OperatorWithInput
- ::execute: `[Function]`

## MotionError < Base

## Motion < Base
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

## MotionWithInput < Motion
- ::isComplete: `[Function]`
- ::canComposeWith: `[Function]`
- ::compose: `[Function]`

## MoveLeft < Motion
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

## MoveRight < Motion
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

## MoveUp < Motion
- ::operatesLinewise: `true`
- ::moveCursor: `[Function]`

## MoveDown < Motion
- ::operatesLinewise: `true`
- ::moveCursor: `[Function]`

## MoveToPreviousWord < Motion
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

## MoveToPreviousWholeWord < Motion
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`
- ::isWholeWord: `[Function]`
- ::isBeginningOfFile: `[Function]`

## MoveToNextWord < Motion
- ::wordRegex: `null`
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`
- ::isEndOfFile: `[Function]`

## MoveToNextWholeWord < MoveToNextWord
- ::wordRegex: `/^\s*$|\S+/`

## MoveToEndOfWord < Motion
- ::wordRegex: `null`
- ::moveCursor: `[Function]`

## MoveToEndOfWholeWord < MoveToEndOfWord
- ::wordRegex: `/\S+/`

## MoveToNextParagraph < Motion
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

## MoveToPreviousParagraph < Motion
- ::moveCursor: `[Function]`

## MoveToLine < Motion
- ::operatesLinewise: `true`
- ::getDestinationRow: `[Function]`

## MoveToAbsoluteLine < MoveToLine
- ::moveCursor: `[Function]`

## MoveToRelativeLine < MoveToLine
- ::operatesLinewise: `true`
- ::moveCursor: `[Function]`

## MoveToScreenLine < MoveToLine
- ::moveCursor: `[Function]`

## MoveToBeginningOfLine < Motion
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

## MoveToFirstCharacterOfLine < Motion
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

## MoveToFirstCharacterOfLineAndDown < Motion
- ::operatesLinewise: `true`
- ::operatesInclusively: `true`
- ::moveCursor: `[Function]`

## MoveToLastCharacterOfLine < Motion
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

## MoveToLastNonblankCharacterOfLineAndDown < Motion
- ::operatesInclusively: `true`
- ::skipTrailingWhitespace: `[Function]`
- ::moveCursor: `[Function]`

## MoveToFirstCharacterOfLineUp < Motion
- ::operatesLinewise: `true`
- ::operatesInclusively: `true`
- ::moveCursor: `[Function]`

## MoveToFirstCharacterOfLineDown < Motion
- ::operatesLinewise: `true`
- ::moveCursor: `[Function]`

## MoveToStartOfFile < MoveToLine
- ::moveCursor: `[Function]`

## MoveToTopOfScreen < MoveToScreenLine
- ::getDestinationRow: `[Function]`

## MoveToBottomOfScreen < MoveToScreenLine
- ::getDestinationRow: `[Function]`

## MoveToMiddleOfScreen < MoveToScreenLine
- ::getDestinationRow: `[Function]`

## ScrollKeepingCursor < MoveToLine
- ::previousFirstScreenRow: `0`
- ::currentFirstScreenRow: `0`
- ::select: `[Function]`
- ::execute: `[Function]`
- ::moveCursor: `[Function]`
- ::getDestinationRow: `[Function]`
- ::scrollScreen: `[Function]`

## ScrollHalfUpKeepCursor < ScrollKeepingCursor
- ::scrollDestination: `[Function]`

## ScrollFullUpKeepCursor < ScrollKeepingCursor
- ::scrollDestination: `[Function]`

## ScrollHalfDownKeepCursor < ScrollKeepingCursor
- ::scrollDestination: `[Function]`

## ScrollFullDownKeepCursor < ScrollKeepingCursor
- ::scrollDestination: `[Function]`

## Find < MotionWithInput
- ::match: `[Function]`
- ::reverse: `[Function]`
- ::moveCursor: `[Function]`

## Till < Find
- ::match: `[Function]`
- ::moveSelectionInclusively: `[Function]`

## MoveToMark < MotionWithInput
- ::operatesInclusively: `false`
- ::isLinewise: `[Function]`
- ::moveCursor: `[Function]`

## SearchBase < MotionWithInput
- ::operatesInclusively: `false`
- ::reversed: `[Function]`
- ::moveCursor: `[Function]`
- ::scan: `[Function]`
- ::getSearchTerm: `[Function]`
- ::updateCurrentSearch: `[Function]`
- ::replicateCurrentSearch: `[Function]`

## Search < SearchBase

## SearchCurrentWord < SearchBase
- @keywordRegex: `null`
- ::getCurrentWord: `[Function]`
- ::cursorIsOnEOF: `[Function]`
- ::getCurrentWordMatch: `[Function]`
- ::isComplete: `[Function]`
- ::execute: `[Function]`

## BracketMatchingMotion < SearchBase
- ::operatesInclusively: `true`
- ::isComplete: `[Function]`
- ::searchForMatch: `[Function]`
- ::characterAt: `[Function]`
- ::getSearchData: `[Function]`
- ::moveCursor: `[Function]`

## RepeatSearch < SearchBase
- ::isComplete: `[Function]`
- ::reversed: `[Function]`

## Insert < Operator
- ::standalone: `true`
- ::isComplete: `[Function]`
- ::confirmChanges: `[Function]`
- ::execute: `[Function]`
- ::inputOperator: `[Function]`

## ReplaceMode < Insert
- ::execute: `[Function]`
- ::countChars: `[Function]`

## InsertAfter < Insert
- ::execute: `[Function]`

## InsertAfterEndOfLine < Insert
- ::execute: `[Function]`

## InsertAtBeginningOfLine < Insert
- ::execute: `[Function]`

## InsertAboveWithNewline < Insert
- ::execute: `[Function]`

## InsertBelowWithNewline < Insert
- ::execute: `[Function]`

## Change < Insert
- ::standalone: `false`
- ::register: `null`
- ::execute: `[Function]`

## SubstituteLine < Change
- ::standalone: `true`
- ::register: `null`

## Prefix < Base
- ::complete: `null`
- ::composedObject: `null`
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`
- ::compose: `[Function]`
- ::execute: `[Function]`
- ::select: `[Function]`
- ::isLinewise: `[Function]`

## Register < Prefix
- ::name: `null`
- ::compose: `[Function]`

## TextObject < Base
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`

## CurrentSelection < TextObject
- ::select: `[Function]`

## SelectInsideWord < TextObject
- ::select: `[Function]`

## SelectAWord < TextObject
- ::select: `[Function]`

## SelectInsideWholeWord < TextObject
- ::select: `[Function]`

## SelectAWholeWord < TextObject
- ::select: `[Function]`

## SelectInsideQuotes < TextObject
- ::findOpeningQuote: `[Function]`
- ::isStartQuote: `[Function]`
- ::lookForwardOnLine: `[Function]`
- ::findClosingQuote: `[Function]`
- ::select: `[Function]`

## SelectInsideBrackets < TextObject
- ::findOpeningBracket: `[Function]`
- ::findClosingBracket: `[Function]`
- ::select: `[Function]`

## SelectInsideParagraph < TextObject
- ::select: `[Function]`

## SelectAParagraph < TextObject
- ::select: `[Function]`

## Scroll < Base
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`

## ScrollDown < Scroll
- ::execute: `[Function]`
- ::keepCursorOnScreen: `[Function]`
- ::scrollUp: `[Function]`

## ScrollUp < Scroll
- ::execute: `[Function]`
- ::keepCursorOnScreen: `[Function]`
- ::scrollDown: `[Function]`

## ScrollCursor < Scroll

## ScrollCursorToTop < ScrollCursor
- ::execute: `[Function]`
- ::scrollUp: `[Function]`
- ::moveToFirstNonBlank: `[Function]`

## ScrollCursorToMiddle < ScrollCursor
- ::execute: `[Function]`
- ::scrollMiddle: `[Function]`
- ::moveToFirstNonBlank: `[Function]`

## ScrollCursorToBottom < ScrollCursor
- ::execute: `[Function]`
- ::scrollDown: `[Function]`
- ::moveToFirstNonBlank: `[Function]`

## ScrollHorizontal < Base
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`
- ::putCursorOnScreen: `[Function]`

## ScrollCursorToLeft < ScrollHorizontal
- ::execute: `[Function]`

## ScrollCursorToRight < ScrollHorizontal
- ::execute: `[Function]`
