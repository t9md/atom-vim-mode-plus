# TOM(TextObject, Operator, Motion) report.

vim-mode version: 0.57.0  
*generated at 2015-08-13T21:35:51.671Z*

- [Base](#base) *Not exported*
  - [Motion](#motion--base)
    - [Find](#find--motion)
      - [FindBackwards](#findbackwards--find)
      - [RepeatFind](#repeatfind--find)
        - [RepeatFindReverse](#repeatfindreverse--repeatfind)
      - [Till](#till--find)
        - [TillBackwards](#tillbackwards--till)
    - [MoveDown](#movedown--motion)
    - [MoveLeft](#moveleft--motion)
    - [MoveRight](#moveright--motion)
    - [MoveToBeginningOfLine](#movetobeginningofline--motion)
    - [MoveToEndOfWord](#movetoendofword--motion)
      - [MoveToEndOfWholeWord](#movetoendofwholeword--movetoendofword)
    - [MoveToFirstCharacterOfLine](#movetofirstcharacterofline--motion)
    - [MoveToFirstCharacterOfLineAndDown](#movetofirstcharacteroflineanddown--motion)
    - [MoveToFirstCharacterOfLineDown](#movetofirstcharacteroflinedown--motion)
    - [MoveToFirstCharacterOfLineUp](#movetofirstcharacteroflineup--motion)
    - [MoveToLastCharacterOfLine](#movetolastcharacterofline--motion)
    - [MoveToLastNonblankCharacterOfLineAndDown](#movetolastnonblankcharacteroflineanddown--motion)
    - [MoveToLineBase](#movetolinebase--motion) *Not exported*
      - [MoveToLine](#movetoline--movetolinebase)
      - [MoveToRelativeLine](#movetorelativeline--movetolinebase)
      - [MoveToScreenLine](#movetoscreenline--movetolinebase) *Not exported*
        - [MoveToBottomOfScreen](#movetobottomofscreen--movetoscreenline)
        - [MoveToMiddleOfScreen](#movetomiddleofscreen--movetoscreenline)
        - [MoveToTopOfScreen](#movetotopofscreen--movetoscreenline)
      - [MoveToStartOfFile](#movetostartoffile--movetolinebase)
      - [ScrollKeepingCursor](#scrollkeepingcursor--movetolinebase) *Not exported*
        - [ScrollFullScreenUp](#scrollfullscreenup--scrollkeepingcursor)
          - [ScrollFullScreenDown](#scrollfullscreendown--scrollfullscreenup)
        - [ScrollHalfScreenUp](#scrollhalfscreenup--scrollkeepingcursor)
          - [ScrollHalfScreenDown](#scrollhalfscreendown--scrollhalfscreenup)
    - [MoveToMark](#movetomark--motion)
      - [MoveToMarkLiteral](#movetomarkliteral--movetomark)
    - [MoveToNextParagraph](#movetonextparagraph--motion)
    - [MoveToNextWord](#movetonextword--motion)
      - [MoveToNextWholeWord](#movetonextwholeword--movetonextword)
    - [MoveToPreviousParagraph](#movetopreviousparagraph--motion)
    - [MoveToPreviousWholeWord](#movetopreviouswholeword--motion)
    - [MoveToPreviousWord](#movetopreviousword--motion)
    - [MoveUp](#moveup--motion)
    - [SearchBase](#searchbase--motion) *Not exported*
      - [BracketMatchingMotion](#bracketmatchingmotion--searchbase)
      - [RepeatSearch](#repeatsearch--searchbase)
        - [RepeatSearchBackwards](#repeatsearchbackwards--repeatsearch)
      - [Search](#search--searchbase)
        - [ReverseSearch](#reversesearch--search)
      - [SearchCurrentWord](#searchcurrentword--searchbase)
        - [ReverseSearchCurrentWord](#reversesearchcurrentword--searchcurrentword)
  - [MotionError](#motionerror--base)
  - [Operator](#operator--base)
    - [AdjustIndentation](#adjustindentation--operator) *Not exported*
      - [AutoIndent](#autoindent--adjustindentation)
      - [Indent](#indent--adjustindentation)
      - [Outdent](#outdent--adjustindentation)
    - [Delete](#delete--operator)
      - [DeleteLeft](#deleteleft--delete)
      - [DeleteRight](#deleteright--delete)
      - [DeleteToLastCharacterOfLine](#deletetolastcharacterofline--delete)
    - [Increase](#increase--operator)
      - [Decrease](#decrease--increase)
    - [Insert](#insert--operator)
    - [Insert](#insert--operator)
      - [Change](#change--insert)
        - [ChangeToLastCharacterOfLine](#changetolastcharacterofline--change)
        - [Substitute](#substitute--change)
        - [SubstituteLine](#substituteline--change)
      - [InsertAboveWithNewline](#insertabovewithnewline--insert)
      - [InsertAfter](#insertafter--insert)
      - [InsertAfterEndOfLine](#insertafterendofline--insert)
      - [InsertAtBeginningOfLine](#insertatbeginningofline--insert)
      - [InsertBelowWithNewline](#insertbelowwithnewline--insert)
      - [ReplaceMode](#replacemode--insert)
      - [ReplaceMode](#replacemode--insert)
    - [Join](#join--operator)
    - [LowerCase](#lowercase--operator)
    - [Mark](#mark--operator)
    - [Put](#put--operator) *Not exported*
      - [PutAfter](#putafter--put)
      - [PutBefore](#putbefore--put)
    - [Repeat](#repeat--operator)
    - [Replace](#replace--operator)
    - [Select](#select--operator)
    - [ToggleCase](#togglecase--operator)
      - [ToggleCaseNow](#togglecasenow--togglecase)
    - [UpperCase](#uppercase--operator)
    - [Yank](#yank--operator)
      - [YankLine](#yankline--yank)
  - [OperatorError](#operatorerror--base)
  - [Scroll](#scroll--base) *Not exported*
    - [ScrollCursor](#scrollcursor--scroll) *Not exported*
      - [ScrollCursorToBottom](#scrollcursortobottom--scrollcursor)
        - [ScrollCursorToBottomLeave](#scrollcursortobottomleave--scrollcursortobottom)
      - [ScrollCursorToMiddle](#scrollcursortomiddle--scrollcursor)
        - [ScrollCursorToMiddleLeave](#scrollcursortomiddleleave--scrollcursortomiddle)
      - [ScrollCursorToTop](#scrollcursortotop--scrollcursor)
        - [ScrollCursorToTopLeave](#scrollcursortotopleave--scrollcursortotop)
    - [ScrollDown](#scrolldown--scroll)
    - [ScrollHorizontal](#scrollhorizontal--scroll) *Not exported*
      - [ScrollCursorToLeft](#scrollcursortoleft--scrollhorizontal)
      - [ScrollCursorToRight](#scrollcursortoright--scrollhorizontal)
    - [ScrollUp](#scrollup--scroll)
  - [TextObject](#textobject--base)
    - [CurrentSelection](#currentselection--textobject)
    - [SelectAWholeWord](#selectawholeword--textobject)
    - [SelectAWord](#selectaword--textobject)
    - [SelectAroundParagraph](#selectaroundparagraph--textobject)
    - [SelectInsideBrackets](#selectinsidebrackets--textobject)
      - [SelectInsideAngleBrackets](#selectinsideanglebrackets--selectinsidebrackets)
        - [SelectAroundAngleBrackets](#selectaroundanglebrackets--selectinsideanglebrackets)
      - [SelectInsideCurlyBrackets](#selectinsidecurlybrackets--selectinsidebrackets)
        - [SelectAroundCurlyBrackets](#selectaroundcurlybrackets--selectinsidecurlybrackets)
      - [SelectInsideParentheses](#selectinsideparentheses--selectinsidebrackets)
        - [SelectAroundParentheses](#selectaroundparentheses--selectinsideparentheses)
      - [SelectInsideSquareBrackets](#selectinsidesquarebrackets--selectinsidebrackets)
        - [SelectAroundSquareBrackets](#selectaroundsquarebrackets--selectinsidesquarebrackets)
      - [SelectInsideTags](#selectinsidetags--selectinsidebrackets)
        - [SelectAroundTags](#selectaroundtags--selectinsidetags)
    - [SelectInsideParagraph](#selectinsideparagraph--textobject)
    - [SelectInsideQuotes](#selectinsidequotes--textobject)
      - [SelectInsideBackTicks](#selectinsidebackticks--selectinsidequotes)
        - [SelectAroundBackTicks](#selectaroundbackticks--selectinsidebackticks)
      - [SelectInsideDoubleQuotes](#selectinsidedoublequotes--selectinsidequotes)
        - [SelectAroundDoubleQuotes](#selectarounddoublequotes--selectinsidedoublequotes)
      - [SelectInsideSingleQuotes](#selectinsidesinglequotes--selectinsidequotes)
        - [SelectAroundSingleQuotes](#selectaroundsinglequotes--selectinsidesinglequotes)
    - [SelectInsideWholeWord](#selectinsidewholeword--textobject)
    - [SelectInsideWord](#selectinsideword--textobject)

## Base
*Not exported*

### Motion < Base
- ::constructor`(@vimState)`: **Overridden**
- ::operatesInclusively: `true`
- ::operatesLinewise: `false`
- ::complete: `true`: **Overridden**
- ::recordable: `false`
- ::select`(options)`
- ::execute`()`
- ::moveSelectionLinewise`(selection, options)`
- ::moveSelectionInclusively`(selection, options)`
- ::moveSelection`(selection, options)`
- ::isLinewise`()`
- ::isInclusive`()`
- ::getInput`()`

### Find < Motion
- ::constructor`()`: `super`: **Overridden**
- ::backwards: `false`
- ::complete: `false`: **Overridden**
- ::repeated: `false`
- ::reverse: `false`
- ::offset: `0`
- ::match`(cursor, count)`
- ::moveCursor`(cursor)`

### FindBackwards < Find
- ::backwards: `true`: **Overridden**

### RepeatFind < Find
- ::constructor`()`: `super`: **Overridden**
- ::repeated: `true`: **Overridden**
- ::reverse: `false`: **Overridden**
- ::offset: `0`: **Overridden**
- ::moveCursor`()`: **Overridden**

### RepeatFindReverse < RepeatFind
- ::constructor`()`: `super`: **Overridden**
- ::reverse: `true`: **Overridden**

### Till < Find
- ::offset: `1`: **Overridden**
- ::match`()`: `super`: **Overridden**
- ::moveSelectionInclusively`(selection, options)`: `super`: **Overridden**

### TillBackwards < Till
- ::backwards: `true`: **Overridden**

### MoveDown < Motion
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveLeft < Motion
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveRight < Motion
- ::operatesInclusively: `false`: **Overridden**
- ::composed: `false`
- ::onDidComposeBy`(operation)`
- ::isOperatorPending`()`
- ::moveCursor`(cursor)`

### MoveToBeginningOfLine < Motion
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToEndOfWord < Motion
- ::wordRegex: `null`
- ::moveCursor`(cursor)`

### MoveToEndOfWholeWord < MoveToEndOfWord
- ::wordRegex: `/\S+/`: **Overridden**

### MoveToFirstCharacterOfLine < Motion
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineAndDown < Motion
- ::operatesLinewise: `true`: **Overridden**
- ::operatesInclusively: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineDown < Motion
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineUp < Motion
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

### MoveToLineBase < Motion
*Not exported*

### MoveToLine < MoveToLineBase
- ::moveCursor`(cursor)`

### MoveToRelativeLine < MoveToLineBase
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToScreenLine < MoveToLineBase
*Not exported*

### MoveToBottomOfScreen < MoveToScreenLine
- ::getDestinationRow`()`: **Overridden**

### MoveToMiddleOfScreen < MoveToScreenLine
- ::getDestinationRow`()`: **Overridden**

### MoveToTopOfScreen < MoveToScreenLine
- ::getDestinationRow`()`: **Overridden**

### MoveToStartOfFile < MoveToLineBase
- ::moveCursor`(cursor)`

### ScrollKeepingCursor < MoveToLineBase
*Not exported*

### ScrollFullScreenUp < ScrollKeepingCursor
- ::direction: `'up'`: **Overridden**
- ::getAmountInPixel`()`

### ScrollFullScreenDown < ScrollFullScreenUp
- ::direction: `'down'`: **Overridden**

### ScrollHalfScreenUp < ScrollKeepingCursor
- ::direction: `'up'`: **Overridden**
- ::getAmountInPixel`()`

### ScrollHalfScreenDown < ScrollHalfScreenUp
- ::direction: `'down'`: **Overridden**

### MoveToMark < Motion
- ::constructor`()`: `super`: **Overridden**
- ::operatesInclusively: `false`: **Overridden**
- ::operatesLinewise: `true`: **Overridden**
- ::complete: `false`: **Overridden**
- ::isLinewise`()`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToMarkLiteral < MoveToMark
- ::operatesLinewise: `false`: **Overridden**

### MoveToNextParagraph < Motion
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToNextWord < Motion
- ::wordRegex: `null`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor, options)`
- ::isEndOfFile`(cursor)`

### MoveToNextWholeWord < MoveToNextWord
- ::wordRegex: `/^\s*$|\S+/`: **Overridden**

### MoveToPreviousParagraph < Motion
- ::moveCursor`(cursor)`

### MoveToPreviousWholeWord < Motion
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`
- ::isWholeWord`(cursor)`
- ::isBeginningOfFile`(cursor)`

### MoveToPreviousWord < Motion
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveUp < Motion
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### SearchBase < Motion
*Not exported*

### BracketMatchingMotion < SearchBase
- ::operatesInclusively: `true`: **Overridden**
- ::complete: `true`: **Overridden**
- ::searchForMatch`(startPosition, reverse, inCharacter, outCharacter)`
- ::characterAt`(position)`
- ::getSearchData`(position)`
- ::moveCursor`(cursor)`: **Overridden**

### RepeatSearch < SearchBase
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**
- ::dontUpdateCurrentSearch: `true`: **Overridden**
- ::reversed`()`: **Overridden**

### RepeatSearchBackwards < RepeatSearch
- ::constructor`()`: `super`: **Overridden**

### Search < SearchBase
- ::constructor`()`: `super`: **Overridden**
- ::getInput`()`: **Overridden**

### ReverseSearch < Search
- ::constructor`()`: `super`: **Overridden**

### SearchCurrentWord < SearchBase
- @keywordRegex: `null`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**
- ::getCurrentWord`()`
- ::cursorIsOnEOF`(cursor)`
- ::getCurrentWordMatch`()`
- ::execute`()`: `super()`: **Overridden**

### ReverseSearchCurrentWord < SearchCurrentWord
- @keywordRegex: `null`
- ::constructor`()`: `super`: **Overridden**

### MotionError < Base
- ::constructor`(@message)`: **Overridden**

### Operator < Base
- ::constructor`(@vimState)`: **Overridden**
- ::vimState: `null`
- ::target: `null`
- ::complete: `false`: **Overridden**
- ::recodable: `true`: **Overridden**
- ::compose`(@target)`
- ::canComposeWith`(operation)`
- ::setTextRegister`(register, text)`
- ::getInput`()`
- ::getRegisterName`()`

### AdjustIndentation < Operator
*Not exported*

### AutoIndent < AdjustIndentation
- ::indent`()`

### Indent < AdjustIndentation
- ::indent`()`

### Outdent < AdjustIndentation
- ::indent`()`

### Delete < Operator
- ::execute`()`

### DeleteLeft < Delete
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### DeleteRight < Delete
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### DeleteToLastCharacterOfLine < Delete
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### Increase < Operator
- ::constructor`()`: `super`: **Overridden**
- ::step: `1`
- ::complete: `true`: **Overridden**
- ::execute`()`
- ::increaseNumber`(cursor)`

### Decrease < Increase
- ::step: `-1`: **Overridden**

### Insert < Operator
- ::complete: `true`: **Overridden**
- ::confirmChanges`(changes)`
- ::execute`()`
- ::inputOperator`()`

### Insert < Operator
- ::complete: `true`: **Overridden**
- ::confirmChanges`(changes)`
- ::execute`()`
- ::inputOperator`()`

### Change < Insert
- ::complete: `false`: **Overridden**
- ::execute`()`: `super`: **Overridden**

### ChangeToLastCharacterOfLine < Change
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### Substitute < Change
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### SubstituteLine < Change
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### InsertAboveWithNewline < Insert
- ::execute`()`: `super`: **Overridden**

### InsertAfter < Insert
- ::execute`()`: `super`: **Overridden**

### InsertAfterEndOfLine < Insert
- ::execute`()`: `super`: **Overridden**

### InsertAtBeginningOfLine < Insert
- ::execute`()`: `super`: **Overridden**

### InsertBelowWithNewline < Insert
- ::execute`()`: `super`: **Overridden**

### ReplaceMode < Insert
- ::execute`()`: **Overridden**
- ::countChars`(char, string)`

### ReplaceMode < Insert
- ::execute`()`: **Overridden**
- ::countChars`(char, string)`

### Join < Operator
- ::complete: `true`: **Overridden**
- ::execute`()`

### LowerCase < Operator
- ::execute`()`

### Mark < Operator
- ::constructor`()`: `super`: **Overridden**
- ::execute`()`

### Put < Operator
*Not exported*

### PutAfter < Put
- ::location: `'after'`

### PutBefore < Put
- ::location: `'before'`

### Repeat < Operator
- ::complete: `true`: **Overridden**
- ::recodable: `false`: **Overridden**
- ::execute`()`

### Replace < Operator
- ::constructor`()`: `super`: **Overridden**
- ::input: `null`
- ::isComplete`()`: **Overridden**
- ::execute`()`

### Select < Operator
- ::execute`()`

### ToggleCase < Operator
- ::execute`()`

### ToggleCaseNow < ToggleCase
- ::complete: `true`: **Overridden**

### UpperCase < Operator
- ::execute`()`

### Yank < Operator
- ::execute`()`

### YankLine < Yank
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### OperatorError < Base
- ::constructor`(@message)`: **Overridden**

### Scroll < Base
*Not exported*

### ScrollCursor < Scroll
*Not exported*

### ScrollCursorToBottom < ScrollCursor
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToBottomLeave < ScrollCursorToBottom
- ::keepCursor: `true`: **Overridden**

### ScrollCursorToMiddle < ScrollCursor
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToMiddleLeave < ScrollCursorToMiddle
- ::keepCursor: `true`: **Overridden**

### ScrollCursorToTop < ScrollCursor
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToTopLeave < ScrollCursorToTop
- ::keepCursor: `true`: **Overridden**

### ScrollDown < Scroll
- ::execute`()`
- ::keepCursorOnScreen`()`
- ::scrollUp`()`

### ScrollHorizontal < Scroll
*Not exported*

### ScrollCursorToLeft < ScrollHorizontal
- ::execute`()`

### ScrollCursorToRight < ScrollHorizontal
- ::execute`()`

### ScrollUp < Scroll
- ::execute`()`
- ::keepCursorOnScreen`()`
- ::scrollDown`()`

### TextObject < Base
- ::constructor`(@vimState)`: **Overridden**
- ::vimState: `null`
- ::complete: `true`: **Overridden**
- ::recodable: `false`: **Overridden**

### CurrentSelection < TextObject
- ::select`()`

### SelectAWholeWord < TextObject
- ::select`()`

### SelectAWord < TextObject
- ::select`()`

### SelectAroundParagraph < TextObject
- ::select`()`

### SelectInsideBrackets < TextObject
- ::beginChar: `null`
- ::endChar: `null`
- ::includeBrackets: `false`
- ::findOpeningBracket`(pos)`
- ::findClosingBracket`(start)`
- ::select`()`

### SelectInsideAngleBrackets < SelectInsideBrackets
- ::beginChar: `'<'`: **Overridden**
- ::endChar: `'>'`: **Overridden**

### SelectAroundAngleBrackets < SelectInsideAngleBrackets
- ::includeBrackets: `true`: **Overridden**

### SelectInsideCurlyBrackets < SelectInsideBrackets
- ::beginChar: `'{'`: **Overridden**
- ::endChar: `'}'`: **Overridden**

### SelectAroundCurlyBrackets < SelectInsideCurlyBrackets
- ::includeBrackets: `true`: **Overridden**

### SelectInsideParentheses < SelectInsideBrackets
- ::beginChar: `'('`: **Overridden**
- ::endChar: `')'`: **Overridden**

### SelectAroundParentheses < SelectInsideParentheses
- ::includeBrackets: `true`: **Overridden**

### SelectInsideSquareBrackets < SelectInsideBrackets
- ::beginChar: `'['`: **Overridden**
- ::endChar: `']'`: **Overridden**

### SelectAroundSquareBrackets < SelectInsideSquareBrackets
- ::includeBrackets: `true`: **Overridden**

### SelectInsideTags < SelectInsideBrackets
- ::beginChar: `'>'`: **Overridden**
- ::endChar: `'<'`: **Overridden**

### SelectAroundTags < SelectInsideTags
- ::includeBrackets: `true`: **Overridden**

### SelectInsideParagraph < TextObject
- ::select`()`

### SelectInsideQuotes < TextObject
- ::char: `null`
- ::includeQuotes: `false`
- ::findOpeningQuote`(pos)`
- ::isStartQuote`(end)`
- ::lookForwardOnLine`(pos)`
- ::findClosingQuote`(start)`
- ::select`()`

### SelectInsideBackTicks < SelectInsideQuotes
- ::char: `'`'`: **Overridden**

### SelectAroundBackTicks < SelectInsideBackTicks
- ::includeQuotes: `true`: **Overridden**

### SelectInsideDoubleQuotes < SelectInsideQuotes
- ::char: `'"'`: **Overridden**

### SelectAroundDoubleQuotes < SelectInsideDoubleQuotes
- ::includeQuotes: `true`: **Overridden**

### SelectInsideSingleQuotes < SelectInsideQuotes
- ::char: `'\''`: **Overridden**

### SelectAroundSingleQuotes < SelectInsideSingleQuotes
- ::includeQuotes: `true`: **Overridden**

### SelectInsideWholeWord < TextObject
- ::select`()`

### SelectInsideWord < TextObject
- ::select`()
