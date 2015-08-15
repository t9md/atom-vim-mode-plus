# TOM(TextObject, Operator, Motion) report.

vim-mode version: 0.57.0  
*generated at 2015-08-15T18:50:27.145Z*

- [Base](#base) *Not exported*
  - [InsertMode](#insertmode--base) *Not exported*
    - [CopyFromLineAbove](#copyfromlineabove--insertmode)
      - [CopyFromLineBelow](#copyfromlinebelow--copyfromlineabove)
    - [InsertRegister](#insertregister--insertmode)
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
      - [ScrollUp](#scrollup--scrolldown)
    - [ScrollHorizontal](#scrollhorizontal--scroll) *Not exported*
      - [ScrollCursorToLeft](#scrollcursortoleft--scrollhorizontal)
      - [ScrollCursorToRight](#scrollcursortoright--scrollhorizontal)
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

### InsertMode < Base
*Not exported*

### CopyFromLineAbove < InsertMode
- keymaps
  - atom-text-editor.vim-mode.insert-mode: `ctrl-y`
- ::complete: `true`: **Overridden**
- ::rowTransration: `-1`
- ::getTextInScreenRange`(range)`
- ::execute`()`

### CopyFromLineBelow < CopyFromLineAbove
- ::rowTransration: `1`: **Overridden**

### InsertRegister < InsertMode
- keymaps
  - atom-text-editor.vim-mode.insert-mode: `ctrl-r`
- ::constructor`()`: `super`: **Overridden**
- ::execute`()`

### Motion < Base
- ::constructor`(@vimState)`: **Overridden**
- ::complete: `true`: **Overridden**
- ::recordable: `false`
- ::operatesInclusively: `true`
- ::operatesLinewise: `false`
- ::select`(options)`
- ::execute`()`
- ::moveSelectionLinewise`(selection, options)`
- ::moveSelectionInclusively`(selection, options)`
- ::moveSelection`(selection, options)`
- ::isLinewise`()`
- ::isInclusive`()`
- ::getInput`()`

### Find < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `f`
- ::constructor`()`: `super`: **Overridden**
- ::backwards: `false`
- ::complete: `false`: **Overridden**
- ::repeated: `false`
- ::reverse: `false`
- ::offset: `0`
- ::match`(cursor, count)`
- ::moveCursor`(cursor)`

### FindBackwards < Find
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-F`
- ::backwards: `true`: **Overridden**

### RepeatFind < Find
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `;`
- ::constructor`()`: `super`: **Overridden**
- ::repeated: `true`: **Overridden**
- ::reverse: `false`: **Overridden**
- ::offset: `0`: **Overridden**
- ::moveCursor`()`: **Overridden**

### RepeatFindReverse < RepeatFind
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `,`
- ::constructor`()`: `super`: **Overridden**
- ::reverse: `true`: **Overridden**

### Till < Find
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `t`
- ::offset: `1`: **Overridden**
- ::match`()`: `super`: **Overridden**
- ::moveSelectionInclusively`(selection, options)`: `super`: **Overridden**

### TillBackwards < Till
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-T`
- ::backwards: `true`: **Overridden**

### MoveDown < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `j`
  - atom-text-editor.vim-mode:not(.insert-mode): `down`
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveLeft < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `h`
  - atom-text-editor.vim-mode:not(.insert-mode): `left`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveRight < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `l`
  - atom-text-editor.vim-mode:not(.insert-mode): `space`
  - atom-text-editor.vim-mode:not(.insert-mode): `right`
- ::operatesInclusively: `false`: **Overridden**
- ::composed: `false`
- ::onDidComposeBy`(operation)`
- ::isOperatorPending`()`
- ::moveCursor`(cursor)`

### MoveToBeginningOfLine < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `0`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToEndOfWord < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `e`
- ::wordRegex: `null`
- ::moveCursor`(cursor)`

### MoveToEndOfWholeWord < MoveToEndOfWord
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-E`
- ::wordRegex: `/\S+/`: **Overridden**

### MoveToFirstCharacterOfLine < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `^`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineAndDown < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `_`
- ::operatesLinewise: `true`: **Overridden**
- ::operatesInclusively: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineDown < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `+`
  - atom-text-editor.vim-mode:not(.insert-mode): `enter`
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineUp < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `-`
- ::operatesLinewise: `true`: **Overridden**
- ::operatesInclusively: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToLastCharacterOfLine < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `$`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToLastNonblankCharacterOfLineAndDown < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `g _`
- ::operatesInclusively: `true`: **Overridden**
- ::skipTrailingWhitespace`(cursor)`
- ::moveCursor`(cursor)`

### MoveToLineBase < Motion
*Not exported*

### MoveToLine < MoveToLineBase
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-G`
- ::moveCursor`(cursor)`

### MoveToRelativeLine < MoveToLineBase
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToScreenLine < MoveToLineBase
*Not exported*

### MoveToBottomOfScreen < MoveToScreenLine
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-L`
- ::getDestinationRow`()`: **Overridden**

### MoveToMiddleOfScreen < MoveToScreenLine
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-M`
- ::getDestinationRow`()`: **Overridden**

### MoveToTopOfScreen < MoveToScreenLine
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-H`
- ::getDestinationRow`()`: **Overridden**

### MoveToStartOfFile < MoveToLineBase
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `g g`
- ::moveCursor`(cursor)`

### ScrollKeepingCursor < MoveToLineBase
*Not exported*

### ScrollFullScreenUp < ScrollKeepingCursor
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `ctrl-b`
- ::direction: `'up'`: **Overridden**
- ::getAmountInPixel`()`

### ScrollFullScreenDown < ScrollFullScreenUp
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `ctrl-f`
- ::direction: `'down'`: **Overridden**

### ScrollHalfScreenUp < ScrollKeepingCursor
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `ctrl-u`
- ::direction: `'up'`: **Overridden**
- ::getAmountInPixel`()`

### ScrollHalfScreenDown < ScrollHalfScreenUp
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `ctrl-d`
- ::direction: `'down'`: **Overridden**

### MoveToMark < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `'`
- ::constructor`()`: `super`: **Overridden**
- ::operatesInclusively: `false`: **Overridden**
- ::operatesLinewise: `true`: **Overridden**
- ::complete: `false`: **Overridden**
- ::isLinewise`()`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToMarkLiteral < MoveToMark
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): ```
- ::operatesLinewise: `false`: **Overridden**

### MoveToNextParagraph < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `}`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToNextWord < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `w`
- ::wordRegex: `null`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor, options)`
- ::isEndOfFile`(cursor)`

### MoveToNextWholeWord < MoveToNextWord
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-W`
- ::wordRegex: `/^\s*$|\S+/`: **Overridden**

### MoveToPreviousParagraph < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `{`
- ::moveCursor`(cursor)`

### MoveToPreviousWholeWord < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-B`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`
- ::isWholeWord`(cursor)`
- ::isBeginningOfFile`(cursor)`

### MoveToPreviousWord < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `b`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveUp < Motion
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `k`
  - atom-text-editor.vim-mode:not(.insert-mode): `up`
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### SearchBase < Motion
*Not exported*

### BracketMatchingMotion < SearchBase
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `%`
- ::operatesInclusively: `true`: **Overridden**
- ::complete: `true`: **Overridden**
- ::searchForMatch`(startPosition, reverse, inCharacter, outCharacter)`
- ::characterAt`(position)`
- ::getSearchData`(position)`
- ::moveCursor`(cursor)`: **Overridden**

### RepeatSearch < SearchBase
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `n`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**
- ::dontUpdateCurrentSearch: `true`: **Overridden**
- ::reversed`()`: **Overridden**

### RepeatSearchBackwards < RepeatSearch
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-N`
- ::constructor`()`: `super`: **Overridden**

### Search < SearchBase
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `/`
- ::constructor`()`: `super`: **Overridden**
- ::getInput`()`: **Overridden**

### ReverseSearch < Search
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `?`
- ::constructor`()`: `super`: **Overridden**

### SearchCurrentWord < SearchBase
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `*`
- @keywordRegex: `null`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**
- ::getCurrentWord`()`
- ::cursorIsOnEOF`(cursor)`
- ::getCurrentWordMatch`()`
- ::execute`()`: `super()`: **Overridden**

### ReverseSearchCurrentWord < SearchCurrentWord
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `#`
- @keywordRegex: `null`
- ::constructor`()`: `super`: **Overridden**

### MotionError < Base
- ::constructor`(@message)`: **Overridden**

### Operator < Base
- ::constructor`(@vimState)`: **Overridden**
- ::target: `null`
- ::complete: `false`: **Overridden**
- ::recodable: `true`: **Overridden**
- ::compose`(@target)`
- ::canComposeWith`(operation)`
- ::setTextToRegister`(register, text)`
- ::getInput`()`
- ::getRegisterName`()`

### AdjustIndentation < Operator
*Not exported*

### AutoIndent < AdjustIndentation
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `=`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `=`
- ::indent`()`

### Indent < AdjustIndentation
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `>`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `>`
- ::indent`()`

### Outdent < AdjustIndentation
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `<`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `<`
- ::indent`()`

### Delete < Operator
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `d`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `d`
  - atom-text-editor.vim-mode.visual-mode: `x`
- ::execute`()`

### DeleteLeft < Delete
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `shift-X`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### DeleteRight < Delete
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `x`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### DeleteToLastCharacterOfLine < Delete
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-D`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### Increase < Operator
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `ctrl-a`
- ::constructor`()`: `super`: **Overridden**
- ::step: `1`
- ::complete: `true`: **Overridden**
- ::execute`()`
- ::increaseNumber`(cursor)`

### Decrease < Increase
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `ctrl-x`
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
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `c`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `c`
  - atom-text-editor.vim-mode.visual-mode: `s`
- ::complete: `false`: **Overridden**
- ::execute`()`: `super`: **Overridden**

### ChangeToLastCharacterOfLine < Change
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-C`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### Substitute < Change
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `s`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### SubstituteLine < Change
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-S`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### InsertAboveWithNewline < Insert
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `shift-O`
- ::execute`()`: `super`: **Overridden**

### InsertAfter < Insert
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `a`
- ::execute`()`: `super`: **Overridden**

### InsertAfterEndOfLine < Insert
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `shift-A`
- ::execute`()`: `super`: **Overridden**

### InsertAtBeginningOfLine < Insert
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-I`
- ::execute`()`: `super`: **Overridden**

### InsertBelowWithNewline < Insert
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `o`
- ::execute`()`: `super`: **Overridden**

### ReplaceMode < Insert
- ::execute`()`: **Overridden**
- ::countChars`(char, string)`

### ReplaceMode < Insert
- ::execute`()`: **Overridden**
- ::countChars`(char, string)`

### Join < Operator
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-J`
- ::complete: `true`: **Overridden**
- ::execute`()`

### LowerCase < Operator
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `g u`
  - atom-text-editor.vim-mode.visual-mode: `u`
- ::execute`()`

### Mark < Operator
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `m`
- ::constructor`()`: `super`: **Overridden**
- ::execute`()`

### Put < Operator
*Not exported*

### PutAfter < Put
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `p`
- ::location: `'after'`

### PutBefore < Put
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-P`
- ::location: `'before'`

### Repeat < Operator
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `.`
- ::complete: `true`: **Overridden**
- ::recodable: `false`: **Overridden**
- ::execute`()`

### Replace < Operator
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `r`
- ::constructor`()`: `super`: **Overridden**
- ::input: `null`
- ::isComplete`()`: **Overridden**
- ::execute`()`

### Select < Operator
- ::execute`()`

### ToggleCase < Operator
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `g ~`
- ::execute`()`

### ToggleCaseNow < ToggleCase
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `~`
- ::complete: `true`: **Overridden**

### UpperCase < Operator
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `g shift-U`
  - atom-text-editor.vim-mode.visual-mode: `shift-U`
- ::execute`()`

### Yank < Operator
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `y`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `y`
  - atom-text-editor.vim-mode.visual-mode: `cmd-c`
- ::execute`()`

### YankLine < Yank
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `shift-Y`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### OperatorError < Base
- ::constructor`(@message)`: **Overridden**

### Scroll < Base
*Not exported*

### ScrollCursor < Scroll
*Not exported*

### ScrollCursorToBottom < ScrollCursor
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `z -`
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToBottomLeave < ScrollCursorToBottom
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `z b`
- ::moveToFirstCharacterOfLine: `null`: **Overridden**

### ScrollCursorToMiddle < ScrollCursor
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `z .`
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToMiddleLeave < ScrollCursorToMiddle
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `z z`
- ::moveToFirstCharacterOfLine: `null`: **Overridden**

### ScrollCursorToTop < ScrollCursor
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `z enter`
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToTopLeave < ScrollCursorToTop
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `z t`
- ::moveToFirstCharacterOfLine: `null`: **Overridden**

### ScrollDown < Scroll
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `ctrl-e`
- ::direction: `'down'`
- ::execute`()`
- ::keepCursorOnScreen`()`

### ScrollUp < ScrollDown
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `ctrl-y`
- ::direction: `'up'`: **Overridden**

### ScrollHorizontal < Scroll
*Not exported*

### ScrollCursorToLeft < ScrollHorizontal
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `z s`
- ::execute`()`

### ScrollCursorToRight < ScrollHorizontal
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `z e`
- ::execute`()`

### TextObject < Base
- ::constructor`(@vimState)`: **Overridden**
- ::complete: `true`: **Overridden**
- ::recodable: `false`: **Overridden**

### CurrentSelection < TextObject
- ::select`()`

### SelectAWholeWord < TextObject
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a shift-W`
- ::select`()`

### SelectAWord < TextObject
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a w`
- ::select`()`

### SelectAroundParagraph < TextObject
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a p`
- ::select`()`

### SelectInsideBrackets < TextObject
- ::beginChar: `null`
- ::endChar: `null`
- ::includeBrackets: `false`
- ::findOpeningBracket`(pos)`
- ::findClosingBracket`(start)`
- ::select`()`

### SelectInsideAngleBrackets < SelectInsideBrackets
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i <`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i >`
- ::beginChar: `'<'`: **Overridden**
- ::endChar: `'>'`: **Overridden**

### SelectAroundAngleBrackets < SelectInsideAngleBrackets
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a <`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a >`
- ::includeBrackets: `true`: **Overridden**

### SelectInsideCurlyBrackets < SelectInsideBrackets
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i {`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i }`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i shift-B`
- ::beginChar: `'{'`: **Overridden**
- ::endChar: `'}'`: **Overridden**

### SelectAroundCurlyBrackets < SelectInsideCurlyBrackets
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a {`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a }`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a shift-B`
- ::includeBrackets: `true`: **Overridden**

### SelectInsideParentheses < SelectInsideBrackets
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i (`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i )`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i b`
- ::beginChar: `'('`: **Overridden**
- ::endChar: `')'`: **Overridden**

### SelectAroundParentheses < SelectInsideParentheses
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a (`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a )`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a b`
- ::includeBrackets: `true`: **Overridden**

### SelectInsideSquareBrackets < SelectInsideBrackets
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i [`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i ]`
- ::beginChar: `'['`: **Overridden**
- ::endChar: `']'`: **Overridden**

### SelectAroundSquareBrackets < SelectInsideSquareBrackets
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a [`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a ]`
- ::includeBrackets: `true`: **Overridden**

### SelectInsideTags < SelectInsideBrackets
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i t`
- ::beginChar: `'>'`: **Overridden**
- ::endChar: `'<'`: **Overridden**

### SelectAroundTags < SelectInsideTags
- ::includeBrackets: `true`: **Overridden**

### SelectInsideParagraph < TextObject
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i p`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `cmd-l`
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
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i ``
- ::char: `'`'`: **Overridden**

### SelectAroundBackTicks < SelectInsideBackTicks
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a ``
- ::includeQuotes: `true`: **Overridden**

### SelectInsideDoubleQuotes < SelectInsideQuotes
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i "`
- ::char: `'"'`: **Overridden**

### SelectAroundDoubleQuotes < SelectInsideDoubleQuotes
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a "`
- ::includeQuotes: `true`: **Overridden**

### SelectInsideSingleQuotes < SelectInsideQuotes
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i '`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `'`
- ::char: `'\''`: **Overridden**

### SelectAroundSingleQuotes < SelectInsideSingleQuotes
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a '`
- ::includeQuotes: `true`: **Overridden**

### SelectInsideWholeWord < TextObject
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i shift-W`
- ::select`()`

### SelectInsideWord < TextObject
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i w`
- ::select`()
