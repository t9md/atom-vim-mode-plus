let focusInput, readChar

const {Emitter, Disposable, CompositeDisposable} = require('atom')
const settings = require('./settings')

const LoadedLibs = {}
const __vimStatesByEditor = new Map()

const dasherize = s => (s[0].toLowerCase() + s.slice(1)).replace(/[A-Z]/g, m => '-' + m.toLowerCase())
const classify = s => s[0].toUpperCase() + s.slice(1).replace(/-(\w)/g, m => m[1].toUpperCase())

module.exports = class VimState {
  // Proxy propperties and methods
  // ===========================================================================
  static get (editor) { return __vimStatesByEditor.get(editor) } // prettier-ignore
  static set (editor, vimState) { return __vimStatesByEditor.set(editor, vimState) } // prettier-ignore
  static has (editor) { return __vimStatesByEditor.has(editor) } // prettier-ignore
  static delete (editor) { return __vimStatesByEditor.delete(editor) } // prettier-ignore
  static forEach (fn) { return __vimStatesByEditor.forEach(fn) } // prettier-ignore
  static clear () { return __vimStatesByEditor.clear() } // prettier-ignore

  flash (...args) { this.flashManager.flash(...args) } // prettier-ignore
  clearFlash () { this.__flashManager && this.flashManager.clearAllMarkers() } // prettier-ignore
  updateStatusBar () { this.statusBarManager.update(this.mode, this.submode) } // prettier-ignore
  setOperatorModifier (...args) { this.operationStack.setOperatorModifier(...args) } // prettier-ignore
  subscribe (...args) { return this.operationStack.subscribe(...args) } // prettier-ignore
  getCount () { return this.operationStack.getCount() } // prettier-ignore
  hasCount () { return this.operationStack.hasCount() } // prettier-ignore
  setCount (...args) { this.operationStack.setCount(...args) } // prettier-ignore
  addToClassList (...args) { return this.operationStack.addToClassList(...args) } // prettier-ignore
  requestScroll (...args) { this.scrollManager.requestScroll(...args) } // prettier-ignore

  // Lazy populated properties for fast package startup
  // =====================================================
  load (file, instantiate = true) {
    if (atom.inDevMode() && settings.get('debug') && !(file in LoadedLibs)) {
      console.log(`# lazy-require: ${file}`)
    }
    const lib = LoadedLibs[file] || (LoadedLibs[file] = require(file))
    return instantiate ? new lib(this) : lib // eslint-disable-line new-cap
  }
  get mark () { return this.__mark || (this.__mark = this.load('./mark-manager')) } // prettier-ignore
  get register () { return this.__register || (this.__register = this.load('./register-manager')) } // prettier-ignore
  get hover () { return this.__hover || (this.__hover = this.load('./hover-manager')) } // prettier-ignore
  get hoverSearchCounter () { return this.__hoverSearchCounter || (this.__hoverSearchCounter = this.load('./hover-manager')) } // prettier-ignore
  get searchHistory () { return this.__searchHistory || (this.__searchHistory = this.load('./search-history-manager')) } // prettier-ignore
  get highlightSearch () { return this.__highlightSearch || (this.__highlightSearch = this.load('./highlight-search-manager')) } // prettier-ignore
  get highlightFind () { return this.__highlightFind || (this.__highlightFind = this.load('./highlight-find-manager')) } // prettier-ignore
  get persistentSelection () { return this.__persistentSelection || (this.__persistentSelection = this.load('./persistent-selection-manager')) } // prettier-ignore
  get occurrenceManager () { return this.__occurrenceManager || (this.__occurrenceManager = this.load('./occurrence-manager')) } // prettier-ignore
  get mutationManager () { return this.__mutationManager || (this.__mutationManager = this.load('./mutation-manager')) } // prettier-ignore
  get flashManager () { return this.__flashManager || (this.__flashManager = this.load('./flash-manager')) } // prettier-ignore
  get searchInput () { return this.__searchInput || (this.__searchInput = this.load('./search-input')) } // prettier-ignore
  get operationStack () { return this.__operationStack || (this.__operationStack = this.load('./operation-stack')) } // prettier-ignore
  get cursorStyleManager () { return this.__cursorStyleManager || (this.__cursorStyleManager = this.load('./cursor-style-manager')) } // prettier-ignore
  get sequentialPasteManager () { return this.__sequentialPasteManager || (this.__sequentialPasteManager = this.load('./sequential-paste-manager')) } // prettier-ignore
  get scrollManager () { return this.__scrollManager || (this.__scrollManager = this.load('./scroll-manager')) } // prettier-ignore
  get swrap () { return this.__swrap || (this.__swrap = this.load('./selection-wrapper', false)) } // prettier-ignore
  get utils () { return this.__utils || (this.__utils = this.load('./utils', false)) } // prettier-ignore
  get globalState () { return this.__globalState || (this.__globalState = this.load('./global-state', false)) } // prettier-ignore
  get _ () { return this.constructor._ } // prettier-ignore
  static get _ () { return this.__underscorePlus || (this.__underscorePlus = require('underscore-plus')) } // prettier-ignore

  static getDispatcher (fn) {
    return function (event) {
      event.stopPropagation()
      const vimState = VimState.get(this.getModel()) // vimState possibly be undefined See #85
      if (vimState) {
        const klass = fn ? fn() : classify(event.type.replace('vim-mode-plus:', ''))
        vimState.operationStack.run(klass)
      }
    }
  }

  static loadPluginLoader (loader) {
    if (!this.executedStatusByLoader) this.executedStatusByLoader = new Map()
    if (!this.executedStatusByLoader.has(loader)) {
      this.executedStatusByLoader.set(loader, loader())
    }
    return this.executedStatusByLoader.get(loader)
  }

  static registerCommandFromSpec (klassName, spec) {
    return this.registerCommandsFromSpec([klassName], spec)
  }

  static registerCommandsFromSpec (klassNames, spec) {
    const getClass = spec.loader ? klassName => this.loadPluginLoader(spec.loader)[klassName] : spec.getClass
    const table = {}
    for (const klassName of klassNames) {
      const commandName = spec.prefix + ':' + dasherize(klassName)
      table[commandName] = this.getDispatcher(() => getClass(klassName))
    }
    return atom.commands.add(spec.scope || 'atom-text-editor', table)
  }

  constructor (editor, statusBarManager) {
    this.editor = editor
    this.editorElement = editor.element
    this.statusBarManager = statusBarManager
    this.emitter = new Emitter()

    this.mode = 'insert' // Bare atom is not modal editor, thus it's `insert` mode.
    this.submode = null

    this.replaceModeDisposable = null

    this.previousSelection = {}
    this.ignoreSelectionChange = false

    this.subscriptions = new CompositeDisposable(
      this.observeMouse(),
      this.editor.onDidAddSelection(selection => this.reconcileVisualModeWithActualSelection()),
      this.editor.onDidChangeSelectionRange(event => this.reconcileVisualModeWithActualSelection())
    )

    this.editorElement.classList.add('vim-mode-plus')

    if (this.getConfig('startInInsertMode') || this.matchScopes(this.getConfig('startInInsertModeScopes'))) {
      this.activate('insert')
    } else {
      this.activate('normal')
    }

    editor.onDidDestroy(() => this.destroy())
    this.constructor.set(editor, this)
  }

  getConfig (param) {
    return settings.get(param)
  }

  matchScopes (scopes) {
    // HACK: length guard to avoid utils prop populated unnecessarily
    return scopes.length && this.utils.matchScopes(this.editorElement, scopes)
  }

  // BlockwiseSelections
  // -------------------------
  getBlockwiseSelections () {
    return this.swrap.getBlockwiseSelections(this.editor)
  }

  getLastBlockwiseSelection () {
    return this.swrap.getLastBlockwiseSelections(this.editor)
  }

  getBlockwiseSelectionsOrderedByBufferPosition () {
    return this.swrap.getBlockwiseSelectionsOrderedByBufferPosition(this.editor)
  }

  clearBlockwiseSelections () {
    if (this.__swrap) this.swrap.clearBlockwiseSelections(this.editor)
  }

  // All subscriptions here is cleared on each operation finished.
  // -------------------------
  onDidChangeSearch (fn) { return this.subscribe(this.searchInput.onDidChange(fn)) } // prettier-ignore
  onDidConfirmSearch (fn) { return this.subscribe(this.searchInput.onDidConfirm(fn)) } // prettier-ignore
  onDidCancelSearch (fn) { return this.subscribe(this.searchInput.onDidCancel(fn)) } // prettier-ignore
  onDidCommandSearch (fn) { return this.subscribe(this.searchInput.onDidCommand(fn)) } // prettier-ignore

  onDidSetTarget (fn) { return this.subscribe(this.emitter.on('did-set-target', fn)) } // prettier-ignore
  emitDidSetTarget (operator) { this.emitter.emit('did-set-target', operator) } // prettier-ignore

  onWillSelectTarget (fn) { return this.subscribe(this.emitter.on('will-select-target', fn)) } // prettier-ignore
  emitWillSelectTarget () { this.emitter.emit('will-select-target') } // prettier-ignore

  onDidSelectTarget (fn) { return this.subscribe(this.emitter.on('did-select-target', fn)) } // prettier-ignore
  emitDidSelectTarget () { this.emitter.emit('did-select-target') } // prettier-ignore

  onDidFailSelectTarget (fn) { return this.subscribe(this.emitter.on('did-fail-select-target', fn)) } // prettier-ignore
  emitDidFailSelectTarget () { this.emitter.emit('did-fail-select-target') } // prettier-ignore

  onWillFinishMutation (fn) { return this.subscribe(this.emitter.on('on-will-finish-mutation', fn)) } // prettier-ignore
  emitWillFinishMutation () { this.emitter.emit('on-will-finish-mutation') } // prettier-ignore

  onDidFinishMutation (fn) { return this.subscribe(this.emitter.on('on-did-finish-mutation', fn)) } // prettier-ignore
  emitDidFinishMutation () { this.emitter.emit('on-did-finish-mutation') } // prettier-ignore

  onDidFinishOperation (fn) { return this.subscribe(this.emitter.on('did-finish-operation', fn)) } // prettier-ignore
  emitDidFinishOperation () { this.emitter.emit('did-finish-operation') } // prettier-ignore

  onDidResetOperationStack (fn) { return this.subscribe(this.emitter.on('did-reset-operation-stack', fn)) } // prettier-ignore
  emitDidResetOperationStack () { this.emitter.emit('did-reset-operation-stack') } // prettier-ignore

  // Events
  // -------------------------
  onWillActivateMode (fn) { return this.emitter.on('will-activate-mode', fn) } // prettier-ignore
  onDidActivateMode (fn) { return this.emitter.on('did-activate-mode', fn) } // prettier-ignore
  onWillDeactivateMode (fn) { return this.emitter.on('will-deactivate-mode', fn) } // prettier-ignore
  preemptWillDeactivateMode (fn) { return this.emitter.preempt('will-deactivate-mode', fn) } // prettier-ignore
  onDidDeactivateMode (fn) { return this.emitter.on('did-deactivate-mode', fn) } // prettier-ignore

  get modeManager () {
    if (!this.modeManagerStub) {
      const Grim = require('grim')
      const warnAndProxy = name => {
        Grim.deprecate(`Use \`vimState.${name}\` instead of \`vimState.modeManager.${name}\``)
        return this[name].bind(this)
      }

      this.modeManagerStub = {
        get onWillActivateMode () { return warnAndProxy('onWillActivateMode') }, // prettier-ignore
        get onDidActivateMode () { return warnAndProxy('onDidActivateMode') }, // prettier-ignore
        get onWillDeactivateMode () { return warnAndProxy('onWillDeactivateMode') }, // prettier-ignore
        get preemptWillDeactivateMode () { return warnAndProxy('preemptWillDeactivateMode') }, // prettier-ignore
        get onDidDeactivateMode () { return warnAndProxy('onDidDeactivateMode') } // prettier-ignore
      }
    }
    return this.modeManagerStub
  }

  onDidFailToPushToOperationStack (fn) { return this.emitter.on('did-fail-to-push-to-operation-stack', fn) } // prettier-ignore
  emitDidFailToPushToOperationStack () { this.emitter.emit('did-fail-to-push-to-operation-stack') } // prettier-ignore
  onDidDestroy (fn) { return this.emitter.on('did-destroy', fn) } // prettier-ignore
  onDidSetInputChar (fn) { return this.emitter.on('did-set-input-char', fn) } // prettier-ignore
  emitDidSetInputChar (char) { this.emitter.emit('did-set-input-char', char) } // prettier-ignore

  // * `fn` {Function} to be called when mark was set.
  //   * `name` Name of mark such as 'a'.
  //   * `bufferPosition`: bufferPosition where mark was set.
  //   * `editor`: editor where mark was set.
  // Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  //
  //  Usage:
  //   onDidSetMark ({name, bufferPosition}) -> do something..
  onDidSetMark (fn) {
    return this.emitter.on('did-set-mark', fn)
  }

  isAlive () {
    return this.constructor.has(this.editor)
  }

  destroy () {
    if (!this.isAlive()) return

    this.constructor.delete(this.editor)
    this.subscriptions.dispose()

    if (this.editor.isAlive()) {
      this.resetNormalMode()
      this.reset()
      if (this.editorElement.component) this.editorElement.component.setInputEnabled(true)

      // Disable `readOnly` state of which possibly be changed by `autoDisableInputMethodWhenLeavingInsertMode`.
      if (this.editor.component.getHiddenInput().readOnly) {
        this.editor.component.getHiddenInput().readOnly = false
      }
      this.editorElement.classList.remove('vim-mode-plus', 'normal-mode')
    }
    this.emitter.emit('did-destroy')
  }

  haveSomeNonEmptySelection () {
    return this.editor.getSelections().some(selection => !selection.isEmpty())
  }

  // This function is mainly called in editor.onDidChangeSelectionRange enent
  // Purpose of this function is to auto-start/stop visual-mode when outer-vmp modify selection.
  // See. vim-mode-plus#878, #873 for detail
  //
  // - When outer-vmp command select some range(1) and clear(2) within single-command.
  // - Vmp start `visual-mode` at (1), then reset to `normal-mode` at (2).
  // - This is NOT elegant solution, but there is no other better way.
  // - We cannot determine selection is eventually cleared or not within `editor.onDidChangeSelectionRange` event.
  // - Delaying, debouncing to minimize useless mode-shift is bad for UX, user see slight delay for cursor updated.
  reconcileVisualModeWithActualSelection (shiftToNormalIfNoSelection = true) {
    // This guard is somewhat verbose and duplicate, but I prefer duplication than increase chance of infinite loop.
    if (this.shouldIgnoreChangeSelection()) return

    this.ignoreSelectionChange = true

    const refreshCursorStyle = () => {
      this.swrap.getSelections(this.editor).forEach($s => $s.saveProperties())
      this.cursorStyleManager.refresh()
    }

    const hasSelection = this.haveSomeNonEmptySelection()
    const isVisual = this.mode === 'visual'

    if (hasSelection && isVisual) refreshCursorStyle()
    else if (hasSelection && !isVisual) this.activate('visual', this.swrap.detectWise(this.editor))
    else if (!hasSelection && isVisual) {
      if (shiftToNormalIfNoSelection) this.activate('normal')
      else refreshCursorStyle()
    }

    this.ignoreSelectionChange = false
  }

  shouldIgnoreChangeSelection () {
    return (
      this.ignoreSelectionChange || this.mode === 'insert' || (this.__operationStack && this.operationStack.isRunning())
    )
  }

  observeMouse () {
    const nextMouseEventTable = {
      'mousedown-capture': 'mousedown-bubble',
      'mousedown-bubble': 'mouseup',
      mouseup: 'mousedown-capture'
    }

    // Why explicitly assure mouse-event lifecycle? see #830 for detail.
    let waitingMouseEvent = 'mousedown-capture'
    const isWaiting = mouseEvent => {
      const isValid = waitingMouseEvent === mouseEvent && !this.shouldIgnoreChangeSelection()
      if (isValid) waitingMouseEvent = nextMouseEventTable[mouseEvent]
      return isValid
    }

    // To keep original cursor screen range(tail range of selection) keep selected on `shift+click`
    // At this phase, cursor position is NOT yet updated, so we interact with original before-clicked cursor position.
    const onMouseDownCapture = () => {
      if (isWaiting('mousedown-capture')) {
        for (const selection of this.editor.getSelections()) {
          selection.initialScreenRange = this.swrap(selection).getTailScreenRange()
        }
      }
    }

    const onMouseDownBubble = () => {
      if (isWaiting('mousedown-bubble')) {
        if (this.isMode('visual', 'blockwise') && !this.haveSomeNonEmptySelection()) {
          this.getBlockwiseSelections().forEach(bs => bs.skipNormalization())
        }
        for (const selection of this.editor.getSelections().filter(s => s.isEmpty())) {
          selection.initialScreenRange = this.swrap(selection).getTailScreenRange()
        }
        // For shilft+click which not involve mousemove event.
        this.reconcileVisualModeWithActualSelection(false) // Prevent auto-shift-to-normal-mode by passing `false`
      }
    }

    const onMouseUp = () => {
      if (isWaiting('mouseup')) {
        this.reconcileVisualModeWithActualSelection()
      }
    }

    this.editorElement.addEventListener('mousedown', onMouseDownCapture, true)
    this.editorElement.addEventListener('mousedown', onMouseDownBubble, false)
    this.editorElement.addEventListener('mouseup', onMouseUp)

    return new Disposable(() => {
      this.editorElement.removeEventListener('mousedown', onMouseDownCapture, true)
      this.editorElement.removeEventListener('mousedown', onMouseDownBubble, false)
      this.editorElement.removeEventListener('mouseup', onMouseUp)
    })
  }

  // What's this?
  // clear all selections and final cursor position becomes head of last selection.
  // editor.clearSelections() does not respect last selection's head, since it merge all selections before clearing.
  clearSelections () {
    this.editor.setCursorBufferPosition(this.editor.getCursorBufferPosition())
  }

  resetNormalMode (options = {}) {
    this.clearBlockwiseSelections()

    if (options.userInvocation) {
      this.operationStack.lastCommandName = null

      if (this.editor.hasMultipleCursors()) {
        this.clearSelections()
      } else if (this.hasPersistentSelections() && this.getConfig('clearPersistentSelectionOnResetNormalMode')) {
        this.clearPersistentSelections()
      } else if (this.__occurrenceManager && this.occurrenceManager.hasPatterns()) {
        this.occurrenceManager.resetPatterns()
      }
      if (this.getConfig('clearHighlightSearchOnResetNormalMode')) {
        this.globalState.set('highlightSearchPattern', null)
      }
    } else {
      this.clearSelections()
    }
    this.activate('normal')
  }

  reset () {
    // Reset each props only if it's already populated.
    this.__register && this.register.reset()
    this.__searchHistory && this.searchHistory.reset()
    this.__hover && this.hover.reset()
    this.__mutationManager && this.mutationManager.reset()
    this.__operationStack && this.operationStack.reset()
  }

  isVisible () {
    return this.utils.getVisibleEditors().includes(this.editor)
  }

  // FIXME: naming, updateLastSelectedInfo ?
  updatePreviousSelection () {
    let properties

    if (this.isMode('visual', 'blockwise')) {
      const blockwiseSelection = this.getLastBlockwiseSelection()
      properties = blockwiseSelection && blockwiseSelection.getProperties()
    } else {
      properties = this.swrap(this.editor.getLastSelection()).getProperties()
    }

    // TODO#704 when cursor is added in visual-mode, corresponding selection prop yet not exists.
    if (!properties) return

    // Copy by extracting only used item.
    properties = {head: properties.head, tail: properties.tail}

    const [whichStart, whichEnd] = properties.head.isGreaterThanOrEqual(properties.tail)
      ? ['tail', 'head']
      : ['head', 'tail']
    properties[whichEnd] = this.utils.translatePointAndClip(this.editor, properties[whichEnd], 'forward')

    this.mark.set('<', properties[whichStart])
    this.mark.set('>', properties[whichEnd])
    this.previousSelection = {properties, submode: this.submode}
  }

  // Persistent selection
  // -------------------------
  hasPersistentSelections () {
    return this.__persistentSelection ? this.persistentSelection.hasMarkers() : false
  }

  getPersistentSelectionBufferRanges () {
    return this.__persistentSelection ? this.persistentSelection.getMarkerBufferRanges() : []
  }

  clearPersistentSelections () {
    if (this.__persistentSelection) this.persistentSelection.clearMarkers()
  }

  // Mode Managerment
  // =========================
  isMode (mode, submode) {
    return mode === this.mode && (submode ? submode === this.submode : true)
  }

  // Use this method to change mode, DONT use other direct method.
  activate (newMode, newSubmode = null) {
    if (newMode === 'visual' && !newSubmode) {
      throw new Error('vimState.activate("visual", null) is not allowed, specify submode as 2nd arg')
    }

    // Avoid odd state(= visual-mode but selection is empty)
    if (newMode === 'visual' && this.editor.isEmpty()) return
    this.ignoreSelectionChange = true

    this.emitter.emit('will-activate-mode', {mode: newMode, submode: newSubmode})

    if (newMode === 'visual' && newSubmode === this.submode) {
      newMode = 'normal'
      newSubmode = null
    }

    if (newMode !== this.mode) {
      this.emitter.emit('will-deactivate-mode', {mode: this.mode, submode: this.submode})
      if (this.modeDeactivator) {
        this.modeDeactivator.dispose()
        this.modeDeactivator = null
      }
      this.emitter.emit('did-deactivate-mode', {mode: this.mode, submode: this.submode})
    }

    if (newMode === 'normal') this.activateNormalMode()
    else if (newMode === 'insert') this.editorElement.component.setInputEnabled(true)
    else if (newMode === 'visual') this.modeDeactivator = this.activateVisualMode(newSubmode)

    if (this.getConfig('autoDisableInputMethodWhenLeavingInsertMode')) {
      this.editor.component.getHiddenInput().readOnly = newMode !== 'insert'
    }

    this.editorElement.classList.remove(`${this.mode}-mode`)
    this.editorElement.classList.remove(this.submode)

    const oldMode = this.mode
    this.mode = newMode
    this.submode = newSubmode

    // Order matter, following code must be called AFTER this.mode was updated
    if (oldMode === 'visual' || this.mode === 'visual') this.updateNarrowedState()

    // Prevent swrap from loaded on initial mode-setup on startup.
    if (this.mode === 'visual') {
      this.updatePreviousSelection()
    } else {
      if (this.__swrap) this.swrap.clearProperties(this.editor)
    }

    this.editorElement.classList.add(`${this.mode}-mode`)
    if (this.submode) this.editorElement.classList.add(this.submode)

    this.statusBarManager.update(this.mode, this.submode)
    if (this.mode === 'visual' || this.__cursorStyleManager) {
      this.cursorStyleManager.refresh()
    }

    this.emitter.emit('did-activate-mode', {mode: this.mode, submode: this.submode})
    this.ignoreSelectionChange = false
  }

  activateNormalMode () {
    this.reset()
    // Component is not necessary avaiable see #98.
    if (this.editorElement.component) {
      this.editorElement.component.setInputEnabled(false)
    }

    // In visual-mode, cursor can place at EOL. move left if cursor is at EOL
    // We should not do this in visual-mode deactivation phase.
    // e.g. `A` directly shift from visua-mode to `insert-mode`, and cursor should remain at EOL.
    for (const cursor of this.editor.getCursors()) {
      // Don't use utils moveCursorLeft to skip require('./utils') for faster startup.
      if (cursor.isAtEndOfLine() && !cursor.isAtBeginningOfLine()) {
        const {goalColumn} = cursor
        cursor.moveLeft()
        if (goalColumn != null) cursor.goalColumn = goalColumn
      }
    }
  }

  // Visual mode
  // -------------------------
  // We treat all selection is initially NOT normalized
  //
  // 1. First we normalize selection
  // 2. Then update selection orientation(=wise).
  //
  // Regardless of selection is modified by vmp-command or outer-vmp-command like `cmd-l`.
  // When normalize, we move cursor to left(selectLeft equivalent).
  // Since Vim's visual-mode is always selectRighted.
  //
  // - un-normalized selection: This is the range we see in visual-mode.( So normal visual-mode range in user perspective ).
  // - normalized selection: One column left selcted at selection end position
  // - When selectRight at end position of normalized-selection, it become un-normalized selection
  //   which is the range in visual-mode.
  activateVisualMode (submode) {
    const swrap = this.swrap
    swrap.saveProperties(this.editor)
    swrap.normalize(this.editor)

    for (const $selection of swrap.getSelections(this.editor)) {
      $selection.applyWise(submode)
    }
    if (submode === 'blockwise') this.getLastBlockwiseSelection().autoscroll()

    return new Disposable(() => {
      swrap.normalize(this.editor)
      if (this.submode === 'blockwise') swrap.setReversedState(this.editor, true)
      for (const selection of this.editor.getSelections()) {
        selection.clear({autoscroll: false})
      }
    })
  }

  // Narrowed selection
  // -------------------------
  updateNarrowedState () {
    const isSingleRowSelection = this.isMode('visual', 'blockwise')
      ? this.getLastBlockwiseSelection().isSingleRow()
      : this.swrap(this.editor.getLastSelection()).isSingleRow()
    this.editorElement.classList.toggle('is-narrowed', !isSingleRowSelection)
  }

  isNarrowed () {
    return this.editorElement.classList.contains('is-narrowed')
  }

  // Other
  // -------------------------
  focusInput (options) {
    if (!focusInput) focusInput = require('./focus-input')
    focusInput(this, options)
  }

  readChar (options) {
    if (!readChar) readChar = require('./read-char')
    readChar(this, options)
  }
}
