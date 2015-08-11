# TOM(TextObject, Operator, Motion) report.

vim-mode version: 0.57.0  
*generated at 2015-08-11T15:20:13.814Z*

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
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
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
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::complete: `false`: **Overridden**
- ::canComposeWith`(operation)`
- ::compose`(@input)`

### Find < MotionWithInput
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`(@vimState, options)`: `super(@vimState)`: **Overridden**
- ::backwards: `false`
- ::offset: `0`
- ::match`(cursor, count)`
- ::reverse`()`
- ::moveCursor`(cursor)`

### FindBackwards < Find
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::backwards: `true`: **Overridden**

### Till < Find
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::offset: `1`: **Overridden**
- ::match`()`: `super`: **Overridden**
- ::moveSelectionInclusively`(selection, options)`: `super`: **Overridden**

### TillBackwards < Till
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::backwards: `true`: **Overridden**

### MoveToMark < MotionWithInput
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`(@vimState, linewise)`: `super(@vimState)`: **Overridden**
- ::operatesInclusively: `false`: **Overridden**
- ::isLinewise`()`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToMarkLiteral < MoveToMark
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`(@vimState)`: `super(@vimState, false)`: **Overridden**

### SearchBase < MotionWithInput
*Not exported*

### BracketMatchingMotion < SearchBase
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::operatesInclusively: `true`: **Overridden**
- ::isComplete`()`: **Overridden**
- ::searchForMatch`(startPosition, reverse, inCharacter, outCharacter)`
- ::characterAt`(position)`
- ::getSearchData`(position)`
- ::moveCursor`(cursor)`: **Overridden**

### RepeatSearch < SearchBase
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`(@vimState)`: **Overridden**
- ::isComplete`()`: **Overridden**
- ::reversed`()`: **Overridden**

### RepeatSearchBackwards < RepeatSearch
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**

### Search < SearchBase
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**

### ReverseSearch < Search
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**

### SearchCurrentWord < SearchBase
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- @keywordRegex: `null`
- ::constructor`(@vimState)`: `super`: **Overridden**
- ::getCurrentWord`()`
- ::cursorIsOnEOF`(cursor)`
- ::getCurrentWordMatch`()`
- ::isComplete`()`: **Overridden**
- ::execute`()`: `super()`: **Overridden**

### ReverseSearchCurrentWord < SearchCurrentWord
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- @keywordRegex: `null`
- ::constructor`()`: `super`: **Overridden**

### MoveDown < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveLeft < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveRight < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::operatesInclusively: `false`: **Overridden**
- ::composed: `false`
- ::onDidComposeBy`(operation)`
- ::isOperatorPending`()`
- ::moveCursor`(cursor)`

### MoveToBeginningOfLine < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToEndOfWord < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::wordRegex: `null`
- ::moveCursor`(cursor)`

### MoveToEndOfWholeWord < MoveToEndOfWord
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::wordRegex: `/\S+/`: **Overridden**

### MoveToFirstCharacterOfLine < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineAndDown < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::operatesLinewise: `true`: **Overridden**
- ::operatesInclusively: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineDown < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineUp < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::operatesLinewise: `true`: **Overridden**
- ::operatesInclusively: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToLastCharacterOfLine < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToLastNonblankCharacterOfLineAndDown < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::operatesInclusively: `true`: **Overridden**
- ::skipTrailingWhitespace`(cursor)`
- ::moveCursor`(cursor)`

### MoveToLineBase < Motion
*Not exported*

### MoveToLine < MoveToLineBase
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::moveCursor`(cursor)`

### MoveToRelativeLine < MoveToLineBase
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToScreenLine < MoveToLineBase
*Not exported*

### MoveToBottomOfScreen < MoveToScreenLine
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::getDestinationRow`()`: **Overridden**

### MoveToMiddleOfScreen < MoveToScreenLine
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::getDestinationRow`()`: **Overridden**

### MoveToTopOfScreen < MoveToScreenLine
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::getDestinationRow`()`: **Overridden**

### MoveToStartOfFile < MoveToLineBase
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::moveCursor`(cursor)`

### ScrollKeepingCursor < MoveToLineBase
*Not exported*

### ScrollFullScreenUp < ScrollKeepingCursor
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::direction: `'up'`: **Overridden**
- ::getAmountInPixel`()`

### ScrollFullScreenDown < ScrollFullScreenUp
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::direction: `'down'`: **Overridden**

### ScrollHalfScreenUp < ScrollKeepingCursor
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::direction: `'up'`: **Overridden**
- ::getAmountInPixel`()`

### ScrollHalfScreenDown < ScrollHalfScreenUp
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::direction: `'down'`: **Overridden**

### MoveToNextParagraph < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToNextWord < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::wordRegex: `null`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor, options)`
- ::isEndOfFile`(cursor)`

### MoveToNextWholeWord < MoveToNextWord
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::wordRegex: `/^\s*$|\S+/`: **Overridden**

### MoveToPreviousParagraph < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::moveCursor`(cursor)`

### MoveToPreviousWholeWord < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`
- ::isWholeWord`(cursor)`
- ::isBeginningOfFile`(cursor)`

### MoveToPreviousWord < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveUp < Motion
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MotionError < Base
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`(@message)`: **Overridden**

### Operator < Base
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
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
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::indent`()`

### Indent < AdjustIndentation
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::indent`()`

