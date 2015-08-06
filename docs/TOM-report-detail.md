# OperatorError < Base

# Operator < Base
- ::vimState: `null`
- ::target: `null`
- ::complete: `null`
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`
- ::compose: `[Function]`
- ::canComposeWith: `[Function]`
- ::setTextRegister: `[Function]`

# OperatorWithInput < Operator < Base
- ::canComposeWith: `[Function]`
- ::compose: `[Function]`

# Select < Operator < Base
- ::execute: `[Function]`

# Delete < Operator < Base
- ::register: `null`
- ::execute: `[Function]`

# ToggleCase < Operator < Base
- ::execute: `[Function]`

# UpperCase < Operator < Base
- ::execute: `[Function]`

# LowerCase < Operator < Base
- ::execute: `[Function]`

# Yank < Operator < Base
- ::register: `null`
- ::execute: `[Function]`

# Join < Operator < Base
- ::execute: `[Function]`

# Repeat < Operator < Base
- ::isRecordable: `[Function]`
- ::execute: `[Function]`

# Mark < OperatorWithInput < Operator < Base
- ::execute: `[Function]`

# Increase < Operator < Base
- ::step: `1`
- ::execute: `[Function]`
- ::increaseNumber: `[Function]`

# Decrease < Increase < Operator < Base
- ::step: `-1`

# AdjustIndentation < Operator < Base
- ::execute: `[Function]`

# Indent < AdjustIndentation < Operator < Base
- ::indent: `[Function]`

# Outdent < AdjustIndentation < Operator < Base
- ::indent: `[Function]`

# Autoindent < AdjustIndentation < Operator < Base
- ::indent: `[Function]`

# Put < Operator < Base
- ::register: `null`
- ::execute: `[Function]`
- ::onLastRow: `[Function]`
- ::onLastColumn: `[Function]`

# Replace < OperatorWithInput < Operator < Base
- ::execute: `[Function]`

# MotionError < Base

# Motion < Base
- ::operatesInclusively: `true`
- ::operatesLinewise: `false`
- ::select: `[Function]`
- ::execute: `[Function]`
- ::moveSelectionLinewise: `[Function]`
- ::moveSelectionInclusively: `[Function]`
- ::moveSelection: `[Function]`
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`
- ::isLinewise: `[Function]`
- ::isInclusive: `[Function]`

# MotionWithInput < Motion < Base
- ::isComplete: `[Function]`
- ::canComposeWith: `[Function]`
- ::compose: `[Function]`

# MoveLeft < Motion < Base
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

# MoveRight < Motion < Base
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

# MoveUp < Motion < Base
- ::operatesLinewise: `true`
- ::moveCursor: `[Function]`

# MoveDown < Motion < Base
- ::operatesLinewise: `true`
- ::moveCursor: `[Function]`

# MoveToPreviousWord < Motion < Base
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

# MoveToPreviousWholeWord < Motion < Base
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`
- ::isWholeWord: `[Function]`
- ::isBeginningOfFile: `[Function]`

# MoveToNextWord < Motion < Base
- ::wordRegex: `null`
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`
- ::isEndOfFile: `[Function]`

# MoveToNextWholeWord < MoveToNextWord < Motion < Base
- ::wordRegex: `/^\s*$|\S+/`

# MoveToEndOfWord < Motion < Base
- ::wordRegex: `null`
- ::moveCursor: `[Function]`

# MoveToEndOfWholeWord < MoveToEndOfWord < Motion < Base
- ::wordRegex: `/\S+/`

# MoveToNextParagraph < Motion < Base
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

# MoveToPreviousParagraph < Motion < Base
- ::moveCursor: `[Function]`

# MoveToLine < Motion < Base
- ::operatesLinewise: `true`
- ::getDestinationRow: `[Function]`

# MoveToAbsoluteLine < MoveToLine < Motion < Base
- ::moveCursor: `[Function]`

# MoveToRelativeLine < MoveToLine < Motion < Base
- ::operatesLinewise: `true`
- ::moveCursor: `[Function]`

