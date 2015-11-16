# TOM(TextObject, Operator, Motion) report.

vim-mode-plus version: 0.2.0  
*generated at 2015-11-16T16:23:31.412Z*

- [Base](#base)
  - [InsertMode](#insertmode--base)
    - [CopyFromLineAbove](#copyfromlineabove--insertmode)
      - [CopyFromLineBelow](#copyfromlinebelow--copyfromlineabove)
    - [InsertRegister](#insertregister--insertmode)
  - [Misc](#misc--base)
    - [ReverseSelections](#reverseselections--misc)
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
    - [Delete](#delete--operator)
      - [DeleteLeft](#deleteleft--delete)
      - [DeleteRight](#deleteright--delete)
      - [DeleteToLastCharacterOfLine](#deletetolastcharacterofline--delete)
    - [Increase](#increase--operator)
      - [Decrease](#decrease--increase)
    - [Indent](#indent--operator)
      - [AutoIndent](#autoindent--indent)
      - [Outdent](#outdent--indent)
    - [Join](#join--operator)
    - [Mark](#mark--operator)
    - [PutBefore](#putbefore--operator)
      - [PutAfter](#putafter--putbefore)
    - [Repeat](#repeat--operator)
    - [Replace](#replace--operator)
    - [ReplaceWithRegister](#replacewithregister--operator)
    - [Select](#select--operator)
    - [ToggleLineComments](#togglelinecomments--operator)
    - [TransformString](#transformstring--operator)
      - [CamelCase](#camelcase--transformstring)
      - [DashCase](#dashcase--transformstring)
      - [LowerCase](#lowercase--transformstring)
      - [SnakeCase](#snakecase--transformstring)
      - [Surround](#surround--transformstring)
        - [DeleteSurround](#deletesurround--surround)
          - [ChangeSurround](#changesurround--deletesurround)
            - [ChangeSurroundAnyPair](#changesurroundanypair--changesurround)
          - [DeleteSurroundAnyPair](#deletesurroundanypair--deletesurround)
        - [SurroundWord](#surroundword--surround)
      - [ToggleCase](#togglecase--transformstring)
        - [ToggleCaseAndMoveRight](#togglecaseandmoveright--togglecase)
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
- ::recodable: ```false```
- ::defaultCount: ```1```
- ::requireInput: ```false```
- ::isComplete`()`
- ::isRecordable`()`
- ::abort`()`
- ::getCount`()`
- ::new`(klassName, properties)`
- ::readInput`(_arg)`
- ::instanceof`(klassName)`

### InsertMode < Base

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

### InsertRegister < InsertMode
- command: `vim-mode-plus:insert-register`
  - keymaps
    - `atom-text-editor.vim-mode-plus.insert-mode`: <kbd>ctrl-r</kbd>
- ::hoverText: ```'"'```
- ::requireInput: ```true```: **Overridden**
- ::initialize`()`
- ::execute`()`

### Misc < Base
- ::complete: ```true```: **Overridden**

### ReverseSelections < Misc
- command: `vim-mode-plus:reverse-selections`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode`: <kbd>o</kbd>
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>O</kbd>
- ::execute`()`

### Undo < Misc
- command: `vim-mode-plus:undo`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>u</kbd>
- ::execute`()`
- ::finish`()`

### Redo < Undo
- command: `vim-mode-plus:redo`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>ctrl-r</kbd>
- ::execute`()`: **Overridden**

### Motion < Base
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
- command: `vim-mode-plus:current-selection`
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
- ::hoverText: ```':mag_right:'```
- ::hoverIcon: ```':find:'```
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
- ::hoverText: ```':mag:'```: **Overridden**
- ::hoverIcon: ```':find:'```: **Overridden**

### RepeatFind < Find
- command: `vim-mode-plus:repeat-find`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>;</kbd>
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
- ::composed: ```false```
- ::onDidComposeBy`(operation)`
- ::isOperatorPending`()`
- ::moveCursor`(cursor)`

### MoveToBeginningOfLine < Motion
- command: `vim-mode-plus:move-to-beginning-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>0</kbd>
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>home</kbd>
- ::defaultCount: ```null```: **Overridden**
- ::initialize`()`
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
- ::hoverText: ```':round_pushpin:`'```
- ::hoverIcon: ```':move-to-mark:`'```
- ::initialize`()`
- ::moveCursor`(cursor)`

### MoveToMarkLine < MoveToMark
- command: `vim-mode-plus:move-to-mark-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>'</kbd>
- ::linewise: ```true```: **Overridden**
- ::hoverText: ```':round_pushpin:\''```: **Overridden**
- ::hoverIcon: ```':move-to-mark:\''```: **Overridden**

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
- command: `vim-mode-plus:move-to-relative-line`
- ::linewise: ```true```: **Overridden**
- ::moveCursor`(cursor)`
- ::getCount`()`: **Overridden**

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
- ::recodable: ```true```: **Overridden**
- ::target: ```null```
- ::flashTarget: ```true```
- ::haveSomeSelection`()`
- ::isSameOperatorRepeated`()`
- ::compose`(@target)`
- ::setTextToRegister`(text)`
- ::markCursorBufferPositions`()`
- ::restoreMarkedCursorPositions`(markerByCursor)`
- ::withKeepingCursorPosition`(fn)`
- ::markSelections`()`
- ::flash`(range, fn)`
- ::eachSelection`(fn)`

### ActivateInsertMode < Operator
- command: `vim-mode-plus:activate-insert-mode`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>i</kbd>
- ::complete: ```true```: **Overridden**
- ::typedText: ```null```
- ::flashTarget: ```false```: **Overridden**
- ::confirmChanges`(changes)`
- ::execute`()`

### ActivateReplaceMode < ActivateInsertMode
- command: `vim-mode-plus:activate-replace-mode`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>R</kbd>
- ::execute`()`: **Overridden**
- ::countChars`(char, string)`

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
- ::initialize`()`

### Substitute < Change
- command: `vim-mode-plus:substitute`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>s</kbd>
- ::initialize`()`

### SubstituteLine < Change
- command: `vim-mode-plus:substitute-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>S</kbd>
- ::initialize`()`

### InsertAboveWithNewline < ActivateInsertMode
- command: `vim-mode-plus:insert-above-with-newline`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>O</kbd>
- ::direction: ```'above'```
- ::execute`()`: `super`: **Overridden**

### InsertBelowWithNewline < InsertAboveWithNewline
- command: `vim-mode-plus:insert-below-with-newline`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>o</kbd>
- ::direction: ```'below'```: **Overridden**

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

### Delete < Operator
- command: `vim-mode-plus:delete`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>d</kbd>
    - `atom-text-editor.vim-mode-plus.visual-mode`: <kbd>x</kbd>
- ::hoverText: ```':scissors:'```
- ::hoverIcon: ```':delete:'```
- ::flashTarget: ```false```: **Overridden**
- ::execute`()`

### DeleteLeft < Delete
- command: `vim-mode-plus:delete-left`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>X</kbd>
- ::initialize`()`

### DeleteRight < Delete
- command: `vim-mode-plus:delete-right`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>x</kbd>
- ::initialize`()`

### DeleteToLastCharacterOfLine < Delete
- command: `vim-mode-plus:delete-to-last-character-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>D</kbd>
- ::initialize`()`

### Increase < Operator
- command: `vim-mode-plus:increase`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>ctrl-a</kbd>
- ::complete: ```true```: **Overridden**
- ::step: ```1```
- ::execute`()`
- ::increaseNumber`(cursor, pattern)`

### Decrease < Increase
- command: `vim-mode-plus:decrease`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>ctrl-x</kbd>
- ::step: ```-1```: **Overridden**

### Indent < Operator
- command: `vim-mode-plus:indent`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>></kbd>
- ::hoverText: ```':point_right:'```
- ::hoverIcon: ```':indent:'```
- ::execute`()`
- ::indent`(s)`

### AutoIndent < Indent
- command: `vim-mode-plus:auto-indent`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>=</kbd>
- ::hoverText: ```':open_hands:'```: **Overridden**
- ::hoverIcon: ```':auto-indent:'```: **Overridden**
- ::indent`(s)`: **Overridden**

### Outdent < Indent
- command: `vim-mode-plus:outdent`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd><</kbd>
- ::hoverText: ```':point_left:'```: **Overridden**
- ::hoverIcon: ```':outdent:'```: **Overridden**
- ::indent`(s)`: **Overridden**

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
- ::hoverText: ```':round_pushpin:'```
- ::hoverIcon: ```':mark:'```
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
- ::recodable: ```false```: **Overridden**
- ::execute`()`

### Replace < Operator
- command: `vim-mode-plus:replace`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>r</kbd>
- ::input: ```null```
- ::hoverText: ```':tractor:'```
- ::requireInput: ```true```: **Overridden**
- ::initialize`()`
- ::isComplete`()`: `super`: **Overridden**
- ::execute`()`

### ReplaceWithRegister < Operator
- command: `vim-mode-plus:replace-with-register`
- ::hoverText: ```':pencil:'```
- ::hoverIcon: ```':replace-with-register:'```
- ::execute`()`

### Select < Operator
- command: `vim-mode-plus:select`
- ::execute`()`

### ToggleLineComments < Operator
- command: `vim-mode-plus:toggle-line-comments`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g /</kbd>
- ::hoverText: ```':mute:'```
- ::hoverIcon: ```':toggle-line-comment:'```
- ::execute`()`

### TransformString < Operator
- ::adjustCursor: ```true```
- ::execute`()`

### CamelCase < TransformString
- command: `vim-mode-plus:camel-case`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g c</kbd>
- ::hoverText: ```':camel:'```
- ::hoverIcon: ```':camel-case:'```
- ::getNewText`(text)`

### DashCase < TransformString
- command: `vim-mode-plus:dash-case`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g -</kbd>
- ::hoverText: ```':dash:'```
- ::hoverIcon: ```':dash-case:'```
- ::getNewText`(text)`

### LowerCase < TransformString
- command: `vim-mode-plus:lower-case`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g u</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>u</kbd>
- ::hoverText: ```':point_down:'```
- ::hoverIcon: ```':lower-case:'```
- ::getNewText`(text)`

### SnakeCase < TransformString
- command: `vim-mode-plus:snake-case`
- ::hoverText: ```':snake:'```
- ::hoverIcon: ```':snake-case:'```
- ::getNewText`(text)`

### Surround < TransformString
- command: `vim-mode-plus:surround`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g s s</kbd>
- ::pairs: ```[ '[]', '()', '{}', '<>' ]```
- ::input: ```null```
- ::charsMax: ```1```
- ::hoverText: ```':two_women_holding_hands:'```
- ::hoverIcon: ```':surround:'```
- ::requireInput: ```true```: **Overridden**
- ::initialize`()`
- ::getInputHandler`()`
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
- ::initialize`()`: `super`: **Overridden**
- ::preSelect`()`
- ::onConfirm`(@char)`: **Overridden**

### DeleteSurroundAnyPair < DeleteSurround
- command: `vim-mode-plus:delete-surround-any-pair`
- ::requireInput: ```false```: **Overridden**
- ::initialize`()`: `super`: **Overridden**

### SurroundWord < Surround
- command: `vim-mode-plus:surround-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g s w</kbd>
- ::initialize`()`: `super`: **Overridden**

### ToggleCase < TransformString
- command: `vim-mode-plus:toggle-case`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g ~</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>~</kbd>
- ::hoverText: ```':clap:'```
- ::hoverIcon: ```':toggle-case:'```
- ::toggleCase`(char)`
- ::getNewText`(text)`

### ToggleCaseAndMoveRight < ToggleCase
- command: `vim-mode-plus:toggle-case-and-move-right`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>~</kbd>
- ::hoverText: ```null```: **Overridden**
- ::hoverIcon: ```null```: **Overridden**
- ::adjustCursor: ```false```: **Overridden**
- ::initialize`()`

### UpperCase < TransformString
- command: `vim-mode-plus:upper-case`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g U</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>U</kbd>
- ::hoverText: ```':point_up:'```
- ::hoverIcon: ```':upper-case:'```
- ::getNewText`(text)`

### Yank < Operator
- command: `vim-mode-plus:yank`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>y</kbd>
- ::hoverText: ```':clipboard:'```
- ::hoverIcon: ```':yank:'```
- ::execute`()`

### YankLine < Yank
- command: `vim-mode-plus:yank-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>Y</kbd>
- ::initialize`()`

### OperatorError < Base
- ::constructor`(@message)`: **Overridden**

### Scroll < Base
- command: `vim-mode-plus:scroll`
- ::complete: ```true```: **Overridden**
- ::scrolloff: ```2```
- ::getFirstVisibleScreenRow`()`
- ::getLastVisibleScreenRow`()`
- ::getLastScreenRow`()`
- ::getPixelCursor`(which)`

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
- ::initialize`()`
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
- ::execute`()`

### BlockwiseChangeToLastCharacterOfLine < BlockwiseDeleteToLastCharacterOfLine
- command: `vim-mode-plus:blockwise-change-to-last-character-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>C</kbd>
- ::delegateTo: ```'ChangeToLastCharacterOfLine'```: **Overridden**

### BlockwiseInsertAtBeginningOfLine < VisualBlockwise
- command: `vim-mode-plus:blockwise-insert-at-beginning-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>I</kbd>
- ::after: ```false```
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