### Outdent < AdjustIndentation
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::indent`()`

### Delete < Operator
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**
- ::register: `null`
- ::execute`()`

### DeleteLeft < Delete
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### DeleteRight < Delete
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### DeleteToLastCharacterOfLine < Delete
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### Increase < Operator
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**
- ::step: `1`
- ::complete: `true`: **Overridden**
- ::execute`()`
- ::increaseNumber`(cursor)`

### Decrease < Increase
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::step: `-1`: **Overridden**

### Insert < Operator
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::complete: `true`: **Overridden**
- ::confirmChanges`(changes)`
- ::execute`()`
- ::inputOperator`()`

### Insert < Operator
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::complete: `true`: **Overridden**
- ::confirmChanges`(changes)`
- ::execute`()`
- ::inputOperator`()`

### Change < Insert
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `false`: **Overridden**
- ::register: `null`
- ::execute`()`: `super`: **Overridden**

### ChangeToLastCharacterOfLine < Change
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### Substitute < Change
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### SubstituteLine < Change
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**
- ::register: `null`: **Overridden**

### InsertAboveWithNewline < Insert
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::execute`()`: `super`: **Overridden**

### InsertAfter < Insert
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::execute`()`: `super`: **Overridden**

### InsertAfterEndOfLine < Insert
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::execute`()`: `super`: **Overridden**

### InsertAtBeginningOfLine < Insert
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::execute`()`: `super`: **Overridden**

### InsertBelowWithNewline < Insert
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::execute`()`: `super`: **Overridden**

### ReplaceMode < Insert
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::execute`()`: **Overridden**
- ::countChars`(char, string)`

### ReplaceMode < Insert
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::execute`()`: **Overridden**
- ::countChars`(char, string)`

### Join < Operator
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::complete: `true`: **Overridden**
- ::execute`()`

### LowerCase < Operator
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::execute`()`

### OperatorWithInput < Operator
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::canComposeWith`(operation)`: **Overridden**
- ::compose`(operation)`: **Overridden**

### Mark < OperatorWithInput
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**
- ::execute`()`

### Replace < OperatorWithInput
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**
- ::execute`()`

### Put < Operator
*Not exported*

### PutAfter < Put
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::location: `'after'`

### PutBefore < Put
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::location: `'before'`

### Repeat < Operator
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::complete: `true`: **Overridden**
- ::recodable: `false`: **Overridden**
- ::execute`()`

### Select < Operator
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::execute`()`

### ToggleCase < Operator
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::execute`()`

### ToggleCaseNow < ToggleCase
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::complete: `true`: **Overridden**

### UpperCase < Operator
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::execute`()`

### Yank < Operator
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**
- ::register: `null`
- ::execute`()`

### YankLine < Yank
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### OperatorError < Base
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`(@message)`: **Overridden**

### Prefix < Base
*Not exported*

### Register < Prefix
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`(@name)`: **Overridden**
- ::name: `null`
- ::compose`(composedObject)`: `super(composedObject)`: **Overridden**

### Scroll < Base
*Not exported*

### ScrollCursor < Scroll
*Not exported*

### ScrollCursorToBottom < ScrollCursor
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToBottomLeave < ScrollCursorToBottom
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::keepCursor: `true`: **Overridden**

### ScrollCursorToMiddle < ScrollCursor
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToMiddleLeave < ScrollCursorToMiddle
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::keepCursor: `true`: **Overridden**

### ScrollCursorToTop < ScrollCursor
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToTopLeave < ScrollCursorToTop
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::keepCursor: `true`: **Overridden**

### ScrollDown < Scroll
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::execute`()`
- ::keepCursorOnScreen`()`
- ::scrollUp`()`

### ScrollHorizontal < Scroll
*Not exported*

### ScrollCursorToLeft < ScrollHorizontal
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::execute`()`

### ScrollCursorToRight < ScrollHorizontal
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::execute`()`

### ScrollUp < Scroll
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::execute`()`
- ::keepCursorOnScreen`()`
- ::scrollDown`()`

### TextObject < Base
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`(@editor, @state)`: **Overridden**
- ::isComplete`()`
- ::isRecordable`()`

### CurrentSelection < TextObject
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`()`: `super`: **Overridden**
- ::select`()`

### SelectAParagraph < TextObject
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`(@editor, @inclusive)`: **Overridden**
- ::select`()`

### SelectAWholeWord < TextObject
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::select`()`

### SelectAWord < TextObject
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::select`()`

### SelectInsideBrackets < TextObject
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`(@editor, @beginChar, @endChar, @includeBrackets)`: **Overridden**
- ::findOpeningBracket`(pos)`
- ::findClosingBracket`(start)`
- ::select`()`

### SelectInsideParagraph < TextObject
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`(@editor, @inclusive)`: **Overridden**
- ::select`()`

### SelectInsideQuotes < TextObject
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::constructor`(@editor, @char, @includeQuotes)`: **Overridden**
- ::findOpeningQuote`(pos)`
- ::isStartQuote`(end)`
- ::lookForwardOnLine`(pos)`
- ::findClosingQuote`(start)`
- ::select`()`

### SelectInsideWholeWord < TextObject
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::select`()`

### SelectInsideWord < TextObject
- @extend`()`
- @getAncestors`()`
- @getParent`()`
- @report`(options)`
- @reportAll`()`
- ::select`()
