_ = require 'underscore-plus'

{getVimState} = require './spec-helper'

xdescribe "visual-mode performance", ->
  [set, ensure, keystroke, editor, editorElement, vimState] = []

  beforeEach ->
    getVimState (state, _vim) ->
      vimState = state # to refer as vimState later.
      {editor, editorElement} = vimState
      {set, ensure, keystroke} = _vim

  afterEach ->
    vimState.resetNormalMode()
    vimState.globalState.reset()

  describe "slow down editor", ->
    moveRightAndLeftCheck = (scenario, modeSig) ->
      console.log [scenario, modeSig, atom.getVersion(), atom.packages.getActivePackage('vim-mode-plus').metadata.version]

      moveCount = 89
      switch scenario
        when 'vmp'
          moveByVMP = ->
            _.times moveCount, -> keystroke 'l'
            _.times moveCount, -> keystroke 'h'
          _.times 10, -> measureWithTimeEnd(moveByVMP)
        when 'sel'
          moveBySelect = ->
            _.times moveCount, -> editor.getLastSelection().selectRight()
            _.times moveCount, -> editor.getLastSelection().selectLeft()
          _.times 15, -> measureWithTimeEnd(moveBySelect)

    measureWithTimeEnd = (fn) ->
      console.time(fn.name)
      fn()
      console.timeEnd(fn.name)

    beforeEach ->
      set
        cursor: [0, 0]
        text: """
          012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
          """

    describe "vmp", ->
      # beforeEach ->
      it "[normal] slow down editor", ->
        moveRightAndLeftCheck('vmp', 'moveCount')
      it "[vC] slow down editor", ->
        ensure 'v', mode: ['visual', 'characterwise']
        moveRightAndLeftCheck('vmp', 'vC')
        ensure 'escape', mode: 'normal'

        ensure 'v', mode: ['visual', 'characterwise']
        moveRightAndLeftCheck('vmp', 'vC')
        ensure 'escape', mode: 'normal'

      it "[vC] slow down editor", ->
        # ensure 'v', mode: ['visual', 'characterwise']
        moveRightAndLeftCheck('sel', 'vC')
