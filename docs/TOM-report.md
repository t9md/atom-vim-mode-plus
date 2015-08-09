# TOM report

All TOMs inherits Base class  
`Base` class itself is omitted from ancestors list to save screen space  

- [Input](#input)
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
- [OperatorError](#operatorerror)
- [Operator](#operator)
- [OperatorWithInput < Operator](#operatorwithinput--operator)
- [Select < Operator](#select--operator)
- [Delete < Operator](#delete--operator)
- [DeleteRight < Delete < Operator](#deleteright--delete--operator)
- [DeleteLeft < Delete < Operator](#deleteleft--delete--operator)
- [DeleteToLastCharacterOfLine < Delete < Operator](#deletetolastcharacterofline--delete--operator)
- [ToggleCase < Operator](#togglecase--operator)
- [ToggleCaseNow < ToggleCase < Operator](#togglecasenow--togglecase--operator)
- [UpperCase < Operator](#uppercase--operator)
- [LowerCase < Operator](#lowercase--operator)
- [Yank < Operator](#yank--operator)
- [YankLine < Yank < Operator](#yankline--yank--operator)
- [Join < Operator](#join--operator)
- [Repeat < Operator](#repeat--operator)
- [Mark < OperatorWithInput < Operator](#mark--operatorwithinput--operator)
- [Increase < Operator](#increase--operator)
- [Decrease < Increase < Operator](#decrease--increase--operator)
- [AdjustIndentation < Operator](#adjustindentation--operator)
- [Indent < AdjustIndentation < Operator](#indent--adjustindentation--operator)
- [Outdent < AdjustIndentation < Operator](#outdent--adjustindentation--operator)
- [AutoIndent < AdjustIndentation < Operator](#autoindent--adjustindentation--operator)
- [Put < Operator](#put--operator)
- [PutBefore < Put < Operator](#putbefore--put--operator)
- [PutAfter < Put < Operator](#putafter--put--operator)
- [Insert < Operator](#insert--operator)
- [ReplaceMode < Insert < Operator](#replacemode--insert--operator)
- [InsertAfter < Insert < Operator](#insertafter--insert--operator)
- [InsertAfterEndOfLine < Insert < Operator](#insertafterendofline--insert--operator)
- [InsertAtBeginningOfLine < Insert < Operator](#insertatbeginningofline--insert--operator)
- [InsertAboveWithNewline < Insert < Operator](#insertabovewithnewline--insert--operator)
- [InsertBelowWithNewline < Insert < Operator](#insertbelowwithnewline--insert--operator)
- [Change < Insert < Operator](#change--insert--operator)
- [Substitute < Change < Insert < Operator](#substitute--change--insert--operator)
- [SubstituteLine < Change < Insert < Operator](#substituteline--change--insert--operator)
- [ChangeToLastCharacterOfLine < Change < Insert < Operator](#changetolastcharacterofline--change--insert--operator)
- [Replace < OperatorWithInput < Operator](#replace--operatorwithinput--operator)
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
- [ScrollCursorToBottom < ScrollCursor < Scroll](#scrollcursortobottom--scrollcursor--scroll)
- [ScrollCursorToMiddle < ScrollCursor < Scroll](#scrollcursortomiddle--scrollcursor--scroll)
- [ScrollCursorToTopLeave < ScrollCursorToTop < ScrollCursor < Scroll](#scrollcursortotopleave--scrollcursortotop--scrollcursor--scroll)
- [ScrollCursorToBottomLeave < ScrollCursorToBottom < ScrollCursor < Scroll](#scrollcursortobottomleave--scrollcursortobottom--scrollcursor--scroll)
- [ScrollCursorToMiddleLeave < ScrollCursorToMiddle < ScrollCursor < Scroll](#scrollcursortomiddleleave--scrollcursortomiddle--scrollcursor--scroll)
- [ScrollHorizontal < Scroll](#scrollhorizontal--scroll)
- [ScrollCursorToLeft < ScrollHorizontal < Scroll](#scrollcursortoleft--scrollhorizontal--scroll)
- [ScrollCursorToRight < ScrollHorizontal < Scroll](#scrollcursortoright--scrollhorizontal--scroll)

### Input
- ::constructor`(@characters)`: **Overridden**
- ::isComplete`()`
- ::isRecordable`()`

### MotionError
- ::constructor`(@message)`: **Overridden**

### Motion
- ::constructor`(@editor, @vimState)`: **Overridden**
- ::operatesInclusively: `true`
- ::operatesLinewise: `false`
- ::select`(options)`
- ::execute`()`
- ::moveSelectionLinewise`(selection, options)`
- ::moveSelectionInclusively`(selection, options)`
- ::moveSelection`(selection, options)`
- ::isComplete`()`
- ::isRecordable`()`
- ::isLinewise`()`
- ::isInclusive`()`

### MotionWithInput < Motion
- ::constructor`()`: `super`: **Overridden**
- ::isComplete`()`: **Overridden**
- ::canComposeWith`(operation)`
- ::compose`(@input)`

### MoveLeft < Motion
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveRight < Motion
- ::constructor`()`: `super`: **Overridden**
- ::didComposeByOperator: `false`
- ::operatesInclusively: `false`: **Overridden**
- ::onDidComposeBy`(operation)`
- ::isOperatorPending`()`
- ::moveCursor`(cursor)`

### MoveUp < Motion
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveDown < Motion
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToPreviousWord < Motion
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToPreviousWholeWord < Motion
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`
- ::isWholeWord`(cursor)`
- ::isBeginningOfFile`(cursor)`

### MoveToNextWord < Motion
- ::wordRegex: `null`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor, options)`
- ::isEndOfFile`(cursor)`

### MoveToNextWholeWord < MoveToNextWord < Motion
- ::wordRegex: `/^\s*$|\S+/`: **Overridden**

### MoveToEndOfWord < Motion
- ::wordRegex: `null`
- ::moveCursor`(cursor)`

### MoveToEndOfWholeWord < MoveToEndOfWord < Motion
- ::wordRegex: `/\S+/`: **Overridden**

### MoveToNextParagraph < Motion
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToPreviousParagraph < Motion
- ::moveCursor`(cursor)`

### MoveToLine < Motion
- ::operatesLinewise: `true`: **Overridden**
- ::getDestinationRow`(count)`

### MoveToAbsoluteLine < MoveToLine < Motion
- ::moveCursor`(cursor)`

### MoveToRelativeLine < MoveToLine < Motion
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToScreenLine < MoveToLine < Motion
- ::constructor`(@editorElement, @vimState, @scrolloff)`: `super(@editorElement.getModel(), @vimState)`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToBeginningOfLine < Motion
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLine < Motion
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineAndDown < Motion
- ::operatesLinewise: `true`: **Overridden**
- ::operatesInclusively: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToLastCharacterOfLine < Motion
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToLastNonblankCharacterOfLineAndDown < Motion
- ::operatesInclusively: `true`: **Overridden**
- ::skipTrailingWhitespace`(cursor)`
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineUp < Motion
- ::operatesLinewise: `true`: **Overridden**
- ::operatesInclusively: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineDown < Motion
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToStartOfFile < MoveToLine < Motion
- ::moveCursor`(cursor)`

### MoveToTopOfScreen < MoveToScreenLine < MoveToLine < Motion
- ::getDestinationRow`()`: **Overridden**

### MoveToBottomOfScreen < MoveToScreenLine < MoveToLine < Motion
- ::getDestinationRow`()`: **Overridden**

### MoveToMiddleOfScreen < MoveToScreenLine < MoveToLine < Motion
- ::getDestinationRow`()`: **Overridden**

### ScrollKeepingCursor < MoveToLine < Motion
- ::constructor`(@editorElement, @vimState)`: `super(@editorElement.getModel(), @vimState)`: **Overridden**
- ::previousFirstScreenRow: `0`
- ::currentFirstScreenRow: `0`
- ::select`(options)`: `super(options)`: **Overridden**
- ::execute`()`: `super`: **Overridden**
- ::moveCursor`(cursor)`
- ::getDestinationRow`()`: **Overridden**
- ::scrollScreen`()`

### ScrollHalfUpKeepCursor < ScrollKeepingCursor < MoveToLine < Motion
- ::scrollDestination`()`

### ScrollFullUpKeepCursor < ScrollKeepingCursor < MoveToLine < Motion
- ::scrollDestination`()`

### ScrollHalfDownKeepCursor < ScrollKeepingCursor < MoveToLine < Motion
- ::scrollDestination`()`

### ScrollFullDownKeepCursor < ScrollKeepingCursor < MoveToLine < Motion
- ::scrollDestination`()`

### Find < MotionWithInput < Motion
- ::constructor`(@editor, @vimState, opts)`: `super(@editor, @vimState)`: **Overridden**
- ::match`(cursor, count)`
- ::reverse`()`
- ::moveCursor`(cursor)`

### Till < Find < MotionWithInput < Motion
- ::constructor`()`: `super`: **Overridden**
- ::match`()`: `super`: **Overridden**
- ::moveSelectionInclusively`(selection, options)`: `super`: **Overridden**

### MoveToMark < MotionWithInput < Motion
- ::constructor`(@editor, @vimState, linewise)`: `super(@editor, @vimState)`: **Overridden**
- ::operatesInclusively: `false`: **Overridden**
- ::isLinewise`()`: **Overridden**
- ::moveCursor`(cursor)`

### SearchBase < MotionWithInput < Motion
- ::constructor`(@editor, @vimState, options)`: `super(@editor, @vimState)`: **Overridden**
- ::operatesInclusively: `false`: **Overridden**
- ::reversed`()`
- ::moveCursor`(cursor)`
- ::scan`(cursor)`
- ::getSearchTerm`(term)`
- ::updateCurrentSearch`()`
- ::replicateCurrentSearch`()`

### Search < SearchBase < MotionWithInput < Motion
- ::constructor`(@editor, @vimState)`: `super(@editor, @vimState)`: **Overridden**

### SearchCurrentWord < SearchBase < MotionWithInput < Motion
- @keywordRegex: `null`
- ::constructor`(@editor, @vimState)`: `super(@editor, @vimState)`: **Overridden**
- ::getCurrentWord`()`
- ::cursorIsOnEOF`(cursor)`
- ::getCurrentWordMatch`()`
- ::isComplete`()`: **Overridden**
- ::execute`()`: `super()`: **Overridden**

### BracketMatchingMotion < SearchBase < MotionWithInput < Motion
- ::operatesInclusively: `true`: **Overridden**
- ::isComplete`()`: **Overridden**
- ::searchForMatch`(startPosition, reverse, inCharacter, outCharacter)`
- ::characterAt`(position)`
- ::getSearchData`(position)`
- ::moveCursor`(cursor)`: **Overridden**

### RepeatSearch < SearchBase < MotionWithInput < Motion
- ::constructor`(@editor, @vimState)`: **Overridden**
- ::isComplete`()`: **Overridden**
- ::reversed`()`: **Overridden**

### OperatorError
- ::constructor`(@message)`: **Overridden**

### Operator
- ::constructor`(@vimState, options)`: **Overridden**
- ::vimState: `null`
- ::target: `null`
- ::complete: `false`
- ::recodable: `true`
- ::isComplete`()`
- ::isRecordable`()`
- ::compose`(@target)`
- ::canComposeWith`(operation)`
- ::setTextRegister`(register, text)`

### OperatorWithInput < Operator
- ::canComposeWith`(operation)`: **Overridden**
- ::compose`(operation)`: **Overridden**

### Select < Operator
- ::execute`()`

### Delete < Operator
- ::constructor`()`: `super`: **Overridden**
- ::register: `null`
- ::execute`()`

### DeleteRight < Delete < Operator
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### DeleteLeft < Delete < Operator
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### DeleteToLastCharacterOfLine < Delete < Operator
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### ToggleCase < Operator
- ::execute`()`

### ToggleCaseNow < ToggleCase < Operator
- ::complete: `true`: **Overridden**

### UpperCase < Operator
- ::execute`()`

### LowerCase < Operator
- ::execute`()`

### Yank < Operator
- ::constructor`()`: `super`: **Overridden**
- ::register: `null`
- ::execute`()`

### YankLine < Yank < Operator
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### Join < Operator
- ::complete: `true`: **Overridden**
- ::execute`()`

### Repeat < Operator
- ::complete: `true`: **Overridden**
- ::recodable: `false`: **Overridden**
- ::execute`()`

### Mark < OperatorWithInput < Operator
- ::constructor`()`: `super`: **Overridden**
- ::execute`()`

### Increase < Operator
- ::constructor`()`: `super`: **Overridden**
- ::step: `1`
- ::complete: `true`: **Overridden**
- ::execute`()`
- ::increaseNumber`(cursor)`

### Decrease < Increase < Operator
- ::step: `-1`: **Overridden**

### AdjustIndentation < Operator
- ::execute`()`

### Indent < AdjustIndentation < Operator
- ::indent`()`

### Outdent < AdjustIndentation < Operator
- ::indent`()`

### AutoIndent < AdjustIndentation < Operator
- ::indent`()`

### Put < Operator
- ::constructor`()`: `super`: **Overridden**
- ::register: `null`
- ::complete: `true`: **Overridden**
- ::execute`()`
- ::onLastRow`()`
- ::onLastColumn`()`

### PutBefore < Put < Operator
- ::location: `'before'`

### PutAfter < Put < Operator
- ::location: `'after'`

### Insert < Operator
- ::complete: `true`: **Overridden**
- ::confirmChanges`(changes)`
- ::execute`()`
- ::inputOperator`()`

### ReplaceMode < Insert < Operator
- ::execute`()`: **Overridden**
- ::countChars`(char, string)`

### InsertAfter < Insert < Operator
- ::execute`()`: `super`: **Overridden**

### InsertAfterEndOfLine < Insert < Operator
- ::execute`()`: `super`: **Overridden**

### InsertAtBeginningOfLine < Insert < Operator
- ::execute`()`: `super`: **Overridden**

### InsertAboveWithNewline < Insert < Operator
- ::execute`()`: `super`: **Overridden**

### InsertBelowWithNewline < Insert < Operator
- ::execute`()`: `super`: **Overridden**

### Change < Insert < Operator
- ::constructor`()`: `super`: **Overridden**
- ::complete: `false`: **Overridden**
- ::register: `null`
- ::execute`()`: `super`: **Overridden**

### Substitute < Change < Insert < Operator
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### SubstituteLine < Change < Insert < Operator
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**
- ::register: `null`: **Overridden**

### ChangeToLastCharacterOfLine < Change < Insert < Operator
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### Replace < OperatorWithInput < Operator
- ::constructor`()`: `super`: **Overridden**
- ::execute`()`

### Prefix
- ::complete: `null`
- ::composedObject: `null`
- ::isComplete`()`
- ::isRecordable`()`
- ::compose`(@composedObject)`
- ::execute`()`
- ::select`()`
- ::isLinewise`()`

### Register < Prefix
- ::constructor`(@name)`: **Overridden**
- ::name: `null`
- ::compose`(composedObject)`: `super(composedObject)`: **Overridden**

### TextObject
- ::constructor`(@editor, @state)`: **Overridden**
- ::isComplete`()`
- ::isRecordable`()`

### CurrentSelection < TextObject
- ::constructor`()`: `super`: **Overridden**
- ::select`()`

### SelectInsideWord < TextObject
- ::select`()`

### SelectAWord < TextObject
- ::select`()`

### SelectInsideWholeWord < TextObject
- ::select`()`

### SelectAWholeWord < TextObject
- ::select`()`

### SelectInsideQuotes < TextObject
- ::constructor`(@editor, @char, @includeQuotes)`: **Overridden**
- ::findOpeningQuote`(pos)`
- ::isStartQuote`(end)`
- ::lookForwardOnLine`(pos)`
- ::findClosingQuote`(start)`
- ::select`()`

### SelectInsideBrackets < TextObject
- ::constructor`(@editor, @beginChar, @endChar, @includeBrackets)`: **Overridden**
- ::findOpeningBracket`(pos)`
- ::findClosingBracket`(start)`
- ::select`()`

### SelectInsideParagraph < TextObject
- ::constructor`(@editor, @inclusive)`: **Overridden**
- ::select`()`

### SelectAParagraph < TextObject
- ::constructor`(@editor, @inclusive)`: **Overridden**
- ::select`()`

### Scroll
- ::constructor`(@vimState, options)`: **Overridden**
- ::isComplete`()`
- ::isRecordable`()`

### ScrollDown < Scroll
- ::execute`()`
- ::keepCursorOnScreen`()`
- ::scrollUp`()`

### ScrollUp < Scroll
- ::execute`()`
- ::keepCursorOnScreen`()`
- ::scrollDown`()`

### ScrollCursor < Scroll
- ::constructor`()`: `super`: **Overridden**
- ::keepCursor: `false`
- ::execute`()`
- ::moveToFirstCharacterOfLine`()`
- ::getOffSetPixelHeight`(lineDelta)`

### ScrollCursorToTop < ScrollCursor < Scroll
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToBottom < ScrollCursor < Scroll
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToMiddle < ScrollCursor < Scroll
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToTopLeave < ScrollCursorToTop < ScrollCursor < Scroll
- ::keepCursor: `true`: **Overridden**

### ScrollCursorToBottomLeave < ScrollCursorToBottom < ScrollCursor < Scroll
- ::keepCursor: `true`: **Overridden**

### ScrollCursorToMiddleLeave < ScrollCursorToMiddle < ScrollCursor < Scroll
- ::keepCursor: `true`: **Overridden**

### ScrollHorizontal < Scroll
- ::constructor`()`: `super`: **Overridden**
- ::putCursorOnScreen`()`

### ScrollCursorToLeft < ScrollHorizontal < Scroll
- ::execute`()`

### ScrollCursorToRight < ScrollHorizontal < Scroll
- ::execute`()`
