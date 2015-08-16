# TOM(TextObject, Operator, Motion) report.

vim-mode version: 0.57.0  
*generated at 2015-08-16T10:19:03.136Z*

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
- ::pure: `false`
- ::complete: `null`
- ::recodable: `null`
- ::isPure`()`
- ::isComplete`()`
- ::isRecordable`()`
- ::abort`()`
- ::getKind`()`
- ::getCount`(defaultCount)`
- ::isOperationAbortedError`()`
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
- ::complete: `false`: **Overridden**
- ::recodable: `false`: **Overridden**
- ::getInput`()`

### CopyFromLineAbove < InsertMode
- command: `vim-mode:copy-from-line-above`
- keymaps
  - atom-text-editor.vim-mode.insert-mode: <kbd>ctrl-y</kbd>
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
  - atom-text-editor.vim-mode.insert-mode: <kbd>ctrl-r</kbd>
- ::constructor`()`: `super`: **Overridden**
- ::execute`()`

### Motion < Base
*Not exported*
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
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>f</kbd>
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
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>F</kbd>
- ::backwards: `true`: **Overridden**

### RepeatFind < Find
- command: `vim-mode:repeat-find`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>;</kbd>
- ::constructor`()`: `super`: **Overridden**
- ::repeated: `true`: **Overridden**
- ::reverse: `false`: **Overridden**
- ::offset: `0`: **Overridden**
- ::moveCursor`()`: **Overridden**

### RepeatFindReverse < RepeatFind
- command: `vim-mode:repeat-find-reverse`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>,</kbd>
- ::constructor`()`: `super`: **Overridden**
- ::reverse: `true`: **Overridden**

### Till < Find
- command: `vim-mode:till`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>t</kbd>
- ::offset: `1`: **Overridden**
- ::match`()`: `super`: **Overridden**
- ::moveSelectionInclusively`(selection, options)`: `super`: **Overridden**

### TillBackwards < Till
- command: `vim-mode:till-backwards`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>T</kbd>
- ::backwards: `true`: **Overridden**

### MoveDown < Motion
- command: `vim-mode:move-down`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>j</kbd>
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>down</kbd>
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveLeft < Motion
- command: `vim-mode:move-left`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>h</kbd>
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>left</kbd>
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveRight < Motion
- command: `vim-mode:move-right`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>l</kbd>
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>space</kbd>
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>right</kbd>
- ::operatesInclusively: `false`: **Overridden**
- ::composed: `false`
- ::onDidComposeBy`(operation)`
- ::isOperatorPending`()`
- ::moveCursor`(cursor)`

