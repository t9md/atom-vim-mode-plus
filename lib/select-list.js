"use babel"

import {humanizeKeystroke} from "underscore-plus"
const SelectListView = require("atom-select-list")
const fuzzaldrinPlus = require("fuzzaldrin-plus")

module.exports = class SelectList {
  constructor() {
    this.selectListView = new SelectListView({
      initiallyVisibleItemCount: 10,
      items: [],
      filterKeyForItem: item => item.displayName,
      elementForItem: (item, {index, selected, visible}) => {
        if (!visible) {
          return document.createElement("li")
        }
        const li = document.createElement("li")
        const div = document.createElement("div")
        div.classList.add("pull-right")

        const commandName = item.klass.getCommandName()
        this.keyBindingsForActiveElement.filter(({command}) => command === commandName).forEach(keyBinding => {
          const kbd = document.createElement("kbd")
          kbd.classList.add("key-binding")
          kbd.textContent = humanizeKeystroke(keyBinding.keystrokes)
          div.appendChild(kbd)
        })

        const span = document.createElement("span")
        highlightMatchesInElement(item.displayName, this.selectListView.getQuery(), span)

        li.appendChild(div)
        li.appendChild(span)
        return li
      },
      emptyMessage: "No matches found",
      didConfirmSelection: item => {
        this.confirmed = true
        if (this.onConfirm) this.onConfirm(item)
        this.hide()
      },
      didCancelSelection: () => {
        if (this.confirmed) return
        if (this.onCancel) this.onCancel()
        this.hide()
      },
    })
    this.selectListView.element.classList.add("vim-mode-plus-select-list")
  }

  async show({items, onCancel, onConfirm}) {
    this.keyBindingsForActiveElement = atom.keymaps.findKeyBindings({target: this.activeElement})

    this.confirmed = false
    this.onConfirm = onConfirm
    this.onCancel = onCancel

    if (!this.panel) {
      this.panel = atom.workspace.addModalPanel({item: this.selectListView})
    }
    this.selectListView.reset()
    await this.selectListView.update({items})

    this.previouslyFocusedElement = document.activeElement
    this.panel.show()
    this.selectListView.focus()
  }

  hide() {
    this.panel.hide()
    if (this.previouslyFocusedElement) {
      this.previouslyFocusedElement.focus()
      this.previouslyFocusedElement = null
    }
  }
}

function highlightMatchesInElement(text, query, el) {
  const matches = fuzzaldrinPlus.match(text, query)
  let matchedChars = []
  let lastIndex = 0
  for (const matchIndex of matches) {
    const unmatched = text.substring(lastIndex, matchIndex)
    if (unmatched) {
      if (matchedChars.length > 0) {
        const matchSpan = document.createElement("span")
        matchSpan.classList.add("character-match")
        matchSpan.textContent = matchedChars.join("")
        el.appendChild(matchSpan)
        matchedChars = []
      }

      el.appendChild(document.createTextNode(unmatched))
    }

    matchedChars.push(text[matchIndex])
    lastIndex = matchIndex + 1
  }

  if (matchedChars.length > 0) {
    const matchSpan = document.createElement("span")
    matchSpan.classList.add("character-match")
    matchSpan.textContent = matchedChars.join("")
    el.appendChild(matchSpan)
  }

  const unmatched = text.substring(lastIndex)
  if (unmatched) {
    el.appendChild(document.createTextNode(unmatched))
  }
}
