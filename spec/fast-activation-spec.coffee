# [DANGER]
# What I'm doing in this test-spec is SUPER hacky, and I don't like this.
#
# - What I'm doing and why
#  - Invalidate require.cache to "observe required file on startup".
#  - Then restore require.cache to original state.
#
# - Just invalidating is not enough unless restoreing other spec file fail.
#
# - What happens just invalidate require.cache and NOT restored to original require.cache?
#  - For module such like `globlal-state.coffee` it instantiated at required time.
#  - Invalidating require.cache for `global-state.coffee` means, it's reloaded again.
#  - This 2nd reload return DIFFERENT globalState instance.
#  - So globalState is now no longer globally referencing same same object, it's broken.
#  - This situation is caused by explicit cache invalidation and not happen in real usage.
#
# - I know this spec is still super hacky and I want to find safer way.
#  - But I need this spec to detect unwanted file is required at startup( vmp get slower startup ).
describe "dirty work for fast package activation", ->
  withCleanActivation = null
  ensureRequiredFiles = null

  beforeEach ->
    runs ->
      packPath = atom.packages.loadPackage('vim-mode-plus').path
      getRequiredLibOrNodeModulePaths = ->
        Object.keys(require.cache).filter (p) ->
          p.startsWith(packPath + 'lib') or p.startsWith(packPath + 'node_modules')

      withCleanActivation = (fn) ->
        savedCache = {}
        pack = null
        runs ->
          getRequiredLibOrNodeModulePaths().forEach (p) ->
            savedCache[p] = require.cache[p]
            delete require.cache[p]

        waitsForPromise ->
          atom.packages.activatePackage('vim-mode-plus').then (_pack) ->
            pack = _pack

        runs ->
          fn(pack)

        runs ->
          oldPaths = Object.keys(savedCache)
          newPaths = getRequiredLibOrNodeModulePaths()
          newPaths.forEach (p) ->
            if p in oldPaths
              require.cache[p] = savedCache[p]
            else
              delete require.cache[p]

      ensureRequiredFiles = (files) ->
        should = files.map((file) -> packPath + file)
        expect(getRequiredLibOrNodeModulePaths()).toEqual(should)

  describe "requrie as minimum num of file as possible on startup", ->
    shouldRequireFilesInOrdered = [
      "lib/main.coffee"
      "lib/base.coffee"
      "node_modules/delegato/lib/delegator.js"
      "node_modules/mixto/lib/mixin.js"
      "lib/settings.coffee"
      "lib/global-state.coffee"
      "lib/vim-state.coffee"
      "lib/mode-manager.coffee"
      "lib/command-table.coffee"
    ]
    if atom.inDevMode()
      shouldRequireFilesInOrdered.push('lib/developer.coffee')

    # * To reduce IO and compile-evaluation of js file on startup
    it "require minimum set of files", ->
      withCleanActivation ->
        ensureRequiredFiles(shouldRequireFilesInOrdered)

    it "[one editor opened] require minimum set of files", ->
      withCleanActivation ->
        waitsForPromise -> atom.workspace.open()
        runs ->
          files = shouldRequireFilesInOrdered.concat('lib/status-bar-manager.coffee')
          ensureRequiredFiles(files)

    it "[after motion executed] require minimum set of files", ->
      withCleanActivation ->
        waitsForPromise ->
          atom.workspace.open().then (e) ->
            atom.commands.dispatch(e.element, 'vim-mode-plus:move-right')
        runs ->
          extraShouldRequireFilesInOrdered = [
            "lib/status-bar-manager.coffee"
            "lib/operation-stack.coffee"
            "lib/selection-wrapper.coffee"
            "lib/utils.coffee"
            "node_modules/underscore-plus/lib/underscore-plus.js"
            "node_modules/underscore/underscore.js"
            "lib/blockwise-selection.coffee"
            "lib/motion.coffee"
            "lib/cursor-style-manager.coffee"
          ]
          files = shouldRequireFilesInOrdered.concat(extraShouldRequireFilesInOrdered)
          ensureRequiredFiles(files)

  describe "command-table", ->
    # * Loading atom commands from pre-generated command-table.
    # * Why?
    #  vmp adds about 300 cmds, which is huge, dynamically calculating and register cmds
    #  took very long time.
    #  So calcluate non-dynamic par then save to command-table.coffe and load in on startup.
    #  When command are executed, necessary command class file is lazy-required.
    describe "initial classRegistry", ->
      it "contains one entry and it's Base class", ->
        withCleanActivation (pack) ->
          Base = pack.mainModule.provideVimModePlus().Base
          classRegistry = Base.getClassRegistry()
          keys = Object.keys(classRegistry)
          expect(keys).toHaveLength(1)
          expect(keys[0]).toBe("Base")
          expect(classRegistry[keys[0]]).toBe(Base)

    describe "fully populated classRegistry", ->
      it "generateCommandTableByEagerLoad populate all registry eagerly", ->
        withCleanActivation (pack) ->
          Base = pack.mainModule.provideVimModePlus().Base
          oldRegistries = Base.getClassRegistry()
          oldRegistriesLength = Object.keys(oldRegistries).length
          expect(Object.keys(oldRegistries)).toHaveLength(1)

          Base.generateCommandTableByEagerLoad()
          newRegistriesLength = Object.keys(Base.getClassRegistry()).length
          expect(newRegistriesLength).toBeGreaterThan(oldRegistriesLength)

    describe "make sure cmd-table is NOT out-of-date", ->
      it "generateCommandTableByEagerLoad return table which is equals to initially loaded command table", ->
        withCleanActivation (pack) ->
          Base = pack.mainModule.provideVimModePlus().Base
          [oldCommandTable, newCommandTable] = []

          oldCommandTable = Base.commandTable
          newCommandTable = Base.generateCommandTableByEagerLoad()
          loadedCommandTable = require('../lib/command-table')

          expect(oldCommandTable).not.toBe(newCommandTable)
          expect(loadedCommandTable).toEqual(oldCommandTable)
          expect(loadedCommandTable).toEqual(newCommandTable)
