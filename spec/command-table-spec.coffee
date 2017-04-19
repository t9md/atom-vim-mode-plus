Base = require '../lib/base'

describe "command-table", ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('vim-mode-plus')

  describe "initial Base.registries", ->
    it "contains one entry and it's Base class", ->
      registries = Base.getClassRegistry()
      keys = Object.keys(registries)
      expect(keys).toHaveLength(1)
      expect(keys[0]).toBe("Base")
      expect(registries[keys[0]]).toBe(Base)

  describe "cmd-table serialize/deserialize", ->
    it "generateCommandTableByEagerLoad populate registry eagerly and return table which is equals to loaded command table", ->
      [oldCommandTable, newCommandTable] = []

      oldRegistries = Base.getClassRegistry()
      oldRegistriesLength = Object.keys(oldRegistries).length
      expect(Object.keys(oldRegistries)).toHaveLength(1)

      oldCommandTable = Base.commandTable
      newCommandTable = Base.generateCommandTableByEagerLoad()
      newRegistries = Base.getClassRegistry()
      newRegistriesLength = Object.keys(newRegistries).length

      expect(newRegistriesLength).toBeGreaterThan(oldRegistriesLength)

      loadedCommandTable = require('../lib/command-table')
      expect(oldCommandTable).not.toBe(newCommandTable)
      expect(loadedCommandTable).toEqual(oldCommandTable)
      expect(loadedCommandTable).toEqual(newCommandTable)
