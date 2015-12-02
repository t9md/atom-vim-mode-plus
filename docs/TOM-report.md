# TOM(TextObject, Operator, Motion) report.

vim-mode-plus version: 0.7.0
*generated at 2015-12-02T14:38:45.430Z*

- [Base](#base)
  - [InsertMode](#insertmode--base)
    - [CopyFromLineAbove](#copyfromlineabove--insertmode)
      - [CopyFromLineBelow](#copyfromlinebelow--copyfromlineabove)
    - [InsertLastInserted](#insertlastinserted--insertmode)
    - [InsertRegister](#insertregister--insertmode)
  - [Misc](#misc--base)
    - [ReverseSelections](#reverseselections--misc)
    - [SelectLatestChange](#selectlatestchange--misc)
    - [Undo](#undo--misc)
      - [Redo](#redo--undo)
  - [Motion](#motion--base)
    - [CurrentSelection](#currentselection--motion)
    - [Find](#find--motion)
      - [FindBackwards](#findbackwards--find)
      - [RepeatFind](#repeatfind--find)
        - [RepeatFindReverse](#repeatfindreverse--repeatfind)
      - [Till](#till--find)
        - [TillBackwards](#tillbackwards--till)
    - [MoveLeft](#moveleft--motion)
    - [MoveRight](#moveright--motion)
    - [MoveToBeginningOfLine](#movetobeginningofline--motion)
    - [MoveToEndOfWord](#movetoendofword--motion)
      - [MoveToEndOfWholeWord](#movetoendofwholeword--movetoendofword)
    - [MoveToFirstCharacterOfLine](#movetofirstcharacterofline--motion)
      - [MoveToFirstCharacterOfLineDown](#movetofirstcharacteroflinedown--movetofirstcharacterofline)
        - [MoveToFirstCharacterOfLineAndDown](#movetofirstcharacteroflineanddown--movetofirstcharacteroflinedown)
      - [MoveToFirstCharacterOfLineUp](#movetofirstcharacteroflineup--movetofirstcharacterofline)
    - [MoveToFirstLine](#movetofirstline--motion)
      - [MoveToLastLine](#movetolastline--movetofirstline)
      - [MoveToLineByPercent](#movetolinebypercent--movetofirstline)
    - [MoveToLastCharacterOfLine](#movetolastcharacterofline--motion)
    - [MoveToLastNonblankCharacterOfLineAndDown](#movetolastnonblankcharacteroflineanddown--motion)
    - [MoveToMark](#movetomark--motion)
      - [MoveToMarkLine](#movetomarkline--movetomark)
    - [MoveToNextParagraph](#movetonextparagraph--motion)
    - [MoveToNextWord](#movetonextword--motion)
      - [MoveToNextWholeWord](#movetonextwholeword--movetonextword)
    - [MoveToPreviousParagraph](#movetopreviousparagraph--motion)
    - [MoveToPreviousWholeWord](#movetopreviouswholeword--motion)
    - [MoveToPreviousWord](#movetopreviousword--motion)
    - [MoveToRelativeLine](#movetorelativeline--motion)
      - [MoveToRelativeLineWithMinimum](#movetorelativelinewithminimum--movetorelativeline)
    - [MoveToTopOfScreen](#movetotopofscreen--motion)
      - [MoveToBottomOfScreen](#movetobottomofscreen--movetotopofscreen)
      - [MoveToMiddleOfScreen](#movetomiddleofscreen--movetotopofscreen)
    - [MoveUp](#moveup--motion)
      - [MoveDown](#movedown--moveup)
    - [ScrollFullScreenDown](#scrollfullscreendown--motion)
      - [ScrollFullScreenUp](#scrollfullscreenup--scrollfullscreendown)
      - [ScrollHalfScreenDown](#scrollhalfscreendown--scrollfullscreendown)
        - [ScrollHalfScreenUp](#scrollhalfscreenup--scrollhalfscreendown)
    - [SearchBase](#searchbase--motion)
      - [BracketMatchingMotion](#bracketmatchingmotion--searchbase)
      - [RepeatSearch](#repeatsearch--searchbase)
        - [RepeatSearchReverse](#repeatsearchreverse--repeatsearch)
      - [Search](#search--searchbase)
        - [SearchBackwards](#searchbackwards--search)
      - [SearchCurrentWord](#searchcurrentword--searchbase)
        - [SearchCurrentWordBackwards](#searchcurrentwordbackwards--searchcurrentword)
  - [OperationAbortedError](#operationabortederror--base)
  - [Operator](#operator--base)
    - [ActivateInsertMode](#activateinsertmode--operator)
      - [ActivateReplaceMode](#activatereplacemode--activateinsertmode)
      - [Change](#change--activateinsertmode)
        - [ChangeToLastCharacterOfLine](#changetolastcharacterofline--change)
        - [Substitute](#substitute--change)
        - [SubstituteLine](#substituteline--change)
      - [InsertAboveWithNewline](#insertabovewithnewline--activateinsertmode)
        - [InsertBelowWithNewline](#insertbelowwithnewline--insertabovewithnewline)
      - [InsertAfter](#insertafter--activateinsertmode)
      - [InsertAfterEndOfLine](#insertafterendofline--activateinsertmode)
      - [InsertAtBeginningOfLine](#insertatbeginningofline--activateinsertmode)
      - [InsertAtLastInsert](#insertatlastinsert--activateinsertmode)
    - [Delete](#delete--operator)
      - [DeleteLeft](#deleteleft--delete)
      - [DeleteRight](#deleteright--delete)
      - [DeleteToLastCharacterOfLine](#deletetolastcharacterofline--delete)
    - [Increase](#increase--operator)
      - [Decrease](#decrease--increase)
    - [IncrementNumber](#incrementnumber--operator)
      - [DecrementNumber](#decrementnumber--incrementnumber)
    - [Join](#join--operator)
    - [Mark](#mark--operator)
    - [PutBefore](#putbefore--operator)
      - [PutAfter](#putafter--putbefore)
    - [Repeat](#repeat--operator)
    - [Replace](#replace--operator)
    - [Select](#select--operator)
    - [TransformString](#transformstring--operator)
      - [CamelCase](#camelcase--transformstring)
      - [DashCase](#dashcase--transformstring)
      - [Indent](#indent--transformstring)
        - [AutoIndent](#autoindent--indent)
        - [Outdent](#outdent--indent)
      - [JoinWithKeepingSpace](#joinwithkeepingspace--transformstring)
        - [JoinByInput](#joinbyinput--joinwithkeepingspace)
          - [JoinByInputWithKeepingSpace](#joinbyinputwithkeepingspace--joinbyinput)
      - [LowerCase](#lowercase--transformstring)
      - [ReplaceWithRegister](#replacewithregister--transformstring)
      - [SnakeCase](#snakecase--transformstring)
      - [Surround](#surround--transformstring)
        - [DeleteSurround](#deletesurround--surround)
          - [ChangeSurround](#changesurround--deletesurround)
            - [ChangeSurroundAnyPair](#changesurroundanypair--changesurround)
          - [DeleteSurroundAnyPair](#deletesurroundanypair--deletesurround)
        - [SurroundWord](#surroundword--surround)
      - [ToggleCase](#togglecase--transformstring)
        - [ToggleCaseAndMoveRight](#togglecaseandmoveright--togglecase)
      - [ToggleLineComments](#togglelinecomments--transformstring)
      - [UpperCase](#uppercase--transformstring)
    - [Yank](#yank--operator)
      - [YankLine](#yankline--yank)
  - [OperatorError](#operatorerror--base)
  - [Scroll](#scroll--base)
    - [ScrollCursor](#scrollcursor--scroll)
      - [ScrollCursorToBottom](#scrollcursortobottom--scrollcursor)
        - [ScrollCursorToBottomLeave](#scrollcursortobottomleave--scrollcursortobottom)
      - [ScrollCursorToMiddle](#scrollcursortomiddle--scrollcursor)
        - [ScrollCursorToMiddleLeave](#scrollcursortomiddleleave--scrollcursortomiddle)
      - [ScrollCursorToTop](#scrollcursortotop--scrollcursor)
        - [ScrollCursorToTopLeave](#scrollcursortotopleave--scrollcursortotop)
    - [ScrollCursorToLeft](#scrollcursortoleft--scroll)
      - [ScrollCursorToRight](#scrollcursortoright--scrollcursortoleft)
    - [ScrollDown](#scrolldown--scroll)
      - [ScrollUp](#scrollup--scrolldown)
  - [TextObject](#textobject--base)
    - [CurrentLine](#currentline--textobject)
    - [Entire](#entire--textobject)
    - [Fold](#fold--textobject)
      - [Function](#function--fold)
    - [Pair](#pair--textobject)
      - [AngleBracket](#anglebracket--pair)
      - [AnyPair](#anypair--pair)
        - [AnyQuote](#anyquote--anypair)
      - [BackTick](#backtick--pair)
      - [CurlyBracket](#curlybracket--pair)
      - [DoubleQuote](#doublequote--pair)
      - [Parenthesis](#parenthesis--pair)
      - [SingleQuote](#singlequote--pair)
      - [SquareBracket](#squarebracket--pair)
      - [Tag](#tag--pair)
    - [Paragraph](#paragraph--textobject)
      - [Comment](#comment--paragraph)
      - [Indentation](#indentation--paragraph)
    - [Word](#word--textobject)
      - [WholeWord](#wholeword--word)
  - [VisualBlockwise](#visualblockwise--base)
    - [BlockwiseDeleteToLastCharacterOfLine](#blockwisedeletetolastcharacterofline--visualblockwise)
      - [BlockwiseChangeToLastCharacterOfLine](#blockwisechangetolastcharacterofline--blockwisedeletetolastcharacterofline)
    - [BlockwiseInsertAtBeginningOfLine](#blockwiseinsertatbeginningofline--visualblockwise)
      - [BlockwiseInsertAfterEndOfLine](#blockwiseinsertafterendofline--blockwiseinsertatbeginningofline)
    - [BlockwiseMoveDown](#blockwisemovedown--visualblockwise)
      - [BlockwiseMoveUp](#blockwisemoveup--blockwisemovedown)
    - [BlockwiseOtherEnd](#blockwiseotherend--visualblockwise)
    - [BlockwiseRestoreCharacterwise](#blockwiserestorecharacterwise--visualblockwise)
    - [BlockwiseSelect](#blockwiseselect--visualblockwise)

## Base
- ::complete: ```false```
- ::recordable: ```false```
- ::defaultCount: ```1```
- ::requireInput: ```false```
- ::repeated: ```false```
- ::onDidChangeInput`()`
- ::onDidConfirmInput`()`
- ::onDidCancelInput`()`
- ::onDidUnfocusInput`()`
- ::onDidCommandInput`()`
- ::onDidChangeSearch`()`
- ::onDidConfirmSearch`()`
- ::onDidCancelSearch`()`
- ::onDidUnfocusSearch`()`
- ::onDidCommandSearch`()`
- ::onWillSelect`()`
- ::onDidSelect`()`
- ::onDidChange`()`
- ::onDidOperationFinish`()`
- ::subscribe`()`
- ::isComplete`()`
- ::isRecordable`()`
- ::isRepeated`()`
- ::setRepeated`()`
- ::abort`()`
- ::getCount`()`
- ::new`(klassName, properties)`
- ::focusInput`(_arg)`
- ::instanceof`(klassName)`
- ::emitWillSelect`()`
- ::emitDidSelect`()`

### InsertMode < Base
- ::constructor`()`: `super`: **Overridden**

### CopyFromLineAbove < InsertMode
- command: `vim-mode-plus:copy-from-line-above`
  - keymaps
    - `atom-text-editor.vim-mode-plus.insert-mode`: <kbd>ctrl-y</kbd>
- ::complete: ```true```: **Overridden**
- ::rowTranslation: ```-1```
- ::getTextInScreenRange`(range)`
- ::execute`()`

### CopyFromLineBelow < CopyFromLineAbove
- command: `vim-mode-plus:copy-from-line-below`
- ::rowTranslation: ```1```: **Overridden**

### InsertLastInserted < InsertMode
- command: `vim-mode-plus:insert-last-inserted`
- ::complete: ```true```: **Overridden**
- ::execute`()`

### InsertRegister < InsertMode
- command: `vim-mode-plus:insert-register`
  - keymaps
    - `atom-text-editor.vim-mode-plus.insert-mode`: <kbd>ctrl-r</kbd>
- ::hover: ```{ icon: '"', emoji: '"' }```
- ::requireInput: ```true```: **Overridden**
- ::initialize`()`
- ::execute`()`

### Misc < Base
- ::constructor`()`: `super`: **Overridden**
- ::complete: ```true```: **Overridden**

### ReverseSelections < Misc
- command: `vim-mode-plus:reverse-selections`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode`: <kbd>o</kbd>
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>O</kbd>
- ::execute`()`

### SelectLatestChange < Misc
- command: `vim-mode-plus:select-latest-change`
- ::complete: ```true```: **Overridden**
- ::execute`()`

### Undo < Misc
- command: `vim-mode-plus:undo`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>u</kbd>
- ::flash`(markers, klass, timeout)`
- ::saveRangeAsMarker`(markers, range)`
- ::mutateWithTrackingChanges`(fn)`
- ::execute`()`
- ::mutate`()`

### Redo < Undo
- command: `vim-mode-plus:redo`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>ctrl-r</kbd>
- ::mutate`()`: **Overridden**

### Motion < Base
- ::constructor`()`: `super`: **Overridden**
- ::complete: ```true```: **Overridden**
- ::inclusive: ```false```
- ::linewise: ```false```
- ::options: ```null```
- ::setOptions`(@options)`
- ::isLinewise`()`
- ::isInclusive`()`
- ::execute`()`
- ::select`()`
- ::selectInclusive`(selection)`
- ::countTimes`(fn)`
- ::at`(where, cursor)`
- ::moveToFirstCharacterOfLine`(cursor)`
- ::getLastRow`()`
- ::getFirstVisibleScreenRow`()`
- ::getLastVisibleScreenRow`()`
- ::unfoldAtCursorRow`(cursor)`

### CurrentSelection < Motion
- ::selectedRange: ```null```
- ::initialize`()`
- ::execute`()`: **Overridden**
- ::select`()`: **Overridden**
- ::selectCharacters`()`

### Find < Motion
- command: `vim-mode-plus:find`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>f</kbd>
- ::backwards: ```false```
- ::complete: ```false```: **Overridden**
- ::requireInput: ```true```: **Overridden**
- ::inclusive: ```true```: **Overridden**
- ::hover: ```{ icon: ':find:', emoji: ':mag_right:' }```
- ::offset: ```0```
- ::initialize`()`
- ::isBackwards`()`
- ::find`(cursor)`
- ::getCount`()`: **Overridden**
- ::moveCursor`(cursor)`

### FindBackwards < Find
- command: `vim-mode-plus:find-backwards`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>F</kbd>
- ::backwards: ```true```: **Overridden**
- ::hover: ```{ icon: ':find:', emoji: ':mag:' }```: **Overridden**

### RepeatFind < Find
- command: `vim-mode-plus:repeat-find`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>;</kbd>
- ::repeated: ```true```: **Overridden**
- ::initialize`()`: **Overridden**

### RepeatFindReverse < RepeatFind
- command: `vim-mode-plus:repeat-find-reverse`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>,</kbd>
- ::isBackwards`()`: **Overridden**

### Till < Find
- command: `vim-mode-plus:till`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>t</kbd>
- ::offset: ```1```: **Overridden**
- ::find`()`: `super`: **Overridden**
- ::selectInclusive`(selection)`: `super`: **Overridden**

### TillBackwards < Till
- command: `vim-mode-plus:till-backwards`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>T</kbd>
- ::backwards: ```true```: **Overridden**

### MoveLeft < Motion
- command: `vim-mode-plus:move-left`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>h</kbd>
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>left</kbd>
- ::moveCursor`(cursor)`

### MoveRight < Motion
- command: `vim-mode-plus:move-right`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>l</kbd>
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>space</kbd>
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>right</kbd>
- ::asTarget: ```false```
- ::onDidComposeBy`(operation)`
- ::isOperatorPending`()`
- ::moveCursor`(cursor)`

### MoveToBeginningOfLine < Motion
- command: `vim-mode-plus:move-to-beginning-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>0</kbd>
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>home</kbd>
- ::defaultCount: ```null```: **Overridden**
- ::moveCursor`(cursor)`

### MoveToEndOfWord < Motion
- command: `vim-mode-plus:move-to-end-of-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>e</kbd>
- ::wordRegex: ```null```
- ::inclusive: ```true```: **Overridden**
- ::getNext`(cursor)`
- ::moveCursor`(cursor)`

### MoveToEndOfWholeWord < MoveToEndOfWord
- command: `vim-mode-plus:move-to-end-of-whole-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>E</kbd>
- ::wordRegex: ```/\S+/```: **Overridden**

### MoveToFirstCharacterOfLine < Motion
- command: `vim-mode-plus:move-to-first-character-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>^</kbd>
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineDown < MoveToFirstCharacterOfLine
- command: `vim-mode-plus:move-to-first-character-of-line-down`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>+</kbd>
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>enter</kbd>
- ::linewise: ```true```: **Overridden**
- ::moveCursor`(cursor)`: `super`: **Overridden**

### MoveToFirstCharacterOfLineAndDown < MoveToFirstCharacterOfLineDown
- command: `vim-mode-plus:move-to-first-character-of-line-and-down`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>\_</kbd>
- ::defaultCount: ```0```: **Overridden**
- ::getCount`()`: **Overridden**

### MoveToFirstCharacterOfLineUp < MoveToFirstCharacterOfLine
- command: `vim-mode-plus:move-to-first-character-of-line-up`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>-</kbd>
- ::linewise: ```true```: **Overridden**
- ::moveCursor`(cursor)`: `super`: **Overridden**

### MoveToFirstLine < Motion
- command: `vim-mode-plus:move-to-first-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g g</kbd>
- ::linewise: ```true```: **Overridden**
- ::defaultCount: ```null```: **Overridden**
- ::getRow`()`
- ::getDefaultRow`()`
- ::moveCursor`(cursor)`

### MoveToLastLine < MoveToFirstLine
- command: `vim-mode-plus:move-to-last-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>G</kbd>
- ::getDefaultRow`()`: **Overridden**

### MoveToLineByPercent < MoveToFirstLine
- command: `vim-mode-plus:move-to-line-by-percent`
  - keymaps
    - `atom-text-editor.vim-mode-plus.with-count:not(.insert-mode)`: <kbd>%</kbd>
- ::getRow`()`: **Overridden**

### MoveToLastCharacterOfLine < Motion
- command: `vim-mode-plus:move-to-last-character-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>$</kbd>
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>end</kbd>
- ::moveCursor`(cursor)`

### MoveToLastNonblankCharacterOfLineAndDown < Motion
- command: `vim-mode-plus:move-to-last-nonblank-character-of-line-and-down`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g \_</kbd>
- ::inclusive: ```true```: **Overridden**
- ::skipTrailingWhitespace`(cursor)`
- ::getCount`()`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToMark < Motion
- command: `vim-mode-plus:move-to-mark`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>\`</kbd>
- ::complete: ```false```: **Overridden**
- ::requireInput: ```true```: **Overridden**
- ::hover: ```{ icon: ':move-to-mark:`', emoji: ':round_pushpin:`' }```
- ::initialize`()`
- ::moveCursor`(cursor)`

### MoveToMarkLine < MoveToMark
- command: `vim-mode-plus:move-to-mark-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>'</kbd>
- ::linewise: ```true```: **Overridden**
- ::hover: ```{ icon: ':move-to-mark:\'', emoji: ':round_pushpin:\'' }```: **Overridden**

### MoveToNextParagraph < Motion
- command: `vim-mode-plus:move-to-next-paragraph`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>}</kbd>
- ::moveCursor`(cursor)`

### MoveToNextWord < Motion
- command: `vim-mode-plus:move-to-next-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>w</kbd>
- ::wordRegex: ```null```
- ::getNext`(cursor)`
- ::moveCursor`(cursor)`

### MoveToNextWholeWord < MoveToNextWord
- command: `vim-mode-plus:move-to-next-whole-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>W</kbd>
- ::wordRegex: ```/^\s*$|\S+/```: **Overridden**

### MoveToPreviousParagraph < Motion
- command: `vim-mode-plus:move-to-previous-paragraph`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>{</kbd>
- ::moveCursor`(cursor)`

### MoveToPreviousWholeWord < Motion
- command: `vim-mode-plus:move-to-previous-whole-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>B</kbd>
- ::wordRegex: ```/^\s*$|\S+/```
- ::moveCursor`(cursor)`

### MoveToPreviousWord < Motion
- command: `vim-mode-plus:move-to-previous-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>b</kbd>
- ::moveCursor`(cursor)`

### MoveToRelativeLine < Motion
- ::linewise: ```true```: **Overridden**
- ::moveCursor`(cursor)`
- ::getCount`()`: **Overridden**

### MoveToRelativeLineWithMinimum < MoveToRelativeLine
- ::min: ```0```
- ::getCount`()`: `super`: **Overridden**

### MoveToTopOfScreen < Motion
- command: `vim-mode-plus:move-to-top-of-screen`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>H</kbd>
- ::linewise: ```true```: **Overridden**
- ::scrolloff: ```2```
- ::defaultCount: ```0```: **Overridden**
- ::moveCursor`(cursor)`
- ::getRow`()`
- ::getCount`()`: **Overridden**

### MoveToBottomOfScreen < MoveToTopOfScreen
- command: `vim-mode-plus:move-to-bottom-of-screen`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>L</kbd>
- ::getRow`()`: **Overridden**

### MoveToMiddleOfScreen < MoveToTopOfScreen
- command: `vim-mode-plus:move-to-middle-of-screen`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>M</kbd>
- ::getRow`()`: **Overridden**

### MoveUp < Motion
- command: `vim-mode-plus:move-up`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>k</kbd>
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>up</kbd>
- ::linewise: ```true```: **Overridden**
- ::amount: ```-1```
- ::isMovable`(cursor)`
- ::move`(cursor)`
- ::moveCursor`(cursor)`

### MoveDown < MoveUp
- command: `vim-mode-plus:move-down`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>j</kbd>
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>down</kbd>
- ::linewise: ```true```: **Overridden**
- ::amount: ```1```: **Overridden**
- ::isMovable`(cursor)`: **Overridden**
- ::move`(cursor)`: **Overridden**

### ScrollFullScreenDown < Motion
- command: `vim-mode-plus:scroll-full-screen-down`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>ctrl-f</kbd>
- ::coefficient: ```1```
- ::initialize`()`
- ::scroll`()`
- ::select`()`: `super()`: **Overridden**
- ::execute`()`: `super()`: **Overridden**
- ::moveCursor`(cursor)`

### ScrollFullScreenUp < ScrollFullScreenDown
- command: `vim-mode-plus:scroll-full-screen-up`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>ctrl-b</kbd>
- ::coefficient: ```-1```: **Overridden**

### ScrollHalfScreenDown < ScrollFullScreenDown
- command: `vim-mode-plus:scroll-half-screen-down`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>ctrl-d</kbd>
- ::coefficient: ```0.5```: **Overridden**

### ScrollHalfScreenUp < ScrollHalfScreenDown
- command: `vim-mode-plus:scroll-half-screen-up`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>ctrl-u</kbd>
- ::coefficient: ```-0.5```: **Overridden**

### SearchBase < Motion
- ::saveCurrentSearch: ```true```
- ::complete: ```false```: **Overridden**
- ::backwards: ```false```
- ::escapeRegExp: ```false```
- ::initialize`()`
- ::isBackwards`()`
- ::getCount`()`: `super`: **Overridden**
- ::flash`(range, _arg)`
- ::finish`()`
- ::moveCursor`(cursor)`
- ::visit`(match, cursor)`
- ::isIncrementalSearch`()`
- ::scan`(cursor)`
- ::getPattern`(term)`
- ::updateEscapeRegExpOption`(input)`
- ::updateUI`(options)`

### BracketMatchingMotion < SearchBase
- command: `vim-mode-plus:bracket-matching-motion`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>%</kbd>
- ::inclusive: ```true```: **Overridden**
- ::complete: ```true```: **Overridden**
- ::searchForMatch`(startPosition, reverse, inCharacter, outCharacter)`
- ::characterAt`(position)`
- ::getSearchData`(position)`
- ::moveCursor`(cursor)`: **Overridden**

### RepeatSearch < SearchBase
- command: `vim-mode-plus:repeat-search`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>n</kbd>
- ::complete: ```true```: **Overridden**
- ::saveCurrentSearch: ```false```: **Overridden**
- ::initialize`()`: `super`: **Overridden**

### RepeatSearchReverse < RepeatSearch
- command: `vim-mode-plus:repeat-search-reverse`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>N</kbd>
- ::isBackwards`()`: **Overridden**

### Search < SearchBase
- command: `vim-mode-plus:search`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>/</kbd>
- ::initialize`()`: `super`: **Overridden**
- ::subscribeScrollChange`()`
- ::isRepeatLastSearch`(input)`
- ::finish`()`: `super`: **Overridden**
- ::onConfirm`(@input)`
- ::onCancel`()`
- ::onChange`(@input)`
- ::onCommand`(command)`

### SearchBackwards < Search
- command: `vim-mode-plus:search-backwards`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>?</kbd>
- ::backwards: ```true```: **Overridden**

### SearchCurrentWord < SearchBase
- command: `vim-mode-plus:search-current-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>*</kbd>
- ::wordRegex: ```null```
- ::complete: ```true```: **Overridden**
- ::initialize`()`: `super`: **Overridden**
- ::getPattern`(text)`: **Overridden**
- ::getCurrentWord`()`

### SearchCurrentWordBackwards < SearchCurrentWord
- command: `vim-mode-plus:search-current-word-backwards`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>#</kbd>
- ::backwards: ```true```: **Overridden**

### OperationAbortedError < Base
- ::constructor`(@message)`: **Overridden**

### Operator < Base
- ::constructor`()`: `super`: **Overridden**
- ::recordable: ```true```: **Overridden**
- ::target: ```null```
- ::flashTarget: ```true```
- ::trackChange: ```false```
- ::activate`(mode, submode)`
- ::setMarkForChange`(range)`
- ::haveSomeSelection`()`
- ::isSameOperatorRepeated`()`
- ::needFlash`()`
- ::needTrackChange`()`
- ::needStay`()`
- ::observeSelectAction`()`
- ::setTarget`(@target)`
- ::selectTarget`(force)`
- ::setTextToRegister`(text)`
- ::flash`(range)`
- ::preservePoints`(_arg)`
- ::eachSelection`(fn)`

### ActivateInsertMode < Operator
- command: `vim-mode-plus:activate-insert-mode`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>i</kbd>
- ::complete: ```true```: **Overridden**
- ::flashTarget: ```false```: **Overridden**
- ::checkpoint: ```null```
- ::submode: ```null```
- ::initialize`()`
- ::setCheckpoint`(purpose)`
- ::getCheckpoint`()`
- ::getText`()`
- ::repeatInsert`(selection, text)`
- ::execute`()`

### ActivateReplaceMode < ActivateInsertMode
- command: `vim-mode-plus:activate-replace-mode`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>R</kbd>
- ::submode: ```'replace'```: **Overridden**
- ::repeatInsert`(selection, text)`: **Overridden**

### Change < ActivateInsertMode
- command: `vim-mode-plus:change`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>c</kbd>
    - `atom-text-editor.vim-mode-plus.visual-mode`: <kbd>s</kbd>
- ::complete: ```false```: **Overridden**
- ::execute`()`: `super`: **Overridden**

### ChangeToLastCharacterOfLine < Change
- command: `vim-mode-plus:change-to-last-character-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>C</kbd>
- ::target: ```'MoveToLastCharacterOfLine'```: **Overridden**

### Substitute < Change
- command: `vim-mode-plus:substitute`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>s</kbd>
- ::target: ```'MoveRight'```: **Overridden**

### SubstituteLine < Change
- command: `vim-mode-plus:substitute-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>S</kbd>
- ::target: ```'MoveToRelativeLine'```: **Overridden**

### InsertAboveWithNewline < ActivateInsertMode
- command: `vim-mode-plus:insert-above-with-newline`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>O</kbd>
- ::execute`()`: `super`: **Overridden**
- ::insertNewline`()`
- ::repeatInsert`(selection, text)`: **Overridden**

### InsertBelowWithNewline < InsertAboveWithNewline
- command: `vim-mode-plus:insert-below-with-newline`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>o</kbd>
- ::insertNewline`()`: **Overridden**

### InsertAfter < ActivateInsertMode
- command: `vim-mode-plus:insert-after`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>a</kbd>
- ::execute`()`: `super`: **Overridden**

### InsertAfterEndOfLine < ActivateInsertMode
- command: `vim-mode-plus:insert-after-end-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>A</kbd>
- ::execute`()`: `super`: **Overridden**

### InsertAtBeginningOfLine < ActivateInsertMode
- command: `vim-mode-plus:insert-at-beginning-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>I</kbd>
- ::execute`()`: `super`: **Overridden**

### InsertAtLastInsert < ActivateInsertMode
- command: `vim-mode-plus:insert-at-last-insert`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>g i</kbd>
- ::execute`()`: `super`: **Overridden**

### Delete < Operator
- command: `vim-mode-plus:delete`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>d</kbd>
    - `atom-text-editor.vim-mode-plus.visual-mode`: <kbd>x</kbd>
- ::hover: ```{ icon: ':delete:', emoji: ':scissors:' }```
- ::trackChange: ```true```: **Overridden**
- ::flashTarget: ```false```: **Overridden**
- ::execute`()`

### DeleteLeft < Delete
- command: `vim-mode-plus:delete-left`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>X</kbd>
- ::target: ```'MoveLeft'```: **Overridden**

### DeleteRight < Delete
- command: `vim-mode-plus:delete-right`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>x</kbd>
- ::target: ```'MoveRight'```: **Overridden**

### DeleteToLastCharacterOfLine < Delete
- command: `vim-mode-plus:delete-to-last-character-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>D</kbd>
- ::target: ```'MoveToLastCharacterOfLine'```: **Overridden**

### Increase < Operator
- command: `vim-mode-plus:increase`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>ctrl-a</kbd>
- ::complete: ```true```: **Overridden**
- ::step: ```1```
- ::execute`()`
- ::increaseNumber`(cursor, scanRange, pattern)`

### Decrease < Increase
- command: `vim-mode-plus:decrease`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>ctrl-x</kbd>
- ::step: ```-1```: **Overridden**

### IncrementNumber < Operator
- command: `vim-mode-plus:increment-number`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g ctrl-a</kbd>
- ::step: ```1```
- ::baseNumber: ```null```
- ::execute`()`
- ::replaceNumber`(scanRange, pattern)`
- ::getNewText`(text)`

### DecrementNumber < IncrementNumber
- command: `vim-mode-plus:decrement-number`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g ctrl-x</kbd>
- ::step: ```-1```: **Overridden**

### Join < Operator
- command: `vim-mode-plus:join`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>J</kbd>
- ::complete: ```true```: **Overridden**
- ::execute`()`

### Mark < Operator
- command: `vim-mode-plus:mark`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>m</kbd>
- ::hover: ```{ icon: ':mark:', emoji: ':round_pushpin:' }```
- ::requireInput: ```true```: **Overridden**
- ::initialize`()`
- ::execute`()`

### PutBefore < Operator
- command: `vim-mode-plus:put-before`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>P</kbd>
- ::complete: ```true```: **Overridden**
- ::location: ```'before'```
- ::execute`()`
- ::pasteLinewise`(selection, text)`
- ::pasteCharacterwise`(selection, text)`
- ::insertTextAbove`(selection, text)`
- ::insertTextBelow`(selection, text)`

### PutAfter < PutBefore
- command: `vim-mode-plus:put-after`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>p</kbd>
- ::location: ```'after'```: **Overridden**

### Repeat < Operator
- command: `vim-mode-plus:repeat`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>.</kbd>
- ::complete: ```true```: **Overridden**
- ::recordable: ```false```: **Overridden**
- ::execute`()`

### Replace < Operator
- command: `vim-mode-plus:replace`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>r</kbd>
- ::input: ```null```
- ::hover: ```{ icon: ':replace:', emoji: ':tractor:' }```
- ::trackChange: ```true```: **Overridden**
- ::requireInput: ```true```: **Overridden**
- ::initialize`()`
- ::isComplete`()`: `super`: **Overridden**
- ::execute`()`

### Select < Operator
- ::execute`()`

### TransformString < Operator
- ::trackChange: ```true```: **Overridden**
- ::stayOnLinewise: ```true```
- ::setPoint: ```true```
- ::execute`()`
- ::mutate`(s, setPoint)`

### CamelCase < TransformString
- command: `vim-mode-plus:camel-case`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g c</kbd>
- ::hover: ```{ icon: ':camel-case:', emoji: ':camel:' }```
- ::getNewText`(text)`

### DashCase < TransformString
- command: `vim-mode-plus:dash-case`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g -</kbd>
- ::hover: ```{ icon: ':dash-case:', emoji: ':dash:' }```
- ::getNewText`(text)`

### Indent < TransformString
- command: `vim-mode-plus:indent`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>></kbd>
- ::hover: ```{ icon: ':indent:', emoji: ':point_right:' }```
- ::stayOnLinewise: ```false```: **Overridden**
- ::mutate`(s, setPoint)`: **Overridden**
- ::indent`(s)`

### AutoIndent < Indent
- command: `vim-mode-plus:auto-indent`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>=</kbd>
- ::hover: ```{ icon: ':auto-indent:', emoji: ':open_hands:' }```: **Overridden**
- ::indent`(s)`: **Overridden**

### Outdent < Indent
- command: `vim-mode-plus:outdent`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd><</kbd>
- ::hover: ```{ icon: ':outdent:', emoji: ':point_left:' }```: **Overridden**
- ::indent`(s)`: **Overridden**

### JoinWithKeepingSpace < TransformString
- command: `vim-mode-plus:join-with-keeping-space`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g J</kbd>
- ::input: ```''```
- ::trim: ```false```
- ::initialize`()`
- ::mutate`(s)`: **Overridden**
- ::join`(rows)`

### JoinByInput < JoinWithKeepingSpace
- command: `vim-mode-plus:join-by-input`
- ::hover: ```{ icon: ':join:', emoji: ':dolls:' }```
- ::requireInput: ```true```: **Overridden**
- ::input: ```null```: **Overridden**
- ::trim: ```true```: **Overridden**
- ::initialize`()`: **Overridden**
- ::join`(rows)`: **Overridden**

### JoinByInputWithKeepingSpace < JoinByInput
- command: `vim-mode-plus:join-by-input-with-keeping-space`
- ::trim: ```false```: **Overridden**
- ::join`(rows)`: **Overridden**

### LowerCase < TransformString
- command: `vim-mode-plus:lower-case`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g u</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>u</kbd>
- ::hover: ```{ icon: ':lower-case:', emoji: ':point_down:' }```
- ::getNewText`(text)`

### ReplaceWithRegister < TransformString
- command: `vim-mode-plus:replace-with-register`
- ::hover: ```{ icon: ':replace-with-register:', emoji: ':pencil:' }```
- ::getNewText`(text)`

### SnakeCase < TransformString
- command: `vim-mode-plus:snake-case`
- ::hover: ```{ icon: ':snake-case:', emoji: ':snake:' }```
- ::getNewText`(text)`

### Surround < TransformString
- command: `vim-mode-plus:surround`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g s s</kbd>
- ::pairs: ```[ '[]', '()', '{}', '<>' ]```
- ::input: ```null```
- ::charsMax: ```1```
- ::hover: ```{ icon: ':surround:', emoji: ':two_women_holding_hands:' }```
- ::requireInput: ```true```: **Overridden**
- ::initialize`()`
- ::onConfirm`(@input)`
- ::getPair`(input)`
- ::surround`(text, pair)`
- ::getNewText`(text)`

### DeleteSurround < Surround
- command: `vim-mode-plus:delete-surround`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g s d</kbd>
- ::pairChars: ```'[](){}'```
- ::onConfirm`(@input)`: **Overridden**
- ::getNewText`(text)`: **Overridden**

### ChangeSurround < DeleteSurround
- command: `vim-mode-plus:change-surround`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g s c</kbd>
- ::charsMax: ```2```: **Overridden**
- ::char: ```null```
- ::onConfirm`(input)`: `super(from)`: **Overridden**
- ::getNewText`(text)`: `super(text), @getPair(@char))`: **Overridden**

### ChangeSurroundAnyPair < ChangeSurround
- command: `vim-mode-plus:change-surround-any-pair`
- ::charsMax: ```1```: **Overridden**
- ::target: ```'AnyPair'```: **Overridden**
- ::initialize`()`: `super`: **Overridden**
- ::onConfirm`(@char)`: **Overridden**

### DeleteSurroundAnyPair < DeleteSurround
- command: `vim-mode-plus:delete-surround-any-pair`
- ::requireInput: ```false```: **Overridden**
- ::target: ```'AnyPair'```: **Overridden**

### SurroundWord < Surround
- command: `vim-mode-plus:surround-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g s w</kbd>
- ::target: ```'Word'```: **Overridden**

### ToggleCase < TransformString
- command: `vim-mode-plus:toggle-case`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g ~</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>~</kbd>
- ::hover: ```{ icon: ':toggle-case:', emoji: ':clap:' }```
- ::toggleCase`(char)`
- ::getNewText`(text)`

### ToggleCaseAndMoveRight < ToggleCase
- command: `vim-mode-plus:toggle-case-and-move-right`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>~</kbd>
- ::hover: ```null```: **Overridden**
- ::setPoint: ```false```: **Overridden**
- ::target: ```'MoveRight'```: **Overridden**

### ToggleLineComments < TransformString
- command: `vim-mode-plus:toggle-line-comments`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g /</kbd>
- ::hover: ```{ icon: ':toggle-line-comment:', emoji: ':mute:' }```
- ::stayOption: ```{ asMarker: true }```
- ::mutate`(s, setPoint)`: **Overridden**

### UpperCase < TransformString
- command: `vim-mode-plus:upper-case`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g U</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>U</kbd>
- ::hover: ```{ icon: ':upper-case:', emoji: ':point_up:' }```
- ::getNewText`(text)`

### Yank < Operator
- command: `vim-mode-plus:yank`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>y</kbd>
- ::hover: ```{ icon: ':yank:', emoji: ':clipboard:' }```
- ::trackChange: ```true```: **Overridden**
- ::stayOnLinewise: ```true```
- ::execute`()`

### YankLine < Yank
- command: `vim-mode-plus:yank-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>Y</kbd>
- ::target: ```'MoveToRelativeLine'```: **Overridden**

### OperatorError < Base
- ::constructor`(@message)`: **Overridden**

### Scroll < Base
- command: `vim-mode-plus:scroll`
- ::constructor`()`: `super`: **Overridden**
- ::complete: ```true```: **Overridden**
- ::scrolloff: ```2```
- ::cursorPixel: ```null```
- ::getFirstVisibleScreenRow`()`
- ::getLastVisibleScreenRow`()`
- ::getLastScreenRow`()`
- ::getCursorPixel`()`

### ScrollCursor < Scroll
- command: `vim-mode-plus:scroll-cursor`
- ::execute`()`
- ::moveToFirstCharacterOfLine`()`
- ::getOffSetPixelHeight`(lineDelta)`

### ScrollCursorToBottom < ScrollCursor
- command: `vim-mode-plus:scroll-cursor-to-bottom`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>z -</kbd>
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToBottomLeave < ScrollCursorToBottom
- command: `vim-mode-plus:scroll-cursor-to-bottom-leave`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>z b</kbd>
- ::moveToFirstCharacterOfLine: ```null```: **Overridden**

### ScrollCursorToMiddle < ScrollCursor
- command: `vim-mode-plus:scroll-cursor-to-middle`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>z .</kbd>
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToMiddleLeave < ScrollCursorToMiddle
- command: `vim-mode-plus:scroll-cursor-to-middle-leave`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>z z</kbd>
- ::moveToFirstCharacterOfLine: ```null```: **Overridden**

### ScrollCursorToTop < ScrollCursor
- command: `vim-mode-plus:scroll-cursor-to-top`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>z enter</kbd>
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToTopLeave < ScrollCursorToTop
- command: `vim-mode-plus:scroll-cursor-to-top-leave`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>z t</kbd>
- ::moveToFirstCharacterOfLine: ```null```: **Overridden**

### ScrollCursorToLeft < Scroll
- command: `vim-mode-plus:scroll-cursor-to-left`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>z s</kbd>
- ::direction: ```'left'```
- ::execute`()`

### ScrollCursorToRight < ScrollCursorToLeft
- command: `vim-mode-plus:scroll-cursor-to-right`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>z e</kbd>
- ::direction: ```'right'```: **Overridden**
- ::execute`()`: **Overridden**

### ScrollDown < Scroll
- command: `vim-mode-plus:scroll-down`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>ctrl-e</kbd>
- ::direction: ```'down'```
- ::execute`()`
- ::keepCursorOnScreen`()`

### ScrollUp < ScrollDown
- command: `vim-mode-plus:scroll-up`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>ctrl-y</kbd>
- ::direction: ```'up'```: **Overridden**

### TextObject < Base
- ::constructor`()`: `super`: **Overridden**
- ::complete: ```true```: **Overridden**
- ::inner: ```false```
- ::isInner`()`
- ::isLinewise`()`
- ::eachSelection`(fn)`
- ::execute`()`

### CurrentLine < TextObject
- command: `vim-mode-plus:a-current-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a l</kbd>
- command: `vim-mode-plus:inner-current-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i l</kbd>
- ::select`()`

### Entire < TextObject
- command: `vim-mode-plus:a-entire`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a e</kbd>
- command: `vim-mode-plus:inner-entire`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i e</kbd>
- ::select`()`

### Fold < TextObject
- command: `vim-mode-plus:a-fold`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a z</kbd>
- command: `vim-mode-plus:inner-fold`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i z</kbd>
- ::getFoldRowRangeForBufferRow`(bufferRow)`
- ::select`()`

### Function < Fold
- command: `vim-mode-plus:a-function`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a f</kbd>
- command: `vim-mode-plus:inner-function`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i f</kbd>
- ::indentScopedLanguages: ```[ 'python', 'coffee' ]```
- ::omitingClosingCharLanguages: ```[ 'go' ]```
- ::initialize`()`
- ::getScopesForRow`(row)`
- ::isFunctionScope`(scope)`
- ::isIncludeFunctionScopeForRow`(row)`
- ::getFoldRowRangeForBufferRow`(bufferRow)`: **Overridden**
- ::adjustRowRange`(startRow, endRow)`

### Pair < TextObject
- ::allowNextLine: ```false```
- ::what: ```'enclosed'```
- ::pair: ```null```
- ::getPairState`(pair, matchText, point)`
- ::pairStateInString`(str, char)`
- ::isEscapedCharAtPoint`(point)`
- ::findPair`(pair, options)`
- ::getPairRange`(from, pair, what)`
- ::getRange`(selection, what)`
- ::select`()`

### AngleBracket < Pair
- command: `vim-mode-plus:a-angle-bracket`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a <</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a ></kbd>
- command: `vim-mode-plus:inner-angle-bracket`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i <</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i ></kbd>
- ::pair: ```'<>'```: **Overridden**

### AnyPair < Pair
- command: `vim-mode-plus:a-any-pair`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a s</kbd>
- command: `vim-mode-plus:inner-any-pair`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i s</kbd>
- ::what: ```'enclosed'```: **Overridden**
- ::member: ```[ 'DoubleQuote',
  'SingleQuote',
  'BackTick',
  'CurlyBracket',
  'AngleBracket',
  'Tag',
  'SquareBracket',
  'Parenthesis' ]```
- ::getRangeBy`(klass, selection)`
- ::getRanges`(selection)`
- ::getNearestRange`(selection)`
- ::select`()`: **Overridden**

### AnyQuote < AnyPair
- command: `vim-mode-plus:a-any-quote`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a q</kbd>
- command: `vim-mode-plus:inner-any-quote`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i q</kbd>
- ::what: ```'next'```: **Overridden**
- ::member: ```[ 'DoubleQuote', 'SingleQuote', 'BackTick' ]```: **Overridden**
- ::getNearestRange`(selection)`: **Overridden**

### BackTick < Pair
- command: `vim-mode-plus:a-back-tick`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a \`</kbd>
- command: `vim-mode-plus:inner-back-tick`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i \`</kbd>
- ::pair: ```'``'```: **Overridden**
- ::what: ```'next'```: **Overridden**

### CurlyBracket < Pair
- command: `vim-mode-plus:a-curly-bracket`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a {</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a }</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a B</kbd>
- command: `vim-mode-plus:inner-curly-bracket`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i {</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i }</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i B</kbd>
- ::pair: ```'{}'```: **Overridden**
- ::allowNextLine: ```true```: **Overridden**

### DoubleQuote < Pair
- command: `vim-mode-plus:a-double-quote`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a "</kbd>
- command: `vim-mode-plus:inner-double-quote`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i "</kbd>
- ::pair: ```'""'```: **Overridden**
- ::what: ```'next'```: **Overridden**

### Parenthesis < Pair
- command: `vim-mode-plus:a-parenthesis`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a (</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a )</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a b</kbd>
- command: `vim-mode-plus:inner-parenthesis`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i (</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i )</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i b</kbd>
- ::pair: ```'()'```: **Overridden**
- ::allowNextLine: ```true```: **Overridden**

### SingleQuote < Pair
- command: `vim-mode-plus:a-single-quote`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a '</kbd>
- command: `vim-mode-plus:inner-single-quote`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i '</kbd>
- ::pair: ```'\'\''```: **Overridden**
- ::what: ```'next'```: **Overridden**

### SquareBracket < Pair
- command: `vim-mode-plus:a-square-bracket`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a [</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a ]</kbd>
- command: `vim-mode-plus:inner-square-bracket`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i [</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i ]</kbd>
- ::pair: ```'[]'```: **Overridden**
- ::allowNextLine: ```true```: **Overridden**

### Tag < Pair
- command: `vim-mode-plus:a-tag`
- command: `vim-mode-plus:inner-tag`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i t</kbd>
- ::pair: ```'><'```: **Overridden**

### Paragraph < TextObject
- command: `vim-mode-plus:a-paragraph`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a p</kbd>
- command: `vim-mode-plus:inner-paragraph`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i p</kbd>
- ::getStartRow`(startRow, fn)`
- ::getEndRow`(startRow, fn)`
- ::getRange`(startRow)`
- ::selectParagraph`(selection)`
- ::selectExclusive`(selection)`
- ::selectInclusive`(selection)`
- ::select`()`

### Comment < Paragraph
- command: `vim-mode-plus:a-comment`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a /</kbd>
- command: `vim-mode-plus:inner-comment`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i /</kbd>
- ::selectInclusive`(selection)`: **Overridden**
- ::getRange`(startRow)`: **Overridden**

### Indentation < Paragraph
- command: `vim-mode-plus:a-indentation`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a i</kbd>
- command: `vim-mode-plus:inner-indentation`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i i</kbd>
- ::selectInclusive`(selection)`: **Overridden**
- ::getRange`(startRow)`: **Overridden**

### Word < TextObject
- command: `vim-mode-plus:a-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a w</kbd>
- command: `vim-mode-plus:inner-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i w</kbd>
- ::select`()`
- ::selectExclusive`(selection, wordRegex)`
- ::selectInclusive`(selection)`

### WholeWord < Word
- command: `vim-mode-plus:a-whole-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a W</kbd>
- command: `vim-mode-plus:inner-whole-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i W</kbd>
- ::wordRegExp: ```/\S+/```
- ::selectExclusive`(s, wordRegex)`: **Overridden**

### VisualBlockwise < Base
- command: `vim-mode-plus:visual-blockwise`
- ::constructor`()`: `super`: **Overridden**
- ::complete: ```true```: **Overridden**
- ::initialize`()`
- ::eachSelection`(fn)`
- ::countTimes`(fn)`
- ::updateProperties`(_arg)`
- ::isSingleLine`()`
- ::getTop`()`
- ::getBottom`()`
- ::isReversed`()`
- ::getHead`()`
- ::getTail`()`
- ::getBufferRowRange`()`

### BlockwiseDeleteToLastCharacterOfLine < VisualBlockwise
- command: `vim-mode-plus:blockwise-delete-to-last-character-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>D</kbd>
- ::delegateTo: ```'DeleteToLastCharacterOfLine'```
- ::initialize`()`: **Overridden**
- ::execute`()`

### BlockwiseChangeToLastCharacterOfLine < BlockwiseDeleteToLastCharacterOfLine
- command: `vim-mode-plus:blockwise-change-to-last-character-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>C</kbd>
- ::recordable: ```true```: **Overridden**
- ::delegateTo: ```'ChangeToLastCharacterOfLine'```: **Overridden**
- ::getCheckpoint`()`
- ::initialize`()`: **Overridden**

### BlockwiseInsertAtBeginningOfLine < VisualBlockwise
- command: `vim-mode-plus:blockwise-insert-at-beginning-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>I</kbd>
- ::delegateTo: ```'ActivateInsertMode'```
- ::recordable: ```true```: **Overridden**
- ::after: ```false```
- ::getCheckpoint`()`
- ::initialize`()`: **Overridden**
- ::execute`()`

### BlockwiseInsertAfterEndOfLine < BlockwiseInsertAtBeginningOfLine
- command: `vim-mode-plus:blockwise-insert-after-end-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>A</kbd>
- ::after: ```true```: **Overridden**

### BlockwiseMoveDown < VisualBlockwise
- command: `vim-mode-plus:blockwise-move-down`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>j</kbd>
- ::direction: ```'Below'```
- ::isExpanding`()`
- ::execute`()`

### BlockwiseMoveUp < BlockwiseMoveDown
- command: `vim-mode-plus:blockwise-move-up`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>k</kbd>
- ::direction: ```'Above'```: **Overridden**

### BlockwiseOtherEnd < VisualBlockwise
- command: `vim-mode-plus:blockwise-other-end`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>o</kbd>
- ::execute`()`

### BlockwiseRestoreCharacterwise < VisualBlockwise
- ::execute`()`

### BlockwiseSelect < VisualBlockwise
- ::execute`()`