# MoveToScreenLine < MoveToLine < Motion < Base
- ::moveCursor: `[Function]`

# MoveToBeginningOfLine < Motion < Base
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

# MoveToFirstCharacterOfLine < Motion < Base
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

# MoveToFirstCharacterOfLineAndDown < Motion < Base
- ::operatesLinewise: `true`
- ::operatesInclusively: `true`
- ::moveCursor: `[Function]`

# MoveToLastCharacterOfLine < Motion < Base
- ::operatesInclusively: `false`
- ::moveCursor: `[Function]`

# MoveToLastNonblankCharacterOfLineAndDown < Motion < Base
- ::operatesInclusively: `true`
- ::skipTrailingWhitespace: `[Function]`
- ::moveCursor: `[Function]`

# MoveToFirstCharacterOfLineUp < Motion < Base
- ::operatesLinewise: `true`
- ::operatesInclusively: `true`
- ::moveCursor: `[Function]`

# MoveToFirstCharacterOfLineDown < Motion < Base
- ::operatesLinewise: `true`
- ::moveCursor: `[Function]`

# MoveToStartOfFile < MoveToLine < Motion < Base
- ::moveCursor: `[Function]`

# MoveToTopOfScreen < MoveToScreenLine < MoveToLine < Motion < Base
- ::getDestinationRow: `[Function]`

# MoveToBottomOfScreen < MoveToScreenLine < MoveToLine < Motion < Base
- ::getDestinationRow: `[Function]`

# MoveToMiddleOfScreen < MoveToScreenLine < MoveToLine < Motion < Base
- ::getDestinationRow: `[Function]`

# ScrollKeepingCursor < MoveToLine < Motion < Base
- ::previousFirstScreenRow: `0`
- ::currentFirstScreenRow: `0`
- ::select: `[Function]`
- ::execute: `[Function]`
- ::moveCursor: `[Function]`
- ::getDestinationRow: `[Function]`
- ::scrollScreen: `[Function]`

# ScrollHalfUpKeepCursor < ScrollKeepingCursor < MoveToLine < Motion < Base
- ::scrollDestination: `[Function]`

# ScrollFullUpKeepCursor < ScrollKeepingCursor < MoveToLine < Motion < Base
- ::scrollDestination: `[Function]`

# ScrollHalfDownKeepCursor < ScrollKeepingCursor < MoveToLine < Motion < Base
- ::scrollDestination: `[Function]`

# ScrollFullDownKeepCursor < ScrollKeepingCursor < MoveToLine < Motion < Base
- ::scrollDestination: `[Function]`

# Find < MotionWithInput < Motion < Base
- ::match: `[Function]`
- ::reverse: `[Function]`
- ::moveCursor: `[Function]`

# Till < Find < MotionWithInput < Motion < Base
- ::match: `[Function]`
- ::moveSelectionInclusively: `[Function]`

# MoveToMark < MotionWithInput < Motion < Base
- ::operatesInclusively: `false`
- ::isLinewise: `[Function]`
- ::moveCursor: `[Function]`

# SearchBase < MotionWithInput < Motion < Base
- ::operatesInclusively: `false`
- ::reversed: `[Function]`
- ::moveCursor: `[Function]`
- ::scan: `[Function]`
- ::getSearchTerm: `[Function]`
- ::updateCurrentSearch: `[Function]`
- ::replicateCurrentSearch: `[Function]`

# Search < SearchBase < MotionWithInput < Motion < Base

# SearchCurrentWord < SearchBase < MotionWithInput < Motion < Base
- @keywordRegex: `null`
- ::getCurrentWord: `[Function]`
- ::cursorIsOnEOF: `[Function]`
- ::getCurrentWordMatch: `[Function]`
- ::isComplete: `[Function]`
- ::execute: `[Function]`

# BracketMatchingMotion < SearchBase < MotionWithInput < Motion < Base
- ::operatesInclusively: `true`
- ::isComplete: `[Function]`
- ::searchForMatch: `[Function]`
- ::characterAt: `[Function]`
- ::getSearchData: `[Function]`
- ::moveCursor: `[Function]`