### MoveToBeginningOfLine < Motion
- command: `vim-mode:move-to-beginning-of-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>0</kbd>
- ::constructor`()`: `super`: **Overridden**
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToEndOfWord < Motion
- command: `vim-mode:move-to-end-of-word`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>e</kbd>
- ::wordRegex: `null`
- ::moveCursor`(cursor)`

### MoveToEndOfWholeWord < MoveToEndOfWord
- command: `vim-mode:move-to-end-of-whole-word`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>E</kbd>
- ::wordRegex: `/\S+/`: **Overridden**

### MoveToFirstCharacterOfLine < Motion
- command: `vim-mode:move-to-first-character-of-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>^</kbd>
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineAndDown < Motion
- command: `vim-mode:move-to-first-character-of-line-and-down`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>\_</kbd>
- ::operatesLinewise: `true`: **Overridden**
- ::operatesInclusively: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineDown < Motion
- command: `vim-mode:move-to-first-character-of-line-down`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>+</kbd>
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>enter</kbd>
- ::operatesLinewise: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineUp < Motion
- command: `vim-mode:move-to-first-character-of-line-up`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>-</kbd>
- ::operatesLinewise: `true`: **Overridden**
- ::operatesInclusively: `true`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToLastCharacterOfLine < Motion
- command: `vim-mode:move-to-last-character-of-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>$</kbd>
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToLastNonblankCharacterOfLineAndDown < Motion
- command: `vim-mode:move-to-last-nonblank-character-of-line-and-down`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>g \_</kbd>
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
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>G</kbd>
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
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>L</kbd>
- ::getDestinationRow`()`: **Overridden**

### MoveToMiddleOfScreen < MoveToScreenLine
- command: `vim-mode:move-to-middle-of-screen`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>M</kbd>
- ::getDestinationRow`()`: **Overridden**

### MoveToTopOfScreen < MoveToScreenLine
- command: `vim-mode:move-to-top-of-screen`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>H</kbd>
- ::getDestinationRow`()`: **Overridden**

### MoveToStartOfFile < MoveToLineBase
- command: `vim-mode:move-to-start-of-file`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>g g</kbd>
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
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>ctrl-b</kbd>
- ::direction: `'up'`: **Overridden**
- ::getAmountInPixel`()`

### ScrollFullScreenDown < ScrollFullScreenUp
- command: `vim-mode:scroll-full-screen-down`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>ctrl-f</kbd>
- ::direction: `'down'`: **Overridden**

### ScrollHalfScreenUp < ScrollKeepingCursor
- command: `vim-mode:scroll-half-screen-up`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>ctrl-u</kbd>
- ::direction: `'up'`: **Overridden**
- ::getAmountInPixel`()`

### ScrollHalfScreenDown < ScrollHalfScreenUp
- command: `vim-mode:scroll-half-screen-down`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>ctrl-d</kbd>
- ::direction: `'down'`: **Overridden**

### MoveToMark < Motion
- command: `vim-mode:move-to-mark`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>'</kbd>
- ::constructor`()`: `super`: **Overridden**
- ::operatesInclusively: `false`: **Overridden**
- ::operatesLinewise: `true`: **Overridden**
- ::complete: `false`: **Overridden**
- ::isLinewise`()`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToMarkLiteral < MoveToMark
- command: `vim-mode:move-to-mark-literal`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>`</kbd>
- ::operatesLinewise: `false`: **Overridden**

### MoveToNextParagraph < Motion
- command: `vim-mode:move-to-next-paragraph`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>}</kbd>
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToNextWord < Motion
- command: `vim-mode:move-to-next-word`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>w</kbd>
- ::wordRegex: `null`
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor, options)`
- ::isEndOfFile`(cursor)`

### MoveToNextWholeWord < MoveToNextWord
- command: `vim-mode:move-to-next-whole-word`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>W</kbd>
- ::wordRegex: `/^\s*$|\S+/`: **Overridden**

### MoveToPreviousParagraph < Motion
- command: `vim-mode:move-to-previous-paragraph`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>{</kbd>
- ::moveCursor`(cursor)`

### MoveToPreviousWholeWord < Motion
- command: `vim-mode:move-to-previous-whole-word`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>B</kbd>
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`
- ::isWholeWord`(cursor)`
- ::isBeginningOfFile`(cursor)`

### MoveToPreviousWord < Motion
- command: `vim-mode:move-to-previous-word`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>b</kbd>
- ::operatesInclusively: `false`: **Overridden**
- ::moveCursor`(cursor)`

### MoveUp < Motion
- command: `vim-mode:move-up`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>k</kbd>
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>up</kbd>
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
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>%</kbd>
- ::operatesInclusively: `true`: **Overridden**
- ::complete: `true`: **Overridden**
- ::searchForMatch`(startPosition, reverse, inCharacter, outCharacter)`
- ::characterAt`(position)`
- ::getSearchData`(position)`
- ::moveCursor`(cursor)`: **Overridden**

### RepeatSearch < SearchBase
- command: `vim-mode:repeat-search`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>n</kbd>
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**
- ::dontUpdateCurrentSearch: `true`: **Overridden**
- ::reversed`()`: **Overridden**

### RepeatSearchBackwards < RepeatSearch
- command: `vim-mode:repeat-search-backwards`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>N</kbd>
- ::constructor`()`: `super`: **Overridden**

