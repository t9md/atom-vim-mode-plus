# TOM report
All TOMs inherits Base class
(Base class omitted from ancesstors list for screen spaces).  
- [OperatorError](#operatorerror)
- [Operator](#operator)
- [OperatorWithInput < Operator](#operatorwithinput--operator)
- [Select < Operator](#select--operator)
- [Delete < Operator](#delete--operator)
- [ToggleCase < Operator](#togglecase--operator)
- [UpperCase < Operator](#uppercase--operator)
- [LowerCase < Operator](#lowercase--operator)
- [Yank < Operator](#yank--operator)
- [Join < Operator](#join--operator)
- [Repeat < Operator](#repeat--operator)
- [Mark < OperatorWithInput < Operator](#mark--operatorwithinput--operator)
- [Increase < Operator](#increase--operator)
- [Decrease < Increase < Operator](#decrease--increase--operator)
- [AdjustIndentation < Operator](#adjustindentation--operator)
- [Indent < AdjustIndentation < Operator](#indent--adjustindentation--operator)
- [Outdent < AdjustIndentation < Operator](#outdent--adjustindentation--operator)
- [Autoindent < AdjustIndentation < Operator](#autoindent--adjustindentation--operator)
- [Put < Operator](#put--operator)
- [Replace < OperatorWithInput < Operator](#replace--operatorwithinput--operator)
- [MotionError](#motionerror)
- [Motion](#motion)
- [MotionWithInput < Motion](#motionwithinput--motion)
- [MoveLeft < Motion](#moveleft--motion)
- [MoveRight < Motion](#moveright--motion)
- [MoveUp < Motion](#moveup--motion)
- [MoveDown < Motion](#movedown--motion)
- [MoveToPreviousWord < Motion](#movetopreviousword--motion)
- [MoveToPreviousWholeWord < Motion](#movetopreviouswholeword--motion)
- [MoveToNextWord < Motion](#movetonextword--motion)
- [MoveToNextWholeWord < MoveToNextWord < Motion](#movetonextwholeword--movetonextword--motion)
- [MoveToEndOfWord < Motion](#movetoendofword--motion)
- [MoveToEndOfWholeWord < MoveToEndOfWord < Motion](#movetoendofwholeword--movetoendofword--motion)
- [MoveToNextParagraph < Motion](#movetonextparagraph--motion)
- [MoveToPreviousParagraph < Motion](#movetopreviousparagraph--motion)
- [MoveToLine < Motion](#movetoline--motion)
- [MoveToAbsoluteLine < MoveToLine < Motion](#movetoabsoluteline--movetoline--motion)
- [MoveToRelativeLine < MoveToLine < Motion](#movetorelativeline--movetoline--motion)
- [MoveToScreenLine < MoveToLine < Motion](#movetoscreenline--movetoline--motion)
- [MoveToBeginningOfLine < Motion](#movetobeginningofline--motion)
- [MoveToFirstCharacterOfLine < Motion](#movetofirstcharacterofline--motion)
- [MoveToFirstCharacterOfLineAndDown < Motion](#movetofirstcharacteroflineanddown--motion)
- [MoveToLastCharacterOfLine < Motion](#movetolastcharacterofline--motion)
- [MoveToLastNonblankCharacterOfLineAndDown < Motion](#movetolastnonblankcharacteroflineanddown--motion)
- [MoveToFirstCharacterOfLineUp < Motion](#movetofirstcharacteroflineup--motion)
- [MoveToFirstCharacterOfLineDown < Motion](#movetofirstcharacteroflinedown--motion)
- [MoveToStartOfFile < MoveToLine < Motion](#movetostartoffile--movetoline--motion)
- [MoveToTopOfScreen < MoveToScreenLine < MoveToLine < Motion](#movetotopofscreen--movetoscreenline--movetoline--motion)
- [MoveToBottomOfScreen < MoveToScreenLine < MoveToLine < Motion](#movetobottomofscreen--movetoscreenline--movetoline--motion)
- [MoveToMiddleOfScreen < MoveToScreenLine < MoveToLine < Motion](#movetomiddleofscreen--movetoscreenline--movetoline--motion)
- [ScrollKeepingCursor < MoveToLine < Motion](#scrollkeepingcursor--movetoline--motion)
- [ScrollHalfUpKeepCursor < ScrollKeepingCursor < MoveToLine < Motion](#scrollhalfupkeepcursor--scrollkeepingcursor--movetoline--motion)
- [ScrollFullUpKeepCursor < ScrollKeepingCursor < MoveToLine < Motion](#scrollfullupkeepcursor--scrollkeepingcursor--movetoline--motion)
- [ScrollHalfDownKeepCursor < ScrollKeepingCursor < MoveToLine < Motion](#scrollhalfdownkeepcursor--scrollkeepingcursor--movetoline--motion)
- [ScrollFullDownKeepCursor < ScrollKeepingCursor < MoveToLine < Motion](#scrollfulldownkeepcursor--scrollkeepingcursor--movetoline--motion)
- [Find < MotionWithInput < Motion](#find--motionwithinput--motion)
- [Till < Find < MotionWithInput < Motion](#till--find--motionwithinput--motion)
- [MoveToMark < MotionWithInput < Motion](#movetomark--motionwithinput--motion)
- [SearchBase < MotionWithInput < Motion](#searchbase--motionwithinput--motion)
- [Search < SearchBase < MotionWithInput < Motion](#search--searchbase--motionwithinput--motion)
- [SearchCurrentWord < SearchBase < MotionWithInput < Motion](#searchcurrentword--searchbase--motionwithinput--motion)
- [BracketMatchingMotion < SearchBase < MotionWithInput < Motion](#bracketmatchingmotion--searchbase--motionwithinput--motion)
- [RepeatSearch < SearchBase < MotionWithInput < Motion](#repeatsearch--searchbase--motionwithinput--motion)
- [Insert < Operator](#insert--operator)
- [ReplaceMode < Insert < Operator](#replacemode--insert--operator)
- [InsertAfter < Insert < Operator](#insertafter--insert--operator)
- [InsertAfterEndOfLine < Insert < Operator](#insertafterendofline--insert--operator)
- [InsertAtBeginningOfLine < Insert < Operator](#insertatbeginningofline--insert--operator)
- [InsertAboveWithNewline < Insert < Operator](#insertabovewithnewline--insert--operator)
- [InsertBelowWithNewline < Insert < Operator](#insertbelowwithnewline--insert--operator)
- [Change < Insert < Operator](#change--insert--operator)
- [SubstituteLine < Change < Insert < Operator](#substituteline--change--insert--operator)
- [Prefix](#prefix)
- [Register < Prefix](#register--prefix)
- [TextObject](#textobject)
- [CurrentSelection < TextObject](#currentselection--textobject)
- [SelectInsideWord < TextObject](#selectinsideword--textobject)
- [SelectAWord < TextObject](#selectaword--textobject)
- [SelectInsideWholeWord < TextObject](#selectinsidewholeword--textobject)
- [SelectAWholeWord < TextObject](#selectawholeword--textobject)
- [SelectInsideQuotes < TextObject](#selectinsidequotes--textobject)
- [SelectInsideBrackets < TextObject](#selectinsidebrackets--textobject)
- [SelectInsideParagraph < TextObject](#selectinsideparagraph--textobject)
- [SelectAParagraph < TextObject](#selectaparagraph--textobject)
- [Scroll](#scroll)
- [ScrollDown < Scroll](#scrolldown--scroll)
- [ScrollUp < Scroll](#scrollup--scroll)
- [ScrollCursor < Scroll](#scrollcursor--scroll)
- [ScrollCursorToTop < ScrollCursor < Scroll](#scrollcursortotop--scrollcursor--scroll)
- [ScrollCursorToMiddle < ScrollCursor < Scroll](#scrollcursortomiddle--scrollcursor--scroll)
- [ScrollCursorToBottom < ScrollCursor < Scroll](#scrollcursortobottom--scrollcursor--scroll)
- [ScrollHorizontal](#scrollhorizontal)
- [ScrollCursorToLeft < ScrollHorizontal](#scrollcursortoleft--scrollhorizontal)
- [ScrollCursorToRight < ScrollHorizontal](#scrollcursortoright--scrollhorizontal)
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
