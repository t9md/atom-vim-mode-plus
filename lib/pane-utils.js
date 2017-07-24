// Return adjacent pane of activePane within current PaneAxis.
//  * return next Pane if exists.
//  * return previous pane if next pane was not exits.
function getAdjacentPane(pane) {
  const parent = pane.getParent()
  if (!parent || !parent.getChildren) return
  const children = pane.getParent().getChildren()
  const index = children.indexOf(pane)
  const [previousPane, nextPane] = [children[index - 1], children[index + 1]]
  return nextPane || previousPane
}

function exchangePane({stay = true} = {}) {
  const activePane = atom.workspace.getActivePane()
  const adjacentPane = getAdjacentPane(activePane)

  // When adjacent was paneAxis, do nothing.
  if (!adjacentPane || adjacentPane.children) return

  const parent = activePane.getParent()
  const children = parent.getChildren()

  if (children.indexOf(activePane) < children.indexOf(adjacentPane)) {
    parent.removeChild(activePane, true)
    parent.insertChildAfter(adjacentPane, activePane)
  } else {
    parent.removeChild(activePane, true)
    parent.insertChildBefore(adjacentPane, activePane)
  }

  adjacentPane.activate()
}

function setFlexScaleToAllPaneAndPaneAxis(root, value) {
  root.setFlexScale(value)
  if (root.children) {
    for (const child of root.children) {
      setFlexScaleToAllPaneAndPaneAxis(child, value)
    }
  }
}

function equalizePanes() {
  const root = atom.workspace.getActivePane().getContainer().getRoot()
  setFlexScaleToAllPaneAndPaneAxis(root, 1)
}

module.exports = {
  exchangePane,
  equalizePanes,
}