# RepeatSearch < SearchBase < MotionWithInput < Motion < Base
- ::isComplete: `[Function]`
- ::reversed: `[Function]`

# Insert < Operator < Base
- ::standalone: `true`
- ::isComplete: `[Function]`
- ::confirmChanges: `[Function]`
- ::execute: `[Function]`
- ::inputOperator: `[Function]`

# ReplaceMode < Insert < Operator < Base
- ::execute: `[Function]`
- ::countChars: `[Function]`

# InsertAfter < Insert < Operator < Base
- ::execute: `[Function]`

# InsertAfterEndOfLine < Insert < Operator < Base
- ::execute: `[Function]`

# InsertAtBeginningOfLine < Insert < Operator < Base
- ::execute: `[Function]`

# InsertAboveWithNewline < Insert < Operator < Base
- ::execute: `[Function]`

# InsertBelowWithNewline < Insert < Operator < Base
- ::execute: `[Function]`

# Change < Insert < Operator < Base
- ::standalone: `false`
- ::register: `null`
- ::execute: `[Function]`

# SubstituteLine < Change < Insert < Operator < Base
- ::standalone: `true`
- ::register: `null`

# Prefix < Base
- ::complete: `null`
- ::composedObject: `null`
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`
- ::compose: `[Function]`
- ::execute: `[Function]`
- ::select: `[Function]`
- ::isLinewise: `[Function]`

# Register < Prefix < Base
- ::name: `null`
- ::compose: `[Function]`

# TextObject < Base
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`

# CurrentSelection < TextObject < Base
- ::select: `[Function]`

# SelectInsideWord < TextObject < Base
- ::select: `[Function]`

# SelectAWord < TextObject < Base
- ::select: `[Function]`

# SelectInsideWholeWord < TextObject < Base
- ::select: `[Function]`

# SelectAWholeWord < TextObject < Base
- ::select: `[Function]`

# SelectInsideQuotes < TextObject < Base
- ::findOpeningQuote: `[Function]`
- ::isStartQuote: `[Function]`
- ::lookForwardOnLine: `[Function]`
- ::findClosingQuote: `[Function]`
- ::select: `[Function]`

# SelectInsideBrackets < TextObject < Base
- ::findOpeningBracket: `[Function]`
- ::findClosingBracket: `[Function]`
- ::select: `[Function]`

# SelectInsideParagraph < TextObject < Base
- ::select: `[Function]`

# SelectAParagraph < TextObject < Base
- ::select: `[Function]`

# Scroll < Base
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`

# ScrollDown < Scroll < Base
- ::execute: `[Function]`
- ::keepCursorOnScreen: `[Function]`
- ::scrollUp: `[Function]`

# ScrollUp < Scroll < Base
- ::execute: `[Function]`
- ::keepCursorOnScreen: `[Function]`
- ::scrollDown: `[Function]`

# ScrollCursor < Scroll < Base

# ScrollCursorToTop < ScrollCursor < Scroll < Base
- ::execute: `[Function]`
- ::scrollUp: `[Function]`
- ::moveToFirstNonBlank: `[Function]`

# ScrollCursorToMiddle < ScrollCursor < Scroll < Base
- ::execute: `[Function]`
- ::scrollMiddle: `[Function]`
- ::moveToFirstNonBlank: `[Function]`

# ScrollCursorToBottom < ScrollCursor < Scroll < Base
- ::execute: `[Function]`
- ::scrollDown: `[Function]`
- ::moveToFirstNonBlank: `[Function]`

# ScrollHorizontal < Base
- ::isComplete: `[Function]`
- ::isRecordable: `[Function]`
- ::putCursorOnScreen: `[Function]`

# ScrollCursorToLeft < ScrollHorizontal < Base
- ::execute: `[Function]`

# ScrollCursorToRight < ScrollHorizontal < Base
- ::execute: `[Function]`
