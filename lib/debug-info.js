const {removeIndent} = require('./utils')

function getNonDefaultConfig () {
  const userConfig = atom.config.get('vim-mode-plus')
  const defaultSettings = atom.config.defaultSettings['vim-mode-plus']

  const nonDefaultConfig = {}
  for (let key in userConfig) {
    if (defaultSettings[key] !== userConfig[key]) {
      nonDefaultConfig[key] = userConfig[key]
    }
  }
  return nonDefaultConfig
}

function clipDebugInfo (withPkgInfo = false) {
  const os = require('os')
  const debugInfo = {
    atom: atom.getVersion(),
    platform: os.platform(),
    release: os.release(),
    vmpVersion: atom.packages.getActivePackage('vim-mode-plus').metadata.version,
    vmpConfig: getNonDefaultConfig()
  }

  if (withPkgInfo) {
    debugInfo.activeCommunityPackages = getActiveCommunityPackages()
  }

  let summary = 'debug info'
  if (withPkgInfo) summary += ' with package info'

  const template = removeIndent(`
    <details>
      <summary>${summary}</summary>

    \`\`\`json
    __JSON__
    \`\`\`

    </details>
    `)

  const jsonString = JSON.stringify(debugInfo, null, '  ')
  atom.clipboard.write(template.replace('__JSON__', jsonString))
}

function getActiveCommunityPackages () {
  return atom.packages
    .getActivePackages()
    .filter(pack => !atom.packages.isBundledPackage(pack.name))
    .map(pack => pack.name + ': ' + pack.metadata.version)
}

module.exports = {
  clipDebugInfo
}
