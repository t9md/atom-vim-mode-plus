# OperatorError < Base

# Operator < Base
- ::vimState
- ::target
- ::complete
- ::isComplete
- ::isRecordable
- ::compose
- ::canComposeWith
- ::setTextRegister

# OperatorWithInput < Operator < Base
- ::canComposeWith
- ::compose

# Select < Operator < Base
- ::execute

# Delete < Operator < Base
- ::register
- ::execute

# ToggleCase < Operator < Base
- ::execute

# UpperCase < Operator < Base
- ::execute

# LowerCase < Operator < Base
- ::execute

# Yank < Operator < Base
- ::register
- ::execute

# Join < Operator < Base
- ::execute

# Repeat < Operator < Base
- ::isRecordable
- ::execute

# Mark < OperatorWithInput < Operator < Base
- ::execute

# Increase < Operator < Base
- ::step
- ::execute
- ::increaseNumber

# Decrease < Increase < Operator < Base
- ::step

# AdjustIndentation < Operator < Base
- ::execute

# Indent < AdjustIndentation < Operator < Base
- ::indent

# Outdent < AdjustIndentation < Operator < Base
- ::indent

# Autoindent < AdjustIndentation < Operator < Base
- ::indent

# Put < Operator < Base
- ::register
- ::execute
- ::onLastRow
- ::onLastColumn

# Replace < OperatorWithInput < Operator < Base
- ::execute

# MotionError < Base

# Motion < Base
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

# MotionWithInput < Motion < Base
- ::isComplete
- ::canComposeWith
- ::compose

# MoveLeft < Motion < Base
- ::operatesInclusively
- ::moveCursor

# MoveRight < Motion < Base
- ::operatesInclusively
- ::moveCursor

# MoveUp < Motion < Base
- ::operatesLinewise
- ::moveCursor

# MoveDown < Motion < Base
- ::operatesLinewise
- ::moveCursor

# MoveToPreviousWord < Motion < Base
- ::operatesInclusively
- ::moveCursor

# MoveToPreviousWholeWord < Motion < Base
- ::operatesInclusively
- ::moveCursor
- ::isWholeWord
- ::isBeginningOfFile

# MoveToNextWord < Motion < Base
- ::wordRegex
- ::operatesInclusively
- ::moveCursor
- ::isEndOfFile

# MoveToNextWholeWord < MoveToNextWord < Motion < Base
- ::wordRegex

# MoveToEndOfWord < Motion < Base
- ::wordRegex
- ::moveCursor

# MoveToEndOfWholeWord < MoveToEndOfWord < Motion < Base
- ::wordRegex

# MoveToNextParagraph < Motion < Base
- ::operatesInclusively
- ::moveCursor

# MoveToPreviousParagraph < Motion < Base
- ::moveCursor

# MoveToLine < Motion < Base
- ::operatesLinewise
- ::getDestinationRow

# MoveToAbsoluteLine < MoveToLine < Motion < Base
- ::moveCursor

# MoveToRelativeLine < MoveToLine < Motion < Base
- ::operatesLinewise
- ::moveCursor

# MoveToScreenLine < MoveToLine < Motion < Base
- ::moveCursor

# MoveToBeginningOfLine < Motion < Base
- ::operatesInclusively
- ::moveCursor

# MoveToFirstCharacterOfLine < Motion < Base
- ::operatesInclusively
- ::moveCursor

# MoveToFirstCharacterOfLineAndDown < Motion < Base
- ::operatesLinewise
- ::operatesInclusively
- ::moveCursor

# MoveToLastCharacterOfLine < Motion < Base
- ::operatesInclusively
- ::moveCursor

# MoveToLastNonblankCharacterOfLineAndDown < Motion < Base
- ::operatesInclusively
- ::skipTrailingWhitespace
- ::moveCursor

# MoveToFirstCharacterOfLineUp < Motion < Base
- ::operatesLinewise
- ::operatesInclusively
- ::moveCursor

# MoveToFirstCharacterOfLineDown < Motion < Base
- ::operatesLinewise
- ::moveCursor

# MoveToStartOfFile < MoveToLine < Motion < Base
- ::moveCursor

# MoveToTopOfScreen < MoveToScreenLine < MoveToLine < Motion < Base
- ::getDestinationRow

# MoveToBottomOfScreen < MoveToScreenLine < MoveToLine < Motion < Base
- ::getDestinationRow

# MoveToMiddleOfScreen < MoveToScreenLine < MoveToLine < Motion < Base
- ::getDestinationRow

# ScrollKeepingCursor < MoveToLine < Motion < Base
- ::previousFirstScreenRow
- ::currentFirstScreenRow
- ::select
- ::execute
- ::moveCursor
- ::getDestinationRow
- ::scrollScreen

