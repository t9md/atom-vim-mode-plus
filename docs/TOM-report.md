# TOM(TextObject, Operator, Motion) report.

vim-mode version: 0.57.0  
*generated at 2015-08-16T05:19:53.389Z*

- [Base](#base) *Not exported*
  - [InsertMode](#insertmode--base) *Not exported*
    - [CopyFromLineAbove](#copyfromlineabove--insertmode)
      - [CopyFromLineBelow](#copyfromlinebelow--copyfromlineabove)
    - [InsertRegister](#insertregister--insertmode)
  - [Motion](#motion--base) *Not exported*
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
- ::isPure`()`
- ::pure: `false`
- ::isComplete`()`
- ::complete: `null`
- ::isRecordable`()`
- ::recodable: `null`
- ::getKind`()`
- ::getCount`(defaultCount)`
- ::isMotionError`()`
- ::isMotion`()`
- ::isMoveLeft`()`
- ::isMoveRight`()`
- ::isMoveUp`()`
- ::isMoveDown`()`
- ::isMoveToPreviousWord`()`
- ::isMoveToPreviousWholeWord`()`
- ::isMoveToNextWord`()`
- ::isMoveToNextWholeWord`()`
- ::isMoveToEndOfWord`()`
- ::isMoveToEndOfWholeWord`()`
- ::isMoveToNextParagraph`()`
- ::isMoveToPreviousParagraph`()`
- ::isMoveToBeginningOfLine`()`
- ::isMoveToFirstCharacterOfLine`()`
- ::isMoveToFirstCharacterOfLineAndDown`()`
- ::isMoveToLastCharacterOfLine`()`
- ::isMoveToLastNonblankCharacterOfLineAndDown`()`
- ::isMoveToFirstCharacterOfLineUp`()`
- ::isMoveToFirstCharacterOfLineDown`()`
- ::isMoveToLineBase`()`
- ::isMoveToLine`()`
- ::isMoveToStartOfFile`()`
- ::isMoveToRelativeLine`()`
- ::isMoveToScreenLine`()`
- ::isMoveToTopOfScreen`()`
- ::isMoveToBottomOfScreen`()`
- ::isMoveToMiddleOfScreen`()`
- ::isScrollKeepingCursor`()`
- ::isScrollHalfScreenUp`()`
- ::isScrollHalfScreenDown`()`
- ::isScrollFullScreenUp`()`
- ::isScrollFullScreenDown`()`
- ::isFind`()`
- ::isRepeatFind`()`
- ::isRepeatFindReverse`()`
- ::isFindBackwards`()`
- ::isTill`()`
- ::isTillBackwards`()`
- ::isMoveToMark`()`
- ::isMoveToMarkLiteral`()`
- ::isSearchBase`()`
- ::isSearch`()`
- ::isReverseSearch`()`
- ::isSearchCurrentWord`()`
- ::isReverseSearchCurrentWord`()`
- ::isRepeatSearch`()`
- ::isRepeatSearchBackwards`()`
- ::isBracketMatchingMotion`()`
- ::isOperatorError`()`
- ::isOperator`()`
- ::isSelect`()`
- ::isDelete`()`
- ::isDeleteRight`()`
- ::isDeleteLeft`()`
- ::isDeleteToLastCharacterOfLine`()`
- ::isToggleCase`()`
- ::isToggleCaseNow`()`
- ::isUpperCase`()`
- ::isLowerCase`()`
- ::isYank`()`
- ::isYankLine`()`
- ::isJoin`()`
- ::isRepeat`()`
- ::isMark`()`
- ::isIncrease`()`
- ::isDecrease`()`
- ::isAdjustIndentation`()`
- ::isIndent`()`
- ::isOutdent`()`
- ::isAutoIndent`()`
- ::isPut`()`
- ::isPutBefore`()`
- ::isPutAfter`()`
- ::isInsert`()`
- ::isReplaceMode`()`
- ::isInsertAfter`()`
- ::isInsertAfterEndOfLine`()`
- ::isInsertAtBeginningOfLine`()`
- ::isInsertAboveWithNewline`()`
- ::isInsertBelowWithNewline`()`
- ::isChange`()`
- ::isSubstitute`()`
- ::isSubstituteLine`()`
- ::isChangeToLastCharacterOfLine`()`
- ::isReplace`()`
- ::isTextObject`()`
- ::isCurrentSelection`()`
- ::isSelectInsideWord`()`
- ::isSelectAWord`()`
- ::isSelectInsideWholeWord`()`
- ::isSelectAWholeWord`()`
- ::isSelectInsideQuotes`()`
- ::isSelectInsideDoubleQuotes`()`
- ::isSelectAroundDoubleQuotes`()`
- ::isSelectInsideSingleQuotes`()`
- ::isSelectAroundSingleQuotes`()`
- ::isSelectInsideBackTicks`()`
- ::isSelectAroundBackTicks`()`
- ::isSelectInsideBrackets`()`
- ::isSelectInsideCurlyBrackets`()`
- ::isSelectAroundCurlyBrackets`()`
- ::isSelectInsideAngleBrackets`()`
- ::isSelectAroundAngleBrackets`()`
- ::isSelectInsideTags`()`
- ::isSelectAroundTags`()`
- ::isSelectInsideSquareBrackets`()`
- ::isSelectAroundSquareBrackets`()`
- ::isSelectInsideParentheses`()`
- ::isSelectAroundParentheses`()`
- ::isSelectInsideParagraph`()`
- ::isSelectAroundParagraph`()`
- ::isInsertMode`()`
- ::isInsertRegister`()`
- ::isCopyFromLineAbove`()`
- ::isCopyFromLineBelow`()`
- ::isScroll`()`
- ::isScrollDown`()`
- ::isScrollUp`()`
- ::isScrollCursor`()`
- ::isScrollCursorToTop`()`
- ::isScrollCursorToBottom`()`
- ::isScrollCursorToMiddle`()`
- ::isScrollCursorToTopLeave`()`
- ::isScrollCursorToBottomLeave`()`
- ::isScrollCursorToMiddleLeave`()`
- ::isScrollHorizontal`()`
- ::isScrollCursorToLeft`()`
- ::isScrollCursorToRight`()`

### InsertMode < Base
*Not exported*
- ::constructor`(@vimState)`: **Overridden**
- ::complete: `false`: **Overridden**
- ::recodable: `false`: **Overridden**
- ::getInput`()`

### CopyFromLineAbove < InsertMode
- command: `vim-mode:copy-from-line-above`
- keymaps
  - atom-text-editor.vim-mode.insert-mode: `ctrl-y`
- ::complete: `true`: **Overridden**
- ::rowTransration: `-1`
- ::getTextInScreenRange`(range)`
- ::execute`()`

### CopyFromLineBelow < CopyFromLineAbove
- command: `vim-mode:copy-from-line-below`
- ::rowTransration: `1`: **Overridden**

### InsertRegister < InsertMode
- command: `vim-mode:insert-register`
- keymaps
  - atom-text-editor.vim-mode.insert-mode: `ctrl-r`
- ::constructor`()`: `super`: **Overridden**
- ::execute`()`

### Motion < Base
*Not exported*
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
- command: `vim-mode:find`
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
- command: `vim-mode:find-backwards`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `F`
- ::backwards: `true`: **Overridden**

### RepeatFind < Find
- command: `vim-mode:repeat-find`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `;`
- ::constructor`()`: `super`: **Overridden**
- ::repeated: `true`: **Overridden**
- ::reverse: `false`: **Overridden**
- ::offset: `0`: **Overridden**
- ::moveCursor`()`: **Overridden**

### RepeatFindReverse < RepeatFind
- command: `vim-mode:repeat-find-reverse`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `,`
- ::constructor`()`: `super`: **Overridden**
- ::reverse: `true`: **Overridden**

### Till < Find
- command: `vim-mode:till`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `t`
- ::offset: `1`: **Overridden**
- ::match`()`: `super`: **Overridden**
- ::moveSelectionInclusively`(selection, options)`: `super`: **Overridden**

### TillBackwards < Till
- command: `vim-mode:till-backwards`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `T`
- ::backwards: `true`: **Overridden**

### MoveDown < Motion
- command: `vim-mode:move-down`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `j`
  - atom-text-editor.vim-mode:not(.insert-mode): `down`
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveLeft < Motion
- command: `vim-mode:move-left`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `h`
  - atom-text-editor.vim-mode:not(.insert-mode): `left`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveRight < Motion
- command: `vim-mode:move-right`
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
- command: `vim-mode:move-to-beginning-of-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `0`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToEndOfWord < Motion
- command: `vim-mode:move-to-end-of-word`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `e`
- ::wordRegex: `null`
- ::moveCursor`(cursor)`

### MoveToEndOfWholeWord < MoveToEndOfWord
- command: `vim-mode:move-to-end-of-whole-word`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `E`
- ::wordRegex: `/\S+/`: **Overridden**

### MoveToFirstCharacterOfLine < Motion
- command: `vim-mode:move-to-first-character-of-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `^`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineAndDown < Motion
- command: `vim-mode:move-to-first-character-of-line-and-down`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `_`
- ::operatesLinewise: `true`: **Overridden**
- ::operatesInclusively: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineDown < Motion
- command: `vim-mode:move-to-first-character-of-line-down`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `+`
  - atom-text-editor.vim-mode:not(.insert-mode): `enter`
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineUp < Motion
- command: `vim-mode:move-to-first-character-of-line-up`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `-`
- ::operatesLinewise: `true`: **Overridden**
- ::operatesInclusively: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToLastCharacterOfLine < Motion
- command: `vim-mode:move-to-last-character-of-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `$`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToLastNonblankCharacterOfLineAndDown < Motion
- command: `vim-mode:move-to-last-nonblank-character-of-line-and-down`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `g _`
- ::operatesInclusively: `true`: **Overridden**
- ::skipTrailingWhitespace`(cursor)`
- ::moveCursor`(cursor)`

### MoveToLineBase < Motion
*Not exported*
- ::operatesLinewise: `true`: **Overridden**
- ::getDestinationRow`(count)`

### MoveToLine < MoveToLineBase
- command: `vim-mode:move-to-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `G`
- ::moveCursor`(cursor)`

### MoveToRelativeLine < MoveToLineBase
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToScreenLine < MoveToLineBase
*Not exported*
- ::scrolloff: `2`
- ::moveCursor`(cursor)`

### MoveToBottomOfScreen < MoveToScreenLine
- command: `vim-mode:move-to-bottom-of-screen`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `L`
- ::getDestinationRow`()`: **Overridden**

### MoveToMiddleOfScreen < MoveToScreenLine
- command: `vim-mode:move-to-middle-of-screen`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `M`
- ::getDestinationRow`()`: **Overridden**

### MoveToTopOfScreen < MoveToScreenLine
- command: `vim-mode:move-to-top-of-screen`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `H`
- ::getDestinationRow`()`: **Overridden**

### MoveToStartOfFile < MoveToLineBase
- command: `vim-mode:move-to-start-of-file`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `g g`
- ::moveCursor`(cursor)`

### ScrollKeepingCursor < MoveToLineBase
*Not exported*
- ::previousFirstScreenRow: `0`
- ::currentFirstScreenRow: `0`
- ::direction: `null`
- ::select`(options)`: `super(options)`: **Overridden**
- ::execute`()`: `super`: **Overridden**
- ::moveCursor`(cursor)`
- ::getDestinationRow`()`: **Overridden**
- ::scrollScreen`()`
- ::getHalfScreenPixel`()`

### ScrollFullScreenUp < ScrollKeepingCursor
- command: `vim-mode:scroll-full-screen-up`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `ctrl-b`
- ::direction: `'up'`: **Overridden**
- ::getAmountInPixel`()`

### ScrollFullScreenDown < ScrollFullScreenUp
- command: `vim-mode:scroll-full-screen-down`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `ctrl-f`
- ::direction: `'down'`: **Overridden**

### ScrollHalfScreenUp < ScrollKeepingCursor
- command: `vim-mode:scroll-half-screen-up`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `ctrl-u`
- ::direction: `'up'`: **Overridden**
- ::getAmountInPixel`()`

### ScrollHalfScreenDown < ScrollHalfScreenUp
- command: `vim-mode:scroll-half-screen-down`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `ctrl-d`
- ::direction: `'down'`: **Overridden**

### MoveToMark < Motion
- command: `vim-mode:move-to-mark`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `'`
- ::constructor`()`: `super`: **Overridden**
- ::operatesInclusively: `false`: **Overridden**
- ::operatesLinewise: `true`: **Overridden**
- ::complete: `false`: **Overridden**
- ::isLinewise`()`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToMarkLiteral < MoveToMark
- command: `vim-mode:move-to-mark-literal`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): ```
- ::operatesLinewise: `false`: **Overridden**

### MoveToNextParagraph < Motion
- command: `vim-mode:move-to-next-paragraph`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `}`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToNextWord < Motion
- command: `vim-mode:move-to-next-word`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `w`
- ::wordRegex: `null`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor, options)`
- ::isEndOfFile`(cursor)`

### MoveToNextWholeWord < MoveToNextWord
- command: `vim-mode:move-to-next-whole-word`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `W`
- ::wordRegex: `/^\s*$|\S+/`: **Overridden**

### MoveToPreviousParagraph < Motion
- command: `vim-mode:move-to-previous-paragraph`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `{`
- ::moveCursor`(cursor)`

### MoveToPreviousWholeWord < Motion
- command: `vim-mode:move-to-previous-whole-word`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `B`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`
- ::isWholeWord`(cursor)`
- ::isBeginningOfFile`(cursor)`

### MoveToPreviousWord < Motion
- command: `vim-mode:move-to-previous-word`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `b`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveUp < Motion
- command: `vim-mode:move-up`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `k`
  - atom-text-editor.vim-mode:not(.insert-mode): `up`
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### SearchBase < Motion
*Not exported*
- ::constructor`()`: `super`: **Overridden**
- ::operatesInclusively: `false`: **Overridden**
- ::dontUpdateCurrentSearch: `false`
- ::complete: `false`: **Overridden**
- ::reversed`()`
- ::moveCursor`(cursor)`
- ::scan`(cursor)`
- ::getSearchTerm`(term)`
- ::updateCurrentSearch`()`
- ::replicateCurrentSearch`()`

### BracketMatchingMotion < SearchBase
- command: `vim-mode:bracket-matching-motion`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `%`
- ::operatesInclusively: `true`: **Overridden**
- ::complete: `true`: **Overridden**
- ::searchForMatch`(startPosition, reverse, inCharacter, outCharacter)`
- ::characterAt`(position)`
- ::getSearchData`(position)`
- ::moveCursor`(cursor)`: **Overridden**

### RepeatSearch < SearchBase
- command: `vim-mode:repeat-search`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `n`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**
- ::dontUpdateCurrentSearch: `true`: **Overridden**
- ::reversed`()`: **Overridden**

### RepeatSearchBackwards < RepeatSearch
- command: `vim-mode:repeat-search-backwards`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `N`
- ::constructor`()`: `super`: **Overridden**

### Search < SearchBase
- command: `vim-mode:search`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `/`
- ::constructor`()`: `super`: **Overridden**
- ::getInput`()`: **Overridden**

### ReverseSearch < Search
- command: `vim-mode:reverse-search`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `?`
- ::constructor`()`: `super`: **Overridden**

### SearchCurrentWord < SearchBase
- command: `vim-mode:search-current-word`
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
- command: `vim-mode:reverse-search-current-word`
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
- ::execute`()`

### AutoIndent < AdjustIndentation
- command: `vim-mode:auto-indent`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `=`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `=`
- ::indent`()`

### Indent < AdjustIndentation
- command: `vim-mode:indent`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `>`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `>`
- ::indent`()`

### Outdent < AdjustIndentation
- command: `vim-mode:outdent`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `<`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `<`
- ::indent`()`

### Delete < Operator
- command: `vim-mode:delete`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `d`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `d`
  - atom-text-editor.vim-mode.visual-mode: `x`
- ::execute`()`

### DeleteLeft < Delete
- command: `vim-mode:delete-left`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `X`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### DeleteRight < Delete
- command: `vim-mode:delete-right`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `x`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### DeleteToLastCharacterOfLine < Delete
- command: `vim-mode:delete-to-last-character-of-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `D`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### Increase < Operator
- command: `vim-mode:increase`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `ctrl-a`
- ::constructor`()`: `super`: **Overridden**
- ::step: `1`
- ::complete: `true`: **Overridden**
- ::execute`()`
- ::increaseNumber`(cursor)`

### Decrease < Increase
- command: `vim-mode:decrease`
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
- command: `vim-mode:change`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `c`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `c`
  - atom-text-editor.vim-mode.visual-mode: `s`
- ::complete: `false`: **Overridden**
- ::execute`()`: `super`: **Overridden**

### ChangeToLastCharacterOfLine < Change
- command: `vim-mode:change-to-last-character-of-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `C`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### Substitute < Change
- command: `vim-mode:substitute`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `s`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### SubstituteLine < Change
- command: `vim-mode:substitute-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `S`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### InsertAboveWithNewline < Insert
- command: `vim-mode:insert-above-with-newline`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `O`
- ::execute`()`: `super`: **Overridden**

### InsertAfter < Insert
- command: `vim-mode:insert-after`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `a`
- ::execute`()`: `super`: **Overridden**

### InsertAfterEndOfLine < Insert
- command: `vim-mode:insert-after-end-of-line`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `A`
- ::execute`()`: `super`: **Overridden**

### InsertAtBeginningOfLine < Insert
- command: `vim-mode:insert-at-beginning-of-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `I`
- ::execute`()`: `super`: **Overridden**

### InsertBelowWithNewline < Insert
- command: `vim-mode:insert-below-with-newline`
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
- command: `vim-mode:join`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `J`
- ::complete: `true`: **Overridden**
- ::execute`()`

### LowerCase < Operator
- command: `vim-mode:lower-case`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `g u`
  - atom-text-editor.vim-mode.visual-mode: `u`
- ::execute`()`

### Mark < Operator
- command: `vim-mode:mark`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `m`
- ::constructor`()`: `super`: **Overridden**
- ::execute`()`

### Put < Operator
*Not exported*
- ::register: `null`
- ::complete: `true`: **Overridden**
- ::execute`()`
- ::onLastRow`()`
- ::onLastColumn`()`

### PutAfter < Put
- command: `vim-mode:put-after`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `p`
- ::location: `'after'`

### PutBefore < Put
- command: `vim-mode:put-before`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `P`
- ::location: `'before'`

### Repeat < Operator
- command: `vim-mode:repeat`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: `.`
- ::complete: `true`: **Overridden**
- ::recodable: `false`: **Overridden**
- ::execute`()`

### Replace < Operator
- command: `vim-mode:replace`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `r`
- ::constructor`()`: `super`: **Overridden**
- ::input: `null`
- ::isComplete`()`: **Overridden**
- ::execute`()`

### Select < Operator
- ::execute`()`

### ToggleCase < Operator
- command: `vim-mode:toggle-case`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `g ~`
- ::execute`()`

### ToggleCaseNow < ToggleCase
- command: `vim-mode:toggle-case-now`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `~`
- ::complete: `true`: **Overridden**

### UpperCase < Operator
- command: `vim-mode:upper-case`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `g shift-U`
  - atom-text-editor.vim-mode.visual-mode: `U`
- ::execute`()`

### Yank < Operator
- command: `vim-mode:yank`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `y`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `y`
- ::execute`()`

### YankLine < Yank
- command: `vim-mode:yank-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `Y`
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### OperatorError < Base
- ::constructor`(@message)`: **Overridden**

### Scroll < Base
*Not exported*
- ::constructor`(@vimState)`: **Overridden**
- ::complete: `true`: **Overridden**
- ::recodable: `false`: **Overridden**
- ::scrolloff: `2`
- ::getFirstVisibleScreenRow`()`
- ::getLastVisibleScreenRow`()`
- ::getLastScreenRow`()`
- ::getPixelCursor`(which)`

### ScrollCursor < Scroll
*Not exported*
- ::execute`()`
- ::moveToFirstCharacterOfLine`()`
- ::getOffSetPixelHeight`(lineDelta)`

### ScrollCursorToBottom < ScrollCursor
- command: `vim-mode:scroll-cursor-to-bottom`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `z -`
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToBottomLeave < ScrollCursorToBottom
- command: `vim-mode:scroll-cursor-to-bottom-leave`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `z b`
- ::moveToFirstCharacterOfLine: `null`: **Overridden**

### ScrollCursorToMiddle < ScrollCursor
- command: `vim-mode:scroll-cursor-to-middle`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `z .`
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToMiddleLeave < ScrollCursorToMiddle
- command: `vim-mode:scroll-cursor-to-middle-leave`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `z z`
- ::moveToFirstCharacterOfLine: `null`: **Overridden**

### ScrollCursorToTop < ScrollCursor
- command: `vim-mode:scroll-cursor-to-top`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `z enter`
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToTopLeave < ScrollCursorToTop
- command: `vim-mode:scroll-cursor-to-top-leave`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `z t`
- ::moveToFirstCharacterOfLine: `null`: **Overridden**

### ScrollDown < Scroll
- command: `vim-mode:scroll-down`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `ctrl-e`
- ::direction: `'down'`
- ::execute`()`
- ::keepCursorOnScreen`()`

### ScrollUp < ScrollDown
- command: `vim-mode:scroll-up`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `ctrl-y`
- ::direction: `'up'`: **Overridden**

### ScrollHorizontal < Scroll
*Not exported*
- ::putCursorOnScreen`()`

### ScrollCursorToLeft < ScrollHorizontal
- command: `vim-mode:scroll-cursor-to-left`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): `z s`
- ::execute`()`

### ScrollCursorToRight < ScrollHorizontal
- command: `vim-mode:scroll-cursor-to-right`
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
- command: `vim-mode:select-a-whole-word`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a shift-W`
- ::select`()`

### SelectAWord < TextObject
- command: `vim-mode:select-a-word`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a w`
- ::select`()`

### SelectAroundParagraph < TextObject
- command: `vim-mode:select-around-paragraph`
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
- command: `vim-mode:select-inside-angle-brackets`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i <`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i >`
- ::beginChar: `'<'`: **Overridden**
- ::endChar: `'>'`: **Overridden**

### SelectAroundAngleBrackets < SelectInsideAngleBrackets
- command: `vim-mode:select-around-angle-brackets`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a <`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a >`
- ::includeBrackets: `true`: **Overridden**

### SelectInsideCurlyBrackets < SelectInsideBrackets
- command: `vim-mode:select-inside-curly-brackets`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i {`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i }`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i shift-B`
- ::beginChar: `'{'`: **Overridden**
- ::endChar: `'}'`: **Overridden**

### SelectAroundCurlyBrackets < SelectInsideCurlyBrackets
- command: `vim-mode:select-around-curly-brackets`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a {`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a }`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a shift-B`
- ::includeBrackets: `true`: **Overridden**

### SelectInsideParentheses < SelectInsideBrackets
- command: `vim-mode:select-inside-parentheses`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i (`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i )`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i b`
- ::beginChar: `'('`: **Overridden**
- ::endChar: `')'`: **Overridden**

### SelectAroundParentheses < SelectInsideParentheses
- command: `vim-mode:select-around-parentheses`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a (`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a )`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a b`
- ::includeBrackets: `true`: **Overridden**

### SelectInsideSquareBrackets < SelectInsideBrackets
- command: `vim-mode:select-inside-square-brackets`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i [`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i ]`
- ::beginChar: `'['`: **Overridden**
- ::endChar: `']'`: **Overridden**

### SelectAroundSquareBrackets < SelectInsideSquareBrackets
- command: `vim-mode:select-around-square-brackets`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a [`
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a ]`
- ::includeBrackets: `true`: **Overridden**

### SelectInsideTags < SelectInsideBrackets
- command: `vim-mode:select-inside-tags`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i t`
- ::beginChar: `'>'`: **Overridden**
- ::endChar: `'<'`: **Overridden**

### SelectAroundTags < SelectInsideTags
- ::includeBrackets: `true`: **Overridden**

### SelectInsideParagraph < TextObject
- command: `vim-mode:select-inside-paragraph`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i p`
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
- command: `vim-mode:select-inside-back-ticks`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i ``
- ::char: `'`'`: **Overridden**

### SelectAroundBackTicks < SelectInsideBackTicks
- command: `vim-mode:select-around-back-ticks`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a ``
- ::includeQuotes: `true`: **Overridden**

### SelectInsideDoubleQuotes < SelectInsideQuotes
- command: `vim-mode:select-inside-double-quotes`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i "`
- ::char: `'"'`: **Overridden**

### SelectAroundDoubleQuotes < SelectInsideDoubleQuotes
- command: `vim-mode:select-around-double-quotes`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a "`
- ::includeQuotes: `true`: **Overridden**

### SelectInsideSingleQuotes < SelectInsideQuotes
- command: `vim-mode:select-inside-single-quotes`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i '`
- ::char: `'\''`: **Overridden**

### SelectAroundSingleQuotes < SelectInsideSingleQuotes
- command: `vim-mode:select-around-single-quotes`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `a '`
- ::includeQuotes: `true`: **Overridden**

### SelectInsideWholeWord < TextObject
- command: `vim-mode:select-inside-whole-word`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i shift-W`
- ::select`()`

### SelectInsideWord < TextObject
- command: `vim-mode:select-inside-word`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: `i w`
- ::select`()
