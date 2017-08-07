const {Disposable, Emitter, CompositeDisposable} = require("atom")
const globalState = require("./global-state")
const VimState = require("./vim-state")
const Base = require("./base")

module.exports = class DemoModeSupport {
  constructor({onWillAddItem, onDidStart, onDidStop, onDidRemoveHover}) {
    this.disposables = new CompositeDisposable(
      onDidStart(() => globalState.set("demoModeIsActive", true)),
      onDidStop(() => globalState.set("demoModeIsActive", false)),
      onDidRemoveHover(this.destroyAllDemoModeFlasheMarkers.bind(this)),
      onWillAddItem(({item, event}) => {
        if (event.binding.command.startsWith("vim-mode-plus:")) {
          const commandElement = item.getElementsByClassName("command")[0]
          commandElement.textContent = commandElement.textContent.replace(/^vim-mode-plus:/, "")
        }
        const element = document.createElement("span")
        element.classList.add("kind", "pull-right")
        element.textContent = this.getKindForCommand(event.binding.command)
        item.appendChild(element)
      })
    )
  }

  destroyAllDemoModeFlasheMarkers() {
    VimState.forEach(vimState => vimState.flashManager.destroyDemoModeMarkers())
  }

  destroy() {
    this.disposables.dispose()
  }

  getKindForCommand(command) {
    if (command.startsWith("vim-mode-plus")) {
      return command.startsWith("vim-mode-plus:operator-modifier")
        ? "op-modifier"
        : Base.getKindForCommandName(command) || "vmp-other"
    } else {
      return "non-vmp"
    }
  }
}
