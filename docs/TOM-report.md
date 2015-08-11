# TOM(TextObject, Operator, Motion) report.

vim-mode version: 0.57.0  
*generated at 2015-08-11T15:24:37.259Z*

- [Base](#base) *Not exported*
  - [Motion](#motion--base)
    - [MotionWithInput](#motionwithinput--motion)
      - [Find](#find--motionwithinput)
        - [FindBackwards](#findbackwards--find)
        - [Till](#till--find)
          - [TillBackwards](#tillbackwards--till)
      - [MoveToMark](#movetomark--motionwithinput)
        - [MoveToMarkLiteral](#movetomarkliteral--movetomark)
      - [SearchBase](#searchbase--motionwithinput) *Not exported*
        - [BracketMatchingMotion](#bracketmatchingmotion--searchbase)
        - [RepeatSearch](#repeatsearch--searchbase)
          - [RepeatSearchBackwards](#repeatsearchbackwards--repeatsearch)
        - [Search](#search--searchbase)
          - [ReverseSearch](#reversesearch--search)
        - [SearchCurrentWord](#searchcurrentword--searchbase)
          - [ReverseSearchCurrentWord](#reversesearchcurrentword--searchcurrentword)
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
    - [MoveToNextParagraph](#movetonextparagraph--motion)
    - [MoveToNextWord](#movetonextword--motion)
      - [MoveToNextWholeWord](#movetonextwholeword--movetonextword)
    - [MoveToPreviousParagraph](#movetopreviousparagraph--motion)
    - [MoveToPreviousWholeWord](#movetopreviouswholeword--motion)
    - [MoveToPreviousWord](#movetopreviousword--motion)
    - [MoveUp](#moveup--motion)
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
    - [OperatorWithInput](#operatorwithinput--operator)
      - [Mark](#mark--operatorwithinput)
      - [Replace](#replace--operatorwithinput)
    - [Put](#put--operator) *Not exported*
      - [PutAfter](#putafter--put)
      - [PutBefore](#putbefore--put)
    - [Repeat](#repeat--operator)
    - [Select](#select--operator)
    - [ToggleCase](#togglecase--operator)
      - [ToggleCaseNow](#togglecasenow--togglecase)
    - [UpperCase](#uppercase--operator)
    - [Yank](#yank--operator)
      - [YankLine](#yankline--yank)
  - [OperatorError](#operatorerror--base)
  - [Prefix](#prefix--base) *Not exported*
    - [Register](#register--prefix)
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
    - [SelectAParagraph](#selectaparagraph--textobject)
    - [SelectAWholeWord](#selectawholeword--textobject)
    - [SelectAWord](#selectaword--textobject)
    - [SelectInsideBrackets](#selectinsidebrackets--textobject)
    - [SelectInsideParagraph](#selectinsideparagraph--textobject)
    - [SelectInsideQuotes](#selectinsidequotes--textobject)
    - [SelectInsideWholeWord](#selectinsidewholeword--textobject)
    - [SelectInsideWord](#selectinsideword--textobject)

## Base
*Not exported*

### Motion < Base
- ::constructor`(@vimState)`: **Overridden**
- ::operatesInclusively: `true`
- ::operatesLinewise: `false`
- ::complete: `true`
- ::recordable: `false`
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
- ::complete: `false`: **Overridden**
- ::canComposeWith`(operation)`
- ::compose`(@input)`

### Find < MotionWithInput
- ::constructor`(@vimState, options)`: `super(@vimState)`: **Overridden**
- ::backwards: `false`
- ::offset: `0`
- ::match`(cursor, count)`
- ::reverse`()`
- ::moveCursor`(cursor)`

### FindBackwards < Find
- ::backwards: `true`: **Overridden**

### Till < Find
- ::offset: `1`: **Overridden**
- ::match`()`: `super`: **Overridden**
- ::moveSelectionInclusively`(selection, options)`: `super`: **Overridden**

### TillBackwards < Till
- ::backwards: `true`: **Overridden**

### MoveToMark < MotionWithInput
- ::constructor`(@vimState, linewise)`: `super(@vimState)`: **Overridden**
- ::operatesInclusively: `false`: **Overridden**
- ::isLinewise`()`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToMarkLiteral < MoveToMark
- ::constructor`(@vimState)`: `super(@vimState, false)`: **Overridden**

### SearchBase < MotionWithInput
*Not exported*

### BracketMatchingMotion < SearchBase
- ::operatesInclusively: `true`: **Overridden**
- ::isComplete`()`: **Overridden**
- ::searchForMatch`(startPosition, reverse, inCharacter, outCharacter)`
- ::characterAt`(position)`
- ::getSearchData`(position)`
- ::moveCursor`(cursor)`: **Overridden**

### RepeatSearch < SearchBase
- ::constructor`(@vimState)`: **Overridden**
- ::isComplete`()`: **Overridden**
- ::reversed`()`: **Overridden**

### RepeatSearchBackwards < RepeatSearch
- ::constructor`()`: `super`: **Overridden**

### Search < SearchBase
- ::constructor`()`: `super`: **Overridden**

### ReverseSearch < Search
- ::constructor`()`: `super`: **Overridden**

### SearchCurrentWord < SearchBase
- @keywordRegex: `null`
- ::constructor`(@vimState)`: `super`: **Overridden**
- ::getCurrentWord`()`
- ::cursorIsOnEOF`(cursor)`
- ::getCurrentWordMatch`()`
- ::isComplete`()`: **Overridden**
- ::execute`()`: `super()`: **Overridden**

### ReverseSearchCurrentWord < SearchCurrentWord
- @keywordRegex: `null`
- ::constructor`()`: `super`: **Overridden**

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

### MotionError < Base
- ::constructor`(@message)`: **Overridden**

### Operator < Base
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

### AdjustIndentation < Operator
*Not exported*

### AutoIndent < AdjustIndentation
- ::indent`()`

### Indent < AdjustIndentation
- ::indent`()`

### Outdent < AdjustIndentation
- ::indent`()`

### Delete < Operator
- ::constructor`()`: `super`: **Overridden**
- ::register: `null`
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
- ::constructor`()`: `super`: **Overridden**
- ::complete: `false`: **Overridden**
- ::register: `null`
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
- ::register: `null`: **Overridden**

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

### OperatorWithInput < Operator
- ::canComposeWith`(operation)`: **Overridden**
- ::compose`(operation)`: **Overridden**

### Mark < OperatorWithInput
- ::constructor`()`: `super`: **Overridden**
- ::execute`()`

### Replace < OperatorWithInput
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

### Select < Operator
- ::execute`()`

### ToggleCase < Operator
- ::execute`()`

### ToggleCaseNow < ToggleCase
- ::complete: `true`: **Overridden**

### UpperCase < Operator
- ::execute`()`

### Yank < Operator
- ::constructor`()`: `super`: **Overridden**
- ::register: `null`
- ::execute`()`

### YankLine < Yank
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### OperatorError < Base
- ::constructor`(@message)`: **Overridden**

### Prefix < Base
*Not exported*

### Register < Prefix
- ::constructor`(@name)`: **Overridden**
- ::name: `null`
- ::compose`(composedObject)`: `super(composedObject)`: **Overridden**

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
- ::constructor`(@editor, @state)`: **Overridden**
- ::isComplete`()`
- ::isRecordable`()`

### CurrentSelection < TextObject
- ::constructor`()`: `super`: **Overridden**
- ::select`()`

### SelectAParagraph < TextObject
- ::constructor`(@editor, @inclusive)`: **Overridden**
- ::select`()`

### SelectAWholeWord < TextObject
- ::select`()`

### SelectAWord < TextObject
- ::select`()`

### SelectInsideBrackets < TextObject
- ::constructor`(@editor, @beginChar, @endChar, @includeBrackets)`: **Overridden**
- ::findOpeningBracket`(pos)`
- ::findClosingBracket`(start)`
- ::select`()`

### SelectInsideParagraph < TextObject
- ::constructor`(@editor, @inclusive)`: **Overridden**
- ::select`()`

### SelectInsideQuotes < TextObject
- ::constructor`(@editor, @char, @includeQuotes)`: **Overridden**
- ::findOpeningQuote`(pos)`
- ::isStartQuote`(end)`
- ::lookForwardOnLine`(pos)`
- ::findClosingQuote`(start)`
- ::select`()`

### SelectInsideWholeWord < TextObject
- ::select`()`

### SelectInsideWord < TextObject
- ::select`()
