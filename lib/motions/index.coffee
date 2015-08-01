Motions = require './general-motions'
{Search, SearchCurrentWord, BracketMatchingMotion, RepeatSearch} = require './search-motion'

Motions.Search = Search
Motions.SearchCurrentWord = SearchCurrentWord
Motions.BracketMatchingMotion = BracketMatchingMotion
Motions.RepeatSearch = RepeatSearch

module.exports = Motions
