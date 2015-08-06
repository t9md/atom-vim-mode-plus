# OperatorError
- @extend: [Function]

# Operator
- @extend: [Function]
- ::vimState: null
- ::target: null
- ::complete: null
- ::isComplete: [Function]
- ::isRecordable: [Function]
- ::compose: [Function]
- ::canComposeWith: [Function]
- ::setTextRegister: [Function]

# MotionError
- @extend: [Function]

# Motion
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

# MotionWithInput
- @extend: [Function]
- ::isComplete: [Function]
- ::canComposeWith: [Function]
- ::compose: [Function]

# MoveLeft
- @extend: [Function]
- ::operatesInclusively: false
- ::moveCursor: [Function]

# MoveRight
- @extend: [Function]
- ::operatesInclusively: false
- ::moveCursor: [Function]

# MoveUp
- @extend: [Function]
- ::operatesLinewise: true
- ::moveCursor: [Function]

# MoveDown
- @extend: [Function]
- ::operatesLinewise: true
- ::moveCursor: [Function]

# MoveToPreviousWord
- @extend: [Function]
- ::operatesInclusively: false
- ::moveCursor: [Function]

# MoveToPreviousWholeWord
- @extend: [Function]
- ::operatesInclusively: false
- ::moveCursor: [Function]
- ::isWholeWord: [Function]
- ::isBeginningOfFile: [Function]

# MoveToNextWord
- @extend: [Function]
- ::wordRegex: null
- ::operatesInclusively: false
- ::moveCursor: [Function]
- ::isEndOfFile: [Function]

# MoveToNextWholeWord
- @extend: [Function]
- ::wordRegex: /^\s*$|\S+/

# MoveToEndOfWord
- @extend: [Function]
- ::wordRegex: null
- ::moveCursor: [Function]

# MoveToEndOfWholeWord
- @extend: [Function]
- ::wordRegex: /\S+/

# MoveToNextParagraph
- @extend: [Function]
- ::operatesInclusively: false
- ::moveCursor: [Function]

# MoveToPreviousParagraph
- @extend: [Function]
- ::moveCursor: [Function]

# MoveToLine
- @extend: [Function]
- ::operatesLinewise: true
- ::getDestinationRow: [Function]

# MoveToAbsoluteLine
- @extend: [Function]
- ::moveCursor: [Function]

# MoveToRelativeLine
- @extend: [Function]
- ::operatesLinewise: true
- ::moveCursor: [Function]

# MoveToScreenLine
- @extend: [Function]
- ::moveCursor: [Function]

# MoveToBeginningOfLine
- @extend: [Function]
- ::operatesInclusively: false
- ::moveCursor: [Function]

# MoveToFirstCharacterOfLine
- @extend: [Function]
- ::operatesInclusively: false
- ::moveCursor: [Function]

# MoveToFirstCharacterOfLineAndDown
- @extend: [Function]
- ::operatesLinewise: true
- ::operatesInclusively: true
- ::moveCursor: [Function]

# MoveToLastCharacterOfLine
- @extend: [Function]
- ::operatesInclusively: false
- ::moveCursor: [Function]

# MoveToLastNonblankCharacterOfLineAndDown
- @extend: [Function]
- ::operatesInclusively: true
- ::skipTrailingWhitespace: [Function]
- ::moveCursor: [Function]

# MoveToFirstCharacterOfLineUp
- @extend: [Function]
- ::operatesLinewise: true
- ::operatesInclusively: true
- ::moveCursor: [Function]

# MoveToFirstCharacterOfLineDown
- @extend: [Function]
- ::operatesLinewise: true
- ::moveCursor: [Function]

# MoveToStartOfFile
- @extend: [Function]
- ::moveCursor: [Function]

# MoveToTopOfScreen
- @extend: [Function]
- ::getDestinationRow: [Function]

# MoveToBottomOfScreen
- @extend: [Function]
- ::getDestinationRow: [Function]

# MoveToMiddleOfScreen
- @extend: [Function]
- ::getDestinationRow: [Function]

# ScrollKeepingCursor
- @extend: [Function]
- ::previousFirstScreenRow: 0
- ::currentFirstScreenRow: 0
- ::select: [Function]
- ::execute: [Function]
- ::moveCursor: [Function]
- ::getDestinationRow: [Function]
- ::scrollScreen: [Function]

# ScrollHalfUpKeepCursor
- @extend: [Function]
- ::scrollDestination: [Function]

# ScrollFullUpKeepCursor
- @extend: [Function]
- ::scrollDestination: [Function]

# ScrollHalfDownKeepCursor
- @extend: [Function]
- ::scrollDestination: [Function]

# ScrollFullDownKeepCursor
- @extend: [Function]
- ::scrollDestination: [Function]

# Find
- @extend: [Function]
- ::match: [Function]
- ::reverse: [Function]
- ::moveCursor: [Function]

# Till
- @extend: [Function]
- ::match: [Function]
- ::moveSelectionInclusively: [Function]

# MoveToMark
- @extend: [Function]
- ::operatesInclusively: false
- ::isLinewise: [Function]
- ::moveCursor: [Function]

# SearchBase
- @extend: [Function]
- ::operatesInclusively: false
- ::reversed: [Function]
- ::moveCursor: [Function]
- ::scan: [Function]
- ::getSearchTerm: [Function]
- ::updateCurrentSearch: [Function]
- ::replicateCurrentSearch: [Function]

# Search
- @extend: [Function]

# SearchCurrentWord
- @extend: [Function]
- @keywordRegex: null
- ::getCurrentWord: [Function]
- ::cursorIsOnEOF: [Function]
- ::getCurrentWordMatch: [Function]
- ::isComplete: [Function]
- ::execute: [Function]

# BracketMatchingMotion
- @extend: [Function]
- ::operatesInclusively: true
- ::isComplete: [Function]
- ::searchForMatch: [Function]
- ::characterAt: [Function]
- ::getSearchData: [Function]
- ::moveCursor: [Function]

# RepeatSearch
- @extend: [Function]
- ::isComplete: [Function]
- ::reversed: [Function]

# TextObject
- @extend: [Function]
- ::isComplete: [Function]
- ::isRecordable: [Function]
