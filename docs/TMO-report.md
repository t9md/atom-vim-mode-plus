# Class OperatorError
- @extend

# Class Operator
- @extend
- ::vimState
- ::target
- ::complete
- ::isComplete
- ::isRecordable
- ::compose
- ::canComposeWith
- ::setTextRegister

# Class MotionError
- @extend

# Class Motion
- @extend
- ::operatesInclusively
- ::operatesLinewise
- ::select
- ::execute
- ::moveSelectionLinewise
- ::moveSelectionInclusively
- ::moveSelection
- ::isComplete
- ::isRecordable
- ::isLinewise
- ::isInclusive

# Class MotionWithInput
- @extend
- ::isComplete
- ::canComposeWith
- ::compose

# Class MoveLeft
- @extend
- ::operatesInclusively
- ::moveCursor

# Class MoveRight
- @extend
- ::operatesInclusively
- ::moveCursor

# Class MoveUp
- @extend
- ::operatesLinewise
- ::moveCursor

# Class MoveDown
- @extend
- ::operatesLinewise
- ::moveCursor

# Class MoveToPreviousWord
- @extend
- ::operatesInclusively
- ::moveCursor

# Class MoveToPreviousWholeWord
- @extend
- ::operatesInclusively
- ::moveCursor
- ::isWholeWord
- ::isBeginningOfFile

# Class MoveToNextWord
- @extend
- ::wordRegex
- ::operatesInclusively
- ::moveCursor
- ::isEndOfFile

# Class MoveToNextWholeWord
- @extend
- ::wordRegex

# Class MoveToEndOfWord
- @extend
- ::wordRegex
- ::moveCursor

# Class MoveToEndOfWholeWord
- @extend
- ::wordRegex

# Class MoveToNextParagraph
- @extend
- ::operatesInclusively
- ::moveCursor

# Class MoveToPreviousParagraph
- @extend
- ::moveCursor

# Class MoveToLine
- @extend
- ::operatesLinewise
- ::getDestinationRow

# Class MoveToAbsoluteLine
- @extend
- ::moveCursor

# Class MoveToRelativeLine
- @extend
- ::operatesLinewise
- ::moveCursor

# Class MoveToScreenLine
- @extend
- ::moveCursor

# Class MoveToBeginningOfLine
- @extend
- ::operatesInclusively
- ::moveCursor

# Class MoveToFirstCharacterOfLine
- @extend
- ::operatesInclusively
- ::moveCursor

# Class MoveToFirstCharacterOfLineAndDown
- @extend
- ::operatesLinewise
- ::operatesInclusively
- ::moveCursor

# Class MoveToLastCharacterOfLine
- @extend
- ::operatesInclusively
- ::moveCursor

# Class MoveToLastNonblankCharacterOfLineAndDown
- @extend
- ::operatesInclusively
- ::skipTrailingWhitespace
- ::moveCursor

# Class MoveToFirstCharacterOfLineUp
- @extend
- ::operatesLinewise
- ::operatesInclusively
- ::moveCursor

# Class MoveToFirstCharacterOfLineDown
- @extend
- ::operatesLinewise
- ::moveCursor

# Class MoveToStartOfFile
- @extend
- ::moveCursor

# Class MoveToTopOfScreen
- @extend
- ::getDestinationRow

# Class MoveToBottomOfScreen
- @extend
- ::getDestinationRow

# Class MoveToMiddleOfScreen
- @extend
- ::getDestinationRow

# Class ScrollKeepingCursor
- @extend
- ::previousFirstScreenRow
- ::currentFirstScreenRow
- ::select
- ::execute
- ::moveCursor
- ::getDestinationRow
- ::scrollScreen

# Class ScrollHalfUpKeepCursor
- @extend
- ::scrollDestination

# Class ScrollFullUpKeepCursor
- @extend
- ::scrollDestination

# Class ScrollHalfDownKeepCursor
- @extend
- ::scrollDestination

# Class ScrollFullDownKeepCursor
- @extend
- ::scrollDestination

# Class Find
- @extend
- ::match
- ::reverse
- ::moveCursor

# Class Till
- @extend
- ::match
- ::moveSelectionInclusively

# Class MoveToMark
- @extend
- ::operatesInclusively
- ::isLinewise
- ::moveCursor

# Class SearchBase
- @extend
- ::operatesInclusively
- ::reversed
- ::moveCursor
- ::scan
- ::getSearchTerm
- ::updateCurrentSearch
- ::replicateCurrentSearch

# Class Search
- @extend

# Class SearchCurrentWord
- @extend
- @keywordRegex
- ::getCurrentWord
- ::cursorIsOnEOF
- ::getCurrentWordMatch
- ::isComplete
- ::execute

# Class BracketMatchingMotion
- @extend
- ::operatesInclusively
- ::isComplete
- ::searchForMatch
- ::characterAt
- ::getSearchData
- ::moveCursor

# Class RepeatSearch
- @extend
- ::isComplete
- ::reversed

# Class TextObject
- @extend
- ::isComplete
- ::isRecordable
