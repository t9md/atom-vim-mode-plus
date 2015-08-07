# TOM report

All TOMs inherits Base class  
Base class omitted from ancesstors list for screen spaces  

- [Input](#input)
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

### Input
- ::isComplete(): `[Function]`
- ::isRecordable(): `[Function]`

### OperatorError

### Operator
- ::vimState: `null`
- ::target: `null`
- ::complete: `null`
- ::isComplete(): `[Function]`
- ::isRecordable(): `[Function]`
- ::compose(target): `[Function]`
- ::canComposeWith(operation): `[Function]`
- ::setTextRegister(register, text): `[Function]`

### OperatorWithInput < Operator
- ::canComposeWith(operation): `[Function]`
- ::compose(operation): `[Function]`

### Select < Operator
- ::execute(): `[Function]`

### Delete < Operator
- ::register: `null`
- ::execute(): `[Function]`

### ToggleCase < Operator
- ::execute(): `[Function]`

### UpperCase < Operator
- ::execute(): `[Function]`

### LowerCase < Operator
- ::execute(): `[Function]`

### Yank < Operator
- ::register: `null`
- ::execute(): `[Function]`

### Join < Operator
- ::execute(): `[Function]`

### Repeat < Operator
- ::isRecordable(): `[Function]`
- ::execute(): `[Function]`

### Mark < OperatorWithInput < Operator
- ::execute(): `[Function]`

### Increase < Operator
- ::step: `1`
- ::execute(): `[Function]`
- ::increaseNumber(cursor): `[Function]`

### Decrease < Increase < Operator
- ::step: `-1`

### AdjustIndentation < Operator
- ::execute(): `[Function]`

### Indent < AdjustIndentation < Operator
- ::indent(): `[Function]`

### Outdent < AdjustIndentation < Operator
- ::indent(): `[Function]`

### Autoindent < AdjustIndentation < Operator
- ::indent(): `[Function]`

### Put < Operator
- ::register: `null`
- ::execute(): `[Function]`
- ::onLastRow(): `[Function]`
- ::onLastColumn(): `[Function]`

### Replace < OperatorWithInput < Operator
- ::execute(): `[Function]`

### MotionError

### Motion
- ::operatesInclusively: `true`
- ::operatesLinewise: `false`
- ::select(options): `[Function]`
- ::execute(): `[Function]`
- ::moveSelectionLinewise(selection, options): `[Function]`
- ::moveSelectionInclusively(selection, options): `[Function]`
- ::moveSelection(selection, options): `[Function]`
- ::isComplete(): `[Function]`
- ::isRecordable(): `[Function]`
- ::isLinewise(): `[Function]`
- ::isInclusive(): `[Function]`

### MotionWithInput < Motion
- ::isComplete(): `[Function]`
- ::canComposeWith(operation): `[Function]`
- ::compose(input): `[Function]`

### MoveLeft < Motion
- ::operatesInclusively: `false`
- ::moveCursor(cursor): `[Function]`

### MoveRight < Motion
- ::operatesInclusively: `false`
- ::moveCursor(cursor): `[Function]`

### MoveUp < Motion
- ::operatesLinewise: `true`
- ::moveCursor(cursor): `[Function]`

### MoveDown < Motion
- ::operatesLinewise: `true`
- ::moveCursor(cursor): `[Function]`

### MoveToPreviousWord < Motion
- ::operatesInclusively: `false`
- ::moveCursor(cursor): `[Function]`

### MoveToPreviousWholeWord < Motion
- ::operatesInclusively: `false`
- ::moveCursor(cursor): `[Function]`
- ::isWholeWord(cursor): `[Function]`
- ::isBeginningOfFile(cursor): `[Function]`

### MoveToNextWord < Motion
- ::wordRegex: `null`
- ::operatesInclusively: `false`
- ::moveCursor(cursor, options): `[Function]`
- ::isEndOfFile(cursor): `[Function]`

### MoveToNextWholeWord < MoveToNextWord < Motion
- ::wordRegex: `/^\s*$|\S+/`

### MoveToEndOfWord < Motion
- ::wordRegex: `null`
- ::moveCursor(cursor): `[Function]`

### MoveToEndOfWholeWord < MoveToEndOfWord < Motion
- ::wordRegex: `/\S+/`

### MoveToNextParagraph < Motion
- ::operatesInclusively: `false`
- ::moveCursor(cursor): `[Function]`

### MoveToPreviousParagraph < Motion
- ::moveCursor(cursor): `[Function]`

### MoveToLine < Motion
- ::operatesLinewise: `true`
- ::getDestinationRow(count): `[Function]`

### MoveToAbsoluteLine < MoveToLine < Motion
- ::moveCursor(cursor): `[Function]`

### MoveToRelativeLine < MoveToLine < Motion
- ::operatesLinewise: `true`
- ::moveCursor(cursor): `[Function]`

### MoveToScreenLine < MoveToLine < Motion
- ::moveCursor(cursor): `[Function]`

### MoveToBeginningOfLine < Motion
- ::operatesInclusively: `false`
- ::moveCursor(cursor): `[Function]`

### MoveToFirstCharacterOfLine < Motion
- ::operatesInclusively: `false`
- ::moveCursor(cursor): `[Function]`

### MoveToFirstCharacterOfLineAndDown < Motion
- ::operatesLinewise: `true`
- ::operatesInclusively: `true`
- ::moveCursor(cursor): `[Function]`

### MoveToLastCharacterOfLine < Motion
- ::operatesInclusively: `false`
- ::moveCursor(cursor): `[Function]`

### MoveToLastNonblankCharacterOfLineAndDown < Motion
- ::operatesInclusively: `true`
- ::skipTrailingWhitespace(cursor): `[Function]`
- ::moveCursor(cursor): `[Function]`

### MoveToFirstCharacterOfLineUp < Motion
- ::operatesLinewise: `true`
- ::operatesInclusively: `true`
- ::moveCursor(cursor): `[Function]`

### MoveToFirstCharacterOfLineDown < Motion
- ::operatesLinewise: `true`
- ::moveCursor(cursor): `[Function]`

### MoveToStartOfFile < MoveToLine < Motion
- ::moveCursor(cursor): `[Function]`

### MoveToTopOfScreen < MoveToScreenLine < MoveToLine < Motion
- ::getDestinationRow(): `[Function]`

### MoveToBottomOfScreen < MoveToScreenLine < MoveToLine < Motion
- ::getDestinationRow(): `[Function]`

### MoveToMiddleOfScreen < MoveToScreenLine < MoveToLine < Motion
- ::getDestinationRow(): `[Function]`

### ScrollKeepingCursor < MoveToLine < Motion
- ::previousFirstScreenRow: `0`
- ::currentFirstScreenRow: `0`
- ::select(options): `[Function]`
- ::execute(): `[Function]`
- ::moveCursor(cursor): `[Function]`
- ::getDestinationRow(): `[Function]`
- ::scrollScreen(): `[Function]`

### ScrollHalfUpKeepCursor < ScrollKeepingCursor < MoveToLine < Motion
- ::scrollDestination(): `[Function]`

### ScrollFullUpKeepCursor < ScrollKeepingCursor < MoveToLine < Motion
- ::scrollDestination(): `[Function]`

### ScrollHalfDownKeepCursor < ScrollKeepingCursor < MoveToLine < Motion
- ::scrollDestination(): `[Function]`

### ScrollFullDownKeepCursor < ScrollKeepingCursor < MoveToLine < Motion
- ::scrollDestination(): `[Function]`

### Find < MotionWithInput < Motion
- ::match(cursor, count): `[Function]`
- ::reverse(): `[Function]`
- ::moveCursor(cursor): `[Function]`

### Till < Find < MotionWithInput < Motion
- ::match(): `[Function]`
- ::moveSelectionInclusively(selection, options): `[Function]`

### MoveToMark < MotionWithInput < Motion
- ::operatesInclusively: `false`
- ::isLinewise(): `[Function]`
- ::moveCursor(cursor): `[Function]`

### SearchBase < MotionWithInput < Motion
- ::operatesInclusively: `false`
- ::reversed(): `[Function]`
- ::moveCursor(cursor): `[Function]`
- ::scan(cursor): `[Function]`
- ::getSearchTerm(term): `[Function]`
- ::updateCurrentSearch(): `[Function]`
- ::replicateCurrentSearch(): `[Function]`

### Search < SearchBase < MotionWithInput < Motion

### SearchCurrentWord < SearchBase < MotionWithInput < Motion
- @keywordRegex: `null`
- ::getCurrentWord(): `[Function]`
- ::cursorIsOnEOF(cursor): `[Function]`
- ::getCurrentWordMatch(): `[Function]`
- ::isComplete(): `[Function]`
- ::execute(): `[Function]`

### BracketMatchingMotion < SearchBase < MotionWithInput < Motion
- ::operatesInclusively: `true`
- ::isComplete(): `[Function]`
- ::searchForMatch(startPosition, reverse, inCharacter, outCharacter): `[Function]`
- ::characterAt(position): `[Function]`
- ::getSearchData(position): `[Function]`
- ::moveCursor(cursor): `[Function]`

### RepeatSearch < SearchBase < MotionWithInput < Motion
- ::isComplete(): `[Function]`
- ::reversed(): `[Function]`

### Insert < Operator
- ::standalone: `true`
- ::isComplete(): `[Function]`
- ::confirmChanges(changes): `[Function]`
- ::execute(): `[Function]`
- ::inputOperator(): `[Function]`

### ReplaceMode < Insert < Operator
- ::execute(): `[Function]`
- ::countChars(char, string): `[Function]`

### InsertAfter < Insert < Operator
- ::execute(): `[Function]`

### InsertAfterEndOfLine < Insert < Operator
- ::execute(): `[Function]`

### InsertAtBeginningOfLine < Insert < Operator
- ::execute(): `[Function]`

### InsertAboveWithNewline < Insert < Operator
- ::execute(): `[Function]`

### InsertBelowWithNewline < Insert < Operator
- ::execute(): `[Function]`

### Change < Insert < Operator
- ::standalone: `false`
- ::register: `null`
- ::execute(): `[Function]`

### SubstituteLine < Change < Insert < Operator
- ::standalone: `true`
- ::register: `null`

### Prefix
- ::complete: `null`
- ::composedObject: `null`
- ::isComplete(): `[Function]`
- ::isRecordable(): `[Function]`
- ::compose(composedObject): `[Function]`
- ::execute(): `[Function]`
- ::select(): `[Function]`
- ::isLinewise(): `[Function]`

### Register < Prefix
- ::name: `null`
- ::compose(composedObject): `[Function]`

### TextObject
- ::isComplete(): `[Function]`
- ::isRecordable(): `[Function]`

### CurrentSelection < TextObject
- ::select(): `[Function]`

### SelectInsideWord < TextObject
- ::select(): `[Function]`

### SelectAWord < TextObject
- ::select(): `[Function]`

### SelectInsideWholeWord < TextObject
- ::select(): `[Function]`

### SelectAWholeWord < TextObject
- ::select(): `[Function]`

### SelectInsideQuotes < TextObject
- ::findOpeningQuote(pos): `[Function]`
- ::isStartQuote(end): `[Function]`
- ::lookForwardOnLine(pos): `[Function]`
- ::findClosingQuote(start): `[Function]`
- ::select(): `[Function]`

### SelectInsideBrackets < TextObject
- ::findOpeningBracket(pos): `[Function]`
- ::findClosingBracket(start): `[Function]`
- ::select(): `[Function]`

### SelectInsideParagraph < TextObject
- ::select(): `[Function]`

### SelectAParagraph < TextObject
- ::select(): `[Function]`

### Scroll
- ::isComplete(): `[Function]`
- ::isRecordable(): `[Function]`

### ScrollDown < Scroll
- ::execute(count): `[Function]`
- ::keepCursorOnScreen(count): `[Function]`
- ::scrollUp(count): `[Function]`

### ScrollUp < Scroll
- ::execute(count): `[Function]`
- ::keepCursorOnScreen(count): `[Function]`
- ::scrollDown(count): `[Function]`

### ScrollCursor < Scroll

### ScrollCursorToTop < ScrollCursor < Scroll
- ::execute(): `[Function]`
- ::scrollUp(): `[Function]`
- ::moveToFirstNonBlank(): `[Function]`

### ScrollCursorToMiddle < ScrollCursor < Scroll
- ::execute(): `[Function]`
- ::scrollMiddle(): `[Function]`
- ::moveToFirstNonBlank(): `[Function]`

### ScrollCursorToBottom < ScrollCursor < Scroll
- ::execute(): `[Function]`
- ::scrollDown(): `[Function]`
- ::moveToFirstNonBlank(): `[Function]`

### ScrollHorizontal
- ::isComplete(): `[Function]`
- ::isRecordable(): `[Function]`
- ::putCursorOnScreen(): `[Function]`

### ScrollCursorToLeft < ScrollHorizontal
- ::execute(): `[Function]`

### ScrollCursorToRight < ScrollHorizontal
- ::execute(): `[Function]`
