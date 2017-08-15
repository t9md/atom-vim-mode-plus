const {CompositeDisposable, Disposable} = require("atom")
const settings = require("./settings")
let PaneAxis = null

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

function exchangePane() {
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

function forEachPaneAxis(base, fn) {
  if (base.children) {
    fn(base)
    for (const child of base.children) {
      forEachPaneAxis(child, fn)
    }
  }
}

function reparentNestedPaneAxis(root) {
  forEachPaneAxis(root, paneAxis => {
    const parent = paneAxis.getParent()
    if (parent instanceof PaneAxis && paneAxis.getOrientation() === parent.getOrientation()) {
      let lastChild
      for (const child of paneAxis.getChildren()) {
        if (!lastChild) {
          parent.replaceChild(paneAxis, child)
        } else {
          parent.insertChildAfter(lastChild, child)
        }
        lastChild = child
      }
      paneAxis.destroy()
    }
  })
}

// Valid direction ["top", "bottom", "left", "right"]
function movePaneToVery(direction) {
  if (atom.workspace.getCenter().getPanes().length < 2) return

  const activePane = atom.workspace.getActivePane()
  const container = activePane.getContainer()
  const parent = activePane.getParent()

  const originalRoot = container.getRoot()
  let root = originalRoot
  // If there is multiple pane in window, root is always instance of PaneAxis
  if (!PaneAxis) PaneAxis = root.constructor

  const finalOrientation = ["top", "bottom"].includes(direction) ? "vertical" : "horizontal"

  if (root.getOrientation() !== finalOrientation) {
    root = new PaneAxis({orientation: finalOrientation, children: [root]}, atom.views)
    container.setRoot(root)
  }

  // avoid automatic reparenting by pssing 2nd arg(= replacing ) to `true`.
  parent.removeChild(activePane, true)

  const indexToAdd = ["top", "left"].includes(direction) ? 0 : undefined
  root.addChild(activePane, indexToAdd)

  if (parent.children.length === 1) {
    parent.reparentLastChild()
  }
  reparentNestedPaneAxis(root)
  activePane.activate()
}

module.exports = class PaneUtils {
  exchangePane() {
    exchangePane()
  }

  equalizePanes() {
    const root = atom.workspace.getActivePane().getContainer().getRoot()
    setFlexScaleToAllPaneAndPaneAxis(root, 1)
  }

  movePaneToVery(direction) {
    movePaneToVery(direction)
  }

  isMaximized() {
    return atom.workspace.getElement().classList.contains("vim-mode-plus--pane-maximized")
  }

  maximizePane(centerPane) {
    if (this.isMaximized()) {
      this.demaximizePane()
      return
    }

    if (centerPane == null) centerPane = settings.get("centerPaneOnMaximizePane")

    const workspaceClassList = [
      "vim-mode-plus--pane-maximized",
      settings.get("hideTabBarOnMaximizePane") && "vim-mode-plus--hide-tab-bar",
      settings.get("hideStatusBarOnMaximizePane") && "vim-mode-plus--hide-status-bar",
      centerPane && "vim-mode-plus--pane-centered",
    ].filter(v => v)
    atom.workspace.getElement().classList.add(...workspaceClassList)

    const activePaneElement = atom.workspace.getActivePane().getElement()
    activePaneElement.classList.add("vim-mode-plus--active-pane")
    for (const element of atom.workspace.getElement().getElementsByTagName("atom-pane-axis")) {
      if (element.contains(activePaneElement)) {
        element.classList.add("vim-mode-plus--active-pane-axis")
      }
    }
  }

  demaximizePane() {
    if (this.isMaximized()) {
      const workspaceElement = atom.workspace.getElement()
      workspaceElement.classList.remove(
        "vim-mode-plus--pane-maximized",
        "vim-mode-plus--hide-tab-bar",
        "vim-mode-plus--hide-status-bar",
        "vim-mode-plus--pane-centered"
      )
      for (const element of workspaceElement.getElementsByTagName("atom-pane-axis")) {
        element.classList.remove("vim-mode-plus--active-pane-axis")
      }
      for (const element of workspaceElement.getElementsByTagName("atom-pane")) {
        element.classList.remove("vim-mode-plus--active-pane")
      }
    }
  }
}
