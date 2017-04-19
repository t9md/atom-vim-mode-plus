Base = require '../lib/base'
fs = require 'fs-plus'

describe "command-table", ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('vim-mode-plus')

  describe "initial Base.registries", ->
    it "contains one entry and it's Base class", ->
      registries = Base.getRegistries()
      keys = Object.keys(registries)
      expect(keys).toHaveLength(1)
      expect(keys[0]).toBe("Base")
      expect(registries[keys[0]]).toBe(Base)

  describe "cmd-table serialize/deserialize", ->
    it "generateCommandTableByEagerLoad populate registry eagerly and return table which is equals to loaded command table", ->
      [oldCommandTable, newCommandTable] = []

      oldRegistries = Base.getRegistries()
      oldRegistriesLength = Object.keys(oldRegistries).length
      expect(Object.keys(oldRegistries)).toHaveLength(1)

      oldCommandTable = Base.commandTable
      newCommandTable = Base.generateCommandTableByEagerLoad()
      newRegistries = Base.getRegistries()
      newRegistriesLength = Object.keys(newRegistries).length

      expect(newRegistriesLength).toBeGreaterThan(oldRegistriesLength)

      loadedCommandTable = require(Base.commandTablePath)
      expect(oldCommandTable).not.toBe(newCommandTable)
      expect(loadedCommandTable).toEqual(oldCommandTable)
      expect(loadedCommandTable).toEqual(newCommandTable)