### Search < SearchBase
- command: `vim-mode:search`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>/</kbd>
- ::constructor`()`: `super`: **Overridden**
- ::getInput`()`: **Overridden**

### ReverseSearch < Search
- command: `vim-mode:reverse-search`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>?</kbd>
- ::constructor`()`: `super`: **Overridden**

### SearchCurrentWord < SearchBase
- command: `vim-mode:search-current-word`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>*</kbd>
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
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>#</kbd>
- @keywordRegex: `null`
- ::constructor`()`: `super`: **Overridden**

### MotionError < Base
- ::constructor`(@message)`: **Overridden**

### Operator < Base
- ::constructor`()`: `super`: **Overridden**
- ::target: `null`
- ::complete: `false`: **Overridden**
- ::recodable: `true`: **Overridden**
- ::lineWiseAlias: `false`
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
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>=</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>=</kbd>
- ::lineWiseAlias: `true`: **Overridden**
- ::indent`()`

### Indent < AdjustIndentation
- command: `vim-mode:indent`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>></kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>></kbd>
- ::lineWiseAlias: `true`: **Overridden**
- ::indent`()`

### Outdent < AdjustIndentation
- command: `vim-mode:outdent`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd><</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd><</kbd>
- ::lineWiseAlias: `true`: **Overridden**
- ::indent`()`

### Delete < Operator
- command: `vim-mode:delete`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>d</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>d</kbd>
  - atom-text-editor.vim-mode.visual-mode: <kbd>x</kbd>
- ::lineWiseAlias: `true`: **Overridden**
- ::execute`()`

### DeleteLeft < Delete
- command: `vim-mode:delete-left`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: <kbd>X</kbd>
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### DeleteRight < Delete
- command: `vim-mode:delete-right`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: <kbd>x</kbd>
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### DeleteToLastCharacterOfLine < Delete
- command: `vim-mode:delete-to-last-character-of-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>D</kbd>
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### Increase < Operator
- command: `vim-mode:increase`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: <kbd>ctrl-a</kbd>
- ::constructor`()`: `super`: **Overridden**
- ::step: `1`
- ::complete: `true`: **Overridden**
- ::execute`()`
- ::increaseNumber`(cursor)`

### Decrease < Increase
- command: `vim-mode:decrease`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: <kbd>ctrl-x</kbd>
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
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>c</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>c</kbd>
  - atom-text-editor.vim-mode.visual-mode: <kbd>s</kbd>
- ::complete: `false`: **Overridden**
- ::lineWiseAlias: `true`: **Overridden**
- ::execute`()`: `super`: **Overridden**

### ChangeToLastCharacterOfLine < Change
- command: `vim-mode:change-to-last-character-of-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>C</kbd>
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### Substitute < Change
- command: `vim-mode:substitute`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: <kbd>s</kbd>
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### SubstituteLine < Change
- command: `vim-mode:substitute-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>S</kbd>
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### InsertAboveWithNewline < Insert
- command: `vim-mode:insert-above-with-newline`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: <kbd>O</kbd>
- ::execute`()`: `super`: **Overridden**

### InsertAfter < Insert
- command: `vim-mode:insert-after`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: <kbd>a</kbd>
- ::execute`()`: `super`: **Overridden**

### InsertAfterEndOfLine < Insert
- command: `vim-mode:insert-after-end-of-line`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: <kbd>A</kbd>
- ::execute`()`: `super`: **Overridden**

### InsertAtBeginningOfLine < Insert
- command: `vim-mode:insert-at-beginning-of-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>I</kbd>
- ::execute`()`: `super`: **Overridden**

### InsertBelowWithNewline < Insert
- command: `vim-mode:insert-below-with-newline`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: <kbd>o</kbd>
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
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>J</kbd>
- ::complete: `true`: **Overridden**
- ::execute`()`

### LowerCase < Operator
- command: `vim-mode:lower-case`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>g u</kbd>
  - atom-text-editor.vim-mode.visual-mode: <kbd>u</kbd>
