getFilePathForPackage = (packageName, file) ->
  path = require 'path'
  pkgRoot = atom.packages.resolvePackagePath(packageName)
  path.join(pkgRoot, 'lib', file)

requirePackageFile = (packageName, file) ->
  if lib = getFilePathForPackage(packageName, file)
    require lib

getVimStateForEditor = (editor) ->
  pack = atom.packages.getActivePackage('vim-mode')
  vimMode = pack.mainModule.provideVimMode()
  vimMode.getEditorState(editor)

module.exports = {
  getFilePathForPackage
  requirePackageFile
  getVimStateForEditor
}
