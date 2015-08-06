# OperatorError
- @extend

# Operator
- @extend
- ::vimState
- ::target
- ::complete
- ::isComplete
- ::isRecordable
- ::compose
- ::canComposeWith
- ::setTextRegister

# MotionError
- @extend

# Motion
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

# MotionWithInput
- @extend
- ::isComplete
- ::canComposeWith
- ::compose

# MoveLeft
- @extend
- ::operatesInclusively
- ::moveCursor

# MoveRight
- @extend
- ::operatesInclusively
- ::moveCursor

# MoveUp
- @extend
- ::operatesLinewise
- ::moveCursor

# MoveDown
- @extend
- ::operatesLinewise
- ::moveCursor

# MoveToPreviousWord
- @extend
- ::operatesInclusively
- ::moveCursor

# MoveToPreviousWholeWord
- @extend
- ::operatesInclusively
- ::moveCursor
- ::isWholeWord
- ::isBeginningOfFile

# MoveToNextWord
- @extend
- ::wordRegex
- ::operatesInclusively
- ::moveCursor
- ::isEndOfFile

# MoveToNextWholeWord
- @extend
- ::wordRegex

# MoveToEndOfWord
- @extend
- ::wordRegex
- ::moveCursor

# MoveToEndOfWholeWord
- @extend
- ::wordRegex

# MoveToNextParagraph
- @extend
- ::operatesInclusively
- ::moveCursor

# MoveToPreviousParagraph
- @extend
- ::moveCursor

# MoveToLine
- @extend
- ::operatesLinewise
- ::getDestinationRow

# MoveToAbsoluteLine
- @extend
- ::moveCursor

# MoveToRelativeLine
- @extend
- ::operatesLinewise
- ::moveCursor

# MoveToScreenLine
- @extend
- ::moveCursor

# MoveToBeginningOfLine
- @extend
- ::operatesInclusively
- ::moveCursor

# MoveToFirstCharacterOfLine
- @extend
- ::operatesInclusively
- ::moveCursor

# MoveToFirstCharacterOfLineAndDown
- @extend
- ::operatesLinewise
- ::operatesInclusively
- ::moveCursor

# MoveToLastCharacterOfLine
- @extend
- ::operatesInclusively
- ::moveCursor

# MoveToLastNonblankCharacterOfLineAndDown
- @extend
- ::operatesInclusively
- ::skipTrailingWhitespace
- ::moveCursor

# MoveToFirstCharacterOfLineUp
- @extend
- ::operatesLinewise
- ::operatesInclusively
- ::moveCursor

# MoveToFirstCharacterOfLineDown
- @extend
- ::operatesLinewise
- ::moveCursor

# MoveToStartOfFile
- @extend
- ::moveCursor

# MoveToTopOfScreen
- @extend
- ::getDestinationRow

# MoveToBottomOfScreen
- @extend
- ::getDestinationRow

# MoveToMiddleOfScreen
- @extend
- ::getDestinationRow

# ScrollKeepingCursor
- @extend
- ::previousFirstScreenRow
- ::currentFirstScreenRow
- ::select
- ::execute
- ::moveCursor
- ::getDestinationRow
- ::scrollScreen

# ScrollHalfUpKeepCursor
- @extend
- ::scrollDestination

# ScrollFullUpKeepCursor
- @extend
- ::scrollDestination

# ScrollHalfDownKeepCursor
- @extend
- ::scrollDestination

# ScrollFullDownKeepCursor
- @extend
- ::scrollDestination

# Find
- @extend
- ::match
- ::reverse
- ::moveCursor

# Till
- @extend
- ::match
- ::moveSelectionInclusively

# MoveToMark
- @extend
- ::operatesInclusively
- ::isLinewise
- ::moveCursor

# SearchBase
- @extend
- ::operatesInclusively
- ::reversed
- ::moveCursor
- ::scan
- ::getSearchTerm
- ::updateCurrentSearch
- ::replicateCurrentSearch

# Search
- @extend

# SearchCurrentWord
- @extend
- @keywordRegex
- ::getCurrentWord
- ::cursorIsOnEOF
- ::getCurrentWordMatch
- ::isComplete
- ::execute

# BracketMatchingMotion
- @extend
- ::operatesInclusively
- ::isComplete
- ::searchForMatch
- ::characterAt
- ::getSearchData
- ::moveCursor

# RepeatSearch
- @extend
- ::isComplete
- ::reversed

# TextObject
- @extend
- ::isComplete
- ::isRecordable
