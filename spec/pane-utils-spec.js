"use babel"

const {Range} = require("atom")
const {
  it,
  fit,
  ffit,
  fffit,
  emitterEventPromise,
  beforeEach,
  afterEach,
} = require("./async-spec-helpers")

function dispatchCommand(commandName) {
  atom.commands.dispatch(atom.workspace.getElement(), commandName)
}

function ensurePaneLayout(layout) {
  const root = atom.workspace.getActivePane().getContainer().getRoot()
  expect(paneLayoutFor(root)).toEqual(layout)
}

function paneLayoutFor(root) {
  const layout = {}
  layout[root.getOrientation()] = root.getChildren().map(child => {
    switch (child.constructor.name) {
      case "Pane":
        return child.getItems()
      case "PaneAxis":
        return paneLayoutFor(child)
    }
  })
  return layout
}

describe("pane manipulation commands", () => {
  beforeEach(() => {
    // `destroyEmptyPanes` is default true, but atom's spec-helper reset to `false`
    // So set it to `true` again here to test with default value.
    atom.config.set("core.destroyEmptyPanes", true)
    jasmine.attachToDOM(atom.workspace.getElement())

    return atom.packages.activatePackage("vim-mode-plus")
  })

  describe("moveToVery direction", () => {
    describe("all horizontal", () => {
      let e1, e2, e3, p1, p2, p3
      beforeEach(async () => {
        e1 = await atom.workspace.open("file1")
        e2 = await atom.workspace.open("file2", {split: "right"})
        e3 = await atom.workspace.open("file3", {split: "right"})
        const panes = atom.workspace.getCenter().getPanes()
        expect(panes).toHaveLength(3)
        ;[p1, p2, p3] = panes
        ensurePaneLayout({horizontal: [[e1], [e2], [e3]]})
        expect(atom.workspace.getActivePane()).toBe(p3)
      })

      describe("very-top", () => {
        it("case 1", () => {
          p1.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-top")
          ensurePaneLayout({vertical: [[e1], {horizontal: [[e2], [e3]]}]})
        })
        it("case 2", () => {
          p2.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-top")
          ensurePaneLayout({vertical: [[e2], {horizontal: [[e1], [e3]]}]})
        })
        it("case 3", () => {
          p3.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-top")
          ensurePaneLayout({vertical: [[e3], {horizontal: [[e1], [e2]]}]})
        })
      })

      describe("very-bottom", () => {
        it("case 1", () => {
          p1.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-bottom")
          ensurePaneLayout({vertical: [{horizontal: [[e2], [e3]]}, [e1]]})
        })
        it("case 2", () => {
          p2.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-bottom")
          ensurePaneLayout({vertical: [{horizontal: [[e1], [e3]]}, [e2]]})
        })
        it("case 3", () => {
          p3.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-bottom")
          ensurePaneLayout({vertical: [{horizontal: [[e1], [e2]]}, [e3]]})
        })
      })

      describe("very-left", () => {
        it("case 1", () => {
          p1.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-left")
          ensurePaneLayout({horizontal: [[e1], [e2], [e3]]})
        })
        it("case 2", () => {
          p2.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-left")
          ensurePaneLayout({horizontal: [[e2], [e1], [e3]]})
        })
        it("case 3", () => {
          p3.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-left")
          ensurePaneLayout({horizontal: [[e3], [e1], [e2]]})
        })
      })

      describe("very-right", () => {
        it("case 1", () => {
          p1.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-right")
          ensurePaneLayout({horizontal: [[e2], [e3], [e1]]})
        })
        it("case 2", () => {
          p2.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-right")
          ensurePaneLayout({horizontal: [[e1], [e3], [e2]]})
        })
        it("case 3", () => {
          p3.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-right")
          ensurePaneLayout({horizontal: [[e1], [e2], [e3]]})
        })
      })

      describe("complex operation", () => {
        it("case 1", () => {
          p1.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-top")
          ensurePaneLayout({vertical: [[e1], {horizontal: [[e2], [e3]]}]})
          dispatchCommand("vim-mode-plus:move-pane-to-very-left")
          ensurePaneLayout({horizontal: [[e1], [e2], [e3]]})
          dispatchCommand("vim-mode-plus:move-pane-to-very-bottom")
          ensurePaneLayout({vertical: [{horizontal: [[e2], [e3]]}, [e1]]})
          dispatchCommand("vim-mode-plus:move-pane-to-very-right")
          ensurePaneLayout({horizontal: [[e2], [e3], [e1]]})
        })
      })
    })

    describe("all vertical", () => {
      let e1, e2, e3, p1, p2, p3
      beforeEach(async () => {
        e1 = await atom.workspace.open("file1")
        e2 = await atom.workspace.open("file2", {split: "down"})
        e3 = await atom.workspace.open("file3", {split: "down"})
        const panes = atom.workspace.getCenter().getPanes()
        expect(panes).toHaveLength(3)
        ;[p1, p2, p3] = panes
        ensurePaneLayout({vertical: [[e1], [e2], [e3]]})
        expect(atom.workspace.getActivePane()).toBe(p3)
      })

      describe("very-top", () => {
        it("case 1", () => {
          p1.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-top")
          ensurePaneLayout({vertical: [[e1], [e2], [e3]]})
        })
        it("case 2", () => {
          p2.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-top")
          ensurePaneLayout({vertical: [[e2], [e1], [e3]]})
        })
        it("case 3", () => {
          p3.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-top")
          ensurePaneLayout({vertical: [[e3], [e1], [e2]]})
        })
      })

      describe("very-bottom", () => {
        it("case 1", () => {
          p1.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-bottom")
          ensurePaneLayout({vertical: [[e2], [e3], [e1]]})
        })
        it("case 2", () => {
          p2.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-bottom")
          ensurePaneLayout({vertical: [[e1], [e3], [e2]]})
        })
        it("case 3", () => {
          p3.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-bottom")
          ensurePaneLayout({vertical: [[e1], [e2], [e3]]})
        })
      })

      describe("very-left", () => {
        it("case 1", () => {
          p1.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-left")
          ensurePaneLayout({horizontal: [[e1], {vertical: [[e2], [e3]]}]})
        })
        it("case 2", () => {
          p2.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-left")
          ensurePaneLayout({horizontal: [[e2], {vertical: [[e1], [e3]]}]})
        })
        it("case 3", () => {
          p3.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-left")
          ensurePaneLayout({horizontal: [[e3], {vertical: [[e1], [e2]]}]})
        })
      })

      describe("very-right", () => {
        it("case 1", () => {
          p1.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-right")
          ensurePaneLayout({horizontal: [{vertical: [[e2], [e3]]}, [e1]]})
        })
        it("case 2", () => {
          p2.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-right")
          ensurePaneLayout({horizontal: [{vertical: [[e1], [e3]]}, [e2]]})
        })
        it("case 3", () => {
          p3.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-right")
          ensurePaneLayout({horizontal: [{vertical: [[e1], [e2]]}, [e3]]})
        })
      })

      describe("complex operation", () =>
        it("case 1", () => {
          p1.activate()
          dispatchCommand("vim-mode-plus:move-pane-to-very-top")
          ensurePaneLayout({vertical: [[e1], [e2], [e3]]})
          dispatchCommand("vim-mode-plus:move-pane-to-very-left")
          ensurePaneLayout({horizontal: [[e1], {vertical: [[e2], [e3]]}]})
          dispatchCommand("vim-mode-plus:move-pane-to-very-bottom")
          ensurePaneLayout({vertical: [[e2], [e3], [e1]]})
          dispatchCommand("vim-mode-plus:move-pane-to-very-right")
          ensurePaneLayout({horizontal: [{vertical: [[e2], [e3]]}, [e1]]})
        }))
    })
  })

  describe("exchange-pane", () => {
    let p1, p2, p3, items
    beforeEach(async () => {
      const e1 = await atom.workspace.open("file1")
      const e2 = await atom.workspace.open("file2", {split: "right"})
      const e3 = await atom.workspace.open("file3")
      const e4 = await atom.workspace.open("file4", {split: "down"})
      const panes = atom.workspace.getCenter().getPanes()
      expect(panes).toHaveLength(3)
      ;[p1, p2, p3] = panes
      items = {
        p1: p1.getItems(),
        p2: p2.getItems(),
        p3: p3.getItems(),
      }
      expect(items).toEqual({
        p1: [e1],
        p2: [e2, e3],
        p3: [e4],
      })

      ensurePaneLayout({horizontal: [items.p1, {vertical: [items.p2, items.p3]}]})
      expect(atom.workspace.getActivePane()).toBe(p3)
    })

    it("[adjacent is pane]: exchange pane and and stay active pane", () => {
      dispatchCommand("vim-mode-plus:exchange-pane")
      ensurePaneLayout({horizontal: [items.p1, {vertical: [items.p3, items.p2]}]})
      expect(atom.workspace.getActivePane()).toBe(p2)

      dispatchCommand("vim-mode-plus:exchange-pane")
      ensurePaneLayout({horizontal: [items.p1, {vertical: [items.p2, items.p3]}]})
      expect(atom.workspace.getActivePane()).toBe(p3)
    })

    it("[adjacent is paneAxis]: Do nothing when adjacent was paneAxis", () => {
      p1.activate()
      dispatchCommand("vim-mode-plus:exchange-pane")
      ensurePaneLayout({horizontal: [items.p1, {vertical: [items.p2, items.p3]}]})
      expect(atom.workspace.getActivePane()).toBe(p1)
    })
  })
})
