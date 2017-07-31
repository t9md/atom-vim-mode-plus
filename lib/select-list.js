const _ = require("underscore-plus")
const {SelectListView, $, $$} = require("atom-space-pen-views")
const fuzzaldrin = require("fuzzaldrin")

module.exports = class SelectList extends SelectListView {
  initialize(...args) {
    super.initialize(...args)
    this.addClass("vim-mode-plus-select-list")
  }

  getFilterKey() {
    return "displayName"
  }

  cancelled() {
    this.vimState.emitter.emit("did-cancel-select-list")
    this.hide()
  }

  show(vimState, {maxItems, items}) {
    this.vimState = vimState
    this.editor = vimState
    this.editorElement = vimState

    if (maxItems != null) {
      this.setMaxItems(maxItems)
    }
    this.storeFocusedElement()
    if (!this.panel) {
      this.panel = atom.workspace.addModalPanel({item: this})
    }
    this.panel.show()
    this.setItems(items)
    this.focusFilterEditor()
  }

  hide() {
    if (this.panel) this.panel.hide()
  }

  viewForItem({name, displayName}) {
    // Style matched characters in search results
    const filterQuery = this.getFilterQuery()
    const matches = fuzzaldrin.match(displayName, filterQuery)
    return $$(function() {
      const highlighter = (command, matches, offsetIndex) => {
        let lastIndex = 0
        let matchedChars = [] // Build up a set of matched chars to be more semantic

        for (let matchIndex of matches) {
          matchIndex -= offsetIndex
          if (matchIndex < 0) {
            continue
          }

          // If marking up the basename, omit command matches
          const unmatched = command.substring(lastIndex, matchIndex)
          if (unmatched) {
            if (matchedChars.length) {
              this.span(matchedChars.join(""), {class: "character-match"})
            }
            matchedChars = []
            this.text(unmatched)
          }
          matchedChars.push(command[matchIndex])
          lastIndex = matchIndex + 1
        }

        if (matchedChars.length) {
          this.span(matchedChars.join(""), {class: "character-match"})
        }
        // Remaining characters are plain text
        this.text(command.substring(lastIndex))
      }

      this.li({class: "event", "data-event-name": name}, () => {
        this.span({title: displayName}, () => highlighter(displayName, matches, 0))
      })
    })
  }

  confirmed(item) {
    this.vimState.emitter.emit("did-confirm-select-list", item)
    this.cancel()
  }
}
