
describe "dirty work for fast package activation", ->
  [main] = []
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('vim-mode-plus').then (pack) ->
        main = pack.mainModule

  describe "requrie as minimum num of file as possible on startup", ->
    # * To reduce IO and compile-evaluation of js file on startup
    describe "with no editor opened", ->
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('vim-mode-plus')

  fdescribe "command-table", ->
    # * Loading atom commands from pre-generated command-table.
    # * Why?
    #  vmp adds about 300 cmds, which is huge, dynamically calculating and register cmds
    #  took very long time.
    #  So calcluate non-dynamic par then save to command-table.coffe and load in on startup.
    #  When command are executed, necessary command class file is lazy-required.
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('vim-mode-plus').then (pack) ->
          main = pack.mainModule

    describe "initial classRegistry", ->
      it "contains one entry and it's Base class", ->
        Base = main.provideVimModePlus().Base
        classRegistry = Base.getClassRegistry()
        keys = Object.keys(classRegistry)
        expect(keys).toHaveLength(1)
        expect(keys[0]).toBe("Base")
        expect(classRegistry[keys[0]]).toBe(Base)

    describe "fully populated classRegistry", ->
      it "generateCommandTableByEagerLoad populate all registry eagerly", ->
        Base = main.provideVimModePlus().Base
        oldRegistries = Base.getClassRegistry()
        oldRegistriesLength = Object.keys(oldRegistries).length
        expect(Object.keys(oldRegistries)).toHaveLength(1)

        Base.generateCommandTableByEagerLoad()
        newRegistriesLength = Object.keys(Base.getClassRegistry()).length
        expect(newRegistriesLength).toBeGreaterThan(oldRegistriesLength)

    describe "make sure cmd-table is NOT out-of-date", ->
      it "generateCommandTableByEagerLoad return table which is equals to initially loaded command table", ->
        Base = main.provideVimModePlus().Base
        [oldCommandTable, newCommandTable] = []

        oldCommandTable = Base.commandTable
        newCommandTable = Base.generateCommandTableByEagerLoad()
        loadedCommandTable = require('../lib/command-table')

        expect(oldCommandTable).not.toBe(newCommandTable)
        expect(loadedCommandTable).toEqual(oldCommandTable)
        expect(loadedCommandTable).toEqual(newCommandTable)
