Base = require '../lib/base'

describe "command-table", ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('vim-mode-plus')

  describe "initial classRegistry", ->
    it "contains one entry and it's Base class", ->
      classRegistry = Base.getClassRegistry()
      keys = Object.keys(classRegistry)
      expect(keys).toHaveLength(1)
      expect(keys[0]).toBe("Base")
      expect(classRegistry[keys[0]]).toBe(Base)

  describe "fully populated classRegistry", ->
    it "generateCommandTableByEagerLoad populate all registry eagerly", ->
      oldRegistries = Base.getClassRegistry()
      oldRegistriesLength = Object.keys(oldRegistries).length
      expect(Object.keys(oldRegistries)).toHaveLength(1)

      Base.generateCommandTableByEagerLoad()
      newRegistriesLength = Object.keys(Base.getClassRegistry()).length
      expect(newRegistriesLength).toBeGreaterThan(oldRegistriesLength)

  describe "make sure cmd-table is NOT out-of-date", ->
    it "generateCommandTableByEagerLoad return table which is equals to initially loaded command table", ->
      [oldCommandTable, newCommandTable] = []

      oldCommandTable = Base.commandTable
      newCommandTable = Base.generateCommandTableByEagerLoad()
      loadedCommandTable = require('../lib/command-table')

      expect(oldCommandTable).not.toBe(newCommandTable)
      expect(loadedCommandTable).toEqual(oldCommandTable)
      expect(loadedCommandTable).toEqual(newCommandTable)
