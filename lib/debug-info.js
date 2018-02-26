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

function clipDebugInfoIncludingCommunityPackageInfo () {
  clipDebugInfo(true)
}

function clipDebugInfo (includeOtherPkgInfo = false) {
  const os = require('os')
  const info = {
    atom: atom.getVersion(),
    platform: os.platform(),
    release: os.release(),
    vmpVersion: atom.packages.getActivePackage('vim-mode-plus').metadata.version,
    vmpConfig: getNonDefaultConfig()
  }

  if (includeOtherPkgInfo) {
    info.activeCommunityPackages = getActiveCommunityPackages()
  }

  const jsonString = JSON.stringify(info, null, '  ')
  const debugInfo = removeIndent(`
    <details>
     <summary>debug info</summary>
     \`\`\`json
     ${jsonString}
     \`\`\`
    </details>

  `)

  atom.clipboard.write(debugInfo)
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
