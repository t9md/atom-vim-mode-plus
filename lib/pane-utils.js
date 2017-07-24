const {CompositeDisposable, Disposable} = require("atom")
const settings = require("./settings")

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

/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
function forEachPaneAxis(base, fn) {
  if (base.children) {
    fn(base)
    for (const child of base.children) {
      forEachPaneAxis(child, fn)
    }
  }
}

function maximizePane() {
  const disposables = new CompositeDisposable()

  const addClassList = (element, classList) => {
    classList = classList.map(className => `vim-mode-plus--${className}`)
    element.classList.add(...classList)
    disposables.add(new Disposable(() => element.classList.remove(...classList)))
  }

  const workspaceClassList = ["pane-maximized"]
  if (settings.get("hideTabBarOnMaximizePane")) {
    workspaceClassList.push("hide-tab-bar")
  }
  if (settings.get("hideStatusBarOnMaximizePane")) {
    workspaceClassList.push("hide-status-bar")
  }
  addClassList(atom.workspace.getElement(), workspaceClassList)

  const activePane = atom.workspace.getActivePane()
  const activePaneElement = activePane.getElement()
  addClassList(activePaneElement, ["active-pane"])

  const root = activePane.getContainer().getRoot()
  forEachPaneAxis(root, paneAxis => {
    const element = paneAxis.getElement()
    if (element.contains(activePaneElement)) {
      addClassList(element, ["active-pane-axis"])
    }
  })
  return disposables
}

module.exports = {
  exchangePane,
  equalizePanes,
  maximizePane,
}
