# TOM(TextObject, Operator, Motion) report.

vim-mode-plus version: 0.2.0  
*generated at 2015-11-16T09:23:32.709Z*

- [Base](#base) *Not exported*
  - [InsertMode](#insertmode--base) *Not exported*
    - [CopyFromLineAbove](#copyfromlineabove--insertmode)
      - [CopyFromLineBelow](#copyfromlinebelow--copyfromlineabove)
    - [InsertRegister](#insertregister--insertmode)
  - [Misc](#misc--base) *Not exported*
    - [ReverseSelections](#reverseselections--misc)
    - [Undo](#undo--misc)
      - [Redo](#redo--undo)
  - [Motion](#motion--base) *Not exported*
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
    - [SearchBase](#searchbase--motion) *Not exported*
      - [BracketMatchingMotion](#bracketmatchingmotion--searchbase)
      - [RepeatSearch](#repeatsearch--searchbase)
        - [RepeatSearchReverse](#repeatsearchreverse--repeatsearch)
      - [Search](#search--searchbase)
        - [SearchBackwards](#searchbackwards--search)
      - [SearchCurrentWord](#searchcurrentword--searchbase)
        - [SearchCurrentWordBackwards](#searchcurrentwordbackwards--searchcurrentword)
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
    - [TransformString](#transformstring--operator) *Not exported*
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
  - [Scroll](#scroll--base) *Not exported*
    - [ScrollCursor](#scrollcursor--scroll) *Not exported*
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
  - [TextObject](#textobject--base) *Not exported*
    - [CurrentLine](#currentline--textobject)
    - [Entire](#entire--textobject)
    - [Fold](#fold--textobject)
      - [Function](#function--fold)
    - [Pair](#pair--textobject) *Not exported*
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
  - [VisualBlockwise](#visualblockwise--base) *Not exported*
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
*Not exported*
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
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
*Not exported*
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'InsertMode'```

### CopyFromLineAbove < InsertMode
- command: `vim-mode-plus:copy-from-line-above`
  - keymaps
    - `atom-text-editor.vim-mode-plus.insert-mode`: <kbd>ctrl-y</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'InsertMode'```
- ::complete: ```true```: **Overridden**
- ::rowTranslation: ```-1```
- ::getTextInScreenRange`(range)`
- ::execute`()`

### CopyFromLineBelow < CopyFromLineAbove
- command: `vim-mode-plus:copy-from-line-below`
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'InsertMode'```
- ::rowTranslation: ```1```: **Overridden**

### InsertRegister < InsertMode
- command: `vim-mode-plus:insert-register`
  - keymaps
    - `atom-text-editor.vim-mode-plus.insert-mode`: <kbd>ctrl-r</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'InsertMode'```
- ::hoverText: ```'"'```
- ::requireInput: ```true```: **Overridden**
- ::initialize`()`
- ::execute`()`

### Misc < Base
*Not exported*
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Misc'```
- ::complete: ```true```: **Overridden**

### ReverseSelections < Misc
- command: `vim-mode-plus:reverse-selections`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode`: <kbd>o</kbd>
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>O</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Misc'```
- ::execute`()`

### Undo < Misc
- command: `vim-mode-plus:undo`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>u</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Misc'```
- ::execute`()`
- ::finish`()`

### Redo < Undo
- command: `vim-mode-plus:redo`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>ctrl-r</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Misc'```
- ::execute`()`: **Overridden**

### Motion < Base
*Not exported*
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::selectedRange: ```null```
- ::initialize`()`
- ::execute`()`: **Overridden**
- ::select`()`: **Overridden**
- ::selectCharacters`()`

### Find < Motion
- command: `vim-mode-plus:find`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>f</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::backwards: ```true```: **Overridden**
- ::hoverText: ```':mag:'```: **Overridden**
- ::hoverIcon: ```':find:'```: **Overridden**

### RepeatFind < Find
- command: `vim-mode-plus:repeat-find`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>;</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::initialize`()`: **Overridden**

### RepeatFindReverse < RepeatFind
- command: `vim-mode-plus:repeat-find-reverse`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>,</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::isBackwards`()`: **Overridden**

### Till < Find
- command: `vim-mode-plus:till`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>t</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::offset: ```1```: **Overridden**
- ::find`()`: `super`: **Overridden**
- ::selectInclusive`(selection)`: `super`: **Overridden**

### TillBackwards < Till
- command: `vim-mode-plus:till-backwards`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>T</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::backwards: ```true```: **Overridden**

### MoveLeft < Motion
- command: `vim-mode-plus:move-left`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>h</kbd>
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>left</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::moveCursor`(cursor)`

### MoveRight < Motion
- command: `vim-mode-plus:move-right`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>l</kbd>
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>space</kbd>
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>right</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::composed: ```false```
- ::onDidComposeBy`(operation)`
- ::isOperatorPending`()`
- ::moveCursor`(cursor)`

### MoveToBeginningOfLine < Motion
- command: `vim-mode-plus:move-to-beginning-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>0</kbd>
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>home</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::defaultCount: ```null```: **Overridden**
- ::initialize`()`
- ::moveCursor`(cursor)`

### MoveToEndOfWord < Motion
- command: `vim-mode-plus:move-to-end-of-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>e</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::wordRegex: ```null```
- ::inclusive: ```true```: **Overridden**
- ::getNext`(cursor)`
- ::moveCursor`(cursor)`

### MoveToEndOfWholeWord < MoveToEndOfWord
- command: `vim-mode-plus:move-to-end-of-whole-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>E</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::wordRegex: ```/\S+/```: **Overridden**

### MoveToFirstCharacterOfLine < Motion
- command: `vim-mode-plus:move-to-first-character-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>^</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::moveCursor`(cursor)`

### MoveToFirstCharacterOfLineDown < MoveToFirstCharacterOfLine
- command: `vim-mode-plus:move-to-first-character-of-line-down`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>+</kbd>
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>enter</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::linewise: ```true```: **Overridden**
- ::moveCursor`(cursor)`: `super`: **Overridden**

### MoveToFirstCharacterOfLineAndDown < MoveToFirstCharacterOfLineDown
- command: `vim-mode-plus:move-to-first-character-of-line-and-down`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>\_</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::defaultCount: ```0```: **Overridden**
- ::getCount`()`: **Overridden**

### MoveToFirstCharacterOfLineUp < MoveToFirstCharacterOfLine
- command: `vim-mode-plus:move-to-first-character-of-line-up`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>-</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::linewise: ```true```: **Overridden**
- ::moveCursor`(cursor)`: `super`: **Overridden**

### MoveToFirstLine < Motion
- command: `vim-mode-plus:move-to-first-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g g</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::linewise: ```true```: **Overridden**
- ::defaultCount: ```null```: **Overridden**
- ::getRow`()`
- ::getDefaultRow`()`
- ::moveCursor`(cursor)`

### MoveToLastLine < MoveToFirstLine
- command: `vim-mode-plus:move-to-last-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>G</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::getDefaultRow`()`: **Overridden**

### MoveToLastCharacterOfLine < Motion
- command: `vim-mode-plus:move-to-last-character-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>$</kbd>
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>end</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::moveCursor`(cursor)`

### MoveToLastNonblankCharacterOfLineAndDown < Motion
- command: `vim-mode-plus:move-to-last-nonblank-character-of-line-and-down`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g \_</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::inclusive: ```true```: **Overridden**
- ::skipTrailingWhitespace`(cursor)`
- ::getCount`()`: **Overridden**
- ::moveCursor`(cursor)`

### MoveToMark < Motion
- command: `vim-mode-plus:move-to-mark`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>\`</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::linewise: ```true```: **Overridden**
- ::hoverText: ```':round_pushpin:\''```: **Overridden**
- ::hoverIcon: ```':move-to-mark:\''```: **Overridden**

### MoveToNextParagraph < Motion
- command: `vim-mode-plus:move-to-next-paragraph`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>}</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::moveCursor`(cursor)`

### MoveToNextWord < Motion
- command: `vim-mode-plus:move-to-next-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>w</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::wordRegex: ```null```
- ::getNext`(cursor)`
- ::moveCursor`(cursor)`

### MoveToNextWholeWord < MoveToNextWord
- command: `vim-mode-plus:move-to-next-whole-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>W</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::wordRegex: ```/^\s*$|\S+/```: **Overridden**

### MoveToPreviousParagraph < Motion
- command: `vim-mode-plus:move-to-previous-paragraph`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>{</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::moveCursor`(cursor)`

### MoveToPreviousWholeWord < Motion
- command: `vim-mode-plus:move-to-previous-whole-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>B</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::wordRegex: ```/^\s*$|\S+/```
- ::moveCursor`(cursor)`

### MoveToPreviousWord < Motion
- command: `vim-mode-plus:move-to-previous-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>b</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::moveCursor`(cursor)`

### MoveToRelativeLine < Motion
- command: `vim-mode-plus:move-to-relative-line`
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::linewise: ```true```: **Overridden**
- ::moveCursor`(cursor)`
- ::getCount`()`: **Overridden**

### MoveToTopOfScreen < Motion
- command: `vim-mode-plus:move-to-top-of-screen`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>H</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::getRow`()`: **Overridden**

### MoveToMiddleOfScreen < MoveToTopOfScreen
- command: `vim-mode-plus:move-to-middle-of-screen`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>M</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::getRow`()`: **Overridden**

### MoveUp < Motion
- command: `vim-mode-plus:move-up`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>k</kbd>
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>up</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::linewise: ```true```: **Overridden**
- ::amount: ```1```: **Overridden**
- ::isMovable`(cursor)`: **Overridden**
- ::move`(cursor)`: **Overridden**

### ScrollFullScreenDown < Motion
- command: `vim-mode-plus:scroll-full-screen-down`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>ctrl-f</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::coefficient: ```-1```: **Overridden**

### ScrollHalfScreenDown < ScrollFullScreenDown
- command: `vim-mode-plus:scroll-half-screen-down`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>ctrl-d</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::coefficient: ```0.5```: **Overridden**

### ScrollHalfScreenUp < ScrollHalfScreenDown
- command: `vim-mode-plus:scroll-half-screen-up`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>ctrl-u</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::coefficient: ```-0.5```: **Overridden**

### SearchBase < Motion
*Not exported*
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::complete: ```true```: **Overridden**
- ::saveCurrentSearch: ```false```: **Overridden**
- ::initialize`()`: `super`: **Overridden**

### RepeatSearchReverse < RepeatSearch
- command: `vim-mode-plus:repeat-search-reverse`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>N</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::isBackwards`()`: **Overridden**

### Search < SearchBase
- command: `vim-mode-plus:search`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>/</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::backwards: ```true```: **Overridden**

### SearchCurrentWord < SearchBase
- command: `vim-mode-plus:search-current-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>*</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::wordRegex: ```null```
- ::complete: ```true```: **Overridden**
- ::initialize`()`: `super`: **Overridden**
- ::getPattern`(text)`: **Overridden**
- ::getCurrentWord`()`

### SearchCurrentWordBackwards < SearchCurrentWord
- command: `vim-mode-plus:search-current-word-backwards`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>#</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Motion'```
- ::backwards: ```true```: **Overridden**

### Operator < Base
- command: `vim-mode-plus:operator`
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::complete: ```true```: **Overridden**
- ::typedText: ```null```
- ::flashTarget: ```false```: **Overridden**
- ::confirmChanges`(changes)`
- ::execute`()`

### ActivateReplaceMode < ActivateInsertMode
- command: `vim-mode-plus:activate-replace-mode`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>R</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::execute`()`: **Overridden**
- ::countChars`(char, string)`

### Change < ActivateInsertMode
- command: `vim-mode-plus:change`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>c</kbd>
    - `atom-text-editor.vim-mode-plus.visual-mode`: <kbd>s</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::complete: ```false```: **Overridden**
- ::execute`()`: `super`: **Overridden**

### ChangeToLastCharacterOfLine < Change
- command: `vim-mode-plus:change-to-last-character-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>C</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::initialize`()`

### Substitute < Change
- command: `vim-mode-plus:substitute`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>s</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::initialize`()`

### SubstituteLine < Change
- command: `vim-mode-plus:substitute-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>S</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::initialize`()`

### InsertAboveWithNewline < ActivateInsertMode
- command: `vim-mode-plus:insert-above-with-newline`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>O</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::direction: ```'above'```
- ::execute`()`: `super`: **Overridden**

### InsertBelowWithNewline < InsertAboveWithNewline
- command: `vim-mode-plus:insert-below-with-newline`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>o</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::direction: ```'below'```: **Overridden**

### InsertAfter < ActivateInsertMode
- command: `vim-mode-plus:insert-after`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>a</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::execute`()`: `super`: **Overridden**

### InsertAfterEndOfLine < ActivateInsertMode
- command: `vim-mode-plus:insert-after-end-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>A</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::execute`()`: `super`: **Overridden**

### InsertAtBeginningOfLine < ActivateInsertMode
- command: `vim-mode-plus:insert-at-beginning-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>I</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::execute`()`: `super`: **Overridden**

### Delete < Operator
- command: `vim-mode-plus:delete`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>d</kbd>
    - `atom-text-editor.vim-mode-plus.visual-mode`: <kbd>x</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::hoverText: ```':scissors:'```
- ::hoverIcon: ```':delete:'```
- ::flashTarget: ```false```: **Overridden**
- ::execute`()`

### DeleteLeft < Delete
- command: `vim-mode-plus:delete-left`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>X</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::initialize`()`

### DeleteRight < Delete
- command: `vim-mode-plus:delete-right`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>x</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::initialize`()`

### DeleteToLastCharacterOfLine < Delete
- command: `vim-mode-plus:delete-to-last-character-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>D</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::initialize`()`

### Increase < Operator
- command: `vim-mode-plus:increase`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>ctrl-a</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::complete: ```true```: **Overridden**
- ::step: ```1```
- ::execute`()`
- ::increaseNumber`(cursor, pattern)`

### Decrease < Increase
- command: `vim-mode-plus:decrease`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>ctrl-x</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::step: ```-1```: **Overridden**

### Indent < Operator
- command: `vim-mode-plus:indent`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>></kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::hoverText: ```':point_right:'```
- ::hoverIcon: ```':indent:'```
- ::execute`()`
- ::indent`(s)`

### AutoIndent < Indent
- command: `vim-mode-plus:auto-indent`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>=</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::hoverText: ```':open_hands:'```: **Overridden**
- ::hoverIcon: ```':auto-indent:'```: **Overridden**
- ::indent`(s)`: **Overridden**

### Outdent < Indent
- command: `vim-mode-plus:outdent`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd><</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::hoverText: ```':point_left:'```: **Overridden**
- ::hoverIcon: ```':outdent:'```: **Overridden**
- ::indent`(s)`: **Overridden**

### Join < Operator
- command: `vim-mode-plus:join`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>J</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::complete: ```true```: **Overridden**
- ::execute`()`

### Mark < Operator
- command: `vim-mode-plus:mark`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>m</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::hoverText: ```':round_pushpin:'```
- ::hoverIcon: ```':mark:'```
- ::requireInput: ```true```: **Overridden**
- ::initialize`()`
- ::execute`()`

### PutBefore < Operator
- command: `vim-mode-plus:put-before`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>P</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::complete: ```true```: **Overridden**
- ::location: ```'before'```
- ::execute`()`
- ::pasteLinewise`(selection, text)`
- ::pasteCharacterwise`(selection, text)`

### PutAfter < PutBefore
- command: `vim-mode-plus:put-after`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>p</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::location: ```'after'```: **Overridden**

### Repeat < Operator
- command: `vim-mode-plus:repeat`
  - keymaps
    - `atom-text-editor.vim-mode-plus.normal-mode`: <kbd>.</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::complete: ```true```: **Overridden**
- ::recodable: ```false```: **Overridden**
- ::execute`()`

### Replace < Operator
- command: `vim-mode-plus:replace`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>r</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::input: ```null```
- ::hoverText: ```':tractor:'```
- ::requireInput: ```true```: **Overridden**
- ::initialize`()`
- ::isComplete`()`: `super`: **Overridden**
- ::execute`()`

### ReplaceWithRegister < Operator
- command: `vim-mode-plus:replace-with-register`
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::hoverText: ```':pencil:'```
- ::hoverIcon: ```':replace-with-register:'```
- ::execute`()`

### Select < Operator
- command: `vim-mode-plus:select`
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::execute`()`

### ToggleLineComments < Operator
- command: `vim-mode-plus:toggle-line-comments`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g /</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::hoverText: ```':mute:'```
- ::hoverIcon: ```':toggle-line-comment:'```
- ::execute`()`

### TransformString < Operator
*Not exported*
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::adjustCursor: ```true```
- ::execute`()`

### CamelCase < TransformString
- command: `vim-mode-plus:camel-case`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g c</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::hoverText: ```':camel:'```
- ::hoverIcon: ```':camel-case:'```
- ::getNewText`(text)`

### DashCase < TransformString
- command: `vim-mode-plus:dash-case`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g -</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::hoverText: ```':dash:'```
- ::hoverIcon: ```':dash-case:'```
- ::getNewText`(text)`

### LowerCase < TransformString
- command: `vim-mode-plus:lower-case`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g u</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>u</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::hoverText: ```':point_down:'```
- ::hoverIcon: ```':lower-case:'```
- ::getNewText`(text)`

### SnakeCase < TransformString
- command: `vim-mode-plus:snake-case`
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::hoverText: ```':snake:'```
- ::hoverIcon: ```':snake-case:'```
- ::getNewText`(text)`

### Surround < TransformString
- command: `vim-mode-plus:surround`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g s s</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::pairChars: ```'[](){}'```
- ::onConfirm`(@input)`: **Overridden**
- ::getNewText`(text)`: **Overridden**

### ChangeSurround < DeleteSurround
- command: `vim-mode-plus:change-surround`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g s c</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::charsMax: ```2```: **Overridden**
- ::char: ```null```
- ::onConfirm`(input)`: `super(from)`: **Overridden**
- ::getNewText`(text)`: `super(text), @getPair(@char))`: **Overridden**

### ChangeSurroundAnyPair < ChangeSurround
- command: `vim-mode-plus:change-surround-any-pair`
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::charsMax: ```1```: **Overridden**
- ::initialize`()`: `super`: **Overridden**
- ::preSelect`()`
- ::onConfirm`(@char)`: **Overridden**

### DeleteSurroundAnyPair < DeleteSurround
- command: `vim-mode-plus:delete-surround-any-pair`
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::requireInput: ```false```: **Overridden**
- ::initialize`()`: `super`: **Overridden**

### SurroundWord < Surround
- command: `vim-mode-plus:surround-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g s w</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::initialize`()`: `super`: **Overridden**

### ToggleCase < TransformString
- command: `vim-mode-plus:toggle-case`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g ~</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>~</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::hoverText: ```':clap:'```
- ::hoverIcon: ```':toggle-case:'```
- ::toggleCase`(char)`
- ::getNewText`(text)`

### ToggleCaseAndMoveRight < ToggleCase
- command: `vim-mode-plus:toggle-case-and-move-right`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>~</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::hoverText: ```null```: **Overridden**
- ::hoverIcon: ```null```: **Overridden**
- ::adjustCursor: ```false```: **Overridden**
- ::initialize`()`

### UpperCase < TransformString
- command: `vim-mode-plus:upper-case`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>g U</kbd>
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>U</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::hoverText: ```':point_up:'```
- ::hoverIcon: ```':upper-case:'```
- ::getNewText`(text)`

### Yank < Operator
- command: `vim-mode-plus:yank`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>y</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::hoverText: ```':clipboard:'```
- ::hoverIcon: ```':yank:'```
- ::execute`()`

### YankLine < Yank
- command: `vim-mode-plus:yank-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>Y</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Operator'```
- ::initialize`()`

### OperatorError < Base
- command: `vim-mode-plus:operator-error`
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- ::constructor`(@message)`: **Overridden**

### Scroll < Base
*Not exported*
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Scroll'```
- ::complete: ```true```: **Overridden**
- ::scrolloff: ```2```
- ::getFirstVisibleScreenRow`()`
- ::getLastVisibleScreenRow`()`
- ::getLastScreenRow`()`
- ::getPixelCursor`(which)`

### ScrollCursor < Scroll
*Not exported*
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Scroll'```
- ::execute`()`
- ::moveToFirstCharacterOfLine`()`
- ::getOffSetPixelHeight`(lineDelta)`

### ScrollCursorToBottom < ScrollCursor
- command: `vim-mode-plus:scroll-cursor-to-bottom`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>z -</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Scroll'```
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToBottomLeave < ScrollCursorToBottom
- command: `vim-mode-plus:scroll-cursor-to-bottom-leave`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>z b</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Scroll'```
- ::moveToFirstCharacterOfLine: ```null```: **Overridden**

### ScrollCursorToMiddle < ScrollCursor
- command: `vim-mode-plus:scroll-cursor-to-middle`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>z .</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Scroll'```
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToMiddleLeave < ScrollCursorToMiddle
- command: `vim-mode-plus:scroll-cursor-to-middle-leave`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>z z</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Scroll'```
- ::moveToFirstCharacterOfLine: ```null```: **Overridden**

### ScrollCursorToTop < ScrollCursor
- command: `vim-mode-plus:scroll-cursor-to-top`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>z enter</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Scroll'```
- ::isScrollable`()`
- ::getScrollTop`()`

### ScrollCursorToTopLeave < ScrollCursorToTop
- command: `vim-mode-plus:scroll-cursor-to-top-leave`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>z t</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Scroll'```
- ::moveToFirstCharacterOfLine: ```null```: **Overridden**

### ScrollCursorToLeft < Scroll
- command: `vim-mode-plus:scroll-cursor-to-left`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>z s</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Scroll'```
- ::direction: ```'left'```
- ::initialize`()`
- ::execute`()`

### ScrollCursorToRight < ScrollCursorToLeft
- command: `vim-mode-plus:scroll-cursor-to-right`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>z e</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Scroll'```
- ::direction: ```'right'```: **Overridden**
- ::execute`()`: **Overridden**

### ScrollDown < Scroll
- command: `vim-mode-plus:scroll-down`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>ctrl-e</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Scroll'```
- ::direction: ```'down'```
- ::execute`()`
- ::keepCursorOnScreen`()`

### ScrollUp < ScrollDown
- command: `vim-mode-plus:scroll-up`
  - keymaps
    - `atom-text-editor.vim-mode-plus:not(.insert-mode)`: <kbd>ctrl-y</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'Scroll'```
- ::direction: ```'up'```: **Overridden**

### TextObject < Base
*Not exported*
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
- ::select`()`

### Entire < TextObject
- command: `vim-mode-plus:a-entire`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a e</kbd>
- command: `vim-mode-plus:inner-entire`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i e</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
- ::select`()`

### Fold < TextObject
- command: `vim-mode-plus:a-fold`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a z</kbd>
- command: `vim-mode-plus:inner-fold`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i z</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
- ::getFoldRowRangeForBufferRow`(bufferRow)`
- ::select`()`

### Function < Fold
- command: `vim-mode-plus:a-function`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a f</kbd>
- command: `vim-mode-plus:inner-function`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i f</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
- ::indentScopedLanguages: ```[ 'python', 'coffee' ]```
- ::omitingClosingCharLanguages: ```[ 'go' ]```
- ::initialize`()`
- ::getScopesForRow`(row)`
- ::isFunctionScope`(scope)`
- ::isIncludeFunctionScopeForRow`(row)`
- ::getFoldRowRangeForBufferRow`(bufferRow)`: **Overridden**
- ::adjustRowRange`(startRow, endRow)`

### Pair < TextObject
*Not exported*
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
- ::pair: ```'<>'```: **Overridden**

### AnyPair < Pair
- command: `vim-mode-plus:a-any-pair`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a s</kbd>
- command: `vim-mode-plus:inner-any-pair`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i s</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
- ::pair: ```'{}'```: **Overridden**
- ::allowNextLine: ```true```: **Overridden**

### DoubleQuote < Pair
- command: `vim-mode-plus:a-double-quote`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a "</kbd>
- command: `vim-mode-plus:inner-double-quote`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i "</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
- ::pair: ```'()'```: **Overridden**
- ::allowNextLine: ```true```: **Overridden**

### SingleQuote < Pair
- command: `vim-mode-plus:a-single-quote`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a '</kbd>
- command: `vim-mode-plus:inner-single-quote`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i '</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
- ::pair: ```'[]'```: **Overridden**
- ::allowNextLine: ```true```: **Overridden**

### Tag < Pair
- command: `vim-mode-plus:a-tag`
- command: `vim-mode-plus:inner-tag`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i t</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
- ::pair: ```'><'```: **Overridden**

### Paragraph < TextObject
- command: `vim-mode-plus:a-paragraph`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a p</kbd>
- command: `vim-mode-plus:inner-paragraph`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i p</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
- ::selectInclusive`(selection)`: **Overridden**
- ::getRange`(startRow)`: **Overridden**

### Indentation < Paragraph
- command: `vim-mode-plus:a-indentation`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a i</kbd>
- command: `vim-mode-plus:inner-indentation`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i i</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
- ::selectInclusive`(selection)`: **Overridden**
- ::getRange`(startRow)`: **Overridden**

### Word < TextObject
- command: `vim-mode-plus:a-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>a w</kbd>
- command: `vim-mode-plus:inner-word`
  - keymaps
    - `atom-text-editor.vim-mode-plus.operator-pending-mode, atom-text-editor.vim-mode-plus.visual-mode`: <kbd>i w</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'TextObject'```
- ::wordRegExp: ```/\S+/```
- ::selectExclusive`(s, wordRegex)`: **Overridden**

### VisualBlockwise < Base
*Not exported*
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'VisualBlockwise'```
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
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'VisualBlockwise'```
- ::delegateTo: ```'DeleteToLastCharacterOfLine'```
- ::execute`()`

### BlockwiseChangeToLastCharacterOfLine < BlockwiseDeleteToLastCharacterOfLine
- command: `vim-mode-plus:blockwise-change-to-last-character-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>C</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'VisualBlockwise'```
- ::delegateTo: ```'ChangeToLastCharacterOfLine'```: **Overridden**

### BlockwiseInsertAtBeginningOfLine < VisualBlockwise
- command: `vim-mode-plus:blockwise-insert-at-beginning-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>I</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'VisualBlockwise'```
- ::after: ```false```
- ::execute`()`

### BlockwiseInsertAfterEndOfLine < BlockwiseInsertAtBeginningOfLine
- command: `vim-mode-plus:blockwise-insert-after-end-of-line`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>A</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'VisualBlockwise'```
- ::after: ```true```: **Overridden**

### BlockwiseMoveDown < VisualBlockwise
- command: `vim-mode-plus:blockwise-move-down`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>j</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'VisualBlockwise'```
- ::direction: ```'Below'```
- ::isExpanding`()`
- ::execute`()`

### BlockwiseMoveUp < BlockwiseMoveDown
- command: `vim-mode-plus:blockwise-move-up`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>k</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'VisualBlockwise'```
- ::direction: ```'Above'```: **Overridden**

### BlockwiseOtherEnd < VisualBlockwise
- command: `vim-mode-plus:blockwise-other-end`
  - keymaps
    - `atom-text-editor.vim-mode-plus.visual-mode.blockwise`: <kbd>o</kbd>
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'VisualBlockwise'```
- ::execute`()`

### BlockwiseRestoreCharacterwise < VisualBlockwise
- command: `vim-mode-plus:blockwise-restore-characterwise`
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'VisualBlockwise'```
- ::execute`()`

### BlockwiseSelect < VisualBlockwise
- command: `vim-mode-plus:blockwise-select`
- @init`(service)`
- @getCommandName`()`
- @getCommands`()`
- @run`(properties)`
- @registerCommands`()`
- @kind: ```'VisualBlockwise'```
- ::execute`()`