- ::execute`()`

### Mark < Operator
- command: `vim-mode:mark`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>m</kbd>
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
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>p</kbd>
- ::location: `'after'`

### PutBefore < Put
- command: `vim-mode:put-before`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>P</kbd>
- ::location: `'before'`

### Repeat < Operator
- command: `vim-mode:repeat`
- keymaps
  - atom-text-editor.vim-mode.normal-mode: <kbd>.</kbd>
- ::complete: `true`: **Overridden**
- ::recodable: `false`: **Overridden**
- ::execute`()`

### Replace < Operator
- command: `vim-mode:replace`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>r</kbd>
- ::constructor`()`: `super`: **Overridden**
- ::input: `null`
- ::isComplete`()`: **Overridden**
- ::execute`()`

### Select < Operator
- ::execute`()`

### ToggleCase < Operator
- command: `vim-mode:toggle-case`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>g ~</kbd>
- ::execute`()`

### ToggleCaseNow < ToggleCase
- command: `vim-mode:toggle-case-now`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>~</kbd>
- ::complete: `true`: **Overridden**

### UpperCase < Operator
- command: `vim-mode:upper-case`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>g shift-U</kbd>
  - atom-text-editor.vim-mode.visual-mode: <kbd>U</kbd>
- ::execute`()`

### Yank < Operator
- command: `vim-mode:yank`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>y</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>y</kbd>
- ::lineWiseAlias: `true`: **Overridden**
- ::execute`()`

### YankLine < Yank
- command: `vim-mode:yank-line`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>Y</kbd>
- ::constructor`()`: `super`: **Overridden**
- ::complete: `true`: **Overridden**

### OperatorError < Base
- ::constructor`(@message)`: **Overridden**

### Scroll < Base
*Not exported*
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
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>z -</kbd>
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToBottomLeave < ScrollCursorToBottom
- command: `vim-mode:scroll-cursor-to-bottom-leave`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>z b</kbd>
- ::moveToFirstCharacterOfLine: `null`: **Overridden**

### ScrollCursorToMiddle < ScrollCursor
- command: `vim-mode:scroll-cursor-to-middle`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>z .</kbd>
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToMiddleLeave < ScrollCursorToMiddle
- command: `vim-mode:scroll-cursor-to-middle-leave`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>z z</kbd>
- ::moveToFirstCharacterOfLine: `null`: **Overridden**

### ScrollCursorToTop < ScrollCursor
- command: `vim-mode:scroll-cursor-to-top`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>z enter</kbd>
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToTopLeave < ScrollCursorToTop
- command: `vim-mode:scroll-cursor-to-top-leave`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>z t</kbd>
- ::moveToFirstCharacterOfLine: `null`: **Overridden**

### ScrollDown < Scroll
- command: `vim-mode:scroll-down`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>ctrl-e</kbd>
- ::direction: `'down'`
- ::execute`()`
- ::keepCursorOnScreen`()`

### ScrollUp < ScrollDown
- command: `vim-mode:scroll-up`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>ctrl-y</kbd>
- ::direction: `'up'`: **Overridden**

### ScrollHorizontal < Scroll
*Not exported*
- ::putCursorOnScreen`()`

### ScrollCursorToLeft < ScrollHorizontal
- command: `vim-mode:scroll-cursor-to-left`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>z s</kbd>
- ::execute`()`

### ScrollCursorToRight < ScrollHorizontal
- command: `vim-mode:scroll-cursor-to-right`
- keymaps
  - atom-text-editor.vim-mode:not(.insert-mode): <kbd>z e</kbd>
- ::execute`()`

### TextObject < Base
- ::complete: `true`: **Overridden**
- ::recodable: `false`: **Overridden**

### CurrentSelection < TextObject
- ::select`()`

### SelectAWholeWord < TextObject
- command: `vim-mode:select-a-whole-word`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>a shift-W</kbd>
- ::select`()`

