const globalState = require('./global-state')
const VimState = require('./vim-state')
const Base = require('./base')
const {CompositeDisposable} = require('atom')

class DemoModeSupport {
  init ({onWillAddItem, onDidStart, onDidStop, onWillFadeoutHover, onDidRemoveHover}) {
    const destroyAllDemoModeFlasheMarkers = this.destroyAllDemoModeFlasheMarkers.bind(this)

    // Returns disposables
    return new CompositeDisposable(
      onDidStart(() => globalState.set('demoModeIsActive', true)),
      onDidStop(() => globalState.set('demoModeIsActive', false)),
      onDidRemoveHover(destroyAllDemoModeFlasheMarkers),
      onWillFadeoutHover(destroyAllDemoModeFlasheMarkers),
      onWillAddItem(({item, event}) => {
        if (event.binding.command.startsWith('vim-mode-plus:')) {
          const commandElement = item.getElementsByClassName('command')[0]
          commandElement.textContent = commandElement.textContent.replace(/^vim-mode-plus:/, '')
        }
        const element = document.createElement('span')
        element.classList.add('kind', 'pull-right')
        element.textContent = this.getKindForCommand(event.binding.command)
        item.appendChild(element)
      })
    )
  }

  destroyAllDemoModeFlasheMarkers () {
    VimState.forEach(vimState => vimState.flashManager.destroyDemoModeMarkers())
  }

  destroy () {
    this.disposables.dispose()
  }

  getKindForCommand (command) {
    if (command.startsWith('vim-mode-plus')) {
      return command.startsWith('vim-mode-plus:operator-modifier')
        ? 'op-modifier'
        : Base.getKindForCommandName(command) || 'vmp-other'
    } else {
      return 'non-vmp'
    }
  }
}

module.exports = new DemoModeSupport()
