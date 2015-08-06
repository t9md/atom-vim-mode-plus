# TOM report
- [OperatorError](#OperatorError)
- [Operator](#Operator)
- [OperatorWithInput < Operator](#OperatorWithInput--Operator)
- [Select < Operator](#Select--Operator)
- [Delete < Operator](#Delete--Operator)
- [ToggleCase < Operator](#ToggleCase--Operator)
- [UpperCase < Operator](#UpperCase--Operator)
- [LowerCase < Operator](#LowerCase--Operator)
- [Yank < Operator](#Yank--Operator)
- [Join < Operator](#Join--Operator)
- [Repeat < Operator](#Repeat--Operator)
- [Mark < OperatorWithInput < Operator](#Mark--OperatorWithInput--Operator)
- [Increase < Operator](#Increase--Operator)
- [Decrease < Increase < Operator](#Decrease--Increase--Operator)
- [AdjustIndentation < Operator](#AdjustIndentation--Operator)
- [Indent < AdjustIndentation < Operator](#Indent--AdjustIndentation--Operator)
- [Outdent < AdjustIndentation < Operator](#Outdent--AdjustIndentation--Operator)
- [Autoindent < AdjustIndentation < Operator](#Autoindent--AdjustIndentation--Operator)
- [Put < Operator](#Put--Operator)
- [Replace < OperatorWithInput < Operator](#Replace--OperatorWithInput--Operator)
- [MotionError](#MotionError)
- [Motion](#Motion)
- [MotionWithInput < Motion](#MotionWithInput--Motion)
- [MoveLeft < Motion](#MoveLeft--Motion)
- [MoveRight < Motion](#MoveRight--Motion)
- [MoveUp < Motion](#MoveUp--Motion)
- [MoveDown < Motion](#MoveDown--Motion)
- [MoveToPreviousWord < Motion](#MoveToPreviousWord--Motion)
- [MoveToPreviousWholeWord < Motion](#MoveToPreviousWholeWord--Motion)
- [MoveToNextWord < Motion](#MoveToNextWord--Motion)
- [MoveToNextWholeWord < MoveToNextWord < Motion](#MoveToNextWholeWord--MoveToNextWord--Motion)
- [MoveToEndOfWord < Motion](#MoveToEndOfWord--Motion)
- [MoveToEndOfWholeWord < MoveToEndOfWord < Motion](#MoveToEndOfWholeWord--MoveToEndOfWord--Motion)
- [MoveToNextParagraph < Motion](#MoveToNextParagraph--Motion)
- [MoveToPreviousParagraph < Motion](#MoveToPreviousParagraph--Motion)
- [MoveToLine < Motion](#MoveToLine--Motion)
- [MoveToAbsoluteLine < MoveToLine < Motion](#MoveToAbsoluteLine--MoveToLine--Motion)
- [MoveToRelativeLine < MoveToLine < Motion](#MoveToRelativeLine--MoveToLine--Motion)
- [MoveToScreenLine < MoveToLine < Motion](#MoveToScreenLine--MoveToLine--Motion)
- [MoveToBeginningOfLine < Motion](#MoveToBeginningOfLine--Motion)
- [MoveToFirstCharacterOfLine < Motion](#MoveToFirstCharacterOfLine--Motion)
- [MoveToFirstCharacterOfLineAndDown < Motion](#MoveToFirstCharacterOfLineAndDown--Motion)
- [MoveToLastCharacterOfLine < Motion](#MoveToLastCharacterOfLine--Motion)
- [MoveToLastNonblankCharacterOfLineAndDown < Motion](#MoveToLastNonblankCharacterOfLineAndDown--Motion)
- [MoveToFirstCharacterOfLineUp < Motion](#MoveToFirstCharacterOfLineUp--Motion)
- [MoveToFirstCharacterOfLineDown < Motion](#MoveToFirstCharacterOfLineDown--Motion)
- [MoveToStartOfFile < MoveToLine < Motion](#MoveToStartOfFile--MoveToLine--Motion)
- [MoveToTopOfScreen < MoveToScreenLine < MoveToLine < Motion](#MoveToTopOfScreen--MoveToScreenLine--MoveToLine--Motion)
- [MoveToBottomOfScreen < MoveToScreenLine < MoveToLine < Motion](#MoveToBottomOfScreen--MoveToScreenLine--MoveToLine--Motion)
- [MoveToMiddleOfScreen < MoveToScreenLine < MoveToLine < Motion](#MoveToMiddleOfScreen--MoveToScreenLine--MoveToLine--Motion)
- [ScrollKeepingCursor < MoveToLine < Motion](#ScrollKeepingCursor--MoveToLine--Motion)
- [ScrollHalfUpKeepCursor < ScrollKeepingCursor < MoveToLine < Motion](#ScrollHalfUpKeepCursor--ScrollKeepingCursor--MoveToLine--Motion)
- [ScrollFullUpKeepCursor < ScrollKeepingCursor < MoveToLine < Motion](#ScrollFullUpKeepCursor--ScrollKeepingCursor--MoveToLine--Motion)
- [ScrollHalfDownKeepCursor < ScrollKeepingCursor < MoveToLine < Motion](#ScrollHalfDownKeepCursor--ScrollKeepingCursor--MoveToLine--Motion)
- [ScrollFullDownKeepCursor < ScrollKeepingCursor < MoveToLine < Motion](#ScrollFullDownKeepCursor--ScrollKeepingCursor--MoveToLine--Motion)
- [Find < MotionWithInput < Motion](#Find--MotionWithInput--Motion)
- [Till < Find < MotionWithInput < Motion](#Till--Find--MotionWithInput--Motion)
- [MoveToMark < MotionWithInput < Motion](#MoveToMark--MotionWithInput--Motion)
- [SearchBase < MotionWithInput < Motion](#SearchBase--MotionWithInput--Motion)
- [Search < SearchBase < MotionWithInput < Motion](#Search--SearchBase--MotionWithInput--Motion)
- [SearchCurrentWord < SearchBase < MotionWithInput < Motion](#SearchCurrentWord--SearchBase--MotionWithInput--Motion)
- [BracketMatchingMotion < SearchBase < MotionWithInput < Motion](#BracketMatchingMotion--SearchBase--MotionWithInput--Motion)
- [RepeatSearch < SearchBase < MotionWithInput < Motion](#RepeatSearch--SearchBase--MotionWithInput--Motion)
- [Insert < Operator](#Insert--Operator)
- [ReplaceMode < Insert < Operator](#ReplaceMode--Insert--Operator)
- [InsertAfter < Insert < Operator](#InsertAfter--Insert--Operator)
- [InsertAfterEndOfLine < Insert < Operator](#InsertAfterEndOfLine--Insert--Operator)
- [InsertAtBeginningOfLine < Insert < Operator](#InsertAtBeginningOfLine--Insert--Operator)
- [InsertAboveWithNewline < Insert < Operator](#InsertAboveWithNewline--Insert--Operator)
- [InsertBelowWithNewline < Insert < Operator](#InsertBelowWithNewline--Insert--Operator)
- [Change < Insert < Operator](#Change--Insert--Operator)
- [SubstituteLine < Change < Insert < Operator](#SubstituteLine--Change--Insert--Operator)
- [Prefix](#Prefix)
- [Register < Prefix](#Register--Prefix)
- [TextObject](#TextObject)
- [CurrentSelection < TextObject](#CurrentSelection--TextObject)
- [SelectInsideWord < TextObject](#SelectInsideWord--TextObject)
- [SelectAWord < TextObject](#SelectAWord--TextObject)
- [SelectInsideWholeWord < TextObject](#SelectInsideWholeWord--TextObject)
- [SelectAWholeWord < TextObject](#SelectAWholeWord--TextObject)
- [SelectInsideQuotes < TextObject](#SelectInsideQuotes--TextObject)
- [SelectInsideBrackets < TextObject](#SelectInsideBrackets--TextObject)
- [SelectInsideParagraph < TextObject](#SelectInsideParagraph--TextObject)
- [SelectAParagraph < TextObject](#SelectAParagraph--TextObject)
- [Scroll](#Scroll)
- [ScrollDown < Scroll](#ScrollDown--Scroll)
- [ScrollUp < Scroll](#ScrollUp--Scroll)
- [ScrollCursor < Scroll](#ScrollCursor--Scroll)
- [ScrollCursorToTop < ScrollCursor < Scroll](#ScrollCursorToTop--ScrollCursor--Scroll)
- [ScrollCursorToMiddle < ScrollCursor < Scroll](#ScrollCursorToMiddle--ScrollCursor--Scroll)
- [ScrollCursorToBottom < ScrollCursor < Scroll](#ScrollCursorToBottom--ScrollCursor--Scroll)
- [ScrollHorizontal](#ScrollHorizontal)
- [ScrollCursorToLeft < ScrollHorizontal](#ScrollCursorToLeft--ScrollHorizontal)
- [ScrollCursorToRight < ScrollHorizontal](#ScrollCursorToRight--ScrollHorizontal)
### OperatorError

### Operator
- ::vimState
- ::target
- ::complete
- ::isComplete
- ::isRecordable
- ::compose
- ::canComposeWith
- ::setTextRegister

### OperatorWithInput < Operator
- ::canComposeWith
- ::compose

### Select < Operator
- ::execute

### Delete < Operator
- ::register
- ::execute

### ToggleCase < Operator
- ::execute

### UpperCase < Operator
- ::execute

### LowerCase < Operator
- ::execute

### Yank < Operator
- ::register
- ::execute

### Join < Operator
- ::execute

### Repeat < Operator
- ::isRecordable
- ::execute

### Mark < OperatorWithInput < Operator
- ::execute

### Increase < Operator
- ::step
- ::execute
- ::increaseNumber

### Decrease < Increase < Operator
- ::step

### AdjustIndentation < Operator
- ::execute

### Indent < AdjustIndentation < Operator
- ::indent

### Outdent < AdjustIndentation < Operator
- ::indent

### Autoindent < AdjustIndentation < Operator
- ::indent

### Put < Operator
- ::register
- ::execute
- ::onLastRow
- ::onLastColumn

### Replace < OperatorWithInput < Operator
- ::execute

### MotionError

### Motion
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

### MotionWithInput < Motion
- ::isComplete
- ::canComposeWith
- ::compose

### MoveLeft < Motion
- ::operatesInclusively
- ::moveCursor

### MoveRight < Motion
- ::operatesInclusively
- ::moveCursor

### MoveUp < Motion
- ::operatesLinewise
- ::moveCursor

### MoveDown < Motion
- ::operatesLinewise
- ::moveCursor

### MoveToPreviousWord < Motion
- ::operatesInclusively
- ::moveCursor

### MoveToPreviousWholeWord < Motion
- ::operatesInclusively
- ::moveCursor
- ::isWholeWord
- ::isBeginningOfFile

### MoveToNextWord < Motion
- ::wordRegex
- ::operatesInclusively
- ::moveCursor
- ::isEndOfFile

### MoveToNextWholeWord < MoveToNextWord < Motion
- ::wordRegex

### MoveToEndOfWord < Motion
- ::wordRegex
- ::moveCursor

### MoveToEndOfWholeWord < MoveToEndOfWord < Motion
- ::wordRegex

### MoveToNextParagraph < Motion
- ::operatesInclusively
- ::moveCursor

### MoveToPreviousParagraph < Motion
- ::moveCursor

### MoveToLine < Motion
- ::operatesLinewise
- ::getDestinationRow

### MoveToAbsoluteLine < MoveToLine < Motion
- ::moveCursor

### MoveToRelativeLine < MoveToLine < Motion
- ::operatesLinewise
- ::moveCursor

### MoveToScreenLine < MoveToLine < Motion
- ::moveCursor

### MoveToBeginningOfLine < Motion
- ::operatesInclusively
- ::moveCursor

### MoveToFirstCharacterOfLine < Motion
- ::operatesInclusively
- ::moveCursor

### MoveToFirstCharacterOfLineAndDown < Motion
- ::operatesLinewise
- ::operatesInclusively
- ::moveCursor

### MoveToLastCharacterOfLine < Motion
- ::operatesInclusively
- ::moveCursor

### MoveToLastNonblankCharacterOfLineAndDown < Motion
- ::operatesInclusively
- ::skipTrailingWhitespace
- ::moveCursor

### MoveToFirstCharacterOfLineUp < Motion
- ::operatesLinewise
- ::operatesInclusively
- ::moveCursor

### MoveToFirstCharacterOfLineDown < Motion
- ::operatesLinewise
- ::moveCursor

### MoveToStartOfFile < MoveToLine < Motion
- ::moveCursor

### MoveToTopOfScreen < MoveToScreenLine < MoveToLine < Motion
- ::getDestinationRow

### MoveToBottomOfScreen < MoveToScreenLine < MoveToLine < Motion
- ::getDestinationRow

### MoveToMiddleOfScreen < MoveToScreenLine < MoveToLine < Motion
- ::getDestinationRow

### ScrollKeepingCursor < MoveToLine < Motion
- ::previousFirstScreenRow
- ::currentFirstScreenRow
- ::select
- ::execute
- ::moveCursor
- ::getDestinationRow
- ::scrollScreen

### ScrollHalfUpKeepCursor < ScrollKeepingCursor < MoveToLine < Motion
- ::scrollDestination

### ScrollFullUpKeepCursor < ScrollKeepingCursor < MoveToLine < Motion
- ::scrollDestination

### ScrollHalfDownKeepCursor < ScrollKeepingCursor < MoveToLine < Motion
- ::scrollDestination

### ScrollFullDownKeepCursor < ScrollKeepingCursor < MoveToLine < Motion
- ::scrollDestination

### Find < MotionWithInput < Motion
- ::match
- ::reverse
- ::moveCursor

### Till < Find < MotionWithInput < Motion
- ::match
- ::moveSelectionInclusively

### MoveToMark < MotionWithInput < Motion
- ::operatesInclusively
- ::isLinewise
- ::moveCursor

### SearchBase < MotionWithInput < Motion
- ::operatesInclusively
- ::reversed
- ::moveCursor
- ::scan
- ::getSearchTerm
- ::updateCurrentSearch
- ::replicateCurrentSearch

### Search < SearchBase < MotionWithInput < Motion

### SearchCurrentWord < SearchBase < MotionWithInput < Motion
- @keywordRegex
- ::getCurrentWord
- ::cursorIsOnEOF
- ::getCurrentWordMatch
- ::isComplete
- ::execute

### BracketMatchingMotion < SearchBase < MotionWithInput < Motion
- ::operatesInclusively
- ::isComplete
- ::searchForMatch
- ::characterAt
- ::getSearchData
- ::moveCursor

### RepeatSearch < SearchBase < MotionWithInput < Motion
- ::isComplete
- ::reversed

### Insert < Operator
- ::standalone
- ::isComplete
- ::confirmChanges
- ::execute
- ::inputOperator

### ReplaceMode < Insert < Operator
- ::execute
- ::countChars

### InsertAfter < Insert < Operator
- ::execute

### InsertAfterEndOfLine < Insert < Operator
- ::execute

### InsertAtBeginningOfLine < Insert < Operator
- ::execute

### InsertAboveWithNewline < Insert < Operator
- ::execute

### InsertBelowWithNewline < Insert < Operator
- ::execute

### Change < Insert < Operator
- ::standalone
- ::register
- ::execute

### SubstituteLine < Change < Insert < Operator
- ::standalone
- ::register

### Prefix
- ::complete
- ::composedObject
- ::isComplete
- ::isRecordable
- ::compose
- ::execute
- ::select
- ::isLinewise

### Register < Prefix
- ::name
- ::compose

### TextObject
- ::isComplete
- ::isRecordable

### CurrentSelection < TextObject
- ::select

### SelectInsideWord < TextObject
- ::select

### SelectAWord < TextObject
- ::select

### SelectInsideWholeWord < TextObject
- ::select

### SelectAWholeWord < TextObject
- ::select

### SelectInsideQuotes < TextObject
- ::findOpeningQuote
- ::isStartQuote
- ::lookForwardOnLine
- ::findClosingQuote
- ::select

### SelectInsideBrackets < TextObject
- ::findOpeningBracket
- ::findClosingBracket
- ::select

### SelectInsideParagraph < TextObject
- ::select

### SelectAParagraph < TextObject
- ::select

### Scroll
- ::isComplete
- ::isRecordable

### ScrollDown < Scroll
- ::execute
- ::keepCursorOnScreen
- ::scrollUp

### ScrollUp < Scroll
- ::execute
- ::keepCursorOnScreen
- ::scrollDown

### ScrollCursor < Scroll

### ScrollCursorToTop < ScrollCursor < Scroll
- ::execute
- ::scrollUp
- ::moveToFirstNonBlank

### ScrollCursorToMiddle < ScrollCursor < Scroll
- ::execute
- ::scrollMiddle
- ::moveToFirstNonBlank

### ScrollCursorToBottom < ScrollCursor < Scroll
- ::execute
- ::scrollDown
- ::moveToFirstNonBlank

### ScrollHorizontal
- ::isComplete
- ::isRecordable
- ::putCursorOnScreen

### ScrollCursorToLeft < ScrollHorizontal
- ::execute

### ScrollCursorToRight < ScrollHorizontal
- ::execute