### SelectAWord < TextObject
- command: `vim-mode:select-a-word`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>a w</kbd>
- ::select`()`

### SelectAroundParagraph < TextObject
- command: `vim-mode:select-around-paragraph`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>a p</kbd>
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
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i <</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i ></kbd>
- ::beginChar: `'<'`: **Overridden**
- ::endChar: `'>'`: **Overridden**

### SelectAroundAngleBrackets < SelectInsideAngleBrackets
- command: `vim-mode:select-around-angle-brackets`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>a <</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>a ></kbd>
- ::includeBrackets: `true`: **Overridden**

### SelectInsideCurlyBrackets < SelectInsideBrackets
- command: `vim-mode:select-inside-curly-brackets`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i {</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i }</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i shift-B</kbd>
- ::beginChar: `'{'`: **Overridden**
- ::endChar: `'}'`: **Overridden**

### SelectAroundCurlyBrackets < SelectInsideCurlyBrackets
- command: `vim-mode:select-around-curly-brackets`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>a {</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>a }</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>a shift-B</kbd>
- ::includeBrackets: `true`: **Overridden**

### SelectInsideParentheses < SelectInsideBrackets
- command: `vim-mode:select-inside-parentheses`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i (</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i )</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i b</kbd>
- ::beginChar: `'('`: **Overridden**
- ::endChar: `')'`: **Overridden**

### SelectAroundParentheses < SelectInsideParentheses
- command: `vim-mode:select-around-parentheses`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>a (</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>a )</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>a b</kbd>
- ::includeBrackets: `true`: **Overridden**

### SelectInsideSquareBrackets < SelectInsideBrackets
- command: `vim-mode:select-inside-square-brackets`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i [</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i ]</kbd>
- ::beginChar: `'['`: **Overridden**
- ::endChar: `']'`: **Overridden**

### SelectAroundSquareBrackets < SelectInsideSquareBrackets
- command: `vim-mode:select-around-square-brackets`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>a [</kbd>
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>a ]</kbd>
- ::includeBrackets: `true`: **Overridden**

### SelectInsideTags < SelectInsideBrackets
- command: `vim-mode:select-inside-tags`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i t</kbd>
- ::beginChar: `'>'`: **Overridden**
- ::endChar: `'<'`: **Overridden**

### SelectAroundTags < SelectInsideTags
- ::includeBrackets: `true`: **Overridden**

### SelectInsideParagraph < TextObject
- command: `vim-mode:select-inside-paragraph`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i p</kbd>
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
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i `</kbd>
- ::char: `'`'`: **Overridden**

### SelectAroundBackTicks < SelectInsideBackTicks
- command: `vim-mode:select-around-back-ticks`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>a `</kbd>
- ::includeQuotes: `true`: **Overridden**

### SelectInsideDoubleQuotes < SelectInsideQuotes
- command: `vim-mode:select-inside-double-quotes`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i "</kbd>
- ::char: `'"'`: **Overridden**

### SelectAroundDoubleQuotes < SelectInsideDoubleQuotes
- command: `vim-mode:select-around-double-quotes`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>a "</kbd>
- ::includeQuotes: `true`: **Overridden**

### SelectInsideSingleQuotes < SelectInsideQuotes
- command: `vim-mode:select-inside-single-quotes`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i '</kbd>
- ::char: `'\''`: **Overridden**

### SelectAroundSingleQuotes < SelectInsideSingleQuotes
- command: `vim-mode:select-around-single-quotes`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>a '</kbd>
- ::includeQuotes: `true`: **Overridden**

### SelectInsideWholeWord < TextObject
- command: `vim-mode:select-inside-whole-word`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i shift-W</kbd>
- ::select`()`

### SelectInsideWord < TextObject
- command: `vim-mode:select-inside-word`
- keymaps
  - atom-text-editor.vim-mode.operator-pending-mode, atom-text-editor.vim-mode.visual-mode: <kbd>i w</kbd>
- ::select`()