# ScrollHalfUpKeepCursor < ScrollKeepingCursor < MoveToLine < Motion < Base
- ::scrollDestination

# ScrollFullUpKeepCursor < ScrollKeepingCursor < MoveToLine < Motion < Base
- ::scrollDestination

# ScrollHalfDownKeepCursor < ScrollKeepingCursor < MoveToLine < Motion < Base
- ::scrollDestination

# ScrollFullDownKeepCursor < ScrollKeepingCursor < MoveToLine < Motion < Base
- ::scrollDestination

# Find < MotionWithInput < Motion < Base
- ::match
- ::reverse
- ::moveCursor

# Till < Find < MotionWithInput < Motion < Base
- ::match
- ::moveSelectionInclusively

# MoveToMark < MotionWithInput < Motion < Base
- ::operatesInclusively
- ::isLinewise
- ::moveCursor

# SearchBase < MotionWithInput < Motion < Base
- ::operatesInclusively
- ::reversed
- ::moveCursor
- ::scan
- ::getSearchTerm
- ::updateCurrentSearch
- ::replicateCurrentSearch

# Search < SearchBase < MotionWithInput < Motion < Base

# SearchCurrentWord < SearchBase < MotionWithInput < Motion < Base
- @keywordRegex
- ::getCurrentWord
- ::cursorIsOnEOF
- ::getCurrentWordMatch
- ::isComplete
- ::execute

# BracketMatchingMotion < SearchBase < MotionWithInput < Motion < Base
- ::operatesInclusively
- ::isComplete
- ::searchForMatch
- ::characterAt
- ::getSearchData
- ::moveCursor

# RepeatSearch < SearchBase < MotionWithInput < Motion < Base
- ::isComplete
- ::reversed

# Insert < Operator < Base
- ::standalone
- ::isComplete
- ::confirmChanges
- ::execute
- ::inputOperator

# ReplaceMode < Insert < Operator < Base
- ::execute
- ::countChars

# InsertAfter < Insert < Operator < Base
- ::execute

# InsertAfterEndOfLine < Insert < Operator < Base
- ::execute

# InsertAtBeginningOfLine < Insert < Operator < Base
- ::execute

# InsertAboveWithNewline < Insert < Operator < Base
- ::execute

# InsertBelowWithNewline < Insert < Operator < Base
- ::execute

# Change < Insert < Operator < Base
- ::standalone
- ::register
- ::execute

# SubstituteLine < Change < Insert < Operator < Base
- ::standalone
- ::register

# Prefix < Base
- ::complete
- ::composedObject
- ::isComplete
- ::isRecordable
- ::compose
- ::execute
- ::select
- ::isLinewise

# Register < Prefix < Base
- ::name
- ::compose

# TextObject < Base
- ::isComplete
- ::isRecordable

# CurrentSelection < TextObject < Base
- ::select

# SelectInsideWord < TextObject < Base
- ::select

# SelectAWord < TextObject < Base
- ::select

# SelectInsideWholeWord < TextObject < Base
- ::select

# SelectAWholeWord < TextObject < Base
- ::select

# SelectInsideQuotes < TextObject < Base
- ::findOpeningQuote
- ::isStartQuote
- ::lookForwardOnLine
- ::findClosingQuote
- ::select

# SelectInsideBrackets < TextObject < Base
- ::findOpeningBracket
- ::findClosingBracket
- ::select

# SelectInsideParagraph < TextObject < Base
- ::select

# SelectAParagraph < TextObject < Base
- ::select

# Scroll < Base
- ::isComplete
- ::isRecordable

# ScrollDown < Scroll < Base
- ::execute
- ::keepCursorOnScreen
- ::scrollUp

# ScrollUp < Scroll < Base
- ::execute
- ::keepCursorOnScreen
- ::scrollDown

# ScrollCursor < Scroll < Base

# ScrollCursorToTop < ScrollCursor < Scroll < Base
- ::execute
- ::scrollUp
- ::moveToFirstNonBlank

# ScrollCursorToMiddle < ScrollCursor < Scroll < Base
- ::execute
- ::scrollMiddle
- ::moveToFirstNonBlank

# ScrollCursorToBottom < ScrollCursor < Scroll < Base
- ::execute
- ::scrollDown
- ::moveToFirstNonBlank

# ScrollHorizontal < Base
- ::isComplete
- ::isRecordable
- ::putCursorOnScreen

# ScrollCursorToLeft < ScrollHorizontal < Base
- ::execute

# ScrollCursorToRight < ScrollHorizontal < Base
- ::execute
