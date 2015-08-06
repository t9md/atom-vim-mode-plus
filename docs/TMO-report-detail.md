# Class OperatorError
- @extend: [Function]

# Class Operator
- @extend: [Function]
- ::vimState: null
- ::target: null
- ::complete: null
- ::isComplete: [Function]
- ::isRecordable: [Function]
- ::compose: [Function]
- ::canComposeWith: [Function]
- ::setTextRegister: [Function]

# Class MotionError
- @extend: [Function]

# Class Motion
- @extend: [Function]
- ::operatesInclusively: true
- ::operatesLinewise: false
- ::select: [Function]
- ::execute: [Function]
- ::moveSelectionLinewise: [Function]
- ::moveSelectionInclusively: [Function]
- ::moveSelection: [Function]
- ::isComplete: [Function]
- ::isRecordable: [Function]
- ::isLinewise: [Function]
- ::isInclusive: [Function]

# Class MotionWithInput
- @extend: [Function]
- ::isComplete: [Function]
- ::canComposeWith: [Function]
- ::compose: [Function]

# Class MoveLeft
- @extend: [Function]
- ::operatesInclusively: false
- ::moveCursor: [Function]

# Class MoveRight
- @extend: [Function]
- ::operatesInclusively: false
- ::moveCursor: [Function]

# Class MoveUp
- @extend: [Function]
- ::operatesLinewise: true
- ::moveCursor: [Function]

# Class MoveDown
- @extend: [Function]
- ::operatesLinewise: true
- ::moveCursor: [Function]

# Class MoveToPreviousWord
- @extend: [Function]
- ::operatesInclusively: false
- ::moveCursor: [Function]

# Class MoveToPreviousWholeWord
- @extend: [Function]
- ::operatesInclusively: false
- ::moveCursor: [Function]
- ::isWholeWord: [Function]
- ::isBeginningOfFile: [Function]

# Class MoveToNextWord
- @extend: [Function]
- ::wordRegex: null
- ::operatesInclusively: false
- ::moveCursor: [Function]
- ::isEndOfFile: [Function]

# Class MoveToNextWholeWord
- @extend: [Function]
- ::wordRegex: /^\s*$|\S+/

# Class MoveToEndOfWord
- @extend: [Function]
- ::wordRegex: null
- ::moveCursor: [Function]

# Class MoveToEndOfWholeWord
- @extend: [Function]
- ::wordRegex: /\S+/

# Class MoveToNextParagraph
- @extend: [Function]
- ::operatesInclusively: false
- ::moveCursor: [Function]

# Class MoveToPreviousParagraph
- @extend: [Function]
- ::moveCursor: [Function]

# Class MoveToLine
- @extend: [Function]
- ::operatesLinewise: true
- ::getDestinationRow: [Function]

# Class MoveToAbsoluteLine
- @extend: [Function]
- ::moveCursor: [Function]

# Class MoveToRelativeLine
- @extend: [Function]
- ::operatesLinewise: true
- ::moveCursor: [Function]

# Class MoveToScreenLine
- @extend: [Function]
- ::moveCursor: [Function]

# Class MoveToBeginningOfLine
- @extend: [Function]
- ::operatesInclusively: false
- ::moveCursor: [Function]

# Class MoveToFirstCharacterOfLine
- @extend: [Function]
- ::operatesInclusively: false
- ::moveCursor: [Function]

# Class MoveToFirstCharacterOfLineAndDown
- @extend: [Function]
- ::operatesLinewise: true
- ::operatesInclusively: true
- ::moveCursor: [Function]

# Class MoveToLastCharacterOfLine
- @extend: [Function]
- ::operatesInclusively: false
- ::moveCursor: [Function]

# Class MoveToLastNonblankCharacterOfLineAndDown
- @extend: [Function]
- ::operatesInclusively: true
- ::skipTrailingWhitespace: [Function]
- ::moveCursor: [Function]

# Class MoveToFirstCharacterOfLineUp
- @extend: [Function]
- ::operatesLinewise: true
- ::operatesInclusively: true
- ::moveCursor: [Function]

# Class MoveToFirstCharacterOfLineDown
- @extend: [Function]
- ::operatesLinewise: true
- ::moveCursor: [Function]

# Class MoveToStartOfFile
- @extend: [Function]
- ::moveCursor: [Function]

# Class MoveToTopOfScreen
- @extend: [Function]
- ::getDestinationRow: [Function]

# Class MoveToBottomOfScreen
- @extend: [Function]
- ::getDestinationRow: [Function]

# Class MoveToMiddleOfScreen
- @extend: [Function]
- ::getDestinationRow: [Function]

# Class ScrollKeepingCursor
- @extend: [Function]
- ::previousFirstScreenRow: 0
- ::currentFirstScreenRow: 0
- ::select: [Function]
- ::execute: [Function]
- ::moveCursor: [Function]
- ::getDestinationRow: [Function]
- ::scrollScreen: [Function]

# Class ScrollHalfUpKeepCursor
- @extend: [Function]
- ::scrollDestination: [Function]

# Class ScrollFullUpKeepCursor
- @extend: [Function]
- ::scrollDestination: [Function]

# Class ScrollHalfDownKeepCursor
- @extend: [Function]
- ::scrollDestination: [Function]

# Class ScrollFullDownKeepCursor
- @extend: [Function]
- ::scrollDestination: [Function]

# Class Find
- @extend: [Function]
- ::match: [Function]
- ::reverse: [Function]
- ::moveCursor: [Function]

# Class Till
- @extend: [Function]
- ::match: [Function]
- ::moveSelectionInclusively: [Function]

# Class MoveToMark
- @extend: [Function]
- ::operatesInclusively: false
- ::isLinewise: [Function]
- ::moveCursor: [Function]

# Class SearchBase
- @extend: [Function]
- ::operatesInclusively: false
- ::reversed: [Function]
- ::moveCursor: [Function]
- ::scan: [Function]
- ::getSearchTerm: [Function]
- ::updateCurrentSearch: [Function]
- ::replicateCurrentSearch: [Function]

# Class Search
- @extend: [Function]

# Class SearchCurrentWord
- @extend: [Function]
- @keywordRegex: null
- ::getCurrentWord: [Function]
- ::cursorIsOnEOF: [Function]
- ::getCurrentWordMatch: [Function]
- ::isComplete: [Function]
- ::execute: [Function]

# Class BracketMatchingMotion
- @extend: [Function]
- ::operatesInclusively: true
- ::isComplete: [Function]
- ::searchForMatch: [Function]
- ::characterAt: [Function]
- ::getSearchData: [Function]
- ::moveCursor: [Function]

# Class RepeatSearch
- @extend: [Function]
- ::isComplete: [Function]
- ::reversed: [Function]

# Class TextObject
- @extend: [Function]
- ::isComplete: [Function]
- ::isRecordable: [Function]
